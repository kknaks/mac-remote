import Foundation

// MARK: - SystemSettingsOpener (Work-06 Task 4)

/// 시스템 설정 열기 유틸리티
/// Spec-06 §5: 권한 거부 시 시스템 설정 해당 페이지로 안내
/// Spec-06 §7: 메뉴바에서 시스템 설정 열기 버튼

#if canImport(AppKit)
import AppKit

public enum SystemSettingsOpener {

    /// 손쉬운 사용 설정 열기 (Spec-06 §5 AX_DENIED)
    public static func openAccessibilitySettings() {
        open(SystemSettingsURL.accessibility)
    }

    /// 화면 기록 설정 열기 (Spec-06 §5 SR_DENIED)
    public static func openScreenRecordingSettings() {
        open(SystemSettingsURL.screenRecording)
    }

    /// URL 문자열로 시스템 설정 열기
    public static func open(_ urlString: String) {
        guard let url = URL(string: urlString) else {
            print("[ERROR] Invalid system settings URL: \(urlString)")
            return
        }
        NSWorkspace.shared.open(url)
    }
}
#endif
