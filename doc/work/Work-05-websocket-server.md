# Work-05: M5 — WebSocket 서버

| 항목 | 내용 |
|------|------|
| ID | Work-05 |
| 상태 | Backlog |
| 담당 | |
| 시작일 | |
| 완료일 | |
| 의존 | Work-01, Work-02, Work-03, Work-04 |
| 관련 스펙 | Spec-05 |

## 1. 목표

> Swifter를 사용해 WebSocket 서버를 구현한다. Spec-05 프로토콜대로 명령 수신/응답하고, 창 목록을 주기적으로 push한다.

---

## 2. 참조 스펙 체크리스트

| Spec 섹션 | 항목 | 반영 여부 |
|-----------|------|-----------|
| Spec-05 §2 데이터 모델 | ClientMessage, ServerMessage | [ ] |
| Spec-05 §3 계약 | 모든 action/type 메시지 처리 | [ ] |
| Spec-05 §4 상태 전이 | 서버 측 연결 관리 | [ ] |
| Spec-05 §5 에러 처리 | UNKNOWN_ACTION, INVALID_JSON | [ ] |

---

## 3. 태스크

| # | 태스크 | 상태 | 커밋 | 비고 |
|---|--------|------|------|------|
| 1 | Swifter SPM 의존성 추가 | [ ] | | |
| 2 | WebSocket 서버 기본 구조 (포트 8765) | [ ] | | |
| 3 | JSON 메시지 파싱 (action 분기) | [ ] | | |
| 4 | listWindows 핸들러 (Work-01 연결) | [ ] | | |
| 5 | focus 핸들러 (Work-02 연결) | [ ] | | |
| 6 | key 핸들러 (Work-03 연결) | [ ] | | |
| 7 | getPermissions 핸들러 (Work-01 권한 로직) | [ ] | | |
| 8 | appIcons push (Work-04 연결, 새 앱 감지 시) | [ ] | | |
| 9 | windowList 주기적 push (1.5초) | [ ] | | |
| 10 | ack 응답 포맷 통일 | [ ] | | |

---

## 4. 기술 메모

> - Swifter: HttpServer 생성 → websocket route 등록
> - 연결된 클라이언트 관리 (다중 연결은 미지원이나, 구조는 배열로)
> - Timer.scheduledTimer로 주기적 push

---

## 5. 검증 방법

| # | 검증 항목 | 방법 | 결과 |
|---|----------|------|------|
| 1 | 서버 시작 | `swift run MacHelper` → "WebSocket server started on port 8765" | — |
| 2 | 연결 | `websocat ws://localhost:8765` 로 연결 | — |
| 3 | listWindows | `{"action":"listWindows"}` 전송 → windowList 응답 | — |
| 4 | focus | `{"action":"focus","windowId":123}` 전송 → ack 응답 | — |
| 5 | key | `{"action":"key","key":"c","modifiers":["cmd"]}` 전송 → ack | — |
| 6 | 주기적 push | 연결 유지 → 1.5초마다 windowList 수신 확인 | — |

---

## 6. 변경 이력

| 날짜 | 변경 내용 | 작성자 |
|------|-----------|--------|
| 2026-05-24 | 최초 작성 | |
