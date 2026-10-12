//
//  SystemMessageViewController.swift
//  XunPengMachine
//
//  我的-系统消息分页列表
//

import UIKit

private final class SystemMessageReadStore {
    static let shared = SystemMessageReadStore()
    private let key = "com.xunpeng.system-message.read-ids"

    private init() {}

    func contains(_ id: Int64) -> Bool {
        readIDs.contains(String(id))
    }

    func markAsRead(_ id: Int64) {
        var ids = readIDs
        ids.insert(String(id))
        UserDefaults.standard.set(Array(ids), forKey: key)
    }

    private var readIDs: Set<String> {
        Set(UserDefaults.standard.stringArray(forKey: key) ?? [])
    }
}

private struct SystemMessagePage: Codable {
    let total: Int
    let list: [SystemMessage]
}

private final class SystemMessageViewModel: BaseViewModel {
    let messages = Observable.create([SystemMessage]())
    private(set) var hasMore = false
    private(set) var lastId = 0

    func load(lastId: Int, refresh: Bool) {
        NetworkManager.shared.request(
            .systemMessages(lastId: lastId),
            type: SystemMessagePage.self
        ) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                switch result {
                case .success(let page):
                    var values = page.list
                    if !refresh {
                        values = self.messages.value
                        values.append(contentsOf: page.list)
                    }
                    self.hasMore = values.count < page.total
                    if let id = page.list.last?.id, let cursor = Int(exactly: id) {
                        self.lastId = cursor
                    } else if refresh {
                        self.lastId = 0
                    }
                    self.messages.onNext(values)
                case .failure(let error):
                    Toast.shared.show(error.errorDescription ?? "加载失败")
                    // 触发列表订阅，确保请求失败时刷新动画也能正常结束。
                    self.messages.onNext(self.messages.value)
                }
            }
        }
    }
}

final class SystemMessageViewController: BaseTableViewController,
                                         UITableViewDataSource,
                                         UITableViewDelegate {

    override var navStyle: NavStyle {
        get { .white }
        set { }
    }

    private let viewModel = SystemMessageViewModel()
    private let emptyView = EmptyView(text: "暂无系统消息")
    private var isRefresh = true
    private var didLoadOnce = false
    private var hasFirstLoad = false

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "系统消息"
        setupBackButton()
        navigationController?.setNavigationBarHidden(false, animated: true)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = SystemMessageCell.rowHeight
        tableView.backgroundColor = AppColor.bg
        tableView.register(SystemMessageCell.self,
                           forCellReuseIdentifier: SystemMessageCell.reuseIdentifier)

        view.addSubview(emptyView)
        emptyView.isHidden = true
        bindViewModel()

        onRefresh = { [weak self] in
            guard let self else { return }
            self.isRefresh = true
            self.viewModel.load(lastId: 0, refresh: true)
        }
        onLoadMore = { [weak self] in
            guard let self else { return }
            self.isRefresh = false
            self.viewModel.load(lastId: self.viewModel.lastId, refresh: false)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !didLoadOnce {
            didLoadOnce = true
            beginRefreshing()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
        emptyView.center = CGPoint(x: view.bounds.midX, y: view.bounds.midY)
    }

    private func bindViewModel() {
        disposables.append(viewModel.messages.subscribe(onNext: { [weak self] _ in
            self?.handleListUpdated()
        }))
    }

    private func handleListUpdated() {
        if isLoading && isRefresh { hasFirstLoad = true }
        tableView.reloadData()
        emptyView.isHidden = !hasFirstLoad || !viewModel.messages.value.isEmpty
        guard isLoading else { return }
        if isRefresh {
            endRefresh()
        } else {
            endLoadMore(hasMore: viewModel.hasMore, lastId: viewModel.lastId)
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.messages.value.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: SystemMessageCell.reuseIdentifier,
            for: indexPath
        ) as! SystemMessageCell
        let message = viewModel.messages.value[indexPath.row]
        cell.configure(message, isRead: SystemMessageReadStore.shared.contains(message.id))
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let message = viewModel.messages.value[indexPath.row]
        SystemMessageReadStore.shared.markAsRead(message.id)
        tableView.reloadRows(at: [indexPath], with: .none)
        AlertManager.shared.showTip(message.content, title: message.title)
        Logger.shared.track("system_message_read", params: ["messageId": message.id])
    }
}

private final class SystemMessageCell: UITableViewCell {
    static let reuseIdentifier = "SystemMessageCell"
    static var rowHeight: CGFloat { 126.fit }

    private let cardView = UIView()
    private let unreadDot = UIView()
    private let titleLabel = UILabel.make("", font: AppFont.bodyM, color: AppColor.textMain)
    private let contentLabel = UILabel.make("", font: AppFont.body, color: AppColor.textMain, lines: 2)
    private let dateLabel = UILabel.make("", font: AppFont.small,
                                         color: AppColor.textHint, alignment: .right)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        cardView.backgroundColor = .white
        contentView.addSubview(cardView)
        [unreadDot, titleLabel, contentLabel, dateLabel].forEach(cardView.addSubview)
        unreadDot.backgroundColor = AppColor.primary
        unreadDot.layer.cornerRadius = 3.fit
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        let horizontalPadding: CGFloat = 4.fit
        cardView.frame = CGRect(x: horizontalPadding, y: 4.fit,
                                width: contentView.w - horizontalPadding * 2,
                                height: contentView.h - 8.fit)
        unreadDot.frame = CGRect(x: 8.fit, y: 16.fit, width: 6.fit, height: 6.fit)
        titleLabel.frame = CGRect(x: 20.fit, y: 10.fit,
                                  width: cardView.w - 30.fit, height: 20.fit)
        contentLabel.frame = CGRect(x: 8.fit, y: 36.fit,
                                    width: cardView.w - 16.fit, height: 42.fit)
        dateLabel.frame = CGRect(x: 8.fit, y: cardView.h - 28.fit,
                                 width: cardView.w - 16.fit, height: 18.fit)
    }

    func configure(_ message: SystemMessage, isRead: Bool) {
        titleLabel.text = message.title
        contentLabel.text = message.content
        dateLabel.text = message.createDateDisplayText
        unreadDot.isHidden = isRead
        titleLabel.font = isRead ? AppFont.body : AppFont.bodyM
        titleLabel.textColor = isRead ? AppColor.textSub : AppColor.textMain
        contentLabel.textColor = isRead ? AppColor.textHint : AppColor.textMain
    }
}
