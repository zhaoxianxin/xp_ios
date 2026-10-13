//
//  PublishViewModel.swift
//  XunPengMachine
//
//  发布 ViewModel：活源 / 设备 / 司机 三类发布接口
//

import Foundation

/// 空响应体（接口返回 data = {} ）
struct EmptyBO: Codable {
    init() {}
    init(from decoder: Decoder) throws {
        // 新增、修改、删除接口可能返回 {}、true 或数字，业务成功只看外层 code。
    }
    func encode(to encoder: Encoder) throws {}
}

final class PublishViewModel: BaseViewModel {

    /// 发布成功事件
    let success = Observable.create(false)

    /// 发布活源
    func publishJob(params: [String: Any]) {
        submit(.publishJob(params: params))
    }

    /// 保存活源；有 editingID 时走修改接口。
    func saveJob(params: [String: Any], editingID: Int64?) {
        if let editingID {
            submit(.updateJob(id: editingID, params: params))
        } else {
            submit(.publishJob(params: params))
        }
    }

    /// 发布设备
    func publishCar(params: [String: Any]) {
        submit(.publishCar(params: params))
    }

    /// 发布招司机
    func publishDriver(params: [String: Any]) {
        submit(.publishDriver(params: params))
    }

    /// 保存招聘；有 editingID 时走修改接口。
    func saveDriver(params: [String: Any], editingID: Int64?) {
        if let editingID {
            submit(.updateDriver(id: editingID, params: params))
        } else {
            submit(.publishDriver(params: params))
        }
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
