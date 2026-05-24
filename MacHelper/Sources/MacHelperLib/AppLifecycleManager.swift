import Foundation

// MARK: - AppLifecycleManager (Work-06 Task 6)

/// 앱 생명주기 관리자
/// 앱 시작 시 WebSocket 서버 자동 시작, 권한 확인, 주기적 상태 갱신을 담당
/// 순수 Swift 로직 — AppState와 WebSocketServer를 조율
public final class AppLifecycleManager {

    public let appState: AppState
    public let server: WebSocketServer
    private var statusTimer: Timer?

    /// 상태 갱신 주기 (초) — 클라이언트 수, 권한 상태 등
    public static let statusUpdateInterval: TimeInterval = 2.0

    public init(port: UInt16 = defaultPort) {
        self.appState = AppState(port: port)
        self.server = WebSocketServer(port: port)
    }

    // MARK: - Startup Sequence (Spec-06 §7: 첫 실행 플로우)

    /// 앱 시작 시 호출 — 서버 시작 + 권한 확인
    /// 1. 권한 확인 (Spec-06 §7 Step 2, 3)
    /// 2. WebSocket 서버 시작 (Spec-05)
    /// 3. 상태 갱신 타이머 시작
    public func start() {
        // Step 1: 권한 확인 (Spec-06 §7)
        checkPermissions()

        // Step 2: WebSocket 서버 시작
        do {
            try server.start()
            appState.serverDidStart(port: appState.serverPort)
            print("[INFO] MacHelper started — port \(appState.serverPort)")
        } catch {
            print("[ERROR] Failed to start WebSocket server: \(error)")
        }

        // Step 3: 주기적 상태 갱신 시작
        startStatusTimer()
    }

    /// 앱 종료 시 호출 — 서버 정지 + 타이머 해제
    public func stop() {
        stopStatusTimer()
        server.stop()
        appState.serverDidStop()
        print("[INFO] MacHelper stopped")
    }

    // MARK: - Permission Check

    /// 권한 상태 확인 및 AppState 갱신
    public func checkPermissions() {
        #if canImport(AppKit)
        let status = PermissionChecker.check()
        appState.updatePermissions(status)
        #else
        // Linux: 권한 확인 불가 — 기본값 유지
        appState.updatePermissions(PermissionStatus(accessibility: false, screenRecording: false))
        #endif
    }

    // MARK: - Status Update Timer

    /// 클라이언트 수, 권한 상태 주기적 갱신
    #if canImport(AppKit)
    private func startStatusTimer() {
        statusTimer = Timer.scheduledTimer(
            withTimeInterval: Self.statusUpdateInterval,
            repeats: true
        ) { [weak self] _ in
            self?.updateStatus()
        }
    }
    #else
    private func startStatusTimer() {
        // Linux: Timer.scheduledTimer는 RunLoop 필요 — 구조만 유지
    }
    #endif

    private func stopStatusTimer() {
        statusTimer?.invalidate()
        statusTimer = nil
    }

    /// 현재 상태 갱신 (타이머 콜백)
    private func updateStatus() {
        // 클라이언트 수 갱신
        appState.updateClientCount(server.clientCount)

        // 권한 상태 재확인 (Spec-06 §9 #1, #4: 권한 변경 감지)
        checkPermissions()
    }
}
