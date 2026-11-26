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
CELL = {"Fafnir": 0.12}  # v16.1 round 2 (Gemini: 99k triangles of micro-voxel static): the biggest pet in chunkier cells


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
    v.cap("Head", "Bark", (0, 3.3, 2.85), (0, 4.3, 2.6), 0.66, 0.52)
    v.ell("Head", "Snout", (0, 4.38, 2.68), (0.52, 0.16, 0.42), rot=E(-15, 0, 0))
    v.ell("Head", "Dark", (0, 3.65, 2.35), (0.48, 0.85, 0.3))
    v.ell("Head", "Moss", (0, 2.6, 3.6), (0.85, 0.75, 0.58), cut=lambda x, y, z: z > 3.75 + nz(x, y, z) * 0.25)
    for s in (-1, 1):
        v.ell("Head", "Dark", (s * 0.17, 4.5, 2.7), (0.09, 0.08, 0.13))
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
        TK = [(s * 0.4, 3.95, 2.35), (s * 0.78, 4.45, 2.75), (s * 1.05, 4.6, 3.35), (s * 1.08, 4.3, 3.95), (s * 0.85, 3.85, 4.25)]
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
    v.muscle("Body", "Clay", (0, 0.8, 3.55), (1.45, 1.25, 1.35))
    v.muscle("Body", "Clay", (0, -0.55, 2.95), (1.15, 1.45, 1.02))
    v.muscle("Body", "Clay", (0, -1.65, 2.8), (1.02, 0.85, 0.92))
    v.muscle("Body", "Clay", (0, 0.45, 4.05), (1.0, 1.1, 0.6))
    for s in (-1, 1):
        v.muscle("Body", "Clay", (s * 1.2, 1.15, 3.85), (0.5, 0.66, 0.78), rot=E(-15, s * -12, 0))
        v.ell("Body", "Tile", (s * 1.25, 1.0, 4.45), (0.75, 0.8, 0.35), rot=E(0, s * 20, 0))
        for k in range(3):
            v.crystal("Body", "Claw", V(s * (1.0 + 0.3 * k), 1.25 - 0.25 * k, 4.65), (s * 0.4, -0.2, 1), 0.55 - 0.08 * k, 0.12, sides=4)
        v.line("Body", "Glow", [(s * 1.55, 1.25, 4.5), (s * 1.75, 0.75, 4.35)], r=0.06)
    v.ell("Body", "Shale", (0, 0.35, 2.25), (0.85, 1.55, 0.42))
    v.paint("Dark", lambda x, y, z: (y % 0.36) < 0.07, part="Body", only={"Shale"})
    shade(v, "Clay")
    scales(v, "Body", (0, 1.7, 3.3), (0, -2.15, 2.9), rows=11, arc=(-100, 100), size=0.36, col="Tile", rim="TileRim")
    v.paint("Glow", lambda x, y, z: nz(x, y, z, 0.3) > 0.58 and z > 3.1, part="Body", only={"TileRim"})
    for st in ([(0, 1.62, 2.0), (0, 1.62, 2.75)], [(0, 1.62, 2.55), (0.3, 1.55, 2.75)], [(0, 1.62, 2.55), (-0.3, 1.55, 2.75)], [(0, 1.62, 2.2), (0.25, 1.58, 2.05)], [(0, 1.62, 2.2), (-0.25, 1.58, 2.05)]):
        v.line("Body", "Glow", st, r=0.06)
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
        v.eye("Head", (s * 0.48, 2.98, 3.12), (s * 0.8, 0.6, 0.0), w=0.34, h=0.24)
        v.curve("Head", "Claw", [(s * 0.62, 2.15, 3.75), (s * 0.95, 1.85, 4.2), (s * 1.05, 1.35, 4.45), (s * 0.95, 1.05, 4.3)], [0.13, 0.11, 0.07, 0.03])
        v.blade("Head", "Clay", (s * 0.72, 2.1, 3.4), (s * 1.15, 1.85, 3.6), 0.3, thick=0.12, normal=(0, 0.3, 1))
    v.anchor("eyes", "Head", (0, 3.15, 3.1))
    # long armoured forelimbs on spade-clawed knuckles; shorter hind legs
    for s in (-1, 1):
        L = "ArmL" if s < 0 else "ArmR"
        leg2(v, L, (s * 1.25, 1.35, 3.6), (s * 1.6, 1.5, 2.25), (s * 1.5, 2.05, 0.75), (s * 1.5, 2.25, 0.0), (0.6, 0.46, 0.36, 0.34), "Clay", front=True, claw="Claw", toes=3, group="leg")
        scales(v, L + "2", (s * 1.42, 1.55, 0.75), (s * 1.48, 1.15, 1.9), rows=4, arc=(-60, 60), size=0.24, col="Tile", rim="TileRim")
        for k in (-1, 0, 1):
            t = V(s * 1.5 + k * 0.24, 2.65, 0.2)
            v.curve(L + "3", "Claw", [t + V(0, -0.2, 0.25), t + V(0, 0.35, 0.3), t + V(0, 0.75, 0.0)], [0.15, 0.1, 0.03])
        shade(v, "Clay", parts={L + "1", L + "2"})
        for k in range(2):
            v.torus(L + "2", "Glow", V(s * 1.55, 1.3 + 0.35 * k, 1.75 - 0.55 * k), (0, 0.35, 1), 0.47 - 0.04 * k, 0.04)
        B = "LegBL" if s < 0 else "LegBR"
        leg2(v, B, (s * 0.92, -1.6, 2.7), (s * 1.05, -0.9, 1.6), (s * 1.05, -1.75, 0.68), (s * 1.05, -1.55, 0.0), (0.72, 0.5, 0.36, 0.34), "Clay", front=False, claw="Claw")
        shade(v, "Clay", parts={B + "1", B + "2"})
    # the heavy tail: five bones of tiles tapering to a smouldering ember club
    pts = [V(0, -2.25, 2.95), V(0, -3.0, 2.45), V(0, -3.6, 1.75), V(0, -4.05, 1.05), V(0, -4.45, 0.55), V(0, -4.9, 0.4)]
    rad = [0.78, 0.62, 0.48, 0.36, 0.25, 0.16]
    for i in range(5):
        nm = f"Tail{i + 1}"
        v.joint(nm, tuple(pts[i]), "Body" if i == 0 else f"Tail{i}", "tail")
        v.cap(nm, "Clay", pts[i], pts[i + 1], rad[i], rad[i + 1])
        scales(v, nm, pts[i + 1], pts[i], rows=2, arc=(-110, 110), size=max(0.16, rad[i] * 0.48), col="Tile", rim="TileRim")
    v.ell("Tail5", "Glow", pts[5] + V(0, 0, 0.05), (0.2, 0.2, 0.2))
    v.cluster("Tail5", "Crystal", pts[5], (0, -0.6, 0.5), 0.8, n=6, seed=3)
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
    v.torus("Body", "Gold", gq, (0, 0.4, 0.9), 0.55, 0.09)
    v.ell("Body", "Crystal", gq + V(0, 0.02, 0.1), (0.48, 0.5, 0.42))
    v.ell("Body", "Glow", gq + V(0, 0.02, 0.18), (0.22, 0.24, 0.3))
    v.anchor("gem", "Body", gq + V(0, 0.1, 0.25))
    # crystal winglets on their own bones (they beat)
    for s, w in ((-1, "WingL"), (1, "WingR")):
        root = V(s * 0.55, 0.45, 2.7)
        v.joint(w, tuple(root), "Body", "wing")
        for tx, ty, tz, wd in ((2.4, -0.6, 3.05, 0.95), (1.9, -1.6, 2.7, 0.7)):
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
        v.curve("Head", "Gold", [(s * 0.35, 2.2, 1.95), (s * 0.85, 2.55, 2.2), (s * 1.0, 3.05, 2.3), (s * 0.7, 3.4, 2.25), (s * 0.25, 3.35, 2.15)], [0.15, 0.14, 0.11, 0.07, 0.03])
        for k in range(3):
            q = V(s * (0.85 - 0.05 * k), 2.55 + 0.25 * k, 2.22)
            v.torus("Head", "Leg", q, (0.3, 1, 0), 0.13, 0.035)
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
@pet("Shinemane", palette(form=("Fur",), Fur="#253a96", Chest="#7d95e8", Dark="#101848", Amethyst="#d052f8", Claw="#c8ecff",
                          Crystal="#5ee6ff", Glow="#8af4ff", Edge="#9ab4ff"))
