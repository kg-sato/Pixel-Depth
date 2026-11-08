"""Hub v4 store textures (2026-11-08): tiling 32 px pixel art for the camp stores and backdrop, in the pd_art.py
"Twilight Hollow" ramps (lights lean peach/cream, shadows lean lavender/plum). Upscaled 8x nearest to 256 px so
Roblox filtering keeps the pixels crisp. One tile = 4 studs in the game (8 px per stud, like the mine blocks).
References: art/hub/refs/README.md (Sketchfab voxel stall, blacksmith houses, cabin, quest board).
Usage: python pd_hub_tex.py [out_dir]"""
import math, os, random, sys

OUT = sys.argv[1] if len(sys.argv) > 1 else os.path.join("roblox_tex", "hub")
sys.argv = [sys.argv[0], os.path.join(OUT, "_tmp")]
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import pd_art as A  # noqa: E402
from PIL import Image  # noqa: E402

os.makedirs(OUT, exist_ok=True)
H, N, pick, fbm, hsh = A.H, A.N, A.pick, A.fbm, A.hsh
RAMP = {
    "plank": [H(h) for h in ("#4a2f36", "#6e4a45", "#93685a", "#b98a72", "#d8ab88")],
    "log": [H(h) for h in ("#3e2834", "#5c3c42", "#80584f", "#a57a62", "#c99c7a")],
    "logend": [H(h) for h in ("#6e4a45", "#b98a72", "#e2c09a", "#f2d8b4")],
    "stone": [H(h) for h in ("#3c3658", "#575080", "#7a72a6", "#a49ccb", "#cdc6ea")],
    "mortar": [H(h) for h in ("#4a405f", "#554a6a")],  # lavender-slate grout (round 4: black grout read as tiling noise)
    "cobble": [H(h) for h in ("#4d4468", "#675d88", "#8378a4", "#a097c0", "#c2badb")],
    "teal": [H(h) for h in ("#1f4a5a", "#2c6878", "#3f8a92", "#62aeae", "#9ad6cc")],
    "plum": [H(h) for h in ("#33244e", "#4a3570", "#634a90", "#8268b2", "#a891d2")],
    "moss": [H(h) for h in ("#245a56", "#347a6a", "#4c9c80", "#6ec7a6", "#a6ead0")],
    "rose": [H(h) for h in ("#8a3d5c", "#c25a7a", "#e87d97", "#ff9db0", "#ffc9d4")],
    "cream": [H(h) for h in ("#b8a4a8", "#d6c4c0", "#ece0d6", "#fbf3ea")],
    "beam": [H(h) for h in ("#2e1d2c", "#432a38", "#5c3c46", "#77525a")],
    "bark": [H(h) for h in ("#2a1a40", "#3b2558", "#4e3274", "#664392", "#8259ae")],
    "rock": [H(h) for h in ("#241a36", "#33264a", "#45345e", "#584474", "#6e588c")],
    "leaf": [H(h) for h in ("#173e44", "#225a58", "#2f786a", "#47987c", "#6cbc94")],
    "path": [H(h) for h in ("#5e4a5c", "#7c6470", "#9c8282", "#bca196", "#d8bfae")],
    "iron": [H(h) for h in ("#25203a", "#3a3456", "#544c78", "#766c9c")],
}


def img():
    return Image.new("RGB", (N, N))


def put(im, x, y, c):
    im.putpixel((x % N, y % N), c)


