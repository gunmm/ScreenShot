import Foundation
import CloudKit
import UIKit

class CloudKitManager {
    static let shared = CloudKitManager()
    
    private var hardwareModel: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        return machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
    }
    
    func uploadFeedback(message: String, completion: @escaping (Bool, Error?) -> Void) {
        let record = CKRecord(recordType: "UserFeedback")
        record["message"] = message as CKRecordValue
        record["deviceModel"] = hardwareModel as CKRecordValue
        record["systemVersion"] = UIDevice.current.systemVersion as CKRecordValue
        record["userId"] = (UIDevice.current.identifierForVendor?.uuidString ?? "Unknown") as CKRecordValue
        
        let logURL = AppLogger.shared.currentLogFileURL
        if FileManager.default.fileExists(atPath: logURL.path) {
            let asset = CKAsset(fileURL: logURL)
            record["logFile"] = asset
        }
        
        let container = CKContainer.default()
        let database = container.publicCloudDatabase
        
        database.save(record) { savedRecord, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(false, error)
                } else {
                    completion(true, nil)
                }
            }
        }
    }
}
