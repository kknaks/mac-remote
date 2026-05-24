# Spec-05: WebSocket 통신 프로토콜

| 항목 | 내용 |
|------|------|
| ID | Spec-05 |
| 상태 | Approved |
| 작성일 | 2026-05-24 |
| 최종 수정 | 2026-05-24 |
| 의존 | Spec-01, Spec-02, Spec-03, Spec-04 |
| 관련 워크 | Work-05 |

## 1. 개요

> Mac 헬퍼(서버)와 iOS 앱(클라이언트) 간의 WebSocket 통신 프로토콜을 정의한다. 모든 메시지는 JSON 형식이며, `action`(요청) / `type`(응답) 필드로 분기한다.

### 범위

- 포함: 메시지 포맷 정의, 연결/재연결, 하트비트, 주기적 push
- 제외: 각 기능의 비즈니스 로직(Spec-01~04), 페어링(Spec-07)

---

## 2. 데이터 모델

```
Entity: ClientMessage (iOS → Mac)
├── action: String     — "listWindows" | "focus" | "key" | "getPermissions"
├── windowId: Int?     — focus 시 필수
├── key: String?       — key 시 필수
└── modifiers: [String]? — key 시 사용

Entity: ServerMessage (Mac → iOS)
├── type: String       — "windowList" | "appIcons" | "permissions" | "ack"
├── windows: [WindowInfo]?  — windowList 시
├── icons: {String:String}? — appIcons 시
├── accessibility: Bool?    — permissions 시
├── screenRecording: Bool?  — permissions 시
├── action: String?         — ack 시 (어떤 액션에 대한 응답인지)
├── ok: Bool?               — ack 시
└── error: String?          — ack 실패 시
```

### 제약 조건

| 필드 | 제약 | 비고 |
|------|------|------|
| action | 정의된 값만 허용 | 미정의 action은 에러 응답 |
| type | 정의된 값만 사용 | 위치 의존 파싱 금지 |
| JSON | UTF-8, 단일 JSON 객체 | 배열 루트 불허 |

---

## 3. 계약 (Contract)

### 3-1. 메시지 / API

| 방향 | 이름 | 설명 | 상세 스펙 |
|------|------|------|-----------|
| iOS → Mac | listWindows | 창 목록 요청 | Spec-01 §3 |
| iOS → Mac | focus | 창 활성화 요청 | Spec-02 §3 |
| iOS → Mac | key | 키 입력 요청 | Spec-03 §3 |
| iOS → Mac | getPermissions | 권한 상태 요청 | Spec-06 §3 |
| Mac → iOS | windowList | 창 목록 응답/push | Spec-01 §3 |
| Mac → iOS | appIcons | 앱 아이콘 push | Spec-04 §3 |
| Mac → iOS | permissions | 권한 상태 응답 | Spec-06 §3 |
| Mac → iOS | ack | 액션 결과 응답 | Spec-02, 03 §3 |

#### iOS → Mac 요청 예시

```json
{"action":"listWindows"}
{"action":"focus","windowId":123}
{"action":"key","key":"c","modifiers":["cmd"]}
{"action":"key","key":"4","modifiers":["cmd","shift"]}
{"action":"getPermissions"}
```

#### Mac → iOS 응답 예시

```json
{"type":"windowList","windows":[
  {"id":123,"app":"Arc","title":"디자인 레퍼런스","frontmost":true},
  {"id":124,"app":"Xcode","title":"AppDelegate.swift","frontmost":false}
]}
{"type":"appIcons","icons":{"Arc":"<base64png>","Xcode":"<base64png>"}}
{"type":"permissions","accessibility":true,"screenRecording":false}
{"type":"ack","action":"focus","ok":true}
{"type":"ack","action":"key","ok":false,"error":"unknown key: xyz"}
```

### 3-2. 공유 상수 / Enum

```swift
// 서버 설정
let defaultPort: UInt16 = 8765
let windowListPushInterval: TimeInterval = 1.5  // 초
let heartbeatInterval: TimeInterval = 10.0       // 초
let reconnectDelay: TimeInterval = 2.0           // 초
let maxReconnectAttempts: Int = 10
```

---

## 4. 상태 전이 (State Machine)

### 연결 상태 (iOS 클라이언트)

```
[미연결] ──(connect)──► [연결 중] ──(성공)──► [연결됨] ──(disconnect)──► [재연결 중] ──(성공)──► [연결됨]
                            │                     │                         │
                         (실패)              (서버 종료)               (최대 횟수 초과)
                            ▼                     ▼                         ▼
                       [미연결]             [재연결 중]                  [미연결]
```

| 현재 상태 | 이벤트 | 다음 상태 | 액션 | 비고 |
|-----------|--------|-----------|------|------|
| 미연결 | connect | 연결 중 | URLSessionWebSocketTask 생성 | |
| 연결 중 | 성공 | 연결됨 | 하트비트 시작, listWindows 전송 | |
| 연결 중 | 실패 | 미연결 | 에러 표시 | |
| 연결됨 | 메시지 수신 | 연결됨 | type별 핸들러 분기 | |
| 연결됨 | 하트비트 타임아웃 | 재연결 중 | 기존 소켓 닫기 | 10초간 pong 없음 |
| 연결됨 | 서버 종료 | 재연결 중 | 재연결 시도 | |
| 재연결 중 | 성공 | 연결됨 | 하트비트 재시작 | |
| 재연결 중 | 최대 횟수 초과 | 미연결 | 에러 표시 | 10회 |

