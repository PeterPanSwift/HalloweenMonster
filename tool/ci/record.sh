#!/usr/bin/env bash
# 在已開機的模擬器上執行 integration_test：先截上架圖，再錄操作影片。
# Usage: tool/ci/record.sh ios|android <device-id> <out-dir>
#
# 不透過 `flutter test` 連線裝置（iOS 27 模擬器上會卡在連 VM service，Android 則會把
# 測試輸出累積到結束才印），而是把測試檔直接編成 App（-t），安裝後啟動，測試會在 App
# 啟動時自動執行；@@READY / @@SHOT / @@MARK 訊號從裝置 log 即時讀取。
set -euo pipefail
PLATFORM=$1
DEVICE=$2
OUT=$(mkdir -p "$3" && cd "$3" && pwd)
mkdir -p "$OUT/shots"
TEST=integration_test/demo_test.dart
IOS_BUNDLE=com.peterpanswift.halloweenMonster
ANDROID_PACKAGE=com.peterpanswift.halloween_monster

host_ms() { python3 -c 'import time; print(int(time.time() * 1000))'; }

build_and_install() {
  local mode=$1
  if [ "$PLATFORM" = ios ]; then
    flutter build ios --simulator --debug -t "$TEST" --dart-define=MODE="$mode" --no-pub
    xcrun simctl install "$DEVICE" build/ios/iphonesimulator/Runner.app
  else
    flutter build apk --debug -t "$TEST" --dart-define=MODE="$mode" --no-pub
    adb -s "$DEVICE" install -r build/app/outputs/flutter-apk/app-debug.apk
  fi
}

# 上架截圖用的乾淨狀態列（Android demo mode；iOS 已在開機時用 simctl status_bar 設定）
clean_status_bar() {
  [ "$PLATFORM" = android ] || return 0
  demo() { adb -s "$DEVICE" shell am broadcast -a com.android.systemui.demo -p com.android.systemui -e command "$@" > /dev/null; }
  adb -s "$DEVICE" shell settings put global sysui_demo_allowed 1
  demo enter
  demo clock -e hhmm 0941
  demo battery -e level 100 -e plugged false
  demo network -e wifi show -e level 4
  demo network -e mobile show -e datatype none -e level 4
  demo notifications -e visible false
}

launch_app() {
  if [ "$PLATFORM" = ios ]; then
    xcrun simctl launch "$DEVICE" "$IOS_BUNDLE"
  else
    adb -s "$DEVICE" shell am start -n "$ANDROID_PACKAGE/.MainActivity"
  fi
}

stop_app() {
  if [ "$PLATFORM" = ios ]; then
    xcrun simctl terminate "$DEVICE" "$IOS_BUNDLE" || true
  else
    adb -s "$DEVICE" shell am force-stop "$ANDROID_PACKAGE" || true
  fi
}

device_log() {
  if [ "$PLATFORM" = ios ]; then
    xcrun simctl spawn "$DEVICE" log stream --level debug --style compact --predicate 'process == "Runner"'
  else
    adb -s "$DEVICE" logcat -c
    adb -s "$DEVICE" logcat -v raw -s flutter:I
  fi
}

stop_device_log() {
  if [ "$PLATFORM" = ios ]; then
    pkill -f "simctl spawn $DEVICE log stream" || true
    pkill -f "log stream --level debug --style compact" || true
  else
    pkill -f "adb -s $DEVICE logcat" || true
  fi
}

screenshot() {
  if [ "$PLATFORM" = ios ]; then
    xcrun simctl io "$DEVICE" screenshot --type=png "$1" < /dev/null
  else
    adb -s "$DEVICE" exec-out screencap -p > "$1" < /dev/null
  fi
}

# 錄影起點與 @@MARK 都是裝置時間（iOS 模擬器與主機共用時鐘），可直接相減。
start_recording() {
  if [ "$PLATFORM" = ios ]; then
    xcrun simctl io "$DEVICE" recordVideo --codec=h264 --force "$OUT/raw.mp4" < /dev/null > "$OUT/rec.log" 2>&1 &
    for _ in $(seq 1 50); do grep -q "Recording started" "$OUT/rec.log" 2>/dev/null && break; sleep 0.1; done
    host_ms > "$OUT/rec_start_ms"
  else
    # 在裝置上先印出時間再 exec screenrecord，取得錄影起點的裝置時間。
    adb -s "$DEVICE" shell 'date +%s%N; exec screenrecord --bit-rate 16000000 --time-limit 180 /sdcard/demo.mp4' \
      < /dev/null > "$OUT/rec.log" 2>&1 &
    for _ in $(seq 1 50); do [ -s "$OUT/rec.log" ] && break; sleep 0.1; done
    head -1 "$OUT/rec.log" | tr -d '\r' > "$OUT/rec_start_ms"
  fi
  echo ">> recording started at $(cat "$OUT/rec_start_ms")"
}

