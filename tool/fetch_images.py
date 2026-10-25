#!/usr/bin/env python3
"""Search Wikimedia Commons for freely licensed monster images.

Runs on the GitHub runner (which has open internet access). For every monster
it downloads a few candidates into `candidates/<id>/` together with the
license/author metadata and a labelled contact sheet for review.

Usage: python3 tool/fetch_images.py [out_dir]
"""
import json
import os
import re
import sys
import time
import urllib.parse
import urllib.request

from PIL import Image, ImageDraw, ImageFont

API = "https://commons.wikimedia.org/w/api.php"
UA = "HalloweenMonsterApp/1.0 (https://github.com/PeterPanSwift/HalloweenMonster)"
PER_MONSTER = 6

MONSTERS = {
    "jack_o_lantern": ["jack-o'-lantern carved pumpkin", "Halloween pumpkin lantern night"],
    "vampire": ["Nosferatu 1922 Max Schreck", "Burne-Jones The Vampire 1897", "Varney the Vampire illustration"],
    "werewolf": ["loup-garou illustration", "werewolf illustration 19th century", "Cranach werewolf woodcut"],
    "frankenstein": ["Frankenstein 1831 frontispiece", "Frankenstein Edison 1910 film"],
    "mummy": ["Egyptian mummy museum", "mummy British Museum"],
    "witch": ["Halloween postcard witch", "witch broomstick illustration", "Goya Witches Flight"],
    "ghost": ["Halloween postcard ghost", "Pepper's ghost illustration", "ghost spectre engraving"],
    "skeleton": ["Posada Calavera Catrina", "skeleton dance danse macabre"],
    "headless_horseman": ["Quidor Headless Horseman Ichabod Crane", "Headless Horseman illustration"],
    "banshee": ["banshee illustration", "banshee Ireland legend"],
}

OK_LICENSE = re.compile(r"^(public domain|pd|cc0|cc[- ]by)", re.I)


def get(url, params=None):
    if params:
        url = url + "?" + urllib.parse.urlencode(params)
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    for attempt in range(4):
        try:
            with urllib.request.urlopen(req, timeout=60) as r:
                return r.read()
        except Exception as e:  # noqa: BLE001
            print(f"  retry {attempt + 1}: {e}", file=sys.stderr)
            time.sleep(2 ** attempt)
    raise RuntimeError(f"failed: {url}")


def strip_html(s):
    return re.sub(r"<[^>]+>", "", s or "").strip()


def search(query):
    data = json.loads(get(API, {
        "action": "query", "format": "json", "generator": "search",
        "gsrsearch": f"{query} filetype:bitmap", "gsrnamespace": 6, "gsrlimit": 12,
        "prop": "imageinfo", "iiprop": "url|size|extmetadata", "iiurlwidth": 1200,
        "iiextmetadatafilter": "LicenseShortName|Artist|LicenseUrl",
    }))
    pages = sorted(data.get("query", {}).get("pages", {}).values(), key=lambda p: p.get("index", 0))
    for p in pages:
        info = (p.get("imageinfo") or [{}])[0]
        meta = info.get("extmetadata", {})
        lic = strip_html(meta.get("LicenseShortName", {}).get("value", ""))
        if not OK_LICENSE.match(lic) or info.get("width", 0) < 500:
            continue
        yield {
            "title": p["title"],
            "page": info.get("descriptionurl"),
            "thumb": info.get("thumburl") or info.get("url"),
            "license": lic,
            "license_url": meta.get("LicenseUrl", {}).get("value", ""),
            "artist": strip_html(meta.get("Artist", {}).get("value", ""))[:200],
        }


def contact_sheet(out_dir, mid, files):
    tiles = []
    for f in files:
        im = Image.open(f).convert("RGB")
        im.thumbnail((400, 400))
        tile = Image.new("RGB", (410, 440), "white")
        tile.paste(im, ((410 - im.width) // 2, 5))
        ImageDraw.Draw(tile).text((8, 415), os.path.basename(f), fill="black",
                                  font=ImageFont.load_default(size=18))
        tiles.append(tile)
    if not tiles:
        return
    sheet = Image.new("RGB", (410 * len(tiles), 440), "white")
    for i, t in enumerate(tiles):
        sheet.paste(t, (410 * i, 0))
    sheet.save(os.path.join(out_dir, f"_sheet_{mid}.jpg"), quality=80)


def main():
    out_dir = sys.argv[1] if len(sys.argv) > 1 else "candidates"
    os.makedirs(out_dir, exist_ok=True)
    report = {}
    only = [m for m in os.environ.get("ONLY", "").split(",") if m]
    for mid, queries in MONSTERS.items():
        if only and mid not in only:
            continue
        print(f"== {mid}")
        seen, picks = set(), []
        for q in queries:
            try:
                for c in search(q):
                    if c["title"] not in seen and len(picks) < PER_MONSTER:
                        seen.add(c["title"])
                        picks.append(c)
            except Exception as e:  # noqa: BLE001
                print(f"  search failed: {e}", file=sys.stderr)
        mdir = os.path.join(out_dir, mid)
        os.makedirs(mdir, exist_ok=True)
        files = []
        for i, c in enumerate(picks):
            path = os.path.join(mdir, f"{i}.jpg")
            try:
                raw = get(c["thumb"])
                tmp = path + ".src"
                with open(tmp, "wb") as fh:
                    fh.write(raw)
                im = Image.open(tmp).convert("RGB")
                im.thumbnail((1200, 1200))
                im.save(path, quality=85)
                os.remove(tmp)
                c["file"] = path
                files.append(path)
                print(f"  {i}: {c['title']} [{c['license']}]")
            except Exception as e:  # noqa: BLE001
                print(f"  download failed {c['title']}: {e}", file=sys.stderr)
        report[mid] = [c for c in picks if "file" in c]
        contact_sheet(out_dir, mid, files)
    with open(os.path.join(out_dir, "candidates.json"), "w", encoding="utf-8") as fh:
        json.dump(report, fh, ensure_ascii=False, indent=2)


if __name__ == "__main__":
    main()
