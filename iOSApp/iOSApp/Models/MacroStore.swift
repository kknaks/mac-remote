import Foundation
import Combine
import SwiftUI

/// 사용자 매크로 저장소 (UserDefaults 기반, Work-11 Task 6)
/// - 기본 프리셋은 MacroItem.defaults에서 제공 (읽기 전용)
/// - 사용자 정의 매크로는 UserDefaults에 JSON으로 저장
/// - ObservableObject로 SwiftUI 바인딩 지원
final class MacroStore: ObservableObject {

    /// 사용자 정의 매크로 목록
    @Published var userMacros: [MacroItem] = []

    /// 전체 매크로 (프리셋 + 사용자 정의)
    var allMacros: [MacroItem] {
        MacroItem.defaults + userMacros
    }

    /// UserDefaults 인스턴스 (테스트 시 교체 가능)
    private let defaults: UserDefaults

    // MARK: - Init

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        load()
    }

    // MARK: - CRUD

    /// 사용자 매크로 추가
    func add(_ macro: MacroItem) {
        let userMacro = MacroItem(
            name: macro.name,
            key: macro.key,
            modifiers: macro.modifiers,
            icon: macro.icon,
            isUserDefined: true
        )
        userMacros.append(userMacro)
        persist()
    }

    /// 사용자 매크로 업데이트 (id 기준)
    func update(_ macro: MacroItem) {
        guard let index = userMacros.firstIndex(where: { $0.id == macro.id }) else {
            return
        }
        userMacros[index] = macro
        persist()
    }

    /// 사용자 매크로 삭제 (id 기준)
    func delete(_ macro: MacroItem) {
        userMacros.removeAll { $0.id == macro.id }
        persist()
    }

    /// ID 기준 삭제 (IndexSet 지원)
    func delete(at offsets: IndexSet) {
        userMacros.remove(atOffsets: offsets)
        persist()
    }

    /// 사용자 매크로 추가 또는 업데이트
    /// - editingId가 nil이면 추가, 있으면 해당 id를 교체
    func saveOrUpdate(_ macro: MacroItem, editingId: UUID?) {
        if let id = editingId,
           let index = userMacros.firstIndex(where: { $0.id == id }) {
            userMacros[index] = macro
        } else {
            userMacros.append(macro)
        }
        persist()
    }

    // MARK: - Persistence (UserDefaults + JSON)

    /// UserDefaults에서 사용자 매크로 로드
    func load() {
        guard let data = defaults.data(forKey: MacroItem.userDefaultsKey) else {
            userMacros = []
            return
        }
        do {
            userMacros = try JSONDecoder().decode([MacroItem].self, from: data)
        } catch {
            print("[ERROR] MacroStore: failed to decode user macros: \(error.localizedDescription)")
            userMacros = []
        }
    }

    /// UserDefaults에 사용자 매크로 JSON 저장
    private func persist() {
        do {
            let data = try JSONEncoder().encode(userMacros)
            defaults.set(data, forKey: MacroItem.userDefaultsKey)
        } catch {
            print("[ERROR] MacroStore: failed to encode user macros: \(error.localizedDescription)")
        }
    }
}
