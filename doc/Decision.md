# Decision

## Project Overview

| 항목 | 내용 |
|------|------|
| 프로젝트명 | 매크로 키보드 (mac-remote) |
| 한줄 요약 | iPhone을 리모컨으로 써서 Mac의 창 전환 + 단축키 매크로 전송 |
| 시작일 | 2026-05-24 |
| 상태 | Active |

### Why — 이 프로젝트를 하는 이유

> Mac에서 여러 창을 전환할 때 키보드/트랙패드 조작이 번거롭다.
> iPhone을 물리 리모컨처럼 써서 한 탭에 원하는 창으로 이동하고,
> 자주 쓰는 단축키를 버튼 하나로 실행하고 싶다.

### 핵심 제약

- [ ] LAN 전용 — 인터넷 경유 원격 접속 불가, 같은 Wi-Fi 필수
- [ ] 화면 캡처/썸네일 금지 — 앱 아이콘만 표시, ScreenCaptureKit 미사용
- [ ] iOS 앱 단독 동작 불가 — 실제 창 제어/키 입력은 100% Mac 헬퍼가 담당
- [ ] DB 미사용 — 영속 저장은 UserDefaults 수준으로 충분
- [ ] 멀티 Mac 동시 연결 불가 — 1:1 연결만 지원

### 기술 선택 요약

| 영역 | 선택 | 근거 |
|------|------|------|
| Mac 헬퍼 | Swift + AppKit, 메뉴바 앱 | 네이티브 API 필수 (CGEvent, AXUIElement, CGWindowList) |
| iOS 앱 | Swift + SwiftUI | 선언형 UI, URLSessionWebSocketTask 내장으로 외부 의존성 불필요 |
| 통신 | WebSocket (JSON) | 실시간 양방향, 서버→클라이언트 push 자연스러움 |
| Mac WS 라이브러리 | Swifter | 경량, 순수 Swift, 외부 의존성 최소화 원칙에 부합 |
| 창 목록 수집 | CGWindowListCopyWindowInfo | deprecated 아님, macOS 공식 API |
| 앱 아이콘 | NSWorkspace / NSRunningApplication | 화면 캡처 아닌 설치된 앱 아이콘 파일 읽기 |
| 키 입력 | CGEvent | 가상 키코드 기반 keyDown/keyUp 전송 |
| 창 활성화 | NSRunningApplication + AXUIElement | PID 기반 활성화 + AXRaise로 특정 창 선택 |
| 페어링 | QR 코드 (IP:포트) | 카메라 스캔으로 간편 연결, 수동 IP 입력 fallback |

---

## Decision Log

의사결정을 날짜순으로 누적한다. 번호는 순차 부여.

### ADR-001: WebSocket을 통신 프로토콜로 선택

| 항목 | 내용 |
|------|------|
| 날짜 | 2026-05-24 |
| 상태 | Accepted |
| 맥락 | iOS ↔ Mac 간 실시간 양방향 통신이 필요하다. 창 목록 갱신을 서버에서 push 해야 한다. |
| 결정 | WebSocket (JSON payload)을 사용한다. Mac 헬퍼가 서버, iOS 앱이 클라이언트. |
| 근거 | HTTP 폴링 대비 지연이 낮고, 서버→클라이언트 push가 자연스럽다. Bonjour/MultipeerConnectivity도 고려했으나 WebSocket이 디버깅이 쉽고 프로토콜이 단순하다. |
| 영향 | Mac 헬퍼가 WebSocket 서버를 내장해야 한다. iOS는 URLSessionWebSocketTask로 추가 라이브러리 없이 구현 가능. |

### ADR-002: CGWindowListCopyWindowInfo를 창 목록 수집에 사용

| 항목 | 내용 |
|------|------|
| 날짜 | 2026-05-24 |
| 상태 | Accepted |
| 맥락 | Mac에서 현재 열린 창 목록을 수집해야 한다. |
| 결정 | CGWindowListCopyWindowInfo를 사용한다. |
| 근거 | 이 API는 deprecated가 아니다. deprecated된 것은 화면 캡처용 CGWindowListCreateImage이며 이 프로젝트는 화면 캡처를 하지 않으므로 무관하다. ScreenCaptureKit은 불필요한 권한과 복잡도를 추가한다. |
| 영향 | 화면 기록(Screen Recording) 권한이 있어야 창 제목(kCGWindowName)을 받을 수 있다. 권한 없으면 빈 문자열로 조용히 실패한다. |

### ADR-003: 화면 캡처 대신 앱 아이콘만 표시

| 항목 | 내용 |
|------|------|
| 날짜 | 2026-05-24 |
| 상태 | Accepted |
| 맥락 | iOS 앱에서 창을 식별할 시각적 요소가 필요하다. |
| 결정 | 창 썸네일/스크린샷 대신 앱 아이콘만 표시한다. |
| 근거 | 화면 캡처는 ScreenCaptureKit 권한이 추가로 필요하고, 지속적 캡처는 성능 부담이 크다. 앱 아이콘은 NSWorkspace로 권한 없이 읽을 수 있고, 앱당 1개로 캐싱 효율이 높다. |
| 영향 | 같은 앱의 여러 창은 아이콘이 동일하므로 창 제목으로 구분해야 한다. |

### ADR-004: Mac 헬퍼를 먼저 개발

| 항목 | 내용 |
|------|------|
| 날짜 | 2026-05-24 |
| 상태 | Accepted |
| 맥락 | 두 컴포넌트의 개발 순서를 정해야 한다. |
| 결정 | Mac 헬퍼를 먼저 만든다. 핵심 기능(창 목록, 아이콘, 활성화, 키 입력)을 CLI에서 검증한 뒤 iOS 앱에 착수한다. |
| 근거 | 터미널에서 바로 검증 가능하고, iOS의 시뮬레이터/프로비저닝/권한 등 낯선 절차를 나중으로 미룰 수 있다. |
| 영향 | M1~M7 → I1~I6 → T1~T3 순서로 진행한다. |

### ADR-005: Swifter를 Mac WebSocket 서버 라이브러리로 선택

| 항목 | 내용 |
|------|------|
| 날짜 | 2026-05-24 |
| 상태 | Accepted |
| 맥락 | Mac 헬퍼에 WebSocket 서버가 필요하다. |
| 결정 | Swifter(httpswift/swifter)를 사용한다. |
| 근거 | 순수 Swift, 경량, 외부 의존성 최소화 원칙에 부합. Vapor/Perfect는 이 용도에 과하다. |
| 영향 | Swift Package Manager로 의존성 추가. Mac 헬퍼의 유일한 외부 의존성. |
