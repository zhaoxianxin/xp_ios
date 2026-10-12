//
//  CarOwnerViewController.swift
//  XunPengMachine
//
//  车主四步认证：身份认证 / 驾驶证认证 / 行驶证认证 / 车辆认证
//

import UIKit

final class CarOwnerViewController: BaseViewController {

    private let viewModel = CarOwnerCertificationViewModel()
    private var selectedStep: OwnerCertificationStep = .identity
    private var imagesByStep: [OwnerCertificationStep: [Int: UIImage]] = [:]
    private var imageUrlsByStep: [OwnerCertificationStep: [Int: String]] = [:]
    private var resultsByStep: [OwnerCertificationStep: CertificationDisplayData] = [:]

    private let stepBar = OwnerCertificationStepBar()
    private let formView = OwnerCertificationFormView()
    private let resultView = OwnerCertificationResultView()
    private let bottomBar = UIView()
    private let submitButton = AppButton(title: "提交认证", style: .danger, height: 48)

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "身份认证"
        navStyle = .white
        setupBackButton()
        applyNavigationStyle()
        setupUI()
        bindViewModel()
        showStep(.identity)
        Logger.shared.track("car_owner_certification_view")
    }

    private func applyNavigationStyle() {
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationController?.navigationBar.tintColor = AppColor.textMain
        if #available(iOS 13.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = .white
            appearance.shadowColor = AppColor.separator
            appearance.titleTextAttributes = [
                .foregroundColor: AppColor.textMain,
                .font: AppFont.navTitle
            ]
            navigationController?.navigationBar.standardAppearance = appearance
            navigationController?.navigationBar.scrollEdgeAppearance = appearance
        } else {
            navigationController?.navigationBar.barTintColor = .white
            navigationController?.navigationBar.titleTextAttributes = [
                .foregroundColor: AppColor.textMain,
                .font: AppFont.navTitle
            ]
        }
    }

    private func setupUI() {
        view.backgroundColor = AppColor.bg
        view.addSubview(stepBar)
        view.addSubview(formView)
        view.addSubview(resultView)

        bottomBar.backgroundColor = .white
        view.addSubview(bottomBar)
        bottomBar.addSubview(submitButton)

        stepBar.onSelect = { [weak self] step in self?.showStep(step) }
        formView.onSelectImage = { [weak self] index in self?.selectImage(at: index) }
        submitButton.addTarget(self, action: #selector(submitTapped), for: .touchUpInside)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let safeTop = view.safeAreaInsets.top
        let safeBottom = view.safeAreaInsets.bottom
        let stepHeight: CGFloat = 44.fit
        let formHeight: CGFloat = 104.fit
        let bottomHeight: CGFloat = 76.fit + safeBottom

        stepBar.frame = CGRect(x: 0, y: safeTop, width: view.w, height: stepHeight)
        formView.frame = CGRect(x: 0, y: stepBar.bottom, width: view.w, height: formHeight)
        bottomBar.frame = CGRect(x: 0, y: view.h - bottomHeight,
                                 width: view.w, height: bottomHeight)
        resultView.frame = CGRect(x: 0, y: stepBar.bottom, width: view.w,
                                  height: bottomBar.y - stepBar.bottom)
        submitButton.frame = CGRect(x: 20.fit, y: 14.fit,
                                    width: bottomBar.w - 40.fit, height: 48.fit)
    }

    private func showStep(_ step: OwnerCertificationStep) {
        selectedStep = step
        stepBar.select(step)
        render(step)
        viewModel.loadResult(for: step) { [weak self] result in
            guard let self, self.selectedStep == step else { return }
            if let result {
                self.resultsByStep[step] = result
            } else {
                self.resultsByStep.removeValue(forKey: step)
            }
            self.render(step)
        }
        Logger.shared.track("car_owner_certification_step", params: ["step": step.rawValue + 1])
    }

    private func render(_ step: OwnerCertificationStep) {
        if let result = resultsByStep[step] {
            formView.isHidden = true
            resultView.isHidden = false
            resultView.configure(result)
            submitButton.setTitle(step == .vehicle ? "提交认证" : "下一步", for: .normal)
        } else {
            resultView.isHidden = true
            formView.isHidden = false
            let savedImages = imagesByStep[step] ?? [:]
            formView.configure(step: step,
                               firstImage: savedImages[0],
                               secondImage: savedImages[1])
            submitButton.setTitle("提交认证", for: .normal)
        }
    }

    private func bindViewModel() {
        disposables.append(viewModel.loading.subscribe(onNext: { loading in
            if loading { LoadingHUD.shared.show() } else { LoadingHUD.shared.hide() }
        }))
    }

    private func selectImage(at index: Int) {
        ImagePickerManager.shared.pick(from: self, maxCount: 1) { [weak self] images in
            guard let self, let image = images.first else { return }
            var stepImages = self.imagesByStep[self.selectedStep] ?? [:]
            stepImages[index] = image
            self.imagesByStep[self.selectedStep] = stepImages
            var stepUrls = self.imageUrlsByStep[self.selectedStep] ?? [:]
            stepUrls[index] = nil
            self.imageUrlsByStep[self.selectedStep] = stepUrls
            self.formView.setImage(image, at: index)
        }
    }

    /// 图片上传成功后由上传流程写入；四个认证提交接口只接收 URL。
    func setUploadedImageUrl(_ url: String, at index: Int,
                             for step: OwnerCertificationStep) {
        var urls = imageUrlsByStep[step] ?? [:]
        urls[index] = url
        imageUrlsByStep[step] = urls
    }

    @objc private func submitTapped() {
        if resultsByStep[selectedStep] != nil {
            guard let nextStep = OwnerCertificationStep(rawValue: selectedStep.rawValue + 1) else {
                showToast("车辆认证已完成")
                return
            }
            showStep(nextStep)
            return
        }

        let stepImages = imagesByStep[selectedStep] ?? [:]
        guard stepImages[0] != nil else {
            showToast("请先\(selectedStep.uploadTitles.0)")
            return
        }
        guard stepImages[1] != nil else {
            showToast("请先\(selectedStep.uploadTitles.1)")
            return
        }

        let urls = imageUrlsByStep[selectedStep] ?? [:]
        guard let firstUrl = urls[0], let secondUrl = urls[1],
              !firstUrl.isEmpty, !secondUrl.isEmpty else {
            showToast("认证图片尚未上传")
            return
        }

        Logger.shared.track("car_owner_certification_submit", params: [
            "step": selectedStep.rawValue + 1
        ])
        let submittingStep = selectedStep
        viewModel.submit(step: submittingStep, imageUrls: [firstUrl, secondUrl]) { [weak self] success in
            guard let self else { return }
            guard success else {
                self.showToast("提交认证失败")
                return
            }
            self.showToast("提交认证成功")
            self.resultsByStep.removeValue(forKey: submittingStep)
            self.showStep(submittingStep)
        }
    }
}

