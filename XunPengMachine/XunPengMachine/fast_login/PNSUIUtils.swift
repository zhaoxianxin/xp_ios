//
//  PNSUIUtils.swift
//  ATAuthSceneDemoSwift
//
//  Created by lyz on 2026/1/28.
//  Copyright © 2020-2026. All rights reserved.
//

import UIKit

/// UI 相关工具类
class PNSUIUtils {
    
    // MARK: - View Controller
    
    /// 获取当前最顶层的 ViewController
    /// - Parameter rootViewController: 根视图控制器（默认为 keyWindow 的 rootViewController）
    /// - Returns: 最顶层的 ViewController
    static func topMostViewController(from rootViewController: UIViewController? = nil) -> UIViewController {
        let root = rootViewController ?? currentKeyWindow?.rootViewController
        guard let root = root else {
            return UIViewController()
        }
        
        var top = root
        while let presented = top.presentedViewController {
            top = presented
        }
        return top
    }
    
    /// 获取当前 keyWindow（兼容 iOS 13+）
    private static var currentKeyWindow: UIWindow? {
        if #available(iOS 13.0, *) {
            return UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first { $0.isKeyWindow }
        }
        return UIApplication.shared.keyWindow
    }
    
    // MARK: - Validation
    
    /// 验证手机号格式
    /// - Parameter phoneNumber: 手机号字符串
    /// - Returns: 是否有效
    static func isValidPhoneNumber(_ phoneNumber: String) -> Bool {
        let phoneRegex = "^1[3-9]\\d{9}$"
        let phonePredicate = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
        return phonePredicate.evaluate(with: phoneNumber)
    }
    
    // MARK: - Alert
    
    /// 显示提示框
    /// - Parameters:
    ///   - title: 标题
    ///   - message: 消息内容
    ///   - viewController: 展示的控制器
    ///   - confirmTitle: 确认按钮标题
    ///   - completion: 完成回调
    static func showAlert(
        title: String,
        message: String,
        on viewController: UIViewController?,
        confirmTitle: String = "确定",
        completion: (() -> Void)? = nil
    ) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: confirmTitle, style: .default) { _ in
            completion?()
        })
        viewController?.present(alert, animated: true)
    }
    
    // MARK: - Toast
    
    /// 显示 Toast 提示
    /// - Parameters:
    ///   - message: 提示消息
    ///   - view: 展示的视图
    ///   - duration: 持续时间
    static func showToast(_ message: String, on view: UIView, duration: TimeInterval = 2.0) {
        // TODO: 实现 Toast 展示逻辑
        print("Toast: \(message)")
    }
}
