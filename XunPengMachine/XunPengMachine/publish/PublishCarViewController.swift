//
//  PublishCarViewController.swift
//  XunPengMachine
//
//  发布出租表单：机械类型/联系电话/车辆地点/车辆照片/出租描述说明
//

import UIKit

final class PublishCarViewController: BaseViewController {

    private let vm = PublishViewModel()

    // MARK: State
    private var equipmentName: String = ""
    private var cityId: Int64?
    private var images: [UIImage] = []
    /// 图片上传成功后由上传流程写入，发布接口只接收 URL。
    private var imageUrls: [String] = []
    private let maxImageCount = 3
    private let maxDescCount = 30
    private let phone = "15963229366"

    // MARK: UI
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let cardView = UIView()
    private let submitBtn = AppButton(title: "立即发布", style: .danger, height: 48)

    private lazy var titleRow = FormRow(title: "标题", required: true,
                                        placeholder: "请输入出租标题")
    private lazy var equipmentRow = FormRow(title: "机械类型", required: true,
                                            placeholder: "请选择", showArrow: true)
    private lazy var phoneRow = FormRow(title: "联系电话", required: true,
                                        placeholder: phone, hint: "可修改>")
    private lazy var cityRow = FormRow(title: "车辆地点", required: true,
                                       placeholder: "请选择", showArrow: true)
    private lazy var addressRow = FormRow(title: "详细地址", required: true,
                                          placeholder: "请输入详细地址")
    private lazy var imageRow = ImageGridRow(title: "车辆照片", required: true,
                                             maxCount: maxImageCount)
    private lazy var descRow = TextareaRow(title: "出租描述说明", required: true,
                                           placeholder: "请描述车辆具体位置以及型号",
                                           maxCount: maxDescCount)

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "发布出租"
        navStyle = .white
        setupBackButton()
        view.backgroundColor = AppColor.bg
        setupUI()
        bindViewModel()
    }

    private func setupUI() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        scrollView.alwaysBounceVertical = true
        scrollView.keyboardDismissMode = .onDrag

        cardView.backgroundColor = .white
        cardView.layer.cornerRadius = 8.fit
        cardView.layer.masksToBounds = true
        contentView.addSubview(cardView)

        let rows: [UIView] = [titleRow, equipmentRow, phoneRow, cityRow, addressRow,
                              imageRow, descRow]
        rows.forEach { cardView.addSubview($0) }
        for i in 0..<(rows.count - 1) {
            let sep = Separator()
            sep.tag = i
            cardView.addSubview(sep)
        }

        // Pre-fill phone
        phoneRow.setValue(phone)
        phoneRow.setInputMode(keyboardType: .numberPad)

        equipmentRow.onTap = { [weak self] in
            self?.showEquipmentPicker()
        }
        cityRow.onTap = { [weak self] in
            self?.showCityPicker()
        }

        // Image picker
        imageRow.onAddImage = { [weak self] in
            guard let self = self else { return }
            self.view.endEditing(true)
            ImagePickerManager.shared.pick(from: self,
                                            maxCount: self.maxImageCount - self.images.count) { [weak self] newImages in
                guard let self = self else { return }
                self.images.append(contentsOf: newImages)
                if self.images.count > self.maxImageCount {
                    self.images = Array(self.images.prefix(self.maxImageCount))
                }
                self.imageUrls.removeAll()
                self.imageRow.updateImages(self.images)
                self.view.setNeedsLayout()
                self.view.layoutIfNeeded()
            }
        }
        imageRow.onRemoveImage = { [weak self] idx in
            guard let self = self else { return }
            guard idx < self.images.count else { return }
            self.images.remove(at: idx)
            self.imageUrls.removeAll()
            self.imageRow.updateImages(self.images)
            self.view.setNeedsLayout()
            self.view.layoutIfNeeded()
        }

        // Description
        descRow.onTextChange = { _ in }

        // Submit
        submitBtn.addTarget(self, action: #selector(submitTapped), for: .touchUpInside)
        view.addSubview(submitBtn)
    }

    @objc private func submitTapped() {
        view.endEditing(true)
        let title = titleRow.getValue().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { showToast("请输入标题"); return }
        guard title.count <= 64 else { showToast("标题不能超过64个字"); return }
        guard !equipmentName.isEmpty else { showToast("请选择机械类型"); return }
        let phoneVal = phoneRow.getValue()
        guard phoneVal.isValidPhone else { showToast("请输入正确的联系电话"); return }
        guard let cityId = cityId else { showToast("请选择车辆地点"); return }
        let address = addressRow.getValue().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !address.isEmpty else { showToast("请输入车辆详细地址"); return }
        guard (1...maxImageCount).contains(imageUrls.count) else {
            showToast(images.isEmpty ? "请上传1~3张设备图片" : "设备图片尚未上传")
            return
        }
        let desc = descRow.getText()
        guard !desc.isEmpty else { showToast("请输入出租描述说明"); return }

        let params: [String: Any] = [
            "title": title,
            "category": equipmentName,
            "vehicleCityId": cityId,
            "vehicleAddress": address,
            "imageUrls": imageUrls,
            "description": desc,
            "contactMobile": phoneVal
        ]

        Logger.shared.track("publish_car_submit")
        vm.publishCar(params: params)
    }

    private func bindViewModel() {
        disposables.append(vm.loading.subscribe(onNext: { [weak self] loading in
            if loading { LoadingHUD.shared.show() } else { LoadingHUD.shared.hide() }
            self?.submitBtn.isEnabled = !loading
            self?.submitBtn.alpha = loading ? 0.6 : 1
        }))
        disposables.append(vm.success.subscribe(onNext: { [weak self] success in
            guard success else { return }
            Toast.shared.show("发布成功")
            self?.navigationController?.popViewController(animated: true)
        }))
    }

    private func showEquipmentPicker() {
        view.endEditing(true)
        let picker = EquipmentPickerViewController()
        picker.onPick = { [weak self] equipment in
            self?.equipmentName = equipment.name
            self?.equipmentRow.setValue(equipment.name)
        }
        navigationController?.pushViewController(picker, animated: true)
    }

    private func showCityPicker() {
        view.endEditing(true)
        let picker = CityPickerViewController()
        picker.onPick = { [weak self] city in
            guard let id = Int64(city.code), id > 0 else {
                Toast.shared.show("请选择具体城市")
                return
            }
            self?.cityId = id
            self?.cityRow.setValue(city.name)
        }
        navigationController?.pushViewController(picker, animated: true)
    }

    // MARK: Layout
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let pad: CGFloat = 16.fit
        let cardW = view.w - 32.fit
        let btnH: CGFloat = 48.fit
        let bottomPad: CGFloat = Screen.bottomSafeH + 24.fit

        scrollView.frame = CGRect(x: 0, y: 0,
                                  width: view.w,
                                  height: view.h - 0 - btnH - bottomPad)
        submitBtn.frame = CGRect(x: 16.fit, y: scrollView.bottom + 8.fit,
                                 width: view.w - 32.fit, height: btnH)

        cardView.frame = CGRect(x: pad, y: pad, width: cardW, height: 0)
        var y: CGFloat = 0
        let rows: [UIView] = [titleRow, equipmentRow, phoneRow, cityRow, addressRow,
                              imageRow, descRow]
        for (i, row) in rows.enumerated() {
            let h = rowHeight(for: row)
            row.frame = CGRect(x: 0, y: y, width: cardW, height: h)
            y += h
            if i < rows.count - 1 {
                if let sep = cardView.subviews.first(where: { $0 is Separator && $0.tag == i }) {
                    sep.frame = CGRect(x: 12.fit, y: y, width: cardW - 24.fit, height: 0.5)
                    y += 0.5
                }
            }
        }
        cardView.frame.size.height = y
        let contentH = cardView.bottom + pad
        contentView.frame = CGRect(x: 0, y: 0, width: view.w, height: contentH)
        scrollView.contentSize = contentView.bounds.size
    }

    private func rowHeight(for row: UIView) -> CGFloat {
        if row is ImageGridRow { return 156.fit }
        if row is TextareaRow { return 132.fit }
        return 48.fit
    }
}

