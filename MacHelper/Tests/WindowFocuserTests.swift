import XCTest
@testable import MacHelperLib

final class WindowFocuserTests: XCTestCase {

    // MARK: - Sample data

    let sampleWindows = [
        WindowInfo(id: 100, app: "Safari", title: "Google", pid: 1001, frontmost: true),
        WindowInfo(id: 200, app: "Terminal", title: "bash", pid: 1002, frontmost: false),
        WindowInfo(id: 300, app: "Xcode", title: "Project", pid: 1003, frontmost: false),
        WindowInfo(id: 400, app: "Safari", title: "GitHub", pid: 1001, frontmost: false),
    ]

    // MARK: - Task 1: windowId → PID 조회

    func test_lookupPID_validWindowId_returnsPID() {
        let result = lookupPID(windowId: 200, in: sampleWindows)
        XCTAssertEqual(result, 1002)
    }

    func test_lookupPID_invalidWindowId_returnsNil() {
        let result = lookupPID(windowId: 999, in: sampleWindows)
        XCTAssertNil(result)
    }

    func test_lookupPID_emptyList_returnsNil() {
        let result = lookupPID(windowId: 100, in: [])
        XCTAssertNil(result)
    }

    func test_lookupPID_sameAppMultipleWindows_returnsCorrectPID() {
        // Spec-02 §9 #3: 같은 앱 창 5개
        let result1 = lookupPID(windowId: 100, in: sampleWindows)
        let result2 = lookupPID(windowId: 400, in: sampleWindows)
        XCTAssertEqual(result1, 1001)
        XCTAssertEqual(result2, 1001)
    }

    // MARK: - Task 1: lookupWindow

