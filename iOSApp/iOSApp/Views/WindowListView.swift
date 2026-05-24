import SwiftUI

/// 창 목록 탭 — placeholder (Work-10에서 구현)
struct WindowListView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(systemName: "macwindow")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.accent)
                Text("창 목록")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                Text("Mac에 연결하면 열린 창 목록이 표시됩니다.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("창 목록")
        }
    }
}

#Preview {
    WindowListView()
        .preferredColorScheme(.dark)
}
