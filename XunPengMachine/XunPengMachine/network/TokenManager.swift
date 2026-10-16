//
//  TokenManager.swift
//  XunPengMachine
//
//  Token 管理：存储 + 401 自动刷新（去重，避免并发多次刷新）
//

import Foundation

final class TokenManager {
    static let shared = TokenManager()
    private init() {}

    private let tokenKey = "com.xunpeng.token"
    private let refreshKey = "com.xunpeng.refreshToken"

    /// 当前访问 token
    var accessToken: String? {
        get { UserDefaults.standard.string(forKey: tokenKey) }
        set { UserDefaults.standard.set(newValue, forKey: tokenKey) }
    }
    /// 刷新 token
    var refreshToken: String? {
        get { UserDefaults.standard.string(forKey: refreshKey) }
        set { UserDefaults.standard.set(newValue, forKey: refreshKey) }
    }

    var isLoggedIn: Bool { accessToken != nil && !(accessToken?.isEmpty ?? true) }

    /// 清空（退出登录）
    func clear() {
        accessToken = nil
        refreshToken = nil
        UserManager.shared.clear()
    }

    // MARK: - 刷新去重
    /// 刷新中的回调队列，保证并发请求只触发一次刷新
    private var refreshCallbacks: [(Result<String, APIError>) -> Void] = []
    private var isRefreshing = false
    private let lock = NSLock()

    /// 刷新 token，并发只触发一次；完成后通知所有等待者
    func refresh(completion: @escaping (Result<String, APIError>) -> Void) {
        lock.lock()
        if isRefreshing {
            // 已有刷新在进行，排队等待结果
            refreshCallbacks.append(completion)
            lock.unlock()
            return
        }
        isRefreshing = true
        refreshCallbacks.append(completion)
        lock.unlock()

        guard let rt = refreshToken, !rt.isEmpty else {
            self.finishRefresh(.failure(.unauthorized))
            return
        }
        // 用 NetworkManager 发起刷新请求（requiresAuth=false，避免递归）
        NetworkManager.shared.requestRaw(router: .refreshToken(refreshToken: rt)) { [weak self] result in
            switch result {
            case .success(let data):
                if let resp = try? JSONDecoder().decode(APIResponse<TokenBO>.self, from: data),
                   let bo = resp.data {
                    self?.accessToken = bo.accessToken
                    self?.refreshToken = bo.refreshToken
                    self?.finishRefresh(.success(bo.accessToken))
                } else {
                    self?.finishRefresh(.failure(.unauthorized))
                }
            case .failure:
                self?.finishRefresh(.failure(.unauthorized))
            }
        }
    }

    private func finishRefresh(_ result: Result<String, APIError>) {
        lock.lock()
        let cbs = refreshCallbacks
        refreshCallbacks.removeAll()
        isRefreshing = false
        lock.unlock()
        cbs.forEach { $0(result) }
    }
}

/// token 刷新返回体
struct TokenBO: Codable {
    let accessToken: String
    let refreshToken: String
}
