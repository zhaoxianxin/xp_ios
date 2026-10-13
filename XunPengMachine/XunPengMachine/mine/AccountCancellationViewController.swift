//
//  AccountCancellationViewController.swift
//  XunPengMachine
//
//  注销账号确认页
//

import UIKit

final class AccountCancellationViewController: BaseViewController {

    var onConfirmCancellation: (() -> Void)?

    private let scrollView = UIScrollView()
    private let warningTitleLabel = UILabel.make("重要提醒", font: AppFont.bodyM,
                                                 color: UIColor(hex: 0xC58324))
    private let warningLabel = UILabel()
    private let bottomBar = UIView()
    private let confirmButton = AppButton(title: "确认注销", style: .danger, height: 44.fit)
    private let abandonButton = AppButton(title: "放弃注销", style: .outline, height: 44.fit)

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "注销账号"
        setupNavigation()
        setupUI()
    }

    private func setupNavigation() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(backTapped)
        )
    }

    private func setupUI() {
        view.backgroundColor = .white
        scrollView.alwaysBounceVertical = true
        view.addSubview(scrollView)
        scrollView.addSubview(warningTitleLabel)

        warningLabel.numberOfLines = 0
        warningLabel.font = AppFont.sub
        warningLabel.textColor = AppColor.textMain
        warningLabel.text = """
        1. 您的巡朋机械注册账号及该账号所有相关数据，包括发布货源、发布招聘司机信息、发布车辆出租信息、求职信息等都会被清空，请谨慎处理。

        2. 注销账号后，将会注销您在巡朋机械登录的当前账号。

        3. 请注意，注销的巡朋机械账号并不代表本巡朋机械账号注销前的账号行为和相关责任豁免或减轻。
        """
        scrollView.addSubview(warningLabel)

        bottomBar.backgroundColor = .white
        view.addSubview(bottomBar)
        bottomBar.addSubview(confirmButton)
        bottomBar.addSubview(abandonButton)

        confirmButton.addTarget(self, action: #selector(confirmTapped), for: .touchUpInside)
        abandonButton.addTarget(self, action: #selector(abandonTapped), for: .touchUpInside)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let safeBottom = view.safeAreaInsets.bottom
        let barHeight = 76.fit + safeBottom
        bottomBar.frame = CGRect(x: 0, y: view.h - barHeight,
                                 width: view.w, height: barHeight)

        let sideInset: CGFloat = 16.fit
        let gap: CGFloat = 14.fit
        let buttonWidth = (view.w - sideInset * 2 - gap) / 2
        confirmButton.frame = CGRect(x: sideInset, y: 14.fit,
                                     width: buttonWidth, height: 44.fit)
        abandonButton.frame = CGRect(x: confirmButton.right + gap, y: 14.fit,
                                     width: buttonWidth, height: 44.fit)

        scrollView.frame = CGRect(x: 0, y: 0, width: view.w, height: bottomBar.y)
        warningTitleLabel.frame = CGRect(x: 16.fit, y: 16.fit,
                                         width: view.w - 32.fit, height: 24.fit)
        let labelWidth = view.w - 32.fit
        let labelHeight = warningLabel.sizeThatFits(
            CGSize(width: labelWidth, height: .greatestFiniteMagnitude)
        ).height
        warningLabel.frame = CGRect(x: 16.fit, y: warningTitleLabel.bottom + 10.fit,
                                    width: labelWidth, height: labelHeight)
        scrollView.contentSize = CGSize(width: view.w, height: warningLabel.bottom + 24.fit)
    }

    @objc private func confirmTapped() {
        Logger.shared.track("settings_confirm_cancel_account")
        onConfirmCancellation?()
    }

    @objc private func abandonTapped() {
        Logger.shared.track("settings_abandon_cancel_account")
        navigationController?.popViewController(animated: true)
    }
}
