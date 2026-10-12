//
//  NetworkManager.swift
//  XunPengMachine
//
//  泛型网络请求封装：Codable 解析 + 401 自动刷新去重 + 重试 + Mock
//

import Foundation

final class NetworkManager {
    static let shared = NetworkManager()
    private init() {}

    /// 基础地址
    let baseURL = "http://47.110.239.69:8080/app-api"
    /// 是否启用 Mock（接口先返回 mock 测试数据）
    var useMock = false

    private let session: URLSession = {
        let cfg = URLSessionConfiguration.default
        cfg.timeoutIntervalForRequest = 15
        return URLSession(configuration: cfg)
    }()

    // MARK: - 泛型请求（解析为指定模型）
    /// 通用请求，T 为 data 字段类型
    func request<T: Codable>(_ router: APIRouter, type: T.Type,
                             completion: @escaping (Result<T, APIError>) -> Void) {
        send(router, retrying: false) { result in
            switch result {
            case .success(let data):
                do {
                    let resp = try JSONDecoder().decode(APIResponse<T>.self, from: data)
                    if resp.isSuccess, let model = resp.data {
                        Logger.shared.log("decode success: \(router.path), res: \(resp)")
                        completion(.success(model))
                    } else if resp.isUnauthorized {
                        Logger.shared.log("decode 401: \(router.path), res: \(resp)")
                        completion(.failure(.unauthorized))
                    } else {
                        Logger.shared.log("decode failed: \(router.path), res: \(resp)")
                        completion(.failure(.business(code: resp.code, msg: resp.msg)))
                    }
                } catch {
                    let str = NSString(data: data, encoding: NSUTF8StringEncoding) ?? ""
                    Logger.shared.error("request decode failed: \(error), res data:\(str)")
                    completion(.failure(.decodeFailed))
                }
            case .failure(let err):
                Logger.shared.error("request failed:\(router.path), err: \(err)")
                completion(.failure(err))
            }
        }
    }

    /// 列表分页请求
    func requestPage<T: Codable>(_ router: APIRouter, type: T.Type,
                                 completion: @escaping (Result<Page<T>, APIError>) -> Void) {
        send(router, retrying: false) { result in
            switch result {
            case .success(let data):
                do {
                    let resp = try JSONDecoder().decode(APIResponse<Page<T>>.self, from: data)
                    if resp.isSuccess, let page = resp.data {
                        completion(.success(page))
                    } else if resp.isUnauthorized {
                        completion(.failure(.unauthorized))
                    } else {
                        completion(.failure(.business(code: resp.code, msg: resp.msg)))
                    }
                } catch {
                    let str = NSString(data: data, encoding: NSUTF8StringEncoding) ?? ""
                    Logger.shared.error("page decode failed: \(error), res data:\(str)")
                    completion(.failure(.decodeFailed))
                }
            case .failure(let err):
                completion(.failure(err))
            }
        }
    }

    // MARK: - 原始数据请求（TokenManager 刷新专用，不再触发刷新）
    func requestRaw(router: APIRouter, completion: @escaping (Result<Data, APIError>) -> Void) {
        send(router, retrying: true, completion: completion)
    }

    // MARK: - 核心发送
    private func send(_ router: APIRouter, retrying: Bool,
                      completion: @escaping (Result<Data, APIError>) -> Void) {
        // Mock 模式
        if useMock, let mockData = MockProvider.shared.mockData(for: router) {
            // 模拟网络延迟
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.4) {
                completion(.success(mockData))
            }
            return
        }

        guard let url = URL(string: baseURL + router.path) else {
            completion(.failure(.invalidURL)); return
        }
        var req = URLRequest(url: url)
        req.httpMethod = router.method.rawValue
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if router.requiresAuth, let token = TokenManager.shared.accessToken {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if !router.parameters.isEmpty {
            if router.method == .get {
                var comps = URLComponents(url: url, resolvingAgainstBaseURL: false)!
                comps.queryItems = router.parameters.map { URLQueryItem(name: $0.key, value: "\($0.value)") }
                req.url = comps.url
            } else {
                req.httpBody = try? JSONSerialization.data(withJSONObject: router.parameters)
            }
        }
        /// 打印输入url，method，head参数，body参数
        Logger.shared.log("request url:\(url), method:\(req.httpMethod ?? ""), head:\(req.allHTTPHeaderFields ?? [:]), body:\(router.parameters)")
        
        session.dataTask(with: req) { [weak self] data, _, error in
            guard let self = self else { return }
            if let error = error {
                completion(.failure(.network(error))); return
            }
            let respData = data ?? Data()
            // 401 处理：仅业务接口（requiresAuth 且非重试中）才刷新
            if self.isUnauthorized(respData), router.requiresAuth, !retrying {
                self.handle401(router: router, completion: completion)
            } else {
                completion(.success(respData))
            }
        }.resume()
    }

    /// 判断响应是否 401
    private func isUnauthorized(_ data: Data) -> Bool {
        guard let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return false
        }
        return (dict["code"] as? Int) == 401
    }

    /// 401 自动刷新 token 后重试原请求（仅重试一次）
    private func handle401(router: APIRouter, completion: @escaping (Result<Data, APIError>) -> Void) {
        TokenManager.shared.refresh { [weak self] result in
            switch result {
            case .success:
                // 刷新成功，重试原请求（retrying=true 避免再次触发刷新）
                self?.send(router, retrying: true, completion: completion)
            case .failure:
                // 刷新失败，清 token 并通知上层跳登录
                TokenManager.shared.clear()
                NotificationCenter.default.post(name: .forceLogout, object: nil)
                completion(.failure(.unauthorized))
            }
        }
    }
}

extension Notification.Name {
    /// token 失效，强制退出登录
    static let forceLogout = Notification.Name("com.xunpeng.forceLogout")
}
