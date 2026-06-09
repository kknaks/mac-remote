#!/bin/bash
# DeskDeckHelper Release DMG 빌드 스크립트 (출력물 이름 = DeskDeckHelper, SPM product는 MacHelperApp 유지)
# - Universal Binary (arm64 + x86_64) Release 빌드
# - .app 번들 조립
# - Developer ID Application 인증서로 codesign
# - DMG 패키징 + DMG 사인
#
# 사용:
#   ./scripts/build_dmg.sh                    # 기본 (버전: Info.plist의 CFBundleShortVersionString)
#   ./scripts/build_dmg.sh 1.0.1              # 버전 명시
#   SIGN_ID="..." ./scripts/build_dmg.sh      # 인증서 이름 명시 (자동 탐색 실패시)

set -euo pipefail

# ---- 경로 ----
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PKG="$ROOT/MacHelper"
BUILD_DIR="$ROOT/build"
APP_NAME="DeskDeckHelper"   # 출력 .app/실행파일/DMG 이름 (브랜드). SPM product명(MacHelperApp)·리소스번들명과는 별개
APP="$BUILD_DIR/$APP_NAME.app"
SRC_PLIST="$PKG/Sources/MacHelperApp/Info.plist"
SRC_ICON="$ROOT/icon/AppIcon.icns"

# ---- 버전 결정 ----
VERSION="${1:-$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$SRC_PLIST")}"
DMG_NAME="$APP_NAME-$VERSION.dmg"
DMG="$BUILD_DIR/$DMG_NAME"

# ---- 사인 인증서 자동 탐색 ----
if [ -z "${SIGN_ID:-}" ]; then
  SIGN_ID="$(security find-identity -v -p codesigning | awk -F\" '/Developer ID Application/{print $2; exit}')"
fi
if [ -z "$SIGN_ID" ]; then
  echo "❌ 'Developer ID Application' 인증서를 찾지 못했습니다."
  echo "   security find-identity -v -p codesigning 으로 확인하세요."
  exit 1
fi

echo "▶ 버전:    $VERSION"
echo "▶ 사인:    $SIGN_ID"
echo "▶ 출력:    $DMG"
echo ""

# ---- 1. Clean build ----
echo "▶ [1/5] Clean & Release 빌드 (universal arm64 + x86_64)"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
cd "$PKG"
swift build -c release --arch arm64 --arch x86_64 --product MacHelperApp

# universal binary 경로 (swift build가 --arch 두 개일 때 만드는 위치)
BIN="$PKG/.build/apple/Products/Release/MacHelperApp"
if [ ! -f "$BIN" ]; then
  # 폴백: 단일 아키텍처 빌드 경로
  BIN="$(find "$PKG/.build" -type f -name 'MacHelperApp' -path '*/release/*' | head -1)"
fi
if [ ! -f "$BIN" ]; then
  echo "❌ 빌드 산출물(MacHelperApp)을 찾지 못했습니다."
  exit 1
fi
echo "   바이너리: $BIN"

# SPM resources bundle (MenuBarIcon PNG들)
RES_BUNDLE="$(find "$PKG/.build" -type d -name 'MacHelper_MacHelperApp.bundle' | head -1)"
echo "   리소스 번들: ${RES_BUNDLE:-(없음)}"

# ---- 2. .app 번들 조립 ----
echo ""
echo "▶ [2/5] .app 번들 조립"
mkdir -p "$APP/Contents/MacOS"
mkdir -p "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/$APP_NAME"
cp "$SRC_PLIST" "$APP/Contents/Info.plist"
cp "$SRC_ICON" "$APP/Contents/Resources/AppIcon.icns"
if [ -d "$RES_BUNDLE" ]; then
  # SPM resource bundle은 Contents/Resources/ 에 둬야 Bundle.module이 찾음
  # (Bundle.main.resourceURL 후보에 매칭됨)
  cp -R "$RES_BUNDLE" "$APP/Contents/Resources/"
fi

# ---- 3. Codesign ----
echo ""
echo "▶ [3/5] Codesign (Developer ID, hardened runtime)"
# 내부 리소스 번들 먼저 사인 (있을 경우)
INNER_BUNDLE="$APP/Contents/Resources/MacHelper_MacHelperApp.bundle"
if [ -d "$INNER_BUNDLE" ]; then
  codesign --force --sign "$SIGN_ID" --timestamp --options runtime "$INNER_BUNDLE"
fi
# 메인 앱 사인
codesign --force --sign "$SIGN_ID" --timestamp --options runtime "$APP"

echo "   검증:"
codesign --verify --deep --strict --verbose=2 "$APP" 2>&1 | sed 's/^/     /'

# ---- 4. DMG 생성 ----
echo ""
echo "▶ [4/5] DMG 생성"
STAGE="$BUILD_DIR/dmg_stage"
rm -rf "$STAGE"
mkdir -p "$STAGE"
cp -R "$APP" "$STAGE/"
ln -s /Applications "$STAGE/Applications"   # 드래그-드롭 설치 UX

rm -f "$DMG"
hdiutil create -volname "$APP_NAME $VERSION" \
  -srcfolder "$STAGE" -ov -format UDZO "$DMG" >/dev/null

rm -rf "$STAGE"

# ---- 5. DMG 사인 ----
echo ""
echo "▶ [5/5] DMG 사인"
codesign --force --sign "$SIGN_ID" --timestamp "$DMG"
codesign --verify --verbose=2 "$DMG" 2>&1 | sed 's/^/     /'

echo ""
echo "✅ 완료: $DMG"
echo ""
echo "검증 명령:"
echo "  codesign -dv --verbose=4 \"$APP\""
echo "  spctl --assess --type execute --verbose \"$APP\"   # 공증 안 했으므로 rejected 정상"
echo ""
echo "TIP: 공증 없이는 받는 사람이 처음 열 때 우클릭→열기 한 번 필요합니다."
