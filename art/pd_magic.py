"""Painted-style parts library for the magical pickaxe set (Claude-authored art for the Claude Design board).
Everything renders at 2x and is downsampled. Coordinates are given at 1x."""
import math, random
import numpy as np
from PIL import Image, ImageDraw
from scipy.ndimage import gaussian_filter, distance_transform_edt

S = 2


def hx(h):
    return np.array([int(h[i:i + 2], 16) for i in (1, 3, 5)], np.float32) / 255


def bez(p0, p1, p2, p3, n=40):
    out = []
    for i in range(n + 1):
        t = i / n
        a, b, c, d = (1 - t) ** 3, 3 * (1 - t) ** 2 * t, 3 * (1 - t) * t * t, t ** 3
        out.append((a * p0[0] + b * p1[0] + c * p2[0] + d * p3[0], a * p0[1] + b * p1[1] + c * p2[1] + d * p3[1]))
    return out


def _bbox(mask, pad, H, W):
    ys, xs = np.nonzero(mask > 0.002)
    if len(xs) == 0:
        return None
    return max(0, ys.min() - pad), min(H, ys.max() + pad + 1), max(0, xs.min() - pad), min(W, xs.max() + pad + 1)


class Art:
    def __init__(self, w, h, seed=0):
        self.w, self.h = w, h
        self.W, self.H = w * S, h * S
        self.C = np.zeros((self.H, self.W, 3), np.float32)
        self.G = np.zeros_like(self.C)  # additive glow
        self.yy, self.xx = np.mgrid[0:self.H, 0:self.W].astype(np.float32)
        self.rnd = random.Random(seed)

    # ---- masks
    def _m(self, fn):
        im = Image.new("L", (self.W, self.H), 0)
        fn(ImageDraw.Draw(im))
        return np.asarray(im).astype(np.float32) / 255

    def poly(self, pts):
        return self._m(lambda d: d.polygon([(x * S, y * S) for x, y in pts], fill=255))

    def ellipse(self, cx, cy, rx, ry, angle=0.0):
        if angle == 0:
            return self._m(lambda d: d.ellipse([(cx - rx) * S, (cy - ry) * S, (cx + rx) * S, (cy + ry) * S], fill=255))
        pts = [(cx + rx * math.cos(t) * math.cos(angle) - ry * math.sin(t) * math.sin(angle), cy + rx * math.cos(t) * math.sin(angle) + ry * math.sin(t) * math.cos(angle))
               for t in np.linspace(0, 2 * math.pi, 64)]
        return self.poly(pts)

    def line(self, pts, width):
        def f(d):
            P = [(x * S, y * S) for x, y in pts]
            d.line(P, fill=255, width=int(width * S), joint="curve")
            for (x, y) in (P[0], P[-1]):
                r = width * S / 2
                d.ellipse([x - r, y - r, x + r, y + r], fill=255)
        return self._m(f)

    # ---- fields
    def iridescent(self, cols, scale=180, angle=0.6, noise=0.35, seed=1):
        cols = [hx(c) if isinstance(c, str) else c for c in cols]
        n = gaussian_filter(np.random.default_rng(seed).random((self.H // 16 + 2, self.W // 16 + 2)).astype(np.float32), 1.5)
        n = np.asarray(Image.fromarray(n, "F").resize((self.W, self.H), Image.BICUBIC))
        t = (self.xx * math.cos(angle) + self.yy * math.sin(angle)) / (scale * S) + n * noise * 4
        t = t % len(cols)
        i0 = np.floor(t).astype(int) % len(cols)
        i1 = (i0 + 1) % len(cols)
        f = (t - np.floor(t))[..., None]
        f = f * f * (3 - 2 * f)
        P = np.stack(cols)
        return P[i0] * (1 - f) + P[i1] * f

    def vgrad(self, top, bot, y0=0, y1=None):
        y1 = y1 or self.h
        t = np.clip((self.yy / S - y0) / (y1 - y0), 0, 1)[..., None]
        return hx(top) * (1 - t) + hx(bot) * t

    # ---- painting
    def paint(self, mask, col, alpha=1.0):
        bb = _bbox(mask, 1, self.H, self.W)
        if bb is None:
            return
        y0, y1, x0, x1 = bb
        m = (mask[y0:y1, x0:x1] * alpha)[..., None]
        if isinstance(col, np.ndarray) and col.ndim == 3:
            col = col[y0:y1, x0:x1]
        else:
            col = hx(col) if isinstance(col, str) else np.array(col, np.float32)
        self.C[y0:y1, x0:x1] = self.C[y0:y1, x0:x1] * (1 - m) + col * m

    def bevel(self, mask, field, radius=10, light=(-0.55, -0.8), spec=0.55, rim="#ffffff", rim_w=1.4, dark=0.62):
        """Glossy rounded fill: darker toward the lower-right rim, bright specular on the upper-left slope, thin light rim."""
        bb = _bbox(mask, 4, self.H, self.W)
        if bb is None:
            return
        y0, y1, x0, x1 = bb
        full_mask = mask
        mask = mask[y0:y1, x0:x1]
        if isinstance(field, np.ndarray) and field.ndim == 3:
            field = field[y0:y1, x0:x1]
        else:
            field = np.broadcast_to(hx(field) if isinstance(field, str) else np.asarray(field, np.float32), mask.shape + (3,))
        inside = mask > 0.5
        dist = distance_transform_edt(inside)
        hgt = np.clip(dist / (radius * S), 0, 1)
        hgt = 1 - (1 - hgt) ** 2
        gy, gx = np.gradient(gaussian_filter(hgt, 1.2))
        mag = np.sqrt(gx * gx + gy * gy) + 1e-6
        facing = -(gx * light[0] + gy * light[1]) / mag * np.clip(mag * radius * S * 1.2, 0, 1)
        shade = dark + (1 - dark) * hgt
        col = field * shade[..., None]
        col = col + np.clip(facing, 0, 1)[..., None] ** 2.5 * spec
        col = col - np.clip(-facing, 0, 1)[..., None] * 0.12
        if rim:
            edge = inside & (dist < rim_w * S)
            col[edge] = col[edge] * 0.4 + hx(rim) * 0.6
        m = mask[..., None]
        self.C[y0:y1, x0:x1] = self.C[y0:y1, x0:x1] * (1 - m) + np.clip(col, 0, 1.4) * m

    def glow(self, mask, col, r=12, k=0.6):
        c = hx(col) if isinstance(col, str) else np.asarray(col, np.float32)
        if c.ndim == 3:
            c = c.reshape(-1, 3).mean(0)
        bb = _bbox(mask, int(r * S * 3), self.H, self.W)
        if bb is None:
            return
        y0, y1, x0, x1 = bb
        self.G[y0:y1, x0:x1] += gaussian_filter(mask[y0:y1, x0:x1], r * S)[..., None] * c * k

    def glitter(self, mask, n=400, cols=("#ffffff",), k=1.0):
        ys, xs = np.nonzero(mask > 0.5)
        if len(xs) == 0:
            return
        for _ in range(n):
            i = self.rnd.randrange(len(xs))
            x, y = xs[i], ys[i]
            c = hx(self.rnd.choice(cols))
            r = self.rnd.choice((1, 1, 2))
            self.C[max(0, y - r):y + r, max(0, x - r):x + r] = self.C[max(0, y - r):y + r, max(0, x - r):x + r] * 0.3 + c * 0.9 * k
            self.G[max(0, y - 3 * r):y + 3 * r, max(0, x - 3 * r):x + 3 * r] += c * 0.08 * k

    def sparkle(self, x, y, size, col="#ffffff", k=1.0, thin=0.13):
        pts_v = [(x, y - size), (x + size * thin, y), (x, y + size), (x - size * thin, y)]
        pts_h = [(x - size, y), (x, y - size * thin), (x + size, y), (x, y + size * thin)]
        m = np.maximum(self.poly(pts_v), self.poly(pts_h))
        self.paint(m, col, min(1, k))
        self.glow(m, col, max(2, size * 0.25), 0.9 * k)
        self.glow(self.ellipse(x, y, size * 0.18, size * 0.18), col, size * 0.5, 0.6 * k)

    def sky_sparkles(self, n, cols=("#ffffff", "#fff3d6", "#d6f6ff"), big=10, region=None):
        x0, y0, x1, y1 = region or (0, 0, self.w, self.h)
        for i in range(n):
            x, y = self.rnd.uniform(x0, x1), self.rnd.uniform(y0, y1)
            if i < big:
                self.sparkle(x, y, self.rnd.uniform(10, 26), self.rnd.choice(cols), 0.9)
            else:
                r = self.rnd.choice((0.8, 1, 1.4, 2))
                m = self.ellipse(x, y, r, r)
                self.paint(m, self.rnd.choice(cols), 0.9)
                self.glow(m, self.rnd.choice(cols), 3, 0.5)

    def clouds(self, n, col="#ffffff", alpha=0.5, region=None):
        x0, y0, x1, y1 = region or (0, 0, self.w, self.h)
        m = np.zeros((self.H, self.W), np.float32)
        for _ in range(n):
            cx, cy = self.rnd.uniform(x0, x1), self.rnd.uniform(y0, y1)
            for k in range(6):
                m = np.maximum(m, self.ellipse(cx + self.rnd.uniform(-60, 60), cy + self.rnd.uniform(-14, 14), self.rnd.uniform(30, 70), self.rnd.uniform(18, 34)))
        self.paint(gaussian_filter(m, 10 * S), col, alpha)

    # ---- shaped parts
    def heart_pts(self, cx, cy, size, angle=0.0):
        pts = []
        for t in np.linspace(0, 2 * math.pi, 80):
            x = 16 * math.sin(t) ** 3
            y = -(13 * math.cos(t) - 5 * math.cos(2 * t) - 2 * math.cos(3 * t) - math.cos(4 * t))
            x, y = x * size / 17, y * size / 17
            pts.append((cx + x * math.cos(angle) - y * math.sin(angle), cy + x * math.sin(angle) + y * math.cos(angle)))
        return pts

    def star_pts(self, cx, cy, r, ri, n=5, angle=-math.pi / 2):
        pts = []
        for i in range(n * 2):
            rr = r if i % 2 == 0 else ri
            a = angle + i * math.pi / n
            pts.append((cx + rr * math.cos(a), cy + rr * math.sin(a)))
        return pts

    def gem(self, pts, base, cx, cy, rim="#fff3fb", glow_k=0.3):
        """Faceted gem: bevel plus facet lines from the centre and a hot highlight."""
        m = self.poly(pts)
        self.bevel(m, base, radius=8, spec=0.9, rim=rim, rim_w=2.0, dark=0.55)
        im = Image.new("L", (self.W, self.H), 0)
        d = ImageDraw.Draw(im)
        for (x, y) in pts[::max(1, len(pts) // 8)]:
            d.line([(cx * S, cy * S), (x * S, y * S)], fill=90, width=S)
        fl = np.asarray(im).astype(np.float32) / 255 * m
        self.paint(fl, "#ffffff", 0.5)
        self.paint(self.ellipse(cx - (cx - min(p[0] for p in pts)) * 0.35, cy - (cy - min(p[1] for p in pts)) * 0.4, 5, 3, -0.6), "#ffffff", 0.85)
        self.glow(m, base if isinstance(base, str) else "#ffffff", 14, glow_k)

    def pearl(self, x, y, r, tint="#fff4fb"):
        m = self.ellipse(x, y, r, r)
        self.bevel(m, self.iridescent(["#fff4fb", "#f6e6ff", "#e6f6ff", "#fff0e6"], 30, 0.5, 0.2, 7), radius=r * 0.9, spec=0.8, rim=None, dark=0.7)

    def chain(self, pts, col="#f2d9a6", link=4.0):
        total = 0
        for (a, b) in zip(pts, pts[1:]):
            L = math.hypot(b[0] - a[0], b[1] - a[1])
            steps = max(1, int(L / link))
            for i in range(steps):
                t = i / steps
                x, y = a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t
                m = self.ellipse(x, y, 1.6, 1.6)
                self.paint(m, col if (total + i) % 2 else "#fffaf0")
            total += steps

    def ribbon(self, pts, width, col_a, col_b, shine="#ffffff"):
        """A flowing ribbon: width breathes, colour flips between faces where it twists."""
        for i in range(len(pts) - 1):
            (x0, y0), (x1, y1) = pts[i], pts[i + 1]
            t = i / (len(pts) - 1)
            w = width * (0.35 + 0.65 * abs(math.sin(t * math.pi * 2.2 + 0.4))) * (1 - 0.5 * t)
            nx, ny = -(y1 - y0), (x1 - x0)
            L = math.hypot(nx, ny) + 1e-6
            nx, ny = nx / L * w / 2, ny / L * w / 2
            q = [(x0 + nx, y0 + ny), (x1 + nx, y1 + ny), (x1 - nx, y1 - ny), (x0 - nx, y0 - ny)]
            face = col_a if math.sin(t * math.pi * 2.2 + 0.4) > 0 else col_b
            self.paint(self.poly(q), face, 0.92)
        self.paint(self.line(pts, 1.2), shine, 0.35)

    def bow(self, cx, cy, size, col, col_dark, angle=0.0, gem_col="#bfe8ff"):
        for sgn in (-1, 1):
            lp = self.ellipse(cx + sgn * size * 0.62 * math.cos(angle), cy + sgn * size * 0.62 * math.sin(angle) - size * 0.08, size * 0.62, size * 0.38, angle + sgn * 0.35)
            self.bevel(lp, col, radius=size * 0.25, spec=0.5, rim="#fff6fb", dark=0.7)
            inner = self.ellipse(cx + sgn * size * 0.66 * math.cos(angle), cy + sgn * size * 0.66 * math.sin(angle) - size * 0.06, size * 0.28, size * 0.14, angle + sgn * 0.35)
            self.paint(inner, col_dark, 0.55)
        k = self.ellipse(cx, cy, size * 0.2, size * 0.2)
        self.bevel(k, col, radius=size * 0.12, spec=0.6, dark=0.7)
        self.gem([(cx + size * 0.12 * math.cos(a), cy + size * 0.12 * math.sin(a)) for a in np.linspace(0, 2 * math.pi, 24)], gem_col, cx, cy)

    def flower(self, cx, cy, r, col, center="#fff1b8", petals=5, angle=0.0, alpha=1.0):
        for k in range(petals):
            a_ = angle + k * 2 * math.pi / petals
            pm = self.ellipse(cx + r * 0.55 * math.cos(a_), cy + r * 0.55 * math.sin(a_), r * 0.55, r * 0.36, a_)
            if alpha >= 1:
                self.bevel(pm, col, radius=r * 0.3, spec=0.45, rim="#ffffff", dark=0.75)
            else:
                self.paint(pm, col, alpha)
        self.paint(self.ellipse(cx, cy, r * 0.22, r * 0.22), center, alpha)

    def handle(self, p0, p1, width, field, wrap=None, wrap_n=10):
        m = self.line([p0, p1], width)
        self.bevel(m, field, radius=width * 0.5, spec=0.55, rim="#fff8ff", dark=0.6)
        if wrap:
            dx, dy = p1[0] - p0[0], p1[1] - p0[1]
            L = math.hypot(dx, dy)
            ux, uy = dx / L, dy / L
            vx, vy = -uy, ux
            for i in range(wrap_n):
                t0 = i / wrap_n
                a = (p0[0] + dx * t0, p0[1] + dy * t0)
                band = [(a[0] + vx * width * 0.55, a[1] + vy * width * 0.55), (a[0] + vx * width * 0.55 + ux * 7, a[1] + vy * width * 0.55 + uy * 7),
                        (a[0] - vx * width * 0.55 + ux * (L / wrap_n * 0.7) + ux * 7, a[1] - vy * width * 0.55 + uy * (L / wrap_n * 0.7) + uy * 7),
                        (a[0] - vx * width * 0.55 + ux * (L / wrap_n * 0.7), a[1] - vy * width * 0.55 + uy * (L / wrap_n * 0.7))]
                bm = self.poly(band) * m
                self.paint(bm, wrap, 0.75)
        return m

    def frame(self, P0, P1):
        dx, dy = P1[0] - P0[0], P1[1] - P0[1]
        L = math.hypot(dx, dy)
        u = (dx / L, dy / L)  # along the handle toward the head
        v = (u[1], -u[0])  # across the head (to the right of the handle direction)

        def to(a, b):
            return (P1[0] + v[0] * a + u[0] * b, P1[1] + v[1] * a + u[1] * b)
        return to

    def pick_arm(self, to, side, length, thick, droop, curl=0.25, tip_w=0.0, root=0.0):
        """One pick arm: a thick root that tapers to a point that curves down toward the handle side."""
        r0 = side * root
        up = [(r0, thick * 0.55), (r0 + side * length * 0.45, thick * 0.75), (r0 + side * length * 0.85, thick * 0.2 - droop * 0.4), (r0 + side * length, -droop)]
        lo = [(r0 + side * length, -droop + tip_w), (r0 + side * length * 0.7, -thick * 0.25 - droop * curl), (r0 + side * length * 0.3, -thick * 0.45), (r0, -thick * 0.5)]
        pts = [to(a, b) for a, b in bez(*up, n=30)] + [to(a, b) for a, b in bez(*lo, n=30)]
        return pts

    def finish(self, glow_scale=1.0):
        out = self.C + self.G * glow_scale
        out = out / (1 + np.maximum(out - 0.85, 0) * 0.9)  # soft shoulder only above 0.85
        out = np.clip(out, 0, 1)
        im = Image.fromarray((out * 255).astype(np.uint8), "RGB")
        return im.resize((self.w, self.h), Image.LANCZOS)
