#!/bin/bash
set -e
APP="/Applications/MacHelper.app"
SRC_BIN="/Users/kknaks/git/toy_pr2/mac-remote/MacHelper/.build/arm64-apple-macosx/release/MacHelperApp"
SRC_PLIST="/Users/kknaks/git/toy_pr2/mac-remote/MacHelper/Sources/MacHelperApp/Info.plist"
SRC_ICON="/Users/kknaks/git/toy_pr2/mac-remote/icon/AppIcon.icns"
SRC_RES_BUNDLE="/Users/kknaks/git/toy_pr2/mac-remote/MacHelper/.build/arm64-apple-macosx/release/MacHelper_MacHelperApp.bundle"

sudo rm -rf "$APP"
sudo mkdir -p "$APP/Contents/MacOS"
sudo mkdir -p "$APP/Contents/Resources"
sudo cp "$SRC_BIN" "$APP/Contents/MacOS/MacHelper"
sudo cp "$SRC_PLIST" "$APP/Contents/Info.plist"
sudo cp "$SRC_ICON" "$APP/Contents/Resources/AppIcon.icns"
# SPM resources bundle (메뉴바 아이콘 PNG) — 실행 파일 옆에 둬야 Bundle.module이 찾음
if [ -d "$SRC_RES_BUNDLE" ]; then
  sudo cp -R "$SRC_RES_BUNDLE" "$APP/Contents/MacOS/MacHelper_MacHelperApp.bundle"
fi
sudo codesign --force --deep --sign - "$APP"
echo "DONE: $APP"
