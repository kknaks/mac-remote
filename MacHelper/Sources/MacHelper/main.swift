import Foundation
import MacHelperLib

// MacHelper CLI Prototype
// Usage: swift run MacHelper

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
