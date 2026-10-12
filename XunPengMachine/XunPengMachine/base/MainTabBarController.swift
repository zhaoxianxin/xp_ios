//
//  MainTabBarController.swift
//  XunPengMachine
//
//  主 TabBar：找活 / 找设备 / [发布] / 招司机 / 我的
//

import UIKit

class MainTabBarController: UITabBarController {

    private var customTabBar: CustomTabBar?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 替换为自定义 TabBar
        let customBar = CustomTabBar()
        customBar.publishDelegate = self
        setValue(customBar, forKey: "tabBar")
        customTabBar = customBar
        
        setupChildControllers()
        delegate = self
    }

    private func setupChildControllers() {
        let jobVC    = JobHomeViewController()
        let carVC    = CarHomeViewController()
        let driverVC = DriverHomeViewController()
        let mineVC   = MineHomeViewController()

        jobVC.tabBarItem    = tabItem(title: "找活")
        carVC.tabBarItem    = tabItem(title: "找车辆")
        driverVC.tabBarItem = tabItem(title: "招聘")
        mineVC.tabBarItem   = tabItem(title: "我的")

        // 中间占位（发布按钮覆盖其上）
        let placeholder = UIViewController()
        placeholder.tabBarItem = UITabBarItem(title: nil, image: nil, selectedImage: nil)
        placeholder.tabBarItem.isEnabled = false

        let navs = [jobVC, carVC, placeholder, driverVC, mineVC].map { wrapNav($0) }
        viewControllers = navs
    }

    private func wrapNav(_ vc: UIViewController) -> UINavigationController {
        let nav = BaseNavigationController(rootViewController: vc)
        nav.navigationBar.isTranslucent = false
        return nav
    }

    private func tabItem(title: String) -> UITabBarItem {
        let blank = UIImage()   // 1x1 透明
        return UITabBarItem(title: title, image: blank, selectedImage: blank)
    }
}

// MARK: - 发布点击
extension MainTabBarController: CustomTabBarDelegate {
    func tabBarDidClickPublish() {
        Logger.shared.track("click_publish")
        let publishVC = PublishEntryViewController()
        publishVC.modalPresentationStyle = .overFullScreen
        present(publishVC, animated: false)
        // 手动触发弹入动画，避免系统过渡导致的灰色闪现
    }
}

// MARK: - 占位项拦截
extension MainTabBarController: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController,
                          shouldSelect viewController: UIViewController) -> Bool {
        // 中间占位不可选中
        guard let navs = tabBarController.viewControllers else { return true }
        if navs.count > 2 && viewController === navs[2] { return false }
        return true
    }
}
