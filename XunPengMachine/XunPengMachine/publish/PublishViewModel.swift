//
//  PublishViewModel.swift
//  XunPengMachine
//
//  发布 ViewModel：活源 / 设备 / 司机 三类发布接口
//

import Foundation

/// 空响应体（接口返回 data = {} ）
struct EmptyBO: Codable {}

final class PublishViewModel: BaseViewModel {

    /// 发布成功事件
    let success = Observable.create(false)

    /// 发布活源
    func publishJob(params: [String: Any]) {
        submit(.publishJob(params: params))
    }

    /// 发布设备
    func publishCar(params: [String: Any]) {
        submit(.publishCar(params: params))
    }

    /// 发布招司机
    func publishDriver(params: [String: Any]) {
        submit(.publishDriver(params: params))
    }

    private func submit(_ router: APIRouter) {
        loading.onNext(true)
        NetworkManager.shared.request(router, type: EmptyBO.self) { [weak self] result in
            DispatchQueue.main.async {
                self?.loading.onNext(false)
                switch result {
                case .success:
                    self?.success.onNext(true)
                case .failure(let e):
                    self?.success.onNext(false)
                    Toast.shared.show(e.errorDescription ?? "提交失败")
                }
            }
        }
    }
}
