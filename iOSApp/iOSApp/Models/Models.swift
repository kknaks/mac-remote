import Foundation
import SwiftUI

// MARK: - 포인트 컬러 (#5eead4)

extension Color {
    /// 청록 포인트 컬러 (#5eead4) — 앱 전체 accent color
    static let accent = Color(red: 0x5E / 255.0, green: 0xEA / 255.0, blue: 0xD4 / 255.0)
}

// MARK: - WindowInfo (Spec-01 §2, MacHelper Models.swift와 JSON 계약 일치)

/// 창 정보 모델
/// - id: 창 고유 ID (kCGWindowNumber)
/// - app: 앱 이름 (kCGWindowOwnerName)
/// - title: 창 제목 (kCGWindowName, 빈 문자열 가능)
/// - pid: 프로세스 PID (kCGWindowOwnerPID)
/// - frontmost: 현재 최전면 창 여부
struct WindowInfo: Codable, Equatable, Identifiable {
    let id: Int
    let app: String
    let title: String
    let pid: Int
    let frontmost: Bool
}

// MARK: - WindowListResponse (Spec-01 §3)

/// 창 목록 응답 모델
/// { "type": "windowList", "windows": [...] }
struct WindowListResponse: Codable, Equatable {
    let type: String
    let windows: [WindowInfo]
}

// MARK: - ClientMessage (Spec-05 §2, iOS → Mac 요청)

/// iOS → Mac 요청 메시지
/// - action: "listWindows" | "focus" | "key" | "getPermissions"
/// - windowId: focus 시 대상 창 ID
/// - key: key 전송 시 키 이름
/// - modifiers: key 전송 시 modifier 목록 ["cmd", "shift", "alt", "ctrl"]
struct ClientMessage: Codable, Equatable {
    let action: String
    let windowId: Int?
    let modifiers: [String]?
    let key: String?

    init(action: String, windowId: Int? = nil, key: String? = nil, modifiers: [String]? = nil) {
        self.action = action
        self.windowId = windowId
        self.key = key
        self.modifiers = modifiers
    }
}

// MARK: - AckResponse (Spec-05 §2, Mac → iOS 응답)

/// 통합 ack 응답 모델
/// { "type": "ack", "action": "...", "ok": true/false, "error": "..." }
struct AckResponse: Codable, Equatable {
    let type: String
    let action: String
    let ok: Bool
    let error: String?
}

// MARK: - AppIconsResponse (Spec-04 §3)

/// 앱 아이콘 응답 모델
/// { "type": "appIcons", "icons": { "AppName": "base64..." } }
struct AppIconsResponse: Codable, Equatable {
    let type: String
    let icons: [String: String]
}

// MARK: - PermissionResponse (Spec-06 §3)

/// 권한 응답 모델
/// { "type": "permissions", "accessibility": true/false, "screenRecording": true/false }
struct PermissionResponse: Codable, Equatable {
    let type: String
    let accessibility: Bool
    let screenRecording: Bool
}

// MARK: - ServerMessage (수신 메시지 디코딩용)

/// 서버에서 오는 메시지의 type 필드로 분기하기 위한 열거형
enum ServerMessageType: String, Codable {
    case windowList = "windowList"
    case ack = "ack"
    case appIcons = "appIcons"
    case permissions = "permissions"
}

/// type 필드만 먼저 디코딩하여 메시지 종류를 판별
struct ServerMessageHeader: Codable {
    let type: String
}
