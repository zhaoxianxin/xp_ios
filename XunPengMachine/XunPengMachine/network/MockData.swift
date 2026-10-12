//
//  MockData.swift
//  XunPengMachine
//
//  各模型 Mock 模板数据
//

import Foundation

// MARK: - Job 模板
extension Job {
    static func templateList(page: Int) -> [Job] {
        let titles = ["我在青岛明天用100吨吊车，有空的师傅联系我", "明天用叉车卸货，有空的联系我",
                      "后天用25吨汽车吊，有空的联系我", "急需渣土车外运，长期能干",
                      "混凝土搅拌车招聘，月结9500", "工地土方运输，日结",
                      "砂石料运输车队急招", "路基材料运输，包吃住",
                      "城市建筑垃圾清运", "沥青运输专车"]
        let equipTags = ["汽车吊", "叉车", "汽车吊", "渣土车", "搅拌车", "自卸车", "挂车", "平板车", "自卸车", "罐车"]
        let rentalTimes = ["上午08:00-09:00", "下午14:00-16:00",
                           "上午07:00-12:00", "全天", "上午08:00-18:00"]
        let cities = ["北京", "上海", "广州", "深圳", "杭州", "成都", "武汉", "南京"]
        // 城市对应经纬度（高德坐标 GCJ-02）
        let cityCoords: [String: (Double, Double)] = [
            "北京": (39.9042, 116.4074), "上海": (31.2304, 121.4737),
            "广州": (23.1291, 113.2644), "深圳": (22.5431, 114.0579),
            "杭州": (30.2741, 120.1551), "成都": (30.5728, 104.0668),
            "武汉": (30.5928, 114.3055), "南京": (32.0603, 118.7969),
        ]
        return (0..<8).map { i in
            let idx = page * 8 + i
            let city = cities.randomElement()!
            let coord = cityCoords[city] ?? (39.9042, 116.4074)
            return Job(
                id: Int64(idx),
                userId: Int64(i + 1),
                title: titles[i % titles.count] + " #\(idx)",
                category: equipTags[i % equipTags.count],
                cityName: city,
                workAddress: ["朝阳区", "浦东新区", "天河区"][i % 3],
                workLat: coord.0,
                workLng: coord.1,
                rentStartDate: "2026-11-\(String(format: "%02d", i + 10))",
                rentTimeSlot: rentalTimes[i % rentalTimes.count],
                durationDays: [2, 3, 1, 30][i % 4],
                rentAmount: [8000, 9500, 12000, 7000][i % 4],
                invoiceType: i % 3,
                description: "工地现场结账，不拖欠，路况好，距离近，欢迎联系。",
                contactMobile: "15963229366",
                businessStatus: i % 3 == 0 ? 1 : 0,
                viewCount: 120 + i * 13,
                createTime: "2026-10-11 10:\(String(format: "%02d", i))"
            )
        }
    }

    static func detail(id: Int64) -> Job {
        Job(id: id, userId: 1, title: "在北京明天用100吨汽车吊", category: "汽车吊",
            cityName: "北京", workAddress: "朝阳区", workLat: 39.9042, workLng: 116.4074,
            rentStartDate: "2026-11-11", rentTimeSlot: "上午08:00-09:00",
            durationDays: 2, rentAmount: 8000, invoiceType: 0,
            description: "工地现场结账，路况良好，欢迎联系。", contactMobile: "15963229366",
            businessStatus: 0, viewCount: 328, createTime: "2026-10-11 10:00")
    }
}

