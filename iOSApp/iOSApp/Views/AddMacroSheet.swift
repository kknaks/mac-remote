import SwiftUI

/// 매크로 추가/편집 시트 (Spec-03 §8, Work-11 Task 5)
/// - 이름, 키, modifier, 아이콘 선택
/// - editingMacro가 nil이면 추가 모드, 값이 있으면 편집 모드
struct AddMacroSheet: View {
    /// 편집 중인 매크로 (nil이면 새로 추가)
    let editingMacro: MacroItem?

    /// 저장 콜백
    let onSave: (MacroItem) -> Void

    /// 취소 콜백
    let onCancel: () -> Void

    // MARK: - Form State

    @State private var name: String = ""
    @State private var key: String = ""
    @State private var useCmdModifier: Bool = false
    @State private var useShiftModifier: Bool = false
    @State private var useAltModifier: Bool = false
    @State private var useCtrlModifier: Bool = false
    @State private var selectedIcon: String = "command"

    /// 사용 가능한 아이콘 목록
    private let availableIcons = [
        "command", "option", "control", "shift",
        "keyboard", "globe", "power",
        "doc.on.doc", "doc.on.clipboard",
        "arrow.uturn.backward", "arrow.uturn.forward",
        "camera.viewfinder", "lock",
        "rectangle.on.rectangle", "square.and.arrow.down",
        "magnifyingglass", "trash",
        "pencil", "scissors", "textformat",
        "star", "heart", "bolt",
    ]

    /// Spec-03 §2 VirtualKeyMap에서 지원하는 키 이름 목록
    private let availableKeys = [
        "a", "b", "c", "d", "e", "f", "g", "h", "i", "j",
        "k", "l", "m", "n", "o", "p", "q", "r", "s", "t",
        "u", "v", "w", "x", "y", "z",
        "0", "1", "2", "3", "4", "5", "6", "7", "8", "9",
        "tab", "space", "return", "escape",
        "delete", "up", "down", "left", "right",
        "f1", "f2", "f3", "f4", "f5", "f6",
        "f7", "f8", "f9", "f10", "f11", "f12",
    ]

    /// 폼 유효성 (이름과 키가 비어있지 않아야 함)
    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !key.trimmingCharacters(in: .whitespaces).isEmpty
    }

    /// 선택된 modifier 배열 (Spec-03 §3-2)
    private var selectedModifiers: [String] {
        var mods: [String] = []
        if useCtrlModifier { mods.append("ctrl") }
        if useAltModifier { mods.append("alt") }
        if useShiftModifier { mods.append("shift") }
        if useCmdModifier { mods.append("cmd") }
        return mods
    }

    /// 편집 모드 여부
    private var isEditing: Bool {
        editingMacro != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - 이름
                Section("매크로 이름") {
                    TextField("예: 전체선택", text: $name)
                }

                // MARK: - 키 선택
                Section("키") {
                    Picker("키 선택", selection: $key) {
                        Text("선택하세요").tag("")
                        ForEach(availableKeys, id: \.self) { keyName in
                            Text(keyName).tag(keyName)
                        }
                    }
                    .pickerStyle(.menu)
                }

                // MARK: - Modifier 선택 (Spec-03 §3-2)
                Section("보조키 (Modifier)") {
                    Toggle("\u{2318} Command", isOn: $useCmdModifier)
                    Toggle("\u{21E7} Shift", isOn: $useShiftModifier)
                    Toggle("\u{2325} Option", isOn: $useAltModifier)
                    Toggle("\u{2303} Control", isOn: $useCtrlModifier)
                }

                // MARK: - 아이콘 선택
                Section("아이콘") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                        ForEach(availableIcons, id: \.self) { iconName in
                            Button {
                                selectedIcon = iconName
                            } label: {
                                Image(systemName: iconName)
                                    .font(.title3)
                                    .frame(width: 40, height: 40)
                                    .background(
                                        selectedIcon == iconName
                                            ? Color.accent.opacity(0.3)
                                            : Color(.systemGray6)
                                    )
                                    .foregroundStyle(
                                        selectedIcon == iconName
                                            ? Color.accent
                                            : .secondary
                                    )
                                    .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }

                // MARK: - 미리보기
                if isValid {
                    Section("미리보기") {
                        HStack {
                            Image(systemName: selectedIcon)
                                .font(.title2)
                                .foregroundStyle(Color.accent)
                            VStack(alignment: .leading) {
                                Text(name)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text(previewShortcutLabel)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle(isEditing ? "매크로 편집" : "매크로 추가")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("취소") {
                        onCancel()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(isEditing ? "저장" : "추가") {
                        let macro = MacroItem(
                            name: name.trimmingCharacters(in: .whitespaces),
                            key: key,
                            modifiers: selectedModifiers,
                            icon: selectedIcon,
                            isUserDefined: true
                        )
                        onSave(macro)
                    }
                    .disabled(!isValid)
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                if let macro = editingMacro {
                    name = macro.name
                    key = macro.key
                    selectedIcon = macro.icon
                    useCmdModifier = macro.modifiers.contains("cmd")
                    useShiftModifier = macro.modifiers.contains("shift")
                    useAltModifier = macro.modifiers.contains("alt")
                    useCtrlModifier = macro.modifiers.contains("ctrl")
                }
            }
        }
    }

    /// 미리보기 단축키 라벨
    private var previewShortcutLabel: String {
        let symbols = selectedModifiers.map { modifier in
            switch modifier {
            case "cmd": return "\u{2318}"
            case "shift": return "\u{21E7}"
            case "alt": return "\u{2325}"
            case "ctrl": return "\u{2303}"
            default: return modifier
            }
        }.joined()
        return symbols + key.uppercased()
    }
}

#Preview {
    AddMacroSheet(
        editingMacro: nil,
        onSave: { _ in },
        onCancel: { }
    )
    .preferredColorScheme(.dark)
}
