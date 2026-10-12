//
//  DriverHomeViewController.swift
//  XunPengMachine
//
//  招聘-首页：巡朋机械顶栏 + 筛选条 + 招聘列表
//

import UIKit

final class DriverHomeViewController: BaseTableViewController, UITableViewDataSource, UITableViewDelegate {

    private let vm = DriverViewModel()

    private var displayList: [Driver] = []
    private var isRefresh = true
    private var didLoadOnce = false
    private var hasFirstLoad = false
    private var equipmentFilter = "全部机械"
    private var jobTypeFilter = "长替都行"

    private let topBar = HomeTopBarView(remindTitle: "工作提醒")
    private let filterBar = HomeFilterBarView(centerTitle: "全部机械", rightTitle: "长替都行", centerHighlighted: false)
    private let emptyView = EmptyView(text: "暂无招聘")

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
        tableView.register(DriverCell.self, forCellReuseIdentifier: "DriverCell")
        tableView.rowHeight = DriverCell.rowHeight
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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let headerH = HomeTopBarView.preferredHeight + HomeFilterBarView.height
        topBar.frame = CGRect(x: 0, y: 0, width: view.w, height: HomeTopBarView.preferredHeight)
        filterBar.frame = CGRect(x: 0, y: topBar.bottom, width: view.w, height: HomeFilterBarView.height)
        tableView.frame = CGRect(x: 0, y: headerH, width: view.w, height: view.h - headerH)
        emptyView.center = CGPoint(x: tableView.w / 2, y: tableView.h / 2)
    }

    private func setupHeader() {
        view.addSubview(topBar)
        view.addSubview(filterBar)

        topBar.onRemindTapped = { [weak self] in
            self?.navigationController?.pushViewController(
                DriverWorkReminderViewController(),
                animated: true
            )
        }
        
        filterBar.onLeftTapped = { [weak self] in self?.cityTapped() }
        filterBar.onCenterTapped = { [weak self] in self?.equipmentTapped() }
        filterBar.onRightTapped = { [weak self] in self?.jobTypeTapped() }
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
        else { endLoadMore(hasMore: vm.hasMore) }
    }

    private func applyFilter() {
        var result = vm.list.value
        if equipmentFilter != "全部机械" {
            result = result.filter { $0.category.contains(equipmentFilter) }
        }
        if jobTypeFilter == "长期活" {
            result = result.filter { $0.workType == 1 || $0.workTypeDisplayText.contains("长期") }
        } else if jobTypeFilter == "替班活" {
            result = result.filter { $0.workType == 2 || $0.workTypeDisplayText.contains("替班") }
        }
        displayList = result
        tableView.reloadData()
        emptyView.isHidden = !hasFirstLoad || !displayList.isEmpty
    }

    private func cityTapped() {
        Logger.shared.track("driver_click_city")
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
            self.filterBar.updateCenter(eq.name)
            self.applyFilter()
        }
        navigationController?.pushViewController(picker, animated: true)
    }

    private func jobTypeTapped() {
        let sheet = UIAlertController(title: "活源类型", message: nil, preferredStyle: .actionSheet)
        let types = ["长替都行", "长期活", "替班活"]
        for type in types {
            sheet.addAction(UIAlertAction(title: type, style: .default) { [weak self] _ in
                self?.jobTypeFilter = type
                self?.filterBar.updateRight(type)
                self?.applyFilter()
            })
        }
        sheet.addAction(UIAlertAction(title: "取消", style: .cancel))
        present(sheet, animated: true)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        displayList.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DriverCell", for: indexPath) as! DriverCell
        if indexPath.row < displayList.count {
            let driver = displayList[indexPath.row]
            cell.configure(driver)
            cell.onCallTapped = { [weak self] in
                self?.callDriver(driver)
            }
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        guard indexPath.row < displayList.count else { return }
        let driver = displayList[indexPath.row]
        Logger.shared.track("driver_click_detail", params: ["id": driver.id])
        navigationController?.pushViewController(
            DriverDetailViewController(id: String(driver.id)),
            animated: true
        )
    }

    private func callDriver(_ driver: Driver) {
        Logger.shared.track("driver_click_call", params: ["id": driver.id])
        guard let mobile = driver.contactMobile?.trimmingCharacters(in: .whitespacesAndNewlines),
              !mobile.isEmpty,
              let url = URL(string: "tel://\(mobile)") else {
            showToast("暂无有效联系电话")
            return
        }
        UIApplication.shared.open(url)
    }
}
