//
//  PNSAuthPageStyleBuilder.swift
//  ATAuthSceneDemoSwift
//
//  Created by lyz on 2026/1/28.
//  Copyright © 2020-2026. All rights reserved.
//

import UIKit
import ATAuthSDK

/// 授权页样式配置器
/// 负责根据不同的 LoginStyle 创建对应的 TXCustomModel 配置
class PNSAuthPageStyleBuilder {
    
    // MARK: - Public Methods
    
    /// 创建授权页样式配置
    /// - Parameter style: 登录样式
    /// - Returns: 配置好的 TXCustomModel
    static func buildCustomModel(for style: LoginStyle) -> TXCustomModel {
        let model = TXCustomModel()
        
        // 配置统一的导航栏返回按钮
        configureNavigationBar(model)
        
        // 根据样式配置不同的 UI
        configureStyle(model, for: style)
        
        // 统一启用自定义隐私协议页
        model.privacyVCIsCustomized = true
        
        return model
    }
    
    // MARK: - Private Methods
    
    /// 配置导航栏
    private static func configureNavigationBar(_ model: TXCustomModel) {
        // 设置自定义返回按钮图片
        if let backImage = UIImage(systemName: "chevron.left")?.withTintColor(.black, renderingMode: .alwaysOriginal) {
            model.navBackImage = backImage
        }
        
        // 设置返回按钮的 frame
        model.navBackButtonFrameBlock = { screenSize, superViewSize, frame in
            let statusBarHeight: CGFloat = 44
            return CGRect(x: 16, y: (statusBarHeight - 30) / 2, width: 30, height: 30)
        }
    }
    
    /// 根据不同样式配置 UI
    private static func configureStyle(_ model: TXCustomModel, for style: LoginStyle) {
        switch style {
        case .fullScreen:
            configureFullScreen(model)
        case .centerPopup:
            configureCenterPopup(model)
        case .bottomPopup:
            configureBottomPopup(model)
        case .landscape:
            configureLandscape(model)
        case .landscapePopup:
            configureLandscapePopup(model)
        case .fadeAnimation:
            configureFadeAnimation(model)
        case .springAnimation:
            configureSpringAnimation(model)
        case .dropAnimation:
            configureDropAnimation(model)
        case .privacyAlertPortrait:
            configurePrivacyAlertPortrait(model)
        case .privacyAlertLandscape:
            configurePrivacyAlertLandscape(model)
        }
    }
    
    // MARK: - Style Configurations
    
    /// 全屏样式
    private static func configureFullScreen(_ model: TXCustomModel) {
        // 使用默认配置
    }
    
    /// 居中弹窗样式
    private static func configureCenterPopup(_ model: TXCustomModel) {
        model.contentViewFrameBlock = { screenSize, superViewSize, frame in
            let width = screenSize.width * 0.85
            let height = screenSize.height * 0.7
            let x = (screenSize.width - width) / 2
            let y = (screenSize.height - height) / 2
            return CGRect(x: x, y: y, width: width, height: height)
        }
    }
    
    /// 底部弹窗样式
    private static func configureBottomPopup(_ model: TXCustomModel) {
        model.contentViewFrameBlock = { screenSize, superViewSize, frame in
            let width = screenSize.width
            let height = screenSize.height * 0.65
            return CGRect(x: 0, y: screenSize.height - height, width: width, height: height)
        }
    }
    
    /// 横屏样式
    private static func configureLandscape(_ model: TXCustomModel) {
        model.contentViewFrameBlock = { screenSize, superViewSize, frame in
            let width = max(screenSize.width, screenSize.height)
            let height = min(screenSize.width, screenSize.height)
            return CGRect(x: 0, y: 0, width: width, height: height)
        }
        model.supportedInterfaceOrientations = .landscape
        
        // 横屏模式下返回按钮位置调整
        model.navBackButtonFrameBlock = { screenSize, superViewSize, frame in
            let statusBarHeight: CGFloat = 32
            return CGRect(x: 16, y: (statusBarHeight - 30) / 2, width: 30, height: 30)
        }
    }
    
