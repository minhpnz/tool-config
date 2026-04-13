#!/bin/bash
# =============================================================================
# IPA Keyboard - Diagnostic Tool
# Run this if you're having issues with IPA Keyboard
# =============================================================================

APP_NAME="IPA Keyboard"
INSTALL_DIR="/Applications"
LOG_FILE="/tmp/ipa-keyboard-install.log"
DIAG_OUTPUT="/tmp/ipa-keyboard-diagnostic.txt"

C="\033[36m"
G="\033[32m"
Y="\033[33m"
R="\033[31m"
B="\033[1m"
D="\033[2m"
N="\033[0m"

# Start diagnostic
echo ""
echo -e "  ${C}============================================${N}"
echo ""
echo -e "  ${C}${B}IPA Keyboard - Diagnostic Tool${N}"
echo ""
echo -e "  ${C}============================================${N}"
echo ""

# Create diagnostic file
{
    echo "================================================================================"
    echo "IPA KEYBOARD DIAGNOSTIC REPORT"
    echo "================================================================================"
    echo ""
    echo "Generated:      $(date '+%Y-%m-%d %H:%M:%S %Z')"
    echo "Tool Version:   2.0.0"
    echo ""
    echo "PLEASE SEND THIS OUTPUT TO THE DEVELOPER FOR TROUBLESHOOTING"
    echo ""
    echo "================================================================================"
    echo "SYSTEM INFORMATION"
    echo "================================================================================"
    echo ""
    echo "macOS Version:  $(sw_vers -productVersion) (Build $(sw_vers -buildVersion))"
    echo "Kernel:         $(uname -r)"
    echo "Architecture:   $(uname -m)"
    echo "CPU:            $(sysctl -n machdep.cpu.brand_string 2>/dev/null || echo 'unknown')"
    echo "Memory:         $(( $(sysctl -n hw.memsize 2>/dev/null || echo 0) / 1073741824 )) GB"
    echo "Hostname:       $(hostname)"
    echo "Username:       $(whoami)"
    echo ""
    echo "Security:"
    echo "  SIP:          $(csrutil status 2>/dev/null | head -1 || echo 'unknown')"
    echo "  Gatekeeper:   $(spctl --status 2>/dev/null || echo 'unknown')"
    echo ""
} > "$DIAG_OUTPUT"

# Display system info
echo -e "  ${B}System:${N}"
echo -e "    macOS:    $(sw_vers -productVersion) ($(sw_vers -buildVersion))"
echo -e "    Arch:     $(uname -m)"
echo -e "    CPU:      $(sysctl -n machdep.cpu.brand_string 2>/dev/null | cut -c1-40)"
echo ""

# Check installation
{
    echo "================================================================================"
    echo "APPLICATION STATUS"
    echo "================================================================================"
    echo ""
} >> "$DIAG_OUTPUT"

echo -e "  ${B}App Status:${N}"

if [ -d "$INSTALL_DIR/$APP_NAME.app" ]; then
    BIN="$INSTALL_DIR/$APP_NAME.app/Contents/MacOS/ipa-keyboard"

    echo -e "    ${G}Installed${N}"
    echo "Installed:      YES" >> "$DIAG_OUTPUT"
    echo "Location:       $INSTALL_DIR/$APP_NAME.app" >> "$DIAG_OUTPUT"

    if [ -f "$BIN" ]; then
        SIZE=$(ls -lh "$BIN" 2>/dev/null | awk '{print $5}')
        ARCH=$(lipo -info "$BIN" 2>/dev/null | sed 's/.*: //' || echo "unknown")
        SIGN=$(codesign -dv "$BIN" 2>&1 | grep -E "Signature|Authority" | head -2 || echo "adhoc/unsigned")

        echo -e "    Size:     $SIZE"
        echo -e "    Arch:     $ARCH"

        echo "" >> "$DIAG_OUTPUT"
        echo "Binary Details:" >> "$DIAG_OUTPUT"
        echo "  Size:         $SIZE" >> "$DIAG_OUTPUT"
        echo "  Architecture: $ARCH" >> "$DIAG_OUTPUT"
        echo "  Signing:" >> "$DIAG_OUTPUT"
        codesign -dv --verbose=2 "$BIN" 2>&1 | head -10 >> "$DIAG_OUTPUT"
        echo "" >> "$DIAG_OUTPUT"
        echo "  File info:" >> "$DIAG_OUTPUT"
        ls -la "$BIN" >> "$DIAG_OUTPUT"
        echo "" >> "$DIAG_OUTPUT"
        echo "  Extended attrs:" >> "$DIAG_OUTPUT"
        xattr -l "$BIN" 2>&1 >> "$DIAG_OUTPUT" || echo "  (none)" >> "$DIAG_OUTPUT"
    else
        echo -e "    ${R}Binary missing!${N}"
        echo "Binary:         MISSING" >> "$DIAG_OUTPUT"
    fi
