import Foundation

// MARK: - 권한 안내 메시지 (Spec-06 §5)

/// Accessibility 권한 거부 시 안내 메시지
public let accessibilityDeniedMessage = """
⚠️  손쉬운 사용(Accessibility) 권한이 필요합니다.
    시스템 설정 → 개인 정보 보호 및 보안 → 손쉬운 사용에서 MacHelper를 허용해주세요.
    이 권한이 없으면 창 활성화와 키 입력 전송이 작동하지 않습니다.
"""

/// Screen Recording 권한 거부 시 안내 메시지
public let screenRecordingDeniedMessage = """
⚠️  화면 기록(Screen Recording) 권한이 필요합니다.
    시스템 설정 → 개인 정보 보호 및 보안 → 화면 기록에서 MacHelper를 허용해주세요.
    이 권한이 없으면 창 제목이 표시되지 않습니다.
"""

/// 모든 권한 허용 시 메시지
public let allPermissionsGrantedMessage = """
✅  모든 권한이 허용되었습니다. MacHelper가 정상 작동합니다.
"""

/// 권한 상태에 따라 적절한 안내 메시지를 생성
/// - Parameter status: 현재 권한 상태
/// - Returns: 출력할 안내 메시지 배열
public func permissionGuidanceMessages(for status: PermissionStatus) -> [String] {
    var messages: [String] = []

    if !status.accessibility {
        messages.append(accessibilityDeniedMessage)
    }
    if !status.screenRecording {
        messages.append(screenRecordingDeniedMessage)
    }
    if status.accessibility && status.screenRecording {
        messages.append(allPermissionsGrantedMessage)
    }

    return messages
}

/// 권한 안내 메시지를 콘솔에 출력
public func printPermissionGuidance(for status: PermissionStatus) {
    let messages = permissionGuidanceMessages(for: status)
    for message in messages {
        print(message)
    }
}
