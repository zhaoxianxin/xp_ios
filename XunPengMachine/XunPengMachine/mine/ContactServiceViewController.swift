//
//  ContactServiceViewController.swift
//  XunPengMachine
//
//  我的-联系客服：客服卡片 + 常见问题折叠
//

import UIKit

final class ContactServiceViewController: BaseViewController {

    struct FAQ {
        let question: String
        let answer: String
        var expanded: Bool
    }

    private var faqs: [FAQ] = []

    // MARK: - UI
    private let scrollView = UIScrollView()
    private let contentContainer = UIView()
    private let tableView = UITableView(frame: .zero, style: .plain)

    // MARK: - 生命周期
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "联系客服"
        navStyle = .white
        setupBackButton()
        applyNavStyle()
        setupUI()
        loadFAQs()
    }

    private func applyNavStyle() {
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationController?.navigationBar.barTintColor = .white
        navigationController?.navigationBar.tintColor = AppColor.textMain
        navigationController?.navigationBar.titleTextAttributes = [
            .foregroundColor: AppColor.textMain, .font: AppFont.navTitle
        ]
    }

    private func setupUI() {
        view.backgroundColor = AppColor.bg

        view.addSubview(scrollView)
        scrollView.frame = CGRect(x: 0, y: Screen.topSafeH,
                                  width: Screen.width,
                                  height: Screen.height - Screen.topSafeH)
        scrollView.alwaysBounceVertical = true

        scrollView.addSubview(contentContainer)
        contentContainer.backgroundColor = .clear

        setupContactCards()
        setupFAQSection()
    }

    // MARK: - 客服卡片
    private func setupContactCards() {
        let card = UIView()
        card.backgroundColor = AppColor.cardBg
        card.layer.cornerRadius = 10
        contentContainer.addSubview(card)

        let phoneRow = makeContactRow(icon: "phone.fill",
                                      title: "客服电话",
                                      value: "400-888-8888",
                                      action: #selector(callPhone))
        let wechatRow = makeContactRow(icon: "message.fill",
                                       title: "微信客服",
                                       value: "xunpeng_kefu",
                                       action: #selector(copyWechat))
        let qqRow = makeContactRow(icon: "person.crop.circle.fill",
                                   title: "QQ客服",
                                   value: "80088888",
                                   action: #selector(copyQQ))

        card.addSubview(phoneRow)
        card.addSubview(wechatRow)
        card.addSubview(qqRow)

        let rowH: CGFloat = 56
        let cardW = Screen.width - 24.fit
        phoneRow.frame = CGRect(x: 0, y: 0, width: cardW, height: rowH)
        wechatRow.frame = CGRect(x: 0, y: rowH, width: cardW, height: rowH)
        qqRow.frame = CGRect(x: 0, y: rowH * 2, width: cardW, height: rowH)

        // 分隔线
        let line1 = Separator(); card.addSubview(line1)
        line1.frame = CGRect(x: 44.fit, y: rowH - 0.25, width: cardW - 44.fit, height: 0.5)
        let line2 = Separator(); card.addSubview(line2)
        line2.frame = CGRect(x: 44.fit, y: rowH * 2 - 0.25, width: cardW - 44.fit, height: 0.5)

        card.frame = CGRect(x: 12.fit, y: 12, width: cardW, height: rowH * 3)
    }

    private func makeContactRow(icon: String, title: String, value: String, action: Selector) -> UIView {
        let row = UIView()
        row.backgroundColor = .clear

        let iconView = UIImageView(image: UIImage(systemName: icon)?.withRenderingMode(.alwaysTemplate))
        iconView.tintColor = AppColor.primary
        row.addSubview(iconView)
        iconView.frame = CGRect(x: 12.fit, y: 19, width: 18.fit, height: 18.fit)

        let titleLabel = UILabel.make(title, font: AppFont.body, color: AppColor.textMain)
        row.addSubview(titleLabel)
        titleLabel.frame = CGRect(x: iconView.right + 10.fit, y: 0, width: 100.fit, height: 56)

        let valueLabel = UILabel.make(value, font: AppFont.small, color: AppColor.textSub, alignment: .right)
        row.addSubview(valueLabel)
        valueLabel.frame = CGRect(x: Screen.width - 24.fit * 2 - 100.fit, y: 0, width: 100.fit, height: 56)

        let arrow = UIImageView(image: UIImage(systemName: "chevron.right")?.withRenderingMode(.alwaysTemplate))
        arrow.tintColor = AppColor.textHint
        row.addSubview(arrow)
        arrow.frame = CGRect(x: Screen.width - 24.fit * 2 - 8.fit, y: 22, width: 8, height: 12)

        let btn = UIButton(type: .custom)
        btn.backgroundColor = .clear
        btn.addTarget(self, action: action, for: .touchUpInside)
        row.addSubview(btn)
        btn.frame = CGRect(x: 0, y: 0, width: Screen.width - 24.fit, height: 56)

        // 保存联系方式供按钮调用
        objc_setAssociatedObject(btn, &ContactServiceViewController.kContactKey, value, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return row
    }

    private static var kContactKey: Void = ()

    // MARK: - FAQ
    private func setupFAQSection() {
        let sectionTitle = UILabel.make("常见问题", font: AppFont.bodyM, color: AppColor.textMain)
        contentContainer.addSubview(sectionTitle)
        sectionTitle.frame = CGRect(x: 16.fit, y: 12 + 56 * 3 + 16, width: 200.fit, height: 22)

        let cardY = sectionTitle.bottom + 8
        let cardW = Screen.width - 24.fit

        // 估算表格高度
        view.addSubview(tableView)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.tableFooterView = UIView()
        tableView.estimatedRowHeight = 60
        tableView.isScrollEnabled = false
        tableView.contentInsetAdjustmentBehavior = .never
        if #available(iOS 15.0, *) { tableView.sectionHeaderTopPadding = 0 }
        tableView.register(FAQCell.self, forCellReuseIdentifier: FAQCell.reuseId)

        contentContainer.addSubview(tableView)
        tableView.frame = CGRect(x: 12.fit, y: cardY, width: cardW, height: 320)

        let totalH = cardY + 320 + 24
        contentContainer.frame = CGRect(x: 0, y: 0, width: Screen.width, height: totalH)
        scrollView.contentSize = CGSize(width: Screen.width, height: totalH)
    }

    private func loadFAQs() {
        faqs = [
            FAQ(question: "如何发布活源？",
                answer: "在首页点击底部中间的发布按钮，选择“发布活源”，填写活源信息后即可发布。",
                expanded: false),
            FAQ(question: "如何联系活源发布人？",
                answer: "进入活源详情页，点击底部“立即联系”按钮即可拨打发布人电话。",
                expanded: false),
            FAQ(question: "活源发布后能修改吗？",
                answer: "可以。进入“我的-我的发布”，找到对应活源，点击“编辑”即可修改。",
                expanded: false),
            FAQ(question: "如何进行车主认证？",
                answer: "进入“我的-车主身份”，点击“去认证”按钮，按提示上传行驶证、营运证等资料即可。",
                expanded: false),
            FAQ(question: "忘记密码怎么办？",
                answer: "本平台使用手机验证码登录，无需密码。如收不到验证码，请检查手机号是否正确或联系客服。",
                expanded: false)
        ]
        tableView.reloadData()
        // 调整表格高度
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.tableView.frame.size.height = self.tableView.contentSize.height
            let totalH = self.tableView.frame.maxY + 24
            self.contentContainer.frame.size.height = totalH
            self.scrollView.contentSize = CGSize(width: Screen.width, height: totalH)
        }
    }

    // MARK: - 事件
    @objc private func callPhone(_ btn: UIButton) {
        let phone = (objc_getAssociatedObject(btn, &ContactServiceViewController.kContactKey) as? String) ?? ""
        AlertManager.shared.showAlert(title: "拨打客服电话",
                                      message: "是否拨打 \(phone)？",
                                      confirmTitle: "拨打",
                                      cancelTitle: "取消",
                                      confirmColor: AppColor.primary,
                                      onConfirm: {
            if let url = URL(string: "tel://\(phone.replacingOccurrences(of: "-", with: ""))") {
                UIApplication.shared.open(url)
            }
        })
        Logger.shared.track("contact_call_phone")
    }

    @objc private func copyWechat(_ btn: UIButton) {
        let value = (objc_getAssociatedObject(btn, &ContactServiceViewController.kContactKey) as? String) ?? ""
        UIPasteboard.general.string = value
        showToast("微信号已复制")
        Logger.shared.track("contact_copy_wechat")
    }

    @objc private func copyQQ(_ btn: UIButton) {
        let value = (objc_getAssociatedObject(btn, &ContactServiceViewController.kContactKey) as? String) ?? ""
        UIPasteboard.general.string = value
        showToast("QQ号已复制")
        Logger.shared.track("contact_copy_qq")
    }
}

// MARK: - 表格数据
extension ContactServiceViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return faqs.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: FAQCell.reuseId, for: indexPath) as! FAQCell
        cell.configure(with: faqs[indexPath.row]) { [weak self] in
            self?.toggleFAQ(at: indexPath.row)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        toggleFAQ(at: indexPath.row)
    }

    private func toggleFAQ(at idx: Int) {
        guard idx < faqs.count else { return }
        faqs[idx].expanded.toggle()
        tableView.reloadRows(at: [IndexPath(row: idx, section: 0)], with: .automatic)
        // 重新计算表格高度
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.tableView.frame.size.height = self.tableView.contentSize.height
            let totalH = self.tableView.frame.maxY + 24
            self.contentContainer.frame.size.height = totalH
            self.scrollView.contentSize = CGSize(width: Screen.width, height: totalH)
        }
    }
}

