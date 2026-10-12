//
//  DriverCell.swift
//  XunPengMachine
//
//  招聘列表 Cell（对齐设计稿：标题 + 标签 + 底部信息 + 拨打电话）
//

import UIKit

final class DriverCell: UITableViewCell {

    static var rowHeight: CGFloat { 130.fit }

    var onCallTapped: (() -> Void)?

    private let titleLabel = UILabel.make("", font: AppFont.bodyM, color: AppColor.textMain, lines: 2)
    private let arrowView = UIImageView(image: UIImage(systemName: "chevron.right")?.withRenderingMode(.alwaysTemplate))
    private let tagsContainer = UIView()
    private let footerLabel = UILabel.make("", font: AppFont.small, color: AppColor.textHint)
    private let callBtn = UIButton.make("拨打电话", font: AppFont.small, titleColor: .white, bgColor: AppColor.danger)
    private let line = Separator()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .white
        contentView.backgroundColor = .white

        arrowView.tintColor = AppColor.textHint
        callBtn.layer.cornerRadius = 14.fit
        callBtn.addTarget(self, action: #selector(callTapped), for: .touchUpInside)

        contentView.addSubview(titleLabel)
        contentView.addSubview(arrowView)
        contentView.addSubview(tagsContainer)
        contentView.addSubview(footerLabel)
        contentView.addSubview(callBtn)
        contentView.addSubview(line)
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(_ driver: Driver) {
        titleLabel.text = driver.title
        footerLabel.text = [driver.locationDisplayText, driver.createTimeDisplayText]
            .filter { !$0.isEmpty }
            .joined(separator: " | ")

        tagsContainer.removeSubviews()
        let tags = [driver.salaryDisplayText, driver.category, driver.workTypeDisplayText]
            .filter { !$0.isEmpty }
        var x: CGFloat = 0
        for (i, text) in tags.enumerated() {
            let isSalary = i == 0
            let tag = TagView(text: text,
                              textColor: isSalary ? AppColor.primary : AppColor.textSub,
                              bgColor: AppColor.bg)
            tag.frame.origin = CGPoint(x: x, y: 0)
            tagsContainer.addSubview(tag)
            x += tag.w + 6.fit
        }
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let pad: CGFloat = 16.fit
        arrowView.frame = CGRect(x: contentView.w - pad - 8.fit, y: 16.fit, width: 8.fit, height: 14.fit)
        titleLabel.frame = CGRect(x: pad, y: 12.fit, width: arrowView.x - pad - 4.fit, height: 40.fit)

        tagsContainer.frame = CGRect(x: pad, y: titleLabel.bottom + 8.fit, width: contentView.w - pad * 2, height: 20.fit)
        var tx: CGFloat = 0
        for v in tagsContainer.subviews {
            v.frame.origin = CGPoint(x: tx, y: 0)
            tx += v.w + 6.fit
        }

        let btnW: CGFloat = 80.fit
        callBtn.frame = CGRect(x: contentView.w - pad - btnW, y: contentView.h - 40.fit, width: btnW, height: 28.fit)
        footerLabel.frame = CGRect(x: pad, y: callBtn.y + 4.fit, width: callBtn.x - pad - 8.fit, height: 16.fit)
        line.frame = CGRect(x: pad, y: contentView.h - 0.5, width: contentView.w - pad, height: 0.5)
    }

    @objc private func callTapped() { onCallTapped?() }
}
