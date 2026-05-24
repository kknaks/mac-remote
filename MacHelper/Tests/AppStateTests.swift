import XCTest
@testable import MacHelperLib

final class AppStateTests: XCTestCase {

    // MARK: - Initial State

    func test_initialState_serverNotRunning() {
        let state = AppState()
        XCTAssertFalse(state.isServerRunning)
    }

    func test_initialState_defaultPort() {
        let state = AppState()
        XCTAssertEqual(state.serverPort, defaultPort)
    }

    func test_initialState_customPort() {
        let state = AppState(port: 9999)
        XCTAssertEqual(state.serverPort, 9999)
    }

    func test_initialState_noClients() {
        let state = AppState()
        XCTAssertEqual(state.connectedClients, 0)
    }

    func test_initialState_permissionsBothFalse() {
        let state = AppState()
        XCTAssertFalse(state.permissions.accessibility)
        XCTAssertFalse(state.permissions.screenRecording)
    }

    // MARK: - Server State Updates

    func test_serverDidStart_setsRunningTrue() {
        let state = AppState()
        state.serverDidStart(port: 8765)
        XCTAssertTrue(state.isServerRunning)
    }

    func test_serverDidStart_updatesPort() {
        let state = AppState()
        state.serverDidStart(port: 9000)
        XCTAssertEqual(state.serverPort, 9000)
    }

    func test_serverDidStop_setsRunningFalse() {
        let state = AppState()
        state.serverDidStart(port: 8765)
        state.serverDidStop()
        XCTAssertFalse(state.isServerRunning)
    }

    func test_serverDidStop_resetsClientCount() {
        let state = AppState()
        state.serverDidStart(port: 8765)
        state.updateClientCount(3)
        state.serverDidStop()
        XCTAssertEqual(state.connectedClients, 0)
    }

    // MARK: - Client Count

    func test_updateClientCount_setsCount() {
        let state = AppState()
        state.updateClientCount(5)
        XCTAssertEqual(state.connectedClients, 5)
    }

    func test_updateClientCount_negativeClampedToZero() {
        let state = AppState()
        state.updateClientCount(-1)
        XCTAssertEqual(state.connectedClients, 0)
    }

    // MARK: - Permission Updates

    func test_updatePermissions_updatesState() {
        let state = AppState()
        let perms = PermissionStatus(accessibility: true, screenRecording: false)
        state.updatePermissions(perms)
        XCTAssertTrue(state.permissions.accessibility)
        XCTAssertFalse(state.permissions.screenRecording)
    }

    func test_updatePermissions_bothTrue() {
        let state = AppState()
        let perms = PermissionStatus(accessibility: true, screenRecording: true)
        state.updatePermissions(perms)
        XCTAssertTrue(state.allPermissionsGranted)
    }

    func test_allPermissionsGranted_falseWhenPartial() {
        let state = AppState()
        state.updatePermissions(PermissionStatus(accessibility: true, screenRecording: false))
        XCTAssertFalse(state.allPermissionsGranted)
    }

    // MARK: - Display Strings

    func test_connectionStatusText_serverOff() {
        let state = AppState()
        XCTAssertEqual(state.connectionStatusText, "서버 꺼짐")
    }

    func test_connectionStatusText_waiting() {
        let state = AppState()
        state.serverDidStart(port: 8765)
        XCTAssertEqual(state.connectionStatusText, "대기 중")
    }

    func test_connectionStatusText_connected() {
        let state = AppState()
        state.serverDidStart(port: 8765)
        state.updateClientCount(2)
        XCTAssertEqual(state.connectionStatusText, "연결 2대")
    }

    func test_addressText() {
        let state = AppState(port: 8765)
        XCTAssertEqual(state.addressText, "포트: 8765")
    }

    func test_fullAddressText() {
        let state = AppState(port: 8765)
        XCTAssertEqual(state.fullAddressText(ip: "192.168.1.10"), "192.168.1.10:8765")
    }

    func test_fullAddressText_localhost() {
        let state = AppState(port: 9000)
        XCTAssertEqual(state.fullAddressText(ip: "localhost"), "localhost:9000")
    }

    func test_accessibilityStatusText_granted() {
        let state = AppState()
        state.updatePermissions(PermissionStatus(accessibility: true, screenRecording: false))
        XCTAssertEqual(state.accessibilityStatusText, "✅ 손쉬운 사용")
    }

    func test_accessibilityStatusText_denied() {
        let state = AppState()
        XCTAssertEqual(state.accessibilityStatusText, "❌ 손쉬운 사용")
    }

    func test_screenRecordingStatusText_granted() {
        let state = AppState()
        state.updatePermissions(PermissionStatus(accessibility: false, screenRecording: true))
        XCTAssertEqual(state.screenRecordingStatusText, "✅ 화면 기록")
    }

    func test_screenRecordingStatusText_denied() {
        let state = AppState()
        XCTAssertEqual(state.screenRecordingStatusText, "❌ 화면 기록")
    }

    // MARK: - Menu Bar Icon

    func test_menuBarIconName_serverOff() {
        let state = AppState()
        XCTAssertEqual(state.menuBarIconName, "desktopcomputer.trianglebadge.exclamationmark")
    }

    func test_menuBarIconName_noClients() {
        let state = AppState()
        state.serverDidStart(port: 8765)
        XCTAssertEqual(state.menuBarIconName, "desktopcomputer")
    }

    func test_menuBarIconName_withClients() {
        let state = AppState()
        state.serverDidStart(port: 8765)
        state.updateClientCount(1)
        XCTAssertEqual(state.menuBarIconName, "desktopcomputer.and.arrow.down")
    }

    // MARK: - System Settings URLs

    func test_systemSettingsURL_accessibility() {
        XCTAssertTrue(SystemSettingsURL.accessibility.contains("Accessibility"))
    }

    func test_systemSettingsURL_screenRecording() {
        XCTAssertTrue(SystemSettingsURL.screenRecording.contains("ScreenCapture"))
    }
}
