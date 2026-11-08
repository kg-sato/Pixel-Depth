"""contact.py [out.jpg] : concept + hero render pairs for all ten pickaxes in one sheet"""
import glob, json, os, sys
from PIL import Image, ImageDraw
HERE = os.path.dirname(os.path.abspath(__file__))
W, H = 260, 390
sheet = Image.new("RGB", (W * 2 * 5, H * 2), (20, 16, 34))
for i in range(1, 11):
    tag = f"pick_{i:02d}"
    x, y = ((i - 1) % 5) * W * 2, ((i - 1) // 5) * H
    c = Image.open(os.path.join(HERE, "..", "art", "gen", tag + ".png")).convert("RGB").resize((W, H))
    sheet.paste(c, (x, y))
    h = glob.glob(os.path.join(HERE, "out", tag, "*_hero_fx.jpg"))
    if h:
        r = Image.open(h[0]).convert("RGB").resize((W, H))
        sheet.paste(r, (x + W, y))
    ImageDraw.Draw(sheet).text((x + 6, y + 6), tag, fill=(255, 255, 0))
dst = sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, "out", "_contact.jpg")
sheet.save(dst, quality=85)
print(dst)
