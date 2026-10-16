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
    let profile = UserManager.shared.user

    /// 拉取用户资料
    func loadProfile() {
        loading.onNext(true)
        UserManager.shared.fetchUser { [weak self] result in
            guard let self = self else { return }
            self.loading.onNext(false)
            if case .failure(let error) = result {
                Logger.shared.error("load profile failed: \(error.errorDescription ?? "")")
            }
        }
    }

    /// 切换当前身份，接口直接返回切换后的完整个人资料。
    func switchIdentity(to identityType: Int, completion: @escaping (Result<Void, APIError>) -> Void) {
        loading.onNext(true)
        UserManager.shared.switchIdentity(to: identityType) { [weak self] result in
            guard let self = self else { return }
            self.loading.onNext(false)
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
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