---

## 5. 에러 처리

| 에러 코드/유형 | 발생 조건 | 처리 주체 | 복구 전략 | 사용자 메시지 |
|---------------|-----------|-----------|-----------|--------------|
| UNKNOWN_ACTION | 정의되지 않은 action | Mac 헬퍼 | ack:false 응답 | — |
| INVALID_JSON | JSON 파싱 실패 | 양쪽 | 메시지 무시, 로그 | — |
| CONNECTION_LOST | WebSocket 연결 끊김 | iOS 앱 | 자동 재연결 시도 | 연결 표시등 빨간색 |
| SERVER_UNREACHABLE | 서버에 연결 불가 | iOS 앱 | 재연결 시도 (최대 10회) | "Mac 헬퍼에 연결할 수 없습니다" |
| HEARTBEAT_TIMEOUT | 10초간 pong 없음 | iOS 앱 | 재연결 시도 | 연결 표시등 노란색 → 빨간색 |

### 재시도 정책

| 에러 유형 | 재시도 | 최대 횟수 | 간격 | 비고 |
|-----------|--------|-----------|------|------|
| CONNECTION_LOST | Y | 10 | 2초 (고정) | |
| SERVER_UNREACHABLE | Y | 10 | 2초 (고정) | |
| HEARTBEAT_TIMEOUT | Y | 10 | 2초 | 재연결로 처리 |

---

## 6. 유효성 검증

| 검증 항목 | 규칙 | 검증 위치 | 실패 시 동작 |
|-----------|------|-----------|-------------|
| JSON 형식 | 유효한 JSON 객체 | Both | 메시지 무시 |
| action 필드 | 정의된 값 | Back (Mac) | UNKNOWN_ACTION 에러 |
| type 필드 | 정의된 값 | Front (iOS) | 메시지 무시 |
| 필수 필드 | action별 필수 필드 존재 | Back (Mac) | ack:false |

---

## 7. 유저 플로우 (User Flow)

### 메인 플로우 (Happy Path)

```
1. iOS 앱이 ws://{ip}:{port}로 WebSocket 연결
   ▼
2. 연결 성공 → 하트비트 시작
   ▼
3. 앱이 listWindows 전송
   ▼
4. 헬퍼가 windowList 응답 + 새 앱 아이콘 push
   ▼
5. 이후 1.5초마다 windowList push 지속
   ▼
6. 사용자 액션 시 focus/key 전송 → ack 수신
```

### 분기 플로우

| 분기 지점 | 조건 | 흐름 |
|-----------|------|------|
| Step 1 | 연결 실패 | 재연결 시도 (최대 10회, 2초 간격) |
| Step 5 | 연결 끊김 | 재연결 → 재연결 성공 시 자동으로 push 재개 |

### 실패 플로우

| 실패 지점 | 원인 | 사용자에게 보이는 것 | 복구 경로 |
|-----------|------|---------------------|-----------|
| Step 1 | IP/포트 틀림 | "연결할 수 없습니다" | 설정에서 재입력/QR 재스캔 |
| Step 1 | 다른 Wi-Fi | "연결할 수 없습니다" | 같은 Wi-Fi 확인 안내 |
| Step 5 | Mac 헬퍼 종료 | 연결 표시등 빨간색 | 헬퍼 재실행 후 자동 재연결 |

---

## 8. UI/UX 요구사항

### 화면 / 컴포넌트

| 화면 | 설명 | 목업 링크 |
|------|------|-----------|
| 전체 화면 상단 | 연결 표시등 (초록/노랑/빨강) | macro_keyboard_mockup.html |

### 사용자 인터랙션

| 동작 | 트리거 | 기대 결과 | 피드백 |
|------|--------|-----------|--------|
| — | 자동 | 연결 상태 실시간 반영 | 표시등 색상 변경 |

---

## 9. 엣지 케이스

| # | 시나리오 | 기대 동작 |
|---|----------|-----------|
| 1 | 동시에 여러 요청 전송 | 서버가 순차 처리, 각각 ack 반환 |
| 2 | 매우 큰 appIcons 메시지 | WebSocket 프레임 분할 자동 처리 |
| 3 | Wi-Fi 변경 | 연결 끊김 → 재연결 시도 → 새 IP면 실패 |
| 4 | Mac 슬립 모드 | 연결 끊김 → 깨어나면 재연결 |
| 5 | iOS 앱 백그라운드 진입 | 연결 유지하되, 복귀 시 재연결 확인 |

---

## 10. 인수 조건 (Acceptance Criteria)

- [ ] Mac 헬퍼가 포트 8765에서 WebSocket 서버를 열 수 있다
- [ ] iOS 앱이 ws://ip:8765로 연결할 수 있다
- [ ] 모든 메시지가 정의된 JSON 형식을 따른다
- [ ] action/type 필드로 메시지를 분기 처리한다
- [ ] 연결 끊김 시 자동 재연결된다 (최대 10회)
- [ ] 1.5초마다 windowList push가 동작한다
- [ ] 하트비트로 연결 상태를 감지한다

---

## 11. 변경 이력

| 날짜 | 변경 내용 | 작성자 |
|------|-----------|--------|
| 2026-05-24 | 최초 작성 | |
