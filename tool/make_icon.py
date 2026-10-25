#!/usr/bin/env python3
"""Draw the app icon (assets/icon/app_icon.png, 1024x1024, no alpha)."""
import math
import os

from PIL import Image, ImageDraw, ImageFilter

N = 2048  # supersampled canvas
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "icon")


def radial_bg():
    bg = Image.new("RGB", (N, N))
    px = bg.load()
    inner, outer = (92, 38, 140), (18, 8, 38)
    cx, cy = N * 0.5, N * 0.38
    for y in range(N):
        for x in range(0, N):
            t = min(1.0, math.hypot(x - cx, y - cy) / (N * 0.8))
            px[x, y] = tuple(int(inner[i] + (outer[i] - inner[i]) * t) for i in range(3))
    return bg


def bat(d, cx, cy, s, fill):
    right = [(0.12, -0.22), (0.16, -0.08), (0.45, -0.32), (0.8, -0.42), (1.0, -0.3),
             (0.82, -0.12), (0.7, 0.02), (0.55, -0.06), (0.42, 0.06), (0.28, -0.02), (0.14, 0.12), (0, 0.2)]
    left = [(-x, y) for x, y in reversed(right)]
    pts = right + left + [(-0.12, -0.22), (-0.06, -0.12), (0.06, -0.12)]
    d.polygon([(cx + x * s, cy + y * s) for x, y in pts], fill=fill)


def main():
    img = radial_bg()

    # Moon with soft glow
    glow = Image.new("L", (N, N), 0)
    ImageDraw.Draw(glow).ellipse((1180, 230, 1820, 870), fill=255)
    glow = glow.filter(ImageFilter.GaussianBlur(90))
    img = Image.composite(Image.new("RGB", (N, N), (255, 236, 170)), img, glow.point(lambda v: v * 0.55))
    d = ImageDraw.Draw(img)
    d.ellipse((1260, 310, 1740, 790), fill=(255, 240, 190))
    for (x, y, r) in [(1420, 450, 50), (1580, 600, 70), (1450, 660, 35)]:
        d.ellipse((x - r, y - r, x + r, y + r), fill=(240, 220, 160))

    bat(d, 480, 470, 260, (14, 5, 28))
    bat(d, 900, 300, 150, (14, 5, 28))

    # Pumpkin body: overlapping ribs drawn back to front
    cx, cy, w, h = N // 2, 1360, 940, 1080
    ribs = [(-0.42, 0.40, (206, 86, 12)), (0.42, 0.40, (206, 86, 12)),
            (-0.21, 0.42, (228, 104, 18)), (0.21, 0.42, (228, 104, 18)), (0, 0.40, (246, 126, 28))]
    for off, rw, col in ribs:
        x0 = cx + off * w - rw * w
        x1 = cx + off * w + rw * w
        d.ellipse((x0, cy - h / 2, x1, cy + h / 2), fill=col, outline=(170, 66, 6), width=12)

    # Stem
    d.polygon([(cx - 70, cy - h / 2 + 40), (cx - 40, cy - h / 2 - 180), (cx + 90, cy - h / 2 - 230),
               (cx + 110, cy - h / 2 - 180), (cx + 30, cy - h / 2 - 140), (cx + 70, cy - h / 2 + 40)],
              fill=(70, 110, 40))

    # Carved face with inner glow
    face = Image.new("L", (N, N), 0)
    fd = ImageDraw.Draw(face)
    fd.polygon([(cx - 420, cy - 70), (cx - 170, cy - 70), (cx - 300, cy - 300)], fill=255)
    fd.polygon([(cx + 420, cy - 70), (cx + 170, cy - 70), (cx + 300, cy - 300)], fill=255)
    fd.polygon([(cx - 70, cy + 40), (cx + 70, cy + 40), (cx, cy - 90)], fill=255)
    mouth = [(cx - 520, cy + 120)]
    teeth = 7
    for i in range(teeth * 2 + 1):
        t = i / (teeth * 2)
        x = cx - 520 + 1040 * t
        base = cy + 120 + math.sin(t * math.pi) * 260
        mouth.append((x, base - (90 if i % 2 else 0)))
    mouth += [(cx + 520, cy + 120)]
    lower = [(cx + 520 - 1040 * t, cy + 120 + math.sin(t * math.pi) * 400) for t in [i / 20 for i in range(21)]]
    fd.polygon(mouth + lower, fill=255)
    halo = face.filter(ImageFilter.GaussianBlur(40))
    img = Image.composite(Image.new("RGB", (N, N), (255, 200, 60)), img, halo.point(lambda v: v * 0.6))
    img = Image.composite(Image.new("RGB", (N, N), (255, 230, 110)), img, face)
    inner = face.filter(ImageFilter.GaussianBlur(12)).point(lambda v: 255 if v > 200 else 0)
    img = Image.composite(Image.new("RGB", (N, N), (255, 248, 200)), img, inner.filter(ImageFilter.GaussianBlur(10)))

    os.makedirs(OUT, exist_ok=True)
    final = img.resize((1024, 1024), Image.LANCZOS)
    final.save(os.path.join(OUT, "app_icon.png"))
    # Foreground for Android adaptive icon: same art inset on transparent background.
    fg = Image.new("RGBA", (1024, 1024), (0, 0, 0, 0))
    fg.paste(final.resize((680, 680), Image.LANCZOS), (172, 172))
    mask = Image.new("L", (1024, 1024), 0)
    ImageDraw.Draw(mask).ellipse((172, 172, 852, 852), fill=255)
    fg.putalpha(mask)
    fg.save(os.path.join(OUT, "app_icon_foreground.png"))


if __name__ == "__main__":
    main()
