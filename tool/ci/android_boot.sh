#!/usr/bin/env bash
# 建立並開機 Pixel 10 模擬器 (Android 16 / API 36)。
set -euo pipefail
API=36
IMAGE="system-images;android-$API;google_apis;x86_64"
SDK="$ANDROID_HOME"

yes | "$SDK/cmdline-tools/latest/bin/sdkmanager" --install "cmdline-tools;latest" >/dev/null
export PATH="$SDK/cmdline-tools/latest/bin:$SDK/emulator:$SDK/platform-tools:$PATH"
yes | sdkmanager --install emulator platform-tools "$IMAGE" >/dev/null
avdmanager list device -c | grep -i pixel || true

if avdmanager list device -c | grep -qx "pixel_10"; then
  echo no | avdmanager create avd -n Pixel_10 -k "$IMAGE" -d pixel_10 --force
else
  # 舊版 cmdline-tools 沒有 Pixel 10 定義時，以 Pixel 9 為基礎改成 Pixel 10 的規格。
  echo "::warning::pixel_10 profile not found, deriving it from pixel_9"
  echo no | avdmanager create avd -n Pixel_10 -k "$IMAGE" -d pixel_9 --force
  CFG="$HOME/.android/avd/Pixel_10.avd/config.ini"
  sed -i -e 's/^hw.lcd.width=.*/hw.lcd.width=1080/' -e 's/^hw.lcd.height=.*/hw.lcd.height=2424/' \
    -e 's/^hw.lcd.density=.*/hw.lcd.density=420/' -e 's/^hw.device.name=.*/hw.device.name=pixel_10/' "$CFG"
fi
CFG="$HOME/.android/avd/Pixel_10.avd/config.ini"
{
  echo "hw.ramSize=4096"
  echo "disk.dataPartition.size=6G"
  echo "hw.keyboard=no"
  echo "showDeviceFrame=no"
} >> "$CFG"
grep -E "hw.lcd|hw.device" "$CFG"

nohup emulator -avd Pixel_10 -no-window -gpu swiftshader_indirect -noaudio -no-boot-anim \
  -no-snapshot -camera-back none -camera-front none > emulator.log 2>&1 &
adb wait-for-device
for _ in $(seq 1 120); do
  [ "$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = "1" ] && break
  sleep 5
done
adb shell getprop sys.boot_completed
adb shell wm size
adb shell settings put global window_animation_scale 1
adb shell settings put global transition_animation_scale 1
adb shell settings put global animator_duration_scale 1
adb shell cmd uimode night yes || true
# 上架截圖用的乾淨狀態列 (demo mode)
adb shell settings put global sysui_demo_allowed 1
demo() { adb shell am broadcast -a com.android.systemui.demo -e command "$@" >/dev/null; }
demo enter
demo clock -e hhmm 0941
demo battery -e level 100 -e plugged false
demo network -e wifi show -e level 4
demo network -e mobile show -e datatype none -e level 4
demo notifications -e visible false
sleep 20  # 讓開機後的背景工作安靜下來
echo "Pixel 10|android-$API" > device.txt
