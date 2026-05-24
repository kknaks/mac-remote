import XCTest
@testable import MacHelperLib

final class AppLifecycleManagerTests: XCTestCase {

    // MARK: - Initialization

    func test_init_defaultPort() {
        let manager = AppLifecycleManager()
        XCTAssertEqual(manager.appState.serverPort, defaultPort)
    }

    func test_init_customPort() {
        let manager = AppLifecycleManager(port: 9999)
        XCTAssertEqual(manager.appState.serverPort, 9999)
    }

    func test_init_serverNotRunning() {
        let manager = AppLifecycleManager()
        XCTAssertFalse(manager.appState.isServerRunning)
    }

    func test_init_noClients() {
        let manager = AppLifecycleManager()
        XCTAssertEqual(manager.appState.connectedClients, 0)
    }

    // MARK: - Status Update Interval

    func test_statusUpdateInterval_isPositive() {
        XCTAssertGreaterThan(AppLifecycleManager.statusUpdateInterval, 0)
    }

    func test_statusUpdateInterval_value() {
        XCTAssertEqual(AppLifecycleManager.statusUpdateInterval, 2.0)
    }

    // MARK: - AppState Access

    func test_appState_isAccessible() {
        let manager = AppLifecycleManager()
        let state = manager.appState
        XCTAssertNotNil(state)
        XCTAssertFalse(state.isServerRunning)
    }

    func test_server_isAccessible() {
        let manager = AppLifecycleManager()
        let server = manager.server
        XCTAssertNotNil(server)
    }

    // MARK: - Permission Check (Linux: defaults to false)

    func test_checkPermissions_setsDefaultOnLinux() {
        let manager = AppLifecycleManager()
        manager.checkPermissions()
        // Linux: 권한 확인 불가 → 기본값 (false, false)
        XCTAssertFalse(manager.appState.permissions.accessibility)
        XCTAssertFalse(manager.appState.permissions.screenRecording)
    }
}
