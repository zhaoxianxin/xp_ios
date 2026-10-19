//
//  CustomTabBar.swift
//  XunPengMachine
//
//  自定义 TabBar：中间凸起「发布」按钮，扩展点击热区
//

import UIKit

protocol CustomTabBarDelegate: AnyObject {
    func tabBarDidClickPublish()
}

class CustomTabBar: UITabBar {

    weak var publishDelegate: CustomTabBarDelegate?

    /// 发布按钮（凸起于 TabBar 顶部）
    private let publishButton = UIButton(type: .custom)
    private var userDisposable: Disposable?

    /// 按钮凸出高度
    private let protrude: CGFloat = 22
    /// 按钮直径
    private let buttonSize: CGFloat = 56

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupAppearance()
        setupPublishButton()
        bindCurrentUser()
        // 去除顶部细线
        backgroundView()
    }
    required init?(coder: NSCoder) { fatalError() }

    deinit {
        userDisposable?.dispose()
    }

    private let publishIcon = UIImageView()
    private let publishLabel = UILabel.make("发布", font: AppFont.mini, color: .white, alignment: .center)

    private func setupPublishButton() {
        publishButton.backgroundColor = AppColor.danger
        publishButton.layer.cornerRadius = buttonSize / 2
        publishButton.layer.masksToBounds = true
        publishButton.layer.borderColor = UIColor.white.cgColor
        publishButton.layer.borderWidth = 3
        publishButton.adjustsImageWhenHighlighted = false
        publishButton.addTarget(self, action: #selector(publishTapped), for: .touchUpInside)
        addSubview(publishButton)

        publishIcon.image = UIImage(systemName: "plus")?.withRenderingMode(.alwaysTemplate)
        publishIcon.tintColor = .white
        publishIcon.contentMode = .scaleAspectFit
        publishButton.addSubview(publishIcon)
        publishButton.addSubview(publishLabel)
    }

    private func bindCurrentUser() {
        userDisposable = UserManager.shared.user.subscribe(onNext: { [weak self] user in
            // 未获取到用户、未选择身份或司机身份均无发布功能。
            self?.publishButton.isHidden = user == nil || user?.identityType == 0 || user?.identityType == 3
        })
    }

    private func backgroundView() {
        // 顶部阴影线
        let line = UIView()
        line.backgroundColor = AppColor.separator
        line.frame = CGRect(x: 0, y: 0, width: Screen.width, height: 0.5)
        addSubview(line)
        bringSubviewToFront(publishButton)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // 发布按钮居中凸起
        let cx = Screen.width / 2
        let cy = -protrude + (buttonSize / 2)
        publishButton.frame = CGRect(x: cx - buttonSize / 2,
                                     y: cy - buttonSize / 2,
                                     width: buttonSize, height: buttonSize)
        publishIcon.frame = CGRect(x: (buttonSize - 22) / 2, y: 10, width: 22, height: 22)
        publishLabel.frame = CGRect(x: 0, y: publishIcon.bottom + 2, width: buttonSize, height: 14)
    }

    /// 扩展点击热区：凸出部分也能响应
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard !publishButton.isHidden else {
            return super.hitTest(point, with: event)
        }
        // 将点转换到发布按钮坐标系
        let p = convert(point, to: publishButton)
        if publishButton.bounds.contains(p) {
            return publishButton
        }
        // 扩大按钮周围热区（直径 72 的圆）
        let center = publishButton.center
        let dx = point.x - center.x, dy = point.y - center.y
        if dx * dx + dy * dy <= 36 * 36 {
            return publishButton
        }
        return super.hitTest(point, with: event)
    }

    @objc private func publishTapped() {
        publishDelegate?.tabBarDidClickPublish()
    }
    
    private func setupAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .white
        appearance.shadowColor = AppColor.separator

        let normal: [NSAttributedString.Key: Any] = [
            .font: AppFont.body,
            .foregroundColor: AppColor.textSub
        ]
        let selected: [NSAttributedString.Key: Any] = [
            .font: AppFont.bodyM,
            .foregroundColor: AppColor.primary
        ]

        // 字体颜色
        appearance.stackedLayoutAppearance.normal.titleTextAttributes   = normal
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = selected

        // ★ 关键:文字垂直居中,必须在这里设
        let offset = UIOffset(horizontal: 0, vertical: -16)
        appearance.stackedLayoutAppearance.normal.titlePositionAdjustment   = offset
        appearance.stackedLayoutAppearance.selected.titlePositionAdjustment = offset

        // 保险:inline / compactInline 也一起设
        appearance.inlineLayoutAppearance.normal.titlePositionAdjustment    = offset
        appearance.inlineLayoutAppearance.selected.titlePositionAdjustment  = offset
        appearance.compactInlineLayoutAppearance.normal.titlePositionAdjustment   = offset
        appearance.compactInlineLayoutAppearance.selected.titlePositionAdjustment = offset

        standardAppearance = appearance
        if #available(iOS 15.0, *) {
            scrollEdgeAppearance = appearance
        }
    }
    
}
