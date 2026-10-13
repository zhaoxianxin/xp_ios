//
//  PublishJobViewController.swift
//  XunPengMachine
//
//  发布求租表单：机械类型/联系电话/施工地点/租车时间/工期/租金/发票/描述
//

import UIKit

/// 求租机械
final class PublishJobViewController: BaseViewController {
    
    private let vm = PublishViewModel()
    private let editingJob: Job?
    var onSaved: (() -> Void)?

    // MARK: State
    private var equipmentName: String = ""
    private var cityId: Int64?
    private var rentStartDate: String = ""
    private var rentTimeSlot: String = ""
    private var invoiceType: Int = 0
    private let maxDescCount = 30
    private let phone = "15963229366"

    // MARK: UI
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let cardView = UIView()
    private let submitBtn = AppButton(title: "立即发布", style: .danger, height: 48)

    private lazy var titleRow = FormRow(title: "标题", required: true,
                                        placeholder: "请输入求租标题")
    private lazy var equipmentRow = FormRow(title: "机械类型", required: true,
                                            placeholder: "请选择", showArrow: true)
    private lazy var phoneRow = FormRow(title: "联系电话", required: true,
                                        placeholder: phone, hint: "可修改>")
    private lazy var cityRow = FormRow(title: "施工地点", required: true,
                                       placeholder: "请选择", showArrow: true)
    private lazy var addressRow = FormRow(title: "详细地址", required: true,
                                          placeholder: "请输入详细地址")
    private lazy var rentDateRow = FormRow(title: "租车时间", required: true,
                                           placeholder: "请选择", showArrow: true)
    private lazy var durationRow = FormRow(title: "租车工期", required: true,
                                           placeholder: "请输入", suffix: "天")
    private lazy var priceRow = FormRow(title: "租车租金", required: true,
                                        placeholder: "请输入", suffix: "元")
    private lazy var invoiceRow = RadioRow(title: "发票信息", required: false,
                                           options: ["不开票", "开专票", "开普票"])
    private lazy var descRow = TextareaRow(title: "用车描述说明", required: true,
                                           placeholder: "请输入描述说明", maxCount: maxDescCount)

    init(job: Job? = nil) {
        self.editingJob = job
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = editingJob == nil ? "发布求租" : "修改求租"
        navStyle = .white
        setupBackButton()
        view.backgroundColor = AppColor.bg
        setupUI()
        applyEditingDataIfNeeded()
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
                              rentDateRow, durationRow, priceRow, invoiceRow, descRow]
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

        rentDateRow.onTap = { [weak self] in self?.showRentalTimePicker() }

        // Number inputs
        durationRow.setInputMode(keyboardType: .numberPad)
        priceRow.setInputMode(keyboardType: .decimalPad)

        // Invoice radio
        invoiceRow.selectIndex(0)
        invoiceRow.onChange = { [weak self] idx in
            self?.invoiceType = idx
        }

        // Description
        descRow.onTextChange = { _ in }

        // Submit
        submitBtn.addTarget(self, action: #selector(submitTapped), for: .touchUpInside)
        view.addSubview(submitBtn)
    }

