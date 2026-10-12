//
//  BaseViewModel.swift
//  XunPengMachine
//
//  MVVM ViewModel 基类
//

import UIKit

class BaseViewModel {
    /// 子类持有的订阅，避免手动管理 dispose（页面销毁时统一释放可扩展）
    var disposables: [Disposable] = []

    /// 默认 loading 事件（ViewModel -> View 通信）
    let loading = Observable.create(false)

    init() {}

    deinit { disposables.forEach { $0.dispose() } }
}