// MARK: - 四步分栏
private final class OwnerCertificationStepBar: UIView {
    var onSelect: ((OwnerCertificationStep) -> Void)?

    private var buttons: [UIButton] = []
    private let bottomLine = Separator()
    private var selectedStep: OwnerCertificationStep = .identity

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        for step in OwnerCertificationStep.allCases {
            let button = UIButton(type: .custom)
            button.tag = step.rawValue
            button.setTitle(step.title, for: .normal)
            button.titleLabel?.font = AppFont.small
            button.setTitleColor(AppColor.textHint, for: .normal)
            button.addTarget(self, action: #selector(stepTapped(_:)), for: .touchUpInside)
            addSubview(button)
            buttons.append(button)
        }
        addSubview(bottomLine)
        updateStyle()
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        let itemWidth = w / CGFloat(max(buttons.count, 1))
        for (index, button) in buttons.enumerated() {
            button.frame = CGRect(x: CGFloat(index) * itemWidth, y: 0,
                                  width: itemWidth, height: h - 0.5)
        }
        bottomLine.frame = CGRect(x: 0, y: h - 0.5, width: w, height: 0.5)
    }

    func select(_ step: OwnerCertificationStep) {
        selectedStep = step
        updateStyle()
    }

    private func updateStyle() {
        for button in buttons {
            let selected = button.tag == selectedStep.rawValue
            button.setTitleColor(selected ? AppColor.textMain : AppColor.textHint, for: .normal)
            button.titleLabel?.font = selected ? AppFont.bodyM : AppFont.small
        }
    }

