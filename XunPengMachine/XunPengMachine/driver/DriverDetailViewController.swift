//
//  DriverDetailViewController.swift
//  XunPengMachine
//
//  招司机-详情（对齐设计稿 6-1-找司机-详情.png）：
//  招聘信息 + 工作介绍 + 温馨提示 + 底部拨打电话
//

import UIKit

final class DriverDetailViewController: BaseViewController {

    private let driverID: String
    private let vm: DriverViewModel
    private var didApplyDriver = false

    override var navStyle: NavStyle {
        get { .white }
        set { }
    }

    // 滚动容器
    private let scrollView = UIScrollView()
    private let contentContainer = UIView()

    // 招聘信息卡
    private let infoCard = UIView()
    private let infoTitleLabel = UILabel.make("招聘信息", font: AppFont.bodyM, color: AppColor.textMain)
    // 第一行：机械类型 + 工资
    private let typeLabel = UILabel.make("机械类型", font: AppFont.body, color: AppColor.textSub)
    private let typeValueLabel = UILabel.make("", font: AppFont.body, color: AppColor.primary)
    private let salaryLabel = UILabel.make("工资", font: AppFont.body, color: AppColor.textSub)
    private let salaryValueLabel = UILabel.make("", font: AppFont.body, color: AppColor.primary)
    // 第二行：工作地点 + 工作周期
    private let cityLabel = UILabel.make("工作地点", font: AppFont.body, color: AppColor.textSub)
    private let cityValueLabel = UILabel.make("", font: AppFont.body, color: AppColor.primary)
    private let periodLabel = UILabel.make("", font: AppFont.body, color: AppColor.textSub)

    // 工作介绍卡
    private let introCard = UIView()
    private let introTitleLabel = UILabel.make("工作介绍", font: AppFont.bodyM, color: AppColor.textMain)
    private let introLabel = UILabel.make("", font: AppFont.body, color: AppColor.textSub, lines: 0)
    private let publishTimeLabel = UILabel.make("", font: AppFont.small, color: AppColor.textHint)

    // 温馨提示卡
    private let tipCard = UIView()
    private let tipTitleLabel = UILabel.make("温馨提示: 免责声明", font: AppFont.bodyM, color: AppColor.textMain)
    private let tipLabel = UILabel.make("", font: AppFont.small, color: AppColor.textSub, lines: 0)

    // 底部栏
    private let bottomBar = UIView()
    private let callButton = AppButton(title: "拨打电话", style: .danger, height: 48)

    init(id: String) {
        self.driverID = id
        self.vm = DriverViewModel()
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - 生命周期
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "招聘详情"
        setupBackButton()
        view.backgroundColor = AppColor.bg

        setupUI()
        bindViewModel()
        vm.loadDetail(id: driverID)
        Logger.shared.track("driver_detail_view", params: ["id": driverID])
    }

