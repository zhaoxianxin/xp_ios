//
//  Observable.swift
//  XunPengMachine
//
//  轻量响应式封装，模拟 RxSwift 的 Observable 用法（closures 实现，无三方依赖）
//  便于后续平滑迁移至 RxSwift
//

import Foundation

/// 事件类型
enum Event<Element> {
    case next(Element)
    case error(Error)
    case completed
}

/// 销毁时机
enum DisposeBag {
    case immediate
}

/// 一次性订阅句柄，可用于取消订阅
final class Disposable {
    fileprivate var action: (() -> Void)?
    init(_ action: @escaping () -> Void) { self.action = action }
    func dispose() { action?(); action = nil }
}

/// 轻量 Observable，支持值变换 / 过滤 / 绑定
class Observable<Element> {

    private let handler: (@escaping (Event<Element>) -> Void) -> Disposable
    fileprivate init(_ handler: @escaping (@escaping (Event<Element>) -> Void) -> Disposable) {
        self.handler = handler
    }

    /// 创建一个可手动赋值、可被订阅的主题（类似 BehaviorSubject / PublishRelay）
    static func create(_ value: Element) -> Subject<Element> { Subject(value) }

    /// 订阅
    @discardableResult
    func subscribe(onNext: ((Element) -> Void)? = nil,
                   onError: ((Error) -> Void)? = nil,
                   onCompleted: (() -> Void)? = nil) -> Disposable {
        handler { event in
            switch event {
            case .next(let v): onNext?(v)
            case .error(let e): onError?(e)
            case .completed:   onCompleted?()
            }
        }
    }

    /// map 变换
    func map<O>(_ transform: @escaping (Element) -> O) -> Observable<O> {
        Observable<O> { observer in
            self.subscribe(onNext: { value in observer(.next(transform(value))) },
                           onError: { error in observer(.error(error)) },
                           onCompleted: { observer(.completed) })
        }
    }

    /// filter 过滤
    func filter(_ predicate: @escaping (Element) -> Bool) -> Observable<Element> {
        Observable<Element> { observer in
            self.subscribe(onNext: { value in if predicate(value) { observer(.next(value)) } },
                           onError: { error in observer(.error(error)) },
                           onCompleted: { observer(.completed) })
        }
    }
}

/// 主题：持有最新值，新订阅者会立即收到当前值（类似 BehaviorSubject）
final class Subject<Element>: Observable<Element> {
    private var current: Element
    private var observers: [UUID: (Event<Element>) -> Void] = [:]
    private var lock = NSLock()

    init(_ value: Element) { self.current = value; super.init({ _ in Disposable {} }) }

    /// 推送新值
    func onNext(_ value: Element) {
        lock.lock(); current = value; let obs = observers; lock.unlock()
        obs.values.forEach { $0(.next(value)) }
    }

    var value: Element { current }

    override func subscribe(onNext: ((Element) -> Void)? = nil,
                            onError: ((Error) -> Void)? = nil,
                            onCompleted: (() -> Void)? = nil) -> Disposable {
        let id = UUID()
        let observer: (Event<Element>) -> Void = { event in
            switch event {
            case .next(let v): onNext?(v)
            case .error(let e): onError?(e)
            case .completed:   onCompleted?()
            }
        }
        lock.lock(); observers[id] = observer; let cur = current; lock.unlock()
        observer(.next(cur)) // 立即回放当前值
        let bag = self
        return Disposable { [weak bag] in
            bag?.lock.lock()
            bag?.observers.removeValue(forKey: id)
            bag?.lock.unlock()
        }
    }
}
