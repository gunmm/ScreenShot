//
//  PurchaseManager.swift
//  RescueScreen
//
//  Created by minzhe on 2026/1/7.
//

import Foundation
import StoreKit
import UIKit

class PurchaseManager: NSObject {
    static let shared = PurchaseManager()
    
    // 商品ID
    private let productId = "com.syl.LongScreenShot.lifelong"
    
    // 付费状态管理器
    private let purchaseStatusManager = PurchaseStatusManager.shared
    
    // 支付完成回调
    private var purchaseCompletion: ((Bool) -> Void)?
    
    private override init() {
        super.init()
        // 监听支付事务
        SKPaymentQueue.default().add(self)
    }
    
    deinit {
        SKPaymentQueue.default().remove(self)
    }
    
    // 检查是否已付费
    func isPurchased() -> Bool {
        return purchaseStatusManager.isPurchased()
    }
    
    // 请求支付
    func requestPurchase(completion: @escaping (Bool) -> Void) {
        guard !isPurchased() else {
            // 如果已付费，直接返回成功
            completion(true)
            return
        }
        
        // 检查是否可以发起支付
        guard SKPaymentQueue.canMakePayments() else {
            DispatchQueue.main.async {
                self.showAlert(title: "无法支付", message: "您的设备不支持应用内购买")
            }
            completion(false)
            return
        }
        
        purchaseCompletion = completion
        
        // 请求商品信息
        let request = SKProductsRequest(productIdentifiers: [productId])
        request.delegate = self
        request.start()
    }
    
    // 恢复购买
    func restorePurchases(completion: @escaping (Bool) -> Void) {
        purchaseCompletion = completion
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
    
    private func showAlert(title: String, message: String) {
        DispatchQueue.main.async {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let rootViewController = windowScene.windows.first?.rootViewController else {
                return
            }
            
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "确定", style: .default))
            
            // 找到最顶层的视图控制器
            var presentedVC = rootViewController
            while let presented = presentedVC.presentedViewController {
                presentedVC = presented
            }
            presentedVC.present(alert, animated: true)
        }
    }
}

// MARK: - SKProductsRequestDelegate
extension PurchaseManager: SKProductsRequestDelegate {
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        guard let product = response.products.first else {
            DispatchQueue.main.async {
                self.showAlert(title: "支付失败", message: "无法获取商品信息")
            }
            purchaseCompletion?(false)
            purchaseCompletion = nil
            return
        }
        
        // 发起支付
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
    }
    
    func request(_ request: SKRequest, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.showAlert(title: "支付失败", message: error.localizedDescription)
        }
        purchaseCompletion?(false)
        purchaseCompletion = nil
    }
}

// MARK: - SKPaymentTransactionObserver
extension PurchaseManager: SKPaymentTransactionObserver {
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased:
                // 支付成功
                handlePurchaseSuccess(transaction: transaction)
                queue.finishTransaction(transaction)
                
            case .failed:
                // 支付失败
                handlePurchaseFailure(transaction: transaction)
                queue.finishTransaction(transaction)
                
            case .restored:
                // 恢复购买
                handlePurchaseRestored(transaction: transaction)
                queue.finishTransaction(transaction)
                
            case .deferred, .purchasing:
                // 支付中，不做处理
                break
                
            @unknown default:
                break
            }
        }
    }
    
    func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        // 恢复购买完成
        if purchaseStatusManager.isPurchased() {
            purchaseCompletion?(true)
        } else {
            DispatchQueue.main.async {
                self.showAlert(title: "恢复购买", message: "未找到可恢复的购买记录")
            }
            purchaseCompletion?(false)
        }
        purchaseCompletion = nil
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
        DispatchQueue.main.async {
            self.showAlert(title: "恢复购买失败", message: error.localizedDescription)
        }
        purchaseCompletion?(false)
        purchaseCompletion = nil
    }
    
    private func handlePurchaseSuccess(transaction: SKPaymentTransaction) {
        // 验证商品ID
        guard transaction.payment.productIdentifier == productId else {
            purchaseCompletion?(false)
            purchaseCompletion = nil
            return
        }
        
        // 更新付费状态
        purchaseStatusManager.setPurchased(true)
        
//        DispatchQueue.main.async {
//            self.showAlert(title: "支付成功", message: "感谢您的支持！")
//        }
        
        purchaseCompletion?(true)
        purchaseCompletion = nil
    }
    
    private func handlePurchaseFailure(transaction: SKPaymentTransaction) {
        if let error = transaction.error as? SKError {
            switch error.code {
            case .paymentCancelled:
                // 用户取消支付，不显示错误提示
                break
            default:
                DispatchQueue.main.async {
                    self.showAlert(title: "支付失败", message: error.localizedDescription)
                }
            }
        } else {
            DispatchQueue.main.async {
                self.showAlert(title: "支付失败", message: transaction.error?.localizedDescription ?? "未知错误")
            }
        }
        
        purchaseCompletion?(false)
        purchaseCompletion = nil
    }
    
    private func handlePurchaseRestored(transaction: SKPaymentTransaction) {
        // 验证商品ID
        guard transaction.original?.payment.productIdentifier == productId else {
            return
        }
        
        // 更新付费状态
        purchaseStatusManager.setPurchased(true)
    }
}
