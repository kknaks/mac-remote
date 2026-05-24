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
            .onAppear {
                updateIconCache(from: wsManager.appIcons)
            }
            .onChange(of: wsManager.appIcons) { _, newIcons in
                updateIconCache(from: newIcons)
            }
        }
    }

    // MARK: - Window List Content

    private var windowListContent: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80), spacing: 16)], spacing: 16) {
                ForEach(wsManager.windows) { window in
                    appGridCell(window: window)
                        .onTapGesture {
                            // Spec-02 §8: 카드 탭 → focus 전송 + 햅틱
                            haptic.impactOccurred()
                            wsManager.sendFocus(windowId: window.id)
                        }
                }
            }
            .padding(.horizontal)
            .padding(.top, 12)
        }
        .refreshable {
            // Spec-01 §8: 당겨서 새로고침
            wsManager.sendListWindows()
            // 잠시 대기하여 UI 피드백 제공
            try? await Task.sleep(nanoseconds: 300_000_000)
        }
    }

    /// 앱 아이콘 그리드 셀 (아이콘 + 앱 이름)
    private func appGridCell(window: WindowInfo) -> some View {
        VStack(spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.06))
                    .frame(width: 64, height: 64)

                if let icon = iconCache[window.app] {
                    Image(uiImage: icon)
                        .resizable()
                        .interpolation(.high)
                        .scaledToFit()
                        .frame(width: 52, height: 52)
                } else {
                    Image(systemName: "app.dashed")
                        .font(.system(size: 28))
                        .foregroundStyle(.secondary)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(window.frontmost ? Color.accent : Color.clear, lineWidth: 2)
            )

            Text(window.app)
                .font(.caption2)
                .lineLimit(1)
                .truncationMode(.tail)
                .foregroundStyle(.primary)
        }
        .frame(width: 80)
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
