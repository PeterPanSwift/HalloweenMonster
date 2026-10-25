#!/usr/bin/env bash
# 在已開機的模擬器上執行 demo 測試：先截上架圖（MODE=shots），再錄操作影片（MODE=video）。
# Usage: tool/ci/record.sh ios|android <device-id> <out-dir>
# 環境變數：DEMO_TEST（預設 integration_test/demo_test.dart）、DEMO_TIMEOUT（每個模式的上限秒數，預設 900）、
#           IOS_BUNDLE_ID / ANDROID_APP_ID（選用，預設自動偵測）
#
# 為什麼不用 `flutter test`：
# - iOS 27 模擬器上 flutter test 編譯完會卡在連 App 的 VM service，沒有任何輸出。
# - Android 上 flutter test 會把測試的 print 累積到測試結束才一次印出，無法即時觸發截圖。
# 所以把測試檔當 App 進入點編譯（-t），安裝後直接啟動；flutter_test 在沒有測試工具時
# 會自己執行 testWidgets。測試透過裝置 log 的 @@SHOT / @@MARK 與 App tmp 資料夾裡的
# demo_shot.txt 通知 CI。
set -euo pipefail
PLATFORM=$1
DEVICE=$2
OUT=$(mkdir -p "$3" && cd "$3" && pwd)
mkdir -p "$OUT/shots"
TEST=${DEMO_TEST:-integration_test/demo_test.dart}
SHOT_FILE=demo_shot.txt
APP_ID=""

host_ms() { python3 -c 'import time; print(int(time.time() * 1000))'; }

