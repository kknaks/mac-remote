import XCTest
@testable import MacHelperLib

final class ClientMessageTests: XCTestCase {

    // MARK: - ClientMessage Decoding (Spec-05 §2)

    func test_clientMessage_decodeListWindows_actionOnly() throws {
        let json = #"{"action":"listWindows"}"#
        let data = json.data(using: .utf8)!
        let message = try JSONDecoder().decode(ClientMessage.self, from: data)

        XCTAssertEqual(message.action, "listWindows")
        XCTAssertNil(message.windowId)
        XCTAssertNil(message.key)
        XCTAssertNil(message.modifiers)
    }

    func test_clientMessage_decodeFocus_withWindowId() throws {
        let json = #"{"action":"focus","windowId":123}"#
        let data = json.data(using: .utf8)!
        let message = try JSONDecoder().decode(ClientMessage.self, from: data)

        XCTAssertEqual(message.action, "focus")
        XCTAssertEqual(message.windowId, 123)
    }

    func test_clientMessage_decodeKey_withModifiers() throws {
        let json = #"{"action":"key","key":"c","modifiers":["cmd"]}"#
        let data = json.data(using: .utf8)!
        let message = try JSONDecoder().decode(ClientMessage.self, from: data)

        XCTAssertEqual(message.action, "key")
        XCTAssertEqual(message.key, "c")
        XCTAssertEqual(message.modifiers, ["cmd"])
    }

    func test_clientMessage_decodeKey_multipleModifiers() throws {
        let json = #"{"action":"key","key":"4","modifiers":["cmd","shift"]}"#
        let data = json.data(using: .utf8)!
        let message = try JSONDecoder().decode(ClientMessage.self, from: data)

        XCTAssertEqual(message.action, "key")
        XCTAssertEqual(message.key, "4")
        XCTAssertEqual(message.modifiers, ["cmd", "shift"])
    }

    func test_clientMessage_decodeGetPermissions() throws {
        let json = #"{"action":"getPermissions"}"#
        let data = json.data(using: .utf8)!
        let message = try JSONDecoder().decode(ClientMessage.self, from: data)

        XCTAssertEqual(message.action, "getPermissions")
    }

    func test_clientMessage_encode_roundTrip() throws {
        let original = ClientMessage(action: "focus", windowId: 42)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ClientMessage.self, from: data)

        XCTAssertEqual(original, decoded)
    }

    func test_clientMessage_equatable() {
        let a = ClientMessage(action: "listWindows")
        let b = ClientMessage(action: "listWindows")
        XCTAssertEqual(a, b)

        let c = ClientMessage(action: "focus", windowId: 1)
        let d = ClientMessage(action: "focus", windowId: 2)
        XCTAssertNotEqual(c, d)
    }
}

final class AckResponseTests: XCTestCase {

    // MARK: - Task 10: ack response format unification

    func test_ackResponse_success_encodesCorrectly() throws {
        let response = AckResponse(action: "focus", ok: true)
        let data = try JSONEncoder().encode(response)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertEqual(json["type"] as? String, "ack")
        XCTAssertEqual(json["action"] as? String, "focus")
        XCTAssertEqual(json["ok"] as? Bool, true)
        // error should be nil/null for success
    }

    func test_ackResponse_failure_encodesWithError() throws {
        let response = AckResponse(action: "key", ok: false, error: "unknown key: xyz")
        let data = try JSONEncoder().encode(response)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertEqual(json["type"] as? String, "ack")
        XCTAssertEqual(json["action"] as? String, "key")
        XCTAssertEqual(json["ok"] as? Bool, false)
        XCTAssertEqual(json["error"] as? String, "unknown key: xyz")
    }

    func test_ackResponse_roundTrip() throws {
        let original = AckResponse(action: "focus", ok: true, error: nil)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(AckResponse.self, from: data)
        XCTAssertEqual(original, decoded)
    }

    func test_encodeAckJSON_success_format() {
        let json = encodeAckJSON(action: "focus", ok: true)
        let parsed = parseJSON(json)

        XCTAssertEqual(parsed["type"] as? String, "ack")
        XCTAssertEqual(parsed["action"] as? String, "focus")
        XCTAssertEqual(parsed["ok"] as? Bool, true)
    }

    func test_encodeAckJSON_failure_format() {
        let json = encodeAckJSON(action: "key", ok: false, error: "unknown key: xyz")
        let parsed = parseJSON(json)

        XCTAssertEqual(parsed["type"] as? String, "ack")
        XCTAssertEqual(parsed["action"] as? String, "key")
        XCTAssertEqual(parsed["ok"] as? Bool, false)
        XCTAssertEqual(parsed["error"] as? String, "unknown key: xyz")
    }

