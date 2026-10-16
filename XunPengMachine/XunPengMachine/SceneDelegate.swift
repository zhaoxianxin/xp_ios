//
//  SceneDelegate.swift
//  XunPengMachine
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        let win = UIWindow(windowScene: windowScene)
        win.rootViewController = initialRootVC()
        win.makeKeyAndVisible()
        self.window = win

        if PrivacyConsentStore.hasAgreed {
            refreshCurrentUserIfNeeded()
        }

        // 监听 token 失效，强制退出登录
        NotificationCenter.default.addObserver(forName: .forceLogout, object: nil,
                                               queue: .main) { [weak self] _ in
            self?.switchToLogin()
        }
    }

    /// 首次启动先展示隐私服务协议，同意后再进入登录页或主页。
    private func initialRootVC() -> UIViewController {
        guard !PrivacyConsentStore.hasAgreed else { return rootVC() }

        let privacyVC = PrivacyAgreementViewController()
        privacyVC.onAgree = { [weak self] in
            (UIApplication.shared.delegate as? AppDelegate)?.setupServicesAfterPrivacyConsent()
            self?.transitionToAppRoot()
        }
        return privacyVC
    }

    private func transitionToAppRoot() {
        guard let window = window else { return }
        UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve) {
            window.rootViewController = self.rootVC()
        }
        refreshCurrentUserIfNeeded()
    }

    /// App 启动时若已有登录态，主动刷新一次全局用户资料。
    private func refreshCurrentUserIfNeeded() {
        guard TokenManager.shared.isLoggedIn else { return }
        UserManager.shared.fetchUser { result in
            if case .failure(let error) = result {
                Logger.shared.error("refresh user on launch failed: \(error.errorDescription ?? "")")
            }
        }
    }

    /// 根据登录状态返回根视图
    private func rootVC() -> UIViewController {
        if TokenManager.shared.isLoggedIn {
            return MainTabBarController()
        }
        return LoginViewController()
    }

    /// 切换到登录页
    func switchToLogin() {
        TokenManager.shared.clear()
        window?.rootViewController = LoginViewController()
    }

    /// 切换到主页
    func switchToMain() {
        window?.rootViewController = MainTabBarController()
    }
}
