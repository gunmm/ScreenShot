//
//  KeychainStore.swift
//  RescueScreen
//
//  Created by minzhe on 2026/1/13.
//

import Foundation
import Security

/// 简单的 Keychain KV 存储（Generic Password）。
/// 用于在卸载/重装后仍能保留少量关键数据（例如：付费状态、前三条历史等）。
final class KeychainStore {
    static let shared = KeychainStore()

    private let service = "com.syl.LongScreenShot"

    private init() {}

    func read(account: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess else { return nil }
        return result as? Data
    }

    /// 写入（存在则更新，不存在则添加）
    func upsert(account: String, data: Data) {
        if update(account: account, data: data) {
            return
        }
        add(account: account, data: data)
    }

    private func add(account: String, data: Data) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        SecItemAdd(query as CFDictionary, nil)
    }

    private func update(account: String, data: Data) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        let attributes: [String: Any] = [
            kSecValueData as String: data
        ]

        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        return status == errSecSuccess
    }
}

