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
                if confidence > 0.3 && cutPointInImg1 >= 0 && cutPointInImg1 < Int(img1.size.height * img1.scale) {
                    
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
                    print("Low confidence or invalid cut point for pair \(i)->\(i+1). Appending full image.")
                    // Fallback: Just append Img1 fully and start Img2 from 0??
                    // No. If detection fails, we assume they are continuous but we missed the join?
                    // Or they are just disjoint?
                    // Safest fallback for a "Screenshot" is usually that they follow each other.
                    // But if we missed the overlap, maybe we should just stack them.
                    
                    // Let's set Img1 end to its full height.
                    // And Img2 start to 0.
                    // This means Img1 + Img2 (Vertical Stack).
                    // BUT: This might duplicate content if there WAS overlap.
                    // However, duplicating is better than "Resetting to 0" which overlaps them entirely (Z-order) if range generation is wrong.
                    // Wait, validRanges controls the Y position in the FINAL canvas?
                    // No. validRanges controls WHICH PART of the image to use.
                    // The 'currentY' in drawing loop controls placement.
                    
                    // IF we default to: Img1 Use Full, Img2 Use Full.
                    // Img1: [0...H1]
                    // Img2: [0...H2]
                    // Then they will be drawn one after another.
                    // This results in Duplicate Content (the overlap is shown twice).
                    // This is the standard "Safe Fallback".
                    // The "Resetting to 0" issue the user saw ("Img4: Range [0 - 1059]")
                    // is actually correct: Img4 uses [0...Height].
                    // The problem is likely VISUAL in the result? 
                    // Ah, if Img4 starts at 0, that's fine.
                    // Maybe the user means Img4 appears "on top" of Img3?
                    // No, the drawing loop increments currentY.
                    
                    // User says: "Img4: Range [0 - 1059]... 4看着不对"
                    // If Img3->4 failed, Img3 is [CutTop ... Img3Height].
                    // Img4 is [0 ... Img4CutBottom].
                    // So we see Img3 Bottom + Img4 Top.
                    // The overlap is repeated.
                    // This is usually OBVIOUSLY wrong (duplicate content).
                    // Maybe user thinks it shouldn't "Start from 0"?
                    // Actually, if stitching works, Img4 usually starts at a "Top Cut" > 0 (to hide the overlap).
                    // If it starts at 0, it means we kept the header/overlap.
                    
                    // The User's previous issue "Img26... 0-997... 中间的图片不应该出现从头开始裁剪"
                    // implies they saw the top content of Img4 which should have been cut.
                    
                    // Since we can't find the cut point, we CAN'T cut it accurately.
                    // We have two choices:
                    // 1. Duplicate content (Current behavior).
                    // 2. Guess a cut? (Dangerous).
                    
                    // But wait, the user says "Img4... 4看着不对".
                    // Img3->4 failed. Conf=0.24.
                    // If we can't match, maybe we should assume a "Default Scroll"?
                    // No, that's dangerous.
                    
                    // Let's look at the failure: Conf=0.24.
                    // Maybe we can LOWER the threshold even more? 0.2?
                    // Or try to process the image differently (Equalize Hist, etc)?
                    
                    // For now, let's keep the fallback as is (Full Append), but maybe log it better?
                    // Actually, ImageStitcher doesn't change validRanges in the 'else' block.
                    // So they stay at default (0, H).
                    // So Img3 ends at H. Img4 starts at 0.
                    // Result: Duplicate overlap.
                    
                    // If the user says "Img4 Range [0-1059]" is WRONG, they probably see the duplication.
                    // They want it to be CUT.
                    // But we don't know where to cut.
                    
                    // Maybe we can try to guess "Median Shift of previous matches"?
                    // If most shifts are ~200px. We could guess 200px?
                    // Let's NOT guess blindly.
                    
                    // But wait. Template Matching FAILED (Conf=0.24).
                    // Img3->4.
                    
                    // Is it possible the overlap is just HUGE? Or very small?
                    // Let's leave it as Duplicate.
                    // But maybe the user's issue is Img4 is showing header?
                    // "中间的都是保留自己独有的部分，去掉和其他人重复的部分"
                    // "中间的图片不应该出现从头开始裁剪" -> Should start from CutPoint.
                    
                    // Proceed with "Duplicate is better than Missing", but I should tell the user
                    // that 3->4 failed.
                    
                    // Wait, I can try to use the *Best* match even if low confidence?
                    // Conf=0.24, Shift=10.
                    // Shift=10 means almost static.
                    // This is likely wrong if user scrolled.
                    
                    // Let's just log it.
                    // No code change here effectively changes the visual result for 3->4 unless I change logic.
                    // BUT, I can lower the ImageStitcher threshold to 0.2?
                    // Conf=0.24 > 0.2.
                    // Then it would accept Shift=10.
                    // If Shift=10 is wrong (actual scroll was 200), then we get a weird jump.
                    
                    // Let's stick with: If fail, Do nothing (Duplicate).
                    // But user is complaining.
                    // Maybe the issue is visual *discontinuity*?
                    
                    // Let's look at Step 75 Log carefully.
                    // Img3->4: Conf=0.24, Shift=10.51.
                    // Img2->3: Conf=0.85, Shift=150.
                    // Img4->5: Conf=0.88, Shift=230.
                    // The shift dropped to 10?
                    // This implies Img3 and Img4 are identical? Or we matched footer to header?
                    
                    // If Conf is low, we cannot trust Shift=10.
                    
                    // I will ADD a "Last Resort" - forcing a check with an even lower margin??
                    // Or using the "Previous Shift" as a hint?
                    
                    // Actually, let's just Lower the Threshold in ImageStitcher to 0.2
                    // AND ensure Template Matching is more robust.
                    // But Template Match was 0.24. That's very low. Means content is different.
                    // Maybe Img3 and Img4 just don't overlap??
                    
                    // I'll stick to modifying ImageStitcher to just Log this explicitly.
                    // The user's request "4看着不对" is because it wasn't cut.
                    // I can't cut it if I don't know where.
                }
            } else {
                print("No overlap found for pair \(i)->\(i+1).")
            }        
        }
        
        // Post-processing: Handle Negative Heights (Redundant Images).
        // If range.end < range.start, it means the "Top Cut" (from Prev) is below the "Bottom Cut" (from Next).
        // This implies the Prev image overlaps the Next image, fully covering the Current image.
        // We need to trim the Prev image to eliminate the duplication.
        
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
                        // (Wait, if pHeight is positive. If pHeight is already 0, we just skip)
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