    private func applyEditingDataIfNeeded() {
        guard let job = editingJob else { return }
        titleRow.setValue(job.title)
        equipmentName = job.category
        equipmentRow.setValue(job.category)
        phoneRow.setValue(job.contactMobile ?? "")
        cityId = job.workCityId
        cityRow.setValue(job.cityName ?? "")
        addressRow.setValue(job.workAddress ?? "")
        rentStartDate = job.rentStartDate ?? ""
        rentTimeSlot = job.rentTimeSlot ?? ""
        let rentalTime = [job.rentStartDate, job.rentTimeSlot]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: "  ")
        rentDateRow.setValue(rentalTime)
        durationRow.setValue(String(job.durationDays))
        priceRow.setValue(job.rentAmountText)
        invoiceType = job.invoiceType ?? 0
        invoiceRow.selectIndex(invoiceType)
        descRow.setText(job.description)
        submitBtn.setTitle("保存修改", for: .normal)
    }

    @objc private func submitTapped() {
        view.endEditing(true)
        let title = titleRow.getValue().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { showToast("请输入标题"); return }
        guard title.count <= 64 else { showToast("标题不能超过64个字"); return }
        guard !equipmentName.isEmpty else { showToast("请选择机械类型"); return }
        let phoneVal = phoneRow.getValue()
        guard phoneVal.isValidPhone else { showToast("请输入正确的联系电话"); return }
        if editingJob == nil, cityId == nil { showToast("请选择施工地点"); return }
        let address = addressRow.getValue().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !address.isEmpty else { showToast("请输入施工详细地址"); return }
        guard !rentStartDate.isEmpty else { showToast("请选择租车时间"); return }
        guard !rentTimeSlot.isEmpty else { showToast("请选择租车时间段"); return }
        guard let duration = Int(durationRow.getValue()), duration > 0 else {
            showToast("请输入正确的租车工期")
            return
        }
        guard let price = Double(priceRow.getValue()), price > 0 else {
            showToast("请输入正确的租车租金")
            return
        }
        let desc = descRow.getText()
        guard !desc.isEmpty else { showToast("请输入用车描述说明"); return }

        var params: [String: Any] = [
            "title": title,
            "category": equipmentName,
            "workAddress": address,
            "rentStartDate": rentStartDate,
            "rentTimeSlot": rentTimeSlot,
            "durationDays": duration,
            "rentAmount": price,
            "invoiceType": invoiceType,
            "description": desc,
            "contactMobile": phoneVal
        ]
        if let cityId { params["workCityId"] = cityId }
        let isEditing = editingJob != nil
        Logger.shared.track(isEditing ? "update_job_submit" : "publish_job_submit")
        vm.saveJob(params: params, editingID: editingJob?.id)
    }

    private func bindViewModel() {
        disposables.append(vm.loading.subscribe(onNext: { [weak self] loading in
            if loading { LoadingHUD.shared.show() } else { LoadingHUD.shared.hide() }
            self?.submitBtn.isEnabled = !loading
            self?.submitBtn.alpha = loading ? 0.6 : 1
        }))
        disposables.append(vm.success.subscribe(onNext: { [weak self] success in
            guard let self, success else { return }
            Toast.shared.show(self.editingJob == nil ? "发布成功" : "修改成功")
            self.onSaved?()
            self.navigationController?.popViewController(animated: true)
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

    private func showRentalTimePicker() {
        view.endEditing(true)
        let picker = RentalTimePickerViewController(date: rentStartDate,
                                                    timeSlot: rentTimeSlot,
                                                    restrictToFuture: true)
        picker.onConfirm = { [weak self] date, timeSlot in
            self?.rentStartDate = date
            self?.rentTimeSlot = timeSlot
            self?.rentDateRow.setValue("\(date)  \(timeSlot)")
        }
        picker.modalPresentationStyle = .overFullScreen
        picker.modalTransitionStyle = .crossDissolve
        present(picker, animated: true)
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
                              rentDateRow, durationRow, priceRow, invoiceRow, descRow]
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
        if row is TextareaRow { return 132.fit }
        if row is RadioRow { return 60.fit }
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

// MARK: - RadioRow (radio button group)
private class RadioRow: UIView {
    var onChange: ((Int) -> Void)?

    private let titleLabel = UILabel()
    private var buttons: [UIButton] = []
    private var selectedIndex: Int = -1
    private let titleW: CGFloat = 90.fit

    init(title: String, required: Bool, options: [String]) {
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

        for (i, opt) in options.enumerated() {
            let btn = UIButton(type: .custom)
            btn.setTitle(opt, for: .normal)
            btn.titleLabel?.font = AppFont.body
            btn.layer.cornerRadius = 4.fit
            btn.layer.borderWidth = 1
            btn.tag = i
            btn.addTarget(self, action: #selector(selected(_:)), for: .touchUpInside)
            addSubview(btn)
            buttons.append(btn)
        }
    }
    required init?(coder: NSCoder) { fatalError() }

    func selectIndex(_ idx: Int) {
        selectedIndex = idx
        updateStyles()
        onChange?(idx)
    }

    @objc private func selected(_ sender: UIButton) {
        selectedIndex = sender.tag
        updateStyles()
        onChange?(sender.tag)
    }

    private func updateStyles() {
        for (i, btn) in buttons.enumerated() {
            if i == selectedIndex {
                btn.backgroundColor = AppColor.primary
                btn.setTitleColor(.white, for: .normal)
                btn.layer.borderColor = AppColor.primary.cgColor
            } else {
                btn.backgroundColor = .white
                btn.setTitleColor(AppColor.textMain, for: .normal)
                btn.layer.borderColor = AppColor.separator.cgColor
            }
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let pad: CGFloat = 12.fit
        titleLabel.frame = CGRect(x: pad, y: (h - 20.fit) / 2,
                                  width: titleW, height: 20.fit)

        let btnH: CGFloat = 30.fit
        let btnY = (h - btnH) / 2
        let spacing: CGFloat = 8.fit
        var x = titleLabel.right + 8.fit
        for btn in buttons {
            let title = btn.title(for: .normal) ?? ""
            let w = title.size(font: AppFont.body).width + 24.fit
            btn.frame = CGRect(x: x, y: btnY, width: w, height: btnH)
            x = btn.right + spacing
        }
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

    func setText(_ text: String) {
        textView.text = String(text.prefix(maxCount))
        textViewDidChange(textView)
    }

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
