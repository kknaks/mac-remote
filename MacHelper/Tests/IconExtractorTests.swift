import XCTest
@testable import MacHelperLib

final class IconExtractorTests: XCTestCase {

    // MARK: - Task 1: AppIcon model + AppIconsResponse (Spec-04 §2, §3)

    func test_appIcon_encodesToJSON_containsAllFields() throws {
        let icon = AppIcon(appName: "Arc", iconData: "iVBORw0KGgo=")
        let data = try JSONEncoder().encode(icon)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertEqual(json["appName"] as? String, "Arc")
        XCTAssertEqual(json["iconData"] as? String, "iVBORw0KGgo=")
    }

    func test_appIcon_roundTrip() throws {
        let original = AppIcon(appName: "Xcode", iconData: "AAAA")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(AppIcon.self, from: data)
        XCTAssertEqual(original, decoded)
    }

    func test_appIconsResponse_typeIsAppIcons() throws {
        let response = AppIconsResponse(icons: [:])
        XCTAssertEqual(response.type, "appIcons")
    }

    func test_appIconsResponse_encodesToSpecFormat() throws {
        // Spec-04 §3: { "type":"appIcons", "icons":{ "Arc":"base64...", ... } }
        let icons = ["Arc": "iVBORw0KGgo=", "Xcode": "AAAA"]
        let response = AppIconsResponse(icons: icons)
        let data = try JSONEncoder().encode(response)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertEqual(json["type"] as? String, "appIcons")
        let iconsDict = json["icons"] as? [String: String]
        XCTAssertNotNil(iconsDict)
        XCTAssertEqual(iconsDict?["Arc"], "iVBORw0KGgo=")
        XCTAssertEqual(iconsDict?["Xcode"], "AAAA")
    }

    func test_appIconsResponse_emptyIcons_isValid() throws {
        let response = AppIconsResponse(icons: [:])
        let data = try JSONEncoder().encode(response)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertEqual(json["type"] as? String, "appIcons")
        let iconsDict = json["icons"] as? [String: String]
        XCTAssertEqual(iconsDict?.count, 0)
    }

    func test_appIconsResponse_roundTrip() throws {
        let original = AppIconsResponse(icons: ["Terminal": "BBBB"])
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(AppIconsResponse.self, from: data)
        XCTAssertEqual(original, decoded)
    }

    // MARK: - Task 3: Icon resize constant (Spec-04 §9 #3)

    func test_iconSizePixels_is64() {
        // Spec-04 §9 #3: 적절한 크기(64x64)로 리사이즈
        XCTAssertEqual(iconSizePixels, 64)
    }

    // MARK: - Task 2: base64 encoding (pure Swift)

    func test_encodeToBase64_validData_returnsBase64String() {
        let data = Data([0x48, 0x65, 0x6C, 0x6C, 0x6F])  // "Hello"
        let result = encodeToBase64(data)
        XCTAssertEqual(result, "SGVsbG8=")
    }

    func test_encodeToBase64_emptyData_returnsEmptyString() {
        let data = Data()
        let result = encodeToBase64(data)
        XCTAssertEqual(result, "")
    }

    func test_isValidPNGBase64_validPNG_returnsTrue() {
        // PNG 시그니처로 시작하는 최소 데이터
        let pngBytes: [UInt8] = [
            0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
            0x00, 0x00, 0x00, 0x0D
        ]
        let base64 = Data(pngBytes).base64EncodedString()
        XCTAssertTrue(isValidPNGBase64(base64))
    }

    func test_isValidPNGBase64_notPNG_returnsFalse() {
        // JPEG 시그니처
        let jpegBytes: [UInt8] = [0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46]
        let base64 = Data(jpegBytes).base64EncodedString()
        XCTAssertFalse(isValidPNGBase64(base64))
    }

    func test_isValidPNGBase64_invalidBase64_returnsFalse() {
        XCTAssertFalse(isValidPNGBase64("not-valid-base64!!!"))
    }

    func test_isValidPNGBase64_tooShort_returnsFalse() {
        let shortData = Data([0x89, 0x50])
        let base64 = shortData.base64EncodedString()
        XCTAssertFalse(isValidPNGBase64(base64))
    }

    // MARK: - Task 4: Default icon fallback (Spec-04 §5 ICON_NOT_FOUND)
    // 아이콘 추출 실패 시 시스템 기본 아이콘으로 대체 (Spec-04 §5)
    // CLI 도구 등 아이콘 없는 앱에도 기본 아이콘 제공 (Spec-04 §9 #4)

    func test_defaultIconBase64_isNotEmpty() {
        XCTAssertFalse(defaultIconBase64.isEmpty)
    }

    func test_defaultIconBase64_isValidBase64() {
        let data = Data(base64Encoded: defaultIconBase64)
        XCTAssertNotNil(data)
    }

    func test_defaultIconBase64_decodedSize_isReasonable() {
        // 기본 아이콘은 최소 1x1 PNG → 최소 크기
        let data = Data(base64Encoded: defaultIconBase64)!
        XCTAssertGreaterThan(data.count, 0)
        // 1x1 PNG는 일반적으로 100바이트 이하
        XCTAssertLessThan(data.count, 200)
    }

    func test_defaultIconBase64_isStable() {
        // 기본 아이콘은 항상 같은 값을 반환 (상수)
        let first = defaultIconBase64
        let second = defaultIconBase64
        XCTAssertEqual(first, second)
    }

    func test_defaultIconBase64_isValidPNG() {
        XCTAssertTrue(isValidPNGBase64(defaultIconBase64))
    }

    // MARK: - Task 5: IconCache — 앱별 중복 제거 (Spec-04 §9 #1, #2)