    /// 横屏弹窗样式
    private static func configureLandscapePopup(_ model: TXCustomModel) {
        model.contentViewFrameBlock = { screenSize, superViewSize, frame in
            let screenWidth = max(screenSize.width, screenSize.height)
            let screenHeight = min(screenSize.width, screenSize.height)
            let width = screenWidth * 0.75
            let height = screenHeight * 0.8
            let x = (screenWidth - width) / 2
            let y = (screenHeight - height) / 2
            return CGRect(x: x, y: y, width: width, height: height)
        }
        model.supportedInterfaceOrientations = .landscape
        
        // 横屏模式下返回按钮位置调整
        model.navBackButtonFrameBlock = { screenSize, superViewSize, frame in
            let statusBarHeight: CGFloat = 32
            return CGRect(x: 16, y: (statusBarHeight - 30) / 2, width: 30, height: 30)
        }
        
        // 设置手机号码位置
        model.numberFrameBlock = { screenSize, superViewSize, frame in
            let screenWidth = max(screenSize.width, screenSize.height)
            let contentWidth = screenWidth * 0.75
            let x = (contentWidth - frame.size.width) / 2
            let y = min(screenSize.width, screenSize.height) * 0.15
            return CGRect(x: x, y: y, width: frame.size.width, height: frame.size.height)
        }
    }
    
    /// 渐变动画效果
    private static func configureFadeAnimation(_ model: TXCustomModel) {
        model.contentViewFrameBlock = { screenSize, superViewSize, frame in
            let width = screenSize.width * 0.85
            let height = screenSize.height * 0.7
            let x = (screenSize.width - width) / 2
            let y = (screenSize.height - height) / 2
            return CGRect(x: x, y: y, width: width, height: height)
        }
        
        // 渐显动画
        let fadeIn = CABasicAnimation(keyPath: "opacity")
        fadeIn.fromValue = 0.0
        fadeIn.toValue = 1.0
        fadeIn.duration = 0.6
        model.entryAnimation = fadeIn
        
        // 渐隐动画
        let fadeOut = CABasicAnimation(keyPath: "opacity")
        fadeOut.fromValue = 1.0
        fadeOut.toValue = 0.0
        fadeOut.duration = 0.4
        model.exitAnimation = fadeOut
    }
    
    /// 弹性动画效果
    private static func configureSpringAnimation(_ model: TXCustomModel) {
        model.contentViewFrameBlock = { screenSize, superViewSize, frame in
            let width = screenSize.width * 0.85
            let height = screenSize.height * 0.7
            let x = (screenSize.width - width) / 2
            let y = (screenSize.height - height) / 2
            return CGRect(x: x, y: y, width: width, height: height)
        }
        
        // 弹性伸缩动画
        let spring = CAKeyframeAnimation(keyPath: "transform.scale")
        spring.values = [0.3, 1.1, 0.9, 1.0]
        spring.keyTimes = [0.0, 0.5, 0.75, 1.0]
        spring.duration = 0.6
        model.entryAnimation = spring
        
        // 缩小消失
        let shrink = CABasicAnimation(keyPath: "transform.scale")
        shrink.fromValue = 1.0
        shrink.toValue = 0.3
        shrink.duration = 0.3
        model.exitAnimation = shrink
    }
    
    /// 下坠动画效果
    private static func configureDropAnimation(_ model: TXCustomModel) {
        model.contentViewFrameBlock = { screenSize, superViewSize, frame in
            let width = screenSize.width * 0.85
            let height = screenSize.height * 0.7
            let x = (screenSize.width - width) / 2
            let y = (screenSize.height - height) / 2
            return CGRect(x: x, y: y, width: width, height: height)
        }
        
        let centerY = UIScreen.main.bounds.height / 2
        
        // 下坠动画
        let drop = CAKeyframeAnimation(keyPath: "position.y")
        drop.values = [-100, centerY + 30, centerY - 10, centerY]
        drop.keyTimes = [0.0, 0.6, 0.8, 1.0]
        drop.duration = 0.8
        drop.timingFunction = CAMediaTimingFunction(name: .easeIn)
        model.entryAnimation = drop
        
        // 上升消失
        let rise = CABasicAnimation(keyPath: "position.y")
        rise.fromValue = centerY
        rise.toValue = -100
        rise.duration = 0.4
        model.exitAnimation = rise
    }
    
