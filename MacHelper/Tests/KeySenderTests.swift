import XCTest
@testable import MacHelperLib

// MARK: - Task 1: VirtualKeyMap Tests

final class VirtualKeyMapTests: XCTestCase {

    // MARK: - a~z 키 매핑

    func test_virtualKeyMap_lookup_a_returns0() {
        XCTAssertEqual(VirtualKeyMap.keyCode(for: "a"), 0)
    }

    func test_virtualKeyMap_lookup_z_returns6() {
        XCTAssertEqual(VirtualKeyMap.keyCode(for: "z"), 6)
    }

    func test_virtualKeyMap_lookup_allAlphabets_exist() {
        let alphabet = "abcdefghijklmnopqrstuvwxyz"
        for char in alphabet {
            XCTAssertNotNil(
                VirtualKeyMap.keyCode(for: String(char)),
                "Key '\(char)' should exist in VirtualKeyMap"
            )
        }
    }

    // MARK: - 0~9 키 매핑

    func test_virtualKeyMap_lookup_0_returns29() {
        XCTAssertEqual(VirtualKeyMap.keyCode(for: "0"), 29)
    }

    func test_virtualKeyMap_lookup_1_returns18() {
        XCTAssertEqual(VirtualKeyMap.keyCode(for: "1"), 18)
    }

    func test_virtualKeyMap_lookup_allDigits_exist() {
        for digit in 0...9 {
            XCTAssertNotNil(
                VirtualKeyMap.keyCode(for: String(digit)),
                "Key '\(digit)' should exist in VirtualKeyMap"
            )
        }
    }

    func test_virtualKeyMap_lookup_digits_correctCodes() {
        // Spec-03 §2: "0"~"9": 29,18,19,20,21,23,22,26,28,25
        let expected: [(String, UInt16)] = [
            ("0", 29), ("1", 18), ("2", 19), ("3", 20), ("4", 21),
            ("5", 23), ("6", 22), ("7", 26), ("8", 28), ("9", 25),
        ]
        for (key, code) in expected {
            XCTAssertEqual(VirtualKeyMap.keyCode(for: key), code, "Key '\(key)' should map to \(code)")
        }
    }

    // MARK: - 특수키 매핑

    func test_virtualKeyMap_lookup_tab_returns48() {
        XCTAssertEqual(VirtualKeyMap.keyCode(for: "tab"), 48)
    }

    func test_virtualKeyMap_lookup_space_returns49() {
        XCTAssertEqual(VirtualKeyMap.keyCode(for: "space"), 49)
    }

    func test_virtualKeyMap_lookup_return_returns36() {
        XCTAssertEqual(VirtualKeyMap.keyCode(for: "return"), 36)
    }

    func test_virtualKeyMap_lookup_escape_returns53() {
        XCTAssertEqual(VirtualKeyMap.keyCode(for: "escape"), 53)
    }

    // MARK: - 존재하지 않는 키

    func test_virtualKeyMap_lookup_unknownKey_returnsNil() {
        XCTAssertNil(VirtualKeyMap.keyCode(for: "xyz"))
    }

    func test_virtualKeyMap_lookup_emptyString_returnsNil() {
        XCTAssertNil(VirtualKeyMap.keyCode(for: ""))
    }

    // MARK: - 대소문자 무시 (소문자만 지원)

    func test_virtualKeyMap_lookup_uppercase_returnsNil() {
        // VirtualKeyMap은 소문자만 저장, 대문자는 매핑 없음
        XCTAssertNil(VirtualKeyMap.keyCode(for: "A"))
    }

    // MARK: - F키 매핑 (추가 특수키)

    func test_virtualKeyMap_lookup_f1_returns122() {
        XCTAssertEqual(VirtualKeyMap.keyCode(for: "f1"), 122)
    }

    func test_virtualKeyMap_lookup_f12_returns111() {
        XCTAssertEqual(VirtualKeyMap.keyCode(for: "f12"), 111)
    }

    // MARK: - 화살표 키

