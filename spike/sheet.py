"""Contact sheet of captures: python spike/sheet.py out.jpg cols a.png b.png ...  (each cell 960 px wide)"""
import sys
from PIL import Image
out, cols, files = sys.argv[1], int(sys.argv[2]), sys.argv[3:]
ims = [Image.open(f).convert("RGB") for f in files]
w = 960; hs = [int(i.height * w / i.width) for i in ims]; h = max(hs)
rows = (len(ims) + cols - 1) // cols
sheet = Image.new("RGB", (w * cols, h * rows), (22, 8, 30))
for k, im in enumerate(ims): sheet.paste(im.resize((w, hs[k]), Image.LANCZOS), ((k % cols) * w, (k // cols) * h))
sheet.save(out, quality=88)
