#!/bin/bash
echo ""
echo "  IPA Keyboard - Diagnostic Report"
echo "  ================================="
echo ""
echo "  macOS:    $(sw_vers -productVersion)"
echo "  Chip:     $(sysctl -n machdep.cpu.brand_string 2>/dev/null || echo 'unknown')"
echo "  Arch:     $(uname -m)"
echo ""

if [ -d "/Applications/IPA Keyboard.app" ]; then
    BIN="/Applications/IPA Keyboard.app/Contents/MacOS/ipa-keyboard"
    SIZE=$(ls -lh "$BIN" 2>/dev/null | awk '{print $5}')
    ARCH=$(lipo -info "$BIN" 2>/dev/null | sed 's/.*: //')
    echo "  App:      Installed"
    echo "  Binary:   $SIZE ($ARCH)"
else
    echo "  App:      NOT installed"
    echo ""
    echo "  Nothing to diagnose. Please install first."
    exit 0
fi

if pgrep -f "ipa-keyboard" > /dev/null 2>&1; then
    echo "  Status:   Running (PID $(pgrep -f 'ipa-keyboard' | head -1))"
else
    echo "  Status:   Not running"
fi

echo ""
echo "  Checking app startup..."
echo "  -----------------------"
echo ""

pkill -f "ipa-keyboard" 2>/dev/null
sleep 1

"$BIN" 2>/tmp/ipa-diag.log &
PID=$!
sleep 5
kill $PID 2>/dev/null
wait $PID 2>/dev/null

while IFS= read -r line; do
    echo "  $line"
done < /tmp/ipa-diag.log
rm -f /tmp/ipa-diag.log

echo ""
echo "  ================================="
echo "  Please screenshot this and send"
echo "  to the developer."
echo ""