// MARK: - Car 模板
extension Car {
    static func templateList(page: Int) -> [Car] {
        let titles = ["我在青岛明天出租100吨吊车，有需要的联系我", "出租25吨汽车吊，带司机",
                      "三一135挖掘机出租，性能良好", "装载机出租，日结",
                      "泵车出租，全国可调度", "自卸车长期出租",
                      "搅拌车出租，月结优惠", "压路机台班出租"]
        let types = ["汽车吊", "汽车吊", "挖掘机", "装载机", "泵车", "自卸车", "搅拌车", "压路机"]
        let brands = ["三一", "徐工", "柳工", "临工", "卡特", "斗山"]
        let cities = ["北京", "上海", "广州", "深圳", "杭州", "成都", "武汉", "南京"]
        // 城市对应经纬度（高德坐标 GCJ-02）
        let cityCoords: [String: (Double, Double)] = [
            "北京": (39.9042, 116.4074), "上海": (31.2304, 121.4737),
            "广州": (23.1291, 113.2644), "深圳": (22.5431, 114.0579),
            "杭州": (30.2741, 120.1551), "成都": (30.5728, 104.0668),
            "武汉": (30.5928, 114.3055), "南京": (32.0603, 118.7969),
        ]
        return (0..<8).map { i in
            let idx = page * 8 + i
            let t = types[i % types.count]
            let city = cities.randomElement()!
            let coord = cityCoords[city] ?? (39.9042, 116.4074)
            return Car(
                id: "car_\(idx)",
                title: titles[i % titles.count],
                type: t, brand: brands[i % brands.count], model: ["SY135", "L956", "XLG"][i % 3],
                city: city, area: ["大兴区", "闵行区", "白云区"][i % 3],
                price: ["1500", "2200", "3000", "1800"][i % 4], unit: "元/台班",
                status: i % 3 == 0 ? "在租" : "闲置",
                images: ["https://api.xunpeng.com/car\(i).png"],
                desc: "设备保养良好，性能稳定，带司机，可月租可台班，全国可调度。",
                owner: ["刘师傅", "陈老板", "周总"][i % 3],
                ownerAvatar: "https://api.xunpeng.com/avatar/\(i+2).png",
                publishTime: ["刚刚", "30分钟前", "2小时前", "今天"][i % 4],
                tags: ["带司机", "全国调度", i % 2 == 0 ? "新机" : "性能好"], viewCount: 88 + i * 9,
                latitude: coord.0, longitude: coord.1
            )
        }
    }

    static func detail(id: String) -> Car {
        Car(id: id, title: "三一SY135挖掘机出租", type: "挖掘机", brand: "三一", model: "SY135-9",
            city: "北京", area: "大兴区", price: "2200", unit: "元/台班", status: "闲置",
            images: ["https://api.xunpeng.com/car0.png", "https://api.xunpeng.com/car1.png"],
            desc: "2019年三一SY135，保养良好，液压系统刚大修，带经验丰富司机，可提供发票，全国可调度。",
            owner: "刘师傅", ownerAvatar: "https://api.xunpeng.com/avatar/2.png", publishTime: "刚刚",
            tags: ["带司机", "全国调度", "性能好"], viewCount: 256,
            latitude: 39.9042, longitude: 116.4074)
    }
}

// MARK: - Driver 模板
extension Driver {
    static func templateList(page: Int) -> [Driver] {
        let titles = ["我在青岛明天用开货车师傅，有空的联系我", "招聘A2司机，长期活，月结9000",
                      "替班活，明天用搅拌车师傅", "招聘挂车司机，6000-9000元/月",
                      "急招自卸车司机，日结", "招聘汽车吊司机，长期",
                      "替班活，后天用平板车师傅", "招聘B2司机，包吃住"]
        let cities = ["山东青岛", "北京", "上海", "广州", "深圳", "杭州", "成都", "武汉"]
        return (0..<8).map { i in
            let idx = page * 8 + i
            return Driver(
                id: Int64(idx), userId: 6, title: titles[i % titles.count],
                category: ["渣土车", "搅拌车", "自卸车"][i % 3],
                cityName: cities[i % cities.count], workAddress: nil,
                workType: i % 3 + 1,
                workTypeName: ["长期活", "替班活", "长替都要"][i % 3],
                salaryMin: Double([6000, 8000, 10000, 12000][i % 4]),
                salaryMax: Double([9000, 10000, 13000, 15000][i % 4]),
                salaryText: nil,
                description: "招聘有经验司机，熟悉城市道路，能吃苦耐劳。",
                contactMobile: "15963229366", viewCount: 10 + i,
                createTime: "2026-06-17 18:00:00"
            )
        }
    }

