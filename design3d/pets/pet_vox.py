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



# ---------------------------------------------------------------- shared helpers for the roster (2026-11-24 night)
import colorsys
from mathutils import Matrix
from plate_kit import look


def _hx(h):
    h = h.lstrip("#"); return tuple(int(h[i:i + 2], 16) / 255 for i in (0, 2, 4))


def _hex(c):
    return "#%02x%02x%02x" % tuple(max(0, min(255, int(round(x * 255)))) for x in c)


def _shift(h, dl=0.0, dh=0.0, ds=0.0):
    r, g, b = _hx(h); H, L, S = colorsys.rgb_to_hls(r, g, b)
    return _hex(colorsys.hls_to_rgb((H + dh) % 1.0, max(0, min(1, L + dl)), max(0, min(1, S + ds))))


def palette(form=(), **cols):
    """a pet palette: every colour gets a lighter Top shade (upward faces); colours named in form also get pixel-art form
    tones for the anatomy pass: Hi (lighter, warmer), Lo (darker, cooler) and <Name>Crease (the dark seam between masses)"""
    out = {}
    for k, h in cols.items():
        if k.startswith("_"): out[k] = h; continue
        out[k] = h
        out.setdefault(k + "Top", _shift(h, 0.07, 0.0, 0.03))
        if k in form:
            out[k + "Hi"] = _shift(h, 0.12, -0.025, 0.05); out[k + "HiTop"] = _shift(h, 0.18, -0.03, 0.05)
            out[k + "Lo"] = _shift(h, -0.1, 0.04, -0.05); out[k + "LoTop"] = _shift(h, -0.05, 0.04, -0.05)
            out[k + "Crease"] = _shift(h, -0.2, 0.05, -0.1); out[k + "CreaseTop"] = _shift(h, -0.16, 0.05, -0.1)
    out.setdefault("Eye", "#1c1026"); out.setdefault("EyeTop", out["Eye"]); out.setdefault("Shine", "#ffffff"); out.setdefault("ShineTop", "#ffffff")
    out.setdefault("Edge", "#b0a8c8"); out["_noseams"] = True
    return out


def shade(v, *names, parts=None):
    for n in names: v.anatomy(n, n + "Hi", n + "Lo", n + "Crease", parts=parts)


def foot_paw(v, part, foot, r, colour, claw, toes=4, fwd=V(0, 1, 0)):
    """a flat-soled paw: a low pad on the ground, toe bumps along the front edge, claws curving down to the ground"""
    f = V(fwd).normalized(); side = f.cross(V(0, 0, 1)).normalized()
    c0 = foot + f * r * 0.45
    v.ell(part, colour, c0 + V(0, 0, 0.0), (r * 1.35, r * 1.6, r * 0.75), cut=lambda x, y, z: z >= 0.0)
    for i in range(toes):
        o = (i - (toes - 1) / 2) * r * 0.62
        t = c0 + side * o + f * r * 1.25
        v.ell(part, colour, t, (r * 0.36, r * 0.42, r * 0.42), cut=lambda x, y, z: z >= 0.0)
        v.cap(part, claw, t + f * r * 0.25 + V(0, 0, r * 0.2), t + f * r * 0.75 + V(0, 0, 0.03), r * 0.16, r * 0.05)


def foot_talon(v, part, foot, r, colour, claw, fwd=V(0, 1, 0)):
    """a bird / drake foot: three long forward toes and a back toe, flat on the ground, hooked claws"""
    f = V(fwd).normalized(); side = f.cross(V(0, 0, 1)).normalized()
    for k in (-1, 0, 1):
        d = (f + side * k * 0.45).normalized()
        a = foot + V(0, 0, r * 0.45); b = foot + d * r * 2.4 + V(0, 0, r * 0.35)
        v.cap(part, colour, a, b, r * 0.55, r * 0.38)
        v.cap(part, claw, b, b + d * r * 0.8 + V(0, 0, -r * 0.3), r * 0.3, r * 0.08)
    v.cap(part, colour, foot + V(0, 0, r * 0.45), foot - f * r * 1.2 + V(0, 0, r * 0.35), r * 0.45, r * 0.3)
    v.cap(part, claw, foot - f * r * 1.2 + V(0, 0, r * 0.35), foot - f * r * 1.7 + V(0, 0, 0.05), r * 0.25, r * 0.07)


def foot_hoof(v, part, foot, r, hoof, cloven=True):
    H, rx, ry, c0 = 0.34, r * 1.45, r * 1.65, foot + V(0, 0.06, 0)
    def inside(x, y, z, c0=c0, H=H, rx=rx, ry=ry):
        tt = (z - c0.z) / H
        if tt < 0 or tt > 1: return False
        k = 1 - 0.28 * tt
        return ((x - c0.x) / (rx * k)) ** 2 + ((y - c0.y - 0.05 * (1 - tt)) / (ry * k)) ** 2 <= 1
    v.fill(part, hoof, c0 - V(rx, ry, 0), c0 + V(rx, ry + 0.1, H), inside)
    if cloven: v.carve(lambda x, y, z, c0=c0: abs(x - c0.x) < 0.06 and y > c0.y - 0.02 and z < c0.z + H * 0.75, part=part)


def leg2(v, limb, hip, knee, ank, foot, r, colour, front=True, kind="paw", parent="Body", claw="Claw", hoof="Hoof", band=None, toes=4, group="leg"):
    """an adult leg with anatomy: limb1 shoulder or thigh (deltoid + triceps in front, quadriceps + hamstring behind), limb2 the
    forearm or gaskin, limb3 the cannon and the foot (a flat paw, a flat cloven hoof or a talon). r = (top, knee, ankle, foot)"""
    hip, knee, ank, foot = V(hip), V(knee), V(ank), V(foot)
    L1, L2 = (hip - knee).length, (knee - ank).length
    fy = 1 if front else -1
    v.joint(limb + "1", tuple(hip), parent, group)
    v.cap(limb + "1", colour, hip, knee, r[0], r[1], over=False)
    if front:
        v.muscle(limb + "1", colour, hip + V(0, r[0] * 0.25, -L1 * 0.12), (r[0] * 1.2, r[0] * 1.25, L1 * 0.4), over=False)
        v.muscle(limb + "1", colour, hip.lerp(knee, 0.5) + V(0, -r[0] * 0.55, 0), (r[0] * 0.95, r[0] * 0.85, L1 * 0.38), over=False)
    else:
        v.muscle(limb + "1", colour, hip.lerp(knee, 0.38) + V(0, r[0] * 0.45, 0), (r[0] * 1.1, r[0] * 0.95, L1 * 0.45), over=False)
        v.muscle(limb + "1", colour, hip.lerp(knee, 0.4) + V(0, -r[0] * 0.65, 0.05), (r[0] * 1.0, r[0] * 0.85, L1 * 0.5), over=False)
    v.joint(limb + "2", tuple(knee), limb + "1", group)
    v.cap(limb + "2", colour, knee, ank, r[1], r[2])
    v.muscle(limb + "2", colour, knee.lerp(ank, 0.28) + V(0, fy * r[1] * 0.3, 0), (r[1] * 1.15, r[1] * 1.1, L2 * 0.36), over=False)
    v.joint(limb + "3", tuple(ank), limb + "2", group)
    v.cap(limb + "3", colour, ank, foot + V(0, 0, 0.15), r[2], r[3])
    if band: v.torus(limb + "2", band, knee.lerp(ank, 0.62), (ank - knee).normalized(), r[2] * 1.12, 0.045)
    if kind == "hoof": foot_hoof(v, limb + "3", foot, r[3], hoof)
    elif kind == "talon": foot_talon(v, limb + "3", foot, r[3], colour, claw)
    else: foot_paw(v, limb + "3", foot, r[3], colour, claw, toes)
    v.anchor("foot" + limb[3:], limb + "3", foot + V(0, 0.1, 0.3))


def ground(v):
    v.carve(lambda x, y, z: z < 0.0)


def surf(v, part, origin, d, maxd=4.0):
    """march from origin along d through the part's cells; the last filled point is on its surface"""
    o, d = V(origin), V(d).normalized(); s = v.s; last = None; t = 0.0
    while t < maxd:
        q = o + d * t
        k = (math.floor(q.x / s), math.floor(q.y / s), math.floor(q.z / s))
        c = v.cells.get(k)
        if c and c[0] == part: last = q
        elif last is not None: break
        t += s * 0.5
    return last


def scales(v, part, a, b, rows, arc, size, col, rim, step=None, lift=0.04, thick=0.32):
    """overlapping shingle scales (pangolin tiles, dragon plates): rows from b (the tail end) to a (the head end), scales over
    the angles in arc (degrees from straight up, round the a->b axis), laid on the surface; each scale's back third is painted
    rim so every row reads; drawn tail first so forward scales overlap the ones behind"""
    a, b = V(a), V(b); ax = (a - b).normalized(); up0 = V(0, 0, 1) - ax * ax.z; up0.normalize(); side0 = ax.cross(up0).normalized()
    step = step or size * 1.25
    for i in range(rows):
        P = b.lerp(a, (i + 0.5) / rows)
        n_ang = arc[0]
        k = 0
        while n_ang <= arc[1] + 1e-6:
            ang = math.radians(n_ang + (step * 18 if i % 2 else 0))
            d = up0 * math.cos(ang) + side0 * math.sin(ang)
            q = surf(v, part, P, d)
            if q is not None:
                n = d; yb = -ax - n * n.dot(-ax); yb.normalize(); xb = yb.cross(n).normalized()
                R = Matrix((xb, yb, n)).transposed()
                c = q + n * lift - yb * size * 0.15
                v.ell(part, col, c, (size, size * 1.15, size * thick), rot=R)
                Ri = R.inverted()
                def back(x, y, z, c=c, Ri=Ri):
                    dl = Ri @ (V(x, y, z) - c)
                    return (dl.x / size) ** 2 + (dl.y / (size * 1.15)) ** 2 + (dl.z / (size * thick)) ** 2 <= 1 and dl.y > size * 0.45
                v.paint(rim, back, part=part, only={col})
            n_ang += step * 36
            k += 1


# ---------------------------------------------------------------- KOBOLD: Clay-Cavern Pangolin-Gargoyle (Common digger; A)
@pet("Kobold", palette(form=("Clay",), Clay="#9a5634", Tile="#cc6a3e", TileRim="#86391f", Shale="#e4d4b2", Dark="#3a2418",
                       Claw="#f2eadc", Hoof="#4a4552", Crystal="#ff8a32", Glow="#ff7a1e", Edge="#d8b090"))
