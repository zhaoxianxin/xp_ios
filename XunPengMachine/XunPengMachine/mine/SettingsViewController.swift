//
//  SettingsViewController.swift
//  XunPengMachine
//
//  我的-设置中心：协议、隐私、第三方 SDK、消息震动、退出与账号注销
//

import UIKit

final class SettingsViewController: BaseViewController {

    private enum RowTag: Int {
        case serviceAgreement = 1
        case privacyPolicy
        case thirdPartySDK
        case logout
        case cancelAccount
    }

    private enum PreferenceKey {
        static let messageVibrationEnabled = "settings_message_vibration_enabled"
        static let messageVibrationInitialized = "settings_message_vibration_initialized"
    }

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let vibrationSwitch = UISwitch()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "设置中心"
        setupNavigation()
        setupUI()
        buildContent()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.frame = view.bounds
        contentView.frame = CGRect(x: 0, y: 0, width: view.w,
                                   height: max(contentView.h, scrollView.h + 1))
        scrollView.contentSize = contentView.frame.size
    }

    private func setupNavigation() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(backTapped)
        )
    }

    private func setupUI() {
        view.backgroundColor = AppColor.bg
        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
    }

    private func buildContent() {
        contentView.removeSubviews()

        let rowHeight: CGFloat = 52.fit
        var y: CGFloat = 12.fit

        let agreementRows: [(String, RowTag)] = [
            ("用户协议", .serviceAgreement),
            ("隐私政策", .privacyPolicy),
            ("第三方 SDK", .thirdPartySDK)
        ]
        for (index, item) in agreementRows.enumerated() {
            let row = makeActionRow(title: item.0, tag: item.1, showsArrow: true)
            row.frame = CGRect(x: 0, y: y, width: Screen.width, height: rowHeight)
            contentView.addSubview(row)
            y += rowHeight
            if index < agreementRows.count - 1 {
                addSeparator(y: y, inset: 12.fit)
            }
        }

        y += 12.fit
        let vibrationRow = makeVibrationRow()
        vibrationRow.frame = CGRect(x: 0, y: y, width: Screen.width, height: rowHeight)
        contentView.addSubview(vibrationRow)
        y += rowHeight

        y += 34.fit
        let logoutRow = makeActionRow(title: "退出登录", tag: .logout,
                                      showsArrow: false, centered: true)
        logoutRow.frame = CGRect(x: 0, y: y, width: Screen.width, height: rowHeight)
        contentView.addSubview(logoutRow)
        y += rowHeight

        let cancelRow = makeActionRow(title: "注销账号", tag: .cancelAccount,
                                      showsArrow: false, centered: true,
                                      titleColor: AppColor.textHint)
        cancelRow.frame = CGRect(x: 0, y: y, width: Screen.width, height: rowHeight)
        contentView.addSubview(cancelRow)
        y += rowHeight + 24.fit

        contentView.frame = CGRect(x: 0, y: 0, width: Screen.width, height: y)
    }

    private func makeActionRow(title: String, tag: RowTag, showsArrow: Bool,
                               centered: Bool = false,
                               titleColor: UIColor = AppColor.textMain) -> UIButton {
        let button = UIButton(type: .custom)
        button.tag = tag.rawValue
        button.backgroundColor = .white
        button.setTitle(title, for: .normal)
        button.setTitleColor(titleColor, for: .normal)
        button.setTitleColor(titleColor.withAlphaComponent(0.55), for: .highlighted)
        button.titleLabel?.font = AppFont.body
        button.contentHorizontalAlignment = centered ? .center : .left
        if !centered {
            button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 12.fit, bottom: 0, right: 42.fit)
        }
        if showsArrow {
            let arrow = UIImageView(image: UIImage(systemName: "chevron.right")?
                .withRenderingMode(.alwaysTemplate))
            arrow.tintColor = AppColor.textHint
            arrow.contentMode = .scaleAspectFit
            arrow.frame = CGRect(x: Screen.width - 24.fit, y: 19.fit,
                                 width: 8.fit, height: 14.fit)
            arrow.isUserInteractionEnabled = false
            button.addSubview(arrow)
        }
        button.addTarget(self, action: #selector(actionRowTapped(_:)), for: .touchUpInside)
        return button
    }

    private func makeVibrationRow() -> UIView {
        let row = UIView()
        row.backgroundColor = .white

        let titleLabel = UILabel.make("消息震动", font: AppFont.body, color: AppColor.textMain)
        titleLabel.frame = CGRect(x: 12.fit, y: 0, width: 150.fit, height: 52.fit)
        row.addSubview(titleLabel)

        let defaults = UserDefaults.standard
        if !defaults.bool(forKey: PreferenceKey.messageVibrationInitialized) {
            defaults.set(true, forKey: PreferenceKey.messageVibrationEnabled)
            defaults.set(true, forKey: PreferenceKey.messageVibrationInitialized)
        }
        vibrationSwitch.isOn = defaults.bool(forKey: PreferenceKey.messageVibrationEnabled)
        vibrationSwitch.onTintColor = AppColor.primary
        vibrationSwitch.addTarget(self, action: #selector(vibrationChanged), for: .valueChanged)
        vibrationSwitch.sizeToFit()
        vibrationSwitch.frame.origin = CGPoint(
            x: Screen.width - vibrationSwitch.w - 12.fit,
            y: (52.fit - vibrationSwitch.h) / 2
        )
        row.addSubview(vibrationSwitch)
        return row
    }

    private func addSeparator(y: CGFloat, inset: CGFloat) {
        let line = Separator()
        line.frame = CGRect(x: inset, y: y - 0.5,
                            width: Screen.width - inset, height: 0.5)
        contentView.addSubview(line)
    }

    @objc private func actionRowTapped(_ sender: UIButton) {
        guard let tag = RowTag(rawValue: sender.tag) else { return }
        switch tag {
        case .serviceAgreement:
            openAgreement(urlString: Constants.serviceAgreementURL, title: "用户协议")
        case .privacyPolicy:
            openAgreement(urlString: Constants.privacyPolicyURL, title: "隐私政策")
        case .thirdPartySDK:
            navigationController?.pushViewController(ThirdPartySDKListViewController(), animated: true)
        case .logout:
            confirmLogout()
        case .cancelAccount:
            let controller = AccountCancellationViewController()
            controller.onConfirmCancellation = { [weak self] in
                self?.performCancelAccount()
            }
            navigationController?.pushViewController(controller, animated: true)
        }
    }

    @objc private func vibrationChanged() {
        UserDefaults.standard.set(vibrationSwitch.isOn,
                                  forKey: PreferenceKey.messageVibrationEnabled)
        Logger.shared.track("settings_message_vibration", params: ["enabled": vibrationSwitch.isOn])
    }

    private func openAgreement(urlString: String, title: String) {
        guard let url = URL(string: urlString),
              let scheme = url.scheme?.lowercased(),
              scheme == "https" || scheme == "http" else {
            Toast.shared.show("协议地址暂未配置")
            return
        }
        let controller = PNSPrivacyWebViewController(urlString: urlString, title: title)
        let navigationController = UINavigationController(rootViewController: controller)
        navigationController.modalPresentationStyle = .fullScreen
        present(navigationController, animated: true)
    }

    private func confirmLogout() {
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

    private func switchToLogin() {
        if let window = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first {
            window.rootViewController = LoginViewController()
        }
    }
}

private final class ThirdPartySDKListViewController: BaseViewController {

    private let scrollView = UIScrollView()
    private let contentLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "第三方 SDK"
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(backTapped)
        )

        contentLabel.numberOfLines = 0
        contentLabel.font = AppFont.sub
        contentLabel.textColor = AppColor.textMain
        contentLabel.text = """
        为实现应用相关功能，我们接入了以下第三方 SDK：

        1. 高德地图 SDK
        使用目的：提供地图展示、地点搜索与定位相关能力。
        涉及信息：位置信息、设备及网络信息（以实际调用和授权为准）。

        2. 阿里云号码认证服务 SDK
        使用目的：提供本机号码一键登录与运营商认证能力。
        涉及信息：手机号码认证信息、设备及网络信息（以实际调用和授权为准）。

        第三方 SDK 仅在实现对应功能所必需的范围内启用。详细的数据处理规则、共享范围和联系方式请查阅《隐私政策》。
        """

        view.addSubview(scrollView)
        scrollView.addSubview(contentLabel)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.frame = view.bounds
        let inset: CGFloat = 16.fit
        let width = view.w - inset * 2
        let height = contentLabel.sizeThatFits(
            CGSize(width: width, height: .greatestFiniteMagnitude)
        ).height
        contentLabel.frame = CGRect(x: inset, y: 18.fit, width: width, height: height)
        scrollView.contentSize = CGSize(width: view.w, height: height + 36.fit)
    }
}
