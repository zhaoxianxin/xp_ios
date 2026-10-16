//
//  UserManager.swift
//  XunPengMachine
//
//  当前用户管理：接口请求 + 内存状态 + UserDefaults 持久化
//

import Foundation

final class UserManager {
    static let shared = UserManager()

    private static let userKey = "com.xunpeng.currentUser"

    /// 当前用户变化流，新订阅者会立即收到内存或本地缓存中的用户。
    let user: Subject<User?>

    var currentUser: User? { user.value }

    private init() {
        let cachedUser: User?
        if let data = UserDefaults.standard.data(forKey: Self.userKey) {
            cachedUser = try? JSONDecoder().decode(User.self, from: data)
        } else {
            cachedUser = nil
        }
        user = Observable.create(cachedUser)
    }

    /// 获取最新用户资料并更新全局缓存。
    func fetchUser(completion: ((Result<User, APIError>) -> Void)? = nil) {
        NetworkManager.shared.request(.mineProfile, type: User.self) { [weak self] result in
            DispatchQueue.main.async {
                if case .success(let user) = result {
                    self?.save(user)
                }
                completion?(result)
            }
        }
    }

    /// 切换身份；接口返回切换后的完整用户资料。
    func switchIdentity(
        to identityType: Int,
        completion: @escaping (Result<User, APIError>) -> Void
    ) {
        NetworkManager.shared.request(.switchIdentity(identityType: identityType),
                                      type: User.self) { [weak self] result in
            DispatchQueue.main.async {
                if case .success(let user) = result {
                    self?.save(user)
                }
                completion(result)
            }
        }
    }

    /// 清除内存和本地用户资料，退出登录或 token 失效时调用。
    func clear() {
        UserDefaults.standard.removeObject(forKey: Self.userKey)
        if Thread.isMainThread {
            user.onNext(nil)
        } else {
            DispatchQueue.main.async { [weak self] in self?.user.onNext(nil) }
        }
    }

    private func save(_ value: User) {
        if let data = try? JSONEncoder().encode(value) {
            UserDefaults.standard.set(data, forKey: Self.userKey)
        }
        user.onNext(value)
    }
}
