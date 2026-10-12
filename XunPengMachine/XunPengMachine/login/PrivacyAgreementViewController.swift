//
//  PrivacyAgreementViewController.swift
//  XunPengMachine
//
//  首次启动隐私服务协议页
//

import UIKit

final class PrivacyAgreementViewController: UIViewController {

    var onAgree: (() -> Void)?

    private let topBar = UIView()
    private let logoView = UIView()
    private let logoLabel = UILabel.make("巡朋机械", font: AppFont.bodyM,
                                         color: .white, alignment: .center)
    private let logoSubtitle = UILabel.make("找活源     招司机", font: AppFont.mini,
                                            color: .white, alignment: .center)
    private let appNameLabel = UILabel.make("巡朋机械APP", font: AppFont.bold(20),
                                            color: AppColor.primary, alignment: .center)
    private let featuresLabel = UILabel.make("发布活源        活源找车\n\n出租机械        招聘司机",
                                             font: AppFont.body, color: AppColor.textMain,
                                             alignment: .center)

    private let maskView = UIView()
    private let agreementCard = UIView()
    private let tipTitle = UILabel.make("温馨提示", font: AppFont.bodyM, color: AppColor.textMain)
    private let messageLabel = UILabel.make("为了更好保障您的合法权益，请您阅读并同意",
                                            font: AppFont.small, color: AppColor.textMain)
    private let privacyButton = UIButton.make("《隐私政策》", font: AppFont.small,
                                              titleColor: AppColor.primary)
    private let serviceButton = UIButton.make("《服务协议》", font: AppFont.small,
                                              titleColor: AppColor.primary)
    private let consentLabel = UILabel.make("选择“同意”代表您授权相关服务",
                                            font: AppFont.mini, color: AppColor.textHint,
                                            alignment: .center)
    private let disagreeButton = UIButton.make("不同意", font: AppFont.small,
                                                titleColor: AppColor.primary)
    private let agreeButton = UIButton.make("同意", font: AppFont.small, titleColor: .white)

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        view.backgroundColor = AppColor.bg

        topBar.backgroundColor = AppColor.navBar
        view.addSubview(topBar)

        logoView.backgroundColor = AppColor.navBar
        logoView.layer.cornerRadius = 4.fit
        view.addSubview(logoView)
        logoView.addSubview(logoLabel)
        logoView.addSubview(logoSubtitle)

        view.addSubview(appNameLabel)
        featuresLabel.numberOfLines = 0
        view.addSubview(featuresLabel)

        maskView.backgroundColor = UIColor.black.withAlphaComponent(0.18)
        view.addSubview(maskView)

        agreementCard.backgroundColor = .white
        agreementCard.layer.cornerRadius = 6.fit
        view.addSubview(agreementCard)
        agreementCard.addSubview(tipTitle)
        agreementCard.addSubview(messageLabel)
        agreementCard.addSubview(privacyButton)
        agreementCard.addSubview(serviceButton)
        agreementCard.addSubview(consentLabel)
        agreementCard.addSubview(disagreeButton)
        agreementCard.addSubview(agreeButton)

        disagreeButton.backgroundColor = AppColor.separator
        disagreeButton.layer.cornerRadius = 18.fit
        disagreeButton.addTarget(self, action: #selector(disagreeTapped), for: .touchUpInside)
        agreeButton.backgroundColor = AppColor.primary
        agreeButton.layer.cornerRadius = 18.fit
        agreeButton.addTarget(self, action: #selector(agreeTapped), for: .touchUpInside)
        privacyButton.addTarget(self, action: #selector(privacyPolicyTapped), for: .touchUpInside)
        serviceButton.addTarget(self, action: #selector(serviceAgreementTapped), for: .touchUpInside)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let safeTop = view.safeAreaInsets.top
        topBar.frame = CGRect(x: 0, y: 0, width: view.w, height: safeTop + 44.fit)

        logoView.frame = CGRect(x: (view.w - 96.fit) / 2,
                                y: topBar.bottom + 48.fit,
                                width: 96.fit, height: 72.fit)
        logoLabel.frame = CGRect(x: 4.fit, y: 12.fit, width: logoView.w - 8.fit, height: 24.fit)
        logoSubtitle.frame = CGRect(x: 4.fit, y: logoLabel.bottom + 5.fit,
                                    width: logoView.w - 8.fit, height: 16.fit)
        appNameLabel.frame = CGRect(x: 20.fit, y: logoView.bottom + 16.fit,
                                    width: view.w - 40.fit, height: 28.fit)
        featuresLabel.frame = CGRect(x: 28.fit, y: appNameLabel.bottom + 18.fit,
                                     width: view.w - 56.fit, height: 86.fit)

        maskView.frame = view.bounds

        let cardWidth = min(view.w - 40.fit, 360.fit)
        let cardHeight: CGFloat = 210.fit
        agreementCard.frame = CGRect(x: (view.w - cardWidth) / 2,
                                     y: view.h - view.safeAreaInsets.bottom - cardHeight - 48.fit,
                                     width: cardWidth, height: cardHeight)
        tipTitle.frame = CGRect(x: 16.fit, y: 14.fit,
                                width: agreementCard.w - 32.fit, height: 22.fit)
        messageLabel.frame = CGRect(x: 16.fit, y: tipTitle.bottom + 8.fit,
                                    width: agreementCard.w - 32.fit, height: 18.fit)
        let privacyWidth = "《隐私政策》".size(font: AppFont.small).width + 4.fit
        let serviceWidth = "《服务协议》".size(font: AppFont.small).width + 4.fit
        privacyButton.frame = CGRect(x: 12.fit, y: messageLabel.bottom + 1.fit,
                                     width: privacyWidth, height: 24.fit)
        serviceButton.frame = CGRect(x: privacyButton.right, y: privacyButton.y,
                                     width: serviceWidth, height: privacyButton.h)
        consentLabel.frame = CGRect(x: 16.fit, y: privacyButton.bottom + 3.fit,
                                    width: agreementCard.w - 32.fit, height: 16.fit)

        let buttonWidth = (agreementCard.w - 48.fit - 24.fit) / 2
        disagreeButton.frame = CGRect(x: 24.fit, y: agreementCard.h - 52.fit,
                                      width: buttonWidth, height: 36.fit)
        agreeButton.frame = CGRect(x: disagreeButton.right + 24.fit, y: disagreeButton.y,
                                   width: buttonWidth, height: 36.fit)
    }

    @objc private func agreeTapped() {
        PrivacyConsentStore.accept()
        onAgree?()
    }

    @objc private func disagreeTapped() {
        let alert = UIAlertController(title: "温馨提示",
                                      message: "需要同意隐私政策与服务协议后才能继续使用巡朋机械。",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "我知道了", style: .default))
        present(alert, animated: true)
    }

    @objc private func privacyPolicyTapped() {
        openAgreement(urlString: Constants.privacyPolicyURL, title: "隐私政策")
    }

    @objc private func serviceAgreementTapped() {
        openAgreement(urlString: Constants.serviceAgreementURL, title: "服务协议")
    }

    /// 与 LoginViewController 的协议点击逻辑保持一致，使用统一 WebView 页面展示。
    private func openAgreement(urlString: String, title: String) {
        guard !urlString.isEmpty, URL(string: urlString) != nil else {
            Toast.shared.show("协议地址暂未配置")
            return
        }

        let webVC = PNSPrivacyWebViewController(urlString: urlString, title: title)
        let nav = UINavigationController(rootViewController: webVC)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }
}
