import Foundation
import Swifter

// MARK: - WebSocket Server Constants (Spec-05 §3-2)

/// 기본 WebSocket 서버 포트
public let defaultPort: UInt16 = 8765

/// 창 목록 push 주기 (초)
public let windowListPushInterval: TimeInterval = 1.5

/// 하트비트 주기 (초)
public let heartbeatInterval: TimeInterval = 10.0

// MARK: - WebSocket Client Session

/// 연결된 WebSocket 클라이언트 세션
public final class ClientSession {
    public let id: String
    public let session: WebSocketSession
    public var connectedAt: Date

    public init(id: String, session: WebSocketSession) {
        self.id = id
        self.session = session
        self.connectedAt = Date()
    }
}

// MARK: - WebSocketServer (Spec-05)

/// WebSocket 서버 — Swifter 기반 (Spec-05 §3)
/// 포트 8765에서 WebSocket 연결을 수신하고, 메시지를 라우팅한다.
public final class WebSocketServer {
    private let server = HttpServer()
    private let port: UInt16
    private var clients: [String: ClientSession] = []
    private let clientsLock = NSLock()
    private var pushTimer: Timer?

    /// 메시지 핸들러 (외부 주입 가능)
    public var messageHandler: MessageHandler

    /// 앱 아이콘 캐시 (Spec-04: 새 앱 감지 시 push)
    public let iconCache = IconCache()

    public init(port: UInt16 = defaultPort) {
        self.port = port
        self.messageHandler = MessageHandler()
        setupWebSocketRoute()
    }

    // MARK: - Server Lifecycle

    /// 서버 시작
    public func start() throws {
        try server.start(port, forceIPv4: false, priority: .default)
        print("[INFO] WebSocket server started on port \(port)")
        startPushTimer()
    }

    /// 서버 정지
    public func stop() {
        stopPushTimer()
        server.stop()
        clientsLock.lock()
        clients.removeAll()
        clientsLock.unlock()
        print("[INFO] WebSocket server stopped")
    }

    /// 현재 연결된 클라이언트 수
    public var clientCount: Int {
        clientsLock.lock()
        defer { clientsLock.unlock() }
        return clients.count
    }

    // MARK: - WebSocket Route Setup

    private func setupWebSocketRoute() {
        server["/"] = websocket(
            text: { [weak self] session, text in
                self?.handleTextMessage(session: session, text: text)
            },
            binary: { _, _ in
                // 바이너리 메시지는 무시
            },
            pong: { _, _ in
                // pong 처리
            },
            connected: { [weak self] session in
                self?.handleConnect(session: session)
            },
            disconnected: { [weak self] session in
                self?.handleDisconnect(session: session)
            }
        )
    }

    // MARK: - Connection Management

    private func handleConnect(session: WebSocketSession) {
        let clientId = UUID().uuidString
        let client = ClientSession(id: clientId, session: session)

        clientsLock.lock()
        clients[clientId] = client
        clientsLock.unlock()

        print("[INFO] Client connected: \(clientId)")
    }

    private func handleDisconnect(session: WebSocketSession) {
        clientsLock.lock()
        // session 참조로 클라이언트 찾기
        let disconnectedId = clients.first(where: { $0.value.session === session })?.key
        if let id = disconnectedId {
            clients.removeValue(forKey: id)
            print("[INFO] Client disconnected: \(id)")
        }
        clientsLock.unlock()
    }

    // MARK: - Message Handling

    private func handleTextMessage(session: WebSocketSession, text: String) {
        let response = messageHandler.handle(text)
        session.writeText(response)
    }

    // MARK: - Periodic Push (Spec-05 §3: 1.5초 주기)

    #if canImport(AppKit)
    private func startPushTimer() {
        pushTimer = Timer.scheduledTimer(
            withTimeInterval: windowListPushInterval,
            repeats: true
        ) { [weak self] _ in
            self?.pushWindowList()
        }
    }
    #else
    private func startPushTimer() {
        // Linux: Timer.scheduledTimer는 RunLoop 필요
        // 실제 동작은 macOS에서만 — 구조만 유지
    }
    #endif

    private func stopPushTimer() {
        pushTimer?.invalidate()
        pushTimer = nil
    }

    /// 모든 연결된 클라이언트에 windowList push
    /// 새 앱이 감지되면 appIcons도 push한다 (Spec-04, Spec-05 §7 Step 4)
    public func pushWindowList() {
        let windowListJSON = messageHandler.handleListWindows()

        clientsLock.lock()
        let currentClients = Array(clients.values)
        clientsLock.unlock()

        guard !currentClients.isEmpty else { return }
        print("[INFO] Pushing windowList to \(currentClients.count) clients")

        for client in currentClients {
            client.session.writeText(windowListJSON)
        }

        // 새 앱 감지 및 아이콘 push (Spec-04 §4)
        pushNewAppIcons()
    }

    /// 새 앱이 감지되면 appIcons를 모든 클라이언트에 push (Spec-05 §3-1 appIcons)
    public func pushNewAppIcons() {
        #if canImport(AppKit)
        let windows = WindowManager.listWindows()
        let newApps = IconExtractor.extractIcons(from: windows, cache: iconCache)

        guard !newApps.isEmpty else { return }

        let iconsResponse = iconCache.toResponse(for: newApps)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        guard let data = try? encoder.encode(iconsResponse),
              let json = String(data: data, encoding: .utf8) else { return }

        print("[INFO] Pushing appIcons for new apps: \(newApps)")
        broadcast(json)
        #endif
    }

    /// 특정 메시지를 모든 클라이언트에 broadcast
    public func broadcast(_ message: String) {
        clientsLock.lock()
        let currentClients = Array(clients.values)
        clientsLock.unlock()

        for client in currentClients {
            client.session.writeText(message)
        }
    }
}
