import SwiftUI

// MARK: - Reconnecting Overlay (Spec-05 §4, §5, Work-13 Task 5)

/// 재연결 중 표시되는 오버레이
/// ProgressView + 재연결 시도 횟수 표시
/// - reconnecting 상태에서만 표시
/// - 배경을 반투명으로 덮어 상태를 명확히 전달
struct ReconnectingOverlay: View {
    @EnvironmentObject var wsManager: WebSocketManager

    var body: some View {
        if wsManager.connectionState == .reconnecting {
            ZStack {
                // 반투명 배경
                Color.black.opacity(0.4)
                    .ignoresSafeArea()

                VStack(spacing: 16) {
                    // 로딩 인디케이터
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(1.5)
                        .tint(Color.accent)

                    // 재연결 메시지
                    Text("재연결 중...")
                        .font(.headline)
                        .foregroundStyle(.white)

                    // 재연결 시도 횟수
                    Text("\(wsManager.reconnectAttempts)/\(wsMaxReconnectAttempts)")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))

                    // 연결 해제 버튼
                    Button {
                        wsManager.disconnect()
                    } label: {
                        Text("연결 취소")
                            .font(.callout)
                            .foregroundStyle(.white.opacity(0.8))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(Color(.systemGray4).opacity(0.5))
                            .clipShape(Capsule())
                    }
                    .padding(.top, 4)
                }
                .padding(32)
            }
        }
    }
}

// MARK: - ViewModifier for Reconnecting Overlay

/// View에 .reconnectingOverlay() modifier로 간편하게 적용
struct ReconnectingOverlayModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .overlay {
                ReconnectingOverlay()
            }
    }
}

extension View {
    /// 재연결 중 오버레이를 표시하는 modifier (Work-13 Task 5)
    func reconnectingOverlay() -> some View {
        modifier(ReconnectingOverlayModifier())
    }
}

#Preview {
    ZStack {
        Color(.systemBackground)
            .ignoresSafeArea()
        Text("콘텐츠 영역")
    }
    .overlay {
        ReconnectingOverlay()
            .environmentObject(WebSocketManager())
    }
    .preferredColorScheme(.dark)
}