// MARK: - FormRow (label + value/arrow/suffix)
private class FormRow: UIView, UITextFieldDelegate {
    var onTap: (() -> Void)?
    var onTextChange: ((String) -> Void)?

    private let titleLabel = UILabel()
    private let valueField = UITextField()
    private let arrowView = UIImageView()
    private let suffixLabel = UILabel()
    private let hintLabel = UILabel()
    private let titleW: CGFloat = 90.fit
    private var interactive = false

    init(title: String, required: Bool, placeholder: String,
         showArrow: Bool = false, suffix: String? = nil, hint: String? = nil) {
        super.init(frame: .zero)
        backgroundColor = .clear

        let attr = NSMutableAttributedString()
        if required {
            attr.append(NSAttributedString(string: "* ", attributes: [
                .font: AppFont.body, .foregroundColor: AppColor.danger
            ]))
        }
        attr.append(NSAttributedString(string: title, attributes: [
            .font: AppFont.body, .foregroundColor: AppColor.textMain
        ]))
        titleLabel.attributedText = attr
        titleLabel.font = AppFont.body
        addSubview(titleLabel)

        valueField.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [.foregroundColor: AppColor.textHint.withAlphaComponent(0.65)]
        )
        valueField.font = AppFont.body
        valueField.textColor = AppColor.textMain
        valueField.textAlignment = .right
        valueField.borderStyle = .none
        valueField.delegate = self
        valueField.addTarget(self, action: #selector(textChanged), for: .editingChanged)
        addSubview(valueField)

        if let hint = hint, !hint.isEmpty {
            hintLabel.text = hint
            hintLabel.font = AppFont.small
            hintLabel.textColor = AppColor.textHint
            hintLabel.textAlignment = .right
            addSubview(hintLabel)
        }

        if let suffix = suffix, !suffix.isEmpty {
            suffixLabel.text = suffix
            suffixLabel.font = AppFont.body
            suffixLabel.textColor = AppColor.textSub
            addSubview(suffixLabel)
        }

        if showArrow {
            arrowView.image = UIImage(systemName: "chevron.right")?
                .withRenderingMode(.alwaysTemplate)
            arrowView.tintColor = AppColor.textHint
            arrowView.contentMode = .scaleAspectFit
            addSubview(arrowView)
            interactive = true
            valueField.isUserInteractionEnabled = false
        }

        if interactive {
            let tap = UITapGestureRecognizer(target: self, action: #selector(tapped))
            addGestureRecognizer(tap)
        }
    }
    required init?(coder: NSCoder) { fatalError() }

    @objc private func tapped() { onTap?() }
    @objc private func textChanged() { onTextChange?(valueField.text ?? "") }

    func setValue(_ value: String) {
        valueField.text = value
    }

    func getValue() -> String { valueField.text ?? "" }

    func setInputMode(keyboardType: UIKeyboardType) {
        valueField.keyboardType = keyboardType
    }

    func beginEditing() { valueField.becomeFirstResponder() }

    override func layoutSubviews() {
        super.layoutSubviews()
        let pad: CGFloat = 12.fit
        titleLabel.frame = CGRect(x: pad, y: (h - 20.fit) / 2,
                                  width: titleW, height: 20.fit)

        let arrowW: CGFloat = 8.fit
        let arrowH: CGFloat = 12.fit
        var rightX = w - pad

        if arrowView.image != nil {
            rightX -= arrowW
            arrowView.frame = CGRect(x: rightX, y: (h - arrowH) / 2,
                                     width: arrowW, height: arrowH)
            rightX -= 4.fit
        }

        if let hint = hintLabel.text, !hint.isEmpty {
            let hintW = hint.size(font: AppFont.small).width
            rightX -= hintW
            hintLabel.frame = CGRect(x: rightX, y: (h - 16.fit) / 2,
                                     width: hintW, height: 16.fit)
            rightX -= 4.fit
        }

        if let suffix = suffixLabel.text, !suffix.isEmpty {
            let suffixW = suffix.size(font: AppFont.body).width
            rightX -= suffixW
            suffixLabel.frame = CGRect(x: rightX, y: (h - 20.fit) / 2,
                                       width: suffixW, height: 20.fit)
            rightX -= 4.fit
        }

        let fieldX = titleLabel.right + 8.fit
        valueField.frame = CGRect(x: fieldX, y: (h - 32.fit) / 2,
                                  width: max(0, rightX - fieldX), height: 32.fit)
    }
}

// MARK: - ImageGridRow (3-column grid with add button)
private class ImageGridRow: UIView {
    var onAddImage: (() -> Void)?
    var onRemoveImage: ((Int) -> Void)?

