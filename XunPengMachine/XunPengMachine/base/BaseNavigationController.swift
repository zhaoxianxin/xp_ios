//
//  BaseNavigationController.swift
//  XunPengMachine
//

import UIKit

class BaseNavigationController: UINavigationController {
    override func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = nil
        delegate = self
    }

    // 统一支持子 VC 设置 navStyle
    override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        // 隐藏根 VC 的返回按钮
        if children.count >= 1 { viewController.hidesBottomBarWhenPushed = true }
        super.pushViewController(viewController, animated: animated)
    }
}

extension BaseNavigationController: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController,
                               willShow viewController: UIViewController, animated: Bool) {
        if let base = viewController as? BaseViewController {
            switch base.navStyle {
            case .blue:
                navigationController.setNavigationBarHidden(false, animated: animated)
            case .white:
                navigationController.setNavigationBarHidden(false, animated: animated)
            case .none:
                navigationController.setNavigationBarHidden(true, animated: animated)
            }
        }
    }
}