// MARK: - FAQ Cell
private final class FAQCell: UITableViewCell {
    static let reuseId = "FAQCell"

    private let container = UIView()
    private let questionLabel = UILabel.make("", font: AppFont.body, color: AppColor.textMain)
    private let answerLabel = UILabel.make("", font: AppFont.small, color: AppColor.textSub, lines: 0)
    private let arrow = UIImageView(image: UIImage(systemName: "chevron.right")?.withRenderingMode(.alwaysTemplate))
    private var onTap: (() -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        contentView.addSubview(container)
        container.backgroundColor = AppColor.cardBg
        container.layer.cornerRadius = 10

        container.addSubview(questionLabel)
        container.addSubview(answerLabel)
        container.addSubview(arrow)
        arrow.tintColor = AppColor.textHint

        let tap = UITapGestureRecognizer(target: self, action: #selector(tapped))
        container.addGestureRecognizer(tap)
    }

    required init?(coder: NSCoder) { fatalError() }

    @objc private func tapped() { onTap?() }

    override func layoutSubviews() {
        super.layoutSubviews()
        let padding: CGFloat = 12.fit
        container.frame = CGRect(x: padding, y: 4, width: Screen.width - padding * 2, height: max(heightForContent, 50))

        let qSize = questionLabel.text?.size(font: AppFont.body, maxWidth: container.w - 60.fit) ?? .zero
        questionLabel.frame = CGRect(x: 12.fit, y: 14, width: qSize.width, height: 22)

        arrow.frame = CGRect(x: container.w - 22.fit, y: 18, width: 8, height: 12)

        if answerLabel.text?.isEmpty == false {
            let aSize = answerLabel.sizeThatFits(CGSize(width: container.w - 24.fit, height: CGFloat.greatestFiniteMagnitude))
            answerLabel.frame = CGRect(x: 12.fit, y: questionLabel.bottom + 6,
                                       width: container.w - 24.fit, height: aSize.height)
        }
    }

    private var heightForContent: CGFloat {
        guard let q = questionLabel.text, !q.isEmpty else { return 50 }
        let qH: CGFloat = 22 + 14 * 2
        if answerLabel.isHidden { return qH }
        let aH = answerLabel.sizeThatFits(CGSize(width: Screen.width - 48.fit, height: CGFloat.greatestFiniteMagnitude)).height
        return qH + 6 + aH + 10
    }

    func configure(with faq: ContactServiceViewController.FAQ, onTap: @escaping () -> Void) {
        questionLabel.text = faq.question
        answerLabel.text = faq.answer
        answerLabel.isHidden = !faq.expanded
        arrow.image = UIImage(systemName: faq.expanded ? "chevron.down" : "chevron.right")?
            .withRenderingMode(.alwaysTemplate)
        self.onTap = onTap
        setNeedsLayout()
        layoutIfNeeded()
    }
}
