"""The v16 pets as hi-detail voxel creatures (the owner, 2026-11-24): the Pixel Depth voxel style at the Lure a Pet detail level,
magical fantasy designs (Overnight/refs/pets_v16/magic: concepts.json, sheet_1/2.jpg). Cell 0.1 studs (the v5 pets used 0.16 on
a pet a third the size): about 55 cells tall, many bones, accessories, glowing runes and crystals; no plate ridges or studs.
    blender -b -P design3d/pets/pet_vox.py -- <out_dir> [Name ...]
Writes <Name>.glb and merges the rig data into design3d/pets/rigs.json (same contract as pet_plate.py)."""
import json, math, os, random, sys
here = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, here)
import plate_kit as K
import vox_kit as X
from plate_kit import V
from mathutils import Euler

args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
OUT = os.path.abspath(args[0] if args else os.path.join(here, "out_vox"))
ONLY = set(a for a in args[1:] if not a.startswith("-"))
os.makedirs(OUT, exist_ok=True)
D = {}
S = 0.1


def pet(name, pal):
    def deco(fn): D[name] = (pal, fn); return fn
    return deco


def E(rx=0, ry=0, rz=0):
    return Euler((math.radians(rx), math.radians(ry), math.radians(rz))).to_matrix()


def noise(seed):
    """a cheap smooth-ish 3D value noise for irregular edges (moss line, bark grain)"""
    rnd = random.Random(seed); g = {}
    def val(i, j, k):
        key = (i, j, k)
        if key not in g: g[key] = rnd.random()
        return g[key]
    def f(x, y, z, sc=0.6):
        x, y, z = x / sc, y / sc, z / sc
        i, j, k = math.floor(x), math.floor(y), math.floor(z); u, v, w = x - i, y - j, z - k
        acc = 0.0
        for a in (0, 1):
            for b in (0, 1):
                for c in (0, 1):
                    acc += val(i + a, j + b, k + c) * (u if a else 1 - u) * (v if b else 1 - v) * (w if c else 1 - w)
        return acc
    return f


def leg(v, limb, hip, knee, ank, foot, r, colour, kind="hoof", parent="Body", hoof="Bone", claw="Bone", band=None, muscle=None):
    """an adult three-bone leg (the owner, 2026-11-24: the pets looked juvenile; long legs, slim joints): limb1 thigh (hip ->
    knee, a muscle mass at the top), limb2 shin (knee -> ankle/hock), limb3 the cannon and a small hoof or a clawed paw (ankle ->
    foot on the ground). r = (thigh top, knee, ankle, foot) radii"""
    hip, knee, ank, foot = V(hip), V(knee), V(ank), V(foot)
    v.joint(limb + "1", tuple(hip), parent, "leg")
    v.cap(limb + "1", colour, hip, knee, r[0], r[1], over=False)
    v.muscle(limb + "1", muscle or colour, hip.lerp(knee, 0.3), (r[0] * 1.15, r[0] * 1.25, (hip - knee).length * 0.42), over=False)
    v.joint(limb + "2", tuple(knee), limb + "1", "leg")
    v.cap(limb + "2", colour, knee, ank, r[1], r[2])
    v.joint(limb + "3", tuple(ank), limb + "2", "leg")
    v.cap(limb + "3", colour, ank, foot + V(0, 0, 0.12), r[2], r[3])
    if band: v.cap(limb + "3", band, ank.lerp(foot, 0.55), ank.lerp(foot, 0.7), r[3] * 1.3, r[3] * 1.3)
    if kind == "hoof":
        # a flat-soled cloven hoof (the owner: "the feet should be flat, not balls"): a frustum standing on the ground, wider at
        # the sole and longer toward the front, split down the front into two toes, two dewclaws behind
        H, rx, ry, c0 = 0.36, r[3] * 1.5, r[3] * 1.7, foot + V(0, 0.08, 0)
        def inside(x, y, z, c0=c0, H=H, rx=rx, ry=ry):
            tt = (z - c0.z) / H
            if tt < 0 or tt > 1: return False
            k = 1 - 0.28 * tt
            return ((x - c0.x) / (rx * k)) ** 2 + ((y - c0.y - 0.05 * (1 - tt)) / (ry * k)) ** 2 <= 1
        v.fill(limb + "3", hoof, c0 - V(rx, ry, 0), c0 + V(rx, ry + 0.1, H), inside)
        v.carve(lambda x, y, z, c0=c0: abs(x - c0.x) < 0.06 and y > c0.y - 0.02 and z < c0.z + H * 0.75, part=limb + "3")
        for sx in (-1, 1):
            v.cap(limb + "3", hoof, foot + V(sx * r[3] * 0.55, -r[3] * 1.1, 0.42), foot + V(sx * r[3] * 0.6, -r[3] * 1.5, 0.22), 0.08, 0.05)
    else:
        v.ell(limb + "3", colour, foot + V(0, 0.12, 0.1), (r[3] * 1.3, r[3] * 1.7, 0.12))
        for k in (-1, 0, 1):
            v.cap(limb + "3", claw, foot + V(k * r[3] * 0.6, r[3] * 1.3, 0.08), foot + V(k * r[3] * 0.7, r[3] * 2.0, 0.02), 0.06, 0.02)


