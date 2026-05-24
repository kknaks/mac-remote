import SwiftUI

/// 매크로 버튼 컴포넌트 (Spec-03 §8, Work-11 Task 4)
/// - 아이콘 (SF Symbol) + 이름 + 단축키 라벨 표시
/// - 탭 시 onTap 콜백 호출 (햅틱은 호출 측에서 처리)
/// - 눌림 효과 (ButtonStyle)
struct MacroButtonView: View {
    let macro: MacroItem
    var onTap: () -> Void = {}

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(systemName: macro.icon)
                    .font(.title2)
                    .frame(height: 28)

                Text(macro.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)

                Text(macro.shortcutLabel)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 8)
            .background(Color(.systemGray6))
            .foregroundStyle(Color.accent)
            .cornerRadius(12)
        }
        .buttonStyle(MacroButtonStyle())
    }
}

// MARK: - Button Style (눌림 효과)

/// 매크로 버튼 눌림 효과 — 스케일 + 투명도 변화
struct MacroButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
        MacroButtonView(macro: MacroItem(
            name: "복사",
            key: "c",
            modifiers: ["cmd"],
            icon: "doc.on.doc"
        ))
        MacroButtonView(macro: MacroItem(
            name: "화면잠금",
            key: "q",
            modifiers: ["ctrl", "cmd"],
            icon: "lock"
        ))
        MacroButtonView(macro: MacroItem(
            name: "스크린샷",
            key: "4",
            modifiers: ["cmd", "shift"],
            icon: "camera.viewfinder"
        ))
        MacroButtonView(macro: MacroItem(
            name: "앱전환",
            key: "tab",
            modifiers: ["cmd"],
            icon: "rectangle.on.rectangle"
        ))
    }
    .padding()
    .preferredColorScheme(.dark)
}