def shinemane(v):
    nz = noise(8)
    v.joint("Body", (0, 0, 3.4))
    # a lean, long-legged crystal lurcher (magic/concepts/Shinemane_s21): a deep chest and tucked waist, a halo collar of
    # crystal shards round its neck, tall ears, a crystal on its brow, glowing starmaps on its flanks, crystal bracers, a plume
    # tail that ends in a crown of crystals
    v.muscle("Body", "Fur", (0, 1.05, 3.55), (1.08, 1.05, 1.1))
    v.muscle("Body", "Fur", (0, -0.2, 3.62), (0.82, 1.2, 0.8))
    v.muscle("Body", "Fur", (0, -1.4, 3.55), (0.98, 0.88, 0.92))
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
    for k in range(22):
        a = k / 22 * math.tau
        out = V(math.cos(a), -0.05, math.sin(a) * 0.95 + 0.1).normalized()
        L = 1.0 + 0.5 * (0.5 + 0.5 * math.sin(a)) + (0.25 if k % 2 else 0)
        v.crystal("Neck", "Crystal" if k % 3 else "Amethyst", N0 + out * 0.45, out, L, 0.17 if k % 2 else 0.13)
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
    rad = [0.3, 0.62, 0.82, 0.74, 0.38]
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
    for s2 in (-1, 1):
        v.curve("Head", "Gold", [(s2 * 0.3, 2.95, 1.95), (s2 * 0.42, 3.15, 1.75), (s2 * 0.38, 3.25, 1.5)], [0.09, 0.07, 0.03])
    v.ell("Head", "Dark", (0, 3.3, 2.06), (0.22, 0.1, 0.16))
    for s in (-1, 1):
        v.eye("Head", (s * 0.48, 2.65, 2.55), (s * 0.75, 0.65, 0.1), w=0.22, h=0.16)
        v.ell("Head", "Fur", (s * 0.66, 1.75, 2.95), (0.2, 0.12, 0.2))
    for st in ([(0, 3.02, 2.38), (0, 3.06, 2.52)], [(-0.08, 3.02, 2.45), (0.08, 3.02, 2.45)]):
        v.line("Head", "Glow", st, r=0.05)
    v.anchor("eyes", "Head", (0, 2.8, 2.55)); v.anchor("halo", "Head", (0, 1.9, 3.9))
    v.joint("Halo", (0, 1.9, 3.95), "Head", "ring"); v.axis("Halo", (0, 0, 1))
    v.torus("Halo", "Gold", (0, 1.9, 3.95), (0, 0.15, 1), 0.75, 0.07)
    for k in range(6):
        a = k / 6 * math.tau
        v.box("Halo", "Nugget", (math.cos(a) * 0.75, 1.9 + math.sin(a) * 0.75, 3.98), (0.26, 0.26, 0.08))
    # powerful forelegs in gold bracers, digging claws; hind legs
    for limb, x, y, front in (("LegFL", -1.0, 1.15, True), ("LegFR", 1.0, 1.15, True), ("LegBL", -0.92, -1.35, False), ("LegBR", 0.92, -1.35, False)):
        s = 1 if x > 0 else -1
        if front:
            leg2(v, limb, (x, y, 2.1), (x + s * 0.08, y + 0.15, 1.15), (x + s * 0.08, y + 0.15, 0.45), (x + s * 0.08, y + 0.25, 0.0), (0.58, 0.42, 0.34, 0.32), "Fur", front=True, claw="Claw", toes=5)
            v.torus(limb + "2", "Gold", V(x + s * 0.08, y + 0.15, 0.85), (0, 0, 1), 0.42, 0.09)
            v.ell(limb + "1", "Gold", V(x + s * 0.2, y + 0.1, 2.25), (0.55, 0.6, 0.38), cut=lambda xx, yy, zz: zz > 2.05)
            v.torus(limb + "1", "Nugget", V(x + s * 0.2, y + 0.1, 2.08), (0, 0, 1), 0.52, 0.05)
            for k in (-1, 0, 1):
                t = V(x + s * 0.08 + k * 0.22, y + 0.95, 0.12)
                v.cap(limb + "3", "Claw", t + V(0, -0.15, 0.18), t + V(0, 0.45, -0.02), 0.11, 0.03)
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
    v.muscle("Body", "Jade", (0, 1.0, 3.45), (1.45, 1.25, 1.2))
    v.muscle("Body", "Jade", (0, -0.4, 3.4), (0.92, 1.4, 0.88))
    v.muscle("Body", "Jade", (0, -1.6, 3.45), (1.25, 0.95, 1.0))
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
    for s in (-1, 1):
        q = surf(v, "Body", (0, -0.6, 3.35), (s, 0, 0)) or V(s * 1.0, -0.6, 3.35)
        v.ell("Body", "Gold", q, (0.12, 0.48, 0.48))
        v.torus("Body", "Mane", q + V(s * 0.08, 0, 0), (s, 0, 0), 0.4, 0.06)
        v.box("Body", "Glow", q + V(s * 0.1, 0, 0), (0.1, 0.18, 0.18))
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
    v.cap("Head", "Jade", (0, 2.85, 3.5), (0, 3.65, 3.0), 0.4, 0.3)
    v.ell("Head", "Glow", (0, 3.3, 3.55), (0.36, 0.55, 0.3))
    v.ell("Head", "Crystal", (0, 3.25, 3.5), (0.2, 0.3, 0.16))
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
        for tx, ty, tz, wd in ((1.7, 0.7, 6.3, 0.62), (2.3, 0.1, 6.0, 0.66), (2.6, -0.5, 5.4, 0.62), (2.5, -1.1, 4.8, 0.56), (2.0, -1.5, 4.3, 0.48)):
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


# ---------------------------------------------------------------- GLIMWISP: Lantern Fox-Wisp (Rare light spirit; v16.1)
@pet("Glimwisp", palette(form=("Fur",), Fur="#4b2a9c", Mask="#f0e8ff", Ruff="#c8b4ff", Dark="#1a1030", Gold="#e8b84a",
                         Flame="#22d6cc", FlameTip="#c8fff6", Violet="#b468ff", Claw="#5cfff0", Crystal="#7af6ff", Glow="#5cfff0", Edge="#d8ccff"))
def glimwisp(v):
    # v16.1 (audit 1:24, 6.2/10: "a faceless purple mushroom-umbrella on thin spider legs"): a lantern fox-wisp. A violet
    # spirit fox on four slender legs whose paws burn teal, a white mask face with glowing eyes and tall ears lit inside, a
    # brass lantern with a teal flame hanging from its collar, and two swept tails that burn from violet fur into teal flame
    # and end in crystal points (round 2, Gemini: a floating fox read as a sausage; four tails read as a hand)
    v.joint("Body", (0, 0, 2.2))
    v.muscle("Body", "Fur", (0, 0.5, 2.3), (0.6, 0.72, 0.62))
    v.muscle("Body", "Fur", (0, -0.4, 2.25), (0.48, 0.7, 0.46))
    v.muscle("Body", "Fur", (0, -0.95, 2.3), (0.52, 0.48, 0.5))
    v.muscle("Body", "Fur", (0, 0.05, 2.3), (0.56, 0.6, 0.56))  # round 3 (Gemini: a tubular torso): a fuller middle
    v.muscle("Body", "Fur", (0, 0.85, 2.7), (0.44, 0.42, 0.46))  # and a neck that bevels into the shoulders
    for s in (-1, 1): v.muscle("Body", "Fur", (s * 0.4, 0.62, 2.45), (0.25, 0.4, 0.42), rot=E(-15, 0, 0))
    shade(v, "Fur")
    v.ell("Body", "Ruff", (0, 0.85, 2.2), (0.46, 0.3, 0.5))  # the chest ruff
    for k in range(7):
        a = math.radians(-60 + k * 20)
        q = V(math.sin(a) * 0.42, 0.95, 1.95 + math.cos(a) * 0.1)
        v.blade("Body", "Mask" if k % 2 else "Ruff", q, q + V(math.sin(a) * 0.22, 0.22, -0.3), 0.18, thick=0.1, normal=(0, 1, 0.3))
    v.torus("Body", "Gold", (0, 0.75, 2.68), (0, 0.6, 1), 0.48, 0.07)  # the collar
    L0 = V(0, 1.15, 1.55)  # the lantern on its collar: a brass frame round a teal flame
    v.line("Body", "Gold", [(0, 1.0, 2.3), (0, 1.15, 1.85)], r=0.04)
    v.box("Body", "Gold", L0 + V(0, 0, 0.26), (0.36, 0.36, 0.07)); v.box("Body", "Gold", L0 + V(0, 0, -0.26), (0.4, 0.4, 0.09))
    v.cap("Body", "Gold", L0 + V(0, 0, 0.3), L0 + V(0, 0, 0.42), 0.12, 0.04)
    v.box("Body", "Glow", L0, (0.27, 0.27, 0.44))
    v.cap("Body", "FlameTip", L0 + V(0, 0, -0.08), L0 + V(0, 0, 0.18), 0.08, 0.02)
    for sx in (-1, 1):
        for sy in (-1, 1): v.box("Body", "Gold", L0 + V(sx * 0.15, sy * 0.15, 0), (0.06, 0.06, 0.5))
    v.anchor("core", "Body", tuple(L0))
    for limb, x, y, front in (("LegFL", -0.32, 0.62, True), ("LegFR", 0.32, 0.62, True), ("LegBL", -0.33, -0.95, False), ("LegBR", 0.33, -0.95, False)):
        s = 1 if x > 0 else -1
        if front: hip, knee, ank, foot = (x, y, 2.05), (x + s * 0.03, y + 0.08, 1.2), (x + s * 0.03, y + 0.02, 0.38), (x + s * 0.03, y + 0.1, 0.0)
        else: hip, knee, ank, foot = (x, y, 2.15), (x + s * 0.04, y + 0.38, 1.35), (x + s * 0.04, y - 0.2, 0.48), (x + s * 0.04, y - 0.1, 0.0)
        leg2(v, limb, hip, knee, ank, foot, (0.36, 0.23, 0.18, 0.18), "Fur", front=front, claw="Claw", toes=3)  # round 4 (Gemini: matchstick legs)
        shade(v, "Fur", parts={limb + "1", limb + "2"})
        v.paint("Flame", lambda xx, yy, zz: zz < 0.55, part=limb + "3", only={"Fur", "FurHi", "FurLo", "FurCrease"})  # the paws burn teal
        v.cap(limb + "3", "FlameTip", V(ank) + V(0, 0, 0.05), V(ank) + V(0, -0.12, 0.35), 0.07, 0.02)
    # the head: a big fox skull with a white mask, a pointed snout and tall ears lit inside
    v.joint("Head", (0, 0.95, 2.75), "Body", "head")
    v.muscle("Head", "Fur", (0, 1.25, 3.2), (0.66, 0.62, 0.56))
    v.ell("Head", "Mask", (0, 1.6, 2.92), (0.46, 0.36, 0.25))
    v.cap("Head", "Mask", (0, 1.7, 2.95), (0, 2.4, 2.78), 0.25, 0.11)
    v.ell("Head", "Dark", (0, 2.45, 2.8), (0.09, 0.07, 0.07))
    shade(v, "Fur", parts={"Head"})
    for s in (-1, 1):
        v.blade("Head", "Mask", (s * 0.5, 1.35, 2.98), (s * 0.9, 1.05, 2.7), 0.3, thick=0.11, normal=(0, 0.4, 1))  # cheek fluff
        v.cap("Head", "Fur", (s * 0.32, 1.1, 3.62), (s * 0.56, 0.95, 4.5), 0.27, 0.05)
        v.cap("Head", "Glow", (s * 0.32, 1.2, 3.68), (s * 0.53, 1.06, 4.32), 0.14, 0.03)
        e = V(s * 0.3, 1.8, 3.42)
        face_eye(v, "Head", (0, 1.25, 3.25), (s * 0.55, 1, 0.38), w=0.3, h=0.14)  # round 9: narrow fox slits, flush on the head  # round 5 (Gemini: googly blocks): flush, sunk eyes with a teal iris
    v.crystal("Head", "Crystal", (0, 1.55, 3.75), (0, 0.3, 1), 0.38, 0.1)
    v.anchor("eyes", "Head", (0, 1.85, 3.42)); v.anchor("visor", "Head", (0, 1.55, 3.95))
    # two swept tails with open space between them, violet at the root burning into teal flame, crystal points at the tips
    TAILS = ([V(-0.12, -1.3, 2.45), V(-0.42, -2.0, 2.85), V(-0.7, -2.6, 3.45), V(-0.72, -2.95, 4.05), V(-0.5, -3.05, 4.55)],  # round 5: two different curves, one curling high
             [V(0.12, -1.3, 2.4), V(0.45, -2.05, 2.55), V(0.85, -2.8, 2.75), V(1.05, -3.45, 3.1), V(1.0, -3.95, 3.5)])  # and one swept long and low
    for j, sp in enumerate((-1.0, 1.0)):
        pts = TAILS[j]
        rad = (0.24, 0.32, 0.34, 0.26, 0.1)
        pre = "Tail" + "LR"[j]
        cols = ("Fur", "Fur", "Flame", "Flame")
        for i in range(4):
            nm = f"{pre}{i + 1}"
            v.joint(nm, tuple(pts[i]), "Body" if i == 0 else f"{pre}{i}", "tail")
            v.cap(nm, cols[i], pts[i], pts[i + 1], rad[i], rad[i + 1])
        v.paint("Flame", lambda x, y, z, c=pts[2]: y < c.y + 0.12, part=f"{pre}2", only={"Fur", "FurHi", "FurLo", "FurCrease"})
        v.paint("FlameTip", lambda x, y, z, c=pts[3]: z > c.z + 0.08, part=f"{pre}4", only={"Flame"})
        shade(v, "Fur", parts={f"{pre}1", f"{pre}2"})
        tip = pts[4]; d = (pts[4] - pts[3]).normalized(); side = d.cross(V(0, 1, 0)).normalized()
        for k, a in enumerate((-0.8, 0.0, 0.8)):  # flame tongues round the tip
            q = pts[3].lerp(pts[4], 0.5) + side * a * 0.16
            v.blade(f"{pre}4", "FlameTip" if k % 2 else "Flame", q, q + d * 0.38 + side * a * 0.28, 0.13, thick=0.12, normal=(0, 1, 0))
        v.crystal(f"{pre}4", "Crystal", tip - d * 0.12, d, 0.5, 0.12)
        v.anchor("ten" + "AB"[j], f"{pre}4", tuple(tip))
    for s, k in ((-1, "C"), (1, "D")): v.anchor("ten" + k, "Head", (s * 0.56, 0.95, 4.5))  # the ear tips trail light too (Shared.PetSigFX echo)
    ground(v)


