# Work-02: M2 — 창 활성화

| 항목 | 내용 |
|------|------|
| ID | Work-02 |
| 상태 | Done |
| 담당 | |
| 시작일 | 2026-05-24 |
| 완료일 | 2026-05-24 |
| 의존 | Work-01 |
| 관련 스펙 | Spec-02 |

## 1. 목표

> windowId를 인자로 받아 해당 창을 최전면으로 활성화한다. PID 기반 앱 활성화 후 AXUIElement로 개별 창을 raise한다.

---

## 2. 참조 스펙 체크리스트

| Spec 섹션 | 항목 | 반영 여부 |
|-----------|------|-----------|
| Spec-02 §2 데이터 모델 | FocusRequest (windowId) | [x] |
| Spec-02 §4 상태 전이 | PID 조회 → 앱 활성화 → AXRaise | [x] |
| Spec-02 §5 에러 처리 | WINDOW_NOT_FOUND, PROCESS_DEAD, AX_PERMISSION | [x] |
| Spec-02 §9 엣지 케이스 | 이미 frontmost, 같은 앱 다중 창 | [x] |

---

## 3. 태스크

| # | 태스크 | 상태 | 커밋 | 비고 |
|---|--------|------|------|------|
| 1 | windowId → PID 조회 함수 (Work-01의 창 목록 활용) | [x] | 7b2e137 | lookupPID, lookupWindow, FocusError, FocusAckResponse |
| 2 | NSRunningApplication.activate() 구현 | [x] | c52f4ee | PID 기반, macOS 전용 |
| 3 | AXUIElement 기반 창 목록 조회 + AXRaise 구현 | [x] | 87afbe5 | Accessibility API, 100ms 재시도 |
| 4 | 에러 처리 (창 없음, 프로세스 종료, 권한 없음) | [x] | b367488 | focusWithAck() 통합 함수 |
| 5 | CLI에서 windowId 인자로 테스트 | [x] | 36c4064 | `swift run MacHelper focus <windowId>` |

---

## 4. 기술 메모

> - AXUIElementCreateApplication(pid) → AXUIElementCopyAttributeValue(.windows) → AXUIElementPerformAction(.raise)
> - Accessibility 권한 필수. 없으면 앱 활성화만 가능.

---

## 5. 검증 방법

| # | 검증 항목 | 방법 | 결과 |
|---|----------|------|------|
| 1 | 앱 활성화 | `swift run MacHelper focus {windowId}` → 해당 앱이 최전면 | 수동 검증 (macOS 필요) |
| 2 | 개별 창 raise | 같은 앱 창 2개 열고 뒤쪽 창 windowId로 실행 → 해당 창이 앞으로 | 수동 검증 (macOS 필요) |
| 3 | 없는 windowId | 존재하지 않는 ID 입력 → 에러 메시지 | 수동 검증 (macOS 필요) |

### 로그 추적 포인트

| # | 위치 (파일/함수) | 로그 레벨 | 로그 내용 | 확인 방법 |
|---|-----------------|-----------|-----------|-----------|
| 1 | WindowFocuser.focus() | INFO | "Focusing windowId={id}, pid={pid}" | 콘솔 |
| 2 | WindowFocuser.focus() | ERROR | "Window not found: {id}" | 콘솔 |
| 3 | WindowFocuser.focus() | ERROR | "Process dead: pid={pid}" | 콘솔 |
| 4 | WindowFocuser.axRaise() | WARN | "AXRaise failed, app activated only" | 콘솔 |
| 5 | WindowFocuser.focus() | ERROR | "Accessibility permission denied" | 콘솔 |

---

## 6. 변경 이력

| 날짜 | 변경 내용 | 작성자 |
|------|-----------|--------|
| 2026-05-24 | 최초 작성 | |
| 2026-05-24 | 5개 태스크 구현 완료 (Done) | |
