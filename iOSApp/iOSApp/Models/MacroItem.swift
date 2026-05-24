import Foundation

/// 매크로 모델 (Spec-03 기반, Work-11에서 상세 구현)
/// 사용자가 등록한 단축키 매크로 정보
struct MacroItem: Codable, Equatable, Identifiable {
    var id: UUID = UUID()
    let name: String
    let key: String
    let modifiers: [String]
    let icon: String

    init(name: String, key: String, modifiers: [String] = [], icon: String = "command") {
        self.id = UUID()
        self.name = name
        self.key = key
        self.modifiers = modifiers
        self.icon = icon
    }

    /// ClientMessage로 변환 (전송용)
    func toClientMessage() -> ClientMessage {
        return ClientMessage(action: "key", key: key, modifiers: modifiers)
    }

    // MARK: - Codable (id 제외)

    enum CodingKeys: String, CodingKey {
        case name, key, modifiers, icon
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.name = try container.decode(String.self, forKey: .name)
        self.key = try container.decode(String.self, forKey: .key)
        self.modifiers = try container.decodeIfPresent([String].self, forKey: .modifiers) ?? []
        self.icon = try container.decodeIfPresent(String.self, forKey: .icon) ?? "command"
    }
}

// MARK: - 기본 매크로 프리셋

extension MacroItem {
    /// 기본 매크로 목록 (Work-11에서 사용)
    static let defaults: [MacroItem] = [
        MacroItem(name: "복사", key: "c", modifiers: ["cmd"], icon: "doc.on.doc"),
        MacroItem(name: "붙여넣기", key: "v", modifiers: ["cmd"], icon: "doc.on.clipboard"),
        MacroItem(name: "실행취소", key: "z", modifiers: ["cmd"], icon: "arrow.uturn.backward"),
        MacroItem(name: "저장", key: "s", modifiers: ["cmd"], icon: "square.and.arrow.down"),
        MacroItem(name: "전체선택", key: "a", modifiers: ["cmd"], icon: "selection.pin.in.out"),
        MacroItem(name: "찾기", key: "f", modifiers: ["cmd"], icon: "magnifyingglass"),
    ]
}
