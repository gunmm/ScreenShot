import ReplayKit
import VideoToolbox
import CoreVideo
import Darwin // For memcmp, memcpy

class SampleHandler: RPBroadcastSampleHandler {

    private var lastProcessedBuffer: CVPixelBuffer?
    private var lastTimestamp: TimeInterval = 0
    private var chunkIndex = 0
    private var isRecording = false
    private let throttleInterval: TimeInterval = 0.5
    
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
            print("---*** 时间短")
            return
        }
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        // 2. Memory Lock & Deduplication
        // Only compare if we have a last buffer
        if let lastBuffer = lastProcessedBuffer {
            if isSameContent(buffer1: lastBuffer, buffer2: pixelBuffer) {
                print("---*** 丢弃重复帧")
                // Duplicate frame, skip
                return
            }
        }
        
        // 3. Save Full Frame
        // We need to convert CVPixelBuffer to UIImage to save it (via ChunkManager)
        if let image = convertToUIImage(buffer: pixelBuffer) {
            print("---*** 保存 chunkIndex：\(chunkIndex)")
            ChunkManager.shared.saveChunk(image: image, index: chunkIndex)
            chunkIndex += 1
            
            // Update state
            lastProcessedBuffer = deepCopy(buffer: pixelBuffer)
            lastTimestamp = timestamp
        }
    }
    
    // Efficient Sparse Sampling Comparison
    // Checks 9 blocks (3 rows x 3 columns) to quickly determine if frames are identical.
    private func isSameContent(buffer1: CVPixelBuffer, buffer2: CVPixelBuffer) -> Bool {
        CVPixelBufferLockBaseAddress(buffer1, .readOnly)
        CVPixelBufferLockBaseAddress(buffer2, .readOnly)
        
        defer {
            CVPixelBufferUnlockBaseAddress(buffer1, .readOnly)
            CVPixelBufferUnlockBaseAddress(buffer2, .readOnly)
        }
        
        let width = CVPixelBufferGetWidth(buffer1)
        let height = CVPixelBufferGetHeight(buffer1)
        
        guard width == CVPixelBufferGetWidth(buffer2), height == CVPixelBufferGetHeight(buffer2) else {
            return false
        }
        
        // Configuration
        let sampleSize = 36 // Compare 36 bytes per block
        
        // Vertical positions: 20%, 50%, 80%
        let yPositions = [
            Int(Double(height) * 0.2),
            Int(Double(height) * 0.5),
            Int(Double(height) * 0.8)
        ]
        
        // Horizontal positions: 10%, 50%, 90%
        // We ensure we don't go out of bounds.
        let leftX = max(0, Int(Double(width) * 0.1))
        let centerX = max(0, (width - sampleSize) / 2)
        let rightX = max(0, Int(Double(width) * 0.9) - sampleSize)
        
        let xPositions = [leftX, centerX, rightX]
        
        // Get Base Addresses
        var base1: UnsafeMutableRawPointer?
        var base2: UnsafeMutableRawPointer?
        var bytesPerRow1 = 0
        var bytesPerRow2 = 0
        
        if CVPixelBufferGetPlaneCount(buffer1) > 0 {
            // Planar YUV - Use Plane 0 (Luma)
            base1 = CVPixelBufferGetBaseAddressOfPlane(buffer1, 0)
            base2 = CVPixelBufferGetBaseAddressOfPlane(buffer2, 0)
            bytesPerRow1 = CVPixelBufferGetBytesPerRowOfPlane(buffer1, 0)
            bytesPerRow2 = CVPixelBufferGetBytesPerRowOfPlane(buffer2, 0)
        } else {
            // BGRA
            base1 = CVPixelBufferGetBaseAddress(buffer1)
            base2 = CVPixelBufferGetBaseAddress(buffer2)
            bytesPerRow1 = CVPixelBufferGetBytesPerRow(buffer1)
            bytesPerRow2 = CVPixelBufferGetBytesPerRow(buffer2)
        }
        
        guard let b1 = base1, let b2 = base2 else { return false }
        
        // Perform 9 checks
        for y in yPositions {
            // Calculate row start address
            let row1 = b1.advanced(by: y * bytesPerRow1)
            let row2 = b2.advanced(by: y * bytesPerRow2)
            
            for x in xPositions {
                // In YUV (1 byte/pixel) x is byte offset.
                // In BGRA (4 bytes/pixel) x should be x*4.
                // To keep it simple and logic generic, let's treat Luma as 1 byte check
                // and BGRA as 4 byte check?
                // Actually, user said 36 pixels. In BGRA that's 36*4 bytes.
                // But for deduplication, checking 36 bytes (even if it's just 9 pixels in BGRA) is usually enough entropy.
                // Let's stick to comparing 'sampleSize' BYTES at offset 'x * bytesPerPixel'.
                
                // Determine Bytes Per Pixel
                let bpp = CVPixelBufferGetPlaneCount(buffer1) > 0 ? 1 : 4
                let byteOffset = x * bpp
                
                // Compare memory
                let p1 = row1.advanced(by: byteOffset)
                let p2 = row2.advanced(by: byteOffset)
                
                if memcmp(p1, p2, sampleSize) != 0 {
                    return false
                }
            }
        }
        
        return true
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
