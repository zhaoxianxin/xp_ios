//
//  PNSBaseViewController.swift
//  ATAuthSceneDemoSwift
//
//  Created by lyz on 2026/1/28.
//  Copyright © 2020-2026. All rights reserved.
//

import UIKit

class PNSBaseViewController: UIViewController {
    
    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        initSubviews()
        setLayoutSubviews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    // MARK: - Status Bar

    override var prefersStatusBarHidden: Bool {
        return false
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }
    
    func shouldSetStatusBarStyleLight() -> Bool {
        return true
    }
    
    func shouldHiddenStatusBar() -> Bool {
        return false
    }
    
    // MARK: - UI Setup
    
    /**
     *  负责初始化和设置controller里面的view，也就是self.view的subView。目的在于分类代码，所以与view初始化的相关代码都写在这里。
     *
     *  @warning initSubviews只负责subviews的init，不负责布局。布局相关的代码应该写在 setLayoutSubviews
     */
    func initSubviews() {
        // 子类重写
    }
    
    /**
     *  负责布局controller里面的view，也就是self.view的subView。目的在于分类代码，所以与view初始化的相关代码都写在这里。
     *
     *  @warning setLayoutSubviews只负责布局subviews的约束
     */
    func setLayoutSubviews() {
        // 子类重写
    }
    
    // MARK: - Screen Orientation

    /// 是否支持设备自动旋转
    override var shouldAutorotate: Bool {
        return true
    }
    
    /// 支持竖屏显示
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .allButUpsideDown
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        print("[\(type(of: self)), \(navigationItem.title ?? title ?? "")] === 已被释放")
    }
}