#!/usr/bin/env bash
set -euo pipefail

APP_PATH="${1:-.build/MeetingRecap.app}"

if [[ ! -d "$APP_PATH" ]]; then
  echo "App bundle not found: $APP_PATH" >&2
  exit 66
fi

PLIST="$APP_PATH/Contents/Info.plist"
EXECUTABLE="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$PLIST" 2>/dev/null || true)"
if [[ -z "$EXECUTABLE" ]]; then
  EXECUTABLE="$(basename "$APP_PATH" .app)"
fi

echo "Verifying code signature for $APP_PATH..."
codesign --verify --deep --strict --verbose=2 "$APP_PATH"

echo "Stopping any existing $EXECUTABLE process..."
osascript -e "tell application \"$EXECUTABLE\" to quit" >/dev/null 2>&1 || true
sleep 1

echo "Opening $APP_PATH..."
open "$APP_PATH"

for _ in {1..20}; do
  if pgrep -x "$EXECUTABLE" >/dev/null 2>&1; then
    echo "$EXECUTABLE launched successfully."
    osascript -e "tell application \"$EXECUTABLE\" to quit" >/dev/null 2>&1 || true
    exit 0
  fi

  sleep 0.5
done

echo "$EXECUTABLE did not stay running after launch." >&2
echo "If a macOS security prompt appeared, resolve it and rerun this smoke test." >&2
exit 67
