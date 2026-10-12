//
//  CarDetailViewController.swift
//  XunPengMachine
//
//  找设备-详情（对齐设计稿 4-2-找设备-详情.png）：
//  基本信息 + 出租详情 + 车辆地点(高德地图) + 温馨提示 + 图片集 + 底部拨打电话
//

import UIKit

final class CarDetailViewController: BaseViewController {

    private let carID: String
    private let vm: CarViewModel
    private var didApplyCar = false

    override var navStyle: NavStyle {
        get { .white }
        set { }
    }

    // 滚动容器
    private let scrollView = UIScrollView()
    private let contentContainer = UIView()

    // 基本信息卡
    private let infoCard = UIView()
    private let infoTitleLabel = UILabel.make("基本信息", font: AppFont.bodyM, color: AppColor.textMain)
    private let typeLabel = UILabel.make("", font: AppFont.body, color: AppColor.textMain)
    private let typeValueLabel = UILabel.make("", font: AppFont.body, color: AppColor.textMain)

    // 出租详情卡
    private let titleCard = UIView()
    private let sectionLabel = UILabel.make("出租详情", font: AppFont.bodyM, color: AppColor.textSub)
    private let titleLabel = UILabel.make("", font: AppFont.title, color: AppColor.textMain, lines: 2)
    private let publishTimeLabel = UILabel.make("", font: AppFont.small, color: AppColor.textHint)

    // 车辆地点卡（高德地图）
    private let locationCard = UIView()
    private let locationRow = UIView()
    private let locationLabel = UILabel.make("", font: AppFont.body, color: AppColor.textMain, lines: 1)
    private let locationArrow = UIImageView(image: UIImage(systemName: "chevron.right")?.withRenderingMode(.alwaysTemplate))
    private let mapPreview = MapPreviewView(title: "")

    // 温馨提示卡
    private let tipCard = UIView()
    private let tipTitleLabel = UILabel.make("温馨提示: 免责声明", font: AppFont.bodyM, color: AppColor.textMain)
    private let tipLabel = UILabel.make("", font: AppFont.small, color: AppColor.textSub, lines: 0)

    // 图片集（垂直拼接展示，可能为空）
    private let imagesCard = UIView()
    private let imagesTitleLabel = UILabel.make("设备图片", font: AppFont.bodyM, color: AppColor.textMain)
    private var imageViews: [WebImageView] = []

    // 底部栏
    private let bottomBar = UIView()
    private let callButton = AppButton(title: "拨打电话", style: .danger, height: 48)

    init(id: String) {
        self.carID = id
        self.vm = CarViewModel()
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - 生命周期
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "出租详情"
        setupBackButton()
        view.backgroundColor = AppColor.bg

        setupUI()
        bindViewModel()
        vm.loadDetail(id: carID)
        Logger.shared.track("car_detail_view", params: ["id": carID])
    }

