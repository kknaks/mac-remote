import SwiftUI

/// 매크로 탭 — placeholder (Work-11에서 구현)
struct MacroView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(systemName: "command")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.accent)
                Text("매크로")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                Text("자주 쓰는 단축키를 매크로로 등록할 수 있습니다.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("매크로")
        }
    }
}

#Preview {
    MacroView()
        .preferredColorScheme(.dark)
}
