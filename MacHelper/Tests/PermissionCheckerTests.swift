import XCTest
@testable import MacHelperLib

final class PermissionStatusTests: XCTestCase {

    // MARK: - PermissionStatus model

    func test_permissionStatus_encodesCorrectly() throws {
        let status = PermissionStatus(accessibility: true, screenRecording: false)
        let data = try JSONEncoder().encode(status)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertEqual(json["accessibility"] as? Bool, true)
        XCTAssertEqual(json["screenRecording"] as? Bool, false)
    }

    func test_permissionStatus_roundTrip() throws {
        let original = PermissionStatus(accessibility: false, screenRecording: true)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(PermissionStatus.self, from: data)

        XCTAssertEqual(original, decoded)
    }

    func test_permissionStatus_bothTrue() throws {
        let status = PermissionStatus(accessibility: true, screenRecording: true)
        XCTAssertTrue(status.accessibility)
        XCTAssertTrue(status.screenRecording)
    }

    func test_permissionStatus_bothFalse() throws {
        let status = PermissionStatus(accessibility: false, screenRecording: false)
        XCTAssertFalse(status.accessibility)
        XCTAssertFalse(status.screenRecording)
    }

    // MARK: - PermissionResponse model (Spec-06 §3)

    func test_permissionResponse_typeIsPermissions() throws {
        let status = PermissionStatus(accessibility: true, screenRecording: false)
        let response = PermissionResponse(status: status)
        XCTAssertEqual(response.type, "permissions")
    }

    func test_permissionResponse_encodesToSpecFormat() throws {
        let status = PermissionStatus(accessibility: true, screenRecording: false)
        let response = PermissionResponse(status: status)
        let data = try JSONEncoder().encode(response)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertEqual(json["type"] as? String, "permissions")
        XCTAssertEqual(json["accessibility"] as? Bool, true)
        XCTAssertEqual(json["screenRecording"] as? Bool, false)
    }

    func test_permissionResponse_roundTrip() throws {
        let status = PermissionStatus(accessibility: false, screenRecording: true)
        let response = PermissionResponse(status: status)
        let data = try JSONEncoder().encode(response)
        let decoded = try JSONDecoder().decode(PermissionResponse.self, from: data)

        XCTAssertEqual(response, decoded)
    }

    // MARK: - Screen Recording 간접 확인 로직

    func test_screenRecording_nonEmptyTitles_returnsTrue() {
        let result = checkScreenRecordingByTitles(
            windowTitles: ["Google", "Xcode", ""],
            windowCount: 3
        )
        XCTAssertTrue(result)
    }

    func test_screenRecording_allEmptyTitles_returnsFalse() {
        // 권한 없으면 모든 창 제목이 빈 문자열
        let result = checkScreenRecordingByTitles(
            windowTitles: ["", "", ""],
            windowCount: 3
        )
        XCTAssertFalse(result)
    }

    func test_screenRecording_noWindows_returnsTrue() {
        // 창이 없으면 판단 불가 → 보수적으로 true
        let result = checkScreenRecordingByTitles(
            windowTitles: [],
            windowCount: 0
        )
        XCTAssertTrue(result)
    }

    func test_screenRecording_oneNonEmptyTitle_returnsTrue() {
        let result = checkScreenRecordingByTitles(
            windowTitles: ["", "", "Terminal"],
            windowCount: 3
        )
        XCTAssertTrue(result)
    }

    func test_screenRecording_emptyTitlesArray_withWindows_returnsFalse() {
        // 창은 있지만 제목 수집이 전혀 안 된 경우
        let result = checkScreenRecordingByTitles(
            windowTitles: [],
            windowCount: 5
        )
        XCTAssertFalse(result)
    }
}