    func test_virtualKeyMap_lookup_arrowKeys_exist() {
        XCTAssertNotNil(VirtualKeyMap.keyCode(for: "up"))
        XCTAssertNotNil(VirtualKeyMap.keyCode(for: "down"))
        XCTAssertNotNil(VirtualKeyMap.keyCode(for: "left"))
        XCTAssertNotNil(VirtualKeyMap.keyCode(for: "right"))
    }

    func test_virtualKeyMap_lookup_arrowKeys_correctCodes() {
        XCTAssertEqual(VirtualKeyMap.keyCode(for: "up"), 126)
        XCTAssertEqual(VirtualKeyMap.keyCode(for: "down"), 125)
        XCTAssertEqual(VirtualKeyMap.keyCode(for: "left"), 123)
        XCTAssertEqual(VirtualKeyMap.keyCode(for: "right"), 124)
    }

    // MARK: - contains 메서드

    func test_virtualKeyMap_contains_existingKey_returnsTrue() {
        XCTAssertTrue(VirtualKeyMap.contains("c"))
        XCTAssertTrue(VirtualKeyMap.contains("tab"))
        XCTAssertTrue(VirtualKeyMap.contains("5"))
    }

    func test_virtualKeyMap_contains_unknownKey_returnsFalse() {
        XCTAssertFalse(VirtualKeyMap.contains("xyz"))
        XCTAssertFalse(VirtualKeyMap.contains(""))
    }
}

// MARK: - Task 2: Modifier Tests

final class ModifierTests: XCTestCase {

    func test_modifier_cmd_rawValue() {
        XCTAssertEqual(Modifier.cmd.rawValue, "cmd")
    }

    func test_modifier_shift_rawValue() {
        XCTAssertEqual(Modifier.shift.rawValue, "shift")
    }

    func test_modifier_alt_rawValue() {
        XCTAssertEqual(Modifier.alt.rawValue, "alt")
    }

    func test_modifier_ctrl_rawValue() {
        XCTAssertEqual(Modifier.ctrl.rawValue, "ctrl")
    }

    func test_modifier_allCases_hasFourCases() {
        XCTAssertEqual(Modifier.allCases.count, 4)
    }

    func test_modifier_initFromRawValue_valid() {
        XCTAssertEqual(Modifier(rawValue: "cmd"), .cmd)
        XCTAssertEqual(Modifier(rawValue: "shift"), .shift)
        XCTAssertEqual(Modifier(rawValue: "alt"), .alt)
        XCTAssertEqual(Modifier(rawValue: "ctrl"), .ctrl)
    }

    func test_modifier_initFromRawValue_invalid_returnsNil() {
        XCTAssertNil(Modifier(rawValue: "command"))
        XCTAssertNil(Modifier(rawValue: "option"))
        XCTAssertNil(Modifier(rawValue: ""))
    }
}

// MARK: - KeyCommand Model Tests

final class KeyCommandTests: XCTestCase {

    func test_keyCommand_init_withModifiers() {
        let cmd = KeyCommand(key: "c", modifiers: ["cmd"])
        XCTAssertEqual(cmd.key, "c")
        XCTAssertEqual(cmd.modifiers, ["cmd"])
    }

    func test_keyCommand_init_withoutModifiers() {
        let cmd = KeyCommand(key: "tab")
        XCTAssertEqual(cmd.key, "tab")
        XCTAssertEqual(cmd.modifiers, [])
    }

    func test_keyCommand_init_multipleModifiers() {
        let cmd = KeyCommand(key: "4", modifiers: ["cmd", "shift"])
        XCTAssertEqual(cmd.key, "4")
        XCTAssertEqual(cmd.modifiers, ["cmd", "shift"])
    }

    func test_keyCommand_validModifiers_filtersInvalid() {
        // Spec-03 §5: INVALID_MODIFIER → 해당 modifier 무시, 나머지로 진행
        let cmd = KeyCommand(key: "c", modifiers: ["cmd", "invalid", "shift"])
        XCTAssertEqual(cmd.validModifiers, [.cmd, .shift])
    }

