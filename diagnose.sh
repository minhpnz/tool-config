#!/bin/bash
echo "=== IPA Keyboard Diagnostic ==="
echo "Date: $(date)"
echo "macOS: $(sw_vers -productVersion)"
echo "Arch: $(uname -m)"
echo "CPU: $(sysctl -n machdep.cpu.brand_string 2>/dev/null)"
echo ""
if [ -d "/Applications/IPA Keyboard.app" ]; then
    echo "App: installed"
    lipo -info "/Applications/IPA Keyboard.app/Contents/MacOS/ipa-keyboard" 2>/dev/null
    ls -lh "/Applications/IPA Keyboard.app/Contents/MacOS/ipa-keyboard"
else
    echo "App: NOT installed"
fi
echo ""
if pgrep -f "ipa-keyboard" > /dev/null 2>&1; then
    echo "Running: yes (PID $(pgrep -f ipa-keyboard | head -1))"
else
    echo "Running: no"
fi
echo ""
echo "=== App Log (5 seconds) ==="
pkill -f "ipa-keyboard" 2>/dev/null
sleep 1
"/Applications/IPA Keyboard.app/Contents/MacOS/ipa-keyboard" 2>/tmp/ipa-diag.log &
PID=$!
sleep 5
kill $PID 2>/dev/null
cat /tmp/ipa-diag.log
rm -f /tmp/ipa-diag.log
echo ""
echo "=== Done ==="
