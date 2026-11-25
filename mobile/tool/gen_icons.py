"""Generates Android (legacy + adaptive) and iOS launcher icons from the Pesa
mark: navy tile, emerald 'P' stroke, gold dot. Re-run after brand changes:
    python3 tool/gen_icons.py
"""
import json, os
from PIL import Image, ImageDraw

NAVY, EMERALD, GOLD = (11, 27, 43), (16, 185, 129), (245, 184, 65)
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

def mark(size, rounded=True, scale=1.0, bg=True):
    ss = 4  # supersample for smooth edges
    S = size * ss
    img = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    if bg:
        if rounded:
            d.rounded_rectangle([0, 0, S - 1, S - 1], radius=int(S * 0.28), fill=NAVY)
        else:
            d.rectangle([0, 0, S, S], fill=NAVY)
    u = S / 32 * scale
    off = S / 2 - 16 * u
    P = lambda x, y: (off + x * u, off + y * u)
    w = int(3 * u)
    # Stem and bowl of the P (matches the in-app CustomPainter geometry).
    d.line([P(10, 23), P(10, 9), P(17, 9)], fill=EMERALD, width=w, joint='curve')
    # PIL strokes arcs inside the box, so grow it by half the stroke width.
    (ax0, ay0), (ax1, ay1) = P(12, 9), P(22, 19)
    d.arc([ax0 - w / 2, ay0 - w / 2, ax1 + w / 2, ay1 + w / 2], start=-90, end=90, fill=EMERALD, width=w)
    d.line([P(17, 19), P(13.5, 19)], fill=EMERALD, width=w)
    for (x, y) in [P(10, 23), P(10, 9), P(13.5, 19)]:
        d.ellipse([x - w / 2, y - w / 2, x + w / 2, y + w / 2], fill=EMERALD)
    cx, cy = P(22.5, 22.5)
    r = 2.5 * u
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=GOLD)
    return img.resize((size, size), Image.LANCZOS)

res = os.path.join(ROOT, 'android/app/src/main/res')
for dens, px in {'mdpi': 48, 'hdpi': 72, 'xhdpi': 96, 'xxhdpi': 144, 'xxxhdpi': 192}.items():
    mark(px).save(f'{res}/mipmap-{dens}/ic_launcher.png')
    fg = Image.new('RGBA', (px * 9 // 4, px * 9 // 4), (0, 0, 0, 0))  # 108dp canvas, 72dp safe zone
    m = mark(px * 3 // 2, bg=False)
    fg.paste(m, ((fg.width - m.width) // 2, (fg.height - m.height) // 2), m)
    fg.save(f'{res}/mipmap-{dens}/ic_launcher_foreground.png')
os.makedirs(f'{res}/mipmap-anydpi-v26', exist_ok=True)
open(f'{res}/mipmap-anydpi-v26/ic_launcher.xml', 'w').write(
    '<?xml version="1.0" encoding="utf-8"?>\n<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
    '    <background android:drawable="@color/ic_launcher_background"/>\n    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>\n'
    '    <monochrome android:drawable="@mipmap/ic_launcher_foreground"/>\n</adaptive-icon>\n')
os.makedirs(f'{res}/values', exist_ok=True)
open(f'{res}/values/colors.xml', 'w').write(
    '<?xml version="1.0" encoding="utf-8"?>\n<resources>\n    <color name="ic_launcher_background">#0B1B2B</color>\n    <color name="splash_background">#06111C</color>\n</resources>\n')

ios = os.path.join(ROOT, 'ios/Runner/Assets.xcassets/AppIcon.appiconset')
contents = json.load(open(f'{ios}/Contents.json'))
for img in contents['images']:
    if 'filename' not in img:
        continue
    size = float(img['size'].split('x')[0]) * int(img['scale'].replace('x', ''))
    # iOS applies its own corner mask and rejects alpha on the marketing icon.
    mark(int(round(size)), rounded=False).convert('RGB').save(f"{ios}/{img['filename']}")
print('icons generated')