    func test_keyCommand_validModifiers_allInvalid_returnsEmpty() {
        let cmd = KeyCommand(key: "c", modifiers: ["command", "option"])
        XCTAssertEqual(cmd.validModifiers, [])
    }

    func test_keyCommand_validModifiers_emptyModifiers_returnsEmpty() {
        let cmd = KeyCommand(key: "c")
        XCTAssertEqual(cmd.validModifiers, [])
    }

    // MARK: - Codable

    func test_keyCommand_encodesToJSON_specFormat() throws {
        // Spec-03 §3-1: {"action":"key","key":"c","modifiers":["cmd"]}
        let cmd = KeyCommand(key: "c", modifiers: ["cmd"])
        let data = try JSONEncoder().encode(cmd)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertEqual(json["key"] as? String, "c")
        let mods = json["modifiers"] as? [String]
        XCTAssertEqual(mods, ["cmd"])
    }

    func test_keyCommand_decodesFromJSON_roundTrip() throws {
        let original = KeyCommand(key: "4", modifiers: ["cmd", "shift"])
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(KeyCommand.self, from: data)
        XCTAssertEqual(original, decoded)
    }

    func test_keyCommand_decodesFromJSON_specRequest() throws {
        // Spec-03 §3-1 요청 예시
        let jsonStr = #"{"key":"c","modifiers":["cmd"]}"#
        let data = jsonStr.data(using: .utf8)!
        let cmd = try JSONDecoder().decode(KeyCommand.self, from: data)
        XCTAssertEqual(cmd.key, "c")
        XCTAssertEqual(cmd.modifiers, ["cmd"])
    }

    func test_keyCommand_equatable() {
        let a = KeyCommand(key: "c", modifiers: ["cmd"])
        let b = KeyCommand(key: "c", modifiers: ["cmd"])
        XCTAssertEqual(a, b)
    }
}

// MARK: - Task 4: Error Handling Tests

final class KeySendErrorTests: XCTestCase {

    func test_unknownKey_description() {
        let err = KeySendError.unknownKey("xyz")
        XCTAssertEqual(err.description, "unknown key: xyz")
    }

    func test_accessibilityPermissionDenied_description() {
        let err = KeySendError.accessibilityPermissionDenied
        XCTAssertEqual(err.description, "손쉬운 사용 권한이 필요합니다")
    }

    func test_eventCreationFailed_description() {
        let err = KeySendError.eventCreationFailed
        XCTAssertEqual(err.description, "키 입력을 생성할 수 없습니다")
    }

    func test_unknownKey_equatable() {
        XCTAssertEqual(KeySendError.unknownKey("a"), KeySendError.unknownKey("a"))
        XCTAssertNotEqual(KeySendError.unknownKey("a"), KeySendError.unknownKey("b"))
    }

    func test_differentErrors_areNotEqual() {
        XCTAssertNotEqual(
            KeySendError.unknownKey("a"),
            KeySendError.accessibilityPermissionDenied
        )
    }
}

// MARK: - KeyAckResponse Tests (Spec-03 §3-1)

final class KeyAckResponseTests: XCTestCase {

    func test_ackResponse_success_format() throws {
        // Spec-03 §3-1: {"type":"ack","action":"key","ok":true}
        let response = KeyAckResponse(ok: true)
        XCTAssertEqual(response.type, "ack")
        XCTAssertEqual(response.action, "key")
        XCTAssertEqual(response.ok, true)
        XCTAssertNil(response.error)
    }

    func test_ackResponse_failure_format() throws {
        // Spec-03 §3-1: {"type":"ack","action":"key","ok":false,"error":"unknown key: xyz"}
        let response = KeyAckResponse(ok: false, error: "unknown key: xyz")
        XCTAssertEqual(response.type, "ack")
        XCTAssertEqual(response.action, "key")
        XCTAssertEqual(response.ok, false)
        XCTAssertEqual(response.error, "unknown key: xyz")
    }

