//
//  DriverViewModel.swift
//  XunPengMachine
//
//  招司机模块 ViewModel：司机列表 + 详情
//

import Foundation

final class DriverViewModel: BaseViewModel {

    /// 司机列表
    let list = Observable.create([Driver]())
    /// 司机详情
    let detail = Observable.create(Driver?.none)
    /// 当前筛选城市
    var city: String?
    /// 列表总数（用于判断是否还有更多）
    var hasMore: Bool = false

    /// 拉取司机列表
    /// - Parameters:
    ///   - page: 页码，从 1 开始
    ///   - refresh: 是否下拉刷新（刷新替换，加载更多追加）
    func loadList(page: Int, refresh: Bool) {
        NetworkManager.shared.requestPage(.driverList(page: page, city: city), type: Driver.self) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                switch result {
                case .success(let pageData):
                    self.hasMore = pageData.hasMore
                    if refresh {
                        self.list.onNext(pageData.list)
                    } else {
                        var arr = self.list.value
                        arr.append(contentsOf: pageData.list)
                        self.list.onNext(arr)
                    }
                case .failure(let error):
                    Toast.shared.show(error.errorDescription ?? "加载失败")
                }
            }
        }
    }

    /// 拉取司机详情
    func loadDetail(id: String) {
        loading.onNext(true)
        NetworkManager.shared.request(.driverDetail(id: id), type: Driver.self) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.loading.onNext(false)
                switch result {
                case .success(let driver):
                    self.detail.onNext(driver)
                case .failure(let error):
                    Toast.shared.show(error.errorDescription ?? "加载失败")
                }
            }
        }
    }

    func deleteDriver(id: Int64, completion: @escaping (Bool) -> Void) {
        loading.onNext(true)
        NetworkManager.shared.request(.deleteDriver(id: id), type: EmptyBO.self) { [weak self] result in
            DispatchQueue.main.async {
                self?.loading.onNext(false)
                switch result {
                case .success:
                    completion(true)
                case .failure(let error):
                    Toast.shared.show(error.errorDescription ?? "删除失败")
                    completion(false)
                }
            }
        }
    }
}