def kobold(v):
    nz = noise(5)
    v.joint("Body", (0, 0, 3.0))
    # a hunched knuckle-walking gargoyle pangolin (magic/concepts/Kobold_s21): long armoured forearms with spade claws, a
    # terracotta tile coat split by glowing heat cracks, a fossil belly, a trilobite visor, ember eyes, a heavy scaled tail
    v.muscle("Body", "Clay", (0, 0.8, 3.25), (1.35, 1.3, 1.25))
    v.muscle("Body", "Clay", (0, -0.55, 2.95), (1.15, 1.45, 1.02))
    v.muscle("Body", "Clay", (0, -1.65, 2.8), (1.02, 0.85, 0.92))
    v.muscle("Body", "Clay", (0, 0.45, 4.05), (1.0, 1.1, 0.6))
    for s in (-1, 1): v.muscle("Body", "Clay", (s * 1.12, 1.15, 3.55), (0.45, 0.62, 0.72), rot=E(-15, s * -12, 0))
    v.ell("Body", "Shale", (0, 0.35, 2.25), (0.85, 1.55, 0.42))
    v.paint("Dark", lambda x, y, z: (y % 0.36) < 0.07, part="Body", only={"Shale"})
    shade(v, "Clay")
    scales(v, "Body", (0, 1.7, 3.3), (0, -2.15, 2.9), rows=11, arc=(-100, 100), size=0.36, col="Tile", rim="TileRim")
    v.paint("Glow", lambda x, y, z: nz(x, y, z, 0.3) > 0.72 and z > 3.3, part="Body", only={"TileRim"})
    v.anchor("back", "Body", (0, -0.2, 4.7))
    # the head: a long pangolin snout, a trilobite shell visor with a ridge and segments, ember eyes under it, gargoyle horns
    v.joint("Head", (0, 1.9, 3.35), "Body", "head")
    v.muscle("Head", "Clay", (0, 2.45, 3.05), (0.75, 0.85, 0.68))
    v.muscle("Head", "Clay", (0, 1.95, 3.35), (0.85, 0.6, 0.7))
    v.cap("Head", "Clay", (0, 2.9, 2.9), (0, 3.75, 2.62), 0.44, 0.26)
    v.ell("Head", "Dark", (0, 3.8, 2.62), (0.2, 0.08, 0.15))
    v.ell("Head", "Shale", (0, 2.5, 3.5), (0.98, 1.05, 0.4), cut=lambda x, y, z: z > 3.38)
    v.paint("TileRim", lambda x, y, z: (y % 0.2) < 0.05, part="Head", only={"Shale"})
    v.cap("Head", "Tile", (0, 1.6, 3.85), (0, 3.25, 3.6), 0.13, 0.08)
    shade(v, "Clay", parts={"Head"})
    for s in (-1, 1):
        v.eye("Head", (s * 0.48, 2.98, 3.12), (s * 0.8, 0.6, 0.0), w=0.28, h=0.2)
        v.curve("Head", "Claw", [(s * 0.62, 2.15, 3.75), (s * 0.95, 1.85, 4.2), (s * 1.05, 1.35, 4.45), (s * 0.95, 1.05, 4.3)], [0.13, 0.11, 0.07, 0.03])
        v.blade("Head", "Clay", (s * 0.72, 2.1, 3.4), (s * 1.15, 1.85, 3.6), 0.3, thick=0.12, normal=(0, 0.3, 1))
    v.anchor("eyes", "Head", (0, 3.15, 3.1))
    # long armoured forelimbs on spade-clawed knuckles; shorter hind legs
    for s in (-1, 1):
        L = "ArmL" if s < 0 else "ArmR"
        leg2(v, L, (s * 1.18, 1.3, 3.3), (s * 1.48, 1.15, 1.95), (s * 1.42, 1.55, 0.62), (s * 1.42, 1.7, 0.0), (0.55, 0.42, 0.34, 0.32), "Clay", front=True, claw="Claw", toes=3, group="leg")
        scales(v, L + "2", (s * 1.42, 1.55, 0.75), (s * 1.48, 1.15, 1.9), rows=4, arc=(-60, 60), size=0.24, col="Tile", rim="TileRim")
        for k in (-1, 0, 1):
            t = V(s * 1.42 + k * 0.2, 2.15, 0.12)
            v.cap(L + "3", "Claw", t + V(0, -0.1, 0.18), t + V(0, 0.5, 0.0), 0.12, 0.03)
        shade(v, "Clay", parts={L + "1", L + "2"})
        B = "LegBL" if s < 0 else "LegBR"
        leg2(v, B, (s * 0.88, -1.6, 2.6), (s * 0.98, -1.05, 1.5), (s * 0.98, -1.7, 0.62), (s * 0.98, -1.6, 0.0), (0.58, 0.4, 0.3, 0.28), "Clay", front=False, claw="Claw")
        shade(v, "Clay", parts={B + "1", B + "2"})
    # the heavy tail: five bones of tiles tapering to a smouldering ember club
    pts = [V(0, -2.25, 2.95), V(0, -3.0, 2.45), V(0, -3.6, 1.75), V(0, -4.05, 1.05), V(0, -4.45, 0.55), V(0, -4.9, 0.4)]
    rad = [0.78, 0.62, 0.48, 0.36, 0.25, 0.16]
    for i in range(5):
        nm = f"Tail{i + 1}"
        v.joint(nm, tuple(pts[i]), "Body" if i == 0 else f"Tail{i}", "tail")
        v.cap(nm, "Clay", pts[i], pts[i + 1], rad[i], rad[i + 1])
        scales(v, nm, pts[i + 1], pts[i], rows=2, arc=(-110, 110), size=max(0.16, rad[i] * 0.48), col="Tile", rim="TileRim")
    v.cluster("Tail5", "Crystal", pts[5], (0, -0.6, 0.5), 0.6, n=5, seed=3)
    v.anchor("tail", "Tail5", pts[5] + V(0, -0.2, 0.3))
    ground(v)


# ---------------------------------------------------------------- KEPRI SCARAB: Jewel-Carapace Jade Scarab (Common fast digger; A)
@pet("Kepri Scarab", palette(form=("Jade",), Jade="#0e7a56", Dark="#082e24", Gold="#d6a632", Quartz="#eef8f2", Leg="#0b4434",
                             Claw="#e0b440", Crystal="#3ff0b0", Glow="#5dffb8", Edge="#a8f0d0"))
def kepri(v):
    v.joint("Body", (0, 0, 1.8))
    # a jewelled beetle (magic/concepts/KepriScarab_s21): two domed jade wing cases traced with gold filigree and set with
    # glowing gems, a heart gem in a gold bezel, crystal winglets, curled gold horns over a fluted quartz drill, six long
    # jointed legs shod in gold
    for s in (-1, 1):
        v.muscle("Body", "Jade", (s * 0.62, -0.5, 1.95), (0.85, 1.75, 0.98), cut=lambda x, y, z, s=s: x * s >= -0.02)
    v.muscle("Body", "Jade", (0, 1.05, 1.85), (1.05, 0.78, 0.75))
    v.ell("Body", "Dark", (0, -0.35, 1.25), (1.12, 1.8, 0.45))
    shade(v, "Jade")
    v.line("Body", "Gold", [(0, 1.0, 2.9), (0, 0.0, 2.95), (0, -1.2, 2.7), (0, -2.05, 2.0)], r=0.07)
    for s in (-1, 1):
        v.curve("Body", "Gold", [(s * 1.42, 1.0, 1.75), (s * 1.48, 0.0, 2.05), (s * 1.38, -1.2, 1.95), (s * 0.9, -2.05, 1.55), (s * 0.1, -2.25, 1.45)], [0.07] * 5)
        sp = [V(s * (0.6 + 0.42 * math.cos(a) * (1 - a / 11)), -0.75 + 0.6 * math.sin(a) * (1 - a / 11), 2.85 - 0.05 * a) for a in [k * 0.35 for k in range(26)]]
        v.tube("Body", "Gold", sp, [0.05] * len(sp))
        for k in range(3):
            q = surf(v, "Body", (s * 0.6, 0.2 - 0.75 * k, 1.9), (s * 0.55, 0, 1))
            if q: v.ell("Body", "Glow", q, (0.11, 0.11, 0.09))
    gq = surf(v, "Body", (0, 1.05, 1.85), (0, 0.55, 1)) or V(0, 1.4, 2.4)
    v.torus("Body", "Gold", gq, (0, 0.55, 0.84), 0.32, 0.07)
    v.ell("Body", "Crystal", gq + V(0, 0.02, 0.05), (0.26, 0.26, 0.3))
    v.anchor("gem", "Body", gq + V(0, 0.1, 0.25))
    # crystal winglets on their own bones (they beat)
    for s, w in ((-1, "WingL"), (1, "WingR")):
        root = V(s * 0.55, 0.45, 2.7)
        v.joint(w, tuple(root), "Body", "wing")
        for tx, ty, tz, wd in ((2.3, -0.2, 3.25, 0.55), (2.1, -1.0, 2.95, 0.45), (1.6, -1.65, 2.6, 0.36)):
            tip = V(s * tx, ty, tz)
            v.blade(w, "Crystal", root, tip, wd, thick=0.1, normal=(0, 0.2, 1))
            v.curve(w, "Gold", [root, root.lerp(tip, 0.55) + V(0, 0.1, 0.1), tip], [0.04, 0.035, 0.02])
    # the head: a jade dome, glowing eyes, curled gold horns, mandibles, antennae with glowing tips and the quartz drill
    v.joint("Head", (0, 1.6, 1.8), "Body", "head")
    v.muscle("Head", "Jade", (0, 1.95, 1.72), (0.68, 0.55, 0.52))
    shade(v, "Jade", parts={"Head"})
    v.crystal("Head", "Quartz", (0, 2.3, 1.75), (0, 1, 0.22), 1.2, 0.2)
    sp = [V(0, 2.35, 1.77) + V(0, 1, 0.22).normalized() * (k * 0.045) + V(math.cos(k * 0.55) * 0.2 * (1 - k / 30), 0, math.sin(k * 0.55) * 0.2 * (1 - k / 30)) for k in range(26)]
    v.tube("Head", "Gold", sp, [0.04] * len(sp))
    for s in (-1, 1):
        v.eye("Head", (s * 0.44, 2.22, 1.88), (s * 0.7, 0.7, 0.1), w=0.24, h=0.2)
        v.curve("Head", "Gold", [(s * 0.3, 2.1, 2.1), (s * 0.58, 2.3, 2.65), (s * 0.82, 2.1, 3.15), (s * 0.72, 1.7, 3.3), (s * 0.5, 1.65, 3.05), (s * 0.52, 1.85, 2.9)], [0.12, 0.11, 0.09, 0.07, 0.05, 0.03])
        v.cap("Head", "Claw", (s * 0.32, 2.25, 1.38), (s * 0.12, 2.75, 1.28), 0.1, 0.03)
        v.curve("Head", "Gold", [(s * 0.2, 2.3, 2.0), (s * 0.5, 2.8, 2.4), (s * 0.85, 3.0, 2.45)], [0.035, 0.03, 0.02])
        v.box("Head", "Glow", (s * 0.88, 3.02, 2.45), (0.1, 0.1, 0.1))
    v.anchor("eyes", "Head", (0, 2.3, 1.9))
    # six legs: long jointed jade legs, gold bands and gold hooked feet, the tripod gait names LegL1_ .. LegR3_
    for s in (-1, 1):
        for i, y in enumerate((0.9, 0.05, -0.8)):
            nm = f"Leg{'L' if s < 0 else 'R'}{i + 1}_"
            hip, knee, ank, tip = V(s * 0.9, y, 1.45), V(s * 1.95, y + 0.15 - 0.1 * i, 2.1), V(s * 2.45, y + 0.3 - 0.25 * i, 0.7), V(s * 2.6, y + 0.5 - 0.35 * i, 0.0)
            v.joint(nm + "1", tuple(hip), "Body", "leg"); v.cap(nm + "1", "Leg", hip, knee, 0.17, 0.14)
            v.ell(nm + "1", "Jade", hip.lerp(knee, 0.4), (0.2, 0.2, 0.2))
            v.joint(nm + "2", tuple(knee), nm + "1", "leg"); v.cap(nm + "2", "Leg", knee, ank, 0.14, 0.1)
            v.torus(nm + "2", "Gold", knee.lerp(ank, 0.5), (ank - knee).normalized(), 0.13, 0.035)
            for k in range(3):
                q = knee.lerp(ank, 0.25 + 0.2 * k)
                v.cap(nm + "2", "Claw", q + V(s * 0.08, 0, 0.05), q + V(s * 0.3, 0.05, 0.1), 0.04, 0.015)
            v.joint(nm + "3", tuple(ank), nm + "2", "leg"); v.cap(nm + "3", "Claw", ank, tip, 0.1, 0.04)
            v.anchor(f"foot{i}{'L' if s < 0 else 'R'}", nm + "3", tip + V(0, 0, 0.15))
    ground(v)


# ---------------------------------------------------------------- SHINEMANE: Prismatic Crystal Lurcher (Uncommon light; A)
@pet("Shinemane", palette(form=("Fur",), Fur="#253a96", Chest="#7d95e8", Dark="#101848", Amethyst="#9a7cf4", Claw="#c8ecff",
                          Crystal="#5ee6ff", Glow="#8af4ff", Edge="#9ab4ff"))
