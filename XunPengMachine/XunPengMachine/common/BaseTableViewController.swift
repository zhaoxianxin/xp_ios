//
//  BaseTableViewController.swift
//  XunPengMachine
//
//  列表基类：下拉刷新 + 上拉加载 + 空视图 + 分页
//

import UIKit

class BaseTableViewController: BaseViewController {

    let tableView = UITableView(frame: .zero, style: .plain)
    private(set) var page = 0
    /// 每页条数（用于判断是否还有更多）
    var pageSize = 10
    private(set) var noMore = false
    private(set) var isLoading = false

    /// 下拉刷新回调
    var onRefresh: (() -> Void)?
    /// 上拉加载回调
    var onLoadMore: (() -> Void)?

    private var refreshHeader: RefreshHeader?
    private var loadMoreFooter: LoadMoreFooter?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
    }

    private func setupTableView() {
        view.addSubview(tableView)
        tableView.frame = view.bounds
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tableView.backgroundColor = AppColor.bg
        tableView.separatorStyle = .none
        tableView.tableFooterView = UIView()
        if #available(iOS 15.0, *) { tableView.sectionHeaderTopPadding = 0 }
        tableView.contentInsetAdjustmentBehavior = .never

        // 下拉刷新头
        let header = RefreshHeader()
        refreshHeader = header
        tableView.addSubview(header)
        header.frame = CGRect(x: 0, y: -RefreshHeader.height, width: Screen.width, height: RefreshHeader.height)

        // 上拉加载尾
        let footer = LoadMoreFooter()
        loadMoreFooter = footer
        tableView.tableFooterView = footer
        footer.frame = CGRect(x: 0, y: 0, width: Screen.width, height: LoadMoreFooter.height)

        observeScroll()
    }

    private func observeScroll() {
        tableView.rx_observe { [weak self] in
            self?.handleScroll()
        }
    }

    private func handleScroll() {
        let y = tableView.contentOffset.y
        // 下拉触发
        if y <= -RefreshHeader.height, !isLoading {
            beginRefreshing()
        }
        // 上拉触发
        let contentH = tableView.contentSize.height
        if contentH > 0, y + tableView.h >= contentH - 40, !isLoading, !noMore {
            beginLoadMore()
        }
    }

    func beginRefreshing() {
        guard !isLoading else { return }
        isLoading = true
        page = 0
        noMore = false
        refreshHeader?.start()
        onRefresh?()
    }

    func beginLoadMore() {
        guard !isLoading else { return }
        isLoading = true
        loadMoreFooter?.start()
        onLoadMore?()
    }

    /// 下拉刷新结束
    func endRefresh() {
        isLoading = false
        refreshHeader?.stop()
    }

    /// 上拉加载结束
    /// - Parameter hasMore: 是否还有更多数据
    func endLoadMore(hasMore: Bool, lastId: Int? = 0) {
        isLoading = false
        noMore = !hasMore
        loadMoreFooter?.stop(noMore: noMore)
        if hasMore { page = lastId ?? 0 }
    }
}

// MARK: - 下拉刷新头
private class RefreshHeader: UIView {
    static let height: CGFloat = 60
    private let indicator = UIActivityIndicatorView(style: .gray)
    private let label = UILabel.make("下拉刷新", font: AppFont.small, color: AppColor.textHint)

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(indicator)
        addSubview(label)
        indicator.bounds = CGRect(x: 0, y: 0, width: 20, height: 20)
        indicator.center = CGPoint(x: Screen.width / 2 - 40, y: Self.height / 2)
        label.frame = CGRect(x: indicator.right + 8, y: 0, width: 100, height: Self.height)
        label.center.y = Self.height / 2
    }
    required init?(coder: NSCoder) { fatalError() }

    func start() {
        indicator.startAnimating()
        label.text = "正在刷新..."
    }
    func stop() {
        indicator.stopAnimating()
        label.text = "下拉刷新"
    }
}

// MARK: - 上拉加载尾
private class LoadMoreFooter: UIView {
    static let height: CGFloat = 50
    private let indicator = UIActivityIndicatorView(style: .gray)
    private let label = UILabel.make("加载中...", font: AppFont.small, color: AppColor.textHint)

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(indicator)
        addSubview(label)
        indicator.bounds = CGRect(x: 0, y: 0, width: 20, height: 20)
        let totalW = indicator.w + 8 + 60
        indicator.frame.origin = CGPoint(x: (Screen.width - totalW) / 2, y: (Self.height - indicator.h) / 2)
        label.frame = CGRect(x: indicator.right + 8, y: 0, width: 60, height: Self.height)
        label.center.y = Self.height / 2
    }
    required init?(coder: NSCoder) { fatalError() }

    func start() { indicator.startAnimating(); label.text = "加载中..." }
    func stop(noMore: Bool) {
        indicator.stopAnimating()
        label.text = noMore ? "没有更多了" : "上拉加载更多"
    }
}

// MARK: - KVO 简易观察 contentOffset
private extension UITableView {
    func rx_observe(_ handler: @escaping () -> Void) {
        let proxy = ScrollProxy()
        proxy.handler = handler
        proxy.tableView = self
        addObserver(proxy, forKeyPath: "contentOffset", options: [.new], context: nil)
        objc_setAssociatedObject(self, &UITableView.kProxyKey, proxy, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    private static var kProxyKey: Void = ()
}

private final class ScrollProxy: NSObject {
    weak var tableView: UITableView?
    var handler: (() -> Void)?
    override func observeValue(forKeyPath keyPath: String?, of object: Any?,
                               change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        handler?()
    }
}
