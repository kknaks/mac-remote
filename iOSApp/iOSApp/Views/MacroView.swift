import SwiftUI

/// 매크로 탭 — 2열 그리드 매크로 버튼 화면 (Spec-03 §8, Work-11)
/// 기본 프리셋 + 사용자 정의 매크로를 LazyVGrid로 표시
struct MacroView: View {
    @EnvironmentObject var wsManager: WebSocketManager

    /// 사용자 매크로 저장소 (Work-11 Task 6)
    @StateObject private var macroStore = MacroStore()

    /// 매크로 추가 시트 표시 여부
    @State private var showAddSheet = false

    /// 편집 중인 매크로 (nil이면 추가 모드, 값이 있으면 편집 모드)
    @State private var editingMacro: MacroItem?

    /// 2열 그리드 레이아웃 (Spec-03 §8, Work-11 기술 메모)
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

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
                    if !macroStore.userMacros.isEmpty {
                        sectionHeader("사용자 매크로")

                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(macroStore.userMacros) { macro in
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
                                        macroStore.delete(macro)
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
                        macroStore.saveOrUpdate(macro, editingId: editingMacro?.id)
                        showAddSheet = false
                    },
                    onCancel: {
                        showAddSheet = false
                    }
                )
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
}

#Preview {
    MacroView()
        .environmentObject(WebSocketManager())
        .preferredColorScheme(.dark)
}
