//
//  JobViewModel.swift
//  XunPengMachine
//
//  找活模块 ViewModel：活源列表 + 详情
//

import Foundation

final class JobViewModel: BaseViewModel {

    /// 活源列表
    let list = Observable.create([Job]())
    /// 活源详情
    let detail = Observable.create(Job?.none)
    /// 当前筛选城市
    var city: String?
    /// 列表总数（用于判断是否还有更多）
    var hasMore: Bool = false
    var lastId: Int?

    /// 拉取活源列表
    /// - Parameters:
    ///   - page: 页码，从 1 开始
    ///   - refresh: 是否下拉刷新（刷新替换，加载更多追加）
    func loadList(page: Int, refresh: Bool) {
        NetworkManager.shared.requestPage(.jobList(page: page, city: city), type: Job.self) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                switch result {
                case .success(let pageData):
                    self.hasMore = pageData.hasMore
                    self.lastId = pageData.lastId
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

    /// 拉取活源详情
    func loadDetail(id: Int64) {
        loading.onNext(true)
        NetworkManager.shared.request(.jobDetail(id: id), type: Job.self) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.loading.onNext(false)
                switch result {
                case .success(let job):
                    self.detail.onNext(job)
                case .failure(let error):
                    Toast.shared.show(error.errorDescription ?? "加载失败")
                }
            }
        }
    }

    func deleteJob(id: Int64, completion: @escaping (Bool) -> Void) {
        loading.onNext(true)
        NetworkManager.shared.request(.deleteJob(id: id), type: EmptyBO.self) { [weak self] result in
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
