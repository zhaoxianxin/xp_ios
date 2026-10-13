//
//  BossDriverListViewController.swift
//  XunPengMachine
//
//  我的-我发布的招聘
//

import UIKit

private struct BossDriverPage: Codable {
    let total: Int
    let list: [RecruitmentPost]
}

final class BossDriverListViewController: BaseViewController {

    /// 作为“我的发布”分栏子页面使用时，不重复配置导航栏。
    var isEmbeddedInPublishedPage = false

    private var posts: [RecruitmentPost] = []
    private var page = 1
    private var isLoading = false
    private var noMore = false

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let emptyView = EmptyView(text: "暂无发布的招聘")
    private let refreshControl = UIRefreshControl()

    override func viewDidLoad() {
        super.viewDidLoad()
        if !isEmbeddedInPublishedPage {
            title = "我发布的招聘"
            navStyle = .white
            setupBackButton()
            applyNavStyle()
        }
        setupUI()
        loadData(page: 1)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let top: CGFloat = isEmbeddedInPublishedPage ? 0 : 16
        tableView.frame = CGRect(x: 0, y: top, width: view.bounds.width,
                                 height: max(0, view.bounds.height - top))
        emptyView.center = CGPoint(x: view.bounds.midX, y: view.bounds.midY)
    }

    private func applyNavStyle() {
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationController?.navigationBar.barTintColor = .white
        navigationController?.navigationBar.tintColor = AppColor.textMain
        navigationController?.navigationBar.titleTextAttributes = [
            .foregroundColor: AppColor.textMain,
            .font: AppFont.navTitle
        ]
    }

    private func setupUI() {
        view.backgroundColor = AppColor.bg
        view.addSubview(tableView)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.tableFooterView = UIView()
        tableView.rowHeight = 148
        tableView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        tableView.contentInsetAdjustmentBehavior = .never
        if #available(iOS 15.0, *) { tableView.sectionHeaderTopPadding = 0 }
        tableView.register(BossDriverCell.self, forCellReuseIdentifier: BossDriverCell.reuseId)

        refreshControl.tintColor = AppColor.primary
        refreshControl.addTarget(self, action: #selector(pullToRefresh), for: .valueChanged)
        tableView.refreshControl = refreshControl

        view.addSubview(emptyView)
        emptyView.isHidden = true

        tableView.addObserver(self, forKeyPath: "contentOffset", options: [.new], context: nil)
    }

    deinit {
        tableView.removeObserver(self, forKeyPath: "contentOffset")
    }

    private func loadData(page: Int) {
        guard !isLoading else { return }
        isLoading = true
        if page == 1, !refreshControl.isRefreshing { LoadingHUD.shared.show() }

        NetworkManager.shared.request(.myDrivers(page: page), type: BossDriverPage.self) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isLoading = false
                LoadingHUD.shared.hide()
                self.refreshControl.endRefreshing()

                switch result {
                case .success(let pageData):
                    if page == 1 {
                        self.posts = pageData.list
                    } else {
                        self.posts.append(contentsOf: pageData.list)
                    }
                    self.page = page
                    self.noMore = self.posts.count >= pageData.total || pageData.list.isEmpty
                    Logger.shared.track("boss_driver_list_loaded", params: ["count": self.posts.count])
                case .failure(let error):
                    self.showToast(error.errorDescription ?? "加载失败")
                }

                self.tableView.reloadData()
                self.emptyView.isHidden = !self.posts.isEmpty
            }
        }
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?,
                               change: [NSKeyValueChangeKey: Any]?,
                               context: UnsafeMutableRawPointer?) {
        guard keyPath == "contentOffset" else { return }
        let y = tableView.contentOffset.y
        if tableView.contentSize.height > 0,
           y + tableView.h >= tableView.contentSize.height - 40,
           !isLoading, !noMore {
            loadData(page: page + 1)
        }
    }

    @objc private func pullToRefresh() {
        noMore = false
        loadData(page: 1)
    }
}

extension BossDriverListViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        posts.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: BossDriverCell.reuseId,
            for: indexPath
        ) as! BossDriverCell
        let post = posts[indexPath.row]
        cell.configure(with: post) { [weak self] action in
            self?.handle(action: action, post: post)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let detail = DriverDetailViewController(id: String(posts[indexPath.row].id), isOwner: true)
        detail.onContentChanged = { [weak self] in
            self?.noMore = false
            self?.loadData(page: 1)
        }
        navigationController?.pushViewController(detail, animated: true)
    }

    private func handle(action: BossDriverCell.Action, post: RecruitmentPost) {
        switch action {
        case .recruiting:
            showToast("当前状态：招聘中")
        case .found:
            showToast("标记已找到接口待接入")
        case .edit:
            let editor = PublishDriverViewController(driver: post)
            editor.onSaved = { [weak self] in
                self?.noMore = false
                self?.loadData(page: 1)
            }
            navigationController?.pushViewController(editor, animated: true)
        }
        Logger.shared.track("boss_driver_action", params: [
            "driverId": post.id,
            "action": action.rawValue
        ])
    }
}

