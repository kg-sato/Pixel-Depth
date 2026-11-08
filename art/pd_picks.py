"""The magical pickaxe set: each design keeps the palette, materials and charms of one reference
(References/Pickaxes/pin_XX.jpg) but takes the shape of a traditional pickaxe. Usage: python pd_picks.py <out_dir> [ids]"""
import math, os, sys
import numpy as np
from scipy.ndimage import binary_erosion
from pd_magic import Art, hx, bez

OUT = sys.argv[1] if len(sys.argv) > 1 else "out"
W, H = 736, 1104


def erode(m, px):
    return binary_erosion(m > 0.5, iterations=int(px * 2)).astype(np.float32)


def pommel(a, P0, P1, field, rim="#fff8ff", length=70, width=26, collar="#f3e6ff"):
    dx, dy = P1[0] - P0[0], P1[1] - P0[1]
    L = math.hypot(dx, dy)
    ux, uy = dx / L, dy / L
    vx, vy = uy, -ux
    tip = (P0[0] - ux * length, P0[1] - uy * length)
    pts = [(P0[0] + vx * width, P0[1] + vy * width), (P0[0] - vx * width, P0[1] - vy * width), tip]
    a.gem(pts, field, (P0[0] - ux * length * 0.35), (P0[1] - uy * length * 0.35))
    c = a.ellipse(P0[0], P0[1], width * 1.15, width * 0.55, math.atan2(vy, vx))
    a.bevel(c, collar, radius=8, spec=0.7, rim=rim, dark=0.6)
    return (ux, uy, vx, vy)


