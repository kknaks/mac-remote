import XCTest
@testable import MacHelperLib

final class QRGeneratorTests: XCTestCase {

    // MARK: - Task 1: WebSocket URL 생성

    func test_webSocketURL_defaultPort() {
        let url = ConnectionInfo(host: "192.168.1.10", port: defaultPort).webSocketURL
        XCTAssertEqual(url, "ws://192.168.1.10:8765")
    }

    func test_webSocketURL_customPort() {
        let url = ConnectionInfo(host: "10.0.0.5", port: 9000).webSocketURL
        XCTAssertEqual(url, "ws://10.0.0.5:9000")
    }

    func test_webSocketURL_localhost() {
        let url = ConnectionInfo(host: "localhost", port: 8765).webSocketURL
        XCTAssertEqual(url, "ws://localhost:8765")
    }

    func test_connectionInfo_fromNetworkInfo() {
        // NetworkInfo.primaryIPAddress()는 Linux에서 "localhost" 반환
        let ip = NetworkInfo.primaryIPAddress()
        let info = ConnectionInfo(host: ip, port: defaultPort)
        XCTAssertTrue(info.webSocketURL.hasPrefix("ws://"))
        XCTAssertTrue(info.webSocketURL.hasSuffix(":\(defaultPort)"))
    }

    func test_connectionInfo_codable() throws {
        let info = ConnectionInfo(host: "192.168.1.10", port: 8765)
        let data = try JSONEncoder().encode(info)
        let decoded = try JSONDecoder().decode(ConnectionInfo.self, from: data)
        XCTAssertEqual(decoded.host, info.host)
        XCTAssertEqual(decoded.port, info.port)
    }

    func test_connectionInfo_equatable() {
        let a = ConnectionInfo(host: "192.168.1.10", port: 8765)
        let b = ConnectionInfo(host: "192.168.1.10", port: 8765)
        let c = ConnectionInfo(host: "10.0.0.1", port: 8765)
        XCTAssertEqual(a, b)
        XCTAssertNotEqual(a, c)
    }

    // MARK: - Task 1: QR 페이로드 형식 검증

    func test_qrPayload_format_wsPrefix() {
        let info = ConnectionInfo(host: "192.168.1.10", port: 8765)
        XCTAssertTrue(info.webSocketURL.hasPrefix(qrPrefix))
    }

    func test_qrPayload_data_utf8() {
        let info = ConnectionInfo(host: "192.168.1.10", port: 8765)
        let data = info.qrPayloadData
        XCTAssertNotNil(data)
        XCTAssertEqual(String(data: data!, encoding: .utf8), "ws://192.168.1.10:8765")
    }

    // MARK: - Task 2: QR 코드 생성 (CIFilter) — macOS 전용

    // QR 코드 생성은 CIFilter 의존으로 macOS에서만 테스트 가능
    // QRGenerator.generateQRImage() 함수 존재 확인만 — 실제 이미지 검증은 수동

    func test_qrGenerator_exists() {
        // QRGenerator 타입이 존재하는지 컴파일 타임 검증
        let _: QRGenerator.Type = QRGenerator.self
        XCTAssertTrue(true)
    }
}
