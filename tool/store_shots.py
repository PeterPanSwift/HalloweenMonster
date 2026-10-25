#!/usr/bin/env python3
"""把模擬器截圖排版成上架用的宣傳圖。

Usage: python3 tool/store_shots.py <shots_dir> <out_dir> <appstore|googleplay> <font.ttf>

- appstore：1320x2868（iPhone 6.9 吋，App Store Connect 必填尺寸）
- googleplay：1080x1920（9:16，符合 Google Play 手機截圖規範）
"""
import glob
import os
import random
import sys

from PIL import Image, ImageDraw, ImageFilter, ImageFont

SIZES = {"appstore": (1320, 2868), "googleplay": (1080, 1920)}

CAPTIONS = {
    "01_home": ("萬聖夜的妖怪全圖鑑", "10 隻經典傳說生物，一次認識"),
    "02_collection": ("恐怖指數一眼就懂", "用骷髏數量標示每隻妖怪有多可怕"),
    "03_detail": ("每隻妖怪都有專屬檔案", "起源、傳說、能力與弱點"),
    "04_story": ("看故事學冷知識", "成為最懂萬聖節的人"),
    "05_witch": ("經典插畫與老明信片", "圖片取自 Wikimedia Commons 公有領域作品"),
}

NIGHT_TOP = (52, 18, 92)
NIGHT_BOTTOM = (14, 6, 28)
PUMPKIN = (255, 122, 26)
MOON = (255, 239, 194)


def font(path, size, weight):
    f = ImageFont.truetype(path, size)
    try:
        f.set_variation_by_axes([weight])
    except Exception:  # noqa: BLE001 - 非可變字型
        pass
    return f


def background(w, h):
    bg = Image.new("RGB", (w, h))
    d = ImageDraw.Draw(bg)
    for y in range(h):
        t = y / h
        d.line([(0, y), (w, y)], fill=tuple(int(NIGHT_TOP[i] + (NIGHT_BOTTOM[i] - NIGHT_TOP[i]) * t) for i in range(3)))
    rnd = random.Random(31)
    for _ in range(90):
        x, y, r = rnd.random() * w, rnd.random() * h * 0.45, rnd.random() * w * 0.003 + 1
        d.ellipse((x - r, y - r, x + r, y + r), fill=(255, 255, 255, int(120 + rnd.random() * 135)))
    # 月亮
    r = int(w * 0.13)
    cx, cy = int(w * 0.97), int(w * 0.02)
    glow = Image.new("L", (w, h), 0)
    ImageDraw.Draw(glow).ellipse((cx - r * 2, cy - r * 2, cx + r * 2, cy + r * 2), fill=110)
    glow = glow.filter(ImageFilter.GaussianBlur(r * 0.6))
    bg = Image.composite(Image.new("RGB", (w, h), MOON), bg, glow)
    ImageDraw.Draw(bg).ellipse((cx - r, cy - r, cx + r, cy + r), fill=MOON)
    return bg


def rounded(img, radius):
    mask = Image.new("L", img.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, img.width - 1, img.height - 1), radius=radius, fill=255)
    out = img.convert("RGBA")
    out.putalpha(mask)
    return out


def compose(shot_path, target, font_path):
    w, h = SIZES[target]
    name = os.path.splitext(os.path.basename(shot_path))[0]
    title, subtitle = CAPTIONS.get(name, ("萬聖節妖怪圖鑑", ""))
    canvas = background(w, h).convert("RGBA")
    d = ImageDraw.Draw(canvas)

    size = int(w * 0.085)
    title_font = font(font_path, size, 900)
    while d.textlength(title, font=title_font) > w * 0.86:
        size -= 4
        title_font = font(font_path, size, 900)
    sub_font = font(font_path, int(w * 0.042), 500)
    ty = int(h * 0.085)
    d.text((w / 2, ty), title, font=title_font, fill=MOON, anchor="mt")
    tb = d.textbbox((w / 2, ty), title, font=title_font, anchor="mt")
    d.text((w / 2, tb[3] + int(w * 0.03)), subtitle, font=sub_font, fill=PUMPKIN, anchor="mt")

    shot = Image.open(shot_path).convert("RGB")
    top = int(h * 0.215)
    avail_h = h - top - int(h * 0.04)
    scale = min(avail_h / shot.height, (w * 0.86) / shot.width)
    sw, sh = int(shot.width * scale), int(shot.height * scale)
    shot = rounded(shot.resize((sw, sh), Image.LANCZOS), int(sw * 0.09))
    x = (w - sw) // 2

    border = int(sw * 0.022)
    frame = Image.new("RGBA", (sw + border * 2, sh + border * 2), (0, 0, 0, 0))
    ImageDraw.Draw(frame).rounded_rectangle((0, 0, frame.width - 1, frame.height - 1),
                                            radius=int(sw * 0.09) + border, fill=(8, 3, 16, 255))
    shadow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle(
        (x - border, top - border + 20, x + sw + border, top + sh + border + 20),
        radius=int(sw * 0.1), fill=(255, 122, 26, 90))
    canvas = Image.alpha_composite(canvas, shadow.filter(ImageFilter.GaussianBlur(40)))
    canvas.alpha_composite(frame, (x - border, top - border))
    canvas.alpha_composite(shot, (x, top))
    return canvas.convert("RGB")


def main():
    shots_dir, out_dir, target, font_path = sys.argv[1:5]
    os.makedirs(out_dir, exist_ok=True)
    for path in sorted(glob.glob(os.path.join(shots_dir, "*.png"))):
        out = os.path.join(out_dir, os.path.basename(path))
        compose(path, target, font_path).save(out, optimize=True)
        print("wrote", out)


if __name__ == "__main__":
    main()