detect_app_id() {
  if [ "$PLATFORM" = ios ]; then
    APP_ID=${IOS_BUNDLE_ID:-$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' \
      build/ios/iphonesimulator/Runner.app/Info.plist)}
  else
    # Groovy 與 Kotlin DSL 都可能，而且只會有其中一個檔案（不能用 grep 兩個檔案，缺檔會讓 pipefail 中止）
    APP_ID=${ANDROID_APP_ID:-$(python3 -c '
import pathlib, re
for name in ("build.gradle.kts", "build.gradle"):
    f = pathlib.Path("android/app") / name
    if f.exists():
        m = re.search(r"applicationId\s*=?\s*[\x22\x27]([^\x22\x27]+)[\x22\x27]", f.read_text())
        if m:
            print(m.group(1))
            break
')}
  fi
  [ -n "$APP_ID" ] || { echo "::error::could not detect app id"; exit 1; }
  echo "app id: $APP_ID"
}

build_and_install() {
  local mode=$1
  if [ "$PLATFORM" = ios ]; then
    flutter build ios --simulator --debug -t "$TEST" --dart-define=MODE="$mode" --no-pub
    xcrun simctl install "$DEVICE" build/ios/iphonesimulator/Runner.app
  else
    flutter build apk --debug -t "$TEST" --dart-define=MODE="$mode" --no-pub
    adb -s "$DEVICE" install -r build/app/outputs/flutter-apk/app-debug.apk
  fi
  detect_app_id
}

# 上架截圖用的乾淨狀態列。iOS 在開機時已用 simctl status_bar 設定；Android 的 demo mode
# 要在 SystemUI 完全就緒後才會生效，所以每次啟動 App 前再送一次。
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
    xcrun simctl launch "$DEVICE" "$APP_ID"
  else
    local activity
    activity=$(adb -s "$DEVICE" shell cmd package resolve-activity --brief "$APP_ID" | tr -d '\r' | tail -1)
    adb -s "$DEVICE" shell am start -n "$activity"
  fi
}

stop_app() {
  if [ "$PLATFORM" = ios ]; then
    xcrun simctl terminate "$DEVICE" "$APP_ID" 2>/dev/null || true
  else
    adb -s "$DEVICE" shell am force-stop "$APP_ID" || true
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

# 錄影起點與 @@MARK 都是裝置時間（iOS 模擬器與主機共用時鐘），事後可直接相減來裁剪。
start_recording() {
  if [ "$PLATFORM" = ios ]; then
    xcrun simctl io "$DEVICE" recordVideo --codec=h264 --force "$OUT/raw.mp4" < /dev/null > "$OUT/rec.log" 2>&1 &
    for _ in $(seq 1 50); do grep -q "Recording started" "$OUT/rec.log" 2>/dev/null && break; sleep 0.1; done
    host_ms > "$OUT/rec_start_ms"
  else
    # 先在裝置上印出時間再 exec screenrecord，取得錄影起點的裝置時間。
    # screenrecord 最長 180 秒，demo 流程要控制在這之內。
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

# 背景監聽裝置 log：全部記錄下來。Android 的 logcat 是即時的，看到 @@SHOT 就截圖並回覆 ack；
# iOS 的 log 會延遲，截圖交給 poll_ios_shots。
# 迴圈內的指令一律 < /dev/null，否則 adb / simctl 會讀走 log 管線裡的下一行（例如 @@MARK START）。
listen() {
  local log=$1 rest name dir
  device_log | while IFS= read -r line; do
    echo "$line" >> "$log"
    case "$line" in
      *"@@SHOT "*)
        [ "$PLATFORM" = android ] || continue
        rest=${line##*@@SHOT }
        name=$(echo "${rest%% *}" | tr -cd 'A-Za-z0-9_')
        dir=$(echo "${rest#* }" | tr -d '\r')
        [ -n "$name" ] || continue
        screenshot "$OUT/shots/$name.png" && echo ">> captured $name"
        adb -s "$DEVICE" shell "run-as $APP_ID sh -c 'echo $name > $dir/demo_shot_ack.txt'" < /dev/null
        ;;
    esac
  done
}

# iOS：輪詢 App container 裡的 tmp/demo_shot.txt（比 log stream 即時），截完圖寫 demo_shot_ack.txt 回覆。
poll_ios_shots() {
  local container="" name last=""
  for _ in $(seq 1 120); do
    container=$(xcrun simctl get_app_container "$DEVICE" "$APP_ID" data 2>/dev/null || true)
    [ -n "$container" ] && break
    sleep 0.5
  done
  while true; do
    if [ -f "$container/tmp/$SHOT_FILE" ]; then
      name=$(tr -cd 'A-Za-z0-9_' < "$container/tmp/$SHOT_FILE")
      if [ -n "$name" ] && [ "$name" != "$last" ]; then
        screenshot "$OUT/shots/$name.png" && echo ">> captured $name"
        printf '%s' "$name" > "$container/tmp/demo_shot_ack.txt"
        last=$name
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
  # 新開機的模擬器第一次截圖要 6 秒左右（擷取服務在啟動），會截到下一個畫面，所以先暖機。
  screenshot "$OUT/warmup.png" > /dev/null 2>&1 || true
  rm -f "$OUT/warmup.png"
  listen "$log" &
  local listener=$!
  sleep 3
  # iOS 的 log 會延遲，所以影片在啟動 App 前就開始錄，事後再依 @@MARK 時間戳裁剪。
  if [ "$mode" = video ]; then start_recording; fi
  local poller=""
  if [ "$PLATFORM" = ios ] && [ "$mode" = shots ]; then
    local c
    c=$(xcrun simctl get_app_container "$DEVICE" "$APP_ID" data 2>/dev/null || echo /nonexistent)
    rm -f "$c/tmp/$SHOT_FILE" "$c/tmp/demo_shot_ack.txt"
    poll_ios_shots &
    poller=$!
  fi
  launch_app
  # 截圖握手在 runner 很忙時每張可能要等 1～2 分鐘，所以整段上限給寬一點（DEMO_TIMEOUT 秒）
  local deadline=$(( $(date +%s) + ${DEMO_TIMEOUT:-900} ))
  until grep -q "$done_marker" "$log"; do
    # 結束訊號與例外可能在同一秒寫入，所以判斷失敗前再確認一次結束訊號
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
  if grep -q "@@WARN" "$log"; then echo "::warning::$(grep -h '@@WARN' "$log" | sed 's/.*@@WARN //' | sort -u | tr '\n' ';')"; fi
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
