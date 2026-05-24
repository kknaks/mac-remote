// MacHelperAppEntry.swift — 메뉴바 앱 엔트리 포인트 (Work-06 Task 2, 5, 6)
// macOS 14+ SwiftUI App 프로토콜 사용
// Info.plist LSUIElement=true로 Dock 아이콘 숨김
// 앱 시작 시 WebSocket 서버 자동 시작

#if canImport(SwiftUI) && canImport(AppKit)
import SwiftUI
import AppKit
import MacHelperLib

/// MacHelper 메뉴바 앱 엔트리 포인트
/// MenuBarExtra로 메뉴바에 상태 아이콘과 메뉴를 표시한다.
/// 앱 시작 시 WebSocket 서버가 자동으로 시작된다 (Work-06 Task 6)
@available(macOS 14.0, *)
@main
struct MacHelperApp: App {
    /// 앱 생명주기 관리자 — 서버 자동 시작, 권한 확인, 상태 갱신
    @State private var lifecycle = AppLifecycleManager()

    var body: some Scene {
        // MenuBarExtra: 메뉴바에 아이콘과 팝오버 윈도우 표시
        // .window 스타일: QR 이미지 등 커스텀 SwiftUI 뷰 지원 (Work-07 Task 3)
        MenuBarExtra {
            MenuBarContentView(appState: lifecycle.appState, onQuit: {
                lifecycle.stop()
                NSApplication.shared.terminate(nil)
            }, onOpenAccessibilitySettings: {
                SystemSettingsOpener.openAccessibilitySettings()
            }, onOpenScreenRecordingSettings: {
                SystemSettingsOpener.openScreenRecordingSettings()
            })
            .onAppear {
                // Task 6: 앱 시작 시 서버 자동 시작
                lifecycle.start()
            }
        } label: {
            // 메뉴바 아이콘 — 커스텀 PNG (template 모드)
            menuBarIconImage
        }
        .menuBarExtraStyle(.window)
    }

    /// 번들 내 MenuBarIcon PNG를 template image로 로드
    /// 실패 시 SF Symbol로 폴백
    private var menuBarIconImage: some View {
        if let url = Bundle.module.url(forResource: "MenuBarIcon", withExtension: "png"),
           let nsImage = NSImage(contentsOf: url) {
            nsImage.isTemplate = true
            return AnyView(Image(nsImage: nsImage))
        }
        return AnyView(Image(systemName: lifecycle.appState.menuBarIconName))
    }
}
#else
// Linux/non-macOS: 빌드 대상이 아님
// MacHelperApp은 macOS 14+에서만 빌드 가능
#endif
