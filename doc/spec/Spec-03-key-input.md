# Spec-03: 키 입력 (매크로)

| 항목 | 내용 |
|------|------|
| ID | Spec-03 |
| 상태 | Approved |
| 작성일 | 2026-05-24 |
| 최종 수정 | 2026-05-24 |
| 의존 | — |
| 관련 워크 | Work-03 |

## 1. 개요

> iOS 앱에서 키+modifier 조합을 전송하면 Mac 헬퍼가 CGEvent로 해당 키 입력을 시스템에 전송한다. 사용자 정의 매크로 버튼의 백엔드.

### 범위

- 포함: CGEvent 기반 키 전송, 가상 키코드 매핑, modifier 조합
- 제외: 매크로 UI/저장(iOS 영역), 텍스트 입력(문자열 타이핑)

---

## 2. 데이터 모델

```
Entity: KeyCommand
├── key: String          — 키 이름 ("c", "v", "z", "tab", "4" 등)
└── modifiers: [String]  — modifier 목록 ["cmd", "shift", "alt", "ctrl"]

Entity: VirtualKeyMap (정적 매핑 테이블)
├── "a": 0, "s": 1, "d": 2, "f": 3
├── "c": 8, "v": 9, "z": 6
├── "tab": 48, "space": 49, "return": 36, "escape": 53
├── "0"~"9": 29,18,19,20,21,23,22,26,28,25
└── ... (전체 키코드 테이블)
```

### 제약 조건

| 필드 | 제약 | 비고 |
|------|------|------|
| key | VirtualKeyMap에 존재해야 함 | 없으면 에러 |
| modifiers | cmd/shift/alt/ctrl만 허용 | 빈 배열 허용 (modifier 없는 키) |

---

## 3. 계약 (Contract)

### 3-1. 메시지 / API

| 방향 | 이름 | 설명 |
|------|------|------|
| iOS → Mac | key | 키 입력 전송 |
| Mac → iOS | ack (key) | 키 입력 결과 응답 |

#### 요청 예시

```json
{"action":"key","key":"c","modifiers":["cmd"]}
```

```json
{"action":"key","key":"4","modifiers":["cmd","shift"]}
```

#### 응답 예시

```json
{"type":"ack","action":"key","ok":true}
```

```json
{"type":"ack","action":"key","ok":false,"error":"unknown key: xyz"}
```

### 3-2. 공유 상수 / Enum

```swift
enum Modifier: String {
    case cmd   = "cmd"
    case shift = "shift"
    case alt   = "alt"
    case ctrl  = "ctrl"
}

// Modifier → CGEventFlags 매핑
// cmd   → .maskCommand
// shift → .maskShift
// alt   → .maskAlternate
// ctrl  → .maskControl
```

---

## 4. 상태 전이 (State Machine)

```
[대기] ──(key 요청)──► [키코드 조회] ──(found)──► [이벤트 생성] ──► [keyDown 전송] ──► [keyUp 전송] ──► [ack:true]
                            │
                         (not found)
                            ▼
                       [ack:false]
```

| 현재 상태 | 이벤트 | 다음 상태 | 액션 | 비고 |
|-----------|--------|-----------|------|------|
| 대기 | key 수신 | 키코드 조회 | VirtualKeyMap에서 조회 | |
| 키코드 조회 | found | 이벤트 생성 | CGEvent 생성 + modifier flags 설정 | |
| 키코드 조회 | not found | ack:false | 에러 응답 | |
| 이벤트 생성 | — | keyDown 전송 | event.post(tap: .cghidEventTap) | |
| keyDown 전송 | — | keyUp 전송 | keyUp 이벤트 post | keyDown/keyUp 쌍 필수 |
| keyUp 전송 | — | ack:true | 성공 응답 | |

---

## 5. 에러 처리

| 에러 코드/유형 | 발생 조건 | 처리 주체 | 복구 전략 | 사용자 메시지 |
|---------------|-----------|-----------|-----------|--------------|
| UNKNOWN_KEY | key가 VirtualKeyMap에 없음 | Mac 헬퍼 | ack:false | "알 수 없는 키: {key}" |
| INVALID_MODIFIER | modifier가 cmd/shift/alt/ctrl 아님 | Mac 헬퍼 | 해당 modifier 무시, 나머지로 진행 | — |
| AX_PERMISSION | Accessibility 권한 없음 | Mac 헬퍼 | ack:false | "손쉬운 사용 권한이 필요합니다" |
| EVENT_CREATE_FAIL | CGEvent 생성 실패 | Mac 헬퍼 | ack:false | "키 입력을 생성할 수 없습니다" |

