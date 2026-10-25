#!/usr/bin/env bash
# 建立並開機 Android 模擬器，裝置資訊寫入 <out-dir>/device.txt。
# Usage: tool/ci/android_boot.sh <out-dir>
# 環境變數：
#   ANDROID_PROFILE      avdmanager 的裝置定義，例如 pixel_10
#   ANDROID_DEVICE_NAME  顯示名稱與影片檔名，例如 "Pixel 10"
#   ANDROID_API          系統映像 API level，例如 36
#   ANDROID_FALLBACK     （選用）找不到 ANDROID_PROFILE 時改用的定義與螢幕規格，
#                        格式 "<profile>:<寬>x<高>:<density>"，例如 "pixel_9:1080x2424:420"
set -euo pipefail
OUT=${1:-out/android}
PROFILE="${ANDROID_PROFILE:?set ANDROID_PROFILE, e.g. pixel_10}"
DEVICE_NAME="${ANDROID_DEVICE_NAME:-$PROFILE}"
API="${ANDROID_API:-36}"
IMAGE="system-images;android-$API;google_apis;x86_64"
AVD=demo_device
SDK="$ANDROID_HOME"
mkdir -p "$OUT"

# 新版 avdmanager 不一定把 AVD 放在 ~/.android/avd，固定下來才找得到 config.ini
export ANDROID_USER_HOME="$HOME/.android"
export ANDROID_AVD_HOME="$ANDROID_USER_HOME/avd"
mkdir -p "$ANDROID_AVD_HOME"

# 新機型的裝置定義（例如 pixel_10）只在最新的 cmdline-tools 裡。
# runner 已有 latest 時 sdkmanager 會裝到 latest-2。注意：不能用 `yes | sdkmanager`
# 搭配 pipefail，yes 會收到 SIGPIPE 讓整個 script 失敗。
(yes || true) | "$SDK/cmdline-tools/latest/bin/sdkmanager" --licenses > /dev/null || true
"$SDK/cmdline-tools/latest/bin/sdkmanager" --install "cmdline-tools;latest" > /dev/null
TOOLS="$SDK/cmdline-tools/latest"
[ -d "$SDK/cmdline-tools/latest-2" ] && TOOLS="$SDK/cmdline-tools/latest-2"
export PATH="$TOOLS/bin:$SDK/emulator:$SDK/platform-tools:$PATH"
# 讓後續的 workflow step 也找得到 adb
echo "$SDK/platform-tools" >> "$GITHUB_PATH"
sdkmanager --install emulator platform-tools "$IMAGE" > /dev/null

CFG="$ANDROID_AVD_HOME/$AVD.avd/config.ini"
if avdmanager list device -c | grep -qx "$PROFILE"; then
  echo no | avdmanager create avd -n "$AVD" -k "$IMAGE" -d "$PROFILE" --force
elif [ -n "${ANDROID_FALLBACK:-}" ]; then
  IFS=: read -r base size density <<< "$ANDROID_FALLBACK"
  echo "::warning::$PROFILE profile not found, deriving it from $base ($size @ $density)"
  echo no | avdmanager create avd -n "$AVD" -k "$IMAGE" -d "$base" --force
  sed -i -e "s/^hw.lcd.width=.*/hw.lcd.width=${size%x*}/" -e "s/^hw.lcd.height=.*/hw.lcd.height=${size#*x}/" \
    -e "s/^hw.lcd.density=.*/hw.lcd.density=$density/" "$CFG"
else
  echo "::error::Device profile '$PROFILE' not found. Available profiles:"
  avdmanager list device -c
  exit 1
fi
{
  echo "hw.ramSize=4096"
  echo "disk.dataPartition.size=6G"
  echo "hw.keyboard=no"
  echo "showDeviceFrame=no"
} >> "$CFG"
grep -E "hw.lcd|hw.device.name" "$CFG"

nohup emulator -avd "$AVD" -no-window -gpu swiftshader_indirect -noaudio -no-boot-anim \
  -no-snapshot -camera-back none -camera-front none > "$OUT/emulator.log" 2>&1 &
adb wait-for-device
for _ in $(seq 1 120); do
  [ "$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = "1" ] && break
  sleep 5
done
adb shell getprop sys.boot_completed
adb shell wm size
# 保留正常的系統動畫（Flutter 會參考 transition_animation_scale 決定要不要停用動畫）
adb shell settings put global window_animation_scale 1
adb shell settings put global transition_animation_scale 1
adb shell settings put global animator_duration_scale 1
adb shell settings put global sysui_demo_allowed 1
sleep 20  # 讓開機後的背景工作安靜下來，錄影比較順
echo "$DEVICE_NAME|android-$API" > "$OUT/device.txt"
