//
//  Models.swift
//  XunPengMachine
//
//  业务数据模型（Codable）
//

import Foundation

// MARK: - 用户
struct User: Codable {
    /// 身份类型：1 老板、2 车主、3 驾驶员
    var identityType: Int
    var identityName: String
    /// 是否完成实名认证
    var realNameVerify: Bool
    /// 是否完成驾驶证认证
    var driverLicenseVerify: Bool
    var vehicleCount: Int
    var mobile: String
    var canPublishJob: Bool
    var canPublishEquipment: Bool
    var canPublishRecruit: Bool

    /// 兼容现有发布入口使用的角色标识。
    var role: String {
        switch identityType {
        case 2: return "car"
        case 3: return "driver"
        default: return "boss"
        }
    }
}

// MARK: - 找活（活源）
struct Job: Codable {
    var id: Int64
    var userId: Int64?
    var title: String
    var category: String
    var cityName: String?
    var workAddress: String?
    var workLat: Double?
    var workLng: Double?
    var rentStartDate: String?
    var rentEndDate: String?
    var rentTimeSlot: String?
    var durationDays: Int
    var rentAmount: Double
    var invoiceType: Int?
    var description: String
    var contactMobile: String?
    var businessStatus: Int
    var viewCount: Int
    var createTime: String

    private enum CodingKeys: String, CodingKey {
        case id, userId, title, category, cityName, workAddress, workLat, workLng
        case rentStartDate, rentEndDate, rentTimeSlot, durationDays, rentAmount
        case invoiceType, description, contactMobile, businessStatus, viewCount, createTime
    }