    static func detail(id: String) -> Driver {
        Driver(id: Int64(id) ?? 0, userId: 6,
               title: "我在青岛明天用开货车师傅，有空的联系我",
               category: "自卸车", cityName: "山东青岛", workAddress: "城阳区",
               workType: 1, workTypeName: "长期活",
               salaryMin: 10000, salaryMax: 12000,
               salaryText: "10000-12000元/月",
               description: "招聘有经验司机，熟悉周边路况，能吃苦耐劳，月结优先。",
               contactMobile: "15963229366", viewCount: 256,
               createTime: "2026-06-17 18:00:00")
    }
}

// MARK: - User 模板
extension User {
    static func template() -> User {
        User(identityType: 1,
             identityName: "老板身份",
             realNameVerify: true,
             driverLicenseVerify: true,
             vehicleCount: 0,
             mobile: "15963229366",
             canPublishJob: true,
             canPublishEquipment: false,
             canPublishRecruit: true)
    }
}

// MARK: - 城市与设备类型

/// 省份（含城市列表，用于两级联动选择）
struct Province: Codable {
    var name: String
    var cities: [City]
}

extension City {
    static let list: [City] = [
        City(code: "bj", name: "北京", hot: true),
        City(code: "sh", name: "上海", hot: true),
        City(code: "gz", name: "广州", hot: true),
        City(code: "sz", name: "深圳", hot: true),
        City(code: "hz", name: "杭州", hot: true),
        City(code: "cd", name: "成都", hot: true),
        City(code: "wh", name: "武汉", hot: false),
        City(code: "nj", name: "南京", hot: false),
        City(code: "xa", name: "西安", hot: false),
        City(code: "cq", name: "重庆", hot: false)
    ]
}

extension Province {
    static let list: [Province] = [
        Province(name: "北京", cities: [City(code: "bj", name: "北京", hot: true)]),
        Province(name: "上海", cities: [City(code: "sh", name: "上海", hot: true)]),
        Province(name: "广东", cities: [
            City(code: "gz", name: "广州", hot: true),
            City(code: "sz", name: "深圳", hot: true),
            City(code: "dg", name: "东莞", hot: false),
            City(code: "fs", name: "佛山", hot: false),
            City(code: "zh", name: "珠海", hot: false),
        ]),
        Province(name: "浙江", cities: [
            City(code: "hz", name: "杭州", hot: true),
            City(code: "nb", name: "宁波", hot: false),
            City(code: "wz", name: "温州", hot: false),
            City(code: "sx", name: "绍兴", hot: false),
            City(code: "jh", name: "金华", hot: false),
        ]),
        Province(name: "四川", cities: [
            City(code: "cd", name: "成都", hot: true),
            City(code: "my", name: "绵阳", hot: false),
            City(code: "dzc", name: "德阳", hot: false),
            City(code: "yib", name: "宜宾", hot: false),
        ]),
        Province(name: "湖北", cities: [
            City(code: "wh", name: "武汉", hot: false),
            City(code: "yc", name: "宜昌", hot: false),
            City(code: "xy", name: "襄阳", hot: false),
        ]),
        Province(name: "江苏", cities: [
            City(code: "nj", name: "南京", hot: false),
            City(code: "sz2", name: "苏州", hot: false),
            City(code: "wx", name: "无锡", hot: false),
            City(code: "cz", name: "常州", hot: false),
            City(code: "nt", name: "南通", hot: false),
        ]),
        Province(name: "陕西", cities: [
            City(code: "xa", name: "西安", hot: false),
            City(code: "bj2", name: "宝鸡", hot: false),
            City(code: "wn", name: "渭南", hot: false),
        ]),
        Province(name: "重庆", cities: [City(code: "cq", name: "重庆", hot: false)]),
        Province(name: "山东", cities: [
            City(code: "jn", name: "济南", hot: false),
            City(code: "qd", name: "青岛", hot: false),
            City(code: "yt", name: "烟台", hot: false),
            City(code: "wf", name: "潍坊", hot: false),
            City(code: "lin", name: "临沂", hot: false),
        ]),
    ]
}