# ---------------------------------------------------------------- SELKIE: Diving-Bell Seal Spirit (Rare oxygen diver; v16.1)
@pet("Selkie", palette(form=("Fur",), Fur="#13687a", Belly="#a6e2ea", Dark="#08303a", Brass="#d0a050", BrassDark="#7a5426",
                       Claw="#ff8aa0", Crystal="#7af0ff", Glow="#8af6ff", Edge="#c0f0ff"))
def selkie(v):
    v.joint("Body", (0, 0, 1.7))
    # v16.1 (audit 1:33, 6.8/10: "a giant pale-beige brain/walnut shell swallowing its back"): a sleek deep-water seal spirit.
    # A long tapered body with a raised chest, a compact brass diving-bell pack strapped to its back (three glowing portholes,
    # a crystal on its crown), a row of crystal fins down the spine, webbed flippers with coral claws, and a broad swept tail
    # fluke edged in crystal. A clear head: pale muzzle, big eyes, whiskers
    v.muscle("Body", "Fur", (0, 0.85, 1.95), (0.82, 0.95, 0.95))
    v.muscle("Body", "Fur", (0, -0.45, 1.45), (0.78, 1.25, 0.72))
    v.muscle("Body", "Fur", (0, -1.55, 1.1), (0.6, 0.75, 0.58))  # round 4: belly depth before the tail
    for s in (-1, 1): v.muscle("Body", "Fur", (s * 0.66, 1.0, 2.15), (0.26, 0.48, 0.5), rot=E(-20, 0, 0))
    v.ell("Body", "Belly", (0, 0.95, 1.5), (0.62, 0.95, 0.6))
    v.ell("Body", "Belly", (0, -0.4, 0.95), (0.6, 1.1, 0.3))
    shade(v, "Fur")
    for k in range(9):  # round 9: harbour-seal dapples, a few soft spots down each flank (not random static)
        y0 = 1.1 - 0.42 * k
        for s2 in (-1, 1):
            q = surf(v, "Body", (0, y0, 1.6 - 0.05 * k), (s2, 0.0, 0.45 if k % 2 else 0.1))
            if q: v.ell("Body", "FurLo", q, (0.09, 0.14, 0.12))
    # the diving-bell pack: a brass dome with rivet bands, portholes and a crystal on its crown, strapped round the chest
    B0 = V(0, -0.1, 2.05)
    v.paint("Dark", lambda x, y, z: (V(x, y, 0) - V(B0.x, B0.y, 0)).length < 0.74 and z < B0.z + 0.08, part="Body", only={"Fur", "FurHi", "FurLo", "FurCrease"})  # round 3: the contact shadow under the pack
    v.cap("Body", "Brass", B0, B0 + V(0, 0, 0.62), 0.58, 0.44)
    v.ell("Body", "Brass", B0 + V(0, 0, 0.62), (0.44, 0.44, 0.28))
    v.torus("Body", "BrassDark", B0 + V(0, 0, 0.08), (0, 0, 1), 0.6, 0.06)
    v.torus("Body", "BrassDark", B0 + V(0, 0, 0.5), (0, 0, 1), 0.48, 0.05)
    for a in (0, 120, 240):
        d = V(math.sin(math.radians(a)), -math.cos(math.radians(a)), 0)
        q = B0 + V(0, 0, 0.3) + d * 0.52
        v.torus("Body", "BrassDark", q, d, 0.15, 0.04)
        v.ell("Body", "Glow", q + d * 0.02, (0.11, 0.11, 0.11))
    v.cluster("Body", "Crystal", B0 + V(0, 0, 0.86), (0, -0.2, 1), 0.5, n=3, seed=3)
    for y in (0.7, -0.75):  # the straps
        v.torus("Body", "Brass", (0, y, 1.62), (0, 1, 0.15), 0.86 if y > 0 else 0.8, 0.07)
    v.anchor("shell", "Body", tuple(B0 + V(0, 0, 1.0)))
    for k in range(4):  # crystal fins down the spine behind the bell
        y = -0.85 - 0.38 * k
        q = surf(v, "Body", (0, y, 1.3), (0, -0.2, 1)) or V(0, y, 2.0)
        v.crystal("Body", "Crystal", q - V(0, 0, 0.08), (0, -0.7, 1), 0.42 - 0.06 * k, 0.09)
    for s2 in (-1, 1):  # glowing lateral line
        for k in range(5):
            q = surf(v, "Body", (0, 1.1 - 0.5 * k, 1.5 - 0.06 * k), (s2, 0, 0.25))
            if q: v.box("Body", "Glow", q, (0.11, 0.11, 0.11))
    h = Shift(v, (0, -0.1, -0.12))  # round 5/6 (Gemini: a stilted, long-necked seal): the head sits lower and closer
    h.joint("Neck", (0, 1.45, 2.4), "Body", "neck")
    v.cap("Neck", "Fur", (0, 1.4, 2.3), (0, 1.85, 2.93), 0.58, 0.48)
    shade(v, "Fur", parts={"Neck"})
    h.joint("Head", (0, 1.95, 3.05), "Neck", "head")
    h.muscle("Head", "Fur", (0, 2.2, 3.3), (0.6, 0.6, 0.52))
    h.ell("Head", "Belly", (0, 2.65, 3.12), (0.42, 0.36, 0.3))
    h.ell("Head", "Dark", (0, 2.98, 3.2), (0.14, 0.08, 0.1))
    shade(v, "Fur", parts={"Head"})
    for s in (-1, 1):
        h.eye("Head", (s * 0.3, 2.58, 3.5), (s * 0.55, 0.82, 0.12), w=0.26, h=0.22, iris="Dark")  # round 6 (Gemini: protruding block eyes): smaller, sunk, black with a catchlight
    h.anchor("snout", "Head", (0, 3.05, 3.2)); h.anchor("eyes", "Head", (0, 2.75, 3.5))
    drop(v, 0.4)
    for s, f in ((-1, "FlipFL"), (1, "FlipFR")):
        # round 7 (Gemini, both graders: an awkward crouch on prop pillars): the whole seal is lowered so the belly rests on the
        # ground (drop() before this loop); each flipper bends at the wrist and its broad paddle lies flat and splayed
        v.joint(f + "1", (s * 0.66, 1.15, 1.0), "Body", "arm")
        v.cap(f + "1", "Fur", (s * 0.66, 1.15, 0.98), (s * 1.05, 1.42, 0.38), 0.46, 0.34)
        v.muscle(f + "1", "Fur", (s * 0.74, 1.15, 0.95), (0.44, 0.48, 0.44))
        v.joint(f + "2", (s * 1.05, 1.42, 0.38), f + "1", "arm")
        v.muscle(f + "2", "Fur", (s * 1.12, 1.5, 0.3), (0.3, 0.3, 0.22))
        v.blade(f + "2", "Fur", (s * 1.1, 1.45, 0.14), (s * 1.95, 1.75, 0.1), 0.95, thick=0.2, normal=(0, 0, 1))
        for k in (-1, 0, 1): v.cap(f + "2", "Claw", (s * 1.85, 1.62 + 0.14 * k, 0.15), (s * 2.05, 1.66 + 0.16 * k, 0.08), 0.07, 0.02)
        shade(v, "Fur", parts={f + "1"})
    pts = [V(0, -1.75, 0.75), V(0, -2.5, 0.55), V(0, -3.2, 0.45), V(0, -3.8, 0.55), V(0, -4.25, 0.72)]  # round 7: lowered with the body
    for i in range(4):
        nm = f"Tail{i + 1}"
        v.joint(nm, tuple(pts[i]), "Body" if i == 0 else f"Tail{i}", "tail")
        v.muscle(nm, "Fur", pts[i].lerp(pts[i + 1], 0.5), (0.5 - 0.1 * i, (pts[i + 1] - pts[i]).length * 0.62, 0.42 - 0.08 * i), rot=look(pts[i + 1] - pts[i]))
        shade(v, "Fur", parts={nm})
    for s in (-1, 1):  # the broad swept fluke, crystal along its trailing edge
        v.blade("Tail4", "Fur", pts[4], pts[4] + V(s * 1.1, -0.8, 0.12), 0.7, thick=0.2, normal=(0, 0, 1), bend=0.08)
        v.blade("Tail4", "Crystal", pts[4] + V(s * 0.5, -0.5, 0.06), pts[4] + V(s * 1.15, -0.95, 0.14), 0.22, thick=0.12, normal=(0, 0, 1))
    v.anchor("gills", "Body", (0, 1.3, 2.35))
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
        sh, el, wr = V(s * 0.6, 0.2, 4.3), V(s * 1.45, -0.05, 5.55), V(s * 2.2, -0.55, 6.9)
        v.joint(w + "1", tuple(sh), "Body", "wing")
        v.cap(w + "1", "Obsidian", sh, el, 0.24, 0.16)
        for k in range(5):
            p = sh.lerp(el, 0.2 + 0.18 * k)
            v.blade(w + "1", "Ember" if k % 2 else "Flame", p, p + V(s * 0.15, -0.95, -1.05 + 0.08 * k), 0.46, thick=0.12, normal=(0, 0.3, 1))
            v.blade(w + "1", "Obsidian", p + V(0, 0.05, 0.08), p + V(s * 0.1, -0.5, -0.45), 0.4, thick=0.12, normal=(0, 0.3, 1))
        v.joint(w + "2", tuple(el), w + "1", "wing")
        v.cap(w + "2", "Obsidian", el, wr, 0.16, 0.1)
        for k in range(6):
            p = el.lerp(wr, 0.15 + 0.17 * k)
            v.blade(w + "2", ("Flame", "Ember", "Gold")[k % 3], p, p + V(s * (0.65 + 0.12 * k), -1.1 - 0.08 * k, -0.35 + 0.3 * k), 0.48, thick=0.12, normal=(0, 0.4, 1))
            v.blade(w + "2", "Obsidian", p + V(0, 0.05, 0.08), p + V(s * 0.25, -0.5, -0.1 + 0.15 * k), 0.36, thick=0.12, normal=(0, 0.4, 1))
    for s, L in ((-1, "LegL"), (1, "LegR")):
        hip, knee, ank, foot = V(s * 0.42, -0.2, 3.0), V(s * 0.5, 0.35, 1.95), V(s * 0.5, -0.2, 0.75), V(s * 0.5, 0.05, 0.0)
        v.joint(L + "1", tuple(hip), "Body", "leg")
        v.muscle(L + "1", "Obsidian", hip.lerp(knee, 0.4), (0.58, 0.62, 0.78), over=False)
        v.cap(L + "1", "Obsidian", hip, knee, 0.42, 0.26, over=False)
        v.joint(L + "2", tuple(knee), L + "1", "leg")
        v.cap(L + "2", "Dark", knee, ank, 0.24, 0.17)
        for k in range(5): v.torus(L + "2", "Ember", knee.lerp(ank, 0.15 + 0.17 * k), (ank - knee).normalized(), 0.16, 0.03)
        v.joint(L + "3", tuple(ank), L + "2", "leg")
        v.cap(L + "3", "Dark", ank, foot + V(0, 0, 0.15), 0.13, 0.12)
        foot_talon(v, L + "3", foot, 0.13, "Dark", "Claw")
        shade(v, "Obsidian", parts={L + "1"})
        v.anchor("foot" + L[3:], L + "3", foot + V(0, 0.1, 0.25))
    tp = [V(0, -0.7, 2.85), V(0, -1.5, 2.3), V(0, -2.3, 1.55), V(0, -3.0, 0.85), V(0, -3.6, 0.45), V(0, -4.1, 0.5)]
    for i in range(5):
        nm = f"Tail{i + 1}"
        v.joint(nm, tuple(tp[i]), "Body" if i == 0 else f"Tail{i}", "tail")
        v.cap(nm, "Obsidian", tp[i], tp[i + 1], 0.26 - 0.04 * i, 0.22 - 0.04 * (i + 1))
        v.cap(nm, "Ember", tp[i] + V(0, 0, -0.08), tp[i + 1] + V(0, 0, -0.08), 0.16 - 0.025 * i, 0.13 - 0.025 * (i + 1))
    for s2 in (-1, 1): v.blade("Tail5", "Flame", tp[5], tp[5] + V(s2 * 0.5, -0.6, 0.55), 0.36, thick=0.11, normal=(0, 0.3, 1))
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





