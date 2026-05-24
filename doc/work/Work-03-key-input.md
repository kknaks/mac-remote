# Work-03: M3 — 키 입력

| 항목 | 내용 |
|------|------|
| ID | Work-03 |
| 상태 | Done |
| 담당 | |
| 시작일 | 2026-05-24 |
| 완료일 | 2026-05-24 |
| 의존 | Work-01 |
| 관련 스펙 | Spec-03 |

## 1. 목표

> key + modifiers를 인자로 받아 CGEvent로 Mac에 키 입력을 전송한다. 가상 키코드 매핑 테이블을 작성한다.

---

## 2. 참조 스펙 체크리스트

| Spec 섹션 | 항목 | 반영 여부 |
|-----------|------|-----------|
| Spec-03 §2 데이터 모델 | KeyCommand (key, modifiers), VirtualKeyMap | [x] |
| Spec-03 §4 상태 전이 | 키코드 조회 → 이벤트 생성 → keyDown → keyUp | [x] |
| Spec-03 §5 에러 처리 | UNKNOWN_KEY, AX_PERMISSION, EVENT_CREATE_FAIL | [x] |

---

## 3. 태스크

| # | 태스크 | 상태 | 커밋 | 비고 |
|---|--------|------|------|------|
| 1 | VirtualKeyMap 정적 매핑 테이블 작성 | [x] | b463f9e | a~z, 0~9, 특수키, F1~F12, 화살표 |
| 2 | Modifier → CGEventFlags 매핑 | [x] | b463f9e | cmd/shift/alt/ctrl, #if canImport(CoreGraphics) |
| 3 | CGEvent keyDown/keyUp 전송 함수 | [x] | b463f9e | KeySender.send(), #if canImport(CoreGraphics) |
| 4 | 에러 처리 (알 수 없는 키, 권한 없음) | [x] | b463f9e | KeySendError enum, INVALID_MODIFIER 무시 |
| 5 | CLI에서 key+modifier 인자로 테스트 | [x] | c3c6e41 | main.swift key 서브커맨드 + formatKeyAckJSON |

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
| 1 | ⌘C 전송 | 텍스트 선택 후 `swift run MacHelper key c cmd` → 클립보드에 복사됨 | 수동 검증 (macOS 필요) |
| 2 | ⌘⇧4 전송 | `swift run MacHelper key 4 cmd shift` → 스크린샷 모드 진입 | 수동 검증 (macOS 필요) |
| 3 | 알 수 없는 키 | `swift run MacHelper key xyz` → 에러 메시지 | 수동 검증 (macOS 필요) |

### 로그 추적 포인트

| # | 위치 (파일/함수) | 로그 레벨 | 로그 내용 | 확인 방법 |
|---|-----------------|-----------|-----------|-----------|
| 1 | KeySender.send() | INFO | "Sending key={key} modifiers={mods}" | 콘솔 |
| 2 | KeySender.send() | ERROR | "Unknown key: {key}" | 콘솔 |
| 3 | KeySender.send() | ERROR | "CGEvent creation failed" | 콘솔 |
| 4 | KeySender.send() | ERROR | "Accessibility permission denied" | 콘솔 |

---

## 6. 변경 이력

| 날짜 | 변경 내용 | 작성자 |
|------|-----------|--------|
| 2026-05-24 | 최초 작성 | |
| 2026-05-24 | TDD 구현 완료 (5/5 태스크), 커밋 b463f9e, c3c6e41 | |
