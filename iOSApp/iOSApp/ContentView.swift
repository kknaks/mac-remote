import SwiftUI

/// 3탭 TabView 메인 화면
/// - 창 목록 (macwindow)
/// - 매크로 (command)
/// - 설정 (gearshape)
///
/// Work-13 Task 5: 재연결 오버레이 + 앱 라이프사이클 처리
struct ContentView: View {
    @EnvironmentObject var wsManager: WebSocketManager

    /// 앱 라이프사이클 감시 (Spec-05 §9 #5: 백그라운드/포그라운드 전환)
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        TabView {
            WindowListView()
                .tabItem {
                    Label("창 목록", systemImage: "macwindow")
                }

            MacroView()
                .tabItem {
                    Label("매크로", systemImage: "command")
                }

            SettingsView()
                .tabItem {
                    Label("설정", systemImage: "gearshape")
                }
        }
        .tint(Color.accent)
        .preferredColorScheme(.dark)
        // 재연결 중 오버레이 (Work-13 Task 5)
        .reconnectingOverlay()
        // 앱 라이프사이클 처리 (Spec-05 §9 #5)
        .onChange(of: scenePhase) { _, newPhase in
            handleScenePhaseChange(newPhase)
        }
    }

    // MARK: - App Lifecycle (Spec-05 §9 #5)

    /// 앱 백그라운드/포그라운드 전환 시 연결 관리
    /// - active: 포그라운드 복귀 → 연결 상태 확인, 필요 시 재연결
    /// - background: 백그라운드 진입 → 연결 유지 (iOS가 자동 관리)
    private func handleScenePhaseChange(_ phase: ScenePhase) {
        switch phase {
        case .active:
            // 포그라운드 복귀 시 연결 상태 확인
            if wsManager.connectionState == .disconnected && !wsManager.host.isEmpty {
                // 자동 재연결이 켜져 있으면 재연결 시도
                if AppSettings.autoReconnect {
                    print("[INFO] App became active — attempting reconnect")
                    wsManager.manualReconnect()
                }
            } else if wsManager.connectionState == .connected {
                // 연결된 상태면 창 목록 갱신
                wsManager.sendListWindows()
            }
        case .inactive:
            // 전환 중 — 별도 처리 없음
            break
        case .background:
            // 백그라운드 — 연결 유지 (iOS가 소켓 관리)
            print("[INFO] App entered background")
        @unknown default:
            break
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(WebSocketManager())
}
