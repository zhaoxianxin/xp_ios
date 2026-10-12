//
//  PNSPrivacyWebViewController.swift
//  ATAuthSceneDemoSwift
//
//  Created by lyz on 2026/1/28.
//  Copyright © 2020-2026. All rights reserved.
//

import UIKit
import WebKit

class PNSPrivacyWebViewController: UIViewController {
    
    // MARK: - Properties

    private let urlString: String
    private let privacyTitle: String
    
    private lazy var webView: WKWebView = {
        let config = WKWebViewConfiguration()
        let wv = WKWebView(frame: .zero, configuration: config)
        wv.navigationDelegate = self
        return wv
    }()
    
    private lazy var progressView: UIProgressView = {
        let pv = UIProgressView(progressViewStyle: .default)
        pv.progressTintColor = .systemOrange
        pv.trackTintColor = .clear
        return pv
    }()
    
    private lazy var errorLabel: UILabel = {
        let label = UILabel()
        label.text = "页面加载失败，请检查网络后重试"
        label.textColor = .systemGray
        label.font = UIFont.systemFont(ofSize: 15)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.isHidden = true
        return label
    }()
    
    private lazy var retryButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("重新加载", for: .normal)
        btn.setTitleColor(.systemOrange, for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        btn.isHidden = true
        btn.addTarget(self, action: #selector(retryTapped), for: .touchUpInside)
        return btn
    }()
    
    private var progressObservation: NSKeyValueObservation?
    
    // MARK: - Init

    init(urlString: String, title: String = "隐私协议") {
        self.urlString = urlString
        self.privacyTitle = title
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadPage()
    }
    
    deinit {
        progressObservation?.invalidate()
    }
    
    // MARK: - UI Setup

    private func setupUI() {
        view.backgroundColor = .systemBackground
        navigationItem.title = privacyTitle
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(backTapped)
        )
        navigationItem.leftBarButtonItem?.tintColor = .systemOrange
        
        [webView, progressView, errorLabel, retryButton].forEach {
            view.addSubview($0)
        }
        
        progressView.pns_makeConstraints { make in
            make.top()
            make.leading()
            make.trailing()
            make.height(equalTo: 2)
        }
        
        webView.pns_makeConstraints { make in
            make.top(equalTo: progressView.bottomAnchor)
            make.leading()
            make.trailing()
            make.bottom()
        }
        
        errorLabel.pns_makeConstraints { make in
            make.centerX()
            make.centerY(offset: -24)
            make.leading(offset: 40)
            make.trailing(offset: -40)
        }
        
        retryButton.pns_makeConstraints { make in
            make.centerX()
            make.top(equalTo: errorLabel.bottomAnchor, offset: 12)
        }
        
        // 监听加载进度
        progressObservation = webView.observe(\.estimatedProgress, options: .new) { [weak self] _, change in
            guard let self = self else { return }
            let progress = Float(change.newValue ?? 0)
            self.progressView.setProgress(progress, animated: true)
            self.progressView.isHidden = progress >= 1.0
        }
    }
    
    // MARK: - Load

    private func loadPage() {
        guard let url = URL(string: urlString) else {
            showError()
            return
        }
        errorLabel.isHidden = true
        retryButton.isHidden = true
        webView.isHidden = false
        progressView.setProgress(0, animated: false)
        progressView.isHidden = false
        webView.load(URLRequest(url: url))
    }
    
    private func showError() {
        webView.isHidden = true
        progressView.isHidden = true
        errorLabel.isHidden = false
        retryButton.isHidden = false
    }
    
    // MARK: - Actions

    @objc private func backTapped() {
        if webView.canGoBack {
            webView.goBack()
        } else {
            // 以 modal 方式弹出，点击返回时 dismiss
            dismiss(animated: true)
        }
    }
    
    @objc private func retryTapped() {
        loadPage()
    }
}

// MARK: - WKNavigationDelegate
extension PNSPrivacyWebViewController: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        progressView.isHidden = true
        // 更新标题为页面实际标题（如有）
        if let pageTitle = webView.title, !pageTitle.isEmpty {
            navigationItem.title = pageTitle
        }
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        showError()
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        showError()
    }
}
