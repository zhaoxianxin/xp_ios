# App Store 提交前审核检查报告

检查日期：2026-10-13
目标：`XunPengMachine` / `com.xunpeng.machine` / `1.0.0 (1)`

## 结论

当前版本**不建议提交审核**。工程配置中的隐私清单、权限声明、显示名、加密声明和无关资源打包问题已处理；设置中心也已增加用户协议、隐私政策、第三方 SDK 清单及独立注销确认页。但仍有多项必须由产品、后端或开发者账号持有人完成的阻断项。

## 已完成的工程配置修正

- 新增应用级 `PrivacyInfo.xcprivacy`，声明应用及静态链接 SDK 使用的 Required Reason API：UserDefaults、文件元数据、系统启动时间和磁盘空间。
- 在隐私清单中登记当前代码涉及的姓名、手机号、用户 ID、图片/视频、敏感信息、地址、用户内容及第三方 SDK 分析数据；均声明为不用于跟踪。
- 按产品功能规划保留使用期间定位、始终定位、相册读取和相机权限；权限文案已在 Info.plist 与 Debug/Release 构建配置中保持一致。
- 移除当前及规划功能均未使用的通讯录、麦克风和相册写入权限文案。
- 补充应用桌面显示名“巡朋机械”和 `ITSAppUsesNonExemptEncryption = NO`。
- 将工程开发语言改为简体中文。
- 从 target membership 中排除 37 张设计参考截图、`tabbar.png` 和内部 `readme.md`，避免它们被打进安装包。源文件未删除。
- 按设计稿重做设置中心，增加用户协议、隐私政策、第三方 SDK 清单和消息震动开关；注销账号改为独立风险确认页。

## P0：提交前必须解决

### 1. App Icon 为空

`Assets.xcassets/AppIcon.appiconset/Contents.json` 只有空槽位，没有任何 `filename`，目录内也没有 1024×1024 图标文件。必须提供有版权的正式图标，并确认不含透明通道。

### 2. 隐私政策和服务协议链接为空

`Constants.privacyPolicyURL` 与 `Constants.serviceAgreementURL` 均为空。首次启动页上的两个链接会直接提示“协议地址暂未配置”，属于审核员一启动即可遇到的失效链接。

必须配置公开可访问的 HTTPS 页面。隐私政策至少应说明：收集的数据、用途、第三方共享（高德地图、阿里一键登录及其依赖）、保存期限、删除方式、撤回同意方式、联系人和生效日期。App Store Connect 的 Privacy Policy URL 必须与应用内保持一致。

### 3. 全局关闭 ATS，接口仍为 HTTP IP

`NetworkManager.baseURL` 为 `http://47.110.239.69:8080/app-api`，`Info.plist` 因此设置了 `NSAllowsArbitraryLoads = YES`。Apple 要求对全局 ATS 例外提供审核理由，而且传输手机号、Token、身份证/驾驶证/车辆资料时使用明文 HTTP 存在严重安全与隐私风险。

必须由后端提供有效证书的 HTTPS 域名，然后删除 `NSAllowsArbitraryLoads`。不要只把字符串改成 `https`，需先确认服务器证书链、TLS 配置和全部接口可用。

### 4. 高德 Key 是占位值

`AppDelegate.setupAMap()` 使用“你的高德Key”。地图和定位能力在审核中会失败。需配置与 `com.xunpeng.machine` 及发布证书匹配的 iOS Key，并在真机 Release 包验证。

### 5. 账号注销没有真正调用服务端

“注销账号”当前只清除本地 Token，随后显示“账号注销申请已提交”，没有删除接口调用、处理时限或结果确认。这不满足 Apple 5.1.1(v) 对账号及关联数据删除的要求。

需要后端提供真实删除能力并覆盖用户发布内容、认证资料和图片；如果异步处理，应展示处理期限并在完成后通知用户。此项属于业务逻辑，因此本次未修改。

### 6. 图片上传链路未实现

车辆发布与四步认证可选择图片，但没有上传请求；`imageUrls` 无法产生，用户最终只会看到“设备图片尚未上传”或“认证图片尚未上传”。这是明显的不完整功能，容易按 2.1 App Completeness 被拒。

需补齐正式上传接口与失败/重试处理，或在首个审核版本中完整下架这些入口。此项属于业务逻辑/UI，因此本次未修改。

### 7. 用户生成内容缺少审核治理能力

