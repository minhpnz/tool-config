#!/bin/bash
set -e

APP_NAME="IPA Keyboard"
DMG_NAME="IPA_Keyboard.dmg"
INSTALL_DIR="/Applications"
GDRIVE_ID="1I44mKnL3hwI1sSn3gDGfUu6H9yItDKOy"
TMP_DMG="/tmp/$DMG_NAME"

B="\033[1m"
D="\033[2m"
G="\033[32m"
Y="\033[33m"
C="\033[36m"
R="\033[31m"
N="\033[0m"

clear
echo ""
echo -e "  ${C}============================================${N}"
echo ""
echo -e "  ${C}  ██╗██████╗  █████╗${N}"
echo -e "  ${C}  ██║██╔══██╗██╔══██╗${N}"
echo -e "  ${C}  ██║██████╔╝███████║${N}"
echo -e "  ${C}  ██║██╔═══╝ ██╔══██║${N}"
echo -e "  ${C}  ██║██║     ██║  ██║${N}"
echo -e "  ${C}  ╚═╝╚═╝     ╚═╝  ╚═╝${N}  ${B}K E Y B O A R D${N}"
echo ""
echo -e "  ${D}  Developed by Henry Phan${N}"
echo -e "  ${D}  Type IPA symbols with your keyboard${N}"
echo ""
echo -e "  ${C}============================================${N}"
echo ""
sleep 1

# -- Step 1 --
echo -e "  ${B}[1/5]${N} Checking for running instance..."
if pgrep -f "$APP_NAME" > /dev/null 2>&1; then
    echo -e "  ${Y}  >>${N}   Stopping running instance..."
    pkill -f "$APP_NAME" 2>/dev/null || true
    sleep 1
    echo -e "  ${G}  OK${N}   Stopped."
else
    echo -e "  ${G}  OK${N}   No running instance."
fi

# -- Step 2 --
echo ""
echo -e "  ${B}[2/5]${N} Downloading latest version..."
echo -e "  ${D}        This may take a moment...${N}"
COOKIES="/tmp/gdrive_cookies_$$"

curl -fsSL -c "$COOKIES" "https://drive.google.com/uc?export=download&id=$GDRIVE_ID" -o /tmp/gdrive_page.html
UUID=$(grep -o 'uuid=[^"&]*' /tmp/gdrive_page.html | head -1 | cut -d= -f2)
curl -fSL -b "$COOKIES" \
    "https://drive.usercontent.google.com/download?id=$GDRIVE_ID&export=download&confirm=t&uuid=$UUID" \
    -o "$TMP_DMG"
rm -f "$COOKIES" /tmp/gdrive_page.html

if head -c 100 "$TMP_DMG" | grep -qi "html"; then
    echo ""
    echo -e "  ${R}  !!${N}   Download failed."
    echo -e "  ${D}        Please check your internet connection and try again.${N}"
    rm -f "$TMP_DMG"
    exit 1
fi
echo -e "  ${G}  OK${N}   Downloaded successfully."

# -- Step 3 --
echo ""
echo -e "  ${B}[3/5]${N} Preparing installation..."
if [ -d "$INSTALL_DIR/$APP_NAME.app" ]; then
    echo -e "  ${Y}  >>${N}   Removing previous version..."
    rm -rf "$INSTALL_DIR/$APP_NAME.app"
    echo -e "  ${G}  OK${N}   Previous version removed."
else
    echo -e "  ${G}  OK${N}   Fresh install."
fi

# -- Step 4 --
echo ""
echo -e "  ${B}[4/5]${N} Installing to ${B}$INSTALL_DIR${N}..."
MOUNT_POINT=$(hdiutil attach "$TMP_DMG" -nobrowse -noverify | grep '/Volumes/' | sed 's/.*\(\/Volumes\/.*\)/\1/')
cp -R "$MOUNT_POINT/$APP_NAME.app" "$INSTALL_DIR/"
xattr -cr "$INSTALL_DIR/$APP_NAME.app"
hdiutil detach "$MOUNT_POINT" -quiet
rm -f "$TMP_DMG"
tccutil reset Accessibility com.minhphan.ipa-keyboard > /dev/null 2>&1 || true
echo -e "  ${G}  OK${N}   Installed."

# -- Step 5 --
echo ""
echo -e "  ${B}[5/5]${N} Launching ${B}$APP_NAME${N}..."
open -a "$APP_NAME"
sleep 2

echo ""
echo -e "  ${Y}--------------------------------------------${N}"
echo ""
echo -e "  ${Y}${B}  One more thing!${N}"
echo ""
echo -e "    A popup is asking for Accessibility"
echo -e "    permission. This lets IPA Keyboard"
echo -e "    read your keystrokes."
echo ""
echo -e "    ${B}1.${N} Click ${C}'Open System Settings'${N}"
echo -e "    ${B}2.${N} Toggle ${G}ON${N} next to ${B}'IPA Keyboard'${N}"
echo -e "    ${B}3.${N} That's it! It works ${B}immediately${N}"
echo ""
echo -e "  ${D}  No restart needed -- just toggle and go.${N}"
echo ""
echo -e "  ${Y}--------------------------------------------${N}"

echo ""
echo -e "  ${G}============================================${N}"
echo ""
echo -e "  ${G}${B}  Installation Complete!${N}"
echo ""
echo -e "  ${B}  How to use:${N}"
echo ""
echo -e "    ${C}Ctrl${N} + ${B}letter${N}    type IPA symbols"
echo -e "    ${C}Ctrl${N} + ${B}A${N}         ae -> open-a -> long-a"
echo -e "    ${C}Ctrl${N} + ${B}Space${N}     toggle on/off"
echo ""
echo -e "  ${D}  Look for the${N} ${B}IPA${N} ${D}icon in your menu bar.${N}"
echo ""
echo -e "  ${G}============================================${N}"
echo ""
