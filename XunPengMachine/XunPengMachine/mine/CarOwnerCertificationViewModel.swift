//
//  CarOwnerCertificationViewModel.swift
//  XunPengMachine
//

import Foundation

final class CarOwnerCertificationViewModel: BaseViewModel {

    func loadResult(for step: OwnerCertificationStep,
                    completion: @escaping (CertificationDisplayData?) -> Void) {
        loading.onNext(true)
        switch step {
        case .identity:
            load(.identityCertification, type: IdentityCertificationResult.self,
                 transform: { $0.displayData }, completion: completion)
        case .driverLicense:
            load(.driverLicenseCertification, type: DriverLicenseCertificationResult.self,
                 transform: { $0.displayData }, completion: completion)
        case .vehicleLicense:
            load(.vehicleLicenseCertification, type: [VehicleLicenseCertificationResult].self,
                 transform: { $0.first?.displayData }, completion: completion)
        case .vehicle:
            load(.vehicleCertification, type: VehicleCertificationResult.self,
                 transform: { $0.displayData }, completion: completion)
        }
    }

    func submit(step: OwnerCertificationStep, imageUrls: [String],
                completion: @escaping (Bool) -> Void) {
        guard imageUrls.count == 2 else {
            completion(false)
            return
        }
        let keys = step.imageParameterKeys
        let params: [String: Any] = [keys.0: imageUrls[0], keys.1: imageUrls[1]]
        let router: APIRouter
        switch step {
        case .identity: router = .submitIdentityCertification(params: params)
        case .driverLicense: router = .submitDriverLicenseCertification(params: params)
        case .vehicleLicense: router = .submitVehicleLicenseCertification(params: params)
        case .vehicle: router = .submitVehicleCertification(params: params)
        }

        loading.onNext(true)
        NetworkManager.shared.request(router, type: NoData.self) { [weak self] result in
            DispatchQueue.main.async {
                defer { self?.loading.onNext(false) }
                completion((try? result.get()) != nil)
            }
        }
    }

    private func load<T: Codable>(_ router: APIRouter, type: T.Type,
                                  transform: @escaping (T) -> CertificationDisplayData?,
                                  completion: @escaping (CertificationDisplayData?) -> Void) {
        NetworkManager.shared.request(router, type: type) { [weak self] result in
            DispatchQueue.main.async {
                defer { self?.loading.onNext(false) }
                switch result {
                case .success(let model): completion(transform(model))
                case .failure: completion(nil)
                }
            }
        }
    }
}
