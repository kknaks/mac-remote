import XCTest
@testable import MacHelperLib

final class WindowInfoTests: XCTestCase {

    // MARK: - WindowInfo Codable

    func test_windowInfo_encodesToJSON_containsAllFields() throws {
        let info = WindowInfo(id: 123, app: "Arc", title: "Tab 1", pid: 456, frontmost: true)
        let data = try JSONEncoder().encode(info)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertEqual(json["id"] as? Int, 123)
        XCTAssertEqual(json["app"] as? String, "Arc")
        XCTAssertEqual(json["title"] as? String, "Tab 1")
        XCTAssertEqual(json["pid"] as? Int, 456)
        XCTAssertEqual(json["frontmost"] as? Bool, true)
    }

    func test_windowInfo_decodesFromJSON_roundTrip() throws {
        let original = WindowInfo(id: 99, app: "Xcode", title: "Project.swift", pid: 100, frontmost: false)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(WindowInfo.self, from: data)

        XCTAssertEqual(original, decoded)
    }

    func test_windowInfo_emptyTitle_isValid() throws {
        // Screen Recording 권한 없으면 title이 빈 문자열 (Spec-01 §2)
        let info = WindowInfo(id: 1, app: "Safari", title: "", pid: 2, frontmost: false)
        let data = try JSONEncoder().encode(info)
        let decoded = try JSONDecoder().decode(WindowInfo.self, from: data)

        XCTAssertEqual(decoded.title, "")
    }

    func test_windowInfo_equatable_sameValues_areEqual() {
        let a = WindowInfo(id: 1, app: "Arc", title: "Tab", pid: 10, frontmost: true)
        let b = WindowInfo(id: 1, app: "Arc", title: "Tab", pid: 10, frontmost: true)
        XCTAssertEqual(a, b)
    }

    func test_windowInfo_equatable_differentValues_areNotEqual() {
        let a = WindowInfo(id: 1, app: "Arc", title: "Tab", pid: 10, frontmost: true)
        let b = WindowInfo(id: 2, app: "Arc", title: "Tab", pid: 10, frontmost: true)
        XCTAssertNotEqual(a, b)
    }

    // MARK: - WindowListResponse

    func test_windowListResponse_typeIsWindowList() throws {
        let response = WindowListResponse(windows: [])
        XCTAssertEqual(response.type, "windowList")
    }

    func test_windowListResponse_encodesToSpecFormat() throws {
        // Spec-01 §3 응답 형식 검증
        let windows = [
            WindowInfo(id: 123, app: "Arc", title: "디자인 레퍼런스", pid: 400, frontmost: true),
            WindowInfo(id: 124, app: "Xcode", title: "MacHelper", pid: 401, frontmost: false),
        ]
        let response = WindowListResponse(windows: windows)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(response)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertEqual(json["type"] as? String, "windowList")
        let windowArray = json["windows"] as? [[String: Any]]
        XCTAssertEqual(windowArray?.count, 2)
        XCTAssertEqual(windowArray?[0]["id"] as? Int, 123)
        XCTAssertEqual(windowArray?[0]["frontmost"] as? Bool, true)
    }

    func test_windowListResponse_emptyWindows_isValid() throws {
        // Spec-01 §5 NO_WINDOWS: 빈 배열 정상 반환
        let response = WindowListResponse(windows: [])
        let data = try JSONEncoder().encode(response)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertEqual(json["type"] as? String, "windowList")
        let windowArray = json["windows"] as? [[String: Any]]
        XCTAssertEqual(windowArray?.count, 0)
    }

    func test_windowListResponse_roundTrip() throws {
        let windows = [
            WindowInfo(id: 1, app: "Safari", title: "Google", pid: 10, frontmost: false)
        ]
        let original = WindowListResponse(windows: windows)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(WindowListResponse.self, from: data)

        XCTAssertEqual(original, decoded)
    }
}
