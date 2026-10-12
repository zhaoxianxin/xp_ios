//
//  JobRemindViewController.swift
//  XunPengMachine
//
//  找活-好活提醒：条件开关 + 保存
//

import UIKit

final class JobRemindViewController: BaseViewController {

    override var navStyle: NavStyle {
        get { .white }
        set { }
    }

    private let scrollView = UIScrollView()
    private let descCard = UIView()
    private let descLabel = UILabel.make("开启后，系统会根据您的偏好，第一时间推送匹配的活源提醒。",
                                         font: AppFont.body, color: AppColor.textSub, lines: 0)
    private let conditionCard = UIView()
    private let conditionTitleLabel = UILabel.make("提醒条件", font: AppFont.bodyM, color: AppColor.textMain)
    private var rows: [UIView] = []
    private var nameLabels: [UILabel] = []
    private var switches: [UISwitch] = []
    private let saveButton = AppButton(title: "保存", style: .primary, height: 44)

    private struct RemindItem { let title: String; let on: Bool }
    private let items: [RemindItem] = [
        RemindItem(title: "渣土活源", on: true),
        RemindItem(title: "混凝土活源", on: false),
        RemindItem(title: "月薪>8000", on: true),
        RemindItem(title: "附近10公里", on: false)
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "好活提醒"
        setupBackButton()
        view.backgroundColor = AppColor.bg
        setupUI()
    }

    private func setupUI() {
        view.addSubview(scrollView)

        scrollView.addSubview(descCard)
        descCard.backgroundColor = AppColor.cardBg
        descCard.layer.cornerRadius = 8.fit
        descCard.layer.masksToBounds = true
        descCard.addSubview(descLabel)

        scrollView.addSubview(conditionCard)
        conditionCard.backgroundColor = AppColor.cardBg
        conditionCard.layer.cornerRadius = 8.fit
        conditionCard.layer.masksToBounds = true
        conditionCard.addSubview(conditionTitleLabel)

        for item in items {
            let row = UIView()
            let nameL = UILabel.make(item.title, font: AppFont.body, color: AppColor.textMain)
            let sw = UISwitch()
            sw.isOn = item.on
            sw.onTintColor = AppColor.primary
            row.addSubview(nameL)
            row.addSubview(sw)
            conditionCard.addSubview(row)
            rows.append(row)
            nameLabels.append(nameL)
            switches.append(sw)
        }

        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        view.addSubview(saveButton)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let saveH: CGFloat = 44.fit
        let bottomH = saveH + 16.fit + Screen.bottomSafeH
        scrollView.frame = CGRect(x: 0, y: 0, width: view.w, height: view.h - bottomH)
        saveButton.frame = CGRect(x: 16.fit, y: view.h - bottomH,
                                  width: view.w - 32.fit, height: saveH)

        let pad: CGFloat = 12.fit
        let cardW = view.w - pad * 2
        let innerPad: CGFloat = 12.fit
        let maxTextW = cardW - innerPad * 2
        var y: CGFloat = pad

        // 说明卡
        let descTextH = (descLabel.text ?? "").size(font: AppFont.body, maxWidth: maxTextW).height
        let descH = innerPad + descTextH + innerPad
        descCard.frame = CGRect(x: pad, y: y, width: cardW, height: descH)
        descLabel.frame = CGRect(x: innerPad, y: innerPad, width: maxTextW, height: descTextH)
        y = descCard.bottom + pad

        // 条件卡
        let titleH: CGFloat = 24.fit
        let rowH: CGFloat = 50.fit
        let condH = innerPad + titleH + rowH * CGFloat(rows.count) + innerPad
        conditionCard.frame = CGRect(x: pad, y: y, width: cardW, height: condH)
        conditionTitleLabel.frame = CGRect(x: innerPad, y: innerPad, width: maxTextW, height: titleH)
        let swW: CGFloat = 51
        let swH: CGFloat = 31
        var ry = innerPad + titleH
        for i in 0..<rows.count {
            rows[i].frame = CGRect(x: 0, y: ry, width: cardW, height: rowH)
            nameLabels[i].frame = CGRect(x: innerPad, y: 0, width: 200.fit, height: rowH)
            switches[i].frame = CGRect(x: cardW - innerPad - swW,
                                       y: (rowH - swH) / 2, width: swW, height: swH)
            ry += rowH
        }
        scrollView.contentSize = CGSize(width: view.w, height: conditionCard.bottom + pad)
    }

    @objc private func saveTapped() {
        let on = switches.filter { $0.isOn }.count
        Logger.shared.track("job_remind_save", params: ["count": on])
        showToast("保存成功")
    }
}
