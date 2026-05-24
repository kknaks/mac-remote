import Foundation

// MARK: - Focus error types (Spec-02 §5)

/// 창 활성화 시 발생할 수 있는 에러
public enum FocusError: Error, Equatable {
    /// windowId가 현재 창 목록에 없음
    case windowNotFound(windowId: Int)
    /// PID에 해당하는 프로세스가 없음
    case processDead(pid: Int)
    /// Accessibility 권한 없음
    case axPermissionDenied
}

// MARK: - Focus result (Spec-02 §3)

/// 창 활성화 결과
public enum FocusResult: Equatable {
    /// 앱 활성화 + AXRaise 모두 성공
    case fullSuccess
    /// 앱 활성화만 성공, AXRaise 실패 (graceful degradation, Spec-02 §4)
    case appOnlyActivated
}

// MARK: - Focus ack response (Spec-02 §3)

/// 활성화 응답 모델
public struct FocusAckResponse: Codable, Equatable {
    public let type: String
    public let action: String
    public let ok: Bool
    public let error: String?

    public init(ok: Bool, error: String? = nil) {
        self.type = "ack"
        self.action = "focus"
        self.ok = ok
        self.error = error
    }
}

// MARK: - PID lookup (pure Swift, testable on all platforms)

/// windowId로 WindowInfo 목록에서 PID를 조회 (Spec-02 §4: PID 조회 단계)
/// - Parameters:
///   - windowId: 대상 창의 kCGWindowNumber
///   - windows: 현재 창 목록
/// - Returns: 해당 창의 PID, 없으면 nil
public func lookupPID(windowId: Int, in windows: [WindowInfo]) -> Int? {
    return windows.first(where: { $0.id == windowId })?.pid
}

/// windowId로 WindowInfo 목록에서 WindowInfo를 조회
/// - Parameters:
///   - windowId: 대상 창의 kCGWindowNumber
///   - windows: 현재 창 목록
/// - Returns: 해당 WindowInfo, 없으면 nil
public func lookupWindow(windowId: Int, in windows: [WindowInfo]) -> WindowInfo? {
    return windows.first(where: { $0.id == windowId })
}

// MARK: - Error message mapping (Spec-02 §5)

/// FocusError를 사용자 메시지로 변환
public func focusErrorMessage(for error: FocusError) -> String {
    switch error {
    case .windowNotFound:
        return "window not found"
    case .processDead:
        return "process dead"
    case .axPermissionDenied:
        return "accessibility permission denied"
    }
}

// MARK: - Focus ack JSON formatting (Spec-02 §3)

/// FocusAckResponse를 JSON 문자열로 변환
public func formatFocusAckJSON(ok: Bool, error: String? = nil) -> String {
    let response = FocusAckResponse(ok: ok, error: error)
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]

    guard let data = try? encoder.encode(response) else {
        return #"{"type":"ack","action":"focus","ok":false,"error":"encoding error"}"#
    }
    return String(data: data, encoding: .utf8) ?? #"{"type":"ack","action":"focus","ok":false,"error":"encoding error"}"#
}

// MARK: - WindowFocuser (macOS implementation)

#if canImport(AppKit)
import AppKit

public enum WindowFocuser {

    // MARK: - Task 2: NSRunningApplication.activate() (Spec-02 §4)

    /// PID 기반 앱 활성화
    /// - Parameter pid: 대상 프로세스 PID
    /// - Returns: 활성화 성공 여부
    /// - Throws: FocusError.processDead if process not found
    public static func activateApp(pid: Int) throws -> Bool {
        guard let app = NSRunningApplication(processIdentifier: pid_t(pid)) else {
            print("[ERROR] Process dead: pid=\(pid)")
            throw FocusError.processDead(pid: pid)
        }
        let activated = app.activate(options: [.activateIgnoringOtherApps])
        if activated {
            print("[INFO] App activated: pid=\(pid)")
        } else {
            print("[WARN] App activation returned false: pid=\(pid)")
        }
        return activated
    }