def diamond(v, part, col, c, w, h):
    """a floating diamond (octahedron): |x|/w + |y|/w + |z|/h <= 1"""
    c = V(c)
    v.fill(part, col, c - V(w, w, h), c + V(w, w, h), lambda x, y, z: abs(x - c.x) / w + abs(y - c.y) / w + abs(z - c.z) / h <= 1)


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


class Shift:
    """v16.1: a proxy of a Vox that moves every position by d (directions, radii and sizes stay), to re-pose a block"""
    def __init__(self, v, d): self.v, self.d = v, V(d)
    def _p(self, q): return tuple(V(q) + self.d)
    def joint(self, part, pivot, parent=None, group=None): self.v.joint(part, self._p(pivot), parent, group)
    def anchor(self, key, part, q): self.v.anchor(key, part, self._p(q))
    def cap(self, part, col, a, b, r0, r1, **k): self.v.cap(part, col, self._p(a), self._p(b), r0, r1, **k)
    def ell(self, part, col, c, r, **k): self.v.ell(part, col, self._p(c), r, **k)
    def muscle(self, part, col, c, r, **k): self.v.muscle(part, col, self._p(c), r, **k)
    def box(self, part, col, c, size, **k): self.v.box(part, col, self._p(c), size, **k)
    def eye(self, part, c, n, **k): self.v.eye(part, self._p(c), n, **k)
    def curve(self, part, col, pts, radii, **k): self.v.curve(part, col, [self._p(q) for q in pts], radii, **k)
    def crystal(self, part, col, base, d, L, w, **k): self.v.crystal(part, col, self._p(base), d, L, w, **k)
    def cluster(self, part, col, base, d, size, **k): self.v.cluster(part, col, self._p(base), d, size, **k)
    def blade(self, part, col, a, b, w, **k): self.v.blade(part, col, self._p(a), self._p(b), w, **k)
    def __getattr__(self, n): return getattr(self.v, n)


def face_eye(v, part, centre, d, **k):
    """v16.1 round 8 (graders: no eyes visible from the front): an eye placed on the real head surface, found by marching from
    the head's centre along d (outward and forward), facing along d"""
    d = V(d).normalized()
    q = surf(v, part, centre, d)
    if q: v.eye(part, tuple(q - d * 0.02), tuple(d), **k)
    return q


def drop(v, dz):
    """v16.1: lower everything built so far by dz studs (whole cells), its joints and anchors with it"""
    n = int(round(dz / v.s))
    v.cells = {(i, j, k - n): c for (i, j, k), c in v.cells.items()}
    for part, q in list(v.c.pivots.items()): v.c.pivots[part] = q - V(0, 0, n * v.s)
    for key, (part, q) in list(v.c.anchors.items()): v.c.anchors[key] = (part, q - V(0, 0, n * v.s))
    for part, ms in list(v.muscles.items()): v.muscles[part] = [(c - V(0, 0, n * v.s), r, Ri, R) for c, r, Ri, R in ms]


def despeckle(v, col, to, keep=2):
    """v16.1: cells of col with fewer than keep same-colour face neighbours become to (no 1-voxel static)"""
    for k, (p, c) in list(v.cells.items()):
        if c != col: continue
        n = sum(1 for d in ((1, 0, 0), (-1, 0, 0), (0, 1, 0), (0, -1, 0), (0, 0, 1), (0, 0, -1)) if v.cells.get((k[0] + d[0], k[1] + d[1], k[2] + d[2]), (None, None))[1] == col)
        if n < keep: v.cells[k] = (p, to)


def under_shade(v, parts, cols, dark):
    """v16.1: the undersides (an empty cell below) of cols in parts take a darker tone"""
    for k, (p, col) in list(v.cells.items()):
        if p in parts and col in cols and (k[0], k[1], k[2] - 1) not in v.cells: v.cells[k] = (p, dark)


