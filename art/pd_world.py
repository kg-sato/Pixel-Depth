"""Pixel Depths key art, part 2: the cave-system world scene and the pickaxe swing frames.
Uses the palette, textures and voxel characters from pd_art.py. Usage: python pd_world.py <out_dir>"""
import math, os, random, sys
from PIL import Image, ImageDraw
import pd_art as A
from pd_art import H, R, N, shade, lerp, pick, fbm, inside, INK

OUT = sys.argv[1] if len(sys.argv) > 1 else "out"
os.makedirs(OUT, exist_ok=True)
B, COLS, ROWS, GROUND, W, HH = 32, 40, 14, 156, 1280, 156 + 14 * 32  # cropped to 592 at the end

SPRITES = []  # (x, y, sprite) of the characters in the last scene, for the shader
CLAY = [H(h) for h in ("#4a2a3a", "#7a3f45", "#b0605a", "#d98b70", "#f2b896")]
STONE = [H(h) for h in ("#2a2440", "#463e66", "#665d8e", "#8a82b2", "#b3acd4")]
WATER = H("#6f8fe0")


def brick_tex(seed):
    rnd = random.Random(seed)
    im = [[None] * N for _ in range(N)]
    for y in range(N):
        for x in range(N):
            row = y // 8
            off = 8 if row % 2 else 0
            mortar = y % 8 == 7 or (x + off) % 16 == 15
            if mortar:
                im[y][x] = STONE[0]
            else:
                t = 0.35 + fbm(x / N, y / N, seed, base=4) * 0.45
                if y % 8 == 0 or (x + off) % 16 == 0:
                    t += 0.2
                if y % 8 == 6 or (x + off) % 16 == 14:
                    t -= 0.18
                im[y][x] = pick(STONE[1:], t, x, y, 0.1)
    for _ in range(3):  # moss tufts creeping over the bricks
        x, y = rnd.randrange(N), rnd.randrange(0, 10)
        for k in range(rnd.randrange(2, 5)):
            if 0 <= x + k < N:
                im[y][x + k] = R["moss"][2]
                if y + 1 < N:
                    im[y + 1][x + k] = R["moss"][1]
    return im


def build_map():
    m = [["#"] * COLS for _ in range(ROWS)]
    for c in range(COLS):
        m[0][c] = "^"
    carve = set()
    for p in ((0, 7), (0, 8), (1, 7), (1, 8), (2, 8), (2, 9), (3, 9), (3, 10), (4, 10)):  # cave mouth from the camp
        carve.add(p)
    for r in (3, 4):
        for c in range(10, 17):
            carve.add((r, c))
    for c in (12, 13, 14):
        carve.add((2, c))
    for r in range(0, 4):
        carve.add((r, 18))  # the player's own dig
    carve |= {(3, 17), (3, 19), (2, 17), (2, 19)}
    for r in range(5, 10):  # big cavern B, noisy edge
        for c in range(21, 30):
            if ((c - 25.5) / 4.8) ** 2 + ((r - 7) / 2.6) ** 2 + (fbm(c / 7, r / 4, 9, tile=False) - 0.5) * 1.6 < 1:
                carve.add((r, c))
    carve |= {(4, 24), (4, 25), (10, 23), (10, 24)}
    carve -= {(9, 26), (8, 26)}  # a stalagmite pillar in the middle of the cavern
    for p in ((4, 16), (5, 16), (5, 17), (6, 17), (6, 18), (7, 19), (7, 20), (6, 21)):  # tunnel A to B
        carve.add(p)
    for p in ((5, 10), (6, 10), (6, 9), (7, 9), (8, 8), (9, 8), (9, 7)):  # tunnel A down to the pool
        carve.add(p)
    for r in range(10, 13):
        for c in range(2, 13):
            if ((c - 7) / 5.6) ** 2 + ((r - 11.3) / 1.9) ** 2 < 1:
                carve.add((r, c))
    for p in ((10, 16), (11, 17), (11, 18), (12, 19), (12, 20), (11, 21), (12, 22), (13, 21), (13, 20)):  # the rift crack
        carve.add(p)
    for (r, c) in carve:
        m[r][c] = "."
    for r in range(5, 11):  # buried kobold shrine on the right
        for c in range(31, 38):
            m[r][c] = "S" if (r in (5, 10) or c in (31, 37)) else "i"
    for c in (32, 33, 36):
        m[5][c] = "#"
    for c in range(29, 31):
        m[8][c] = "."
        m[9][c] = "."
    m[8][31] = "D"
    m[9][31] = "D"
    rnd = random.Random(21)
    for r in range(1, ROWS):  # ore veins follow noise so they cluster
        for c in range(COLS):
            if m[r][c] != "#":
                continue
            n = fbm(c / 14, r / 6, 33, base=2, tile=False)
            n2 = fbm(c / 11, r / 5, 44, base=2, tile=False)
            if n > 0.72 and rnd.random() < 0.7:
                m[r][c] = "o"
            elif n2 > 0.72 and rnd.random() < 0.7:
                m[r][c] = "c"
    for p in ((5, 19), (5, 20), (6, 19)):
        m[p[0]][p[1]] = "g"
    m[7][17] = "e"
    for p in ((11, 23), (11, 24)):  # a geode pair under the crystal cavern
        if m[p[0]][p[1]] in "#oct":
            m[p[0]][p[1]] = "G"
    for r in (12, 13):  # Titan's Rest clay starts below a wavy line
        for c in range(COLS):
            if m[r][c] == "#" and (r == 13 or math.sin(c / 3) > 0.2):
                m[r][c] = "t"
    return m


