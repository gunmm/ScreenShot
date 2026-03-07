import ReplayKit
import VideoToolbox
import CoreVideo
import CoreGraphics
import CoreImage
import Darwin // For memcmp, memcpy

class SampleHandler: RPBroadcastSampleHandler {

    private var lastProcessedBuffer: CVPixelBuffer?
    private var lastTimestamp: TimeInterval = 0
    private var chunkIndex = 0
    private var isRecording = false
    private let throttleInterval: TimeInterval = 0.2
    
    // Simple memory reuse for saving if needed, though we usually just create new UIImages
    private let context = CIContext()

    override func broadcastStarted(withSetupInfo setupInfo: [String : NSObject]?) {
        print("Broadcast started")
        isRecording = true
        chunkIndex = 0
        lastProcessedBuffer = nil
        lastTimestamp = 0
        AppGroupConfig.clearChunkDirectory()
    }
    
    override func broadcastPaused() {
        isRecording = false
    }
    
    override func broadcastResumed() {
        isRecording = true
    }
    
    override func broadcastFinished() {
        isRecording = false
        print("Broadcast finished. Total chunks: \(chunkIndex)")
    }
    
    override func processSampleBuffer(_ sampleBuffer: CMSampleBuffer, with sampleBufferType: RPSampleBufferType) {
        guard isRecording, sampleBufferType == .video else { return }
        
        let timestamp = CMSampleBufferGetOutputPresentationTimeStamp(sampleBuffer).seconds
        
        // 1. Time Throttle
        if lastTimestamp != 0 && (timestamp - lastTimestamp) < throttleInterval {
            return
        }
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        var orientedBuffer = pixelBuffer
        if let orientationAttachment = CMGetAttachment(sampleBuffer, key: RPVideoSampleOrientationKey as CFString, attachmentModeOut: nil) as? NSNumber,
           let orientation = CGImagePropertyOrientation(rawValue: orientationAttachment.uint32Value), orientation != .up {
            if let rotated = rotatePixelBuffer(pixelBuffer, orientation: orientation) {
                orientedBuffer = rotated
            }
        }
        
        // 2. OpenCV-based Shift Detection
        if let lastBuffer = lastProcessedBuffer {
            let result = OpenCVWrapper.compare(lastBuffer, with: orientedBuffer, staticThreshold: 5.0)
            
            if let dy = result["dy"] as? Double,
               let confidence = result["confidence"] as? Double,
               let meanDiff = result["meanDiff"] as? Double {
                
                // Logic:
                // dy > 0: Content moved UP (Scrolled DOWN) - VALID
                // dy <= 0: Content moved DOWN (Scrolled UP) or Static - INVALID
                
                // Thresholds:
                // Shift must be significant (> 150 pixels) to avoid jitter and redundant small overlaps
                // Confidence must be reasonable (> 0.2)
                
                if dy <= 50 || confidence < 0.15 {
                    print("---*** 丢弃无效帧 (dy: \(String(format: "%.1f", dy)), conf: \(String(format: "%.2f", confidence)), diff: \(String(format: "%.2f", meanDiff))) - 非下滑或静止")
                    return
                }
                
                print("---*** 捕获有效下滑 (Shift: \(Int(dy))) , conf: \(String(format: "%.2f", confidence)), diff: \(String(format: "%.2f", meanDiff))")
            } else {
                // Comparison failed (no features matched or error)
                // If confidence is low, safe to skip to avoid bad stitches
                print("---*** 丢弃帧 (对比失败)")
                return
            }
        }
        
        // 3. Save Full Frame
        if let image = convertToUIImage(buffer: orientedBuffer) {
            print("---*** 保存 chunkIndex：\(chunkIndex)")
            ChunkManager.shared.saveChunk(image: image, index: chunkIndex)
            chunkIndex += 1
            
            // Update state
            lastProcessedBuffer = deepCopy(buffer: orientedBuffer)
            lastTimestamp = timestamp
        }
    }
    
