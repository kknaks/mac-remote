# Spec-01: 창 목록 수집

| 항목 | 내용 |
|------|------|
| ID | Spec-01 |
| 상태 | Approved |
| 작성일 | 2026-05-24 |
| 최종 수정 | 2026-05-24 |
| 의존 | — |
| 관련 워크 | Work-01 |

## 1. 개요

> Mac에서 현재 화면에 표시된 일반 창 목록을 수집한다. iOS 앱이 어떤 창이 열려 있는지 표시하고 전환할 수 있게 하는 기반 데이터.

### 범위

- 포함: CGWindowListCopyWindowInfo 호출, 필터링, WindowInfo 모델 정의
- 제외: 창 활성화(Spec-02), 화면 캡처/썸네일, 앱 아이콘(Spec-04)

---

## 2. 데이터 모델

```
Entity: WindowInfo
├── id: Int           — kCGWindowNumber, 창 고유 ID
├── app: String       — kCGWindowOwnerName, 앱 이름
├── title: String     — kCGWindowName, 창 제목 (빈 문자열 가능)
├── pid: Int          — kCGWindowOwnerPID, 프로세스 PID
└── frontmost: Bool   — 현재 최전면 창 여부
```

### 제약 조건

| 필드 | 제약 | 비고 |
|------|------|------|
| id | 양의 정수, 시스템이 부여 | 세션 내 고유 |
| app | 빈 문자열 제외 | 빈 OwnerName은 필터링 |
| title | 빈 문자열 허용 | Screen Recording 권한 없으면 항상 빈 문자열 |
| pid | 양의 정수 | 실행 중 프로세스에 한함 |
| frontmost | 목록 중 최대 1개만 true | NSWorkspace로 판별 |

---

## 3. 계약 (Contract)

### 3-1. 메시지 / API

| 방향 | 이름 | 설명 |
|------|------|------|
| iOS → Mac | listWindows | 창 목록 요청 |
| Mac → iOS | windowList | 창 목록 응답 (주기적 push에도 사용) |

#### 요청 예시

```json
{"action":"listWindows"}
```

#### 응답 예시

```json
{
  "type":"windowList",
  "windows":[
    {"id":123,"app":"Arc","title":"디자인 레퍼런스 — 12개 탭","frontmost":true},
    {"id":124,"app":"Xcode","title":"MacroHelper — AppDelegate.swift","frontmost":false},
    {"id":125,"app":"Terminal","title":"bash","frontmost":false}
  ]
}
```

### 3-2. 공유 상수 / Enum

```swift
// 필터링에서 제외할 시스템 프로세스
let excludedProcesses = ["Window Server", "Dock", "SystemUIServer", "Control Center", "Notification Center"]
```

---

## 4. 상태 전이 (State Machine)

```
[대기] ──(listWindows 요청)──► [수집 중] ──(성공)──► [응답 전송] ──► [대기]
                                    │
                                 (실패)
                                    ▼
                              [에러 응답] ──► [대기]
```

| 현재 상태 | 이벤트 | 다음 상태 | 액션 | 비고 |
|-----------|--------|-----------|------|------|
| 대기 | listWindows 수신 | 수집 중 | CGWindowListCopyWindowInfo 호출 | |
| 수집 중 | 성공 | 응답 전송 | 필터링 → JSON 생성 → 전송 | |
| 수집 중 | 실패 | 에러 응답 | 에러 메시지 전송 | CGWindowList null 반환 |
| 대기 | 타이머(1.5초) | 수집 중 | 주기적 push | 폴링 방식 |

---

## 5. 에러 처리

| 에러 코드/유형 | 발생 조건 | 처리 주체 | 복구 전략 | 사용자 메시지 |
|---------------|-----------|-----------|-----------|--------------|
| EMPTY_TITLE | Screen Recording 권한 없음 | Mac 헬퍼 | 경고 로그 출력, 빈 제목으로 계속 동작 | "화면 기록 권한을 허용하면 창 제목이 표시됩니다" |
| NULL_LIST | CGWindowListCopyWindowInfo null 반환 | Mac 헬퍼 | 빈 배열 반환 | "창 목록을 가져올 수 없습니다" |
| NO_WINDOWS | 일반 창이 0개 | Mac 헬퍼 | 빈 배열 정상 반환 | iOS에서 빈 상태 UI 표시 |

### 재시도 정책

