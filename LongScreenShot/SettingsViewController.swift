//
//  SettingsViewController.swift
//  Microphone
//
//  Created by minzhe on 2026/1/11.
//

import UIKit

class SettingsViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = NSLocalizedString("设置", comment: "Settings title")
        
        addPremiumButton()
        
        // 导航栏关闭按钮
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(closeButtonTapped)
        )
    }
    
    @objc private func closeButtonTapped() {
        dismiss(animated: true)
    }
    
    // MARK: - Premium Button
    
    private lazy var premiumButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(NSLocalizedString("放弃免费使用时间", comment: "Give up trial time button"), for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14)
        button.tintColor = .systemRed
        button.addTarget(self, action: #selector(premiumButtonTapped), for: .touchUpInside)
        return button
    }()
    
    @objc private func premiumButtonTapped() {
        PurchaseStatusManager.shared.setTrialExpirationDate(Date())
        
        let alert = UIAlertController(title: NSLocalizedString("提示", comment: "Alert title prompt"), message: NSLocalizedString("免费试用已结束，当前状态已重置为过期", comment: "Trial ended message"), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("确定", comment: "OK action"), style: .default))
        present(alert, animated: true)
    }

    // Adding button to setupUI
    func addPremiumButton() {
        view.addSubview(premiumButton)
        view.addSubview(restoreButton)
        
        premiumButton.translatesAutoresizingMaskIntoConstraints = false
        restoreButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            premiumButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            premiumButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            restoreButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            restoreButton.topAnchor.constraint(equalTo: premiumButton.bottomAnchor, constant: 10)
        ])
    }
    
    // MARK: - Restore Button
    
    private lazy var restoreButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(NSLocalizedString("恢复购买", comment: "Restore purchase button"), for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14)
        button.tintColor = .systemBlue
        button.addTarget(self, action: #selector(restoreButtonTapped), for: .touchUpInside)
        return button
    }()
    
    @objc private func restoreButtonTapped() {
        // 显示加载提示
        let alert = UIAlertController(title: NSLocalizedString("正在恢复...", comment: "Restoring purchase loading"), message: nil, preferredStyle: .alert)
        present(alert, animated: true)
        
        PurchaseManager.shared.restorePurchases { [weak self] success in
            DispatchQueue.main.async {
                alert.dismiss(animated: true) {
                    if success {
                        let resultAlert = UIAlertController(title: NSLocalizedString("恢复成功", comment: "Restore success title"), message: NSLocalizedString("您的购买已恢复", comment: "Restore success message"), preferredStyle: .alert)
                        resultAlert.addAction(UIAlertAction(title: NSLocalizedString("确定", comment: "OK action"), style: .default))
                        self?.present(resultAlert, animated: true)
                    } else {
                        // 失败的情况 PurchaseManager 内部通常会弹窗提示，这里为了保险起见，如果 PurchaseManager 没有弹窗，用户界面也不会卡住
                    }
                }
            }
        }
    }
}