else
    echo -e "    ${R}NOT installed${N}"
    echo "Installed:      NO" >> "$DIAG_OUTPUT"
    echo ""
    echo -e "  ${Y}Please install first:${N}"
    echo -e "  ${D}bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/minhpnz/tool-config/main/install-ipa-keyboard.sh)\"${N}"
    echo ""

    echo "" >> "$DIAG_OUTPUT"
    echo "App not installed. Run the install script first." >> "$DIAG_OUTPUT"
    cat "$DIAG_OUTPUT"
    exit 0
fi

# Check if running
echo ""
echo -e "  ${B}Process Status:${N}"
{
    echo "" >> "$DIAG_OUTPUT"
    echo "Process Status:" >> "$DIAG_OUTPUT"
} >> "$DIAG_OUTPUT"

if pgrep -f "ipa-keyboard" > /dev/null 2>&1; then
    PID=$(pgrep -f "ipa-keyboard" | head -1)
    echo -e "    ${G}Running${N} (PID: $PID)"
    echo "  Running:      YES (PID $PID)" >> "$DIAG_OUTPUT"

    # Get process details
    echo "" >> "$DIAG_OUTPUT"
    echo "  Process details:" >> "$DIAG_OUTPUT"
    ps aux | grep -E "PID|ipa-keyboard" | grep -v grep >> "$DIAG_OUTPUT"
else
    echo -e "    ${Y}Not running${N}"
    echo "  Running:      NO" >> "$DIAG_OUTPUT"
fi

# Check Accessibility permission
echo ""
echo -e "  ${B}Accessibility:${N}"
{
    echo "" >> "$DIAG_OUTPUT"
    echo "================================================================================" >> "$DIAG_OUTPUT"
    echo "ACCESSIBILITY PERMISSION" >> "$DIAG_OUTPUT"
    echo "================================================================================" >> "$DIAG_OUTPUT"
    echo "" >> "$DIAG_OUTPUT"
} >> "$DIAG_OUTPUT"

# Try to check TCC database (may fail due to SIP)
TCC_CHECK=$(sqlite3 "/Library/Application Support/com.apple.TCC/TCC.db" \
    "SELECT allowed FROM access WHERE client='com.minhphan.ipa-keyboard' AND service='kTCCServiceAccessibility'" 2>/dev/null || echo "cannot_read")

if [ "$TCC_CHECK" = "1" ]; then
    echo -e "    ${G}Granted${N}"
    echo "Permission:     GRANTED" >> "$DIAG_OUTPUT"
elif [ "$TCC_CHECK" = "0" ]; then
    echo -e "    ${R}Denied${N}"
    echo "Permission:     DENIED" >> "$DIAG_OUTPUT"
elif [ "$TCC_CHECK" = "cannot_read" ]; then
    echo -e "    ${Y}Cannot check${N} (SIP protected)"
    echo "Permission:     CANNOT CHECK (SIP protected)" >> "$DIAG_OUTPUT"
else
    echo -e "    ${Y}Not requested yet${N}"
    echo "Permission:     NOT REQUESTED" >> "$DIAG_OUTPUT"
fi

echo "" >> "$DIAG_OUTPUT"
echo "TCC Database query result: $TCC_CHECK" >> "$DIAG_OUTPUT"

# Test app startup
echo ""
echo -e "  ${B}Testing app startup...${N}"
{
    echo "" >> "$DIAG_OUTPUT"
    echo "================================================================================" >> "$DIAG_OUTPUT"
    echo "APP STARTUP TEST" >> "$DIAG_OUTPUT"
    echo "================================================================================" >> "$DIAG_OUTPUT"
    echo "" >> "$DIAG_OUTPUT"
} >> "$DIAG_OUTPUT"

