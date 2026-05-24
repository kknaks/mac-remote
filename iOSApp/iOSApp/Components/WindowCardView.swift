import SwiftUI

/// 창 카드 컴포넌트 (Work-10, Spec-01 §8, Spec-04 §8)
/// 앱 아이콘 + 앱 이름 + 창 제목 + frontmost 표시
struct WindowCardView: View {
    let window: WindowInfo

    /// 앱 아이콘 (base64 디코딩 후 UIImage, nil이면 기본 아이콘)
    let appIcon: UIImage?

    var body: some View {
        HStack(spacing: 12) {
            // 앱 아이콘 (Spec-04 §8: 카드 왼쪽에 앱 아이콘 표시)
            iconView
                .frame(width: 40, height: 40)

            // 앱 이름 + 창 제목
            VStack(alignment: .leading, spacing: 2) {
                Text(window.app)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text(window.title.isEmpty ? "(제목 없음)" : window.title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }

            Spacer()

            // frontmost 표시
            if window.frontmost {
                Text("활성")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.accent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.accent.opacity(0.15))
                    .clipShape(Capsule())
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    window.frontmost ? Color.accent : Color.clear,
                    lineWidth: window.frontmost ? 1.5 : 0
                )
        )
    }

    // MARK: - Icon View

    @ViewBuilder
    private var iconView: some View {
        if let icon = appIcon {
            Image(uiImage: icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        } else {
            // 기본 아이콘 (Spec-04 §6: 매칭 안 되면 아이콘 없이 → 기본 아이콘으로 표시)
            Image(systemName: "app.fill")
                .font(.title2)
                .foregroundStyle(Color.accent)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

#Preview {
    VStack(spacing: 8) {
        WindowCardView(
            window: WindowInfo(
                id: 1,
                app: "Safari",
                title: "Apple - 공식 사이트",
                pid: 1234,
                frontmost: true
            ),
            appIcon: nil
        )
        WindowCardView(
            window: WindowInfo(
                id: 2,
                app: "Xcode",
                title: "MacHelper — AppDelegate.swift",
                pid: 5678,
                frontmost: false
            ),
            appIcon: nil
        )
        WindowCardView(
            window: WindowInfo(
                id: 3,
                app: "Terminal",
                title: "",
                pid: 9012,
                frontmost: false
            ),
            appIcon: nil
        )
    }
    .padding()
    .preferredColorScheme(.dark)
}
