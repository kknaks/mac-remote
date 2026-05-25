# Mac DMG 배포 런북

MacHelper를 Developer ID 사인된 DMG로 패키징해 외부 배포한다.

- **빌드 스크립트**: `scripts/build_dmg.sh`
- **출력**: `build/MacHelper-<버전>.dmg`
- **배포 형태**: Universal Binary (arm64 + x86_64), Developer ID 사인, 공증(notarization) 미적용

> **공증 정책**: 현재는 내부 테스트 단계라 공증을 생략한다. 받는 사람은 첫 실행 시 **우클릭 → 열기**가 한 번 필요하다. 외부 공개 배포로 전환할 때 공증을 추가한다 (§5 참조).

---

## 1. 사전 준비 (최초 1회)

### 1-1. Apple Developer Program 가입
- $99/년, 개인 또는 조직 계정.
- 이미 가입되어 있다면 스킵.

### 1-2. Developer ID Application 인증서 발급

`Apple Distribution` 인증서는 **App Store 업로드 전용**이므로, **외부 직접 배포에는 못 쓴다**. 별도로 `Developer ID Application` 인증서를 만들어야 한다.

#### CSR 생성

1. **키체인 접근(Keychain Access)** 앱 실행
   - Spotlight(⌘+Space) → "키체인 접근"
   - ⚠️ macOS Sequoia의 "암호(Passwords)" 앱과 다른 앱이다.
2. 메뉴: **키체인 접근 → 인증서 지원 → 인증 기관에서 인증서 요청...**
3. 입력:
   - 사용자 이메일 주소: 본인 이메일
   - 일반 이름: 본인 이름
   - CA 이메일 주소: 비워둠
   - 요청 다음 작업: **디스크에 저장됨** 선택
4. `CertificateSigningRequest.certSigningRequest` 파일 저장.

#### 인증서 발급

1. https://developer.apple.com/account/resources/certificates/list 접속
2. **+** 클릭 → **Software → Developer ID Application** 선택
3. **Profile Type**: G2 Sub-CA (Xcode 11.4.1 or later)
4. CSR 파일 업로드 → **Continue**
5. `.cer` 파일 다운로드 → **더블클릭**으로 로그인 키체인에 추가

#### 설치 확인

```bash
security find-identity -v -p codesigning | grep "Developer ID Application"
```

다음과 같이 한 줄 출력되면 성공:

```
3) BFE76B997529D04CAB7DABC5BA147F873F608CFA "Developer ID Application: keonhak lee (UYQF47UCVR)"
```

---

## 2. 배포 빌드 실행

```bash
cd /path/to/mac-remote
./scripts/build_dmg.sh                # 버전: Info.plist의 CFBundleShortVersionString
./scripts/build_dmg.sh 1.0.1          # 버전 명시
SIGN_ID="Developer ID Application: keonhak lee (UYQF47UCVR)" \
  ./scripts/build_dmg.sh              # 인증서 명시 (자동 탐색 실패 시)
```

### 스크립트가 하는 일

1. **Clean & Universal Release 빌드** — `swift build -c release --arch arm64 --arch x86_64`
2. **`.app` 번들 조립**
   - `Contents/MacOS/MacHelper` ← 실행 바이너리
   - `Contents/Info.plist` ← `Sources/MacHelperApp/Info.plist`
   - `Contents/Resources/AppIcon.icns` ← `icon/AppIcon.icns`
   - `Contents/MacOS/MacHelper_MacHelperApp.bundle` ← SPM 리소스 번들 (메뉴바 아이콘 PNG)
3. **Codesign** — Developer ID + `--timestamp` + `--options runtime` (hardened runtime)
4. **DMG 생성** — `hdiutil create`로 UDZO 압축, `/Applications` 심볼릭 링크 포함 (드래그-드롭 UX)
5. **DMG 사인** — DMG 파일 자체도 Developer ID로 사인

---

## 3. 빌드 결과 검증

```bash
APP="build/MacHelper.app"
DMG="build/MacHelper-1.0.dmg"

# 사인 정보
codesign -dv --verbose=2 "$APP"

# 사인 검증 (전체 트리)
codesign --verify --deep --strict --verbose=2 "$APP"

# 아키텍처 확인 (universal: x86_64 arm64 둘 다 나와야 함)
lipo -info "$APP/Contents/MacOS/MacHelper"

# Gatekeeper 평가 (공증 안 했으므로 rejected 정상)
spctl --assess --type execute --verbose "$APP"
```

