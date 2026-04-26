#!/usr/bin/env bash
# ──────────────────────────────────────────────────────
#  build.sh — One-command build for MeetingRecap.app
#
#  Usage:
#    ./build.sh          Build the app
#    ./build.sh install  Build + copy to ~/Applications
#    ./build.sh run      Build + launch immediately
# ──────────────────────────────────────────────────────
set -euo pipefail
cd "$(dirname "$0")"

APP_NAME="MeetingRecap"
BUILD_DIR=".build"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
INSTALL_DIR="$HOME/Applications"
MODULE_CACHE_DIR="$(pwd)/$BUILD_DIR/module-cache"
DITTO="/usr/bin/ditto"

printf "🔧 Building %s...\n" "$APP_NAME"

if ! xcode-select -p >/dev/null 2>&1; then
    echo "❌ Xcode Command Line Tools required."
    echo "   Run: xcode-select --install"
    exit 1
fi

if ! command -v xcodegen >/dev/null 2>&1; then
    echo "❌ xcodegen is required."
    echo "   Install with: brew install xcodegen"
    exit 1
fi

printf "📦 Generating Xcode project with xcodegen...\n"
xcodegen generate --quiet

printf "🏗️  Building with xcodebuild...\n"
xcodebuild \
    -project "$APP_NAME.xcodeproj" \
    -scheme "$APP_NAME" \
    -configuration Release \
    -derivedDataPath "$BUILD_DIR/derived" \
    -quiet \
    CLANG_MODULE_CACHE_PATH="$MODULE_CACHE_DIR" \
    CODE_SIGN_IDENTITY="-" \
    CODE_SIGNING_ALLOWED=YES

BUILT_APP=$(find "$BUILD_DIR/derived" -name "$APP_NAME.app" -type d | head -1)
if [[ -z "$BUILT_APP" ]]; then
    echo "❌ Could not find built app bundle."
    exit 1
fi

mkdir -p "$BUILD_DIR"
rm -rf "$APP_BUNDLE"
"$DITTO" "$BUILT_APP" "$APP_BUNDLE"

codesign --verify --deep --strict --verbose=2 "$APP_BUNDLE"

printf "\n✅ Built: %s\n" "$APP_BUNDLE"

case "${1:-}" in
    install)
        mkdir -p "$INSTALL_DIR"
        rm -rf "$INSTALL_DIR/$APP_NAME.app"
        "$DITTO" "$APP_BUNDLE" "$INSTALL_DIR/$APP_NAME.app"
        printf "📂 Installed to %s/%s.app\n" "$INSTALL_DIR" "$APP_NAME"
        ;;
    run)
        printf "🚀 Launching...\n"
        open "$APP_BUNDLE"
        ;;
    *)
        echo ""
        echo "   ./build.sh install   → Copy to ~/Applications"
        echo "   ./build.sh run       → Launch now"
        ;;
esac
