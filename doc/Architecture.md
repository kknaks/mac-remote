# Architecture

## 1. 기술 스택

| 계층 | 기술 | 버전 | 선택 근거 |
|------|------|------|-----------|
| Mac 헬퍼 | Swift + AppKit | Swift 5.9+ / macOS 14+ | 네이티브 API 필수 (CGEvent, AXUIElement, CGWindowList) |
| iOS 앱 | Swift + SwiftUI | Swift 5.9+ / iOS 17+ | 선언형 UI, URLSessionWebSocketTask 내장 |
| 통신 | WebSocket (JSON) | RFC 6455 | 실시간 양방향, 서버→클라이언트 push |
| Mac WS 서버 | Swifter | latest | 경량, 순수 Swift |

### 외부 의존성

| 이름 | 용도 | 라이선스 | 비고 |
|------|------|----------|------|
| Swifter (httpswift/swifter) | Mac WebSocket 서버 | BSD-3 | Mac 헬퍼의 유일한 외부 의존성 |

---

## 2. 전체 엔티티

| 엔티티 | 설명 | 생명주기 | 저장 | 참조 스펙 |
|--------|------|----------|------|-----------|
| WindowInfo | 창 정보 (id, app, title, pid, frontmost) | 런타임 | 메모리 | Spec-01 §2 |
| KeyCommand | 키 입력 요청 (key, modifiers) | 런타임 | 메모리 | Spec-03 §2 |
| VirtualKeyMap | 가상 키코드 매핑 테이블 | 정적 | 코드 내 상수 | Spec-03 §2 |
| AppIcon | 앱 아이콘 (appName, iconData base64) | 런타임+캐시 | 메모리 | Spec-04 §2 |
| PermissionStatus | 권한 상태 (accessibility, screenRecording) | 런타임 | 메모리 | Spec-06 §2 |
| ConnectionInfo | 페어링 정보 (host, port) | 영속 | UserDefaults | Spec-07 §2 |
| MacroItem | 사용자 정의 매크로 (이름, key, modifiers) | 영속 | UserDefaults | Spec-03 §8 |
| ClientMessage | iOS→Mac 요청 (action + 파라미터) | 런타임 | 메모리 | Spec-05 §2 |
| ServerMessage | Mac→iOS 응답 (type + 페이로드) | 런타임 | 메모리 | Spec-05 §2 |

### 엔티티 관계도

```
[WindowInfo] N──1 [AppIcon]         (앱 이름으로 매칭)
      │
      └── focus 시 ──► [FocusRequest]

[KeyCommand] ──lookup──► [VirtualKeyMap]

[MacroItem] ──generates──► [KeyCommand]

[ConnectionInfo] ──connects──► [WebSocket Session]
                                     │
                              [ClientMessage] ◄──► [ServerMessage]

[PermissionStatus] ──affects──► [WindowInfo] (title 빈 값)
                   ──affects──► [KeyCommand] (전송 불가)
```

---

## 3. 프로젝트 디렉토리 구조

```
mac-remote/
├── CLAUDE.md                          ← 프로젝트 가이드
├── MacHelper/                         ← Mac 헬퍼 (메뉴바 앱)
│   ├── Package.swift                  ← SPM 매니페스트
│   └── Sources/
│       ├── WindowManager.swift        ← 창 목록 수집 + 필터링
│       ├── WindowFocuser.swift        ← 창 활성화 (PID + AXRaise)
│       ├── KeySender.swift            ← 키 입력 전송 (CGEvent)
│       ├── IconExtractor.swift        ← 앱 아이콘 추출
│       ├── WebSocketServer.swift      ← WS 서버 + 메시지 핸들링
│       ├── PermissionChecker.swift    ← 권한 상태 확인
│       ├── QRGenerator.swift          ← QR 코드 생성
│       ├── MenuBarApp.swift           ← 메뉴바 앱 엔트리
│       └── Models.swift               ← 공유 모델 (WindowInfo 등)
├── iOSApp/                            ← iPhone 앱 (SwiftUI)
│   ├── iOSApp.xcodeproj
│   └── iOSApp/
│       ├── iOSAppApp.swift            ← 앱 엔트리
│       ├── ContentView.swift          ← 3탭 TabView
│       ├── WebSocketManager.swift     ← WS 클라이언트
│       ├── Views/
│       │   ├── WindowListView.swift   ← 창 목록 탭
│       │   ├── MacroView.swift        ← 매크로 탭
│       │   └── SettingsView.swift     ← 설정 탭
│       ├── Components/
│       │   ├── WindowCardView.swift   ← 창 카드 컴포넌트
│       │   ├── MacroButtonView.swift  ← 매크로 버튼
│       │   └── StatusIndicator.swift  ← 연결 표시등
│       └── Models/
│           ├── Models.swift           ← 공유 모델
│           └── MacroItem.swift        ← 매크로 모델
├── doc/
│   ├── templates/                     ← 문서 템플릿 (수정 금지)
│   ├── Decision.md
│   ├── Spec.md
│   ├── spec/                          ← 상세 스펙
│   ├── Work.md
│   ├── work/                          ← 상세 워크플랜
│   └── Architecture.md               ← 이 파일
└── .claude/
    └── skills/                        ← 문서 파이프라인 스킬
```