def back_shade(v, parts, cols, dark):
    """v16.1: recolour the cells of cols in parts whose back neighbour (-y, the side seen from behind) is empty"""
    for k, (p, col) in list(v.cells.items()):
        if p in parts and col in cols and (k[0], k[1] - 1, k[2]) not in v.cells: v.cells[k] = (p, dark)


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
                       Wing="#5e2e9e", WingBack="#341660", Claw="#ece0c8", Maw="#d040ff", Crystal="#c84cff", Glow="#ff8a1e", Edge="#b8b0d8"))
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
    v.ell("Body", "Plate", (0, 0.2, 3.0), (1.0, 1.85, 0.42))  # round 6: the belly plate lifted (graders: no negative space under it)
    v.paint("PlateRim", lambda x, y, z: (y % 0.42) < 0.08, part="Body", only={"Plate"})
    shade(v, "Stone")
    # round 5 (Gemini: clashing yellow slits): no lava on the flanks; the molten glow stays in the jaw, the brows and the eyes
    scales(v, "Body", (0, 2.2, 4.2), (0, -2.8, 4.0), rows=10, arc=(-55, 55), size=0.42, col="Plate", rim="PlateRim")
    # v16.1 (audit 1:51): the amethyst geodes sit further aft and lower, so the head and brow horns read from 3/4 and from above
    for (x, y, z, sz) in ((0, -0.3, 5.2, 1.15), (0.65, -1.0, 5.0, 0.95), (-0.6, -1.5, 4.95, 1.0), (0.15, -2.2, 4.8, 1.05), (1.15, 0.2, 4.9, 0.6), (-1.15, 0.2, 4.9, 0.6)):
        q = surf(v, "Body", (x * 0.6, y, 3.9), (x * 0.5, 0, 1)) or V(x, y, z)
        v.cluster("Body", "Crystal", q - V(0, 0, 0.18), (x * 0.4, -0.5, 1), sz * 1.25, n=7, seed=int(sz * 10 + y * 3 + 40))
    v.anchor("chest", "Body", (0, 2.4, 3.8)); v.anchor("back", "Body", (0, 0.4, 6.4))
    # neck and head
    v.joint("Neck", (0, 2.2, 4.6), "Body", "neck")
    v.cap("Neck", "Stone", (0, 2.1, 4.5), (0, 3.25, 5.85), 0.9, 0.72)
    for s in (-1, 1): v.muscle("Neck", "Stone", (s * 0.45, 2.6, 5.0), (0.45, 0.6, 0.65), rot=E(40, 0, 0))
    scales(v, "Neck", (0, 3.0, 5.6), (0, 2.1, 4.9), rows=3, arc=(-60, 60), size=0.36, col="Plate", rim="PlateRim")
    shade(v, "Stone", parts={"Neck"})
    h = Shift(v, (0, 0.2, 0.4))  # round 5 (Gemini: the jaw merged with the chest in the blackout): the head lifted and forward
    h.joint("Head", (0, 3.05, 5.45), "Neck", "head")
    h.muscle("Head", "Stone", (0, 3.55, 5.7), (1.1, 1.2, 0.95))
    h.cap("Head", "Stone", (0, 4.0, 5.65), (0, 5.3, 5.35), 0.7, 0.52)
    h.cap("Head", "Stone", (0, 3.85, 5.0), (0, 5.0, 4.82), 0.52, 0.36)  # round 2 (Gemini: the face was a dark pit): the jaw closed
    h.ell("Head", "Glow", (0, 4.6, 5.14), (0.4, 0.62, 0.06))  # a molten seam between the jaws
    for s2 in (-1, 1): h.ell("Head", "Stone", (s2 * 0.55, 3.75, 6.1), (0.42, 0.55, 0.24), rot=E(0, s2 * -15, 0))
    shade(v, "Stone", parts={"Head"})
    for s in (-1, 1):
        for k in range(4):
            q = V(s * (0.2 + 0.11 * k), 5.15 - 0.22 * k, 5.12)
            h.cap("Head", "Claw", q, q + V(0, 0, -0.3), 0.08, 0.02)
            q2 = V(s * (0.2 + 0.11 * k), 4.95 - 0.22 * k, 4.6)
            h.cap("Head", "Claw", q2, q2 + V(0, 0, 0.25), 0.07, 0.02)
        h.box("Head", "Plate", (s * 0.5, 4.0, 6.12), (0.5, 0.42, 0.14), rot=E(0, 0, s * -20))  # round 4: a brow plate over each eye
        face_eye(v, "Head", (0, 3.75, 6.15), (s * 0.55, 1, 0.3), w=0.48, h=0.3)  # round 8: molten eyes on the front of the head
        h.curve("Head", "Glow", [(s * 0.25, 4.25, 6.2), (s * 0.55, 4.05, 6.15), (s * 0.8, 3.75, 6.0)], [0.05, 0.05, 0.04])  # a molten brow over each eye
        h.box("Head", "Glow", (s * 0.16, 5.02, 5.32), (0.1, 0.1, 0.1))
        h.curve("Head", "Horn", [(s * 0.6, 3.25, 6.15), (s * 1.0, 2.75, 6.55), (s * 1.5, 2.45, 6.15), (s * 1.65, 2.75, 5.5), (s * 1.5, 3.3, 5.3), (s * 1.3, 3.5, 5.62)], [0.44, 0.4, 0.32, 0.22, 0.13, 0.05])
        h.cluster("Head", "Crystal", (s * 0.3, 3.4, 6.35), (s * 0.3, -0.3, 1), 0.8, n=2, seed=5)
    h.anchor("snout", "Head", (0, 5.35, 5.35)); v.anchor("eyes", "Head", (0, 4.15, 5.85))
    for s, w in ((-1, "WingL"), (1, "WingR")):
        # v16.1: the wings sweep back and lower behind the shoulders (they stood up behind the head and hid it)
        v.muscle("Body", "Stone", (s * 1.05, 0.3, 5.0), (0.55, 0.65, 0.5))  # round 3: a muscular wing root on the spine
        bat_wing(v, w, (s * 1.2, 0.6, 5.2), (s * 2.6, -0.4, 7.5), [(s * 4.4, -1.4, 8.2), (s * 4.8, -2.5, 7.2), (s * 4.3, -3.4, 6.1), (s * 2.7, -3.1, 5.4)], "Stone", "Wing", (s * 1.0, -2.0, 4.9), thick=0.48)  # round 7: thick membranes
        for t in ((s * 4.4, -1.4, 8.2), (s * 4.8, -2.5, 7.2), (s * 4.3, -3.4, 6.1)): v.cap(w + "2", "Stone", (s * 2.6, -0.4, 7.5), t, 0.2, 0.08)  # thick finger spars
        back_shade(v, {w + "1", w + "2"}, {"Wing"}, "WingBack")  # round 2 (Gemini: cardboard fins): thick membranes, darker on the back
        v.cluster(w + "2", "Crystal", (s * 2.6, -0.4, 7.55), (s * 0.3, -0.2, 1), 0.65, n=2, seed=6)
    for limb, x, y, front in (("LegFL", -1.25, 1.4, True), ("LegFR", 1.25, 1.4, True), ("LegBL", -1.15, -2.05, False), ("LegBR", 1.15, -2.05, False)):
        s = 1 if x > 0 else -1
        if front: hip, knee, ank, foot = (x, y, 3.55), (x + s * 0.12, y + 0.15, 1.95), (x + s * 0.12, y + 0.05, 0.68), (x + s * 0.12, y + 0.15, 0.0)
        else: hip, knee, ank, foot = (x, y, 3.6), (x + s * 0.12, y + 0.5, 2.1), (x + s * 0.12, y - 0.25, 0.85), (x + s * 0.12, y - 0.1, 0.0)
        leg2(v, limb, hip, knee, ank, foot, (0.78, 0.55, 0.44, 0.42), "Stone", front=front, claw="Claw", toes=4)
        shade(v, "Stone", parts={limb + "1", limb + "2", limb + "3"})
        kq = V(knee) + V(s * 0.3, 0.35 if front else -0.35, 0.1)
        # round 7 (Gemini: scattered pink flecks): no crystals on the knees; the geodes stay on the back and the tail
    pts = [V(0, -2.9, 4.05), V(0, -3.7, 3.5), V(0, -4.45, 2.8), V(0, -5.1, 2.0), V(0, -5.6, 1.3), V(0, -6.05, 0.9), V(0, -6.45, 0.8)]
    rad = [0.78, 0.64, 0.52, 0.42, 0.33, 0.26, 0.2]
    for i in range(6):
        nm = f"Tail{i + 1}"
        v.joint(nm, tuple(pts[i]), "Body" if i == 0 else f"Tail{i}", "tail")
        v.cap(nm, "Stone", pts[i], pts[i + 1], rad[i], rad[i + 1])
        if i % 2 == 0: v.crystal(nm, "Crystal", pts[i] + V(0, -0.1, rad[i] * 0.8), (0, -0.4, 1), 0.75 + 0.3 * rad[i], 0.17)
        shade(v, "Stone", parts={nm})
    v.ell("Tail6", "Stone", pts[6], (0.62, 0.62, 0.58))
    for d in ((1, 0, 0.3), (-1, 0, 0.3), (0, -1, 0.2), (0, 0, 1)):
        v.crystal("Tail6", "Crystal", pts[6] + V(d).normalized() * 0.45, d, 0.75, 0.17)
    v.anchor("tail", "Tail6", pts[6])
    ground(v)


# ---------------------------------------------------------------- KIRIN: Sacred Lotus Qilin (Legendary cleanser; B)
@pet("Kirin", palette(form=("Pearl",), Pearl="#2558b4", Scale="#3d7fe0", ScaleRim="#14306e", Pink="#ff9a1e", PinkLight="#ffcf5c", Muzzle="#9cc4f4",
                      Belly="#7aa6e6", Gold="#e6b44a", Fin="#ffc45a", Hoof="#7a4e1a", Claw="#f4f0e8", Petal="#ffb03a", Crystal="#86e6ff", Glow="#6ae0ff", Edge="#a8c8ff"))
