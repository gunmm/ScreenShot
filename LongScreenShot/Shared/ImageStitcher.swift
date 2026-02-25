import Foundation
import UIKit

class ImageStitcher {
    
    // Backwards compatible method
    static func stitch(images: [UIImage]) -> UIImage? {
        guard images.count >= 2 else {
            print("Need at least 2 images to stitch.")
            return images.first
        }
        
        let validRanges = calculateValidRanges(for: images)
        return stitch(images: images, withRanges: validRanges)
    }
    
    // Split 1: Calculation
    static func calculateValidRanges(for images: [UIImage]) -> [(start: Int, end: Int)] {
        var validRanges: [(start: Int, end: Int)] = []
        for img in images {
            let h = Int(img.size.height * img.scale) // Work in pixels
            validRanges.append((0, h))
        }
        
        guard images.count >= 2 else { return validRanges }
        
        for i in 0..<(images.count - 1) {
            let img1 = images[i]
            let img2 = images[i+1]
            
            // Call OpenCV wrapper
            let result = OpenCVWrapper.findOverlapBetween(img1, and: img2)
            
            // Expected keys: "offsetY" (CutPointInImg1), "confidence", "matchYInImg2"
            if let cutPointNum = result["offsetY"] as? NSNumber,
               let confidenceNum = result["confidence"] as? NSNumber,
               let matchYInImg2Num = result["matchYInImg2"] as? NSNumber {
                
                let cutPointInImg1 = cutPointNum.intValue
                let confidence = confidenceNum.doubleValue
                let matchYInImg2 = matchYInImg2Num.intValue
                
                print("Match Pair \(i)->\(i+1): Conf=\(confidence), CutPointInImg1=\(cutPointInImg1), MinMatchY2=\(matchYInImg2)")

                // ORB confidence check
                if confidence > 0.3 && cutPointInImg1 >= 0 && cutPointInImg1 < Int(img1.size.height * img1.scale) {
                    let cutTop2 = matchYInImg2
                    let calculatedCutBottom1 = cutTop2 + cutPointInImg1
                    let cutBottom1 = min(calculatedCutBottom1, Int(img1.size.height * img1.scale))
                    
                    validRanges[i].end = cutBottom1
                    validRanges[i+1].start = cutTop2
                    
                    print("  -> Cutting Img\(i) Bottom at: \(cutBottom1)")
                    print("  -> Cutting Img\(i+1) Top at: \(cutTop2)")
                } else {
                    print("Low confidence or invalid cut point for pair \(i)->\(i+1). Appending full image.")
                }
            } else {
                print("No overlap found for pair \(i)->\(i+1).")
            }        
        }
        
        return validRanges
    }
    
    // Split 2: Drawing
    static func stitch(images: [UIImage], withRanges inputRanges: [(start: Int, end: Int)]) -> UIImage? {
        guard !images.isEmpty else { return nil }
        if images.count == 1 { return images.first }
        var validRanges = inputRanges
        
        // Post-processing: Handle Negative Heights (Redundant Images).
        for i in 1..<validRanges.count {
            let start = validRanges[i].start
            let end = validRanges[i].end
            
            if end < start {
                let overlap = start - end
                print("Img\(i) is redundant (Negative Height: \(end - start)). Propagating trim of \(overlap)px to previous images.")
                
                // 1. Collapse current image to size 0
                validRanges[i].start = end 
                
                // 2. Propagate 'overlap' backwards
                var debt = overlap
                var prevIdx = i - 1
                
                while debt > 0 && prevIdx >= 0 {
                    let pStart = validRanges[prevIdx].start
                    let pEnd = validRanges[prevIdx].end
                    let pHeight = pEnd - pStart
                    
                    if pHeight > debt {
                        // Current Prev has enough height to absorb the debt
                        validRanges[prevIdx].end = pEnd - debt
                        debt = 0
                    } else {
                        // Current Prev is smaller than debt. Collapse it and carry over.
                        if pHeight > 0 {
                            debt -= pHeight
                            validRanges[prevIdx].end = pStart
                        }
                        prevIdx -= 1
                    }
                }
            }
        }
        
        // Now calculate total height and draw
        guard let firstCG = images.first?.cgImage else { return nil }
        let width = firstCG.width
        var totalHeight = 0
        
        print("--- Final Stitching Ranges ---")
        for (index, range) in validRanges.enumerated() {
            let h = range.end - range.start
            print("Img\(index): Range [\(range.start) - \(range.end)], Height: \(h)")
            if h > 0 {
                totalHeight += h
            }
        }
        
        if totalHeight <= 0 { return nil }
        
        let totalSize = CGSize(width: CGFloat(width), height: CGFloat(totalHeight))
        
        // Use UIGraphicsBeginImageContextWithOptions with scale 1.0 to work in "Pixels" as "Points".
        UIGraphicsBeginImageContextWithOptions(totalSize, false, 1.0)
        
        var currentY: CGFloat = 0
        for (index, img) in images.enumerated() {
            guard let cg = img.cgImage else { continue }
            
            let range = validRanges[index]
            let h = range.end - range.start
            if h <= 0 { continue }
            
            let cropRect = CGRect(x: 0, y: range.start, width: width, height: h)
            if let cropped = cg.cropping(to: cropRect) {
                // Determine rect in our context
                let drawRect = CGRect(x: 0, y: currentY, width: CGFloat(width), height: CGFloat(h))
                
                // Draw using UIKit wrapper to handle orientation automatically
                let cropImg = UIImage(cgImage: cropped)
                cropImg.draw(in: drawRect)
                
                currentY += CGFloat(h)
            }
        }
        
        let resultImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        // Restore the original scale if needed
        if let cgResult = resultImage?.cgImage {
            return UIImage(cgImage: cgResult, scale: images[0].scale, orientation: .up)
        }
        
        return resultImage
    }
}
