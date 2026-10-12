//
//  PNSLayout.swift
//  ATAuthSceneDemoSwift
//
//  Created by lyz on 2026/1/28.
//  Copyright © 2020-2026. All rights reserved.
//

import UIKit
import ObjectiveC

/// 自定义布局管理模块
/// 提供轻量级 Auto Layout 链式 API
class PNSLayout {
    
    // MARK: - Types
    
    enum EdgeTarget {
        case superview
        case safeArea
    }
    
    /// 布局约束构建器
    class ConstraintMaker {
        private let view: UIView
        private var constraints: [NSLayoutConstraint] = []
        
        init(view: UIView) {
            self.view = view
            view.translatesAutoresizingMaskIntoConstraints = false
        }
        
        // MARK: - Edge Constraints
        
        /// 设置顶部约束
        @discardableResult
        func top(equalTo anchor: NSLayoutYAxisAnchor, offset: CGFloat = 0) -> ConstraintMaker {
            append(view.topAnchor.constraint(equalTo: anchor, constant: offset))
            return self
        }
        
        /// 设置顶部约束（默认相对父视图安全区）
        @discardableResult
        func top(offset: CGFloat = 0, target: EdgeTarget = .safeArea) -> ConstraintMaker {
            guard let superview = view.superview else {
                logMissingSuperview(function: #function)
                return self
            }
            let anchor = (target == .safeArea) ? superview.safeAreaLayoutGuide.topAnchor : superview.topAnchor
            append(view.topAnchor.constraint(equalTo: anchor, constant: offset))
            return self
        }
        
        /// 设置底部约束
        @discardableResult
        func bottom(equalTo anchor: NSLayoutYAxisAnchor, offset: CGFloat = 0) -> ConstraintMaker {
            append(view.bottomAnchor.constraint(equalTo: anchor, constant: offset))
            return self
        }
        
        /// 设置底部约束（默认相对父视图安全区）
        @discardableResult
        func bottom(offset: CGFloat = 0, target: EdgeTarget = .safeArea) -> ConstraintMaker {
            guard let superview = view.superview else {
                logMissingSuperview(function: #function)
                return self
            }
            let anchor = (target == .safeArea) ? superview.safeAreaLayoutGuide.bottomAnchor : superview.bottomAnchor
            append(view.bottomAnchor.constraint(equalTo: anchor, constant: offset))
            return self
        }
        
        /// 设置左侧约束
        @discardableResult
        func leading(equalTo anchor: NSLayoutXAxisAnchor, offset: CGFloat = 0) -> ConstraintMaker {
            append(view.leadingAnchor.constraint(equalTo: anchor, constant: offset))
            return self
        }
        
        /// 设置左侧约束（默认相对父视图安全区）
        @discardableResult
        func leading(offset: CGFloat = 0, target: EdgeTarget = .safeArea) -> ConstraintMaker {
            guard let superview = view.superview else {
                logMissingSuperview(function: #function)
                return self
            }
            let anchor = (target == .safeArea) ? superview.safeAreaLayoutGuide.leadingAnchor : superview.leadingAnchor
            append(view.leadingAnchor.constraint(equalTo: anchor, constant: offset))
            return self
        }
        
        /// 设置右侧约束
        @discardableResult
        func trailing(equalTo anchor: NSLayoutXAxisAnchor, offset: CGFloat = 0) -> ConstraintMaker {
            append(view.trailingAnchor.constraint(equalTo: anchor, constant: offset))
            return self
        }
        
        /// 设置右侧约束（默认相对父视图安全区）
        @discardableResult
        func trailing(offset: CGFloat = 0, target: EdgeTarget = .safeArea) -> ConstraintMaker {
            guard let superview = view.superview else {
                logMissingSuperview(function: #function)
                return self
            }
            let anchor = (target == .safeArea) ? superview.safeAreaLayoutGuide.trailingAnchor : superview.trailingAnchor
            append(view.trailingAnchor.constraint(equalTo: anchor, constant: offset))
            return self
        }
        
        /// 设置四边约束
        @discardableResult
        func edges(insets: UIEdgeInsets = .zero, target: EdgeTarget = .safeArea) -> ConstraintMaker {
            top(offset: insets.top, target: target)
            leading(offset: insets.left, target: target)
            trailing(offset: -insets.right, target: target)
            bottom(offset: -insets.bottom, target: target)
            return self
        }
        
        // MARK: - Size Constraints
        
        /// 设置宽度约束
        @discardableResult
        func width(equalTo constant: CGFloat, priority: UILayoutPriority = .required) -> ConstraintMaker {
            append(view.widthAnchor.constraint(equalToConstant: constant), priority: priority)
            return self
        }
        
        /// 设置宽度约束
        @discardableResult
        func width(equalTo anchor: NSLayoutDimension, multiplier: CGFloat = 1, constant: CGFloat = 0, priority: UILayoutPriority = .required) -> ConstraintMaker {
            append(view.widthAnchor.constraint(equalTo: anchor, multiplier: multiplier, constant: constant), priority: priority)
            return self
        }
        
        /// 设置最小宽度约束
        @discardableResult
        func width(greaterThanOrEqualTo constant: CGFloat, priority: UILayoutPriority = .required) -> ConstraintMaker {
            append(view.widthAnchor.constraint(greaterThanOrEqualToConstant: constant), priority: priority)
            return self
        }
        
        /// 设置最大宽度约束
        @discardableResult
        func width(lessThanOrEqualTo constant: CGFloat, priority: UILayoutPriority = .required) -> ConstraintMaker {
            append(view.widthAnchor.constraint(lessThanOrEqualToConstant: constant), priority: priority)
            return self
        }
        
        /// 设置高度约束
        @discardableResult
        func height(equalTo constant: CGFloat, priority: UILayoutPriority = .required) -> ConstraintMaker {
            append(view.heightAnchor.constraint(equalToConstant: constant), priority: priority)
            return self
        }
        
        /// 设置高度约束
        @discardableResult
        func height(equalTo anchor: NSLayoutDimension, multiplier: CGFloat = 1, constant: CGFloat = 0, priority: UILayoutPriority = .required) -> ConstraintMaker {
            append(view.heightAnchor.constraint(equalTo: anchor, multiplier: multiplier, constant: constant), priority: priority)
            return self
        }
        
        /// 设置最小高度约束
        @discardableResult
        func height(greaterThanOrEqualTo constant: CGFloat, priority: UILayoutPriority = .required) -> ConstraintMaker {
            append(view.heightAnchor.constraint(greaterThanOrEqualToConstant: constant), priority: priority)
            return self
        }
        
        /// 设置最大高度约束
        @discardableResult
        func height(lessThanOrEqualTo constant: CGFloat, priority: UILayoutPriority = .required) -> ConstraintMaker {
            append(view.heightAnchor.constraint(lessThanOrEqualToConstant: constant), priority: priority)
            return self
        }
        
        // MARK: - Center Constraints
        
        /// 设置中心 X 约束
        @discardableResult
        func centerX(equalTo anchor: NSLayoutXAxisAnchor, offset: CGFloat = 0) -> ConstraintMaker {
            append(view.centerXAnchor.constraint(equalTo: anchor, constant: offset))
            return self
        }
        
        /// 设置中心 X 约束（相对父视图）
        @discardableResult
        func centerX(offset: CGFloat = 0) -> ConstraintMaker {
            guard let anchor = view.superview?.centerXAnchor else {
                logMissingSuperview(function: #function)
                return self
            }
            append(view.centerXAnchor.constraint(equalTo: anchor, constant: offset))
            return self
        }
        
        /// 设置中心 Y 约束
        @discardableResult
        func centerY(equalTo anchor: NSLayoutYAxisAnchor, offset: CGFloat = 0) -> ConstraintMaker {
            append(view.centerYAnchor.constraint(equalTo: anchor, constant: offset))
            return self
        }
        
        /// 设置中心 Y 约束（相对父视图）
        @discardableResult
        func centerY(offset: CGFloat = 0) -> ConstraintMaker {
            guard let anchor = view.superview?.centerYAnchor else {
                logMissingSuperview(function: #function)
                return self
            }
            append(view.centerYAnchor.constraint(equalTo: anchor, constant: offset))
            return self
        }
        
        /// 设置中心点约束（相对父视图）
        @discardableResult
        func center(offset: CGPoint = .zero) -> ConstraintMaker {
            centerX(offset: offset.x)
            centerY(offset: offset.y)
            return self
        }
        
        // MARK: - Apply Constraints
        
        /// 激活所有约束
        @discardableResult
        func activate() -> [NSLayoutConstraint] {
            guard !constraints.isEmpty else {
                PNSLayout.log("No constraints created for \(PNSLayout.viewDescription(view)).")
                return []
            }
            NSLayoutConstraint.activate(constraints)
            return constraints
        }
        
        private func append(_ constraint: NSLayoutConstraint, priority: UILayoutPriority = .required) {
            constraint.priority = priority
            constraints.append(constraint)
        }
        
        private func logMissingSuperview(function: String) {
            PNSLayout.log("\(function) ignored because \(PNSLayout.viewDescription(view)) has no superview. Add it to a superview before setting parent-relative constraints.")
        }
    }
    
    // MARK: - Constraint Storage
    
    private static var storedConstraintsKey: UInt8 = 0
    
    private static func storedConstraints(for view: UIView) -> [NSLayoutConstraint] {
        return (objc_getAssociatedObject(view, &storedConstraintsKey) as? [NSLayoutConstraint]) ?? []
    }
    
    private static func setStoredConstraints(_ constraints: [NSLayoutConstraint], for view: UIView) {
        objc_setAssociatedObject(view, &storedConstraintsKey, constraints, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    /// 为视图创建布局约束
    /// - Parameters:
    ///   - view: 需要布局的视图
    ///   - closure: 布局配置闭包
    static func makeConstraints(for view: UIView, _ closure: (ConstraintMaker) -> Void) {
        warnIfNeededForDuplicateConstraints(on: view)
        let maker = ConstraintMaker(view: view)
        closure(maker)
        let newConstraints = maker.activate()
        guard !newConstraints.isEmpty else { return }
        setStoredConstraints(storedConstraints(for: view) + newConstraints, for: view)
    }
    
    /// 移除当前模块为视图创建过的约束后重新创建
    static func remakeConstraints(for view: UIView, _ closure: (ConstraintMaker) -> Void) {
        removeConstraints(for: view)
        makeConstraints(for: view, closure)
    }
    
    /// 移除当前模块为视图创建过的约束
    static func removeConstraints(for view: UIView) {
        let constraints = storedConstraints(for: view)
        guard !constraints.isEmpty else { return }
        NSLayoutConstraint.deactivate(constraints)
        setStoredConstraints([], for: view)
    }
    
    private static func warnIfNeededForDuplicateConstraints(on view: UIView) {
        guard !storedConstraints(for: view).isEmpty else { return }
        log("\(viewDescription(view)) already has constraints created by pns_makeConstraints. Use pns_remakeConstraints when replacing constraints.")
    }
    
    fileprivate static func viewDescription(_ view: UIView) -> String {
        let typeName = String(describing: type(of: view))
        let address = Unmanaged.passUnretained(view).toOpaque()
        return "<\(typeName): \(address)>"
    }
    
    fileprivate static func log(_ message: String) {
        #if DEBUG
        print("[PNSLayout] \(message)")
        #endif
    }
}

// MARK: - UIView Extension
extension UIView {
    
    /// 便捷方法：使用 PNSLayout 添加约束
    func pns_makeConstraints(_ closure: (PNSLayout.ConstraintMaker) -> Void) {
        PNSLayout.makeConstraints(for: self, closure)
    }
    
    /// 便捷方法：移除当前模块创建的旧约束后重新添加约束
    func pns_remakeConstraints(_ closure: (PNSLayout.ConstraintMaker) -> Void) {
        PNSLayout.remakeConstraints(for: self, closure)
    }
    
    /// 移除当前模块创建过的约束
    func pns_removeConstraints() {
        PNSLayout.removeConstraints(for: self)
    }
}
