#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

PRODUCT_NAME="codex-app-switcher"
APP_NAME="codex-app-switcher.app"
APP_DIR="$ROOT_DIR/dist/$APP_NAME"
PROJECT_PATH="$ROOT_DIR/codex-app-switcher.xcodeproj"
SCHEME_NAME="codex-app-switcher"
TEMP_DIR="$(mktemp -d)"
DERIVED_DATA_DIR="$TEMP_DIR/DerivedData"
BUILT_APP_PATH="$DERIVED_DATA_DIR/Build/Products/Release/$APP_NAME"

cleanup() {
  rm -rf "$TEMP_DIR"
}

trap cleanup EXIT

if [[ ! -d "$PROJECT_PATH" ]]; then
  echo "Missing Xcode project: $PROJECT_PATH" >&2
  exit 1
fi

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

mkdir -p "$ROOT_DIR/dist"
cp -R "$BUILT_APP_PATH" "$APP_DIR"

echo "Built: $APP_DIR"