def kirin(v):
    v.joint("Body", (0, 0, 3.95))
    # a pearl-scaled qilin (magic/concepts/Kirin_s22): a deer's long legs on jade hooves, a scaled back, a long neck under a
    # flowing pink mane, rose-quartz antlers that bloom into lotus flowers, dragon whiskers, pink shoulder fins and silk
    # ribbons trailing from its shoulders
    # round 4 (Gemini: a paper-thin slab from the front): the ribcage, shoulders and hips a third wider
    v.muscle("Body", "Pearl", (0, 0.95, 4.1), (1.45, 1.05, 1.1))
    v.muscle("Body", "Pearl", (0, -0.2, 4.05), (1.0, 1.2, 0.8))
    v.muscle("Body", "Pearl", (0, -1.3, 4.1), (1.25, 0.9, 0.94))
    for s in (-1, 1):
        v.muscle("Body", "Pearl", (s * 0.95, 1.05, 4.35), (0.36, 0.58, 0.64), rot=E(-15, s * -10, 0))
        v.muscle("Body", "Pearl", (s * 0.8, -1.45, 4.3), (0.5, 0.64, 0.62))
    shade(v, "Pearl")
    v.paint("Belly", lambda x, y, z: z < 3.5, part="Body", only={"Pearl", "PearlLo"})  # v16.1: a lighter sapphire belly under the storm-blue coat
    v.paint("PearlLo", lambda x, y, z: 3.55 < z < 4.4 and math.sin(y * 6.5) + math.sin(z * 8 + abs(x) * 3) > 1.25, part="Body", only={"Pearl", "PearlHi"})  # round 3: storm dapples down the flanks
    scales(v, "Body", (0, 1.6, 4.3), (0, -1.9, 4.2), rows=12, arc=(-70, 70), size=0.22, col="Scale", rim="ScaleRim")
    for k in range(10):
        y = 1.3 - k * 0.32; q = surf(v, "Body", (0, y, 4.0), (0, 0, 1))
        if q: v.blade("Body", "Pink" if k % 2 else "PinkLight", q - V(0, 0, 0.05), q + V(0, -0.45, 0.35), 0.24, thick=0.1, normal=(1, 0, 0))
    v.anchor("back", "Body", (0, -0.2, 5.3))
    for s2 in (-1, 1):  # round 2 (Gemini: a monochrome blue slab between the legs): gold-trimmed flank plates
        for k in range(4):
            q = surf(v, "Body", (0, 0.75 - 0.6 * k, 3.95), (s2, 0, 0.1))
            if q: v.ell("Body", "Gold", q, (0.13, 0.26, 0.2)); v.ell("Body", "Scale", q + V(s2 * 0.07, 0, 0), (0.08, 0.18, 0.13))
    v.joint("Neck", (0, 1.4, 4.45), "Body", "neck")
    v.cap("Neck", "Pearl", (0, 1.35, 4.35), (0, 2.0, 5.65), 0.5, 0.36)
    v.cap("Neck", "Belly", (0, 1.55, 4.2), (0, 2.12, 5.35), 0.36, 0.26)  # round 6: a lighter throat (graders: no neck transition)
    for k in range(9):
        t = k / 8; q = V(0, 1.3 + 0.62 * t, 4.65 + 1.15 * t)
        for s in (-1, 1):
            v.blade("Neck", "Pink" if (k + (s > 0)) % 2 else "PinkLight", q + V(s * 0.05, -0.1, 0), q + V(s * 0.45, -0.75, -0.25), 0.3, thick=0.1, normal=(s, 0.2, 0.4))
    shade(v, "Pearl", parts={"Neck"})
    v.joint("Head", (0, 2.0, 5.65), "Neck", "head")
    v.muscle("Head", "Pearl", (0, 2.3, 5.85), (0.64, 0.72, 0.56))
    v.cap("Head", "Pearl", (0, 2.65, 5.85), (0, 3.5, 5.6), 0.48, 0.36)  # round 2 (Gemini): a wider muzzle
    v.cap("Head", "Muzzle", (0, 2.6, 5.35), (0, 3.35, 5.05), 0.36, 0.27)
    v.ell("Head", "Glow", (0, 3.0, 5.4), (0.26, 0.35, 0.12))
    for s2 in (-1, 1):
        for k in range(3):
            v.cap("Head", "Claw", (s2 * (0.12 + 0.09 * k), 3.35 - 0.12 * k, 5.45), (s2 * (0.12 + 0.09 * k), 3.35 - 0.12 * k, 5.25), 0.05, 0.015)
        v.cap("Head", "Claw", (s2 * 0.24, 3.25, 5.18), (s2 * 0.24, 3.25, 5.5), 0.06, 0.015)
    v.box("Head", "Pink", (0, 3.58, 5.65), (0.16, 0.08, 0.1))
    for k in range(14):
        a = math.radians(-120 + k * 240 / 13)
        d = V(math.sin(a), -0.55, math.cos(a) * 0.9 + 0.1).normalized()
        v.crystal("Head", "Pink" if k % 2 else "PinkLight", V(0, 2.0, 5.85) + d * 0.5, d, 0.75 + 0.25 * math.cos(a), 0.12)  # round 5: an amber flame mane, not a cyan halo
    shade(v, "Pearl", parts={"Head"})
    for s in (-1, 1):
        face_eye(v, "Head", (0, 2.3, 5.9), (s * 0.55, 1, 0.3), w=0.34, h=0.26, ring="Claw")  # round 8: pale-ringed glowing eyes, on the front
        v.blade("Head", "Pearl", (s * 0.32, 2.05, 6.15), (s * 0.72, 1.8, 6.4), 0.24, thick=0.1, normal=(s * 0.3, 1, 0))
        v.curve("Head", "Pink", [(s * 0.18, 3.2, 5.55), (s * 0.6, 3.3, 5.5), (s * 0.9, 3.0, 5.2), (s * 1.0, 2.6, 5.35)], [0.04, 0.035, 0.03, 0.02])
        A = [V(s * 0.22, 2.15, 6.25), V(s * 0.45, 1.95, 6.85), V(s * 0.68, 1.65, 7.4), V(s * 0.78, 1.3, 7.8)]
        v.curve("Head", "Gold", A, [0.12, 0.1, 0.08, 0.05])  # v16.1: burnished gold antlers (were rose quartz)
        for i, d in ((1, V(s * 0.45, 0.25, 0.35)), (2, V(s * 0.4, 0.1, 0.4))):
            v.curve("Head", "Gold", [A[i], A[i] + d * 0.6, A[i] + d], [0.07, 0.055, 0.04])
            lotus(v, "Head", A[i] + d, (d.x * 0.4, 0.1, 1), 0.3, 6, "Petal", "PinkLight")
        lotus(v, "Head", A[3], (s * 0.3, -0.2, 1), 0.34, 6, "Petal", "PinkLight")
    v.anchor("antlers", "Head", (0, 1.7, 7.5)); v.anchor("eyes", "Head", (0, 2.7, 6.0))
    for s, w in ((-1, "FinL"), (1, "FinR")):
        v.joint(w, (s * 0.9, 1.0, 4.6), "Body", "wing")
        for k in range(3):
            v.blade(w, "Fin" if k % 2 else "Gold", (s * 1.1, 1.0, 4.7), (s * (1.8 - 0.15 * k), 1.2 - 0.6 * k, 6.4 - 0.3 * k), 0.55, thick=0.12, normal=(s, 0.2, 0.3), bend=0.12)
    for limb, x, y, front in (("LegFL", -0.66, 1.05, True), ("LegFR", 0.66, 1.05, True), ("LegBL", -0.68, -1.35, False), ("LegBR", 0.68, -1.35, False)):
        s = 1 if x > 0 else -1
        if front: hip, knee, ank, foot = (x, y, 3.7), (x + s * 0.1, y + 0.1, 2.25), (x + s * 0.14, y, 0.78), (x + s * 0.15, y + 0.08, 0.0)
        else: hip, knee, ank, foot = (x, y, 3.8), (x + s * 0.08, y + 0.45, 2.55), (x + s * 0.12, y - 0.25, 1.1), (x + s * 0.13, y - 0.12, 0.0)
        leg2(v, limb, hip, knee, ank, foot, (0.54, 0.31, 0.22, 0.21), "Pearl", front=front, kind="hoof", hoof="Hoof", band="Gold")
        shade(v, "Pearl", parts={limb + "1", limb + "2"})
        a = V(ank)
        for k in range(6):
            ang = k / 6 * math.tau
            v.blade(limb + "3", "PinkLight", a + V(math.cos(ang) * 0.1, math.sin(ang) * 0.1, -0.25), a + V(math.cos(ang) * 0.3, math.sin(ang) * 0.3 - 0.1, -0.6), 0.16, thick=0.1, normal=(math.sin(ang), -math.cos(ang), 0))
    pts = [V(0, -2.0, 4.4), V(0, -2.75, 4.45), V(0, -3.4, 4.1), V(0, -3.8, 3.5), V(0, -4.0, 2.85), V(0, -3.9, 2.25)]
    for i in range(5):
        nm = f"Tail{i + 1}"
        v.joint(nm, tuple(pts[i]), "Body" if i == 0 else f"Tail{i}", "tail")
        v.cap(nm, "Pearl", pts[i], pts[i + 1], 0.3 - 0.035 * i, 0.27 - 0.035 * (i + 1))
        v.blade(nm, "Pink", pts[i + 1] + V(0, 0, 0.1), pts[i + 1] + V(0, -0.35, 0.45), 0.22, thick=0.1, normal=(1, 0, 0))
    for k in range(7):
        a = k / 7 * math.tau
        v.blade("Tail5", "Pink" if k % 2 else "PinkLight", pts[5] + V(0, 0, 0.1), pts[5] + V(math.cos(a) * 0.4, -0.35, -0.6 + math.sin(a) * 0.25), 0.26, thick=0.1, normal=(math.cos(a), 0, math.sin(a)))
    for s, r in ((-1, "RibbonL"), (1, "RibbonR")):
        pts = [V(s * 0.6, 0.8, 4.75), V(s * 0.9, -0.3, 5.25), V(s * 1.0, -1.5, 4.9), V(s * 0.8, -2.6, 5.3)]
        for i in range(3):
            nm = f"{r}{i + 1}"
            v.joint(nm, tuple(pts[i]), "Body" if i == 0 else f"{r}{i}", "tail")
            v.blade(nm, "Pink", pts[i], pts[i + 1], 0.32, thick=0.1, normal=(0, 0.2, 1), bend=0.12 * (1 if i % 2 else -1))
    ground(v)


# ---------------------------------------------------------------- OURO: World-Tree Infinity Wyrm (Mythic all-rounder; A)
@pet("Ouro", palette(form=("Scale",), Scale="#26457e", Belly="#eaa22a", Crest="#f0b04a", Gold="#e2b452", Wing="#c8507c", Mane="#c8186c", Prism="#c070ff", Dark="#101a30",
                     WingBack="#4a1026", WingRim="#8e1e44", ManeBack="#3c0c1e",
                     Claw="#f0e6d6", Crystal="#c8f2ff", Glow="#b070ff", Edge="#a8c0f0"))
