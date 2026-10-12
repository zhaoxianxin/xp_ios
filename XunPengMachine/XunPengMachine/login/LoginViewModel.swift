//
//  LoginViewModel.swift
//  XunPengMachine
//
//  登录 ViewModel：手机号 + 验证码登录，60s 倒计时
//

import Foundation

final class LoginViewModel: BaseViewModel {

    /// 手机号主题
    let phone = Observable.create("")
    /// 验证码主题
    let code = Observable.create("")
    /// 倒计时主题（0 表示可发码）
    let countdown = Observable.create(0)
    /// 登录成功事件
    let loginSuccess = Observable.create(false)

    private var countdownTimer: Timer?

    deinit { countdownTimer?.invalidate() }

    /// 发送验证码
    func sendCode() {
        let p = phone.value
        guard p.isValidPhone else {
            Toast.shared.show("请输入正确的手机号")
            return
        }
        guard countdown.value == 0 else { return }

        loading.onNext(true)
        NetworkManager.shared.request(.sendCode(phone: p), type: EmptyBO.self) { [weak self] result in
            DispatchQueue.main.async {
                self?.loading.onNext(false)
                switch result {
                case .success:
                    Toast.shared.show("验证码已发送")
                    self?.startCountdown()
                case .failure(let e):
                    Toast.shared.show(e.errorDescription ?? "发送失败")
                }
            }
        }
    }

    /// 登录
    func login(identityType: Int) {
        let p = phone.value
        let c = code.value
        guard p.isValidPhone else {
            Toast.shared.show("请输入正确的手机号")
            return
        }
        guard c.isValidCode else {
            Toast.shared.show("请输入6位验证码")
            return
        }

        loading.onNext(true)
        NetworkManager.shared.request(.login(phone: p, code: c, identityType: identityType),
                                      type: TokenBO.self) { [weak self] result in
            DispatchQueue.main.async {
                self?.loading.onNext(false)
                switch result {
                case .success(let bo):
                    TokenManager.shared.accessToken = bo.accessToken
                    TokenManager.shared.refreshToken = bo.refreshToken
                    Logger.shared.track("login_success")
                    self?.loginSuccess.onNext(true)
                case .failure(let e):
                    Toast.shared.show(e.errorDescription ?? "登录失败")
                }
            }
        }
    }
    
    // 一键登录
    func onekeyLogin(_ token: String, identityType: Int) {
        loading.onNext(true)
        NetworkManager.shared.request(.fastLogin(token: token, identityType: identityType),
                                      type: TokenBO.self) { [weak self] result in
            DispatchQueue.main.async {
                self?.loading.onNext(false)
                switch result {
                case .success(let bo):
                    TokenManager.shared.accessToken = bo.accessToken
                    TokenManager.shared.refreshToken = bo.refreshToken
                    Logger.shared.track("login_success")
                    self?.loginSuccess.onNext(true)
                case .failure(let e):
                    Toast.shared.show(e.errorDescription ?? "登录失败")
                }
            }
        }
    }

    /// 启动 60s 倒计时
    private func startCountdown() {
        countdown.onNext(60)
        countdownTimer?.invalidate()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] t in
            guard let self = self else { t.invalidate(); return }
            let cur = self.countdown.value - 1
            if cur <= 0 {
                t.invalidate()
                self.countdown.onNext(0)
            } else {
                self.countdown.onNext(cur)
            }
        }
    }
}
