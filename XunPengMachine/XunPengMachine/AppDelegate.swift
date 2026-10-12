//
//  AppDelegate.swift
//  XunPengMachine
//

import UIKit
import AMapFoundationKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    private var didSetupServices = false

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        setupAppearance()
        if PrivacyConsentStore.hasAgreed {
            setupServicesAfterPrivacyConsent()
        }
        Logger.shared.log("App 启动")
        return true
    }

    /// 涉及设备信息或第三方 SDK 的服务仅在用户同意隐私协议后初始化。
    func setupServicesAfterPrivacyConsent() {
        guard !didSetupServices else { return }
        didSetupServices = true
        setupAMap()
        setupBugly()
        setupFastLogin()
    }

    /// 全局外观设置
    private func setupAppearance() {
        // 导航栏
        UINavigationBar.appearance().barTintColor = AppColor.navBar
        UINavigationBar.appearance().tintColor = .white
        UINavigationBar.appearance().titleTextAttributes = [
            .foregroundColor: UIColor.white, .font: AppFont.navTitle
        ]
        if #available(iOS 13.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = AppColor.navBar
            appearance.titleTextAttributes = [.foregroundColor: UIColor.white, .font: AppFont.navTitle]
            UINavigationBar.appearance().standardAppearance = appearance
            UINavigationBar.appearance().scrollEdgeAppearance = appearance
        }
        // TabBar
        UITabBar.appearance().barTintColor = .white
        UITabBar.appearance().tintColor = AppColor.primary
    }

    /// 高德地图 SDK 初始化（API Key）
    private func setupAMap() {
        AMapServices.shared().apiKey = "你的高德Key"
        AMapServices.shared().enableHTTPS = true
        Logger.shared.log("高德地图 SDK 初始化")
    }

    /// Bugly 初始化（接入 SDK 后替换为真实初始化）
    private func setupBugly() {
        // Bugly.start(withAppId: "你的BuglyAppId")
        Logger.shared.log("Bugly 初始化（占位）")
    }

    // MARK: UISceneSession Lifecycle
    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    /// 阿里一键登录
    private func setupFastLogin() {
        
        /* Demo展示直接使用常量进行赋值 */
        AuthSDKManager.shared.setAuthSDKInfo(info: Constants.authSDKInfo) { result in
            print("AuthSDK设置秘钥结果：\(result.rawCode) - \(result.message)")
        }
        
    }
}
