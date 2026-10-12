//
//  Screen.swift
//  XunPengMachine
//
//  屏幕适配：以 iPhone 6/7/8 (375pt) 为基准等比缩放
//

import UIKit

enum Screen {
    static let width: CGFloat  = UIScreen.main.bounds.width
    static let height: CGFloat = UIScreen.main.bounds.height
    /// 基准宽度
    static let baseWidth: CGFloat = 375.0
    /// 缩放系数
    static let scale: CGFloat = width / baseWidth
    /// 状态栏高度
    static var statusBarH: CGFloat {
        if #available(iOS 13.0, *) {
            return UIApplication.shared.windows.first?.windowScene?.statusBarManager?.statusBarFrame.height ?? 20
        }
        return 20
    }
    /// 导航栏高度
    static let navBarH: CGFloat = 44
    /// 顶部安全高度（状态栏+导航）
    static var topSafeH: CGFloat { statusBarH + navBarH }
    /// 底部安全高度
    static var bottomSafeH: CGFloat {
        if #available(iOS 13.0, *) {
            return UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 0
        }
        return 0
    }
    /// TabBar 高度
    static var tabBarH: CGFloat { 49 + bottomSafeH }
}

/// 等比适配 CGFloat
extension CGFloat {
    var fit: CGFloat { self * Screen.scale }
}

/// 等比适配 Int/Double
extension Int {
    var fit: CGFloat { CGFloat(self) * Screen.scale }
}
extension Double {
    var fit: CGFloat { CGFloat(self) * Screen.scale }
}
