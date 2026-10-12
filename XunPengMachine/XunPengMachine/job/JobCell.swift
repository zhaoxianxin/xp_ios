//
//  JobCell.swift
//  XunPengMachine
//
//  找活列表 Cell（对齐设计稿：标题 + 标签/租金/工期同行 + 时间胶囊 + 底部信息）
//

import UIKit

final class JobCell: UITableViewCell {

    /// 固定间距常量
    private static let pad: CGFloat = 16.fit
    private static let arrowW: CGFloat = 8.fit
    private static let topMargin: CGFloat = 12.fit
    private static let bottomMargin: CGFloat = 10.fit
    private static let bottomH: CGFloat = 16.fit
    private static let rowH: CGFloat = 20.fit
    private static let pillH: CGFloat = 20.fit
    private static let lineH: CGFloat = 0.5

    private let titleLabel = UILabel.make("", font: AppFont.bodyM, color: AppColor.textMain, lines: 2)
    private let arrowView = UIImageView(image: UIImage(systemName: "chevron.right")?.withRenderingMode(.alwaysTemplate))
    private let tagContainer = UIView()
    private let rentLabel = UILabel()
    private let durationLabel = UILabel()
    private let timePillContainer = UIView()
    private let cityLabel = UILabel.make("", font: AppFont.small, color: AppColor.textHint)
    private let timeLabel = UILabel.make("", font: AppFont.small, color: AppColor.textHint)
    private let line = Separator()

    /// 缓存标题高度，供外部计算 cell 行高
    private(set) var titleHeight: CGFloat = 20.fit

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .white
        contentView.backgroundColor = .white

        arrowView.tintColor = AppColor.textHint
        contentView.addSubview(titleLabel)
        contentView.addSubview(arrowView)
        contentView.addSubview(tagContainer)
        contentView.addSubview(rentLabel)
        contentView.addSubview(durationLabel)
        contentView.addSubview(timePillContainer)
        contentView.addSubview(cityLabel)
        contentView.addSubview(timeLabel)
        contentView.addSubview(line)
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(_ job: Job) {
        titleLabel.text = job.title
        cityLabel.text = job.cityDisplayText
        timeLabel.text = job.createTimeText

        tagContainer.removeSubviews()
        let tag = TagView(text: job.category,
                          textColor: AppColor.textSub, bgColor: AppColor.bg)
        tagContainer.addSubview(tag)
        tag.frame.origin = .zero

        rentLabel.attributedText = priceAttr(prefix: "租金 ", value: job.rentAmountText, suffix: "元")
        durationLabel.attributedText = priceAttr(prefix: "工期 ", value: job.durationText, suffix: "")

        timePillContainer.removeSubviews()
        let pill = TimePillView(prefix: "业务进展 |", time: job.businessStatusText)
        timePillContainer.addSubview(pill)
        pill.frame.origin = .zero

        // 预计算标题高度
        let titleMaxW = UIScreen.main.bounds.width - Self.pad * 2 - Self.arrowW - 8.fit
        titleHeight = calcTitleHeight(text: job.title, width: titleMaxW)

        setNeedsLayout()
    }

    /// 计算带换行的标题高度（最多2行）
    static func titleHeight(for text: String, width: CGFloat) -> CGFloat {
        let label = UILabel()
        label.font = AppFont.bodyM
        label.numberOfLines = 2
        label.text = text
        return label.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude)).height
    }

    /// 当前 cell 内容所需高度
    static func rowHeight(for job: Job) -> CGFloat {
        let pad: CGFloat = 16.fit
        let arrowW: CGFloat = 8.fit
        let titleMaxW = UIScreen.main.bounds.width - pad * 2 - arrowW - 8.fit
        let titleH = titleHeight(for: job.title, width: titleMaxW)
        return pad + titleH + 8.fit + rowH + 8.fit + pillH + 10.fit + bottomH + bottomMargin + lineH
    }

    private func calcTitleHeight(text: String, width: CGFloat) -> CGFloat {
        Self.titleHeight(for: text, width: width)
    }

    private func priceAttr(prefix: String, value: String, suffix: String) -> NSAttributedString {
        let attr = NSMutableAttributedString(string: prefix, attributes: [
            .font: AppFont.small, .foregroundColor: AppColor.textSub
        ])
        attr.append(NSAttributedString(string: value + suffix, attributes: [
            .font: AppFont.bodyM, .foregroundColor: AppColor.primary
        ]))
        return attr
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let pad = Self.pad
        let arrowW = Self.arrowW

        // 1. 标题：动态高度，最多2行
        let titleMaxW = contentView.w - pad * 2 - arrowW - 8.fit
        titleLabel.frame = CGRect(x: pad, y: Self.topMargin,
                                  width: titleMaxW, height: titleHeight)

        // 箭头：与标题垂直居中
        let arrowH: CGFloat = 14.fit
        let arrowY = titleLabel.y + (titleHeight - arrowH) / 2
        arrowView.frame = CGRect(x: contentView.w - pad - arrowW, y: arrowY,
                                 width: arrowW, height: arrowH)

        // 2. 标签 + 租金 + 工期 同一行，垂直居中对齐
        let rowY = titleLabel.bottom + 8.fit
        let rowH = Self.rowH

        // 标签（左）
        if let tag = tagContainer.subviews.first {
            tag.frame.origin = .zero
            tagContainer.frame = CGRect(x: pad, y: rowY, width: tag.frame.width, height: rowH)
        } else {
            tagContainer.frame = CGRect(x: pad, y: rowY, width: 0, height: rowH)
        }

        // 租金（标签右侧，垂直居中）
        rentLabel.sizeToFit()
        let rentH = rentLabel.frame.height
        rentLabel.frame = CGRect(x: tagContainer.right + 12.fit,
                                 y: rowY + (rowH - rentH) / 2,
                                 width: rentLabel.frame.width, height: rentH)

        // 工期（租金右侧，垂直居中）
        durationLabel.sizeToFit()
        let durH = durationLabel.frame.height
        durationLabel.frame = CGRect(x: rentLabel.right + 16.fit,
                                     y: rowY + (rowH - durH) / 2,
                                     width: durationLabel.frame.width, height: durH)

        // 3. 租车时间胶囊
        timePillContainer.frame = CGRect(x: pad, y: rowY + rowH + 8.fit,
                                         width: contentView.w - pad * 2, height: Self.pillH)
        if let pill = timePillContainer.subviews.first {
            pill.frame.origin = .zero
        }

        // 4. 城市 + 时间（紧贴分割线上方）
        let bottomY = contentView.h - Self.lineH - Self.bottomMargin - Self.bottomH
        cityLabel.frame = CGRect(x: pad, y: bottomY, width: 120.fit, height: Self.bottomH)
        let timeW = (timeLabel.text ?? "").size(font: AppFont.small).width
        timeLabel.frame = CGRect(x: contentView.w - pad - timeW, y: bottomY, width: timeW, height: Self.bottomH)

        // 5. 分割线（最底部）
        line.frame = CGRect(x: pad, y: contentView.h - Self.lineH, width: contentView.w - pad, height: Self.lineH)
    }
}
