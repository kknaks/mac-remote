import Foundation

// MARK: - Client Message Model (Spec-05 §2)

/// iOS → Mac 요청 메시지
public struct ClientMessage: Codable, Equatable {
    public let action: String
    public let windowId: Int?
    public let key: String?
    public let modifiers: [String]?

    public init(action: String, windowId: Int? = nil, key: String? = nil, modifiers: [String]? = nil) {
        self.action = action
        self.windowId = windowId
        self.key = key
        self.modifiers = modifiers
    }
}

// MARK: - Server Message Models (Spec-05 §2)

/// 에러 ack 응답 (UNKNOWN_ACTION, INVALID_JSON)
public struct ErrorAckResponse: Codable, Equatable {
    public let type: String
    public let action: String
    public let ok: Bool
    public let error: String

    public init(action: String, error: String) {
        self.type = "ack"
        self.action = action
        self.ok = false
        self.error = error
    }
}

// MARK: - MessageHandler (Spec-05 §3)

/// WebSocket 메시지 핸들러
/// action 필드 기반으로 적절한 핸들러를 호출한다.
public final class MessageHandler {

    public init() {}

    /// 텍스트 메시지를 처리하고 응답 JSON을 반환
    /// - Parameter text: 수신된 JSON 문자열
    /// - Returns: 응답 JSON 문자열
    public func handle(_ text: String) -> String {
        // Step 1: JSON 파싱
        guard let data = text.data(using: .utf8) else {
            print("[ERROR] Invalid JSON received")
            return encodeErrorAck(action: "unknown", error: "INVALID_JSON")
        }

        let message: ClientMessage
        do {
            message = try JSONDecoder().decode(ClientMessage.self, from: data)
        } catch {
            print("[ERROR] Invalid JSON received")
            return encodeErrorAck(action: "unknown", error: "INVALID_JSON")
        }

        print("[INFO] Handling action=\(message.action)")

        // Step 2: action 분기 (Spec-05 §3-1)
        switch message.action {
        case "listWindows":
            return handleListWindows()
        case "focus":
            return handleFocus(message: message)
        case "key":
            return handleKey(message: message)
        case "getPermissions":
            return handleGetPermissions()
        default:
            print("[WARN] Unknown action: \(message.action)")
            return encodeErrorAck(action: message.action, error: "UNKNOWN_ACTION")
        }
    }

    // MARK: - Handler stubs (will be connected in Tasks 4~7)

    /// listWindows 핸들러 (Task 4에서 구현)
    public func handleListWindows() -> String {
        #if canImport(AppKit)
        let windows = WindowManager.listWindows()
        return formatWindowListJSON(windows)
        #else
        return formatWindowListJSON([])
        #endif
    }

    /// focus 핸들러 (Task 5에서 구현)
    public func handleFocus(message: ClientMessage) -> String {
        guard let windowId = message.windowId else {
            return encodeErrorAck(action: "focus", error: "missing windowId")
        }
        guard windowId > 0 else {
            return formatFocusAckJSON(ok: false, error: "invalid windowId")
        }
        #if canImport(AppKit)
        let windows = WindowManager.listWindows()
        return WindowFocuser.focusWithAck(windowId: windowId, windows: windows)
        #else
        return formatFocusAckJSON(ok: true)
        #endif
    }

    /// key 핸들러 (Task 6에서 구현)
    public func handleKey(message: ClientMessage) -> String {
        guard let key = message.key else {
            return encodeKeyAck(ok: false, error: "missing key")
        }
        guard VirtualKeyMap.contains(key) else {
            return encodeKeyAck(ok: false, error: "unknown key: \(key)")
        }
        let modifiers = message.modifiers ?? []
        let command = KeyCommand(key: key, modifiers: modifiers)

        #if canImport(CoreGraphics)
        let result = KeySender.send(command)
        switch result {
        case .success:
            return encodeKeyAck(ok: true)
        case .failure(let error):
            return encodeKeyAck(ok: false, error: error.description)
        }
        #else
        return encodeKeyAck(ok: true)
        #endif
    }

    /// getPermissions 핸들러 (Task 7에서 구현)
    public func handleGetPermissions() -> String {
        #if canImport(AppKit)
        let status = PermissionChecker.check()
        return formatPermissionJSON(status)
        #else
        let status = PermissionStatus(accessibility: false, screenRecording: false)
        return formatPermissionJSON(status)
        #endif
    }

    // MARK: - Encoding helpers

    private func encodeErrorAck(action: String, error: String) -> String {
        let response = ErrorAckResponse(action: action, error: error)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        guard let data = try? encoder.encode(response),
              let json = String(data: data, encoding: .utf8) else {
            return #"{"type":"ack","action":"\#(action)","ok":false,"error":"\#(error)"}"#
        }
        return json
    }

    private func encodeKeyAck(ok: Bool, error: String? = nil) -> String {
        let response = KeyAckResponse(ok: ok, error: error)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        guard let data = try? encoder.encode(response),
              let json = String(data: data, encoding: .utf8) else {
            return #"{"type":"ack","action":"key","ok":false}"#
        }
        return json
    }
}