    func test_iconCache_initiallyEmpty() {
        let cache = IconCache()
        XCTAssertEqual(cache.count, 0)
        XCTAssertFalse(cache.has("Arc"))
    }

    func test_iconCache_setAndGet() {
        let cache = IconCache()
        cache.set("Arc", iconData: "base64data")

        XCTAssertTrue(cache.has("Arc"))
        XCTAssertEqual(cache.get("Arc"), "base64data")
        XCTAssertEqual(cache.count, 1)
    }

    func test_iconCache_filterNew_returnsOnlyNewApps() {
        let cache = IconCache()
        cache.set("Arc", iconData: "aaa")
        cache.set("Xcode", iconData: "bbb")

        let newApps = cache.filterNew(["Arc", "Terminal", "Xcode", "Safari"])
        XCTAssertEqual(newApps, ["Terminal", "Safari"])
    }

    func test_iconCache_filterNew_allCached_returnsEmpty() {
        let cache = IconCache()
        cache.set("Arc", iconData: "aaa")

        let newApps = cache.filterNew(["Arc"])
        XCTAssertTrue(newApps.isEmpty)
    }

    func test_iconCache_filterNew_noneCached_returnsAll() {
        let cache = IconCache()
        let newApps = cache.filterNew(["Arc", "Xcode"])
        XCTAssertEqual(newApps, ["Arc", "Xcode"])
    }

    func test_uniqueAppNames_deduplicates() {
        // Spec-04 §9 #1: 같은 앱 창 3개 → 앱 이름 1개
        let windows = [
            WindowInfo(id: 1, app: "Safari", title: "Tab 1", pid: 100, frontmost: true),
            WindowInfo(id: 2, app: "Safari", title: "Tab 2", pid: 100, frontmost: false),
            WindowInfo(id: 3, app: "Safari", title: "Tab 3", pid: 100, frontmost: false),
            WindowInfo(id: 4, app: "Xcode", title: "Project", pid: 200, frontmost: false),
        ]
        let names = IconCache.uniqueAppNames(from: windows)
        XCTAssertEqual(names, ["Safari", "Xcode"])
    }

    func test_uniqueAppNames_preservesOrder() {
        let windows = [
            WindowInfo(id: 1, app: "Terminal", title: "zsh", pid: 300, frontmost: false),
            WindowInfo(id: 2, app: "Arc", title: "Tab", pid: 100, frontmost: true),
            WindowInfo(id: 3, app: "Xcode", title: "P", pid: 200, frontmost: false),
            WindowInfo(id: 4, app: "Arc", title: "Tab 2", pid: 100, frontmost: false),
        ]
        let names = IconCache.uniqueAppNames(from: windows)
        XCTAssertEqual(names, ["Terminal", "Arc", "Xcode"])
    }

    func test_uniqueAppNames_emptyWindows_returnsEmpty() {
        let names = IconCache.uniqueAppNames(from: [])
        XCTAssertTrue(names.isEmpty)
    }

    func test_iconCache_toResponse_returnsAllCachedIcons() {
        let cache = IconCache()
        cache.set("Arc", iconData: "aaa")
        cache.set("Xcode", iconData: "bbb")

        let response = cache.toResponse()
        XCTAssertEqual(response.type, "appIcons")
        XCTAssertEqual(response.icons.count, 2)
        XCTAssertEqual(response.icons["Arc"], "aaa")
        XCTAssertEqual(response.icons["Xcode"], "bbb")
    }

    func test_iconCache_toResponseForApps_returnsOnlyRequestedIcons() {
        let cache = IconCache()
        cache.set("Arc", iconData: "aaa")
        cache.set("Xcode", iconData: "bbb")
        cache.set("Terminal", iconData: "ccc")

        let response = cache.toResponse(for: ["Arc", "Terminal"])
        XCTAssertEqual(response.icons.count, 2)
        XCTAssertEqual(response.icons["Arc"], "aaa")
        XCTAssertEqual(response.icons["Terminal"], "ccc")
        XCTAssertNil(response.icons["Xcode"])
    }

    func test_iconCache_toResponseForApps_unknownApp_isSkipped() {
        let cache = IconCache()
        cache.set("Arc", iconData: "aaa")

        let response = cache.toResponse(for: ["Arc", "Unknown"])
        XCTAssertEqual(response.icons.count, 1)
        XCTAssertEqual(response.icons["Arc"], "aaa")
    }

    // MARK: - Integration: cache + unique apps workflow

    func test_workflow_newAppsDetected_cacheUpdated() {
        let cache = IconCache()

        // First batch of windows
        let windows1 = [
            WindowInfo(id: 1, app: "Safari", title: "Tab 1", pid: 100, frontmost: true),
            WindowInfo(id: 2, app: "Xcode", title: "Project", pid: 200, frontmost: false),
        ]
        let allApps1 = IconCache.uniqueAppNames(from: windows1)
        let newApps1 = cache.filterNew(allApps1)
        XCTAssertEqual(newApps1, ["Safari", "Xcode"])

        // Simulate caching
        for app in newApps1 {
            cache.set(app, iconData: "icon_\(app)")
        }

        // Second batch with one new app (Spec-04 §9 #2: 재실행 시 캐시에 있으면 재전송 안 함)
        let windows2 = [
            WindowInfo(id: 1, app: "Safari", title: "Tab 1", pid: 100, frontmost: true),
            WindowInfo(id: 3, app: "Terminal", title: "zsh", pid: 300, frontmost: false),
            WindowInfo(id: 2, app: "Xcode", title: "Project", pid: 200, frontmost: false),
        ]
        let allApps2 = IconCache.uniqueAppNames(from: windows2)
        let newApps2 = cache.filterNew(allApps2)
        XCTAssertEqual(newApps2, ["Terminal"])  // Only Terminal is new
    }
}
