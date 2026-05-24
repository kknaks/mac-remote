// MenuBarApp.swift — MenuBarExtra 메뉴바 뷰 (Work-06 Task 2)
// macOS 14+ SwiftUI 뷰 컴포넌트
// @main 엔트리 포인트는 MacHelperApp 타겟에 위치
// Linux에서는 컴파일 불가 — #if canImport(SwiftUI) 가드

#if canImport(SwiftUI) && canImport(AppKit)
import SwiftUI

// MARK: - MenuBarContentView (Work-06 Task 2, 3, 4)

/// 메뉴바 드롭다운 메뉴 내용
@available(macOS 14.0, *)
public struct MenuBarContentView: View {
    let appState: AppState
    let onQuit: () -> Void
    let onOpenAccessibilitySettings: () -> Void
    let onOpenScreenRecordingSettings: () -> Void

    public init(
        appState: AppState,
        onQuit: @escaping () -> Void,
        onOpenAccessibilitySettings: @escaping () -> Void,
        onOpenScreenRecordingSettings: @escaping () -> Void
    ) {
        self.appState = appState
        self.onQuit = onQuit
        self.onOpenAccessibilitySettings = onOpenAccessibilitySettings
        self.onOpenScreenRecordingSettings = onOpenScreenRecordingSettings
    }

    public var body: some View {
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
