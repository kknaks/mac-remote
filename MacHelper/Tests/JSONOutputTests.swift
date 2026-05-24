import XCTest
@testable import MacHelperLib

final class JSONOutputTests: XCTestCase {

    // MARK: - formatWindowListJSON

    func test_formatWindowListJSON_specFormat_containsTypeAndWindows() throws {
        let windows = [
            WindowInfo(id: 123, app: "Arc", title: "디자인 레퍼런스 — 12개 탭", pid: 400, frontmost: true),
            WindowInfo(id: 124, app: "Xcode", title: "MacroHelper — AppDelegate.swift", pid: 401, frontmost: false),
            WindowInfo(id: 125, app: "Terminal", title: "bash", pid: 402, frontmost: false),
        ]
        let jsonString = formatWindowListJSON(windows)
        let data = jsonString.data(using: .utf8)!
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        // Spec-01 §3: type은 "windowList"
        XCTAssertEqual(json["type"] as? String, "windowList")

        // Spec-01 §3: windows 배열
        let windowArray = json["windows"] as? [[String: Any]]
        XCTAssertEqual(windowArray?.count, 3)

        // 첫 번째 창 검증
        XCTAssertEqual(windowArray?[0]["id"] as? Int, 123)
        XCTAssertEqual(windowArray?[0]["app"] as? String, "Arc")
        XCTAssertEqual(windowArray?[0]["frontmost"] as? Bool, true)
    }

    func test_formatWindowListJSON_emptyWindows_validJSON() throws {
        let jsonString = formatWindowListJSON([])
        let data = jsonString.data(using: .utf8)!
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertEqual(json["type"] as? String, "windowList")
        let windowArray = json["windows"] as? [[String: Any]]
        XCTAssertEqual(windowArray?.count, 0)
    }

    func test_formatWindowListJSON_emptyTitle_validJSON() throws {
        // Screen Recording 권한 없을 때 title이 빈 문자열
        let windows = [
            WindowInfo(id: 1, app: "Safari", title: "", pid: 100, frontmost: false),
        ]
        let jsonString = formatWindowListJSON(windows)
        let data = jsonString.data(using: .utf8)!
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        let windowArray = json["windows"] as? [[String: Any]]
        XCTAssertEqual(windowArray?[0]["title"] as? String, "")
    }

    func test_formatWindowListJSON_isPrettyPrinted() {
        let windows = [
            WindowInfo(id: 1, app: "App", title: "Title", pid: 10, frontmost: false),
        ]
        let jsonString = formatWindowListJSON(windows)
        // Pretty printed JSON contains newlines
        XCTAssertTrue(jsonString.contains("\n"))
    }

    // MARK: - formatPermissionJSON

    func test_formatPermissionJSON_specFormat() throws {
        // Spec-06 §3 응답 형식
        let status = PermissionStatus(accessibility: true, screenRecording: false)
        let jsonString = formatPermissionJSON(status)
        let data = jsonString.data(using: .utf8)!
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertEqual(json["type"] as? String, "permissions")
        XCTAssertEqual(json["accessibility"] as? Bool, true)
        XCTAssertEqual(json["screenRecording"] as? Bool, false)
    }

    func test_formatPermissionJSON_bothTrue() throws {
        let status = PermissionStatus(accessibility: true, screenRecording: true)
        let jsonString = formatPermissionJSON(status)
        let data = jsonString.data(using: .utf8)!
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertEqual(json["accessibility"] as? Bool, true)
        XCTAssertEqual(json["screenRecording"] as? Bool, true)
    }

    func test_formatPermissionJSON_bothFalse() throws {
        let status = PermissionStatus(accessibility: false, screenRecording: false)
        let jsonString = formatPermissionJSON(status)
        let data = jsonString.data(using: .utf8)!
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertEqual(json["accessibility"] as? Bool, false)
        XCTAssertEqual(json["screenRecording"] as? Bool, false)
    }

    func test_formatPermissionJSON_roundTripThroughJSON() throws {
        let original = PermissionStatus(accessibility: true, screenRecording: true)
        let jsonString = formatPermissionJSON(original)
        let data = jsonString.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(PermissionResponse.self, from: data)

        XCTAssertEqual(decoded.type, "permissions")
        XCTAssertEqual(decoded.accessibility, true)
        XCTAssertEqual(decoded.screenRecording, true)
    }
}
