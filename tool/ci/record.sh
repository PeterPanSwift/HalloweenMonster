#!/usr/bin/env bash
# 在已開機的模擬器上跑 integration_test：先截上架圖，再錄操作影片。
# Usage: tool/ci/record.sh ios|android <device-id> <out-dir>
set -euo pipefail
PLATFORM=$1
DEVICE=$2
OUT=$3
mkdir -p "$OUT/shots"
TEST=integration_test/demo_test.dart

host_ms() { python3 -c 'import time; print(int(time.time() * 1000))'; }

screenshot() {
  if [ "$PLATFORM" = ios ]; then
    xcrun simctl io "$DEVICE" screenshot --type=png "$1"
  else
    adb -s "$DEVICE" exec-out screencap -p > "$1"
  fi
}

# 錄影起點與 @@MARK 都是裝置時間（iOS 模擬器與主機共用時鐘），可直接相減。
start_recording() {
  if [ "$PLATFORM" = ios ]; then
    xcrun simctl io "$DEVICE" recordVideo --codec=h264 --force "$OUT/raw.mp4" > "$OUT/rec.log" 2>&1 &
    for _ in $(seq 1 50); do grep -q "Recording started" "$OUT/rec.log" 2>/dev/null && break; sleep 0.1; done
    host_ms > "$OUT/rec_start_ms"
  else
    # 在裝置上先印出時間再 exec screenrecord，取得錄影起點的裝置時間。
    adb -s "$DEVICE" shell 'date +%s%N; exec screenrecord --bit-rate 16000000 --time-limit 180 /sdcard/demo.mp4' \
      > "$OUT/rec.log" 2>&1 &
    for _ in $(seq 1 50); do [ -s "$OUT/rec.log" ] && break; sleep 0.1; done
    head -1 "$OUT/rec.log" | tr -d '\r' > "$OUT/rec_start_ms"
  fi
  echo "recording started at $(cat "$OUT/rec_start_ms")"
}

echo "::group::Store screenshots"
flutter test "$TEST" -d "$DEVICE" --dart-define=MODE=shots --no-pub 2>&1 | while IFS= read -r line; do
  echo "$line"
  case "$line" in
    *"@@SHOT "*)
      name=$(echo "${line##*@@SHOT }" | tr -cd 'A-Za-z0-9_')
      screenshot "$OUT/shots/$name.png" && echo ">> captured $name"
      ;;
  esac
done
echo "::endgroup::"

echo "::group::Demo video"
: > "$OUT/marks.txt"
flutter test "$TEST" -d "$DEVICE" --dart-define=MODE=video --no-pub 2>&1 | while IFS= read -r line; do
  echo "$line"
  case "$line" in
    *"@@READY"*) start_recording ;;
    *"@@MARK "*) echo "${line##*@@MARK }" | tr -d '\r' >> "$OUT/marks.txt" ;;
  esac
done
echo "::endgroup::"
# start_recording 在 pipeline 的 subshell 內執行，這裡另外找出錄影程序停止它。
if [ "$PLATFORM" = ios ]; then
  REC_PID=$(pgrep -f "simctl io $DEVICE recordVideo" | head -1)
  kill -INT "$REC_PID" || true
  while kill -0 "$REC_PID" 2>/dev/null; do sleep 0.5; done
else
  adb -s "$DEVICE" shell pkill -INT screenrecord || true
  sleep 4
  adb -s "$DEVICE" pull /sdcard/demo.mp4 "$OUT/raw.mp4"
fi
cat "$OUT/marks.txt" "$OUT/rec_start_ms"
ls -la "$OUT" "$OUT/shots"
