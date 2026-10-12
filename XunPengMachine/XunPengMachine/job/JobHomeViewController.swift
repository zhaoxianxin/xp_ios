//
//  JobHomeViewController.swift
//  XunPengMachine
//
//  找活-首页：巡朋机械顶栏 + 筛选条 + 活源列表
//

import UIKit

final class JobHomeViewController: BaseTableViewController, UITableViewDataSource, UITableViewDelegate {

    private let vm = JobViewModel()

    private var displayList: [Job] = []
    private var isRefresh = true
    private var didLoadOnce = false
    private var hasFirstLoad = false
    private var searchKeyword = ""
    private var equipmentFilter = "全部机械"

    private let topBar = HomeTopBarView(remindTitle: "好活提醒")
    private let filterBar = HomeFilterBarView(centerTitle: "求租设备")
    private let emptyView = EmptyView(text: "暂无活源")

    override var navStyle: NavStyle {
        get { .none }
        set { /* 固定隐藏系统导航栏 */ }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)

        setupHeader()
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(JobCell.self, forCellReuseIdentifier: "JobCell")
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 148.fit
        tableView.backgroundColor = AppColor.bg

        view.addSubview(emptyView)
        emptyView.isHidden = true
        bindViewModel()

        onRefresh = { [weak self] in
            guard let self = self else { return }
            self.isRefresh = true
            self.vm.loadList(page: 1, refresh: true)
        }
        onLoadMore = { [weak self] in
            guard let self = self else { return }
            self.isRefresh = false
            self.vm.loadList(page: self.page + 1, refresh: false)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !didLoadOnce {
            didLoadOnce = true
            beginRefreshing()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let headerH = HomeTopBarView.preferredHeight + HomeFilterBarView.height
        topBar.frame = CGRect(x: 0, y: 0, width: view.w, height: HomeTopBarView.preferredHeight)
        filterBar.frame = CGRect(x: 0, y: topBar.bottom, width: view.w, height: HomeFilterBarView.height)
        tableView.frame = CGRect(x: 0, y: headerH, width: view.w, height: view.h - headerH)
        emptyView.center = CGPoint(x: tableView.w / 2, y: tableView.h / 2 + headerH/2)
    }

    private func setupHeader() {
        view.addSubview(topBar)
        view.addSubview(filterBar)

        topBar.onRemindTapped = { [weak self] in
            self?.navigationController?.pushViewController(JobRemindViewController(), animated: true)
        }
        filterBar.disableCenter()
        
        filterBar.onLeftTapped = { [weak self] in self?.cityTapped() }
        filterBar.onRightTapped = { [weak self] in self?.equipmentTapped() }
    }

    private func bindViewModel() {
        disposables.append(vm.list.subscribe(onNext: { [weak self] _ in
            self?.handleListUpdated()
        }))
    }

    private func handleListUpdated() {
        if isLoading && isRefresh { hasFirstLoad = true }
        applyFilter()
        guard isLoading else { return }
        if isRefresh { endRefresh() }
        else { endLoadMore(hasMore: vm.hasMore, lastId: vm.lastId) }
        emptyView.isHidden = !displayList.isEmpty
    }

    private func applyFilter() {
        var result = vm.list.value
        if equipmentFilter != "全部机械" {
            result = result.filter { $0.category.contains(equipmentFilter) }
        }
        let kw = searchKeyword.trimmingCharacters(in: .whitespaces)
        if !kw.isEmpty {
            result = result.filter {
                $0.title.contains(kw) || $0.category.contains(kw) || $0.cityDisplayText.contains(kw)
            }
        }
        displayList = result
        tableView.reloadData()
        emptyView.isHidden = !hasFirstLoad || !displayList.isEmpty
    }

    private func cityTapped() {
        Logger.shared.track("job_click_city")
        let picker = CityPickerViewController()
        picker.onPick = { [weak self] city in
            guard let self = self else { return }
            self.vm.city = city.name == "全国" ? nil : city.name
            self.filterBar.updateLeft(city.name)
            self.beginRefreshing()
        }
        navigationController?.pushViewController(picker, animated: true)
    }

    private func equipmentTapped() {
        let picker = EquipmentPickerViewController()
        picker.onPick = { [weak self] eq in
            guard let self = self else { return }
            self.equipmentFilter = eq.name
            self.filterBar.updateRight(eq.name)
            self.applyFilter()
        }
        navigationController?.pushViewController(picker, animated: true)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        displayList.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "JobCell", for: indexPath) as! JobCell
        if indexPath.row < displayList.count {
            cell.configure(displayList[indexPath.row])
        }
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard indexPath.row < displayList.count else { return 148.fit }
        return JobCell.rowHeight(for: displayList[indexPath.row])
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        guard indexPath.row < displayList.count else { return }
        let job = displayList[indexPath.row]
        Logger.shared.track("job_click_detail", params: ["id": job.id])
        navigationController?.pushViewController(JobDetailViewController(id: job.id), animated: true)
    }
}
