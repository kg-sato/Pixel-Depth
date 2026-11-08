"""Roblox texture set for Pixel Depths (2026-11-08): block faces for all seven layers, rare blocks, grass, walls, caves.
32 px pixel art from pd_art.py (same ramps and helpers), upscaled 8x nearest-neighbour to 256 px so Roblox's bilinear
filtering keeps the pixels crisp. Usage: python pd_roblox.py <out_dir>  -> <out_dir>/<name>.png + sheet.png"""
import os, random, sys

OUT = sys.argv[1] if len(sys.argv) > 1 else "roblox_tex"
sys.argv = [sys.argv[0], os.path.join(OUT, "_pd_art_tmp")]
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import pd_art as A  # noqa: E402
from PIL import Image  # noqa: E402

os.makedirs(OUT, exist_ok=True)
H, N = A.H, A.N


def ramp(*hexes):
    return [H(h) for h in hexes]


# per layer: base ramp, ore2 (kind, ramp), ore3 (kind, ramp); kinds: crystal or nugget
LAYERS = [
    ("rootholm", A.R["dirt"], ("crystal", A.R["coal"]), ("nugget", A.R["copper"])),
    ("titan", ramp("#4a2230", "#7a3438", "#a8503e", "#cf7550", "#ec9f72", "#ffd0a8"),
     ("nugget", ramp("#3a2f36", "#5e5058", "#867884", "#b2a6b2", "#e2dae2")), ("crystal", ramp("#4a4a5e", "#7a7a92", "#aeb0c6", "#dcdff0", "#ffffff"))),
    ("glitter", ramp("#161a3e", "#232c5e", "#344283", "#4a5fa8", "#6a86c8", "#9cb6e6"),
     ("crystal", A.R["lilac"]), ("crystal", ramp("#1b2a6e", "#2f4fb0", "#4f86e8", "#8ec0ff", "#e0f0ff"))),
    ("muspell", ramp("#2a0c18", "#4d1420", "#7a2026", "#a8382c", "#d0603a", "#f29a58"),
     ("crystal", ramp("#120a18", "#2a1630", "#4a2a52", "#7a4a82", "#b08ab8")), ("crystal", ramp("#5a0a1e", "#a01a34", "#e03a52", "#ff7a86", "#ffd0d4"))),
    ("mimir", ramp("#0e2a36", "#164452", "#21606c", "#2f8288", "#4ca8a6", "#86d2c6"),
     ("nugget", A.R["rose"] + [H("#ffe8ee")]), ("nugget", A.R["egg"])),
    ("alfglow", ramp("#1f1030", "#331a4a", "#4a2866", "#643a84", "#8458a4", "#a982c4"),
     ("crystal", ramp("#1e5a2a", "#3a8c3e", "#6cc44e", "#a8ec7e", "#e8ffd0")), ("nugget", ramp("#7a2e6a", "#b8509a", "#f08ccc", "#ffc8ec", "#fff0fa"))),
    ("gap", ramp("#0a0614", "#160c24", "#241236", "#38184a", "#521e62", "#76307e"),
     ("crystal", ramp("#3a0a4a", "#6e1a82", "#b82ed0", "#ee7cff", "#ffd8ff")), ("nugget", A.R["gold"])),
]


def ore(im, kind, rp, seed):
    rv = random.Random(seed)
    j = lambda a: a + rv.randint(-2, 2)
    A.glow_halo(im, 15, 17, 13, rp[3], 0.2)
    if kind == "crystal":
        for (bx, by, ang, L, Wd) in ((j(9), 26, -0.5 + rv.uniform(-.2, .2), 13, 8), (j(19), 25, 0.35 + rv.uniform(-.2, .2), 15, 9), (j(15), 27, rv.uniform(-.2, .2), 9, 6)):
            A.crystal(im, bx, by, ang, L, Wd, rp)
    else:
        A.nugget(im, j(11), j(19), 6.5, 5.5, rp)
        A.nugget(im, j(21), j(12), 4.5, 4.0, rp)
        A.nugget(im, j(22), j(24), 3.0, 2.6, rp)


def save(name, im):
    img = A.to_img(im) if isinstance(im, list) else im
    img.resize((N * 8, N * 8), Image.NEAREST).save(os.path.join(OUT, name + ".png"))
    return img


tiles = []
for li, (nm, base, o2, o3) in enumerate(LAYERS):
    for v in range(2):
        tiles.append(save(f"{nm}_base{v}", A.tex_dirt(11 + li * 131 + v * 97, ramp=base, pebbles=3 + v, roots=1 if li == 0 and v else 0)))
    b2 = A.tex_dirt(21 + li * 131, ramp=base, pebbles=2, roots=0)
    ore(b2, o2[0], o2[1], 300 + li)
    tiles.append(save(f"{nm}_ore2", b2))
    b3 = A.tex_dirt(31 + li * 131, ramp=base, pebbles=2, roots=0)
    ore(b3, o3[0], o3[1], 400 + li)
    tiles.append(save(f"{nm}_ore3", b3))
    deep = [A.lerp(c, A.COOL, 0.35) for c in base[:5]]
    tiles.append(save(f"{nm}_wall", A.tex_dirt(61 + li * 131, ramp=deep, pebbles=7, roots=2 if li < 2 else 0, bevel=False, base=2)))
    cave = [A.lerp(c, A.COOL, 0.62) for c in base[:5]]
    tiles.append(save(f"{nm}_cave", [[A.pick(cave, 0.15 + A.fbm(x / N, y / N, 71 + li, base=2) * 0.6 + A.fbm(x / N, y / N, 72 + li, base=8, octs=2) * 0.25, x, y, 0.1) for x in range(N)] for y in range(N)]))
T0 = A.make_textures(0)
for k in ("grass", "gilded", "egg"):
    tiles.append(save(k, T0[k]))
tiles.append(save("geode", A.tex_geode()))
tiles.append(save("amber_egg", A.tex_amber_egg()))

cols = 8
sheet = Image.new("RGB", (cols * 34, ((len(tiles) + cols - 1) // cols) * 34), (16, 12, 30))
for i, t in enumerate(tiles):
    sheet.paste(t, ((i % cols) * 34 + 1, (i // cols) * 34 + 1))
sheet.resize((sheet.width * 3, sheet.height * 3), Image.NEAREST).save(os.path.join(OUT, "_sheet.png"))
print(len(tiles), "textures ->", OUT)
