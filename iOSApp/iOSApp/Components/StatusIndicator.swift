import SwiftUI

/// 연결 상태 표시등 컴포넌트 — placeholder (Work-09에서 구현)
struct StatusIndicator: View {
    let isConnected: Bool

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(isConnected ? Color.green : Color.red)
                .frame(width: 8, height: 8)
            Text(isConnected ? "연결됨" : "연결 끊김")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        StatusIndicator(isConnected: true)
        StatusIndicator(isConnected: false)
    }
    .preferredColorScheme(.dark)
}
