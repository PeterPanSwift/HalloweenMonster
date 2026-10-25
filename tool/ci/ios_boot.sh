#!/usr/bin/env bash
# 建立並開機 iOS 模擬器，UDID 寫入 $GITHUB_ENV (SIM_ID)，裝置資訊寫入 <out-dir>/device.txt。
# Usage: tool/ci/ios_boot.sh <out-dir>
# 環境變數：IOS_DEVICE（例如 "iPhone 18 Pro Max"）
set -euo pipefail
OUT=${1:-out/ios}
NAME="${IOS_DEVICE:?set IOS_DEVICE, e.g. "iPhone 18 Pro Max"}"
mkdir -p "$OUT"

xcodebuild -version
TYPE=$(xcrun simctl list devicetypes -j | python3 -c "
import json, sys
name = sys.argv[1]
for t in json.load(sys.stdin)['devicetypes']:
    if t['name'] == name:
        print(t['identifier'])
" "$NAME")
if [ -z "$TYPE" ]; then
  echo "::error::Device type '$NAME' is not available in $(xcodebuild -version | head -1). Available iPhones:"
  xcrun simctl list devicetypes | grep -i iphone
  exit 1
fi

# 由新到舊列出可用的 iOS runtime。最新的 runtime 不一定支援新機型
# （例如 iOS 27.1 建不出 iPhone 18 Pro Max，27.0 可以），所以逐一嘗試。
runtimes() {
  xcrun simctl list runtimes -j | python3 -c "
import json, sys
rts = [r for r in json.load(sys.stdin)['runtimes'] if r['platform'] == 'iOS' and r['isAvailable']]
rts.sort(key=lambda r: [int(x) for x in r['version'].split('.')], reverse=True)
print('\n'.join(r['identifier'] for r in rts))
"
}

create_device() {
  for rt in $(runtimes); do
    UDID=$(xcrun simctl create "$NAME" "$TYPE" "$rt" 2>&1 || true)
    # simctl 失敗時會把錯誤訊息印到 stdout，所以用 UUID 格式判斷成功與否
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
  echo "No compatible iOS runtime installed, downloading the platform for this Xcode..."
  xcodebuild -downloadPlatform iOS
  create_device
fi
echo "Created $NAME ($TYPE) on $RUNTIME: $UDID"

xcrun simctl boot "$UDID"
xcrun simctl bootstatus "$UDID" -b > /dev/null
# 上架截圖用的乾淨狀態列
xcrun simctl status_bar "$UDID" override --time "9:41" --dataNetwork wifi --wifiMode active \
  --wifiBars 3 --cellularMode active --cellularBars 4 --batteryState charged --batteryLevel 100
echo "SIM_ID=$UDID" >> "$GITHUB_ENV"
echo "$NAME|$RUNTIME" > "$OUT/device.txt"
