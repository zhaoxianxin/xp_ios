//
//  MockProvider.swift
//  XunPengMachine
//
//  Mock 数据提供者：接口先返回测试数据
//

import Foundation

final class MockProvider {
    static let shared = MockProvider()
    private init() {}

    /// 返回对应路由的 mock JSON Data
    func mockData(for router: APIRouter) -> Data? {
        let json = body(for: router)
        return json.data(using: .utf8)
    }

    private func wrap(_ dataJson: String, code: Int = 0, msg: String = "ok") -> String {
        """
        {"code":\(code),"msg":"\(msg)","data":\(dataJson)}
        """
    }

    private func body(for router: APIRouter) -> String {
        switch router {
        case .sendCode:
            return wrap("{}", msg: "验证码已发送")

        case .login:
            let bo = """
            {"token":"mock_token_\(Int(Date().timeIntervalSince1970))","refreshToken":"mock_refresh_token_999"}
            """
            return wrap(bo)
            
        case .fastLogin:
            let bo = """
            {"token":"mock_token_\(Int(Date().timeIntervalSince1970))","refreshToken":"mock_refresh_token_999"}
            """
            return wrap(bo)

        case .refreshToken:
            let bo = """
            {"token":"mock_token_refreshed_\(Int(Date().timeIntervalSince1970))","refreshToken":"mock_refresh_token_new"}
            """
            return wrap(bo)

        case .jobList(let page, _):
            return wrap(pageJson(Job.templateList(page: page), page: page))

        case .carList(let page, _):
            return wrap(pageJson(Car.templateList(page: page), page: page))

        case .driverList(let page, _):
            return wrap(pageJson(Driver.templateList(page: page), page: page))

        case .jobDetail(let id):
            return wrap(Job.detail(id: id).toJson())

        case .carDetail(let id):
            return wrap(Car.detail(id: id).toJson())

        case .driverDetail(let id):
            return wrap(Driver.detail(id: id).toJson())

        case .mineProfile:
            return wrap(User.template().toJson())

        case .myJobs(let page):
            return wrap(pageJson(Job.templateList(page: page), page: page))

        case .myDrivers(let page):
            let list = page == 1 ? """
            [{"id":1,"userId":6,"title":"我在青岛明天用开货车师傅，吊钢筋和水","category":"叉车","cityName":"浙江杭州","workAddress":"余杭区","workType":3,"workTypeName":"长替都要","salaryMin":6000,"salaryMax":9000,"salaryText":"6000-9000元/月","description":"招聘叉车司机","contactMobile":"15963229366","viewCount":18,"createTime":"2026-06-17 18:00:00"}]
            """ : "[]"
            return wrap("{\"page\":\(page),\"size\":10,\"total\":1,\"list\":\(list)}")

        case .systemMessages(let lastId):
            let list = lastId == 0 ? """
            [{"id":2,"isAllUser":true,"title":"电话客服","content":"平台客服电话已更新，如有问题请及时联系我们。","category":3,"isRead":false,"readTime":null,"createTime":"2026-06-30 10:00:00"},{"id":1,"isAllUser":false,"title":"审核结果","content":"您的认证资料已审核通过。","category":2,"isRead":false,"readTime":null,"createTime":"2026-06-29 09:30:00"}]
            """ : "[]"
            return wrap("{\"list\":\(list),\"hasMore\":false,\"lastId\":1}")

        case .cities:
            return wrap("[\(City.list.map { $0.toJson() }.joined(separator: ","))]")

        case .equipmentTypes:
            return wrap("[\(EquipmentType.list.map { $0.toJson() }.joined(separator: ","))]")

        case .identityCertification:
            return wrap("""
            {"verifyStatus":2,"realName":"安XX","idCardNo":"3711************12","ethnicity":"汉族","birthday":"1990-01-01","address":"山东省青岛市","issuingAuthority":"青岛市公安局","idStartDate":"2016-05-10","idEndDate":"2036-05-10","portraitImgUrl":"","emblemImgUrl":"","verifyTime":"2026-10-11 10:00:00"}
            """)

        case .driverLicenseCertification:
            return wrap("""
            {"verifyStatus":2,"licenseNo":"3711************12","realName":"安XX","vehicleType":"C1","firstIssueDate":"2020-01-01","validStartDate":"2023-12-30","validEndDate":"长期","imgUrl":"","auditTime":"2026-10-11 10:00:00","rejectReason":null}
            """)

        case .vehicleLicenseCertification:
            return wrap("""
            [{"homePageImageUrl":"","vicePageImageUrl":"","plateNumber":"鲁BLXXX","vehicleType":"小型轿车","ownerName":"安XX","brandModel":"大众牌XXXXXX","vin":"LJAABBXXXXXXXXXXXX","engineNumber":"923XXXX","registerDate":"2009-12-15","issueDate":"2026-11-30","annualInspectionValidUntil":"2025-10"}]
            """)

        case .vehicleCertification:
            return wrap("""
            {"frontImageUrl":"","rearImageUrl":"","plateNumber":"鲁BLXXX"}
            """)

        case .publishJob, .publishCar, .publishDriver, .saveRecruitmentReminder, .feedback,
             .submitIdentityCertification, .submitDriverLicenseCertification,
             .submitVehicleLicenseCertification, .submitVehicleCertification:
            return wrap("{}", msg: "提交成功")
        }
    }

    /// 分页结构
    private func pageJson<T: Codable>(_ list: [T], page: Int) -> String {
        let total = 38
        let arr = list.map { $0.toJson() }.joined(separator: ",")
        return """
        {"page":\(page),"size":10,"total":\(total),"list":[\(arr)]}
        """
    }
}

// MARK: - Encodable -> JSON 字符串辅助
extension Encodable {
    func toJson() -> String {
        let data = (try? JSONEncoder().encode(self)) ?? Data()
        return String(data: data, encoding: .utf8) ?? "{}"
    }
}
