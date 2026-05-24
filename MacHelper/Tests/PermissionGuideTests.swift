import XCTest
@testable import MacHelperLib

final class PermissionGuideTests: XCTestCase {

    // MARK: - 안내 메시지 상수 검증

    func test_accessibilityDeniedMessage_containsSystemSettings() {
        XCTAssertTrue(accessibilityDeniedMessage.contains("시스템 설정"))
        XCTAssertTrue(accessibilityDeniedMessage.contains("손쉬운 사용"))
    }

    func test_screenRecordingDeniedMessage_containsSystemSettings() {
        XCTAssertTrue(screenRecordingDeniedMessage.contains("시스템 설정"))
        XCTAssertTrue(screenRecordingDeniedMessage.contains("화면 기록"))
    }

    func test_allPermissionsGrantedMessage_containsSuccess() {
        XCTAssertTrue(allPermissionsGrantedMessage.contains("정상 작동"))
    }

    // MARK: - permissionGuidanceMessages

    func test_guidance_bothDenied_twoWarnings() {
        let status = PermissionStatus(accessibility: false, screenRecording: false)
        let messages = permissionGuidanceMessages(for: status)

        XCTAssertEqual(messages.count, 2)
        XCTAssertTrue(messages[0].contains("손쉬운 사용"))
        XCTAssertTrue(messages[1].contains("화면 기록"))
    }

    func test_guidance_bothGranted_successMessage() {
        let status = PermissionStatus(accessibility: true, screenRecording: true)
        let messages = permissionGuidanceMessages(for: status)

        XCTAssertEqual(messages.count, 1)
        XCTAssertTrue(messages[0].contains("정상 작동"))
    }

    func test_guidance_accessibilityDeniedOnly_oneWarning() {
        let status = PermissionStatus(accessibility: false, screenRecording: true)
        let messages = permissionGuidanceMessages(for: status)

        XCTAssertEqual(messages.count, 1)
        XCTAssertTrue(messages[0].contains("손쉬운 사용"))
    }

    func test_guidance_screenRecordingDeniedOnly_oneWarning() {
        let status = PermissionStatus(accessibility: true, screenRecording: false)
        let messages = permissionGuidanceMessages(for: status)

        XCTAssertEqual(messages.count, 1)
        XCTAssertTrue(messages[0].contains("화면 기록"))
    }

    func test_guidance_bothDenied_noSuccessMessage() {
        let status = PermissionStatus(accessibility: false, screenRecording: false)
        let messages = permissionGuidanceMessages(for: status)

        let hasSuccess = messages.contains { $0.contains("정상 작동") }
        XCTAssertFalse(hasSuccess)
    }

    func test_guidance_bothGranted_noWarnings() {
        let status = PermissionStatus(accessibility: true, screenRecording: true)
        let messages = permissionGuidanceMessages(for: status)

        let hasWarning = messages.contains { $0.contains("⚠️") }
        XCTAssertFalse(hasWarning)
    }
}
