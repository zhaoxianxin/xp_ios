//
//  UIColor+Ext.swift
//  XunPengMachine
//

import UIKit

extension UIColor {
    /// 16进制初始化，支持 0xRRGGBB
    convenience init(hex: UInt32, alpha: CGFloat = 1.0) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255.0,
            green: CGFloat((hex >> 8) & 0xFF) / 255.0,
            blue: CGFloat(hex & 0xFF) / 255.0,
            alpha: alpha
        )
    }

    /// 16进制字符串初始化 "#0076FF" / "0076FF"
    convenience init?(hexString: String, alpha: CGFloat = 1.0) {
        var s = hexString.trimmingCharacters(in: .whitespaces)
        if s.hasPrefix("#") { s.removeFirst() }
        guard let v = UInt32(s, radix: 16) else { return nil }
        self.init(hex: v, alpha: alpha)
    }

    /// 颜色加深/变浅 (0~1)
    func adjust(brightness delta: CGFloat) -> UIColor {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        if getHue(&h, saturation: &s, brightness: &b, alpha: &a) {
            return UIColor(hue: h, saturation: s, brightness: max(0, min(1, b + delta)), alpha: a)
        }
        return self
    }
}
