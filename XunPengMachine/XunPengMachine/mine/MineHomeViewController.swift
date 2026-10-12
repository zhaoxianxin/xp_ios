//
//  MineHomeViewController.swift
//  XunPengMachine
//
//  我的-个人中心（对齐设计稿）
//

import UIKit

final class MineHomeViewController: BaseViewController {

    private let vm = MineViewModel()
    private let scrollView = UIScrollView()
    private let contentView = UIView()

    private let navBar = UIView()
    private let navTitle = UILabel.make("个人中心", font: AppFont.navTitle, color: .white, alignment: .center)

    private let identityCard = UIView()
    private let roleLabel = UILabel.make("老板身份", font: AppFont.bodyM, color: AppColor.primary)
    private let roleDescLabel = UILabel.make("(发布活源/招聘司机)", font: AppFont.small, color: AppColor.textSub)
    private let certifyBtn = UIButton.make("点此实名认证 >", font: AppFont.small, titleColor: AppColor.textHint)
    private let phoneLabel = UILabel.make("", font: AppFont.body, color: AppColor.textMain)
    private let editPhoneBtn = UIButton.make("点此修改 >", font: AppFont.small, titleColor: AppColor.textHint)

    private let switchTitle = UILabel.make("身份切换", font: AppFont.bodyM, color: AppColor.textMain)
    private let ownerBtn = IdentitySwitchButton(title: "车主身份", subtitle: "(出租车辆/招聘司机)")
    private let driverBtn = IdentitySwitchButton(title: "驾驶员身份", subtitle: "(求职司机/应聘司机)")

    private let manageCard = UIView()
    private let serviceTitle = UILabel.make("服务功能", font: AppFont.bodyM, color: AppColor.textMain)
    private let settingsRow = MenuRowView(title: "设置中心")

