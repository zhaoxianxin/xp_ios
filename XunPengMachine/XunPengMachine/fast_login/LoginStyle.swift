//
//  LoginStyle.swift
//  ATAuthSceneDemoSwift
//
//  Created by lyz on 2026/1/28.
//  Copyright © 2020-2026. All rights reserved.
//

import Foundation

/// 一键登录样式枚举
enum LoginStyle {
    case fullScreen             // 全屏
    case centerPopup            // 居中弹窗
    case bottomPopup            // 底部弹窗
    case landscape              // 横屏
    case landscapePopup         // 横屏弹窗
    case fadeAnimation          // 弹窗渐变效果
    case springAnimation        // 弹窗弹性伸缩效果
    case dropAnimation          // 弹窗下坠效果
    case privacyAlertPortrait   // 二次协议弹窗竖屏
    case privacyAlertLandscape  // 二次协议弹窗横屏
}
