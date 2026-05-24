# CLAUDE.md

## 프로젝트 개요

iPhone을 리모컨으로 써서 MacBook의 창을 전환하고 단축키 매크로를 전송하는 앱.
Mac 헬퍼(실행기) + iOS 앱(리모컨), WebSocket(JSON) 통신.

---

## 단일 진실 공급원 (Single Source of Truth)

각 문서는 해당 영역의 단일 진실 공급원이다. 중복 작성하지 않고, 참조로 연결한다.

| 영역 | 문서 | 역할 |
|------|------|------|
| 프로젝트 계획·의사결정 | `doc/Decision.md` | WHY, 제약, 기술 선택, ADR 로그 |
| 기능 스펙 (인덱스) | `doc/Spec.md` | 스펙 간 관계·상태 맵 |
| 기능 스펙 (상세) | `doc/spec/Spec-NN-slug.md` | **기능별 단일 진실 공급원** — 계약, 상태 전이, 에러, 유저 플로우 |
| 작업 계획 (인덱스) | `doc/Work.md` | 워크 간 관계 + 스펙 커버리지 + 작업 현황 |
| 작업 계획 (상세) | `doc/work/Work-NN-slug.md` | 태스크 분해, 커밋 추적, 검증 방법 |
| 아키텍처 | `doc/Architecture.md` | 기술 스택 ↔ 시스템 구조, 엔티티 맵, 디렉토리 구조 |
| 템플릿 | `doc/templates/*.tpl.md` | 각 문서의 원본 양식 |

---

## 문서 흐름 (파이프라인)

```
Decision ──► Spec ──► Work ──► /work-run (TDD 구현)
    │           │                    │
    └───────────┴──► Architecture    └──► Work 갱신 (상태 + 커밋 해시)
```

1. **Decision** 먼저: 프로젝트의 WHY, 제약, 기술 선택을 확정한다.
2. **Spec** 다음: Decision의 제약 안에서 기능별 상세 스펙을 작성한다.
3. **Work** 마지막: Spec을 구현 관점으로 분해한 워크플랜을 작성한다.
4. **Architecture**: Decision + Spec을 기반으로 전체 구조를 정리한다.

상위 문서가 바뀌면 하위 문서를 갱신한다. 하위가 상위를 수정하지 않는다.

---

## 스킬 파이프라인

문서 작업 시 아래 스킬을 사용한다. 각 스킬은 **읽어야 할 파일과 만들어야 할 파일이 명확히 정의**되어 있어 불필요한 문서 탐색을 하지 않는다.

| 순서 | 스킬 | 읽는 것 | 만드는 것 |
|------|------|---------|-----------|
| 1 | `/doc-decision` | Decision 템플릿 | `doc/Decision.md` |
| 2 | `/doc-spec` | Spec 템플릿 + Decision.md | `doc/Spec.md` + `doc/spec/Spec-NN-slug.md` |
| 3 | `/doc-work` | Work 템플릿 + 관련 Spec만 | `doc/Work.md` + `doc/work/Work-NN-slug.md` |
| 4 | `/doc-arch` | Arch 템플릿 + Decision + Spec 인덱스 | `doc/Architecture.md` |
| — | `/doc-status` | Spec.md + Work.md 인덱스만 | 없음 (현황 보고만) |
| 5 | `/work-run` | Work-detail + 관련 Spec만 | 코드 구현 + Work-detail·인덱스 갱신 |

### 사용 규칙

- 문서를 처음 만들 때: 파이프라인 순서대로 (Decision → Spec → Work → Architecture)
- 기존 문서 업데이트: 해당 스킬만 호출
- 현황 파악: `/doc-status`로 인덱스만 읽고 보고
- 구현: `/work-run`으로 TDD 사이클 (RED → GREEN → REFACTOR → COMMIT)
- **스킬이 지정하지 않은 문서는 읽지 않는다** — 컨텍스트 낭비 방지

---

## 디렉토리 구조