    override var navStyle: NavStyle {
        get { .none }
        set { /* 固定隐藏系统导航栏 */ }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        view.backgroundColor = AppColor.bg
        setupUI()
        bindViewModel()
        vm.loadProfile()
        Logger.shared.track("mine_home_view")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    private func setupUI() {
        view.addSubview(navBar)
        navBar.backgroundColor = AppColor.navBar
        navBar.addSubview(navTitle)

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        // 身份信息卡
        identityCard.backgroundColor = .white
        identityCard.layer.cornerRadius = 8.fit
        contentView.addSubview(identityCard)
        identityCard.addSubview(roleLabel)
        identityCard.addSubview(roleDescLabel)
        identityCard.addSubview(certifyBtn)
        identityCard.addSubview(phoneLabel)
        identityCard.addSubview(editPhoneBtn)
        certifyBtn.addTarget(self, action: #selector(certifyTapped), for: .touchUpInside)
        editPhoneBtn.addTarget(self, action: #selector(editPhoneTapped), for: .touchUpInside)

        contentView.addSubview(switchTitle)
        contentView.addSubview(ownerBtn)
        contentView.addSubview(driverBtn)
        ownerBtn.addTarget(self, action: #selector(switchOwner), for: .touchUpInside)
        driverBtn.addTarget(self, action: #selector(switchDriver), for: .touchUpInside)

        manageCard.backgroundColor = .white
        manageCard.layer.cornerRadius = 8.fit
        contentView.addSubview(manageCard)
        addManageRow("发布的活源") { [weak self] in
            let controller = MyPublishedViewController(initialTab: .jobs)
            self?.navigationController?.pushViewController(controller, animated: true)
        }
        addManageRow("发布的招聘") { [weak self] in
            let controller = MyPublishedViewController(initialTab: .recruitments)
            self?.navigationController?.pushViewController(controller, animated: true)
        }

        contentView.addSubview(serviceTitle)
        let serviceRow = ServiceRowView(items: [
            ("联系客服", { [weak self] in self?.goContact() }),
            ("意见反馈", { [weak self] in self?.goFeedback() }),
            ("系统消息", { [weak self] in
                self?.navigationController?.pushViewController(
                    SystemMessageViewController(),
                    animated: true
                )
            })
        ])
        contentView.addSubview(serviceRow)

        settingsRow.onTap = { [weak self] in
            self?.navigationController?.pushViewController(SettingsViewController(), animated: true)
        }
        contentView.addSubview(settingsRow)
    }

    private var manageRows: [(UIView, () -> Void)] = []

    private func addManageRow(_ title: String, action: @escaping () -> Void) {
        let row = ManageRowView(title: title)
        manageCard.addSubview(row)
        manageRows.append((row, action))
        row.onTap = action
    }

    private func bindViewModel() {
        disposables.append(vm.profile.subscribe(onNext: { [weak self] user in
            self?.render(user: user)
        }))
        disposables.append(vm.loading.subscribe(onNext: { loading in
            if loading { LoadingHUD.shared.show() } else { LoadingHUD.shared.hide() }
        }))
    }

    private func render(user: User?) {
        guard let user = user else { return }
        phoneLabel.text = user.mobile.phoneMasked
        roleLabel.text = user.identityName

        switch user.identityType {
        case 2:
            roleDescLabel.text = "(出租车辆/招聘司机)"
        case 3:
            roleDescLabel.text = "(求职司机/应聘司机)"
        default:
            roleDescLabel.text = "(发布活源/招聘司机)"
        }

        let certifyTitle = user.realNameVerify ? "已实名 >" : "点此实名认证 >"
        certifyBtn.setTitle(certifyTitle, for: .normal)
        certifyBtn.setTitleColor(user.realNameVerify ? AppColor.textMain : AppColor.textHint,
                                 for: .normal)
        certifyBtn.isHidden = false
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let pad: CGFloat = 12.fit
        navBar.frame = CGRect(x: 0, y: 0, width: view.w, height: Screen.statusBarH + 44.fit)
        navTitle.frame = CGRect(x: 0, y: Screen.statusBarH, width: view.w, height: 44.fit)

        scrollView.frame = CGRect(x: 0, y: navBar.bottom, width: view.w,
                                  height: view.h - navBar.bottom - Screen.tabBarH)
        contentView.frame = CGRect(x: 0, y: 0, width: view.w, height: 800.fit)

        identityCard.frame = CGRect(x: pad, y: 12.fit, width: view.w - pad * 2, height: 80.fit)
        roleLabel.frame = CGRect(x: 16.fit, y: 16.fit, width: 80.fit, height: 20.fit)
        roleDescLabel.frame = CGRect(x: roleLabel.right + 4.fit, y: 18.fit, width: 160.fit, height: 16.fit)
        certifyBtn.frame = CGRect(x: identityCard.w - 120.fit, y: 16.fit, width: 110.fit, height: 20.fit)
        phoneLabel.frame = CGRect(x: 16.fit, y: 48.fit, width: 120.fit, height: 20.fit)
        editPhoneBtn.frame = CGRect(x: phoneLabel.right + 8.fit, y: 48.fit, width: 80.fit, height: 20.fit)

        switchTitle.frame = CGRect(x: pad, y: identityCard.bottom + 16.fit, width: 100.fit, height: 20.fit)
        let btnW = (view.w - pad * 2 - 8.fit) / 2
        ownerBtn.frame = CGRect(x: pad, y: switchTitle.bottom + 8.fit, width: btnW, height: 56.fit)
        driverBtn.frame = CGRect(x: ownerBtn.right + 8.fit, y: ownerBtn.y, width: btnW, height: 56.fit)

        manageCard.frame = CGRect(x: pad, y: ownerBtn.bottom + 16.fit, width: view.w - pad * 2, height: CGFloat(manageRows.count) * 50.fit)
        for (i, (row, _)) in manageRows.enumerated() {
            (row as? ManageRowView)?.frame = CGRect(x: 0, y: CGFloat(i) * 50.fit, width: manageCard.w, height: 50.fit)
        }

        let serviceY = manageCard.bottom + 16.fit
        serviceTitle.frame = CGRect(x: pad, y: serviceY, width: 100.fit, height: 20.fit)
        if let serviceRow = contentView.subviews.compactMap({ $0 as? ServiceRowView }).first {
            serviceRow.frame = CGRect(x: pad, y: serviceTitle.bottom + 8.fit, width: view.w - pad * 2, height: 44.fit)
        }
        settingsRow.frame = CGRect(x: pad, y: serviceTitle.bottom + 60.fit, width: view.w - pad * 2, height: 50.fit)

        contentView.frame.size.height = settingsRow.bottom + 20.fit
        scrollView.contentSize = contentView.frame.size
    }

    @objc private func certifyTapped() {
        navigationController?.pushViewController(CarOwnerViewController(), animated: true)
    }
    @objc private func editPhoneTapped() { showToast("修改手机号功能开发中") }
    @objc private func switchOwner() {
        navigationController?.pushViewController(CarOwnerViewController(), animated: true)
    }
    @objc private func switchDriver() { showToast("驾驶员身份功能开发中") }
    private func goContact() {
        navigationController?.pushViewController(ContactServiceViewController(), animated: true)
    }
    private func goFeedback() {
        navigationController?.pushViewController(FeedbackViewController(), animated: true)
    }
}

// MARK: - 子组件
private class IdentitySwitchButton: UIControl {
    private let titleLbl = UILabel()
    private let subLbl = UILabel()

    init(title: String, subtitle: String) {
        super.init(frame: .zero)
        backgroundColor = AppColor.bg
        layer.cornerRadius = 8.fit
        titleLbl.text = title
        titleLbl.font = AppFont.bodyM
        titleLbl.textColor = AppColor.textMain
        subLbl.text = subtitle
        subLbl.font = AppFont.mini
        subLbl.textColor = AppColor.textHint
        addSubview(titleLbl)
        addSubview(subLbl)
    }
    required init?(coder: NSCoder) { fatalError() }
    override func layoutSubviews() {
        super.layoutSubviews()
        titleLbl.frame = CGRect(x: 12.fit, y: 10.fit, width: w - 24.fit, height: 18.fit)
        subLbl.frame = CGRect(x: 12.fit, y: titleLbl.bottom + 4.fit, width: w - 24.fit, height: 14.fit)
    }
}

private class ManageRowView: UIControl {
    var onTap: (() -> Void)?
    init(title: String) {
        super.init(frame: .zero)
        let lbl = UILabel.make(title, font: AppFont.body, color: AppColor.textMain)
        let action = UILabel.make("点此查看 >", font: AppFont.small, color: AppColor.textHint)
        addSubview(lbl)
        addSubview(action)
        lbl.frame = CGRect(x: 16.fit, y: 0, width: 120.fit, height: 50.fit)
        action.frame = CGRect(x: Screen.width - 120.fit, y: 0, width: 90.fit, height: 50.fit)
        addTarget(self, action: #selector(tapped), for: .touchUpInside)
    }
    required init?(coder: NSCoder) { fatalError() }
    @objc private func tapped() { onTap?() }
}

private class ServiceRowView: UIView {
    init(items: [(String, () -> Void)]) {
        super.init(frame: .zero)
        backgroundColor = .white
        layer.cornerRadius = 8.fit
        let colW = (Screen.width - 24.fit) / CGFloat(items.count)
        for (i, item) in items.enumerated() {
            let btn = UIButton.make(item.0, font: AppFont.body, titleColor: AppColor.textMain)
            btn.frame = CGRect(x: CGFloat(i) * colW, y: 0, width: colW, height: 44.fit)
            btn.addAction(UIAction { _ in item.1() }, for: .touchUpInside)
            addSubview(btn)
        }
    }
    required init?(coder: NSCoder) { fatalError() }
}

private class MenuRowView: UIControl {
    var onTap: (() -> Void)?
    init(title: String) {
        super.init(frame: .zero)
        backgroundColor = .white
        layer.cornerRadius = 8.fit
        let lbl = UILabel.make(title, font: AppFont.body, color: AppColor.textMain)
        let arrow = UIImageView(image: UIImage(systemName: "chevron.right")?.withRenderingMode(.alwaysTemplate))
        arrow.tintColor = AppColor.textHint
        addSubview(lbl)
        addSubview(arrow)
        lbl.frame = CGRect(x: 16.fit, y: 0, width: 120.fit, height: 50.fit)
        arrow.frame = CGRect(x: Screen.width - 48.fit, y: 19.fit, width: 8, height: 12)
        addTarget(self, action: #selector(tapped), for: .touchUpInside)
    }
    required init?(coder: NSCoder) { fatalError() }
    @objc private func tapped() { onTap?() }
}
