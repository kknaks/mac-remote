import Foundation

// MARK: - Modifier Enum (Spec-03 §3-2)

/// 키 modifier 열거형
public enum Modifier: String, Codable, CaseIterable {
    case cmd   = "cmd"
    case shift = "shift"
    case alt   = "alt"
    case ctrl  = "ctrl"
}

// MARK: - KeyCommand Model (Spec-03 §2)

/// 키 입력 명령 모델
/// - key: 키 이름 ("c", "v", "z", "tab", "4" 등)
/// - modifiers: modifier 목록 ["cmd", "shift", "alt", "ctrl"]
public struct KeyCommand: Codable, Equatable {
    public let key: String
    public let modifiers: [String]

    public init(key: String, modifiers: [String] = []) {
        self.key = key
        self.modifiers = modifiers
    }

    /// modifiers 문자열 배열에서 유효한 Modifier만 필터링
    /// Spec-03 §5: INVALID_MODIFIER → 해당 modifier 무시, 나머지로 진행
    public var validModifiers: [Modifier] {
        return modifiers.compactMap { Modifier(rawValue: $0) }
    }
}

// MARK: - KeySendError (Spec-03 §5)

/// 키 전송 에러
public enum KeySendError: Error, Equatable {
    /// key가 VirtualKeyMap에 없음
    case unknownKey(String)
    /// Accessibility 권한 없음
    case accessibilityPermissionDenied
    /// CGEvent 생성 실패
    case eventCreationFailed
}

extension KeySendError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .unknownKey(let key):
            return "unknown key: \(key)"
        case .accessibilityPermissionDenied:
            return "손쉬운 사용 권한이 필요합니다"
        case .eventCreationFailed:
            return "키 입력을 생성할 수 없습니다"
        }
    }
}

// MARK: - VirtualKeyMap (Spec-03 §2)

/// macOS 가상 키코드 매핑 테이블
/// 키 이름(소문자) → macOS virtual key code (UInt16)
public enum VirtualKeyMap {

    /// 전체 매핑 테이블
    private static let map: [String: UInt16] = {
        var m = [String: UInt16]()

        // a~z (macOS virtual key codes)
        m["a"] = 0
        m["s"] = 1
        m["d"] = 2
        m["f"] = 3
        m["h"] = 4
        m["g"] = 5
        m["z"] = 6
        m["x"] = 7
        m["c"] = 8
        m["v"] = 9
        m["b"] = 11
        m["q"] = 12
        m["w"] = 13
        m["e"] = 14
        m["r"] = 15
        m["y"] = 16
        m["t"] = 17
        m["o"] = 31
        m["u"] = 32
        m["i"] = 34
        m["p"] = 35
        m["l"] = 37
        m["j"] = 38
        m["k"] = 40
        m["n"] = 45
        m["m"] = 46

        // 0~9 (Spec-03 §2: 29,18,19,20,21,23,22,26,28,25)
        m["0"] = 29
        m["1"] = 18
        m["2"] = 19
        m["3"] = 20
        m["4"] = 21
        m["5"] = 23
        m["6"] = 22
        m["7"] = 26
        m["8"] = 28
        m["9"] = 25

        // 특수키
        m["tab"] = 48
        m["space"] = 49
        m["return"] = 36
        m["escape"] = 53
        m["delete"] = 51       // backspace
        m["forwarddelete"] = 117

        // 화살표
        m["up"] = 126
        m["down"] = 125
        m["left"] = 123
        m["right"] = 124

        // F1~F12
        m["f1"] = 122
        m["f2"] = 120
        m["f3"] = 99
        m["f4"] = 118
        m["f5"] = 96
        m["f6"] = 97
        m["f7"] = 98
        m["f8"] = 100
        m["f9"] = 101
        m["f10"] = 109
        m["f11"] = 103
        m["f12"] = 111

        // 기타
        m["home"] = 115
        m["end"] = 119
        m["pageup"] = 116
        m["pagedown"] = 121

        // 구두점/기호 (US 키보드 기준)
        m["-"] = 27         // minus
        m["="] = 24         // equal
        m["["] = 33         // left bracket
        m["]"] = 30         // right bracket
        m["\\"] = 42        // backslash
        m[";"] = 41         // semicolon
        m["'"] = 39         // quote
        m[","] = 43         // comma
        m["."] = 47         // period
        m["/"] = 44         // slash
        m["`"] = 50         // grave accent

        return m
    }()