def shinemane(v):
    nz = noise(8)
    v.joint("Body", (0, 0, 3.4))
    # a lean, long-legged crystal lurcher (magic/concepts/Shinemane_s21): a deep chest and tucked waist, a halo collar of
    # crystal shards round its neck, tall ears, a crystal on its brow, glowing starmaps on its flanks, crystal bracers, a plume
    # tail that ends in a crown of crystals
    v.muscle("Body", "Fur", (0, 1.05, 3.55), (0.88, 1.0, 1.02))
    v.muscle("Body", "Fur", (0, -0.2, 3.62), (0.62, 1.2, 0.66))
    v.muscle("Body", "Fur", (0, -1.4, 3.55), (0.78, 0.82, 0.8))
    for s in (-1, 1):
        v.muscle("Body", "Fur", (s * 0.72, 1.15, 3.75), (0.28, 0.55, 0.62), rot=E(-15, s * -10, 0))
        v.muscle("Body", "Fur", (s * 0.55, -1.55, 3.75), (0.42, 0.62, 0.55))
        for k, y in enumerate((0.45, 0.1, -0.25)):
            v.muscle("Body", "Fur", (s * 0.68, y, 3.45), (0.14, 0.12, 0.5 - 0.05 * k))
    v.ell("Body", "Chest", (0, 1.55, 3.3), (0.62, 0.55, 0.82))
    v.ell("Body", "Chest", (0, 0.6, 2.85), (0.55, 0.9, 0.35))
    shade(v, "Fur")
    v.paint("Chest", lambda x, y, z: nz(x, y, z, 0.25) > 0.62 and y > 1.2 and z < 3.6, part="Body", only={"Fur", "FurLo"})
    for s in (-1, 1):
        stars = [V(s * 0.72, 0.15, 3.85), V(s * 0.66, -0.3, 3.55), V(s * 0.7, -0.75, 3.82), V(s * 0.78, -1.2, 3.55), V(s * 0.52, -0.4, 4.1)]
        stars = [surf(v, "Body", (0, q.y, q.z), (s, 0, 0)) or q for q in stars]
        for a, b in ((0, 1), (1, 2), (2, 3), (1, 4)): v.line("Body", "Glow", [stars[a], stars[b]], r=0.045)
        for q in stars: v.box("Body", "Glow", q, (0.14, 0.14, 0.14))
    # the neck, the crystal collar and the head
    v.joint("Neck", (0, 1.4, 3.9), "Body", "neck")
    v.cap("Neck", "Fur", (0, 1.4, 3.9), (0, 2.05, 4.85), 0.5, 0.38)
    for s in (-1, 1): v.muscle("Neck", "Fur", (s * 0.3, 1.75, 4.3), (0.28, 0.5, 0.55), rot=E(35, 0, 0))
    shade(v, "Fur", parts={"Neck"})
    N0 = V(0, 1.7, 4.35)
    for k in range(18):
        a = k / 18 * math.tau
        out = V(math.cos(a), -0.35, math.sin(a) * 0.95 + 0.2).normalized()
        L = 0.75 + 0.45 * (0.5 + 0.5 * math.sin(a)) + (0.2 if k % 2 else 0)
        v.crystal("Neck", "Crystal" if k % 3 else "Amethyst", N0 + out * 0.42, out, L, 0.12 if k % 2 else 0.09)
    v.anchor("mane", "Neck", N0)
    v.joint("Head", (0, 2.05, 4.85), "Neck", "head")
    v.muscle("Head", "Fur", (0, 2.3, 5.05), (0.52, 0.58, 0.48))
    v.cap("Head", "Fur", (0, 2.55, 4.95), (0, 3.4, 4.72), 0.3, 0.12)
    v.cap("Head", "Chest", (0, 2.55, 4.78), (0, 3.2, 4.62), 0.22, 0.09)
    v.box("Head", "Dark", (0, 3.48, 4.74), (0.12, 0.1, 0.1))
    shade(v, "Fur", parts={"Head"})
    v.crystal("Head", "Crystal", (0, 2.62, 5.42), (0, 0.4, 1), 0.55, 0.1)
    for s in (-1, 1):
        v.eye("Head", (s * 0.3, 2.82, 5.12), (s * 0.7, 0.75, 0.05), w=0.24, h=0.18)
        v.blade("Head", "Fur", (s * 0.28, 2.15, 5.3), (s * 0.62, 1.95, 6.35), 0.52, thick=0.16, normal=(s * 0.3, 1, 0))
        v.blade("Head", "Amethyst", (s * 0.29, 2.24, 5.36), (s * 0.57, 2.06, 6.1), 0.28, thick=0.12, normal=(s * 0.3, 1, 0))
    v.anchor("eyes", "Head", (0, 2.95, 5.1))
    # long slender legs with crystal bracers
    for limb, x, y, front in (("LegFL", -0.5, 1.15, True), ("LegFR", 0.5, 1.15, True), ("LegBL", -0.52, -1.5, False), ("LegBR", 0.52, -1.5, False)):
        s = 1 if x > 0 else -1
        if front:
            hip, knee, ank, foot = (x, y, 3.25), (x + s * 0.03, y + 0.05, 1.75), (x + s * 0.03, y - 0.05, 0.55), (x + s * 0.03, y + 0.05, 0.0)
        else:
            hip, knee, ank, foot = (x, y, 3.35), (x + s * 0.04, y + 0.5, 2.0), (x + s * 0.04, y - 0.25, 0.8), (x + s * 0.04, y - 0.1, 0.0)
        leg2(v, limb, hip, knee, ank, foot, (0.36, 0.22, 0.16, 0.15), "Fur", front=front, claw="Claw", toes=4)
        shade(v, "Fur", parts={limb + "1", limb + "2", limb + "3"})
        k, a = V(knee), V(ank)
        v.crystal(limb + "2", "Crystal", k.lerp(a, 0.5) + V(s * 0.15, 0, 0), (s * 0.6, -0.3, 0.75), 0.5, 0.08)
        v.crystal(limb + "2", "Amethyst", k.lerp(a, 0.62) + V(s * 0.13, 0.12, 0), (s * 0.7, -0.2, 0.5), 0.32, 0.06)
    # the plume tail
    pts = [V(0, -2.0, 3.9), V(0, -2.75, 4.25), V(0, -3.35, 4.75), V(0, -3.6, 5.4), V(0, -3.4, 6.0)]
    rad = [0.2, 0.36, 0.48, 0.44, 0.2]
    for i in range(4):
        nm = f"Tail{i + 1}"
        v.joint(nm, tuple(pts[i]), "Body" if i == 0 else f"Tail{i}", "tail")
        v.muscle(nm, "Fur", pts[i].lerp(pts[i + 1], 0.5), (rad[i + 1] * 1.05, (pts[i + 1] - pts[i]).length * 0.62, rad[i + 1] * 1.05), rot=look(pts[i + 1] - pts[i]))
        shade(v, "Fur", parts={nm})
        v.paint("Chest", lambda x, y, z: nz(x, y, z, 0.22) > 0.6, part=nm, only={"Fur", "FurHi"})
    v.cluster("Tail4", "Crystal", pts[4], (0, 0.2, 1), 0.85, n=6, seed=9)
    v.anchor("tail", "Tail4", pts[4] + V(0, 0, 0.5))
    ground(v)


# ---------------------------------------------------------------- GOLDBRISTLE: Auric-Pyrite Hedgehog-Badger (Uncommon lucky; B)
@pet("Goldbristle", palette(form=("Fur",), Fur="#2a2f3c", Stripe="#e8e4da", Gold="#e6a628", Nugget="#c88a1a", Dark="#14161e",
                            Claw="#ffd24a", Crystal="#ffd968", Glow="#ffcf40", Edge="#c8b070"))
