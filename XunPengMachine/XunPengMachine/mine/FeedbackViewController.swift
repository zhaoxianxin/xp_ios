//
//  FeedbackViewController.swift
//  XunPengMachine
//
//  我的-意见反馈：文本输入 + 类型选择 + 九宫格图片 + 提交
//

import UIKit

final class FeedbackViewController: BaseViewController, UITextViewDelegate {

    private let vm = MineViewModel()

    // MARK: - UI
    private let scrollView = UIScrollView()
    private let contentContainer = UIView()

    private let textViewCard = UIView()
    private let textView = UITextView()
    private let placeholderLabel = UILabel.make("请描述您遇到的问题或建议（最多500字）",
                                                font: AppFont.body, color: AppColor.textHint)
    private let countLabel = UILabel.make("0/500", font: AppFont.small, color: AppColor.textHint, alignment: .right)

    private let typeTitleLabel = UILabel.make("问题类型", font: AppFont.bodyM, color: AppColor.textMain)
    private let typeContainer = UIView()
    private let types: [String] = ["功能建议", "bug反馈", "投诉", "其他"]
    private var typeButtons: [UIButton] = []
    private var selectedType: Int = 0

    private let imageTitleLabel = UILabel.make("上传图片（可选，最多9张）", font: AppFont.bodyM, color: AppColor.textMain)
    private let imageGrid = UIView()
    private var images: [UIImage] = []
    private let maxImageCount = 9

    private let submitButton = AppButton(title: "提交", style: .primary, height: 44)

