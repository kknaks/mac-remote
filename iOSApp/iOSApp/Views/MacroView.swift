import SwiftUI

/// 매크로 탭 — 2열 그리드 매크로 버튼 화면 (Spec-03 §8, Work-11 Task 3)
/// 기본 프리셋 + 사용자 정의 매크로를 LazyVGrid로 표시
struct MacroView: View {
    @EnvironmentObject var wsManager: WebSocketManager

    /// 사용자 정의 매크로 목록 (UserDefaults에서 로드, Work-11 Task 6)
    @State private var userMacros: [MacroItem] = []

    /// 매크로 추가 시트 표시 여부
    @State private var showAddSheet = false

    /// 편집 중인 매크로 (nil이면 추가 모드, 값이 있으면 편집 모드)
    @State private var editingMacro: MacroItem?

    /// 2열 그리드 레이아웃 (Spec-03 §8, Work-11 기술 메모)
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    /// 전체 매크로 목록 (프리셋 + 사용자 정의)
    private var allMacros: [MacroItem] {
        MacroItem.defaults + userMacros
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // MARK: - 기본 프리셋 섹션
                    sectionHeader("기본 단축키")

                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(MacroItem.defaults) { macro in
                            MacroButtonView(macro: macro) {
                                executeMacro(macro)
                            }
                        }
                    }

                    // MARK: - 사용자 정의 매크로 섹션
                    if !userMacros.isEmpty {
                        sectionHeader("사용자 매크로")

                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(userMacros) { macro in
                                MacroButtonView(macro: macro) {
                                    executeMacro(macro)
                                }
                                .contextMenu {
                                    Button {
                                        editingMacro = macro
                                        showAddSheet = true
                                    } label: {
                                        Label("편집", systemImage: "pencil")
                                    }
                                    Button(role: .destructive) {
                                        deleteMacro(macro)
                                    } label: {
                                        Label("삭제", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(16)
            }
            .navigationTitle("매크로")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        editingMacro = nil
                        showAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .tint(Color.accent)
                }
            }
            .sheet(isPresented: $showAddSheet, onDismiss: {
                editingMacro = nil
            }) {
                AddMacroSheet(
                    editingMacro: editingMacro,
                    onSave: { macro in
                        saveMacro(macro)
                        showAddSheet = false
                    },
                    onCancel: {
                        showAddSheet = false
                    }
                )
            }
            .onAppear {
                loadUserMacros()
            }
        }
    }

    // MARK: - Section Header

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .foregroundStyle(.secondary)
    }

    // MARK: - Macro Actions

    /// 매크로 실행: WebSocket으로 key 명령 전송 + 햅틱 (Work-11 Task 4)
    private func executeMacro(_ macro: MacroItem) {
        wsManager.sendMacro(macro)
        triggerHaptic()
    }

    /// 햅틱 피드백 (UIImpactFeedbackGenerator, Work-11 기술 메모)
    private func triggerHaptic() {
        #if canImport(UIKit)
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        #endif
    }

    // MARK: - UserDefaults CRUD (Work-11 Task 6)

    /// 사용자 매크로 로드
    private func loadUserMacros() {
        guard let data = UserDefaults.standard.data(forKey: MacroItem.userDefaultsKey) else {
            return
        }
        do {
            userMacros = try JSONDecoder().decode([MacroItem].self, from: data)
        } catch {
            print("[ERROR] Failed to load user macros: \(error.localizedDescription)")
        }
    }

    /// 사용자 매크로 저장/업데이트
    private func saveMacro(_ macro: MacroItem) {
        if let editingMacro = editingMacro,
           let index = userMacros.firstIndex(where: { $0.id == editingMacro.id }) {
            // 편집: 기존 매크로 교체
            userMacros[index] = macro
        } else {
            // 추가: 새 매크로 추가
            userMacros.append(macro)
        }
        persistUserMacros()
    }

    /// 사용자 매크로 삭제
    private func deleteMacro(_ macro: MacroItem) {
        userMacros.removeAll { $0.id == macro.id }
        persistUserMacros()
    }

    /// UserDefaults에 사용자 매크로 JSON 저장
    private func persistUserMacros() {
        do {
            let data = try JSONEncoder().encode(userMacros)
            UserDefaults.standard.set(data, forKey: MacroItem.userDefaultsKey)
        } catch {
            print("[ERROR] Failed to persist user macros: \(error.localizedDescription)")
        }
    }
}

#Preview {
    MacroView()
        .environmentObject(WebSocketManager())
        .preferredColorScheme(.dark)
}