    /// 二次协议弹窗（竖屏）
    private static func configurePrivacyAlertPortrait(_ model: TXCustomModel) {
        // 显示二次协议弹窗
        model.privacyAlertIsNeedShow = true
        model.privacyAlertIsNeedAutoLogin = true
        
        // 标题配置
        model.privacyAlertTitleContent = "服务协议与隐私政策"
        model.privacyAlertTitleFont = UIFont.systemFont(ofSize: 18, weight: .semibold)
        model.privacyAlertTitleColor = UIColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1.0)
        model.privacyAlertTitleAlignment = .center
        
        // 协议内容配置
        model.privacyAlertContentFont = UIFont.systemFont(ofSize: 14)
        model.privacyAlertContentColors = [UIColor.gray, UIColor(red: 0x18/255.0, green: 0x90/255.0, blue: 0xFF/255.0, alpha: 1.0)]
        model.privacyAlertContentAlignment = .center
        model.privacyAlertPreText = "请阅读并同意"
        
        // 按钮配置 - 与登录按钮一致（#1890FF 蓝色，圆角）
        model.privacyAlertBtnContent = "同意并继续"
        model.privacyAlertButtonFont = UIFont.systemFont(ofSize: 16, weight: .semibold)
        model.privacyAlertButtonTextColors = [.white, UIColor.white.withAlphaComponent(0.8)]
        let btnSize = CGSize(width: 100, height: 48)
        let loginBtnColor = UIColor(red: 0x18/255.0, green: 0x90/255.0, blue: 0xFF/255.0, alpha: 1.0)
        let btnBgImage = UIGraphicsImageRenderer(size: btnSize).image { context in
            loginBtnColor.setFill()
            let path = UIBezierPath(roundedRect: CGRect(origin: .zero, size: btnSize), cornerRadius: 2)
            path.fill()
        }
        model.privacyAlertBtnBackgroundImages = [btnBgImage, btnBgImage]
        
        // 弹窗样式
        model.privacyAlertBackgroundColor = .white
        model.privacyAlertCornerRadiusArray = [20, 20, 20, 20]
        model.privacyAlertAlpha = 1.0
        
        // 蒙层配置
        model.privacyAlertMaskIsNeedShow = true
        model.privacyAlertMaskAlpha = 0.5
        model.privacyAlertMaskColor = .black
        model.tapPrivacyAlertMaskCloseAlert = true
        
        // 关闭按钮
        model.privacyAlertCloseButtonIsNeedShow = true
        
        // 弹窗尺寸和位置
        model.privacyAlertFrameBlock = { screenSize, superViewSize, frame in
            let width = screenSize.width * 0.8
            let height: CGFloat = 280
            let x = (screenSize.width - width) / 2
            let y = (screenSize.height - height) / 2
            return CGRect(x: x, y: y, width: width, height: height)
        }
        
        // 标题位置 - 不顶在最上面，留出顶部间距（保留 SDK 默认宽高）
        model.privacyAlertTitleFrameBlock = { screenSize, superViewSize, frame in
            return CGRect(x: 0, y: 30, width: frame.size.width, height: frame.size.height)
        }
        
        // 协议内容位置 - 紧跟标题下方（保留 SDK 默认宽高）
        model.privacyAlertPrivacyContentFrameBlock = { screenSize, superViewSize, frame in
            return CGRect(x: 24, y: 68, width: frame.size.width, height: frame.size.height)
        }
        
