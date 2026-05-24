import Foundation

/// 창 정보 모델 (Spec-01 §2)
/// - id: kCGWindowNumber, 창 고유 ID
/// - app: kCGWindowOwnerName, 앱 이름
/// - title: kCGWindowName, 창 제목 (빈 문자열 가능)
/// - pid: kCGWindowOwnerPID, 프로세스 PID
/// - frontmost: 현재 최전면 창 여부
public struct WindowInfo: Codable, Equatable {
    public let id: Int
    public let app: String
    public let title: String
    public let pid: Int
    public let frontmost: Bool

    public init(id: Int, app: String, title: String, pid: Int, frontmost: Bool) {
        self.id = id
        self.app = app
        self.title = title
        self.pid = pid
        self.frontmost = frontmost
    }
}

/// 창 목록 응답 모델 (Spec-01 §3)
public struct WindowListResponse: Codable, Equatable {
    public let type: String
    public let windows: [WindowInfo]

    public init(windows: [WindowInfo]) {
        self.type = "windowList"
        self.windows = windows
    }
}