| 디렉토리 | 용도 | 비고 |
|----------|------|------|
| MacHelper/ | Mac 헬퍼 앱 전체 소스 | Swift Package (SPM) |
| iOSApp/ | iOS 앱 전체 소스 | Xcode 프로젝트 |
| doc/ | 프로젝트 문서 | 단일 진실 공급원 체계 |
| doc/templates/ | 문서 원본 양식 | 수정 금지 |
| .claude/skills/ | Claude Code 스킬 | 문서 파이프라인 자동화 |

---

## 4. 시스템 구조

### 전체 구조도

```
┌─────────────────────────┐         Wi-Fi (LAN)         ┌──────────────────────────────┐
│  iOS 앱 (리모컨)          │                             │  Mac 헬퍼 (실행기)              │
│  SwiftUI                 │                             │  Swift, 메뉴바 앱              │
│                          │   WebSocket / JSON          │                              │
│  ┌─────────────────┐    │◄────────────────────────────►│  ┌──────────────────────┐    │
│  │ WebSocketManager │    │   ws://ip:8765              │  │ WebSocketServer      │    │
│  └────────┬────────┘    │                             │  │ (Swifter)            │    │
│           │              │                             │  └──────────┬───────────┘    │
│  ┌────────▼────────┐    │                             │             │                │
│  │ WindowListView   │    │   ◄── windowList push       │  ┌──────────▼───────────┐    │
│  │ MacroView        │    │   ◄── appIcons push         │  │ WindowManager        │    │
│  │ SettingsView     │    │   ◄── permissions           │  │ WindowFocuser        │    │
│  └──────────────────┘    │   ──► focus/key/list        │  │ KeySender            │    │
│                          │                             │  │ IconExtractor        │    │
│  ┌──────────────────┐    │                             │  │ PermissionChecker    │    │
│  │ UserDefaults      │    │                             │  └──────────────────────┘    │
│  │ - ConnectionInfo  │    │                             │                              │
│  │ - MacroItems      │    │                             │  ┌──────────────────────┐    │
│  └──────────────────┘    │                             │  │ MenuBarExtra         │    │
│                          │                             │  │ - 상태/IP/권한/QR     │    │
└─────────────────────────┘                             │  └──────────────────────┘    │
                                                         └──────────────────────────────┘
```

### 컴포넌트 목록

| 컴포넌트 | 역할 | 기술 스택 | 비고 |
|----------|------|-----------|------|
| Mac 헬퍼 | 창 관리, 키 입력, WS 서버, 메뉴바 앱 | Swift, AppKit, CoreGraphics, Accessibility | 모든 실행 로직 담당 |
| iOS 앱 | 리모컨 UI, WS 클라이언트 | Swift, SwiftUI | 표시+명령 전송만 |

---

## 5. 컴포넌트 상세

### 5-1. Mac 헬퍼

```
MacHelper/Sources/
├── Models.swift              — 공유 데이터 모델
├── WindowManager.swift       — 창 목록 수집
├── WindowFocuser.swift       — 창 활성화
├── KeySender.swift           — 키 입력 전송
├── IconExtractor.swift       — 앱 아이콘 추출
├── PermissionChecker.swift   — 권한 확인
├── WebSocketServer.swift     — WS 서버 + 메시지 라우팅
├── QRGenerator.swift         — QR 코드 생성
└── MenuBarApp.swift          — 앱 엔트리 + 메뉴바 UI
```

| 모듈 | 책임 | 의존 | 기술 |
|------|------|------|------|
| WindowManager | CGWindowList 호출, 필터링, WindowInfo 반환 | CoreGraphics, AppKit | CGWindowListCopyWindowInfo |
| WindowFocuser | PID 기반 앱 활성화 + AXRaise | AppKit, Accessibility | NSRunningApplication, AXUIElement |
| KeySender | CGEvent 생성 + 전송 | CoreGraphics | CGEvent, CGEventFlags |
| IconExtractor | 앱 아이콘 → PNG base64 | AppKit | NSRunningApplication.icon |
| PermissionChecker | Accessibility + Screen Recording 확인 | ApplicationServices | AXIsProcessTrusted |
| WebSocketServer | WS 서버, JSON 파싱, 메시지 라우팅, 주기적 push | Swifter | |
| QRGenerator | IP:포트 → QR 이미지 | CoreImage | CIFilter |
| MenuBarApp | 메뉴바 UI, 앱 라이프사이클 | SwiftUI | MenuBarExtra |

### 5-2. iOS 앱

```
iOSApp/iOSApp/
├── iOSAppApp.swift           — 앱 엔트리
├── ContentView.swift         — 3탭 TabView
├── WebSocketManager.swift    — WS 클라이언트
├── Views/                    — 탭별 화면
├── Components/               — 재사용 컴포넌트
└── Models/                   — 데이터 모델
```

