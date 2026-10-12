//
//  Toast.swift
//  XunPengMachine
//
//  轻量 Toast
//

import UIKit

final class Toast {
    static let shared = Toast()

    enum Position { case top, center, bottom }

    func show(_ message: String, duration: TimeInterval = 2.0, position: Position = .center) {
        guard let window = Self.keyWindow else { return }
        let toast = ToastView(message: message, maxWidth: window.bounds.width - 48)
        window.addSubview(toast)
        toast.alpha = 0
        toast.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)

        let centerY: CGFloat
        switch position {
        case .top:
            centerY = window.safeAreaInsets.top + 60
        case .center:
            centerY = window.bounds.midY
        case .bottom:
            centerY = window.bounds.height - window.safeAreaInsets.bottom - 100 - toast.h / 2
        }
        toast.center = CGPoint(x: window.bounds.midX, y: centerY)

        UIView.animate(withDuration: 0.25, delay: 0,
                       usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5,
                       options: .curveEaseOut, animations: {
            toast.alpha = 1
            toast.transform = .identity
        }) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                UIView.animate(withDuration: 0.25, animations: {
                    toast.alpha = 0
                    toast.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
                }) { _ in toast.removeFromSuperview() }
            }
        }
    }

    @discardableResult
    @objc func hide() -> Bool { true }

    private static var keyWindow: UIWindow? {
        if #available(iOS 13.0, *) {
            return UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap(\.windows)
                .first(where: \.isKeyWindow)
        }
        return UIApplication.shared.windows.first(where: \.isKeyWindow)
    }
}

private class ToastView: UIView {
    init(message: String, maxWidth: CGFloat) {
        let horizontalPadding: CGFloat = 20
        let verticalPadding: CGFloat = 14
        let minimumWidth: CGFloat = 80
        let font = AppFont.body
        let maximumTextWidth = max(1, maxWidth - horizontalPadding * 2)
        let textBounds = (message as NSString).boundingRect(
            with: CGSize(width: maximumTextWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font],
            context: nil
        )
        let textWidth = min(maximumTextWidth, ceil(textBounds.width))
        let textHeight = max(font.lineHeight, ceil(textBounds.height))
        let toastWidth = min(maxWidth, max(minimumWidth, textWidth + horizontalPadding * 2))
        let toastHeight = textHeight + verticalPadding * 2

        super.init(frame: CGRect(x: 0, y: 0, width: toastWidth, height: toastHeight))
        backgroundColor = UIColor.black.withAlphaComponent(0.8)
        layer.cornerRadius = 10
        layer.masksToBounds = true

        let label = UILabel.make(message, font: font, color: .white, alignment: .center, lines: 0)
        label.lineBreakMode = .byWordWrapping
        label.frame = CGRect(x: horizontalPadding,
                             y: verticalPadding,
                             width: toastWidth - horizontalPadding * 2,
                             height: textHeight)
        addSubview(label)
    }
    required init?(coder: NSCoder) { fatalError() }
}

extension UIViewController {
    func showToast(_ message: String, position: Toast.Position = .center) {
        Toast.shared.show(message, position: position)
    }
}
