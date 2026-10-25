#!/usr/bin/env python3
"""裁剪、壓縮錄影並產生上架截圖。

Usage: python3 tool/ci/process_media.py <in_dir> <out_dir> <store.json> <font.ttf>

<in_dir>/<ios|android>/ 是 record.sh 的輸出：raw.mp4、marks.txt、rec_start_ms、shots/、device.txt。
影片檔名為 <APP_NAME>_<裝置名稱去空白>.mp4（APP_NAME 取自環境變數）。
"""
import json
import os
import shutil
import subprocess
import sys

from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
# platform: (上架截圖類型, 原始截圖要符合的尺寸；None 表示保留裝置原尺寸)
PLATFORMS = {
    "ios": ("appstore", (1320, 2868)),  # App Store Connect 必填的 6.9 吋
    "android": ("googleplay", None),
}
# 錄影時間軸與時間戳有幾百毫秒的誤差。START 之前多留一點；END 之後操作腳本會在同一畫面停 3 秒，
# 結尾只多留 0.2 秒，才不會剪進測試結束後的「Test finished.」畫面。
LEAD_IN, TAIL = 0.4, 0.2
VIDEO_HEIGHT = int(os.environ.get("VIDEO_HEIGHT", "1280"))
VIDEO_CRF = os.environ.get("VIDEO_CRF", "26")


def to_ms(raw):
    digits = "".join(c for c in raw if c.isdigit())
    if len(digits) >= 13:
        return int(digits[:13])  # 毫秒或奈秒都取前 13 位
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
        "-vf", f"fps=30,scale=-2:{VIDEO_HEIGHT}:flags=lanczos", "-c:v", "libx264", "-preset", "slow",
        "-crf", VIDEO_CRF, "-pix_fmt", "yuv420p", "-movflags", "+faststart", "-an", out,
    ])
    # 驗收用：裁剪後的第一格、最後一格，以及每 3 秒一格的縮圖
    check = os.path.join(out_dir, "_check")
    os.makedirs(check, exist_ok=True)
    base = os.path.splitext(name)[0]
    subprocess.check_call(["ffmpeg", "-y", "-v", "error", "-i", out, "-frames:v", "1",
                           os.path.join(check, f"{base}_first.jpg")])
    subprocess.check_call(["ffmpeg", "-y", "-v", "error", "-sseof", "-0.1", "-i", out, "-frames:v", "1",
                           os.path.join(check, f"{base}_last.jpg")])
    subprocess.check_call(["ffmpeg", "-y", "-v", "error", "-i", out, "-vf", "fps=1/3,scale=-2:400,tile=20x1",
                           "-frames:v", "1", os.path.join(check, f"{base}_sheet.jpg")])
    return {
        "raw_seconds": round(total, 2),
        "trim": [round(start, 2), round(end, 2)],
        "seconds": round(duration(out), 2),
        "megabytes": round(os.path.getsize(out) / 1e6, 2),
        "raw_megabytes": round(os.path.getsize(raw) / 1e6, 2),
    }


def fit_exact(path, size):
    """等比縮放後置中裁切成指定尺寸（裝置解析度與商店規格不同時用）。"""
    im = Image.open(path).convert("RGB")
    if im.size != size:
        scale = max(size[0] / im.width, size[1] / im.height)
        im = im.resize((round(im.width * scale), round(im.height * scale)), Image.LANCZOS)
        left, top = (im.width - size[0]) // 2, (im.height - size[1]) // 2
        im = im.crop((left, top, left + size[0], top + size[1]))
    im.save(path, optimize=True)


def main():
    in_dir, out_dir, store_json, font = sys.argv[1:5]
    app = os.environ.get("APP_NAME", "App")
    os.makedirs(out_dir, exist_ok=True)
    report = {}
    for platform, (store, raw_size) in PLATFORMS.items():
        src = os.path.join(in_dir, platform)
        if not os.path.isdir(src):
            print(f"skip {platform}: no input")
            continue
        device_txt = os.path.join(src, "device.txt")
        device = open(device_txt).read().strip() if os.path.exists(device_txt) else platform
        info = {"device": device}
        video_name = f"{app}_{device.split('|')[0].replace(' ', '')}.mp4"
        try:
            info["video"] = process_video(src, os.path.join(out_dir, "videos"), video_name)
        except Exception as e:  # noqa: BLE001 - 單一平台失敗時仍處理截圖
            info["video_error"] = repr(e)
        shots = os.path.join(src, "shots")
        if os.path.isdir(shots) and os.listdir(shots):
            raw_out = os.path.join(out_dir, "screenshots", f"{platform}_raw")
            os.makedirs(raw_out, exist_ok=True)
            for f in sorted(os.listdir(shots)):
                shutil.copy(os.path.join(shots, f), raw_out)
                if raw_size:
                    fit_exact(os.path.join(raw_out, f), raw_size)
            subprocess.check_call([sys.executable, os.path.join(HERE, "store_shots.py"), shots,
                                   os.path.join(out_dir, "screenshots", store), store, store_json, font])
            info["screenshots"] = sorted(os.listdir(shots))
        report[platform] = info
    with open(os.path.join(out_dir, "report.json"), "w", encoding="utf-8") as fh:
        json.dump(report, fh, ensure_ascii=False, indent=2)
    print(json.dumps(report, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
