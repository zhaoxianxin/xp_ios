//
//  JobDetailViewController.swift
//  XunPengMachine
//
//  找活-详情（对齐设计稿 2-2-找活详情.png）：
//  标题卡 + 基本信息卡（含高德地图）+ 温馨提示 + 底部拨打电话
//

import UIKit

final class JobDetailViewController: BaseViewController {

    private let jobID: Int64
    private let vm: JobViewModel
    private var didApplyJob = false

    override var navStyle: NavStyle {
        get { .white }
        set { }
    }

    // 滚动容器
    private let scrollView = UIScrollView()
    private let contentContainer = UIView()

    // 标题卡
    private let titleCard = UIView()
    private let sectionLabel = UILabel.make("租车详情", font: AppFont.bodyM, color: AppColor.textSub)
    private let titleLabel = UILabel.make("", font: AppFont.title, color: AppColor.textMain, lines: 2)
    private let publishTimeLabel = UILabel.make("", font: AppFont.small, color: AppColor.textHint)

    // 基本信息卡
    private let infoCard = UIView()
    private let infoTitleLabel = UILabel.make("基本信息", font: AppFont.bodyM, color: AppColor.textMain)
    private var infoRows: [(UILabel, UILabel)] = []

    // 施工地点卡（含高德地图）
    private let locationCard = UIView()
    private let locationRow = UIView()
    private let locationLabel = UILabel.make("", font: AppFont.body, color: AppColor.textMain, lines: 1)
    private let locationArrow = UIImageView(image: UIImage(systemName: "chevron.right")?.withRenderingMode(.alwaysTemplate))
    private let mapPreview = MapPreviewView(title: "")

    // 温馨提示卡
    private let tipCard = UIView()
    private let tipTitleLabel = UILabel.make("温馨提示: 免责声明", font: AppFont.bodyM, color: AppColor.textMain)
    private let tipLabel = UILabel.make("", font: AppFont.small, color: AppColor.textSub, lines: 0)

    // 底部栏
    private let bottomBar = UIView()
    private let callButton = AppButton(title: "拨打电话", style: .danger, height: 48)

    init(id: Int64) {
        self.jobID = id
        self.vm = JobViewModel()
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - 生命周期
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "求租详情"
        setupBackButton()
        view.backgroundColor = AppColor.bg

        setupUI()
        bindViewModel()
        vm.loadDetail(id: jobID)
        Logger.shared.track("job_detail_view", params: ["id": jobID])
    }

