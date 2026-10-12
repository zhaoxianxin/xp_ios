//
//  CarViewModel.swift
//  XunPengMachine
//
//  找设备模块 ViewModel：设备列表 + 详情
//

import Foundation

final class CarViewModel: BaseViewModel {

    /// 设备列表
    let list = Observable.create([Car]())
    /// 设备详情
    let detail = Observable.create(Car?.none)
    /// 当前筛选城市
    var city: String?
    /// 列表总数（用于判断是否还有更多）
    var hasMore: Bool = false

    /// 拉取设备列表
    /// - Parameters:
    ///   - page: 页码，从 1 开始
    ///   - refresh: 是否下拉刷新（刷新替换，加载更多追加）
    func loadList(page: Int, refresh: Bool) {
        NetworkManager.shared.requestPage(.carList(page: page, city: city), type: Car.self) { [weak self] result in
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

    /// 拉取设备详情
    func loadDetail(id: String) {
        loading.onNext(true)
        NetworkManager.shared.request(.carDetail(id: id), type: Car.self) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.loading.onNext(false)
                switch result {
                case .success(let car):
                    self.detail.onNext(car)
                case .failure(let error):
                    Toast.shared.show(error.errorDescription ?? "加载失败")
                }
            }
        }
    }
}
