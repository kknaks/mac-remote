import Foundation

// MARK: - PermissionStatus model (Spec-06 §2)

/// 권한 상태 모델
public struct PermissionStatus: Codable, Equatable {
    public let accessibility: Bool
    public let screenRecording: Bool

    public init(accessibility: Bool, screenRecording: Bool) {
        self.accessibility = accessibility
        self.screenRecording = screenRecording
    }
}

/// 권한 응답 모델 (Spec-06 §3)
public struct PermissionResponse: Codable, Equatable {
    public let type: String
    public let accessibility: Bool
    public let screenRecording: Bool

    public init(status: PermissionStatus) {
        self.type = "permissions"
        self.accessibility = status.accessibility
        self.screenRecording = status.screenRecording
    }
}

// MARK: - Screen Recording 간접 확인 로직

/// 창 제목 수집 결과로 Screen Recording 권한을 간접 확인 (Spec-06 §4)
/// 일반 창이 있는데 모든 제목이 빈 문자열이면 권한 없음으로 판단
public func checkScreenRecordingByTitles(windowTitles: [String], windowCount: Int) -> Bool {
    // 창이 없으면 판단 불가 → 보수적으로 true (Spec-06 §9 #5)
    guard windowCount > 0 else { return true }
    // 하나라도 비어있지 않은 제목이 있으면 권한 있음
    let hasNonEmptyTitle = windowTitles.contains { !$0.isEmpty }
    return hasNonEmptyTitle
}

// MARK: - PermissionChecker (macOS implementation)

#if canImport(AppKit)
import AppKit

public enum PermissionChecker {

    /// Accessibility 권한 확인 (Spec-06 §2)
    /// AXIsProcessTrusted() 호출
    public static func checkAccessibility() -> Bool {
        return AXIsProcessTrusted()
    }

    /// Screen Recording 권한 간접 확인 (Spec-06 §4)
    /// CGWindowListCopyWindowInfo로 창 제목 수집을 시도하여 확인
    public static func checkScreenRecording() -> Bool {
        guard let windowList = CGWindowListCopyWindowInfo(
            [.optionOnScreenOnly, .excludeDesktopElements],
            kCGNullWindowID
        ) as? [[String: Any]] else {
            return false
        }

        // layer == 0인 일반 창의 제목만 수집
        let normalWindows = windowList.filter { ($0["kCGWindowLayer"] as? Int) == 0 }
        let titles = normalWindows.compactMap { $0["kCGWindowName"] as? String }

        return checkScreenRecordingByTitles(windowTitles: titles, windowCount: normalWindows.count)
    }

    /// 모든 권한 상태를 한 번에 확인
    public static func check() -> PermissionStatus {
        let ax = checkAccessibility()
        let sr = checkScreenRecording()

        if !ax {
            print("[ERROR] Accessibility 권한이 거부되었습니다. 시스템 설정 → 개인 정보 보호 → 손쉬운 사용에서 허용해주세요.")
        }
        if !sr {
            print("[WARN] 화면 기록 권한이 거부되었습니다. 화면 기록 권한을 허용하면 창 제목이 표시됩니다.")
        }

        return PermissionStatus(accessibility: ax, screenRecording: sr)
    }
}
#endif
