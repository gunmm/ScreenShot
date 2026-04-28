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
}
