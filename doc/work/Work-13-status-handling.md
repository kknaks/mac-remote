# Work-13: I6 — 상태 처리

| 항목 | 내용 |
|------|------|
| ID | Work-13 |
| 상태 | Done |
| 담당 | |
| 시작일 | 2026-05-24 |
| 완료일 | 2026-05-24 |
| 의존 | Work-09 |
| 관련 스펙 | Spec-05 |

## 1. 목표

> 미연결/연결 중/연결됨/재연결 중 상태를 헤더 연결 표시등에 반영하고, 각 상태에 맞는 UI를 표시한다.

---

## 2. 참조 스펙 체크리스트

| Spec 섹션 | 항목 | 반영 여부 |
|-----------|------|-----------|
| Spec-05 §4 상태 전이 | 연결 상태 머신 (iOS 클라이언트) | [x] |
| Spec-05 §8 UI/UX | 연결 표시등 (초록/노랑/빨강) | [x] |

---

## 3. 태스크

| # | 태스크 | 상태 | 커밋 | 비고 |
|---|--------|------|------|------|
| 1 | ConnectionState enum 정의 | [x] | 13a3f66 | indicatorColor, displayText, isDisconnected, isAttempting 속성 추가 |
| 2 | 헤더 연결 표시등 컴포넌트 | [x] | 094f9e9 | ConnectionStatusHeader 배너 + StatusIndicator 맥동 애니메이션 |
| 3 | 각 탭에 연결 상태 헤더 적용 | [x] | c6062b0 | WindowListView, MacroView, SettingsView에 ConnectionStatusHeader 적용 |
| 4 | 미연결 시 오버레이 UI | [x] | 53a597e | DisconnectedOverlay 컴포넌트 + disconnectedOverlay() modifier |
| 5 | 재연결 중 표시 | [x] | 586c798 | ReconnectingOverlay + 앱 라이프사이클(scenePhase) 연결 관리 |

---

## 4. 기술 메모

> - WebSocketManager의 @Published connectionState를 각 뷰에서 관찰
> - .overlay()로 미연결 상태 표시

---

## 5. 검증 방법

| # | 검증 항목 | 방법 | 결과 |
|---|----------|------|------|
| 1 | 연결됨 | 헬퍼 실행 + 연결 → 초록 표시등 | 수동 검증 (Xcode 필요) |
| 2 | 끊김 | 헬퍼 종료 → 빨간 표시등 + 재연결 중 노란색 | 수동 검증 (Xcode 필요) |
| 3 | 미연결 | 헬퍼 없이 앱 실행 → 오버레이 표시 | 수동 검증 (Xcode 필요) |

---

## 6. 변경 이력

| 날짜 | 변경 내용 | 작성자 |
|------|-----------|--------|
| 2026-05-24 | 최초 작성 | |
| 2026-05-24 | 전체 태스크 완료 (Done) | |
