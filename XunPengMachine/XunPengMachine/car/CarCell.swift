//
//  CarCell.swift
//  XunPengMachine
//
//  找设备列表 Cell（对齐设计稿：标题 + 图片/标签 + 底部信息，兼容无图样式）
//

import UIKit

final class CarCell: UITableViewCell {

    private static let pad: CGFloat = 16.fit
    private static let arrowW: CGFloat = 8.fit
    private static let topMargin: CGFloat = 12.fit
    private static let gap: CGFloat = 8.fit
    private static let imgW: CGFloat = 100.fit
    private static let imgH: CGFloat = 72.fit
    private static let tagH: CGFloat = 20.fit
    private static let bottomH: CGFloat = 16.fit
    private static let bottomMargin: CGFloat = 10.fit
    private static let lineH: CGFloat = 0.5

    private let titleLabel = UILabel.make("", font: AppFont.bodyM, color: AppColor.textMain, lines: 2)
    private let arrowView = UIImageView(image: UIImage(systemName: "chevron.right")?.withRenderingMode(.alwaysTemplate))
    private let thumbView = WebImageView()
    private let tagContainer = UIView()
    private let cityLabel = UILabel.make("", font: AppFont.small, color: AppColor.textHint)
    private let timeLabel = UILabel.make("", font: AppFont.small, color: AppColor.textHint)
    private let line = Separator()

    /// 是否有图
    private var hasImage = false
    /// 缓存标题高度
    private(set) var titleHeight: CGFloat = 20.fit

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .white
        contentView.backgroundColor = .white

        thumbView.layer.cornerRadius = 4.fit
        thumbView.layer.masksToBounds = true
        thumbView.contentMode = .scaleAspectFill
        thumbView.backgroundColor = AppColor.bg
        arrowView.tintColor = AppColor.textHint

        contentView.addSubview(titleLabel)
        contentView.addSubview(arrowView)
        contentView.addSubview(thumbView)
        contentView.addSubview(tagContainer)
        contentView.addSubview(cityLabel)
        contentView.addSubview(timeLabel)
        contentView.addSubview(line)
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(_ car: Car) {
        titleLabel.text = car.title
        cityLabel.text = "\(car.city)\(car.area)"
        timeLabel.text = car.publishTime

        // 图片
        let imgUrl = car.images.first
        hasImage = !(imgUrl?.isEmpty ?? true)
        if hasImage {
            thumbView.setUrl(imgUrl)
            thumbView.isHidden = false
        } else {
            thumbView.isHidden = true
        }

        // 标签
        tagContainer.removeSubviews()
        let tag = TagView(text: car.type, textColor: AppColor.textSub, bgColor: AppColor.bg)
        tagContainer.addSubview(tag)
        tag.frame.origin = .zero

        // 预计算标题高度
        let titleMaxW = UIScreen.main.bounds.width - Self.pad * 2 - Self.arrowW - 8.fit
        titleHeight = Self.titleHeight(for: car.title, width: titleMaxW)

        setNeedsLayout()
    }

    // MARK: - 高度计算

    /// 计算标题高度（最多2行）
    static func titleHeight(for text: String, width: CGFloat) -> CGFloat {
        let label = UILabel()
        label.font = AppFont.bodyM
        label.numberOfLines = 2
        label.text = text
        return label.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude)).height
    }

    /// 根据 Car 数据计算 cell 所需高度
    static func rowHeight(for car: Car) -> CGFloat {
        let titleMaxW = UIScreen.main.bounds.width - pad * 2 - arrowW - 8.fit
        let titleH = titleHeight(for: car.title, width: titleMaxW)
        let hasImg = !(car.images.first?.isEmpty ?? true)

        // top + title + gap + (imgH or tagH) + gap + bottomH + bottomMargin + line
        let contentH: CGFloat = hasImg ? imgH : tagH
        return topMargin + titleH + gap + contentH + gap + bottomH + bottomMargin + lineH
    }

    // MARK: - 布局

    override func layoutSubviews() {
        super.layoutSubviews()
        let pad = Self.pad
        let arrowW = Self.arrowW

        // 1. 标题：全宽，动态高度，最多2行
        let titleMaxW = contentView.w - pad * 2 - arrowW - 8.fit
        titleLabel.frame = CGRect(x: pad, y: Self.topMargin, width: titleMaxW, height: titleHeight)

        // 箭头：与标题垂直居中
        let arrowH: CGFloat = 14.fit
        let arrowY = titleLabel.y + (titleHeight - arrowH) / 2
        arrowView.frame = CGRect(x: contentView.w - pad - arrowW, y: arrowY,
                                 width: arrowW, height: arrowH)

        // 2. 图片 + 标签（图片在标题下方）
        let belowTitleY = titleLabel.bottom + Self.gap

        if hasImage {
            // 有图：图片在左，标签在图片右侧
            thumbView.frame = CGRect(x: pad, y: belowTitleY,
                                     width: Self.imgW, height: Self.imgH)

            if let tag = tagContainer.subviews.first {
                tag.frame.origin = .zero
                tagContainer.frame = CGRect(x: thumbView.right + Self.gap,
                                            y: belowTitleY + (Self.imgH - Self.tagH) / 2,
                                            width: tag.frame.width, height: Self.tagH)
            }
        } else {
            // 无图：标签在标题下方
            if let tag = tagContainer.subviews.first {
                tag.frame.origin = .zero
                tagContainer.frame = CGRect(x: pad, y: belowTitleY,
                                            width: tag.frame.width, height: Self.tagH)
            }
        }

        // 3. 城市 + 时间（紧贴分割线上方）
        let bottomY = contentView.h - Self.lineH - Self.bottomMargin - Self.bottomH
        cityLabel.frame = CGRect(x: pad, y: bottomY, width: 120.fit, height: Self.bottomH)
        let timeW = (timeLabel.text ?? "").size(font: AppFont.small).width
        timeLabel.frame = CGRect(x: contentView.w - pad - timeW, y: bottomY,
                                 width: timeW, height: Self.bottomH)

        // 4. 分割线
        line.frame = CGRect(x: pad, y: contentView.h - Self.lineH,
                             width: contentView.w - pad, height: Self.lineH)
    }
}
