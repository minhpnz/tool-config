#!/bin/bash
set -e

APP_NAME="IPA Keyboard"
DMG_NAME="IPA_Keyboard.dmg"
INSTALL_DIR="/Applications"
GDRIVE_ID="1I44mKnL3hwI1sSn3gDGfUu6H9yItDKOy"
TMP_DMG="/tmp/$DMG_NAME"

echo "==> Installing $APP_NAME..."

# Download from Google Drive
echo "==> Downloading..."
curl -fSL "https://drive.google.com/uc?export=download&id=$GDRIVE_ID" -o "$TMP_DMG"

# Check if we got a confirmation page (large file warning)
if head -c 100 "$TMP_DMG" | grep -q "html"; then
    CONFIRM=$(curl -fsSL "https://drive.google.com/uc?export=download&id=$GDRIVE_ID" | grep -o 'confirm=[^&]*' | head -1)
    curl -fSL "https://drive.google.com/uc?export=download&${CONFIRM}&id=$GDRIVE_ID" -o "$TMP_DMG"
fi

# Remove old installation
if [ -d "$INSTALL_DIR/$APP_NAME.app" ]; then
    echo "==> Removing old version..."
    rm -rf "$INSTALL_DIR/$APP_NAME.app"
fi

# Mount DMG
echo "==> Mounting DMG..."
MOUNT_POINT=$(hdiutil attach "$TMP_DMG" -nobrowse -noverify | grep '/Volumes/' | sed 's/.*\(\/Volumes\/.*\)/\1/')

# Copy app to Applications
echo "==> Installing to $INSTALL_DIR..."
cp -R "$MOUNT_POINT/$APP_NAME.app" "$INSTALL_DIR/"

# Remove quarantine attribute
xattr -cr "$INSTALL_DIR/$APP_NAME.app"

# Unmount DMG
echo "==> Cleaning up..."
hdiutil detach "$MOUNT_POINT" -quiet
rm -f "$TMP_DMG"

echo "==> $APP_NAME installed to $INSTALL_DIR."
echo ""
echo "NOTE: On first launch, grant Accessibility permission:"
echo "  System Settings → Privacy & Security → Accessibility → enable $APP_NAME"
echo ""
echo "To launch: open -a '$APP_NAME'"
