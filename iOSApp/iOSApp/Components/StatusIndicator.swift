import SwiftUI

// MARK: - Status Indicator (Work-12 Task 5, Work-13 Task 2)

/// 연결 상태 표시등 컴포넌트 — 원형 인디케이터 + 상태 텍스트
/// - connected: 녹색 원 + "연결됨"
/// - connecting/reconnecting: 황색 원 + 상태 텍스트 + 맥동 애니메이션
/// - disconnected: 적색 원 + "연결 끊김"
struct StatusIndicator: View {
    let state: ConnectionState

    /// 맥동 애니메이션 상태 (connecting/reconnecting에서 사용)
    @State private var isPulsing: Bool = false

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(state.indicatorColor)
                .frame(width: 8, height: 8)
                .scaleEffect(isPulsing ? 1.3 : 1.0)
                .opacity(isPulsing ? 0.6 : 1.0)
                .animation(
                    state.isAttempting
                        ? .easeInOut(duration: 0.8).repeatForever(autoreverses: true)
                        : .default,
                    value: isPulsing
                )
            Text(state.displayText)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .onChange(of: state) { _, newState in
            isPulsing = newState.isAttempting
        }
        .onAppear {
            isPulsing = state.isAttempting
        }
    }
}

// MARK: - Connection Status Header (Spec-05 §8, Work-13 Task 2)

/// 네비게이션 바 하단에 표시되는 연결 상태 헤더 배너
/// - connected: 표시하지 않음 (공간 절약)
/// - connecting/reconnecting: 노란색 배너 + ProgressView
/// - disconnected: 빨간색 배너
struct ConnectionStatusHeader: View {
    @EnvironmentObject var wsManager: WebSocketManager

    var body: some View {
        if wsManager.connectionState != .connected {
            HStack(spacing: 8) {
                // 연결 시도 중이면 로딩 인디케이터 표시
                if wsManager.connectionState.isAttempting {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(0.7)
                        .tint(.white)
                }

                Circle()
                    .fill(wsManager.connectionState.indicatorColor)
                    .frame(width: 8, height: 8)

                Text(headerText)
                    .font(.caption)
                    .fontWeight(.medium)

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(headerBackgroundColor.opacity(0.15))
            .foregroundStyle(headerBackgroundColor)
        }
    }

    /// 헤더 배경 색상
    private var headerBackgroundColor: Color {
        switch wsManager.connectionState {
        case .disconnected:
            return .red
        case .connecting, .reconnecting:
            return .yellow
        case .connected:
            return .green
        }
    }

    /// 헤더 표시 텍스트
    private var headerText: String {
        switch wsManager.connectionState {
        case .disconnected:
            return "Mac 헬퍼에 연결되지 않았습니다"
        case .connecting:
            return "연결 중..."
        case .reconnecting:
            return "재연결 중... (\(wsManager.reconnectAttempts)/\(wsMaxReconnectAttempts))"
        case .connected:
            return "연결됨"
        }
    }
}

// MARK: - Legacy convenience init (Bool 기반)

extension StatusIndicator {
    /// 기존 호환용 초기화 (Bool → ConnectionState)
    init(isConnected: Bool) {
        self.state = isConnected ? .connected : .disconnected
    }
}

#Preview {
    VStack(spacing: 12) {
        StatusIndicator(state: .connected)
        StatusIndicator(state: .connecting)
        StatusIndicator(state: .reconnecting)
        StatusIndicator(state: .disconnected)
        // Legacy
        StatusIndicator(isConnected: true)
        StatusIndicator(isConnected: false)

        Divider()

        // Connection Status Header
        ConnectionStatusHeader()
            .environmentObject(WebSocketManager())
    }
    .preferredColorScheme(.dark)
}
