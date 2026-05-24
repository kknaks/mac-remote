import Foundation
import MacHelperLib

// MacHelper CLI Prototype
// Usage:
//   swift run MacHelper                    — 창 목록 출력
//   swift run MacHelper key <key> [mods..] — 키 입력 전송 (Work-03)

let args = CommandLine.arguments

// MARK: - "key" 서브커맨드 (Work-03 Task 5)
// swift run MacHelper key c cmd
// swift run MacHelper key 4 cmd shift

if args.count >= 3 && args[1] == "key" {
    let keyName = args[2]
    let modifiers = Array(args.dropFirst(3))  // 나머지는 modifier

    // 키코드 유효성 검증 (플랫폼 독립)
    guard VirtualKeyMap.contains(keyName) else {
        let response = KeyAckResponse(ok: false, error: "unknown key: \(keyName)")
        print(formatKeyAckJSON(response))
        #if canImport(AppKit)
        exit(1)
        #else
        Foundation.exit(1)
        #endif
    }

    let command = KeyCommand(key: keyName, modifiers: modifiers)

    #if canImport(CoreGraphics)
    // macOS: 실제 키 전송
    let result = KeySender.send(command)
    switch result {
    case .success:
        let response = KeyAckResponse(ok: true)
        print(formatKeyAckJSON(response))
    case .failure(let error):
        let response = KeyAckResponse(ok: false, error: error.description)
        print(formatKeyAckJSON(response))
        exit(1)
    }
    #else
    // Linux/기타: 스텁 출력
    print("[INFO] Key command received (stub): key=\(keyName) modifiers=\(modifiers.joined(separator: "+"))")
    let response = KeyAckResponse(ok: true)
    print(formatKeyAckJSON(response))
    #endif

} else if args.count == 1 {
    // MARK: - 기본 동작: 창 목록 출력

    #if canImport(AppKit)
    // macOS: 실제 창 목록 수집 + 권한 확인 + JSON 출력

    // 1. 권한 확인
    let permissions = PermissionChecker.check()

    // 2. 권한 안내 메시지 출력
    printPermissionGuidance(for: permissions)

    // 3. 권한 상태 JSON 출력
    let permJSON = formatPermissionJSON(permissions)
    print(permJSON)

    // 4. 창 목록 수집
    let windows = WindowManager.listWindows()

    // 5. Screen Recording 경고 확인
    if !permissions.screenRecording && !windows.isEmpty {
        print("[WARN] 화면 기록 권한을 허용하면 창 제목이 표시됩니다.")
    }

    // 6. 창 목록 JSON 출력
    let windowJSON = formatWindowListJSON(windows)
    print(windowJSON)

    #else
    // Linux/기타: 스텁 출력
    print("MacHelper CLI Prototype")
    print("Note: macOS APIs not available on this platform.")
    print("Run on macOS for full functionality.")

    // 빈 권한 상태 + 안내 메시지 출력
    let permissions = PermissionStatus(accessibility: false, screenRecording: false)
    printPermissionGuidance(for: permissions)
    print(formatPermissionJSON(permissions))

    // 빈 창 목록 출력
    print(formatWindowListJSON([]))
    #endif

} else {
    // 사용법 출력
    print("Usage:")
    print("  MacHelper              — 창 목록 출력")
    print("  MacHelper key <key> [modifiers...]  — 키 입력 전송")
    print("")
    print("Examples:")
    print("  MacHelper key c cmd          — ⌘C 전송")
    print("  MacHelper key 4 cmd shift    — ⌘⇧4 전송")
    print("  MacHelper key tab            — Tab 전송")
}
