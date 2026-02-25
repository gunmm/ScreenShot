import UIKit

struct ChunkMetadata: Codable {
    let index: Int
    let offset: Int // Y offset from the previous chunk
    let filename: String
    let timestamp: TimeInterval
}

class ChunkManager {
    static let shared = ChunkManager()
    
    private init() {}

    func chunkCount() -> Int {
        guard let dir = AppGroupConfig.chunkDirectoryURL else { return 0 }
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)
            return fileURLs.count { $0.pathExtension.lowercased() == "jpg" }
        } catch {
            return 0
        }
    }
    
    func saveChunk(image: UIImage, index: Int) {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }
        guard let dir = AppGroupConfig.chunkDirectoryURL else { return }
        
        let filename = String(format: "chunk_%04d.jpg", index)
        let fileURL = dir.appendingPathComponent(filename)
        
        do {
            try data.write(to: fileURL)
            print("Saved chunk: \(filename)")
        } catch {
            print("Error saving chunk: \(error)")
        }
    }
    
    func loadAllChunks() -> [(image: UIImage, offset: Int)] {
        guard let dir = AppGroupConfig.chunkDirectoryURL else { return [] }
        
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)
            let imageFiles = fileURLs.filter { $0.pathExtension == "jpg" }
            
            // Sort by filename to ensure correct order (chunk_0000, chunk_0001...)
            let sortedFiles = imageFiles.sorted { $0.lastPathComponent < $1.lastPathComponent }
            
            var result: [(image: UIImage, offset: Int)] = []
            
            for url in sortedFiles {
                if let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
                    let filename = url.deletingPathExtension().lastPathComponent
                    let components = filename.components(separatedBy: "_")
                    if components.count >= 3, let offset = Int(components[2]) {
                        result.append((image, offset))
                    } else {
                         // Fallback for first frame or unknown format
                         result.append((image, 0))
                    }
                }
            }
            return result
        } catch {
            print("Error loading chunks: \(error)")
            return []
        }
    }
}
