#!/bin/bash
set -e

APP_NAME="IPA Keyboard"
DMG_NAME="IPA_Keyboard.dmg"
INSTALL_DIR="/Applications"
GDRIVE_ID="1I44mKnL3hwI1sSn3gDGfUu6H9yItDKOy"
TMP_DMG="/tmp/$DMG_NAME"

echo ""
echo "  ╔══════════════════════════════════════════════╗"
echo "  ║                                              ║"
echo "  ║   ██╗██████╗  █████╗                         ║"
echo "  ║   ██║██╔══██╗██╔══██╗                        ║"
echo "  ║   ██║██████╔╝███████║                        ║"
echo "  ║   ██║██╔═══╝ ██╔══██║                        ║"
echo "  ║   ██║██║     ██║  ██║                        ║"
echo "  ║   ╚═╝╚═╝     ╚═╝  ╚═╝  K E Y B O A R D     ║"
echo "  ║                                              ║"
echo "  ║          Developed by Henry Phan             ║"
echo "  ║   Type IPA symbols with your keyboard ✦     ║"
echo "  ║                                              ║"
echo "  ╚══════════════════════════════════════════════╝"
echo ""

# ① Stop running instance
if pgrep -f "$APP_NAME" > /dev/null 2>&1; then
    echo "  ⏹  Stopping running instance..."
    pkill -f "$APP_NAME" 2>/dev/null || true
    sleep 1
    echo "     Done."
else
    echo "  ✓  No running instance detected."
fi

# ② Download
echo ""
echo "  📦  Downloading latest version..."
COOKIES="/tmp/gdrive_cookies_$$"

curl -fsSL -c "$COOKIES" "https://drive.google.com/uc?export=download&id=$GDRIVE_ID" -o /tmp/gdrive_page.html
UUID=$(grep -o 'uuid=[^"&]*' /tmp/gdrive_page.html | head -1 | cut -d= -f2)
curl -fSL -b "$COOKIES" \
    "https://drive.usercontent.google.com/download?id=$GDRIVE_ID&export=download&confirm=t&uuid=$UUID" \
    -o "$TMP_DMG"
rm -f "$COOKIES" /tmp/gdrive_page.html

if head -c 100 "$TMP_DMG" | grep -qi "html"; then
    echo ""
    echo "  ✗  Download failed. Please check your internet connection."
    rm -f "$TMP_DMG"
    exit 1
fi
echo "     Done."

# ③ Remove old version
echo ""
if [ -d "$INSTALL_DIR/$APP_NAME.app" ]; then
    echo "  🗑  Removing previous version..."
    rm -rf "$INSTALL_DIR/$APP_NAME.app"
    echo "     Done."
else
    echo "  ✓  No previous version — clean install."
fi

# ④ Install
echo ""
echo "  📲  Installing to $INSTALL_DIR..."
MOUNT_POINT=$(hdiutil attach "$TMP_DMG" -nobrowse -noverify | grep '/Volumes/' | sed 's/.*\(\/Volumes\/.*\)/\1/')
cp -R "$MOUNT_POINT/$APP_NAME.app" "$INSTALL_DIR/"
xattr -cr "$INSTALL_DIR/$APP_NAME.app"
hdiutil detach "$MOUNT_POINT" -quiet
rm -f "$TMP_DMG"
echo "     Done."

# ⑤ Reset Accessibility (clean slate)
echo ""
echo "  🔐  Preparing permissions..."
tccutil reset Accessibility com.minhphan.ipa-keyboard > /dev/null 2>&1 || true
echo "     Done."

# ⑥ Launch and wait for Accessibility, then restart
echo ""
echo "  🚀  Launching $APP_NAME..."
open -a "$APP_NAME"
sleep 3

echo ""
echo "  ┌──────────────────────────────────────────────┐"
echo "  │  🔓  Accessibility Permission Required       │"
echo "  │                                              │"
echo "  │  A popup should have appeared.               │"
echo "  │                                              │"
echo "  │  1. Click 'Open System Settings' on popup    │"
echo "  │  2. Toggle ON 'IPA Keyboard'                 │"
echo "  │  3. Come back here and press Enter           │"
echo "  │                                              │"
echo "  └──────────────────────────────────────────────┘"
echo ""
read -p "  ✋  Press Enter after granting permission... " _
echo ""
echo "  🔄  Restarting $APP_NAME..."
pkill -f "$APP_NAME" 2>/dev/null || true
sleep 1
open -a "$APP_NAME"
sleep 2
echo "     $APP_NAME is ready!"

echo ""
echo "  ╔══════════════════════════════════════════════╗"
echo "  ║                                              ║"
echo "  ║   ✅  Installation Complete!                 ║"
echo "  ║                                              ║"
echo "  ║   Ctrl + letter   →  type IPA symbols        ║"
echo "  ║   Ctrl + A        →  æ → ɑ → ɑː → ʌ        ║"
echo "  ║   Ctrl + Space    →  toggle on/off           ║"
echo "  ║                                              ║"
echo "  ║   Enjoy! 🎉                                  ║"
echo "  ║                                              ║"
echo "  ╚══════════════════════════════════════════════╝"
echo ""