    func test_ackResponse_success_encodesToJSON() throws {
        let response = KeyAckResponse(ok: true)
        let data = try JSONEncoder().encode(response)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertEqual(json["type"] as? String, "ack")
        XCTAssertEqual(json["action"] as? String, "key")
        XCTAssertEqual(json["ok"] as? Bool, true)
        // error should not be present for success
    }

    func test_ackResponse_failure_encodesToJSON() throws {
        let response = KeyAckResponse(ok: false, error: "unknown key: xyz")
        let data = try JSONEncoder().encode(response)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertEqual(json["type"] as? String, "ack")
        XCTAssertEqual(json["action"] as? String, "key")
        XCTAssertEqual(json["ok"] as? Bool, false)
        XCTAssertEqual(json["error"] as? String, "unknown key: xyz")
    }

    func test_ackResponse_roundTrip() throws {
        let original = KeyAckResponse(ok: false, error: "test error")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(KeyAckResponse.self, from: data)
        XCTAssertEqual(original, decoded)
    }
}

// MARK: - Work-17: Hold 모드 (Spec-03 §3-3, §4-2)

#if canImport(CoreGraphics)
final class HeldModifierStoreTests: XCTestCase {

    func test_held_initiallyEmpty() {
        let store = HeldModifierStore()
        XCTAssertTrue(store.current.isEmpty)
    }

    func test_hold_addsToHeldSet() {
        let store = HeldModifierStore()
        let added = store.hold([.cmd])
        XCTAssertEqual(store.current, [.cmd])
        XCTAssertEqual(added, [.cmd])
    }

    func test_hold_idempotent_returnsOnlyNewlyAdded() {
        let store = HeldModifierStore()
        _ = store.hold([.cmd])
        let added = store.hold([.cmd, .shift])
        XCTAssertEqual(store.current, [.cmd, .shift])
        XCTAssertEqual(added, [.shift]) // cmd was already held
    }

    func test_releaseAll_clearsAndReturnsPriorSet() {
        let store = HeldModifierStore()
        _ = store.hold([.cmd, .shift])
        let released = store.releaseAll()
        XCTAssertTrue(store.current.isEmpty)
        XCTAssertEqual(released, [.cmd, .shift])
    }

    func test_releaseAll_whenEmpty_returnsEmpty() {
        let store = HeldModifierStore()
        let released = store.releaseAll()
        XCTAssertTrue(released.isEmpty)
    }
}

final class CombinedFlagsTests: XCTestCase {

    func test_combinedFlags_requestOnly() {
        let flags = combinedEventFlags(requested: [.cmd], held: [])
        XCTAssertTrue(flags.contains(.maskCommand))
        XCTAssertFalse(flags.contains(.maskShift))
    }

    func test_combinedFlags_heldOnly() {
        let flags = combinedEventFlags(requested: [], held: [.cmd])
        XCTAssertTrue(flags.contains(.maskCommand))
    }

    func test_combinedFlags_union() {
        let flags = combinedEventFlags(requested: [.shift], held: [.cmd])
        XCTAssertTrue(flags.contains(.maskCommand))
        XCTAssertTrue(flags.contains(.maskShift))
    }

    func test_combinedFlags_dedupes() {
        // 같은 modifier가 양쪽에 있어도 단일 비트만 set
        let flags = combinedEventFlags(requested: [.cmd], held: [.cmd])
        XCTAssertTrue(flags.contains(.maskCommand))
    }
}

final class ModifierVirtualKeyCodeTests: XCTestCase {

    func test_modifier_virtualKeyCode_cmd() {
        XCTAssertEqual(Modifier.cmd.virtualKeyCode, 55)
    }

    func test_modifier_virtualKeyCode_shift() {
        XCTAssertEqual(Modifier.shift.virtualKeyCode, 56)
    }

    func test_modifier_virtualKeyCode_alt() {
        XCTAssertEqual(Modifier.alt.virtualKeyCode, 58)
    }

    func test_modifier_virtualKeyCode_ctrl() {
        XCTAssertEqual(Modifier.ctrl.virtualKeyCode, 59)
    }
}
#endif
