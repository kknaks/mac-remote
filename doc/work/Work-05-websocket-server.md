# Work-05: M5 — WebSocket 서버

| 항목 | 내용 |
|------|------|
| ID | Work-05 |
| 상태 | Done |
| 담당 | |
| 시작일 | 2026-05-24 |
| 완료일 | 2026-05-24 |
| 의존 | Work-01, Work-02, Work-03, Work-04 |
| 관련 스펙 | Spec-05 |

## 1. 목표

> Swifter를 사용해 WebSocket 서버를 구현한다. Spec-05 프로토콜대로 명령 수신/응답하고, 창 목록을 주기적으로 push한다.

---

## 2. 참조 스펙 체크리스트

| Spec 섹션 | 항목 | 반영 여부 |
|-----------|------|-----------|
| Spec-05 §2 데이터 모델 | ClientMessage, ServerMessage | [x] |
| Spec-05 §3 계약 | 모든 action/type 메시지 처리 | [x] |
| Spec-05 §4 상태 전이 | 서버 측 연결 관리 | [x] |
| Spec-05 §5 에러 처리 | UNKNOWN_ACTION, INVALID_JSON | [x] |

---

## 3. 태스크

| # | 태스크 | 상태 | 커밋 | 비고 |
|---|--------|------|------|------|
| 1 | Swifter SPM 의존성 추가 | [x] | a0abc02 | Package.swift에 swifter 1.5.0+ 추가 |
| 2 | WebSocket 서버 기본 구조 (포트 8765) | [x] | 899508c | WebSocketServer.swift + MessageHandler.swift 생성 |
| 3 | JSON 메시지 파싱 (action 분기) | [x] | bb73c60 | ClientMessage 디코딩, action switch 분기 |
| 4 | listWindows 핸들러 (Work-01 연결) | [x] | 6bb2784 | WindowManager.listWindows() 연결 |
| 5 | focus 핸들러 (Work-02 연결) | [x] | 7b653a3 | windowId 검증 + WindowFocuser 연결 |
| 6 | key 핸들러 (Work-03 연결) | [x] | 2de46a2 | key/modifiers 검증 + KeySender 연결 |
| 7 | getPermissions 핸들러 (Work-01 권한 로직) | [x] | f7bb500 | PermissionChecker.check() 연결 |
| 8 | appIcons push (Work-04 연결, 새 앱 감지 시) | [x] | 1765e2b | IconCache + IconExtractor 연결, broadcast |
| 9 | windowList 주기적 push (1.5초) | [x] | dc6e349 | Timer.scheduledTimer 1.5초 주기 |
| 10 | ack 응답 포맷 통일 | [x] | 56d582f | AckResponse 통합 모델 + encodeAckJSON 함수 |

---

## 4. 기술 메모

> - Swifter: HttpServer 생성 → websocket route 등록
> - 연결된 클라이언트 관리 (다중 연결은 미지원이나, 구조는 배열로)
> - Timer.scheduledTimer로 주기적 push
> - ClientMessage: action 기반 디코딩, optional 필드로 모든 액션 커버
> - AckResponse: 통합 ack 모델 (type, action, ok, error)
> - MessageHandler: 순수 Swift 로직 (파싱 + 라우팅), macOS API는 #if canImport로 분리
> - WebSocketServer: Swifter 기반, ClientSession으로 클라이언트 관리

---

## 5. 검증 방법

| # | 검증 항목 | 방법 | 결과 |
|---|----------|------|------|
| 1 | 서버 시작 | `swift run MacHelper` → "WebSocket server started on port 8765" | 수동 검증 (macOS 필요) |
| 2 | 연결 | `websocat ws://localhost:8765` 로 연결 | 수동 검증 (macOS 필요) |
| 3 | listWindows | `{"action":"listWindows"}` 전송 → windowList 응답 | 수동 검증 (macOS 필요) |
| 4 | focus | `{"action":"focus","windowId":123}` 전송 → ack 응답 | 수동 검증 (macOS 필요) |
| 5 | key | `{"action":"key","key":"c","modifiers":["cmd"]}` 전송 → ack | 수동 검증 (macOS 필요) |
| 6 | 주기적 push | 연결 유지 → 1.5초마다 windowList 수신 확인 | 수동 검증 (macOS 필요) |
| 7 | JSON 파싱 | 유효/무효 JSON 테스트 (MessageHandlerTests) | 자동 테스트 통과 |
| 8 | action 라우팅 | 4개 action + unknown action 테스트 | 자동 테스트 통과 |
| 9 | ack 포맷 | 모든 ack 응답 필드 일관성 검증 | 자동 테스트 통과 |
| 10 | 상수 검증 | defaultPort=8765, pushInterval=1.5, heartbeat=10 | 자동 테스트 통과 |

### 로그 추적 포인트

| # | 위치 (파일/함수) | 로그 레벨 | 로그 내용 | 확인 방법 |
|---|-----------------|-----------|-----------|-----------|
| 1 | WebSocketServer.start() | INFO | "WebSocket server started on port {port}" | 콘솔 |
| 2 | WebSocketServer.handleConnect() | INFO | "Client connected: {clientId}" | 콘솔 |
| 3 | WebSocketServer.handleDisconnect() | INFO | "Client disconnected: {clientId}" | 콘솔 |
| 4 | MessageHandler.handle() | WARN | "Unknown action: {action}" | 콘솔 |
| 5 | MessageHandler.handle() | ERROR | "Invalid JSON received" | 콘솔 |
| 6 | MessageHandler.handle() | INFO | "Handling action={action}" | 콘솔 |
| 7 | WebSocketServer.pushWindowList() | INFO | "Pushing windowList to {n} clients" | 콘솔 |
| 8 | WebSocketServer.pushNewAppIcons() | INFO | "Pushing appIcons for new apps: {apps}" | 콘솔 |

---

## 6. 변경 이력

| 날짜 | 변경 내용 | 작성자 |
|------|-----------|--------|
| 2026-05-24 | 최초 작성 | |
| 2026-05-24 | 10개 태스크 전체 구현 완료 (Done) | |
