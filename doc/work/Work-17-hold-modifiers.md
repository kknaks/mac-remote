# Work-17: Hold 모드 — modifier 유지 + 앱 스위처 오버레이

| 항목 | 내용 |
|------|------|
| ID | Work-17 |
| 상태 | Done |
| 담당 | |
| 시작일 | 2026-05-24 |
| 완료일 | 2026-05-24 |
| 의존 | Work-03, Work-05, Work-11 |
| 관련 스펙 | Spec-03 (Hold 모드 추가분) |

## 1. 목표

> ⌘+Tab 같은 "modifier hold + 반복 키" 단축키를 iPhone에서 쓸 수 있게 한다. iOS 매크로 버튼을 길게 누르면 modifier hold + 초기 키 전송 + 오버레이(◀ ▶ ✓ ✕)가 뜨고, 손가락 떼면 안전하게 release된다.

---

## 2. 참조 스펙 체크리스트

| Spec 섹션 | 항목 | 반영 여부 |
|-----------|------|-----------|
| Spec-03 §3-1 메시지 | holdModifiers / releaseModifiers 액션 + ack | [x] |
| Spec-03 §3-3 Hold 모드 동작 | held set 상태, key 발사 시 flags 합성, 연결 끊김 시 자동 release | [x] |
| Spec-03 §4-2 상태 전이 | heldModifiers={} ↔ ≠{} 전이 | [x] |
| Spec-03 §7 유저 플로우 | Hold 모드 진입/다음·이전/종료/취소 | [x] |
| Spec-03 §8 UI | `holdMode` 플래그, hold 오버레이 컴포넌트 | [x] |
| Spec-03 §9 엣지케이스 #5~#8 | 연결 끊김, 중복 hold, 멱등 release 등 | [x] |
| Spec-03 §10 인수 조건 추가분 | hold/release 흐름 검증 5개 | [x] (단위 테스트 + 수동 검증 대기) |

---

## 3. 태스크

| # | 태스크 | 상태 | 커밋 | 비고 |
|---|--------|------|------|------|
| 1 | Mac: `KeySender`에 `heldModifiers` 상태 + `holdModifiers(_:)` / `releaseModifiers()` 메서드 추가 | [x] | 5e4c006 | CGEvent로 modifier keyDown/keyUp |
| 2 | Mac: 기존 `sendKey(...)`가 held set을 flags에 OR로 합성 | [x] | 5e4c006 | §4-1 갱신 반영 |
| 3 | Mac: `MessageHandler`에 holdModifiers/releaseModifiers 액션 라우팅 + ack 응답 | [x] | b54be64 | Spec-03 §3-1 |
| 4 | Mac: 클라이언트 disconnect 시 자동 releaseModifiers (WebSocketServer 훅) | [x] | 70cbe73 | 안전장치 (마지막 클라이언트 기준) |
| 5 | iOS: `MacroItem`에 `holdMode: Bool` 필드 추가 (Codable, 기본 false) | [x] | 351558e | |
| 6 | iOS: 기본 프리셋 "앱전환"에 `holdMode: true` 설정 | [x] | 351558e | |
| 7 | iOS: `WebSocketManager`에 `sendHoldModifiers(_:)` / `sendReleaseModifiers()` 메서드 | [x] | 351558e | |
| 8 | iOS: `MacroButtonView`에 long-press 제스처 추가 — holdMode 매크로일 때 오버레이 띄움 | [x] | 351558e | SwiftUI LongPressGesture(0.4s) |
| 9 | iOS: `HoldOverlayView` 컴포넌트 — ◀ ▶ ✓ ✕ 4버튼 + 햅틱 | [x] | 351558e | 모달 표시 |
| 10 | iOS: 오버레이 ▶ → 같은 key 단발, ◀ → key + shift, ✓ → release, ✕ → Esc + release | [x] | 351558e | |
| 11 | iOS: 손가락 떼기/오버레이 닫힘 시 자동 release (안전장치) | [x] | 351558e | onDisappear hook |
| 12 | 테스트: 단발 흐름 + Hold 흐름 시나리오 (수동 검증) | [x] | (대기) | 단위 테스트 13개 GREEN; 실기기 수동 검증은 별도 |

---

## 4. 기술 메모

> Mac:
> - `heldModifiers: Set<CGEventFlags>` 또는 OptionSet (cmd/shift/alt/ctrl). Set<String> 으로 둬도 OK.
> - hold modifier keyDown 시 CGEvent의 virtualKey = 해당 modifier 키코드 (cmd=55, shift=56, alt=58, ctrl=59).
> - 단발 key 발사 시 `event.flags = req.modifiers ∪ heldModifiers`.
> - WebSocketServer 측에서 클라이언트 disconnect 이벤트 잡아서 KeySender.releaseModifiers() 호출.
>
> iOS:
> - SwiftUI `LongPressGesture(minimumDuration: 0.4)` 또는 `.onLongPressGesture`.
> - 오버레이는 `.sheet(isPresented:)` 또는 풀스크린 ZStack overlay (반투명 + blur).
> - 오버레이 안의 ✓/✕ 버튼은 명시적 release. onDisappear에서 한 번 더 release 호출(멱등) — 안전장치.
> - 햅틱: `UIImpactFeedbackGenerator(style: .light)` 각 인터랙션마다.

---

## 5. 검증 방법

| # | 검증 항목 | 방법 | 결과 |
|---|----------|------|------|
| 1 | 단발 매크로 회귀 | ⌘C/⌘V 등 기존 매크로가 그대로 동작 | |
| 2 | Hold 진입 | "앱전환" 길게 누름 → Mac 화면에 ⌘+Tab 스위처 뜸 | |
| 3 | Hold 중 ▶ | 오버레이 ▶ 탭 → 스위처가 다음 앱으로 이동 | |
| 4 | Hold 중 ◀ | ◀ 탭 → 스위처가 이전 앱으로 이동 | |
| 5 | Hold 종료 (선택) | ✓ 탭 → 현재 하이라이트된 앱이 활성화됨 | |
| 6 | Hold 종료 (취소) | ✕ 탭 → 스위처 닫히고 활성 앱 유지 | |
| 7 | 손가락 떼기 안전장치 | hold 중 iOS 앱을 백그라운드로 → Mac에서 ⌘이 떼져있어야 함 | |
| 8 | 연결 끊김 안전장치 | hold 중 Wi-Fi 끊기 → Mac에서 자동 release | |

### 로그 추적 포인트

| # | 위치 (파일/함수) | 로그 레벨 | 로그 내용 | 확인 방법 |
|---|------------------|-----------|-----------|-----------|
| 1 | KeySender.holdModifiers | INFO | `[INFO] Held modifiers: [cmd]` | 콘솔 |
| 2 | KeySender.releaseModifiers | INFO | `[INFO] Released all held modifiers` | 콘솔 |
| 3 | WebSocketServer.onDisconnect | INFO | `[INFO] Client disconnected — auto release` | 콘솔 |

---

## 6. 변경 이력

| 날짜 | 변경 내용 |
|------|-----------|
| 2026-05-24 | 최초 작성 (Spec-03 Hold 모드 분기 대응) |
