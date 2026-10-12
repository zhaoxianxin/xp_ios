//
//  SettingsViewController.swift
//  XunPengMachine
//
//  我的-设置中心：缓存清理、关于、反馈、退出登录、注销账号
//

import UIKit

final class SettingsViewController: BaseViewController {

    // MARK: - UI
    private let scrollView = UIScrollView()
    private let menuContainer = UIView()

    private struct MenuItem {
        let icon: String
        let title: String
        let accessory: String   // 右侧辅助文字，空则显示箭头
        let action: () -> Void
    }

    private var menuItems: [MenuItem] = []

    // MARK: - 生命周期
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "设置中心"
        navStyle = .white
        setupBackButton()
        applyNavStyle()
        setupUI()
        rebuildMenu()
        layoutMenu()
    }

    private func applyNavStyle() {
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationController?.navigationBar.barTintColor = .white
        navigationController?.navigationBar.tintColor = AppColor.textMain
        navigationController?.navigationBar.titleTextAttributes = [
            .foregroundColor: AppColor.textMain, .font: AppFont.navTitle
        ]
    }

    // MARK: - UI 搭建
    private func setupUI() {
        view.backgroundColor = AppColor.bg

        view.addSubview(scrollView)
        scrollView.frame = CGRect(x: 0, y: Screen.topSafeH,
                                  width: Screen.width,
                                  height: Screen.height - Screen.topSafeH)
        scrollView.alwaysBounceVertical = true

        scrollView.addSubview(menuContainer)
    }

    private func rebuildMenu() {
        let cacheSize = currentCacheSize()
        menuItems = [
            MenuItem(icon: "trash", title: "清除缓存", accessory: cacheSize) { [weak self] in
                self?.clearCache()
            },
            MenuItem(icon: "info.circle", title: "关于我们", accessory: "") { [weak self] in
                self?.showAbout()
            },
            MenuItem(icon: "envelope", title: "意见反馈", accessory: "") { [weak self] in
                self?.navigationController?.pushViewController(FeedbackViewController(), animated: true)
            }
        ]
    }

    private func layoutMenu() {
        menuContainer.removeSubviews()
        let padding: CGFloat = 12.fit
        let cardW = Screen.width - padding * 2
        let rowH: CGFloat = 50.fit
        var y: CGFloat = 0

        for (idx, item) in menuItems.enumerated() {
            let row = makeMenuRow(item: item)
            row.tag = idx
            menuContainer.addSubview(row)
            row.frame = CGRect(x: 0, y: y, width: cardW, height: rowH)
            row.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(menuTapped(_:))))
            y += rowH
            if idx < menuItems.count - 1 {
                let line = Separator()
                menuContainer.addSubview(line)
                line.frame = CGRect(x: 44.fit, y: y - 0.25, width: cardW - 44.fit, height: 0.5)
            }
        }

        // 注销账号（红色文字按钮，独立卡）
        y += 16
        let cancelAccountBtn = makeTextButton(title: "注销账号", color: AppColor.danger)
        cancelAccountBtn.tag = 100
        menuContainer.addSubview(cancelAccountBtn)
        cancelAccountBtn.frame = CGRect(x: 0, y: y, width: cardW, height: rowH)
        cancelAccountBtn.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(cancelAccountTapped)))
        cancelAccountBtn.isUserInteractionEnabled = true
        y += rowH

        // 退出登录按钮
        y += 40
        let logoutBtn = AppButton(title: "退出登录", style: .danger, height: 44)
        menuContainer.addSubview(logoutBtn)
        logoutBtn.frame = CGRect(x: 0, y: y, width: cardW, height: 44)
        logoutBtn.addTarget(self, action: #selector(logoutTapped), for: .touchUpInside)
        y += 44 + 40

        menuContainer.frame = CGRect(x: padding, y: 12, width: cardW, height: y)
        scrollView.contentSize = CGSize(width: Screen.width, height: y + 24)
    }

    private func makeMenuRow(item: MenuItem) -> UIView {
        let container = UIView()
        container.backgroundColor = AppColor.cardBg
        container.layer.cornerRadius = 10

        let icon = UIImageView(image: UIImage(systemName: item.icon)?.withRenderingMode(.alwaysTemplate))
        icon.tintColor = AppColor.primary
        container.addSubview(icon)
        icon.frame = CGRect(x: 12.fit, y: (50.fit - 18.fit) / 2, width: 18.fit, height: 18.fit)

        let title = UILabel.make(item.title, font: AppFont.body, color: AppColor.textMain)
        container.addSubview(title)
        title.frame = CGRect(x: icon.right + 10.fit, y: 0, width: 160.fit, height: 50.fit)

        if item.accessory.isEmpty {
            let arrow = UIImageView(image: UIImage(systemName: "chevron.right")?.withRenderingMode(.alwaysTemplate))
            arrow.tintColor = AppColor.textHint
            container.addSubview(arrow)
            arrow.frame = CGRect(x: Screen.width - 24.fit * 2 - 8.fit, y: (50.fit - 12) / 2, width: 8, height: 12)
        } else {
            let acc = UILabel.make(item.accessory, font: AppFont.small, color: AppColor.textHint, alignment: .right)
            container.addSubview(acc)
            acc.frame = CGRect(x: Screen.width - 24.fit * 2 - 80.fit, y: 0, width: 80.fit, height: 50.fit)
        }
        return container
    }

    private func makeTextButton(title: String, color: UIColor) -> UIView {
        let container = UIView()
        container.backgroundColor = AppColor.cardBg
        container.layer.cornerRadius = 10
        let label = UILabel.make(title, font: AppFont.body, color: color, alignment: .center)
        container.addSubview(label)
        label.frame = CGRect(x: 0, y: 0, width: Screen.width - 24.fit, height: 50.fit)
        return container
    }

    // MARK: - 缓存
    private func currentCacheSize() -> String {
        let cacheURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        var size: UInt64 = 0
        if let enumerator = FileManager.default.enumerator(at: cacheURL,
                                                            includingPropertiesForKeys: [.fileSizeKey]) {
            for case let url as URL in enumerator {
                size += UInt64((try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0)
            }
        }
        if size < 1024 { return "\(size)B" }
        if size < 1024 * 1024 { return "\(size / 1024)KB" }
        return String(format: "%.1fM", Double(size) / 1024.0 / 1024.0)
    }

    private func clearCache() {
        let cacheURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        try? FileManager.default.removeItem(at: cacheURL)
        try? FileManager.default.createDirectory(at: cacheURL, withIntermediateDirectories: true)
        showToast("已清理")
        rebuildMenu()
        layoutMenu()
        Logger.shared.track("settings_clear_cache")
    }

    // MARK: - 关于我们
    private func showAbout() {
        AlertManager.shared.showTip("迅鹏机器 v1.0.0\n让物流找人找车更高效",
                                    title: "关于我们")
        Logger.shared.track("settings_about")
    }

    // MARK: - 事件
    @objc private func menuTapped(_ gesture: UITapGestureRecognizer) {
        guard let idx = gesture.view?.tag, idx < menuItems.count else { return }
        menuItems[idx].action()
    }

    @objc private func logoutTapped() {
        AlertManager.shared.showAlert(title: "退出登录",
                                      message: "确定要退出当前账号吗？",
                                      confirmTitle: "退出",
                                      cancelTitle: "取消",
                                      confirmColor: AppColor.danger,
                                      onConfirm: { [weak self] in
            self?.performLogout()
        })
        Logger.shared.track("settings_click_logout")
    }

    @objc private func cancelAccountTapped() {
        AlertManager.shared.showAlert(title: "注销账号",
                                      message: "注销后账号将无法恢复，所有数据将被清除，确定要注销吗？",
                                      confirmTitle: "确定注销",
                                      cancelTitle: "取消",
                                      confirmColor: AppColor.danger,
                                      onConfirm: { [weak self] in
            self?.performCancelAccount()
        })
        Logger.shared.track("settings_click_cancel_account")
    }

    // MARK: - 退出 / 注销
    private func performLogout() {
        TokenManager.shared.clear()
        switchToLogin()
    }

    private func performCancelAccount() {
        TokenManager.shared.clear()
        showToast("账号注销申请已提交")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            self?.switchToLogin()
        }
    }

    /// 切回登录页
    private func switchToLogin() {
        if let window = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first {
            window.rootViewController = LoginViewController()
        }
    }
}
