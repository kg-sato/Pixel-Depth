"""Textures for the 3D camp and mine (2026-11-08 v2): top-down grass for the camp crust, moss for cave floors,
a rippled water surface and three crack stages shown on a block while you dig it.
32 px pixel art from pd_art.py ramps, upscaled 8x nearest. Usage: python pd_world3d.py <out_dir>"""
import math, os, random, sys

OUT = sys.argv[1] if len(sys.argv) > 1 else os.path.join("roblox_tex", "world3d")
sys.argv = [sys.argv[0], os.path.join(OUT, "_tmp")]
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import pd_art as A  # noqa: E402
from PIL import Image  # noqa: E402

os.makedirs(OUT, exist_ok=True)
H, R, N = A.H, A.R, A.N


def save(name, im):
    im.resize((N * 8, N * 8), Image.NEAREST).save(os.path.join(OUT, name + ".png"))
    return im


def grass_top():
    im = Image.new("RGB", (N, N))
    ramp = [H(h) for h in ("#2f6f68", "#3f8f7c", "#58b090", "#7ccaa6", "#a6e4c4")]
    for y in range(N):
        for x in range(N):
            t = 0.25 + A.fbm(x / N, y / N, 31, base=3) * 0.55 + A.fbm(x / N, y / N, 32, base=8, octs=2) * 0.25
            im.putpixel((x, y), A.pick(ramp, t, x, y, 0.12))
    rv = random.Random(4)
    for _ in range(26):  # blades
        x, y = rv.randrange(N), rv.randrange(N)
        im.putpixel((x, y), ramp[4])
        im.putpixel((x, (y + 1) % N), ramp[3])
    for col in (R["rose"][2], R["gold"][3], R["lilac"][3], (255, 248, 240)):  # tiny flowers
        x, y = rv.randrange(1, N - 1), rv.randrange(1, N - 1)
        for dx, dy in ((0, 0), (1, 0), (-1, 0), (0, 1), (0, -1)):
            im.putpixel((x + dx, y + dy), col if (dx, dy) != (0, 0) else R["gold"][4])
    return im


def moss_top():
    im = Image.new("RGB", (N, N))
    dirt = R["dirt"]
    for y in range(N):
        for x in range(N):
            m = A.fbm(x / N, y / N, 41, base=3) + A.fbm(x / N, y / N, 42, base=8, octs=2) * 0.4
            if m > 0.62:
                im.putpixel((x, y), A.pick(dirt, 0.3 + (m - 0.62), x, y, 0.1))
            else:
                im.putpixel((x, y), A.pick(R["moss"], 0.2 + m * 0.9, x, y, 0.12))
    rv = random.Random(9)
    for _ in range(5):
        x, y = rv.randrange(N), rv.randrange(N)
        im.putpixel((x, y), R["mint"][4])
    return im


def water_top():
    im = Image.new("RGBA", (N, N))
    for y in range(N):
        for x in range(N):
            w = math.sin((x + 2 * math.sin(y / 5)) / 3.0) + math.sin((y + 2 * math.sin(x / 6)) / 4.0)
            if w > 1.45:
                im.putpixel((x, y), (236, 252, 255, 230))
            elif w > 0.9:
                im.putpixel((x, y), (170, 232, 242, 150))
            else:
                im.putpixel((x, y), (90, 180, 210, 60))
    return im


def crack(stage):
    im = Image.new("RGBA", (N, N), (0, 0, 0, 0))
    rv = random.Random(77)
    ink = (26, 16, 38, 235)
    lines = [((16, 16), a) for a in (0.3, 1.9, 3.6, 5.0)][:stage + 1] + [((9, 22), 4.2), ((23, 9), 1.0)][: max(0, stage - 1)]
    for (sx, sy), ang in lines:
        x, y = float(sx), float(sy)
        L = 7 + stage * 4
        for _ in range(L):
            ang += rv.uniform(-0.5, 0.5)
            x += math.cos(ang)
            y += math.sin(ang)
            if 0 <= int(x) < N and 0 <= int(y) < N:
                im.putpixel((int(x), int(y)), ink)
                if stage >= 2 and rv.random() < 0.35 and int(x) + 1 < N:
                    im.putpixel((int(x) + 1, int(y)), ink)
    return im


if __name__ == "__main__":
    out = [save("grass_top", grass_top()), save("moss_top", moss_top()), save("water_top", water_top())]
    for i in range(3):
        out.append(save(f"crack{i + 1}", crack(i + 1)))
    sheet = Image.new("RGBA", (len(out) * 34, 34), (40, 30, 60, 255))
    for i, t in enumerate(out):
        sheet.alpha_composite(t.convert("RGBA"), (i * 34 + 1, 1))
    sheet.resize((sheet.width * 4, sheet.height * 4), Image.NEAREST).save(os.path.join(OUT, "_sheet.png"))
    print(len(out), "textures ->", OUT)
