#!/bin/bash
set -e
APP="/Applications/MacHelper.app"
SRC_BIN="/Users/kknaks/git/toy_pr2/mac-remote/MacHelper/.build/arm64-apple-macosx/release/MacHelperApp"
SRC_PLIST="/Users/kknaks/git/toy_pr2/mac-remote/MacHelper/Sources/MacHelperApp/Info.plist"
SRC_ICON="/Users/kknaks/git/toy_pr2/mac-remote/icon/AppIcon.icns"

sudo rm -rf "$APP"
sudo mkdir -p "$APP/Contents/MacOS"
sudo mkdir -p "$APP/Contents/Resources"
sudo cp "$SRC_BIN" "$APP/Contents/MacOS/MacHelper"
sudo cp "$SRC_PLIST" "$APP/Contents/Info.plist"
sudo cp "$SRC_ICON" "$APP/Contents/Resources/AppIcon.icns"
sudo codesign --force --deep --sign - "$APP"
echo "DONE: $APP"
