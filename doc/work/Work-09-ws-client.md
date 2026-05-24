# Work-09: I2 — WebSocket 클라이언트

| 항목 | 내용 |
|------|------|
| ID | Work-09 |
| 상태 | Done |
| 담당 | |
| 시작일 | 2026-05-24 |
| 완료일 | 2026-05-24 |
| 의존 | Work-08 |
| 관련 스펙 | Spec-05 |

## 1. 목표

> URLSessionWebSocketTask로 Mac 헬퍼에 연결하고, Spec-05 프로토콜대로 메시지를 송수신한다. 자동 재연결과 하트비트를 구현한다.

---

## 2. 참조 스펙 체크리스트

| Spec 섹션 | 항목 | 반영 여부 |
|-----------|------|-----------|
| Spec-05 §2 데이터 모델 | ClientMessage, ServerMessage Codable 모델 | [x] |
| Spec-05 §3 계약 | 모든 action 전송 / type 수신 처리 | [x] |
| Spec-05 §4 상태 전이 | 미연결→연결 중→연결됨→재연결 중 | [x] |
| Spec-05 §5 에러 처리 | CONNECTION_LOST, HEARTBEAT_TIMEOUT 재연결 | [x] |

---

## 3. 태스크

| # | 태스크 | 상태 | 커밋 | 비고 |
|---|--------|------|------|------|
| 1 | WebSocketManager 클래스 (ObservableObject) | [x] | 1a7892a | ConnectionState enum + 공유 상수 |
| 2 | 연결/해제 메서드 | [x] | 675028a | URLSessionWebSocketTask |
| 3 | 메시지 수신 루프 + type별 디코딩 | [x] | 5b8f7a6 | 재귀 receive + ServerMessageType 분기 |
| 4 | 메시지 송신 메서드 (action별) | [x] | 452c9dc | listWindows/focus/key/getPermissions |
| 5 | 자동 재연결 (최대 10회, 2초 간격) | [x] | 41b1676 | heartbeat ping/pong 포함 |
| 6 | 연결 상태 Published 프로퍼티 | [x] | aaf6aef | isConnected, connectionStatusText 헬퍼 |

---

## 4. 기술 메모

> - URLSessionWebSocketTask.receive()는 재귀 호출로 연속 수신
> - @Published var connectionState로 UI 바인딩
> - 외부 라이브러리 불필요

---

## 5. 검증 방법

| # | 검증 항목 | 방법 | 결과 |
|---|----------|------|------|
| 1 | 연결 | Mac 헬퍼 실행 + iOS 앱 실행 → 연결 성공 | 수동 검증 (Xcode 필요) |
| 2 | 메시지 수신 | windowList push 수신 확인 (디버그 로그) | 수동 검증 (Xcode 필요) |
| 3 | 재연결 | Mac 헬퍼 종료 → 재시작 → 자동 재연결 | 수동 검증 (Xcode 필요) |

### 로그 추적 포인트

| # | 위치 (파일/함수) | 로그 레벨 | 로그 내용 | 확인 방법 |
|---|-----------------|-----------|-----------|-----------|
| 1 | WebSocketManager.connect() | INFO | "Connecting to ws://{host}:{port}" | Xcode 콘솔 |
| 2 | WebSocketManager.connect() | INFO | "Connected successfully" | Xcode 콘솔 |
| 3 | WebSocketManager.receive() | ERROR | "Connection lost: {error}" | Xcode 콘솔 |
| 4 | WebSocketManager.reconnect() | WARN | "Reconnecting attempt {n}/{max}" | Xcode 콘솔 |
| 5 | WebSocketManager.receive() | ERROR | "JSON decode failed: {error}" | Xcode 콘솔 |
| 6 | WebSocketManager.send() | INFO | "Sending action={action}" | Xcode 콘솔 (verbose) |

---

## 6. 변경 이력

| 날짜 | 변경 내용 | 작성자 |
|------|-----------|--------|
| 2026-05-24 | 최초 작성 | |