    // MARK: - UI 搭建
    private func setupUI() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentContainer)

        // 招聘信息卡
        setupCard(infoCard)
        infoCard.addSubview(infoTitleLabel)
        infoCard.addSubview(typeLabel)
        infoCard.addSubview(typeValueLabel)
        infoCard.addSubview(salaryLabel)
        infoCard.addSubview(salaryValueLabel)
        infoCard.addSubview(cityLabel)
        infoCard.addSubview(cityValueLabel)
        infoCard.addSubview(periodLabel)

        // 工作介绍卡
        setupCard(introCard)
        introCard.addSubview(introTitleLabel)
        introCard.addSubview(introLabel)
        introCard.addSubview(publishTimeLabel)

        // 温馨提示卡
        setupCard(tipCard)
        tipCard.addSubview(tipTitleLabel)
        tipCard.addSubview(tipLabel)
        tipLabel.text = "严禁用人单位和招聘用户做出任何损害求职者合法权益的违法违规行为，包括但不限于扣押求职者证件、收取求职者财务让求职者入股。到岗前不要进行任何财务转账，防止被骗。工作期间双方可拍照保留证据，以免产生经济纠纷。巡朋机械可配合调查，但概不承担相应损失及责任。"

        // 底部栏
        bottomBar.backgroundColor = AppColor.cardBg
        view.addSubview(bottomBar)
        callButton.addTarget(self, action: #selector(callTapped), for: .touchUpInside)
        bottomBar.addSubview(callButton)
    }

    private func setupCard(_ card: UIView) {
        card.backgroundColor = AppColor.cardBg
        contentContainer.addSubview(card)
    }

    private func bindViewModel() {
        disposables.append(vm.detail.subscribe(onNext: { [weak self] driver in
            guard let driver = driver else { return }
            self?.applyDriver(driver)
        }))
        disposables.append(vm.loading.subscribe(onNext: { loading in
            if loading { LoadingHUD.shared.show() } else { LoadingHUD.shared.hide() }
        }))
    }

    // MARK: - 数据渲染
    private func applyDriver(_ driver: Driver) {
        didApplyDriver = true

        // 招聘信息
        typeValueLabel.text = driver.category
        salaryValueLabel.text = driver.salaryDisplayText
        cityValueLabel.text = driver.locationDisplayText
        periodLabel.text = driver.workTypeDisplayText

        // 工作介绍
        introLabel.text = driver.description
        publishTimeLabel.text = "发布时间  \(driver.createTimeDisplayText)"

        view.setNeedsLayout()
    }

    // MARK: - 布局
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let bottomBarH: CGFloat = 72.fit + Screen.bottomSafeH
        scrollView.frame = CGRect(x: 0, y: 0, width: view.w, height: view.h - bottomBarH)
        bottomBar.frame = CGRect(x: 0, y: view.h - bottomBarH, width: view.w, height: bottomBarH)
        layoutBottomBar()
        if didApplyDriver { layoutContent() }
    }

    private func layoutBottomBar() {
        let btnH: CGFloat = 48.fit
        callButton.frame = CGRect(x: 16.fit, y: 12.fit,
                                  width: bottomBar.w - 32.fit, height: btnH)
    }

    private func layoutContent() {
        let pad: CGFloat = 12.fit
        let cardW = view.w - pad * 2
        let innerPad: CGFloat = 16.fit
        let maxTextW = cardW - innerPad * 2
        var y: CGFloat = pad

        // ===== 招聘信息卡 =====
        let infoTitleH: CGFloat = 24.fit
        let rowH: CGFloat = 30.fit
        let infoH = innerPad + infoTitleH + 8.fit + rowH * 2 + innerPad
        infoCard.frame = CGRect(x: pad, y: y, width: cardW, height: infoH)
        infoTitleLabel.frame = CGRect(x: innerPad, y: innerPad, width: maxTextW, height: infoTitleH)

        // 第一行：机械类型 + 工资（各占一半）
        let halfW = (maxTextW - 8.fit) / 2
        let rowY1 = infoTitleLabel.bottom + 8.fit
        typeLabel.sizeToFit()
        typeLabel.frame = CGRect(x: innerPad, y: rowY1, width: typeLabel.w, height: rowH)
        typeValueLabel.frame = CGRect(x: typeLabel.right + 4.fit, y: rowY1,
                                      width: halfW - typeLabel.w - 4.fit, height: rowH)
        salaryLabel.sizeToFit()
        salaryLabel.frame = CGRect(x: innerPad + halfW + 8.fit, y: rowY1, width: salaryLabel.w, height: rowH)
        salaryValueLabel.frame = CGRect(x: salaryLabel.right + 4.fit, y: rowY1,
                                        width: halfW - salaryLabel.w - 4.fit, height: rowH)

        // 第二行：工作地点 + 工作周期
        let rowY2 = rowY1 + rowH
        cityLabel.sizeToFit()
        cityLabel.frame = CGRect(x: innerPad, y: rowY2, width: cityLabel.w, height: rowH)
        cityValueLabel.frame = CGRect(x: cityLabel.right + 4.fit, y: rowY2,
                                      width: halfW - cityLabel.w - 4.fit, height: rowH)
        periodLabel.sizeToFit()
        periodLabel.frame = CGRect(x: innerPad + halfW + 8.fit, y: rowY2,
                                   width: maxTextW - halfW - 8.fit, height: rowH)
        y = infoCard.bottom + pad

        // ===== 工作介绍卡 =====
        let introTitleH: CGFloat = 24.fit
        let introTextH = (introLabel.text ?? "").size(font: AppFont.body, maxWidth: maxTextW).height
        let publishH: CGFloat = 16.fit
        let introH = innerPad + introTitleH + 6.fit + introTextH + 6.fit + publishH + innerPad
        introCard.frame = CGRect(x: pad, y: y, width: cardW, height: introH)
        introTitleLabel.frame = CGRect(x: innerPad, y: innerPad, width: maxTextW, height: introTitleH)
        introLabel.frame = CGRect(x: innerPad, y: introTitleLabel.bottom + 6.fit,
                                  width: maxTextW, height: introTextH)
        publishTimeLabel.frame = CGRect(x: innerPad, y: introLabel.bottom + 6.fit,
                                        width: maxTextW, height: publishH)
        y = introCard.bottom + pad

        // ===== 温馨提示卡 =====
        let tipTitleH: CGFloat = 24.fit
        let tipTextH = (tipLabel.text ?? "").size(font: AppFont.small, maxWidth: maxTextW).height
        let tipCardH = innerPad + tipTitleH + 6.fit + tipTextH + innerPad
        tipCard.frame = CGRect(x: pad, y: y, width: cardW, height: tipCardH)
        tipTitleLabel.frame = CGRect(x: innerPad, y: innerPad, width: maxTextW, height: tipTitleH)
        tipLabel.frame = CGRect(x: innerPad, y: tipTitleLabel.bottom + 6.fit,
                                 width: maxTextW, height: tipTextH)
        y = tipCard.bottom + pad

        contentContainer.frame = CGRect(x: 0, y: 0, width: view.w, height: y)
        scrollView.contentSize = CGSize(width: view.w, height: y)
    }

    // MARK: - 事件
    @objc private func callTapped() {
        Logger.shared.track("driver_detail_call")
        let phone = vm.detail.value?.contactMobile ?? ""
        guard !phone.isEmpty else {
            showToast("暂无有效联系电话")
            return
        }
        AlertManager.shared.showAlert(title: "拨打电话",
                                      message: "确认拨打电话联系招聘方？",
                                      confirmTitle: "拨打",
                                      confirmColor: AppColor.danger,
                                      onConfirm: {
            if let url = URL(string: "tel:\(phone)") {
                UIApplication.shared.open(url)
            }
        })
    }
}
