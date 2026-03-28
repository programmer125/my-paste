#!/bin/zsh

set -euo pipefail

APP_NAME="${APP_NAME:-ClipboardMenu}"
BUNDLE_ID="${BUNDLE_ID:-com.duyx.clipboardmenu}"
SHORT_VERSION="${SHORT_VERSION:-0.1.0}"
BUILD_VERSION="${BUILD_VERSION:-1}"
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_DIR="$DIST_DIR/$APP_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
MODULE_CACHE_DIR="${MODULE_CACHE_DIR:-$DIST_DIR/module-cache}"

cd "$ROOT_DIR"

/bin/mkdir -p "$MODULE_CACHE_DIR"
export CLANG_MODULE_CACHE_PATH="$MODULE_CACHE_DIR"
export SWIFT_MODULECACHE_PATH="$MODULE_CACHE_DIR"

swift build -c release --product ClipboardMenu

BIN_DIR="$(swift build -c release --show-bin-path)"
EXECUTABLE_PATH="$BIN_DIR/ClipboardMenu"

if [[ ! -x "$EXECUTABLE_PATH" ]]; then
    echo "Release executable not found at $EXECUTABLE_PATH" >&2
    exit 1
fi

/bin/mkdir -p "$DIST_DIR"
/bin/rm -rf "$APP_DIR"
/bin/mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"
/bin/cp "$EXECUTABLE_PATH" "$MACOS_DIR/$APP_NAME"
/bin/chmod +x "$MACOS_DIR/$APP_NAME"

/bin/cat >"$CONTENTS_DIR/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
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
    <string>$SHORT_VERSION</string>
    <key>CFBundleVersion</key>
    <string>$BUILD_VERSION</string>
    <key>LSMinimumSystemVersion</key>
    <string>15.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

echo "App bundle created at: $APP_DIR"
