#!/bin/bash
set -e

APP_NAME="IPA Keyboard"
DMG_NAME="IPA_Keyboard.dmg"
INSTALL_DIR="/Applications"
GDRIVE_ID="1I44mKnL3hwI1sSn3gDGfUu6H9yItDKOy"
TMP_DMG="/tmp/$DMG_NAME"

# ── Colors ──
B="\033[1m"
D="\033[2m"
G="\033[32m"
Y="\033[33m"
C="\033[36m"
R="\033[31m"
N="\033[0m"

clear
echo ""
echo "  ╔════════════════════════════════════════════╗"
echo "  ║                                            ║"
echo "  ║   ██╗██████╗  █████╗                       ║"
echo "  ║   ██║██╔══██╗██╔══██╗                      ║"
echo "  ║   ██║██████╔╝███████║                       ║"
echo "  ║   ██║██╔═══╝ ██╔══██║                       ║"
echo "  ║   ██║██║     ██║  ██║                       ║"
echo "  ║   ╚═╝╚═╝     ╚═╝  ╚═╝  K E Y B O A R D    ║"
echo "  ║                                            ║"
echo "  ║   Developed by Henry Phan                  ║"
echo "  ║   Type IPA symbols with your keyboard      ║"
echo "  ║                                            ║"
echo "  ╚════════════════════════════════════════════╝"
echo ""
sleep 1

# ── Step 1: Stop running instance ──
echo -e "  ${B}[1/5]${N} Checking for running instance..."
if pgrep -f "$APP_NAME" > /dev/null 2>&1; then
    echo -e "        Stopping running instance..."
    pkill -f "$APP_NAME" 2>/dev/null || true
    sleep 1
    echo -e "  ${G}  ✓   Stopped.${N}"
else
    echo -e "  ${G}  ✓   No running instance.${N}"
fi

# ── Step 2: Download ──
echo ""
echo -e "  ${B}[2/5]${N} Downloading latest version..."
echo -e "  ${D}      This may take a moment...${N}"
COOKIES="/tmp/gdrive_cookies_$$"

curl -fsSL -c "$COOKIES" "https://drive.google.com/uc?export=download&id=$GDRIVE_ID" -o /tmp/gdrive_page.html
UUID=$(grep -o 'uuid=[^"&]*' /tmp/gdrive_page.html | head -1 | cut -d= -f2)
curl -fSL -b "$COOKIES" \
    "https://drive.usercontent.google.com/download?id=$GDRIVE_ID&export=download&confirm=t&uuid=$UUID" \
    -o "$TMP_DMG"
rm -f "$COOKIES" /tmp/gdrive_page.html

if head -c 100 "$TMP_DMG" | grep -qi "html"; then
    echo ""
    echo -e "  ${R}  ✗   Download failed.${N}"
    echo -e "  ${D}      Please check your internet connection and try again.${N}"
    rm -f "$TMP_DMG"
    exit 1
fi
echo -e "  ${G}  ✓   Downloaded successfully.${N}"

# ── Step 3: Remove old version ──
echo ""
echo -e "  ${B}[3/5]${N} Preparing installation..."
if [ -d "$INSTALL_DIR/$APP_NAME.app" ]; then
    echo -e "        Removing previous version..."
    rm -rf "$INSTALL_DIR/$APP_NAME.app"
    echo -e "  ${G}  ✓   Previous version removed.${N}"
else
    echo -e "  ${G}  ✓   Fresh install.${N}"
fi

# ── Step 4: Install ──
echo ""
echo -e "  ${B}[4/5]${N} Installing to $INSTALL_DIR..."
MOUNT_POINT=$(hdiutil attach "$TMP_DMG" -nobrowse -noverify | grep '/Volumes/' | sed 's/.*\(\/Volumes\/.*\)/\1/')
cp -R "$MOUNT_POINT/$APP_NAME.app" "$INSTALL_DIR/"
xattr -cr "$INSTALL_DIR/$APP_NAME.app"
hdiutil detach "$MOUNT_POINT" -quiet
rm -f "$TMP_DMG"
tccutil reset Accessibility com.minhphan.ipa-keyboard > /dev/null 2>&1 || true
echo -e "  ${G}  ✓   Installed.${N}"

# ── Step 5: Launch & Accessibility ──
echo ""
echo -e "  ${B}[5/5]${N} Launching $APP_NAME..."
open -a "$APP_NAME"
sleep 2

echo ""
echo "  ┌────────────────────────────────────────────┐"
echo "  │                                            │"
echo "  │   One more thing!                          │"
echo "  │                                            │"
echo "  │   A popup is asking for Accessibility      │"
echo "  │   permission. This lets IPA Keyboard       │"
echo "  │   read your keystrokes.                    │"
echo "  │                                            │"
echo "  │   1. Click 'Open System Settings'          │"
echo "  │   2. Toggle ON next to 'IPA Keyboard'      │"
echo "  │   3. That's it! It works immediately       │"
echo "  │                                            │"
echo "  │   No restart needed — just toggle and go.  │"
echo "  │                                            │"
echo "  └────────────────────────────────────────────┘"

echo ""
echo "  ╔════════════════════════════════════════════╗"
echo "  ║                                            ║"
echo "  ║   Installation Complete!                   ║"
echo "  ║                                            ║"
echo "  ║   How to use:                              ║"
echo "  ║                                            ║"
echo "  ║   Ctrl + letter    type IPA symbols        ║"
echo "  ║   Ctrl + A         æ → ɑ → ɑː → ʌ        ║"
echo "  ║   Ctrl + Space     toggle on/off           ║"
echo "  ║                                            ║"
echo "  ║   Look for the IPA icon in your menu bar.  ║"
echo "  ║                                            ║"
echo "  ╚════════════════════════════════════════════╝"
echo ""