    private let titleLabel = UILabel()
    private let gridContainer = UIView()
    private var images: [UIImage] = []
    private let maxCount: Int
    private let thumb: CGFloat = 76.fit
    private let spacing: CGFloat = 8.fit
    private let titleH: CGFloat = 32.fit

    init(title: String, required: Bool, maxCount: Int) {
        self.maxCount = maxCount
        super.init(frame: .zero)

        let attr = NSMutableAttributedString()
        if required {
            attr.append(NSAttributedString(string: "* ", attributes: [
                .font: AppFont.body, .foregroundColor: AppColor.danger
            ]))
        }
        attr.append(NSAttributedString(string: title, attributes: [
            .font: AppFont.body, .foregroundColor: AppColor.textMain
        ]))
        titleLabel.attributedText = attr
        titleLabel.font = AppFont.body
        addSubview(titleLabel)
        addSubview(gridContainer)
    }
    required init?(coder: NSCoder) { fatalError() }

    func updateImages(_ imgs: [UIImage]) {
        images = imgs
        rebuildGrid()
    }

    private func rebuildGrid() {
        gridContainer.removeSubviews()
        let pad: CGFloat = 12.fit
        var x = pad
        let y: CGFloat = 0
        for (i, img) in images.enumerated() {
            let iv = UIImageView(image: img)
            iv.contentMode = .scaleAspectFill
            iv.clipsToBounds = true
            iv.layer.cornerRadius = 6.fit
            iv.frame = CGRect(x: x, y: y, width: thumb, height: thumb)
            gridContainer.addSubview(iv)

            let remove = UIButton(type: .custom)
            remove.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
            remove.tintColor = UIColor.black.withAlphaComponent(0.6)
            remove.frame = CGRect(x: x + thumb - 12.fit, y: -4.fit,
                                  width: 16.fit, height: 16.fit)
            remove.tag = i
            remove.addTarget(self, action: #selector(removeTapped(_:)), for: .touchUpInside)
            gridContainer.addSubview(remove)
            x = iv.right + spacing
        }
        if images.count < maxCount {
            let addBtn = UIButton(type: .custom)
            addBtn.backgroundColor = AppColor.bg
            addBtn.layer.cornerRadius = 6.fit
            addBtn.layer.borderWidth = 1
            addBtn.layer.borderColor = AppColor.separator.cgColor
            addBtn.setImage(UIImage(systemName: "plus"), for: .normal)
            addBtn.tintColor = AppColor.textHint
            addBtn.frame = CGRect(x: x, y: y, width: thumb, height: thumb)
            addBtn.addTarget(self, action: #selector(addTapped), for: .touchUpInside)
            gridContainer.addSubview(addBtn)
        }
    }

    @objc private func addTapped() { onAddImage?() }
    @objc private func removeTapped(_ sender: UIButton) { onRemoveImage?(sender.tag) }

    override func layoutSubviews() {
        super.layoutSubviews()
        let pad: CGFloat = 12.fit
        titleLabel.frame = CGRect(x: pad, y: 8.fit, width: w - 24.fit, height: 20.fit)
        let gridY = titleLabel.bottom + 4.fit
        let gridH = h - gridY - pad
        gridContainer.frame = CGRect(x: 0, y: gridY, width: w, height: gridH)
        rebuildGrid()
    }
}

// MARK: - TextareaRow
private class TextareaRow: UIView, UITextViewDelegate {
    var onTextChange: ((String) -> Void)?

    private let titleLabel = UILabel()
    private let textView = UITextView()
    private let counterLabel = UILabel()
    private let placeholderLabel = UILabel()
    private let maxCount: Int

    init(title: String, required: Bool, placeholder: String, maxCount: Int) {
        self.maxCount = maxCount
        super.init(frame: .zero)

        let attr = NSMutableAttributedString()
        if required {
            attr.append(NSAttributedString(string: "* ", attributes: [
                .font: AppFont.body, .foregroundColor: AppColor.danger
            ]))
        }
        attr.append(NSAttributedString(string: title, attributes: [
            .font: AppFont.body, .foregroundColor: AppColor.textMain
        ]))
        titleLabel.attributedText = attr
        titleLabel.font = AppFont.body
        addSubview(titleLabel)

        textView.font = AppFont.body
        textView.textColor = AppColor.textMain
        textView.backgroundColor = AppColor.bg
        textView.layer.cornerRadius = 6.fit
        textView.layer.borderWidth = 0.5
        textView.layer.borderColor = AppColor.separator.cgColor
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        textView.delegate = self
        addSubview(textView)

        placeholderLabel.text = placeholder
        placeholderLabel.font = AppFont.body
        placeholderLabel.textColor = AppColor.textHint.withAlphaComponent(0.65)
        placeholderLabel.numberOfLines = 0
        textView.addSubview(placeholderLabel)

        counterLabel.text = "0/\(maxCount)"
        counterLabel.font = AppFont.small
        counterLabel.textColor = AppColor.textHint
        counterLabel.textAlignment = .right
        addSubview(counterLabel)
    }
    required init?(coder: NSCoder) { fatalError() }

    func getText() -> String { textView.text ?? "" }

    func textViewDidChange(_ textView: UITextView) {
        let text = textView.text ?? ""
        if text.count > maxCount {
            textView.text = String(text.prefix(maxCount))
        }
        let count = textView.text?.count ?? 0
        counterLabel.text = "\(count)/\(maxCount)"
        placeholderLabel.isHidden = !text.isEmpty
        onTextChange?(textView.text ?? "")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let pad: CGFloat = 12.fit
        titleLabel.frame = CGRect(x: pad, y: 12.fit,
                                  width: w - 24.fit, height: 20.fit)
        let tvY = titleLabel.bottom + 8.fit
        let counterH: CGFloat = 16.fit
        let counterW: CGFloat = 50.fit
        counterLabel.frame = CGRect(x: w - pad - counterW,
                                    y: h - pad - counterH + 4.fit,
                                    width: counterW, height: counterH)
        let tvH = h - tvY - counterH - pad
        textView.frame = CGRect(x: pad, y: tvY,
                                width: w - 24.fit, height: tvH)
        placeholderLabel.frame = CGRect(x: 8, y: 8,
                                        width: textView.w - 16, height: 20.fit)
    }
}
