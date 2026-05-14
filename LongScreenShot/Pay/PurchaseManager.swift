//
//  PurchaseManager.swift
//  RescueScreen
//
//  Created by minzhe on 2026/1/7.
//

import Foundation
import StoreKit
import UIKit

extension Notification.Name {
    static let purchaseStatusDidChange = Notification.Name("PurchaseStatusDidChange")
}

struct PurchaseProductInfo {
    let localizedPrice: String
}

class PurchaseManager: NSObject {
    static let shared = PurchaseManager()
    
    // 商品ID
    private let productId = "com.syl.LongScreenShot.lifelong"
    
    // 付费状态管理器
    private let purchaseStatusManager = PurchaseStatusManager.shared
    
    // 支付完成回调
    private var purchaseCompletion: ((Bool) -> Void)?
    private var productRequest: SKProductsRequest?
    private var productCompletions: [(SKProduct?) -> Void] = []
    private var cachedProduct: SKProduct?
    
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

    var currentProductInfo: PurchaseProductInfo? {
        guard let product = cachedProduct else {
            return nil
        }

        return PurchaseProductInfo(localizedPrice: localizedPrice(for: product))
    }

    func loadProductInfo(completion: @escaping (PurchaseProductInfo?) -> Void) {
        fetchProduct { [weak self] product in
            guard let self = self, let product = product else {
                completion(nil)
                return
            }

            completion(PurchaseProductInfo(localizedPrice: self.localizedPrice(for: product)))
        }
    }
    
    // 请求支付
    func requestPurchase(completion: @escaping (Bool) -> Void) {
        AppLogger.shared.log("requestPurchase: Starting purchase request for \(productId)")
        guard !isPurchased() else {
            // 如果已付费，直接返回成功
            AppLogger.shared.log("requestPurchase: Already purchased, returning true")
            completion(true)
            return
        }
        
        // 检查是否可以发起支付
        guard SKPaymentQueue.canMakePayments() else {
            AppLogger.shared.log("requestPurchase: Device cannot make payments")
            DispatchQueue.main.async {
                self.showAlert(title: NSLocalizedString("无法支付", comment: "Purchase unavailable title"), message: NSLocalizedString("您的设备不支持应用内购买", comment: "Purchase unavailable message"))
            }
            completion(false)
            return
        }
        
        purchaseCompletion = completion

        fetchProduct { [weak self] product in
            guard let self = self else { return }
            guard let product = product else {
                AppLogger.shared.log("requestPurchase: Failed to retrieve product info before purchase")
                DispatchQueue.main.async {
                    self.showAlert(title: NSLocalizedString("支付失败", comment: "Purchase failed title"), message: NSLocalizedString("无法获取商品信息", comment: "Purchase failed product info message"))
                }
                self.purchaseCompletion?(false)
                self.purchaseCompletion = nil
                return
            }

            AppLogger.shared.log("requestPurchase: Successfully loaded product \(product.productIdentifier). Adding payment.")
            let payment = SKPayment(product: product)
            SKPaymentQueue.default().add(payment)
        }
    }
    
    // 恢复购买
    func restorePurchases(completion: @escaping (Bool) -> Void) {
        AppLogger.shared.log("restorePurchases: Requesting restore completed transactions")
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
            alert.addAction(UIAlertAction(title: NSLocalizedString("确定", comment: "Purchase alert confirmation"), style: .default))
            
            // 找到最顶层的视图控制器
            var presentedVC = rootViewController
            while let presented = presentedVC.presentedViewController {
                presentedVC = presented
            }
            presentedVC.present(alert, animated: true)
        }
    }

    private func fetchProduct(completion: @escaping (SKProduct?) -> Void) {
        if let cachedProduct {
            completion(cachedProduct)
            return
        }

        productCompletions.append(completion)

        guard productRequest == nil else {
            return
        }

        let request = SKProductsRequest(productIdentifiers: [productId])
        request.delegate = self
        productRequest = request
        request.start()
    }

    private func completeProductRequest(with product: SKProduct?) {
        if let product {
            cachedProduct = product
        }

        let completions = productCompletions
        productCompletions.removeAll()
        productRequest = nil
        completions.forEach { $0(product) }
    }

    private func localizedPrice(for product: SKProduct) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = product.priceLocale
        return formatter.string(from: product.price) ?? product.price.stringValue
    }

    private func notifyPurchaseStatusDidChange() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .purchaseStatusDidChange, object: nil)
        }
    }
}

// MARK: - SKProductsRequestDelegate
extension PurchaseManager: SKProductsRequestDelegate {
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        guard let product = response.products.first else {
            AppLogger.shared.log("productsRequest: Failed to retrieve product info (array empty)")
            completeProductRequest(with: nil)
            return
        }

        AppLogger.shared.log("productsRequest: Successfully loaded product \(product.productIdentifier)")
        completeProductRequest(with: product)
    }
    
    func request(_ request: SKRequest, didFailWithError error: Error) {
        AppLogger.shared.log("productsRequest: App Store request failed with error: \(error.localizedDescription)")
        completeProductRequest(with: nil)
    }
}

// MARK: - SKPaymentTransactionObserver
extension PurchaseManager: SKPaymentTransactionObserver {
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased:
                AppLogger.shared.log("paymentQueue: Transaction state = .purchased for \(transaction.payment.productIdentifier)")
                // 支付成功
                handlePurchaseSuccess(transaction: transaction)
                queue.finishTransaction(transaction)
                
            case .failed:
                AppLogger.shared.log("paymentQueue: Transaction state = .failed for \(transaction.payment.productIdentifier), error: \(transaction.error?.localizedDescription ?? "null")")
                // 支付失败
                handlePurchaseFailure(transaction: transaction)
                queue.finishTransaction(transaction)
                
            case .restored:
                AppLogger.shared.log("paymentQueue: Transaction state = .restored for \(transaction.payment.productIdentifier)")
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
        AppLogger.shared.log("paymentQueueRestoreCompletedTransactionsFinished: Finished traversing. isPurchased = \(purchaseStatusManager.isPurchased())")
        // 恢复购买完成
        if purchaseStatusManager.isPurchased() {
            purchaseCompletion?(true)
        } else {
            DispatchQueue.main.async {
                self.showAlert(title: NSLocalizedString("恢复购买", comment: "Restore purchase title"), message: NSLocalizedString("未找到可恢复的购买记录", comment: "Restore purchase not found"))
            }
            purchaseCompletion?(false)
        }
        purchaseCompletion = nil
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
        AppLogger.shared.log("restoreCompletedTransactionsFailedWithError: \(error.localizedDescription)")
        DispatchQueue.main.async {
            self.showAlert(title: NSLocalizedString("恢复购买失败", comment: "Restore purchase failed title"), message: error.localizedDescription)
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
        notifyPurchaseStatusDidChange()
        
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
                    self.showAlert(title: NSLocalizedString("支付失败", comment: "Purchase failed title"), message: error.localizedDescription)
                }
            }
        } else {
            DispatchQueue.main.async {
                self.showAlert(title: NSLocalizedString("支付失败", comment: "Purchase failed title"), message: transaction.error?.localizedDescription ?? NSLocalizedString("未知错误", comment: "Unknown purchase error"))
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
        notifyPurchaseStatusDidChange()
    }
}
