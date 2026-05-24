import Foundation

// MARK: - ConnectionInfo (Spec-07 §2, Work-12 Task 2)

/// WebSocket 연결 정보 모델
/// QR 코드 또는 수동 입력으로 획득한 Mac 헬퍼의 IP:포트 정보
struct ConnectionInfo: Codable, Equatable {
    /// Mac 헬퍼 IP 주소 (e.g. "192.168.1.10")
    let host: String

    /// WebSocket 포트 (기본 8765, 범위: 1024~65535)
    let port: UInt16
}

// MARK: - QR Payload Parsing (Spec-07 §2, §6)

extension ConnectionInfo {

    /// QR 코드 페이로드에서 ConnectionInfo를 파싱
    /// 형식: ws://{host}:{port}
    ///
    /// - Parameter payload: QR 코드에서 읽은 문자열
    /// - Returns: 파싱된 ConnectionInfo, 실패 시 nil
    ///
    /// 검증 규칙 (Spec-07 §6):
    /// - ws:// 접두사 필수
    /// - 유효한 IPv4 주소
    /// - 포트 범위: 1024~65535
    static func fromQRPayload(_ payload: String) -> ConnectionInfo? {
        // ws:// 접두사 확인 (Spec-07 §3-2: qrPrefix = "ws://")
        let trimmed = payload.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.lowercased().hasPrefix("ws://") else {
            return nil
        }

        // ws:// 제거 → host:port 파싱
        let hostPort = String(trimmed.dropFirst(5))
        return parseHostPort(hostPort)
    }

    /// "host:port" 문자열에서 ConnectionInfo를 파싱
    ///
    /// - Parameter input: "192.168.1.10:8765" 또는 "192.168.1.10" (포트 생략 시 기본값)
    /// - Returns: 파싱된 ConnectionInfo, 실패 시 nil
    static func fromManualInput(_ input: String) -> ConnectionInfo? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)

        // ws:// 접두사가 있으면 제거
        let hostPort: String
        if trimmed.lowercased().hasPrefix("ws://") {
            hostPort = String(trimmed.dropFirst(5))
        } else {
            hostPort = trimmed
        }

        return parseHostPort(hostPort)
    }

    /// "host:port" 파싱 공통 로직
    private static func parseHostPort(_ hostPort: String) -> ConnectionInfo? {
        let components = hostPort.split(separator: ":", maxSplits: 1)
        guard !components.isEmpty else { return nil }

        let host = String(components[0])

        // IPv4 유효성 검증 (Spec-07 §6)
        guard isValidIPv4(host) else { return nil }

        // 포트 파싱 (Spec-07 §2: 기본 8765, 범위 1024~65535)
        let port: UInt16
        if components.count == 2 {
            guard let p = UInt16(components[1]), p >= 1024 else {
                return nil
            }
            port = p
        } else {
            port = wsDefaultPort
        }

        return ConnectionInfo(host: host, port: port)
    }

    /// IPv4 주소 유효성 검증
    /// - Parameter address: IP 주소 문자열
    /// - Returns: 유효한 IPv4 주소인지 여부
    static func isValidIPv4(_ address: String) -> Bool {
        let parts = address.split(separator: ".")
        guard parts.count == 4 else { return false }

        for part in parts {
            guard let num = UInt8(part) else { return false }
            // leading zero 검사 ("01" 등 방지)
            if part.count > 1 && part.first == "0" { return false }
            _ = num // suppress unused warning
        }

        return true
    }

    /// WebSocket URL 문자열 생성
    var wsURLString: String {
        "ws://\(host):\(port)"
    }

    /// 표시용 문자열 (IP:포트)
    var displayString: String {
        "\(host):\(port)"
    }
}

// MARK: - ConnectionInfo UserDefaults Store (Spec-07 §4, Work-12 Task 4)

/// ConnectionInfo의 UserDefaults 저장/로드
/// 앱 재실행 시 저장된 정보로 자동 연결을 시도한다 (Spec-07 §9-2)
enum ConnectionInfoStore {
    /// UserDefaults 키
    private static let hostKey = "connection_host"
    private static let portKey = "connection_port"

    /// 연결 정보 저장
    /// - Parameter info: 저장할 ConnectionInfo
    static func save(_ info: ConnectionInfo) {
        UserDefaults.standard.set(info.host, forKey: hostKey)
        UserDefaults.standard.set(Int(info.port), forKey: portKey)
        print("[INFO] ConnectionInfo saved: \(info.displayString)")
    }

    /// 저장된 연결 정보 로드
    /// - Returns: 저장된 ConnectionInfo, 없으면 nil
    static func load() -> ConnectionInfo? {
        guard let host = UserDefaults.standard.string(forKey: hostKey),
              !host.isEmpty else {
            return nil
        }

        let portValue = UserDefaults.standard.integer(forKey: portKey)
        let port: UInt16 = portValue > 0 ? UInt16(portValue) : wsDefaultPort

        return ConnectionInfo(host: host, port: port)
    }

    /// 저장된 연결 정보 삭제
    static func clear() {
        UserDefaults.standard.removeObject(forKey: hostKey)
        UserDefaults.standard.removeObject(forKey: portKey)
        print("[INFO] ConnectionInfo cleared")
    }

    /// 저장된 연결 정보 존재 여부
    static var hasSaved: Bool {
        load() != nil
    }
}

// MARK: - QR Parsing Error (Spec-07 §5)

/// QR/수동입력 파싱 에러 유형
enum PairingError: Equatable {
    /// QR 코드가 ws:// 형식이 아님 (Spec-07 §5: INVALID_QR)
    case invalidQR

    /// 수동 입력 IP가 유효하지 않음 (Spec-07 §5: INVALID_IP)
    case invalidIP

    /// 연결 실패 (Spec-07 §5: CONNECTION_FAIL)
    case connectionFail

    /// 카메라 권한 거부 (Spec-07 §5: CAMERA_DENIED)
    case cameraDenied

    /// 사용자에게 표시할 메시지 (Spec-07 §5)
    var message: String {
        switch self {
        case .invalidQR:
            return "올바른 QR 코드가 아닙니다"
        case .invalidIP:
            return "올바른 IP 주소를 입력해주세요"
        case .connectionFail:
            return "Mac 헬퍼에 연결할 수 없습니다. 같은 Wi-Fi인지 확인해주세요"
        case .cameraDenied:
            return "QR 스캔을 위해 카메라 권한이 필요합니다"
        }
    }
}
