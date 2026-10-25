#!/usr/bin/env python3
"""把模擬器截圖排版成上架用的宣傳圖（標語 + 帶外框的手機畫面）。

Usage: python3 tool/ci/store_shots.py <shots_dir> <out_dir> <appstore|googleplay> <store.json> <font.ttf>

- appstore：1320x2868（iPhone 6.9 吋，App Store Connect 必填尺寸）
- googleplay：1080x1920（9:16；Play 要求長邊不超過短邊兩倍，Pixel 原始截圖通常超過）

store.json 範例見 tool/ci/store.json：
{
  "theme": {"top": "#34125C", "bottom": "#0E061C", "title": "#FFEFC2",
            "subtitle": "#FF7A1A", "glow": "#FF7A1A", "stars": true, "moon": true},
  "captions": {"01_home": ["主標", "副標"], ...},
  "default_caption": ["App 名稱", ""]
}
"""
import glob
import json
import os
import random
import sys

from PIL import Image, ImageDraw, ImageFilter, ImageFont

SIZES = {"appstore": (1320, 2868), "googleplay": (1080, 1920)}
DEFAULT_THEME = {
    "top": "#34125C", "bottom": "#0E061C", "title": "#FFEFC2", "subtitle": "#FF7A1A",
    "glow": "#FF7A1A", "frame": "#080310", "stars": True, "moon": False,
}


def rgb(hex_color):
    h = hex_color.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def font(path, size, weight):
    f = ImageFont.truetype(path, size)
    try:
        f.set_variation_by_axes([weight])  # 可變字型（例如 Noto Sans TC）調粗細
    except Exception:  # noqa: BLE001 - 非可變字型就用預設粗細
        pass
    return f


def background(w, h, theme):
    top, bottom = rgb(theme["top"]), rgb(theme["bottom"])
    bg = Image.new("RGB", (w, h))
    d = ImageDraw.Draw(bg)
    for y in range(h):
        t = y / h
        d.line([(0, y), (w, y)], fill=tuple(int(top[i] + (bottom[i] - top[i]) * t) for i in range(3)))
    if theme.get("stars"):
        rnd = random.Random(31)
        for _ in range(90):
            x, y, r = rnd.random() * w, rnd.random() * h * 0.45, rnd.random() * w * 0.003 + 1
            d.ellipse((x - r, y - r, x + r, y + r), fill=(255, 255, 255))
    if theme.get("moon"):
        moon = rgb(theme["title"])
        r = int(w * 0.13)
        cx, cy = int(w * 0.97), int(w * 0.02)
        glow = Image.new("L", (w, h), 0)
        ImageDraw.Draw(glow).ellipse((cx - r * 2, cy - r * 2, cx + r * 2, cy + r * 2), fill=110)
        glow = glow.filter(ImageFilter.GaussianBlur(r * 0.6))
        bg = Image.composite(Image.new("RGB", (w, h), moon), bg, glow)
        ImageDraw.Draw(bg).ellipse((cx - r, cy - r, cx + r, cy + r), fill=moon)
    return bg


def rounded(img, radius):
    mask = Image.new("L", img.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, img.width - 1, img.height - 1), radius=radius, fill=255)
    out = img.convert("RGBA")
    out.putalpha(mask)
    return out


def compose(shot_path, target, config, font_path):
    w, h = SIZES[target]
    theme = {**DEFAULT_THEME, **config.get("theme", {})}
    name = os.path.splitext(os.path.basename(shot_path))[0]
    title, subtitle = config.get("captions", {}).get(name, config.get("default_caption", ["", ""]))
    canvas = background(w, h, theme).convert("RGBA")
    d = ImageDraw.Draw(canvas)

    # 標語自動縮小到畫面寬度的 86% 以內
    size = int(w * 0.085)
    title_font = font(font_path, size, 900)
    while title and d.textlength(title, font=title_font) > w * 0.86:
        size -= 4
        title_font = font(font_path, size, 900)
    sub_size = int(w * 0.042)
    sub_font = font(font_path, sub_size, 500)
    while subtitle and d.textlength(subtitle, font=sub_font) > w * 0.9:
        sub_size -= 2
        sub_font = font(font_path, sub_size, 500)
    ty = int(h * 0.085)
    d.text((w / 2, ty), title, font=title_font, fill=rgb(theme["title"]), anchor="mt")
    tb = d.textbbox((w / 2, ty), title or " ", font=title_font, anchor="mt")
    d.text((w / 2, tb[3] + int(w * 0.03)), subtitle, font=sub_font, fill=rgb(theme["subtitle"]), anchor="mt")

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
                                            radius=int(sw * 0.09) + border, fill=rgb(theme["frame"]) + (255,))
    shadow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle(
        (x - border, top - border + 20, x + sw + border, top + sh + border + 20),
        radius=int(sw * 0.1), fill=rgb(theme["glow"]) + (90,))
    canvas = Image.alpha_composite(canvas, shadow.filter(ImageFilter.GaussianBlur(40)))
    canvas.alpha_composite(frame, (x - border, top - border))
    canvas.alpha_composite(shot, (x, top))
    return canvas.convert("RGB")


def main():
    shots_dir, out_dir, target, store_json, font_path = sys.argv[1:6]
    config = json.load(open(store_json, encoding="utf-8")) if os.path.exists(store_json) else {}
    os.makedirs(out_dir, exist_ok=True)
    for path in sorted(glob.glob(os.path.join(shots_dir, "*.png"))):
        out = os.path.join(out_dir, os.path.basename(path))
        compose(path, target, config, font_path).save(out, optimize=True)
        print("wrote", out)


if __name__ == "__main__":
    main()