def design_01(a):
    """Lavender heart-gem pickaxe (pin_01): glitter-iridescent pick arms with a pale frame, flower rosette, heart gem, pink bow, star and heart charms."""
    a.paint(np.ones((a.H, a.W)), a.vgrad("#bba8ec", "#e2cdf3", 0, 700))
    a.paint(np.clip((a.yy / 2 - 700) / 400, 0, 1), "#cbb5ee", 1)
    a.clouds(7, "#ffffff", 0.45, (0, 450, W, 1100))
    a.clouds(3, "#f6e6ff", 0.35, (0, 0, W, 300))
    for (cx, cy) in ((50, 620), (80, 720), (650, 780), (690, 880), (590, 1010), (30, 990)):  # soft blossom clusters
        for k in range(7):
            a.flower(cx + a.rnd.uniform(-55, 55), cy + a.rnd.uniform(-45, 45), a.rnd.uniform(9, 14), "#f8d0ea", "#fff3c8", 5, a.rnd.uniform(0, 1), 0.75)
    a.sky_sparkles(240, big=16)
    for (bx, by, sz) in ((640, 115, 16), (90, 470, 14), (610, 600, 14), (430, 1000, 13), (95, 830, 13)):  # butterflies
        for sgn in (-1, 1):
            a.paint(a.ellipse(bx + sgn * sz * 0.55, by - sz * 0.15, sz * 0.55, sz * 0.4, sgn * 0.5), "#ffffff", 0.85)
            a.paint(a.ellipse(bx + sgn * sz * 0.45, by + sz * 0.35, sz * 0.35, sz * 0.25, -sgn * 0.4), "#f6e6ff", 0.85)
        a.glow(a.ellipse(bx, by, sz, sz), "#ffffff", 8, 0.5)
    P0, P1 = (205, 990), (418, 312)
    irid = a.iridescent(["#c9a8ff", "#f6bfe9", "#b8d4ff", "#e9d8ff", "#ffcfe9"], 160, 0.7, 0.35, 3)
    a.handle(P0, P1, 34, irid, wrap="#f7c8e6", wrap_n=12)
    to = a.frame(P0, P1)
    for side in (-1, 1):  # pick arms: pale shimmering frame around a galaxy-glitter core
        arm = a.poly(a.pick_arm(to, side, 250, 74, 140, curl=0.3, root=22))
        a.bevel(arm, a.iridescent(["#f9e8ff", "#ffe0f3", "#e8f0ff"], 90, 0.3, 0.2, 5), radius=16, spec=0.7, rim="#ffffff", dark=0.7)
        core = erode(arm, 9)
        a.bevel(core, a.iridescent(["#b48cf0", "#d9a3ef", "#9fb8f6", "#c8a0f8", "#e8b0e8"], 70, 1.1, 0.45, 9 + side), radius=22, spec=0.45, rim=None, dark=0.72)
        a.glitter(core, 1100, ("#ffffff", "#fff2fb", "#e0f4ff", "#ffd6f2"))
        a.glow(arm, "#e8c8ff", 18, 0.22)
    cx, cy = to(0, 0)
    for k in range(14):  # rosette of petals and leaves around the gem
        ang = k / 14 * 2 * math.pi
        col = ("#bfa2f2", "#d9c2ff", "#b9e6d2", "#f2c2ea")[k % 4]
        pm = a.ellipse(cx + 48 * math.cos(ang), cy + 48 * math.sin(ang), 30, 13, ang)
        a.bevel(pm, col, radius=7, spec=0.5, rim="#ffffff", dark=0.65)
    for k in range(8):
        ang = k / 8 * 2 * math.pi + 0.2
        a.bevel(a.ellipse(cx + 34 * math.cos(ang), cy + 34 * math.sin(ang), 9, 9), "#f6d6ef", radius=5, spec=0.6, rim="#ffffff", dark=0.7)
    tip = to(0, 120)  # crystal spike above the gem
    spike = [to(-16, 30), to(16, 30), tip]
    a.gem(spike, a.iridescent(["#e8d6ff", "#ffd6f0", "#d6ecff"], 40, 0.2, 0.2, 11), *to(0, 60))
    frame = a.poly(a.heart_pts(cx, cy + 4, 50))
    a.bevel(frame, "#ef9fcf", radius=8, spec=0.6, rim="#fff0f8", dark=0.6)
    a.gem(a.heart_pts(cx, cy + 4, 40), a.iridescent(["#f2b6ff", "#c9b0ff", "#ffc6e6", "#d6e8ff"], 30, 0.9, 0.3, 13), cx, cy)
    bx, by = to(0, -78)
    a.ribbon(bez((bx, by), (bx - 60, by + 60), (bx - 140, by + 120), (bx - 185, by + 230), 40), 36, "#f7c8e6", "#e2a0cc")
    a.ribbon(bez((bx, by), (bx + 40, by + 70), (bx + 80, by + 150), (bx + 46, by + 280), 40), 36, "#f7c8e6", "#e2a0cc")
    a.bow(bx, by, 64, "#f7c3e3", "#d98fbe", math.atan2(to(1, 0)[1] - cy, to(1, 0)[0] - cx), "#c9e8ff")
    for (sx, sy, ln, charm) in ((bx + 95, by - 10, 170, "star"), (bx + 60, by + 20, 110, "star2"), (bx - 30, by + 40, 90, "heart")):  # chains with charms
        pts = bez((sx, sy), (sx + 6, sy + ln * 0.3), (sx - 6, sy + ln * 0.7), (sx, sy + ln), 12)
        a.chain(pts, "#f2d9a6")
        ex, ey = pts[-1]
        if charm.startswith("star"):
            a.gem(a.star_pts(ex, ey + 14, 17, 7), a.iridescent(["#bfe8ff", "#e8d8ff"], 20, 0.4, 0.2, 17), ex, ey + 14)
        else:
            a.gem(a.heart_pts(ex, ey + 14, 15), "#f9c6e8", ex, ey + 14)
    u = pommel(a, P0, P1, a.iridescent(["#b8c8ff", "#e6c8ff", "#c8f0ff"], 40, 0.3, 0.3, 19), length=95, width=30, collar="#efd8fa")
    for k in range(6):  # pearls round the collar
        ang = k / 6 * 2 * math.pi
        a.pearl(P0[0] + 30 * math.cos(ang) * 0.9, P0[1] + 13 * math.sin(ang), 5)
    for (dx, ln) in ((-30, 70), (34, 95)):
        pts = bez((P0[0] + dx * 0.6, P0[1] + 10), (P0[0] + dx, P0[1] + 30), (P0[0] + dx * 1.2, P0[1] + ln * 0.7), (P0[0] + dx * 1.3, P0[1] + ln), 10)
        a.chain(pts)
        a.gem(a.heart_pts(pts[-1][0], pts[-1][1] + 12, 13), "#f6d0ee", pts[-1][0], pts[-1][1] + 12)
    a.sky_sparkles(40, big=8, region=(150, 180, 700, 560))


DESIGNS = {1: design_01}

if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    ids = [int(x) for x in sys.argv[2:]] or sorted(DESIGNS)
    for i in ids:
        a = Art(W, H, seed=i)
        DESIGNS[i](a)
        a.finish().save(os.path.join(OUT, f"pick_{i:02d}.png"))
        print("ok", i)
