//
//  AuthSDKManager.swift
//  ATAuthSceneDemoSwift
//
//  Created by lyz on 2026/1/28.
//  Copyright © 2020-2026. All rights reserved.
//

import UIKit
import ATAuthSDK

// MARK: - 返回码定义（收敛 PNSReturnCode.h，业务层禁止使用字符串魔法值）

enum AuthSDKCode: String {
    // MARK: 通用返回码
    
    /// 接口成功
    case success = "600000"
    /// 获取运营商配置信息失败
    case getOperatorInfoFailed = "600004"
    /// 未检测到 SIM 卡
    case noSIMCard = "600007"
    /// 蜂窝网络未开启或不稳定
    case noCellularNetwork = "600008"
    /// 无法判运营商
    case unknownOperator = "600009"
    /// 未知异常
    case unknownError = "600010"
    /// 获取 token 失败
    case getTokenFailed = "600011"
    /// 预取号失败
    case getMaskPhoneFailed = "600012"
    /// 运营商维护升级，该功能不可用
    case interfaceDemoted = "600013"
    /// 运营商维护升级，该功能已达最大调用次数
    case interfaceLimited = "600014"
    /// 接口超时
    case timeout = "600015"
    /// AppID、AppKey 解析失败
    case decodeAppInfoFailed = "600017"
    /// 该号码已被运营商管控
    case phoneBlack = "600018"
    /// 运营商已切换
    case carrierChanged = "600021"
    /// 终端环境检测失败
    case envCheckFailed = "600025"
    
    // MARK: 授权页返回码
    
    /// 唤起授权页成功
    case loginPagePresentSuccess = "600001"
    /// 唤起授权页失败
    case loginPagePresentFailed = "600002"
    /// 授权页已加载时不允许调用加速或预取号接口
    case preLoginInAuthPage = "600026"
    /// 点击返回，用户取消一键登录
    case clickCancel = "700000"
    /// 点击切换按钮，用户取消免密登录
    case clickSwitchButton = "700001"
    /// 点击登录按钮事件
    case clickLoginButton = "700002"
    /// 点击 CheckBox 事件
    case clickCheckBox = "700003"
    /// 点击协议富文本文字（主授权页）
    case clickPrivacy = "700004"
    /// suspendDisMissVC 模式下点击返回
    case suspendDismiss = "700010"
    /// 授权页已销毁
    case loginPageDealloc = "700020"
    
    // MARK: 二次协议弹窗返回码
    
    /// 拉起授权页二次弹窗
    case privacyAlertPresent = "700006"
    /// 二次协议弹窗关闭
    case privacyAlertClose = "700007"
    /// 二次协议弹窗点击确认并继续
    case privacyAlertContinue = "700008"
    /// 点击二次弹窗协议富文本
    case privacyAlertClickPrivacy = "700009"
}

extension AuthSDKCode {
    
    /// 用户主动操作或中间态（不应按错误处理）
    var isUserInteraction: Bool {
        switch self {
        case .loginPagePresentSuccess,
             .clickCancel, .clickSwitchButton, .clickLoginButton, .clickCheckBox,
             .clickPrivacy, .suspendDismiss, .loginPageDealloc,
             .privacyAlertPresent, .privacyAlertClose, .privacyAlertContinue,
             .privacyAlertClickPrivacy:
            return true
        default:
            return false
        }
    }
    
    /// 内置中文描述
    var errorMessage: String {
        switch self {
        case .success:                      return "成功"
        case .getOperatorInfoFailed:        return "获取运营商配置信息失败"
        case .noSIMCard:                    return "未检测到 SIM 卡"
        case .noCellularNetwork:            return "蜂窝网络未开启或不稳定"
        case .unknownOperator:              return "无法判运营商"
        case .unknownError:                 return "未知异常"
        case .getTokenFailed:               return "获取 token 失败"
        case .getMaskPhoneFailed:           return "预取号失败"
        case .interfaceDemoted:             return "运营商维护升级，该功能不可用"
        case .interfaceLimited:             return "运营商维护升级，该功能已达最大调用次数"
        case .timeout:                      return "接口超时"
        case .decodeAppInfoFailed:          return "AppID、AppKey 解析失败"
        case .phoneBlack:                   return "该号码已被运营商管控"
        case .carrierChanged:               return "运营商已切换"
        case .envCheckFailed:               return "终端环境检测失败"
        case .loginPagePresentSuccess:      return "授权页唤起成功"
        case .loginPagePresentFailed:       return "授权页唤起失败"
        case .preLoginInAuthPage:           return "授权页已加载时不允许调用预取号"
        case .clickCancel:                  return "用户取消一键登录"
        case .clickSwitchButton:            return "用户切换其他登录方式"
        case .clickLoginButton:             return "用户点击登录"
        case .clickCheckBox:                return "用户点击协议勾选框"
        case .clickPrivacy:                 return "用户点击协议富文本"
        case .suspendDismiss:               return "用户中断页面"
        case .loginPageDealloc:             return "授权页已销毁"
        case .privacyAlertPresent:          return "二次协议弹窗已展示"
        case .privacyAlertClose:            return "二次协议弹窗已关闭"
        case .privacyAlertContinue:         return "用户点击确认并继续"
        case .privacyAlertClickPrivacy:     return "用户点击二次弹窗协议"
        }
    }
}

