#!/bin/bash
set -e

APP_NAME="IPA Keyboard"
DMG_NAME="IPA_Keyboard.dmg"
INSTALL_DIR="/Applications"
GDRIVE_ID="1I44mKnL3hwI1sSn3gDGfUu6H9yItDKOy"
TMP_DMG="/tmp/$DMG_NAME"

# ── Colors ──
BOLD="\033[1m"
DIM="\033[2m"
GREEN="\033[32m"
YELLOW="\033[33m"
CYAN="\033[36m"
RED="\033[31m"
RESET="\033[0m"

clear
echo ""
echo -e "  ${BOLD}╔══════════════════════════════════════════════════╗${RESET}"
echo -e "  ${BOLD}║                                                  ║${RESET}"
echo -e "  ${BOLD}║${RESET}   ${CYAN}██╗${RESET}${CYAN}██████╗ ${RESET}${CYAN} █████╗ ${RESET}                           ${BOLD}║${RESET}"
echo -e "  ${BOLD}║${RESET}   ${CYAN}██║${RESET}${CYAN}██╔══██╗${RESET}${CYAN}██╔══██╗${RESET}                           ${BOLD}║${RESET}"
echo -e "  ${BOLD}║${RESET}   ${CYAN}██║${RESET}${CYAN}██████╔╝${RESET}${CYAN}███████║${RESET}                           ${BOLD}║${RESET}"
echo -e "  ${BOLD}║${RESET}   ${CYAN}██║${RESET}${CYAN}██╔═══╝ ${RESET}${CYAN}██╔══██║${RESET}                           ${BOLD}║${RESET}"
echo -e "  ${BOLD}║${RESET}   ${CYAN}██║${RESET}${CYAN}██║     ${RESET}${CYAN}██║  ██║${RESET}                           ${BOLD}║${RESET}"
echo -e "  ${BOLD}║${RESET}   ${CYAN}╚═╝${RESET}${CYAN}╚═╝     ${RESET}${CYAN}╚═╝  ╚═╝${RESET}  ${BOLD}K E Y B O A R D${RESET}       ${BOLD}║${RESET}"
echo -e "  ${BOLD}║                                                  ║${RESET}"
echo -e "  ${BOLD}║${RESET}   ${DIM}Developed by Henry Phan${RESET}                          ${BOLD}║${RESET}"
echo -e "  ${BOLD}║${RESET}   ${DIM}Type IPA symbols with your keyboard${RESET}              ${BOLD}║${RESET}"
echo -e "  ${BOLD}║                                                  ║${RESET}"
echo -e "  ${BOLD}╚══════════════════════════════════════════════════╝${RESET}"
echo ""
sleep 1

# ── Step 1: Stop running instance ──
echo -e "  ${BOLD}[1/5]${RESET} Checking for running instance..."
if pgrep -f "$APP_NAME" > /dev/null 2>&1; then
    echo -e "  ${YELLOW}►${RESET}  Stopping running instance..."
    pkill -f "$APP_NAME" 2>/dev/null || true
    sleep 1
    echo -e "  ${GREEN}✓${RESET}  Stopped."
else
    echo -e "  ${GREEN}✓${RESET}  No running instance."
fi

# ── Step 2: Download ──
echo ""
echo -e "  ${BOLD}[2/5]${RESET} Downloading latest version..."
echo -e "  ${DIM}     This may take a moment...${RESET}"
COOKIES="/tmp/gdrive_cookies_$$"

curl -fsSL -c "$COOKIES" "https://drive.google.com/uc?export=download&id=$GDRIVE_ID" -o /tmp/gdrive_page.html
UUID=$(grep -o 'uuid=[^"&]*' /tmp/gdrive_page.html | head -1 | cut -d= -f2)
curl -fSL -b "$COOKIES" \
    "https://drive.usercontent.google.com/download?id=$GDRIVE_ID&export=download&confirm=t&uuid=$UUID" \
    -o "$TMP_DMG"
rm -f "$COOKIES" /tmp/gdrive_page.html

if head -c 100 "$TMP_DMG" | grep -qi "html"; then
    echo ""
    echo -e "  ${RED}✗  Download failed.${RESET}"
    echo -e "  ${DIM}     Please check your internet connection and try again.${RESET}"
    rm -f "$TMP_DMG"
    exit 1
fi
echo -e "  ${GREEN}✓${RESET}  Downloaded successfully."

