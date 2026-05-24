import Foundation

// MARK: - Shared constants

/// 필터링에서 제외할 시스템 프로세스 (Spec-01 §3-2)
public let excludedProcesses: Set<String> = [
    "Window Server",
    "Dock",
    "SystemUIServer",
    "Control Center",
    "Notification Center"
]

// MARK: - Raw window data (platform-independent representation)

/// CGWindowListCopyWindowInfo 결과의 플랫폼 독립 표현
/// macOS에서 raw dictionary → 이 구조체로 변환 후 필터링
public struct RawWindowEntry: Equatable {
    public let windowNumber: Int
    public let ownerName: String
    public let windowName: String?
    public let ownerPID: Int
    public let windowLayer: Int

    public init(windowNumber: Int, ownerName: String, windowName: String?, ownerPID: Int, windowLayer: Int) {
        self.windowNumber = windowNumber
        self.ownerName = ownerName
        self.windowName = windowName
        self.ownerPID = ownerPID
        self.windowLayer = windowLayer
    }
}

// MARK: - Filtering logic (pure Swift, testable on all platforms)

/// raw 창 목록에서 일반 사용자 창만 필터링 (Spec-01 §6)
/// - layer == 0 (일반 창만)
/// - ownerName이 비어있지 않을 것
/// - excludedProcesses에 포함되지 않을 것
public func filterWindows(_ entries: [RawWindowEntry]) -> [RawWindowEntry] {
    return entries.filter { entry in
        // layer == 0: 일반 창만 (Spec-01 §6)
        guard entry.windowLayer == 0 else { return false }
        // 빈 OwnerName 제외 (Spec-01 §6)
        guard !entry.ownerName.isEmpty else { return false }
        // 시스템 프로세스 제외 (Spec-01 §3-2)
        guard !excludedProcesses.contains(entry.ownerName) else { return false }
        return true
    }
}

/// 필터링된 RawWindowEntry → WindowInfo 변환
/// frontmostPID: 현재 최전면 앱의 PID (nil이면 모두 false)
/// Spec-01 §2: frontmost는 목록 중 최대 1개만 true
public func convertToWindowInfos(_ entries: [RawWindowEntry], frontmostPID: Int?) -> [WindowInfo] {
    var frontmostAssigned = false
    return entries.map { entry in
        let isFrontmost: Bool
        if !frontmostAssigned, let pid = frontmostPID, entry.ownerPID == pid {
            isFrontmost = true
            frontmostAssigned = true
        } else {
            isFrontmost = false
        }
        return WindowInfo(
            id: entry.windowNumber,
            app: entry.ownerName,
            title: entry.windowName ?? "",
            pid: entry.ownerPID,
            frontmost: isFrontmost
        )
    }
}

// MARK: - Frontmost PID detection (macOS only)

#if canImport(AppKit)
import AppKit

/// NSWorkspace로 현재 최전면 앱의 PID를 가져온다 (Spec-01 §2)
public func getFrontmostPID() -> Int? {
    guard let app = NSWorkspace.shared.frontmostApplication else {
        return nil
    }
    return Int(app.processIdentifier)
}
#endif

// MARK: - WindowManager (macOS implementation)

#if canImport(CoreGraphics) && canImport(AppKit)
import CoreGraphics

/// 창 목록 수집 (macOS 전용)
public enum WindowManager {

    /// CGWindowListCopyWindowInfo로 현재 화면의 창 목록 수집
    /// frontmostPID를 자동으로 감지한다.
    /// - Returns: 필터링된 WindowInfo 배열, null 반환 시 빈 배열
    public static func listWindows() -> [WindowInfo] {
        let frontmostPID = getFrontmostPID()
        return listWindows(frontmostPID: frontmostPID)
    }

    /// CGWindowListCopyWindowInfo로 현재 화면의 창 목록 수집
    /// - Parameter frontmostPID: 최전면 앱 PID (테스트 주입용)
    /// - Returns: 필터링된 WindowInfo 배열, null 반환 시 빈 배열
    public static func listWindows(frontmostPID: Int?) -> [WindowInfo] {
        // CGWindowListCopyWindowInfo 호출
        guard let windowList = CGWindowListCopyWindowInfo(
            [.optionOnScreenOnly, .excludeDesktopElements],
            kCGNullWindowID
        ) as? [[String: Any]] else {
            // Spec-01 §5 NULL_LIST: CGWindowListCopyWindowInfo null 반환
            print("[WARN] CGWindowListCopyWindowInfo returned null")
            return []
        }

        let totalCount = windowList.count

        // raw dictionary → RawWindowEntry 변환
        let rawEntries = windowList.compactMap { dict -> RawWindowEntry? in
            guard let windowNumber = dict["kCGWindowNumber"] as? Int,
                  let ownerName = dict["kCGWindowOwnerName"] as? String,
                  let ownerPID = dict["kCGWindowOwnerPID"] as? Int,
                  let windowLayer = dict["kCGWindowLayer"] as? Int else {
                return nil
            }
            let windowName = dict["kCGWindowName"] as? String
            return RawWindowEntry(
                windowNumber: windowNumber,
                ownerName: ownerName,
                windowName: windowName,
                ownerPID: ownerPID,
                windowLayer: windowLayer
            )
        }

        // 필터링
        let filtered = filterWindows(rawEntries)
        print("[INFO] Windows: total=\(totalCount), filtered=\(filtered.count)")

        // WindowInfo 변환
        return convertToWindowInfos(filtered, frontmostPID: frontmostPID)
    }
}
#endif