```
mac-remote/
├── CLAUDE.md              ← 지금 이 파일
├── doc/
│   ├── templates/         ← 문서 템플릿 (수정 금지)
│   │   ├── Decision.tpl.md
│   │   ├── Spec.tpl.md
│   │   ├── Spec-detail.tpl.md
│   │   ├── Work.tpl.md
│   │   ├── Work-detail.tpl.md
│   │   └── Architecture.tpl.md
│   ├── Decision.md
│   ├── Spec.md
│   ├── spec/              ← 상세 스펙
│   ├── Work.md
│   ├── work/              ← 상세 워크플랜
│   └── Architecture.md
├── MacHelper/                         ← Mac 헬퍼 (메뉴바 앱, Swift Package)
│   ├── Package.swift
│   ├── Sources/
│   │   ├── MacHelper/
│   │   │   └── main.swift             ← CLI 엔트리포인트
│   │   └── MacHelperLib/
│   │       ├── MacHelperLib.swift      ← 라이브러리 엔트리
│   │       ├── Models.swift           ← 공유 모델 (WindowInfo, KeyCommand 등)
│   │       ├── WindowManager.swift    ← 창 목록 수집 (CGWindowListCopyWindowInfo)
│   │       ├── WindowFocuser.swift    ← 창 활성화 (PID + AXRaise)
│   │       ├── KeySender.swift        ← 키 입력 전송 (CGEvent)
│   │       ├── IconExtractor.swift    ← 앱 아이콘 추출 (NSWorkspace)
│   │       ├── PermissionChecker.swift ← 권한 확인 (AXIsProcessTrusted)
│   │       ├── PermissionGuide.swift  ← 권한 안내 메시지
│   │       ├── JSONOutput.swift       ← JSON 콘솔 출력
│   │       ├── WebSocketServer.swift  ← WS 서버 + 메시지 라우팅 (Swifter)
│   │       ├── QRGenerator.swift      ← QR 코드 생성 (CIFilter)
│   │       └── MenuBarApp.swift       ← 앱 엔트리 (MenuBarExtra)
│   └── Tests/
│       ├── MacHelperTests.swift       ← 통합 테스트
│       ├── ModelsTests.swift          ← 모델 테스트
│       ├── WindowManagerTests.swift   ← 창 관리 테스트
│       ├── PermissionCheckerTests.swift ← 권한 확인 테스트
│       ├── PermissionGuideTests.swift ← 권한 안내 테스트
│       └── JSONOutputTests.swift      ← JSON 출력 테스트
├── iOSApp/                            ← iPhone 앱 (SwiftUI, iOS 17+)
│   ├── iOSApp.xcodeproj
│   └── iOSApp/
│       ├── iOSAppApp.swift            ← 앱 엔트리
│       ├── ContentView.swift          ← 3탭 TabView
│       ├── WebSocketManager.swift     ← WS 클라이언트 (URLSessionWebSocketTask)
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
└── .claude/
    └── skills/            ← 문서 파이프라인 스킬
        ├── doc-decision/SKILL.md
        ├── doc-spec/SKILL.md
        ├── doc-work/SKILL.md
        ├── doc-arch/SKILL.md
        ├── doc-status/SKILL.md
        └── work-run/SKILL.md
```

---

## 배포 전략

| 환경 | 대상 | 방법 | 비고 |
|------|------|------|------|
| **Local** | Mac 헬퍼 | `swift build` → 직접 실행 또는 Xcode Archive | 개발 중 기본 |
| **Local** | iOS 앱 | Xcode → USB/Wi-Fi 직접 설치 | 실기기 필수 (시뮬레이터는 WebSocket만 테스트 가능) |
| **TestFlight** | iOS 앱 | Xcode → Archive → App Store Connect 업로드 → TestFlight 배포 | 내부 테스터 즉시, 외부 테스터는 간이 심사 |

### 배포별 차이

| | Local | TestFlight |
|---|-------|------------|
| 계정 | 유료 Apple Developer | 유료 Apple Developer |
| 서명 | Development 인증서 | Distribution 인증서 |
| 프로비저닝 | Development Profile | App Store Profile |
| 설치 범위 | 등록된 기기만 | 초대된 테스터 (내부 100명 / 외부 10,000명) |
| 유효 기간 | 기기 등록 유지 시 무제한 | 빌드당 90일 |
| 설치 방법 | Xcode / USB / Wi-Fi | TestFlight 앱 |
| 심사 | 없음 | 외부 테스터만 간이 심사 |

### 빠른 명령어

```bash
# Mac 헬퍼 — 개발 빌드 + 실행
cd MacHelper && swift run MacHelper

# Mac 헬퍼 — Release 빌드
cd MacHelper && swift build -c release

# iOS — 실기기 직접 설치 (Xcode GUI 권장: ⌘R)
cd iOSApp && xcodebuild -scheme iOSApp -destination 'platform=iOS,name=My iPhone' build

# iOS — TestFlight 업로드
cd iOSApp
xcodebuild -scheme iOSApp -configuration Release -destination 'generic/platform=iOS' archive -archivePath build/iOSApp.xcarchive
xcodebuild -exportArchive -archivePath build/iOSApp.xcarchive -exportPath build/ -exportOptionsPlist ExportOptions-AppStore.plist
xcrun altool --upload-app -f build/iOSApp.ipa -t ios -u "APPLE_ID" -p "@keychain:AC_PASSWORD"
```

상세 명령어와 옵션은 `doc/Architecture.md` §8 참조.
