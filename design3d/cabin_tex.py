"""Tiling material pictures for the cabin and the dock (the owner, 2026-11-15: "details for materials so they come out well").
    python design3d/cabin_tex.py        writes design3d/tex/cabin_*.png (512 or 1024 px, each tiles in both directions)
logs: round peeled logs laid across, honey brown, a dark chinking line between courses (one course = half the picture height)
ends: end grain with growth rings        roof: standing-seam metal, grey-blue, ribs running down the slope, rust streaks
stone: fieldstones in pale mortar        planks: weathered deck boards with nail heads
The log grain comes from the CC0 nature kit's bark (Overnight/downloads/forge_nature), turned and recoloured."""
import pathlib
import numpy as np
from PIL import Image, ImageFilter

here = pathlib.Path(__file__).resolve().parent
root = here.parent.parent.parent
tex = here / "tex"
rng = np.random.default_rng(21)
S = 512


def rgb(h): h = h.lstrip("#"); return np.array([int(h[i:i + 2], 16) for i in (0, 2, 4)], dtype=np.float64)


def tile_noise(n, size=S, blur=0.0):
    a = rng.random((n, n))
    im = Image.fromarray((np.tile(a, (3, 3)) * 255).astype(np.uint8)).resize((size * 3, size * 3), Image.BICUBIC)
    if blur: im = im.filter(ImageFilter.GaussianBlur(blur))
    return np.asarray(im, dtype=np.float64)[size:2 * size, size:2 * size] / 255.0


def save(name, img): Image.fromarray(np.clip(img, 0, 255).astype(np.uint8), "RGB").save(tex / name); print("wrote", name)


yy, xx = np.mgrid[0:S, 0:S] / S

# logs: two courses per tile; each course is lit on top and dark underneath, with long grain and a few knots
grain = np.asarray(Image.open(root / "Overnight" / "downloads" / "forge_nature" / "kit" / "glTF" / "Bark_NormalTree.png").convert("L").rotate(90).resize((S, S), Image.LANCZOS), dtype=np.float64) / 255.0
v = (yy * 2) % 1.0                                   # 0..1 down one log
round_ = np.sin(np.pi * v) ** 0.55                   # the log's roundness as light
base = rgb("#b5763c")[None, None] * (0.5 + 0.7 * round_[..., None]) * (0.8 + 0.45 * grain[..., None])  # honey brown, measured on refs/forge/sheets/cabin_views
base = base * (0.9 + 0.2 * tile_noise(6)[..., None])
streak = tile_noise(48)[:, :1] * np.ones((1, S))     # long streaks along the log
base = base * (0.92 + 0.16 * streak[..., None])
for _ in range(7):                                    # knots
    cx, cy, r = rng.random(), (rng.integers(0, 2) + 0.5) / 2 + rng.uniform(-0.1, 0.1), rng.uniform(0.012, 0.03)
    d = np.hypot(np.minimum(np.abs(xx - cx), 1 - np.abs(xx - cx)) * 0.6, yy - cy) / r
    base = base * (1 - 0.6 * np.clip(1 - d, 0, 1)[..., None]) + rgb("#4a3020") * (0.6 * np.clip(1 - d, 0, 1)[..., None])
chink = np.clip(1 - np.abs(v - 0.0) / 0.05, 0, 1) + np.clip(1 - np.abs(v - 1.0) / 0.05, 0, 1)
base = base * (1 - 0.75 * chink[..., None]) + rgb("#2c2019") * (0.75 * chink[..., None])
save("cabin_logs.png", base)

# end grain: rings round the middle of the tile
r = np.hypot(xx - 0.5, yy - 0.5) * 2
rings = 0.5 + 0.5 * np.sin(r * 46 + tile_noise(5) * 5)
end = rgb("#c9a070")[None, None] * (0.78 + 0.22 * rings[..., None]) * (1.05 - 0.3 * np.clip(r, 0, 1)[..., None])
for a in rng.random(5) * np.pi:                       # drying cracks from the heart
    crack = np.clip(1 - np.abs((xx - 0.5) * np.sin(a) - (yy - 0.5) * np.cos(a)) / 0.006, 0, 1) * np.clip(1 - r / 0.7, 0, 1)
    end = end * (1 - 0.6 * crack[..., None])
