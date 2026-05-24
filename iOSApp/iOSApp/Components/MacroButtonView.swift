import SwiftUI

/// 매크로 버튼 컴포넌트 — placeholder (Work-11에서 구현)
struct MacroButtonView: View {
    let macro: MacroItem
    var onTap: () -> Void = {}

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(systemName: macro.icon)
                    .font(.title2)
                Text(macro.name)
                    .font(.caption)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemGray6))
            .foregroundStyle(Color.accent)
            .cornerRadius(12)
        }
    }
}

#Preview {
    MacroButtonView(macro: MacroItem(
        name: "복사",
        key: "c",
        modifiers: ["cmd"],
        icon: "doc.on.doc"
    ))
    .preferredColorScheme(.dark)
    .padding()
}
