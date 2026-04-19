#!/bin/bash
set -e

APP_NAME="IPA Keyboard"
APP_VERSION="0.1.0"
DMG_NAME="IPA_Keyboard.dmg"
INSTALL_DIR="/Applications"
GDRIVE_ID="1k0_2m-SVF9pr9Q8dSkxVqsM-sLR7gzeo"
TMP_DMG="/tmp/$DMG_NAME"
LOG_FILE="/tmp/ipa-keyboard-install.log"
DIAG_FILE="$HOME/Desktop/ipa-keyboard-diagnostic.txt"

B="\033[1m"
D="\033[2m"
G="\033[32m"
Y="\033[33m"
C="\033[36m"
R="\033[31m"
N="\033[0m"

# =============================================================================
# LOGGING FUNCTIONS
# =============================================================================

# Initialize log file with system info header
init_log() {
    cat > "$LOG_FILE" << EOF
================================================================================
IPA KEYBOARD INSTALLATION LOG
================================================================================
Timestamp:      $(date '+%Y-%m-%d %H:%M:%S %Z')
Installer Ver:  2.1.0
App Version:    $APP_VERSION
================================================================================

SYSTEM INFORMATION
------------------
macOS Version:  $(sw_vers -productVersion) ($(sw_vers -buildVersion))
Kernel:         $(uname -r)
Architecture:   $(uname -m)
CPU:            $(sysctl -n machdep.cpu.brand_string 2>/dev/null || echo 'unknown')
CPU Cores:      $(sysctl -n hw.ncpu 2>/dev/null || echo 'unknown')
Memory:         $(( $(sysctl -n hw.memsize 2>/dev/null || echo 0) / 1073741824 )) GB
Hostname:       $(hostname)
Username:       $(whoami)
Shell:          $SHELL
Terminal:       ${TERM_PROGRAM:-unknown}

SECURITY STATUS
---------------
SIP Status:     $(csrutil status 2>/dev/null | head -1 || echo 'unknown')
Gatekeeper:     $(spctl --status 2>/dev/null || echo 'unknown')

ACCESSIBILITY (before install)
------------------------------
EOF
    # Log current accessibility database entries for our app
    sqlite3 "/Library/Application Support/com.apple.TCC/TCC.db" \
        "SELECT service,client,allowed FROM access WHERE client LIKE '%ipa-keyboard%'" 2>/dev/null \
        >> "$LOG_FILE" || echo "Cannot read TCC database (expected)" >> "$LOG_FILE"

    echo "" >> "$LOG_FILE"
    echo "INSTALLATION STEPS" >> "$LOG_FILE"
    echo "------------------" >> "$LOG_FILE"
}

# Log a message with timestamp
log() {
    local level="$1"
    shift
    local msg="$*"
    local ts=$(date '+%H:%M:%S')
    echo "[$ts] [$level] $msg" >> "$LOG_FILE"
}

log_info()  { log "INFO" "$*"; }
log_warn()  { log "WARN" "$*"; }
log_error() { log "ERROR" "$*"; }
log_debug() { log "DEBUG" "$*"; }

# Log command output
log_cmd() {
    local cmd="$1"
    log_debug "Running: $cmd"
    echo "--- Command: $cmd ---" >> "$LOG_FILE"
    eval "$cmd" >> "$LOG_FILE" 2>&1 || true
    echo "--- End command ---" >> "$LOG_FILE"
}

