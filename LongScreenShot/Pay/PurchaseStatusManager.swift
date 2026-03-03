//
//  PurchaseStatusManager.swift
//  RescueScreen
//
//  Created by minzhe on 2026/1/7.
//

import Foundation

class PurchaseStatusManager {
    static let shared = PurchaseStatusManager()
    
    private let account = "purchase_status"
    private let trialExpirationAccount = "trial_expiration_ts"
    
    private init() {}
    
    // 检查是否已付费
    func isPurchased() -> Bool {
        guard let data = KeychainStore.shared.read(account: account) else {
            return false
        }
        
        guard let value = String(data: data, encoding: .utf8) else {
            return false
        }
        
        return value == "true"
    }
    
    // 设置付费状态
    func setPurchased(_ purchased: Bool) {
        let value = purchased ? "true" : "false"
        guard let data = value.data(using: .utf8) else {
            return
        }

        KeychainStore.shared.upsert(account: account, data: data)
    }

    // MARK: - Trial Expiration (Keychain)

    /// 确保 Keychain 中存在试用过期时间；不存在则按“首次安装/首次启动时间 + 7 天”写入。
    @discardableResult
    func ensureTrialExpirationDate() -> Date {
        if let existing = readTrialExpirationDate() {
            return existing
        }

        let expiration = Date().addingTimeInterval(7 * 24 * 60 * 60)
        setTrialExpirationDate(expiration)
        return expiration
    }

    /// 当前是否已超过试用期（未设置时会自动初始化）。
    func isTrialExpired(now: Date = Date()) -> Bool {
        let expiration = ensureTrialExpirationDate()
        return now > expiration
    }

    private func readTrialExpirationDate() -> Date? {
        guard let data = KeychainStore.shared.read(account: trialExpirationAccount),
              let value = String(data: data, encoding: .utf8),
              let ts = TimeInterval(value) else {
            return nil
        }
        return Date(timeIntervalSince1970: ts)
    }

    func setTrialExpirationDate(_ date: Date) {
        let tsString = String(date.timeIntervalSince1970)
        guard let data = tsString.data(using: .utf8) else { return }
        KeychainStore.shared.upsert(account: trialExpirationAccount, data: data)
    }
}
