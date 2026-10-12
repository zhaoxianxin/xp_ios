//
//  MyPublishedViewController.swift
//  XunPengMachine
//
//  我的发布：活源与招聘统一分栏容器
//

import UIKit

final class MyPublishedViewController: BaseViewController {

    enum Tab {
        case jobs
        case recruitments
    }

    private let initialTab: Tab
    private var selectedTab: Tab

    private let tabBar = UIView()
    private let jobsButton = UIButton(type: .system)
    private let recruitmentsButton = UIButton(type: .system)
    private let indicator = UIView()
    private let bottomLine = UIView()
    private let contentContainer = UIView()

    private lazy var jobsController: BossJobListViewController = {
        let controller = BossJobListViewController()
        controller.isEmbeddedInPublishedPage = true
        return controller
    }()

    private lazy var recruitmentsController: BossDriverListViewController = {
        let controller = BossDriverListViewController()
        controller.isEmbeddedInPublishedPage = true
        return controller
    }()

    init(initialTab: Tab = .jobs) {
        self.initialTab = initialTab
        self.selectedTab = initialTab
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        initialTab = .jobs
        selectedTab = .jobs
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "我的发布"
        setupBackButton()
        setupUI()
        show(initialTab, animated: false)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let tabHeight: CGFloat = 50
        tabBar.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: tabHeight)
        let buttonWidth = tabBar.bounds.width / 2
        jobsButton.frame = CGRect(x: 0, y: 0, width: buttonWidth, height: tabHeight - 2)
        recruitmentsButton.frame = CGRect(x: buttonWidth, y: 0,
                                           width: buttonWidth, height: tabHeight - 2)
        bottomLine.frame = CGRect(x: 0, y: tabHeight - 0.5,
                                  width: tabBar.bounds.width, height: 0.5)
        updateIndicatorFrame(animated: false)

        contentContainer.frame = CGRect(x: 0, y: tabHeight,
                                        width: view.bounds.width,
                                        height: max(0, view.bounds.height - tabHeight))
        children.forEach { $0.view.frame = contentContainer.bounds }
    }

    private func setupUI() {
        view.backgroundColor = AppColor.bg
        tabBar.backgroundColor = .white
        contentContainer.backgroundColor = AppColor.bg
        view.addSubview(tabBar)
        view.addSubview(contentContainer)

        configureTabButton(jobsButton, title: "发布的活源", action: #selector(jobsTapped))
        configureTabButton(recruitmentsButton, title: "发布的招聘",
                           action: #selector(recruitmentsTapped))
        tabBar.addSubview(jobsButton)
        tabBar.addSubview(recruitmentsButton)

        indicator.backgroundColor = AppColor.primary
        indicator.layer.cornerRadius = 1
        tabBar.addSubview(indicator)

        bottomLine.backgroundColor = AppColor.separator
        tabBar.addSubview(bottomLine)
    }

    private func configureTabButton(_ button: UIButton, title: String, action: Selector) {
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = AppFont.body
        button.addTarget(self, action: action, for: .touchUpInside)
    }

    private func show(_ tab: Tab, animated: Bool) {
        selectedTab = tab
        let controller: UIViewController = tab == .jobs ? jobsController : recruitmentsController

        if controller.parent == nil {
            addChild(controller)
            controller.view.frame = contentContainer.bounds
            contentContainer.addSubview(controller.view)
            controller.didMove(toParent: self)
        }

        children.forEach { $0.view.isHidden = $0 !== controller }
        contentContainer.bringSubviewToFront(controller.view)
        updateSelectionStyle()
        updateIndicatorFrame(animated: animated)
        Logger.shared.track("my_published_tab", params: [
            "tab": tab == .jobs ? "jobs" : "recruitments"
        ])
    }

    private func updateSelectionStyle() {
        jobsButton.setTitleColor(selectedTab == .jobs ? AppColor.primary : AppColor.textMain,
                                 for: .normal)
        recruitmentsButton.setTitleColor(
            selectedTab == .recruitments ? AppColor.primary : AppColor.textMain,
            for: .normal
        )
    }

    private func updateIndicatorFrame(animated: Bool) {
        let buttonWidth = tabBar.bounds.width / 2
        let indicatorWidth: CGFloat = 72.fit
        let selectedCenterX = selectedTab == .jobs ? buttonWidth / 2 : buttonWidth * 1.5
        let frame = CGRect(x: selectedCenterX - indicatorWidth / 2,
                           y: tabBar.bounds.height - 2,
                           width: indicatorWidth,
                           height: 2)
        guard animated else {
            indicator.frame = frame
            return
        }
        UIView.animate(withDuration: 0.2) { self.indicator.frame = frame }
    }

    @objc private func jobsTapped() {
        guard selectedTab != .jobs else { return }
        show(.jobs, animated: true)
    }

    @objc private func recruitmentsTapped() {
        guard selectedTab != .recruitments else { return }
        show(.recruitments, animated: true)
    }
}