    @objc private func stepTapped(_ sender: UIButton) {
        guard let step = OwnerCertificationStep(rawValue: sender.tag) else { return }
        onSelect?(step)
    }
}

// MARK: - 可复用认证填写组件
private final class OwnerCertificationFormView: UIView {
    var onSelectImage: ((Int) -> Void)?

    private let firstUploadView = CertificationImageUploadView()
    private let secondUploadView = CertificationImageUploadView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        addSubview(firstUploadView)
        addSubview(secondUploadView)
        firstUploadView.onTap = { [weak self] in self?.onSelectImage?(0) }
        secondUploadView.onTap = { [weak self] in self?.onSelectImage?(1) }
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        let horizontalPadding: CGFloat = 13.fit
        let spacing: CGFloat = 16.fit
        let itemWidth = (w - horizontalPadding * 2 - spacing) / 2
        let itemHeight: CGFloat = 68.fit
        firstUploadView.frame = CGRect(x: horizontalPadding, y: 8.fit,
                                       width: itemWidth, height: itemHeight)
        secondUploadView.frame = CGRect(x: firstUploadView.right + spacing, y: 8.fit,
                                        width: itemWidth, height: itemHeight)
    }

    func configure(step: OwnerCertificationStep, firstImage: UIImage?, secondImage: UIImage?) {
        let titles = step.uploadTitles
        firstUploadView.configure(title: titles.0, image: firstImage)
        secondUploadView.configure(title: titles.1, image: secondImage)
    }

    func setImage(_ image: UIImage, at index: Int) {
        if index == 0 { firstUploadView.setImage(image) }
        else { secondUploadView.setImage(image) }
    }
}

// MARK: - 认证结果展示组件
private final class OwnerCertificationResultView: UIScrollView {
    private let contentView = UIView()
    private let imageSection = UIView()
    private let firstImageView = WebImageView()
    private let secondImageView = WebImageView()
    private let rowsContainer = UIView()
    private var rowViews: [CertificationResultRowView] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = AppColor.bg
        alwaysBounceVertical = true
        showsVerticalScrollIndicator = false
        addSubview(contentView)
        imageSection.backgroundColor = .white
        contentView.addSubview(imageSection)
        imageSection.addSubview(firstImageView)
        imageSection.addSubview(secondImageView)
        rowsContainer.backgroundColor = .white
        contentView.addSubview(rowsContainer)
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(_ data: CertificationDisplayData) {
        firstImageView.setUrl(data.imageUrls.indices.contains(0) ? data.imageUrls[0] : nil)
        secondImageView.setUrl(data.imageUrls.indices.contains(1) ? data.imageUrls[1] : nil)

        rowViews.forEach { $0.removeFromSuperview() }
        rowViews = data.rows.map { row in
            let view = CertificationResultRowView()
            view.configure(row)
            rowsContainer.addSubview(view)
            return view
        }
        setNeedsLayout()
        layoutIfNeeded()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        contentView.frame = CGRect(x: 0, y: 0, width: w, height: 0)
        imageSection.frame = CGRect(x: 0, y: 0, width: w, height: 106.fit)

        let padding: CGFloat = 15.fit
        let spacing: CGFloat = 15.fit
        let imageWidth = (w - padding * 2 - spacing) / 2
        firstImageView.frame = CGRect(x: padding, y: 8.fit,
                                      width: imageWidth, height: 68.fit)
        secondImageView.frame = CGRect(x: firstImageView.right + spacing, y: 8.fit,
                                       width: imageWidth, height: 68.fit)

        let rowHeight: CGFloat = 38.fit
        rowsContainer.frame = CGRect(x: 0, y: imageSection.bottom + 8.fit,
                                     width: w, height: rowHeight * CGFloat(rowViews.count))
        for (index, rowView) in rowViews.enumerated() {
            rowView.frame = CGRect(x: 0, y: CGFloat(index) * rowHeight,
                                   width: rowsContainer.w, height: rowHeight)
        }
        contentView.frame.size.height = max(rowsContainer.bottom, h)
        contentSize = contentView.frame.size
    }
}