def vine(v, part, a, b, r, turns=1.5, colour="Leaf", leaf="Leaf", bud="Glow", leaves=4, phase=0.0, w=0.055, seed=1):
    """a vine spiralling round the axis a -> b at radius r(t) (a number or (r0, r1)), with leaves and glowing buds along it"""
    a, b = V(a), V(b); ax = (b - a).normalized(); u = ax.orthogonal().normalized(); wv = ax.cross(u).normalized()
    r0, r1 = (r, r) if isinstance(r, (int, float)) else r
    pts = []
    n = 18
    for i in range(n + 1):
        tt = i / n; ang = phase + tt * turns * math.tau; rr = r0 + (r1 - r0) * tt
        pts.append(a + (b - a) * tt + (u * math.cos(ang) + wv * math.sin(ang)) * rr)
    v.tube(part, colour, pts, [w] * len(pts))
    rnd = random.Random(seed)
    for k in range(leaves):
        i = int((k + 0.5) / leaves * n); q = pts[i]; out = (q - (a + (b - a) * (i / n))).normalized()
        if k % 2 == 0:
            v.blade(part, leaf, q, q + out * 0.32 + ax * 0.12, 0.2, thick=0.1, normal=ax)
        else:
            v.box(part, bud, q + out * 0.08, (0.11, 0.11, 0.11))


def proportions(v):
    """the adult check (the owner, 2026-11-24): leg clearance = ground to the belly over the shoulder height, head share = the
    head's height over the shoulder height, from the cells. Adults: clearance 0.38 to 0.55, head 0.25 to 0.38."""
    s = v.s
    body = [k for k, (p, col) in v.cells.items() if p == "Body"]
    head = [k for k, (p, col) in v.cells.items() if p == "Head"]
    if not body: return {}
    main = max(set(col for k, (p, col) in v.cells.items() if p == "Body"), key=lambda c: sum(1 for k2, (p2, c2) in v.cells.items() if p2 == "Body" and c2 == c))
    torso = [k for k, (p, col) in v.cells.items() if p == "Body" and col == main]
    shoulder = (max(k[2] for k in torso) + 1) * s
    clear = min(k[2] for k in torso) * s
    hh = ((max(k[2] for k in head) - min(k[2] for k in head) + 1) * s) if head else 0
    return {"clearance": round(clear / shoulder, 2), "head": round(hh / shoulder, 2), "shoulder": round(shoulder, 2)}