    init(id: Int64, userId: Int64? = nil, title: String, category: String,
         cityName: String? = nil, workAddress: String? = nil,
         workLat: Double? = nil, workLng: Double? = nil,
         rentStartDate: String? = nil, rentEndDate: String? = nil,
         rentTimeSlot: String? = nil, durationDays: Int, rentAmount: Double,
         invoiceType: Int? = nil, description: String,
         contactMobile: String? = nil, businessStatus: Int = 0,
         viewCount: Int = 0, createTime: String) {
        self.id = id
        self.userId = userId
        self.title = title
        self.category = category
        self.cityName = cityName
        self.workAddress = workAddress
        self.workLat = workLat
        self.workLng = workLng
        self.rentStartDate = rentStartDate
        self.rentEndDate = rentEndDate
        self.rentTimeSlot = rentTimeSlot
        self.durationDays = durationDays
        self.rentAmount = rentAmount
        self.invoiceType = invoiceType
        self.description = description
        self.contactMobile = contactMobile
        self.businessStatus = businessStatus
        self.viewCount = viewCount
        self.createTime = createTime
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int64.self, forKey: .id)
        userId = try container.decodeIfPresent(Int64.self, forKey: .userId)
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
        category = try container.decodeIfPresent(String.self, forKey: .category) ?? ""
        cityName = try container.decodeIfPresent(String.self, forKey: .cityName)
        workAddress = try container.decodeIfPresent(String.self, forKey: .workAddress)
        workLat = try container.decodeIfPresent(Double.self, forKey: .workLat)
        workLng = try container.decodeIfPresent(Double.self, forKey: .workLng)
        rentStartDate = Self.decodeDate(from: container, forKey: .rentStartDate)
        rentEndDate = Self.decodeDate(from: container, forKey: .rentEndDate)
        rentTimeSlot = try container.decodeIfPresent(String.self, forKey: .rentTimeSlot)
        durationDays = try container.decodeIfPresent(Int.self, forKey: .durationDays) ?? 0
        rentAmount = Self.decodeAmount(from: container, forKey: .rentAmount)
        invoiceType = try container.decodeIfPresent(Int.self, forKey: .invoiceType)
        description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""
        contactMobile = try container.decodeIfPresent(String.self, forKey: .contactMobile)
        businessStatus = try container.decodeIfPresent(Int.self, forKey: .businessStatus) ?? 0
        viewCount = try container.decodeIfPresent(Int.self, forKey: .viewCount) ?? 0
        createTime = Self.decodeDateTime(from: container, forKey: .createTime)
    }

    private static func decodeDate(
        from container: KeyedDecodingContainer<CodingKeys>, forKey key: CodingKeys
    ) -> String? {
        if let value = try? container.decode(String.self, forKey: key) { return value }
        if let parts = try? container.decode([Int].self, forKey: key), parts.count >= 3 {
            return String(format: "%04d-%02d-%02d", parts[0], parts[1], parts[2])
        }
        return nil
    }

    private static func decodeAmount(
        from container: KeyedDecodingContainer<CodingKeys>, forKey key: CodingKeys
    ) -> Double {
        if let value = try? container.decode(Double.self, forKey: key) { return value }
        if let value = try? container.decode(String.self, forKey: key) { return Double(value) ?? 0 }
        return 0
    }

    private static func decodeDateTime(
        from container: KeyedDecodingContainer<CodingKeys>, forKey key: CodingKeys
    ) -> String {
        if let value = try? container.decode(String.self, forKey: key) { return value }
        if let milliseconds = try? container.decode(Int64.self, forKey: key) {
            return displayDateFormatter.string(
                from: Date(timeIntervalSince1970: Double(milliseconds) / 1000)
            )
        }
        return ""
    }

    private static let displayDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter
    }()

    var cityDisplayText: String { cityName ?? "" }

    var locationDisplayText: String {
        [cityName, workAddress]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    var rentAmountText: String {
        rentAmount.rounded() == rentAmount ? String(Int(rentAmount)) : String(rentAmount)
    }

    var durationText: String { "\(durationDays)天" }

    var rentalTimeText: String {
        let dateText: String?
        if let startDate = rentStartDate, let endDate = rentEndDate,
           !endDate.isEmpty, endDate != startDate {
            dateText = "\(startDate)至\(endDate)"
        } else {
            dateText = rentStartDate
        }
        return [dateText, rentTimeSlot]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    var createTimeText: String {
        let normalized = createTime.replacingOccurrences(of: "T", with: " ")
        return normalized.count > 16 ? String(normalized.prefix(16)) : normalized
    }

    var invoiceTypeText: String {
        switch invoiceType {
        case 1: return "开专票"
        case 2: return "开普票"
        default: return "不开票"
        }
    }

    var businessStatusText: String { businessStatus == 1 ? "已找到" : "进行中" }
}

// MARK: - 找设备（车）
struct Car: Codable {
    var id: String
    var title: String
    var type: String           // 设备类型：挖掘机、装载机...
    var brand: String
    var model: String
    var city: String
    var area: String
    var price: String
    var unit: String           // 元/台班、元/月
    var status: String         // 在租/闲置
    var images: [String]
    var desc: String
    var owner: String
    var ownerAvatar: String
    var publishTime: String
    var tags: [String]
    var viewCount: Int
    /// 车辆位置纬度
    var latitude: Double
    /// 车辆位置经度
    var longitude: Double
}

// MARK: - 我发布的招聘
struct RecruitmentPost: Codable {
    var id: Int64
    var userId: Int64?
    var title: String
    var category: String
    var cityName: String?
    var workAddress: String?
    var workType: Int
    var workTypeName: String?
    var salaryMin: Double?
    var salaryMax: Double?
    var salaryText: String?
    var description: String
    var contactMobile: String?
    var viewCount: Int
    var createTime: String

    private enum CodingKeys: String, CodingKey {
        case id, userId, title, category, cityName, workAddress, workType, workTypeName
        case salaryMin, salaryMax, salaryText, description, contactMobile, viewCount, createTime
    }

    init(id: Int64, userId: Int64? = nil, title: String, category: String,
         cityName: String? = nil, workAddress: String? = nil,
         workType: Int, workTypeName: String? = nil,
         salaryMin: Double? = nil, salaryMax: Double? = nil, salaryText: String? = nil,
         description: String, contactMobile: String? = nil,
         viewCount: Int = 0, createTime: String) {
        self.id = id
        self.userId = userId
        self.title = title
        self.category = category
        self.cityName = cityName
        self.workAddress = workAddress
        self.workType = workType
        self.workTypeName = workTypeName
        self.salaryMin = salaryMin
        self.salaryMax = salaryMax
        self.salaryText = salaryText
        self.description = description
        self.contactMobile = contactMobile
        self.viewCount = viewCount
        self.createTime = createTime
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let value = try? container.decode(Int64.self, forKey: .id) {
            id = value
        } else if let value = try? container.decode(String.self, forKey: .id),
                  let parsed = Int64(value) {
            id = parsed
        } else {
            id = 0
        }
        userId = try container.decodeIfPresent(Int64.self, forKey: .userId)
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
        category = try container.decodeIfPresent(String.self, forKey: .category) ?? ""
        cityName = try container.decodeIfPresent(String.self, forKey: .cityName)
        workAddress = try container.decodeIfPresent(String.self, forKey: .workAddress)
        workType = try container.decodeIfPresent(Int.self, forKey: .workType) ?? 0
        workTypeName = try container.decodeIfPresent(String.self, forKey: .workTypeName)
        salaryMin = Self.decodeAmount(from: container, forKey: .salaryMin)
        salaryMax = Self.decodeAmount(from: container, forKey: .salaryMax)
        salaryText = try container.decodeIfPresent(String.self, forKey: .salaryText)
        description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""
        contactMobile = try container.decodeIfPresent(String.self, forKey: .contactMobile)
        viewCount = try container.decodeIfPresent(Int.self, forKey: .viewCount) ?? 0
        createTime = Self.decodeDateTime(from: container, forKey: .createTime)
    }

    private static func decodeAmount(
        from container: KeyedDecodingContainer<CodingKeys>, forKey key: CodingKeys
    ) -> Double? {
        if let value = try? container.decodeIfPresent(Double.self, forKey: key) { return value }
        if let value = try? container.decodeIfPresent(String.self, forKey: key) {
            return Double(value)
        }
        return nil
    }

    private static func decodeDateTime(
        from container: KeyedDecodingContainer<CodingKeys>, forKey key: CodingKeys
    ) -> String {
        if let value = try? container.decode(String.self, forKey: key) { return value }
        if let milliseconds = try? container.decode(Int64.self, forKey: key) {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "zh_CN")
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            return formatter.string(from: Date(timeIntervalSince1970: Double(milliseconds) / 1000))
        }
        return ""
    }

    var salaryDisplayText: String {
        if let salaryText = salaryText?.trimmingCharacters(in: .whitespacesAndNewlines),
           !salaryText.isEmpty {
            return salaryText
        }
        if let salaryMin, let salaryMax {
            return "\(Self.amountText(salaryMin))-\(Self.amountText(salaryMax))元/月"
        }
        if let salaryMin { return "\(Self.amountText(salaryMin))元/月起" }
        if let salaryMax { return "最高\(Self.amountText(salaryMax))元/月" }
        return "面议"
    }

    var workTypeDisplayText: String {
        if let workTypeName = workTypeName?.trimmingCharacters(in: .whitespacesAndNewlines),
           !workTypeName.isEmpty {
            return workTypeName
        }
        switch workType {
        case 1: return "长期活"
        case 2: return "替班活"
        case 3: return "长替都要"
        default: return ""
        }
    }

    var locationDisplayText: String {
        [cityName, workAddress]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    var createTimeDisplayText: String {
        let normalized = createTime.replacingOccurrences(of: "T", with: " ")
        let value = String(normalized.prefix(19))
        for format in ["yyyy-MM-dd HH:mm:ss", "yyyy-MM-dd HH:mm"] {
            let parser = DateFormatter()
            parser.locale = Locale(identifier: "en_US_POSIX")
            parser.dateFormat = format
            if let date = parser.date(from: value) {
                let formatter = DateFormatter()
                formatter.locale = Locale(identifier: "zh_CN")
                formatter.dateFormat = "M月d日 HH:mm"
                return formatter.string(from: date)
            }
        }
        return normalized
    }

    private static func amountText(_ amount: Double) -> String {
        amount.rounded() == amount ? String(Int(amount)) : String(amount)
    }
}

/// 招聘首页与“我发布的招聘”使用同一套接口字段。
typealias Driver = RecruitmentPost

// MARK: - 系统消息
struct SystemMessage: Codable {
    let id: Int64
    let isAllUser: Bool
    let title: String
    let content: String
    let category: Int
    /// 接口当前固定返回 false；页面已读状态由 SystemMessageReadStore 决定。
    let isRead: Bool
    let readTime: String?
    let createTime: String

    private enum CodingKeys: String, CodingKey {
        case id, isAllUser, title, content, category, isRead, readTime, createTime
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let value = try? container.decode(Int64.self, forKey: .id) {
            id = value
        } else if let value = try? container.decode(String.self, forKey: .id),
                  let parsed = Int64(value) {
            id = parsed
        } else {
            id = 0
        }
        isAllUser = try container.decodeIfPresent(Bool.self, forKey: .isAllUser) ?? false
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
        content = try container.decodeIfPresent(String.self, forKey: .content) ?? ""
        category = try container.decodeIfPresent(Int.self, forKey: .category) ?? 1
        isRead = try container.decodeIfPresent(Bool.self, forKey: .isRead) ?? false
        readTime = Self.decodeDateTime(from: container, forKey: .readTime)
        createTime = Self.decodeDateTime(from: container, forKey: .createTime) ?? ""
    }

    private static func decodeDateTime(
        from container: KeyedDecodingContainer<CodingKeys>, forKey key: CodingKeys
    ) -> String? {
        if let value = try? container.decodeIfPresent(String.self, forKey: key) { return value }
        if let milliseconds = try? container.decodeIfPresent(Int64.self, forKey: key) {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "zh_CN")
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            return formatter.string(from: Date(timeIntervalSince1970: Double(milliseconds) / 1000))
        }
        return nil
    }

    var createDateDisplayText: String {
        let normalized = createTime.replacingOccurrences(of: "T", with: " ")
        let value = String(normalized.prefix(19))
        for format in ["yyyy-MM-dd HH:mm:ss", "yyyy-MM-dd HH:mm", "yyyy-MM-dd"] {
            let parser = DateFormatter()
            parser.locale = Locale(identifier: "en_US_POSIX")
            parser.dateFormat = format
            if let date = parser.date(from: value) {
                let formatter = DateFormatter()
                formatter.locale = Locale(identifier: "zh_CN")
                formatter.dateFormat = "yyyy年M月d日"
                return formatter.string(from: date)
            }
        }
        return normalized
    }
}

// MARK: - 通用
struct City: Codable {
    var code: String
    var name: String
    var hot: Bool
}

struct EquipmentType: Codable {
    var id: String
    var name: String
    var icon: String
}
