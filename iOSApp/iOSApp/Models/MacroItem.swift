import Foundation

/// 매크로 모델 (Spec-03 기반, Work-11)
/// 사용자가 등록한 단축키 매크로 정보
/// - name: 표시 이름
/// - key: 키 이름 ("c", "v", "z", "tab", "4" 등, Spec-03 §2 VirtualKeyMap 참조)
/// - modifiers: modifier 목록 ["cmd", "shift", "alt", "ctrl"] (Spec-03 §3-2)
/// - icon: SF Symbol 이름
/// - isUserDefined: 사용자 정의 매크로 여부 (false = 기본 프리셋)
struct MacroItem: Codable, Equatable, Identifiable {
    var id: UUID = UUID()
    let name: String
    let key: String
    let modifiers: [String]
    let icon: String
    let isUserDefined: Bool

    init(name: String, key: String, modifiers: [String] = [], icon: String = "command", isUserDefined: Bool = false) {
        self.id = UUID()
        self.name = name
        self.key = key
        self.modifiers = modifiers
        self.icon = icon
        self.isUserDefined = isUserDefined
    }

    /// ClientMessage로 변환 (전송용, Spec-03 §3-1)
    /// {"action":"key","key":"c","modifiers":["cmd"]}
    func toClientMessage() -> ClientMessage {
        return ClientMessage(action: "key", key: key, modifiers: modifiers)
    }

    /// modifier 문자열을 기호로 변환 (UI 표시용)
    var modifierSymbols: String {
        modifiers.map { modifier in
            switch modifier {
            case "cmd": return "\u{2318}"    // ⌘
            case "shift": return "\u{21E7}"  // ⇧
            case "alt": return "\u{2325}"    // ⌥
            case "ctrl": return "\u{2303}"   // ⌃
            default: return modifier
            }
        }.joined()
    }

    /// 키 표시 문자열 (예: "⌘C", "⌃⌘Q")
    var shortcutLabel: String {
        modifierSymbols + key.uppercased()
    }

    // MARK: - Codable (id 제외)

    enum CodingKeys: String, CodingKey {
        case name, key, modifiers, icon, isUserDefined
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.name = try container.decode(String.self, forKey: .name)
        self.key = try container.decode(String.self, forKey: .key)
        self.modifiers = try container.decodeIfPresent([String].self, forKey: .modifiers) ?? []
        self.icon = try container.decodeIfPresent(String.self, forKey: .icon) ?? "command"
        self.isUserDefined = try container.decodeIfPresent(Bool.self, forKey: .isUserDefined) ?? false
    }
}

// MARK: - 기본 매크로 프리셋 (Spec-03 §8, §10)

extension MacroItem {
    /// 기본 매크로 프리셋 7개 (Work-11 Task 2)
    /// ⌘C, ⌘V, ⌘Z, ⌘⇧Z, ⌘⇧4, ⌃⌘Q, ⌘⇥
    static let defaults: [MacroItem] = [
        MacroItem(name: "복사", key: "c", modifiers: ["cmd"], icon: "doc.on.doc"),
        MacroItem(name: "붙여넣기", key: "v", modifiers: ["cmd"], icon: "doc.on.clipboard"),
        MacroItem(name: "실행취소", key: "z", modifiers: ["cmd"], icon: "arrow.uturn.backward"),
        MacroItem(name: "다시실행", key: "z", modifiers: ["cmd", "shift"], icon: "arrow.uturn.forward"),
        MacroItem(name: "스크린샷", key: "4", modifiers: ["cmd", "shift"], icon: "camera.viewfinder"),
        MacroItem(name: "화면잠금", key: "q", modifiers: ["ctrl", "cmd"], icon: "lock"),
        MacroItem(name: "앱전환", key: "tab", modifiers: ["cmd"], icon: "rectangle.on.rectangle"),
    ]

    /// UserDefaults에 저장할 때 사용하는 키
    static let userDefaultsKey = "userMacros"
}
