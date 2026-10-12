//
//  CarOwnerCertificationModels.swift
//  XunPengMachine
//

import Foundation

enum OwnerCertificationStep: Int, CaseIterable {
    case identity
    case driverLicense
    case vehicleLicense
    case vehicle

    var title: String {
        switch self {
        case .identity: return "身份认证"
        case .driverLicense: return "驾驶证认证"
        case .vehicleLicense: return "行驶证认证"
        case .vehicle: return "车辆认证"
        }
    }

    var uploadTitles: (String, String) {
        switch self {
        case .identity: return ("点击上传人像面", "点击上传国徽面")
        case .driverLicense: return ("上传驾驶证人像面", "上传驾驶证副页")
        case .vehicleLicense: return ("上传行驶证主页", "上传行驶证副页")
        case .vehicle: return ("上传车头车牌照片", "上传车尾车牌照片")
        }
    }

    var imageParameterKeys: (String, String) {
        switch self {
        case .identity: return ("portraitImgUrl", "emblemImgUrl")
        case .driverLicense: return ("portraitImageUrl", "vicePageImageUrl")
        case .vehicleLicense: return ("homePageImageUrl", "vicePageImageUrl")
        case .vehicle: return ("frontImageUrl", "rearImageUrl")
        }
    }
}

struct CertificationDisplayRow {
    let title: String
    let value: String
    var showsArrow = false
}

struct CertificationDisplayData {
    let imageUrls: [String]
    let rows: [CertificationDisplayRow]
}

struct IdentityCertificationResult: Codable {
    let verifyStatus: Int
    let realName: String?
    let idCardNo: String?
    let ethnicity: String?
    let birthday: String?
    let address: String?
    let issuingAuthority: String?
    let idStartDate: String?
    let idEndDate: String?
    let portraitImgUrl: String?
    let emblemImgUrl: String?
    let verifyTime: String?

    var displayData: CertificationDisplayData? {
        guard verifyStatus != 0,
              let realName, !realName.isEmpty,
              let idCardNo, !idCardNo.isEmpty else {
            return nil
        }
        return CertificationDisplayData(imageUrls: [portraitImgUrl ?? "", emblemImgUrl ?? ""], rows: [
            CertificationDisplayRow(title: "真实姓名", value: realName),
            CertificationDisplayRow(title: "身份证号", value: idCardNo),
            CertificationDisplayRow(title: "证件有效期", value: idEndDate ?? "")
        ])
    }
}

struct DriverLicenseCertificationResult: Codable {
    let verifyStatus: Int
    let licenseNo: String?
    let realName: String?
    let vehicleType: String?
    let firstIssueDate: String?
    let validStartDate: String?
    let validEndDate: String?
    let imgUrl: String?
    let auditTime: String?
    let rejectReason: String?

    var displayData: CertificationDisplayData? {
        guard verifyStatus != 0,
              let realName, !realName.isEmpty,
              let licenseNo, !licenseNo.isEmpty else {
            return nil
        }
        return CertificationDisplayData(imageUrls: [imgUrl ?? ""], rows: [
            CertificationDisplayRow(title: "真实姓名", value: realName),
            CertificationDisplayRow(title: "驾驶证号", value: licenseNo),
            CertificationDisplayRow(title: "准驾车型", value: vehicleType ?? ""),
            CertificationDisplayRow(title: "有效起始日期", value: validStartDate ?? ""),
            CertificationDisplayRow(title: "有效结束日期", value: validEndDate ?? "")
        ])
    }
}

struct VehicleLicenseCertificationResult: Codable {
    let homePageImageUrl: String
    let vicePageImageUrl: String
    let plateNumber: String
    let vehicleType: String
    let ownerName: String
    let brandModel: String
    let vin: String
    let engineNumber: String
    let registerDate: String
    let issueDate: String
    let annualInspectionValidUntil: String

    var displayData: CertificationDisplayData {
        CertificationDisplayData(imageUrls: [homePageImageUrl, vicePageImageUrl], rows: [
            CertificationDisplayRow(title: "车牌号", value: plateNumber),
            CertificationDisplayRow(title: "车辆类型", value: vehicleType),
            CertificationDisplayRow(title: "所有人", value: ownerName),
            CertificationDisplayRow(title: "品牌型号", value: brandModel),
            CertificationDisplayRow(title: "车辆识别代码", value: vin),
            CertificationDisplayRow(title: "发动机号", value: engineNumber),
            CertificationDisplayRow(title: "注册日期", value: registerDate),
            CertificationDisplayRow(title: "发证日期", value: issueDate),
            CertificationDisplayRow(title: "年审有效期至", value: annualInspectionValidUntil,
                                    showsArrow: true)
        ])
    }
}

struct VehicleCertificationResult: Codable {
    let frontImageUrl: String
    let rearImageUrl: String
    let plateNumber: String

    var displayData: CertificationDisplayData {
        CertificationDisplayData(imageUrls: [frontImageUrl, rearImageUrl], rows: [
            CertificationDisplayRow(title: "车牌号", value: plateNumber)
        ])
    }
}