| 모듈 | 책임 | 의존 | 기술 |
|------|------|------|------|
| WebSocketManager | WS 연결/해제/수신/송신/재연결 | Foundation | URLSessionWebSocketTask |
| WindowListView | 창 목록 카드 리스트, focus 전송 | SwiftUI | List, WindowCardView |
| MacroView | 매크로 버튼 그리드, key 전송 | SwiftUI | LazyVGrid |
| SettingsView | QR 스캔, 수동 입력, 권한 표시, 설정 | SwiftUI, AVFoundation | AVCaptureSession |
| StatusIndicator | 연결 상태 표시등 | SwiftUI | Circle + color |

---

## 6. 통신 / 인터페이스

| 경로 | 프로토콜 | 포맷 | 방향 | 참조 스펙 |
|------|----------|------|------|-----------|
| iOS ↔ Mac | WebSocket | JSON | 양방향 | Spec-05 §3 |
| iOS → Mac: listWindows | WebSocket | JSON | 단방향 | Spec-01 §3 |
| iOS → Mac: focus | WebSocket | JSON | 요청/응답 | Spec-02 §3 |
| iOS → Mac: key | WebSocket | JSON | 요청/응답 | Spec-03 §3 |
| Mac → iOS: windowList | WebSocket | JSON | push (1.5초) | Spec-01 §3 |
| Mac → iOS: appIcons | WebSocket | JSON+base64 | push (새 앱 시) | Spec-04 §3 |
| Mac → iOS: permissions | WebSocket | JSON | 요청/응답 | Spec-06 §3 |

---

## 7. 데이터 흐름

```
iOS 사용자 액션 ──► [WebSocketManager] ──JSON──► [WebSocketServer]
                                                       │
                           ┌───────────────────────────┤
                           ▼                           ▼
                    listWindows?               focus/key?
                           │                           │
                    [WindowManager]          [WindowFocuser/KeySender]
                           │                           │
                    CGWindowList               CGEvent / AXUIElement
                           │                           │
                           ▼                           ▼
                    windowList JSON ─────────► [WebSocketServer] ──push──► [iOS 앱 UI 갱신]
                                                       │
                                                [IconExtractor]
                                                       │
                                              appIcons push ──► [iOS 아이콘 캐시]
```

---

## 8. 배포 / 실행 환경

| 컴포넌트 | 플랫폼 | 최소 버전 | 권한 / 설정 |
|----------|--------|-----------|-------------|
| Mac 헬퍼 | macOS | 14.0+ | Accessibility (필수), Screen Recording (창 제목에 필요) |
| iOS 앱 | iOS | 17.0+ | 카메라 (QR 스캔, 선택적) |
| 네트워크 | Wi-Fi LAN | — | 같은 네트워크 필수, 포트 8765 |

### 배포 전략

| 환경 | 대상 | 서명 | 프로비저닝 |
|------|------|------|-----------|
| Local | Mac 헬퍼 | 불필요 (개발 중) | 불필요 |
| Local | iOS 앱 | Development 인증서 | Development Profile |
| TestFlight | iOS 앱 | Distribution 인증서 | App Store Profile |

### 배포 명령어

#### Mac 헬퍼 — Local

```bash
# 개발 빌드 + 실행
cd MacHelper
swift build
swift run MacHelper

# Release 빌드
swift build -c release

# .app 번들로 Archive (Xcode)
xcodebuild -scheme MacHelper -configuration Release archive \
  -archivePath build/MacHelper.xcarchive

# Archive에서 .app 추출
xcodebuild -exportArchive \
  -archivePath build/MacHelper.xcarchive \
  -exportPath build/ \
  -exportOptionsPlist ExportOptions.plist
```

#### iOS 앱 — Local (실기기 직접 설치)

```bash
cd iOSApp

# 연결된 기기에 빌드 + 설치
xcodebuild -scheme iOSApp \
  -destination 'platform=iOS,name=My iPhone' \
  -configuration Debug \
  build

# 또는 Xcode GUI: Product → Run (⌘R) with device selected
```

#### iOS 앱 — TestFlight

```bash
cd iOSApp

# 1. Archive 생성
xcodebuild -scheme iOSApp \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  archive \
  -archivePath build/iOSApp.xcarchive

# 2. IPA 추출
xcodebuild -exportArchive \
  -archivePath build/iOSApp.xcarchive \
  -exportPath build/ \
  -exportOptionsPlist ExportOptions-AppStore.plist

# 3. App Store Connect에 업로드
xcrun altool --upload-app \
  -f build/iOSApp.ipa \
  -t ios \
  -u "developer@example.com" \
  -p "@keychain:AC_PASSWORD"

# 4. App Store Connect → TestFlight → 테스터 초대
# (웹 또는 Xcode GUI에서 수행)
```

---

## 9. 변경 이력

| 날짜 | 변경 내용 | 작성자 |
|------|-----------|--------|
| 2026-05-24 | 최초 작성 | |
