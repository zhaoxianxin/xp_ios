//
//  ImagePickerManager.swift
//  XunPengMachine
//
//  图片选择器封装：iOS14+ 使用 PHPickerViewController，低版本回退 UIImagePickerController
//  权限文案由调用方在 Info.plist 配置
//

import UIKit
import PhotosUI

final class ImagePickerManager: NSObject {

    static let shared = ImagePickerManager()
    private override init() { super.init() }

    private weak var presentingVC: UIViewController?
    private var completion: (([UIImage]) -> Void)?

    /// 弹出图片选择器
    /// - Parameters:
    ///   - vc: 承载弹出的控制器
    ///   - maxCount: 最多可选数量，默认 9
    ///   - completion: 选择结果回调（取消时返回空数组）
    func pick(from vc: UIViewController, maxCount: Int = 9,
              completion: @escaping ([UIImage]) -> Void) {
        self.presentingVC = vc
        self.completion = completion

        if #available(iOS 14, *) {
            var config = PHPickerConfiguration()
            config.selectionLimit = maxCount
            config.filter = .images
            let picker = PHPickerViewController(configuration: config)
            picker.delegate = self
            vc.present(picker, animated: true)
        } else {
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.allowsEditing = false
            picker.delegate = self
            vc.present(picker, animated: true)
        }
    }
}

// MARK: - iOS14+ PHPicker
@available(iOS 14, *)
extension ImagePickerManager: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)

        guard !results.isEmpty else {
            self.completion?([])
            self.completion = nil
            return
        }

        let group = DispatchGroup()
        let lock = NSLock()
        var images: [UIImage] = []

        for result in results {
            group.enter()
            if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                result.itemProvider.loadObject(ofClass: UIImage.self) { obj, _ in
                    if let img = obj as? UIImage {
                        lock.lock()
                        images.append(img)
                        lock.unlock()
                    }
                    group.leave()
                }
            } else {
                group.leave()
            }
        }

        group.notify(queue: .main) { [weak self] in
            self?.completion?(images)
            self?.completion = nil
        }
    }
}

// MARK: - iOS13 回退
extension ImagePickerManager: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true)
        let img = info[.originalImage] as? UIImage
        self.completion?(img.map { [$0] } ?? [])
        self.completion = nil
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
        self.completion?([])
        self.completion = nil
    }
}
