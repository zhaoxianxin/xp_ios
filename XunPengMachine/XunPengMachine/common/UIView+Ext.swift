//
//  UIView+Ext.swift
//  XunPengMachine
//

import UIKit

extension UIView {
    var x: CGFloat {
        get { frame.minX }
        set { frame.origin.x = newValue }
    }
    
    var y: CGFloat {
        get { frame.minY }
        set { frame.origin.y = newValue }
    }
    
    var w: CGFloat {
        get { frame.width }
        set { frame.size.width = newValue }
    }
    
    var h: CGFloat {
        get { frame.height }
        set { frame.size.height = newValue }
    }
    
    var right: CGFloat {
        get { frame.maxX }
        set { frame.origin.x = newValue - frame.width }
    }
    
    var bottom: CGFloat {
        get { frame.maxY }
        set { frame.origin.y = newValue - frame.height }
    }
    
    var centerX: CGFloat {
        get { center.x }
        set { center.x = newValue }
    }
    var centerY: CGFloat {
        get { center.y }
        set { center.y = newValue }
    }
    
    /// 圆角
    @discardableResult
    func corner(_ radius: CGFloat) -> Self {
        layer.cornerRadius = radius.fit
        layer.masksToBounds = true
        return self
    }
    /// 指定角圆角
    func corner(_ radius: CGFloat, corners: UIRectCorner) {
        let path = UIBezierPath(roundedRect: bounds,
                                byRoundingCorners: corners,
                                cornerRadii: CGSize(width: radius.fit, height: radius.fit))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        layer.mask = mask
    }
    /// 边框
    @discardableResult
    func border(_ width: CGFloat, _ color: UIColor) -> Self {
        layer.borderWidth = width
        layer.borderColor = color.cgColor
        return self
    }
    /// 阴影
    func shadow(color: UIColor = AppColor.shadow, radius: CGFloat = 6,
                offset: CGSize = CGSize(width: 0, height: 2), opacity: Float = 1) {
        layer.shadowColor = color.cgColor
        layer.shadowRadius = radius
        layer.shadowOffset = offset
        layer.shadowOpacity = opacity
        layer.masksToBounds = false
    }

    /// 快速链式添加到父视图
    @discardableResult
    func addTo(_ parent: UIView) -> Self {
        parent.addSubview(self)
        return self
    }

    /// 渐变背景
    func gradient(_ colors: [UIColor], startPoint: CGPoint = CGPoint(x: 0, y: 0.5),
                  endPoint: CGPoint = CGPoint(x: 1, y: 0.5)) {
        let gl = CAGradientLayer()
        gl.frame = bounds
        gl.colors = colors.map { $0.cgColor }
        gl.startPoint = startPoint
        gl.endPoint = endPoint
        layer.insertSublayer(gl, at: 0)
        objc_setAssociatedObject(self, &UIView.kGradientKey, gl, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    /// 移除所有子视图
    func removeSubviews() { subviews.forEach { $0.removeFromSuperview() } }

    /// 截图
    func snapshot() -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(bounds.size, false, 0)
        defer { UIGraphicsEndImageContext() }
        layer.render(in: UIGraphicsGetCurrentContext()!)
        return UIGraphicsGetImageFromCurrentImageContext()
    }

    private static var kGradientKey: Void = ()
}