def scene(TV, night=False, sky_fn=None, post_fn=None):
    m = build_map()
    img = Image.new("RGB", (W, HH))
    px = img.load()
    d = ImageDraw.Draw(img)
    emit = Image.new("RGB", (W, HH))  # emissive map for the night shader (what glows by itself)
    ep = emit.load()
    de = ImageDraw.Draw(emit)
    sky = [H(h) for h in ("#8d9fe0", "#a4aee6", "#bdb3e6", "#d4b6dd", "#ecbccd", "#ffc9b8", "#ffdcc4")]
    for y in range(GROUND):
        for x in range(W):
            px[x, y] = pick(sky, y / GROUND, x, y, 0.22)

    def blob(cx, cy, rs, top, bot, ymax=GROUND):
        for (ox, oy, r) in rs:
            for yy in range(-r, r + 1):
                for xx in range(-r, r + 1):
                    if xx * xx + yy * yy <= r * r:
                        X, Y = cx + ox + xx, cy + oy + yy
                        if 0 <= X < W and 0 <= Y < ymax:
                            px[X, Y] = bot if Y > cy + 2 else top

    for (cx, cy, sc) in ((520, 40, 1.0), (840, 66, 0.8), (1120, 30, 1.2), (690, 20, 0.6)):
        rs = [(int(o * sc), int(q * sc), max(3, int(r * sc))) for o, q, r in ((0, 0, 14), (18, 4, 11), (-17, 5, 10), (34, 8, 7), (-31, 9, 6))]
        blob(cx, cy, rs, H("#fff3ec"), H("#e4cfe6"))
    for (amp, base_y, col, seed) in ((22, GROUND - 26, H("#b9a6d8"), 3), (16, GROUND - 12, H("#a48ec8"), 9)):
        for x in range(W):
            hy = int(base_y - amp * fbm(x / W, 0.5, seed, base=5, tile=False))
            for y in range(max(0, hy), GROUND):
                px[x, y] = col
    trunk, trunk_l, trunk_d = H("#8f78a8"), H("#ab95c6"), H("#715c8c")  # the world tree on the far right
    for y in range(0, GROUND):
        flare = max(0, (y - 90)) ** 1.6 * 0.35
        half = 66 + int(6 * math.sin(y / 23)) + int(flare)
        cx = 1170 + int(6 * math.sin(y / 41))
        for x in range(cx - half, cx + half):
            if 0 <= x < W:
                rel = (x - (cx - half)) / (2 * half)
                groove = (x * 3 + int(8 * math.sin(y / 17 + x / 9))) % 13 == 0
                c = trunk_d if rel < 0.2 else (trunk_l if rel > 0.82 else trunk)
                px[x, y] = trunk_d if groove and 0.1 < rel < 0.92 else c
    leaf_t, leaf_b = H("#b4e6d2"), H("#8cc7b8")
    for (cx, cy) in ((1240, -8), (1170, 6), (1090, -4), (1010, 12), (940, 0), (1270, 24)):
        blob(cx, cy, [(0, 0, 30), (24, 8, 22), (-22, 10, 20), (8, 18, 16)], leaf_t, leaf_b)

    if night and sky_fn:
        sky_fn(img, emit)
    # back wall behind every open cell, darker the deeper it goes
    for r in range(ROWS):
        for c in range(COLS):
            if m[r][c] in ".Di":
                t = TV[(r + c) % len(TV)]["cave"]
                for y in range(B):
                    for x in range(B):
                        X, Y = c * B + x, GROUND + r * B + y
                        if r == 0 and y < 6:
                            continue
                        px[X, Y] = t[y][x] if m[r][c] == "." else STONE[1] if (x + y) % 9 else STONE[0]
    for r in range(ROWS):  # the shrine interior gets a brick back wall
        for c in range(COLS):
            if m[r][c] == "i":
                bt = brick_tex(5 + c)
                for y in range(B):
                    for x in range(B):
                        px[c * B + x, GROUND + r * B + y] = shade(bt[y][x], 0.7)

    # solid blocks
    kind = {"#": "rootflint", "^": "grass", "o": "copper", "c": "ashcoal", "g": "gilded_full", "e": "amber_egg", "t": "clay", "G": "geode"}
    rare = {"gilded_full": A.tex_gilded_full(), "amber_egg": A.tex_amber_egg(), "geode": A.tex_geode()}
    for v in TV:
        v.update(rare)
    for v in TV:
        v["clay"] = v.get("clay") or A.tex_dirt(81 + TV.index(v) * 97, ramp=CLAY, pebbles=3, roots=0)
    bricks = brick_tex(77)
    TF = [A.make_textures(v, bevel=False) for v in range(len(TV))]
    for v in TF:
        v.update(rare)
    for v, f_ in zip(TF, TV):
        v["clay"] = A.tex_dirt(81 + TV.index(f_) * 97, ramp=CLAY, pebbles=3, roots=0, bevel=False)
    for r in range(ROWS):
        for c in range(COLS):
            k = m[r][c]
            if k in ".Di":
                continue
            if k == "S":
                t, f = bricks, 1
            else:
                t = (TF if night else TV)[(r * 5 + c * 3 + (r * c) % 4) % len(TV)][kind[k]]
                f = 1.0 if night else 0.92 + fbm(c / COLS, r / ROWS, 404, base=3, tile=False) * 0.16
            flip = (r * 7 + c) % 3 == 0 and k in "#oct"
            if k in "gGe":
                f = 1.0
            for y in range(B):
                for x in range(B):
                    col = t[y][B - 1 - x if flip else x]
                    px[c * B + x, GROUND + r * B + y] = shade(col, f) if k in "#^t" else col
    D, SK = 9, 6
    for r in range(ROWS):  # oblique top and right faces where a block borders open space
        for c in range(COLS):
            k = m[r][c]
            if k in ".Di":
                continue
            t = bricks if k == "S" else TV[0][kind[k]]
            X0, Y0 = c * B, GROUND + r * B
            if r > 0 and m[r - 1][c] in ".Di":
                for i in range(D):
                    sh = int((D - i) * SK / D)
                    for x in range(B):
                        if X0 + x + sh < W:
                            px[X0 + x + sh, Y0 - D + i] = shade(t[1 + (i * 3) // D][x], 1.12 if i < D - 1 else 1.0)
            if c + 1 < COLS and m[r][c + 1] in ".Di":
                for j in range(SK):
                    lift = int(j * D / SK)
                    for y in range(B):
                        if GROUND <= Y0 + y - lift:
                            px[X0 + B + j, Y0 + y - lift] = shade(t[y][B - 1 - j % 3], 0.7)

    rnd = random.Random(8)
    lights = [(18 * B + 20, GROUND + 3 * B + 4, 130, (1.0, 0.97, 0.88))]
    for r in range(1, ROWS):  # cave dressing: drips from ceilings, mushrooms and roots
        for c in range(COLS):
            if m[r][c] != ".":
                continue
            X0, Y0 = c * B, GROUND + r * B
            if m[r - 1][c] not in ".Di" and rnd.random() < 0.7:
                for _ in range(rnd.randrange(1, 3)):
                    sx, ln = X0 + rnd.randrange(3, 27), rnd.randrange(6, 26)
                    for k in range(ln):
                        w = max(0, 2 - k * 3 // ln)
                        for xx in range(-w, w + 1):
                            px[sx + xx, Y0 + k] = R["dirt"][2] if xx < 0 or k < 2 else R["dirt"][1]
                    if rnd.random() < 0.3:
                        px[sx, Y0 + ln + 2] = R["mint"][3]
            if r + 1 < ROWS and m[r + 1][c] not in ".Di":  # rubble pebbles along the floor
                for _ in range(rnd.randrange(1, 4)):
                    bx_, bw_ = X0 + rnd.randrange(2, 26), rnd.choice((2, 3, 4))
                    by_ = Y0 + B - D + 1
                    for xx in range(bw_):
                        px[bx_ + xx, by_] = R["pebble"][1]
                        px[bx_ + xx, by_ - 1] = R["pebble"][2] if xx else R["pebble"][3]
            if r + 1 < ROWS and m[r + 1][c] not in ".Di" and rnd.random() < 0.35:
                mc = rnd.choice((R["rose"], R["mint"], R["lilac"]))
                mx, my = X0 + rnd.randrange(6, 24), Y0 + B - D + 1
                for y in range(5):
                    px[mx, my - y] = R["egg"][2]
                    px[mx + 1, my - y] = R["egg"][1]
                for xx in range(-4, 6):
                    for yy in range(0, 4):
                        if ((xx - 0.5) / 5) ** 2 + (yy / 4) ** 2 <= 1:
                            px[mx + xx, my - 5 - yy] = mc[3] if yy >= 2 else mc[2]
                            ep[mx + xx, my - 5 - yy] = px[mx + xx, my - 5 - yy]
                px[mx - 2, my - 8] = mc[-1]
                lights.append((mx, my - 6, 44, tuple(v / 255 for v in mc[3])))

    # water pool, drawn as 2.5D water blocks like the rock: a see-through front face per cell
    # and a top surface face that leans back and to the right exactly like the block tops
    WL = GROUND + 11 * B  # the surface sits on the cell grid (Minecraft-style water blocks)
    wcells = [(r, c) for r in (11, 12) for c in range(2, 13) if m[r][c] == "."] if not night else []  # at night the shader pours real liquid
    for (r, c) in wcells:
        X0, Y0 = c * B, GROUND + r * B
        for y in range(B):
            Y = Y0 + y
            depth_ = (Y - WL) / 60
            for x in range(B):
                X = X0 + x
                wc = lerp(H("#86d6de"), H("#162055"), min(1, depth_) ** 0.75)
                if x == 0 or y == 0:
                    wc = lerp(wc, H("#d8f6ff"), 0.18)  # faint cell edges: you can read the water blocks
                if (X // 5 + Y // 9) % 7 == 0 and depth_ < 0.6:
                    wc = lerp(wc, H("#b9eef4"), 0.25)  # shimmer
                px[X, Y] = lerp(px[X, Y], wc, 0.8)
        if r == 11 or (r - 1, c) not in wcells:  # top surface face
            for i_ in range(D):
                sh = int((D - i_) * SK / D)
                yy = Y0 - D + i_
                for x in range(B):
                    X = X0 + x + sh
                    if X >= 13 * B + SK:
                        continue
                    sc = lerp(H("#e2f9ff"), H("#8fdbe4"), i_ / D)
                    if (x + i_ * 4 + c * 7) % 13 < 2:
                        sc = H("#ffffff")  # ripple glints
                    px[X, yy] = lerp(px[X, yy], sc, 0.85)
                    ep[X, yy] = lerp((0, 0, 0), sc, 0.22)
            for x in range(B):
                px[X0 + x, Y0] = H("#e8fbff")  # bright front lip where surface meets front face
                ep[X0 + x, Y0] = (70, 100, 115)
    for X in range(2 * B, 13 * B):  # caustics dancing on the cave ceiling over the pool
        for Y in range(GROUND + 10 * B - 6, GROUND + 11 * B + 8):
            if A.hsh(X // 4, Y // 3, 77) > 0.9 and abs(math.sin(X / 11 + math.sin(Y / 4) * 1.5)) < 0.25 and Y > GROUND + 10 * B + 4:
                cm = m[(Y - GROUND) // B][X // B]
                if cm in ".":
                    px[X, Y] = lerp(px[X, Y], H("#9fe6ee"), 0.5)
                    ep[X, Y] = (20, 45, 55)

    # shrine: rune door, banners, lantern, chest
    dx0, dy0 = 31 * B, GROUND + 8 * B
    d.rectangle([dx0 + 2, dy0 + 10, dx0 + 29, dy0 + 2 * B - 1], fill=STONE[2])
    d.ellipse([dx0 + 2, dy0 - 4, dx0 + 29, dy0 + 24], fill=STONE[2])
    d.ellipse([dx0 + 7, dy0 + 2, dx0 + 24, dy0 + 22], fill=H("#1a1428"))
    d.rectangle([dx0 + 7, dy0 + 12, dx0 + 24, dy0 + 2 * B - 1], fill=H("#1a1428"))
    d.rectangle([dx0 + 2, dy0 + 10, dx0 + 3, dy0 + 2 * B - 1], fill=STONE[4])
    for i, (rx, ry) in enumerate(((12, 14), (18, 20), (13, 28), (19, 36), (14, 44), (18, 52))):
        d.rectangle([dx0 + rx, dy0 + ry, dx0 + rx + 2, dy0 + ry + 3], fill=R["mint"][3])
        de.rectangle([dx0 + rx, dy0 + ry, dx0 + rx + 2, dy0 + ry + 3], fill=R["mint"][3])
    d.rectangle([dx0 + 13, dy0 - 3, dx0 + 18, dy0 + 1], fill=STONE[4])  # keystone
    lights.append((dx0 + 16, dy0 + 32, 90, (0.6, 1.0, 0.85)))
    for bx in (33 * B + 6, 35 * B + 10):  # banners
        d.rectangle([bx, GROUND + 6 * B + 4, bx + 14, GROUND + 7 * B + 18], fill=R["rose"][1])
        d.polygon([(bx, GROUND + 7 * B + 18), (bx + 7, GROUND + 7 * B + 26), (bx + 14, GROUND + 7 * B + 18)], fill=R["rose"][1])
        d.rectangle([bx + 5, GROUND + 6 * B + 14, bx + 9, GROUND + 6 * B + 24], fill=R["gold"][3])
        d.rectangle([bx - 2, GROUND + 6 * B + 2, bx + 16, GROUND + 6 * B + 4], fill=R["wood"][2])
    chx, chy = 34 * B + 4, GROUND + 10 * B - 20  # chest
    d.rectangle([chx, chy, chx + 26, chy + 18], fill=R["wood"][2])
    d.rectangle([chx, chy, chx + 26, chy + 6], fill=R["wood"][3])
    d.rectangle([chx, chy + 6, chx + 26, chy + 7], fill=R["gold"][2])
    d.rectangle([chx + 11, chy + 5, chx + 15, chy + 11], fill=R["gold"][3])
    de.rectangle([chx + 11, chy + 5, chx + 15, chy + 11], fill=R["gold"][2])
    d.rectangle([chx - 1, chy - 1, chx + 27, chy + 19], outline=INK)
    lights.append((chx + 13, chy + 6, 60, (1.0, 0.9, 0.6)))
    d.rectangle([36 * B + 10, GROUND + 7 * B + 2, 36 * B + 13, GROUND + 7 * B + 14], fill=R["wood"][1])
    d.rectangle([36 * B + 6, GROUND + 7 * B + 14, 36 * B + 17, GROUND + 7 * B + 24], fill=R["gold"][3])
    de.rectangle([36 * B + 7, GROUND + 7 * B + 15, 36 * B + 16, GROUND + 7 * B + 23], fill=R["gold"][4])
    lights.append((36 * B + 12, GROUND + 7 * B + 19, 70, (1.0, 0.92, 0.7)))

    # crystals growing in cavern B
    for (bx, by, ang, L, wd, rp) in ((23 * B + 10, GROUND + 9 * B + 20, -0.5, 30, 11, R["mint"]), (24 * B + 2, GROUND + 9 * B + 22, 0.1, 40, 13, R["mint"]),
                                     (25 * B + 0, GROUND + 9 * B + 22, 0.55, 26, 10, R["lilac"]), (28 * B + 6, GROUND + 5 * B + 8, 3.0, 24, 9, R["lilac"])):
        ddx, ddy, pxx, pyy = math.sin(ang), -math.cos(ang), math.cos(ang), math.sin(ang)
        pts = [(bx - pxx * wd / 2, by - pyy * wd / 2), (bx + pxx * wd / 2, by + pyy * wd / 2), (bx + ddx * L * .7 + pxx * wd / 2, by + ddy * L * .7 + pyy * wd / 2),
               (bx + ddx * L, by + ddy * L), (bx + ddx * L * .7 - pxx * wd / 2, by + ddy * L * .7 - pyy * wd / 2)]
        for y in range(int(by - L - 4), int(by + L + 4)):
            for x in range(int(bx - L - 4), int(bx + L + 4)):
                if 0 <= x < W and GROUND <= y < HH and inside(x + .5, y + .5, pts):
                    side = (x + .5 - bx) * pxx + (y + .5 - by) * pyy
                    px[x, y] = rp[3] if side < -wd * .12 else (rp[1] if side > wd * .12 else rp[2])
                    ep[x, y] = lerp(px[x, y], (0, 0, 0), 0.25)
        lights.append((int(bx + ddx * L / 2), int(by + ddy * L / 2), 80, tuple(v / 255 for v in rp[3])))

    # the rift to the next realm: a glowing crack with floating stones
    rr = random.Random(12)  # jagged lightning-shaped crack, wide in the middle
    pts_top, pts_bot = [], []
    for i in range(15):
        t = i / 14
        x = 16 * B + 8 + t * (6.5 * B)
        y = GROUND + 11.6 * B + math.sin(t * 5) * 14
        half = 3 + 15 * math.sin(t * math.pi) ** 1.5 + rr.uniform(-2, 2)
        pts_top.append((x + rr.uniform(-3, 3), y - half))
        pts_bot.append((x + rr.uniform(-3, 3), y + half))
    rift = pts_top + pts_bot[::-1]
    cx_, cy_ = 19.5 * B, GROUND + 11.6 * B
    for y in range(GROUND + 10 * B, HH):
        for x in range(16 * B, 23 * B + 12):
            if inside(x + .5, y + .5, rift):  # a void full of stars, rimmed with light
                rim = not all(inside(x + .5 + ox, y + .5 + oy, rift) for ox, oy in ((3, 0), (-3, 0), (0, 3), (0, -3)))
                rim2 = not all(inside(x + .5 + ox, y + .5 + oy, rift) for ox, oy in ((6, 0), (-6, 0), (0, 5), (0, -5)))
                if rim:
                    px[x, y] = (255, 250, 255)
                elif rim2:
                    px[x, y] = R["lilac"][3]
                else:
                    px[x, y] = H("#160c2c") if A.hsh(x, y, 5) > 0.03 else (R["lilac"][4] if A.hsh(x, y, 6) > 0.5 else R["mint"][3])
                ep[x, y] = lerp(px[x, y], (0, 0, 0), 0.55 if rim else 0.7) if (rim or rim2 or px[x, y] != H("#160c2c")) else (20, 10, 36)
    for k in range(40):  # sparks leaking out of the rift
        sx, sy = int(cx_ + rr.uniform(-110, 110)), int(cy_ + rr.uniform(-40, 20))
        if GROUND < sy < HH:
            px[sx, sy] = R["lilac"][4]
    for (fx, fy, fs) in ((18 * B + 4, GROUND + 10 * B + 22, 7), (20 * B + 18, GROUND + 10 * B + 30, 5), (21 * B + 28, GROUND + 11 * B + 4, 4)):
        d.rectangle([fx, fy, fx + fs, fy + fs - 2], fill=CLAY[2])
        d.rectangle([fx, fy, fx + fs, fy + 1], fill=CLAY[3])
    lights.append((int(19.5 * B), GROUND + 12 * B, 170, (0.85, 0.7, 1.0)))

    # surface: mine entrance with beams over the cave mouth, tent, lantern
    mx0 = 7 * B
    d.rectangle([mx0 - 6, GROUND - 46, mx0 - 1, GROUND + 4], fill=R["wood"][1])
    d.rectangle([mx0 + 2 * B, GROUND - 46, mx0 + 2 * B + 5, GROUND + 4], fill=R["wood"][1])
    d.rectangle([mx0 - 12, GROUND - 52, mx0 + 2 * B + 11, GROUND - 44], fill=R["wood"][2])
    d.rectangle([mx0 - 12, GROUND - 52, mx0 + 2 * B + 11, GROUND - 51], fill=R["wood"][3])
    d.rectangle([mx0 + 22, GROUND - 44, mx0 + 25, GROUND - 34], fill=R["wood"][0])
    d.rectangle([mx0 + 18, GROUND - 34, mx0 + 29, GROUND - 25], fill=R["gold"][3])
    de.rectangle([mx0 + 19, GROUND - 33, mx0 + 28, GROUND - 26], fill=R["gold"][4])
    lights.append((mx0 + 24, GROUND - 30, 60, (1.0, 0.92, 0.7)))
    if not night:  # the night camp is drawn by pd_night (forge, stall, incubator, headframe)
        d.polygon([(40, GROUND), (86, GROUND - 50), (132, GROUND)], fill=R["lilac"][2])
        d.polygon([(86, GROUND - 50), (132, GROUND), (104, GROUND)], fill=R["lilac"][1])
        d.polygon([(76, GROUND), (86, GROUND - 24), (96, GROUND)], fill=R["cave"][1])
        lx0 = 18 * B + 16  # lift A-frame over the player's dig
        d.line([(lx0 - 34, GROUND), (lx0, GROUND - 70)], fill=R["wood"][2], width=5)
        d.line([(lx0 + 34, GROUND), (lx0, GROUND - 70)], fill=R["wood"][1], width=5)
        d.rectangle([lx0 - 10, GROUND - 78, lx0 + 10, GROUND - 66], fill=R["wood"][3])
        d.line([(lx0, GROUND - 66), (lx0, GROUND + 2 * B)], fill=R["egg"][1], width=1)

    # characters
    dwa, kob = A.dwarf(), A.kobold()
    def rim(sp):
        sp = sp.copy()
        q = sp.load()
        for y in range(1, sp.height):
            for x in range(1, sp.width):
                if q[x, y][3] and (q[x, y - 1][3] == 0 or q[x - 1, y][3] == 0) and q[x, y][:3] != INK:
                    q[x, y] = lerp(q[x, y][:3], (255, 240, 214), 0.45) + (255,)
        return sp

    ds, ks = rim(A.render_oblique(dwa, s=3 if night else 2)), rim(A.render_oblique(kob, s=2))  # bigger miner: kids must read him
    floor = GROUND + 4 * B - D + 3
    img.paste(ds, (18 * B + 16 - ds.width // 2, floor - ds.height + 2), ds)
    img.paste(ks, (19 * B + 18 - ks.width // 2, floor - ks.height + 2), ks)
    SPRITES.clear()
    for sp, ox, oy in ((ds, 18 * B + 16 - ds.width // 2, floor - ds.height + 2), (ks, 19 * B + 18 - ks.width // 2, floor - ks.height + 2)):
        SPRITES.append((ox, oy, sp))
        q = sp.load()
        for y in range(sp.height):
            for x in range(sp.width):
                if q[x, y][3]:
                    ep[ox + x, oy + y] = lerp(q[x, y][:3], (0, 0, 0), 0.72)
    lights.append((19 * B + 20, GROUND + 5 * B + 20, 90, (1.0, 0.85, 0.5)))  # the gilded vein glows
    lights.append((17 * B + 16, GROUND + 7 * B + 16, 60, (1.0, 0.97, 0.92)))  # the fossil egg

    if night:  # gilded ore, the fossil egg and glowing voxels on the characters emit light too
        for r in range(ROWS):  # rare blocks glow as whole blocks
            for c in range(COLS):
                if m[r][c] in "gGe":
                    for y in range(B):
                        for x in range(B):
                            X, Y = c * B + x, GROUND + r * B + y
                            ep[X, Y] = lerp(px[X, Y], (0, 0, 0), 0.55)
        for y in range(GROUND, GROUND + 5 * B):
            for x in range(14 * B, 22 * B):
                if px[x, y] in A.GLOW:
                    ep[x, y] = lerp(px[x, y], (0, 0, 0), 0.55)
        if post_fn:
            post_fn(img, emit, m)
        return img, m, lights, emit
    # light pass: caves darken with depth, stepped bands around every light
    for y in range(GROUND, HH):
        depth = (y - GROUND) / (HH - GROUND)
        for x in range(W):
            amb = 0.9 - 0.45 * depth
            tint = [amb * 0.94, amb * 0.9, amb * 1.06]
            for (lx, ly, lr, lc) in lights:
                dd = math.hypot(x - lx, (y - ly) * 1.1)
                if dd < lr:
                    band = 0.3 if dd < lr * 0.33 else (0.17 if dd < lr * 0.66 else 0.07)
                    tint = [tint[i] + band * lc[i] for i in range(3)]
            c = px[x, y]
            px[x, y] = tuple(max(0, min(255, int(c[i] * min(tint[i], 1.3)))) for i in range(3))
    return img.crop((0, 0, W, 592))


def swing_frames():
    """Pickaxe swing, Pixel Blade style, in the side pose: anticipation, swing with a crescent smear,
    impact with hit-stop sparks, follow-through, recover. The pick turns about the near (left) hand."""
    s, k = 4, 0.5
    plain = A.dwarf(with_pick=False)
    zmax = max(q[2] for q in plain)
    side = A.face_right(plain)
    base = A.render_oblique(side, s=s)
    xs, ys, zs = [q[0] for q in side], [q[1] for q in side], [q[2] for q in side]
    x0, y1, z0 = min(xs), max(ys), min(zs)
    dz = max(zs) - z0 + 1
    hv = (zmax - 6, 8, 2)  # left hand after face_right
    gx = (hv[0] - x0) * s + (hv[2] - z0) * k * s + 2 + s / 2
    gy = (y1 - hv[1]) * s - (hv[2] - z0) * k * s + dz * k * s + 2 + s / 2
    L = 17 * s
    pick = Image.new("RGBA", (2 * L + 8, 2 * L + 8), (0, 0, 0, 0))  # grip at the centre so rotation pivots on the hand
    c0 = L + 4
    pd = ImageDraw.Draw(pick)
    pd.rectangle([c0 - s // 2, c0 - 15 * s, c0 + s // 2, c0 + 2 * s], fill=R["wood"][2] + (255,))
    pd.rectangle([c0 - s // 2, c0 - 15 * s, c0 - s // 2 + 1, c0 + 2 * s], fill=R["wood"][3] + (255,))
    pd.rectangle([c0 - 4 * s, c0 - 17 * s, c0 + 5 * s, c0 - 15 * s], fill=R["mint"][2] + (255,))
    pd.rectangle([c0 - 4 * s, c0 - 17 * s, c0 + 5 * s, c0 - 16 * s - 2], fill=R["mint"][3] + (255,))
    pd.rectangle([c0 - 5 * s, c0 - 15 * s, c0 - 4 * s, c0 - 14 * s], fill=R["mint"][1] + (255,))
    pd.rectangle([c0 + 5 * s, c0 - 15 * s, c0 + 6 * s, c0 - 14 * s], fill=R["mint"][1] + (255,))
    pick = A.add_outline(pick)
    blk = A.to_img(A.make_textures(0)["copper"]).resize((20 * s, 20 * s), Image.NEAREST)
    frames = [("ANTICIPATE", -80, None, 0, -3), ("SWING", 30, (-80, 30), 0, 3), ("IMPACT", 112, (-20, 112), 1, 6), ("FOLLOW", 135, (70, 135), 0, 5), ("RECOVER", 5, None, 0, 0)]
    out = []
    PX, PY = 60, 70
    for name, ang, smear, hit, lean in frames:
        fr = Image.new("RGBA", (base.width + 210, base.height + 110), (0, 0, 0, 0))
        fr.paste(blk, (PX + base.width + 30, PY + base.height - 20 * s))
        fr.paste(base, (PX + lean, PY + (3 if hit else 0)), base)
        GX, GY = PX + lean + gx, PY + gy + (3 if hit else 0)
        fp = fr.load()
        if smear:
            a0, a1 = smear
            rin, rout = 10 * s, 18 * s
            for y in range(fr.height):
                for x in range(fr.width):
                    dx, dy = x - GX, y - GY
                    r = math.hypot(dx, dy)
                    a = math.degrees(math.atan2(dx, -dy))
                    if rin <= r <= rout and a0 <= a <= a1:
                        t = (a - a0) / max(1, a1 - a0)
                        edge = (r - rin) / (rout - rin)
                        if edge > 0.82 - 0.2 * t:
                            col = (255, 255, 250, 255)
                        elif edge > 0.5:
                            col = R["mint"][3] + (255,)
                        elif edge > 0.25 and (x + y) % 2 == 0 and t > 0.35:
                            col = R["mint"][2] + (255,)
                        else:
                            continue
                        if t < 0.3 and (x + y) % 2:
                            continue
                        fp[x, y] = col
        rp = pick.rotate(-ang, resample=Image.NEAREST)
        fr.paste(rp, (int(GX - rp.width / 2), int(GY - rp.height / 2)), rp)
        if hit:
            rad = math.radians(ang)
            tx, ty = int(GX + math.sin(rad) * 16 * s), int(GY - math.cos(rad) * 16 * s)
            dr = ImageDraw.Draw(fr)
            for q in range(8):
                aa = q * math.pi / 4
                ln = 26 if q % 2 == 0 else 14
                dr.line([(tx, ty), (tx + math.cos(aa) * ln, ty + math.sin(aa) * ln)], fill=(255, 251, 230, 255), width=3)
            dr.ellipse([tx - 18, ty - 18, tx + 18, ty + 18], outline=R["gold"][3] + (255,), width=3)
            dr.rectangle([tx - 3, ty - 3, tx + 3, ty + 3], fill=(255, 255, 255, 255))
        out.append((name, fr))
    return out


def facing_frames():
    """Idle faces the camera; moving turns side-on and walks (two leg phases)."""
    s = 4
    d = A.dwarf()
    side = A.face_right(A.dwarf())
    frames = [("IDLE (FACES YOU)", A.render_oblique(d, s=s))]
    for ph, nm in ((-1, "WALK 1"), (0, "WALK 2"), (1, "WALK 3")):
        frames.append((nm, A.render_oblique(A.walk_pose(side, ph), s=s)))
    kb = A.kobold()
    frames.append(("KOBOLD IDLE", A.render_oblique(kb, s=s)))
    frames.append(("KOBOLD RUN", A.render_oblique(A.walk_pose(A.face_right(kb), 1), s=s)))
    return frames


if __name__ == "__main__":
    TV = [A.make_textures(v) for v in range(4)]
    scene(TV).save(os.path.join(OUT, "scene_caves.png"))
    frames = swing_frames()
    Wd = sum(f.width for _, f in frames)
    strip = Image.new("RGBA", (Wd, frames[0][1].height), (0, 0, 0, 0))
    x = 0
    for name, f in frames:
        f.save(os.path.join(OUT, f"swing_{name.lower()}.png"))
        strip.paste(f, (x, 0), f)
        x += f.width
    strip.save(os.path.join(OUT, "swing_strip.png"))
    ff = facing_frames()
    hgt = max(f.height for _, f in ff)
    strip = Image.new("RGBA", (sum(f.width for _, f in ff) + 30 * len(ff), hgt), (0, 0, 0, 0))
    x = 0
    for name, f in ff:
        strip.paste(f, (x, hgt - f.height), f)
        x += f.width + 30
    strip.save(os.path.join(OUT, "facing_strip.png"))
    print("ok")