    // MARK: - UI 搭建
    private func setupUI() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentContainer)

        // 标题卡
        setupCard(titleCard)
        titleCard.addSubview(sectionLabel)
        titleCard.addSubview(titleLabel)
        titleCard.addSubview(publishTimeLabel)

        // 基本信息卡
        setupCard(infoCard)
        infoCard.addSubview(infoTitleLabel)
        // 信息行：机械类型 / 租金·工期 / 租车时间
        for title in ["机械类型", "租金", "租车时间", "发票类型", "用车描述"] {
            let l = UILabel.make(title, font: AppFont.body, color: AppColor.textSub)
            let v = UILabel.make("", font: AppFont.body, color: AppColor.textMain)
            infoCard.addSubview(l)
            infoCard.addSubview(v)
            infoRows.append((l, v))
        }

        // 施工地点卡（含高德地图）
        setupCard(locationCard)
        locationArrow.tintColor = AppColor.textHint
        locationRow.addSubview(locationLabel)
        locationRow.addSubview(locationArrow)
        locationRow.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(locationTapped)))
        locationCard.addSubview(locationRow)
        locationCard.addSubview(mapPreview)

        // 温馨提示卡
        setupCard(tipCard)
        tipCard.addSubview(tipTitleLabel)
        tipCard.addSubview(tipLabel)
        tipLabel.text = "达成交易前，请确认好对方身份，在双方确认交易达成前不要进行任何财务转账，交易双方可拍照保留证据，以免产生经济纠纷。巡朋机械可配合调查，但概不承担相应损失及责任。"

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
        disposables.append(vm.detail.subscribe(onNext: { [weak self] job in
            guard let job = job else { return }
            self?.applyJob(job)
        }))
        disposables.append(vm.loading.subscribe(onNext: { loading in
            if loading { LoadingHUD.shared.show() } else { LoadingHUD.shared.hide() }
        }))
    }

    // MARK: - 数据渲染
    private func applyJob(_ job: Job) {
        didApplyJob = true

        // 标题卡
        titleLabel.text = job.title
        publishTimeLabel.text = "发布时间 \(job.createTimeText)  ·  浏览 \(job.viewCount) 次"

        // 基本信息
        let values: [String] = [
            job.category,
            "\(job.rentAmountText)元    工期 \(job.durationText)",
            job.rentalTimeText.isEmpty ? "待沟通" : job.rentalTimeText,
            job.invoiceTypeText,
            job.description
        ]
        for (i, pair) in infoRows.enumerated() where i < values.count {
            pair.1.text = values[i]
        }

        // 施工地点
        let attr = NSMutableAttributedString(string: "施工地点  ", attributes: [
            .font: AppFont.body, .foregroundColor: AppColor.textSub
        ])
        attr.append(NSAttributedString(string: job.locationDisplayText, attributes: [
            .font: AppFont.body, .foregroundColor: AppColor.textMain
        ]))
        locationLabel.attributedText = attr

        // 地图展示
        if let latitude = job.workLat, let longitude = job.workLng {
            mapPreview.isHidden = false
            mapPreview.show(lat: latitude, lng: longitude, title: job.locationDisplayText)
        } else {
            mapPreview.isHidden = true
        }

        view.setNeedsLayout()
    }

    // MARK: - 布局
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let bottomBarH: CGFloat = 72.fit + Screen.bottomSafeH
        scrollView.frame = CGRect(x: 0, y: 0, width: view.w, height: view.h - bottomBarH)
        bottomBar.frame = CGRect(x: 0, y: view.h - bottomBarH, width: view.w, height: bottomBarH)
        layoutBottomBar()
        if didApplyJob { layoutContent() }
    }

    private func layoutBottomBar() {
        let btnH: CGFloat = 48.fit
        let btnY: CGFloat = 12.fit
        callButton.frame = CGRect(x: 16.fit, y: btnY,
                                  width: bottomBar.w - 32.fit, height: btnH)
    }

    private func layoutContent() {
        let pad: CGFloat = 12.fit
        let cardW = view.w - pad * 2
        let innerPad: CGFloat = 16.fit
        let maxTextW = cardW - innerPad * 2
        var y: CGFloat = pad

        // ===== 标题卡 =====
        let sectionH: CGFloat = 20.fit
        let titleH = (titleLabel.text ?? "").size(font: AppFont.title, maxWidth: maxTextW).height
        let publishH: CGFloat = 16.fit
        let titleCardH = innerPad + sectionH + 6.fit + titleH + 6.fit + publishH + innerPad
        titleCard.frame = CGRect(x: pad, y: y, width: cardW, height: titleCardH)
        sectionLabel.frame = CGRect(x: innerPad, y: innerPad, width: maxTextW, height: sectionH)
        titleLabel.frame = CGRect(x: innerPad, y: sectionLabel.bottom + 6.fit,
                                  width: maxTextW, height: titleH)
        publishTimeLabel.frame = CGRect(x: innerPad, y: titleLabel.bottom + 6.fit,
                                        width: maxTextW, height: publishH)
        y = titleCard.bottom + pad

        // ===== 基本信息卡 =====
        let infoTitleH: CGFloat = 24.fit
        let rowH: CGFloat = 30.fit
        let labelW: CGFloat = 70.fit
        let infoH = innerPad + infoTitleH + 8.fit
                    + rowH * CGFloat(infoRows.count)       // 机械类型 / 租金工期 / 租车时间
                    + innerPad
        infoCard.frame = CGRect(x: pad, y: y, width: cardW, height: infoH)
        infoTitleLabel.frame = CGRect(x: innerPad, y: innerPad, width: maxTextW, height: infoTitleH)

        var rowY = infoTitleLabel.bottom + 8.fit
        for pair in infoRows {
            pair.0.frame = CGRect(x: innerPad, y: rowY, width: labelW, height: rowH)
            pair.1.frame = CGRect(x: innerPad + labelW, y: rowY,
                                  width: maxTextW - labelW, height: rowH)
            rowY += rowH
        }
        y = infoCard.bottom + pad

        // ===== 施工地点卡（含高德地图） =====
        let locRowH: CGFloat = 30.fit
        let mapH: CGFloat = 140.fit
        let locH = innerPad + locRowH + 8.fit + mapH + innerPad
        locationCard.frame = CGRect(x: pad, y: y, width: cardW, height: locH)
        locationRow.frame = CGRect(x: innerPad, y: innerPad, width: maxTextW, height: locRowH)
        locationLabel.frame = CGRect(x: 0, y: 0, width: maxTextW - 20.fit, height: locRowH)
        locationArrow.frame = CGRect(x: maxTextW - 8.fit, y: (locRowH - 12.fit) / 2,
                                     width: 8.fit, height: 12.fit)
        mapPreview.frame = CGRect(x: innerPad, y: innerPad + locRowH + 8.fit,
                                  width: maxTextW, height: mapH)
        y = locationCard.bottom + pad

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
    @objc private func locationTapped() {
        // 跳转到地图全屏查看（暂用 Toast 提示）
        Toast.shared.show("查看地图位置")
    }

    @objc private func callTapped() {
        Logger.shared.track("job_detail_call")
        guard let mobile = vm.detail.value?.contactMobile, mobile.isValidPhone else {
            Toast.shared.show("暂无有效联系电话")
            return
        }
        AlertManager.shared.showAlert(title: "拨打电话",
                                      message: "确认拨打 \(mobile) 联系发布人？",
                                      confirmTitle: "拨打",
                                      confirmColor: AppColor.danger,
                                      onConfirm: {
            if let url = URL(string: "tel:\(mobile)") {
                UIApplication.shared.open(url)
            }
        })
    }
}