save("cabin_ends.png", end)

# roof: rows of rounded shingles, as on the reference sheet: grey-blue, each tab its own tone, a shadow under the row above
ROWS, TABS = 8, 8
rv = yy * ROWS; ri = np.floor(rv).astype(int); v2 = rv - ri
tu = xx * TABS + (ri % 2) * 0.5; ti = np.floor(tu).astype(int); u2 = tu - ti
tone = (np.sin(ri * 12.9898 + (ti % TABS) * 78.233) * 43758.5453) % 1.0
roof = rgb("#8797a8")[None, None] * (0.86 + 0.24 * tone[..., None]) * (0.92 + 0.14 * tile_noise(32)[..., None])
scallop = 1 - 0.3 * (1 - np.sqrt(np.clip(1 - (2 * u2 - 1) ** 2, 0, 1)))          # where the tab's rounded lower edge ends
below = v2 > scallop                                                            # past the edge: the next row shows, in shadow
roof = roof * (1 - 0.42 * below[..., None])
roof = roof * (0.72 + 0.28 * np.clip(v2 / 0.3, 0, 1)[..., None])                 # shadow cast by the row above
roof = roof * (1 + 0.16 * np.clip(1 - np.abs(v2 - scallop + 0.05) / 0.05, 0, 1)[..., None] * (~below)[..., None])   # a lit lip
gapx = np.clip(1 - np.minimum(u2, 1 - u2) / 0.03, 0, 1) * (~below)
roof = roof * (1 - 0.4 * gapx[..., None])
moss = np.clip(tile_noise(7) - 0.74, 0, 1) * 2.5
roof = roof * (1 - moss[..., None]) + rgb("#6f8a5c") * moss[..., None]
save("cabin_roof.png", roof)

# fieldstone: a tiling Voronoi of rounded stones with pale mortar between
pts = rng.random((46, 2)); cols = [rgb(c) for c in ("#8d8c92", "#74727a", "#a3a1a0", "#8a7a6c", "#9a8f86", "#6c6b74")]
d1 = np.full((S, S), 9.0); d2 = np.full((S, S), 9.0); who = np.zeros((S, S), dtype=int)
for k, (px, py) in enumerate(pts):
    dx = np.minimum(np.abs(xx - px), 1 - np.abs(xx - px)); dy = np.minimum(np.abs(yy - py), 1 - np.abs(yy - py))
    d = np.hypot(dx, dy)
    closer = d < d1
    d2 = np.where(closer, d1, np.minimum(d2, d)); who = np.where(closer, k, who); d1 = np.where(closer, d, d1)
edge = np.clip((d2 - d1) / 0.03, 0, 1)                # 0 on a joint, 1 inside a stone
stone = np.zeros((S, S, 3))
for k in range(len(pts)): stone[who == k] = cols[k % len(cols)] * (0.9 + 0.2 * rng.random())
stone = stone * (0.8 + 0.35 * tile_noise(24)[..., None]) * (0.7 + 0.3 * edge[..., None] ** 0.5)
stone = stone * edge[..., None] + rgb("#c9c0b0") * (1 - edge[..., None]) * 0.9
save("cabin_stone.png", stone)

# planks: six boards down the tile, each its own tone, a dark gap, two nail heads
b = (yy * 6); bi = np.floor(b).astype(int); bv = b - bi
tone = np.array([0.86, 1.0, 0.92, 1.06, 0.9, 0.98])[bi]
plank = rgb("#8f5c36")[None, None] * tone[..., None] * (0.85 + 0.3 * (tile_noise(64)[:, :1] * np.ones((1, S)) * 0.5 + tile_noise(96) * 0.5)[..., None])
gap = np.clip(1 - np.minimum(bv, 1 - bv) / 0.05, 0, 1)
plank = plank * (1 - 0.7 * gap[..., None])
for k in range(6):
    for nx in (0.08, 0.58):
        d = np.hypot(xx - (nx + 0.03 * (k % 2)), yy - (k + 0.5) / 6) / 0.012
        plank = plank * (1 - 0.7 * np.clip(1 - d, 0, 1)[..., None])
save("cabin_planks.png", plank)
