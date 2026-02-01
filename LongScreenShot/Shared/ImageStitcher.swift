import Foundation
import UIKit

class ImageStitcher {
    static func stitch(images: [UIImage]) -> UIImage? {
        guard images.count >= 2 else {
            print("Need at least 2 images to stitch.")
            return images.first
        }
        
        var cropRects: [CGRect] = []
        
        // We need to determine the "valid range" for each image.
        // Img 0: [0 ... CutBottom]
        // Img i: [CutTop ... CutBottom]
        // Img N: [CutTop ... Height]
        
        var validRanges: [(start: Int, end: Int)] = []
        for img in images {
            let h = Int(img.size.height * img.scale) // Work in pixels
            validRanges.append((0, h))
        }
        
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
                if confidence > 0.2 && cutPointInImg1 > 0 && cutPointInImg1 < Int(img1.size.height * img1.scale) {
                    
                    // Logic Update:
                    // matchYInImg2 is the "Top" of the overlapping content in Img2.
                    // This means 0...matchYInImg2 in Img2 is "Header" or "Top Overlap that didn't match".
                    // The User wants to remove this Top part of Img2.
                    
                    let cutTop2 = matchYInImg2
                    
                    // To stitch seamlessly, Img1 must end where Img2 starts.
                    // Img2 starts at matchYInImg2.
                    // Corresponding point in Img1 = matchYInImg2 + Shift(offsetY).
                    // Wait, Shift = Y1 - Y2.
                    // Y1 = Y2 + Shift.
                    // So Img1 Point = cutTop2 + cutPointInImg1(which is Shift).
                    // Actually my wrapper returns 'offsetY' as the Shift.
                    // So cutBottom1 = cutTop2 + cutPointInImg1.
                    
                    // Safety:
                    let calculatedCutBottom1 = cutTop2 + cutPointInImg1
                    let cutBottom1 = min(calculatedCutBottom1, Int(img1.size.height * img1.scale))
                    
                    // Let's output these values.
                    validRanges[i].end = cutBottom1
                    validRanges[i+1].start = cutTop2
                    
                    print("  -> Cutting Img\(i) Bottom at: \(cutBottom1)")
                    print("  -> Cutting Img\(i+1) Top at: \(cutTop2)")
                    
                } else {
                    print("Low confidence or invalid cut point for pair \(i)->\(i+1).")
                }
            } else {
                print("No overlap found for pair \(i)->\(i+1).")
            }
        }
        
        // Now calculate total height and draw
        guard let firstCG = images[0].cgImage else { return nil }
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
        
        if totalHeight <= 0 { return nil }
        
        let totalSize = CGSize(width: CGFloat(width), height: CGFloat(totalHeight))
        
        // Use UIGraphicsBeginImageContextWithOptions with scale 1.0 to work in "Pixels" as "Points".
        // This ensures (0,0) is Top-Left, eliminating coordinate confusion.
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
