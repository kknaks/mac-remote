// MacHelperAppEntry.swift — 메뉴바 앱 엔트리 포인트 (Work-06 Task 2, 5)
// macOS 14+ SwiftUI App 프로토콜 사용
// Info.plist LSUIElement=true로 Dock 아이콘 숨김

#if canImport(SwiftUI) && canImport(AppKit)
import SwiftUI
import AppKit
import MacHelperLib

/// MacHelper 메뉴바 앱 엔트리 포인트
/// MenuBarExtra로 메뉴바에 상태 아이콘과 메뉴를 표시한다.
@available(macOS 14.0, *)
@main
struct MacHelperApp: App {
    @State private var appState = AppState()
    @State private var server: WebSocketServer?

    var body: some Scene {
        // MenuBarExtra: 메뉴바에 아이콘과 메뉴 표시 (Work-06 Task 2)
        MenuBarExtra {
            MenuBarContentView(appState: appState, onQuit: {
                server?.stop()
                NSApplication.shared.terminate(nil)
            }, onOpenAccessibilitySettings: {
                SystemSettingsOpener.openAccessibilitySettings()
            }, onOpenScreenRecordingSettings: {
                SystemSettingsOpener.openScreenRecordingSettings()
            })
        } label: {
            // 메뉴바 아이콘 (SF Symbol)
            Image(systemName: appState.menuBarIconName)
        }
    }
}
#else
// Linux/non-macOS: 빌드 대상이 아님
// MacHelperApp은 macOS 14+에서만 빌드 가능
#endif
