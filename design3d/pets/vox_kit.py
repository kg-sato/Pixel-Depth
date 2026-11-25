"""Hi-detail voxel creature kit (the owner, 2026-11-24: keep the voxel "Pixel" style of pets.py / pets5.py, but at the detail
level of their Lure a Pet video: finer cells, bigger pets, more bones and accessories; magical fantasy designs; no plate ridges,
panel seams or lego studs). Shapes are written in studs (Blender axes: x right, y forward, z up) and rasterised into one cubic
grid of cell size s; every cell belongs to one Part (a bone) and one colour key. Export goes through plate_kit.export: plain
cubes (hidden faces culled per part), vertex-colour bake (colour, its Top shade on upward faces, occlusion, key light), objects
split under the MeshPart limit, rig data for Shared.PetRig.
    import vox_kit as X; v = X.Vox(name, palette, s=0.1); v.ell(...); ...; c = v.build(); plate_kit.export(c, out_dir)"""
import math, random
from mathutils import Vector, Matrix, Euler
import plate_kit as K

V = K.V


def _rot(rot):
    if rot is None: return None
    return rot if isinstance(rot, Matrix) else Euler(rot).to_matrix()


class Vox:
    def __init__(self, name, pal, s=0.1):
        self.name, self.pal, self.s = name, pal, s
        self.cells = {}  # (i, j, k) -> (part, colour)
        self.muscles = {}  # part -> [(centre, radii, inverse rotation, rotation)] for the anatomy shading
        self.c = K.Creature(name, pal)

    # ---- rig pass-through
    def joint(self, part, pivot, parent=None, group=None): self.c.joint(part, pivot, parent, group)
    def anchor(self, key, part, p): self.c.anchors[key] = (part, V(p))
    def axis(self, part, a): self.c.axes[part] = a

    # ---- rasterising
    def fill(self, part, colour, lo, hi, inside, over=True):
        s = self.s
        i0 = [math.floor(lo[k] / s) - 1 for k in range(3)]; i1 = [math.ceil(hi[k] / s) + 1 for k in range(3)]
        cells = self.cells
        for i in range(i0[0], i1[0] + 1):
            x = (i + 0.5) * s
            for j in range(i0[1], i1[1] + 1):
                y = (j + 0.5) * s
                for k in range(i0[2], i1[2] + 1):
                    z = (k + 0.5) * s
                    if inside(x, y, z) and (over or (i, j, k) not in cells):
                        cells[(i, j, k)] = (part, colour)

    def ell(self, part, colour, c, r, rot=None, cut=None, over=True):
        """an ellipsoid; cut(x, y, z) -> bool keeps only part of it"""
        c, r = V(c), V(r); R = _rot(rot); Ri = R.inverted() if R is not None else None
        m = max(r)
        def inside(x, y, z):
            d = V(x, y, z) - c
            if Ri is not None: d = Ri @ d
            return (d.x / r.x) ** 2 + (d.y / r.y) ** 2 + (d.z / r.z) ** 2 <= 1 and (cut is None or cut(x, y, z))
        self.fill(part, colour, c - V(m, m, m), c + V(m, m, m), inside, over)

    def cap(self, part, colour, a, b, r0, r1, over=True, cut=None):
        """a tapered capsule from a (radius r0) to b (radius r1): limbs, necks, horns, tusks, claws (r1 small)"""
        a, b = V(a), V(b); ab = b - a; L2 = max(ab.length_squared, 1e-9); m = max(r0, r1)
        def inside(x, y, z):
            p = V(x, y, z)
            t = max(0.0, min(1.0, (p - a).dot(ab) / L2))
            return (p - (a + ab * t)).length <= r0 + (r1 - r0) * t and (cut is None or cut(x, y, z))
        lo = V(min(a.x, b.x) - m, min(a.y, b.y) - m, min(a.z, b.z) - m); hi = V(max(a.x, b.x) + m, max(a.y, b.y) + m, max(a.z, b.z) + m)
        self.fill(part, colour, lo, hi, inside, over)

    def tube(self, part, colour, pts, radii, over=True):
        """a swept tube through points (vines, roots, ribbons, tails); radii per point"""
        pts = [V(q) for q in pts]
        for i in range(len(pts) - 1):
            self.cap(part, colour, pts[i], pts[i + 1], radii[i], radii[i + 1], over)

    def curve(self, part, colour, pts, radii, n=24, over=True):
        """a smooth Catmull-Rom tube through the points (tusks, horns, whiskers, tails that curl)"""
        P = [V(q) for q in pts]; P = [P[0]] + P + [P[-1]]
        out, rad = [], []
        segs = len(P) - 3
        for i in range(n + 1):
            u = i / n * segs; k = min(int(u), segs - 1); t = u - k
            p0, p1, p2, p3 = P[k], P[k + 1], P[k + 2], P[k + 3]
            out.append(0.5 * ((2 * p1) + (-p0 + p2) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t * t + (-p0 + 3 * p1 - 3 * p2 + p3) * t ** 3))
            rr = radii[min(k, len(radii) - 1)] + (radii[min(k + 1, len(radii) - 1)] - radii[min(k, len(radii) - 1)]) * t
            rad.append(rr)
        self.tube(part, colour, out, rad, over)

    def box(self, part, colour, c, size, rot=None, over=True):
        c, h = V(c), V(size) / 2; R = _rot(rot); Ri = R.inverted() if R is not None else None
        m = h.length
        def inside(x, y, z):
            d = V(x, y, z) - c
            if Ri is not None: d = Ri @ d
            return abs(d.x) <= h.x and abs(d.y) <= h.y and abs(d.z) <= h.z
        self.fill(part, colour, c - V(m, m, m), c + V(m, m, m), inside, over)

    def crystal(self, part, colour, base, direction, L, w, sides=6, over=True):
        """a faceted crystal: a prism of radius w that sharpens to a point over its last 30 percent"""
        b, d = V(base), V(direction).normalized()
        def inside(x, y, z):
            q = V(x, y, z) - b; t = q.dot(d)
            if t < 0 or t > L: return False
            rr = w if t < L * 0.7 else w * (L - t) / (L * 0.3)
            return (q - d * t).length <= rr
        e = V(w, w, w)
        lo = V(min(b.x, (b + d * L).x), min(b.y, (b + d * L).y), min(b.z, (b + d * L).z)) - e
        hi = V(max(b.x, (b + d * L).x), max(b.y, (b + d * L).y), max(b.z, (b + d * L).z)) + e
        self.fill(part, colour, lo, hi, inside, over)

    def cluster(self, part, colour, base, direction, size, n=5, spread=0.55, seed=1):
        rnd = random.Random(seed)
        d = V(direction).normalized(); side = d.orthogonal().normalized(); other = d.cross(side).normalized()
        self.crystal(part, colour, base, d, size, size * 0.2)
        for i in range(n - 1):
            a = i / (n - 1) * math.tau + rnd.random() * 0.6
            o = side * math.cos(a) + other * math.sin(a)
            self.crystal(part, colour, V(base) + o * size * 0.16, (d + o * spread).normalized(), size * (0.45 + 0.35 * rnd.random()), size * 0.14)

    def blade(self, part, colour, base, tip, width, thick=None, normal=(0, 0, 1), bend=0.0, over=True):
        """a flat leaf / feather / fin / ear: an almond outline from base to tip, 'thick' deep along normal, curving by bend"""
        b, t = V(base), V(tip); ax = t - b; L = ax.length; ax = ax.normalized()
        n = V(normal); n = (n - ax * n.dot(ax)).normalized(); side = ax.cross(n).normalized()
        th = thick or self.s * 1.1
        def inside(x, y, z):
            q = V(x, y, z) - b; u = q.dot(ax) / L
            if u < 0 or u > 1: return False
            off = bend * 4 * u * (1 - u)
            wv = width * math.sin(math.pi * min(1.0, u * 0.85 + 0.08)) * (1 - 0.35 * u)
            return abs(q.dot(side)) <= wv / 2 and abs(q.dot(n) - off) <= th / 2
        m = max(width, th, abs(bend)) + self.s
        lo = V(min(b.x, t.x) - m, min(b.y, t.y) - m, min(b.z, t.z) - m); hi = V(max(b.x, t.x) + m, max(b.y, t.y) + m, max(b.z, t.z) + m)
        self.fill(part, colour, lo, hi, inside, over)

    def torus(self, part, colour, c, normal, R, r, over=True, arc=None):
        """a ring (halo, collar, basket band, astrolabe); arc = (a0, a1) radians keeps only part of it"""
        c = V(c); n = V(normal).normalized(); u = n.orthogonal().normalized(); w = n.cross(u)
        def inside(x, y, z):
            q = V(x, y, z) - c; h = q.dot(n); p = q - n * h
            if p.length < 1e-6: return False
            if arc is not None:
                a = math.atan2(p.dot(w), p.dot(u)) % math.tau
                if not (arc[0] <= a <= arc[1]): return False
            return (p.length - R) ** 2 + h * h <= r * r
        m = R + r
        self.fill(part, colour, c - V(m, m, m), c + V(m, m, m), inside, over)

    def muscle(self, part, colour, c, r, rot=None, over=True, cut=None):
        """an anatomical mass (chest, shoulder blade, triceps, forearm, thigh, hamstring, gaskin, jaw): an ellipsoid that the
        anatomy() pass shades like pixel art (a lit top, a shadow side, a dark crease where two masses meet)"""
        self.ell(part, colour, c, r, rot, cut, over)
        R = _rot(rot)
        self.muscles.setdefault(part, []).append((V(c), V(r), R.inverted() if R is not None else None, R))

    def anatomy(self, base, hi, lo, crease, light=(-0.35, 0.45, 0.82), parts=None, gap=0.2):
        """pixel-art form shading over the muscle masses (the owner, 2026-11-24: "muscles, structure"): on surface cells of
        colour base, a crease tone where two masses meet, a hue-shifted highlight where the mass faces the light, a cool shadow
        tone where it faces away; cells away from any mass stay base"""
        L = V(light).normalized(); s = self.s
        for k, (p, col) in list(self.cells.items()):
            if col != base or (parts is not None and p not in parts): continue
            ms = self.muscles.get(p)
            if not ms or not self.surface(k): continue
            x = V((k[0] + 0.5) * s, (k[1] + 0.5) * s, (k[2] + 0.5) * s)
            fs = []
            for c, r, Ri, R in ms:
                d = x - c; dl = Ri @ d if Ri is not None else d
                f = 1 - ((dl.x / r.x) ** 2 + (dl.y / r.y) ** 2 + (dl.z / r.z) ** 2)
                g = V(dl.x / r.x ** 2, dl.y / r.y ** 2, dl.z / r.z ** 2)
                if R is not None: g = R @ g
                fs.append((f, g))
            fs.sort(key=lambda a: -a[0])
            f1, g1 = fs[0]
            if f1 < -0.35: continue
            if len(fs) > 1 and fs[1][0] > -0.1 and f1 - fs[1][0] < gap:
                self.cells[k] = (p, crease)
                continue
            nd = g1.normalized().dot(L) if g1.length > 1e-9 else 0
            if nd > 0.5: self.cells[k] = (p, hi)
            elif nd < -0.3: self.cells[k] = (p, lo)

    # ---- painting
    def paint(self, colour, test, part=None, only=None):
        """recolour placed cells where test(x, y, z) holds (only: a set of colours that may be repainted)"""
        s = self.s
        for k, (p, col) in list(self.cells.items()):
            if part is not None and p != part: continue
            if only is not None and col not in only: continue
            if test((k[0] + 0.5) * s, (k[1] + 0.5) * s, (k[2] + 0.5) * s):
                self.cells[k] = (p, colour)

    def surface(self, k):
        i, j, kk = k
        return any((i + a, j + b, kk + c2) not in self.cells for a, b, c2 in ((1, 0, 0), (-1, 0, 0), (0, 1, 0), (0, -1, 0), (0, 0, 1), (0, 0, -1)))

    def speckle(self, colour, base, frac, seed=1, part=None):
        """dither: repaint a fraction of the surface cells of colour 'base' (voxel-art texture, no noise everywhere)"""
        rnd = random.Random(seed)
        for k, (p, col) in list(self.cells.items()):
            if col == base and (part is None or p == part) and self.surface(k) and rnd.random() < frac:
                self.cells[k] = (p, colour)

    def carve(self, test, part=None):
        s = self.s
        for k, (p, col) in list(self.cells.items()):
            if (part is None or p == part) and test((k[0] + 0.5) * s, (k[1] + 0.5) * s, (k[2] + 0.5) * s):
                del self.cells[k]

    def line(self, part, colour, pts, r=None):
        """a glowing rune stroke / seam laid on a surface: a thin tube of one cell"""
        self.tube(part, colour, pts, [r or self.s * 0.75] * len(pts))

    def eye(self, part, c, normal, w=0.34, h=0.42, iris="Glow", ring="Eye", shine="Shine"):
        """a big readable voxel eye sunk into the face: a dark ring, a glowing iris, a 1-cell catchlight up and toward the middle"""
        c, n = V(c), V(normal).normalized(); up = V(0, 0, 1); side = n.cross(up).normalized()
        self.carve(lambda x, y, z: abs((V(x, y, z) - c).dot(side)) <= w / 2 and abs((V(x, y, z) - c).dot(up)) <= h / 2 and 0 <= (V(x, y, z) - c).dot(n) <= self.s * 2.5, part)
        def inside_ring(x, y, z):
            q = V(x, y, z) - c
            return abs(q.dot(side)) <= w / 2 and abs(q.dot(up)) <= h / 2 and -self.s * 1.5 <= q.dot(n) <= self.s * 0.5
        self.fill(part, ring, c - V(1, 1, 1), c + V(1, 1, 1), inside_ring)
        def inside_iris(x, y, z):
            q = V(x, y, z) - c
            return abs(q.dot(side)) <= w / 2 - self.s and abs(q.dot(up)) <= h / 2 - self.s and -self.s * 0.5 <= q.dot(n) <= self.s * 0.6
        self.fill(part, iris, c - V(1, 1, 1), c + V(1, 1, 1), inside_iris)
        self.box(part, shine, c + up * (h / 2 - self.s * 1.5) - side * (w / 2 - self.s * 1.5) * (1 if n.x >= 0 else -1) + n * self.s * 0.3, (self.s * 0.9, self.s * 0.9, self.s * 0.9))

    # ---- export
    def build(self):
        groups = {}
        for ijk, (part, col) in self.cells.items():
            groups.setdefault(part, {}).setdefault(col, set()).add(ijk)
        for part, cols in groups.items():
            occ = set().union(*cols.values())
            for col, cells in cols.items():
                role = "Glow" if col.startswith("Glow") else ("Crystal" if col.startswith("Crystal") else "Tex")
                self.c.voxels(part, cells, self.s, (0, 0, 0), colour=col, role=role, occ=occ)
        return self.c
