//
//  LoginViewController.swift
//  XunPengMachine
//
//  登录/注册页（对齐设计稿 B-4）
//

import UIKit

final class LoginViewController: BaseViewController {

    private let viewModel = LoginViewModel()

    private let navBar = UIView()
    private let navTitle = UILabel.make("登录/注册", font: AppFont.navTitle, color: .white, alignment: .center)

    private let phoneRow = LoginInputRow(label: "手机号", placeholder: "请输入手机号")
    private let codeRow = LoginInputRow(label: "验证码", placeholder: "请输入短信验证码", showAction: true)
    private let loginBtn = AppButton(title: "登录", style: .primary, height: 44)
    private let quickLoginBtn = UIButton.make("使用本机号码快速登录", font: AppFont.body, titleColor: AppColor.primary)

    private let agreementView = UIView()
    private let checkBox = UIButton(type: .custom)
    private let agreementLabel = UILabel()
    private var selectedIdentityType: Int?

    override var navStyle: NavStyle {
        get { .none }
        set { /* 固定 none */ }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        view.backgroundColor = .white
        setupUI()
        bindViewModel()
    }

    private func setupUI() {
        navBar.backgroundColor = AppColor.navBar
        view.addSubview(navBar)
        navBar.addSubview(navTitle)

        view.addSubview(phoneRow)
        view.addSubview(codeRow)
        phoneRow.textField.keyboardType = .numberPad
        codeRow.textField.keyboardType = .numberPad
        phoneRow.textField.addTarget(self, action: #selector(phoneChanged), for: .editingChanged)
        codeRow.textField.addTarget(self, action: #selector(codeChanged), for: .editingChanged)
        codeRow.actionBtn.addTarget(self, action: #selector(sendCodeTapped), for: .touchUpInside)

        loginBtn.addTarget(self, action: #selector(loginTapped), for: .touchUpInside)
        loginBtn.isEnabled = false
        loginBtn.alpha = 0.5
        view.addSubview(loginBtn)

        quickLoginBtn.addTarget(self, action: #selector(quickLoginTapped), for: .touchUpInside)
        view.addSubview(quickLoginBtn)

        view.addSubview(agreementView)
        checkBox.setImage(UIImage(systemName: "circle"), for: .normal)
        checkBox.setImage(UIImage(systemName: "checkmark.circle.fill"), for: .selected)
        checkBox.tintColor = AppColor.primary
        checkBox.addTarget(self, action: #selector(checkToggled), for: .touchUpInside)
        agreementView.addSubview(checkBox)

        agreementLabel.font = AppFont.mini
        agreementLabel.textColor = AppColor.textSub
        agreementLabel.numberOfLines = 0
        let attrText = NSMutableAttributedString(string: "已阅读并同意")
        attrText.append(NSAttributedString(string: "《隐私协议》", attributes: [.foregroundColor: AppColor.primary]))
        attrText.append(NSAttributedString(string: "《服务协议》", attributes: [.foregroundColor: AppColor.primary]))
        attrText.append(NSAttributedString(string: "并授权巡朋机械APP获得本机号码"))
        agreementLabel.attributedText = attrText
        agreementView.addSubview(agreementLabel)
    }

    private func bindViewModel() {
        disposables.append(viewModel.countdown.subscribe(onNext: { [weak self] count in
            self?.updateSendButton(count: count)
        }))
        disposables.append(viewModel.loading.subscribe(onNext: { [weak self] loading in
            if loading { LoadingHUD.shared.show() } else { LoadingHUD.shared.hide() }
            self?.updateLoginButton()
        }))
        disposables.append(viewModel.loginSuccess.subscribe(onNext: { [weak self] success in
            guard success else {
                // 登录失败，关闭授权页并提示
                AuthSDKManager.shared.cancelLoginVC(animated: true)
                return
            }
            self?.enterMain()
        }))
    }

    private func updateSendButton(count: Int) {
        if count > 0 {
            codeRow.actionBtn.setTitle("\(count)s 后重发", for: .normal)
            codeRow.actionBtn.setTitleColor(AppColor.textHint, for: .normal)
            codeRow.actionBtn.isEnabled = false
        } else {
            codeRow.actionBtn.setTitle("获取验证码", for: .normal)
            codeRow.actionBtn.setTitleColor(.white, for: .normal)
            codeRow.actionBtn.isEnabled = !viewModel.loading.value
        }
    }

    private func updateLoginButton() {
        let phone = phoneRow.textField.text ?? ""
        let code = codeRow.textField.text ?? ""
        let enabled = phone.isValidPhone && code.isValidCode && checkBox.isSelected && !viewModel.loading.value
        loginBtn.isEnabled = enabled
        loginBtn.alpha = enabled ? 1 : 0.5
    }

    private func enterMain() {
        Logger.shared.track("enter_main")
        let tab = MainTabBarController()
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = scene.windows.first {
            UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve,
                              animations: { window.rootViewController = tab })
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        navBar.frame = CGRect(x: 0, y: 0, width: view.w, height: Screen.statusBarH + 44.fit)
        navTitle.frame = CGRect(x: 0, y: Screen.statusBarH, width: view.w, height: 44.fit)

        let rowH: CGFloat = 50.fit
        phoneRow.frame = CGRect(x: 0, y: navBar.bottom + 20.fit, width: view.w, height: rowH)
        codeRow.frame = CGRect(x: 0, y: phoneRow.bottom, width: view.w, height: rowH)

        let pad: CGFloat = 16.fit
        loginBtn.frame = CGRect(x: pad, y: codeRow.bottom + 24.fit, width: view.w - pad * 2, height: 44.fit)
        quickLoginBtn.frame = CGRect(x: pad, y: loginBtn.bottom + 16.fit, width: view.w - pad * 2, height: 24.fit)

        agreementView.frame = CGRect(x: pad, y: quickLoginBtn.bottom + 24.fit, width: view.w - pad * 2, height: 50.fit)
        checkBox.frame = CGRect(x: 0, y: 2, width: 20, height: 20)
        agreementLabel.frame = CGRect(x: 26, y: 0, width: agreementView.w - 26, height: 50)
    }

    @objc private func phoneChanged() {
        viewModel.phone.onNext(phoneRow.textField.text ?? "")
        updateLoginButton()
    }
    @objc private func codeChanged() {
        viewModel.code.onNext(codeRow.textField.text ?? "")
        updateLoginButton()
    }
    @objc private func sendCodeTapped() {
        view.endEditing(true)
        viewModel.sendCode()
    }
    @objc private func loginTapped() {
        view.endEditing(true)
        guard checkBox.isSelected else {
            Toast.shared.show("请先阅读并同意协议")
            return
        }
        presentIdentityPicker { [weak self] identityType in
            self?.viewModel.login(identityType: identityType)
        }
    }
    @objc private func quickLoginTapped() {
//        let controller = PNSStyleSelectController()
//        present(controller, animated: true)
//        navigationController?.pushViewController(controller, animated: true)
        presentIdentityPicker { [weak self] identityType in
            self?.selectedIdentityType = identityType
            self?.startLogin(style: .fullScreen)
        }
    }

    private func presentIdentityPicker(onPick: @escaping (Int) -> Void) {
        let picker = IdentityPickerViewController()
        picker.onPick = onPick
        picker.modalPresentationStyle = .overFullScreen
        picker.modalTransitionStyle = .crossDissolve
        present(picker, animated: true)
    }
    
    private func startLogin(style: LoginStyle) {
        // 直接显示授权页
        showAuthPage(style: style)
    }
    
    private func showAuthPage(style: LoginStyle) {
        let customModel = PNSAuthPageStyleBuilder.buildCustomModel(for: style)
        
        AuthSDKManager.shared.getLoginToken(controller: self, model: customModel) { [weak self] result in
            guard let self = self else { return }
            
            switch result.code {
            case .success:
                // 获取 token 成功
                guard let identityType = self.selectedIdentityType else {
                    Toast.shared.show("请先选择身份")
                    return
                }
                self.viewModel.onekeyLogin(result.token ?? "", identityType: identityType)
            case .clickPrivacy, .privacyAlertClickPrivacy:
                // 点击隐私协议富文本（主授权页 / 二次协议弹窗）
                self.openPrivacyPage(result: result)
                
            default:
                break
            }
        }
    }
    
    /// 打开隐私协议 WebView（授权页处于最顶层，在其之上再次 present）
    private func openPrivacyPage(result: AuthSDKResult) {
        guard let urlString = result.privacyURL, !urlString.isEmpty else {
            print("[Privacy] URL is empty, cannot navigate")
            return
        }
        
        DispatchQueue.main.async {
            let webVC = PNSPrivacyWebViewController(
                urlString: urlString,
                title: result.privacyName ?? "隐私协议"
            )
            let nav = UINavigationController(rootViewController: webVC)
            PNSUIUtils.topMostViewController().present(nav, animated: true)
        }
    }
    
    @objc private func checkToggled() {
        checkBox.isSelected.toggle()
        updateLoginButton()
    }
}

// MARK: - 登录输入行
private class LoginInputRow: UIView {
    let textField = UITextField()
    let actionBtn = UIButton(type: .custom)
    private let label = UILabel()
    private let line = Separator()

    init(label text: String, placeholder: String, showAction: Bool = false) {
        super.init(frame: .zero)
        label.text = text
        label.font = AppFont.body
        label.textColor = AppColor.textMain
        addSubview(label)

        textField.placeholder = placeholder
        textField.font = AppFont.body
        textField.borderStyle = .none
        textField.textAlignment = .right
        textField.textColor = AppColor.textMain
        textField.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [
                .foregroundColor: AppColor.textHint // 你的占位颜色
            ]
        )
        addSubview(textField)

        if showAction {
            actionBtn.setTitle("获取验证码", for: .normal)
            actionBtn.setTitleColor(.white, for: .normal)
            actionBtn.titleLabel?.font = AppFont.small
            actionBtn.backgroundColor = AppColor.primary
            actionBtn.layer.cornerRadius = 4.fit
            actionBtn.contentEdgeInsets = UIEdgeInsets(top: 6, left: 8, bottom: 6, right: 8)
            addSubview(actionBtn)
        }

        addSubview(line)
    }
    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        label.frame = CGRect(x: 16.fit, y: 0, width: 70.fit, height: h)
        if actionBtn.superview != nil {
            let btnW: CGFloat = 90.fit
            actionBtn.frame = CGRect(x: w - 16.fit - btnW, y: (h - 30.fit) / 2, width: btnW, height: 30.fit)
            textField.frame = CGRect(x: label.right + 8.fit, y: 0, width: actionBtn.x - label.right - 16.fit, height: h)
        } else {
            textField.frame = CGRect(x: label.right + 8.fit, y: 0, width: w - label.right - 24.fit, height: h)
        }
        line.frame = CGRect(x: 16.fit, y: h - 0.5, width: w - 32.fit, height: 0.5)
    }
}