private final class CertificationResultRowView: UIView {
    private let titleLabel = UILabel.make("", font: AppFont.small, color: AppColor.textHint)
    private let valueLabel = UILabel.make("", font: AppFont.small,
                                          color: AppColor.textMain, alignment: .right)
    private let arrowView = UIImageView(image: UIImage(systemName: "chevron.right")?
        .withRenderingMode(.alwaysTemplate))
    private let separator = Separator()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        addSubview(titleLabel)
        addSubview(valueLabel)
        arrowView.tintColor = AppColor.textHint
        addSubview(arrowView)
        addSubview(separator)
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(_ row: CertificationDisplayRow) {
        titleLabel.text = row.title
        valueLabel.text = row.value
        arrowView.isHidden = !row.showsArrow
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let padding: CGFloat = 15.fit
        titleLabel.frame = CGRect(x: padding, y: 0, width: 120.fit, height: h)
        let arrowWidth: CGFloat = arrowView.isHidden ? 0 : 8.fit
        arrowView.frame = CGRect(x: w - padding - arrowWidth, y: (h - 12.fit) / 2,
                                 width: arrowWidth, height: 12.fit)
        valueLabel.frame = CGRect(x: titleLabel.right, y: 0,
                                  width: w - titleLabel.right - padding - arrowWidth - 6.fit,
                                  height: h)
        separator.frame = CGRect(x: padding, y: h - 0.5,
                                 width: w - padding, height: 0.5)
    }
}

private final class CertificationImageUploadView: UIControl {
    var onTap: (() -> Void)?

    private let imageView = UIImageView()
    private let plusLabel = UILabel.make("+", font: AppFont.regular(28),
                                         color: AppColor.textMain, alignment: .center)
    private let titleLabel = UILabel.make("", font: AppFont.small,
                                          color: AppColor.textMain, alignment: .center)
    private let imageTitleBackground = UIView()
    private var title = ""

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor(hex: 0xF0F0F0)
        clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        addSubview(imageView)
        addSubview(plusLabel)
        addSubview(titleLabel)
        imageTitleBackground.backgroundColor = UIColor.black.withAlphaComponent(0.45)
        imageTitleBackground.isHidden = true
        addSubview(imageTitleBackground)
        bringSubviewToFront(titleLabel)
        addTarget(self, action: #selector(tapped), for: .touchUpInside)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.frame = bounds
        plusLabel.frame = CGRect(x: 0, y: 8.fit, width: w, height: 30.fit)
        titleLabel.frame = CGRect(x: 4.fit, y: plusLabel.bottom,
                                  width: w - 8.fit, height: 22.fit)
        imageTitleBackground.frame = CGRect(x: 0, y: h - 24.fit, width: w, height: 24.fit)
        if imageView.image != nil { titleLabel.frame = imageTitleBackground.frame }
    }

    func configure(title: String, image: UIImage?) {
        self.title = title
        titleLabel.text = title
        setImage(image)
    }

    func setImage(_ image: UIImage?) {
        imageView.image = image
        let hasImage = image != nil
        plusLabel.isHidden = hasImage
        imageTitleBackground.isHidden = !hasImage
        titleLabel.textColor = hasImage ? .white : AppColor.textMain
        accessibilityLabel = title
        setNeedsLayout()
    }

    @objc private func tapped() { onTap?() }
}
