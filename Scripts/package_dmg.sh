#!/usr/bin/env bash
set -euo pipefail

APP_NAME="FocusFlow"
BUNDLE_ID="com.loker2024.FocusFlow"
VERSION="1.0.0"
MIN_MACOS="14.0"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RELEASE_DIR="$ROOT_DIR/.build/release"
DIST_DIR="$ROOT_DIR/.build/dist"
APP_PATH="$DIST_DIR/$APP_NAME.app"
DMG_STAGING_DIR="$DIST_DIR/dmg-staging"
ICON_FILE="$APP_NAME.icns"
ICON_SOURCE="$ROOT_DIR/FocusFlow/Resources/$ICON_FILE"
DESKTOP_DIR="$HOME/Desktop"
DESKTOP_APP_PATH="$DESKTOP_DIR/$APP_NAME.app"
DESKTOP_DMG_PATH="$DESKTOP_DIR/$APP_NAME.dmg"

swift build -c release --package-path "$ROOT_DIR"

rm -rf "$APP_PATH" "$DMG_STAGING_DIR" "$DESKTOP_APP_PATH" "$DESKTOP_DMG_PATH"
mkdir -p "$APP_PATH/Contents/MacOS" "$APP_PATH/Contents/Resources" "$DMG_STAGING_DIR"

cp "$RELEASE_DIR/$APP_NAME" "$APP_PATH/Contents/MacOS/$APP_NAME"
chmod 755 "$APP_PATH/Contents/MacOS/$APP_NAME"

if [[ ! -f "$ICON_SOURCE" ]]; then
    echo "Missing app icon: $ICON_SOURCE" >&2
    echo "Run Scripts/generate_app_icon.py first." >&2
    exit 1
fi
cp "$ICON_SOURCE" "$APP_PATH/Contents/Resources/$ICON_FILE"

cat > "$APP_PATH/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>zh_CN</string>
    <key>CFBundleDisplayName</key>
    <string>$APP_NAME</string>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIconFile</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>$BUNDLE_ID</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.productivity</string>
    <key>LSMinimumSystemVersion</key>
    <string>$MIN_MACOS</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>
PLIST

printf "APPL????" > "$APP_PATH/Contents/PkgInfo"

codesign --force --deep --sign - "$APP_PATH"
codesign --verify --deep --strict "$APP_PATH"

ditto "$APP_PATH" "$DESKTOP_APP_PATH"

ditto "$APP_PATH" "$DMG_STAGING_DIR/$APP_NAME.app"
ln -s /Applications "$DMG_STAGING_DIR/Applications"
hdiutil create \
    -volname "$APP_NAME" \
    -srcfolder "$DMG_STAGING_DIR" \
    -ov \
    -format UDZO \
    "$DESKTOP_DMG_PATH"

echo "Installed app: $DESKTOP_APP_PATH"
echo "Created DMG: $DESKTOP_DMG_PATH"
