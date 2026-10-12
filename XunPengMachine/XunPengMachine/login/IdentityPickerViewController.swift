//
//  IdentityPickerViewController.swift
//  XunPengMachine
//
//  登录前身份选择弹框
//

import UIKit

final class IdentityPickerViewController: UIViewController {

    var onPick: ((Int) -> Void)?

    private let maskView = UIView()
    private let panel = UIView()
    private let brandLabel = UILabel.make("巡朋机械", font: AppFont.bold(24),
                                          color: AppColor.primary, alignment: .center)
    private let titleLabel = UILabel.make("请选择您的身份", font: AppFont.title,
                                          color: AppColor.textMain, alignment: .center)
    private var optionViews: [IdentityOptionView] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        view.backgroundColor = .clear

        maskView.backgroundColor = UIColor.black.withAlphaComponent(0.35)
        view.addSubview(maskView)
        maskView.addGestureRecognizer(UITapGestureRecognizer(target: self,
                                                             action: #selector(closeTapped)))

        panel.backgroundColor = AppColor.bg
        panel.layer.cornerRadius = 18.fit
        panel.layer.masksToBounds = true
        view.addSubview(panel)
        panel.addSubview(brandLabel)
        panel.addSubview(titleLabel)

        let options: [(Int, String, String, String, UIColor)] = [
            (1, "老板身份", "求租机械", "(发布活源/招聘司机)", AppColor.danger),
            (2, "车主身份", "出租机械", "(出租机械/招聘司机)", AppColor.primary),
            (3, "驾驶员身份", "求职工作", "(求职司机/应聘司机)", AppColor.primary)
        ]

        optionViews = options.map { option in
            let optionView = IdentityOptionView(identityType: option.0,
                                                identityName: option.1,
                                                actionTitle: option.2,
                                                subtitle: option.3,
                                                color: option.4)
            optionView.addTarget(self, action: #selector(optionTapped(_:)), for: .touchUpInside)
            panel.addSubview(optionView)
            return optionView
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        maskView.frame = view.bounds

        let horizontalMargin: CGFloat = 14.fit
        let panelWidth = min(view.w - horizontalMargin * 2, 390.fit)
        let panelHeight: CGFloat = 430.fit
        panel.frame = CGRect(x: (view.w - panelWidth) / 2,
                             y: (view.h - panelHeight) / 2,
                             width: panelWidth,
                             height: panelHeight)

        brandLabel.frame = CGRect(x: 20.fit, y: 24.fit,
                                  width: panel.w - 40.fit, height: 34.fit)
        titleLabel.frame = CGRect(x: 20.fit, y: brandLabel.bottom + 14.fit,
                                  width: panel.w - 40.fit, height: 26.fit)

        let optionsTop = titleLabel.bottom + 18.fit
        let rowHeight: CGFloat = 92.fit
        for (index, optionView) in optionViews.enumerated() {
            optionView.frame = CGRect(x: 0,
                                      y: optionsTop + CGFloat(index) * rowHeight,
                                      width: panel.w,
                                      height: rowHeight)
        }
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    @objc private func optionTapped(_ sender: IdentityOptionView) {
        let identityType = sender.identityType
        let selectionHandler = onPick
        dismiss(animated: true) {
            selectionHandler?(identityType)
        }
    }
}

private final class IdentityOptionView: UIControl {

    let identityType: Int

    private let identityLabel = UILabel.make("", font: AppFont.bodyM,
                                             color: AppColor.textMain, alignment: .center)
    private let actionView = UIView()
    private let actionLabel = UILabel.make("", font: AppFont.bodyM,
                                           color: .white, alignment: .center)
    private let subtitleLabel = UILabel.make("", font: AppFont.small,
                                             color: UIColor.white.withAlphaComponent(0.9),
                                             alignment: .center)
    private let arrowLabel = UILabel.make("〉", font: AppFont.bodyM,
                                          color: .white, alignment: .center)

    init(identityType: Int, identityName: String, actionTitle: String,
         subtitle: String, color: UIColor) {
        self.identityType = identityType
        super.init(frame: .zero)

        identityLabel.text = identityName
        actionView.backgroundColor = color
        actionView.layer.cornerRadius = 4.fit
        actionView.isUserInteractionEnabled = false
        actionLabel.text = actionTitle
        subtitleLabel.text = subtitle

        addSubview(identityLabel)
        addSubview(actionView)
        actionView.addSubview(actionLabel)
        actionView.addSubview(subtitleLabel)
        actionView.addSubview(arrowLabel)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        identityLabel.frame = CGRect(x: 12.fit, y: 0, width: 120.fit, height: h)
        actionView.frame = CGRect(x: 148.fit, y: 13.fit,
                                  width: w - 168.fit, height: 66.fit)
        actionLabel.frame = CGRect(x: 12.fit, y: 10.fit,
                                   width: actionView.w - 38.fit, height: 22.fit)
        subtitleLabel.frame = CGRect(x: 8.fit, y: actionLabel.bottom + 2.fit,
                                     width: actionView.w - 30.fit, height: 18.fit)
        arrowLabel.frame = CGRect(x: actionView.w - 28.fit, y: 0,
                                  width: 20.fit, height: actionView.h)
    }

    override var isHighlighted: Bool {
        didSet { alpha = isHighlighted ? 0.7 : 1 }
    }
}