# Kill existing instance
pkill -f "ipa-keyboard" 2>/dev/null || true
sleep 1

# Start app and capture output
echo -e "    Starting app for 5 seconds..."
echo "Starting app at $(date '+%H:%M:%S')..." >> "$DIAG_OUTPUT"

STARTUP_LOG="/tmp/ipa-startup-$$.log"
"$BIN" > "$STARTUP_LOG" 2>&1 &
APP_PID=$!

sleep 5

if ps -p $APP_PID > /dev/null 2>&1; then
    echo -e "    ${G}App started successfully${N}"
    echo "Result:         SUCCESS (still running after 5s)" >> "$DIAG_OUTPUT"
    kill $APP_PID 2>/dev/null || true
else
    EXIT_CODE=$(wait $APP_PID 2>/dev/null; echo $?)
    echo -e "    ${R}App exited${N} (code: $EXIT_CODE)"
    echo "Result:         FAILED (exit code: $EXIT_CODE)" >> "$DIAG_OUTPUT"
fi

wait 2>/dev/null

# Append startup output
echo "" >> "$DIAG_OUTPUT"
echo "App console output:" >> "$DIAG_OUTPUT"
echo "-------------------" >> "$DIAG_OUTPUT"
if [ -s "$STARTUP_LOG" ]; then
    cat "$STARTUP_LOG" >> "$DIAG_OUTPUT"
else
    echo "(no output captured)" >> "$DIAG_OUTPUT"
fi
rm -f "$STARTUP_LOG"

# Check for install log
{
    echo "" >> "$DIAG_OUTPUT"
    echo "================================================================================" >> "$DIAG_OUTPUT"
    echo "INSTALLATION LOG (last 50 lines)" >> "$DIAG_OUTPUT"
    echo "================================================================================" >> "$DIAG_OUTPUT"
    echo "" >> "$DIAG_OUTPUT"
} >> "$DIAG_OUTPUT"

if [ -f "$LOG_FILE" ]; then
    tail -50 "$LOG_FILE" >> "$DIAG_OUTPUT"
else
    echo "(no installation log found at $LOG_FILE)" >> "$DIAG_OUTPUT"
fi

# Check system log for related entries
{
    echo "" >> "$DIAG_OUTPUT"
    echo "================================================================================" >> "$DIAG_OUTPUT"
    echo "SYSTEM LOG (recent IPA Keyboard entries)" >> "$DIAG_OUTPUT"
    echo "================================================================================" >> "$DIAG_OUTPUT"
    echo "" >> "$DIAG_OUTPUT"
} >> "$DIAG_OUTPUT"

log show --predicate 'process CONTAINS "ipa-keyboard"' --last 5m 2>/dev/null | tail -30 >> "$DIAG_OUTPUT" || echo "(cannot read system log)" >> "$DIAG_OUTPUT"

# Final summary
{
    echo "" >> "$DIAG_OUTPUT"
    echo "================================================================================" >> "$DIAG_OUTPUT"
    echo "END OF DIAGNOSTIC REPORT" >> "$DIAG_OUTPUT"
    echo "================================================================================" >> "$DIAG_OUTPUT"
} >> "$DIAG_OUTPUT"

# Output results
echo ""
echo -e "  ${C}============================================${N}"
echo ""
echo -e "  ${B}Diagnostic Complete${N}"
echo ""
echo -e "  ${D}Full report saved to:${N}"
echo -e "  ${D}$DIAG_OUTPUT${N}"
echo ""
echo -e "  ${Y}To share with developer, run:${N}"
echo -e "  ${D}cat $DIAG_OUTPUT | pbcopy${N}"
echo -e "  ${D}(Then paste into a message)${N}"
echo ""
echo -e "  ${C}============================================${N}"
echo ""

# Also print to terminal
echo ""
echo "--- DIAGNOSTIC SUMMARY ---"
cat "$DIAG_OUTPUT" | grep -E "^(macOS|Installed|Running|Permission|Result):" | while read line; do
    echo "  $line"
done
echo ""
