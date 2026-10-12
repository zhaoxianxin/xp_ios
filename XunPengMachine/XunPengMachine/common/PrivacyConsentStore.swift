//
//  PrivacyConsentStore.swift
//  XunPengMachine
//

import Foundation

enum PrivacyConsentStore {
    /// 协议内容发生实质变化时升级版本，即可重新征求用户同意。
    private static let agreementVersion = "v1"
    private static let consentKey = "privacy_agreement_accepted_\(agreementVersion)"

    static var hasAgreed: Bool {
        UserDefaults.standard.bool(forKey: consentKey)
    }

    static func accept() {
        UserDefaults.standard.set(true, forKey: consentKey)
    }
}
