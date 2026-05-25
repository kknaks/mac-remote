# iOS TestFlight 배포 런북

iOSApp(MacRemote)을 TestFlight로 업로드해 내부 테스터에게 배포한다.

- **빌드 도구**: Xcode (Archive → Distribute App)
- **서명 방식**: Automatic (Xcode가 인증서·프로비저닝 자동 관리)
- **배포 채널**: TestFlight 내부 테스트 (심사 없음, 즉시 배포)

---

## 1. 사전 준비 (최초 1회)

### 1-1. Apple Developer Program 가입
- $99/년, 개인 또는 조직 계정.

### 1-2. Apple Distribution 인증서

Keychain에 `Apple Distribution: <name> (<TeamID>)` 인증서가 있어야 한다.

```bash
security find-identity -v -p codesigning | grep "Apple Distribution"
```

없으면 Xcode 자동 발급:
- Xcode → Settings → Accounts → Apple ID 추가 → **Manage Certificates...** → **+ → Apple Distribution**

또는 [developer.apple.com](https://developer.apple.com/account/resources/certificates/list)에서 수동 발급.

### 1-3. Bundle ID 등록

`com.macremote.MacRemote` (또는 프로젝트 설정의 `PRODUCT_BUNDLE_IDENTIFIER`)를 [Identifiers](https://developer.apple.com/account/resources/identifiers/list)에 등록.

1. **+** → **App IDs** → **App** → Continue
2. Description, Bundle ID (**Explicit**, 정확히 매칭) 입력
3. Capabilities: 우리 앱은 WebSocket만 사용 — 모두 해제
4. Continue → Register

> ⚠️ Bundle ID는 등록 후 재사용·재등록이 매우 제한적. 신중히 결정.

### 1-4. App Store Connect 앱 레코드 생성

[App Store Connect](https://appstoreconnect.apple.com/apps)에서:

1. **+** → **새로운 앱(New App)**
2. 입력:
   - 플랫폼: **iOS**
   - 이름: `MacRemote` (App Store 표시명, 30자 이내, 변경 가능)
   - 기본 언어: 한국어
   - 번들 ID: §1-3에서 등록한 ID 선택
   - SKU: 임의 고유 식별자 (예: `macremote-ios-001`) — **변경 불가**
   - 사용자 액세스: 전체 액세스
3. **생성**

> TestFlight 내부 테스트만 할 거면 메타데이터(스크린샷, 설명 등)는 작성하지 않아도 된다.

---

## 2. 코드/리소스 사전 점검

업로드 전에 다음 항목을 확인한다. 누락 시 Apple 측 validation에서 거부된다.

### 2-1. App Icon 1024×1024 알파 채널 금지

iOS App Store는 1024 아이콘에 알파(투명도) 없는 PNG만 허용한다.

```bash
sips -g hasAlpha iOSApp/iOSApp/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png
# hasAlpha: no  ← 이어야 함
```

`yes`로 나오면 평탄화:

```bash
python3 <<'PY'
from PIL import Image
src = "iOSApp/iOSApp/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png"
img = Image.open(src).convert("RGBA")
bg = Image.new("RGB", img.size, (0, 0, 0))  # 디자인에 맞춰 배경색 선택
bg.paste(img, mask=img.split()[3])
bg.save(src, "PNG", optimize=True)
PY
```

- 둥근 모서리는 iOS가 자동 적용하니 **정사각형 + 단색 배경**으로 채우면 충분.
- 배경색은 아이콘 디자인 톤에 맞춰 결정 (어두운 디자인 → 검정, 밝은 디자인 → 흰색).

### 2-2. Local Network 권한 (`NSLocalNetworkUsageDescription`)

같은 Wi-Fi의 Mac에 WebSocket 연결하려면 iOS 14+ 로컬 네트워크 권한이 필요. **description 키가 없으면 Distribution 빌드에서 시스템이 권한 다이얼로그를 띄우지 않고 조용히 차단**한다.

이 프로젝트는 `INFOPLIST_KEY_*` 빌드 설정 방식으로 Xcode가 Info.plist 자동 생성. `project.pbxproj`에 다음이 있어야 함 (Debug + Release 양쪽):

```
INFOPLIST_KEY_NSLocalNetworkUsageDescription = "같은 Wi-Fi의 Mac과 연결하기 위해 로컬 네트워크에 접근합니다.";
```

확인:
```bash
grep -c NSLocalNetworkUsageDescription iOSApp/MacRemote.xcodeproj/project.pbxproj
# 2  ← Debug + Release 둘 다 있어야 정상
```

### 2-3. ATS (App Transport Security)

WebSocket을 `ws://` 평문으로 쓰지만, **사설 IP(192.168.x.x, 10.x, 172.16-31.x)와 `.local` 호스트는 ATS 자동 예외** ([Apple 공식](https://developer.apple.com/documentation/security/preventing-insecure-network-connections)). `NSAppTransportSecurity` 설정 추가 불필요.

> 만약 도메인 기반 호스트로 평문 통신을 한다면 `NSAllowsLocalNetworking = true` 같은 예외가 필요해진다. 우리 케이스는 해당 없음.

### 2-4. 서명 설정 확인

`MacRemote.xcodeproj/project.pbxproj`:

```
CODE_SIGN_STYLE = Automatic;
DEVELOPMENT_TEAM = UYQF47UCVR;
PRODUCT_BUNDLE_IDENTIFIER = com.macremote.MacRemote;
```

Xcode → Target → **Signing & Capabilities** 탭에서:
- ✅ Automatically manage signing
- ✅ Team 선택됨 (`keonhak lee (UYQF47UCVR)`)
- ✅ Bundle Identifier 일치
- 빨간 에러 없음 (Provisioning Profile 자동 발급 중이면 잠시 대기)

---

## 3. Archive & Upload

### 3-1. 빌드 대상

Xcode 상단 destination 드롭다운에서 **`Any iOS Device (arm64)`** 선택.
시뮬레이터로는 Archive 불가.

### 3-2. Archive

**Product → Archive** (1~3분).

성공 시 **Organizer** 창이 자동으로 열림 (다른 모니터/공간에 떠 있을 수 있음 — 확인).

### 3-3. Distribute App

Organizer → Archives 탭 → 방금 만든 archive 선택 → **Distribute App**:

1. **App Store Connect** → Next
2. **Upload** → Next
3. 기본값 유지 (Upload symbols, Manage version automatically) → Next
4. **Automatically manage signing** → Next
5. 요약 → **Upload**

업로드 1~5분. 성공 메시지 → **Done**.

---

## 4. App Store Connect 처리

### 4-1. 처리 대기

[App Store Connect](https://appstoreconnect.apple.com) → My Apps → **MacRemote** → **TestFlight** 탭

방금 올린 빌드가 **"처리 중(Processing)"** 5~30분.

### 4-2. Export Compliance

처리 끝나면 노란 ⚠️ **"Missing Compliance"** 표시되는 경우 클릭:

- 질문: "암호화를 사용합니까?"
- 답: **아니요** *(이 앱은 평문 WebSocket만 사용, HTTPS/암호화 통신 없음)*

> 표준 암호화(HTTPS, TLS만) 사용 시엔 "예 → 표준 암호화" 선택하면 면제. 우리 케이스는 그냥 "아니요"로 충분.

### 4-3. 내부 테스터 추가

TestFlight 탭 → 좌측 **내부 테스트(Internal Testing)** → **+** → 그룹 생성:

- 그룹 이름: `Dev` 등
- **사용자 추가**: App Store Connect에 등록된 사람만 가능 (최대 100명)
- 빌드 할당: 방금 처리 끝난 1.0 (1)

내부 테스트는 **심사 없이 즉시** 배포.

> 외부 테스터(외부 도메인, 최대 10,000명)는 첫 빌드 한 번만 Apple 간이 심사(24-48시간) 필요.

### 4-4. iPhone에 설치

1. **App Store**에서 **TestFlight** 앱 설치 (없다면)
2. TestFlight 열기 → Apple ID 로그인 (App Store Connect 계정과 동일)
3. **MacRemote** 표시됨 → **설치**
4. 첫 실행 시 **로컬 네트워크 권한 다이얼로그** → **허용**
5. Mac 메뉴바 헬퍼에서 QR 코드 → 카메라로 스캔 → 연결 확인

---

## 5. 후속 빌드 (버전 올리기)

```
1.0 (1) → 1.0 (2) → 1.0 (3) ...
```

- **Build number(`CURRENT_PROJECT_VERSION`)는 매 업로드마다 +1**. 같은 번호로 재업로드 불가.
- Marketing version (`MARKETING_VERSION`)은 사용자에게 보이는 버전. 큰 변경 때만 올린다.

Xcode → Target → **General** 탭에서 버전·빌드 번호 수정 가능. 또는 `project.pbxproj` 직접 수정.

Distribute App 단계에서 **"Manage Version and Build Number"** 체크하면 Xcode가 자동으로 빌드 번호 증가시켜준다.

---

## 6. 트러블슈팅

| 증상 | 원인 / 해결 |
|---|---|
| **`Validation failed: Invalid large app icon … can't be transparent or contain an alpha channel`** | 1024 아이콘 알파 채널 문제. §2-1로 평탄화. |
| **`Validation failed: Missing Info.plist value … NSLocalNetworkUsageDescription`** | §2-2 권한 키 누락. project.pbxproj에 `INFOPLIST_KEY_NSLocalNetworkUsageDescription` 추가. |
| iPhone 설치 후 Mac에 연결 안 됨 (조용히 실패) | 로컬 네트워크 권한 거부. 설정 → MacRemote → "로컬 네트워크" 허용. |
| Archive 메뉴 회색 | Destination이 시뮬레이터. "Any iOS Device (arm64)"로 변경. |
| `Provisioning profile doesn't include the currently selected device` | 다른 기기에 직접 설치하려는 경우. TestFlight 통해 배포할 거면 무시. Xcode 직접 설치하려면 device를 Apple Developer에 등록. |
| "Could not locate provisioning profile" | Automatic signing이 꺼져있거나 Team 미선택. Signing & Capabilities 탭 확인. |
| 같은 빌드 번호 재업로드 시도 거부 | App Store Connect는 동일 (version, build) 조합 1회만 허용. 빌드 번호 +1 후 재업로드. |
| Organizer가 안 보임 | 다른 데스크탑/모니터/공간에 떠 있을 수 있음. **Window → Organizer**로 호출. |
| 업로드는 성공했는데 TestFlight에 안 보임 | 처리 중(5~30분). 완료되면 이메일로 알림 옴 ("App Store Connect: The build … is now available for testing"). |

---

## 7. 관련 파일

- `iOSApp/MacRemote.xcodeproj` — Xcode 프로젝트
- `iOSApp/iOSApp/Assets.xcassets/AppIcon.appiconset/` — iOS 앱 아이콘 (1024 알파 금지)
- `icon/` — 원본 아이콘 PNG/ICNS 보관소
- `doc/runbook/mac-dmg-release.md` — Mac 헬퍼 DMG 배포 런북 (짝)
