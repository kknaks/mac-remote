# Spec-02: 창 활성화

| 항목 | 내용 |
|------|------|
| ID | Spec-02 |
| 상태 | Approved |
| 작성일 | 2026-05-24 |
| 최종 수정 | 2026-05-24 |
| 의존 | Spec-01 |
| 관련 워크 | Work-02 |

## 1. 개요

> 사용자가 iOS 앱에서 특정 창을 탭하면 Mac에서 해당 창을 최전면으로 활성화한다. PID 기반 앱 활성화를 1차로, AXUIElement 기반 개별 창 활성화를 2차로 구현한다.

### 범위

- 포함: PID로 앱 활성화, AXUIElement로 특정 창 raise, 결과 응답
- 제외: 창 목록 수집(Spec-01), 창 이동/리사이즈

---

## 2. 데이터 모델

```
Entity: FocusRequest
├── windowId: Int     — 대상 창의 kCGWindowNumber
└── (pid는 Spec-01의 WindowInfo에서 조회)
```

### 제약 조건

| 필드 | 제약 | 비고 |
|------|------|------|
| windowId | Spec-01 windowList에 존재하는 id | 존재하지 않으면 에러 |

---

## 3. 계약 (Contract)

### 3-1. 메시지 / API

| 방향 | 이름 | 설명 |
|------|------|------|
| iOS → Mac | focus | 특정 창 활성화 요청 |
| Mac → iOS | ack (focus) | 활성화 결과 응답 |

#### 요청 예시

```json
{"action":"focus","windowId":123}
```

#### 응답 예시

```json
{"type":"ack","action":"focus","ok":true}
```

```json
{"type":"ack","action":"focus","ok":false,"error":"window not found"}
```

### 3-2. 공유 상수 / Enum

해당 없음

---

## 4. 상태 전이 (State Machine)

```
[대기] ──(focus 요청)──► [PID 조회] ──(found)──► [앱 활성화] ──(성공)──► [AX 창 Raise] ──► [ack 전송]
                             │                       │                       │
                          (not found)             (실패)                  (AX 실패)
                             ▼                       ▼                       ▼
                        [ack:false]             [ack:false]           [ack:true, 앱만 활성화]
```

| 현재 상태 | 이벤트 | 다음 상태 | 액션 | 비고 |
|-----------|--------|-----------|------|------|
| 대기 | focus 수신 | PID 조회 | windowId로 WindowInfo 검색 → PID 획득 | |
| PID 조회 | found | 앱 활성화 | NSRunningApplication(pid).activate() | |
| PID 조회 | not found | ack:false | 에러 응답 | 창이 닫혔을 수 있음 |
| 앱 활성화 | 성공 | AX 창 Raise | AXUIElement로 해당 창에 AXRaise | 같은 앱 다중 창 대응 |
| 앱 활성화 | 실패 | ack:false | 에러 응답 | 프로세스 종료 등 |
| AX 창 Raise | 성공/실패 | ack 전송 | AX 실패해도 앱은 활성화됨 → ok:true | graceful degradation |

---

## 5. 에러 처리

| 에러 코드/유형 | 발생 조건 | 처리 주체 | 복구 전략 | 사용자 메시지 |
|---------------|-----------|-----------|-----------|--------------|
| WINDOW_NOT_FOUND | windowId가 현재 목록에 없음 | Mac 헬퍼 | ack:false + 창 목록 재전송 | "창을 찾을 수 없습니다" |
| PROCESS_DEAD | PID에 해당하는 프로세스 없음 | Mac 헬퍼 | ack:false + 창 목록 재전송 | "앱이 종료되었습니다" |
| AX_PERMISSION | Accessibility 권한 없음 | Mac 헬퍼 | PID 활성화만 수행, 경고 로그 | "손쉬운 사용 권한이 필요합니다" |
| AX_RAISE_FAIL | AXRaise 실패 | Mac 헬퍼 | 앱은 활성화됨, ok:true 반환 | — (무시) |