    // MARK: - UI 搭建
    private func setupUI() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentContainer)

        // 基本信息卡
        setupCard(infoCard)
        infoCard.addSubview(infoTitleLabel)
        typeLabel.text = "机械类型"
        typeLabel.textColor = AppColor.textSub
        infoCard.addSubview(typeLabel)
        infoCard.addSubview(typeValueLabel)

        // 出租详情卡
        setupCard(titleCard)
        titleCard.addSubview(sectionLabel)
        titleCard.addSubview(titleLabel)
        titleCard.addSubview(publishTimeLabel)

        // 车辆地点卡
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

        // 图片集卡
        setupCard(imagesCard)
        imagesCard.addSubview(imagesTitleLabel)

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
        disposables.append(vm.detail.subscribe(onNext: { [weak self] car in
            guard let car = car else { return }
            self?.applyCar(car)
        }))
        disposables.append(vm.loading.subscribe(onNext: { loading in
            if loading { LoadingHUD.shared.show() } else { LoadingHUD.shared.hide() }
        }))
    }

    // MARK: - 数据渲染
    private func applyCar(_ car: Car) {
        didApplyCar = true

        // 基本信息
        typeValueLabel.text = car.type

        // 出租详情
        titleLabel.text = car.title
        publishTimeLabel.text = "发布时间 \(car.publishTime)"

        // 车辆地点
        let attr = NSMutableAttributedString(string: "车辆地点  ", attributes: [
            .font: AppFont.body, .foregroundColor: AppColor.textSub
        ])
        attr.append(NSAttributedString(string: "\(car.city)\(car.area)", attributes: [
            .font: AppFont.body, .foregroundColor: AppColor.textMain
        ]))
        locationLabel.attributedText = attr
        mapPreview.show(lat: car.latitude, lng: car.longitude, title: "\(car.city)\(car.area)")

        // 图片集：清空并重建
        imageViews.forEach { $0.removeFromSuperview() }
        imageViews.removeAll()
        for url in car.images {
            let imgView = WebImageView()
            imgView.contentMode = .scaleAspectFill
            imgView.clipsToBounds = true
            imgView.backgroundColor = AppColor.bg
            imgView.layer.cornerRadius = 4.fit
            imgView.setUrl(url)
            imagesCard.addSubview(imgView)
            imageViews.append(imgView)
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
        if didApplyCar { layoutContent() }
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

        // ===== 基本信息卡 =====
        let infoTitleH: CGFloat = 24.fit
        let rowH: CGFloat = 30.fit
        let infoH = innerPad + infoTitleH + 8.fit + rowH + innerPad
        infoCard.frame = CGRect(x: pad, y: y, width: cardW, height: infoH)
        infoTitleLabel.frame = CGRect(x: innerPad, y: innerPad, width: maxTextW, height: infoTitleH)
        let rowY = infoTitleLabel.bottom + 8.fit
        typeLabel.frame = CGRect(x: innerPad, y: rowY, width: 70.fit, height: rowH)
        typeValueLabel.frame = CGRect(x: innerPad + 70.fit, y: rowY,
                                      width: maxTextW - 70.fit, height: rowH)
        y = infoCard.bottom + pad

        // ===== 出租详情卡 =====
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

        // ===== 车辆地点卡 =====
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

        // ===== 图片集卡 =====
        let imgTitleH: CGFloat = 24.fit
        let imgGap: CGFloat = 8.fit
        let imgH: CGFloat = 200.fit
        let hasImages = !imageViews.isEmpty
        let imagesCardH: CGFloat
        if hasImages {
            let totalImgH = CGFloat(imageViews.count) * imgH + CGFloat(imageViews.count - 1) * imgGap
            imagesCardH = innerPad + imgTitleH + 8.fit + totalImgH + innerPad
        } else {
            // 无图：仅显示标题，高度最小
            imagesCardH = innerPad + imgTitleH + innerPad
        }
        imagesCard.frame = CGRect(x: pad, y: y, width: cardW, height: imagesCardH)
        imagesTitleLabel.frame = CGRect(x: innerPad, y: innerPad, width: maxTextW, height: imgTitleH)
        var imgY = imagesTitleLabel.bottom + 8.fit
        for imgView in imageViews {
            imgView.frame = CGRect(x: innerPad, y: imgY, width: maxTextW, height: imgH)
            imgY += imgH + imgGap
        }
        y = imagesCard.bottom + pad

        contentContainer.frame = CGRect(x: 0, y: 0, width: view.w, height: y)
        scrollView.contentSize = CGSize(width: view.w, height: y)
    }

    // MARK: - 事件
    @objc private func locationTapped() {
        Toast.shared.show("查看车辆位置")
    }

    @objc private func callTapped() {
        Logger.shared.track("car_detail_call")
        AlertManager.shared.showAlert(title: "拨打电话",
                                      message: "确认拨打电话联系车主？",
                                      confirmTitle: "拨打",
                                      confirmColor: AppColor.danger,
                                      onConfirm: {
            if let url = URL(string: "tel:13800000000") {
                UIApplication.shared.open(url)
            }
        })
    }
}
