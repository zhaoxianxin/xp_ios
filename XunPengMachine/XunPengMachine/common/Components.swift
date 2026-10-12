//
//  Components.swift
//  XunPengMachine
//
//  通用 UI 组件：标签、空视图、主题按钮、搜索栏、分段控件
//

import UIKit

// MARK: - 标签胶囊
class TagView: UIView {
    init(text: String, textColor: UIColor = AppColor.tagText, bgColor: UIColor = AppColor.tagBg) {
        super.init(frame: .zero)
        let label = UILabel.make(text, font: AppFont.mini, color: textColor)
        addSubview(label)
        label.frame = CGRect(x: 6, y: 3, width: text.size(font: AppFont.mini).width, height: 14)
        frame.size = CGSize(width: label.w + 12, height: 20)
        backgroundColor = bgColor
        layer.cornerRadius = 3
    }
    required init?(coder: NSCoder) { fatalError() }
}

// MARK: - 空视图
class EmptyView: UIView {
    private var label: UILabel?
    private var icon: UIImageView?
    init(text: String = "暂无数据") {
        super.init(frame: .zero)
        let icon = UIImageView(image: UIImage(systemName: "tray")?.withRenderingMode(.alwaysTemplate))
        icon.tintColor = AppColor.textHint
        addSubview(icon)
        icon.frame = CGRect(x: 0, y: 0, width: 60, height: 60)

        let label = UILabel.make(text, font: AppFont.sub, color: AppColor.textHint, alignment: .center)
        addSubview(label)

        let totalH: CGFloat = 90
        icon.center = CGPoint(x: 0, y: 0)
        icon.frame.origin = CGPoint(x: -30, y: 0)
        label.frame = CGRect(x: -80, y: 70, width: 160, height: 20)
        frame = CGRect(x: 0, y: 0, width: 160, height: totalH)
        
        self.label = label
        self.icon = icon
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        label?.centerX = self.frame.size.width / 2;
        icon?.centerX = self.frame.size.width / 2;
    }
    required init?(coder: NSCoder) { fatalError() }
}

// MARK: - 主题按钮
class AppButton: UIButton {
    enum Style { case primary, danger, outline }
    private var style: Style = .primary

    init(title: String, style: Style = .primary, height: CGFloat = 44) {
        super.init(frame: .zero)
        self.style = style
        setTitle(title, for: .normal)
        titleLabel?.font = AppFont.bodyM
        layer.cornerRadius = height / 2
        applyStyle()
        frame.size = CGSize(width: 0, height: height)
    }
    required init?(coder: NSCoder) { fatalError() }

    private func applyStyle() {
        switch style {
        case .primary:
            backgroundColor = AppColor.primary
            setTitleColor(.white, for: .normal)
        case .danger:
            backgroundColor = AppColor.danger
            setTitleColor(.white, for: .normal)
        case .outline:
            backgroundColor = .clear
            layer.borderWidth = 1
            layer.borderColor = AppColor.primary.cgColor
            setTitleColor(AppColor.primary, for: .normal)
        }
    }
}

// MARK: - 搜索栏
class SearchBar: UIView {
    var textDidChange: ((String) -> Void)?
    private let textField = UITextField()

    init(placeholder: String = "搜索活源/设备/司机") {
        super.init(frame: .zero)
        backgroundColor = AppColor.bg
        layer.cornerRadius = 18

        let icon = UIImageView(image: UIImage(systemName: "magnifyingglass")?.withRenderingMode(.alwaysTemplate))
        icon.tintColor = AppColor.textHint
        addSubview(icon)
        icon.frame = CGRect(x: 12, y: 9, width: 16, height: 16)

        textField.placeholder = placeholder
        textField.font = AppFont.body
        textField.borderStyle = .none
        textField.clearButtonMode = .whileEditing
        textField.returnKeyType = .search
        textField.addTarget(self, action: #selector(editingChanged), for: .editingChanged)
        addSubview(textField)
        textField.frame = CGRect(x: 36, y: 0, width: 0, height: 36)
    }
    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        textField.frame = CGRect(x: 36, y: 0, width: w - 50, height: h)
    }

