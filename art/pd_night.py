"""Pixel Depths night key art: night sky + a lighting 'shader' over the cave scene.
Lighting model (the same one the game should copy): light spreads cell by cell through open air and fades fast
inside rock (Terraria-style), so unexplored rock stays dark and caves glow from their own lights.
Then: bump shading from block bevels and texture, ambient occlusion in cave corners, emissive bloom,
ACES tone map, cool night grade, vignette. Usage: python pd_night.py <out_dir>"""
import math, os, random, sys
import numpy as np
from PIL import Image, ImageDraw, ImageFilter
import pd_art as A
import pd_world as Wd
from pd_art import H, R, lerp, pick, fbm

OUT = sys.argv[1] if len(sys.argv) > 1 else "out"
W, GROUND, B, ROWS, COLS = Wd.W, Wd.GROUND, Wd.B, Wd.ROWS, Wd.COLS
CAMPFIRE = (172, GROUND - 8)


def sky_night(img, emit):
    px, ep = img.load(), emit.load()
    grad = [H(h) for h in ("#070b22", "#0c1132", "#141842", "#1e1c50", "#2b235e", "#3c2d6c")]
    for y in range(GROUND):
        for x in range(W):
            px[x, y] = pick(grad, y / GROUND, x, y, 0.2)
    for x in range(W):  # aurora curtains in mint and lilac
        yc = 14 + 8 * math.sin(x / 130) + 4 * math.sin(x / 41 + 1)
        col = lerp(R["mint"][3], R["lilac"][3], (math.sin(x / 210) + 1) / 2)
        streak = 0.55 + 0.45 * math.sin(x / 2.7) * math.sin(x / 13)
        for y in range(int(yc - 6), int(yc + 46)):
            if 0 <= y < GROUND:
                t = (y - (yc - 6)) / 52
                a = (1 - t) ** 1.6 * 0.36 * max(0.15, streak)
                px[x, y] = lerp(px[x, y], col, a)
                ep[x, y] = lerp((0, 0, 0), col, a * 0.35)
    rnd = random.Random(99)
    for _ in range(300):  # stars, a few with sparkle crosses
        x, y = rnd.randrange(W), rnd.randrange(0, GROUND - 34)
        b = rnd.random()
        col = (255, 255, 255) if b > 0.55 else (R["lilac"][4] if b > 0.25 else R["mint"][4])
        px[x, y] = col if b > 0.35 else lerp(px[x, y], col, 0.55)
        ep[x, y] = lerp((0, 0, 0), col, 0.6 if b > 0.55 else 0.25)
        if b > 0.975:
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1), (2, 0), (-2, 0), (0, 2), (0, -2)):
                if 0 <= x + dx < W and 0 <= y + dy < GROUND:
                    px[x + dx, y + dy] = R["lilac"][3]
                    ep[x + dx, y + dy] = R["lilac"][2]
    mx, my, mr = 300, 58, 22  # the moon, with a soft halo and craters
    for y in range(my - 80, my + 80):
        for x in range(mx - 80, mx + 80):
            if 0 <= y < GROUND and 0 <= x < W:
                dd = math.hypot(x - mx, y - my)
                if dd <= mr:
                    shadeK = max(0, (x - mx + 0.4 * (y - my)) / mr)
                    c = lerp(H("#f3eeff"), H("#c8bdf0"), shadeK * 0.7)
                    for (cx, cy, cr) in ((-7, -5, 5), (6, 4, 4), (-2, 9, 3), (9, -8, 2)):
                        if math.hypot(x - mx - cx, y - my - cy) <= cr:
                            c = lerp(c, H("#b7aae6"), 0.55)
                    px[x, y] = c
                    ep[x, y] = lerp(c, (0, 0, 0), 0.1)
                elif dd < 80:
                    a = (1 - (dd - mr) / (80 - mr)) ** 2.2
                    a = math.floor(a * 4 + A.BAYER[y % 4][x % 4] / 16) / 4 * 0.35  # stepped, dithered pixel halo
                    px[x, y] = lerp(px[x, y], H("#9c90e6"), a)
                    ep[x, y] = lerp((0, 0, 0), H("#9c90e6"), a * 0.5)

    def blob(cx, cy, rs, top, bot):
        for (ox, oy, r) in rs:
            for yy in range(-r, r + 1):
                for xx in range(-r, r + 1):
                    if xx * xx + yy * yy <= r * r:
                        X, Y = cx + ox + xx, cy + oy + yy
                        if 0 <= X < W and 0 <= Y < GROUND:
                            px[X, Y] = top if Y < cy - r // 2 + oy else bot

    for (cx, cy, sc) in ((560, 46, 1.0), (860, 70, 0.8), (700, 22, 0.6), (430, 90, 0.7)):  # moonlit clouds
        rs = [(int(o * sc), int(q * sc), max(3, int(r * sc))) for o, q, r in ((0, 0, 14), (18, 4, 11), (-17, 5, 10), (34, 8, 7), (-31, 9, 6))]
        blob(cx, cy, rs, H("#5a5394"), H("#2d2858"))
    for (amp, base_y, col, seed) in ((22, GROUND - 26, H("#1d1a44"), 3), (16, GROUND - 12, H("#151334"), 9)):
        for x in range(W):
            hy = int(base_y - amp * fbm(x / W, 0.5, seed, base=5, tile=False))
            for y in range(max(0, hy), GROUND):
                px[x, y] = col
    trunk, trunk_d, rim = H("#3d3270"), H("#2a2252"), H("#9d8ee6")  # world tree silhouette, moon rim on the left
    for y in range(0, GROUND):
        flare = max(0, (y - 90)) ** 1.6 * 0.35
        half = 66 + int(6 * math.sin(y / 23)) + int(flare)
        cx = 1170 + int(6 * math.sin(y / 41))
        for x in range(cx - half, cx + half):
            if 0 <= x < W:
                rel = (x - (cx - half)) / (2 * half)
                groove = (x * 3 + int(8 * math.sin(y / 17 + x / 9))) % 13 == 0
                px[x, y] = rim if rel < 0.04 else (lerp(rim, trunk, 0.6) if rel < 0.09 else (trunk_d if groove or rel > 0.85 else trunk))
    for (cx, cy) in ((1240, -8), (1170, 6), (1090, -4), (1010, 12), (940, 0), (1270, 24)):
        blob(cx, cy, [(0, 0, 30), (24, 8, 22), (-22, 10, 20), (8, 18, 16)], H("#3a7480"), H("#132a33"))
    for i in range(70):  # fireflies around the tree
        rr = random.Random(500 + i)
        x, y = rr.randrange(880, W), rr.randrange(10, GROUND - 4)
        col = R["mint"][4] if i % 3 else R["gold"][4]
        px[x, y] = col
        ep[x, y] = col
    d, de = ImageDraw.Draw(img), ImageDraw.Draw(emit)
    fx, fy = CAMPFIRE  # campfire by the tent, ringed with stones
    for sx in (-14, -8, 8, 14):
        d.ellipse([fx + sx - 3, fy + 4, fx + sx + 3, fy + 9], fill=H("#4b4566"))
        d.point((fx + sx - 1, fy + 5), fill=H("#8a84a6"))
    for dx in (-10, -3, 4):
        d.rectangle([fx + dx, fy + 3, fx + dx + 7, fy + 7], fill=R["wood"][1])
    for (w_, h_, col) in ((16, 20, R["rose"][2]), (11, 15, R["gold"][2]), (6, 9, R["gold"][4])):
        poly = [(fx - w_ // 2, fy + 4), (fx, fy + 4 - h_), (fx + w_ // 2, fy + 4)]
        d.polygon(poly, fill=col)
        de.polygon(poly, fill=col)
    for i in range(10):
        rr = random.Random(900 + i)
        ex, ey = fx + rr.randrange(-12, 13), fy - rr.randrange(18, 44)
        d.point((ex, ey), fill=R["gold"][3])
        de.point((ex, ey), fill=R["gold"][3])


def surface_detail(img, emit, m):
    """Rolling grass knolls over the surface row, and world-tree roots pushing down into the rock."""
    px, d = img.load(), ImageDraw.Draw(img)
    for x in range(W):
        if m[0][x // B] in ".Di":
            continue
        h = int(3 + 6 * fbm(x / 260, 0.4, 61, base=3, tile=False) + 2 * math.sin(x / 37))
        for y in range(GROUND - h, GROUND + 3):
            t = (y - (GROUND - h)) / max(1, h + 3)
            px[x, y] = pick(R["moss"], 0.95 - t * 0.7, x, y, 0.15)
        if (x * 7) % 11 == 0:
            px[x, GROUND - h - 1] = R["moss"][3]
            if (x * 3) % 5 == 0:
                px[x, GROUND - h - 2] = R["moss"][4]
    draw_camp(img, emit)
    bark = [H(h_) for h_ in ("#1c1636", "#2c2350", "#3d3270", "#57499a")]
    for (x0, path, w0) in ((1080, [(1080, GROUND), (1060, GROUND + 40), (1010, GROUND + 70), (990, GROUND + 120)], 9),
                          (1150, [(1150, GROUND), (1160, GROUND + 50), (1120, GROUND + 100), (1130, GROUND + 160)], 11),
                          (1230, [(1230, GROUND), (1250, GROUND + 60), (1280, GROUND + 90)], 8)):
        for i in range(len(path) - 1):
            (xa, ya), (xb, yb) = path[i], path[i + 1]
            n = int(max(abs(xb - xa), abs(yb - ya)))
            for j in range(n):
                x = xa + (xb - xa) * j / n
                y = ya + (yb - ya) * j / n
                w = max(2, int(w0 * (1 - (y - GROUND) / 200)))
                for t in range(-w, w + 1):
                    X = int(x + t)
                    if 0 <= X < W and int(y) < Wd.HH:
                        tt = (t + w) / (2 * w)
                        c = bark[3] if tt < 0.2 else (bark[2] if tt < 0.55 else (bark[1] if tt < 0.9 else bark[0]))
                        if (X + int(y)) % 9 == 0 and 0.2 < tt < 0.85:
                            c = bark[0]
                        px[X, int(y)] = c


FONT = {  # 5x7 pixel font for signs and rarity tags
    "A": ".###.#...##...#######...##...##...#",
    "B": "####.#...##...#####.#...##...#####.",
    "C": ".###.#...##....#....#....#...#.###.",
    "D": "####.#...##...##...##...##...#####.",
    "E": "######....#....####.#....#....#####",
    "F": "######....#....####.#....#....#....",
    "G": ".###.#...##....#.####...##...#.###.",
    "H": "#...##...##...#######...##...##...#",
    "I": ".###...#....#....#....#....#...###.",
    "K": "#...##..#.#.#..##...#.#..#..#.#...#",
    "L": "#....#....#....#....#....#....#####",
    "M": "#...###.###.#.##...##...##...##...#",
    "N": "#...###..##.#.##..###...##...##...#",
    "O": ".###.#...##...##...##...##...#.###.",
    "P": "####.#...##...#####.#....#....#....",
    "R": "####.#...##...#####.#.#..#..#.#...#",
    "S": ".#####....#.....###.....#....#####.",
    "T": "#####..#....#....#....#....#....#..",
    "W": "#...##...##...##.#.##.#.###.###...#",
    "Y": "#...##...#.#.#...#....#....#....#..",
    "0": ".###.#...##..###.#.###..##...#.###.",
    "1": "..#...##....#....#....#....#...###.",
    "2": ".###.#...#....#...#...#...#...#####",
    "3": "####.....#....#.###.....#....#####.",
    "4": "#...##...##...######....#....#....#",
    "5": "######....####.....#....##...#.###.",
    "6": ".###.#....#....####.#...##...#.###.",
    "7": "#####....#...#...#....#....#....#..",
    "8": ".###.#...##...#.###.#...##...#.###.",
    "9": ".###.#...##...#.####....#....#.###.",
    ",": "...........................#...#...",
    " ": "...................................",
}


def draw_text(d, x, y, text, col, scale=1, outline=A.INK):
    """Pixel text with a 1-step dark outline; returns the width drawn."""
    cx = x
    for chx in text:
        g = FONT.get(chx, FONT[" "])
        for pass_ in (0, 1):
            for i, bit in enumerate(g):
                if bit != "#":
                    continue
                gx, gy = cx + (i % 5) * scale, y + (i // 5) * scale
                if pass_ == 0 and outline:
                    d.rectangle([gx - scale, gy - scale, gx + 2 * scale - 1, gy + 2 * scale - 1], fill=outline)
                elif pass_ == 1:
                    d.rectangle([gx, gy, gx + scale - 1, gy + scale - 1], fill=col)
        cx += 6 * scale
    return cx - x


CAMP_LIGHTS = []


def draw_camp(img, emit):
    """The surface hub, one station per step of the loop: sell stall, forge, egg incubator, lift headframe, map board."""
    d, de = ImageDraw.Draw(img), ImageDraw.Draw(emit)
    G = GROUND - 3
    CAMP_LIGHTS.clear()
    wood, stone = R["wood"], [H(h) for h in ("#2a2440", "#463e66", "#665d8e", "#8a82b2")]
    # tent with stripes, a lit doorway and guy ropes
    d.polygon([(34, G), (86, G - 54), (138, G)], fill=R["lilac"][2])
    d.polygon([(86, G - 54), (138, G), (108, G)], fill=R["lilac"][1])
    for k in range(5):
        d.line([(46 + k * 10, G), (86, G - 54)], fill=R["rose"][1], width=1)
    d.polygon([(74, G), (86, G - 26), (98, G)], fill=R["gold"][2])
    de.polygon([(74, G), (86, G - 26), (98, G)], fill=R["gold"][1])
    d.line([(86, G - 54), (86, G - 58)], fill=wood[2], width=2)
    d.line([(34, G), (20, G + 2)], fill=R["egg"][1])
    d.line([(138, G), (152, G + 2)], fill=R["egg"][1])
    CAMP_LIGHTS.append((86, G - 12, 60, (1.0, 0.82, 0.55)))
    for lx in (150, 194):  # log seats by the fire
        d.rectangle([lx - 8, G - 3, lx + 8, G + 1], fill=wood[1])
        d.rectangle([lx - 8, G - 3, lx + 8, G - 3], fill=wood[3])
    # forge: stone hut, plank roof, chimney with smoke, glowing furnace mouth, anvil
    d.rectangle([318, G - 46, 412, G], fill=stone[1])
    for yy in range(G - 46, G, 8):
        d.line([(318, yy), (412, yy)], fill=stone[0])
        for xx in range(318 + (8 if (yy // 8) % 2 else 0), 412, 16):
            d.line([(xx, yy), (xx, yy + 7)], fill=stone[0])
    d.rectangle([318, G - 46, 412, G - 45], fill=stone[3])
    d.polygon([(310, G - 46), (365, G - 72), (420, G - 46)], fill=wood[2])
    d.polygon([(365, G - 72), (420, G - 46), (392, G - 46)], fill=wood[1])
    d.rectangle([392, G - 86, 404, G - 58], fill=stone[2])
    d.rectangle([392, G - 86, 404, G - 84], fill=stone[3])
    for (sx, sy, sr) in ((398, G - 94, 4), (403, G - 104, 5), (396, G - 116, 6)):
        d.ellipse([sx - sr, sy - sr, sx + sr, sy + sr], fill=H("#4a4378"))
    d.rectangle([336, G - 26, 364, G], fill=H("#1a1020"))
    d.ellipse([336, G - 34, 364, G - 18], fill=H("#1a1020"))
    d.rectangle([340, G - 16, 360, G - 2], fill=R["copper"][3])
    d.rectangle([343, G - 12, 357, G - 2], fill=R["gold"][4])
    de.rectangle([338, G - 20, 362, G - 1], fill=R["copper"][3])
    CAMP_LIGHTS.append((350, G - 10, 120, (1.0, 0.55, 0.28)))
    d.rectangle([378, G - 12, 404, G - 8], fill=H("#3a3550"))
    d.rectangle([384, G - 8, 398, G], fill=H("#2a2640"))
    d.rectangle([378, G - 12, 404, G - 12], fill=H("#7a74a0"))
    draw_text(d, 340, G - 64, "FORGE", R["gold"][3], 1)
    # sell stall: striped awning, counter, ore crates, lantern
    d.rectangle([444, G - 30, 534, G], fill=wood[2])
    d.rectangle([444, G - 30, 534, G - 28], fill=wood[3])
    for px_ in (448, 528):
        d.rectangle([px_, G - 62, px_ + 4, G], fill=wood[1])
    for k in range(8):
        d.polygon([(440 + k * 12, G - 64), (452 + k * 12, G - 64), (452 + k * 12, G - 52), (446 + k * 12, G - 48), (440 + k * 12, G - 52)],
                  fill=R["rose"][2] if k % 2 == 0 else H("#fff1e6"))
    for (cx, col) in ((456, R["copper"][2]), (480, R["coal"][3]), (504, R["gold"][3])):
        d.rectangle([cx, G - 44, cx + 18, G - 31], fill=wood[1])
        d.rectangle([cx + 2, G - 47, cx + 16, G - 42], fill=col)
    d.rectangle([520, G - 46, 526, G - 38], fill=R["gold"][3])
    de.rectangle([520, G - 46, 526, G - 38], fill=R["gold"][3])
    CAMP_LIGHTS.append((523, G - 42, 70, (1.0, 0.88, 0.6)))
    draw_text(d, 470, G - 20, "SELL", R["gold"][4], 1)
    # lift headframe over the dig: posts, braces, pulley wheel, rope, lantern
    cx = 18 * B + 16
    for px_ in (cx - 30, cx + 26):
        d.rectangle([px_, G - 92, px_ + 4, G + 2], fill=wood[2])
        d.rectangle([px_, G - 92, px_ + 1, G + 2], fill=wood[3])
    d.rectangle([cx - 34, G - 96, cx + 34, G - 90], fill=wood[3])
    d.line([(cx - 28, G - 40), (cx + 28, G - 86)], fill=wood[1], width=3)
    d.line([(cx + 28, G - 40), (cx - 28, G - 86)], fill=wood[1], width=3)
    d.ellipse([cx - 11, G - 110, cx + 11, G - 88], outline=H("#8a84a6"), width=3)
    for a_ in range(0, 180, 45):
        rr = math.radians(a_)
        d.line([(cx - 9 * math.cos(rr), G - 99 - 9 * math.sin(rr)), (cx + 9 * math.cos(rr), G - 99 + 9 * math.sin(rr))], fill=H("#6a6490"))
    d.line([(cx + 10, G - 99), (cx + 10, G + 2 * B + 10)], fill=R["egg"][2], width=1)
    d.rectangle([cx + 31, G - 72, cx + 37, G - 64], fill=R["gold"][3])
    de.rectangle([cx + 31, G - 72, cx + 37, G - 64], fill=R["gold"][3])
    CAMP_LIGHTS.append((cx + 34, G - 68, 60, (1.0, 0.9, 0.65)))
    # egg incubator: little greenhouse, warm heater, three eggs
    d.rectangle([672, G - 30, 772, G], fill=wood[1])
    d.rectangle([672, G - 30, 772, G - 28], fill=wood[3])
    d.pieslice([668, G - 84, 776, G - 4], 180, 360, fill=H("#7fb6d6"))
    d.pieslice([674, G - 78, 770, G - 10], 180, 360, fill=H("#3b5c86"))
    for gx in range(686, 760, 16):
        d.line([(gx, G - 30), (gx + 6, G - 72)], fill=H("#a9d8ee"))
    for (ex, ec) in ((694, R["egg"][3]), (718, R["lilac"][3]), (742, R["rose"][3])):
        d.ellipse([ex, G - 50, ex + 14, G - 30], fill=ec)
        d.point((ex + 4, G - 45), fill=(255, 255, 255))
        de.ellipse([ex + 2, G - 48, ex + 12, G - 32], fill=lerp(ec, (0, 0, 0), 0.5))
    CAMP_LIGHTS.append((722, G - 34, 100, (1.0, 0.7, 0.85)))
    draw_text(d, 704, G - 20, "EGGS", R["rose"][3], 1)
    # map board: where the next area opens
    d.rectangle([818, G - 46, 822, G], fill=wood[1])
    d.rectangle([800, G - 62, 842, G - 40], fill=wood[2])
    for k, col in enumerate((R["moss"][2], R["copper"][2], R["lilac"][2], R["rose"][2])):
        d.rectangle([804, G - 58 + k * 4, 838, G - 56 + k * 4], fill=col)
    d.rectangle([826, G - 52, 829, G - 49], fill=R["gold"][4])
    de.rectangle([826, G - 52, 829, G - 49], fill=R["gold"][3])
    draw_text(d, 808, G - 74, "MAP", R["moss"][3], 1)
    for (bx, by) in ((250, G), (300, G), (556, G), (650, G), (870, G), (905, G)):  # shrubs and rocks break the skyline
        d.ellipse([bx - 9, by - 9, bx + 9, by + 3], fill=R["moss"][1])
        d.ellipse([bx - 6, by - 11, bx + 4, by - 3], fill=R["moss"][2])


def gauss(arr, r):
    """Gaussian blur of a float HxW (or HxWx3) array (blur only the two image axes)."""
    from scipy.ndimage import gaussian_filter
    return gaussian_filter(arr, sigma=(r, r, 0) if arr.ndim == 3 else r)


def shift(L, dy, dx):
    out = np.zeros_like(L)
    h, w = L.shape[:2]
    out[max(dy, 0):h + min(dy, 0), max(dx, 0):w + min(dx, 0)] = L[max(-dy, 0):h + min(-dy, 0), max(-dx, 0):w + min(-dx, 0)]
    return out


def flood(src, decay, iters):
    L = src.copy()
    dirs = [(0, 1, 1), (0, -1, 1), (1, 0, 1), (-1, 0, 1), (1, 1, 1.414), (1, -1, 1.414), (-1, 1, 1.414), (-1, -1, 1.414)]
    for _ in range(iters):
        for dy, dx, k in dirs:
            L = np.maximum(L, shift(L, dy, dx) * decay ** k)
        L = np.maximum(L, src)
    return L


BAYER = np.array([[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]], np.float32) / 16


def vnoise_np(h, w, cell, seed):
    rng = np.random.default_rng(seed)
    g = rng.random((h // cell + 2, w // cell + 2)).astype(np.float32)
    im = Image.fromarray(g, "F").resize(((w // cell + 2) * cell, (h // cell + 2) * cell), Image.BICUBIC)
    return np.asarray(im)[:h, :w]


def night_scene(shroud=True):
    TV = [A.make_textures(v) for v in range(4)]
    img, m, lights, emit = Wd.scene(TV, night=True, sky_fn=sky_night, post_fn=surface_detail)
    lights = list(lights) + [(CAMPFIRE[0], CAMPFIRE[1] - 6, 170, (1.0, 0.62, 0.34))] + CAMP_LIGHTS
    a = (np.asarray(img).astype(np.float32) / 255) ** 2.2
    e = (np.asarray(emit).astype(np.float32) / 255) ** 2.2
    Hh, Wt = a.shape[:2]
    solid = np.zeros((Hh, Wt), np.float32)
    natural = np.zeros((Hh, Wt), bool)
    for r in range(ROWS):
        for c in range(COLS):
            if m[r][c] not in ".Di":
                solid[GROUND + r * B:GROUND + (r + 1) * B, c * B:(c + 1) * B] = 1
                natural[GROUND + r * B:GROUND + (r + 1) * B, c * B:(c + 1) * B] = m[r][c] not in "SgGe"  # rare blocks stay crisp whole squares
    # round the convex corners of the rock so caves read as natural, not boxes
    from scipy.ndimage import binary_opening, binary_closing
    yy0, xx0 = np.mgrid[-7:8, -7:8]
    disk = xx0 ** 2 + yy0 ** 2 <= 49
    top = np.arange(Hh)[:, None] < GROUND + B
    fill = binary_closing(natural, structure=disk[3:12, 3:12]) & ~natural & ~top & (solid == 0)  # round the inside corners too
    rock_rgb = np.asarray(A.to_img(A.make_textures(2, bevel=False)["rootflint"])).astype(np.float32) / 255
    rock_bg = np.tile(rock_rgb, (Hh // 32 + 1, Wt // 32 + 1, 1))[:Hh, :Wt] ** 2.2
    a[fill] = rock_bg[fill]
    solid[fill] = 1
    natural |= fill
    nat_open = binary_opening(natural, structure=disk) | top
    cut = natural & ~nat_open
    cave_rgb = np.asarray(A.to_img(TV[1]["cave"])).astype(np.float32) / 255
    cave_bg = np.tile(cave_rgb, (Hh // 32 + 1, Wt // 32 + 1, 1))[:Hh, :Wt] ** 2.2
    a[cut] = cave_bg[cut]
    solid[cut] = 0
    natural &= ~cut
    # one continuous rock mass: large soft strata in world space instead of per-tile shading
    strata = 0.8 + 0.4 * vnoise_np(Hh, Wt, 64, 4) + 0.12 * np.sin(np.arange(Hh)[:, None] / 13 + 2 * np.sin(np.arange(Wt)[None, :] / 150))
    a = np.where(natural[..., None], a * strata[..., None] * np.array([0.92, 0.9, 1.06], np.float32), a)
    # crisp pixel edges where rock meets open cave: dark rim, lit lip on top
    air = (solid == 0) & (np.arange(Hh)[:, None] >= GROUND)
    nb_air = np.zeros_like(air)
    for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
        nb_air |= shift(air.astype(np.float32), dy, dx) > 0
    edge = natural & nb_air
    lip = natural & ~edge & (shift(air.astype(np.float32), 2, 0) > 0) | natural & ~edge & (shift(air.astype(np.float32), 3, 0) > 0)
    a[edge] = (np.array(H("#241a33"), np.float32) / 255) ** 2.2
    a[lip] = np.clip(a[lip] * 1.7, 0, 1)
    # liquid pool: fills the real basin, rippled surface, background bends through it, foam on the rock, a spring feeding it
    Xg, Yg = np.meshgrid(np.arange(Wt), np.arange(Hh))
    wl = (GROUND + 11 * B + 4 + 1.6 * np.sin(np.arange(Wt) / 7.0) + 0.8 * np.sin(np.arange(Wt) / 3.1 + 1)).astype(int)
    box = (Xg >= 2 * B) & (Xg < 13 * B) & (Yg >= GROUND + 10 * B)
    water = box & (solid == 0) & (Yg >= wl[None, :])
    depth = np.clip((Yg - wl[None, :]) / 64.0, 0, 1)[..., None] ** 0.7
    wc = ((np.array(H("#8ee0e6"), np.float32) / 255) ** 2.2) * (1 - depth) + ((np.array(H("#141c4c"), np.float32) / 255) ** 2.2) * depth
    sx = np.clip(Xg + (2 * np.sin(Yg / 4.0 + Xg / 13.0)).astype(int), 0, Wt - 1)
    a = np.where(water[..., None], a[Yg, sx] * 0.28 + wc * 0.72, a)
    surf = box & (solid == 0) & ((Yg == wl[None, :]) | (Yg == wl[None, :] + 1))
    a[surf] = (np.array(H("#e6fbff"), np.float32) / 255) ** 2.2
    e[surf] = e[surf] + 0.05
    foam = water & (gauss(solid, 1.6) > 0.12) & (Yg < wl[None, :] + 8)
    a[foam] = a[foam] * 0.4 + 0.45
    fx = 5 * B + 14
    for yy in range(GROUND + 10 * B - 8, int(wl[fx]) + 1):
        if solid[yy, fx] == 0:
            for k, dx in enumerate((-1, 0, 1)):
                a[yy, fx + dx] = ((np.array(H("#bfeff4") if (yy + k * 3) % 5 else H("#ffffff"), np.float32)) / 255) ** 2.2
                e[yy, fx + dx] = e[yy, fx + dx] + 0.03
    for k in range(10):
        a[int(wl[fx]) - 1 - (k % 3), fx - 6 + k + (k % 2)] = 0.85
    # darken the wall right behind the characters so they pop out of the rock
    from scipy.ndimage import binary_dilation
    smask = np.zeros((Hh, Wt), bool)
    for (ox, oy, sp) in Wd.SPRITES:
        al = np.asarray(sp)[..., 3] > 0
        smask[oy:oy + al.shape[0], ox:ox + al.shape[1]] |= al
    halo = binary_dilation(smask, structure=disk) & ~smask & (solid == 0) & (Yg >= GROUND)
    a[halo] *= 0.4
    g = 4
    gh, gw = Hh // g, Wt // g
    sg = solid[:gh * g:g, :gw * g:g]
    decay = np.where(sg > 0, 0.8, 0.972)[..., None]  # rock swallows light fast: unexplored rock stays dark
    sky = np.zeros((gh, gw, 3), np.float32)
    sky[: GROUND // g] = (0.24, 0.30, 0.62)  # moonlight pours in from above
    moon = flood(sky, decay, 60)
    src = np.zeros((gh, gw, 3), np.float32)
    for (lx, ly, lr, lc) in lights:
        gx, gy = int(lx / g), int(ly / g)
        if 0 <= gx < gw and 0 <= gy < gh:
            k = 0.5 * (lr / 90) ** 0.7
            src[max(0, gy - 1):gy + 2, max(0, gx - 1):gx + 2] = np.maximum(src[max(0, gy - 1):gy + 2, max(0, gx - 1):gx + 2], np.array(lc, np.float32) * k)
    lamp = flood(src, decay, 70)
    Lg = moon * 0.85 + lamp

    def up(arr):
        return np.stack([np.asarray(Image.fromarray(np.ascontiguousarray(arr[..., i], dtype=np.float32), "F").resize((Wt, Hh), Image.BILINEAR)) for i in range(3)], -1)

    L = gauss(up(Lg), 3)
    bay = np.tile(BAYER, (Hh // 4 + 1, Wt // 4 + 1))[:Hh, :Wt][..., None]
    L = np.floor(L * 14 + bay) / 14
    Le = gauss(up(lamp), 3)
    lum = (a * [0.3, 0.59, 0.11]).sum(-1)
    hgt = gauss(solid, 2.5) + lum * 0.6  # height: block bevels plus texture relief
    ny, nx = np.gradient(-hgt)
    Ls = (L * [0.3, 0.59, 0.11]).sum(-1)
    gy_, gx_ = np.gradient(Ls)
    mag = np.sqrt(gx_ ** 2 + gy_ ** 2) + 1e-5
    bump = np.clip(1 + 2.4 * (nx * gx_ + ny * gy_) / mag * np.clip(mag * 60, 0, 1), 0.45, 1.9)[..., None]
    occ = gauss(solid, 7)
    ao = np.where(solid[..., None] > 0, 1.0, (1 - 0.6 * occ)[..., None])
    under = (np.arange(Hh) >= GROUND)[:, None, None]
    amb = np.array([0.03, 0.028, 0.06], np.float32)
    col_under = a * (amb * ao + L * bump * ao) + e * 1.7
    depth = np.clip((np.arange(Hh) - GROUND) / (Hh - GROUND), 0, 1)[:, None, None]
    fog = np.array([0.03, 0.025, 0.07], np.float32) * depth * (1 - solid[..., None]) * 0.8
    col_under += fog
    col_sky = a * (0.82 + Le * 1.4) + e * 1.1
    col = np.where(under, col_under, col_sky)
    if shroud:
        sm = np.zeros((Hh, Wt), np.float32)
        for r in range(ROWS):
            for c in range(COLS):
                if m[r][c] in "SiD":
                    sm[GROUND + r * B:GROUND + (r + 1) * B, c * B:(c + 1) * B] = 1
        edge_n = vnoise_np(Hh, Wt, 10, 8)
        sm = np.clip(gauss(sm, 14) * 2.2 - (edge_n - 0.5) * 0.8, 0, 1)  # ragged, misty edge, not a box
        mist = 0.7 + 0.3 * vnoise_np(Hh, Wt, 12, 9)
        col = col * (1 - 0.988 * sm[..., None]) + np.array([0.012, 0.008, 0.03], np.float32) * sm[..., None] * mist[..., None]
        e = e * (1 - sm[..., None])
        dx0, dy0 = 31 * B, GROUND + 8 * B
        glint = np.zeros((Hh, Wt, 3), np.float32)
        glint[dy0 + 14:dy0 + 58, dx0 + 15:dx0 + 17] = (0.25, 0.9, 0.7)  # light through the crack of the rune door
        col = col + glint * 0.6
        e = e + glint
    bloom_src = e * 1.0 + np.clip(col - 0.8, 0, None)
    col = col + gauss(bloom_src, 4) * 0.8 + gauss(bloom_src, 16) * 0.45
    col = col + np.array([0.004, 0.004, 0.012], np.float32)  # lift the shadows toward blue
    col = np.clip((col * (2.51 * col + 0.03)) / (col * (2.43 * col + 0.59) + 0.14), 0, 1)  # ACES
    yy, xx = np.mgrid[0:Hh, 0:Wt]
    vig = 1 - 0.38 * (((xx - Wt / 2) / (Wt / 2)) ** 2 + ((yy - Hh / 2) / (Hh / 1.05)) ** 2)
    col = col * np.clip(vig, 0.55, 1)[..., None]
    col = col ** (1 / 2.2) + (np.random.default_rng(3).random((Hh, Wt, 1)) - 0.5) * (2 / 255)
    out = Image.fromarray((np.clip(np.nan_to_num(col), 0, 1) * 255).astype(np.uint8), "RGB")
    rarity_tags(out, m)
    return out.crop((0, 0, W, 592))


def rarity_tags(out, m):
    """Rare blocks get a rarity-coloured outline and a Delve-style "1 IN N" tag (true per-block odds; spawn rates are set to match)."""
    from scipy.ndimage import binary_dilation
    arr = np.asarray(out).astype(np.float32)
    Hh, Wt = arr.shape[:2]
    groups = [("g", R["gold"][3], "LEGENDARY", "1 IN 800", (6, 6)), ("G", R["lilac"][3], "EPIC", "1 IN 300", (8, -26)), ("e", R["rose"][2], "MYTHIC", "1 IN 2,500", (-210, -14))]
    tags = []
    for key, col, word, odds, (tx, ty) in groups:
        mask = np.zeros((Hh, Wt), bool)
        cells = [(r, c) for r in range(ROWS) for c in range(COLS) if m[r][c] == key]
        for (r, c) in cells:
            mask[GROUND + r * B:GROUND + (r + 1) * B, c * B:(c + 1) * B] = True
        if not cells:
            continue
        ring = binary_dilation(mask, iterations=2) & ~mask
        glow = binary_dilation(mask, iterations=6) & ~binary_dilation(mask, iterations=2)
        arr[ring] = col
        arr[glow] = arr[glow] * 0.6 + np.array(col, np.float32) * 0.4
        x1 = max(c for r, c in cells) * B + B
        y0 = GROUND + min(r for r, c in cells) * B
        tags.append((x1 + tx, y0 + ty, col, word, odds))
    out.paste(Image.fromarray(arr.astype(np.uint8), "RGB"))
    d = ImageDraw.Draw(out)
    for (x, y, col, word, odds) in tags:
        w = max(len(word), len(odds)) * 12 + 14
        d.rectangle([x, y, x + w, y + 46], fill=H("#160f28"))
        d.rectangle([x, y, x + w, y + 46], outline=col, width=2)
        draw_text(d, x + 8, y + 7, word, col, 2)
        draw_text(d, x + 8, y + 27, odds, (255, 251, 240), 2)


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    night_scene().save(os.path.join(OUT, "scene_night.png"))
    night_scene(shroud=False).crop((29 * B - 20, GROUND + 4 * B, 38 * B + 10, GROUND + 11 * B + 10)).save(os.path.join(OUT, "shrine_revealed.png"))
    print("ok")