| 에러 유형 | 재시도 | 최대 횟수 | 간격 | 비고 |
|-----------|--------|-----------|------|------|
| NULL_LIST | Y | 3 | 500ms | 일시적 실패 가능성 |
| EMPTY_TITLE | N | — | — | 권한 문제, 재시도 무의미 |

---

## 6. 유효성 검증

| 검증 항목 | 규칙 | 검증 위치 | 실패 시 동작 |
|-----------|------|-----------|-------------|
| kCGWindowLayer | == 0 (일반 창만) | Back (Mac) | 해당 창 제외 |
| kCGWindowOwnerName | 빈 문자열 아닐 것 | Back (Mac) | 해당 창 제외 |
| 시스템 프로세스 | excludedProcesses에 포함되지 않을 것 | Back (Mac) | 해당 창 제외 |
| windows 배열 | JSON 배열일 것 | Front (iOS) | 파싱 실패 시 기존 목록 유지 |

---

## 7. 유저 플로우 (User Flow)

### 메인 플로우 (Happy Path)

```
1. iOS 앱에서 "창 목록" 탭 진입
   ▼
2. 앱이 Mac 헬퍼에 {"action":"listWindows"} 전송
   ▼
3. 헬퍼가 CGWindowListCopyWindowInfo 호출 → 필터링 → windowList 응답
   ▼
4. iOS 앱이 리스트 렌더링, frontmost 창에 청록 테두리
   ▼
5. 이후 헬퍼가 1.5초마다 windowList push → 목록 자동 갱신
```

### 분기 플로우

| 분기 지점 | 조건 | 흐름 |
|-----------|------|------|
| Step 3 | Screen Recording 권한 없음 | 창 제목이 빈 문자열로 옴 → iOS에서 앱 이름만 표시 |
| Step 5 | 새 창 열림/닫힘 | 다음 push 주기에 반영 |

### 실패 플로우

| 실패 지점 | 원인 | 사용자에게 보이는 것 | 복구 경로 |
|-----------|------|---------------------|-----------|
| Step 2 | WebSocket 미연결 | 연결 표시등 빨간색 | 재연결 시도 후 재요청 |
| Step 3 | CGWindowList null | 빈 목록 | 500ms 후 자동 재시도 (최대 3회) |

---

## 8. UI/UX 요구사항

### 화면 / 컴포넌트

| 화면 | 설명 | 목업 링크 |
|------|------|-----------|
| 창 목록 탭 | 세로 리스트, 카드형 아이템 | macro_keyboard_mockup.html |

### 사용자 인터랙션

| 동작 | 트리거 | 기대 결과 | 피드백 |
|------|--------|-----------|--------|
| 창 목록 보기 | 탭 진입 | 현재 열린 창 리스트 표시 | — |
| 당겨서 새로고침 | Pull-to-refresh | listWindows 재요청 | 리스트 갱신 |
| 창 탭 | 카드 탭 | focus 명령 전송 (Spec-02) | 햅틱 피드백 |

---

## 9. 엣지 케이스

| # | 시나리오 | 기대 동작 |
|---|----------|-----------|
| 1 | 열린 창이 0개 | 빈 상태 UI 표시 ("열린 창이 없습니다") |
| 2 | 같은 앱이 창 여러 개 | 각각 별도 항목, 창 제목으로 구분 |
| 3 | Screen Recording 권한 없음 | 창 제목 빈 문자열, 앱 이름만 표시 |
| 4 | macOS 15.6 storeuid 등 백그라운드 프로세스 혼입 | excludedProcesses + layer 필터로 제거 |
| 5 | 창 제목이 매우 긴 경우 | iOS에서 말줄임 처리 |
| 6 | 앱이 창을 빠르게 열고 닫을 때 | 다음 push 주기에 반영, 일시적 불일치 허용 |

---

## 10. 인수 조건 (Acceptance Criteria)

- [ ] CGWindowListCopyWindowInfo 호출로 현재 화면의 창 목록을 가져올 수 있다
- [ ] layer == 0인 일반 창만 반환된다
- [ ] 시스템 프로세스(Window Server, Dock 등)가 제외된다
- [ ] 빈 OwnerName 창이 제외된다
- [ ] 각 창의 id, app, title, pid, frontmost 필드가 포함된다
- [ ] frontmost 표시가 정확하다
- [ ] Screen Recording 권한 없을 때 title이 빈 문자열이고 에러 없이 동작한다
- [ ] JSON 응답이 계약(§3) 형식을 따른다

---

## 11. 변경 이력

| 날짜 | 변경 내용 | 작성자 |
|------|-----------|--------|
| 2026-05-24 | 최초 작성 | |