    @objc private func editingChanged() { textDidChange?(textField.text ?? "") }
}

// MARK: - 网络图片 ImageView
class WebImageView: UIImageView {
    var placeholder = UIImage(systemName: "photo")?.withRenderingMode(.alwaysTemplate)
    override init(frame: CGRect) {
        super.init(frame: frame)
        tintColor = AppColor.separator
    }
    convenience init() { self.init(frame: .zero) }
    required init?(coder: NSCoder) { fatalError() }

    func setUrl(_ url: String?) {
        ImageLoader.shared.load(url, into: self, placeholder: placeholder)
    }
}

// MARK: - 分割线
class Separator: UIView {
    init() { super.init(frame: .zero); backgroundColor = AppColor.separator; frame.size.height = 0.5 }
    required init?(coder: NSCoder) { fatalError() }
}

// MARK: - 首页顶部蓝条（巡朋机械 + 提醒）
class HomeTopBarView: UIView {
    var onRemindTapped: (() -> Void)?

    private let titleLabel = UILabel.make("巡朋机械", font: AppFont.bold(18), color: .white)
    private let remindLabel = UILabel.make("好活提醒", font: AppFont.sub, color: .white)
    private let remindBtn = UIButton(type: .custom)

    init(remindTitle: String = "好活提醒") {
        super.init(frame: .zero)
        backgroundColor = AppColor.navBar
        remindLabel.text = remindTitle
        addSubview(titleLabel)
        addSubview(remindLabel)

        remindBtn.backgroundColor = AppColor.danger
        remindBtn.layer.cornerRadius = 12.fit
        remindBtn.setTitle("去开启", for: .normal)
        remindBtn.setTitleColor(.white, for: .normal)
        remindBtn.titleLabel?.font = AppFont.mini
        remindBtn.contentEdgeInsets = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
        remindBtn.addTarget(self, action: #selector(remindTapped), for: .touchUpInside)
        addSubview(remindBtn)
    }
    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        titleLabel.frame = CGRect(x: 16.fit, y: Screen.statusBarH + 10.fit, width: 120.fit, height: 24.fit)
        let btnW = remindBtn.intrinsicContentSize.width + 16.fit
        remindBtn.frame = CGRect(x: w - 16.fit - btnW, y: Screen.statusBarH + 8.fit, width: btnW, height: 24.fit)
        let labelW = remindLabel.text?.size(font: AppFont.sub).width ?? 60
        remindLabel.frame = CGRect(x: remindBtn.x - 8.fit - labelW, y: Screen.statusBarH + 10.fit,
                                   width: labelW, height: 20.fit)
    }

    static var preferredHeight: CGFloat { Screen.statusBarH + 44.fit }

    @objc private func remindTapped() { onRemindTapped?() }
}

// MARK: - 首页筛选条（三列下拉）
class HomeFilterBarView: UIView {
    var onLeftTapped: (() -> Void)?
    var onCenterTapped: (() -> Void)?
    var onRightTapped: (() -> Void)?

    private let leftBtn = FilterDropdownButton(title: "全国地区")
    private let centerBtn = FilterDropdownButton(title: "求租设备", highlighted: true)
    private let rightBtn = FilterDropdownButton(title: "全部机械")
    private let line = Separator()

