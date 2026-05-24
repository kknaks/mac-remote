import Foundation

// MARK: - JSON 출력 유틸리티

/// WindowListResponse를 Spec-01 §3 형식의 JSON 문자열로 변환
public func formatWindowListJSON(_ windows: [WindowInfo]) -> String {
    let response = WindowListResponse(windows: windows)
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

    guard let data = try? encoder.encode(response) else {
        return #"{"type":"windowList","windows":[]}"#
    }
    return String(data: data, encoding: .utf8) ?? #"{"type":"windowList","windows":[]}"#
}

/// PermissionResponse를 Spec-06 §3 형식의 JSON 문자열로 변환
public func formatPermissionJSON(_ status: PermissionStatus) -> String {
    let response = PermissionResponse(status: status)
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

    guard let data = try? encoder.encode(response) else {
        return #"{"type":"permissions","accessibility":false,"screenRecording":false}"#
    }
    return String(data: data, encoding: .utf8) ?? #"{"type":"permissions","accessibility":false,"screenRecording":false}"#
}

/// AppIconsResponse를 Spec-04 §3 형식의 JSON 문자열로 변환
public func formatAppIconsJSON(_ icons: [String: String]) -> String {
    let response = AppIconsResponse(icons: icons)
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

    guard let data = try? encoder.encode(response) else {
        return #"{"type":"appIcons","icons":{}}"#
    }
    return String(data: data, encoding: .utf8) ?? #"{"type":"appIcons","icons":{}}"#
}

/// KeyAckResponse를 Spec-03 §3-1 형식의 JSON 문자열로 변환
public func formatKeyAckJSON(_ response: KeyAckResponse) -> String {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

    guard let data = try? encoder.encode(response) else {
        return #"{"type":"ack","action":"key","ok":false}"#
    }
    return String(data: data, encoding: .utf8) ?? #"{"type":"ack","action":"key","ok":false}"#
}
