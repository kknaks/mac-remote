import XCTest
@testable import MacHelperLib

final class WindowFilterTests: XCTestCase {

    // MARK: - excludedProcesses

    func test_excludedProcesses_containsRequiredEntries() {
        XCTAssertTrue(excludedProcesses.contains("Window Server"))
        XCTAssertTrue(excludedProcesses.contains("Dock"))
        XCTAssertTrue(excludedProcesses.contains("SystemUIServer"))
        XCTAssertTrue(excludedProcesses.contains("Control Center"))
        XCTAssertTrue(excludedProcesses.contains("Notification Center"))
    }

    func test_excludedProcesses_doesNotContainUserApps() {
        XCTAssertFalse(excludedProcesses.contains("Xcode"))
        XCTAssertFalse(excludedProcesses.contains("Safari"))
        XCTAssertFalse(excludedProcesses.contains("Terminal"))
    }

    // MARK: - filterWindows: layer filtering

    func test_filterWindows_layer0_included() {
        let entries = [
            RawWindowEntry(windowNumber: 1, ownerName: "Safari", windowName: "Google", ownerPID: 100, windowLayer: 0)
        ]
        let result = filterWindows(entries)
        XCTAssertEqual(result.count, 1)
    }

    func test_filterWindows_nonZeroLayer_excluded() {
        let entries = [
            RawWindowEntry(windowNumber: 1, ownerName: "Safari", windowName: "Google", ownerPID: 100, windowLayer: 1),
            RawWindowEntry(windowNumber: 2, ownerName: "Chrome", windowName: "Tab", ownerPID: 101, windowLayer: -1),
            RawWindowEntry(windowNumber: 3, ownerName: "Terminal", windowName: "bash", ownerPID: 102, windowLayer: 25),
        ]
        let result = filterWindows(entries)
        XCTAssertEqual(result.count, 0)
    }

    // MARK: - filterWindows: empty ownerName

    func test_filterWindows_emptyOwnerName_excluded() {
        let entries = [
            RawWindowEntry(windowNumber: 1, ownerName: "", windowName: "Unknown", ownerPID: 100, windowLayer: 0)
        ]
        let result = filterWindows(entries)
        XCTAssertEqual(result.count, 0)
    }

    // MARK: - filterWindows: system process exclusion

    func test_filterWindows_systemProcesses_excluded() {
        let entries = [
            RawWindowEntry(windowNumber: 1, ownerName: "Window Server", windowName: nil, ownerPID: 1, windowLayer: 0),
            RawWindowEntry(windowNumber: 2, ownerName: "Dock", windowName: nil, ownerPID: 2, windowLayer: 0),
            RawWindowEntry(windowNumber: 3, ownerName: "SystemUIServer", windowName: nil, ownerPID: 3, windowLayer: 0),
            RawWindowEntry(windowNumber: 4, ownerName: "Control Center", windowName: nil, ownerPID: 4, windowLayer: 0),
            RawWindowEntry(windowNumber: 5, ownerName: "Notification Center", windowName: nil, ownerPID: 5, windowLayer: 0),
        ]
        let result = filterWindows(entries)
        XCTAssertEqual(result.count, 0)
    }

    func test_filterWindows_userApps_included() {
        let entries = [
            RawWindowEntry(windowNumber: 10, ownerName: "Xcode", windowName: "Project", ownerPID: 100, windowLayer: 0),
            RawWindowEntry(windowNumber: 11, ownerName: "Safari", windowName: "Apple", ownerPID: 101, windowLayer: 0),
            RawWindowEntry(windowNumber: 12, ownerName: "Terminal", windowName: "bash", ownerPID: 102, windowLayer: 0),
        ]
        let result = filterWindows(entries)
        XCTAssertEqual(result.count, 3)
    }

    // MARK: - filterWindows: mixed entries

