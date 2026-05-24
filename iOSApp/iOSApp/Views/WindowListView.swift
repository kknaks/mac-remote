import SwiftUI

/// 창 목록 탭 (Work-10, Spec-01 §8, Spec-02 §8)
/// WebSocketManager.windows를 카드형 리스트로 표시
/// 카드 탭 → focus 명령 전송 + 햅틱 피드백
struct WindowListView: View {
    @EnvironmentObject var wsManager: WebSocketManager

    /// 아이콘 캐시 (앱 이름 → UIImage)
    @State private var iconCache: [String: UIImage] = [:]

    /// 햅틱 피드백 제너레이터
    private let haptic = UIImpactFeedbackGenerator(style: .medium)

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 연결 상태 헤더 (Work-13 Task 3)
                ConnectionStatusHeader()

                Group {
                    if wsManager.windows.isEmpty {
                        // 빈 목록 (Spec-01 §9 엣지 케이스 #1)
                        emptyStateView
                    } else {
                        // 창 목록 (Spec-01 §8: 카드형 리스트, 당겨서 새로고침)
                        windowListContent
                    }
                }
                .frame(maxHeight: .infinity)
            }
            // 미연결 오버레이 (Work-13 Task 4)
            .disconnectedOverlay()
            .navigationTitle("창 목록")
            .onChange(of: wsManager.appIcons) { _, newIcons in
                updateIconCache(from: newIcons)
            }
        }
    }

    // MARK: - Window List Content

    private var windowListContent: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(wsManager.windows) { window in
                    WindowCardView(
                        window: window,
                        appIcon: iconCache[window.app]
                    )
                    .onTapGesture {
                        // Spec-02 §8: 카드 탭 → focus 전송 + 햅틱
                        haptic.impactOccurred()
                        wsManager.sendFocus(windowId: window.id)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
        }
        .refreshable {
            // Spec-01 §8: 당겨서 새로고침
            wsManager.sendListWindows()
            // 잠시 대기하여 UI 피드백 제공
            try? await Task.sleep(nanoseconds: 300_000_000)
        }
    }

    // MARK: - Empty State (Spec-01 §9 #1)

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "macwindow")
                .font(.system(size: 48))
                .foregroundStyle(Color.accent.opacity(0.5))
            Text("열린 창이 없습니다")
                .font(.title3)
                .foregroundStyle(.secondary)
            Text("Mac에서 앱을 열면 여기에 표시됩니다.")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Icon Cache (Spec-04 §7 Step 5)

    /// base64 문자열을 UIImage로 디코딩하여 캐시에 저장
    private func updateIconCache(from icons: [String: String]) {
        for (appName, base64String) in icons {
            // 이미 캐시에 있으면 스킵
            if iconCache[appName] != nil { continue }

            // base64 → Data → UIImage (Spec-04 §6: 유효한 base64)
            if let data = Data(base64Encoded: base64String),
               let image = UIImage(data: data) {
                iconCache[appName] = image
            }
        }
    }
}

#Preview {
    WindowListView()
        .environmentObject(WebSocketManager())
        .preferredColorScheme(.dark)
}
