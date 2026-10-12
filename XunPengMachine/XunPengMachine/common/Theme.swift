//
//  Theme.swift
//  XunPengMachine
//
//  全局主题：颜色、字体统一管理，便于一键换肤
//

import UIKit

/// 主题颜色统一管理
enum AppColor {
    // 主色（导航栏 / 主按钮）
    static let navBar: UIColor      = UIColor(hex: 0x0076FF)
    static let primary: UIColor     = UIColor(hex: 0x0076FF)   // 蓝色按钮背景
    static let danger: UIColor      = UIColor(hex: 0xFF0000)   // 红色按钮
    static let price: UIColor       = UIColor(hex: 0xFF0000)   // 价格红

    // 文本
    static let textMain: UIColor    = UIColor(hex: 0x222222)
    static let textSub: UIColor     = UIColor(hex: 0x666666)
    static let textHint: UIColor    = UIColor(hex: 0x999999)
    static let textWhite: UIColor   = .white

    // 背景 / 分割
    static let bg: UIColor          = UIColor(hex: 0xF5F6F8)
    static let cardBg: UIColor      = .white
    static let separator: UIColor   = UIColor(hex: 0xEEEEEE)

    // 功能
    static let tagBg: UIColor       = UIColor(hex: 0xFFF0E5)
    static let tagText: UIColor     = UIColor(hex: 0xFF8A00)
    static let online: UIColor      = UIColor(hex: 0x27C24C)
    static let shadow: UIColor      = UIColor.black.withAlphaComponent(0.06)
}

/// 字体统一管理
enum AppFont {
    static func regular(_ size: CGFloat) -> UIFont { UIFont.systemFont(ofSize: size.fit) }
    static func medium(_ size: CGFloat) -> UIFont  { UIFont.systemFont(ofSize: size.fit, weight: .medium) }
    static func semibold(_ size: CGFloat) -> UIFont{ UIFont.systemFont(ofSize: size.fit, weight: .semibold) }
    static func bold(_ size: CGFloat) -> UIFont    { UIFont.systemFont(ofSize: size.fit, weight: .bold) }

    // 常用字号快捷
    static let title   = semibold(18)
    static let navTitle = semibold(17)
    static let body    = regular(15)
    static let bodyM   = medium(15)
    static let sub     = regular(13)
    static let small   = regular(12)
    static let mini    = regular(11)
    static let price   = bold(18)
    static let priceLg = bold(22)
}
