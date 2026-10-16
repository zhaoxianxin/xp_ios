//
//  APIRouter.swift
//  XunPengMachine
//
//  接口路由统一定义
//

import Foundation

/// HTTP 方法
enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

/// 接口路由
enum APIRouter {
    case login(phone: String, code: String, identityType: Int)
    case fastLogin(token: String, identityType: Int)
    case sendCode(phone: String)
    case refreshToken(refreshToken: String)
    case jobList(page: Int, city: String?)
    case jobDetail(id: Int64)
    case carList(page: Int, city: String?)
    case carDetail(id: String)
    case driverList(page: Int, city: String?)
    case driverDetail(id: String)
    case mineProfile
    case switchIdentity(identityType: Int)
    case myJobs(page: Int)
    case myDrivers(page: Int)
    case systemMessages(lastId: Int)
    /// 临时接口：开通或重新开通招聘工作提醒，正式地址确定后替换 path 即可。
    case saveRecruitmentReminder(params: [String: Any])
    case publishJob(params: [String: Any])
    case updateJob(id: Int64, params: [String: Any])
    case deleteJob(id: Int64)
    case publishCar(params: [String: Any])
    case publishDriver(params: [String: Any])
    case updateDriver(id: Int64, params: [String: Any])
    case deleteDriver(id: Int64)
    case cities
    case equipmentTypes
    case feedback(content: String)
    case identityCertification
    case submitIdentityCertification(params: [String: Any])
    case driverLicenseCertification
    case submitDriverLicenseCertification(params: [String: Any])
    case vehicleLicenseCertification
    case submitVehicleLicenseCertification(params: [String: Any])
    case vehicleCertification
    case submitVehicleCertification(params: [String: Any])

    /// 路径
    var path: String {
        switch self {
        case .login:            return "/member/auth/sms-login"
        case .fastLogin:        return "/member/auth/one-click-login"
        case .sendCode:         return "/member/auth/send-sms-code"
        case .refreshToken(let refreshToken):   return "/member/auth/refresh-token?refreshToken=\(refreshToken)"
        case .jobList:          return "/post/job/page"
        case .jobDetail(let id): return "/post/job/get?id=\(id)"
        case .carList:          return "/post/equipment/page"
        case .carDetail(let id): return "/post/equipment/get?id=\(id)"
        case .driverList:       return "/post/recruit/page"
        case .driverDetail(let id): return "/post/recruit/get?id=\(id)"
        case .mineProfile:      return "/member/mine/info"
        case .switchIdentity:   return "/member/mine/identity"
        case .myJobs:           return "/post/job/mine/page"
        case .myDrivers:        return "/post/recruit/mine/page"
        case .systemMessages:   return "/post/message/page"
        case .saveRecruitmentReminder: return "/post/recruit/reminder/open"
        case .publishJob:       return "/post/job/publish"
        case .updateJob(let id, _): return "/post/job/update?id=\(id)"
        case .deleteJob(let id): return "/post/job?id=\(id)"
        case .publishCar:       return "/post/equipment/publish"
        case .publishDriver:    return "/post/recruit/publish"
        case .updateDriver(let id, _): return "/post/recruit/update?id=\(id)"
        case .deleteDriver(let id): return "/post/recruit?id=\(id)"
        case .cities:           return "/common/cities"
        case .equipmentTypes:   return "/post/meta/categories"
        case .feedback:         return "/user/feedback"
        case .identityCertification: return "/member/real-name/get"
        case .submitIdentityCertification: return "/member/real-name/verify-image"
        case .driverLicenseCertification: return "/member/driver-license/get"
        case .submitDriverLicenseCertification: return "//member/driver-license/verify"
        case .vehicleLicenseCertification: return "/member/vehicle/list"
        case .submitVehicleLicenseCertification: return "/member/vehicle/verify-license"
        case .vehicleCertification: return "/member/certification/vehicle"
        case .submitVehicleCertification: return "/member/certification/vehicle/submit"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .login, .fastLogin, .sendCode, .refreshToken, .publishJob, .publishCar,
             .publishDriver, .saveRecruitmentReminder, .feedback, .submitIdentityCertification,
             .submitDriverLicenseCertification, .submitVehicleLicenseCertification,
             .submitVehicleCertification:
            return .post
        case .switchIdentity, .updateJob, .updateDriver:
            return .put
        case .deleteJob, .deleteDriver:
            return .delete
        default:
            return .get
        }
    }

    /// 请求参数
    var parameters: [String: Any] {
        switch self {
        case .login(let phone, let code, let identityType):
            return ["mobile": phone, "code": code, "identityType": identityType]
        case .fastLogin(let token, let identityType):
            return ["accessToken": token, "identityType": identityType]
        case .switchIdentity(let identityType):
            return ["identityType": identityType]
        case .sendCode(let phone):
            return ["mobile": phone, "scene": 1]
        case .refreshToken(let refreshToken):
            return [:]
//            return ["refreshToken": refreshToken]
        case .jobList(let page, let city):
            var p: [String: Any] = ["lastId": page, "size": 10]
            if let c = city { p["cityId"] = c }
            let category: String? = nil
            if let c = category { p["category"] = c }
            return p
        case .carList(let page, let city):
            var p: [String: Any] = ["page": page, "size": 10]
            if let c = city { p["city"] = c }
            return p
        case .driverList(let page, let city):
            var p: [String: Any] = ["page": page, "size": 10]
            if let c = city { p["city"] = c }
            return p
        case .myJobs(let page):
            return ["page": page, "size": 10]
        case .myDrivers(let page):
            return ["page": page, "size": 10]
        case .systemMessages(let lastId):
            return ["lastId": lastId, "size": 10]
        case .publishJob(let p), .publishCar(let p), .publishDriver(let p),
             .saveRecruitmentReminder(let p):
            return p
        case .updateJob(_, let params), .updateDriver(_, let params):
            return params
        case .feedback(let content):
            return ["content": content]
        case .submitIdentityCertification(let p),
             .submitDriverLicenseCertification(let p),
             .submitVehicleLicenseCertification(let p),
             .submitVehicleCertification(let p):
            return p
        default:
            return [:]
        }
    }

    /// 是否需要 token（登录/发码/刷新token 不需要）
    var requiresAuth: Bool {
        switch self {
        case .login, .fastLogin, .sendCode, .refreshToken:
            return false
        default:
            return true
        }
    }
}
