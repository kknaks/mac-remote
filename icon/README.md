# mac-remote — App Icons

생성된 아이콘 파일 사용 가이드.

## 📦 파일 목록

### iOS / Mac 앱 아이콘 (공통)
- **`AppIcon-1024.png`** ← 가장 중요. Xcode에 이거 하나만 넣으면 됨
- `AppIcon-512.png` ~ `AppIcon-16.png` — `.icns` 직접 만들 때 사용

### Mac 메뉴바 아이콘 (M2: 키캡 + ⌘)
- **`MenuBarIcon.png`** — 18×18 (1x)
- **`MenuBarIcon-2x.png`** — 36×36 (2x) ← **Xcode 넣을 때 `MenuBarIcon@2x.png`로 이름 바꿔주세요**
- **`MenuBarIcon-3x.png`** — 54×54 (3x) ← **`MenuBarIcon@3x.png`로 이름 바꿔주세요**
- `MenuBarIcon-512.png` — 미리보기/문서용

> 파일 시스템 제약상 `@` 문자가 `-`로 저장됨. Xcode `.xcassets`에 넣기 전에 파일명에서 `-2x` → `@2x`, `-3x` → `@3x`로 바꿔주세요.

---

## 🍎 iOS 앱에 적용 (`iOSApp/`)

1. Xcode에서 `iOSApp/iOSApp/Assets.xcassets` 열기
2. `AppIcon` 에셋 선택 → "Single Size" (1024×1024) 슬롯에 **`AppIcon-1024.png`** 드래그
3. 끝. Xcode 14+ 가 나머지 사이즈 자동 생성.

> Apple 가이드: 알파(투명) 채널 없어야 함 ✓, 1024×1024 ✓, 정사각형 ✓ — 모두 충족.

---

## 🖥 Mac 헬퍼 앱에 적용 (`MacHelper/`)

### A. 앱 아이콘 (Finder / Dock / About 메뉴)

**방법 1 — Xcode AppIcon 에셋 사용 (권장)**
- `MacHelper/Sources/MacHelperApp/Assets.xcassets/AppIcon.appiconset/` 만들고 `AppIcon-1024.png` 넣기
- (또는 그냥 SwiftPM 빌드면 `Package.swift` 의 resources에 추가)

**방법 2 — `.icns` 직접 생성**
```bash
mkdir AppIcon.iconset
cp AppIcon-16.png   AppIcon.iconset/icon_16x16.png
cp AppIcon-32.png   AppIcon.iconset/icon_16x16@2x.png
cp AppIcon-32.png   AppIcon.iconset/icon_32x32.png
cp AppIcon-64.png   AppIcon.iconset/icon_32x32@2x.png
cp AppIcon-128.png  AppIcon.iconset/icon_128x128.png
cp AppIcon-256.png  AppIcon.iconset/icon_128x128@2x.png
cp AppIcon-256.png  AppIcon.iconset/icon_256x256.png
cp AppIcon-512.png  AppIcon.iconset/icon_256x256@2x.png
cp AppIcon-512.png  AppIcon.iconset/icon_512x512.png
cp AppIcon-1024.png AppIcon.iconset/icon_512x512@2x.png
iconutil -c icns AppIcon.iconset
```

### B. 메뉴바 아이콘 (status bar item)

1. `MacHelper/.../Assets.xcassets/MenuBarIcon.imageset/` 생성
2. 세 파일 추가:
   - `MenuBarIcon.png` (1x)
   - `MenuBarIcon@2x.png` (2x — 파일명 `@` 로 변경)
   - `MenuBarIcon@3x.png` (3x — 파일명 `@` 로 변경)
3. `Contents.json` 에서 **"Render As: Template Image"** 체크
   (또는 SwiftUI에서 `.renderingMode(.template)` 적용)
4. SwiftUI 사용 예시:
   ```swift
   MenuBarExtra("mac-remote", image: "MenuBarIcon") {
       MenuBarContentView()
   }
   ```

> Template image라서 macOS가 라이트 모드에선 검정, 다크 모드에선 흰색으로 자동 변환합니다.
