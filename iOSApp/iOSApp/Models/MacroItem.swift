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
