#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

PRODUCT_NAME="codex-app-switcher"
APP_NAME="$PRODUCT_NAME.app"
APP_DIR="$ROOT_DIR/dist/$APP_NAME"
PROJECT_PATH="$ROOT_DIR/codex-app-switcher.xcodeproj"
SCHEME_NAME="$PRODUCT_NAME"
MIN_MACOS_VERSION="14.0"
TEMP_DIR="$(mktemp -d)"
DERIVED_DATA_DIR="$TEMP_DIR/DerivedData"
BUILT_APP_PATH="$DERIVED_DATA_DIR/Build/Products/Release/$APP_NAME"
ASSET_DIR="$ROOT_DIR/Sources/CodexAppSwitcher/Assets.xcassets/AppIcon.appiconset"

cleanup() {
  rm -rf "$TEMP_DIR"
}

trap cleanup EXIT

create_icns() {
  local iconset_dir="$TEMP_DIR/AppIcon.iconset"
  local icns_path="$APP_DIR/Contents/Resources/AppIcon.icns"

  mkdir -p "$iconset_dir"
  cp "$ASSET_DIR/icon_16x16.png" "$iconset_dir/icon_16x16.png"
  cp "$ASSET_DIR/icon_16x16@2x.png" "$iconset_dir/icon_16x16@2x.png"
  cp "$ASSET_DIR/icon_32x32.png" "$iconset_dir/icon_32x32.png"
  cp "$ASSET_DIR/icon_32x32@2x.png" "$iconset_dir/icon_32x32@2x.png"
  cp "$ASSET_DIR/icon_128x128.png" "$iconset_dir/icon_128x128.png"
  cp "$ASSET_DIR/icon_128x128@2x.png" "$iconset_dir/icon_128x128@2x.png"
  cp "$ASSET_DIR/icon_256x256.png" "$iconset_dir/icon_256x256.png"
  cp "$ASSET_DIR/icon_256x256@2x.png" "$iconset_dir/icon_256x256@2x.png"
  cp "$ASSET_DIR/icon_512x512.png" "$iconset_dir/icon_512x512.png"
  cp "$ASSET_DIR/icon_512x512@2x.png" "$iconset_dir/icon_512x512@2x.png"

  if command -v iconutil >/dev/null 2>&1; then
    iconutil -c icns "$iconset_dir" -o "$icns_path"
  fi
}

manual_build() {
  local sdk_path
  local executable_path="$APP_DIR/Contents/MacOS/$PRODUCT_NAME"

  sdk_path="$(xcrun --sdk macosx --show-sdk-path)"

  rm -rf "$APP_DIR"
  mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"

  xcrun swiftc \
    -sdk "$sdk_path" \
    -target "$(uname -m)-apple-macos${MIN_MACOS_VERSION}" \
    -DNO_PREVIEWS \
    -O \
    Sources/CodexAppSwitcher/*.swift \
    -o "$executable_path"

  create_icns

  cat > "$APP_DIR/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "https://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleDisplayName</key>
  <string>$PRODUCT_NAME</string>
  <key>CFBundleExecutable</key>
  <string>$PRODUCT_NAME</string>
  <key>CFBundleIconFile</key>
  <string>AppIcon</string>
  <key>CFBundleIdentifier</key>
  <string>com.rfbz.codex-app-switcher</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>$PRODUCT_NAME</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>1.0</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>LSApplicationCategoryType</key>
  <string>public.app-category.developer-tools</string>
  <key>LSMinimumSystemVersion</key>
  <string>$MIN_MACOS_VERSION</string>
  <key>NSHighResolutionCapable</key>
  <true/>
</dict>
</plist>
EOF
}

if [[ ! -d "$PROJECT_PATH" ]]; then
  echo "Missing Xcode project: $PROJECT_PATH" >&2
  exit 1
fi

mkdir -p "$ROOT_DIR/dist"

if xcodebuild -version >/dev/null 2>&1; then
  rm -rf "$APP_DIR"

  xcodebuild \
    -project "$PROJECT_PATH" \
    -scheme "$SCHEME_NAME" \
    -configuration Release \
    -derivedDataPath "$DERIVED_DATA_DIR" \
    -quiet \
    build

  if [[ ! -d "$BUILT_APP_PATH" ]]; then
    echo "Build succeeded but app bundle was not found at: $BUILT_APP_PATH" >&2
    exit 1
  fi

  cp -R "$BUILT_APP_PATH" "$APP_DIR"
else
  echo "xcodebuild is unavailable; falling back to swiftc bundle packaging." >&2
  manual_build
fi

echo "Built: $APP_DIR"
