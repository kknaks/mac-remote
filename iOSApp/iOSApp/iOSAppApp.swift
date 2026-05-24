import SwiftUI

/// 앱 엔트리 포인트 (iOS 17+, SwiftUI)
/// 앱 시작 시 저장된 연결 정보가 있으면 자동 연결 시도 (Spec-07 §9-2, Work-12 Task 7)
@main
struct iOSAppApp: App {
    @StateObject private var wsManager = WebSocketManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(wsManager)
                .onAppear {
                    autoConnectIfNeeded()
                }
        }
    }

    /// 저장된 연결 정보로 자동 연결 시도
    /// - Spec-07 §9-2: 이전 페어링 정보로 자동 연결 시도
    /// - autoReconnect 설정이 켜져 있을 때만 시도
    private func autoConnectIfNeeded() {
        guard AppSettings.autoReconnect else { return }
        guard let info = ConnectionInfoStore.load() else { return }
        guard wsManager.connectionState == .disconnected else { return }

        print("[INFO] Auto-connecting to saved server: \(info.displayString)")
        wsManager.connect(host: info.host, port: info.port)
    }
}
