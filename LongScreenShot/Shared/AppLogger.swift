import Foundation

class AppLogger {
    static let shared = AppLogger()
    
    private let logFileURL: URL
    private let queue = DispatchQueue(label: "com.syl.LongScreenShot.AppLogger")
    
    init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        logFileURL = docs.appendingPathComponent("app_activity.log")
        
        // 如果日志过大跳过（1MB）
        if let attrs = try? FileManager.default.attributesOfItem(atPath: logFileURL.path),
           let size = attrs[.size] as? UInt64, size > 1024 * 1024 {
            try? FileManager.default.removeItem(at: logFileURL)
        }
    }
    
    func log(_ message: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        let timeString = formatter.string(from: Date())
        let formattedMessage = "[\(timeString)] \(message)\n"
        
        print(formattedMessage, terminator: "")
        
        queue.async {
            guard let data = formattedMessage.data(using: .utf8) else { return }
            if FileManager.default.fileExists(atPath: self.logFileURL.path) {
                if let fileHandle = try? FileHandle(forWritingTo: self.logFileURL) {
                    if #available(iOS 13.4, *) {
                        try? fileHandle.seekToEnd()
                        try? fileHandle.write(contentsOf: data)
                    } else {
                        fileHandle.seekToEndOfFile()
                        fileHandle.write(data)
                    }
                    try? fileHandle.close()
                }
            } else {
                try? data.write(to: self.logFileURL)
            }
        }
    }
    
    var currentLogFileURL: URL {
        return logFileURL
    }
}
