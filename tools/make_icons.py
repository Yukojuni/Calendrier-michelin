"""Génère les icônes de l'app (web, Android, iOS) : le pneu-sourire jaune sur fond bleu nuit."""
import json, pathlib
from PIL import Image, ImageDraw

NAVY, STUD, YELLOW = (16, 26, 51), (51, 65, 106), (252, 229, 0)


def draw(size, padding=0.0, background=True):
    s = 1024
    im = Image.new("RGBA", (s, s), NAVY + (255,) if background else (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    c, r = s / 2, s / 2 * (1 - padding) * 0.86
    d.ellipse([c - r, c - r, c + r, c + r], fill=(26, 38, 72))
    for dx, dy in [(0, -1), (0, 1), (-1, 0), (1, 0)]:
        x, y, rs = c + dx * r * 0.82, c + dy * r * 0.82, r * 0.09
        d.ellipse([x - rs, y - rs, x + rs, y + rs], fill=STUD)
    ri = r * 0.6
    d.ellipse([c - ri, c - ri, c + ri, c + ri], fill=YELLOW)
    for ex in (-0.2, 0.2):
        x, y, re = c + ex * r, c - 0.09 * r, r * 0.09
        d.ellipse([x - re, y - re, x + re, y + re], fill=NAVY)
    w = int(r * 0.09)
    d.arc([c - r * 0.25, c - r * 0.12, c + r * 0.25, c + r * 0.3], start=20, end=160, fill=NAVY, width=w)
    return im.resize((size, size), Image.LANCZOS)


def save(path, size, **kw):
    p = pathlib.Path(path)
    if not p.parent.exists():
        return
    draw(size, **kw).convert("RGBA" if p.suffix == ".png" else "RGB").save(p)


# Web
save("web/favicon.png", 64)
save("web/icons/Icon-192.png", 192)
save("web/icons/Icon-512.png", 512)
save("web/icons/Icon-maskable-192.png", 192, padding=0.2)
save("web/icons/Icon-maskable-512.png", 512, padding=0.2)
# Android
for name, px in {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}.items():
    save(f"android/app/src/main/res/mipmap-{name}/ic_launcher.png", px)
# iOS (sans transparence)
ios = pathlib.Path("ios/Runner/Assets.xcassets/AppIcon.appiconset")
if ios.exists():
    for img in json.load(open(ios / "Contents.json"))["images"]:
        fn = img.get("filename")
        if not fn:
            continue
        pt = float(img["size"].split("x")[0])
        scale = int(img["scale"].rstrip("x"))
        draw(int(pt * scale)).convert("RGB").save(ios / fn)
print("icônes générées")
