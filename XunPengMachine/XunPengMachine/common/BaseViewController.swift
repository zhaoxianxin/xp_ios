//
//  BaseViewController.swift
//  XunPengMachine
//
//  VC 基类：导航栏配置、空视图、loading、页面埋点
//

import UIKit

class BaseViewController: UIViewController {

    /// 持有订阅，页面销毁时统一释放
    var disposables: [Disposable] = []

    /// 是否使用大标题蓝色导航栏
    var navStyle: NavStyle = .blue

    enum NavStyle {
        case blue   // 蓝色背景白字
        case white  // 白色背景黑字
        case none   // 无导航栏
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColor.bg
        setupNavBar()
        Logger.shared.pageStart(pageName)
    }

    deinit {
        disposables.forEach { $0.dispose() }
        Logger.shared.pageEnd(pageName)
    }

    var pageName: String { String(describing: type(of: self)) }

    private func setupNavBar() {
        switch navStyle {
        case .blue:
            navigationController?.navigationBar.barTintColor = AppColor.navBar
            navigationController?.navigationBar.tintColor = .white
            navigationController?.navigationBar.titleTextAttributes = [
                .foregroundColor: UIColor.white, .font: AppFont.navTitle
            ]
            navigationController?.navigationBar.shadowImage = UIImage()
            if #available(iOS 13.0, *) {
                let appearance = UINavigationBarAppearance()
                appearance.configureWithOpaqueBackground()
                appearance.backgroundColor = AppColor.navBar
                appearance.titleTextAttributes = [.foregroundColor: UIColor.white, .font: AppFont.navTitle]
                navigationController?.navigationBar.standardAppearance = appearance
                navigationController?.navigationBar.scrollEdgeAppearance = appearance
            }
        case .white:
            navigationController?.navigationBar.barTintColor = .white
            navigationController?.navigationBar.tintColor = AppColor.textMain
            navigationController?.navigationBar.titleTextAttributes = [
                .foregroundColor: AppColor.textMain, .font: AppFont.navTitle
            ]
        case .none:
            navigationController?.setNavigationBarHidden(true, animated: false)
        }
    }

    /// 设置返回按钮（无文字）
    func setupBackButton() {
        let btn = UIBarButtonItem(image: UIImage(named: "nav_back"),
                                  style: .plain, target: self, action: #selector(backTapped))
        btn.imageInsets = UIEdgeInsets(top: 0, left: -6, bottom: 0, right: 6)
        navigationItem.leftBarButtonItem = btn
    }

    @objc func backTapped() { navigationController?.popViewController(animated: true) }
}
