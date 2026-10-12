//
//  Response.swift
//  XunPengMachine
//
//  统一响应模型 + 错误定义
//

import Foundation

/// 后端统一响应结构
struct APIResponse<T: Codable>: Codable {
    let code: Int
    let msg: String
    let data: T?

    /// code == 0 视为成功
    var isSuccess: Bool { code == 0 }
    /// token 过期
    var isUnauthorized: Bool { code == 401 }
}

/// 分页数据
struct Page<T: Codable>: Codable {
//    let page: Int
//    let size: Int
//    let total: Int
    let list: [T]
    let hasMore: Bool
    let lastId: Int?
}

/// 网络错误
enum APIError: Error, LocalizedError {
    case invalidURL
    case decodeFailed
    case network(Error)
    case business(code: Int, msg: String)
    case unauthorized
    case unknown

    var errorDescription: String? {
        switch self {
        case .invalidURL:           return "请求地址错误"
        case .decodeFailed:         return "数据解析失败"
        case .network(let e):       return "网络错误：\(e.localizedDescription)"
        case .business(_, let m):   return m
        case .unauthorized:         return "登录已过期，请重新登录"
        case .unknown:              return "未知错误"
        }
    }
}