### 재시도 정책

| 에러 유형 | 재시도 | 최대 횟수 | 간격 | 비고 |
|-----------|--------|-----------|------|------|
| 모든 유형 | N | — | — | 키 입력은 재시도하면 중복 입력 위험 |

---

## 6. 유효성 검증

| 검증 항목 | 규칙 | 검증 위치 | 실패 시 동작 |
|-----------|------|-----------|-------------|
| key | VirtualKeyMap에 존재 | Back (Mac) | UNKNOWN_KEY 에러 |
| modifiers | 각 항목이 cmd/shift/alt/ctrl | Back (Mac) | 잘못된 modifier 무시 |
| modifiers | 배열 (빈 배열 허용) | Front (iOS) | 빈 배열로 전송 |

---

## 7. 유저 플로우 (User Flow)

### 메인 플로우 (Happy Path)

```
1. iOS 앱에서 "매크로" 탭 진입
   ▼
2. 사용자가 매크로 버튼 탭 (예: ⌘C)
   ▼
3. 앱이 {"action":"key","key":"c","modifiers":["cmd"]} 전송
   ▼
4. Mac 헬퍼가 CGEvent로 ⌘C keyDown → keyUp 전송
   ▼
5. Mac에서 복사 동작 실행
   ▼
6. ack:true → iOS에서 햅틱 피드백
```

### 분기 플로우

| 분기 지점 | 조건 | 흐름 |
|-----------|------|------|
| Step 2 | 사용자 정의 매크로 | 동일 흐름, key/modifiers가 사용자 설정값 |
| Step 4 | modifier 없는 단일 키 | flags 없이 CGEvent 전송 |

### 실패 플로우

| 실패 지점 | 원인 | 사용자에게 보이는 것 | 복구 경로 |
|-----------|------|---------------------|-----------|
| Step 4 | Accessibility 권한 없음 | "권한 필요" 알림 | 설정 화면으로 안내 |
| Step 3 | WebSocket 미연결 | 연결 표시등 빨간색 | 재연결 후 재시도 |

---

## 8. UI/UX 요구사항

### 화면 / 컴포넌트

| 화면 | 설명 | 목업 링크 |
|------|------|-----------|
| 매크로 탭 | 2열 그리드 버튼 | macro_keyboard_mockup.html |

### 사용자 인터랙션

| 동작 | 트리거 | 기대 결과 | 피드백 |
|------|--------|-----------|--------|
| 매크로 실행 | 버튼 탭 | Mac에서 해당 키 조합 실행 | 햅틱 (성공 시) |
| 매크로 추가 | "매크로 추가" 버튼 | 키 + modifier 선택 화면 | — |

---

## 9. 엣지 케이스

| # | 시나리오 | 기대 동작 |
|---|----------|-----------|
| 1 | 매우 빠른 연속 탭 | 각각 독립된 key 이벤트로 전송, 순서 보장 |
| 2 | modifier만 있고 key가 빈 문자열 | UNKNOWN_KEY 에러 |
| 3 | 같은 매크로 동시 2회 탭 | 2회 모두 전송 |
| 4 | Mac이 잠금 화면일 때 | CGEvent 전송되나 효과 없음, ack:true |

---

## 10. 인수 조건 (Acceptance Criteria)

- [ ] key + modifiers 조합으로 CGEvent가 정확히 전송된다
- [ ] keyDown과 keyUp이 쌍으로 전송된다
- [ ] 기본 프리셋(⌘C/⌘V/⌘Z/⌘⇧Z/⌘⇧4/⌃⌘Q/⌘⇥)이 동작한다
- [ ] 알 수 없는 key에 대해 ack:false가 반환된다
- [ ] Accessibility 권한 없이 실행 시 ack:false + 권한 안내
- [ ] JSON 요청/응답이 계약 형식을 따른다

---

## 11. 변경 이력

| 날짜 | 변경 내용 | 작성자 |
|------|-----------|--------|
| 2026-05-24 | 최초 작성 | |
