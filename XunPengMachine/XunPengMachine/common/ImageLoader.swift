//
//  ImageLoader.swift
//  XunPengMachine
//
//  轻量图片下载+内存/磁盘缓存（Kingfisher 风格 API，无三方依赖）
//

import UIKit

final class ImageLoader {
    static let shared = ImageLoader()

    private let memoryCache = NSCache<NSString, UIImage>()
    private let session = URLSession.shared
    private let ioQueue = DispatchQueue(label: "com.xunpeng.imageloader.io")
    private var inflight: [String: [(UIImage?) -> Void]] = [:]
    private let lock = NSLock()

    private init() {
        memoryCache.countLimit = 200
    }

    private var cacheDir: URL {
        let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("XPImageCache", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    /// 加载网络/本地图，urlStr 为空则使用占位
    func load(_ urlStr: String?, into imageView: UIImageView, placeholder: UIImage? = nil) {
        guard let urlStr = urlStr, !urlStr.isEmpty, let url = URL(string: urlStr) else {
            imageView.image = placeholder
            return
        }
        imageView.image = placeholder
        // 内存命中
        if let img = memoryCache.object(forKey: urlStr as NSString) {
            imageView.image = img
            return
        }
        // 磁盘命中
        ioQueue.async { [weak self] in
            guard let self = self else { return }
            let path = self.cacheDir.appendingPathComponent(urlStr.md5)
            if let data = try? Data(contentsOf: path), let img = UIImage(data: data) {
                self.memoryCache.setObject(img, forKey: urlStr as NSString)
                DispatchQueue.main.async { imageView.image = img }
                return
            }
            self.download(urlStr, url, path, imageView)
        }
    }

    private func download(_ urlStr: String, _ url: URL, _ path: URL, _ imageView: UIImageView) {
        // 去重相同请求
        lock.lock()
        if inflight[urlStr] != nil {
            inflight[urlStr]?.append { img in DispatchQueue.main.async { imageView.image = img } }
            lock.unlock()
            return
        }
        inflight[urlStr] = [{ img in DispatchQueue.main.async { imageView.image = img } }]
        lock.unlock()

        session.dataTask(with: url) { [weak self] data, _, _ in
            guard let self = self, let data = data, let img = UIImage(data: data) else {
                self?.complete(urlStr, nil); return
            }
            self.memoryCache.setObject(img, forKey: urlStr as NSString)
            try? data.write(to: path)
            self.complete(urlStr, img)
        }.resume()
    }

    private func complete(_ urlStr: String, _ img: UIImage?) {
        lock.lock()
        let cbs = inflight.removeValue(forKey: urlStr) ?? []
        lock.unlock()
        cbs.forEach { $0(img) }
    }
}

private extension String {
    var md5: String {
        var hash = 0
        for char in unicodeScalars { hash = (hash &<< 5) &- hash &+ Int(char.value) }
        return String(format: "%x", abs(hash))
    }
}