    init(centerTitle: String, rightTitle: String = "全部机械", centerHighlighted: Bool = true) {
        super.init(frame: .zero)
        backgroundColor = .white
        centerBtn.setTitle(centerTitle, for: .normal)
        centerBtn.isHighlightedStyle = centerHighlighted
        rightBtn.setTitle(rightTitle, for: .normal)
        rightBtn.isHighlightedStyle = false
        addSubview(leftBtn)
        addSubview(centerBtn)
        addSubview(rightBtn)
        addSubview(line)
        leftBtn.addTarget(self, action: #selector(leftTap), for: .touchUpInside)
        centerBtn.addTarget(self, action: #selector(centerTap), for: .touchUpInside)
        rightBtn.addTarget(self, action: #selector(rightTap), for: .touchUpInside)
    }
    required init?(coder: NSCoder) { fatalError() }
    
    func disableCenter() {
        centerBtn.setImage(nil, for: .normal)
        centerBtn.imageEdgeInsets = .zero
    }

    func updateLeft(_ title: String) { leftBtn.setTitle(title, for: .normal) }
    func updateCenter(_ title: String) { centerBtn.setTitle(title, for: .normal) }
    func updateRight(_ title: String) { rightBtn.setTitle(title, for: .normal) }

    override func layoutSubviews() {
        super.layoutSubviews()
        line.frame = CGRect(x: 0, y: h - 0.5, width: w, height: 0.5)
        let colW = w / 3
        leftBtn.frame = CGRect(x: 0, y: 0, width: colW, height: h)
        centerBtn.frame = CGRect(x: colW, y: 0, width: colW, height: h)
        rightBtn.frame = CGRect(x: colW * 2, y: 0, width: colW, height: h)
    }

    static let height: CGFloat = 44.fit

    @objc private func leftTap() { onLeftTapped?() }
    @objc private func centerTap() { onCenterTapped?() }
    @objc private func rightTap() { onRightTapped?() }
}

// MARK: - 筛选下拉按钮
class FilterDropdownButton: UIButton {
    var isHighlightedStyle = false {
        didSet { updateStyle() }
    }

    init(title: String, highlighted: Bool = false) {
        super.init(frame: .zero)
        setTitle(title, for: .normal)
        titleLabel?.font = AppFont.body
        isHighlightedStyle = highlighted
        setImage(UIImage(systemName: "chevron.down")?.withRenderingMode(.alwaysTemplate), for: .normal)
        semanticContentAttribute = .forceRightToLeft
        imageEdgeInsets = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: 0)
        updateStyle()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func updateStyle() {
        setTitleColor(isHighlightedStyle ? AppColor.primary : AppColor.textMain, for: .normal)
        tintColor = AppColor.textHint
    }
}

// MARK: - 时间胶囊标签
/// 时间胶囊：prefix 文案在外部（无背景），time 部分带背景底色
class TimePillView: UIView {
    /// 外部文案 label（"租车时间 |"）
    private(set) var prefixLabel = UILabel()
    /// 时间胶囊（带背景底色）
    private(set) var pillView = UIView()
    private(set) var timeLabel = UILabel()

    init(prefix: String, time: String) {
        super.init(frame: .zero)

        // 外部文案
        prefixLabel = UILabel.make(prefix, font: AppFont.small, color: AppColor.textSub)
        addSubview(prefixLabel)

        // 时间胶囊（仅时间部分带背景）
        pillView.backgroundColor = AppColor.primary.withAlphaComponent(0.08)
        pillView.layer.cornerRadius = 4.fit
        addSubview(pillView)

        timeLabel = UILabel.make(time, font: AppFont.small, color: AppColor.primary)
        pillView.addSubview(timeLabel)

        // 计算尺寸
        let prefixW = prefix.size(font: AppFont.small).width
        let timeW = time.size(font: AppFont.small).width
        let pillH: CGFloat = 20.fit
        let pillContentW = timeW + 12.fit

        prefixLabel.frame = CGRect(x: 0, y: (pillH - 16.fit) / 2, width: prefixW, height: 16.fit)
        pillView.frame = CGRect(x: prefixW + 4.fit, y: 0, width: pillContentW, height: pillH)
        timeLabel.frame = CGRect(x: 6.fit, y: 2.fit, width: timeW, height: 16.fit)

        frame.size = CGSize(width: prefixW + 4.fit + pillContentW, height: pillH)
    }
    required init?(coder: NSCoder) { fatalError() }
}