### 재시도 정책

| 에러 유형 | 재시도 | 최대 횟수 | 간격 | 비고 |
|-----------|--------|-----------|------|------|
| WINDOW_NOT_FOUND | N | — | — | 창 닫힘, 재시도 무의미 |
| AX_RAISE_FAIL | Y | 1 | 100ms | 타이밍 이슈 가능 |

---

## 6. 유효성 검증

| 검증 항목 | 규칙 | 검증 위치 | 실패 시 동작 |
|-----------|------|-----------|-------------|
| windowId | 양의 정수 | Back (Mac) | ack:false |
| windowId 존재 | 현재 창 목록에 존재 | Back (Mac) | WINDOW_NOT_FOUND |
| Accessibility 권한 | 허용 상태 | Back (Mac) | PID만으로 활성화 시도 |

---

## 7. 유저 플로우 (User Flow)

### 메인 플로우 (Happy Path)

```
1. iOS 앱에서 창 목록 중 원하는 창 카드 탭
   ▼
2. 앱이 {"action":"focus","windowId":123} 전송
   ▼
3. Mac 헬퍼가 PID 조회 → 앱 활성화 → AXRaise
   ▼
4. Mac에서 해당 창이 최전면으로 올라옴
   ▼
5. ack:true 응답 → iOS에서 해당 카드에 frontmost 표시
```

### 분기 플로우

| 분기 지점 | 조건 | 흐름 |
|-----------|------|------|
| Step 3 | 같은 앱 창 1개뿐 | AXRaise 생략, 앱 활성화만으로 충분 |
| Step 3 | Accessibility 권한 없음 | 앱 활성화만 수행, 같은 앱 다중 창 구분 불가 |

### 실패 플로우

| 실패 지점 | 원인 | 사용자에게 보이는 것 | 복구 경로 |
|-----------|------|---------------------|-----------|
| Step 3 | 창이 이미 닫힘 | "창을 찾을 수 없습니다" 토스트 | 창 목록 자동 갱신 |
| Step 3 | 앱이 종료됨 | "앱이 종료되었습니다" 토스트 | 창 목록 자동 갱신 |

---

## 8. UI/UX 요구사항

### 화면 / 컴포넌트

| 화면 | 설명 | 목업 링크 |
|------|------|-----------|
| 창 목록 탭 | 카드 탭으로 focus 발동 | macro_keyboard_mockup.html |

### 사용자 인터랙션

| 동작 | 트리거 | 기대 결과 | 피드백 |
|------|--------|-----------|--------|
| 창 전환 | 카드 탭 | Mac에서 해당 창 최전면 | 햅틱 + frontmost 표시 갱신 |

---

## 9. 엣지 케이스

| # | 시나리오 | 기대 동작 |
|---|----------|-----------|
| 1 | 탭한 창이 이미 frontmost | 아무 변화 없음, ack:true |
| 2 | 탭 직후 창이 닫힘 (race condition) | ack:false, 목록 자동 갱신 |
| 3 | 같은 앱 창 5개 | AXRaise로 정확한 창 활성화 |
| 4 | Accessibility 권한 없음 + 같은 앱 다중 창 | 앱만 활성화, 특정 창 선택 불가 |
| 5 | 전체 화면(full screen) 앱 | 해당 Space로 전환 후 활성화 |

---

## 10. 인수 조건 (Acceptance Criteria)

- [ ] windowId로 해당 앱이 최전면으로 활성화된다
- [ ] 같은 앱의 여러 창 중 정확한 창이 AXRaise로 올라온다
- [ ] 존재하지 않는 windowId에 대해 ack:false가 반환된다
- [ ] Accessibility 권한 없이도 앱 수준 활성화는 동작한다
- [ ] 활성화 후 다음 windowList push에서 frontmost가 갱신된다

---

## 11. 변경 이력

| 날짜 | 변경 내용 | 작성자 |
|------|-----------|--------|
| 2026-05-24 | 최초 작성 | |
