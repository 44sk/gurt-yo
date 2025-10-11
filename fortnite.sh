#!/usr/bin/env bash
set -euo pipefail

# --- Config ---
ZIP_URL="https://raw.githubusercontent.com/44sk/expert-disco/main/Warp%20Shield.zip"
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

# --- Final message ---
echo
echo "Thanks for downloading :)"