    /// 키 이름으로 가상 키코드 조회
    /// - Parameter key: 키 이름 (소문자)
    /// - Returns: 가상 키코드, 없으면 nil
    public static func keyCode(for key: String) -> UInt16? {
        return map[key]
    }

    /// 키가 매핑 테이블에 존재하는지 확인
    public static func contains(_ key: String) -> Bool {
        return map[key] != nil
    }
}

// MARK: - Modifier → CGEventFlags 매핑 (Task 2)

#if canImport(CoreGraphics)
import CoreGraphics

extension Modifier {
    /// Modifier → CGEventFlags 변환 (Spec-03 §3-2)
    public var eventFlag: CGEventFlags {
        switch self {
        case .cmd:   return .maskCommand
        case .shift: return .maskShift
        case .alt:   return .maskAlternate
        case .ctrl:  return .maskControl
        }
    }
}

/// 유효한 Modifier 배열을 CGEventFlags로 합산
public func combinedEventFlags(from modifiers: [Modifier]) -> CGEventFlags {
    var flags = CGEventFlags()
    for modifier in modifiers {
        flags.insert(modifier.eventFlag)
    }
    return flags
}
#endif

// MARK: - KeySender (Task 3, 4)

#if canImport(CoreGraphics)
import CoreGraphics

public enum KeySender {

    /// 키 입력 전송 (Spec-03 §4 상태 전이)
    /// 키코드 조회 → 이벤트 생성 → keyDown → keyUp
    ///
    /// - Parameter command: KeyCommand (key + modifiers)
    /// - Returns: Result<Void, KeySendError>
    public static func send(_ command: KeyCommand) -> Result<Void, KeySendError> {
        // 1. 키코드 조회
        guard let keyCode = VirtualKeyMap.keyCode(for: command.key) else {
            print("[ERROR] Unknown key: \(command.key)")
            return .failure(.unknownKey(command.key))
        }

        // 2. Accessibility 권한 확인
        if !AXIsProcessTrusted() {
            print("[ERROR] Accessibility permission denied")
            return .failure(.accessibilityPermissionDenied)
        }

        // 3. modifier flags 계산
        // Spec-03 §5: INVALID_MODIFIER → 해당 modifier 무시
        let validMods = command.validModifiers
        let flags = combinedEventFlags(from: validMods)

        let modDesc = validMods.map { $0.rawValue }.joined(separator: "+")
        print("[INFO] Sending key=\(command.key) modifiers=\(modDesc)")

        // 4. CGEvent 생성 - keyDown
        guard let keyDownEvent = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: true) else {
            print("[ERROR] CGEvent creation failed")
            return .failure(.eventCreationFailed)
        }

        // 5. CGEvent 생성 - keyUp
        guard let keyUpEvent = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: false) else {
            print("[ERROR] CGEvent creation failed")
            return .failure(.eventCreationFailed)
        }

        // 6. modifier flags 설정
        if !validMods.isEmpty {
            keyDownEvent.flags = flags
            keyUpEvent.flags = flags
        }

        // 7. 전송 (Spec-03 §4: keyDown → keyUp 쌍)
        keyDownEvent.post(tap: .cghidEventTap)
        keyUpEvent.post(tap: .cghidEventTap)

        return .success(())
    }
}
#endif

// MARK: - KeyAckResponse (Spec-03 §3-1)

/// 키 입력 응답 모델
public struct KeyAckResponse: Codable, Equatable {
    public let type: String
    public let action: String
    public let ok: Bool
    public let error: String?

    public init(ok: Bool, error: String? = nil) {
        self.type = "ack"
        self.action = "key"
        self.ok = ok
        self.error = error
    }
}
