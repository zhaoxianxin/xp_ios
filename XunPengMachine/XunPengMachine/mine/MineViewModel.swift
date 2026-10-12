//
//  MineViewModel.swift
//  XunPengMachine
//
//  我的模块 ViewModel：用户资料 / 意见反馈
//

import Foundation

/// 空响应占位模型（接口 data 为 {}）
struct NoData: Codable {}

final class MineViewModel: BaseViewModel {

    /// 当前登录用户资料
    let profile = Observable.create(User?.none)

    /// 拉取用户资料
    func loadProfile() {
        loading.onNext(true)
        NetworkManager.shared.request(.mineProfile, type: User.self) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.loading.onNext(false)
                switch result {
                case .success(let user):
                    self.profile.onNext(user)
                case .failure(let error):
                    Logger.shared.error("load profile failed: \(error.errorDescription ?? "")")
                }
            }
        }
    }

    /// 提交意见反馈
    func feedback(content: String, completion: @escaping (Bool) -> Void) {
        loading.onNext(true)
        NetworkManager.shared.request(.feedback(content: content), type: NoData.self) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.loading.onNext(false)
                switch result {
                case .success:
                    completion(true)
                case .failure(let error):
                    Logger.shared.error("feedback failed: \(error.errorDescription ?? "")")
                    completion(false)
                }
            }
        }
    }
    
    /// 4个步骤的认证
    
}