### 정상 출력 기준

| 항목 | 기대값 |
|---|---|
| Authority | `Developer ID Application: <이름> (<TeamID>)` |
| Authority chain | `Developer ID Certification Authority` → `Apple Root CA` |
| Format | `app bundle with Mach-O universal (x86_64 arm64)` |
| flags | `0x10000(runtime)` |
| Timestamp | (서명 시각, 공백 아님) |
| `lipo -info` | `x86_64 arm64` 둘 다 |
| `spctl --assess` | `rejected: source=Unnotarized Developer ID` ← **현재는 이게 정상** |

---

## 4. 받는 사람용 설치 가이드

DMG와 함께 다음 안내문을 전달한다.

> ### MacHelper 설치 방법
>
> 1. `MacHelper-1.0.dmg` 더블클릭 → 창이 열리면 **MacHelper.app**을 **Applications** 폴더로 드래그
> 2. Finder → 응용 프로그램 → **MacHelper.app**을 **우클릭 → 열기** *(첫 실행만, 이후엔 더블클릭 OK)*
> 3. "확인되지 않은 개발자" 경고 → **열기** 클릭
> 4. 메뉴바에 아이콘 표시 확인
> 5. 권한 허용:
>    - 시스템 설정 → 개인정보 보호 및 보안 → **손쉬운 사용** → MacHelper 체크
>    - (필요 시) **화면 기록 및 시스템 오디오 녹음** → MacHelper 체크
> 6. 메뉴바 아이콘 클릭 → QR 코드로 iPhone 앱 연결

---

## 5. (선택) 공증으로 전환

외부 일반 사용자에게 배포할 때, **우클릭→열기** 단계를 없애려면 Apple 공증(notarization)을 추가한다.

### 일회성 자격증명 저장

```bash
# Apple ID 앱 전용 암호 발급: https://appleid.apple.com → 로그인 → "앱 암호" 생성
xcrun notarytool store-credentials "AC_NOTARY" \
  --apple-id "YOUR_APPLE_ID@email.com" \
  --team-id "UYQF47UCVR" \
  --password "xxxx-xxxx-xxxx-xxxx"
```

### 공증 단계 (DMG 빌드 후 추가)

```bash
DMG="build/MacHelper-1.0.dmg"

# 업로드 + 대기 + 결과
xcrun notarytool submit "$DMG" --keychain-profile "AC_NOTARY" --wait

# 성공 시 DMG에 티켓 부착
xcrun stapler staple "$DMG"

# 검증
spctl --assess --type open --context context:primary-signature -v "$DMG"
# → "accepted, source=Notarized Developer ID" 가 나와야 함
```

공증을 정식 채택할 때는 `scripts/build_dmg.sh`에 위 단계를 추가하거나 별도 스크립트 `scripts/notarize_dmg.sh`로 분리한다.

---

## 6. 트러블슈팅

| 증상 | 원인 / 해결 |
|---|---|
| `❌ 'Developer ID Application' 인증서를 찾지 못했습니다.` | §1-2 인증서 발급 누락. 또는 다른 키체인에 있음 — 로그인 키체인으로 옮기기. |
| `errSecInternalComponent` codesign 실패 | 키체인 잠김. `security unlock-keychain login.keychain` 후 재시도. |
| `MacHelper_MacHelperApp.bundle` 없음 | 메뉴바 아이콘 PNG 리소스 번들이 안 만들어진 상태. `swift build -c release`가 정상 완료됐는지 확인. `Package.swift`의 `resources:` 설정 점검. |
| 받는 사람 Mac에서 "손상되어 열 수 없음" | DMG 전송 중 손상(다운로드 캐시·확장자 변경). 다시 받아보고, 안 되면 격리 속성 제거: `xattr -d com.apple.quarantine MacHelper.app` |
| spctl이 `accepted`로 나옴 (예상은 rejected) | 본인 Mac에서는 키체인 신뢰 때문에 accepted로 나올 수 있음. 다른 Mac에서 테스트해야 정확함. |

---

## 7. 관련 파일

- `scripts/build_dmg.sh` — 본 런북이 호출하는 빌드 스크립트
- `scripts/install_machelper.sh` — 로컬 개발용 (ad-hoc 사인, /Applications 직접 설치)
- `MacHelper/Sources/MacHelperApp/Info.plist` — 앱 메타데이터 (버전, Bundle ID 등)
- `icon/AppIcon.icns` — 앱 아이콘
