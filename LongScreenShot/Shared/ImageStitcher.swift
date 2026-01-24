import Foundation
import CoreVideo
import CoreImage
import UIKit

class ImageStitcher {
    
    // Configuration for cropping fixed elements
    // These values might need adjustment based on device model, 
    // or can be detected dynamically. For now, use safe defaults or percentage based.
    private let topCutHeightRatio: CGFloat = 0.12 // Approx status bar + nav bar area
    private let bottomCutHeightRatio: CGFloat = 0.1 // Approx home indicator area
    
    private let context = CIContext()
    
    // Finds the vertical offset between two pixel buffers
    func findOffset(prevBuffer: CVPixelBuffer, currBuffer: CVPixelBuffer) -> Int {
        // Simple pixel comparison or Optical Flow. 
        // For scrolling text/content, a scanline comparison is often efficient enough.
        
        // Convert to CIImages
        let prevImage = CIImage(cvPixelBuffer: prevBuffer)
        let currImage = CIImage(cvPixelBuffer: currBuffer)
        
        // Optimization: Crop to center vertical strip to avoid scrollbar noise if any
        // And convert to grayscale to speed up
        
        // Simplified approach for MVP:
        // We will assume vertical scrolling.
        // We check row by row. 
        // This is computationally expensive in Swift without Metal/Accelerate for full resolution.
        // For MVP, we will assume a "dumb" implementation that relies on SampleHandler calling this 
        // and we delegate the heavy lifting to the main app or keep it very simple here.
        // BUT, SampleHandler needs to decide whether to save.
        
        // Let's implement a basic row sampling using vImage or raw pointers if possible.
        // Or better, since we are in a high-level agent, let's write safe Swift code accessing CVPixelBuffer.
        
        CVPixelBufferLockBaseAddress(prevBuffer, .readOnly)
        CVPixelBufferLockBaseAddress(currBuffer, .readOnly)
        
        defer {
            CVPixelBufferUnlockBaseAddress(prevBuffer, .readOnly)
            CVPixelBufferUnlockBaseAddress(currBuffer, .readOnly)
        }
        
        let width = CVPixelBufferGetWidth(prevBuffer)
        let height = CVPixelBufferGetHeight(prevBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(prevBuffer)
        
        guard let prevBase = CVPixelBufferGetBaseAddress(prevBuffer),
              let currBase = CVPixelBufferGetBaseAddress(currBuffer) else { return 0 }
        
        let prevPtr = prevBase.assumingMemoryBound(to: UInt8.self)
        let currPtr = currBase.assumingMemoryBound(to: UInt8.self)
        
        // Check center column to find offset
        // We search how much 'curr' has moved UP compared to 'prev'
        // That means the top of 'curr' should match somewhere in 'prev'
        
        // Search range: look for the top row of CURR inside PREV.
        // It should be strictly below the top of PREV if we scrolled down.
        // PREV: [ A B C D ]
        // CURR: [ B C D E ]
        // We look for row 'B' (row 0 of CURR) inside PREV. It should be at row 1 of PREV. Offset = 1.
        
        let searchLimit = height / 3 // Don't search more than 1/3 screen scroll per frame
        let centerX = width / 2
        let step = 4 // Subsampling for speed
        
        // We will match a block of lines for robustness
        let blockHeight = 20
        
        for y in 1..<searchLimit {
             if matchRows(yInPrev: y, yInCurr: 0, height: blockHeight, width: width, centerX: centerX, prevPtr: prevPtr, currPtr: currPtr, bytesPerRow: bytesPerRow) {
                 return y
             }
        }
        
        return 0
    }
    
    private func matchRows(yInPrev: Int, yInCurr: Int, height: Int, width: Int, centerX: Int, prevPtr: UnsafePointer<UInt8>, currPtr: UnsafePointer<UInt8>, bytesPerRow: Int) -> Bool {
        // Compare a block of rows
        for h in 0..<height {
            // Compare a horizontal strip in the middle
            // Just comparing 50 pixels in the center for speed
            for x in (centerX - 25)..<(centerX + 25) {
                let prevIdx = (yInPrev + h) * bytesPerRow + x * 4 // Assuming BGRA
                let currIdx = (yInCurr + h) * bytesPerRow + x * 4
                
                // Compare R, G, B. Ignore A.
                let diff = abs(Int(prevPtr[prevIdx]) - Int(currPtr[currIdx])) +
                           abs(Int(prevPtr[prevIdx+1]) - Int(currPtr[currIdx+1])) +
                           abs(Int(prevPtr[prevIdx+2]) - Int(currPtr[currIdx+2]))
                
                if diff > 10 { // Threshold for compression noise
                    return false
                }
            }
        }
        return true
    }
    
    // Crops fixed UI (Header/Footer) and returns a UIImage
    func processAndCrop(buffer: CVPixelBuffer) -> UIImage? {
        let ciImage = CIImage(cvPixelBuffer: buffer)
        let width = CGFloat(CVPixelBufferGetWidth(buffer))
        let height = CGFloat(CVPixelBufferGetHeight(buffer))
        
        let topCut = height * topCutHeightRatio
        let bottomCut = height * bottomCutHeightRatio
        let cropRect = CGRect(x: 0, y: bottomCut, width: width, height: height - topCut - bottomCut)
        
        // Note: CIImage origin is bottom-left, but UIKit is top-left.
        // CIImage cropping usually takes coordinates in its own space.
        // Actually for screen coordinate parity, it's easier to use CGImage.
        
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }
        
        // Crop using CoreGraphics (Origin is Top-Left for CGImageCreateWithImageInRect?? No, it varies.)
        // Let's do a safe crop based on image logic.
        
        let unsafeCropRect = CGRect(x: 0, y: topCut, width: width, height: height - topCut - bottomCut)
        
        guard let croppedCG = cgImage.cropping(to: unsafeCropRect) else { return nil }
        
        return UIImage(cgImage: croppedCG)
    }
}
