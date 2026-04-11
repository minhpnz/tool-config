#!/bin/bash
set -e

APP_NAME="IPA Keyboard"
DMG_NAME="IPA_Keyboard.dmg"
INSTALL_DIR="/Applications"
GDRIVE_ID="1I44mKnL3hwI1sSn3gDGfUu6H9yItDKOy"
TMP_DMG="/tmp/$DMG_NAME"

echo ""
echo "============================================"
echo "  IPA Keyboard Installer"
echo "============================================"
echo ""

# Kill running instance if any
if pgrep -f "$APP_NAME" > /dev/null 2>&1; then
    echo "[1/6] Stopping running instance of $APP_NAME..."
    pkill -f "$APP_NAME" 2>/dev/null || true
    sleep 1
    echo "       Done."
else
    echo "[1/6] No running instance found. Skipping."
fi

# Download from Google Drive
echo ""
echo "[2/6] Downloading $APP_NAME from server..."
echo "       This may take a minute depending on your internet speed."
COOKIES="/tmp/gdrive_cookies_$$"

curl -fsSL -c "$COOKIES" "https://drive.google.com/uc?export=download&id=$GDRIVE_ID" -o /tmp/gdrive_page.html

UUID=$(grep -o 'uuid=[^"&]*' /tmp/gdrive_page.html | head -1 | cut -d= -f2)

curl -fSL -b "$COOKIES" \
    "https://drive.usercontent.google.com/download?id=$GDRIVE_ID&export=download&confirm=t&uuid=$UUID" \
    -o "$TMP_DMG"

rm -f "$COOKIES" /tmp/gdrive_page.html

if head -c 100 "$TMP_DMG" | grep -qi "html"; then
    echo ""
    echo "ERROR: Download failed."
    echo "       The file could not be downloaded from Google Drive."
    echo "       Please check your internet connection and try again."
    rm -f "$TMP_DMG"
    exit 1
fi

echo "       Download complete."

# Remove old installation
echo ""
if [ -d "$INSTALL_DIR/$APP_NAME.app" ]; then
    echo "[3/6] Removing previous version of $APP_NAME..."
    rm -rf "$INSTALL_DIR/$APP_NAME.app"
    echo "       Previous version removed."
else
    echo "[3/6] No previous version found. Clean install."
fi

# Mount DMG and copy app
echo ""
echo "[4/6] Installing $APP_NAME to $INSTALL_DIR..."
MOUNT_POINT=$(hdiutil attach "$TMP_DMG" -nobrowse -noverify | grep '/Volumes/' | sed 's/.*\(\/Volumes\/.*\)/\1/')

cp -R "$MOUNT_POINT/$APP_NAME.app" "$INSTALL_DIR/"
xattr -cr "$INSTALL_DIR/$APP_NAME.app"

hdiutil detach "$MOUNT_POINT" -quiet
rm -f "$TMP_DMG"
echo "       $APP_NAME has been installed to $INSTALL_DIR."

# Reset old Accessibility entry to avoid duplicates
echo ""
echo "[5/6] Resetting Accessibility permission for clean setup..."
tccutil reset Accessibility com.minhphan.ipa-keyboard 2>/dev/null || true
echo "       Done."

# Launch the app
echo ""
echo "[6/6] Launching $APP_NAME..."
open -a "$APP_NAME"
echo "       $APP_NAME is now running."
echo "       If prompted, grant Accessibility permission and restart the app."
echo ""
echo "============================================"
echo "  Installation complete!"
echo ""
echo "  Shortcut: Ctrl + letter to type IPA symbols"
echo "  Toggle:   Ctrl + Space to turn on/off"
echo "============================================"
echo ""
