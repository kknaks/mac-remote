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

    // Note: WebSocketServer 인스턴스 생성/시작/정지 테스트는 macOS 필요 (수동 검증)
    // - 서버 시작 → "WebSocket server started on port 8765" 로그 확인
    // - websocat ws://localhost:8765 연결 → 연결 로그 확인
    // - 연결 해제 → 해제 로그 확인
}
