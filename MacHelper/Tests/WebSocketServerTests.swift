import XCTest
@testable import MacHelperLib

final class WebSocketServerTests: XCTestCase {

    // MARK: - Task 2: Server Constants (Spec-05 §3-2)

    func test_defaultPort_is8765() {
        XCTAssertEqual(defaultPort, 8765)
    }

    func test_windowListPushInterval_is1point5() {
        XCTAssertEqual(windowListPushInterval, 1.5, accuracy: 0.001)
    }

    func test_heartbeatInterval_is10() {
        XCTAssertEqual(heartbeatInterval, 10.0, accuracy: 0.001)
    }

    // MARK: - Task 8: appIcons push (icon cache integration)

    func test_iconCache_filterNew_detectsNewApps() {
        let cache = IconCache()
        cache.set("Arc", iconData: "base64data")

        let newApps = cache.filterNew(["Arc", "Xcode", "Safari"])
        XCTAssertEqual(newApps, ["Xcode", "Safari"])
    }

    func test_iconCache_filterNew_emptyCache_allNew() {
        let cache = IconCache()
        let newApps = cache.filterNew(["Arc", "Xcode"])
        XCTAssertEqual(newApps, ["Arc", "Xcode"])
    }

    func test_iconCache_filterNew_allCached_noneNew() {
        let cache = IconCache()
        cache.set("Arc", iconData: "data1")
        cache.set("Xcode", iconData: "data2")

        let newApps = cache.filterNew(["Arc", "Xcode"])
        XCTAssertEqual(newApps, [])
    }

    func test_iconCache_toResponseForApps_returnsOnlyRequested() {
        let cache = IconCache()
        cache.set("Arc", iconData: "arcData")
        cache.set("Xcode", iconData: "xcodeData")
        cache.set("Safari", iconData: "safariData")

        let response = cache.toResponse(for: ["Arc", "Xcode"])
        XCTAssertEqual(response.type, "appIcons")
        XCTAssertEqual(response.icons.count, 2)
        XCTAssertEqual(response.icons["Arc"], "arcData")
        XCTAssertEqual(response.icons["Xcode"], "xcodeData")
        XCTAssertNil(response.icons["Safari"])
    }

    func test_appIconsResponse_encodesToSpecFormat() throws {
        let response = AppIconsResponse(icons: ["Arc": "base64data"])
        let data = try JSONEncoder().encode(response)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertEqual(json["type"] as? String, "appIcons")
        let icons = json["icons"] as? [String: String]
        XCTAssertEqual(icons?["Arc"], "base64data")
    }

    // Note: pushNewAppIcons 실제 동작은 macOS에서 수동 검증
    // - WebSocket 연결 후 새 앱이 열리면 appIcons push 확인
}