    func test_filterWindows_mixedEntries_onlyValidRemain() {
        let entries = [
            // Valid
            RawWindowEntry(windowNumber: 10, ownerName: "Arc", windowName: "Tab 1", ownerPID: 100, windowLayer: 0),
            // Excluded: non-zero layer
            RawWindowEntry(windowNumber: 11, ownerName: "Arc", windowName: "Popup", ownerPID: 100, windowLayer: 1),
            // Excluded: system process
            RawWindowEntry(windowNumber: 12, ownerName: "Dock", windowName: nil, ownerPID: 50, windowLayer: 0),
            // Valid
            RawWindowEntry(windowNumber: 13, ownerName: "Terminal", windowName: "zsh", ownerPID: 200, windowLayer: 0),
            // Excluded: empty ownerName
            RawWindowEntry(windowNumber: 14, ownerName: "", windowName: "Ghost", ownerPID: 0, windowLayer: 0),
        ]
        let result = filterWindows(entries)
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[0].windowNumber, 10)
        XCTAssertEqual(result[1].windowNumber, 13)
    }

    func test_filterWindows_emptyInput_returnsEmpty() {
        let result = filterWindows([])
        XCTAssertEqual(result.count, 0)
    }

    // MARK: - convertToWindowInfos

    func test_convertToWindowInfos_mapsFieldsCorrectly() {
        let entries = [
            RawWindowEntry(windowNumber: 42, ownerName: "Safari", windowName: "Apple", ownerPID: 300, windowLayer: 0)
        ]
        let infos = convertToWindowInfos(entries, frontmostPID: nil)
        XCTAssertEqual(infos.count, 1)
        XCTAssertEqual(infos[0].id, 42)
        XCTAssertEqual(infos[0].app, "Safari")
        XCTAssertEqual(infos[0].title, "Apple")
        XCTAssertEqual(infos[0].pid, 300)
        XCTAssertEqual(infos[0].frontmost, false)
    }

    func test_convertToWindowInfos_nilWindowName_becomesEmptyString() {
        let entries = [
            RawWindowEntry(windowNumber: 1, ownerName: "App", windowName: nil, ownerPID: 10, windowLayer: 0)
        ]
        let infos = convertToWindowInfos(entries, frontmostPID: nil)
        XCTAssertEqual(infos[0].title, "")
    }

    func test_convertToWindowInfos_emptyInput_returnsEmpty() {
        let infos = convertToWindowInfos([], frontmostPID: nil)
        XCTAssertEqual(infos.count, 0)
    }

    // MARK: - frontmost detection

    func test_frontmost_matchingPID_isTrue() {
        let entries = [
            RawWindowEntry(windowNumber: 1, ownerName: "Safari", windowName: "Tab", ownerPID: 100, windowLayer: 0),
            RawWindowEntry(windowNumber: 2, ownerName: "Xcode", windowName: "Project", ownerPID: 200, windowLayer: 0),
        ]
        let infos = convertToWindowInfos(entries, frontmostPID: 100)
        XCTAssertTrue(infos[0].frontmost)
        XCTAssertFalse(infos[1].frontmost)
    }

    func test_frontmost_noMatchingPID_allFalse() {
        let entries = [
            RawWindowEntry(windowNumber: 1, ownerName: "Safari", windowName: "Tab", ownerPID: 100, windowLayer: 0),
            RawWindowEntry(windowNumber: 2, ownerName: "Xcode", windowName: "Project", ownerPID: 200, windowLayer: 0),
        ]
        let infos = convertToWindowInfos(entries, frontmostPID: 999)
        XCTAssertFalse(infos[0].frontmost)
        XCTAssertFalse(infos[1].frontmost)
    }

    func test_frontmost_nilPID_allFalse() {
        let entries = [
            RawWindowEntry(windowNumber: 1, ownerName: "Safari", windowName: "Tab", ownerPID: 100, windowLayer: 0),
        ]
        let infos = convertToWindowInfos(entries, frontmostPID: nil)
        XCTAssertFalse(infos[0].frontmost)
    }

    func test_frontmost_multipleWindowsSamePID_onlyFirstIsTrue() {
        // Spec-01 §2: frontmost는 목록 중 최대 1개만 true
        let entries = [
            RawWindowEntry(windowNumber: 1, ownerName: "Safari", windowName: "Tab 1", ownerPID: 100, windowLayer: 0),
            RawWindowEntry(windowNumber: 2, ownerName: "Safari", windowName: "Tab 2", ownerPID: 100, windowLayer: 0),
            RawWindowEntry(windowNumber: 3, ownerName: "Safari", windowName: "Tab 3", ownerPID: 100, windowLayer: 0),
        ]
        let infos = convertToWindowInfos(entries, frontmostPID: 100)
        let frontmostCount = infos.filter { $0.frontmost }.count
        XCTAssertEqual(frontmostCount, 1, "Only one window should be frontmost")
        XCTAssertTrue(infos[0].frontmost)
        XCTAssertFalse(infos[1].frontmost)
        XCTAssertFalse(infos[2].frontmost)
    }

    func test_frontmost_mixedApps_onlyFrontmostAppFirstWindow() {
        let entries = [
            RawWindowEntry(windowNumber: 1, ownerName: "Xcode", windowName: "A", ownerPID: 200, windowLayer: 0),
            RawWindowEntry(windowNumber: 2, ownerName: "Safari", windowName: "B", ownerPID: 100, windowLayer: 0),
            RawWindowEntry(windowNumber: 3, ownerName: "Safari", windowName: "C", ownerPID: 100, windowLayer: 0),
        ]
        let infos = convertToWindowInfos(entries, frontmostPID: 100)
        XCTAssertFalse(infos[0].frontmost)  // Xcode
        XCTAssertTrue(infos[1].frontmost)   // Safari first window
        XCTAssertFalse(infos[2].frontmost)  // Safari second window
    }
}
