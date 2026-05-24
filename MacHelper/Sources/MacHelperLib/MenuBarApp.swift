// MenuBarApp.swift — MenuBarExtra 메뉴바 앱 (Work-06 Task 2)
// macOS 14+ SwiftUI App 프로토콜 사용
// Linux에서는 컴파일 불가 — #if canImport(SwiftUI) 가드

#if canImport(SwiftUI) && canImport(AppKit)
import SwiftUI

/// MacHelper 메뉴바 앱 엔트리 포인트
/// MenuBarExtra로 메뉴바에 상태 아이콘과 메뉴를 표시한다.
/// Dock 아이콘은 Info.plist LSUIElement=true로 숨긴다.
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
                openSystemSettings(SystemSettingsURL.accessibility)
            }, onOpenScreenRecordingSettings: {
                openSystemSettings(SystemSettingsURL.screenRecording)
            })
        } label: {
            // 메뉴바 아이콘 (SF Symbol)
            Image(systemName: appState.menuBarIconName)
        }
    }

    /// 시스템 설정 열기 (Spec-06 §7, §8)
    private func openSystemSettings(_ urlString: String) {
        if let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
    }
}

// MARK: - MenuBarContentView (Work-06 Task 2, 3, 4)

/// 메뉴바 드롭다운 메뉴 내용
@available(macOS 14.0, *)
struct MenuBarContentView: View {
    let appState: AppState
    let onQuit: () -> Void
    let onOpenAccessibilitySettings: () -> Void
    let onOpenScreenRecordingSettings: () -> Void

    var body: some View {
        // Task 3: 연결 상태 표시 (클라이언트 수, IP:포트)
        Section("연결") {
            Text(appState.connectionStatusText)
            Text(appState.addressText)
            Text(appState.fullAddressText(ip: NetworkInfo.primaryIPAddress()))
                .font(.caption)
                .foregroundStyle(.secondary)
        }

        Divider()

        // Task 4: 권한 상태 표시
        Section("권한") {
            HStack {
                Text(appState.accessibilityStatusText)
                if !appState.permissions.accessibility {
                    Button("설정 열기") {
                        onOpenAccessibilitySettings()
                    }
                }
            }
            HStack {
                Text(appState.screenRecordingStatusText)
                if !appState.permissions.screenRecording {
                    Button("설정 열기") {
                        onOpenScreenRecordingSettings()
                    }
                }
            }
        }

        Divider()

        // 종료 버튼
        Button("종료") {
            onQuit()
        }
        .keyboardShortcut("q")
    }
}
#endif