// MARK: - 统一回调结果（业务层唯一出口，不再接触 SDK 原始字典）

struct AuthSDKResult {
    
    /// 原始返回码字符串（未收录进 AuthSDKCode 时仍可追溯）
    let rawCode: String
    /// SDK 原始回调字典
    let raw: [AnyHashable: Any]
    
    init(_ dict: [AnyHashable: Any]?) {
        self.rawCode = (dict?["resultCode"] as? String) ?? ""
        self.raw = dict ?? [:]
    }
    
    /// 已识别的返回码（无法识别时为 nil，可用 rawCode 追溯）
    var code: AuthSDKCode? { AuthSDKCode(rawValue: rawCode) }
    /// 是否成功（600000）
    var isSuccess: Bool { rawCode == AuthSDKCode.success.rawValue }
    /// 结果描述（优先 SDK 返回的 msg，其次错误码内置描述）
    var message: String {
        if let msg = raw["msg"] as? String, !msg.isEmpty { return msg }
        return code?.errorMessage ?? "未知错误(\(rawCode))"
    }
    /// 一键登录 / 本机号码认证 token（仅成功时有值）
    var token: String? { isSuccess ? raw["token"] as? String : nil }
    /// 协议点击回调中的协议名称
    var privacyName: String? { (raw["privacyName"] ?? raw["name"]) as? String }
    /// 协议点击回调中的协议链接
    var privacyURL: String? { (raw["privacyUrl"] ?? raw["privacyURL"] ?? raw["url"]) as? String }
}

/// ATAuthSDK 统一管理类
/// 封装所有 SDK 相关调用：返回码、结果解析、接口调用均收敛于此，
/// 业务层只使用 AuthSDKResult / AuthSDKCode，禁止直接触碰 SDK 原始字典与字符串码
class AuthSDKManager {
    
    // MARK: - Singleton
    
    static let shared = AuthSDKManager()
    
    private init() {}
    
    // MARK: - Public Properties
    
    /// 获取当前 SDK 版本号
    var sdkVersion: String {
        return TXCommonHandler.sharedInstance().getVersion()
    }
    
    // MARK: - SDK Initialization
    
    /// 设置 SDK 鉴权信息
    /// - Parameters:
    ///   - info: App 对应的秘钥
    ///   - completion: 结果回调（统一结构，见 AuthSDKResult）
    func setAuthSDKInfo(info: String, completion: @escaping (AuthSDKResult) -> Void) {
        TXCommonHandler.sharedInstance().setAuthSDKInfo(info) { resultDic in
            let result = AuthSDKResult(resultDic)
            Self.log("setAuthSDKInfo", result)
            completion(result)
        }
    }
    
    // MARK: - Environment Check
    
    /// 检查环境是否可用
    /// - Parameters:
    ///   - authType: 认证类型（.verifyToken 或 .loginToken）
    ///   - completion: 结果回调（isSuccess 为 true 才可继续后续流程）
    func checkEnvAvailable(authType: PNSAuthType, completion: @escaping (AuthSDKResult) -> Void) {
        TXCommonHandler.sharedInstance().checkEnvAvailable(with: authType) { resultDic in
            let result = AuthSDKResult(resultDic)
            Self.log("checkEnvAvailable", result)
            completion(result)
        }
    }
    
    // MARK: - Phone Verification (本机号码认证)
    