    func test_lookupWindow_validId_returnsWindowInfo() {
        let result = lookupWindow(windowId: 200, in: sampleWindows)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.app, "Terminal")
        XCTAssertEqual(result?.title, "bash")
        XCTAssertEqual(result?.pid, 1002)
    }

    func test_lookupWindow_invalidId_returnsNil() {
        let result = lookupWindow(windowId: 999, in: sampleWindows)
        XCTAssertNil(result)
    }

    // MARK: - Task 4: FocusError

    func test_focusError_windowNotFound_equatable() {
        let error1 = FocusError.windowNotFound(windowId: 100)
        let error2 = FocusError.windowNotFound(windowId: 100)
        let error3 = FocusError.windowNotFound(windowId: 200)
        XCTAssertEqual(error1, error2)
        XCTAssertNotEqual(error1, error3)
    }

    func test_focusError_processDead_equatable() {
        let error1 = FocusError.processDead(pid: 1001)
        let error2 = FocusError.processDead(pid: 1001)
        let error3 = FocusError.processDead(pid: 1002)
        XCTAssertEqual(error1, error2)
        XCTAssertNotEqual(error1, error3)
    }

    func test_focusError_axPermissionDenied_equatable() {
        let error1 = FocusError.axPermissionDenied
        let error2 = FocusError.axPermissionDenied
        XCTAssertEqual(error1, error2)
    }

    func test_focusError_differentTypes_notEqual() {
        let error1 = FocusError.windowNotFound(windowId: 100)
        let error2 = FocusError.processDead(pid: 100)
        let error3 = FocusError.axPermissionDenied
        XCTAssertNotEqual(error1, error2)
        XCTAssertNotEqual(error1, error3)
        XCTAssertNotEqual(error2, error3)
    }

    // MARK: - Task 4: FocusAckResponse model

    func test_focusAckResponse_success() {
        let response = FocusAckResponse(ok: true)
        XCTAssertEqual(response.type, "ack")
        XCTAssertEqual(response.action, "focus")
        XCTAssertTrue(response.ok)
        XCTAssertNil(response.error)
    }

    func test_focusAckResponse_failure_withError() {
        let response = FocusAckResponse(ok: false, error: "window not found")
        XCTAssertEqual(response.type, "ack")
        XCTAssertEqual(response.action, "focus")
        XCTAssertFalse(response.ok)
        XCTAssertEqual(response.error, "window not found")
    }

    // MARK: - Task 4: FocusAck JSON format (Spec-02 §3)

    func test_formatFocusAckJSON_success() {
        let json = formatFocusAckJSON(ok: true)
        let data = json.data(using: .utf8)!
        let decoded = try! JSONDecoder().decode(FocusAckResponse.self, from: data)
        XCTAssertEqual(decoded.type, "ack")
        XCTAssertEqual(decoded.action, "focus")
        XCTAssertTrue(decoded.ok)
        XCTAssertNil(decoded.error)
    }

    func test_formatFocusAckJSON_failure() {
        let json = formatFocusAckJSON(ok: false, error: "window not found")
        let data = json.data(using: .utf8)!
        let decoded = try! JSONDecoder().decode(FocusAckResponse.self, from: data)
        XCTAssertEqual(decoded.type, "ack")
        XCTAssertEqual(decoded.action, "focus")
        XCTAssertFalse(decoded.ok)
        XCTAssertEqual(decoded.error, "window not found")
    }

    // MARK: - Task 4: Error message mapping

    func test_focusErrorMessage_windowNotFound() {
        let message = focusErrorMessage(for: .windowNotFound(windowId: 123))
        XCTAssertEqual(message, "window not found")
    }

    func test_focusErrorMessage_processDead() {
        let message = focusErrorMessage(for: .processDead(pid: 456))
        XCTAssertEqual(message, "process dead")
    }

    func test_focusErrorMessage_axPermissionDenied() {
        let message = focusErrorMessage(for: .axPermissionDenied)
        XCTAssertEqual(message, "accessibility permission denied")
    }

    // MARK: - FocusResult

    func test_focusResult_equatable() {
        XCTAssertEqual(FocusResult.fullSuccess, FocusResult.fullSuccess)
        XCTAssertEqual(FocusResult.appOnlyActivated, FocusResult.appOnlyActivated)
        XCTAssertNotEqual(FocusResult.fullSuccess, FocusResult.appOnlyActivated)
    }

    // MARK: - FocusAckResponse JSON round-trip (Spec-02 §3 계약 검증)

    func test_focusAckJSON_matchesSpecFormat_success() {
        // Spec-02 §3: {"type":"ack","action":"focus","ok":true}
        let json = formatFocusAckJSON(ok: true)
        let data = json.data(using: .utf8)!
        let dict = try! JSONSerialization.jsonObject(with: data) as! [String: Any]
        XCTAssertEqual(dict["type"] as? String, "ack")
        XCTAssertEqual(dict["action"] as? String, "focus")
        XCTAssertEqual(dict["ok"] as? Bool, true)
        // error 키는 없거나 null
        XCTAssertTrue(dict["error"] == nil || dict["error"] is NSNull)
    }

    func test_focusAckJSON_matchesSpecFormat_failure() {
        // Spec-02 §3: {"type":"ack","action":"focus","ok":false,"error":"window not found"}
        let json = formatFocusAckJSON(ok: false, error: "window not found")
        let data = json.data(using: .utf8)!
        let dict = try! JSONSerialization.jsonObject(with: data) as! [String: Any]
        XCTAssertEqual(dict["type"] as? String, "ack")
        XCTAssertEqual(dict["action"] as? String, "focus")
        XCTAssertEqual(dict["ok"] as? Bool, false)
        XCTAssertEqual(dict["error"] as? String, "window not found")
    }

    // MARK: - Error scenarios via focusErrorMessage mapping

    func test_allFocusErrors_haveMessages() {
        // 모든 에러 타입이 유의미한 메시지를 가지는지 확인
        let errors: [FocusError] = [
            .windowNotFound(windowId: 1),
            .processDead(pid: 1),
            .axPermissionDenied,
        ]
        for error in errors {
            let message = focusErrorMessage(for: error)
            XCTAssertFalse(message.isEmpty, "Error message should not be empty for \(error)")
        }
    }
}
