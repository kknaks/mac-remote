import SwiftUI

/// 설정 탭 — placeholder (Work-12에서 구현)
struct SettingsView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(systemName: "gearshape")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.accent)
                Text("설정")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                Text("연결 및 앱 설정을 관리합니다.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("설정")
        }
    }
}

#Preview {
    SettingsView()
        .preferredColorScheme(.dark)
}