# Generate diagnostic file for user to share
generate_diagnostic() {
    cat > "$DIAG_FILE" << EOF
================================================================================
IPA KEYBOARD DIAGNOSTIC REPORT
================================================================================
Generated:      $(date '+%Y-%m-%d %H:%M:%S %Z')
App Version:    $APP_VERSION

Please send this file to the developer for troubleshooting.

SYSTEM
------
macOS:          $(sw_vers -productVersion) ($(sw_vers -buildVersion))
Architecture:   $(uname -m)
CPU:            $(sysctl -n machdep.cpu.brand_string 2>/dev/null || echo 'unknown')

APP STATUS
----------
EOF

    if [ -d "$INSTALL_DIR/$APP_NAME.app" ]; then
        local bin="$INSTALL_DIR/$APP_NAME.app/Contents/MacOS/ipa-keyboard"
        echo "Installed:      Yes" >> "$DIAG_FILE"
        echo "Binary Size:    $(ls -lh "$bin" 2>/dev/null | awk '{print $5}')" >> "$DIAG_FILE"
        echo "Binary Arch:    $(lipo -info "$bin" 2>/dev/null | sed 's/.*: //')" >> "$DIAG_FILE"
        echo "Code Signed:    $(codesign -dv "$bin" 2>&1 | grep -o 'adhoc\|Developer ID' || echo 'unknown')" >> "$DIAG_FILE"
    else
        echo "Installed:      No" >> "$DIAG_FILE"
    fi

    if pgrep -f "ipa-keyboard" > /dev/null 2>&1; then
        echo "Running:        Yes (PID $(pgrep -f 'ipa-keyboard' | head -1))" >> "$DIAG_FILE"
    else
        echo "Running:        No" >> "$DIAG_FILE"
    fi

    echo "" >> "$DIAG_FILE"
    echo "ACCESSIBILITY" >> "$DIAG_FILE"
    echo "-------------" >> "$DIAG_FILE"

    # Check if app has accessibility
    if sqlite3 "/Library/Application Support/com.apple.TCC/TCC.db" \
        "SELECT allowed FROM access WHERE client='com.minhphan.ipa-keyboard' AND service='kTCCServiceAccessibility'" 2>/dev/null | grep -q "1"; then
        echo "Permission:     Granted" >> "$DIAG_FILE"
    else
        echo "Permission:     NOT granted (or cannot check)" >> "$DIAG_FILE"
    fi

    echo "" >> "$DIAG_FILE"
    echo "RECENT LOG" >> "$DIAG_FILE"
    echo "----------" >> "$DIAG_FILE"
    if [ -f "$LOG_FILE" ]; then
        tail -50 "$LOG_FILE" >> "$DIAG_FILE"
    else
        echo "(no log file found)" >> "$DIAG_FILE"
    fi

    echo "" >> "$DIAG_FILE"
    echo "APP CONSOLE OUTPUT (last 5 seconds)" >> "$DIAG_FILE"
    echo "------------------------------------" >> "$DIAG_FILE"

    # Capture app output briefly
    pkill -f "ipa-keyboard" 2>/dev/null || true
    sleep 1
    if [ -d "$INSTALL_DIR/$APP_NAME.app" ]; then
        "$INSTALL_DIR/$APP_NAME.app/Contents/MacOS/ipa-keyboard" 2>&1 &
        local pid=$!
        sleep 5
        kill $pid 2>/dev/null || true
        wait $pid 2>/dev/null || true
    fi >> "$DIAG_FILE" 2>&1

    echo "" >> "$DIAG_FILE"
    echo "=================================================================================" >> "$DIAG_FILE"
    echo "END OF DIAGNOSTIC REPORT" >> "$DIAG_FILE"
}

# =============================================================================
# MAIN INSTALLATION
# =============================================================================

# Initialize logging
init_log
log_info "Installation started"
log_info "Script location: $0"
log_info "Working directory: $(pwd)"

# Redirect stdout/stderr to both terminal and log
# Log output to file (without using exec/tee which can cause SIGPIPE)
# Instead, we'll log key events directly using log_* functions

# Clear screen only if interactive terminal
[ -t 1 ] && clear
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
echo -e "  ${D}  Version: ${APP_VERSION}${N}"
echo ""
echo -e "  ${C}============================================${N}"
echo ""
sleep 1

# -- System Info --
echo -e "  ${D}  macOS $(sw_vers -productVersion) | $(uname -m) | $(sysctl -n machdep.cpu.brand_string 2>/dev/null | cut -c1-40)${N}"
echo ""
log_info "System: macOS $(sw_vers -productVersion), $(uname -m)"

# -- Step 1: Check for running instance --
echo -e "  ${B}[1/6]${N} Checking for running instance..."
log_info "[Step 1] Checking for running instance"

# Kill any running IPA Keyboard app (match the actual binary path, not script)
# Use specific pattern to avoid killing this install script
APP_PATTERN="IPA Keyboard.app"
RUNNING_PIDS=$(pgrep -f "$APP_PATTERN" 2>/dev/null || echo "")

