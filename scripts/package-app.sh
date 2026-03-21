#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

PRODUCT_NAME="codex-app-switcher"
APP_NAME="codex-app-switcher.app"
APP_DIR="$ROOT_DIR/dist/$APP_NAME"
BIN_DIR="$(swift build -c release --show-bin-path)"
BIN_PATH="$BIN_DIR/$PRODUCT_NAME"

rm -rf "$APP_DIR"
rm -f "$ROOT_DIR/dist/$PRODUCT_NAME"
mkdir -p "$APP_DIR/Contents/MacOS"

cp "$BIN_PATH" "$APP_DIR/Contents/MacOS/$PRODUCT_NAME"
chmod +x "$APP_DIR/Contents/MacOS/$PRODUCT_NAME"

cat > "$APP_DIR/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key>
  <string>codex-app-switcher</string>
  <key>CFBundleDisplayName</key>
  <string>CodexSwitcher</string>
  <key>CFBundleExecutable</key>
  <string>codex-app-switcher</string>
  <key>CFBundleIdentifier</key>
  <string>com.rfbz.codex-switcher.local</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
</dict>
</plist>
PLIST

echo "Built: $APP_DIR"