    /// 获取本机号码认证 Token
    /// - Parameters:
    ///   - timeout: 超时时间（秒）
    ///   - completion: 结果回调（token 仅成功时有值）
    func getVerifyToken(timeout: TimeInterval = 5.0, completion: @escaping (AuthSDKResult) -> Void) {
        TXCommonHandler.sharedInstance().getVerifyToken(withTimeout: timeout) { resultDic in
            let result = AuthSDKResult(resultDic)
            Self.log("getVerifyToken", result)
            completion(result)
        }
    }
    
    // MARK: - One-Click Login (一键登录)
    
    /// 加速一键登录（预取号）
    /// - Parameters:
    ///   - timeout: 超时时间（秒）
    ///   - completion: 结果回调
    func accelerateLoginPage(timeout: TimeInterval = 5.0, completion: @escaping (AuthSDKResult) -> Void) {
        TXCommonHandler.sharedInstance().accelerateLoginPage(withTimeout: timeout) { resultDic in
            let result = AuthSDKResult(resultDic)
            Self.log("accelerateLoginPage", result)
            completion(result)
        }
    }
    
    /// 获取一键登录 Token（会弹出授权页）
    /// - Parameters:
    ///   - timeout: 超时时间（秒）
    ///   - controller: 弹出授权页的容器控制器
    ///   - customModel: 自定义授权页样式配置（可为 nil）
    ///   - completion: 结果回调（成功时 token 有值；点击协议时 privacyName / privacyURL 有值）
    func getLoginToken(timeout: TimeInterval = 5.0,
                       controller: UIViewController,
                       model: TXCustomModel?,
                       completion: @escaping (AuthSDKResult) -> Void) {
        TXCommonHandler.sharedInstance().getLoginToken(withTimeout: timeout,
                                                       controller: controller,
                                                       model: model) { resultDic in
            let result = AuthSDKResult(resultDic)
            Self.log("getLoginToken", result)
            completion(result)
        }
    }
    
    /// 取消/关闭授权页
    /// - Parameters:
    ///   - animated: 是否带动画
    ///   - completion: 完成回调
    func cancelLoginVC(animated: Bool = true, completion: (() -> Void)? = nil) {
        TXCommonHandler.sharedInstance().cancelLoginVC(animated: animated, complete: completion)
    }
    
    /// 隐藏登录加载动画
    func hideLoginLoading() {
        TXCommonHandler.sharedInstance().hideLoginLoading()
    }
    
    // MARK: - Privacy Agreement (二次协议)
    
    /// 关闭二次授权弹窗
    func closePrivacyAlertView() {
        TXCommonHandler.sharedInstance().closePrivactAlertView()
    }
    
    // MARK: - Utility Methods
    
    /// 获取日志埋点控制对象
    func getReporter() -> PNSReporter {
        return TXCommonHandler.sharedInstance().getReporter()
    }
    
    /// 启动 checkbox 动画
    func startCheckboxAnimation() {
        TXCommonHandler.sharedInstance().checkboxAnimationStart()
    }
    
    // MARK: - Logging
    
    /// 统一输出 SDK 调用日志（收敛所有 print，仅 Debug 生效）
    private static func log(_ api: String, _ result: AuthSDKResult) {
        #if DEBUG
        print("[AuthSDK] \(api) -> code=\(result.rawCode), success=\(result.isSuccess), msg=\(result.message)")
        if !result.raw.isEmpty {
            print("[AuthSDK] \(api) raw: \(result.raw)")
        }
        #endif
    }
}

// MARK: - 便捷扩展：运营商信息查询

extension AuthSDKManager {
    
    /// 判断当前设备蜂窝数据网络是否开启
    var isCellularDataEnabled: Bool {
        return TXCommonUtils.checkDeviceCellularDataEnable()
    }
    
    /// 判断当前上网卡运营商是否是中国联通
    var isChinaUnicom: Bool {
        return TXCommonUtils.isChinaUnicom()
    }
    
    /// 判断当前上网卡运营商是否是中国移动
    var isChinaMobile: Bool {
        return TXCommonUtils.isChinaMobile()
    }
    
    /// 判断当前上网卡运营商是否是中国电信
    var isChinaTelecom: Bool {
        return TXCommonUtils.isChinaTelecom()
    }
    
    /// 获取当前上网卡运营商名称
    var currentCarrierName: String {
        return TXCommonUtils.getCurrentCarrierName()
    }
    
    /// 获取当前上网卡网络类型
    var networkType: String {
        return TXCommonUtils.getNetworktype()
    }
    
    /// 判断当前设备是否有 SIM 卡
    var hasSIMCard: Bool {
        return TXCommonUtils.simSupportedIsOK()
    }
}
