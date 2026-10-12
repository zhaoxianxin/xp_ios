//
//  DriverWorkReminderViewController.swift
//  XunPengMachine
//
//  招聘首页-工作提醒
//

import UIKit

private struct RecruitmentReminderSubmitResponse: Codable {}

private final class RecruitmentReminderViewModel: BaseViewModel {
    let submitted = Observable.create(false)

    func save(categories: [String], workType: Int, cityId: String?, enabled: Bool) {
        var params: [String: Any] = [
            "categories": categories,
            "workType": workType,
            "enabled": enabled
        ]
        if let cityId, !cityId.isEmpty { params["cityId"] = cityId }

        loading.onNext(true)
        NetworkManager.shared.request(
            .saveRecruitmentReminder(params: params),
            type: RecruitmentReminderSubmitResponse.self
        ) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                self.loading.onNext(false)
                switch result {
                case .success:
                    self.submitted.onNext(true)
                case .failure(let error):
                    self.submitted.onNext(false)
                    Toast.shared.show(error.errorDescription ?? "开通失败")
                }
            }
        }
    }
}

final class DriverWorkReminderViewController: BaseViewController {

    override var navStyle: NavStyle {
        get { .blue }
        set { }
    }

    private let viewModel = RecruitmentReminderViewModel()
    private var selectedCategories: [String] = []
    private var selectedWorkType = 3
    private var selectedCity: City?
    private var hasOpenedBefore = false

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let equipmentTitleLabel = UILabel.make("机械类型", font: AppFont.body, color: AppColor.textMain)
    private let equipmentButton = UIButton(type: .system)
    private let workTypeTitleLabel = UILabel.make("工期", font: AppFont.body, color: AppColor.textMain)
    private let workTypeContainer = UIView()
    private var workTypeButtons: [UIButton] = []
    private let cityTitleLabel = UILabel.make("工作地点", font: AppFont.body, color: AppColor.textMain)
    private let cityButton = UIButton(type: .system)
    private let reminderRow = UIView()
    private let reminderLabel = UILabel.make("开通提醒", font: AppFont.body, color: AppColor.textMain)
    private let reminderStatusLabel = UILabel.make("已开启", font: AppFont.body,
                                                    color: AppColor.primary,
                                                    alignment: .right)
    private let reminderSwitch = UISwitch()
    private let hintRow = UIView()
    private let hintLabel = UILabel.make("收不到提醒，提醒没有声音？点此打开设置 〉",
                                         font: AppFont.small, color: AppColor.primary)
    private let actionButton = AppButton(title: "开通", style: .danger, height: 48)

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "工作提醒"
        setupBackButton()
        navigationController?.setNavigationBarHidden(false, animated: true)
        view.backgroundColor = .white
        setupUI()
        bindViewModel()
        updateUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        applyNavigationStyle()
    }

    private func applyNavigationStyle() {
        navigationController?.setNavigationBarHidden(false, animated: false)
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = AppColor.navBar
        appearance.shadowColor = .clear
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: AppFont.navTitle
        ]
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.tintColor = .white
    }

    private func setupUI() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        scrollView.alwaysBounceVertical = true

        [equipmentTitleLabel, equipmentButton, workTypeTitleLabel, workTypeContainer,
         cityTitleLabel, cityButton, reminderRow, hintRow].forEach(contentView.addSubview)

        configureSelectionButton(equipmentButton, title: "请选择机械类型")
        equipmentButton.addTarget(self, action: #selector(equipmentTapped), for: .touchUpInside)
        configureSelectionButton(cityButton, title: "请选择工作地点")
        cityButton.addTarget(self, action: #selector(cityTapped), for: .touchUpInside)

        workTypeContainer.backgroundColor = AppColor.bg
        let titles = ["长期活", "替班活", "长替都要"]
        for (index, title) in titles.enumerated() {
            let button = UIButton(type: .system)
            button.tag = index + 1
            button.setTitle(title, for: .normal)
            button.titleLabel?.font = AppFont.body
            button.layer.cornerRadius = 2
            button.layer.borderWidth = 0.5
            button.addTarget(self, action: #selector(workTypeTapped(_:)), for: .touchUpInside)
            workTypeContainer.addSubview(button)
            workTypeButtons.append(button)
        }

        reminderRow.backgroundColor = AppColor.bg
        reminderRow.addSubview(reminderLabel)
        reminderRow.addSubview(reminderStatusLabel)
        reminderSwitch.isOn = true
        reminderSwitch.onTintColor = AppColor.primary
        reminderSwitch.addTarget(self, action: #selector(reminderChanged), for: .valueChanged)
        reminderRow.addSubview(reminderSwitch)

        hintRow.backgroundColor = AppColor.bg
        hintRow.addSubview(hintLabel)
        let hintTap = UITapGestureRecognizer(target: self, action: #selector(openSettings))
        hintRow.addGestureRecognizer(hintTap)

        actionButton.addTarget(self, action: #selector(actionTapped), for: .touchUpInside)
        view.addSubview(actionButton)
    }

    private func configureSelectionButton(_ button: UIButton, title: String) {
        button.backgroundColor = AppColor.bg
        button.setTitle(title, for: .normal)
        button.setTitleColor(AppColor.primary, for: .normal)
        button.titleLabel?.font = AppFont.body
        button.contentHorizontalAlignment = .left
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 8.fit, bottom: 0, right: 30.fit)
        let arrow = UIImage(systemName: "chevron.right")?.withRenderingMode(.alwaysTemplate)
        button.setImage(arrow, for: .normal)
        button.tintColor = AppColor.textHint
        button.semanticContentAttribute = .forceRightToLeft
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: -12.fit)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let buttonHeight: CGFloat = 48
        let bottomAreaHeight = buttonHeight + 24.fit + Screen.bottomSafeH
        scrollView.frame = CGRect(x: 0, y: 0, width: view.w,
                                  height: max(0, view.h - bottomAreaHeight))
        actionButton.frame = CGRect(x: 8.fit,
                                    y: view.h - bottomAreaHeight + 8.fit,
                                    width: view.w - 16.fit,
                                    height: buttonHeight)

        let horizontalPadding: CGFloat = 8.fit
        let contentWidth = view.w
        let rowWidth = contentWidth - horizontalPadding * 2
        var y: CGFloat = 12.fit

        equipmentTitleLabel.frame = CGRect(x: 12.fit, y: y, width: rowWidth, height: 22.fit)
        y = equipmentTitleLabel.bottom + 10.fit
        equipmentButton.frame = CGRect(x: horizontalPadding, y: y, width: rowWidth, height: 48.fit)
        y = equipmentButton.bottom + 16.fit

        workTypeTitleLabel.frame = CGRect(x: 12.fit, y: y, width: rowWidth, height: 22.fit)
        y = workTypeTitleLabel.bottom + 10.fit
        workTypeContainer.frame = CGRect(x: horizontalPadding, y: y, width: rowWidth, height: 48.fit)
        let workButtonWidth: CGFloat = 74.fit
        let gap = (rowWidth - workButtonWidth * 3) / 4
        for (index, button) in workTypeButtons.enumerated() {
            button.frame = CGRect(x: gap + CGFloat(index) * (workButtonWidth + gap),
                                  y: 10.fit, width: workButtonWidth, height: 28.fit)
        }
        y = workTypeContainer.bottom + 16.fit

        cityTitleLabel.frame = CGRect(x: 12.fit, y: y, width: rowWidth, height: 22.fit)
        y = cityTitleLabel.bottom + 10.fit
        cityButton.frame = CGRect(x: horizontalPadding, y: y, width: rowWidth, height: 48.fit)
        y = cityButton.bottom + 10.fit

        reminderRow.frame = CGRect(x: horizontalPadding, y: y, width: rowWidth, height: 46.fit)
        reminderLabel.frame = CGRect(x: 4.fit, y: 0,
                                     width: reminderRow.w - 150.fit, height: reminderRow.h)
        reminderStatusLabel.frame = CGRect(x: reminderRow.w - 145.fit, y: 0,
                                           width: 90.fit, height: reminderRow.h)
        reminderSwitch.transform = CGAffineTransform(scaleX: 0.78, y: 0.78)
        reminderSwitch.center = CGPoint(x: reminderRow.w - 28.fit, y: reminderRow.h / 2)
        y = reminderRow.bottom + 8.fit

        hintRow.frame = CGRect(x: horizontalPadding, y: y, width: rowWidth, height: 46.fit)
        hintLabel.frame = CGRect(x: 4.fit, y: 0, width: hintRow.w - 8.fit, height: hintRow.h)
        y = hintRow.bottom + 16.fit

        contentView.frame = CGRect(x: 0, y: 0, width: contentWidth, height: y)
        scrollView.contentSize = contentView.bounds.size
    }

    private func bindViewModel() {
        disposables.append(viewModel.loading.subscribe(onNext: { loading in
            if loading { LoadingHUD.shared.show() } else { LoadingHUD.shared.hide() }
        }))
        disposables.append(viewModel.submitted.subscribe(onNext: { [weak self] success in
            guard success, let self else { return }
            self.hasOpenedBefore = true
            self.updateUI()
            self.showToast("工作提醒已开通")
        }))
    }

    private func updateUI() {
        let equipmentText = selectedCategories.isEmpty
            ? "请选择机械类型"
            : selectedCategories.joined(separator: "、")
        equipmentButton.setTitle(equipmentText, for: .normal)
        cityButton.setTitle(selectedCity.map { "\($0.name)" } ?? "请选择工作地点", for: .normal)
        actionButton.setTitle(hasOpenedBefore ? "重新开通" : "开通", for: .normal)
        reminderStatusLabel.text = reminderSwitch.isOn ? "已开启" : "已关闭"
        reminderStatusLabel.textColor = reminderSwitch.isOn ? AppColor.primary : AppColor.textHint

        for button in workTypeButtons {
            let selected = button.tag == selectedWorkType
            button.backgroundColor = selected ? AppColor.primary : .white
            button.setTitleColor(selected ? .white : AppColor.textMain, for: .normal)
            button.layer.borderColor = selected ? AppColor.primary.cgColor : AppColor.textHint.cgColor
        }
    }

    @objc private func equipmentTapped() {
        let picker = EquipmentPickerViewController()
        picker.onPick = { [weak self] equipment in
            guard let self else { return }
            if !self.selectedCategories.contains(equipment.name) {
                self.selectedCategories.append(equipment.name)
            }
            self.updateUI()
        }
        navigationController?.pushViewController(picker, animated: true)
    }

    @objc private func cityTapped() {
        let picker = CityPickerViewController()
        picker.onPick = { [weak self] city in
            self?.selectedCity = city
            self?.updateUI()
        }
        navigationController?.pushViewController(picker, animated: true)
    }

    @objc private func workTypeTapped(_ sender: UIButton) {
        selectedWorkType = sender.tag
        updateUI()
    }

    @objc private func reminderChanged() {
        updateUI()
        Logger.shared.track("driver_reminder_switch", params: ["enabled": reminderSwitch.isOn])
    }

    @objc private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    @objc private func actionTapped() {
        guard !selectedCategories.isEmpty else {
            showToast("请选择机械类型")
            return
        }
        guard let selectedCity, selectedCity.name != "全国" else {
            showToast("请选择工作地点")
            return
        }
        viewModel.save(categories: selectedCategories,
                       workType: selectedWorkType,
                       cityId: selectedCity.code,
                       enabled: reminderSwitch.isOn)
    }
}
