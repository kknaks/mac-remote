import Foundation
import Combine

// MARK: - Connection State (Spec-05 §4)

/// WebSocket 연결 상태
/// - disconnected: 미연결
/// - connecting: 연결 중
/// - connected: 연결됨
/// - reconnecting: 재연결 중
enum ConnectionState: String, Equatable {
    case disconnected = "disconnected"
    case connecting = "connecting"
    case connected = "connected"
    case reconnecting = "reconnecting"
}

// MARK: - WebSocket Shared Constants (Spec-05 §3-2)

/// WebSocket 기본 포트
let wsDefaultPort: UInt16 = 8765

/// 재연결 딜레이 (초)
let wsReconnectDelay: TimeInterval = 2.0

/// 최대 재연결 시도 횟수
let wsMaxReconnectAttempts: Int = 10

/// 하트비트 타임아웃 (초)
let wsHeartbeatInterval: TimeInterval = 10.0

// MARK: - WebSocketManager (Spec-05, Work-09)

/// WebSocket 클라이언트 매니저
/// URLSessionWebSocketTask 기반, 자동 재연결 + 하트비트 지원
/// @Published로 SwiftUI 바인딩 가능
final class WebSocketManager: ObservableObject {

    // MARK: - Published Properties

    /// 현재 연결 상태 (Spec-05 §4)
    @Published var connectionState: ConnectionState = .disconnected

    /// 최근 수신된 창 목록
    @Published var windows: [WindowInfo] = []

    /// 최근 수신된 앱 아이콘 (앱 이름 → Base64 PNG)
    @Published var appIcons: [String: String] = [:]

    /// 최근 수신된 권한 상태
    @Published var permissions: PermissionResponse?

    /// 최근 수신된 ack 응답
    @Published var lastAck: AckResponse?

    // MARK: - Internal State

    /// 서버 호스트
    private(set) var host: String = ""

    /// 서버 포트
    private(set) var port: UInt16 = wsDefaultPort

    /// 현재 재연결 시도 횟수
    private(set) var reconnectAttempts: Int = 0

    /// WebSocket 태스크
    private var webSocketTask: URLSessionWebSocketTask?

    /// URL 세션
    private let session: URLSession

    /// 하트비트 타이머
    private var heartbeatTimer: Timer?

    /// 재연결 타이머
    private var reconnectTimer: Timer?

    /// 수동 해제 플래그 (수동 해제 시 재연결 방지)
    private var isManualDisconnect: Bool = false

    // MARK: - Init

    init(session: URLSession = .shared) {
        self.session = session
    }

    deinit {
        isManualDisconnect = true
        disconnect()
    }
}