private final class BossDriverCell: UITableViewCell {

    enum Action: String {
        case recruiting
        case found
        case edit
    }

    static let reuseId = "BossDriverCell"

    private let container = UIView()
    private let titleLabel = UILabel.make("", font: AppFont.bodyM, color: AppColor.textMain)
    private let salaryLabel = InsetLabel()
    private let categoryLabel = InsetLabel()
    private let workTypeLabel = InsetLabel()
    private let infoLabel = UILabel.make("", font: AppFont.small, color: AppColor.textSub)
    private let separator = UIView()
    private let recruitingButton = UIButton(type: .system)
    private let foundButton = UIButton(type: .system)
    private let editButton = UIButton(type: .system)
    private var onAction: ((Action) -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        container.backgroundColor = .white
        contentView.addSubview(container)
        [titleLabel, salaryLabel, categoryLabel, workTypeLabel, infoLabel,
         separator, recruitingButton, foundButton, editButton].forEach(container.addSubview)

        titleLabel.lineBreakMode = .byTruncatingTail
        configureTag(salaryLabel, textColor: AppColor.primary,
                     backgroundColor: AppColor.primary.withAlphaComponent(0.08))
        configureTag(categoryLabel, textColor: AppColor.textSub, backgroundColor: AppColor.bg)
        configureTag(workTypeLabel, textColor: AppColor.textSub, backgroundColor: AppColor.bg)
        separator.backgroundColor = AppColor.separator

        configureButton(recruitingButton, title: "招聘中", color: AppColor.primary,
                        selector: #selector(recruitingTapped))
        configureButton(foundButton, title: "已找到", color: AppColor.textSub,
                        selector: #selector(foundTapped))
        configureButton(editButton, title: "修改", color: AppColor.textSub,
                        selector: #selector(editTapped))
    }

    required init?(coder: NSCoder) { fatalError() }

    private func configureTag(_ label: UILabel, textColor: UIColor, backgroundColor: UIColor) {
        label.font = AppFont.mini
        label.textColor = textColor
        label.backgroundColor = backgroundColor
        label.layer.cornerRadius = 2
        label.layer.masksToBounds = true
        label.textAlignment = .center
    }

    private func configureButton(_ button: UIButton, title: String, color: UIColor,
                                 selector: Selector) {
        button.setTitle(title, for: .normal)
        button.setTitleColor(color, for: .normal)
        button.titleLabel?.font = AppFont.small
        button.layer.cornerRadius = 4
        button.layer.borderWidth = 0.5
        button.layer.borderColor = color.cgColor
        button.addTarget(self, action: selector, for: .touchUpInside)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let cardX: CGFloat = 8.fit
        let cardWidth = Screen.width - cardX * 2
        container.frame = CGRect(x: cardX, y: 4, width: cardWidth, height: 140)
        titleLabel.frame = CGRect(x: 8.fit, y: 8, width: cardWidth - 16.fit, height: 21)

        let tagY: CGFloat = 36
        var tagX: CGFloat = 8.fit
        for label in [salaryLabel, categoryLabel, workTypeLabel] {
            let width = min(cardWidth - tagX - 8.fit,
                            (label.text?.size(font: AppFont.mini).width ?? 0) + 16.fit)
            label.frame = CGRect(x: tagX, y: tagY, width: width, height: 22)
            tagX = label.right + 14.fit
        }

        infoLabel.frame = CGRect(x: 8.fit, y: 64, width: cardWidth - 16.fit, height: 19)
        separator.frame = CGRect(x: 0, y: 90, width: cardWidth, height: 0.5)

        let buttonY: CGFloat = 101
        let buttonWidth: CGFloat = 68.fit
        let buttonHeight: CGFloat = 32
        recruitingButton.frame = CGRect(x: 12.fit, y: buttonY, width: buttonWidth, height: buttonHeight)
        foundButton.frame = CGRect(x: recruitingButton.right + 16.fit, y: buttonY,
                                   width: buttonWidth, height: buttonHeight)
        editButton.frame = CGRect(x: foundButton.right + 16.fit, y: buttonY,
                                  width: buttonWidth, height: buttonHeight)
    }

    func configure(with post: RecruitmentPost, onAction: @escaping (Action) -> Void) {
        titleLabel.text = post.title
        salaryLabel.text = post.salaryDisplayText
        categoryLabel.text = post.category
        workTypeLabel.text = post.workTypeDisplayText
        infoLabel.text = [post.cityName, post.createTimeDisplayText]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: "  ")
        self.onAction = onAction
        setNeedsLayout()
    }

    @objc private func recruitingTapped() { onAction?(.recruiting) }
    @objc private func foundTapped() { onAction?(.found) }
    @objc private func editTapped() { onAction?(.edit) }
}

private final class InsetLabel: UILabel {
    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.insetBy(dx: 8.fit, dy: 0))
    }
}
