//
//  String+Ext.swift
//  XunPengMachine
//

import UIKit

extension String {
    /// 计算文本宽高
    func size(font: UIFont, maxWidth: CGFloat = CGFloat.greatestFiniteMagnitude) -> CGSize {
        let attr = [NSAttributedString.Key.font: font]
        let size = (self as NSString).boundingRect(
            with: CGSize(width: maxWidth, height: CGFloat.greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: attr, context: nil).size
        return CGSize(width: ceil(size.width), height: ceil(size.height))
    }

    /// 是否合法手机号
    var isValidPhone: Bool {
        let regex = "^1[3-9]\\d{9}$"
        return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: self)
    }

    /// 是否验证码（4位数字）
    var isValidCode: Bool {
        let regex = "^\\d{4}$"
        return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: self)
    }

    /// 手机号脱敏 138****1234
    var phoneMasked: String {
        guard count == 11 else { return self }
        let start = index(startIndex, offsetBy: 3)
        let end = index(startIndex, offsetBy: 7)
        return replacingCharacters(in: start..<end, with: "****")
    }
}

extension UILabel {
    /// 便捷构造
    static func make(_ text: String = "", font: UIFont = AppFont.body,
                     color: UIColor = AppColor.textMain, alignment: NSTextAlignment = .left,
                     lines: Int = 1) -> UILabel {
        let l = UILabel()
        l.text = text
        l.font = font
        l.textColor = color
        l.textAlignment = alignment
        l.numberOfLines = lines
        return l
    }
}

extension UIButton {
    /// 便捷构造文字按钮
    static func make(_ title: String = "", font: UIFont = AppFont.bodyM,
                     titleColor: UIColor = AppColor.textMain, bgColor: UIColor = .clear) -> UIButton {
        let b = UIButton(type: .custom)
        b.setTitle(title, for: .normal)
        b.titleLabel?.font = font
        b.setTitleColor(titleColor, for: .normal)
        b.backgroundColor = bgColor
        return b
    }
}

extension UIImageView {
    static func make(_ image: UIImage? = nil, contentMode: UIView.ContentMode = .scaleAspectFill) -> UIImageView {
        let v = UIImageView(image: image)
        v.contentMode = contentMode
        v.clipsToBounds = true
        return v
    }
}