    private func convertToUIImage(buffer: CVPixelBuffer) -> UIImage? {
        // CIContext creation is expensive, but we reused 'context' property
        let ciImage = CIImage(cvPixelBuffer: buffer)
        // Create CGImage to ensure we get a snapshot
        if let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
            return UIImage(cgImage: cgImage)
        }
        return nil
    }
    
    private func rotatePixelBuffer(_ pixelBuffer: CVPixelBuffer, orientation: CGImagePropertyOrientation) -> CVPixelBuffer? {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer).oriented(orientation)
        
        // CVPixelBufferCreate usually creates a bottom-left origin buffer for CIContext.
        // Depending on the applied orientation, we need to flip the image horizontally and/or vertically
        // to ensure it renders right-side-up and unmirrored in the final CVPixelBuffer.
        
        var sx: CGFloat = 1.0
        var sy: CGFloat = 1.0
        
        switch orientation {
        case .up:
            sx = 1.0; sy = 1.0
        case .down:
            sx = 1.0; sy = 1.0
        case .left:
            sx = -1.0; sy = -1.0
        case .right:
            sx = -1.0; sy = -1.0
        default:
            // Standard fallback
            sx = 1.0; sy = 1.0
        }
        
        var flippedImage = ciImage
        if sx != 1.0 || sy != 1.0 {
            let tx: CGFloat = sx == -1.0 ? -ciImage.extent.width : 0.0
            let ty: CGFloat = sy == -1.0 ? -ciImage.extent.height : 0.0
            let transform = CGAffineTransform(scaleX: sx, y: sy).translatedBy(x: tx, y: ty)
            flippedImage = ciImage.transformed(by: transform)
        }
        
        var newPixelBuffer: CVPixelBuffer?
        let attributes: [String: Any] = [
            kCVPixelBufferIOSurfacePropertiesKey as String: [:]
        ]
        
        let width = Int(flippedImage.extent.width)
        let height = Int(flippedImage.extent.height)
        
        let status = CVPixelBufferCreate(kCFAllocatorDefault,
                                         width,
                                         height,
                                         CVPixelBufferGetPixelFormatType(pixelBuffer),
                                         attributes as CFDictionary,
                                         &newPixelBuffer)
        
        if status == kCVReturnSuccess, let destBuffer = newPixelBuffer {
            // Keep original attachments (like color space, etc)
            if let attachments = CVBufferGetAttachments(pixelBuffer, .shouldPropagate) {
                CVBufferSetAttachments(destBuffer, attachments, .shouldPropagate)
            }
            if let nonPropagatingAttachments = CVBufferGetAttachments(pixelBuffer, .shouldNotPropagate) {
                CVBufferSetAttachments(destBuffer, nonPropagatingAttachments, .shouldNotPropagate)
            }
            
            context.render(flippedImage, to: destBuffer, bounds: flippedImage.extent, colorSpace: flippedImage.colorSpace)
            return destBuffer
        }
        return nil
    }
    
    private func deepCopy(buffer: CVPixelBuffer) -> CVPixelBuffer? {
        var copy: CVPixelBuffer?
        // Create a new pixel buffer compatible with the source
        let dict = CVBufferGetAttachments(buffer, .shouldPropagate) as? [String: Any]
        
        CVPixelBufferCreate(nil,
                            CVPixelBufferGetWidth(buffer),
                            CVPixelBufferGetHeight(buffer),
                            CVPixelBufferGetPixelFormatType(buffer),
                            dict as CFDictionary?,
                            &copy)
        
        guard let dest = copy else { return nil }
        
        CVPixelBufferLockBaseAddress(buffer, .readOnly)
        CVPixelBufferLockBaseAddress(dest, [])
        
        if CVPixelBufferGetPlaneCount(buffer) > 0 {
            for i in 0..<CVPixelBufferGetPlaneCount(buffer) {
                if let src = CVPixelBufferGetBaseAddressOfPlane(buffer, i),
                   let dst = CVPixelBufferGetBaseAddressOfPlane(dest, i) {
                    let height = CVPixelBufferGetHeightOfPlane(buffer, i)
                    let bpr = CVPixelBufferGetBytesPerRowOfPlane(buffer, i)
                    memcpy(dst, src, height * bpr)
                }
            }
        } else {
            if let src = CVPixelBufferGetBaseAddress(buffer),
               let dst = CVPixelBufferGetBaseAddress(dest) {
                let height = CVPixelBufferGetHeight(buffer)
                let bpr = CVPixelBufferGetBytesPerRow(buffer)
                memcpy(dst, src, height * bpr)
            }
        }
        
        CVPixelBufferUnlockBaseAddress(dest, [])
        CVPixelBufferUnlockBaseAddress(buffer, .readOnly)
        
        return dest
    }
}