    func test_encodeAckJSON_unknownAction_format() {
        let json = encodeAckJSON(action: "badAction", ok: false, error: "UNKNOWN_ACTION")
        let parsed = parseJSON(json)

        XCTAssertEqual(parsed["type"] as? String, "ack")
        XCTAssertEqual(parsed["action"] as? String, "badAction")
        XCTAssertEqual(parsed["ok"] as? Bool, false)
        XCTAssertEqual(parsed["error"] as? String, "UNKNOWN_ACTION")
    }

    func test_errorAck_encodesCorrectly() throws {
        let response = ErrorAckResponse(action: "badAction", error: "UNKNOWN_ACTION")
        let data = try JSONEncoder().encode(response)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertEqual(json["type"] as? String, "ack")
        XCTAssertEqual(json["action"] as? String, "badAction")
        XCTAssertEqual(json["ok"] as? Bool, false)
        XCTAssertEqual(json["error"] as? String, "UNKNOWN_ACTION")
    }

    // MARK: - All ack responses have consistent fields

    func test_allAckActions_haveConsistentFormat() {
        let handler = MessageHandler()

        // 각 action별 ack/에러 응답이 동일한 포맷을 따르는지 검증
        let testCases: [(String, [String: Any])] = [
            // focus ack
            (handler.handleFocus(message: ClientMessage(action: "focus", windowId: 123)),
             ["type": "ack", "action": "focus"]),
            // key ack
            (handler.handleKey(message: ClientMessage(action: "key", key: "c", modifiers: ["cmd"])),
             ["type": "ack", "action": "key"]),
            // unknown action ack
            (handler.handle(#"{"action":"unknown"}"#),
             ["type": "ack", "action": "unknown"]),
            // focus error
            (handler.handleFocus(message: ClientMessage(action: "focus", windowId: nil)),
             ["type": "ack", "action": "focus"]),
            // key error
            (handler.handleKey(message: ClientMessage(action: "key", key: nil)),
             ["type": "ack", "action": "key"]),
        ]

        for (jsonStr, expected) in testCases {
            let parsed = parseJSON(jsonStr)
            XCTAssertEqual(parsed["type"] as? String, expected["type"] as? String,
                          "type mismatch in: \(jsonStr)")
            XCTAssertEqual(parsed["action"] as? String, expected["action"] as? String,
                          "action mismatch in: \(jsonStr)")
            XCTAssertNotNil(parsed["ok"], "ok field missing in: \(jsonStr)")
        }
    }

    // MARK: - Helper

    private func parseJSON(_ string: String) -> [String: Any] {
        guard let data = string.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            XCTFail("Failed to parse JSON: \(string)")
            return [:]
        }
        return json
    }
}

final class MessageHandlerTests: XCTestCase {

    var handler: MessageHandler!

    override func setUp() {
        super.setUp()
        handler = MessageHandler()
    }

    // MARK: - Task 3: JSON Parsing & Action Routing

    // MARK: Invalid JSON (Spec-05 §5 INVALID_JSON)

    func test_handle_invalidJSON_returnsError() {
        let response = handler.handle("not json at all")
        let json = parseJSON(response)

        XCTAssertEqual(json["type"] as? String, "ack")
        XCTAssertEqual(json["ok"] as? Bool, false)
        XCTAssertEqual(json["error"] as? String, "INVALID_JSON")
    }

    func test_handle_emptyString_returnsInvalidJSON() {
        let response = handler.handle("")
        let json = parseJSON(response)

        XCTAssertEqual(json["type"] as? String, "ack")
        XCTAssertEqual(json["ok"] as? Bool, false)
        XCTAssertEqual(json["error"] as? String, "INVALID_JSON")
    }

