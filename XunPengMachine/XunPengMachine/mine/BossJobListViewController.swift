//
//  BossJobListViewController.swift
//  XunPengMachine
//
//  我的-我发布的活源：分页列表 + 下拉刷新 + 操作按钮
//

import UIKit

private struct BossJobPage: Codable {
    let total: Int
    let list: [Job]
}

final class BossJobListViewController: BaseViewController {

    /// 作为“我的发布”分栏子页面使用时，不重复配置导航栏。
    var isEmbeddedInPublishedPage = false

    private var jobs: [Job] = []
    private var page = 1
    private var isLoading = false
    private var noMore = false

    // MARK: - UI
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let emptyView = EmptyView(text: "暂无发布的活源")
    private let refreshControl = UIRefreshControl()

    // MARK: - 生命周期
    override func viewDidLoad() {
        super.viewDidLoad()
        if !isEmbeddedInPublishedPage {
            title = "我发布的活源"
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
            .foregroundColor: AppColor.textMain, .font: AppFont.navTitle
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
        tableView.estimatedRowHeight = 160
        tableView.rowHeight = 160
        tableView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        tableView.contentInsetAdjustmentBehavior = .never
        if #available(iOS 15.0, *) { tableView.sectionHeaderTopPadding = 0 }
        tableView.register(BossJobCell.self, forCellReuseIdentifier: BossJobCell.reuseId)

        // 下拉刷新
        refreshControl.tintColor = AppColor.primary
        refreshControl.addTarget(self, action: #selector(pullToRefresh), for: .valueChanged)
        tableView.refreshControl = refreshControl

        // 空视图
        view.addSubview(emptyView)
        emptyView.isHidden = true

        // 上拉加载更多（监听滚动）
        tableView.addObserver(self, forKeyPath: "contentOffset", options: [.new], context: nil)
    }

    deinit {
        tableView.removeObserver(self, forKeyPath: "contentOffset")
    }

    // MARK: - 数据
    private func loadData(page: Int) {
        guard !isLoading else { return }
        isLoading = true
        if page == 1 && !refreshControl.isRefreshing {
            LoadingHUD.shared.show()
        }
        NetworkManager.shared.request(.myJobs(page: page), type: BossJobPage.self) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isLoading = false
                LoadingHUD.shared.hide()
                if self.refreshControl.isRefreshing {
                    self.refreshControl.endRefreshing()
                }
                switch result {
                case .success(let pageData):
                    if page == 1 {
                        self.jobs = pageData.list
                    } else {
                        self.jobs.append(contentsOf: pageData.list)
                    }
                    self.noMore = self.jobs.count >= pageData.total || pageData.list.isEmpty
                    self.page = page
                    Logger.shared.track("boss_job_list_loaded", params: ["count": self.jobs.count])
                case .failure(let error):
                    self.showToast(error.errorDescription ?? "加载失败")
                }
                self.tableView.reloadData()
                self.emptyView.isHidden = !self.jobs.isEmpty
            }
        }
    }

    // MARK: - KVO 滚动监听（上拉加载更多）
    override func observeValue(forKeyPath keyPath: String?, of object: Any?,
                               change: [NSKeyValueChangeKey: Any]?,
                               context: UnsafeMutableRawPointer?) {
        guard keyPath == "contentOffset" else { return }
        let y = tableView.contentOffset.y
        let contentH = tableView.contentSize.height
        if contentH > 0, y + tableView.h >= contentH - 40, !isLoading, !noMore {
            loadData(page: page + 1)
        }
    }

    // MARK: - 事件
    @objc private func pullToRefresh() {
        loadData(page: 1)
    }
}

// MARK: - 表格数据
extension BossJobListViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return jobs.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: BossJobCell.reuseId, for: indexPath) as! BossJobCell
        let job = jobs[indexPath.row]
        let status: BossJobCell.Status = job.businessStatus == 0 ? .ongoing : .found
        cell.configure(with: job, status: status) { [weak self] action in
            self?.handleCellAction(action: action, job: self?.jobs[indexPath.row])
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let detail = JobDetailViewController(id: jobs[indexPath.row].id, isOwner: true)
        detail.onContentChanged = { [weak self] in
            self?.noMore = false
            self?.loadData(page: 1)
        }
        navigationController?.pushViewController(detail, animated: true)
    }

    private func handleCellAction(action: BossJobCell.Action, job: Job?) {
        guard let job = job else { return }
        switch action {
        case .edit:
            let editor = PublishJobViewController(job: job)
            editor.onSaved = { [weak self] in
                self?.noMore = false
                self?.loadData(page: 1)
            }
            navigationController?.pushViewController(editor, animated: true)
            Logger.shared.track("boss_job_click_edit", params: ["jobId": job.id])
        case .offline:
            AlertManager.shared.showAlert(title: "下架活源",
                                          message: "确定要下架「\(job.title)」吗？",
                                          confirmTitle: "下架",
                                          cancelTitle: "取消",
                                          confirmColor: AppColor.danger,
                                          onConfirm: { [weak self] in
                self?.showToast("已下架")
                Logger.shared.track("boss_job_offline", params: ["jobId": job.id])
            })
        }
    }
}