def planks(ramp="plank", board=8, seed=3):
    """Vertical boards with grain, a dark seam between boards, staggered butt joints and nail heads."""
    r = RAMP[ramp]
    im = img()
    for x in range(N):
        b = x // board
        bx = x % board
        tone = 0.35 + hsh(b, 0, seed) * 0.3
        for y in range(N):
            g = fbm(x / N * 0.25, y / N, seed + b, base=6, octs=2) * 0.35
            t = tone + g - (0.25 if bx == board - 1 else 0) + (0.12 if bx == 0 else 0)
            put(im, x, y, pick(r, t, x, y, 0.1))
        j = int(hsh(b, 1, seed) * N)  # butt joint
        for xx in range(board - 1):
            put(im, b * board + xx, j, r[0])
            put(im, b * board + xx, j + 1, r[3])
        for ny in (j + 3, j - 3):  # nails
            put(im, b * board + 1, ny, r[0])
            put(im, b * board + board - 3, ny, r[0])
    return im


def logs(seed=5):
    """Horizontal round logs, 8 px tall: lit top, shaded bottom, a dark gap, bark knots."""
    r = RAMP["log"]
    im = img()
    for y in range(N):
        ly = y % 8
        prof = [0.15, 0.55, 0.75, 0.7, 0.6, 0.5, 0.38, 0.0][ly]
        for x in range(N):
            g = fbm(x / N, y / N * 0.3, seed + y // 8, base=4, octs=2) * 0.25
            put(im, x, y, pick(r, prof + g - 0.1, x, y, 0.1) if ly != 7 else r[0])
    rv = random.Random(seed)
    for _ in range(5):
        x, y = rv.randrange(N), rv.randrange(4) * 8 + 3
        put(im, x, y, r[1]); put(im, x + 1, y, r[1]); put(im, x, y + 1, r[0])
    return im


def bricks(ramp="stone", bw=16, bh=8, seed=7, chips=True):
    """Offset bricks with plum mortar, per-brick tone, a lit top-left edge and a shaded bottom-right edge."""
    r, m = RAMP[ramp], RAMP["mortar"]
    im = img()
    for y in range(N):
        row = y // bh
        off = (row % 2) * bw // 2
        for x in range(N):
            xx = (x + off) % N
            bi = xx // bw
            lx, ly = xx % bw, y % bh
            if lx == bw - 1 or ly == bh - 1:
                put(im, x, y, m[(x + y) % 2])
                continue
            tone = 0.3 + hsh(bi, row, seed) * 0.35
            t = tone + fbm(x / N, y / N, seed, base=8, octs=2) * 0.25
            if ly == 0 or lx == 0:
                t += 0.22
            if ly == bh - 2 or lx == bw - 2:
                t -= 0.18
            put(im, x, y, pick(r, t, x, y, 0.1))
    if chips:
        rv = random.Random(seed)
        for _ in range(6):
            x, y = rv.randrange(N), rv.randrange(N)
            put(im, x, y, r[0])
    return im


def cobble(seed=11, n=9):
    """Rounded plaza stones on a tiling voronoi with dark grout and a lit top edge."""
    r, m = RAMP["cobble"], RAMP["mortar"]
    rv = random.Random(seed)
    pts = [(rv.uniform(0, N), rv.uniform(0, N), rv.random()) for _ in range(n)]
    im = img()
    for y in range(N):
        for x in range(N):
            ds = []
            for px, py, tone in pts:
                for ox in (-N, 0, N):
                    for oy in (-N, 0, N):
                        ds.append((math.hypot(x - px - ox, y - py - oy), py + oy, tone))
            ds.sort()
            (d1, cy, tone), d2 = ds[0], ds[1][0]
            if d2 - d1 < 1.3:
                put(im, x, y, m[(x * 3 + y) % 2])
            else:
                t = 0.3 + tone * 0.35 + (0.2 if y < cy - 1.5 else -0.1 if y > cy + 2 else 0) + (d2 - d1) * 0.015
                put(im, x, y, pick(r, t, x, y, 0.1))
    return im


def shingles(ramp, seed=13):
    """Overlapping roof shingles: 8 px rows, 6 px tiles offset each row, dark drop shadow under each row, lit lip."""
    r = RAMP[ramp]
    im = img()
    for y in range(N):
        row, ly = y // 8, y % 8
        off = (row % 2) * 4
        for x in range(N):
            xx = (x + off) % N
            ti = xx // 8
            lx = xx % 8
            tone = 0.35 + hsh(ti, row, seed) * 0.3
            t = tone + (0.25 if ly >= 6 else 0) - (0.35 if ly <= 1 else 0) + (-0.2 if lx == 7 else 0)
            t += fbm(x / N, y / N, seed, base=8, octs=1) * 0.15
            put(im, x, y, pick(r, t, x, y, 0.08))
            if ly == 7 and lx in (0, 7):  # rounded lip corners
                put(im, x, y, r[1])
    return im


def moss_roof(seed=17):
    """Thatch under a thick moss cover with tiny flowers."""
    r = RAMP["moss"]
    im = img()
    for y in range(N):
        for x in range(N):
            t = 0.25 + fbm(x / N, y / N, seed, base=4) * 0.6 + (0.1 if (x + y * 3) % 7 == 0 else 0)
            put(im, x, y, pick(r, t, x, y, 0.14))
    rv = random.Random(seed)
    for col in (RAMP["rose"][3], (255, 236, 160), RAMP["cream"][3], RAMP["rose"][4]):
        for _ in range(2):
            x, y = rv.randrange(N), rv.randrange(N)
            put(im, x, y, col)
    return im


def awning(seed=19):
    """Canvas stripes, 8 px rose then 8 px cream, with weave and soft fold shading."""
    im = img()
    for x in range(N):
        ramp = RAMP["rose"] if (x // 8) % 2 == 0 else RAMP["cream"]
        lx = x % 8
        for y in range(N):
            t = 0.55 + (0.15 if lx in (1, 2) else 0) - (0.2 if lx == 7 else 0) + ((x + y) % 2) * 0.05
            t += fbm(x / N, y / N, seed, base=4, octs=1) * 0.1 - 0.05
            put(im, x, y, pick(ramp, t, x, y, 0.06))
    return im


def plaster(seed=23):
    r = RAMP["cream"]
    im = img()
    for y in range(N):
        for x in range(N):
            put(im, x, y, pick(r, 0.45 + fbm(x / N, y / N, seed, base=6) * 0.45, x, y, 0.16))
    rv = random.Random(seed)
    for _ in range(4):  # a few cracks / chips
        x, y = rv.randrange(N), rv.randrange(N)
        put(im, x, y, r[0]); put(im, x + 1, y + 1, r[0])
    return im


def beam(seed=29):
    """Dark timber beam, horizontal grain."""
    r = RAMP["beam"]
    im = img()
    for y in range(N):
        for x in range(N):
            put(im, x, y, pick(r, 0.4 + fbm(x / N * 0.3, y / N, seed, base=8, octs=2) * 0.5, x, y, 0.08))
    return im


def bark(seed=31):
    """World Tree bark: deep vertical grooves in plum and violet, lit ridges."""
    r = RAMP["bark"]
    im = img()
    for x in range(N):
        for y in range(N):
            w = math.sin((x + fbm(x / N, y / N, seed, base=3) * 10) / N * math.pi * 2 * 5)
            t = 0.45 + w * 0.3 + fbm(x / N, y / N, seed + 1, base=8, octs=2) * 0.2 - 0.1
            put(im, x, y, pick(r, t, x, y, 0.1))
    return im


def rockface(seed=37):
    """Chunky cave-wall stones for the Hollow Mountain."""
    r, m = RAMP["rock"], RAMP["mortar"]
    rv = random.Random(seed)
    pts = [(rv.uniform(0, N), rv.uniform(0, N), rv.random()) for _ in range(6)]
    im = img()
    for y in range(N):
        for x in range(N):
            ds = sorted((math.hypot(x - px - ox, (y - py - oy) * 1.3), py + oy, tone) for px, py, tone in pts for ox in (-N, 0, N) for oy in (-N, 0, N))
            (d1, cy, tone), d2 = ds[0], ds[1][0]
            if d2 - d1 < 1.1:
                put(im, x, y, m[0])
            else:
                t = 0.3 + tone * 0.35 + (0.25 if y < cy - 2 else -0.1) + fbm(x / N, y / N, seed, base=8, octs=2) * 0.2
                put(im, x, y, pick(r, t, x, y, 0.1))
    return im


def leaves(seed=41):
    r = RAMP["leaf"]
    im = img()
    rv = random.Random(seed)
    for y in range(N):
        for x in range(N):
            put(im, x, y, pick(r, 0.2 + fbm(x / N, y / N, seed, base=4) * 0.4, x, y, 0.12))
    for _ in range(22):  # leaf clusters: lit top-left pixel, shaded bottom-right
        x, y = rv.randrange(N), rv.randrange(N)
        for dx, dy, k in ((0, 0, 3), (1, 0, 3), (0, 1, 2), (1, 1, 2), (2, 1, 1), (1, 2, 1)):
            put(im, x + dx, y + dy, r[k + (1 if rv.random() < 0.3 else 0)])
    return im


def path(seed=43):
    r = RAMP["path"]
    im = img()
    for y in range(N):
        for x in range(N):
            put(im, x, y, pick(r, 0.35 + fbm(x / N, y / N, seed, base=6) * 0.45, x, y, 0.18))
    rv = random.Random(seed)
    for _ in range(9):  # pebbles
        x, y = rv.randrange(N), rv.randrange(N)
        put(im, x, y, A.R["pebble"][2]); put(im, x + 1, y, A.R["pebble"][1])
    return im


def iron(seed=47):
    r = RAMP["iron"]
    im = img()
    for y in range(N):
        for x in range(N):
            put(im, x, y, pick(r, 0.4 + fbm(x / N, y / N, seed, base=4) * 0.4 + (0.2 if y % 16 == 0 else 0), x, y, 0.1))
    for x in range(2, N, 8):  # rivets
        for y in (3, 19):
            put(im, x, y, r[3]); put(im, x + 1, y + 1, r[0])
    return im


def glass(seed=53):
    """Greenhouse pane: one pane per tile, clear pale sky tint, two soft diagonal shine streaks, a 1 px warm mullion on two edges."""
    im = Image.new("RGBA", (N, N))
    for y in range(N):
        for x in range(N):
            d = (x + y) % N
            if x == 0 or y == 0:
                im.putpixel((x, y), (214, 160, 116, 255))
            elif d in (9, 10):  # one soft shine streak (round 5: more streaks read as noise)
                im.putpixel((x, y), (236, 246, 255, 70))
            else:
                im.putpixel((x, y), (190, 222, 244, 26))
    return im


def wood_frame(seed=59):
    """Warm greenhouse timber: light planed wood with a fine grain."""
    r = RAMP["plank"]
    im = img()
    for y in range(N):
        for x in range(N):
            put(im, x, y, pick(r, 0.62 + fbm(x / N * 0.3, y / N, seed, base=8, octs=2) * 0.3, x, y, 0.08))
    return im


def flagstone(seed=61, n=6):
    """Smooth large flagstones for paths and the campfire patio: pale and calm next to the busy cobbles."""
    r, m = RAMP["path"], RAMP["mortar"]
    rv = random.Random(seed)
    pts = [(rv.uniform(0, N), rv.uniform(0, N), rv.random()) for _ in range(n)]
    im = img()
    for y in range(N):
        for x in range(N):
            ds = sorted((math.hypot(x - px - ox, y - py - oy), tone) for px, py, tone in pts for ox in (-N, 0, N) for oy in (-N, 0, N))
            (d1, tone), d2 = ds[0], ds[1][0]
            if d2 - d1 < 1.0:
                put(im, x, y, m[1])
            else:
                put(im, x, y, pick(r, 0.45 + tone * 0.3 + fbm(x / N, y / N, seed, base=8, octs=1) * 0.12, x, y, 0.06))
    return im


def cobble_soft(seed=12, n=7):
    """Calmer plaza cobbles: bigger stones, a narrow tone range and thin grout, so the plaza stays quiet behind the stores."""
    r, m = RAMP["cobble"], RAMP["mortar"]
    rv = random.Random(seed)
    pts = [(rv.uniform(0, N), rv.uniform(0, N), rv.random()) for _ in range(n)]
    im = img()
    for y in range(N):
        for x in range(N):
            ds = sorted((math.hypot(x - px - ox, y - py - oy), py + oy, tone) for px, py, tone in pts for ox in (-N, 0, N) for oy in (-N, 0, N))
            (d1, cy, tone), d2 = ds[0], ds[1][0]
            if d2 - d1 < 0.9:
                put(im, x, y, r[1])
            else:
                t = 0.45 + tone * 0.18 + (0.1 if y < cy - 2 else 0) + fbm(x / N, y / N, seed, base=8, octs=1) * 0.08
                put(im, x, y, pick(r, t, x, y, 0.05))
    return im


def cobble_lane(seed=21, n=6):
    """Lane cobbles: big rounded stones in lilac grey with moss in some of the joints and a lit top edge on each stone."""
    r = RAMP["cobble"]
    rv = random.Random(seed)
    pts = [(rv.uniform(0, N), rv.uniform(0, N), rv.random()) for _ in range(n)]
    im = img()
    for y in range(N):
        for x in range(N):
            ds = sorted((math.hypot(x - px - ox, y - py - oy), py + oy, tone) for px, py, tone in pts for ox in (-N, 0, N) for oy in (-N, 0, N))
            (d1, cy, tone), d2 = ds[0], ds[1][0]
            if d2 - d1 < 1.4:
                moss = fbm(x / N, y / N, seed + 5, base=3) > 0.55
                put(im, x, y, RAMP["moss"][1] if moss else RAMP["mortar"][1])
            else:
                edge = min(1.0, (d2 - d1) / 5)
                t = 0.35 + tone * 0.25 + (0.22 if y < cy - 2.5 else (-0.12 if y > cy + 3 else 0)) * edge + fbm(x / N, y / N, seed, base=8, octs=1) * 0.1
                put(im, x, y, pick(r, t, x, y, 0.05))
    return im


TEX = {
    "planks": lambda: planks(), "planks_light": lambda: planks(seed=4, board=8), "logs": logs, "stonebrick": bricks,
    "cobble": cobble, "shingle_teal": lambda: shingles("teal"), "shingle_plum": lambda: shingles("plum", seed=14),
    "moss_roof": moss_roof, "awning": awning, "plaster": plaster, "beam": beam, "bark": bark, "rockface": rockface,
    "leaves": leaves, "path": path, "iron": iron, "glass": glass, "wood_frame": wood_frame, "flagstone": flagstone, "cobble_soft": cobble_soft, "cobble_lane": cobble_lane,
}

if __name__ == "__main__":
    out = []
    for name, fn in TEX.items():
        im = fn()
        im.resize((N * 8, N * 8), Image.NEAREST).save(os.path.join(OUT, name + ".png"))
        out.append((name, im))
    # contact sheet: each texture tiled 2x2 so seams show
    sheet = Image.new("RGBA", (len(out) * 70, 70), (40, 30, 60, 255))
    for i, (name, t) in enumerate(out):
        t = t.convert("RGBA")
        for ox in (0, 1):
            for oy in (0, 1):
                sheet.alpha_composite(t, (i * 70 + 3 + ox * N, 3 + oy * N))
    sheet.resize((sheet.width * 3, sheet.height * 3), Image.NEAREST).save(os.path.join(OUT, "_sheet.png"))
    print(len(out), "textures ->", OUT)