if [ -n "$RUNNING_PIDS" ]; then
    log_info "Found running instance(s): $RUNNING_PIDS"
    echo -e "  ${Y}  >>${N}   Stopping running instance..."

    # Kill gracefully first (use exact app name pattern)
    pkill -f "$APP_PATTERN" 2>/dev/null || true
    sleep 1

    # Check if still running, force kill if needed
    STILL_RUNNING=$(pgrep -f "$APP_PATTERN" 2>/dev/null || echo "")
    if [ -n "$STILL_RUNNING" ]; then
        log_warn "Process still running, sending SIGKILL..."
        pkill -9 -f "$APP_PATTERN" 2>/dev/null || true
        sleep 1
    fi

    # Final check
    FINAL_CHECK=$(pgrep -f "$APP_PATTERN" 2>/dev/null || echo "")
    if [ -n "$FINAL_CHECK" ]; then
        log_error "Could not stop running instance"
        echo -e "  ${R}  !!${N}   Could not stop running instance."
        echo -e "  ${D}        Please quit IPA Keyboard manually and try again.${N}"
        exit 1
    fi

    log_info "Instance stopped successfully"
    echo -e "  ${G}  OK${N}   Stopped."
else
    log_info "No running instance found"
    echo -e "  ${G}  OK${N}   No running instance."
fi

# -- Step 2: Download --
echo ""
echo -e "  ${B}[2/6]${N} Downloading latest version..."
echo -e "  ${D}        This may take a moment...${N}"
log_info "[Step 2] Starting download from Google Drive"
log_debug "GDRIVE_ID: $GDRIVE_ID"

COOKIES="/tmp/gdrive_cookies_$$"
DOWNLOAD_START=$(date +%s)

# First request to get the confirmation token
log_debug "Fetching confirmation page..."
curl -fsSL -c "$COOKIES" "https://drive.google.com/uc?export=download&id=$GDRIVE_ID" -o /tmp/gdrive_page.html 2>> "$LOG_FILE"
CURL_STATUS=$?
log_debug "Initial curl status: $CURL_STATUS"

UUID=$(grep -o 'uuid=[^"&]*' /tmp/gdrive_page.html 2>/dev/null | head -1 | cut -d= -f2 || echo "")
log_debug "UUID extracted: ${UUID:-none}"

# Download the actual file
log_debug "Downloading DMG..."
curl -fSL -b "$COOKIES" \
    "https://drive.usercontent.google.com/download?id=$GDRIVE_ID&export=download&confirm=t&uuid=$UUID" \
    -o "$TMP_DMG" 2>> "$LOG_FILE"
CURL_STATUS=$?
DOWNLOAD_END=$(date +%s)
DOWNLOAD_TIME=$((DOWNLOAD_END - DOWNLOAD_START))

log_debug "Download curl status: $CURL_STATUS"
log_info "Download completed in ${DOWNLOAD_TIME}s"

rm -f "$COOKIES" /tmp/gdrive_page.html

# Verify download
if [ ! -f "$TMP_DMG" ]; then
    log_error "DMG file not created"
    echo -e "  ${R}  !!${N}   Download failed - file not created."
    exit 1
fi

DMG_SIZE_BYTES=$(stat -f%z "$TMP_DMG" 2>/dev/null || echo 0)
log_debug "Downloaded file size: $DMG_SIZE_BYTES bytes"

if [ "$DMG_SIZE_BYTES" -lt 1000000 ]; then
    log_error "Downloaded file too small ($DMG_SIZE_BYTES bytes), likely an error page"
    log_cmd "head -c 500 $TMP_DMG"
    echo -e "  ${R}  !!${N}   Download failed - file too small."
    rm -f "$TMP_DMG"
    exit 1
fi

if head -c 100 "$TMP_DMG" | grep -qi "html"; then
    log_error "Downloaded file appears to be HTML (error page)"
    log_cmd "head -c 500 $TMP_DMG"
    echo ""
    echo -e "  ${R}  !!${N}   Download failed."
    echo -e "  ${D}        Please check your internet connection and try again.${N}"
    rm -f "$TMP_DMG"
    exit 1
fi

DMG_SIZE=$(ls -lh "$TMP_DMG" | awk '{print $5}')
log_info "Download verified: $DMG_SIZE"
echo -e "  ${G}  OK${N}   Downloaded. (${DMG_SIZE}, ${DOWNLOAD_TIME}s)"

