//
//  EquipmentPickerViewController.swift
//  XunPengMachine
//
//  设备类型选择器：两层分类标签展示（分类标题 + 流式标签网格）
//

import UIKit

final class EquipmentViewModel: BaseViewModel {

    /// 接口返回的设备分类（已映射为页面使用的模型）
    let categories = Observable.create([EquipmentCategory]())

    /// 拉取设备分类及设备类型
    func loadCategories() {
        loading.onNext(true)
        NetworkManager.shared.request(.equipmentTypes, type: [EquipmentCategoryResponse].self) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.loading.onNext(false)

                switch result {
                case .success(let response):
                    let mapped = response
                        .sorted { $0.sort < $1.sort }
                        .map { category in
                            EquipmentCategory(
                                name: category.category,
                                items: category.items.enumerated().map { index, name in
                                    // 接口只返回名称，页面模型所需的 id 使用分类排序值和下标生成。
                                    EquipmentType(id: "\(category.sort)-\(index)", name: name, icon: "")
                                }
                            )
                        }
                    self.categories.onNext(mapped)
                case .failure(let error):
                    Toast.shared.show(error.errorDescription ?? "加载失败")
                }
            }
        }
    }

    /// /post/meta/categories 的单个分类响应模型。
    /// category -> EquipmentCategory.name，items 中的字符串 -> EquipmentType.name。
    private struct EquipmentCategoryResponse: Codable {
        let category: String
        let sort: Int
        let items: [String]
    }
}

final class EquipmentPickerViewController: BaseViewController {

    private let viewModel = EquipmentViewModel()

    /// 选中回调
    var onPick: ((EquipmentType) -> Void)?

    private var categories: [EquipmentCategory] = []
    private let collectionView: UICollectionView = {
        let layout = LeftAlignedFlowLayout()
        layout.minimumLineSpacing = 10.fit
        layout.minimumInteritemSpacing = 10.fit
        layout.sectionInset = UIEdgeInsets(top: 0, left: 16.fit, bottom: 16.fit, right: 16.fit)
        layout.headerReferenceSize = CGSize(width: UIScreen.main.bounds.width, height: 44.fit)
        let v = UICollectionView(frame: .zero, collectionViewLayout: layout)
        v.backgroundColor = AppColor.bg
        v.alwaysBounceVertical = true
        return v
    }()

    override var navStyle: NavStyle {
        get { .white }
        set { }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "全部机械"
        setupBackButton()
        setupCollectionView()
        bindViewModel()
        loadData()
    }

    // MARK: - Setup
    private func setupCollectionView() {
        view.addSubview(collectionView)
        collectionView.frame = view.bounds
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(EquipTagCell.self, forCellWithReuseIdentifier: EquipTagCell.reuseId)
        collectionView.register(EquipHeader.self,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                withReuseIdentifier: EquipHeader.reuseId)
    }

    private func loadData() {
        viewModel.loadCategories()
    }

    private func bindViewModel() {
        disposables.append(viewModel.categories.subscribe(onNext: { [weak self] categories in
            self?.categories = categories
            self?.collectionView.reloadData()
        }))
    }
}

// MARK: - DataSource & Delegate
extension EquipmentPickerViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        categories.count
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        categories[section].items.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: EquipTagCell.reuseId,
                                                       for: indexPath) as! EquipTagCell
        let item = categories[indexPath.section].items[indexPath.item]
        cell.configure(name: item.name)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind, withReuseIdentifier: EquipHeader.reuseId, for: indexPath) as! EquipHeader
        header.configure(title: categories[indexPath.section].name)
        return header
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let name = categories[indexPath.section].items[indexPath.item].name
        let textW = name.size(font: AppFont.body).width
        let tagW = textW + 28.fit   // 左右各 14.fit padding
        let tagH: CGFloat = 36.fit
        return CGSize(width: tagW, height: tagH)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = categories[indexPath.section].items[indexPath.item]
        Logger.shared.track("pick_equipment", params: ["id": item.id])
        onPick?(item)
        navigationController?.popViewController(animated: true)
    }
}

// MARK: - 分类标题
private final class EquipHeader: UICollectionReusableView {
    static let reuseId = "EquipHeader"
    private let label = UILabel.make("", font: AppFont.bodyM, color: AppColor.textMain)

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(label)
    }
    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        label.frame = CGRect(x: 16.fit, y: 12.fit, width: w - 32.fit, height: 20.fit)
    }

    func configure(title: String) {
        label.text = title
    }
}

// MARK: - 设备标签 Cell
private final class EquipTagCell: UICollectionViewCell {
    static let reuseId = "EquipTagCell"
    private let label = UILabel.make("", font: AppFont.body, color: AppColor.textMain, alignment: .center)

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .white
        contentView.layer.cornerRadius = 6.fit
        contentView.layer.borderWidth = 1
        contentView.layer.borderColor = AppColor.separator.cgColor
        contentView.addSubview(label)
    }
    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        label.frame = contentView.bounds
    }

    override var isSelected: Bool {
        didSet {
            if isSelected {
                contentView.backgroundColor = AppColor.primary
                contentView.layer.borderColor = AppColor.primary.cgColor
                label.textColor = .white
            } else {
                contentView.backgroundColor = .white
                contentView.layer.borderColor = AppColor.separator.cgColor
                label.textColor = AppColor.textMain
            }
        }
    }

    func configure(name: String) {
        label.text = name
    }
}

// MARK: - 左对齐 FlowLayout（标签流式排列，每行从左到右）
private final class LeftAlignedFlowLayout: UICollectionViewFlowLayout {
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let attributes = super.layoutAttributesForElements(in: rect)?.compactMap({ $0.copy() as? UICollectionViewLayoutAttributes }) else {
            return nil
        }
        // 按 section + row 分组，将每行第一个 item 的 leftInset 设为 sectionInset.left
        var xOffset: CGFloat = sectionInset.left
        var currentRow: Int = -1
        for attr in attributes {
            guard attr.representedElementCategory == .cell else { continue }
            if attr.indexPath.row == 0 {
                xOffset = sectionInset.left
                currentRow = 0
            }
            // 检测换行：如果当前 x + width 超出可用宽度，则另起一行
            let maxWidth = collectionView?.bounds.width ?? UIScreen.main.bounds.width
            if xOffset + attr.size.width > maxWidth - sectionInset.right {
                xOffset = sectionInset.left
            }
            attr.frame.origin.x = xOffset
            xOffset += attr.size.width + minimumInteritemSpacing
        }
        return attributes
    }
}
