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

    // MARK: - Task 9: windowList periodic push (1.5초)

    func test_pushInterval_matchesSpec() {
        // Spec-05 §3-2: windowListPushInterval = 1.5초
        XCTAssertEqual(windowListPushInterval, 1.5, accuracy: 0.001)
    }

    func test_windowListResponse_format_hasTypeAndWindows() throws {
        // push되는 windowList 메시지 형식 검증
        let windows = [
            WindowInfo(id: 1, app: "Arc", title: "Tab", pid: 100, frontmost: true)
        ]
        let response = WindowListResponse(windows: windows)
        let data = try JSONEncoder().encode(response)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertEqual(json["type"] as? String, "windowList")
        let windowArray = json["windows"] as? [[String: Any]]
        XCTAssertEqual(windowArray?.count, 1)
    }

    // Note: 주기적 push 실제 동작은 macOS에서 수동 검증
    // - websocat 연결 후 1.5초마다 windowList 메시지 수신 확인
    // - 서버 로그: "[INFO] Pushing windowList to N clients"
}
