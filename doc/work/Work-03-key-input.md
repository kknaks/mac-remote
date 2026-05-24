# Work-03: M3 — 키 입력

| 항목 | 내용 |
|------|------|
| ID | Work-03 |
| 상태 | Backlog |
| 담당 | |
| 시작일 | |
| 완료일 | |
| 의존 | Work-01 |
| 관련 스펙 | Spec-03 |

## 1. 목표

> key + modifiers를 인자로 받아 CGEvent로 Mac에 키 입력을 전송한다. 가상 키코드 매핑 테이블을 작성한다.

---

## 2. 참조 스펙 체크리스트

| Spec 섹션 | 항목 | 반영 여부 |
|-----------|------|-----------|
| Spec-03 §2 데이터 모델 | KeyCommand (key, modifiers), VirtualKeyMap | [ ] |
| Spec-03 §4 상태 전이 | 키코드 조회 → 이벤트 생성 → keyDown → keyUp | [ ] |
| Spec-03 §5 에러 처리 | UNKNOWN_KEY, AX_PERMISSION, EVENT_CREATE_FAIL | [ ] |

---

## 3. 태스크

| # | 태스크 | 상태 | 커밋 | 비고 |
|---|--------|------|------|------|
| 1 | VirtualKeyMap 정적 매핑 테이블 작성 | [ ] | | a~z, 0~9, 특수키 |
| 2 | Modifier → CGEventFlags 매핑 | [ ] | | cmd/shift/alt/ctrl |
| 3 | CGEvent keyDown/keyUp 전송 함수 | [ ] | | event.post(tap:) |
| 4 | 에러 처리 (알 수 없는 키, 권한 없음) | [ ] | | |
| 5 | CLI에서 key+modifier 인자로 테스트 | [ ] | | |

---

## 4. 기술 메모

> - CGEvent(keyboardEventSource:nil, virtualKey:keyCode, keyDown:true/false)
> - event.flags = [.maskCommand, .maskShift] 등으로 modifier 설정
> - event.post(tap: .cghidEventTap)
> - Accessibility 권한 필요

---

## 5. 검증 방법

| # | 검증 항목 | 방법 | 결과 |
|---|----------|------|------|
| 1 | ⌘C 전송 | 텍스트 선택 후 `swift run MacHelper key c cmd` → 클립보드에 복사됨 | — |
| 2 | ⌘⇧4 전송 | `swift run MacHelper key 4 cmd shift` → 스크린샷 모드 진입 | — |
| 3 | 알 수 없는 키 | `swift run MacHelper key xyz` → 에러 메시지 | — |

---

## 6. 변경 이력

| 날짜 | 변경 내용 | 작성자 |
|------|-----------|--------|
| 2026-05-24 | 최초 작성 | |
