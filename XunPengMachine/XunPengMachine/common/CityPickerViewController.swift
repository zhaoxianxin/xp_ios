//
//  CityPickerViewController.swift
//  XunPengMachine
//
//  城市选择器：两级联动（左侧省级 + 右侧城市）
//

import UIKit
import Foundation

class CityPickerViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate {

    private struct AreaResponse: Decodable {
        let data: [AreaNode]
    }

    private struct AreaNode: Decodable {
        let id: Int64
        let name: String
        let children: [AreaNode]
    }

    /// 选择回调
    var onPick: ((City) -> Void)?

    /// 省份列表（首项「全国」合成）
    private let provinces: [Province] = {
        let global = Province(name: "全国", cities: [City(code: "", name: "全国", hot: false)])
        return [global] + CityPickerViewController.loadProvinces()
    }()

    private static func loadProvinces() -> [Province] {
        guard let url = Bundle.main.url(forResource: "system_area_tree", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let response = try? JSONDecoder().decode(AreaResponse.self, from: data) else {
            return []
        }

        return response.data.map { province in
            Province(
                name: province.name,
                cities: province.children.map { city in
                    City(code: String(city.id), name: city.name, hot: false)
                }
            )
        }
    }

    /// 当前选中的省份索引
    private var selectedProvinceIndex = 0

    private let leftTable = UITableView(frame: .zero, style: .plain)
    private let rightTable = UITableView(frame: .zero, style: .grouped)

    /// 左侧宽度
    private let leftWidth: CGFloat = 100.fit

    override var navStyle: NavStyle {
        get { .white }
        set { }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "选择城市"
        setupBackButton()
        view.backgroundColor = AppColor.bg

        setupLeftTable()
        setupRightTable()
    }

    // MARK: - Setup
    private func setupLeftTable() {
        view.addSubview(leftTable)
        leftTable.dataSource = self
        leftTable.delegate = self
        leftTable.register(UITableViewCell.self, forCellReuseIdentifier: "provinceCell")
        leftTable.tableFooterView = UIView()
        leftTable.backgroundColor = AppColor.bg
        leftTable.separatorStyle = .none
        if #available(iOS 15.0, *) { leftTable.sectionHeaderTopPadding = 0 }
    }

    private func setupRightTable() {
        view.addSubview(rightTable)
        rightTable.dataSource = self
        rightTable.delegate = self
        rightTable.register(UITableViewCell.self, forCellReuseIdentifier: "cityCell")
        rightTable.tableFooterView = UIView()
        rightTable.backgroundColor = .white
        rightTable.separatorColor = AppColor.separator
        if #available(iOS 15.0, *) { rightTable.sectionHeaderTopPadding = 0 }
    }

    // MARK: - Layout
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        leftTable.frame = CGRect(x: 0, y: 0, width: leftWidth, height: view.h)
        rightTable.frame = CGRect(x: leftWidth, y: 0,
                                  width: view.w - leftWidth, height: view.h)
    }

    // MARK: - 左侧省 TableView
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tableView == leftTable ? provinces.count : provinces[selectedProvinceIndex].cities.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == leftTable {
            let cell = tableView.dequeueReusableCell(withIdentifier: "provinceCell", for: indexPath)
            let p = provinces[indexPath.row]
            let isSelected = indexPath.row == selectedProvinceIndex
            cell.textLabel?.text = p.name
            cell.textLabel?.font = isSelected ? AppFont.bodyM : AppFont.body
            cell.textLabel?.textColor = isSelected ? AppColor.primary : AppColor.textMain
            cell.backgroundColor = isSelected ? .white : AppColor.bg
            cell.accessoryType = .none
            cell.selectionStyle = .none
            return cell
        }

        let cell = tableView.dequeueReusableCell(withIdentifier: "cityCell", for: indexPath)
        let city = provinces[selectedProvinceIndex].cities[indexPath.row]
        cell.textLabel?.text = city.name
        cell.textLabel?.font = AppFont.body
        cell.textLabel?.textColor = AppColor.textMain
        cell.backgroundColor = .white
        cell.accessoryType = .none
        cell.selectionStyle = .default
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == leftTable {
            // 选择省份 → 刷新右侧城市列表
            selectedProvinceIndex = indexPath.row
            leftTable.reloadData()
            rightTable.reloadData()
            // 默认选中右侧第一行
            rightTable.selectRow(at: IndexPath(row: 0, section: 0), animated: false, scrollPosition: .top)
        } else {
            // 选择城市 → 回调并返回
            tableView.deselectRow(at: indexPath, animated: true)
            let city = provinces[selectedProvinceIndex].cities[indexPath.row]
            Logger.shared.track("city_pick", params: ["city": city.name])
            onPick?(city)
            if let nav = navigationController, nav.viewControllers.count > 1 {
                nav.popViewController(animated: true)
            } else {
                dismiss(animated: true)
            }
        }
    }
}
