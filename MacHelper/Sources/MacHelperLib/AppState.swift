import Foundation

// MARK: - AppState (Work-06: 메뉴바 앱 상태 모델)

/// 메뉴바 앱의 전체 상태를 관리하는 모델
/// MenuBarExtra에서 표시할 연결 상태, 포트, 권한 정보를 담는다.
/// 순수 Swift — SwiftUI 없이 테스트 가능
public final class AppState {

    // MARK: - Connection State

    /// WebSocket 서버가 실행 중인지 여부
    public private(set) var isServerRunning: Bool = false

    /// 서버 포트
    public private(set) var serverPort: UInt16

    /// 현재 연결된 클라이언트 수
    public private(set) var connectedClients: Int = 0

    // MARK: - Permission State

    /// 현재 권한 상태
    public private(set) var permissions: PermissionStatus

    // MARK: - Init

    public init(port: UInt16 = defaultPort) {
        self.serverPort = port
        self.permissions = PermissionStatus(accessibility: false, screenRecording: false)
    }

    // MARK: - Server State Updates

    /// 서버 시작됨
    public func serverDidStart(port: UInt16) {
        self.isServerRunning = true
        self.serverPort = port
    }

    /// 서버 정지됨
    public func serverDidStop() {
        self.isServerRunning = false
        self.connectedClients = 0
    }

    /// 클라이언트 수 갱신
    public func updateClientCount(_ count: Int) {
        self.connectedClients = max(0, count)
    }

    // MARK: - Permission Updates

    /// 권한 상태 갱신
    public func updatePermissions(_ status: PermissionStatus) {
        self.permissions = status
    }

    // MARK: - Display Strings

    /// 메뉴바에 표시할 연결 상태 문자열
    /// Spec-06 §8: "연결 N대" 형식
    public var connectionStatusText: String {
        if !isServerRunning {
            return "서버 꺼짐"
        }
        if connectedClients == 0 {
            return "대기 중"
        }
        return "연결 \(connectedClients)대"
    }

    /// 메뉴바에 표시할 IP:포트 문자열
    public var addressText: String {
        return "포트: \(serverPort)"
    }

    /// IP:포트 전체 주소 문자열 (iOS 앱 연결용)
    public func fullAddressText(ip: String) -> String {
        return "\(ip):\(serverPort)"
    }

    /// Accessibility 권한 상태 표시 문자열
    public var accessibilityStatusText: String {
        return permissions.accessibility ? "✅ 손쉬운 사용" : "❌ 손쉬운 사용"
    }

    /// Screen Recording 권한 상태 표시 문자열
    public var screenRecordingStatusText: String {
        return permissions.screenRecording ? "✅ 화면 기록" : "❌ 화면 기록"
    }

    /// 모든 권한이 허용되었는지
    public var allPermissionsGranted: Bool {
        return permissions.accessibility && permissions.screenRecording
    }

    /// 메뉴바 아이콘 이름 (SF Symbol)
    /// 서버 꺼짐: 빈 모니터, 연결 0: 점선, 연결 있음: 채워진 모니터
    public var menuBarIconName: String {
        if !isServerRunning {
            return "desktopcomputer.trianglebadge.exclamationmark"
        }
        if connectedClients > 0 {
            return "desktopcomputer.and.arrow.down"
        }
        return "desktopcomputer"
    }
}

// MARK: - System Settings URLs (Spec-06 §5, §7)

/// 시스템 설정 URL 상수
public enum SystemSettingsURL {
    /// 손쉬운 사용 설정
    public static let accessibility = "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
    /// 화면 기록 설정
    public static let screenRecording = "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture"
}