def ouro(v):
    # a coiled world-tree wyrm (magic/concepts/Ouro_s21): a long serpent body lying in a spiral coil with a gold belly and an
    # orange crest, the neck rising tall to a horned dragon head with gold antlers and whiskers, pink bat wings at the
    # shoulders, and six prism crystals floating round it on their own spinning bone
    N = 13
    pts = []
    for i in range(N + 1):
        t = i / N; th = t * math.tau * 1.25; R = 1.85 - 1.2 * t if t <= 0.75 else 0.95 + (t - 0.75) * 3.2  # v16.1 round 2: the tail end flicks out of the coil
        pts.append(V(R * math.sin(th), R * math.cos(th) - 0.25, 0.62 - 0.12 * t + max(0.0, t - 0.75) * 2.4 + 0.16 * max(0.0, math.sin(th * 2.0))))  # round 5: the coil rises and dips
    rad = [0.62 - 0.44 * (i / N) for i in range(N + 1)]
    v.joint("Body", tuple(pts[0]), None)
    v.cap("Body", "Scale", pts[0] + V(0, 0, 0.1), pts[1], rad[0], rad[1])
    v.muscle("Body", "Scale", pts[0] + V(0, 0, 0.35), (0.7, 0.7, 0.6))
    for i in range(1, N):
        nm = f"Tail{i}"
        v.joint(nm, tuple(pts[i]), "Body" if i == 1 else f"Tail{i - 1}", "tail")
        v.muscle(nm, "Scale", pts[i].lerp(pts[i + 1], 0.5), (rad[i] * 1.05, (pts[i + 1] - pts[i]).length * 0.7, rad[i] * 1.0), rot=look(pts[i + 1] - pts[i]))
        q = pts[i].lerp(pts[i + 1], 0.5)
        v.cap(nm, "Gold", pts[i] + V(0, 0, rad[i] * 0.85), pts[i + 1] + V(0, 0, rad[i + 1] * 0.85), 0.09, 0.08)  # round 3: a continuous gold dorsal ridge (the crest flecks read as scattered gems)
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
        for s2 in (-1, 0, 1):
            v.blade(nm, "Mane" if s2 else "Crest", npts[i] + V(s2 * 0.2, -0.35, 0.2), npts[i] + V(s2 * 0.55, -1.0, 0.45), 0.34, thick=0.1, normal=(1, 0, s2 * 0.5))
        shade(v, "Scale", parts={nm})
    v.joint("Head", tuple(npts[3]), "Neck3", "head")
    v.muscle("Head", "Scale", (0, 2.0, 3.95), (0.5, 0.62, 0.46))
    v.cap("Head", "Scale", (0, 2.3, 3.9), (0, 3.05, 3.7), 0.36, 0.26)
    v.cap("Head", "Belly", (0, 2.2, 3.4), (0, 2.85, 3.05), 0.27, 0.19)
    v.ell("Head", "Glow", (0, 2.55, 3.45), (0.2, 0.3, 0.1))
    for s2 in (-1, 1):
        for k in range(3): v.cap("Head", "Claw", (s2 * 0.16, 2.6 + 0.15 * k, 3.6), (s2 * 0.16, 2.6 + 0.15 * k, 3.4), 0.04, 0.015)
    shade(v, "Scale", parts={"Head"})
    for s in (-1, 1):
        v.eye("Head", (s * 0.34, 2.45, 4.12), (s * 0.7, 0.7, 0.1), w=0.3, h=0.22, iris="Gold")
        A = [V(s * 0.25, 1.85, 4.3), V(s * 0.55, 1.35, 4.75), V(s * 0.8, 0.75, 5.0), V(s * 0.85, 0.25, 5.05)]
        v.curve("Head", "Gold", A, [0.14, 0.12, 0.09, 0.06])  # round 4: antlers two voxels thick
        for i, d in ((1, V(s * 0.4, 0.3, 0.3)), (2, V(s * 0.35, 0.05, 0.4))):
            v.curve("Head", "Gold", [A[i], A[i] + d], [0.08, 0.05])
        v.curve("Head", "Gold", [(s * 0.22, 3.0, 3.6), (s * 0.7, 3.2, 3.5), (s * 1.1, 2.95, 3.1), (s * 1.25, 2.6, 2.85)], [0.04, 0.035, 0.03, 0.02])
        for k in range(3):
            v.blade("Head", "Crest", (s * 0.3, 1.7, 4.0 - 0.15 * k), (s * (0.75 + 0.1 * k), 1.25, 4.15 - 0.25 * k), 0.24, thick=0.1, normal=(0, 0.3, 1))
    v.anchor("eyes", "Head", (0, 2.55, 4.1)); v.anchor("gem", "Head", (0, 1.9, 4.55))
    back_shade(v, {"Neck1", "Neck2", "Neck3"}, {"Mane"}, "ManeBack")  # v16.1: the red hood darkens toward its back
    for s, w in ((-1, "WingL"), (1, "WingR")):
        bat_wing(v, w, (s * 0.45, 1.75, 2.3), (s * 1.8, 0.9, 3.6), [(s * 2.9, 0.0, 3.7), (s * 3.0, -0.9, 2.9), (s * 2.3, -1.4, 2.2), (s * 1.3, -0.5, 1.8)], "Gold", "Wing", (s * 0.6, 0.6, 1.6), thick=0.34)
        for t in ((s * 2.9, 0.0, 3.7), (s * 3.0, -0.9, 2.9), (s * 2.3, -1.4, 2.2), (s * 2.95, -0.45, 3.3), (s * 2.65, -1.15, 2.55)): v.cap(w + "2", "Gold", (s * 1.8, 0.9, 3.6), t, 0.11, 0.05)  # gold finger spars and ribs over the membrane
        v.cap(w + "1", "Gold", (s * 0.45, 1.75, 2.3), (s * 1.8, 0.9, 3.6), 0.12, 0.09)  # a gold-bound wing arm (round 2: the wings read paper-thin)
        # v16.1 (audit 2:09: flat red slabs from behind): a darker crimson rim round the outer membrane, crimson-obsidian on the back
        sh0 = V(s * 0.45, 1.75, 2.3)  # (rearward wings, round 2)
        far = max(((V(k) + V(0.5, 0.5, 0.5)) * v.s - sh0).length for k, (pp, cc) in v.cells.items() if pp in (w + "1", w + "2") and cc == "Wing")
        v.paint("WingRim", lambda x, y, z, sh0=sh0, far=far: (V(x, y, z) - sh0).length > far * 0.72, part=w + "2", only={"Wing"})
        v.paint("WingRim", lambda x, y, z, sh0=sh0, far=far: (V(x, y, z) - sh0).length > far * 0.72, part=w + "1", only={"Wing"})
        back_shade(v, {w + "1", w + "2"}, {"Wing", "WingRim"}, "WingBack")
    # two clawed forelegs planted in front of the coil (round 2: Gemini)
    for limb, x in (("LegFL", -0.62), ("LegFR", 0.62)):
        leg2(v, limb, (x, 1.75, 1.45), (x * 1.35, 2.05, 0.95), (x * 1.4, 2.1, 0.4), (x * 1.4, 2.25, 0.0), (0.32, 0.24, 0.19, 0.18), "Scale", front=True, claw="Claw", toes=4)
        shade(v, "Scale", parts={limb + "1", limb + "2"})
    # prism crystals grow along the top of the coil (round 2, Gemini: six diamonds floating round it read as debris)
    for i in (3, 7):  # round 3: two geode clusters in one prism colour (single crystals read as scattered pastel flecks)
        q = pts[i].lerp(pts[i + 1], 0.5)
        v.cluster(f"Tail{i}", "Prism", q + V(0, 0, rad[i] * 0.6), (0, 0, 1), 0.85 - 0.04 * i, n=5, seed=i)
    ground(v)


# ---------------------------------------------------------------- NINERING: Sovereign Chrono-Relic (Secret ore copier; B)
@pet("Ninering", palette(form=("Head",), Gold="#e2a634", Dark="#1c1c36", Void="#0a0a18", Head="#2a2c40", Horn="#ffd04a", Claw="#ffd04a", Ivory="#f6eed8", HornDark="#9a6418",
                         Crystal="#7ae8ff", Glow="#38d8ff", Edge="#f0d890"))
