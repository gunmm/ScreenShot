import Foundation
import CloudKit
import UIKit

class CloudKitManager {
    static let shared = CloudKitManager()
    
    private let autoLogUploadRecordType = "AutoLogUpload"
    private let userFeedbackRecordType = "UserFeedback"
    private let autoLogUploadMessage = "save_success_auto_upload"
    private let lastAutoLogUploadAtKey = "lastAutoLogUploadAt"
    private let autoLogUploadInterval: TimeInterval = 24 * 60 * 60
    private let workQueue = DispatchQueue(label: "com.syl.LongScreenShot.CloudKitManager", qos: .utility)
    
    private var hardwareModel: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        return machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
    }
    
    
    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown"
    }

    private var buildVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "Unknown"
    }

    private var database: CKDatabase {
        CKContainer.default().publicCloudDatabase
    }

    
    func uploadFeedback(message: String, completion: @escaping (Bool, Error?) -> Void) {
        let record = makeRecord(recordType: userFeedbackRecordType, message: message, logFileURL: AppLogger.shared.currentLogFileURL)
        save(record: record) { success, error in
            DispatchQueue.main.async {
                completion(success, error)
            }
        }
    }

    func uploadAutoLogIfNeeded() {
        let now = Date()
        if let lastUploadAt = UserDefaults.standard.object(forKey: lastAutoLogUploadAtKey) as? Date,
           now.timeIntervalSince(lastUploadAt) < autoLogUploadInterval {
            AppLogger.shared.log("uploadAutoLogIfNeeded: skipped, last upload at \(lastUploadAt)")
            return
        }

        AppLogger.shared.log("uploadAutoLogIfNeeded: scheduling upload attempt")
        workQueue.async { [self] in
            let snapshotURL = makeLogSnapshotURL()
            let record = makeRecord(recordType: autoLogUploadRecordType, message: autoLogUploadMessage, logFileURL: snapshotURL)

            save(record: record) { success, error in
                if success {
                    UserDefaults.standard.set(now, forKey: self.lastAutoLogUploadAtKey)
                    AppLogger.shared.log("uploadAutoLogIfNeeded: upload succeeded")
                } else {
                    AppLogger.shared.log("uploadAutoLogIfNeeded: upload failed: \(error?.localizedDescription ?? "Unknown")")
                }

                if let snapshotURL {
                    do {
                        try FileManager.default.removeItem(at: snapshotURL)
                        AppLogger.shared.log("uploadAutoLogIfNeeded: removed snapshot \(snapshotURL.lastPathComponent)")
                    } catch {
                        AppLogger.shared.log("uploadAutoLogIfNeeded: failed to remove snapshot: \(error.localizedDescription)")
                    }
                }
            }
        }
    }

    private func makeRecord(recordType: String, message: String, logFileURL: URL?) -> CKRecord {
        let record = CKRecord(recordType: recordType)
        record["message"] = message as CKRecordValue
        record["deviceModel"] = hardwareModel as CKRecordValue
        record["systemVersion"] = UIDevice.current.systemVersion as CKRecordValue
        record["appVersion"] = appVersion as CKRecordValue
        record["buildVersion"] = buildVersion as CKRecordValue
        record["userId"] = (UIDevice.current.identifierForVendor?.uuidString ?? "Unknown") as CKRecordValue

        if let logFileURL, FileManager.default.fileExists(atPath: logFileURL.path) {
            record["logFile"] = CKAsset(fileURL: logFileURL)
        }

        return record
    }

    private func save(record: CKRecord, completion: @escaping (Bool, Error?) -> Void) {
        database.save(record) { _, error in
            if let error {
                completion(false, error)
            } else {
                completion(true, nil)
            }
        }
    }

    private func makeLogSnapshotURL() -> URL? {
        let sourceURL = AppLogger.shared.currentLogFileURL
        guard FileManager.default.fileExists(atPath: sourceURL.path) else {
            AppLogger.shared.log("makeLogSnapshotURL: source log file missing")
            return nil
        }

        let snapshotURL = FileManager.default.temporaryDirectory.appendingPathComponent("auto_log_\(UUID().uuidString).log")

        do {
            try FileManager.default.copyItem(at: sourceURL, to: snapshotURL)
            AppLogger.shared.log("makeLogSnapshotURL: created snapshot \(snapshotURL.lastPathComponent)")
            return snapshotURL
        } catch {
            AppLogger.shared.log("makeLogSnapshotURL: failed to create snapshot: \(error.localizedDescription)")
            return nil
        }
    }
}
