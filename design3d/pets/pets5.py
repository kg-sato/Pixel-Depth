"""v5 voxel pets (Master Directive v16 under the owner's call of 2026-11-24: keep the voxel style, follow the vault).
The v4 power body plan (pets.py; vault Research/3D and Art/Voxel Creature Power Proportions (2026-11-18).md) stays the shapes at
VOX 0.16; v5 changes what the vault audit (Pet Models and Icon Craft Audit (2026-11-24)) found weak without changing the style:
  * EYES: no more 2x3 blocks stuck out of the face. Each eye is cut into the face and redrawn at half-voxel scale (0.08 studs,
    the "fine" cells): a rounded oval sunk half a voxel deep, its corners filled with the face colour; a catchlight toward the
    viewer's upper left; Rare spirits and up (GLOW_EYES) get a dark ring round a glowing iris (Iris role, Neon in the game)
  * the bake loses the white-noise speckle (build_pets.py VOXEL_NOISE=0)
  * REFINE: per-pet v5 builders replace the v4 ones the audit named (in this file, after the v4 import)
    python design3d/pets/pets5.py [Name ...]   -> design3d/pets/pets5.json (pets.json format plus "fine": part -> [x, y, z, role])
    VOXEL_JSON=design3d/pets/pets5.json VOXEL_BAKE=1 VOXEL_NOISE=0 VOXEL_KEEP=Gem,Iris blender -b -P design3d/pets/build_pets.py -- design3d/pets/out5"""
import json, os, sys
here = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, here)
import pets as P

GLOW_EYES = {"Pixiu", "Glimwisp", "Zharbird", "Fafnir", "Kirin", "Ouro", "Ninering"}
IRIS = {"Pixiu": "#c8ff60", "Glimwisp": "#8afcff", "Zharbird": "#ffd040", "Fafnir": "#ffb020", "Kirin": "#6af0ff", "Ouro": "#ff4ab0", "Ninering": "#ffe070"}
REFINE = {}  # name -> v5 builder (replaces the v4 one)


def _eyes(self, part, y, z, dx=2, h=3):  # record where a builder wants the eyes; draw_eyes cuts and draws them at the fine scale
    self.__dict__.setdefault("eyecalls", []).append((part, y, z, dx, h))


P.Pet.eyes = _eyes