# ---------------------------------------------------------------- TOSK: Mossbark Boar-Cart (Common hauler; concept B)
@pet("Tosk", {"Bark": "#5a3826", "BarkTop": "#7e5236", "BarkHi": "#86562e", "BarkHiTop": "#a87038", "BarkLo": "#3e2632", "BarkLoTop": "#54323a", "Crease": "#22141a", "CreaseTop": "#2e1c22", "Grain": "#3e2418", "GrainTop": "#553222", "Dark": "#2e1a12", "DarkTop": "#42281a",
              "Moss": "#55a832", "MossTop": "#8fdc4e", "Moss2": "#3f8a2a", "Moss2Top": "#68b83e", "Leaf": "#6cc63a", "LeafTop": "#b4f06a",
              "Tusk": "#f2e2c0", "TuskTop": "#fffbef", "Bone": "#4a4552", "BoneTop": "#77717f", "Root": "#8a5e36", "RootTop": "#b07c48",
              "Snout": "#c47a66", "SnoutTop": "#e0967e", "Shroom": "#22c4c8", "ShroomTop": "#7af6ee", "Stem": "#efe4cc", "StemTop": "#fffaf0",
              "Petal": "#ff7ab8", "PetalTop": "#ffb8dc", "Eye": "#24120a", "EyeTop": "#24120a", "Shine": "#ffffff", "ShineTop": "#ffffff",
              "Crystal": "#ffae2a", "Glow": "#ffc23a", "GlowSap": "#ff9a1e", "Edge": "#c8b088", "_noseams": True})
