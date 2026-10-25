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

runtimes() {
  # 由新到舊列出可用的 iOS runtime
  xcrun simctl list runtimes -j | python3 -c "
import json, sys
rts = [r for r in json.load(sys.stdin)['runtimes'] if r['platform'] == 'iOS' and r['isAvailable']]
rts.sort(key=lambda r: [int(x) for x in r['version'].split('.')], reverse=True)
print('\\n'.join(r['identifier'] for r in rts))
"
}

create_device() {
  for rt in $(runtimes); do
    UDID=$(xcrun simctl create "$NAME" "$TYPE" "$rt" 2>&1 || true)
    if [[ "$UDID" =~ ^[0-9A-F-]{36}$ ]]; then
      RUNTIME=$rt
      return 0
    fi
    echo "  $rt: $UDID"
  done
  return 1
}

UDID=""
RUNTIME=""
if ! create_device; then
  echo "No compatible iOS runtime yet, downloading the platform for this Xcode..."
  xcodebuild -downloadPlatform iOS
  create_device
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
