//
//  Constants.swift
//  ATAuthSceneDemoSwift
//
//  Created by lyz on 2026/1/28.
//  Copyright © 2020-2026. All rights reserved.
//

import Foundation
import UIKit

struct Constants {
    static let authSDKInfo = "wDYluKUAQoqszN3CNIhR3Nk2xAn/nfyzMndan9C/7/9P6HIwhKgRVtkJBRUl35PGEgDZy/JAaXpD+Er9AzlG6imlAi2gQ7PZg99tf+gqmEVX6jGLYcl6kHDvMZSHGDVYHXcpH3llxP4rVnOw6XbjItKhiRAwfxuc6L+nd9U1wzDQPBz9OHn33UuyODhjuDNEbzo5iazEqgMxc+oRKma8+EdoH5KrgSQkGTp/0AV4obJ5RxVhjmp6cQuv37ai7Mit7m8xhiXaGzc="

    /// 正式协议页面地址，由服务端/运营提供后在此配置。
    static let privacyPolicyURL = ""
    static let serviceAgreementURL = ""
}

// MARK: - Toast Helper
func showToast(on view: UIView, message: String, duration: TimeInterval = 2.0) {
    // Using MBProgressHUD equivalent
    // TODO: Implement toast functionality
    print("Toast: \(message)")
}