    func test_handle_arrayRoot_returnsInvalidJSON() {
        // Spec-05 §2: 배열 루트 불허
        let response = handler.handle(#"[{"action":"listWindows"}]"#)
        let json = parseJSON(response)

        XCTAssertEqual(json["type"] as? String, "ack")
        XCTAssertEqual(json["ok"] as? Bool, false)
        XCTAssertEqual(json["error"] as? String, "INVALID_JSON")
    }

    // MARK: Unknown Action (Spec-05 §5 UNKNOWN_ACTION)

    func test_handle_unknownAction_returnsError() {
        let response = handler.handle(#"{"action":"doSomething"}"#)
        let json = parseJSON(response)

        XCTAssertEqual(json["type"] as? String, "ack")
        XCTAssertEqual(json["action"] as? String, "doSomething")
        XCTAssertEqual(json["ok"] as? Bool, false)
        XCTAssertEqual(json["error"] as? String, "UNKNOWN_ACTION")
    }

    // MARK: listWindows routing (Task 4: Work-01 connection)

    func test_handle_listWindows_returnsWindowList() {
        let response = handler.handle(#"{"action":"listWindows"}"#)
        let json = parseJSON(response)

        XCTAssertEqual(json["type"] as? String, "windowList")
        XCTAssertNotNil(json["windows"])
    }

    func test_handleListWindows_direct_returnsWindowListType() {
        let response = handler.handleListWindows()
        let json = parseJSON(response)

        // Spec-05 §3-1: windowList 응답 형식
        XCTAssertEqual(json["type"] as? String, "windowList")
        // Linux에서는 빈 배열
        let windows = json["windows"] as? [[String: Any]]
        XCTAssertNotNil(windows)
    }

    // MARK: focus routing (Task 5: Work-02 connection)

    func test_handle_focus_missingWindowId_returnsError() {
        let response = handler.handle(#"{"action":"focus"}"#)
        let json = parseJSON(response)

        XCTAssertEqual(json["type"] as? String, "ack")
        XCTAssertEqual(json["action"] as? String, "focus")
        XCTAssertEqual(json["ok"] as? Bool, false)
        XCTAssertEqual(json["error"] as? String, "missing windowId")
    }

    func test_handle_focus_invalidWindowId_returnsError() {
        let response = handler.handle(#"{"action":"focus","windowId":-1}"#)
        let json = parseJSON(response)

        XCTAssertEqual(json["type"] as? String, "ack")
        XCTAssertEqual(json["ok"] as? Bool, false)
        XCTAssertEqual(json["error"] as? String, "invalid windowId")
    }

    func test_handle_focus_zeroWindowId_returnsError() {
        let response = handler.handle(#"{"action":"focus","windowId":0}"#)
        let json = parseJSON(response)

        XCTAssertEqual(json["type"] as? String, "ack")
        XCTAssertEqual(json["ok"] as? Bool, false)
    }

    func test_handle_focus_validWindowId_returnsAck() {
        // Linux에서는 stub이므로 ok:true 반환
        let response = handler.handle(#"{"action":"focus","windowId":123}"#)
        let json = parseJSON(response)

        XCTAssertEqual(json["type"] as? String, "ack")
        XCTAssertEqual(json["action"] as? String, "focus")
        XCTAssertEqual(json["ok"] as? Bool, true)
    }

    func test_handleFocus_direct_missingWindowId() {
        let msg = ClientMessage(action: "focus", windowId: nil)
        let response = handler.handleFocus(message: msg)
        let json = parseJSON(response)

        XCTAssertEqual(json["type"] as? String, "ack")
        XCTAssertEqual(json["ok"] as? Bool, false)
        XCTAssertEqual(json["error"] as? String, "missing windowId")
    }

    func test_handleFocus_direct_negativeWindowId() {
        let msg = ClientMessage(action: "focus", windowId: -5)
        let response = handler.handleFocus(message: msg)
        let json = parseJSON(response)

        XCTAssertEqual(json["ok"] as? Bool, false)
        XCTAssertEqual(json["error"] as? String, "invalid windowId")
    }

    // MARK: key routing (Task 6: Work-03 connection)

    func test_handle_key_missingKey_returnsError() {
        let response = handler.handle(#"{"action":"key"}"#)
        let json = parseJSON(response)

        XCTAssertEqual(json["type"] as? String, "ack")
        XCTAssertEqual(json["action"] as? String, "key")
        XCTAssertEqual(json["ok"] as? Bool, false)
        XCTAssertEqual(json["error"] as? String, "missing key")
    }

    func test_handle_key_unknownKey_returnsError() {
        let response = handler.handle(#"{"action":"key","key":"xyz"}"#)
        let json = parseJSON(response)

        XCTAssertEqual(json["type"] as? String, "ack")
        XCTAssertEqual(json["action"] as? String, "key")
        XCTAssertEqual(json["ok"] as? Bool, false)
        XCTAssertTrue((json["error"] as? String)?.contains("unknown key") ?? false)
    }

    func test_handle_key_validKey_returnsAck() {
        let response = handler.handle(#"{"action":"key","key":"c","modifiers":["cmd"]}"#)
        let json = parseJSON(response)

        XCTAssertEqual(json["type"] as? String, "ack")
        XCTAssertEqual(json["action"] as? String, "key")
        XCTAssertEqual(json["ok"] as? Bool, true)
    }

    func test_handle_key_noModifiers_returnsAck() {
        let response = handler.handle(#"{"action":"key","key":"tab"}"#)
        let json = parseJSON(response)

        XCTAssertEqual(json["type"] as? String, "ack")
        XCTAssertEqual(json["action"] as? String, "key")
        XCTAssertEqual(json["ok"] as? Bool, true)
    }

    func test_handleKey_direct_missingKey() {
        let msg = ClientMessage(action: "key", key: nil)
        let response = handler.handleKey(message: msg)
        let json = parseJSON(response)

        XCTAssertEqual(json["type"] as? String, "ack")
        XCTAssertEqual(json["ok"] as? Bool, false)
        XCTAssertEqual(json["error"] as? String, "missing key")
    }

    func test_handleKey_direct_unknownKey() {
        let msg = ClientMessage(action: "key", key: "nonexistent")
        let response = handler.handleKey(message: msg)
        let json = parseJSON(response)

        XCTAssertEqual(json["ok"] as? Bool, false)
        XCTAssertTrue((json["error"] as? String)?.contains("unknown key") ?? false)
    }

    func test_handleKey_direct_multipleModifiers() {
        let msg = ClientMessage(action: "key", key: "4", modifiers: ["cmd", "shift"])
        let response = handler.handleKey(message: msg)
        let json = parseJSON(response)

        XCTAssertEqual(json["type"] as? String, "ack")
        XCTAssertEqual(json["action"] as? String, "key")
        XCTAssertEqual(json["ok"] as? Bool, true)
    }

    func test_handle_key_allValidKeys_returnOk() {
        // 대표적인 키들만 테스트
        let keys = ["a", "z", "0", "9", "tab", "space", "return", "escape", "f1", "up"]
        for key in keys {
            let response = handler.handle(#"{"action":"key","key":"\#(key)"}"#)
            let json = parseJSON(response)
            XCTAssertEqual(json["ok"] as? Bool, true, "key '\(key)' should return ok:true")
        }
    }

    // MARK: getPermissions routing (Task 7: Work-01 permissions connection)

    func test_handle_getPermissions_returnsPermissions() {
        let response = handler.handle(#"{"action":"getPermissions"}"#)
        let json = parseJSON(response)

        // Spec-05 §3-1: permissions 응답 형식
        XCTAssertEqual(json["type"] as? String, "permissions")
        XCTAssertNotNil(json["accessibility"])
        XCTAssertNotNil(json["screenRecording"])
    }

    func test_handleGetPermissions_direct_returnsPermissionsType() {
        let response = handler.handleGetPermissions()
        let json = parseJSON(response)

        XCTAssertEqual(json["type"] as? String, "permissions")
        // Linux에서는 accessibility: false, screenRecording: false
        XCTAssertEqual(json["accessibility"] as? Bool, false)
        XCTAssertEqual(json["screenRecording"] as? Bool, false)
    }

    func test_handle_getPermissions_outputMatchesSpecFormat() {
        // Spec-05 §3-1: {"type":"permissions","accessibility":bool,"screenRecording":bool}
        let response = handler.handleGetPermissions()
        let json = parseJSON(response)

        // type 필드 필수
        XCTAssertNotNil(json["type"])
        // accessibility, screenRecording 필드 필수 (Bool 타입)
        XCTAssertTrue(json["accessibility"] is Bool)
        XCTAssertTrue(json["screenRecording"] is Bool)
    }

    // MARK: - Edge Cases (Spec-05 §9)

    func test_handle_extraFields_ignored() {
        // 정의되지 않은 필드가 있어도 정상 처리
        let response = handler.handle(#"{"action":"listWindows","extra":"data"}"#)
        let json = parseJSON(response)

        XCTAssertEqual(json["type"] as? String, "windowList")
    }

    func test_handle_missingActionField_returnsInvalidJSON() {
        let response = handler.handle(#"{"windowId":123}"#)
        let json = parseJSON(response)

        // action 필드가 없으면 디코딩 실패 → INVALID_JSON
        XCTAssertEqual(json["type"] as? String, "ack")
        XCTAssertEqual(json["ok"] as? Bool, false)
        XCTAssertEqual(json["error"] as? String, "INVALID_JSON")
    }

    // MARK: - Helper

    private func parseJSON(_ string: String) -> [String: Any] {
        guard let data = string.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            XCTFail("Failed to parse JSON: \(string)")
            return [:]
        }
        return json
    }
}
