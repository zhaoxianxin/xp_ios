//
//  AlertManager.swift
//  XunPengMachine
//
//  自定义系统弹框（UIAlertController 风格，主题色按钮）
//

import UIKit

final class AlertManager {
    static let shared = AlertManager()

    /// 双按钮确认框（cancelTitle 传 nil 则为单按钮）
    func showAlert(title: String?, message: String?,
                   confirmTitle: String = "确定", cancelTitle: String? = "取消",
                   confirmColor: UIColor = AppColor.primary,
                   onConfirm: (() -> Void)? = nil, onCancel: (() -> Void)? = nil) {
        guard let window = UIApplication.shared.windows.first,
              let root = window.rootViewController?.presentedViewController ?? window.rootViewController else { return }

        let alert = CustomAlertView(title: title, message: message,
                                    confirmTitle: confirmTitle, cancelTitle: cancelTitle,
                                    confirmColor: confirmColor)
        alert.onConfirm = { onConfirm?(); alert.dismiss() }
        alert.onCancel = { onCancel?(); alert.dismiss() }
        alert.show(on: root)
    }

    /// 单按钮提示
    func showTip(_ message: String, title: String? = nil, onDismiss: (() -> Void)? = nil) {
        guard let window = UIApplication.shared.windows.first,
              let root = window.rootViewController?.presentedViewController ?? window.rootViewController else { return }
        let alert = CustomAlertView(title: title, message: message,
                                    confirmTitle: "我知道了", cancelTitle: nil,
                                    confirmColor: AppColor.primary)
        alert.onConfirm = { alert.dismiss(); onDismiss?() }
        alert.show(on: root)
    }
}

// MARK: - 自定义弹框视图
private final class CustomAlertView: UIView {
    var onConfirm: (() -> Void)?
    var onCancel: (() -> Void)?

    private let container = UIView()
    private let overlay = UIView()

    init(title: String?, message: String?, confirmTitle: String, cancelTitle: String?, confirmColor: UIColor) {
        super.init(frame: .zero)
        overlay.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        addSubview(overlay)

        container.backgroundColor = .white
        container.layer.cornerRadius = 12
        container.frame = CGRect(x: 0, y: 0, width: 280, height: 0)
        addSubview(container)

        var top: CGFloat = 24
        if let t = title, !t.isEmpty {
            let titleLabel = UILabel.make(t, font: AppFont.title, color: AppColor.textMain, alignment: .center)
            container.addSubview(titleLabel)
            titleLabel.frame = CGRect(x: 20, y: top, width: 240, height: 24)
            top += 34
        }
        if let m = message, !m.isEmpty {
            let msgLabel = UILabel.make(m, font: AppFont.body, color: AppColor.textSub, alignment: .center, lines: 0)
            let size = msgLabel.sizeThatFits(CGSize(width: 240, height: CGFloat.greatestFiniteMagnitude))
            container.addSubview(msgLabel)
            msgLabel.frame = CGRect(x: 20, y: top, width: 240, height: size.height)
            top += size.height + 8
        }

        let lineH = UIView(); lineH.backgroundColor = AppColor.separator
        container.addSubview(lineH)

        let btnH: CGFloat = 48
        lineH.frame = CGRect(x: 0, y: top, width: 280, height: 0.5)

        if let cancel = cancelTitle {
            // 双按钮
            let cancelBtn = UIButton.make(cancel, font: AppFont.bodyM, titleColor: AppColor.textSub)
            cancelBtn.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
            container.addSubview(cancelBtn)
            cancelBtn.frame = CGRect(x: 0, y: top, width: 140, height: btnH)

            let lineV = UIView(); lineV.backgroundColor = AppColor.separator
            container.addSubview(lineV)
            lineV.frame = CGRect(x: 140, y: top, width: 0.5, height: btnH)

            let confirmBtn = UIButton.make(confirmTitle, font: AppFont.bodyM, titleColor: confirmColor)
            confirmBtn.addTarget(self, action: #selector(confirmTapped), for: .touchUpInside)
            container.addSubview(confirmBtn)
            confirmBtn.frame = CGRect(x: 140, y: top, width: 140, height: btnH)
        } else {
            let confirmBtn = UIButton.make(confirmTitle, font: AppFont.bodyM, titleColor: confirmColor)
            confirmBtn.addTarget(self, action: #selector(confirmTapped), for: .touchUpInside)
            container.addSubview(confirmBtn)
            confirmBtn.frame = CGRect(x: 0, y: top, width: 280, height: btnH)
        }
        container.frame.size = CGSize(width: 280, height: top + btnH)
        container.center = CGPoint(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2)
    }
    required init?(coder: NSCoder) { fatalError() }

    func show(on parent: UIViewController) {
        frame = parent.view.bounds
        parent.view.addSubview(self)
        container.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
        container.alpha = 0
        overlay.alpha = 0
        UIView.animate(withDuration: 0.2, delay: 0,
                       usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5,
                       options: .curveEaseOut, animations: {
            self.overlay.alpha = 1
            self.container.alpha = 1
            self.container.transform = .identity
        })
    }

    func dismiss() {
        UIView.animate(withDuration: 0.18, animations: {
            self.overlay.alpha = 0
            self.container.alpha = 0
            self.container.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
        }) { _ in self.removeFromSuperview() }
    }

    @objc private func confirmTapped() { onConfirm?() }
    @objc private func cancelTapped() { onCancel?() }
}
