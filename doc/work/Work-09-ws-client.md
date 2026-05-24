# Work-09: I2 — WebSocket 클라이언트

| 항목 | 내용 |
|------|------|
| ID | Work-09 |
| 상태 | Backlog |
| 담당 | |
| 시작일 | |
| 완료일 | |
| 의존 | Work-08 |
| 관련 스펙 | Spec-05 |

## 1. 목표

> URLSessionWebSocketTask로 Mac 헬퍼에 연결하고, Spec-05 프로토콜대로 메시지를 송수신한다. 자동 재연결과 하트비트를 구현한다.

---

## 2. 참조 스펙 체크리스트

| Spec 섹션 | 항목 | 반영 여부 |
|-----------|------|-----------|
| Spec-05 §2 데이터 모델 | ClientMessage, ServerMessage Codable 모델 | [ ] |
| Spec-05 §3 계약 | 모든 action 전송 / type 수신 처리 | [ ] |
| Spec-05 §4 상태 전이 | 미연결→연결 중→연결됨→재연결 중 | [ ] |
| Spec-05 §5 에러 처리 | CONNECTION_LOST, HEARTBEAT_TIMEOUT 재연결 | [ ] |

---

## 3. 태스크

| # | 태스크 | 상태 | 커밋 | 비고 |
|---|--------|------|------|------|
| 1 | WebSocketManager 클래스 (ObservableObject) | [ ] | | |
| 2 | 연결/해제 메서드 | [ ] | | URLSessionWebSocketTask |
| 3 | 메시지 수신 루프 + type별 디코딩 | [ ] | | |
| 4 | 메시지 송신 메서드 (action별) | [ ] | | |
| 5 | 자동 재연결 (최대 10회, 2초 간격) | [ ] | | |
| 6 | 연결 상태 Published 프로퍼티 | [ ] | | connected/reconnecting/disconnected |

---

## 4. 기술 메모

> - URLSessionWebSocketTask.receive()는 재귀 호출로 연속 수신
> - @Published var connectionState로 UI 바인딩
> - 외부 라이브러리 불필요

---

## 5. 검증 방법

| # | 검증 항목 | 방법 | 결과 |
|---|----------|------|------|
| 1 | 연결 | Mac 헬퍼 실행 + iOS 앱 실행 → 연결 성공 | — |
| 2 | 메시지 수신 | windowList push 수신 확인 (디버그 로그) | — |
| 3 | 재연결 | Mac 헬퍼 종료 → 재시작 → 자동 재연결 | — |

---

## 6. 변경 이력

| 날짜 | 변경 내용 | 작성자 |
|------|-----------|--------|
| 2026-05-24 | 최초 작성 | |
