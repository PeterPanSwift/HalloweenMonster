#!/usr/bin/env bash
# 建立並開機 iPhone 18 Pro Max 模擬器，把 UDID 寫入 $GITHUB_ENV (SIM_ID)。
set -euo pipefail
NAME="${DEVICE_NAME:-iPhone 18 Pro Max}"

xcrun simctl list devicetypes | grep -i "iphone" | tail -15
TYPE=$(xcrun simctl list devicetypes -j | python3 -c "
import json, sys
name = sys.argv[1]
for t in json.load(sys.stdin)['devicetypes']:
    if t['name'] == name:
        print(t['identifier'])
" "$NAME")
if [ -z "$TYPE" ]; then
  echo "::error::Device type '$NAME' is not available in $(xcodebuild -version | head -1)"
  exit 1
fi

newest_runtime() {
  xcrun simctl list runtimes -j | python3 -c "
import json, sys
rts = [r for r in json.load(sys.stdin)['runtimes'] if r['platform'] == 'iOS' and r['isAvailable']]
rts.sort(key=lambda r: [int(x) for x in r['version'].split('.')])
print(rts[-1]['identifier'] if rts else '')
"
}

RUNTIME=$(newest_runtime)
UDID=""
if [ -n "$RUNTIME" ]; then
  UDID=$(xcrun simctl create "$NAME" "$TYPE" "$RUNTIME" 2>/dev/null || true)
fi
if [ -z "$UDID" ]; then
  echo "No compatible iOS runtime yet, downloading the platform for this Xcode..."
  xcodebuild -downloadPlatform iOS
  RUNTIME=$(newest_runtime)
  UDID=$(xcrun simctl create "$NAME" "$TYPE" "$RUNTIME")
fi
echo "Created $NAME ($TYPE) on $RUNTIME: $UDID"

xcrun simctl boot "$UDID"
xcrun simctl bootstatus "$UDID" -b
# 上架截圖用的乾淨狀態列
xcrun simctl status_bar "$UDID" override --time "9:41" --dataNetwork wifi --wifiMode active \
  --wifiBars 3 --cellularMode active --cellularBars 4 --batteryState charged --batteryLevel 100
xcrun simctl ui "$UDID" appearance dark || true
echo "SIM_ID=$UDID" >> "$GITHUB_ENV"
echo "$NAME|$RUNTIME" > device.txt
