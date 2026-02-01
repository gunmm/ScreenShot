import UIKit

class ImageOverlapCalculator {
    
    /// Entry point: Just extract features and log the last 100 rows.
    /// Completion returns empty array as we are only debugging now.
    static func calculateOverlaps(images: [UIImage], completion: @escaping ([CGRect]) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            
            for (index, image) in images.enumerated() {
                let feats = self.features(for: image)
                
                let count = feats.count
                if count == 0 {
                    print("Img[\(index)]: No features extracted.")
                    continue
                }
                
                // Get last 100 rows (or fewer if image is small)
                let suffixCount = min(200, count)
                let suffix = feats[(count - suffixCount)..<count]
                
                print("--- Img[\(index)] Last \(suffixCount) rows RGBA-Total-sums ---")
                print(Array(suffix))
                print("-------------------------------------------------")
            }
            
            // Return empty result as requested just for logging
            DispatchQueue.main.async {
                completion([])
            }
        }
    }
    
    /// Calculate the feature array: Sum of (R+G+B+A) for each row
    private static func features(for image: UIImage) -> [Int] {
        guard let cgImage = image.cgImage else { return [] }
        
        let width = cgImage.width
        let height = cgImage.height
        
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        let bitsPerComponent = 8
        
        var pixelData = [UInt8](repeating: 0, count: width * height * bytesPerPixel)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        guard let context = CGContext(data: &pixelData,
                                      width: width,
                                      height: height,
                                      bitsPerComponent: bitsPerComponent,
                                      bytesPerRow: bytesPerRow,
                                      space: colorSpace,
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue) else {
            return []
        }
        
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height)))
        
        var rowSums: [Int] = []
        rowSums.reserveCapacity(height)
        
        for y in 0..<height {
            var rowTotal = 0
            
            let rowOffset = y * bytesPerRow
            for x in 0..<width {
                let pixelIndex = rowOffset + x * bytesPerPixel
                
                let r = Int(pixelData[pixelIndex])
                let g = Int(pixelData[pixelIndex + 1])
                let b = Int(pixelData[pixelIndex + 2])
                let a = Int(pixelData[pixelIndex + 3])
                
                rowTotal += (r + g + b + a)
            }
            rowSums.append(rowTotal)
        }
        
        return rowSums
    }
}