应用允许用户发布活源、设备和招聘信息，但代码中未找到发布前过滤、内容举报、屏蔽滥用用户等能力。Apple 1.2 对 UGC 要求至少包含：不良内容过滤、举报与及时处理、屏蔽滥用用户、公开联系信息。

需要产品与后端补齐，并在 App Review Notes 说明入口和处理机制。此项属于业务逻辑/UI，因此本次未修改。

### 8. 审核账号与登录可达性

应用登录依赖中国手机号短信验证码或本机号一键登录。必须在 App Store Connect 提供长期有效的审核账号、固定验证码/审核白名单或经 Apple 预先同意的完整 Demo 模式，并确保审核地区网络可访问后端。若三种身份看到的功能不同，应分别提供账号和操作说明。

## P1：归档或提审前确认

- 签名配置使用手动签名，target team 为 `797T44L76Z`，project team 为 `6Z3HEPT682`，并绑定 `paipan_dev` / `machine_release`。需在实际提交机器统一团队、证书和 App Store 发布描述文件；当前机器还报告多份损坏的 provisioning profile。
- 手工集成的 `ATAuthSDK`、`YTXMonitor`、`YTXOperators` 是静态 framework；其隐私清单存在且格式有效，但归档后仍需在 Organizer 生成 Privacy Report，确认三份 SDK 声明被聚合。应用级清单已覆盖其 Required Reason API 和 Other Data 分析数据。
- 高德四个静态 SDK 当前包内未发现各自的 `PrivacyInfo.xcprivacy`。虽然它们不在 Apple 的强制签名 SDK 名单中，仍应向高德确认当前版本的隐私清单、SDK 签名和数据采集说明，并优先升级到官方明确支持当前 Xcode/App Store 要求的版本。
- `APIRouter.submitDriverLicenseCertification` 的 path 以 `//member/...` 开头，应由接口联调确认是否导致 404。修改会影响业务逻辑，本次未动。
- 正式包不要输出 Token、手机号、身份证资料或完整响应。当前 `Logger.log` 在 Release 关闭，但 `Logger.error` 仍会 `print`；需真机检查错误分支不泄露个人数据。
- 逐项核对 App Store Connect 的 App Privacy 标签与 `PrivacyInfo.xcprivacy`、隐私政策和真实后端行为一致。不要直接照抄清单后提交，尤其要确认 SDK 是否额外收集设备标识、运营商、诊断或精确位置。
- 年龄分级应如实勾选 User-Generated Content；不要选择 Kids Category。
- 若在中国大陆上架，确认 App Store Connect 要求的 ICP 备案号、主体一致性以及地图/招聘相关资质。

## App Store Connect 清单

- App 名称、主分类/副分类、年龄分级、版权、SKU、Bundle ID。
- 中文描述、关键词、支持 URL；支持页面必须展示真实联系方式。
- 隐私政策 URL；可选但建议提供 User Privacy Choices URL（访问、更正、撤回同意、删除）。
- App Privacy 数据类型与用途，包含所有第三方 SDK。
- 真实设备截图；截图必须对应当前版本，不得使用工程里的旧设计稿冒充现状。
- App Review 联系人、国际格式电话、邮箱、审核账号、验证码方式、各身份测试路径、定位与认证测试说明。
- 出口合规问卷与 `ITSAppUsesNonExemptEncryption = NO` 保持一致（仅使用系统/HTTPS 的豁免加密时）。
- Content Rights、广告标识符/Tracking 问卷、地区可用性和中国大陆备案资料。

## 验证结果

- 所有现有隐私清单及新增清单均通过 `plutil -lint`。
- Xcode 工程可以被 `xcodebuild -list` 正常解析，target 和 scheme 均存在。
- 应用级隐私清单已确认被复制到构建产物根目录。
- 当前受限执行环境无法连接 CoreSimulatorService，Storyboard 编译报“iOS 26.5 Platform Not Installed”，因此未完成整包 Release 构建、签名归档和上传验证。提交前必须在正常 Xcode 环境执行 Clean Archive、Validate App、生成 Privacy Report，并至少完成一次真机全流程回归。

## 官方依据

- App Review Guidelines: https://developer.apple.com/app-store/review/guidelines/
- Privacy manifests: https://developer.apple.com/documentation/bundleresources/privacy-manifest-files
- Required reason APIs: https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api
- Account deletion: https://developer.apple.com/help/app-review/guideline-reference/5-1-1-account-deletion/
- App privacy: https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy/
- Complete review information: https://developer.apple.com/help/app-review/before-submitting-for-review/complete-review