# -- Step 3: Remove previous version and old variants --
echo ""
echo -e "  ${B}[3/6]${N} Preparing installation..."
log_info "[Step 3] Preparing installation directory"

# Clean up old app variants (development builds, renamed apps, etc.)
# This ensures a clean slate and prevents TCC confusion
OLD_VARIANTS=(
    "$INSTALL_DIR/$APP_NAME.app"
    "$INSTALL_DIR/ipa-keyboard.app"
    "$INSTALL_DIR/ipa-keyboard-prod.app"
    "$INSTALL_DIR/ipa-keyboard-dev.app"
    "$INSTALL_DIR/IPAKeyboard.app"
)

REMOVED_COUNT=0
for variant in "${OLD_VARIANTS[@]}"; do
    if [ -d "$variant" ]; then
        log_info "Found old variant: $variant, removing..."
        echo -e "  ${Y}  >>${N}   Removing $(basename "$variant")..."
        rm -rf "$variant"
        REMOVED_COUNT=$((REMOVED_COUNT + 1))
    fi
done

if [ $REMOVED_COUNT -gt 0 ]; then
    log_info "Removed $REMOVED_COUNT old app variant(s)"
    echo -e "  ${G}  OK${N}   Cleaned up $REMOVED_COUNT old version(s)."
else
    log_info "No previous version found, fresh install"
    echo -e "  ${G}  OK${N}   Fresh install."
fi

# Also reset full Accessibility TCC to clear any old entries with different bundle IDs
log_debug "Resetting Accessibility TCC for clean slate..."
tccutil reset Accessibility > /dev/null 2>&1 || true

# -- Step 4: Install --
echo ""
echo -e "  ${B}[4/6]${N} Installing to ${B}$INSTALL_DIR${N}..."
log_info "[Step 4] Installing application"

# Mount DMG
log_debug "Mounting DMG..."
MOUNT_OUTPUT=$(hdiutil attach "$TMP_DMG" -nobrowse -noverify 2>&1)
log_debug "Mount output: $MOUNT_OUTPUT"
MOUNT_POINT=$(echo "$MOUNT_OUTPUT" | grep '/Volumes/' | sed 's/.*\(\/Volumes\/.*\)/\1/')
log_debug "Mount point: $MOUNT_POINT"

if [ -z "$MOUNT_POINT" ] || [ ! -d "$MOUNT_POINT" ]; then
    log_error "Failed to mount DMG"
    echo -e "  ${R}  !!${N}   Failed to mount DMG."
    exit 1
fi

# Copy app
log_debug "Copying app to $INSTALL_DIR"
cp -R "$MOUNT_POINT/$APP_NAME.app" "$INSTALL_DIR/" 2>> "$LOG_FILE"
COPY_STATUS=$?
log_debug "Copy status: $COPY_STATUS"

# Remove quarantine attribute (critical for unsigned apps)
log_debug "Removing quarantine attribute..."
xattr -cr "$INSTALL_DIR/$APP_NAME.app" 2>> "$LOG_FILE"
XATTR_STATUS=$?
log_debug "xattr status: $XATTR_STATUS"

# Ad-hoc sign the app (required for proper TCC display name/icon)
log_debug "Ad-hoc signing the app..."
codesign --force --deep --sign - "$INSTALL_DIR/$APP_NAME.app" 2>> "$LOG_FILE" || true
log_debug "codesign completed"

# Cleanup
log_debug "Unmounting and cleaning up..."
hdiutil detach "$MOUNT_POINT" -quiet 2>> "$LOG_FILE" || true
rm -f "$TMP_DMG"

# Reset TCC for our specific bundle ID (full reset already done in step 3)
log_debug "Resetting TCC for com.minhphan.ipa-keyboard..."
tccutil reset Accessibility com.minhphan.ipa-keyboard > /dev/null 2>&1 || true

