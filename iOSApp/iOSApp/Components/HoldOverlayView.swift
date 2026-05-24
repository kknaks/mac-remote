import SwiftUI

/// Hold 모드 오버레이 (Work-17, Spec-03 §7-8)
/// holdMode:true 매크로를 길게 누르면 표시되는 모달.
/// ◀ ▶ ✓ ✕ 4개 버튼으로 modifier hold 중 추가 키 입력을 조작한다.
struct HoldOverlayView: View {
    let macro: MacroItem
    let onPrevious: () -> Void   // ◀  Shift+key 단발
    let onNext: () -> Void       // ▶  key 단발
    let onSelect: () -> Void     // ✓  releaseModifiers
    let onCancel: () -> Void     // ✕  Esc + releaseModifiers

    var body: some View {
        VStack(spacing: 20) {
            // 상단 표시 — 어떤 매크로의 hold 모드인지
            VStack(spacing: 4) {
                Image(systemName: macro.icon)
                    .font(.system(size: 32))
                    .foregroundStyle(Color.accent)
                Text(macro.name)
                    .font(.headline)
                Text("\(macro.shortcutLabel) hold")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()

            // 이전 / 다음 — 같은 key를 modifier 유지 상태로 반복
            HStack(spacing: 16) {
                holdButton(systemName: "chevron.left", label: "이전", color: .accent, action: onPrevious)
                holdButton(systemName: "chevron.right", label: "다음", color: .accent, action: onNext)
            }

            // 선택 / 취소
            HStack(spacing: 16) {
                holdButton(systemName: "checkmark", label: "선택", color: .green, action: onSelect)
                holdButton(systemName: "xmark", label: "취소", color: .red, action: onCancel)
            }
        }
        .padding(24)
        .frame(maxWidth: 320)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(radius: 16)
    }

    private func holdButton(systemName: String, label: String, color: Color, action: @escaping () -> Void) -> some View {
        Button {
            triggerHaptic()
            action()
        } label: {
            VStack(spacing: 6) {
                Image(systemName: systemName)
                    .font(.system(size: 28, weight: .semibold))
                Text(label)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    private func triggerHaptic() {
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        HoldOverlayView(
            macro: MacroItem(
                name: "앱전환",
                key: "tab",
                modifiers: ["cmd"],
                icon: "rectangle.on.rectangle",
                holdMode: true
            ),
            onPrevious: {},
            onNext: {},
            onSelect: {},
            onCancel: {}
        )
    }
    .preferredColorScheme(.dark)
}