    // MARK: - Task 3: AXUIElement 기반 창 Raise (Spec-02 §4)

    /// AXUIElement를 사용하여 특정 창을 Raise
    /// - Parameters:
    ///   - windowId: 대상 창의 kCGWindowNumber
    ///   - pid: 대상 프로세스 PID
    /// - Returns: AXRaise 성공 여부
    public static func axRaiseWindow(windowId: Int, pid: Int) -> Bool {
        // Accessibility 권한 확인
        guard AXIsProcessTrusted() else {
            print("[WARN] AXRaise failed, app activated only — Accessibility permission denied")
            return false
        }

        let appElement = AXUIElementCreateApplication(pid_t(pid))

        // AXWindows 속성 가져오기
        var windowsValue: AnyObject?
        let windowsResult = AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windowsValue)
        guard windowsResult == .success,
              let axWindows = windowsValue as? [AXUIElement] else {
            print("[WARN] AXRaise failed, could not get windows for pid=\(pid)")
            return false
        }

        // 각 AX 윈도우에서 _kCGWindowNumber와 매칭하여 대상 창 찾기
        for axWindow in axWindows {
            var windowNumberValue: AnyObject?
            // _kCGWindowNumber는 private attribute이지만 널리 사용됨
            let numResult = AXUIElementCopyAttributeValue(axWindow, "_kCGWindowNumber" as CFString, &windowNumberValue)
            if numResult == .success,
               let num = (windowNumberValue as? NSNumber)?.intValue,
               num == windowId {
                // AXRaise 수행
                let raiseResult = AXUIElementPerformAction(axWindow, kAXRaiseAction as CFString)
                if raiseResult == .success {
                    print("[INFO] AXRaise succeeded: windowId=\(windowId)")
                    return true
                } else {
                    print("[WARN] AXRaise action failed: windowId=\(windowId), error=\(raiseResult)")
                    // Spec-02 §5: AX_RAISE_FAIL — 1회 재시도 (100ms 후)
                    usleep(100_000)  // 100ms
                    let retryResult = AXUIElementPerformAction(axWindow, kAXRaiseAction as CFString)
                    if retryResult == .success {
                        print("[INFO] AXRaise retry succeeded: windowId=\(windowId)")
                        return true
                    }
                    print("[WARN] AXRaise retry also failed: windowId=\(windowId)")
                    return false
                }
            }
        }

        print("[WARN] AXRaise failed, window not found in AX tree: windowId=\(windowId)")
        return false
    }

    // MARK: - Main focus function (Spec-02 §4 상태 전이)

    /// windowId를 인자로 받아 해당 창을 최전면으로 활성화
    /// 상태 전이: PID 조회 → 앱 활성화 → AXRaise → ack
    /// - Parameters:
    ///   - windowId: 대상 창의 kCGWindowNumber
    ///   - windows: 현재 창 목록 (PID 조회용)
    /// - Returns: FocusResult
    /// - Throws: FocusError
    public static func focus(windowId: Int, windows: [WindowInfo]) throws -> FocusResult {
        print("[INFO] Focusing windowId=\(windowId)")

        // Step 1: PID 조회 (Spec-02 §4)
        guard let window = lookupWindow(windowId: windowId, in: windows) else {
            print("[ERROR] Window not found: \(windowId)")
            throw FocusError.windowNotFound(windowId: windowId)
        }

        let pid = window.pid
        print("[INFO] Focusing windowId=\(windowId), pid=\(pid)")

        // Step 2: 앱 활성화 (Spec-02 §4)
        let _ = try activateApp(pid: pid)

        // Step 3: AXRaise (Spec-02 §4)
        let axSuccess = axRaiseWindow(windowId: windowId, pid: pid)

        if axSuccess {
            return .fullSuccess
        } else {
            // Spec-02 §4: AX 실패해도 앱은 활성화됨 → ok:true (graceful degradation)
            return .appOnlyActivated
        }
    }
}
#endif