def tosk(v):
    nz = noise(3)
    rnd = random.Random(11)
    v.joint("Body", (0, 0, 3.4))
    # an ADULT forest-spirit boar (real ratios: legs ~43% of the shoulder height, head ~1/3 of the body length) made magical
    # (magic/concepts/Tosk_s22; the owner 2026-11-24: "more fantasy like"): a hide of living bark split by glowing amber sap,
    # a meadow of moss over the back with teal glow-caps, pink flowers and a sapling, a leaf mane, twig antlers, Ogham runes,
    # huge ivory tusks tipped with amber, the root basket of amber crystals, and pollen motes drifting round it
    v.muscle("Body", "Bark", (0, 1.0, 3.5), (1.5, 1.6, 1.38))       # chest and shoulders, the biggest mass
    v.muscle("Body", "Bark", (0, -0.5, 3.4), (1.38, 1.85, 1.12))     # barrel
    v.muscle("Body", "Bark", (0, -2.0, 3.45), (1.22, 0.98, 1.0))     # rump, lower than the hump
    v.muscle("Body", "Bark", (0, 0.9, 4.35), (0.95, 1.25, 0.58))     # the shoulder hump
    for s in (-1, 1):
        v.muscle("Body", "Bark", (s * 1.28, 1.05, 3.85), (0.32, 0.62, 0.78), rot=E(-18, s * -14, 0))  # the shoulder blade
        v.muscle("Body", "Bark", (s * 1.3, 1.55, 3.0), (0.4, 0.45, 0.55))                              # the point of the shoulder
        for k, y in enumerate((0.25, -0.2, -0.65, -1.1)):
            v.muscle("Body", "Bark", (s * 1.22, y, 3.2 - 0.05 * k), (0.22, 0.17, 0.7 - 0.06 * k))       # ribs under the hide
        v.muscle("Body", "Bark", (s * 0.6, -2.1, 3.95), (0.62, 0.78, 0.55))                            # the gluteal mass
        v.muscle("Body", "Bark", (s * 0.95, -2.35, 3.25), (0.5, 0.55, 0.72))                           # the haunch
    v.ell("Body", "Dark", (0, -0.3, 2.6), (1.05, 1.75, 0.44))        # belly line, tucked up toward the flank
    grain = lambda x, y, z: (math.floor(y / 0.1 + nz(x, y, z, 0.5) * 6) % 5 == 0) and z > 2.7
    # the moss meadow: a ragged blanket, cushions heaped on top, a leaf mane down the spine
    v.ell("Body", "Moss", (0, -0.55, 3.45), (1.5, 2.0, 1.24), cut=lambda x, y, z: z > 3.75 + nz(x, y, z) * 0.45)
    v.ell("Body", "Moss", (0, 1.0, 3.5), (1.58, 1.68, 1.46), cut=lambda x, y, z: z > 4.2 + nz(x, y, z) * 0.35)
    for k in range(26):
        a = rnd.uniform(0, math.tau); d = rnd.uniform(0.15, 1.0)
        x, y = math.cos(a) * d * 1.15, -0.4 + math.sin(a) * d * 2.1
        zt = 3.45 + 1.2 * math.sqrt(max(0.0, 1 - (x / 1.5) ** 2 - ((y + 0.55) / 2.0) ** 2))
        if y > 0.2: zt = max(zt, 4.35 + 0.55 * math.sqrt(max(0.0, 1 - (x / 0.95) ** 2 - ((y - 0.9) / 1.25) ** 2)))
        v.ell("Body", "Moss" if k % 3 else "Moss2", (x, y, zt - 0.08), (rnd.uniform(0.22, 0.42), rnd.uniform(0.22, 0.42), rnd.uniform(0.12, 0.22)))
    v.speckle("Moss2", "Moss", 0.2, seed=6)
    for k in range(12):
        y = 2.0 - k * 0.32
        top = 4.95 - max(0, k - 3) * 0.1
        for s in (-1, 1):
            v.blade("Body", "Leaf" if k % 2 else "Moss2", (s * 0.05, y, top - 0.15), (s * 0.35, y - 0.4, top + 0.5 - abs(k - 3) * 0.03), 0.3, thick=0.11, normal=(1, 0, -s * 0.4), bend=0.06)
    # glow-caps, flowers and a sapling growing out of the moss
    for k, (x, y, sc) in enumerate(((0.75, 0.2, 1.9), (-0.85, -0.3, 1.6), (0.6, -1.75, 1.7), (-0.5, 1.6, 1.4), (1.0, 1.15, 1.5), (-1.0, -1.45, 1.6), (0.2, -0.2, 1.2))):
        zt = 3.45 + 1.2 * math.sqrt(max(0.0, 1 - (x / 1.5) ** 2 - ((y + 0.55) / 2.0) ** 2))
        if y > 0.2: zt = max(zt, 4.2 + 0.7 * math.sqrt(max(0.0, 1 - (x / 1.4) ** 2 - ((y - 0.9) / 1.5) ** 2)))
        v.cap("Body", "Stem", (x, y, zt - 0.1), (x, y, zt + 0.32 * sc), 0.07 * sc, 0.06 * sc)
        v.ell("Body", "Shroom", (x, y, zt + 0.34 * sc), (0.22 * sc, 0.22 * sc, 0.1 * sc), cut=lambda xx, yy, zz, zc=zt + 0.3 * sc: zz >= zc)
        v.box("Body", "Glow", (x + 0.08 * sc, y + 0.05 * sc, zt + 0.43 * sc), (0.1, 0.1, 0.08)); v.box("Body", "Glow", (x - 0.1 * sc, y - 0.06 * sc, zt + 0.41 * sc), (0.1, 0.1, 0.08))
    for k in range(14):
        a = rnd.uniform(0, math.tau); d = rnd.uniform(0.3, 1.0)
        x, y = math.cos(a) * d * 1.2, -0.4 + math.sin(a) * d * 2.0
        zt = 3.45 + 1.22 * math.sqrt(max(0.0, 1 - (x / 1.5) ** 2 - ((y + 0.55) / 2.0) ** 2))
        for dx, dy in ((0.12, 0), (-0.12, 0), (0, 0.12), (0, -0.12)): v.box("Body", "Petal", (x + dx, y + dy, zt + 0.08), (0.13, 0.13, 0.1))
        v.box("Body", "Glow", (x, y, zt + 0.12), (0.11, 0.11, 0.11))
    T = V(0.55, 0.85, 4.75)  # a sapling from the hump
    v.curve("Body", "Root", [T, T + V(0.15, -0.1, 0.5), T + V(0.1, -0.2, 0.95)], [0.09, 0.07, 0.05])
    v.curve("Body", "Root", [T + V(0.13, -0.12, 0.55), T + V(0.45, -0.1, 0.8)], [0.05, 0.03])
    v.ell("Body", "Leaf", T + V(0.1, -0.2, 1.15), (0.38, 0.36, 0.28)); v.ell("Body", "Moss2", T + V(0.45, -0.1, 0.92), (0.22, 0.22, 0.17))
    v.speckle("LeafTop", "Leaf", 0.25, seed=12)
    # roots wrapping the flanks, Ogham runes glowing on the shoulders and haunches
    for s in (-1, 1):
        v.curve("Body", "Root", [(s * 1.15, 1.9, 4.2), (s * 1.5, 0.9, 3.4), (s * 1.4, -0.4, 3.75), (s * 1.3, -1.6, 3.25), (s * 0.95, -2.6, 3.0)], [0.11, 0.13, 0.11, 0.1, 0.05])
        v.curve("Body", "Root", [(s * 1.42, 0.0, 2.95), (s * 1.4, -1.0, 2.9), (s * 1.15, -2.0, 3.8)], [0.08, 0.09, 0.04])
        for x0, y0, z0, n in ((s * 1.52, 1.0, 3.0, 4), (s * 1.24, -2.05, 3.0, 3)):
            v.line("Body", "Glow", [(x0, y0, z0), (x0, y0, z0 + 0.95)], r=0.06)
            for k in range(n):
                zz = z0 + 0.2 + k * 0.2
                v.line("Body", "Glow", [(x0, y0, zz), (x0, y0 + (0.28 if k % 2 else -0.28), zz + 0.12)], r=0.05)
    # the root basket between hump and rump, heaped with tall glowing amber, vines with amber drops hanging from its rim
    B = V(0, -0.95, 4.4)
    v.torus("Body", "Root", B, (0, 0, 1), 0.78, 0.11)
    v.torus("Body", "Root", B + V(0, 0, 0.45), (0, 0, 1), 0.92, 0.11)
    for k in range(12):
        a = k / 12 * math.tau
        v.curve("Body", "Root", [B + V(math.cos(a) * 0.68, math.sin(a) * 0.68, -0.35), B + V(math.cos(a) * 0.8, math.sin(a) * 0.8, 0.15), B + V(math.cos(a) * 0.98, math.sin(a) * 0.98, 0.75)], [0.065, 0.07, 0.04])
    v.ell("Body", "Root", B + V(0, 0, -0.12), (0.75, 0.75, 0.2))
    v.cluster("Body", "Crystal", B, (0, 0, 1), 1.45, n=8, spread=0.55, seed=4)
    v.cluster("Body", "Crystal", B + V(0.4, -0.3, 0.05), (0.4, -0.25, 1), 0.8, n=4, seed=7)
    v.cluster("Body", "Crystal", B + V(-0.35, 0.3, 0.05), (-0.4, 0.3, 1), 0.7, n=4, seed=8)
    for a in (0.5, 2.1, 3.6, 5.0):
        p0 = B + V(math.cos(a) * 0.95, math.sin(a) * 0.95, 0.45)
        v.curve("Body", "Leaf", [p0, p0 + V(math.cos(a) * 0.15, math.sin(a) * 0.15, -0.35), p0 + V(math.cos(a) * 0.12, math.sin(a) * 0.12, -0.7)], [0.04, 0.04, 0.035])
        v.ell("Body", "Crystal", p0 + V(math.cos(a) * 0.12, math.sin(a) * 0.12, -0.8), (0.09, 0.09, 0.13))
    v.anchor("back", "Body", B + V(0, 0, 1.0))
    # pollen motes: little glowing cubes drifting over the basket and the meadow
    v.anchor("canopy", "Body", (0.65, 0.65, 5.9))
    # neck and head: a long wedge skull carried low, a disc nose, glowing amber eyes under a mossy brow, leaf-tipped ears, twig
    # antlers with glowing buds, a rune on the brow, and huge ivory tusks sweeping up and back to amber crystal tips
    v.joint("Head", (0, 2.1, 3.4), "Body", "head")
    v.cap("Head", "Bark", (0, 2.0, 3.55), (0, 2.75, 3.1), 1.08, 0.86)
    v.muscle("Head", "Bark", (0, 3.05, 2.95), (0.82, 0.9, 0.76))
    v.muscle("Head", "Bark", (0, 2.3, 3.4), (0.95, 0.75, 0.8))
    for s in (-1, 1):
        v.muscle("Head", "Bark", (s * 0.62, 2.35, 3.3), (0.42, 0.72, 0.6), rot=E(25, 0, 0))   # the neck muscle to the shoulder
        v.muscle("Head", "Bark", (s * 0.56, 3.25, 2.72), (0.3, 0.45, 0.42))                  # the jaw (masseter)
    v.cap("Head", "Bark", (0, 3.3, 2.85), (0, 4.6, 2.42), 0.6, 0.42)
    v.ell("Head", "Snout", (0, 4.64, 2.4), (0.44, 0.13, 0.36))
    v.ell("Head", "Dark", (0, 3.65, 2.35), (0.48, 0.85, 0.3))
    v.ell("Head", "Moss", (0, 2.6, 3.6), (0.85, 0.75, 0.58), cut=lambda x, y, z: z > 3.75 + nz(x, y, z) * 0.25)
    for s in (-1, 1):
        v.box("Head", "Dark", (s * 0.15, 4.74, 2.4), (0.1, 0.1, 0.14))
        v.ell("Head", "Moss2", (s * 0.42, 3.4, 3.45), (0.32, 0.42, 0.13), rot=E(0, s * -18, 0))  # a mossy brow ridge
        v.eye("Head", (s * 0.55, 3.7, 3.08), (s * 0.75, 0.7, 0.05), w=0.34, h=0.26)
        v.blade("Head", "Bark", (s * 0.45, 2.55, 3.65), (s * 0.85, 2.35, 4.4), 0.42, thick=0.12, normal=(s * 0.4, 1, 0), bend=0.05)
        v.blade("Head", "Leaf", (s * 0.75, 2.4, 4.2), (s * 1.05, 2.2, 4.7), 0.24, thick=0.1, normal=(s * 0.4, 1, 0))
        # twig antlers from behind the brow, each with three tines, leaves and glowing buds
        A = [V(s * 0.3, 2.75, 3.85), V(s * 0.55, 2.55, 4.45), V(s * 0.8, 2.2, 5.05), V(s * 0.95, 1.85, 5.45)]
        v.curve("Head", "Root", A, [0.09, 0.08, 0.06, 0.04])
        for (i, d) in ((1, V(s * 0.45, 0.2, 0.35)), (2, V(-s * 0.1, 0.35, 0.45)), (2, V(s * 0.45, -0.1, 0.2))):
            v.curve("Head", "Root", [A[i], A[i] + d * 0.6, A[i] + d], [0.05, 0.04, 0.025])
            v.box("Head", "Glow", A[i] + d * 1.05, (0.1, 0.1, 0.1))
        v.blade("Head", "Leaf", A[3], A[3] + V(s * 0.3, -0.35, 0.2), 0.2, thick=0.1, normal=(0, 0.3, 1))
        v.blade("Head", "Leaf", A[2], A[2] + V(s * 0.4, 0.1, -0.15), 0.18, thick=0.1, normal=(0, 0.3, 1))
        # the tusks: thick at the jaw, a root band, sweeping out, up and back, an amber crystal at each tip
        TK = [(s * 0.36, 4.05, 2.2), (s * 0.7, 4.5, 2.3), (s * 0.98, 4.75, 2.85), (s * 1.0, 4.5, 3.5), (s * 0.82, 4.05, 3.85)]
        v.curve("Head", "Tusk", TK, [0.26, 0.24, 0.19, 0.13, 0.06])
        vine(v, "Head", TK[0], TK[2], (0.3, 0.24), turns=1.3, colour="Leaf", phase=s, seed=6, leaves=5)
        vine(v, "Head", TK[2], TK[4], (0.22, 0.12), turns=1.0, colour="Leaf", phase=s + 2, seed=7, leaves=3, w=0.045)
        for f, rr in ((0.32, 0.25), (0.5, 0.22), (0.66, 0.18)):
            k = f * 4; i = int(k); tt = k - i
            q = V(TK[i]).lerp(V(TK[i + 1]), tt); d = (V(TK[i + 1]) - V(TK[i])).normalized()
            v.torus("Head", "Glow", q, d, rr, 0.035)
        v.cluster("Head", "Crystal", V(TK[0]) + V(s * 0.25, -0.1, 0.05), (s * 0.9, 0.2, 0.4), 0.55, n=4, seed=8)
        tip = V(TK[4])
        v.box("Head", "Glow", tip + V(0, -0.12, -0.32), (0.08, 0.08, 0.14)); v.box("Head", "Glow", tip + V(0, -0.14, -0.55), (0.07, 0.07, 0.07))
        v.anchor("tusk" + ("R" if s > 0 else "L"), "Head", tip + V(0, 0, 0.1))
        v.torus("Head", "Root", (s * 0.5, 4.22, 2.24), (s * 0.55, 0.8, 0.1), 0.2, 0.06)
        v.torus("Head", "Glow", (s * 0.85, 4.66, 2.55), (s * 0.4, 0.5, 0.75), 0.16, 0.035)
        v.crystal("Head", "Crystal", V(TK[4]) + V(0, 0.05, -0.05), (-s * 0.2, -0.75, 0.5), 0.45, 0.08)
    for st in ([(0, 3.62, 3.66), (0, 3.7, 4.0)], [(0, 3.64, 3.78), (0.16, 3.62, 3.92)], [(0, 3.63, 3.7), (-0.16, 3.6, 3.82)]):
        v.line("Head", "Glow", st, r=0.055)
    v.anchor("eyes", "Head", (0, 3.75, 3.2))
    # long legs on small dark hooves, root bands and a glowing rune ring on each shin
    for limb, x, y, front in (("LegFL", -0.98, 1.25, True), ("LegFR", 0.98, 1.25, True), ("LegBL", -0.92, -2.0, False), ("LegBR", 0.92, -2.0, False)):
        s = 1 if x > 0 else -1
        if front:
            leg(v, limb, (x, y, 3.05), (x + s * 0.04, y + 0.12, 1.55), (x + s * 0.04, y + 0.02, 0.62), (x + s * 0.04, y + 0.1, 0.0), (0.64, 0.42, 0.32, 0.3), "Bark", band="Root", muscle="Bark")
            v.torus(limb + "2", "Glow", (x + s * 0.04, y + 0.07, 1.1), (0, 0.1, 1), 0.44, 0.04)
        else:
            leg(v, limb, (x, y, 3.1), (x + s * 0.06, y + 0.45, 1.85), (x + s * 0.06, y - 0.15, 0.85), (x + s * 0.06, y - 0.05, 0.0), (0.7, 0.45, 0.32, 0.3), "Bark", band="Root", muscle="Bark")
            v.torus(limb + "2", "Glow", (x + s * 0.06, y + 0.15, 1.35), (0, 0.6, 1), 0.46, 0.04)
        v.ell(limb + "1", "Moss", (x + s * 0.4, y, 2.9), (0.32, 0.4, 0.2))
        hip = V(x, y, 3.05 if front else 3.1)
        knee = V(x + s * 0.04, y + 0.12, 1.55) if front else V(x + s * 0.06, y + 0.45, 1.85)
        ank = V(x + s * 0.04, y + 0.02, 0.62) if front else V(x + s * 0.06, y - 0.15, 0.85)
        foot = V(x + s * 0.04, y + 0.1, 0.0) if front else V(x + s * 0.06, y - 0.05, 0.0)
        if front:
            v.muscle(limb + "1", "Bark", hip + V(s * 0.08, 0.15, -0.2), (0.6, 0.62, 0.6), over=False)                  # deltoid
            v.muscle(limb + "1", "Bark", hip.lerp(knee, 0.45) + V(0, -0.28, 0), (0.48, 0.45, 0.62), over=False)        # triceps
            v.muscle(limb + "2", "Bark", knee.lerp(ank, 0.25) + V(0, 0.1, 0), (0.46, 0.42, (knee - ank).length * 0.36), over=False)  # forearm
        else:
            v.muscle(limb + "1", "Bark", hip.lerp(knee, 0.4) + V(0, 0.25, 0), (0.55, 0.5, 0.72), over=False)           # quadriceps
            v.muscle(limb + "1", "Bark", hip.lerp(knee, 0.4) + V(0, -0.35, 0.1), (0.52, 0.45, 0.82), over=False)       # hamstring
            v.muscle(limb + "2", "Bark", knee.lerp(ank, 0.3) + V(0, -0.15, 0), (0.44, 0.42, (knee - ank).length * 0.38), over=False)  # gaskin
            v.cap(limb + "2", "Grain", knee.lerp(ank, 0.55) + V(0, -0.3, 0), ank + V(0, -0.24, 0.05), 0.09, 0.08)       # the hock tendon
        v.ell(limb + "1", "Grain", knee + V(0, 0.2 if front else -0.25, 0.1), (0.42, 0.3, 0.3), over=False)  # the knee
        # living roots spiral down each leg with leaves and glowing buds; amber shards on the knee; leafy feathering and a
        # glowing rim at the hoof; motes drifting at the ankle
        vine(v, limb + "1", hip.lerp(knee, 0.15), knee, (0.62, 0.48), turns=0.9, colour="Root", phase=1.0 + s, seed=3)
        vine(v, limb + "2", knee, ank, (0.48, 0.36), turns=1.1, colour="Root", phase=2.0 + s, seed=4)
        v.cluster(limb + "2", "Crystal", knee + V(s * 0.1, 0.38 if front else -0.35, 0.05), (s * 0.4, 0.8 if front else -0.8, 0.5), 0.5, n=4, seed=5)
        for k in range(9):
            a = k / 9 * math.tau
            o = V(math.cos(a), math.sin(a), 0)
            v.blade(limb + "3", "Leaf" if k % 2 else "Moss2", ank + V(0, 0, 0.05) + o * 0.3, ank + o * 0.55 + V(0, 0, -0.18), 0.22, thick=0.1, normal=o.cross(V(0, 0, 1)))
        v.torus(limb + "3", "Glow", foot + V(0, 0.08, 0.37), (0, 0, 1), 0.36, 0.04)
        v.anchor("hoof" + limb[3:], limb + "3", foot + V(0, 0.1, 0.35))
    # pixel-art form shading over the muscles, then the bark grain and the glowing sap on the mid tone
    v.anatomy("Bark", "BarkHi", "BarkLo", "Crease")
    v.paint("Grain", grain, part="Body", only={"Bark"})
    v.paint("GlowSap", lambda x, y, z: grain(x, y, z) and nz(x + 7, y, z, 0.35) > 0.66 and 2.9 < z < 4.0, part="Body", only={"Grain"})
    v.paint("Grain", lambda x, y, z: (math.floor(x / 0.1 + nz(x, y, z, 0.4) * 5) % 6 == 0) and y < 3.9, part="Head", only={"Bark"})
    # a leafy sapling tail with a glowing amber berry
    pts = [V(0, -2.85, 3.85), V(0, -3.2, 3.45), V(0, -3.32, 2.95)]
    v.joint("Tail1", tuple(pts[0]), "Body", "tail"); v.cap("Tail1", "Root", pts[0], pts[1], 0.1, 0.08)
    v.joint("Tail2", tuple(pts[1]), "Tail1", "tail"); v.cap("Tail2", "Root", pts[1], pts[2], 0.08, 0.05)
    for k in range(6):
        a = k / 6 * math.tau
        v.blade("Tail2", "Leaf" if k % 2 else "Moss2", (0, -3.32, 2.95), (math.cos(a) * 0.32, -3.55, 2.68 + math.sin(a) * 0.28), 0.2, thick=0.1, normal=(0, 1, 0))
    v.ell("Tail2", "Crystal", (0, -3.42, 2.8), (0.1, 0.1, 0.12))

if __name__ == "__main__":
    rp = os.path.join(here, "rigs.json")
    db = json.load(open(rp)) if os.path.exists(rp) else {}
    for name, (pal, fn) in D.items():
        if ONLY and name not in ONLY and name.replace(" ", "") not in ONLY: continue
        v = X.Vox(name, pal, s=S)
        fn(v)
        c = v.build()
        d = K.export(c, OUT)
        d["cells"] = len(v.cells); d["proportions"] = proportions(v)
        db[name] = d
        print(f"{name}: {d['proportions']} {len(v.cells)} cells, {d['tris']} triangles, {d['parts']} parts, {d['objects']} objects, biggest {d['maxPart']}, size {d['size']}", flush=True)
    json.dump(db, open(rp, "w"), indent=1)