# Verify install
if [ -d "$INSTALL_DIR/$APP_NAME.app" ]; then
    BINARY="$INSTALL_DIR/$APP_NAME.app/Contents/MacOS/ipa-keyboard"
    if [ -f "$BINARY" ]; then
        ARCH=$(lipo -info "$BINARY" 2>/dev/null | sed 's/.*: //' || echo "unknown")
        BIN_SIZE=$(ls -lh "$BINARY" | awk '{print $5}')
        log_info "Installation verified: $BIN_SIZE, $ARCH"
        log_cmd "ls -la \"$BINARY\""
        log_cmd "codesign -dv \"$BINARY\""
        echo -e "  ${G}  OK${N}   Installed. (${BIN_SIZE}, ${ARCH})"
    else
        log_error "Binary not found after install"
        echo -e "  ${R}  !!${N}   Binary not found after install."
        exit 1
    fi
else
    log_error "App bundle not found after install"
    echo -e "  ${R}  !!${N}   Installation failed."
    exit 1
fi

# -- Step 5: Grant Accessibility --
echo ""
echo -e "  ${B}[5/6]${N} Granting Accessibility permission..."
log_info "[Step 5] Requesting accessibility permission"

echo ""
echo -e "    Launching app to trigger permission popup..."
log_debug "Opening app for first time..."
open -a "$APP_NAME" 2>> "$LOG_FILE"
OPEN_STATUS=$?
log_debug "open command status: $OPEN_STATUS"
sleep 3

# Check if it's running
if pgrep -f "ipa-keyboard" > /dev/null 2>&1; then
    log_info "App launched successfully for permission request"
else
    log_warn "App may not have launched (no process found)"
fi

echo ""
echo -e "  ${Y}--------------------------------------------${N}"
echo ""
echo -e "  ${Y}${B}  Accessibility Permission Required${N}"
echo ""
echo -e "    ${B}1.${N} Click ${C}'Open System Settings'${N} on the popup"
echo -e "    ${B}2.${N} Toggle ${G}ON${N} next to ${B}'IPA Keyboard'${N}"
echo -e "    ${B}3.${N} Come back here and press ${B}Enter${N}"
echo ""
echo -e "  ${Y}--------------------------------------------${N}"
echo ""

log_info "Waiting for user to grant permission..."
read -p "    Press Enter after granting permission... " _
log_info "User confirmed permission grant"

# -- Step 6: Restart app with permission --
echo ""
echo -e "  ${B}[6/6]${N} Restarting app with permission..."
log_info "[Step 6] Restarting app with new permissions"

log_debug "Stopping current instance..."
pkill -f "$APP_NAME" 2>/dev/null || true
sleep 1

log_debug "Launching fresh instance..."
open -a "$APP_NAME" 2>> "$LOG_FILE"
sleep 2

if pgrep -f "$APP_NAME" > /dev/null 2>&1; then
    APP_PID=$(pgrep -f "ipa-keyboard" | head -1)
    log_info "App running with PID: $APP_PID"
    echo -e "  ${G}  OK${N}   App is running. (PID: ${APP_PID})"

    # Capture initial app output
    log_debug "Capturing app startup log..."
    sleep 2
    log_cmd "ps aux | grep ipa-keyboard"
else
    log_error "App failed to launch after permission grant"
    echo -e "  ${R}  !!${N}   App failed to launch."
    echo -e "  ${D}        Try: open -a \"$APP_NAME\"${N}"

    # Generate diagnostic on failure
    log_info "Generating diagnostic file due to launch failure..."
    generate_diagnostic
    echo ""
    echo -e "  ${Y}  A diagnostic file has been created on your Desktop:${N}"
    echo -e "  ${D}  $DIAG_FILE${N}"
    exit 1
fi

# Final log entry
log_info "Installation completed successfully"
echo "" >> "$LOG_FILE"
echo "=================================================================================" >> "$LOG_FILE"
echo "INSTALLATION COMPLETED SUCCESSFULLY" >> "$LOG_FILE"
echo "Timestamp: $(date '+%Y-%m-%d %H:%M:%S %Z')" >> "$LOG_FILE"
echo "=================================================================================" >> "$LOG_FILE"

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
echo -e "  ${D}  Having trouble? Run this command:${N}"
echo -e "  ${D}  bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/minhpnz/tool-config/main/diagnose.sh)\"${N}"
echo ""
echo -e "  ${D}  Or send this file to the developer:${N}"
echo -e "  ${D}  ${LOG_FILE}${N}"
echo ""