# ── Step 3: Remove old version ──
echo ""
echo -e "  ${BOLD}[3/5]${RESET} Preparing installation..."
if [ -d "$INSTALL_DIR/$APP_NAME.app" ]; then
    echo -e "  ${YELLOW}►${RESET}  Removing previous version..."
    rm -rf "$INSTALL_DIR/$APP_NAME.app"
    echo -e "  ${GREEN}✓${RESET}  Previous version removed."
else
    echo -e "  ${GREEN}✓${RESET}  Fresh install — no previous version found."
fi

# ── Step 4: Install ──
echo ""
echo -e "  ${BOLD}[4/5]${RESET} Installing to ${BOLD}$INSTALL_DIR${RESET}..."
MOUNT_POINT=$(hdiutil attach "$TMP_DMG" -nobrowse -noverify | grep '/Volumes/' | sed 's/.*\(\/Volumes\/.*\)/\1/')
cp -R "$MOUNT_POINT/$APP_NAME.app" "$INSTALL_DIR/"
xattr -cr "$INSTALL_DIR/$APP_NAME.app"
hdiutil detach "$MOUNT_POINT" -quiet
rm -f "$TMP_DMG"
tccutil reset Accessibility com.minhphan.ipa-keyboard > /dev/null 2>&1 || true
echo -e "  ${GREEN}✓${RESET}  Installed."

# ── Step 5: Launch & Accessibility ──
echo ""
echo -e "  ${BOLD}[5/5]${RESET} Launching ${BOLD}$APP_NAME${RESET}..."
open -a "$APP_NAME"
sleep 2

echo ""
echo -e "  ┌────────────────────────────────────────────────────┐"
echo -e "  │                                                    │"
echo -e "  │   ${YELLOW}${BOLD}One more thing!${RESET}                                   │"
echo -e "  │                                                    │"
echo -e "  │   A popup is asking for Accessibility permission.  │"
echo -e "  │   This lets IPA Keyboard read your keystrokes.     │"
echo -e "  │                                                    │"
echo -e "  │   ${BOLD}1.${RESET} Click ${CYAN}\"Open System Settings\"${RESET} on the popup      │"
echo -e "  │   ${BOLD}2.${RESET} Toggle ${GREEN}ON${RESET} next to ${BOLD}\"IPA Keyboard\"${RESET}              │"
echo -e "  │   ${BOLD}3.${RESET} That's it! It works ${BOLD}immediately${RESET}               │"
echo -e "  │                                                    │"
echo -e "  │   ${DIM}No restart needed — just toggle and go.${RESET}         │"
echo -e "  │                                                    │"
echo -e "  └────────────────────────────────────────────────────┘"

echo ""
echo -e "  ${BOLD}╔══════════════════════════════════════════════════╗${RESET}"
echo -e "  ${BOLD}║                                                  ║${RESET}"
echo -e "  ${BOLD}║${RESET}   ${GREEN}${BOLD}Installation Complete!${RESET}                            ${BOLD}║${RESET}"
echo -e "  ${BOLD}║                                                  ║${RESET}"
echo -e "  ${BOLD}║${RESET}   ${BOLD}How to use:${RESET}                                       ${BOLD}║${RESET}"
echo -e "  ${BOLD}║                                                  ║${RESET}"
echo -e "  ${BOLD}║${RESET}   ${CYAN}Ctrl${RESET} + ${BOLD}letter${RESET}     type IPA symbols              ${BOLD}║${RESET}"
echo -e "  ${BOLD}║${RESET}   ${CYAN}Ctrl${RESET} + ${BOLD}A${RESET}          ${DIM}æ → ɑ → ɑː → ʌ${RESET}                ${BOLD}║${RESET}"
echo -e "  ${BOLD}║${RESET}   ${CYAN}Ctrl${RESET} + ${BOLD}Space${RESET}      toggle on/off                 ${BOLD}║${RESET}"
echo -e "  ${BOLD}║                                                  ║${RESET}"
echo -e "  ${BOLD}║${RESET}   ${DIM}Look for the${RESET} ${BOLD}IPA${RESET} ${DIM}icon in your menu bar.${RESET}          ${BOLD}║${RESET}"
echo -e "  ${BOLD}║                                                  ║${RESET}"
echo -e "  ${BOLD}╚══════════════════════════════════════════════════╝${RESET}"
echo ""
