//
//  LoadingHUD.swift
//  XunPengMachine
//
//  全局 Loading
//

import UIKit

final class LoadingHUD {
    static let shared = LoadingHUD()

    private var view: LoadingView?

    func show(_ text: String = "加载中...") {
        hide()
        guard let window = UIApplication.shared.windows.first else { return }
        let v = LoadingView(text: text)
        v.frame = window.bounds
        v.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        window.addSubview(v)
        view = v
        v.alpha = 0
        UIView.animate(withDuration: 0.2) { v.alpha = 1 }
    }

    func hide() {
        guard let v = view else { return }
        UIView.animate(withDuration: 0.2, animations: { v.alpha = 0 }) { _ in v.removeFromSuperview() }
        view = nil
    }
}

private class LoadingView: UIView {
    init(text: String) {
        super.init(frame: .zero)
        backgroundColor = UIColor.clear

        let container = UIView()
        container.backgroundColor = UIColor.black.withAlphaComponent(0.78)
        container.layer.cornerRadius = 12
        addSubview(container)
        container.frame = CGRect(x: 0, y: 0, width: 110, height: 110)
        container.center = CGPoint(x: Screen.width / 2, y: Screen.height / 2)

        let indicator = UIActivityIndicatorView(style: .whiteLarge)
        indicator.startAnimating()
        container.addSubview(indicator)
        indicator.center = CGPoint(x: 55, y: 44)

        let label = UILabel.make(text, font: AppFont.small, color: .white, alignment: .center)
        label.frame = CGRect(x: 0, y: 76, width: 110, height: 20)
        container.addSubview(label)
    }
    required init?(coder: NSCoder) { fatalError() }
}
