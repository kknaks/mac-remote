import Foundation
import SwiftUI

// MARK: - App Settings (Work-12 Task 6)

/// 앱 설정 관리자
/// @AppStorage 키 상수 + 편의 접근자
/// 설정 값은 UserDefaults에 저장된다.
enum AppSettingsKey {
    /// 햅틱 피드백 활성화 여부
    static let hapticEnabled = "hapticEnabled"

    /// 자동 재연결 활성화 여부
    static let autoReconnect = "autoReconnect"

    /// 빈 제목 창 숨기기 여부
    static let hideEmptyTitle = "hideEmptyTitle"
}

/// 앱 설정 읽기 헬퍼 (비-SwiftUI 코드에서 사용)
enum AppSettings {
    /// 햅틱 피드백 활성화 여부 (기본: true)
    static var hapticEnabled: Bool {
        // UserDefaults에 값이 없으면 기본값 true
        if UserDefaults.standard.object(forKey: AppSettingsKey.hapticEnabled) == nil {
            return true
        }
        return UserDefaults.standard.bool(forKey: AppSettingsKey.hapticEnabled)
    }

    /// 자동 재연결 활성화 여부 (기본: true)
    static var autoReconnect: Bool {
        if UserDefaults.standard.object(forKey: AppSettingsKey.autoReconnect) == nil {
            return true
        }
        return UserDefaults.standard.bool(forKey: AppSettingsKey.autoReconnect)
    }

    /// 빈 제목 창 숨기기 여부 (기본: false)
    static var hideEmptyTitle: Bool {
        UserDefaults.standard.bool(forKey: AppSettingsKey.hideEmptyTitle)
    }
}