def ninering(v):
    C = V(0, 0, 3.95)
    v.joint("Body", tuple(C), None)
    # a living astrolabe (magic/concepts/Ninering_s22): nine counter-rotating rings of gold and dark enamel set with glowing
    # crystal gems round a domed void-glass core under a raised gold star, a big horned void-dragon head crowning it, and two
    # scaled digitigrade legs on gold talons that carry the whole relic (round 2: Gemini, head 2.5x, legs, a domed core)
    # v16.1 round 2 (Gemini: "a flat paper-thin disc", noisy 1-voxel flecks, a head too small to read as a creature): a round
    # void core, six thick rings on six different axes (a gyroscope that reads in 3D from every side, each ring still turns on
    # its own bone), four big set gems a ring, and the dragon head 1.45x bigger above it
    v.ell("Body", "Void", C, (0.95, 0.9, 0.95))
    v.torus("Body", "Dark", C, (0, 0, 1), 0.93, 0.12)
    F = C + V(0, 0.86, 0)
    for k in range(8):
        a = k / 8 * math.tau
        d = V(math.cos(a), 0, math.sin(a))
        v.blade("Body", "Gold", F, F + V(0, -0.12, 0) + d * (0.85 if k % 2 == 0 else 0.55), 0.26, thick=0.14, normal=(0, 1, 0))
    v.ell("Body", "Glow", F + V(0, 0.06, 0), (0.26, 0.12, 0.26))
    v.torus("Body", "Glow", F + V(0, -0.15, 0), (0, 1, 0), 0.62, 0.05)
    v.anchor("core", "Body", tuple(F + V(0, 0.15, 0)))
    RINGS = ((1.4, (0, 1, 0), "Gold"), (1.75, (1, 0, 0), "Dark"), (2.1, (0, 0, 1), "Gold"), (2.45, (-0.7, 0.7, 0.2), "Gold"), (2.82, (0, 0.95, 0.3), "Gold"))  # round 9: five rings
    for i, (R, n0, col) in enumerate(RINGS):
        nm = f"Ring{i + 1}"
        nrm = V(n0).normalized()
        v.joint(nm, tuple(C), "Body", "ring"); v.axis(nm, tuple(nrm))
        v.torus(nm, col, C, nrm, R, 0.17 + 0.01 * i)  # round 9: a heavier gauge
        if col == "Dark": v.torus(nm, "Gold", C, nrm, R + 0.13, 0.035)  # a gold edge on the dark enamel rings
        u = nrm.orthogonal().normalized(); w = nrm.cross(u)
        for k in range(4):
            a = k / 4 * math.tau + i * 0.7
            q = C + (u * math.cos(a) + w * math.sin(a)) * R
            v.ell(nm, "Gold", q, (0.17, 0.17, 0.17))
            v.ell(nm, "Glow" if (k + i) % 2 == 0 else "Crystal", q + (q - C).normalized() * 0.1, (0.13, 0.13, 0.13))
        if i == len(RINGS) - 1:
            for k in range(12):
                a = k / 12 * math.tau
                rd = u * math.cos(a) + w * math.sin(a)
                v.crystal(nm, "Gold", C + rd * (R + 0.08), rd, 0.42, 0.1)
    # the crowning dragon head, 1.45x (round 2) and lifted clear of the outer ring
    K2, H0, HP = 1.45, V(0, 0, 6.3), V(0, 0, 7.05)
    def P(x, y, z): return tuple(HP + (V(x, y, z) - H0) * K2)
    v.joint("Head", tuple(HP), "Body", "head")
    v.line("Body", "Gold", [tuple(C + V(0, 0, 0.85)), tuple(HP + V(0, 0, -0.2))], r=0.16)  # the neck stem
    for zz, R2, w2 in ((5.78, 0.95, 0.12), (5.62, 0.72, 0.1), (5.92, 1.12, 0.06)):  # round 4: a flared gold collar under the head where it meets the frame
        v.torus("Body", "Gold", (0, -0.2, zz), (0, 0.2, 1), R2, w2)
    v.torus("Body", "Glow", (0, -0.2, 5.78), (0, 0.2, 1), 1.04, 0.035)
    for sx in (-1, 1): v.cap("Body", "Gold", (sx * 0.85, -0.2, 5.75), (sx * 1.25, -0.1, 5.2), 0.1, 0.08)  # round 5: brackets from the collar to the frame
    v.cap("Head", "Head", P(0, -0.2, 6.1), P(0, 0.1, 6.9), 0.75 * K2, 0.7 * K2)
    v.muscle("Head", "Head", P(0, 0.35, 7.05), (0.9 * K2, 1.0 * K2, 0.78 * K2))
    v.cap("Head", "Head", P(0, 0.9, 6.95), P(0, 1.9, 6.7), 0.55 * K2, 0.38 * K2)
    v.cap("Head", "Dark", P(0, 0.85, 6.5), P(0, 1.75, 6.3), 0.42 * K2, 0.3 * K2)
    v.ell("Head", "Glow", P(0, 1.55, 6.42), (0.3, 0.45, 0.07))  # a lit seam between the jaws
    v.cap("Head", "Gold", P(0, 0.9, 6.36), P(0, 1.85, 6.22), 0.09, 0.07)  # a gold jawline
    for k in range(4):
        for s2 in (-1, 1): v.cap("Head", "Claw", P(s2 * (0.14 + 0.09 * k), 1.75 - 0.18 * k, 6.62), P(s2 * (0.14 + 0.09 * k), 1.75 - 0.18 * k, 6.42), 0.07, 0.025)
    shade(v, "Head", parts={"Head"})
    for s in (-1, 1):
        face_eye(v, "Head", P(0, 0.35, 7.1), (s * 0.5, 1, 0.3), w=0.5, h=0.3, iris="Glow")  # round 8: glowing cyan eyes on the front of the head
        v.curve("Head", "Gold", [P(s * 0.2, 1.3, 7.42), P(s * 0.5, 1.15, 7.5), P(s * 0.78, 0.85, 7.42)], [0.06, 0.06, 0.05])  # gold brow ridges
        v.curve("Head", "Horn", [P(s * 0.5, 0.0, 7.55), P(s * 1.05, -0.45, 8.1), P(s * 1.45, -0.95, 8.25), P(s * 1.6, -1.4, 7.95)], [0.3, 0.24, 0.15, 0.05])
        v.curve("Head", "Horn", [P(s * 0.75, 0.55, 6.85), P(s * 1.4, 0.4, 6.75), P(s * 1.75, 0.1, 6.45)], [0.16, 0.11, 0.04])
        v.curve("Head", "Gold", [P(s * 0.3, 1.7, 7.0), P(s * 0.55, 0.9, 7.55), P(s * 0.4, 0.2, 7.85)], [0.07, 0.07, 0.05])
    v.crystal("Head", "Crystal", P(0, 0.4, 7.75), (0, -0.2, 1), 1.1, 0.2)
    for k in range(4):
        a = (k - 1.5) * 0.4
        v.crystal("Head", "Gold", P(math.sin(a) * 0.5, 0.0, 7.6), (math.sin(a), -0.4, 1), 0.65, 0.1)
    v.anchor("eyes", "Head", P(0, 1.15, 7.25))
    under_shade(v, {"Head"}, {"Horn"}, "HornDark")  # round 3: darker horn undersides so they part from the top ring
    # v16.1 (audit 2:18: "a dark charcoal sphere on two stubby round black feet" from behind): no legs. The relic hovers inside
    # its rings; a gold pendulum with a crystal drop hangs under the core (a tentacle bone, so PetVoxels floats it), and the
    # back of the core carries an ivory and gold filigree rosette round a glowing gem
    # round 6 (Gemini, both graders: "an armillary sphere with a severed goat head", no creature mass): the dragon's own body
    # runs down from the head and coils one and a half turns round the core inside the rings, gold scutes on its back, the tail
    # ending in a crystal under the core. Four tentacle bones, so PetVoxels still floats it and the coil sways
    coil = [V(0, -0.25, 5.75), V(0, -0.8, 5.2)]
    for i in range(1, 25):
        t = i / 24; a = -math.pi / 2 + t * math.pi * 3
        coil.append(C + V(math.cos(a) * 1.12, math.sin(a) * 1.12, 0.78 - 1.85 * t))
    coil.append(coil[-1] + V(0, 0, -0.45))
    rads = [0.34 - 0.24 * (k / (len(coil) - 1)) for k in range(len(coil))]
    seg = [0, 7, 14, 20, len(coil) - 1]
    for bi in range(4):
        nm = f"Coil{bi + 1}"
        v.joint(nm, tuple(coil[seg[bi]]), "Body" if bi == 0 else f"Coil{bi}", "tentacle")
        v.tube(nm, "Head", coil[seg[bi]:seg[bi + 1] + 1], rads[seg[bi]:seg[bi + 1] + 1])
        for k in range(seg[bi] + 1, seg[bi + 1], 2):
            q = coil[k]; out = V(q.x - C.x, q.y - C.y, 0)
            if out.length > 1e-6:
                out.normalize()
                v.crystal(nm, "Gold", q + out * rads[k] * 0.7 + V(0, 0, rads[k] * 0.4), out + V(0, 0, 0.7), 0.28, 0.08)
    shade(v, "Head", parts={"Coil1", "Coil2", "Coil3", "Coil4"})
    v.crystal("Coil4", "Crystal", coil[-1], (0, 0, -1), 0.55, 0.15)
    v.ell("Coil4", "Glow", coil[-1] + V(0, 0, -0.1), (0.1, 0.1, 0.12))
    BK = C + V(0, -0.88, 0)
    for k in range(12):
        ang = k / 12 * math.tau
        d = V(math.cos(ang), 0, math.sin(ang))
        v.blade("Body", "Ivory" if k % 2 else "Gold", BK + V(0, -0.02, 0) + d * 0.18, BK + V(0, 0.08, 0) + d * (0.85 if k % 2 == 0 else 0.6), 0.2, thick=0.12, normal=(0, 1, 0))
    v.torus("Body", "Ivory", BK + V(0, -0.04, 0), (0, 1, 0), 0.7, 0.045)
    v.torus("Body", "Gold", BK + V(0, -0.04, 0), (0, 1, 0), 0.42, 0.04)
    for k in range(4):
        ang = k / 4 * math.tau + math.pi / 4
        curl(v, "Body", "Gold", BK + V(math.cos(ang) * 0.55, -0.06, math.sin(ang) * 0.55), (0, 1, 0), 0.16, 0.04, 1.2, 0.035, 0.025, n=14, start=ang)
    v.ell("Body", "Glow", BK + V(0, -0.06, 0), (0.16, 0.1, 0.16))
    v.curve("Head", "Gold", [P(0, -0.75, 6.4), P(0, -0.55, 7.1), P(0, -0.1, 7.55), P(0, 0.4, 7.75)], [0.1, 0.1, 0.08, 0.05])  # a gold crest down the back of the head
    for s in (-1, 1): v.curve("Head", "Ivory", [P(s * 0.35, -0.6, 6.55), P(s * 0.5, -0.35, 7.15), P(s * 0.45, 0.1, 7.5)], [0.05, 0.045, 0.03])

if __name__ == "__main__":
    rp = os.path.join(here, "rigs.json")
    db = json.load(open(rp)) if os.path.exists(rp) else {}
    for name, (pal, fn) in D.items():
        if ONLY and name not in ONLY and name.replace(" ", "") not in ONLY: continue
        v = X.Vox(name, pal, s=CELL.get(name, S))
        fn(v)
        c = v.build()
        d = K.export(c, OUT)
        d["cells"] = len(v.cells); d["proportions"] = proportions(v)
        db[name] = d
        print(f"{name}: {d['proportions']} {len(v.cells)} cells, {d['tris']} triangles, {d['parts']} parts, {d['objects']} objects, biggest {d['maxPart']}, size {d['size']}", flush=True)
    json.dump(db, open(rp, "w"), indent=1)
