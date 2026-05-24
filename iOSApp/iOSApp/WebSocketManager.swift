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

    // MARK: - Connect / Disconnect (Spec-05 §4)

    /// WebSocket 서버에 연결
    /// - Parameters:
    ///   - host: 서버 IP 주소
    ///   - port: 서버 포트 (기본 8765)
    func connect(host: String, port: UInt16 = wsDefaultPort) {
        // 이미 연결 중이거나 연결된 상태면 무시
        guard connectionState == .disconnected || connectionState == .reconnecting else { return }

        self.host = host
        self.port = port
        self.isManualDisconnect = false

        let urlString = "ws://\(host):\(port)"
        guard let url = URL(string: urlString) else {
            print("[ERROR] Invalid URL: \(urlString)")
            return
        }

        print("[INFO] Connecting to \(urlString)")
        connectionState = connectionState == .reconnecting ? .reconnecting : .connecting

        let task = session.webSocketTask(with: url)
        self.webSocketTask = task
        task.resume()

        // 연결 성공 확인: 첫 번째 receive 시도
        startReceiveLoop()
        startHeartbeat()

        // 연결 성공 시 상태 변경
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if self.connectionState == .connecting || self.connectionState == .reconnecting {
                print("[INFO] Connected successfully")
                self.reconnectAttempts = 0
                self.connectionState = .connected
                // 연결 직후 listWindows 전송 (Spec-05 §4, §7 Step 3)
                self.sendListWindows()
            }
        }
    }

    /// WebSocket 연결 해제
    func disconnect() {
        isManualDisconnect = true
        stopHeartbeat()
        stopReconnectTimer()

        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil

        DispatchQueue.main.async { [weak self] in
            self?.connectionState = .disconnected
        }
        print("[INFO] Disconnected")
    }

    /// 내부용: 소켓만 정리 (재연결 전)
    private func cleanupConnection() {
        stopHeartbeat()
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
    }

    // MARK: - Receive Loop (Spec-05 §3, §4)

    /// 재귀적 메시지 수신 루프
    /// URLSessionWebSocketTask.receive()는 1회성이므로 재귀 호출로 연속 수신
    private func startReceiveLoop() {
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let message):
                self.handleReceivedMessage(message)
                // 다음 메시지 대기 (재귀)
                self.startReceiveLoop()

            case .failure(let error):
                print("[ERROR] Connection lost: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.handleConnectionLost()
                }
            }
        }
    }

    /// 수신된 WebSocket 메시지 처리
    /// - Parameter message: URLSessionWebSocketTask.Message (.string 또는 .data)
    private func handleReceivedMessage(_ message: URLSessionWebSocketTask.Message) {
        let text: String

        switch message {
        case .string(let str):
            text = str
        case .data(let data):
            guard let str = String(data: data, encoding: .utf8) else {
                print("[ERROR] Failed to decode binary message as UTF-8")
                return
            }
            text = str
        @unknown default:
            print("[ERROR] Unknown message type received")
            return
        }

        // type 필드로 분기 (Spec-05 §3-1)
        guard let data = text.data(using: .utf8) else {
            print("[ERROR] JSON decode failed: invalid UTF-8")
            return
        }

        do {
            let header = try JSONDecoder().decode(ServerMessageHeader.self, from: data)
            guard let messageType = ServerMessageType(rawValue: header.type) else {
                print("[ERROR] Unknown server message type: \(header.type)")
                return
            }

            switch messageType {
            case .windowList:
                let response = try JSONDecoder().decode(WindowListResponse.self, from: data)
                DispatchQueue.main.async { [weak self] in
                    self?.windows = response.windows
                }

            case .appIcons:
                let response = try JSONDecoder().decode(AppIconsResponse.self, from: data)
                DispatchQueue.main.async { [weak self] in
                    // 기존 아이콘에 merge (새 앱만 추가)
                    self?.appIcons.merge(response.icons) { _, new in new }
                }

            case .permissions:
                let response = try JSONDecoder().decode(PermissionResponse.self, from: data)
                DispatchQueue.main.async { [weak self] in
                    self?.permissions = response
                }

            case .ack:
                let response = try JSONDecoder().decode(AckResponse.self, from: data)
                DispatchQueue.main.async { [weak self] in
                    self?.lastAck = response
                }
            }
        } catch {
            print("[ERROR] JSON decode failed: \(error.localizedDescription)")
        }
    }

    /// 연결 끊김 처리 (Spec-05 §4, §5)
    private func handleConnectionLost() {
        guard !isManualDisconnect else { return }
        cleanupConnection()
        attemptReconnect()
    }
}