// MARK: - 我发布的活源 Cell
private final class BossJobCell: UITableViewCell {

    enum Status { case ongoing, found }
    enum Action { case edit, offline }

    static let reuseId = "BossJobCell"

    private let container = UIView()
    private let titleLabel = UILabel.make("", font: AppFont.bodyM, color: AppColor.textMain)
    private let statusTag = UIView()
    private let statusLabel = UILabel.make("", font: AppFont.mini, color: .white)
    private let priceLabel = UILabel.make("", font: AppFont.price, color: AppColor.price)
    private let unitLabel = UILabel.make("", font: AppFont.small, color: AppColor.textSub)
    private let timeLabel = UILabel.make("", font: AppFont.small, color: AppColor.textHint)
    private let editButton = UIButton.make("编辑", font: AppFont.small, titleColor: AppColor.textSub, bgColor: AppColor.bg)
    private let offlineButton = UIButton.make("下架", font: AppFont.small, titleColor: AppColor.textSub, bgColor: AppColor.bg)
    private var onAction: ((Action) -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        contentView.addSubview(container)
        container.backgroundColor = AppColor.cardBg
        container.layer.cornerRadius = 10

        container.addSubview(titleLabel)
        container.addSubview(statusTag)
        statusTag.addSubview(statusLabel)
        statusTag.layer.cornerRadius = 3
        container.addSubview(priceLabel)
        container.addSubview(unitLabel)
        container.addSubview(timeLabel)

        editButton.layer.cornerRadius = 12
        editButton.contentEdgeInsets = UIEdgeInsets(top: 4, left: 12, bottom: 4, right: 12)
        editButton.addTarget(self, action: #selector(editTapped), for: .touchUpInside)
        container.addSubview(editButton)

        offlineButton.layer.cornerRadius = 12
        offlineButton.contentEdgeInsets = UIEdgeInsets(top: 4, left: 12, bottom: 4, right: 12)
        offlineButton.addTarget(self, action: #selector(offlineTapped), for: .touchUpInside)
        container.addSubview(offlineButton)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        let padding: CGFloat = 12.fit
        let cardW = Screen.width - padding * 2
        container.frame = CGRect(x: padding, y: 4, width: cardW, height: 152)

        // 标题
        let titleW = cardW - 24.fit - 70
        titleLabel.frame = CGRect(x: 12.fit, y: 12, width: titleW, height: 22)

        // 状态 tag
        let statusW = statusLabel.text?.size(font: AppFont.mini).width ?? 0
        statusTag.frame = CGRect(x: cardW - 12.fit - statusW - 12, y: 14,
                                 width: statusW + 12, height: 20)
        statusLabel.frame = CGRect(x: 6, y: 3, width: statusW, height: 14)

        // 价格
        let priceW = priceLabel.text?.size(font: AppFont.price).width ?? 0
        priceLabel.frame = CGRect(x: 12.fit, y: titleLabel.bottom + 12, width: priceW, height: 24)
        unitLabel.frame = CGRect(x: priceLabel.right + 4, y: priceLabel.bottom - 18,
                                 width: 60.fit, height: 18)

        // 时间
        timeLabel.frame = CGRect(x: 12.fit, y: priceLabel.bottom + 8, width: cardW - 24.fit, height: 18)

        // 操作按钮
        let btnW: CGFloat = 56.fit
        let btnH: CGFloat = 26
        offlineButton.frame = CGRect(x: cardW - 12.fit - btnW, y: 110,
                                     width: btnW, height: btnH)
        editButton.frame = CGRect(x: offlineButton.x - 8 - btnW, y: 110,
                                  width: btnW, height: btnH)
    }

    func configure(with job: Job, status: Status, onAction: @escaping (Action) -> Void) {
        titleLabel.text = job.title
        priceLabel.text = job.rentAmountText
        unitLabel.text = "元"
        timeLabel.text = "发布时间：\(job.createTimeText)  ·  浏览 \(job.viewCount) 次"

        switch status {
        case .ongoing:
            statusLabel.text = "进行中"
            statusTag.backgroundColor = AppColor.online
        case .found:
            statusLabel.text = "已找到"
            statusTag.backgroundColor = AppColor.textHint
        }

        self.onAction = onAction
        setNeedsLayout()
        layoutIfNeeded()
    }

    @objc private func editTapped() { onAction?(.edit) }
    @objc private func offlineTapped() { onAction?(.offline) }
}
