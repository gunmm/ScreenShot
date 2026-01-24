import ReplayKit
import UIKit // Needed for deepCopy (though actually CVPixelBuffer is CoreVideo, but we might rely on stitcher which uses UIKit)

class SampleHandler: RPBroadcastSampleHandler {

    private let stitcher = ImageStitcher()
    private var lastProcessedBuffer: CVPixelBuffer?
    private var frameCount = 0
    private var chunkIndex = 0
    private var isRecording = false
    
    override func broadcastStarted(withSetupInfo setupInfo: [String : NSObject]?) {
        // User has requested to start the broadcast. Setup info from the UI extension can be supplied but optional. 
        print("Broadcast started")
        isRecording = true
        chunkIndex = 0
        lastProcessedBuffer = nil
        frameCount = 0
        AppGroupConfig.clearChunkDirectory()
    }
    
    override func broadcastPaused() {
        // User has requested to pause the broadcast. Samples will stop being delivered.
        isRecording = false
    }
    
    override func broadcastResumed() {
        // User has requested to resume the broadcast. Samples delivery will resume.
        isRecording = true
    }
    
    override func broadcastFinished() {
        // User has requested to finish the broadcast.
        isRecording = false
        print("Broadcast finished. Total chunks: \(chunkIndex)")
    }
    
    override func processSampleBuffer(_ sampleBuffer: CMSampleBuffer, with sampleBufferType: RPSampleBufferType) {
        guard isRecording, sampleBufferType == .video else { return }
        
        // Throttling: processing every frame is too heavy and unnecessary for scrolling
        // Process every 10th frame (assuming 60fps, that's 6 checks per second)
        // Or better: time based.
        frameCount += 1
        if frameCount % 6 != 0 {
            return
        }
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        // If it's the first frame
        guard let lastBuffer = lastProcessedBuffer else {
            // Save first frame
            if let image = stitcher.processAndCrop(buffer: pixelBuffer) {
                ChunkManager.shared.saveChunk(image: image, index: chunkIndex, offset: 0)
                chunkIndex += 1
                // Keep a copy because the original buffer might be recycled by the system
                lastProcessedBuffer = deepCopy(buffer: pixelBuffer)
            }
            return
        }
        
        // Compare with last buffer
        let offset = stitcher.findOffset(prevBuffer: lastBuffer, currBuffer: pixelBuffer)
        
        if offset > 10 { // Threshold filter
            // Significant movement detected
            
            // We only need to save the new information... OR
            // Simple approach for MVP: Save the whole cropped frame, simpler stitching logic in stitching phase.
            // BUT, to be efficient, we should ideally save only the new part.
            // However, saving full frames and stitching later allows for better error correction.
            // Let's save full frames with offset metadata for now, as implemented in ChunkManager.
            
            if let image = stitcher.processAndCrop(buffer: pixelBuffer) {
                ChunkManager.shared.saveChunk(image: image, index: chunkIndex, offset: offset)
                chunkIndex += 1
                lastProcessedBuffer = deepCopy(buffer: pixelBuffer)
            }
        }
        // If offset is small, we assume it's still static or noise, don't update lastProcessedBuffer to avoid drift
    }
    
    private func deepCopy(buffer: CVPixelBuffer) -> CVPixelBuffer? {
        var copy: CVPixelBuffer?
        CVPixelBufferCreate(nil,
                            CVPixelBufferGetWidth(buffer),
                            CVPixelBufferGetHeight(buffer),
                            CVPixelBufferGetPixelFormatType(buffer),
                            CVBufferGetAttachments(buffer, .shouldPropagate),
                            &copy)
        
        if let copy = copy {
            CVPixelBufferLockBaseAddress(buffer, .readOnly)
            CVPixelBufferLockBaseAddress(copy, [])
            
            let planeCount = CVPixelBufferGetPlaneCount(buffer)
            if planeCount > 0 {
                // Planar (e.g. YUV)
                for i in 0..<planeCount {
                    if let src = CVPixelBufferGetBaseAddressOfPlane(buffer, i),
                       let dst = CVPixelBufferGetBaseAddressOfPlane(copy, i) {
                        let height = CVPixelBufferGetHeightOfPlane(buffer, i)
                        let bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(buffer, i)
                        memcpy(dst, src, height * bytesPerRow)
                    }
                }
            } else {
                // Non-planar (e.g. BGRA)
                if let src = CVPixelBufferGetBaseAddress(buffer),
                   let dst = CVPixelBufferGetBaseAddress(copy) {
                     let height = CVPixelBufferGetHeight(buffer)
                     let bytesPerRow = CVPixelBufferGetBytesPerRow(buffer)
                     memcpy(dst, src, height * bytesPerRow)
                }
            }
            
            CVPixelBufferUnlockBaseAddress(copy, [])
            CVPixelBufferUnlockBaseAddress(buffer, .readOnly)
        }
        return copy
    }
}