/// 设备分类（两级：分类名 + 设备列表）
struct EquipmentCategory: Codable {
    var name: String
    var items: [EquipmentType]
}

extension EquipmentType {
    static let list: [EquipmentType] = [
        EquipmentType(id: "1", name: "挖掘机", icon: "excavator"),
        EquipmentType(id: "2", name: "装载机", icon: "loader"),
        EquipmentType(id: "3", name: "推土机", icon: "bulldozer"),
        EquipmentType(id: "4", name: "压路机", icon: "roller"),
        EquipmentType(id: "5", name: "吊车", icon: "crane"),
        EquipmentType(id: "6", name: "泵车", icon: "pump"),
        EquipmentType(id: "7", name: "自卸车", icon: "dump"),
        EquipmentType(id: "8", name: "搅拌车", icon: "mixer")
    ]
}

extension EquipmentCategory {
    static let list: [EquipmentCategory] = [
        EquipmentCategory(name: "起重机械", items: [
            EquipmentType(id: "c1", name: "汽车吊", icon: "crane"),
            EquipmentType(id: "c2", name: "随车吊", icon: "crane"),
            EquipmentType(id: "c3", name: "履带吊", icon: "crane"),
            EquipmentType(id: "c4", name: "叉车", icon: "forklift"),
            EquipmentType(id: "c5", name: "折臂吊", icon: "crane"),
            EquipmentType(id: "c6", name: "高空/云梯车", icon: "ladder"),
            EquipmentType(id: "c7", name: "铲车", icon: "loader"),
        ]),
        EquipmentCategory(name: "路面机械", items: [
            EquipmentType(id: "r1", name: "压路机", icon: "roller"),
            EquipmentType(id: "r2", name: "推土机", icon: "bulldozer"),
            EquipmentType(id: "r3", name: "铣刨机", icon: "milling"),
            EquipmentType(id: "r4", name: "摊铺机", icon: "paver"),
            EquipmentType(id: "r5", name: "平地机", icon: "grader"),
            EquipmentType(id: "r6", name: "打桩机", icon: "pile"),
            EquipmentType(id: "r7", name: "装载机", icon: "loader"),
            EquipmentType(id: "r8", name: "破碎机", icon: "crusher"),
        ]),
        EquipmentCategory(name: "挖掘机械", items: [
            EquipmentType(id: "e1", name: "轮挖", icon: "excavator"),
            EquipmentType(id: "e2", name: "船挖", icon: "excavator"),
            EquipmentType(id: "e3", name: "旋挖机", icon: "excavator"),
            EquipmentType(id: "e4", name: "长臂挖", icon: "excavator"),
            EquipmentType(id: "e5", name: "挖机/履带挖", icon: "excavator"),
            EquipmentType(id: "e6", name: "钻机/螺旋钻", icon: "drill"),
        ]),
        EquipmentCategory(name: "运输机械", items: [
            EquipmentType(id: "t1", name: "冷藏车/厢货", icon: "truck"),
            EquipmentType(id: "t2", name: "挂车/平板车", icon: "truck"),
            EquipmentType(id: "t3", name: "洒水车", icon: "truck"),
            EquipmentType(id: "t4", name: "罐车/水罐", icon: "truck"),
            EquipmentType(id: "t5", name: "搅拌车/泵车", icon: "mixer"),
            EquipmentType(id: "t6", name: "自卸/渣土车", icon: "dump"),
        ]),
    ]
}
