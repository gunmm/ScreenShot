import Foundation

struct AppGroupConfig {
    // MARK: - Configuration
    // TODO: USER_ACTION - Replace with your actual App Group ID
    static let appGroupIdentifier = "group.gunmm.LongScreenShot"
    
    // MARK: - Paths
    static var sharedContainerURL: URL? {
        return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)
    }
    
    static var chunkDirectoryURL: URL? {
        return sharedContainerURL?.appendingPathComponent("ScreenChunks", isDirectory: true)
    }
    
    // MARK: - Setup
    static func ensureChunkDirectoryExists() {
        guard let url = chunkDirectoryURL else { return }
        if !FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
        }
    }
    
    static func clearChunkDirectory() {
        guard let url = chunkDirectoryURL else { return }
        try? FileManager.default.removeItem(at: url)
        ensureChunkDirectoryExists()
    }
}
