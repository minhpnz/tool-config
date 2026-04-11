#!/bin/bash
set -e

APP_NAME="IPA Keyboard"
DMG_NAME="IPA_Keyboard.dmg"
INSTALL_DIR="/Applications"
GDRIVE_ID="1I44mKnL3hwI1sSn3gDGfUu6H9yItDKOy"
TMP_DMG="/tmp/$DMG_NAME"

clear
echo ""
echo "  =========================================="
echo ""
echo "    ___ ____   _"
echo "   |_ _|  _ \ / \\"
echo "    | || |_) / _ \\"
echo "    | ||  __/ ___ \\    K E Y B O A R D"
echo "   |___|_| /_/   \_\\"
echo ""
echo "    Developed by Henry Phan"
echo "    Type IPA symbols with your keyboard"
echo ""
echo "  =========================================="
echo ""
sleep 1

# -- Step 1 --
echo "  [1/5] Checking for running instance..."
if pgrep -f "$APP_NAME" > /dev/null 2>&1; then
    echo "         Stopping running instance..."
    pkill -f "$APP_NAME" 2>/dev/null || true
    sleep 1
    echo "    OK   Stopped."
else
    echo "    OK   No running instance."
fi

# -- Step 2 --
echo ""
echo "  [2/5] Downloading latest version..."
echo "         This may take a moment..."
COOKIES="/tmp/gdrive_cookies_$$"

curl -fsSL -c "$COOKIES" "https://drive.google.com/uc?export=download&id=$GDRIVE_ID" -o /tmp/gdrive_page.html
UUID=$(grep -o 'uuid=[^"&]*' /tmp/gdrive_page.html | head -1 | cut -d= -f2)
curl -fSL -b "$COOKIES" \
    "https://drive.usercontent.google.com/download?id=$GDRIVE_ID&export=download&confirm=t&uuid=$UUID" \
    -o "$TMP_DMG"
rm -f "$COOKIES" /tmp/gdrive_page.html

if head -c 100 "$TMP_DMG" | grep -qi "html"; then
    echo ""
    echo "    !!   Download failed."
    echo "         Please check your internet connection and try again."
    rm -f "$TMP_DMG"
    exit 1
fi
echo "    OK   Downloaded successfully."

# -- Step 3 --
echo ""
echo "  [3/5] Preparing installation..."
if [ -d "$INSTALL_DIR/$APP_NAME.app" ]; then
    echo "         Removing previous version..."
    rm -rf "$INSTALL_DIR/$APP_NAME.app"
    echo "    OK   Previous version removed."
else
    echo "    OK   Fresh install."
fi

# -- Step 4 --
echo ""
echo "  [4/5] Installing to $INSTALL_DIR..."
MOUNT_POINT=$(hdiutil attach "$TMP_DMG" -nobrowse -noverify | grep '/Volumes/' | sed 's/.*\(\/Volumes\/.*\)/\1/')
cp -R "$MOUNT_POINT/$APP_NAME.app" "$INSTALL_DIR/"
xattr -cr "$INSTALL_DIR/$APP_NAME.app"
hdiutil detach "$MOUNT_POINT" -quiet
rm -f "$TMP_DMG"
tccutil reset Accessibility com.minhphan.ipa-keyboard > /dev/null 2>&1 || true
echo "    OK   Installed."

# -- Step 5 --
echo ""
echo "  [5/5] Launching $APP_NAME..."
open -a "$APP_NAME"
sleep 2

echo ""
echo "  ------------------------------------------"
echo ""
echo "    One more thing!"
echo ""
echo "    A popup is asking for Accessibility"
echo "    permission. This lets IPA Keyboard"
echo "    read your keystrokes."
echo ""
echo "    1. Click 'Open System Settings'"
echo "    2. Toggle ON next to 'IPA Keyboard'"
echo "    3. That's it! It works immediately"
echo ""
echo "    No restart needed -- just toggle and go."
echo ""
echo "  ------------------------------------------"

echo ""
echo "  =========================================="
echo ""
echo "    Installation Complete!"
echo ""
echo "    How to use:"
echo ""
echo "    Ctrl + letter    type IPA symbols"
echo "    Ctrl + A         a -> ae -> open-a"
echo "    Ctrl + Space     toggle on/off"
echo ""
echo "    Look for the IPA icon in your menu bar."
echo ""
echo "  =========================================="
echo ""