def goldbristle(v):
    rnd = random.Random(4)
    v.joint("Body", (0, 0, 2.3))
    # a heavy honey-badger (magic/concepts/Goldbristle_s22): a broad low body, a dome of raw gold quills and pyrite nuggets
    # splayed past its flanks, a white badger stripe, gold-shod forearms with filigree, golden claws; its halo of coins is
    # the game's orbit effect
    v.muscle("Body", "Fur", (0, 0.65, 2.35), (1.35, 1.3, 1.1))
    v.muscle("Body", "Fur", (0, -0.75, 2.3), (1.3, 1.4, 1.05))
    for s in (-1, 1):
        v.muscle("Body", "Fur", (s * 1.05, 1.05, 2.55), (0.48, 0.65, 0.72), rot=E(-15, s * -12, 0))
        v.muscle("Body", "Fur", (s * 0.85, -1.4, 2.5), (0.6, 0.7, 0.72))
    v.ell("Body", "Dark", (0, -0.1, 1.6), (1.0, 1.6, 0.45))
    shade(v, "Fur")
    for i in range(9):
        y = 1.2 - i * 0.36
        for a in range(-95, 100, 19):
            aa = math.radians(a + (9 if i % 2 else 0))
            d = V(math.sin(aa), -0.35, math.cos(aa)).normalized()
            q = surf(v, "Body", (0, y, 2.3), d)
            if q is None: continue
            L = 0.85 + 0.4 * math.cos(aa) + rnd.uniform(-0.1, 0.15)
            v.crystal("Body", "Gold" if (i + a // 19) % 3 else "Nugget", q - d * 0.1, (d + V(0, -0.35, 0.2)).normalized(), L, 0.11 + 0.03 * rnd.random(), sides=4)
    for k in range(14):
        a = rnd.uniform(-1.4, 1.4); y = rnd.uniform(-1.6, 1.0)
        q = surf(v, "Body", (0, y, 2.3), (math.sin(a), 0, math.cos(a)))
        if q: v.ell("Body", "Nugget", q, (0.18, 0.16, 0.13), rot=E(rnd.uniform(0, 60), rnd.uniform(0, 60), 0))
    v.anchor("back", "Body", (0, -0.2, 4.6))
    # the head: broad and low, a white stripe from the nose over the crown, small ears, gold eyes, a clover rune on the snout
    v.joint("Head", (0, 1.65, 2.4), "Body", "head")
    v.muscle("Head", "Fur", (0, 2.15, 2.35), (0.82, 0.8, 0.68))
    v.muscle("Head", "Fur", (0, 1.7, 2.6), (0.92, 0.55, 0.72))
    v.cap("Head", "Fur", (0, 2.6, 2.25), (0, 3.25, 2.05), 0.44, 0.24)
    shade(v, "Fur", parts={"Head"})
    v.paint("Stripe", lambda x, y, z: abs(x) < 0.22 + 0.05 * (y - 2) and z > 2.25 - 0.1 * (y - 2.0), part="Head", only={"Fur", "FurHi", "FurLo", "FurCrease"})
    v.ell("Head", "Dark", (0, 3.3, 2.06), (0.22, 0.1, 0.16))
    for s in (-1, 1):
        v.eye("Head", (s * 0.48, 2.65, 2.55), (s * 0.75, 0.65, 0.1), w=0.22, h=0.16)
        v.ell("Head", "Fur", (s * 0.66, 1.75, 2.95), (0.2, 0.12, 0.2))
    for st in ([(0, 3.02, 2.38), (0, 3.06, 2.52)], [(-0.08, 3.02, 2.45), (0.08, 3.02, 2.45)]):
        v.line("Head", "Glow", st, r=0.05)
    v.anchor("eyes", "Head", (0, 2.8, 2.55)); v.anchor("halo", "Head", (0, 1.8, 3.7))
    # powerful forelegs in gold bracers, digging claws; hind legs
    for limb, x, y, front in (("LegFL", -1.0, 1.15, True), ("LegFR", 1.0, 1.15, True), ("LegBL", -0.92, -1.35, False), ("LegBR", 0.92, -1.35, False)):
        s = 1 if x > 0 else -1
        if front:
            leg2(v, limb, (x, y, 2.1), (x + s * 0.08, y + 0.15, 1.15), (x + s * 0.08, y + 0.15, 0.45), (x + s * 0.08, y + 0.25, 0.0), (0.58, 0.42, 0.34, 0.32), "Fur", front=True, claw="Claw", toes=5)
            v.torus(limb + "2", "Gold", V(x + s * 0.08, y + 0.15, 0.85), (0, 0, 1), 0.42, 0.09)
            v.torus(limb + "2", "Gold", V(x + s * 0.08, y + 0.15, 0.62), (0, 0, 1), 0.38, 0.07)
            v.curve(limb + "2", "Gold", [(x + s * 0.5, y + 0.15, 1.05), (x + s * 0.52, y + 0.35, 0.8), (x + s * 0.48, y + 0.15, 0.55)], [0.04, 0.04, 0.04])
        else:
            leg2(v, limb, (x, y, 2.15), (x + s * 0.06, y + 0.4, 1.25), (x + s * 0.06, y - 0.15, 0.5), (x + s * 0.06, y, 0.0), (0.6, 0.4, 0.3, 0.29), "Fur", front=False, claw="Claw", toes=5)
        shade(v, "Fur", parts={limb + "1", limb + "2", limb + "3"})
    v.joint("Tail1", (0, -2.1, 2.5), "Body", "tail")
    v.cap("Tail1", "Fur", (0, -2.1, 2.5), (0, -2.6, 2.3), 0.22, 0.1)
    ground(v)





def curl(v, part, col, c, axis, r0, r1, turns, w0, w1, n=24, start=0.0, drift=0.0):
    """a voxel spiral curl (manes, filigree, nautilus shells, ram horns): radius r0 -> r1 round axis, width w0 -> w1"""
    c = V(c); ax = V(axis).normalized(); u = ax.orthogonal().normalized(); w = ax.cross(u).normalized()
    pts, rad = [], []
    for i in range(n + 1):
        t = i / n; a = start + t * turns * math.tau; R = r0 * (r1 / r0) ** t
        pts.append(c + (u * math.cos(a) + w * math.sin(a)) * R + ax * drift * t); rad.append(w0 + (w1 - w0) * t)
    v.tube(part, col, pts, rad)
    return pts


# ---------------------------------------------------------------- PIXIU: Celestial Jade Chimera (Rare treasure hauler; B)
@pet("Pixiu", palette(form=("Jade",), Jade="#13875c", Belly="#eef2e2", Gold="#e2aa34", Mane="#f0bc48", Wing="#1ea468", Ruby="#ff3a5a",
                      Dark="#07301f", Claw="#f4ecd6", Crystal="#ff9a3a", Glow="#ffb040", Edge="#c0e8c8"))
def pixiu(v):
    v.joint("Body", (0, 0, 3.3))
    # a jade lion-dragon (magic/concepts/Pixiu_s22): a deep chest and lion's waist, a mane of golden curls, swept gold horns,
    # an open maw glowing with treasure-fire, small jade wings on gold spars, gold filigree on its flanks, a flame-tufted tail
    v.muscle("Body", "Jade", (0, 1.0, 3.45), (1.15, 1.2, 1.15))
    v.muscle("Body", "Jade", (0, -0.4, 3.4), (0.92, 1.4, 0.88))
    v.muscle("Body", "Jade", (0, -1.6, 3.45), (1.0, 0.9, 0.95))
    for s in (-1, 1):
        v.muscle("Body", "Jade", (s * 0.95, 1.15, 3.7), (0.38, 0.6, 0.72), rot=E(-15, s * -12, 0))
        v.muscle("Body", "Jade", (s * 0.72, -1.75, 3.65), (0.55, 0.72, 0.65))
        for k, y in enumerate((0.3, -0.1, -0.5)): v.muscle("Body", "Jade", (s * 0.88, y, 3.3), (0.17, 0.13, 0.62 - 0.05 * k))
    v.ell("Body", "Belly", (0, 0.4, 2.65), (0.78, 1.6, 0.42))
    shade(v, "Jade")
    for s in (-1, 1):
        q = surf(v, "Body", (0, -0.5, 3.45), (s, 0, 0.1)) or V(s * 0.9, -0.5, 3.45)
        curl(v, "Body", "Gold", q + V(s * 0.05, 0, 0), (s, 0, 0), 0.06, 0.42, 1.6, 0.05, 0.06)
        q = surf(v, "Body", (0, -1.6, 3.5), (s, 0, 0.2)) or V(s * 0.9, -1.6, 3.5)
        curl(v, "Body", "Gold", q + V(s * 0.05, 0, 0), (s, 0, 0), 0.05, 0.3, 1.4, 0.045, 0.05, start=2)
    for k in range(9):
        y = 1.5 - k * 0.42; q = surf(v, "Body", (0, y, 3.4), (0, 0, 1))
        if q: v.blade("Body", "Gold", q - V(0, 0, 0.1), q + V(0, -0.3, 0.45 - abs(k - 2) * 0.03), 0.28, thick=0.12, normal=(1, 0, 0))
    v.anchor("vault", "Body", (0, -0.6, 4.6))
    # the head and mane
    v.joint("Head", (0, 1.85, 3.95), "Body", "head")
    for k in range(22):
        a = k / 22 * math.tau
        d = V(math.cos(a), -0.45, math.sin(a) * 0.95 + 0.15).normalized()
        c = V(0, 1.95, 4.0) + d * 0.72
        curl(v, "Head", "Mane" if k % 2 else "Gold", c, (d.cross(V(0, 1, 0)) if abs(d.y) < 0.9 else V(1, 0, 0)), 0.06, 0.26, 1.3, 0.07, 0.11, n=16, start=a)
    v.ell("Head", "Mane", (0, 1.9, 4.0), (0.95, 0.55, 0.95))
    v.muscle("Head", "Jade", (0, 2.55, 4.2), (0.78, 0.82, 0.72))
    v.cap("Head", "Jade", (0, 3.0, 4.15), (0, 3.75, 3.98), 0.48, 0.38)
    v.cap("Head", "Jade", (0, 2.85, 3.62), (0, 3.6, 3.28), 0.38, 0.28)
    v.ell("Head", "Glow", (0, 3.3, 3.68), (0.3, 0.42, 0.16))
    v.ell("Head", "Gold", (0, 3.82, 4.02), (0.24, 0.12, 0.15))
    for s in (-1, 1):
        for k in range(3):
            v.cap("Head", "Claw", (s * (0.12 + 0.1 * k), 3.65 - 0.12 * k, 3.84), (s * (0.12 + 0.1 * k), 3.65 - 0.12 * k, 3.66), 0.06, 0.02)
            v.cap("Head", "Claw", (s * (0.12 + 0.1 * k), 3.5 - 0.12 * k, 3.38), (s * (0.12 + 0.1 * k), 3.5 - 0.12 * k, 3.55), 0.05, 0.02)
        v.eye("Head", (s * 0.42, 3.05, 4.42), (s * 0.7, 0.7, 0.1), w=0.24, h=0.18, iris="Ruby")
        v.cap("Head", "Gold", (s * 0.38, 2.9, 4.62), (s * 0.55, 3.25, 4.5), 0.09, 0.05)
        v.curve("Head", "Gold", [(s * 0.4, 2.35, 4.75), (s * 0.68, 1.85, 5.35), (s * 0.82, 1.2, 5.65), (s * 0.76, 0.75, 5.45)], [0.14, 0.12, 0.08, 0.03])
        v.curve("Head", "Gold", [(s * 0.66, 1.9, 5.3), (s * 0.95, 1.95, 5.7), (s * 1.05, 1.75, 5.95)], [0.07, 0.05, 0.02])
        v.curve("Head", "Mane", [(s * 0.3, 3.45, 3.25), (s * 0.4, 3.3, 2.85), (s * 0.3, 3.05, 2.55)], [0.08, 0.07, 0.03])
    shade(v, "Jade", parts={"Head"})
    v.anchor("eyes", "Head", (0, 3.2, 4.42)); v.anchor("maw", "Head", (0, 3.6, 3.6))
    # small jade wings on gold spars
    for s, w in ((-1, "WingL"), (1, "WingR")):
        root = V(s * 0.75, 0.95, 4.4)
        v.joint(w, tuple(root), "Body", "wing")
        for tx, ty, tz, wd in ((1.9, 0.3, 5.7, 0.5), (2.2, -0.3, 5.3, 0.48), (2.1, -0.85, 4.8, 0.42), (1.7, -1.2, 4.35, 0.36)):
            tip = V(s * tx, ty, tz)
            v.blade(w, "Wing", root, tip, wd, thick=0.11, normal=(0, 0.5, 1))
            v.curve(w, "Gold", [root, root.lerp(tip, 0.5) + V(0, 0.1, 0.1), tip], [0.06, 0.05, 0.02])
    for limb, x, y, front in (("LegFL", -0.75, 1.25, True), ("LegFR", 0.75, 1.25, True), ("LegBL", -0.72, -1.7, False), ("LegBR", 0.72, -1.7, False)):
        s = 1 if x > 0 else -1
        if front: hip, knee, ank, foot = (x, y, 3.0), (x + s * 0.05, y + 0.1, 1.6), (x + s * 0.05, y, 0.55), (x + s * 0.05, y + 0.1, 0.0)
        else: hip, knee, ank, foot = (x, y, 3.1), (x + s * 0.06, y + 0.45, 1.8), (x + s * 0.06, y - 0.25, 0.75), (x + s * 0.06, y - 0.1, 0.0)
        leg2(v, limb, hip, knee, ank, foot, (0.5, 0.33, 0.25, 0.24), "Jade", front=front, claw="Claw", band="Gold")
        shade(v, "Jade", parts={limb + "1", limb + "2", limb + "3"})
    pts = [V(0, -2.4, 3.8), V(0, -3.05, 4.15), V(0, -3.55, 4.7), V(0, -3.75, 5.3), V(0, -3.55, 5.8)]
    for i in range(4):
        nm = f"Tail{i + 1}"
        v.joint(nm, tuple(pts[i]), "Body" if i == 0 else f"Tail{i}", "tail")
        v.cap(nm, "Jade", pts[i], pts[i + 1], 0.22 - 0.025 * i, 0.2 - 0.025 * (i + 1))
    for k in range(7):
        a = k / 7 * math.tau
        v.blade("Tail4", "Mane" if k % 2 else "Gold", pts[4], pts[4] + V(math.cos(a) * 0.35, -0.2, 0.6 + math.sin(a) * 0.25), 0.26, thick=0.11, normal=(math.cos(a), 0, math.sin(a)))
    v.cluster("Tail4", "Crystal", pts[4], (0, -0.1, 1), 0.6, n=4, seed=2)
    v.anchor("tail", "Tail4", pts[4] + V(0, 0, 0.5))
    ground(v)


# ---------------------------------------------------------------- GLIMWISP: Spore-Lantern Nymph (Rare light spirit; A)
@pet("Glimwisp", palette(form=("Cap", "Spirit"), Cap="#6c3cbc", Spot="#ff8ad8", Gill="#f2c4ee", Spirit="#5c5c86", Root="#4a3428",
                         Leaf="#58c878", Crystal="#5ad8ff", Glow="#4af0ff", Edge="#c8b8f0"))
def glimwisp(v):
    rnd = random.Random(7)
    v.joint("Body", (0, 0, 3.4))
    # a floating mushroom spirit (magic/concepts/Glimwisp_s21): a wide glowing-spotted cap with gills underneath and crystal
    # drops hanging from its rim, a small spirit body with a cage of wooden ribs round a cyan wisp core, big glowing eyes,
    # crystal leaf wings, and four root tendrils trailing to crystal tips
    v.muscle("Body", "Spirit", (0, 0, 3.55), (0.58, 0.52, 0.75))
    v.muscle("Body", "Spirit", (0, 0.05, 4.2), (0.62, 0.6, 0.48))
    v.muscle("Body", "Spirit", (0, 0, 2.95), (0.4, 0.38, 0.4))
    shade(v, "Spirit")
    v.ell("Body", "Glow", (0, 0.32, 3.45), (0.3, 0.2, 0.36))
    for k in range(5):
        z = 3.05 + k * 0.2
        v.curve("Body", "Root", [(-0.55, -0.1, z), (-0.5, 0.45, z + 0.05), (0, 0.62, z + 0.08), (0.5, 0.45, z + 0.05), (0.55, -0.1, z)], [0.055] * 5)
    v.line("Body", "Root", [(0, 0.6, 2.95), (0, 0.66, 4.0)], r=0.07)
    for s in (-1, 1):
        v.eye("Body", (s * 0.25, 0.55, 4.25), (s * 0.4, 1, 0.05), w=0.26, h=0.3)
        v.blade("Body", "Leaf", (s * 0.4, 0, 4.4), (s * 1.0, -0.2, 4.75), 0.3, thick=0.11, normal=(0, 0.4, 1))
    v.anchor("core", "Body", (0, 0.4, 3.45)); v.anchor("eyes", "Body", (0, 0.6, 4.25))
    # the cap (its own bone so it bobs), its spots, gills, rim and hanging crystal drops
    v.joint("Cap", (0, 0, 4.55), "Body", "head")
    v.muscle("Cap", "Cap", (0, 0, 4.82), (2.05, 2.05, 1.08), cut=lambda x, y, z: z >= 4.72)
    shade(v, "Cap", parts={"Cap"})
    for k in range(16):
        a = rnd.uniform(0, math.tau); el = rnd.uniform(0.25, 1.35)
        d = V(math.cos(a) * math.cos(el), math.sin(a) * math.cos(el), math.sin(el))
        q = surf(v, "Cap", (0, 0, 4.8), d)
        if q: v.ell("Cap", "Spot", q, (0.2 + 0.08 * rnd.random(),) * 2 + (0.1,))
    for k in range(32):
        a = k / 32 * math.tau
        v.box("Cap", "Gill", V(math.cos(a) * 1.15, math.sin(a) * 1.15, 4.7), (0.07, 1.5, 0.12), rot=E(0, 0, math.degrees(a) + 90))
    v.torus("Cap", "Spot", (0, 0, 4.78), (0, 0, 1), 1.98, 0.09)
    v.cluster("Cap", "Crystal", (0, 0, 5.85), (0, 0, 1), 0.6, n=5, seed=4)
    for k in range(6):
        a = k / 6 * math.tau + 0.3
        p0 = V(math.cos(a) * 1.85, math.sin(a) * 1.85, 4.72)
        v.line("Cap", "Root", [p0, p0 + V(0, 0, -0.55)], r=0.04)
        v.ell("Cap", "Crystal", p0 + V(0, 0, -0.68), (0.1, 0.1, 0.15))
    v.anchor("visor", "Cap", (0, 0, 5.9))
    # four root tendrils trailing down to glowing crystal tips
    for j, (x, y) in enumerate(((0.3, 0.25), (-0.3, 0.25), (0.28, -0.3), (-0.28, -0.3))):
        pts = [V(x, y, 2.75), V(x * 1.6, y * 1.5, 2.15), V(x * 2.0, y * 1.9, 1.5), V(x * 1.8, y * 2.2, 0.9), V(x * 1.4, y * 2.4, 0.4)]
        pre = "Ten" + "ABCD"[j]
        for i in range(4):
            nm = f"{pre}{i + 1}"
            v.joint(nm, tuple(pts[i]), "Body" if i == 0 else f"{pre}{i}", "tentacle")
            v.cap(nm, "Root", pts[i], pts[i + 1], 0.12 - 0.02 * i, 0.1 - 0.02 * i)
            if i % 2 == 0: v.blade(nm, "Leaf", pts[i + 1], pts[i + 1] + V(x * 0.6, y * 0.6, -0.1), 0.18, thick=0.1, normal=(0, 0, 1))
        v.crystal(f"{pre}4", "Crystal", pts[4] + V(0, 0, 0.1), (0, 0, -1), 0.4, 0.1)
        v.anchor("ten" + "ABCD"[j], f"{pre}4", pts[4])


# ---------------------------------------------------------------- SELKIE: Trench-Otter Kelpie (Rare oxygen diver; A)
@pet("Selkie", palette(form=("Fur",), Fur="#1d8e9e", Belly="#b8eef2", Shell="#f4ece0", ShellRib="#d6aa98", Dark="#0c3a44",
                       Claw="#ff8aa0", Crystal="#7af0ff", Glow="#8af6ff", Edge="#c0f0ff"))
def selkie(v):
    v.joint("Body", (0, 0, 1.7))
    # a sleek sea-otter kelpie (magic/concepts/Selkie_s21): a raised chest and long body, a big spiral nautilus shell of
    # mother-of-pearl on its back with glowing tidal runes on its rim, webbed flippers with coral claws, a crystal fluke tail
    v.muscle("Body", "Fur", (0, 0.85, 2.0), (0.95, 1.0, 1.05))
    v.muscle("Body", "Fur", (0, -0.55, 1.5), (0.88, 1.25, 0.85))
    for s in (-1, 1): v.muscle("Body", "Fur", (s * 0.78, 1.05, 2.25), (0.3, 0.5, 0.55), rot=E(-20, 0, 0))
    v.ell("Body", "Belly", (0, 0.9, 1.55), (0.7, 1.05, 0.7))
    shade(v, "Fur")
    pts, rad = [], []
    C0, n = V(0, -0.35, 2.75), 60
    for i in range(n + 1):
        t = i / n; a = t * 1.35 * math.tau; R = 0.12 * (1.15 / 0.12) ** t
        pts.append(C0 + V(0, math.cos(a) * R, math.sin(a) * R)); rad.append(0.08 + 0.72 * t ** 1.3)
    v.tube("Body", "Shell", pts, rad)
    for i in range(6, n, 5):
        p, q = pts[i], pts[i - 1]; d = (p - q).normalized()
        v.torus("Body", "ShellRib", p, d, rad[i] * 0.98, 0.04)
    for i in range(30, n, 6):
        p = pts[i]; out = (p - C0); out.normalize()
        v.box("Body", "Glow", p + out * rad[i] * 0.92 + V(0.0, 0, 0), (0.6 * rad[i] + 0.1, 0.1, 0.1))
    v.anchor("shell", "Body", C0 + V(0, 0, 1.3))
    v.joint("Neck", (0, 1.45, 2.5), "Body", "neck")
    v.cap("Neck", "Fur", (0, 1.4, 2.4), (0, 1.95, 3.2), 0.6, 0.48)
    shade(v, "Fur", parts={"Neck"})
    v.joint("Head", (0, 1.95, 3.2), "Neck", "head")
    v.muscle("Head", "Fur", (0, 2.2, 3.4), (0.62, 0.6, 0.55))
    v.ell("Head", "Belly", (0, 2.72, 3.22), (0.4, 0.32, 0.3))
    v.ell("Head", "Dark", (0, 3.02, 3.32), (0.15, 0.08, 0.11))
    shade(v, "Fur", parts={"Head"})
    for s in (-1, 1):
        v.eye("Head", (s * 0.36, 2.66, 3.55), (s * 0.6, 0.8, 0.05), w=0.24, h=0.22)
        v.ell("Head", "Fur", (s * 0.5, 1.95, 3.85), (0.15, 0.1, 0.13))
        for k in range(3): v.line("Head", "Belly", [(s * 0.22, 3.0, 3.18 - 0.07 * k), (s * 0.7, 3.05, 3.12 - 0.12 * k)], r=0.03)
    v.anchor("snout", "Head", (0, 3.1, 3.3)); v.anchor("eyes", "Head", (0, 2.8, 3.55))
    for s, f in ((-1, "FlipFL"), (1, "FlipFR")):
        v.joint(f + "1", (s * 0.8, 1.2, 1.7), "Body", "arm")
        v.cap(f + "1", "Fur", (s * 0.8, 1.2, 1.7), (s * 1.15, 1.6, 0.7), 0.32, 0.24)
        v.muscle(f + "1", "Fur", (s * 0.88, 1.3, 1.45), (0.32, 0.35, 0.45))
        v.joint(f + "2", (s * 1.15, 1.6, 0.7), f + "1", "arm")
        v.blade(f + "2", "Fur", (s * 1.15, 1.6, 0.7), (s * 1.45, 2.3, 0.08), 0.62, thick=0.14, normal=(0, 0, 1))
        for k in (-1, 0, 1): v.cap(f + "2", "Claw", (s * (1.4 + 0.12 * k), 2.2 + 0.05 * k, 0.12), (s * (1.45 + 0.14 * k), 2.45, 0.05), 0.05, 0.02)
        shade(v, "Fur", parts={f + "1"})
    pts = [V(0, -1.7, 1.25), V(0, -2.4, 0.9), V(0, -3.05, 0.6), V(0, -3.55, 0.5)]
    for i in range(3):
        nm = f"Tail{i + 1}"
        v.joint(nm, tuple(pts[i]), "Body" if i == 0 else f"Tail{i}", "tail")
        v.muscle(nm, "Fur", pts[i].lerp(pts[i + 1], 0.5), (0.6 - 0.15 * i, (pts[i + 1] - pts[i]).length * 0.62, 0.5 - 0.12 * i), rot=look(pts[i + 1] - pts[i]))
        shade(v, "Fur", parts={nm})
    for s in (-1, 1):
        v.blade("Tail3", "Crystal", pts[3], pts[3] + V(s * 0.95, -0.55, 0.15), 0.5, thick=0.12, normal=(0, 0, 1))
        v.blade("Tail3", "Fur", pts[2] + V(s * 0.3, 0.1, 0), pts[2] + V(s * 0.75, -0.2, 0.05), 0.35, thick=0.12, normal=(0, 0, 1))
    v.anchor("gills", "Body", (0, 1.3, 2.9))
    ground(v)


# ---------------------------------------------------------------- ZHARBIRD: Muspell Magma Phoenix (Epic heat-proof; B)
@pet("Zharbird", palette(form=("Obsidian",), Obsidian="#2a1d24", Ember="#cc320e", Flame="#ff9c1e", Gold="#ffc43a", Dark="#120c0e",
                         Claw="#e42a2a", Crystal="#ff7a1a", Glow="#ff8a20", Edge="#ffb070"))
def zharbird(v):
    rnd = random.Random(3)
    v.joint("Body", (0, 0, 3.4))
    # an obsidian-plated phoenix raptor (magic/concepts/Zharbird_s22): a deep keeled chest cracked with magma veins under
    # layered ember feathers, long hooked wings of fire feathers, a crown of flame on a hawk head with a gold beak, long
    # scaled legs on red talons, and three molten ribbon plumes trailing behind
    v.muscle("Body", "Obsidian", (0, 0.15, 3.6), (0.78, 0.82, 1.1), rot=E(22, 0, 0))
    v.muscle("Body", "Obsidian", (0, -0.55, 3.25), (0.65, 0.75, 0.75))
    for s in (-1, 1): v.muscle("Body", "Obsidian", (s * 0.5, 0.45, 4.05), (0.4, 0.45, 0.55))
    shade(v, "Obsidian")
    v.paint("Glow", lambda x, y, z: (abs(math.sin(x * 9 + z * 5)) < 0.12) and y > 0.55, part="Body", only={"Obsidian", "ObsidianHi", "ObsidianLo"})
    for row in range(6):
        z = 4.25 - row * 0.28
        for k in range(-2, 3):
            x = k * 0.24 + (0.12 if row % 2 else 0)
            q = surf(v, "Body", (0, 0, z), (x, 1, 0)) or V(x, 0.8, z)
            v.blade("Body", "Ember" if (row + k) % 2 else "Flame", q + V(0, -0.05, 0.05), q + V(x * 0.1, 0.1, -0.45), 0.24, thick=0.1, normal=(0, 1, 0))
    v.anchor("breast", "Body", (0, 0.85, 3.6))
    v.joint("Head", (0, 0.45, 4.55), "Body", "head")
    v.cap("Head", "Obsidian", (0, 0.4, 4.4), (0, 0.75, 4.95), 0.42, 0.36)
    v.muscle("Head", "Obsidian", (0, 0.85, 5.05), (0.42, 0.52, 0.44))
    shade(v, "Obsidian", parts={"Head"})
    v.curve("Head", "Gold", [(0, 1.2, 5.05), (0, 1.65, 4.95), (0, 1.9, 4.7), (0, 1.82, 4.45)], [0.2, 0.15, 0.08, 0.03])
    for s in (-1, 1):
        v.eye("Head", (s * 0.3, 1.1, 5.12), (s * 0.7, 0.7, 0.1), w=0.2, h=0.16)
        v.cap("Head", "Gold", (s * 0.2, 1.05, 5.32), (s * 0.4, 0.7, 5.55), 0.07, 0.03)
    for k in range(9):
        a = (k - 4) * 0.22
        base = V(math.sin(a) * 0.2, 0.7 - abs(k - 4) * 0.04, 5.35)
        tip = base + V(math.sin(a) * 0.6, -0.8 - 0.1 * abs(k - 4), 0.95 - 0.12 * abs(k - 4))
        v.blade("Head", ("Flame", "Ember", "Gold")[k % 3], base, tip, 0.26, thick=0.11, normal=(math.cos(a), 0, -math.sin(a)))
    v.anchor("crest", "Head", (0, 0.4, 6.1)); v.anchor("eyes", "Head", (0, 1.2, 5.12))
    for s, w in ((-1, "WingL"), (1, "WingR")):
        sh, el, wr = V(s * 0.6, 0.2, 4.2), V(s * 1.6, -0.15, 4.85), V(s * 2.7, -0.75, 5.35)
        v.joint(w + "1", tuple(sh), "Body", "wing")
        v.cap(w + "1", "Obsidian", sh, el, 0.24, 0.16)
        for k in range(5):
            p = sh.lerp(el, 0.2 + 0.18 * k)
            v.blade(w + "1", "Ember" if k % 2 else "Obsidian", p, p + V(s * 0.15, -0.7, -0.9 + 0.05 * k), 0.3, thick=0.11, normal=(0, 0.3, 1))
        v.joint(w + "2", tuple(el), w + "1", "wing")
        v.cap(w + "2", "Obsidian", el, wr, 0.16, 0.1)
        for k in range(6):
            p = el.lerp(wr, 0.15 + 0.17 * k)
            v.blade(w + "2", ("Flame", "Ember", "Gold")[k % 3], p, p + V(s * (0.3 + 0.12 * k), -0.85 - 0.05 * k, -0.7 + 0.2 * k), 0.3, thick=0.11, normal=(0, 0.3, 1))
    for s, L in ((-1, "LegL"), (1, "LegR")):
        hip, knee, ank, foot = V(s * 0.42, -0.2, 3.0), V(s * 0.5, 0.35, 1.95), V(s * 0.5, -0.2, 0.75), V(s * 0.5, 0.05, 0.0)
        v.joint(L + "1", tuple(hip), "Body", "leg")
        v.muscle(L + "1", "Obsidian", hip.lerp(knee, 0.4), (0.42, 0.45, 0.62), over=False)
        v.cap(L + "1", "Obsidian", hip, knee, 0.32, 0.2, over=False)
        v.joint(L + "2", tuple(knee), L + "1", "leg")
        v.cap(L + "2", "Dark", knee, ank, 0.18, 0.13)
        for k in range(5): v.torus(L + "2", "Ember", knee.lerp(ank, 0.15 + 0.17 * k), (ank - knee).normalized(), 0.16, 0.03)
        v.joint(L + "3", tuple(ank), L + "2", "leg")
        v.cap(L + "3", "Dark", ank, foot + V(0, 0, 0.15), 0.13, 0.12)
        foot_talon(v, L + "3", foot, 0.13, "Dark", "Claw")
        shade(v, "Obsidian", parts={L + "1"})
        v.anchor("foot" + L[3:], L + "3", foot + V(0, 0.1, 0.25))
    for j, x in enumerate((-0.25, 0.0, 0.25)):
        pre = "Plume" + "ABC"[j]
        pts = [V(x, -0.7, 3.05), V(x * 1.6, -1.6, 2.7), V(x * 2.2, -2.5, 2.55), V(x * 2.4, -3.3, 2.8), V(x * 2.0, -3.9, 3.3)]
        for i in range(4):
            nm = f"{pre}{i + 1}"
            v.joint(nm, tuple(pts[i]), "Body" if i == 0 else f"{pre}{i}", "tail")
            v.cap(nm, "Ember" if i < 2 else "Flame", pts[i], pts[i + 1], 0.15 - 0.025 * i, 0.13 - 0.025 * i)
            v.blade(nm, "Flame" if i % 2 else "Gold", pts[i + 1], pts[i + 1] + V(x * 0.4, -0.25, 0.4), 0.22, thick=0.1, normal=(1, 0, 0))
        v.anchor("plume" + "ABC"[j], f"{pre}4", pts[4])
    ground(v)





def tri(v, part, col, a, b, c, thick=0.12):
    """a thin flat triangle (wing membranes)"""
    a, b, c = V(a), V(b), V(c); n = (b - a).cross(c - a)
    if n.length < 1e-9: return
    n.normalize(); e0, e1 = b - a, c - a
    d00, d01, d11 = e0.dot(e0), e0.dot(e1), e1.dot(e1); den = d00 * d11 - d01 * d01
    def inside(x, y, z):
        p = V(x, y, z) - a
        if abs(p.dot(n)) > thick / 2: return False
        d20, d21 = p.dot(e0), p.dot(e1)
        vv = (d11 * d20 - d01 * d21) / den; ww = (d00 * d21 - d01 * d20) / den
        return vv >= 0 and ww >= 0 and vv + ww <= 1
    lo = V(min(a.x, b.x, c.x), min(a.y, b.y, c.y), min(a.z, b.z, c.z)) - V(0.2, 0.2, 0.2)
    hi = V(max(a.x, b.x, c.x), max(a.y, b.y, c.y), max(a.z, b.z, c.z)) + V(0.2, 0.2, 0.2)
    v.fill(part, col, lo, hi, inside)


def lotus(v, part, c, normal, r, n, col, col2, heart="Glow"):
    c, nr = V(c), V(normal).normalized(); u = nr.orthogonal().normalized(); w = nr.cross(u)
    for L in range(2):
        for k in range(n):
            a = math.tau * (k + 0.5 * L) / n; rad = u * math.cos(a) + w * math.sin(a)
            v.blade(part, col2 if L else col, c + rad * r * 0.1, c + rad * r * (1.0 - 0.35 * L) + nr * r * (0.5 + 0.4 * L), r * 0.45, thick=0.1, normal=rad.cross(nr))
    v.ell(part, heart, c + nr * r * 0.15, (r * 0.22,) * 3)


def bat_wing(v, w, sh, wrist, tips, spar, membrane, root_back, thick=0.12):
    """a two-bone bat wing: w1 the arm (shoulder -> wrist), w2 the hand with finger spars to each tip; membrane triangles
    between consecutive spars and from the last spar back to the flank"""
    sh, wrist = V(sh), V(wrist)
    v.joint(w + "1", tuple(sh), "Body", "wing"); v.cap(w + "1", spar, sh, wrist, 0.22, 0.15)
    v.joint(w + "2", tuple(wrist), w + "1", "wing")
    prev = None
    for t in tips:
        t = V(t); v.cap(w + "2", spar, wrist, t, 0.12, 0.05)
        if prev is not None: tri(v, w + "2", membrane, wrist, prev, t, thick)
        prev = t
    tri(v, w + "1", membrane, sh, wrist, V(tips[-1]), thick)
    tri(v, w + "1", membrane, sh, V(tips[-1]), V(root_back), thick)
    v.cap(w + "2", "Claw", wrist, wrist + (wrist - sh).normalized() * 0.1 + V(0, 0.15, 0.45), 0.1, 0.03)


# ---------------------------------------------------------------- FAFNIR: Bastion Amethyst Drake (Legendary hoard drake; B)
@pet("Fafnir", palette(form=("Stone",), Stone="#4c5262", Plate="#6c7488", PlateRim="#3a3e4c", Dark="#22252e", Horn="#c0905c",
                       Wing="#5e2e9e", Claw="#ece0c8", Crystal="#ac6cff", Glow="#ffb02a", Edge="#b8b0d8"))
def fafnir(v):
    nz = noise(11)
    v.joint("Body", (0, 0, 3.9))
    # a granite drake (magic/concepts/Fafnir_s22): a massive chest and shoulders, slabbed stone plates down its back with
    # amethyst geodes bursting through, molten-gold veins glowing in the cracks, curled ram horns, purple bat wings on stone
    # spars, pillar legs with ivory claws, a spiked tail ending in a geode mace
    v.muscle("Body", "Stone", (0, 1.15, 4.05), (1.6, 1.5, 1.45))
    v.muscle("Body", "Stone", (0, -0.6, 3.9), (1.35, 1.75, 1.2))
    v.muscle("Body", "Stone", (0, -2.05, 3.95), (1.3, 1.0, 1.15))
    for s in (-1, 1):
        v.muscle("Body", "Stone", (s * 1.3, 1.3, 4.4), (0.5, 0.75, 0.9), rot=E(-15, s * -12, 0))
        v.muscle("Body", "Stone", (s * 1.0, -2.2, 4.15), (0.7, 0.8, 0.75))
        for k, y in enumerate((0.35, -0.15, -0.65, -1.15)): v.muscle("Body", "Stone", (s * 1.25, y, 3.75), (0.22, 0.16, 0.8 - 0.05 * k))
    v.ell("Body", "Plate", (0, 0.2, 2.75), (1.05, 1.9, 0.48))
    v.paint("PlateRim", lambda x, y, z: (y % 0.42) < 0.08, part="Body", only={"Plate"})
    shade(v, "Stone")
    v.paint("Glow", lambda x, y, z: nz(x, y, z, 0.35) > 0.74 and 3.2 < z < 4.6, part="Body", only={"StoneCrease", "StoneLo"})
    scales(v, "Body", (0, 2.2, 4.2), (0, -2.8, 4.0), rows=10, arc=(-55, 55), size=0.42, col="Plate", rim="PlateRim")
    for (x, y, z, sz) in ((0, 1.2, 5.6, 1.4), (0.7, 0.2, 5.3, 1.0), (-0.65, -0.5, 5.25, 1.1), (0.2, -1.4, 5.1, 1.2), (1.35, 1.25, 5.1, 0.8), (-1.35, 1.25, 5.1, 0.8)):
        q = surf(v, "Body", (x * 0.6, y, 3.9), (x * 0.5, 0, 1)) or V(x, y, z)
        v.cluster("Body", "Crystal", q - V(0, 0, 0.15), (x * 0.4, -0.2, 1), sz, n=6, seed=int(sz * 10 + y * 3))
    v.anchor("chest", "Body", (0, 2.4, 3.8)); v.anchor("back", "Body", (0, 0.4, 6.4))
    # neck and head
    v.joint("Neck", (0, 2.2, 4.6), "Body", "neck")
    v.cap("Neck", "Stone", (0, 2.1, 4.5), (0, 3.05, 5.45), 0.9, 0.72)
    for s in (-1, 1): v.muscle("Neck", "Stone", (s * 0.45, 2.6, 5.0), (0.45, 0.6, 0.65), rot=E(40, 0, 0))
    scales(v, "Neck", (0, 3.0, 5.6), (0, 2.1, 4.9), rows=3, arc=(-60, 60), size=0.36, col="Plate", rim="PlateRim")
    shade(v, "Stone", parts={"Neck"})
    v.joint("Head", (0, 3.05, 5.45), "Neck", "head")
    v.muscle("Head", "Stone", (0, 3.5, 5.65), (0.88, 0.95, 0.76))
    v.cap("Head", "Stone", (0, 3.95, 5.5), (0, 4.95, 5.2), 0.56, 0.42)
    v.cap("Head", "Dark", (0, 3.75, 5.0), (0, 4.7, 4.78), 0.46, 0.32)
    shade(v, "Stone", parts={"Head"})
    for s in (-1, 1):
        for k in range(4):
            q = V(s * (0.18 + 0.1 * k), 4.85 - 0.18 * k, 5.0)
            v.cap("Head", "Claw", q, q + V(0, 0, -0.22), 0.06, 0.02)
        v.eye("Head", (s * 0.52, 4.05, 5.85), (s * 0.7, 0.7, 0.1), w=0.26, h=0.18)
        v.box("Head", "Glow", (s * 0.16, 5.02, 5.32), (0.1, 0.1, 0.1))
        v.curve("Head", "Horn", [(s * 0.6, 3.25, 6.15), (s * 1.0, 2.75, 6.55), (s * 1.5, 2.45, 6.15), (s * 1.65, 2.75, 5.5), (s * 1.5, 3.3, 5.3), (s * 1.3, 3.5, 5.62)], [0.34, 0.3, 0.24, 0.17, 0.1, 0.04])
        v.cluster("Head", "Crystal", (s * 0.3, 3.4, 6.2), (s * 0.3, -0.3, 1), 0.5, n=3, seed=5)
    v.anchor("snout", "Head", (0, 5.05, 5.3)); v.anchor("eyes", "Head", (0, 4.15, 5.85))
    for s, w in ((-1, "WingL"), (1, "WingR")):
        bat_wing(v, w, (s * 1.2, 0.9, 5.2), (s * 3.0, 0.2, 6.7), [(s * 4.5, -0.5, 6.3), (s * 4.3, -1.5, 5.3), (s * 3.5, -2.2, 4.5), (s * 2.2, -2.1, 4.4)], "Stone", "Wing", (s * 1.1, -1.4, 4.6))
        v.cluster(w + "2", "Crystal", (s * 3.0, 0.2, 6.75), (s * 0.3, 0.2, 1), 0.55, n=3, seed=6)
    for limb, x, y, front in (("LegFL", -1.25, 1.4, True), ("LegFR", 1.25, 1.4, True), ("LegBL", -1.15, -2.05, False), ("LegBR", 1.15, -2.05, False)):
        s = 1 if x > 0 else -1
        if front: hip, knee, ank, foot = (x, y, 3.55), (x + s * 0.12, y + 0.15, 1.95), (x + s * 0.12, y + 0.05, 0.68), (x + s * 0.12, y + 0.15, 0.0)
        else: hip, knee, ank, foot = (x, y, 3.6), (x + s * 0.12, y + 0.5, 2.1), (x + s * 0.12, y - 0.25, 0.85), (x + s * 0.12, y - 0.1, 0.0)
        leg2(v, limb, hip, knee, ank, foot, (0.78, 0.55, 0.44, 0.42), "Stone", front=front, claw="Claw", toes=4)
        shade(v, "Stone", parts={limb + "1", limb + "2", limb + "3"})
    pts = [V(0, -2.9, 4.05), V(0, -3.7, 3.5), V(0, -4.45, 2.8), V(0, -5.1, 2.0), V(0, -5.6, 1.3), V(0, -6.05, 0.9), V(0, -6.45, 0.8)]
    rad = [0.78, 0.64, 0.52, 0.42, 0.33, 0.26, 0.2]
    for i in range(6):
        nm = f"Tail{i + 1}"
        v.joint(nm, tuple(pts[i]), "Body" if i == 0 else f"Tail{i}", "tail")
        v.cap(nm, "Stone", pts[i], pts[i + 1], rad[i], rad[i + 1])
        v.crystal(nm, "Crystal", pts[i] + V(0, -0.1, rad[i] * 0.8), (0, -0.4, 1), 0.5 + 0.2 * rad[i], 0.12)
        shade(v, "Stone", parts={nm})
    v.ell("Tail6", "Stone", pts[6], (0.62, 0.62, 0.58))
    for d in ((1, 0, 0.3), (-1, 0, 0.3), (0, -1, 0.2), (0, 0, 1), (0.7, -0.6, -0.2), (-0.7, -0.6, -0.2)):
        v.crystal("Tail6", "Crystal", pts[6] + V(d).normalized() * 0.45, d, 0.6, 0.13)
    v.anchor("tail", "Tail6", pts[6])
    ground(v)


# ---------------------------------------------------------------- KIRIN: Sacred Lotus Qilin (Legendary cleanser; B)
@pet("Kirin", palette(form=("Pearl",), Pearl="#e8e4f2", Scale="#d2caee", ScaleRim="#a89cd8", Pink="#ff74b4", PinkLight="#ffbadc",
                      Gold="#e8c050", Hoof="#22a46c", Claw="#22a46c", Petal="#ff9ad2", Crystal="#ff8ac4", Glow="#ff6cc0", Edge="#f0d8f0"))
def kirin(v):
    v.joint("Body", (0, 0, 3.95))
    # a pearl-scaled qilin (magic/concepts/Kirin_s22): a deer's long legs on jade hooves, a scaled back, a long neck under a
    # flowing pink mane, rose-quartz antlers that bloom into lotus flowers, dragon whiskers, pink shoulder fins and silk
    # ribbons trailing from its shoulders
    v.muscle("Body", "Pearl", (0, 0.95, 4.1), (0.85, 0.95, 0.95))
    v.muscle("Body", "Pearl", (0, -0.2, 4.05), (0.72, 1.2, 0.75))
    v.muscle("Body", "Pearl", (0, -1.3, 4.1), (0.8, 0.85, 0.85))
    for s in (-1, 1):
        v.muscle("Body", "Pearl", (s * 0.7, 1.05, 4.35), (0.3, 0.55, 0.62), rot=E(-15, s * -10, 0))
        v.muscle("Body", "Pearl", (s * 0.58, -1.45, 4.3), (0.45, 0.62, 0.6))
    shade(v, "Pearl")
    scales(v, "Body", (0, 1.6, 4.3), (0, -1.9, 4.2), rows=12, arc=(-70, 70), size=0.22, col="Scale", rim="ScaleRim")
    for k in range(10):
        y = 1.3 - k * 0.32; q = surf(v, "Body", (0, y, 4.0), (0, 0, 1))
        if q: v.blade("Body", "Pink" if k % 2 else "PinkLight", q - V(0, 0, 0.05), q + V(0, -0.45, 0.35), 0.24, thick=0.1, normal=(1, 0, 0))
    v.anchor("back", "Body", (0, -0.2, 5.3))
    v.joint("Neck", (0, 1.4, 4.45), "Body", "neck")
    v.cap("Neck", "Pearl", (0, 1.35, 4.35), (0, 2.0, 5.65), 0.5, 0.36)
    for k in range(9):
        t = k / 8; q = V(0, 1.3 + 0.62 * t, 4.65 + 1.15 * t)
        for s in (-1, 1):
            v.blade("Neck", "Pink" if (k + (s > 0)) % 2 else "PinkLight", q + V(s * 0.05, -0.1, 0), q + V(s * 0.45, -0.75, -0.25), 0.3, thick=0.1, normal=(s, 0.2, 0.4))
    shade(v, "Pearl", parts={"Neck"})
    v.joint("Head", (0, 2.0, 5.65), "Neck", "head")
    v.muscle("Head", "Pearl", (0, 2.3, 5.85), (0.48, 0.6, 0.46))
    v.cap("Head", "Pearl", (0, 2.6, 5.8), (0, 3.3, 5.55), 0.3, 0.2)
    v.box("Head", "Pink", (0, 3.38, 5.58), (0.12, 0.08, 0.08))
    shade(v, "Pearl", parts={"Head"})
    for s in (-1, 1):
        v.eye("Head", (s * 0.3, 2.62, 6.02), (s * 0.7, 0.7, 0.1), w=0.2, h=0.16)
        v.blade("Head", "Pearl", (s * 0.32, 2.05, 6.15), (s * 0.72, 1.8, 6.4), 0.24, thick=0.1, normal=(s * 0.3, 1, 0))
        v.curve("Head", "Pink", [(s * 0.18, 3.2, 5.55), (s * 0.6, 3.3, 5.5), (s * 0.9, 3.0, 5.2), (s * 1.0, 2.6, 5.35)], [0.04, 0.035, 0.03, 0.02])
        A = [V(s * 0.22, 2.15, 6.25), V(s * 0.45, 1.95, 6.85), V(s * 0.68, 1.65, 7.4), V(s * 0.78, 1.3, 7.8)]
        v.curve("Head", "Crystal", A, [0.1, 0.09, 0.07, 0.05])
        for i, d in ((1, V(s * 0.45, 0.25, 0.35)), (2, V(s * 0.4, 0.1, 0.4))):
            v.curve("Head", "Crystal", [A[i], A[i] + d * 0.6, A[i] + d], [0.06, 0.05, 0.035])
            lotus(v, "Head", A[i] + d, (d.x * 0.4, 0.1, 1), 0.3, 6, "Petal", "PinkLight")
        lotus(v, "Head", A[3], (s * 0.3, -0.2, 1), 0.34, 6, "Petal", "PinkLight")
    v.anchor("antlers", "Head", (0, 1.7, 7.5)); v.anchor("eyes", "Head", (0, 2.7, 6.0))
    for s, w in ((-1, "FinL"), (1, "FinR")):
        v.joint(w, (s * 0.65, 1.0, 4.6), "Body", "wing")
        for k in range(3):
            v.blade(w, "Pink" if k % 2 else "PinkLight", (s * 0.65, 1.0, 4.6), (s * (1.5 - 0.15 * k), 0.4 - 0.45 * k, 5.4 - 0.2 * k), 0.36, thick=0.1, normal=(0, 0.3, 1))
    for limb, x, y, front in (("LegFL", -0.46, 1.05, True), ("LegFR", 0.46, 1.05, True), ("LegBL", -0.5, -1.35, False), ("LegBR", 0.5, -1.35, False)):
        s = 1 if x > 0 else -1
        if front: hip, knee, ank, foot = (x, y, 3.7), (x + s * 0.03, y + 0.1, 2.25), (x + s * 0.03, y, 0.78), (x + s * 0.03, y + 0.08, 0.0)
        else: hip, knee, ank, foot = (x, y, 3.8), (x + s * 0.04, y + 0.45, 2.55), (x + s * 0.04, y - 0.25, 1.1), (x + s * 0.04, y - 0.12, 0.0)
        leg2(v, limb, hip, knee, ank, foot, (0.38, 0.21, 0.15, 0.15), "Pearl", front=front, kind="hoof", hoof="Hoof", band="Gold")
        shade(v, "Pearl", parts={limb + "1", limb + "2"})
        a = V(ank)
        for k in range(6):
            ang = k / 6 * math.tau
            v.blade(limb + "3", "PinkLight", a + V(math.cos(ang) * 0.1, math.sin(ang) * 0.1, -0.25), a + V(math.cos(ang) * 0.3, math.sin(ang) * 0.3 - 0.1, -0.6), 0.16, thick=0.1, normal=(math.sin(ang), -math.cos(ang), 0))
    pts = [V(0, -2.0, 4.4), V(0, -2.55, 4.3), V(0, -2.95, 3.85), V(0, -3.15, 3.3)]
    for i in range(3):
        nm = f"Tail{i + 1}"
        v.joint(nm, tuple(pts[i]), "Body" if i == 0 else f"Tail{i}", "tail")
        v.cap(nm, "Pearl", pts[i], pts[i + 1], 0.16 - 0.03 * i, 0.13 - 0.03 * i)
    for k in range(7):
        a = k / 7 * math.tau
        v.blade("Tail3", "Pink" if k % 2 else "PinkLight", pts[3] + V(0, 0, 0.1), pts[3] + V(math.cos(a) * 0.35, -0.3, -0.6 + math.sin(a) * 0.2), 0.24, thick=0.1, normal=(math.cos(a), 0, math.sin(a)))
    for s, r in ((-1, "RibbonL"), (1, "RibbonR")):
        pts = [V(s * 0.6, 0.8, 4.75), V(s * 0.9, -0.3, 5.25), V(s * 1.0, -1.5, 4.9), V(s * 0.8, -2.6, 5.3)]
        for i in range(3):
            nm = f"{r}{i + 1}"
            v.joint(nm, tuple(pts[i]), "Body" if i == 0 else f"{r}{i}", "tail")
            v.blade(nm, "Pink", pts[i], pts[i + 1], 0.32, thick=0.1, normal=(0, 0.2, 1), bend=0.12 * (1 if i % 2 else -1))
    ground(v)


# ---------------------------------------------------------------- OURO: World-Tree Infinity Wyrm (Mythic all-rounder; A)
@pet("Ouro", palette(form=("Scale",), Scale="#26457e", Belly="#eaa22a", Crest="#ff8a2a", Gold="#e2b452", Wing="#c8507c", Dark="#101a30",
                     Claw="#f0e6d6", Crystal="#c8f2ff", Glow="#b070ff", Edge="#a8c0f0"))
def ouro(v):
    # a coiled world-tree wyrm (magic/concepts/Ouro_s21): a long serpent body lying in a spiral coil with a gold belly and an
    # orange crest, the neck rising tall to a horned dragon head with gold antlers and whiskers, pink bat wings at the
    # shoulders, and six prism crystals floating round it on their own spinning bone
    N = 13
    pts = []
    for i in range(N + 1):
        t = i / N; th = t * math.tau * 1.25; R = 1.85 - 1.2 * t
        pts.append(V(R * math.sin(th), R * math.cos(th) - 0.25, 0.62 - 0.12 * t))
    rad = [0.62 - 0.44 * (i / N) for i in range(N + 1)]
    v.joint("Body", tuple(pts[0]), None)
    v.cap("Body", "Scale", pts[0] + V(0, 0, 0.1), pts[1], rad[0], rad[1])
    v.muscle("Body", "Scale", pts[0] + V(0, 0, 0.35), (0.7, 0.7, 0.6))
    for i in range(1, N):
        nm = f"Tail{i}"
        v.joint(nm, tuple(pts[i]), "Body" if i == 1 else f"Tail{i - 1}", "tail")
        v.muscle(nm, "Scale", pts[i].lerp(pts[i + 1], 0.5), (rad[i] * 1.05, (pts[i + 1] - pts[i]).length * 0.7, rad[i] * 1.0), rot=look(pts[i + 1] - pts[i]))
        q = pts[i].lerp(pts[i + 1], 0.5)
        v.blade(nm, "Crest", q + V(0, 0, rad[i] * 0.8), q + V(0, 0, rad[i] * 0.8 + 0.35) - (pts[i + 1] - pts[i]).normalized() * 0.25, 0.22, thick=0.1, normal=(pts[i + 1] - pts[i]).cross(V(0, 0, 1)))
    v.cap(f"Tail{N - 1}", "Gold", pts[N], pts[N] + (pts[N] - pts[N - 1]).normalized() * 0.4, 0.15, 0.03)
    for i in range(N):
        nm = "Body" if i == 0 else f"Tail{i}"
        cz = pts[i].z
        v.paint("Belly", lambda x, y, z, cz=cz: z < cz - 0.05, part=nm, only={"Scale"})
    shade(v, "Scale", parts={"Body"} | {f"Tail{i}" for i in range(1, N)})
    v.anchor("coil", "Body", (0, -0.25, 1.4))
    # the neck rising from the front of the coil, and the head
    npts = [pts[0] + V(0, 0, 0.2), V(0, 1.85, 1.75), V(0, 1.55, 2.85), V(0, 1.75, 3.75)]
    for i in range(3):
        nm = f"Neck{i + 1}"
        v.joint(nm, tuple(npts[i]), "Body" if i == 0 else f"Neck{i}", "neck")
        v.muscle(nm, "Scale", npts[i].lerp(npts[i + 1], 0.5), (0.52 - 0.04 * i, (npts[i + 1] - npts[i]).length * 0.66, 0.5 - 0.04 * i), rot=look(npts[i + 1] - npts[i]))
        v.paint("Belly", lambda x, y, z: y > npts[i].lerp(npts[i + 1], 0.5).y + 0.2, part=nm, only={"Scale"})
        v.blade(nm, "Crest", npts[i] + V(0, -0.35, 0.2), npts[i] + V(0, -0.85, 0.55), 0.3, thick=0.1, normal=(1, 0, 0))
        shade(v, "Scale", parts={nm})
    v.joint("Head", tuple(npts[3]), "Neck3", "head")
    v.muscle("Head", "Scale", (0, 2.0, 3.95), (0.5, 0.62, 0.46))
    v.cap("Head", "Scale", (0, 2.3, 3.9), (0, 3.05, 3.7), 0.36, 0.26)
    v.cap("Head", "Belly", (0, 2.25, 3.55), (0, 2.95, 3.38), 0.28, 0.2)
    shade(v, "Scale", parts={"Head"})
    for s in (-1, 1):
        v.eye("Head", (s * 0.34, 2.45, 4.12), (s * 0.7, 0.7, 0.1), w=0.22, h=0.16)
        A = [V(s * 0.25, 1.85, 4.3), V(s * 0.5, 1.6, 4.85), V(s * 0.75, 1.25, 5.25), V(s * 0.8, 0.9, 5.45)]
        v.curve("Head", "Gold", A, [0.1, 0.09, 0.06, 0.03])
        for i, d in ((1, V(s * 0.4, 0.3, 0.3)), (2, V(s * 0.35, 0.05, 0.4))):
            v.curve("Head", "Gold", [A[i], A[i] + d], [0.05, 0.025])
        v.curve("Head", "Gold", [(s * 0.22, 3.0, 3.6), (s * 0.7, 3.2, 3.5), (s * 1.1, 2.95, 3.1), (s * 1.25, 2.6, 2.85)], [0.04, 0.035, 0.03, 0.02])
        for k in range(3):
            v.blade("Head", "Crest", (s * 0.3, 1.7, 4.0 - 0.15 * k), (s * (0.75 + 0.1 * k), 1.25, 4.15 - 0.25 * k), 0.24, thick=0.1, normal=(0, 0.3, 1))
    v.anchor("eyes", "Head", (0, 2.55, 4.1)); v.anchor("gem", "Head", (0, 1.9, 4.55))
    for s, w in ((-1, "WingL"), (1, "WingR")):
        bat_wing(v, w, (s * 0.45, 1.75, 2.3), (s * 1.9, 1.3, 3.5), [(s * 3.0, 0.7, 3.3), (s * 2.9, -0.1, 2.6), (s * 2.3, -0.5, 2.0), (s * 1.3, 0.2, 1.7)], "Scale", "Wing", (s * 0.6, 1.0, 1.6))
    # six prism crystals on a bone of their own that spins round the wyrm
    v.joint("Orbit", (0, -0.25, 2.2), "Body", "ring"); v.axis("Orbit", (0, 0, 1))
    for k in range(6):
        a = k / 6 * math.tau
        c = V(math.cos(a) * 2.7, -0.25 + math.sin(a) * 2.7, 1.6 + 0.9 * (k % 3))
        v.cluster("Orbit", "Crystal", c, (math.cos(a) * 0.3, math.sin(a) * 0.3, 1), 0.7, n=4, seed=k + 1)
    ground(v)


# ---------------------------------------------------------------- NINERING: Sovereign Chrono-Relic (Secret ore copier; B)
@pet("Ninering", palette(Gold="#e2a634", Dark="#1c1c36", Void="#0a0a18", Head="#24243c", Horn="#ffd04a", Claw="#ffd04a",
                         Crystal="#7ae8ff", Glow="#38d8ff", Edge="#f0d890"))
def ninering(v):
    C = V(0, 0, 3.45)
    v.joint("Body", tuple(C), None)
    # a living astrolabe (magic/concepts/Ninering_s22): nine counter-rotating rings of gold and dark enamel set with glowing
    # crystal gems round a void disc with a gold star and a crystal heart, a horned void-dragon head crowning it, and two gold
    # claws gripping the outer ring
    v.ell("Body", "Void", C, (0.85, 0.22, 0.85))
    for k in range(8):
        a = k / 8 * math.tau
        d = V(math.cos(a), 0, math.sin(a))
        v.blade("Body", "Gold", C + V(0, 0.18, 0), C + V(0, 0.18, 0) + d * (0.75 if k % 2 == 0 else 0.5), 0.22, thick=0.1, normal=(0, 1, 0))
    v.ell("Body", "Glow", C + V(0, 0.25, 0), (0.22, 0.14, 0.22))
    v.anchor("core", "Body", C + V(0, 0.35, 0))
    for i in range(9):
        R = 1.05 + 0.25 * i
        nm = f"Ring{i + 1}"
        tilt = math.radians(5 + 2.5 * i); az = i * 2.35
        nrm = V(math.sin(tilt) * math.cos(az), math.cos(tilt), math.sin(tilt) * math.sin(az))
        v.joint(nm, tuple(C), "Body", "ring"); v.axis(nm, tuple(nrm))
        col = "Gold" if i % 2 == 0 else "Dark"
        v.torus(nm, col, C, nrm, R, 0.09 + 0.006 * i)
        u = nrm.orthogonal().normalized(); w = nrm.cross(u)
        gems = 4 + i
        for k in range(gems):
            a = k / gems * math.tau + i
            q = C + (u * math.cos(a) + w * math.sin(a)) * R
            v.box(nm, "Glow" if (k + i) % 2 == 0 else "Crystal", q + nrm * 0.08, (0.14, 0.14, 0.14))
        if i == 8:
            for k in range(16):
                a = k / 16 * math.tau
                rd = u * math.cos(a) + w * math.sin(a)
                v.crystal(nm, "Gold", C + rd * (R + 0.05), rd, 0.35, 0.08, sides=4)
    # the crowning dragon head on its own bone above the rings
    v.joint("Head", (0, 0, 6.0), "Body", "head")
    v.cap("Head", "Head", (0, 0, 5.75), (0, 0.15, 6.35), 0.42, 0.42)
    v.ell("Head", "Head", (0, 0.35, 6.45), (0.5, 0.6, 0.45))
    v.cap("Head", "Head", (0, 0.7, 6.4), (0, 1.3, 6.25), 0.32, 0.22)
    for s in (-1, 1):
        v.eye("Head", (s * 0.3, 0.78, 6.6), (s * 0.7, 0.7, 0.1), w=0.22, h=0.16)
        v.curve("Head", "Horn", [(s * 0.3, 0.2, 6.75), (s * 0.7, -0.15, 7.15), (s * 0.95, -0.55, 7.25), (s * 1.0, -0.85, 7.05)], [0.13, 0.1, 0.06, 0.03])
        v.cap("Head", "Horn", (s * 0.42, 0.45, 6.15), (s * 0.95, 0.4, 5.85), 0.08, 0.02)
    v.crystal("Head", "Crystal", (0, 0.2, 6.85), (0, -0.2, 1), 0.6, 0.12)
    v.anchor("eyes", "Head", (0, 0.85, 6.6))
    for s, a in ((-1, "ArmL"), (1, "ArmR")):
        sh, el, wr = V(s * 1.1, 0.35, 2.3), V(s * 2.1, 0.45, 1.6), V(s * 2.65, 0.4, 1.15)
        v.joint(a + "1", tuple(sh), "Body", "arm"); v.cap(a + "1", "Head", sh, el, 0.18, 0.15)
        v.joint(a + "2", tuple(el), a + "1", "arm"); v.cap(a + "2", "Head", el, wr, 0.15, 0.13)
        for k in (-1, 0, 1):
            d = V(s * 0.2, 0.15 * k + 0.1, -0.55).normalized()
            v.cap(a + "2", "Claw", wr, wr + d * 0.5, 0.08, 0.03)
    ground(v)



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
