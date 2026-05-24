import SwiftUI

// MARK: - Status Indicator (Work-12 Task 5)

/// 연결 상태 표시등 컴포넌트
/// - connected: 녹색 원 + "연결됨"
/// - connecting/reconnecting: 황색 원 + 상태 텍스트
/// - disconnected: 적색 원 + "연결 끊김"
struct StatusIndicator: View {
    let state: ConnectionState

    /// 상태별 색상 (녹/황/적)
    private var color: Color {
        switch state {
        case .connected:
            return .green
        case .connecting, .reconnecting:
            return .yellow
        case .disconnected:
            return .red
        }
    }

    /// 상태별 텍스트
    private var text: String {
        switch state {
        case .connected:
            return "연결됨"
        case .connecting:
            return "연결 중..."
        case .reconnecting:
            return "재연결 중..."
        case .disconnected:
            return "연결 끊김"
        }
    }

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
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
    }
    .preferredColorScheme(.dark)
}
