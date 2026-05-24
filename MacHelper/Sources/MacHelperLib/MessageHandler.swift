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

/// 통합 ack 응답 모델 (Spec-05 §2)
/// 모든 ack 응답은 이 모델을 사용한다.
/// type: "ack", action: 어떤 액션에 대한 응답인지, ok: 성공 여부, error: 실패 시 에러 메시지
public struct AckResponse: Codable, Equatable {
    public let type: String
    public let action: String
    public let ok: Bool
    public let error: String?

    public init(action: String, ok: Bool, error: String? = nil) {
        self.type = "ack"
        self.action = action
        self.ok = ok
        self.error = error
    }
}

/// 에러 ack 응답 (UNKNOWN_ACTION, INVALID_JSON) — 하위 호환용
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

/// 통합 ack 응답 JSON 인코딩 (Spec-05 §2)
public func encodeAckJSON(action: String, ok: Bool, error: String? = nil) -> String {
    let response = AckResponse(action: action, ok: ok, error: error)
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
    guard let data = try? encoder.encode(response),
          let json = String(data: data, encoding: .utf8) else {
        if let error = error {
            return #"{"action":"\#(action)","error":"\#(error)","ok":false,"type":"ack"}"#
        }
        return #"{"action":"\#(action)","ok":\#(ok),"type":"ack"}"#
    }
    return json
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

        // Step 2: action 분기 (Spec-05 §3-1, Spec-03 §3-1)
        switch message.action {
        case "listWindows":
            return handleListWindows()
        case "focus":
            return handleFocus(message: message)
        case "key":
            return handleKey(message: message)
        case "holdModifiers":
            return handleHoldModifiers(message: message)
        case "releaseModifiers":
            return handleReleaseModifiers()
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
            return encodeAckJSON(action: "focus", ok: false, error: "missing windowId")
        }
        guard windowId > 0 else {
            return encodeAckJSON(action: "focus", ok: false, error: "invalid windowId")
        }
        #if canImport(AppKit)
        let windows = WindowManager.listWindows()
        return WindowFocuser.focusWithAck(windowId: windowId, windows: windows)
        #else
        return encodeAckJSON(action: "focus", ok: true)
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

    /// holdModifiers 핸들러 (Work-17, Spec-03 §3-1)
    public func handleHoldModifiers(message: ClientMessage) -> String {
        guard let raw = message.modifiers, !raw.isEmpty else {
            return encodeAckJSON(action: "holdModifiers", ok: false, error: "missing modifiers")
        }
        #if canImport(CoreGraphics)
        // Spec-03 §5 INVALID_MODIFIER: 잘못된 modifier는 무시
        let mods = raw.compactMap { Modifier(rawValue: $0) }
        guard !mods.isEmpty else {
            return encodeAckJSON(action: "holdModifiers", ok: false, error: "no valid modifiers")
        }
        let result = KeySender.holdModifiers(mods)
        switch result {
        case .success:
            return encodeAckJSON(action: "holdModifiers", ok: true)
        case .failure(let error):
            return encodeAckJSON(action: "holdModifiers", ok: false, error: error.description)
        }
        #else
        return encodeAckJSON(action: "holdModifiers", ok: true)
        #endif
    }

    /// releaseModifiers 핸들러 (Work-17, Spec-03 §3-1)
    /// Spec-03 §9 #7: 빈 상태에서도 멱등 → ack:true
    public func handleReleaseModifiers() -> String {
        #if canImport(CoreGraphics)
        let result = KeySender.releaseModifiers()
        switch result {
        case .success:
            return encodeAckJSON(action: "releaseModifiers", ok: true)
        case .failure(let error):
            return encodeAckJSON(action: "releaseModifiers", ok: false, error: error.description)
        }
        #else
        return encodeAckJSON(action: "releaseModifiers", ok: true)
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

    // MARK: - Encoding helpers (통합 ack 사용)

    private func encodeErrorAck(action: String, error: String) -> String {
        return encodeAckJSON(action: action, ok: false, error: error)
    }

    private func encodeKeyAck(ok: Bool, error: String? = nil) -> String {
        return encodeAckJSON(action: "key", ok: ok, error: error)
    }
}
