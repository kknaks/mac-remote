import SwiftUI

/// 창 카드 컴포넌트 — placeholder (Work-10에서 구현)
struct WindowCardView: View {
    let window: WindowInfo

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "macwindow")
                .font(.title2)
                .foregroundStyle(Color.accent)

            VStack(alignment: .leading, spacing: 2) {
                Text(window.app)
                    .font(.headline)
                Text(window.title.isEmpty ? "(제목 없음)" : window.title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            if window.frontmost {
                Circle()
                    .fill(Color.accent)
                    .frame(width: 8, height: 8)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    WindowCardView(window: WindowInfo(
        id: 1,
        app: "Safari",
        title: "Apple",
        pid: 1234,
        frontmost: true
    ))
    .preferredColorScheme(.dark)
    .padding()
}
