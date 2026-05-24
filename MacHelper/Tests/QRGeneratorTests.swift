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

    func test_qrGenerator_currentConnectionInfo() {
        let info = QRGenerator.currentConnectionInfo(port: 9999)
        XCTAssertEqual(info.port, 9999)
        // Linux에서는 "localhost", macOS에서는 실제 IP
        XCTAssertFalse(info.host.isEmpty)
    }

    func test_qrGenerator_currentConnectionInfo_defaultPort() {
        let info = QRGenerator.currentConnectionInfo()
        XCTAssertEqual(info.port, defaultPort)
    }

    func test_qrGenerator_defaultQRSize() {
        XCTAssertEqual(QRGenerator.defaultQRSize, 200)
    }

    // QR 이미지 생성 (macOS 전용) — Linux에서는 스킵
    // generateQRImage, scaleQRImage, generateNSImage는
    // #if canImport(CoreImage) / canImport(AppKit) 가드 내부
    // → 수동 검증 (macOS 필요)

    // MARK: - Task 3: 메뉴바 QR 표시 검증

    // QRCodeView, MenuBarContentView는 SwiftUI + AppKit 필요
    // 아래는 표시에 사용되는 데이터 로직만 검증

    func test_qrDisplay_webSocketURL_matchesExpected() {
        let info = ConnectionInfo(host: "192.168.1.10", port: 8765)
        // QRCodeView에서 표시할 URL 텍스트
        XCTAssertEqual(info.webSocketURL, "ws://192.168.1.10:8765")
    }

    func test_qrDisplay_currentInfo_hasValidURL() {
        let info = QRGenerator.currentConnectionInfo(port: 8765)
        let url = info.webSocketURL
        // ws:// prefix + host + : + port 형식
        XCTAssertTrue(url.hasPrefix("ws://"))
        XCTAssertTrue(url.contains(":8765"))
    }

    func test_appState_fullAddressText_matchesQRHost() {
        // AppState.fullAddressText와 ConnectionInfo.webSocketURL의 host:port가 일치
        let state = AppState(port: 8765)
        let ip = "192.168.1.10"
        let info = ConnectionInfo(host: ip, port: 8765)
        XCTAssertEqual(state.fullAddressText(ip: ip), "\(ip):8765")
        XCTAssertEqual(info.webSocketURL, "ws://\(ip):8765")
    }

    // MARK: - Task 4: IP 변경 감지

    func test_ipMonitor_initialIP() {
        let monitor = IPMonitor()
        // 초기 IP는 NetworkInfo.primaryIPAddress()와 동일
        XCTAssertEqual(monitor.currentIP, NetworkInfo.primaryIPAddress())
    }

    func test_ipMonitor_checkIPChange_noChange_noCallback() {
        let monitor = IPMonitor()
        var callbackCalled = false
        monitor.onIPChanged = { _ in
            callbackCalled = true
        }
        // IP가 같으면 콜백 호출 안 됨
        monitor.checkIPChange()
        XCTAssertFalse(callbackCalled)
    }

    func test_ipMonitor_checkIPChange_changed_callsCallback() {
        let monitor = IPMonitor()
        // 강제로 다른 IP 설정
        monitor._setCurrentIP("10.0.0.1")

        var receivedIP: String?
        monitor.onIPChanged = { newIP in
            receivedIP = newIP
        }

        // checkIPChange는 NetworkInfo.primaryIPAddress()와 비교
        // Linux에서 primaryIPAddress()는 "localhost"
        // currentIP를 "10.0.0.1"로 설정했으므로 변경이 감지됨
        monitor.checkIPChange()

        let expectedIP = NetworkInfo.primaryIPAddress()
        XCTAssertEqual(receivedIP, expectedIP)
        XCTAssertEqual(monitor.currentIP, expectedIP)
    }

    func test_ipMonitor_setCurrentIP() {
        let monitor = IPMonitor()
        monitor._setCurrentIP("192.168.1.100")
        XCTAssertEqual(monitor.currentIP, "192.168.1.100")
    }

    func test_ipMonitor_stopDoesNotCrash() {
        let monitor = IPMonitor()
        monitor.start()
        monitor.stop()
        // stop 후에도 에러 없음
        XCTAssertTrue(true)
    }
}