    // MARK: - 生命周期
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "意见反馈"
        navStyle = .white
        setupBackButton()
        applyNavStyle()
        setupUI()
        bindViewModel()
    }

    private func applyNavStyle() {
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationController?.navigationBar.barTintColor = .white
        navigationController?.navigationBar.tintColor = AppColor.textMain
        navigationController?.navigationBar.titleTextAttributes = [
            .foregroundColor: AppColor.textMain, .font: AppFont.navTitle
        ]
    }

    // MARK: - UI 搭建
    private func setupUI() {
        view.backgroundColor = AppColor.bg

        view.addSubview(scrollView)
        let bottomInset: CGFloat = Screen.bottomSafeH + 60
        scrollView.frame = CGRect(x: 0, y: Screen.topSafeH,
                                  width: Screen.width,
                                  height: Screen.height - Screen.topSafeH)
        scrollView.alwaysBounceVertical = true
        scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: bottomInset, right: 0)

        scrollView.addSubview(contentContainer)
        contentContainer.backgroundColor = .clear

        setupTextView()
        setupTypeTags()
        setupImageGrid()
        setupSubmitButton()
        layoutContent()

        // 点击空白收起键盘
        let tap = UITapGestureRecognizer(target: self, action: #selector(endEditing))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    private func setupTextView() {
        contentContainer.addSubview(textViewCard)
        textViewCard.backgroundColor = AppColor.cardBg
        textViewCard.layer.cornerRadius = 10

        textViewCard.addSubview(textView)
        textView.font = AppFont.body
        textView.textColor = AppColor.textMain
        textView.delegate = self
        textView.backgroundColor = .clear
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 8, bottom: 12, right: 8)

        textViewCard.addSubview(placeholderLabel)
        placeholderLabel.frame = CGRect(x: 12.fit, y: 12, width: Screen.width - 24.fit - 24.fit, height: 22)

        textViewCard.addSubview(countLabel)
    }

    private func setupTypeTags() {
        contentContainer.addSubview(typeTitleLabel)
        contentContainer.addSubview(typeContainer)
        typeContainer.backgroundColor = .clear
        typeButtons = types.enumerated().map { idx, title in
            let btn = UIButton.make(title, font: AppFont.small, titleColor: AppColor.textSub, bgColor: AppColor.cardBg)
            btn.tag = idx
            btn.layer.cornerRadius = 14
            btn.layer.borderWidth = 1
            btn.contentEdgeInsets = UIEdgeInsets(top: 6, left: 14, bottom: 6, right: 14)
            btn.addTarget(self, action: #selector(typeSelected(_:)), for: .touchUpInside)
            typeContainer.addSubview(btn)
            return btn
        }
        applyTypeSelection()
    }

    private func setupImageGrid() {
        contentContainer.addSubview(imageTitleLabel)
        contentContainer.addSubview(imageGrid)
        imageGrid.backgroundColor = .clear
        rebuildImageGrid()
    }

    private func setupSubmitButton() {
        view.addSubview(submitButton)
        submitButton.addTarget(self, action: #selector(submitTapped), for: .touchUpInside)
    }

    private func layoutContent() {
        let padding: CGFloat = 12.fit
        let cardW = Screen.width - padding * 2
        var y: CGFloat = 12

        // 文本框
        textViewCard.frame = CGRect(x: padding, y: y, width: cardW, height: 150)
        textView.frame = CGRect(x: 8, y: 0, width: cardW - 16, height: 110)
        countLabel.frame = CGRect(x: cardW - 80, y: 122, width: 70, height: 18)
        y += 150 + 16

        // 类型标题
        typeTitleLabel.frame = CGRect(x: padding, y: y, width: cardW, height: 22)
        y += 26

        // 类型 tag 横排
        let tagH: CGFloat = 28
        var x: CGFloat = padding
        for btn in typeButtons {
            btn.sizeToFit()
            let w = (btn.titleLabel?.text ?? "").size(font: AppFont.small).width
            let bw = w + 28
            if x + bw > Screen.width - padding {
                x = padding
                y += tagH + 8
            }
            btn.frame = CGRect(x: x, y: y, width: bw, height: tagH)
            x += bw + 8
        }
        typeContainer.frame = CGRect(x: 0, y: typeTitleLabel.bottom, width: Screen.width, height: y - typeTitleLabel.bottom + tagH)
        y = typeContainer.bottom + 16

        // 图片标题
        imageTitleLabel.frame = CGRect(x: padding, y: y, width: cardW, height: 22)
        y += 26

        // 图片网格
        let gridH = layoutImageGrid(y: y)
        imageGrid.frame = CGRect(x: 0, y: y, width: Screen.width, height: gridH)
        y += gridH + 16

        contentContainer.frame = CGRect(x: 0, y: 0, width: Screen.width, height: y)
        scrollView.contentSize = CGSize(width: Screen.width, height: y)

        // 提交按钮悬浮在底部
        submitButton.frame = CGRect(x: padding, y: Screen.height - Screen.bottomSafeH - 60,
                                    width: cardW, height: 44)
    }

    private func rebuildImageGrid() {
        imageGrid.removeSubviews()
        let gridH = layoutImageGrid(y: imageGrid.frame.minY)
        imageGrid.frame.size.height = gridH
        // 更新内容总高
        var h = imageGrid.bottom + 16
        contentContainer.frame.size.height = h
        scrollView.contentSize = CGSize(width: Screen.width, height: h)
    }

    @discardableResult
    private func layoutImageGrid(y: CGFloat) -> CGFloat {
        let padding: CGFloat = 12.fit
        let gap: CGFloat = 8
        let itemSize = (Screen.width - padding * 2 - gap * 2) / 3
        var row: CGFloat = 0
        var col: CGFloat = 0

        for (idx, img) in images.enumerated() {
            let imageView = UIImageView(image: img)
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            imageView.layer.cornerRadius = 6
            imageView.frame = CGRect(x: padding + col * (itemSize + gap),
                                     y: y + row * (itemSize + gap),
                                     width: itemSize, height: itemSize)
            imageGrid.addSubview(imageView)

            // 删除按钮
            let delBtn = UIButton(type: .custom)
            delBtn.setImage(UIImage(systemName: "xmark.circle.fill")?.withRenderingMode(.alwaysTemplate),
                            for: .normal)
            delBtn.tintColor = AppColor.danger
            delBtn.tag = idx
            delBtn.addTarget(self, action: #selector(removeImage(_:)), for: .touchUpInside)
            imageGrid.addSubview(delBtn)
            delBtn.frame = CGRect(x: imageView.right - 18, y: imageView.y - 4,
                                  width: 22, height: 22)

            col += 1
            if col >= 3 { col = 0; row += 1 }
        }

        // 添加按钮
        if images.count < maxImageCount {
            let addBtn = UIButton(type: .custom)
            addBtn.backgroundColor = AppColor.cardBg
            addBtn.layer.cornerRadius = 6
            addBtn.setImage(UIImage(systemName: "plus")?.withRenderingMode(.alwaysTemplate), for: .normal)
            addBtn.tintColor = AppColor.textHint
            addBtn.addTarget(self, action: #selector(addImage), for: .touchUpInside)
            addBtn.frame = CGRect(x: padding + col * (itemSize + gap),
                                  y: y + row * (itemSize + gap),
                                  width: itemSize, height: itemSize)
            imageGrid.addSubview(addBtn)
            col += 1
            if col >= 3 { col = 0; row += 1 }
        }

        let rows = max(1, (col == 0 ? Int(row) : Int(row) + 1))
        return CGFloat(rows) * itemSize + CGFloat(rows - 1) * gap
    }

    // MARK: - 类型选择
    private func applyTypeSelection() {
        for (idx, btn) in typeButtons.enumerated() {
            let selected = idx == selectedType
            btn.isSelected = selected
            if selected {
                btn.layer.borderColor = AppColor.primary.cgColor
                btn.setTitleColor(AppColor.primary, for: .normal)
                btn.backgroundColor = UIColor(hex: 0x0076FF, alpha: 0.08)
            } else {
                btn.layer.borderColor = AppColor.separator.cgColor
                btn.setTitleColor(AppColor.textSub, for: .normal)
                btn.backgroundColor = AppColor.cardBg
            }
        }
    }

    // MARK: - 绑定
    private func bindViewModel() {
        let sub = vm.loading.subscribe(onNext: { loading in
            if loading { LoadingHUD.shared.show() } else { LoadingHUD.shared.hide() }
        })
        disposables.append(sub)
    }

    // MARK: - UITextViewDelegate
    func textViewDidChange(_ textView: UITextView) {
        let text = textView.text ?? ""
        // 限制 500 字
        if text.count > 500 {
            textView.text = String(text.prefix(500))
        }
        let current = textView.text ?? ""
        placeholderLabel.isHidden = !current.isEmpty
        countLabel.text = "\(current.count)/500"
        countLabel.textColor = current.count >= 500 ? AppColor.danger : AppColor.textHint
    }

    // MARK: - 事件
    @objc private func endEditing() {
        view.endEditing(true)
    }

    @objc private func typeSelected(_ btn: UIButton) {
        selectedType = btn.tag
        applyTypeSelection()
        Logger.shared.track("feedback_select_type", params: ["type": types[selectedType]])
    }

    @objc private func addImage() {
        view.endEditing(true)
        let remaining = maxImageCount - images.count
        guard remaining > 0 else {
            showToast("最多上传 \(maxImageCount) 张图片")
            return
        }
        ImagePickerManager.shared.pick(from: self, maxCount: remaining) { [weak self] newImages in
            guard let self = self else { return }
            self.images.append(contentsOf: newImages)
            if self.images.count > self.maxImageCount {
                self.images = Array(self.images.prefix(self.maxImageCount))
            }
            self.rebuildImageGrid()
        }
    }

    @objc private func removeImage(_ btn: UIButton) {
        guard btn.tag < images.count else { return }
        images.remove(at: btn.tag)
        rebuildImageGrid()
    }

    @objc private func submitTapped() {
        view.endEditing(true)
        let content = textView.text ?? ""
        guard content.count >= 5 else {
            showToast("请至少输入5个字")
            return
        }
        let typeText = types[selectedType]
        let fullContent = "【\(typeText)】\(content)"
        vm.feedback(content: fullContent) { [weak self] success in
            guard let self = self else { return }
            if success {
                self.showToast("提交成功，感谢您的反馈")
                Logger.shared.track("feedback_submit_success")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    self.navigationController?.popViewController(animated: true)
                }
            } else {
                self.showToast("提交失败，请稍后重试")
            }
        }
    }

    // MARK: - 布局更新
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let padding: CGFloat = 12.fit
        submitButton.frame = CGRect(x: padding,
                                    y: Screen.height - Screen.bottomSafeH - 60,
                                    width: Screen.width - padding * 2,
                                    height: 44)
    }
}