def draw_eyes(p, fine):
    glow = p.name in GLOW_EYES
    for part, y, z, dx, h in getattr(p, "eyecalls", []):
        H = 2 * h
        for s in (-1, 1):
            cols = (dx - 1, dx) if s > 0 else (-dx, -(dx - 1))
            face = {}
            for cxv in cols:  # cut the face voxels where the eye goes; remember their colour for the socket rim
                for yy in range(y, y + h):
                    face[(cxv, yy)] = (p.v.pop((cxv, yy, z), (part, "Main"))[1])
            xs = [2 * cols[0], 2 * cols[0] + 1, 2 * cols[1], 2 * cols[1] + 1]
            for ci, x in enumerate(xs):
                for r in range(H):
                    yy = 2 * y + r
                    rim = face[(x // 2, yy // 2)]
                    corner = (ci in (0, 3)) and (r in (0, H - 1))
                    if corner:  # round the opening: both half-layers keep the face colour
                        fine[(x, yy, 2 * z)] = (part, rim); fine[(x, yy, 2 * z + 1)] = (part, rim)
                        continue
                    role = "Eye"
                    if glow:
                        if ci in (1, 2) and 0 < r < H - 1: role = "Iris"
                        if ci == 3 and r == H - 2: role = "Shine"
                    elif (ci == 2 and r == H - 1) or (ci in (2, 3) and r == H - 2):  # the catchlight toward the viewer's upper left (+x)
                        role = "Shine"
                    fine[(x, yy, 2 * z)] = (part, role)  # the back half only: the eye sits half a voxel deep


# ---------------------------------------------------------------- voxel primitives for the refinements (all in voxel cells)
import math


def _seg_dist(c, a, b):
    ab = [b[i] - a[i] for i in range(3)]
    L2 = sum(v * v for v in ab) or 1e-9
    t = max(0.0, min(1.0, sum((c[i] - a[i]) * ab[i] for i in range(3)) / L2))
    return math.dist(c, [a[i] + ab[i] * t for i in range(3)]), t


def vline(p, part, role, a, b, r0, r1=None, over=True):
    """a solid tapered capsule from a to b (cell centres within the radius): tusks, horns, bones, tails stay connected"""
    r1 = r0 if r1 is None else r1
    R = max(r0, r1)
    lo = [math.floor(min(a[i], b[i]) - R) for i in range(3)]
    hi = [math.ceil(max(a[i], b[i]) + R) for i in range(3)]
    for x in range(lo[0], hi[0] + 1):
        for y in range(lo[1], hi[1] + 1):
            for z in range(lo[2], hi[2] + 1):
                d, t = _seg_dist((x, y, z), a, b)
                if d <= r0 + (r1 - r0) * t and (over or (x, y, z) not in p.v):
                    p.put(x, y, z, part, role)


def bez(a, c, b, n):
    return [[a[i] * (1 - u) ** 2 + c[i] * 2 * u * (1 - u) + b[i] * u * u for i in range(3)] for u in [k / (n - 1) for k in range(n)]]


def vcurve(p, part, role, a, c, b, r0, r1, n=8, over=True):
    pts = bez(a, c, b, n)
    for k in range(n - 1):
        u0, u1 = k / (n - 1), (k + 1) / (n - 1)
        vline(p, part, role, pts[k], pts[k + 1], r0 + (r1 - r0) * u0, r0 + (r1 - r0) * u1, over)


def vtri(p, part, role, A, B, C, th=0.55, over=False):
    """a one-voxel sheet over the triangle ABC (wing membranes)"""
    lo = [math.floor(min(A[i], B[i], C[i]) - 1) for i in range(3)]
    hi = [math.ceil(max(A[i], B[i], C[i]) + 1) for i in range(3)]
    e1 = [B[i] - A[i] for i in range(3)]; e2 = [C[i] - A[i] for i in range(3)]
    nrm = [e1[1] * e2[2] - e1[2] * e2[1], e1[2] * e2[0] - e1[0] * e2[2], e1[0] * e2[1] - e1[1] * e2[0]]
    nl = math.sqrt(sum(v * v for v in nrm)) or 1e-9
    nrm = [v / nl for v in nrm]
    d00 = sum(e1[i] * e1[i] for i in range(3)); d01 = sum(e1[i] * e2[i] for i in range(3)); d11 = sum(e2[i] * e2[i] for i in range(3))
    den = d00 * d11 - d01 * d01 or 1e-9
    for x in range(lo[0], hi[0] + 1):
        for y in range(lo[1], hi[1] + 1):
            for z in range(lo[2], hi[2] + 1):
                w = [x - A[0], y - A[1], z - A[2]]
                dist = sum(w[i] * nrm[i] for i in range(3))
                if abs(dist) > th: continue
                q = [w[i] - nrm[i] * dist for i in range(3)]
                d20 = sum(q[i] * e1[i] for i in range(3)); d21 = sum(q[i] * e2[i] for i in range(3))
                v = (d11 * d20 - d01 * d21) / den; u = (d00 * d21 - d01 * d20) / den
                if v >= -0.02 and u >= -0.02 and u + v <= 1.02 and (over or (x, y, z) not in p.v):
                    p.put(x, y, z, part, role)


def vring(p, part, role, c, R, r, normal=(0, 1, 0)):
    nl = math.sqrt(sum(v * v for v in normal)); n = [v / nl for v in normal]
    lo = [math.floor(c[i] - R - r) for i in range(3)]; hi = [math.ceil(c[i] + R + r) for i in range(3)]
    for x in range(lo[0], hi[0] + 1):
        for y in range(lo[1], hi[1] + 1):
            for z in range(lo[2], hi[2] + 1):
                w = [x - c[0], y - c[1], z - c[2]]
                h = sum(w[i] * n[i] for i in range(3))
                rad = math.sqrt(max(sum(v * v for v in w) - h * h, 0))
                if (rad - R) ** 2 + h * h <= r * r: p.put(x, y, z, part, role)


def drop(p, test):
    for k, (pp, r) in list(p.v.items()):
        if test(k[0], k[1], k[2], pp, r): del p.v[k]


V5_PAL = {}  # name -> extra or changed palette entries for the v5 roles


# ---------------------------------------------------------------- REFINE: per-pet v5 voxel fixes (vault audit section 3, voxel style kept)
def tosk5():
    """the war boar: tusks as connected curves from the jaw, a real strapped pack and bedroll, a flank lantern on its strap,
    pointed ears, a curled tail with a tuft (v4: floating zig-zag tusks, a loose plank and pole, a stick tail)"""
    p = P.tosk4()
    drop(p, lambda x, y, z, pp, r: pp == "Tail" or (pp == "Head" and r == "Tusk") or (pp == "Body" and r in ("Wood", "Metal", "Accent", "Pack", "Leather")))
    drop(p, lambda x, y, z, pp, r: pp == "Head" and r == "Dark" and abs(x) >= 4 and y >= 10)  # the old block ears
    for s in (-1, 1):
        vcurve(p, "Head", "Tusk", (s * 3, 5, 12), (s * 5.5, 5, 14.5), (s * 6, 9, 14), 1.05, 0.55, n=9)
        for (x, y, z) in ((4, 11, 6), (4, 11, 7), (5, 11, 6), (5, 11, 7), (5, 12, 6), (5, 12, 7), (6, 13, 6), (6, 12, 7), (6, 14, 6)):
            p.put(s * x, y, z, "Head", "Main")
        for (x, y) in ((5, 12), (6, 13)): p.put(s * x, y, 8, "Head", "Light")  # inner ear facing forward
    # the pack: a rounded load on the back, two straps round the barrel, a bedroll across the top
    for x in range(-5, 6):
        for y in range(10, 15):
            for z in range(-7, 1):
                if (x / 4.6) ** 2 + ((y - 12.4) / 2.3) ** 2 + ((z + 3) / 3.4) ** 2 <= 1 and (x, y, z) not in p.v: p.put(x, y, z, "Body", "Pack")
    for k, (pp, r) in list(p.v.items()):
        if pp == "Body" and k[2] in (-5, -1) and k[1] >= 5: p.v[k] = ("Body", "Leather")
    for x in range(-5, 6):
        for y in range(14, 18):
            for z in range(-5, -1):
                if (y - 15.5) ** 2 + (z + 3) ** 2 <= 2.6: p.put(x, y, z, "Body", "Cloth" if abs(x) not in (3, 4) else "Leather")
    # the lantern hangs from the right strap
    vline(p, "Body", "Metal", (6, 10, -1), (8, 10, -1), 0.5)
    for (x, y) in ((7, 9), (8, 9), (7, 5), (8, 5)):
        for z in (-2, -1): p.put(x, y, z, "Body", "Metal")
    for x in (7, 8):
        for y in (6, 7, 8):
            for z in (-2, -1): p.put(x, y, z, "Body", "Gem")
    # a curled tail with a dark tuft
    vcurve(p, "Tail", "Main", (0, 9, -8), (0, 11, -11), (1, 13, -10), 1.0, 0.7, n=7)
    for (x, y, z) in ((1, 14, -10), (1, 14, -9), (0, 14, -10), (1, 15, -10)): p.put(x, y, z, "Tail", "Dark")
    p.pivots["Tail"] = (0, 9, -7.5)
    return p


def fafnir5():
    """the hoard drake: real bat wings (bone spars, a scalloped membrane between them), curved horns, calm belly plates
    (v4: flat 1-voxel zig-zag wing boards, noisy striped belly, horns as single-voxel stair steps)"""
    p = P.fafnir4()
    drop(p, lambda x, y, z, pp, r: pp in ("WingL", "WingR") or (pp == "Head" and r == "Horn"))
    for k, (pp, r) in list(p.v.items()):  # belly plates: two rows of plate, one row of seam
        x, y, z = k
        if pp == "Body" and r in ("Light", "Dark", "Metal") and z >= 3 and abs(x) <= 2 and y <= 13:
            p.v[k] = ("Body", "Dark" if y % 3 == 0 else "Light")
    for s in (-1, 1):
        vcurve(p, "Head", "Horn", (s * 2.5, 20, 6), (s * 4.5, 23.5, 3.5), (s * 5.5, 23, -0.5), 1.1, 0.45, n=9)
        vcurve(p, "Head", "Horn", (s * 3, 18, 8), (s * 4.8, 18.5, 7), (s * 5.6, 19.5, 5.5), 0.7, 0.35, n=5)
    for s, nm in ((-1, "WingL"), (1, "WingR")):
        sh, wr = (s * 4.5, 13, -1.5), (s * 10, 18, -3)
        tips = [(s * 17, 19.5, -6), (s * 16, 14, -7.5), (s * 12, 9.5, -7)]
        vline(p, nm, "Dark", sh, wr, 1.0, 0.85)
        for t in tips: vline(p, nm, "Dark", wr, t, 0.75, 0.45)
        vline(p, nm, "Horn", wr, (wr[0] + s * 0.5, wr[1] + 2, wr[2] + 0.5), 0.6, 0.35)  # the wrist claw
        edge = [wr] + tips + [(s * 6, 9, -4)]
        for a, b in zip(tips + [(s * 6, 9, -4)], tips[1:] + [(s * 6, 9, -4)]):
            mid = [a[i] + (b[i] - a[i]) * 0.5 + (wr[i] - (a[i] + b[i]) / 2) * 0.28 for i in range(3)]  # the scallop between spars
            vtri(p, nm, "Wing", wr, a, mid); vtri(p, nm, "Wing", wr, mid, b)
        vtri(p, nm, "Wing", sh, wr, (s * 6, 9, -4))
        p.pivots[nm] = (s * 4.5, 13, -1.5)
    for (x, y, z) in ((0, 10, 7), (0, 11, 7), (-1, 10, 7), (1, 10, 7), (0, 9, 7)): p.put(x, y, z, "Body", "Gem")  # the hoard gem on the chest
    return p


REFINE.update({"Tosk": tosk5, "Fafnir": fafnir5})
V5_PAL.update({"Tosk": {"Gem": "#78ffc8", "Metal": "#d9a441", "Leather": "#5e3a22", "Cloth": "#6a5aa0"},
               "Fafnir": {"Wing": "#2f6a52", "Gem": "#ff3d5a"}})


leg = P.leg


def legv(p, nm, hip, knee, foot, r0, r1, role="Dark", claw=None, s=1):
    """a jointed insect/bird leg: hip -> knee -> foot as tapered capsules; the pivot sits on the hip"""
    vline(p, nm, role, hip, knee, r0, (r0 + r1) / 2)
    vline(p, nm, role, knee, foot, (r0 + r1) / 2, r1)
    if claw: vline(p, nm, claw, foot, (foot[0] + s * 0.8, max(foot[1] - 0.5, 0), foot[2] + 1.4), 0.6, 0.4)
    p.pivots[nm] = hip


def tufts(p, part, role, tip_role, base, ctrl, tip, r0, r1, split=0.72, n=7):
    """a strand that changes colour near its tip (manes, plumes, flame tails)"""
    pts = bez(base, ctrl, tip, n)
    for k in range(n - 1):
        u0, u1 = k / (n - 1), (k + 1) / (n - 1)
        vline(p, part, role if u0 < split else tip_role, pts[k], pts[k + 1], r0 + (r1 - r0) * u0, r0 + (r1 - r0) * u1)


def tosk5b():
    p = tosk5()
    drop(p, lambda x, y, z, pp, r: pp == "Body" and r == "Cloth")
    for x in range(-4, 5):  # a slimmer bedroll across the load, tied twice
        for y in range(13, 17):
            for z in range(-5, -1):
                if (y - 14.6) ** 2 + (z + 3) ** 2 <= 1.6 and (x, y, z) not in p.v: p.put(x, y, z, "Body", "Cloth" if abs(x) != 2 else "Leather")
    for k, (pp, r) in list(p.v.items()):  # the lantern frame is brass, the nose ring stays steel
        if pp == "Body" and r == "Metal": p.v[k] = ("Body", "Brass")
    return p


def fafnir5b():
    p = fafnir5()
    drop(p, lambda x, y, z, pp, r: pp == "Body" and r == "Gem")
    for (x, y) in ((0, 9), (-1, 10), (0, 10), (1, 10), (0, 11)): p.put(x, y, 8, "Body", "Gem")
    for (x, y) in ((-1, 9), (1, 9), (-2, 10), (2, 10), (-1, 11), (1, 11), (0, 12), (0, 8)): p.put(x, y, 7, "Body", "Metal")
    return p


def kobold5():
    """the mine brute: a domed brass helmet with a lamp (v4: a pancake brim), rounded iron pauldrons, a real pickaxe"""
    p = P.kobold4()
    drop(p, lambda x, y, z, pp, r: pp == "ArmR" and r in ("Wood", "Metal", "Gem"))
    drop(p, lambda x, y, z, pp, r: pp == "Head" and r in ("Helmet", "Accent", "Metal", "Gem", "Leather"))
    drop(p, lambda x, y, z, pp, r: pp in ("ArmL", "ArmR") and r == "Metal")
    for x in range(-5, 6):
        for y in range(17, 23):
            for z in range(-3, 8):
                d = (x / 4.6) ** 2 + ((y - 17.5) / 4.2) ** 2 + ((z - 2.5) / 4.6) ** 2
                if d <= 1 and y >= 18: p.put(x, y, z, "Head", "Helmet")
                elif y == 18 and d <= 1.35 and (x, y, z) not in p.v: p.put(x, y, z, "Head", "Helmet")  # the brim
    for (x, y) in ((-1, 19), (0, 19), (1, 19), (-1, 20), (0, 20), (1, 20)): p.put(x, y, 7, "Head", "Gem")  # the lamp
    for (x, y) in ((-2, 19), (2, 19), (-2, 20), (2, 20), (-1, 21), (0, 21), (1, 21)): p.put(x, y, 7, "Head", "Metal")
    for s, nm in ((-1, "ArmL"), (1, "ArmR")):
        for x in range(3, 10):
            for y in range(12, 17):
                for z in range(-3, 5):
                    if ((x - 6) / 2.8) ** 2 + ((y - 13) / 2.2) ** 2 + ((z - 0.5) / 3) ** 2 <= 1 and y >= 13: p.put(s * x, y, z, nm, "Metal")
    T = (8, 11, 8.5)  # the pick held up from the fist, its head across the end of the handle
    vline(p, "ArmR", "Wood", (8, 3.5, 2.5), T, 0.75)
    dn, pr = (0, 0.81, 0.59), (0, -0.59, 0.81)
    f = lambda o, a, b: (o[0], o[1] + dn[1] * a + pr[1] * b, o[2] + dn[2] * a + pr[2] * b)
    vcurve(p, "ArmR", "Metal", T, f(T, 0.8, 2.8), f(T, -0.6, 5.5), 1.2, 0.45, n=7)
    vcurve(p, "ArmR", "Metal", T, f(T, 0.8, -2.4), f(T, -0.4, -4.2), 1.0, 0.45, n=6)
    e = f(T, -0.6, 5.5)
    for (dy, dz) in ((0, 0), (0, 1), (-1, 0)): p.put(8, round(e[1]) + dy, round(e[2]) + dz, "ArmR", "Gem")
    return p


def kepri5():
    """the rhino scarab: a bronze dome with a gold rim and seam, a thick tapered horn with a jewel at its root, mandibles,
    and six jointed legs (v4: a muddy stepped dome, a one-voxel horn, posts for legs)"""
    p = P.Pet("Kepri Scarab")
    p.ell("Body", "Main", 0, 4.5, -3, 5.6, 4.4, 5.6, cut=lambda x, y, z: y >= 2)
    p.paint("Dark", lambda x, y, z: y <= 3, part="Body")
    p.paint("Metal", lambda x, y, z: y == 4 or (x == 0 and y >= 6), part="Body")  # the rim and the seam between the wing cases
    p.paint("Light", lambda x, y, z: abs(x) in (3, 4) and y >= 6 and (z + 3) % 3 == 0, part="Body")  # engraved ridges
    p.ell("Head", "Dark", 0, 5.5, 3, 4.8, 3.6, 2.6, cut=lambda x, y, z: y >= 2)  # the front shield
    p.paint("Metal", lambda x, y, z: y == 2 or (y >= 7 and abs(x) >= 3), part="Head")
    p.box("Head", "Main", -2, 2, 2, 5, 4, 7)
    p.eyes("Head", 3, 7, dx=2, h=2)
    vcurve(p, "Head", "Horn", (0, 7, 7), (0, 15, 10.5), (0, 15.5, 5.5), 2.0, 0.6, n=10)
    for (x, y) in ((0, 8), (-1, 8), (1, 8), (0, 9)): p.put(x, y, 8, "Head", "Gem")
    for s in (-1, 1): vcurve(p, "Head", "Horn", (s * 2, 3, 8), (s * 4, 3, 10.5), (s * 1.5, 3, 11.5), 0.8, 0.45, n=6)
    p.pivots["Head"] = (0, 4, 1)
    for nm, s, z in (("Leg1", -1, 2), ("Leg2", 1, 2), ("Leg5", -1, -2), ("Leg6", 1, -2), ("Leg3", -1, -6), ("Leg4", 1, -6)):
        legv(p, nm, (s * 4.5, 3, z), (s * 8, 5.5, z + (1 if z > 0 else -1)), (s * 9, 0, z + (2 if z > 0 else -2)), 1.0, 0.6, role="Dark", claw="Metal", s=s)
    return p


def shinemane5():
    """the radiant warhorse: a mane of flowing gold strands down the crest, a plumed tail (v4: a block of mane)"""
    p = P.shinemane4()
    drop(p, lambda x, y, z, pp, r: pp in ("Head", "Tail") and r == "Accent")
    drop(p, lambda x, y, z, pp, r: pp == "Tail")
    for i in range(6):
        u = i / 5
        y0, z0 = 21.5 - u * 7.5, 7.5 - u * 5
        tufts(p, "Head", "Accent", "Light", (0, y0, z0), (0, y0 + 1.5, z0 - 2.5), (0.6 * (i % 2 * 2 - 1), y0 - 3, z0 - 4), 1.2, 0.5)
    tufts(p, "Head", "Accent", "Light", (0, 21, 8), (0, 22.5, 10.5), (0, 20, 12), 1.1, 0.5)  # the forelock
    for k in (-1, 0, 1):
        tufts(p, "Tail", "Accent", "Light", (0, 13, -8), (k * 1.5, 15, -12), (k * 2.5, 6, -13), 1.5, 0.6, n=8)
    p.pivots["Tail"] = (0, 12, -7.5)
    return p


def goldbristle5():
    """the armoured quill-back: three tiers of clean tapered quills raked back, splayed past the flanks (v4: random spikes)"""
    p = P.goldbristle4()
    drop(p, lambda x, y, z, pp, r: pp == "Body" and r in ("Accent", "Light"))
    for tier, (zb, yb, L, n) in enumerate(((2, 11, 7, 7), (-2, 10.5, 7.5, 9), (-6, 8.5, 6, 7))):
        for i in range(n):
            a = (i / (n - 1) - 0.5) * 2.4
            bx, by = math.sin(a) * 4.8, yb + (math.cos(a) - 1) * 4.2
            d = (math.sin(a) * 0.8, 0.55 + math.cos(a) * 0.3, -0.75)
            tufts(p, "Body", "Accent", "Light", (bx * 0.85, by - 0.5, zb), (bx + d[0] * L * 0.4, by + d[1] * L * 0.5, zb + d[2] * L * 0.4), (bx + d[0] * L, by + d[1] * L * 0.75, zb + d[2] * L), 1.1, 0.4, split=0.78, n=6)
    return p


def pixiu5():
    """the jade guardian: a 3D mane of curling gold tufts round the face (v4: a flat disc), gold cloud scrolls, a curled tail"""
    p = P.pixiu4()
    drop(p, lambda x, y, z, pp, r: pp == "Head" and z in (2, 3) and r in ("Accent", "Light"))
    drop(p, lambda x, y, z, pp, r: pp == "Tail" or (pp == "Body" and r == "Accent"))
    for ring, (R0, R1, zz, n) in enumerate(((4.2, 7.6, 5, 12), (3.6, 6.4, 3, 10))):
        for i in range(n):
            a = i / n * math.tau + ring * 0.3
            ca, sa = math.cos(a), math.sin(a)
            base = (ca * R0, 11 + sa * R0 * 0.95, zz)
            tip = (ca * R1 - sa * 1.6, 11 + sa * R1 * 0.9 + ca * 1.6, zz - 3)
            ctrl = (ca * (R0 + R1) / 2, 11 + sa * (R0 + R1) / 2, zz)
            tufts(p, "Head", "Accent", "Light", base, ctrl, tip, 1.3, 0.55, split=0.7, n=5)
    for s in (-1, 1):
        pts = [(s * 5, 8 + 1.8 * math.sin(a) * (1 - a / 11), -2 + 1.8 * math.cos(a) * (1 - a / 11)) for a in [k * 0.55 for k in range(18)]]
        for a, b in zip(pts, pts[1:]): vline(p, "Body", "Metal", a, b, 0.5)
    vcurve(p, "Tail", "Main", (0, 8, -7.5), (0, 11, -10), (0, 13, -8), 1.2, 0.9, n=6)
    for (x, y, z, r) in ((0, 14, -8, 1.6), (1.2, 13.5, -9, 1.2), (-1.2, 13.5, -9, 1.2)): p.ell("Tail", "Accent", x, y, z, r, r, r)
    p.pivots["Tail"] = (0, 7.5, -7)
    return p


def glimwisp5():
    """the spirit fox: a lean body, a long pointed snout, tall ears with pink insides, three bushy tails that fade from teal
    through cream into a glowing tip (v4: a confusing cube cluster)"""
    p = P.Pet("Glimwisp")
    p.ell("Body", "Main", 0, 7.5, -1, 3, 3, 5)
    p.ell("Body", "Light", 0, 7, 3, 3.1, 3.3, 2.4)
    p.paint("Light", lambda x, y, z: y <= 5, part="Body")
    p.box("Head", "Main", -3, 3, 10, 14, 2, 6)
    p.ell("Head", "Main", 0, 12, 4, 3.4, 2.9, 2.9)
    vline(p, "Head", "Light", (0, 11, 6), (0, 10.5, 10), 1.8, 0.9)
    p.put(0, 11, 11, "Head", "Dark"); p.put(0, 10, 10, "Head", "Light")
    p.paint("Light", lambda x, y, z: y <= 11 and z >= 5, part="Head")
    p.eyes("Head", 12, 6, dx=2, h=2)
    for s in (-1, 1):
        for zz, role in ((3, "Main"), (4, "Main")):
            vtri(p, "Head", role, (s * 1, 14, zz), (s * 3.5, 14, zz), (s * 3, 19.5, zz - 1), over=True)
        vtri(p, "Head", "Mark", (s * 1.7, 15, 4.6), (s * 3, 15, 4.6), (s * 2.8, 18, 3.8), th=0.45, over=True)
        p.put(s * 3, 12, 6, "Head", "Mark")
    p.pivots["Head"] = (0, 10, 2)
    leg(p, "Leg1", -2, -1, 2, 3, 4, role="Main", foot="Light"); leg(p, "Leg2", 1, 2, 2, 3, 4, role="Main", foot="Light")
    leg(p, "Leg3", -2, -1, -5, -4, 4, role="Main", foot="Light"); leg(p, "Leg4", 1, 2, -5, -4, 4, role="Main", foot="Light")
    for side in (-1, 0, 1):
        a = (side * 0.8, 8, -5)
        c = (side * 4.5, 9, -11)
        t = (side * 6.5, 16 - abs(side) * 1.5, -12)
        pts = bez(a, c, t, 9)
        for k in range(8):
            u = k / 8
            r = 1.2 + 1.3 * math.sin(min(u * 1.25, 1) * math.pi * 0.9)
            role = "Main" if u < 0.4 else ("Light" if u < 0.72 else "Gem")
            vline(p, "Tail", role, pts[k], pts[k + 1], r if u < 0.85 else 0.9, r if u < 0.75 else 0.6)
    p.pivots["Tail"] = (0, 8, -4.5)
    return p


def selkie5():
    """the diver walrus: paddle flippers and swept flukes (v4: block slabs), no speckles, a brass tank on straps"""
    p = P.selkie4()
    drop(p, lambda x, y, z, pp, r: pp in ("FinL", "FinR", "Tail") or (pp == "Body" and r == "Dark"))
    for s, nm in ((-1, "FinL"), (1, "FinR")):
        for yy in (0, 1):
            vtri(p, nm, "Dark", (s * 4, 3 + yy, 3), (s * 8.5, 0.4 + yy, 6), (s * 7.5, 0.4 + yy, 1), over=True)
        vline(p, nm, "Main", (s * 4, 5, 2), (s * 5, 2, 3), 1.3)
        p.pivots[nm] = (s * 4.5, 5, 2)
    vline(p, "Tail", "Main", (0, 1.5, -9), (0, 1.5, -11), 1.4, 1.0)
    for s in (-1, 1):
        for yy in (0, 1):
            vtri(p, "Tail", "Dark", (0, 1 + yy, -11), (s * 5, 1.5 + yy, -14), (s * 2, 1 + yy, -13.5), over=True)
    p.pivots["Tail"] = (0, 1, -9.5)
    return p


def zharbird5():
    """the firebird raptor: breast feather rows instead of ember speckles, wings of separate fanned flight feathers, long
    ribbon plumes with glowing tips, a flame crest"""
    p = P.zharbird4()
    drop(p, lambda x, y, z, pp, r: pp in ("WingL", "WingR", "Tail") or (pp == "Head" and r == "Accent"))
    for k, (pp, r) in list(p.v.items()):
        x, y, z = k
        if pp == "Body" and r == "Accent": p.v[k] = ("Body", "Light")
        if pp == "Body" and r == "Light" and y in (4, 7, 10) and (x + z) % 2 == 0: p.v[k] = ("Body", "Accent")  # rows of breast feathers
    for i, (x, h) in enumerate(((-1.5, 4), (0, 6.5), (1.5, 5))):
        tufts(p, "Head", "Accent", "Light", (x, 16, 3), (x * 1.4, 19, 2), (x * 1.8, 16 + h, -1), 1.0, 0.45, split=0.6, n=6)
    for s, nm in ((-1, "WingL"), (1, "WingR")):
        sh = (s * 4, 11, -1.5)
        arm = (s * 8, 15, -2.5)
        vline(p, nm, "Main", sh, arm, 1.4, 1.1)
        for i in range(6):
            u = i / 5
            b0 = [sh[j] + (arm[j] - sh[j]) * min(1, u * 1.2) for j in range(3)]
            tip = (s * (8 + 4.5 * u), 18 - 9 * u, -4 - 1.5 * u)
            tufts(p, nm, "Main" if i % 2 else "Dark", "Accent", b0, ((b0[0] + tip[0]) / 2, (b0[1] + tip[1]) / 2 + 1, -3), tip, 1.0, 0.5, split=0.7, n=6)
        p.pivots[nm] = (s * 4, 11, -1.5)
    for x in (-2, 0, 2):
        sgn = (x > 0) - (x < 0)
        tufts(p, "Tail", "Accent", "Light", (x * 0.5, 7, -3), (x * 1.5, 6, -9), (x * 3 + sgn, 9, -15), 0.9, 0.5, split=0.8, n=8)
        p.put(x * 3 + sgn, 9, -16, "Tail", "Gem"); p.put(x * 3 + sgn, 10, -16, "Tail", "Gem")
    p.pivots["Tail"] = (0, 6.5, -3.5)
    return p


def kirin5():
    """the storm qilin: a long dragon head with branched gold antlers and whiskers, a flowing pale flame mane, ordered scale
    rows and a gold chevron line down the back (v4: a blue horse with orange slabs and speckled scales)"""
    p = P.kirin4()
    drop(p, lambda x, y, z, pp, r: (pp == "Head" and r in ("Accent", "Horn")) or pp == "Tail" or (pp == "Body" and r == "Accent"))
    for k, (pp, r) in list(p.v.items()):
        x, y, z = k
        if pp == "Body" and r == "Dark": p.v[k] = ("Body", "Main")
        if pp == "Body" and r == "Main" and y >= 13 and abs(x) >= 2 and (y + (z // 2)) % 3 == 0: p.v[k] = ("Body", "Dark")  # scale rows
        if pp == "Body" and y >= 14 and x == 0 and z % 2 == 0: p.v[k] = ("Body", "Metal")
    vline(p, "Head", "Main", (0, 18, 11), (0, 17.5, 14), 1.6, 1.2, over=False)  # a longer dragon muzzle
    p.put(-1, 18, 15, "Head", "Dark"); p.put(1, 18, 15, "Head", "Dark")
    for s in (-1, 1):
        vcurve(p, "Head", "Horn", (s * 1.5, 21, 8), (s * 3.5, 25, 6), (s * 4.5, 27, 3), 0.9, 0.5, n=8)
        vline(p, "Head", "Horn", (s * 2.7, 23.5, 6.5), (s * 2.5, 26.5, 8), 0.6, 0.4)
        vline(p, "Head", "Horn", (s * 3.9, 26, 4.5), (s * 5.5, 28, 5), 0.55, 0.4)
        vcurve(p, "Head", "Metal", (s * 2, 17, 14), (s * 6, 17, 15), (s * 6.5, 13, 12), 0.5, 0.4, n=7)  # whiskers
    tufts(p, "Head", "Flame", "Light", (0, 15, 12), (0, 12.5, 12.5), (0, 11, 10.5), 1.0, 0.5)  # the beard
    for i in range(7):  # the mane: C-curved flame ribbons down the neck and over the withers
        u = i / 6
        y0, z0 = 21 - u * 8, 6 - u * 7
        tufts(p, "Head" if u < 0.35 else "Body", "Flame", "Light", (0, y0, z0), (0.8 * (i % 2 * 2 - 1), y0 + 2.5, z0 - 1.5), (1.2 * (i % 2 * 2 - 1), y0 + 1, z0 - 4), 1.2, 0.5)
    tufts(p, "Tail", "Main", "Main", (0, 12, -8), (0, 13, -11), (0, 10, -12), 0.9, 0.8, n=5)
    for k in (-1, 0, 1):
        tufts(p, "Tail", "Flame", "Light", (0, 10, -12), (k * 2, 9, -14), (k * 2.5, 12, -16), 1.3, 0.5, n=6)
    p.pivots["Tail"] = (0, 11, -7.5)
    return p


def ouro5():
    """the void ouroboros: an upright figure-8 coil seen whole from the front and from the town camera, scale chevrons and
    gold bands along it, a singularity orb in one loop, a horned cobra head with a ribbed hood biting its tail
    (v4: a flat ring like a tyre)"""
    p = P.Pet("Ouro")
    a, b, cy = 9.0, 12.5, 9.5

    def L(t):
        d = 1 + math.sin(t) ** 2
        return (a * math.cos(t) / d, cy + b * math.sin(t) * math.cos(t) / d, 1.8 * math.sin(t))
    t0 = math.pi / 4 + 0.45
    n = 72
    ts = [t0 + (2 * math.pi - 0.9) * k / n for k in range(n + 1)]
    pts = [L(t) for t in ts]
    ox = -(pts[0][0] + 1.5)  # centre the head on x = 0 (the eyes and the game's head part expect it)
    pts = [(q[0] + ox, q[1], q[2]) for q in pts]
    for k in range(n):
        u = k / n
        vline(p, "Body", "Main", pts[k], pts[k + 1], 2.5 - 1.6 * u, 2.5 - 1.6 * (k + 1) / n)
    for k in range(0, n, 6):  # gold bands round the coil
        u = k / n
        c = pts[k]; tg = [pts[k + 1][i] - pts[k][i] for i in range(3)]
        tl = math.sqrt(sum(v * v for v in tg)) or 1
        R = 2.5 - 1.6 * u + 0.7
        for x in range(int(c[0] - R) - 1, int(c[0] + R) + 2):
            for y in range(int(c[1] - R) - 1, int(c[1] + R) + 2):
                for z in range(int(c[2] - R) - 1, int(c[2] + R) + 2):
                    if (x, y, z) in p.v and abs(sum((q - c[i]) * tg[i] / tl for i, q in enumerate((x, y, z)))) < 0.5:
                        p.v[(x, y, z)] = ("Body", "Metal" if k % 12 == 0 else "Dark")
    for k, (pp, r) in list(p.v.items()):  # a pale belly on the inner side of each loop, magenta seams on the outer side
        x, y, z = k
        if pp == "Body" and r == "Main" and z <= -1: p.v[k] = ("Body", "Light")
    p.ell("Body", "Gem", -5.2 + ox, cy, 0, 1.6, 1.6, 1.6)  # the singularity in the left loop
    vring(p, "Body", "Metal", (-5.2 + ox, cy, 0), 2.6, 0.5, normal=(0.3, 0.5, 1))
    hx, hy, hz = pts[0][0] + 1.5, pts[0][1] + 3.5, 2.5
    p.ell("Head", "Main", hx, hy, hz, 3, 2.6, 3)
    vline(p, "Head", "Main", (hx, hy - 0.5, hz + 1), (hx, hy - 1.2, hz + 5), 2.1, 1.4)
    p.box("Head", "Light", int(hx) - 1, int(hx) + 1, int(hy) - 3, int(hy) - 2, int(hz) + 1, int(hz) + 5)
    vline(p, "Head", "Main", pts[0], (hx, hy - 1, hz - 1), 2.4, 2.2)  # the neck
    for x in range(-7, 8):  # the hood: a flared ribbed fan behind the head
        for y in range(-1, 9):
            if (x / 6.5) ** 2 + ((y - 3) / 5.2) ** 2 <= 1:
                p.put(int(hx) + x, int(hy) + y - 2, int(hz) - 2, "Head", "Dark" if abs(x) >= 5 or y >= 7 else ("Metal" if x in (-3, 3) else "Main"))
    for s in (-1, 1):
        vcurve(p, "Head", "Accent", (hx + s * 2, hy + 2, hz), (hx + s * 4, hy + 5, hz - 2), (hx + s * 5, hy + 5, hz - 5), 0.9, 0.45, n=7)
        vline(p, "Head", "Horn", (hx + s * 1, hy - 3, hz + 4.5), (hx + s * 1, hy - 4.5, hz + 4.5), 0.5, 0.35)
    p.eyes("Head", int(hy), int(hz + 3), dx=2, h=2)
    p.pivots["Head"] = (pts[0][0], pts[0][1], pts[0][2])
    vring(p, "Body", "Metal", pts[-1], 1.4, 0.5, normal=[pts[-1][i] - pts[-2][i] for i in range(3)])  # the clasp on the tail tip
    return p


def ninering5():
    """the celestial seraph: a floating layered robe with gold hems, gold pauldrons, a glowing chest prism, a porcelain face
    under a hood and diadem, two pairs of small wings, inside nine large tilted gold rings with sapphire nodes
    (v4: a pale blob among small square donuts)"""
    p = P.Pet("Ninering")
    for (y, r, role) in ((2, 1.2, "Light"), (3, 1.8, "Light"), (4, 2.5, "Main"), (5, 3.1, "Main"), (6, 3.6, "Main"), (7, 4.1, "Main"), (8, 4.4, "Main")):
        p.ell("Body", role, 0, y, 0, r, 0.8, r * 0.85)
    for y in (4, 8):  # gold hems
        for k, (pp, r) in list(p.v.items()):
            if pp == "Body" and k[1] == y and k[0] ** 2 + (k[2] / 0.85) ** 2 >= (4.4 if y == 8 else 2.5) ** 2 * 0.55: p.v[k] = ("Body", "Ring")
    p.ell("Body", "Main", 0, 10.5, 0, 4.2, 2.6, 3.2)
    for s in (-1, 1): p.ell("Body", "Ring", s * 4.2, 12, 0, 1.9, 1.3, 1.9, cut=lambda x, y, z: y >= 12)
    for (x, y) in ((0, 10), (-1, 11), (0, 11), (1, 11), (0, 12)): p.put(x, y, 3, "Body", "Gem")
    for (x, y) in ((-1, 10), (1, 10), (-2, 11), (2, 11), (-1, 12), (1, 12), (0, 13), (0, 9)): p.put(x, y, 2, "Body", "Ring")
    for s in (-1, 1):  # two pairs of small wings from the shoulder blades
        vtri(p, "Body", "Light", (s * 2, 12, -3), (s * 8, 18, -5), (s * 9, 14, -5), over=True)
        vline(p, "Body", "Ring", (s * 2, 12, -3), (s * 8, 18, -5), 0.45)
        vtri(p, "Body", "Light", (s * 2, 9, -3), (s * 7, 6, -5), (s * 8, 9.5, -5), over=True)
    p.ell("Head", "Light", 0, 15.5, 0.5, 2.8, 2.9, 2.6)
    for x in range(-4, 5):  # the hood behind and over the head
        for y in range(13, 20):
            for z in range(-4, 2):
                if (x / 3.5) ** 2 + ((y - 16) / 3.6) ** 2 + ((z + 0.5) / 3.3) ** 2 <= 1 and (x, y, z) not in p.v and z <= 0: p.put(x, y, z, "Head", "Dark")
    for x in (-2, -1, 0, 1, 2): p.put(x, 18, 2, "Head", "Ring")
    for (x, y) in ((-2, 19), (0, 19), (0, 20), (2, 19)): p.put(x, y, 2, "Head", "Ring")
    p.put(0, 19, 3, "Head", "Gem")
    p.eyes("Head", 15, 2, dx=2, h=2)
    p.pivots["Head"] = (0, 13, 0)
    for i in range(9):
        R = 7 + 0.62 * i
        tilt = math.radians(20 + 17 * i)
        az = i * 2.2
        nrm = (math.sin(tilt) * math.cos(az), math.cos(tilt), math.sin(tilt) * math.sin(az))
        nm = f"Ring{i + 1}"
        vring(p, nm, "Ring", (0, 11, 0), R, 0.55, normal=nrm)
        cells = [k for k, (pp, r) in p.v.items() if pp == nm]
        top = max(cells, key=lambda k: k[1]); bot = min(cells, key=lambda k: k[1])
        p.v[top] = (nm, "Gem"); p.v[bot] = (nm, "Gem")
        p.pivots[nm] = (0, 11, 0)
    return p


REFINE.update({"Tosk": tosk5b, "Fafnir": fafnir5b, "Kobold": kobold5, "Kepri Scarab": kepri5, "Shinemane": shinemane5,
               "Goldbristle": goldbristle5, "Pixiu": pixiu5, "Glimwisp": glimwisp5, "Selkie": selkie5, "Zharbird": zharbird5,
               "Kirin": kirin5, "Ouro": ouro5, "Ninering": ninering5})
V5_PAL["Tosk"].update({"Brass": "#d9a441", "Cloth": "#4c6a74", "Metal": "#c8ccd8"})
V5_PAL.update({"Kobold": {"Metal": "#9aa2b8", "Gem": "#ffd27a"}, "Kepri Scarab": {"Main": "#8a5a24", "Dark": "#3e2a12", "Light": "#c08a3c", "Horn": "#b8862e", "Gem": "#3fd6ff"},
               "Goldbristle": {"Accent": "#e8b438", "Light": "#fff0b0"}, "Glimwisp": {"Gem": "#ff9ad0", "Mark": "#ff8a9a", "Light": "#f2f4e4"},
               "Selkie": {"Dark": "#2c3252"}, "Zharbird": {"Gem": "#40f0ff", "Dark": "#8a240c"},
               "Kirin": {"Flame": "#d8f6ff", "Metal": "#f0c040", "Horn": "#f0c040", "Light": "#ffffff"},
               "Ouro": {"Eye": "#14081e", "Light": "#7a5aa8", "Dark": "#21153a", "Horn": "#f4f0e0", "Gem": "#ff4aa0"},
               "Ninering": {"Ring": "#f0c850", "Gem": "#5aa8ff", "Dark": "#6a5aa8", "Main": "#ece4f6", "Light": "#fbf8ff"}})


def build(names=()):
    out = []
    for b in P.BUILDERS:
        name = b().name
        if names and name not in names and name.replace(" ", "") not in names: continue
        p = REFINE.get(name, b)()
        P.add_chains(p)
        fine = {}
        draw_eyes(p, fine)
        d = p.data()
        d["fine"] = {}
        for (x, y, z), (pp, r) in fine.items(): d["fine"].setdefault(pp, []).append([x, y, z, r])
        full = {**P.ROLES, **P.PALETTES[name], **P.ROLE_OVERRIDES.get(name, {}), **V5_PAL.get(name, {})}
        if name in IRIS: full["Iris"] = IRIS[name]
        roles = {v[3] for vs in d["parts"].values() for v in vs} | {v[3] for vs in d["fine"].values() for v in vs}
        d["palette"] = {r: c for r, c in full.items() if r in roles}
        assert not roles - set(d["palette"]), (name, roles - set(d["palette"]))
        out.append(d)
        print(f"{name:14} {len(p.v):5} voxels + {len(fine)} fine  {d['height']:2} tall")
    return out


if __name__ == "__main__":
    names = set(sys.argv[1:])
    dbp = os.path.join(here, "pets5.json")
    db = {d["name"]: d for d in json.load(open(dbp))} if os.path.exists(dbp) and names else {}
    for d in build(names): db[d["name"]] = d
    order = [b().name for b in P.BUILDERS]
    json.dump([db[n] for n in order if n in db], open(dbp, "w"), separators=(",", ":"))
