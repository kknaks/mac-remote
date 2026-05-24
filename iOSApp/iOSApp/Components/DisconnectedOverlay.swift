import SwiftUI

// MARK: - Disconnected Overlay (Spec-05 §8, Work-13 Task 4)

/// 미연결 시 콘텐츠 위에 표시되는 오버레이
/// "Mac 헬퍼에 연결되지 않았습니다" 메시지 + 설정 이동 안내
/// - disconnected 상태에서만 표시
/// - 배경을 반투명으로 덮어 콘텐츠 조작 방지
struct DisconnectedOverlay: View {
    @EnvironmentObject var wsManager: WebSocketManager

    /// 수동 재연결 콜백 (optional)
    var onReconnect: (() -> Void)?

    var body: some View {
        if wsManager.connectionState.isDisconnected {
            ZStack {
                // 반투명 배경
                Color.black.opacity(0.6)
                    .ignoresSafeArea()

                VStack(spacing: 20) {
                    // 아이콘
                    Image(systemName: "wifi.slash")
                        .font(.system(size: 56))
                        .foregroundStyle(.red.opacity(0.7))

                    // 메시지 (Spec-05 §5: SERVER_UNREACHABLE)
                    Text("Mac 헬퍼에 연결되지 않았습니다")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)

                    // 안내 텍스트
                    Text("설정 탭에서 Mac에 연결하세요.")
                        .font(.callout)
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.center)

                    // 재연결 버튼 (호스트 정보가 있을 때만 표시)
                    if !wsManager.host.isEmpty {
                        Button {
                            if let onReconnect = onReconnect {
                                onReconnect()
                            } else {
                                wsManager.manualReconnect()
                            }
                        } label: {
                            Label("다시 연결", systemImage: "arrow.clockwise")
                                .font(.callout)
                                .fontWeight(.medium)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 10)
                                .background(Color.accent.opacity(0.8))
                                .clipShape(Capsule())
                        }
                        .padding(.top, 4)
                    }
                }
                .padding(32)
            }
        }
    }
}

// MARK: - ViewModifier for Disconnected Overlay

/// View에 .disconnectedOverlay() modifier로 간편하게 적용
struct DisconnectedOverlayModifier: ViewModifier {
    var onReconnect: (() -> Void)?

    func body(content: Content) -> some View {
        content
            .overlay {
                DisconnectedOverlay(onReconnect: onReconnect)
            }
    }
}

extension View {
    /// 미연결 시 오버레이를 표시하는 modifier (Work-13 Task 4)
    func disconnectedOverlay(onReconnect: (() -> Void)? = nil) -> some View {
        modifier(DisconnectedOverlayModifier(onReconnect: onReconnect))
    }
}

#Preview {
    ZStack {
        Color(.systemBackground)
            .ignoresSafeArea()
        Text("콘텐츠 영역")
    }
    .overlay {
        DisconnectedOverlay()
            .environmentObject(WebSocketManager())
    }
    .preferredColorScheme(.dark)
}
