//
//  Logger.swift
//  XunPengMachine
//
//  日志与埋点统一入口（Bugly 风格 API：reportException/trackEvent）
//  接入 Bugly 后将内部实现替换为 Bugly SDK 调用即可
//

import Foundation

final class Logger {
    static let shared = Logger()
    private init() {}

    #if DEBUG
    var enabled = true
    #else
    var enabled = false
    #endif

    /// 普通日志
    func log(_ message: @autoclosure () -> String, file: String = #file, line: Int = #line) {
        guard enabled else { return }
        let fileName = (file as NSString).lastPathComponent
        print("👾 [\(fileName):\(line)] \(message())")
    }

    /// 错误日志（上报 Bugly）
    func error(_ message: @autoclosure () -> String, file: String = #file, line: Int = #line) {
        let msg = message()
        print("❌ [ERROR] \(msg)")
        // TODO: Bugly 异常上报
        // Bugly.reportException(...)
    }

    /// 埋点事件
    func track(_ event: String, params: [String: Any] = [:]) {
        Logger.shared.log("📊 track: \(event) \(params)")
        // TODO: 埋点 SDK 上报
    }

    /// 页面埋点
    func pageStart(_ page: String) { track("page_view", params: ["page": page]) }
    func pageEnd(_ page: String)   { track("page_leave", params: ["page": page]) }
}