        // 按钮尺寸 - 固定在底部
        model.privacyAlertButtonFrameBlock = { screenSize, superViewSize, frame in
            let width = superViewSize.width - 48
            let height: CGFloat = 48
            let x: CGFloat = 24
            let y = superViewSize.height - height - 24
            return CGRect(x: x, y: y, width: width, height: height)
        }
    }
    
    /// 二次协议弹窗（横屏）
    private static func configurePrivacyAlertLandscape(_ model: TXCustomModel) {
        model.supportedInterfaceOrientations = .landscape
        
        // 显示二次协议弹窗
        model.privacyAlertIsNeedShow = true
        model.privacyAlertIsNeedAutoLogin = true
        
        // 标题配置
        model.privacyAlertTitleContent = "服务协议与隐私政策"
        model.privacyAlertTitleFont = UIFont.systemFont(ofSize: 18, weight: .semibold)
        model.privacyAlertTitleColor = UIColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1.0)
        model.privacyAlertTitleAlignment = .center
        
        // 协议内容配置
        model.privacyAlertContentFont = UIFont.systemFont(ofSize: 14)
        model.privacyAlertContentColors = [UIColor.gray, UIColor(red: 0x18/255.0, green: 0x90/255.0, blue: 0xFF/255.0, alpha: 1.0)]
        model.privacyAlertContentAlignment = .center
        model.privacyAlertPreText = "请阅读并同意"
        
        // 按钮配置 - 与登录按钮一致（#1890FF 蓝色，圆角）
        model.privacyAlertBtnContent = "同意并继续"
        model.privacyAlertButtonFont = UIFont.systemFont(ofSize: 16, weight: .semibold)
        model.privacyAlertButtonTextColors = [.white, UIColor.white.withAlphaComponent(0.8)]
        let btnSize = CGSize(width: 100, height: 48)
        let loginBtnColor = UIColor(red: 0x18/255.0, green: 0x90/255.0, blue: 0xFF/255.0, alpha: 1.0)
        let btnBgImage = UIGraphicsImageRenderer(size: btnSize).image { context in
            loginBtnColor.setFill()
            let path = UIBezierPath(roundedRect: CGRect(origin: .zero, size: btnSize), cornerRadius: 2)
            path.fill()
        }
        model.privacyAlertBtnBackgroundImages = [btnBgImage, btnBgImage]
        
        // 弹窗样式
        model.privacyAlertBackgroundColor = .white
        model.privacyAlertCornerRadiusArray = [20, 20, 20, 20]
        model.privacyAlertAlpha = 1.0
        
        // 蒙层配置
        model.privacyAlertMaskIsNeedShow = true
        model.privacyAlertMaskAlpha = 0.5
        model.privacyAlertMaskColor = .black
        model.tapPrivacyAlertMaskCloseAlert = true
        
        // 关闭按钮
        model.privacyAlertCloseButtonIsNeedShow = true
        
        // 横屏模式下返回按钮位置调整
        model.navBackButtonFrameBlock = { screenSize, superViewSize, frame in
            let statusBarHeight: CGFloat = 32
            return CGRect(x: 16, y: (statusBarHeight - 30) / 2, width: 30, height: 30)
        }
        
        // 弹窗尺寸和位置
        model.privacyAlertFrameBlock = { screenSize, superViewSize, frame in
            let screenW = max(screenSize.width, screenSize.height)
            let screenH = min(screenSize.width, screenSize.height)
            let width = screenW * 0.5
            let height = screenH * 0.85
            let x = (screenW - width) / 2
            let y = (screenH - height) / 2
            return CGRect(x: x, y: y, width: width, height: height)
        }
        
        // 标题位置 - 不顶在最上面，留出顶部间距（保留 SDK 默认宽高）
        model.privacyAlertTitleFrameBlock = { screenSize, superViewSize, frame in
            return CGRect(x: 0, y: 30, width: frame.size.width, height: frame.size.height)
        }
        
        // 协议内容位置 - 紧跟标题下方（保留 SDK 默认宽高）
        model.privacyAlertPrivacyContentFrameBlock = { screenSize, superViewSize, frame in
            return CGRect(x: 24, y: 68, width: frame.size.width, height: frame.size.height)
        }
        
        // 按钮尺寸 - 固定在底部
        model.privacyAlertButtonFrameBlock = { screenSize, superViewSize, frame in
            let width = superViewSize.width - 48
            let height: CGFloat = 48
            let x: CGFloat = 24
            let y = superViewSize.height - height - 24
            return CGRect(x: x, y: y, width: width, height: height)
        }
    }
}
