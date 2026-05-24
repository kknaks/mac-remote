import XCTest
@testable import MacHelperLib

final class SystemSettingsTests: XCTestCase {

    // MARK: - System Settings URL Constants

    func test_accessibilityURL_containsAccessibility() {
        XCTAssertTrue(SystemSettingsURL.accessibility.contains("Accessibility"))
    }

    func test_accessibilityURL_isSystemPreferences() {
        XCTAssertTrue(SystemSettingsURL.accessibility.hasPrefix("x-apple.systempreferences:"))
    }

    func test_screenRecordingURL_containsScreenCapture() {
        XCTAssertTrue(SystemSettingsURL.screenRecording.contains("ScreenCapture"))
    }

    func test_screenRecordingURL_isSystemPreferences() {
        XCTAssertTrue(SystemSettingsURL.screenRecording.hasPrefix("x-apple.systempreferences:"))
    }

    // MARK: - Permission Display in AppState

    func test_permissionStatusDisplay_allDenied() {
        let state = AppState()
        // Initial: both false
        XCTAssertEqual(state.accessibilityStatusText, "❌ 손쉬운 사용")
        XCTAssertEqual(state.screenRecordingStatusText, "❌ 화면 기록")
        XCTAssertFalse(state.allPermissionsGranted)
    }

    func test_permissionStatusDisplay_allGranted() {
        let state = AppState()
        state.updatePermissions(PermissionStatus(accessibility: true, screenRecording: true))
        XCTAssertEqual(state.accessibilityStatusText, "✅ 손쉬운 사용")
        XCTAssertEqual(state.screenRecordingStatusText, "✅ 화면 기록")
        XCTAssertTrue(state.allPermissionsGranted)
    }

    func test_permissionStatusDisplay_partialGrant() {
        let state = AppState()
        state.updatePermissions(PermissionStatus(accessibility: true, screenRecording: false))
        XCTAssertEqual(state.accessibilityStatusText, "✅ 손쉬운 사용")
        XCTAssertEqual(state.screenRecordingStatusText, "❌ 화면 기록")
        XCTAssertFalse(state.allPermissionsGranted)
    }

    func test_permissionStatusDisplay_canUpdateMultipleTimes() {
        let state = AppState()
        // First: both denied
        XCTAssertFalse(state.allPermissionsGranted)

        // Then: accessibility granted
        state.updatePermissions(PermissionStatus(accessibility: true, screenRecording: false))
        XCTAssertTrue(state.permissions.accessibility)
        XCTAssertFalse(state.permissions.screenRecording)

        // Then: both granted
        state.updatePermissions(PermissionStatus(accessibility: true, screenRecording: true))
        XCTAssertTrue(state.allPermissionsGranted)

        // Then: revoked (Spec-06 §9 #1)
        state.updatePermissions(PermissionStatus(accessibility: false, screenRecording: false))
        XCTAssertFalse(state.allPermissionsGranted)
    }
}