stop_recording() {
  if [ "$PLATFORM" = ios ]; then
    local pid
    pid=$(pgrep -f "simctl io $DEVICE recordVideo" | head -1 || true)
    if [ -n "$pid" ]; then
      kill -INT "$pid"
      while kill -0 "$pid" 2>/dev/null; do sleep 0.5; done
    fi
  else
    adb -s "$DEVICE" shell pkill -INT screenrecord || true
    sleep 4
    adb -s "$DEVICE" pull /sdcard/demo.mp4 "$OUT/raw.mp4"
  fi
}

# 背景監聽裝置 log：記錄 log、依 @@SHOT 截圖。
# 迴圈內的指令一律 < /dev/null，避免它們吃掉 log 管線裡的下一行。
listen() {
  local log=$1
  device_log | while IFS= read -r line; do
    echo "$line" >> "$log"
    case "$line" in
      *"@@SHOT "*)
        name=$(echo "${line##*@@SHOT }" | tr -cd 'A-Za-z0-9_')
        if [ ! -f "$OUT/shots/$name.png" ]; then
          screenshot "$OUT/shots/$name.png" && echo ">> captured $name"
        fi
        ;;
    esac
  done
}

# iOS：輪詢 App container 裡的 tmp/hm_shot.txt，比 log stream 即時。
poll_ios_shots() {
  local container="" f name
  for _ in $(seq 1 120); do
    container=$(xcrun simctl get_app_container "$DEVICE" "$IOS_BUNDLE" data 2>/dev/null || true)
    [ -n "$container" ] && break
    sleep 0.5
  done
  f="$container/tmp/hm_shot.txt"
  while true; do
    if [ -f "$f" ]; then
      name=$(tr -cd 'A-Za-z0-9_' < "$f")
      if [ -n "$name" ] && [ ! -f "$OUT/shots/$name.png" ]; then
        screenshot "$OUT/shots/$name.png" && echo ">> captured $name (file)"
      fi
    fi
    sleep 0.25
  done
}

run_mode() {
  local mode=$1 done_marker=$2
  local log="$OUT/device_$mode.log"
  : > "$log"
  build_and_install "$mode"
  stop_app
  clean_status_bar
  listen "$log" &
  local listener=$!
  sleep 3
  # iOS 的 log stream 會延遲數秒，所以影片在啟動 App 前就開始錄，事後再依 @@MARK 裁剪。
  if [ "$mode" = video ]; then start_recording; fi
  local poller=""
  if [ "$PLATFORM" = ios ] && [ "$mode" = shots ]; then
    rm -f "$(xcrun simctl get_app_container "$DEVICE" "$IOS_BUNDLE" data 2>/dev/null || echo /nonexistent)/tmp/hm_shot.txt"
    poll_ios_shots &
    poller=$!
  fi
  launch_app
  local deadline=$(( $(date +%s) + 300 ))
  until grep -q "$done_marker" "$log"; do
    if { grep -q "tests failed\|EXCEPTION CAUGHT" "$log" && ! grep -q "$done_marker" "$log"; } \
      || [ "$(date +%s)" -gt "$deadline" ]; then
      echo "::error::$mode run failed or timed out"
      cat "$log"
      [ -n "$poller" ] && kill "$poller" 2>/dev/null
      stop_device_log; stop_app
      return 1
    fi
    sleep 1
  done
  sleep 6
  [ -n "$poller" ] && kill "$poller" 2>/dev/null
  stop_device_log
  wait "$listener" 2>/dev/null || true
  stop_app
  grep -E "@@|tests passed|tests failed" "$log" || true
  if grep -q "EXCEPTION CAUGHT" "$log"; then
    echo "::warning::$mode run logged an exception after finishing"
    grep -A40 "EXCEPTION CAUGHT" "$log" | head -60
  fi
}

echo "::group::Store screenshots"
run_mode shots "@@MARK DONE"
echo "::endgroup::"

echo "::group::Demo video"
run_mode video "@@MARK END"
stop_recording
echo "::endgroup::"

grep -h "@@MARK " "$OUT/device_video.log" | sed 's/.*@@MARK //' | tr -d '\r' | awk '{print $1, $2}' > "$OUT/marks.txt"
cat "$OUT/marks.txt" "$OUT/rec_start_ms"
ls -la "$OUT" "$OUT/shots"
