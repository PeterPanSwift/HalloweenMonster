#!/usr/bin/env python3
"""裁剪、壓縮錄影並產生上架截圖。

Usage: python3 tool/ci/process_media.py <in_dir> <out_dir> <font.ttf>
<in_dir>/<platform>/ 需包含 record.sh 的輸出：raw.mp4、marks.txt、rec_start_ms、shots/、device.txt
"""
import json
import os
import shutil
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
PLATFORMS = {
    # platform: (影片檔名, 上架截圖類型, 原始截圖目標尺寸)
    "ios": ("HalloweenMonster_iPhone18ProMax.mp4", "appstore", (1320, 2868)),
    "android": ("HalloweenMonster_Pixel10.mp4", "googleplay", None),
}
# END 之後 Android 會立刻顯示 integration_test 的 "Test finished." 畫面，所以結尾往前收一點。
LEAD_IN, TAIL = 0.4, -0.3


def to_ms(raw):
    digits = "".join(c for c in raw if c.isdigit())
    if len(digits) >= 13:
        return int(digits[:13])
    return int(digits) * 1000  # 只有秒


def duration(path):
    out = subprocess.check_output(["ffprobe", "-v", "error", "-show_entries", "format=duration",
                                   "-of", "default=nw=1:nk=1", path], text=True)
    return float(out.strip())


def process_video(src_dir, out_dir, name):
    marks = {}
    for line in open(os.path.join(src_dir, "marks.txt")):
        parts = line.split()
        if len(parts) == 2:
            marks[parts[0]] = int(parts[1])
    rec = to_ms(open(os.path.join(src_dir, "rec_start_ms")).read())
    raw = os.path.join(src_dir, "raw.mp4")
    total = duration(raw)
    start = max(0.0, (marks["START"] - rec) / 1000 - LEAD_IN)
    end = min(total, (marks["END"] - rec) / 1000 + TAIL)
    os.makedirs(out_dir, exist_ok=True)
    out = os.path.join(out_dir, name)
    subprocess.check_call([
        "ffmpeg", "-y", "-v", "error", "-i", raw, "-ss", f"{start:.3f}", "-to", f"{end:.3f}",
        "-vf", "fps=30,scale=-2:1280:flags=lanczos", "-c:v", "libx264", "-preset", "slow",
        "-crf", "26", "-pix_fmt", "yuv420p", "-movflags", "+faststart", "-an", out,
    ])
    # 檢查用：裁剪後的第一格與最後一格
    check = os.path.join(out_dir, "_check")
    os.makedirs(check, exist_ok=True)
    base = os.path.splitext(name)[0]
    subprocess.check_call(["ffmpeg", "-y", "-v", "error", "-i", out, "-frames:v", "1",
                           os.path.join(check, f"{base}_first.jpg")])
    subprocess.check_call(["ffmpeg", "-y", "-v", "error", "-sseof", "-0.1", "-i", out, "-frames:v", "1",
                           os.path.join(check, f"{base}_last.jpg")])
    return {
        "raw_seconds": round(total, 2),
        "trim": [round(start, 2), round(end, 2)],
        "seconds": round(duration(out), 2),
        "megabytes": round(os.path.getsize(out) / 1e6, 2),
        "raw_megabytes": round(os.path.getsize(raw) / 1e6, 2),
    }


def main():
    in_dir, out_dir, font = sys.argv[1:4]
    os.makedirs(out_dir, exist_ok=True)
    report = {}
    for platform, (video_name, store, raw_size) in PLATFORMS.items():
        src = os.path.join(in_dir, platform)
        if not os.path.isdir(src):
            print(f"skip {platform}: no input")
            continue
        device_txt = os.path.join(src, "device.txt")
        info = {"device": open(device_txt).read().strip() if os.path.exists(device_txt) else platform}
        try:
            info["video"] = process_video(src, os.path.join(out_dir, "videos"), video_name)
        except Exception as e:  # noqa: BLE001
            info["video_error"] = repr(e)
        shots = os.path.join(src, "shots")
        if not os.path.isdir(shots) or not os.listdir(shots):
            report[platform] = info
            continue
        raw_out = os.path.join(out_dir, "screenshots", f"{platform}_raw")
        os.makedirs(raw_out, exist_ok=True)
        for f in sorted(os.listdir(shots)):
            shutil.copy(os.path.join(shots, f), raw_out)
        if raw_size:
            # App Store 6.9 吋規格：若裝置解析度不同，等比縮放後置中裁切成 1320x2868。
            from PIL import Image
            for f in os.listdir(raw_out):
                p = os.path.join(raw_out, f)
                im = Image.open(p).convert("RGB")
                if im.size != raw_size:
                    scale = max(raw_size[0] / im.width, raw_size[1] / im.height)
                    im = im.resize((round(im.width * scale), round(im.height * scale)), Image.LANCZOS)
                    left, top = (im.width - raw_size[0]) // 2, (im.height - raw_size[1]) // 2
                    im = im.crop((left, top, left + raw_size[0], top + raw_size[1]))
                im.save(p, optimize=True)
        subprocess.check_call([sys.executable, os.path.join(HERE, "..", "store_shots.py"), shots,
                               os.path.join(out_dir, "screenshots", store), store, font])
        info["screenshots"] = sorted(os.listdir(shots))
        report[platform] = info
    with open(os.path.join(out_dir, "report.json"), "w", encoding="utf-8") as fh:
        json.dump(report, fh, ensure_ascii=False, indent=2)
    print(json.dumps(report, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
