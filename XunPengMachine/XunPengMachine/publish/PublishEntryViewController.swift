//
//  PublishEntryViewController.swift
//  XunPengMachine
//
//  发布入口：alert 弹框样式，根据用户角色显示不同发布选项。
//  老板：求租机械（活源找车）→ PublishJobViewController
//  车主：出租机械（出租车辆）→ PublishCarViewController
//  通用：找驾驶员（招聘司机）→ PublishDriverViewController
//

import UIKit

final class PublishEntryViewController: BaseViewController {

    override var navStyle: NavStyle {
        get { .none }
        set { }
    }

    /// 半透明遮罩
    private let dimView = UIView()
    /// 弹框卡片
    private let cardView = UIView()
    /// 关闭按钮
    private let closeBtn = UIButton(type: .system)
    /// 堆叠容器
    private let stackView = UIStackView()

    /// 用户角色
    private var role: String { UserManager.shared.currentUser?.role ?? "boss" }

    /// 行数（角色行 + 招聘发布行）
    private var rowCount: Int { 2 }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        setupDim()
        setupCard()
        // 初始状态：卡片隐藏，避免弹出时白色闪现
        cardView.alpha = 0
        cardView.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
    }

    // MARK: - 遮罩
    private func setupDim() {
        dimView.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        view.addSubview(dimView)
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissSelf))
        dimView.addGestureRecognizer(tap)
    }

    // MARK: - 弹框卡片
    private func setupCard() {
        cardView.backgroundColor = .white
        cardView.layer.cornerRadius = 16.fit
        cardView.layer.masksToBounds = true
        view.addSubview(cardView)

        // 关闭按钮
        let closeImg = UIImage(systemName: "xmark")?
            .withTintColor(AppColor.textHint, renderingMode: .alwaysTemplate)
        closeBtn.setImage(closeImg, for: .normal)
        closeBtn.addTarget(self, action: #selector(dismissSelf), for: .touchUpInside)
        cardView.addSubview(closeBtn)

        // 按钮堆叠
        stackView.axis = .vertical
        stackView.spacing = 16.fit
        cardView.addSubview(stackView)

        // 第一行：根据角色显示
        if role == "boss" {
            addRow(category: "租赁发布",
                   title: "求租机械",
                   subtitle: "（活源找车）",
                   color: AppColor.danger,
                   action: #selector(jobTapped))
        } else if role == "car" {
            addRow(category: "租赁发布",
                   title: "出租机械",
                   subtitle: "（出租车辆）",
                   color: AppColor.danger,
                   action: #selector(carTapped))
        }
        // 第二行：招聘发布（boss, car）
        addRow(category: "招聘发布",
               title: "找驾驶员",
               subtitle: "（招聘司机）",
               color: AppColor.primary,
               action: #selector(driverTapped))
    }

    /// 添加一行：左侧分类标签 + 右侧彩色按钮
    private func addRow(category: String, title: String, subtitle: String,
                        color: UIColor, action: Selector) {
        let row = UIView()
        row.backgroundColor = .clear

        let catLabel = UILabel.make(category, font: AppFont.bodyM, color: AppColor.textMain)
        row.addSubview(catLabel)

        let btn = UIButton(type: .system)
        btn.backgroundColor = color
        btn.layer.cornerRadius = 8.fit
        btn.layer.masksToBounds = true
        let attr = NSMutableAttributedString()
        attr.append(NSAttributedString(string: title, attributes: [
            .font: AppFont.bodyM, .foregroundColor: UIColor.white
        ]))
        attr.append(NSAttributedString(string: "  \(subtitle)", attributes: [
            .font: AppFont.small, .foregroundColor: UIColor.white.withAlphaComponent(0.9)
        ]))
        btn.setAttributedTitle(attr, for: .normal)
        btn.contentEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        btn.addTarget(self, action: action, for: .touchUpInside)
        row.addSubview(btn)

        let arrow = UIImageView(image: UIImage(systemName: "chevron.right")?.withRenderingMode(.alwaysTemplate))
        arrow.tintColor = .white
        row.addSubview(arrow)

        row.translatesAutoresizingMaskIntoConstraints = false
        catLabel.translatesAutoresizingMaskIntoConstraints = false
        btn.translatesAutoresizingMaskIntoConstraints = false
        arrow.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            row.heightAnchor.constraint(equalToConstant: 72.fit),
            catLabel.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            catLabel.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            btn.trailingAnchor.constraint(equalTo: row.trailingAnchor),
            btn.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            btn.heightAnchor.constraint(equalToConstant: 48.fit),
            arrow.trailingAnchor.constraint(equalTo: btn.trailingAnchor, constant: -12.fit),
            arrow.centerYAnchor.constraint(equalTo: btn.centerYAnchor),
            arrow.widthAnchor.constraint(equalToConstant: 8.fit),
            arrow.heightAnchor.constraint(equalToConstant: 14.fit),
        ])

        stackView.addArrangedSubview(row)
    }

    // MARK: - 布局
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        dimView.frame = view.bounds

        let cardW: CGFloat = min(view.w - 48.fit, 320.fit)
        let cardH: CGFloat = 52.fit + CGFloat(rowCount) * 72.fit + 16.fit * CGFloat(max(0, rowCount - 1)) + 24.fit
        cardView.frame = CGRect(
            x: (view.w - cardW) / 2,
            y: (view.h - cardH) / 2,
            width: cardW,
            height: cardH
        )

        closeBtn.frame = CGRect(x: cardView.w - 40.fit, y: 12.fit,
                                width: 28.fit, height: 28.fit)
        stackView.frame = CGRect(x: 20.fit, y: 52.fit,
                                 width: cardView.w - 40.fit,
                                 height: cardView.h - 52.fit - 24.fit)
    }

    // MARK: - 动画
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // 卡片缩放淡入
        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseOut) {
            self.cardView.alpha = 1
            self.cardView.transform = .identity
        }
    }

    // MARK: - 事件
    @objc private func dismissSelf() {
        dismiss(animated: false)
    }

    @objc private func jobTapped() {
        Logger.shared.track("click_publish_job")
        dismiss(animated: false) { [weak self] in
            self?.rootVC()?.pushViewController(PublishJobViewController(), animated: true)
        }
    }

    @objc private func carTapped() {
        Logger.shared.track("click_publish_car")
        dismiss(animated: false) { [weak self] in
            self?.rootVC()?.pushViewController(PublishCarViewController(), animated: true)
        }
    }

    @objc private func driverTapped() {
        Logger.shared.track("click_publish_driver")
        dismiss(animated: false) { [weak self] in
            self?.rootVC()?.pushViewController(PublishDriverViewController(), animated: true)
        }
    }

    /// 获取当前最顶层的导航控制器
    private func rootVC() -> UINavigationController? {
        guard let root = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows }).first(where: { $0.isKeyWindow })?.rootViewController
        else { return nil }
        if let tab = root as? UITabBarController,
           let nav = tab.selectedViewController as? UINavigationController {
            return nav
        }
        if let nav = root as? UINavigationController { return nav }
        var top = root
        while let next = top.presentedViewController { top = next }
        return top as? UINavigationController ?? nil
    }
}
