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

    /// 현재 Hold 모드 진입 중인 매크로 (Work-17). nil이면 hold 비활성.
    @State private var activeHoldMacro: MacroItem?

    /// 2열 그리드 레이아웃 (Spec-03 §8, Work-11 기술 메모)
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 연결 상태 헤더 (Work-13 Task 3)
                ConnectionStatusHeader()

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
            }
            // 미연결 오버레이 (Work-13 Task 4)
            .disconnectedOverlay()
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
            .overlay {
                // Work-17: Hold 모드 오버레이
                if let active = activeHoldMacro {
                    ZStack {
                        Color.black.opacity(0.35)
                            .ignoresSafeArea()
                            .onTapGesture {
                                // 빈 곳 탭 → 취소와 동일하게 처리
                                holdCancel()
                            }
                        HoldOverlayView(
                            macro: active,
                            onPrevious: { holdSendKey(macro: active, addShift: true) },
                            onNext: { holdSendKey(macro: active, addShift: false) },
                            onSelect: holdSelect,
                            onCancel: holdCancel
                        )
                        .padding(.horizontal, 24)
                    }
                    .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.15), value: activeHoldMacro?.id)
            .onDisappear {
                // Work-17 Task 11: 화면 이탈 시 안전장치 — hold 잔류 방지
                if activeHoldMacro != nil {
                    wsManager.sendReleaseModifiers()
                    activeHoldMacro = nil
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

    /// 매크로 실행: holdMode면 hold 모드 진입, 아니면 일반 단발 전송 (Work-11 Task 4, Work-17)
    private func executeMacro(_ macro: MacroItem) {
        if macro.holdMode {
            startHoldMode(macro)
        } else {
            wsManager.sendMacro(macro)
            triggerHaptic()
        }
    }

    // MARK: - Hold Mode (Work-17)

    /// Hold 모드 진입 — modifier hold + 초기 key 전송 + 오버레이 표시
    private func startHoldMode(_ macro: MacroItem) {
        wsManager.sendHoldModifiers(macro.modifiers)
        wsManager.sendKey(key: macro.key, modifiers: [])
        triggerHaptic(style: .heavy)
        activeHoldMacro = macro
    }

    /// Hold 중 단발 key 전송 (다음/이전)
    private func holdSendKey(macro: MacroItem, addShift: Bool) {
        // ⌘은 held로 유지 중이므로 요청 modifiers엔 shift 여부만
        let mods: [String] = addShift ? ["shift"] : []
        wsManager.sendKey(key: macro.key, modifiers: mods)
    }

    /// Hold 종료 — 현재 선택을 확정 (release)
    private func holdSelect() {
        wsManager.sendReleaseModifiers()
        activeHoldMacro = nil
        triggerHaptic()
    }

    /// Hold 취소 — Esc로 스위처 닫고 release
    private func holdCancel() {
        wsManager.sendKey(key: "escape", modifiers: [])
        wsManager.sendReleaseModifiers()
        activeHoldMacro = nil
        triggerHaptic()
    }

    /// 햅틱 피드백 (UIImpactFeedbackGenerator, Work-11 기술 메모)
    private func triggerHaptic(style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        #if canImport(UIKit)
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
        #endif
    }
}

#Preview {
    MacroView()
        .environmentObject(WebSocketManager())
        .preferredColorScheme(.dark)
}
