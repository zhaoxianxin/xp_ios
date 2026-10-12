//
//  MapWrapper.swift
//  XunPengMachine
//
//  地图二次封装：基于高德地图 MAMapKit + AMapLocationKit 实现。
//  对外提供 MapProvider 协议，业务层无需关心具体地图 SDK。
//

import UIKit
import MAMapKit
import AMapFoundationKit
import AMapLocationKit

/// 地图能力抽象
protocol MapProvider: AnyObject {
    /// 把地图挂载到容器视图
    func attach(to view: UIView)
    /// 显示指定坐标，并添加大头针
    func showCoordinate(_ lat: Double, _ lng: Double, title: String)
    /// 开始定位
    func beginLocating()
}

/// 高德地图封装
final class AMapWrapper: NSObject, MapProvider {

    private var mapView: MAMapView?
    private var locationManager: AMapLocationManager?
    /// 当前显示的大头针
    private var currentAnnotation: MAPointAnnotation?

    func attach(to view: UIView) {
        if mapView == nil {
            let map = MAMapView(frame: view.bounds)
            map.showsUserLocation = true
            map.userTrackingMode = .none
            map.delegate = self
            view.addSubview(map)
            mapView = map
        }
        mapView?.frame = view.bounds
        mapView?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }

    func showCoordinate(_ lat: Double, _ lng: Double, title: String) {
        guard let map = mapView else { return }
        let coord = CLLocationCoordinate2D(latitude: lat, longitude: lng)

        // 清除旧大头针
        if let old = currentAnnotation {
            map.removeAnnotation(old)
        }

        let annotation = MAPointAnnotation()
        annotation.coordinate = coord
        annotation.title = title
        map.addAnnotation(annotation)
        currentAnnotation = annotation

        // 设置地图中心和缩放级别（500米范围）
        map.setCenter(coord, animated: false)
        map.setZoomLevel(15, animated: false)
    }

    func beginLocating() {
        if locationManager == nil {
            let mgr = AMapLocationManager()
            mgr.desiredAccuracy = kCLLocationAccuracyBest
            mgr.distanceFilter = 50
            mgr.locatingWithReGeocode = true
            locationManager = mgr
        }
        locationManager?.requestLocation(withReGeocode: true, completionBlock: { [weak self] location, _, _ in
            guard let location = location, let map = self?.mapView else { return }
            map.setCenter(location.coordinate, animated: true)
        })
    }
}

// MARK: - MAMapViewDelegate
extension AMapWrapper: MAMapViewDelegate {
    /// 自定义大头针视图
    func mapView(_ mapView: MAMapView!, viewFor annotation: MAAnnotation!) -> MAAnnotationView! {
        guard let pointAnnotation = annotation as? MAPointAnnotation else { return nil }
        let reuseId = "XunPengPin"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MAPinAnnotationView
        if annotationView == nil {
            annotationView = MAPinAnnotationView(annotation: pointAnnotation, reuseIdentifier: reuseId)
        }
        annotationView?.pinColor = .red
        annotationView?.animatesDrop = true
        annotationView?.canShowCallout = true
        return annotationView
    }
}

/// 地图预览视图：内嵌高德地图
final class MapPreviewView: UIView {

    private let titleLabel = UILabel.make("位置信息", font: AppFont.bodyM, color: AppColor.textMain)
    private let mapHolder = UIView()
    private let provider: MapProvider = AMapWrapper()
    /// 定位箭头按钮
    private let locateBtn = UIButton(type: .custom)

    init(title: String = "位置信息") {
        super.init(frame: .zero)
        titleLabel.text = title
        backgroundColor = .white
        layer.cornerRadius = 8.fit
        clipsToBounds = true

        addSubview(titleLabel)
        addSubview(mapHolder)

        locateBtn.setImage(UIImage(systemName: "location.fill")?.withRenderingMode(.alwaysTemplate), for: .normal)
        locateBtn.tintColor = AppColor.primary
        locateBtn.backgroundColor = .white
        locateBtn.layer.cornerRadius = 4.fit
        locateBtn.layer.shadowColor = UIColor.black.cgColor
        locateBtn.layer.shadowOpacity = 0.2
        locateBtn.layer.shadowOffset = CGSize(width: 0, height: 1)
        locateBtn.layer.shadowRadius = 2
        locateBtn.addTarget(self, action: #selector(locateTapped), for: .touchUpInside)
        mapHolder.addSubview(locateBtn)

        provider.attach(to: mapHolder)
    }
    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        titleLabel.frame = CGRect(x: 12.fit, y: 12.fit,
                                  width: w - 24.fit, height: 20.fit)
        mapHolder.frame = CGRect(x: 12.fit, y: titleLabel.bottom + 8.fit,
                                 width: w - 24.fit,
                                 height: h - titleLabel.bottom - 20.fit)
        let btnS: CGFloat = 32.fit
        locateBtn.frame = CGRect(x: mapHolder.w - btnS - 8.fit,
                                 y: mapHolder.h - btnS - 8.fit,
                                 width: btnS, height: btnS)
    }

    /// 显示坐标
    func show(lat: Double, lng: Double, title: String) {
        provider.showCoordinate(lat, lng, title: title)
    }

    @objc private func locateTapped() {
        provider.beginLocating()
    }
}
