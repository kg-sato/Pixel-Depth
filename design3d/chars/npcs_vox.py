"""Named NPCs as hi-detail voxel characters (Master Directive v17, 2026-11-26; built 2026-11-27): the pets' own pipeline
(design3d/pets/vox_kit.py + plate_kit.py, cell 0.1 studs, form shading, no smooth blobs), so they share the rig loader
(Shared.PetVoxels builds and animates them from Shared.PetRigData) and Shared.CharRigs stands them in for the part-built
placeholders. Blender axes: x right, y forward (the face), z up; feet at z 0.
    blender -b -P design3d/chars/npcs_vox.py -- <out_dir> [Name ...]
Writes <Name>.glb and merges the rig data into design3d/pets/rigs.json (make_rig_lua.py then writes Shared.PetRigData)."""
import json, math, os, sys
here = os.path.dirname(os.path.abspath(__file__))
pets = os.path.join(os.path.dirname(here), "pets")
sys.path.insert(0, pets)
import plate_kit as K
import vox_kit as X
from plate_kit import V
import pet_vox as P  # its helpers (palette, shade, E, surf, foot_paw, ground); its own pets build only when run directly

args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
OUT = os.path.abspath(args[0] if args else os.path.join(here, "out_vox"))
ONLY = set(a for a in args[1:] if not a.startswith("-"))
os.makedirs(OUT, exist_ok=True)
D = {}


def round_eye(v, part, c, normal, w, h, skin=None, iris="Iris"):
    """v.eye plus a second small catchlight low on the other side; with skin, the four corner cells of the eye's front face go
    back to the skin, so it reads as a rounded eye and not a square goggle"""
    v.eye(part, c, normal, w=w, h=h, iris=iris)
    c, n = V(c), V(normal).normalized(); up = V(0, 0, 1); side = n.cross(up).normalized()
    if skin:
        cells = [(k, (V((k[0] + 0.5) * v.s, (k[1] + 0.5) * v.s, (k[2] + 0.5) * v.s) - c)) for k, (p, col) in v.cells.items() if p == part and col in ("Eye", iris)]
        cells = [(k, q.dot(side), q.dot(up)) for k, q in cells if abs(q.dot(side)) <= w / 2 + v.s and abs(q.dot(up)) <= h / 2 + v.s]
        if cells:
            s0, s1 = min(a for _, a, _ in cells), max(a for _, a, _ in cells); u0, u1 = min(b for _, _, b in cells), max(b for _, _, b in cells)
            for k, a, b in cells:
                if (abs(a - s0) < v.s * 0.6 or abs(a - s1) < v.s * 0.6) and (abs(b - u0) < v.s * 0.6 or abs(b - u1) < v.s * 0.6):
                    v.cells[k] = (part, skin)
    v.box(part, "Shine", c - up * (h / 2 - v.s * 1.6) + side * (w / 2 - v.s * 1.6) * (1 if n.x >= 0 else -1) + n * v.s * 0.3, (v.s * 0.8, v.s * 0.8, v.s * 0.8))


def despeckle(v, rounds=2):
    """graders kept calling the form shading "salt-and-pepper noise": a shade cell (X, XHi, XLo, XCrease) with at most one
    same-tone neighbour among its shade-family neighbours takes the family's majority tone"""
    fam = {}
    for _, col in v.cells.values():
        for suf in ("Hi", "Lo", "Crease"):
            if col.endswith(suf): fam[col] = col[: -len(suf)]
    for _, col in list(v.cells.values()):
        if col in fam.values(): fam.setdefault(col, col)
    nb = [(a, b, c) for a in (-1, 0, 1) for b in (-1, 0, 1) for c in (-1, 0, 1) if (a, b, c) != (0, 0, 0)]
    for _ in range(rounds):
        out = {}
        for k, (part, col) in v.cells.items():
            base = fam.get(col)
            if base is None: continue
            same, tally = 0, {}
            for a, b, c in nb:
                q = v.cells.get((k[0] + a, k[1] + b, k[2] + c))
                if q is None or q[0] != part or fam.get(q[1]) != base: continue
                tally[q[1]] = tally.get(q[1], 0) + 1
                if q[1] == col: same += 1
            if same <= 1 and sum(tally.values()) >= 5:
                out[k] = (part, max(tally, key=tally.get))
        v.cells.update(out)


def flat_eye(v, part, c, normal, w, h, iris_frac=0.4, eye="Eye", iris="Iris", shine="Shine"):
    """a painted eye flush with the face (graders: a carved eye socket reads as a hollow, sunken stare): an ellipse of dark eye,
    its lower part in the iris tone, a 2x2 catchlight up and out and a 1-cell glint low and in, both a hair proud"""
    c, n = V(c), V(normal).normalized(); up = V(0, 0, 1); side = n.cross(up).normalized(); up = side.cross(n).normalized() * -1 if side.cross(n).z < 0 else side.cross(n).normalized()
    def inside(x, y, z):
        q = V(x, y, z) - c
        return (q.dot(side) / (w / 2)) ** 2 + (q.dot(up) / (h / 2)) ** 2 <= 1 and -v.s * 2.5 <= q.dot(n) <= v.s * 1.5
    v.paint(eye, inside, part=part)
    v.paint(iris, lambda x, y, z: inside(x, y, z) and (V(x, y, z) - c).dot(up) < -h / 2 + h * iris_frac, part=part)
    o = 1 if n.x >= 0 else -1
    v.box(part, shine, c + up * (h * 0.24) - side * (w * 0.2) * o + n * v.s * 0.6, (v.s * 1.2, v.s * 1.2, v.s * 1.2))
    v.box(part, shine, c - up * (h * 0.28) + side * (w * 0.2) * o + n * v.s * 0.6, (v.s * 0.9, v.s * 0.9, v.s * 0.9))


def soft_tops(pal, names, k=0.35):
    """graders read the lighter top faces on big curved stone as dithered noise: pull each named family's Top tones toward the
    side tone (k = how much of the top lift is kept)"""
    def mix(a, b):
        a, b = a.lstrip("#"), b.lstrip("#")
        return "#" + "".join("%02x" % round(int(a[i:i + 2], 16) + (int(b[i:i + 2], 16) - int(a[i:i + 2], 16)) * k) for i in (0, 2, 4))
    out = dict(pal)
    for n in names:
        for suf in ("", "Hi", "Lo", "Crease"):
            if n + suf in out and n + suf + "Top" in out: out[n + suf + "Top"] = mix(out[n + suf], out[n + suf + "Top"])
    return out


def char(name, pal):
    def deco(fn): D[name] = (pal, fn); return fn
    return deco


# ---------------------------------------------------------------- BOLT: the raccoon master smith (the Forge)
@char("Bolt", P.palette(form=("Fur", "Shirt", "Apron"), Fur="#8d8a9c", FurDark="#4a4656", Mask="#25212c", White="#eeedf3", Shirt="#40588c",
                        Apron="#b8865a", Strap="#8a5a34", Iron="#9aa0b4", Brass="#d9a843", Pink="#b04a52", Blush="#e88a9a", Glow="#ff9a36", Nose="#18131c",
                        Claw="#d8d0c4", Ember="#ff5a1e", Crystal="#ffb050", Edge="#b8b0c8", Eye="#1a1020", Iris="#ffb43a", IronLo="#3e404c"))
def bolt(v):
    E = P.E
    v.joint("Body", (0, 0, 2.05))
    # a broad husky smith: a barrel chest in a rolled-sleeve indigo shirt, a cream leather apron with an iron buckle and straps
    v.muscle("Body", "Shirt", (0, 0.05, 3.05), (1.05, 0.78, 0.82))
    v.muscle("Body", "Shirt", (0, 0.0, 2.35), (0.92, 0.72, 0.62))
    for s in (-1, 1): v.muscle("Body", "Shirt", (s * 0.78, 0.0, 3.4), (0.48, 0.5, 0.42))  # the shoulder masses
    v.muscle("Body", "FurDark", (0, -0.05, 1.75), (0.82, 0.62, 0.42))  # the hips
    P.shade(v, "Shirt")
    # round 3 (Gemini: "a paper-thin plate"): the apron wraps the barrel chest: a thick curved bib, a skirt that flares, side panels
    v.ell("Body", "Apron", (0, 0.64, 2.6), (0.88, 0.4, 1.05), cut=lambda x, y, z: y < 0.62)  # round 4: proud of the chest, so the bib shows
    v.ell("Body", "Apron", (0, 0.5, 1.5), (1.0, 0.38, 0.62), cut=lambda x, y, z: y < 0.48 or z > 1.95)
    for s2 in (-1, 1): v.box("Body", "ApronLo", (s2 * 0.86, 0.38, 1.9), (0.14, 0.5, 1.3))
    v.paint("ApronLo", lambda x, y, z: z < 1.25 or abs(x) > 0.66, part="Body", only={"Apron"})
    for z in (2.1, 1.3): v.box("Body", "Strap", (0, 0.86, z), (1.5, 0.08, 0.1))  # stitched seams
    v.box("Body", "Iron", (0, 0.86, 3.05), (0.46, 0.14, 0.34))  # the buckle
    v.box("Body", "Brass", (0, 0.94, 3.05), (0.26, 0.08, 0.16))
    for s in (-1, 1):
        v.curve("Body", "Strap", [(s * 0.55, 0.72, 3.2), (s * 0.72, 0.45, 3.7), (s * 0.55, -0.2, 3.75), (s * 0.35, -0.62, 2.9)], [0.07, 0.07, 0.07, 0.07])
        v.box("Body", "ApronLo", (s * 0.5, 0.95, 1.55), (0.5, 0.12, 0.42))  # a pocket
        if s > 0: v.box("Body", "Iron", (s * 0.62, 1.0, 1.8), (0.16, 0.1, 0.55))  # a file in it (round 9: the tongs moved to the off paw)
    v.box("Body", "Strap", (0, 0.05, 1.98), (1.7, 1.38, 0.16))  # the belt
    for s in (-1, 1):  # round 8: a crossed tool harness on the back, and a hammer loop pouch at the belt
        v.curve("Body", "Strap", [(s * 0.62, -0.62, 3.65), (s * 0.2, -0.86, 3.0), (-s * 0.3, -0.84, 2.45), (-s * 0.6, -0.7, 2.05)], [0.08, 0.08, 0.08, 0.08])
    v.box("Body", "Iron", (0, -0.9, 2.85), (0.22, 0.1, 0.22))
    v.box("Body", "ApronLo", (0.55, -0.78, 1.82), (0.42, 0.2, 0.4))
    v.box("Body", "Brass", (0.55, -0.9, 1.92), (0.12, 0.06, 0.1))
    v.box("Body", "Brass", (0, 0.72, 1.98), (0.26, 0.08, 0.2))
    for s in (-1, 1): v.ell("Body", "Shirt", (s * 1.0, 0.0, 3.5), (0.5, 0.55, 0.42))  # round 17: rounded shoulders over the arm joins
    for s in (-1, 1):  # b18: leather pauldrons with brass rivets, a shoulder read from the town camera
        v.ell("Body", "Strap", (s * 1.12, 0.0, 3.78), (0.52, 0.58, 0.2), rot=E(0, s * 24, 0))
        for k in (-1, 0, 1): v.ell("Body", "Brass", (s * 1.2, k * 0.32, 3.92 - abs(k) * 0.05), (0.06, 0.06, 0.05))
    for s in (-1, 1): v.ell("Body", "Strap", (s * 0.62, -0.05, 3.72), (0.5, 0.62, 0.14), rot=E(0, s * 16, 0))  # round 9: a leather yoke over each shoulder (Gemini r8: the torso a blue blob from the town camera)
    v.box("Body", "Brass", (0, -0.72, 3.7), (0.3, 0.08, 0.12))  # its back clasp
    v.anchor("chest", "Body", (0, 0.8, 3.0))
    # the head: a big raccoon head, grey fur, a dark bandit mask round amber eyes, white cheek tufts and muzzle, notched ears
    v.joint("Head", (0, 0.1, 3.85), "Body", "head")
    v.muscle("Head", "Fur", (0, 0.05, 4.65), (0.98, 0.86, 0.82))
    v.muscle("Head", "Fur", (0, 0.35, 4.45), (0.8, 0.72, 0.62))
    P.shade(v, "Fur", parts={"Head"})
    for s in (-1, 1):
        v.ell("Head", "White", (s * 0.62, 0.55, 4.3), (0.42, 0.34, 0.32))  # cheek tufts
        for k in range(3): v.crystal("Head", "FurDark", V(s * (0.8 + 0.08 * k), 0.45 - 0.12 * k, 4.12 + 0.14 * k), (s * 1, -0.2, -0.35), 0.55, 0.16, sides=4)  # b18: flared cheek tufts, dark with white tips
        for k in range(3): v.crystal("Head", "White", V(s * (1.2 + 0.08 * k), 0.4 - 0.12 * k, 3.98 + 0.14 * k), (s * 1, -0.2, -0.35), 0.28, 0.1, sides=4)
        v.ell("Head", "Mask", (s * 0.4, 0.78, 4.78), (0.36, 0.2, 0.24), rot=E(0, 0, s * -14))  # the mask band over each eye
        v.ell("Head", "Edge", (s * 0.37, 0.9, 4.8), (0.3, 0.06, 0.28))  # round 8: a pale rim so the eye reads against the mask
        v.eye("Head", (s * 0.37, 0.92, 4.8), (s * 0.35, 1, 0.12), w=0.38, h=0.36, iris="Iris")  # round 14: bigger again (r13: eyes lost in the mask)  # round 2: bigger, so the face reads from the town camera
        v.ell("Head", "Blush", (s * 0.62, 0.86, 4.42), (0.13, 0.05, 0.08))  # blush
        # notched ears with dark backs and pale insides
        v.ell("Head", "FurDark", (s * 0.6, -0.05, 5.5), (0.3, 0.16, 0.36), rot=E(0, s * -18, 0))
        v.ell("Head", "White", (s * 0.6, 0.06, 5.48), (0.18, 0.06, 0.24), rot=E(0, s * -18, 0))
    v.box("Head", "Mask", (0, 0.86, 4.8), (0.4, 0.12, 0.16))  # the mask's bridge
    v.ell("Head", "FurHi", (0, 0.72, 5.0), (0.62, 0.22, 0.14))  # round 6: a brow ridge one voxel proud over the mask
    v.ell("Head", "White", (0, 1.06, 4.36), (0.42, 0.4, 0.3))
    v.ell("Head", "White", (0, 1.3, 4.42), (0.26, 0.26, 0.2))  # round 17: a tapered snout tip, depth in the profile  # the muzzle (round 15: a voxel further out, depth under the eyes)
    v.ell("Head", "Nose", (0, 1.54, 4.5), (0.15, 0.1, 0.11))
    v.box("Head", "Nose", (0, 1.3, 4.2), (0.36, 0.08, 0.06))  # b18: a mouth cleft under the snout
    v.box("Head", "Nose", (0, 1.4, 4.3), (0.06, 0.06, 0.14))
    v.box("Head", "FurDark", (0, 0.4, 5.2), (0.2, 0.5, 0.2))  # a dark stripe up the brow
    for k in range(5): v.crystal("Body", "White", V(-0.3 + 0.15 * k, 0.55, 3.72), (0, 0.4, 1), 0.22, 0.08, sides=4)  # chest fur at the collar
    # the pink headband with brass smith goggles pushed up on it
    v.torus("Head", "Pink", (0, 0.02, 5.08), (0, 0, 1), 0.86, 0.09)
    for s in (-1, 1):
        v.torus("Head", "Strap", (s * 0.29, 0.76, 5.24), (0, 0.85, 0.5), 0.22, 0.06)  # b19: slimmer goggles, lenses recessed (b20: bronze-dark frames)
        v.ell("Head", "Crystal", (s * 0.29, 0.76, 5.25), (0.15, 0.04, 0.15))
        v.ell("Head", "Shine", (s * 0.29 - 0.06, 0.8, 5.31), (0.04, 0.03, 0.04))
    v.box("Head", "Brass", (0, 0.84, 5.22), (0.18, 0.06, 0.06))
    v.anchor("eyes", "Head", (0, 0.95, 4.8)); v.anchor("speech", "Head", (0, 0.0, 5.9))
    # arms: indigo sleeves rolled to the elbow (a cream cuff), grey furred forearms, dark paws; the right paw holds a forge hammer
    for s, A in ((-1, "ArmL"), (1, "ArmR")):
        sh, el, wr = V(s * 1.05, 0.05, 3.45), (V(s * 1.9, 0.1, 3.05) if s > 0 else V(-1.7, 0.42, 2.68)), (V(s * 2.45, 0.2, 3.65) if s > 0 else V(-1.95, 1.2, 3.05))  # round 15: a bent elbow, the forearm forward (r14: a stiff diagonal stick); round 14: the off paw holds the tongs out forward-left, away from the hammer and tail in the 3/4 blackout  # round 12: the off paw raised too, showing the hot ingot (r11: the lowered tongs clumped with the tail)  # round 3: arms clear of the body; the right one raises the hammer
        v.joint(A + "1", tuple(sh), "Body", "arm")
        v.cap(A + "1", "Shirt", sh, el, 0.45, 0.39)  # round 2: heavier smith's arms
        v.torus(A + "1", "Apron", el + (sh - el) * 0.12, (sh - el).normalized(), 0.34, 0.08)
        v.torus(A + "1", "Edge", sh + (el - sh) * 0.12, (el - sh).normalized(), 0.46, 0.05)  # b19: a pale stitch at the shoulder seam
        P.shade(v, "Shirt", parts={A + "1"})
        v.joint(A + "2", tuple(el), A + "1", "arm")
        v.cap(A + "2", "Fur", el, wr, 0.37, 0.31)  # round 15: thicker forearms (r14: spindly against the barrel body)
        v.ell(A + "2", "Mask", wr + V(0, 0.08, -0.08), (0.24, 0.24, 0.22))
        bm = el.lerp(wr, 0.62)
        v.torus(A + "2", "Brass", bm, (wr - el).normalized(), 0.3, 0.09)  # round 6: a brass forge bracer with a glowing rune line
        v.torus(A + "2", "Glow", el.lerp(wr, 0.5), (wr - el).normalized(), 0.31, 0.035)
        for k in (-1, 0, 1): v.crystal(A + "2", "Claw", wr + V(k * 0.09, 0.2, -0.16), (0, 0.6, -1), 0.14, 0.05, sides=4)
        P.shade(v, "Fur", parts={A + "2"})
        v.anchor("hand" + A[3:], A + "2", wr + V(0, 0.15, -0.1))
    hand = V(2.45, 0.4, 3.6)  # round 8: in the raised paw (round 7 moved the wrist)
    # round 2 (the hammer read as a small yellow block): a heavy smith's hammer resting on the shoulder line, a long haft, a
    # stepped iron head with a glowing ember striking face and a brass collar
    up = E(0, 18, 0)  # the haft leans out a little
    v.box("ArmR2", "Strap", hand + V(0.18, 0.0, 0.7), (0.18, 0.18, 1.7), rot=up)
    v.box("ArmR2", "Iron", hand + V(0.5, 0.0, 1.6), (1.3, 0.64, 0.64), rot=up)  # b18: a bigger head
    v.box("ArmR2", "IronLo", hand + V(0.5, 0.0, 1.6), (1.38, 0.5, 0.5), rot=up)
    v.box("ArmR2", "Edge", hand + V(0.55, 0.0, 1.93), (1.2, 0.6, 0.06), rot=up)  # a steel highlight along the top
    for dx in (0.3, 0.75): v.box("ArmR2", "IronLo", hand + V(dx, 0.0, 1.97), (0.1, 0.1, 0.05), rot=up)  # b20: rivets on its top
    v.box("ArmR2", "IronLo", hand + V(-0.3, 0.0, 1.72), (0.36, 0.64, 0.2), rot=up)  # the cross peen, a wedge
    v.box("ArmR2", "Glow", hand + V(1.18, 0.0, 1.38), (0.1, 0.54, 0.54), rot=up)  # the glowing striking face
    v.box("ArmR2", "Ember", hand + V(1.22, 0.0, 1.37), (0.06, 0.36, 0.36), rot=up)
    v.box("ArmR2", "Brass", hand + V(0.33, 0.0, 1.22), (0.28, 0.28, 0.14), rot=up)
    for dx in (0.05, 0.95): v.box("ArmR2", "Brass", hand + V(dx, 0.0, 1.6), (0.1, 0.7, 0.7), rot=up)  # round 16: brass bands round the head
    v.box("ArmR2", "Glow", hand + V(0.45, 0.27, 1.55), (0.36, 0.04, 0.1), rot=up)  # a forge rune on each cheek
    v.box("ArmR2", "Glow", hand + V(0.45, -0.27, 1.55), (0.36, 0.04, 0.1), rot=up)
    v.box("ArmR2", "IronLo", hand + V(-0.12, 0.0, 1.55), (0.12, 0.32, 0.32), rot=up)  # a bevelled peen
    v.box("ArmR2", "Brass", hand + V(0.0, 0.0, -0.1), (0.24, 0.24, 0.16), rot=up)  # the pommel
    v.anchor("hammer", "ArmR2", hand + V(1.2, 0.0, 1.4))
    # round 9: forge tongs in the off paw, jaws angled down and out, a glowing ingot in their grip (r8: the flank read as one bulge)
    lh = V(-1.98, 1.36, 2.98)
    td = V(-0.4, 0.62, 0.42).normalized()  # round 14: out forward-left, the ingot clear of the body (r13: the tongs clumped with the tail)
    sd = td.cross(V(0, 1, 0)).normalized()
    # round 15: a freshly forged sword held up in the off paw, its flat to the 3/4 camera: a leather grip, a brass guard, a steel
    # blade still glowing along the fuller and red at the tip (r14: tongs and horseshoe read as a magnet on a stick)
    bd = (V(-0.82, 0.57, 0) * 0.42 + V(0, 0, 1) + V(0, 0.25, 0)).normalized()
    nv = V(0.57, 0.82, 0); nv = (nv - bd * nv.dot(bd)).normalized(); wv = nv.cross(bd).normalized()
    J = lh + V(0, 0.05, 0.05)
    def slab(col, hw, th, a, b2, tip=1.85):
        def inside(x, y, z):
            q = V(x, y, z) - J; t = q.dot(bd)
            if not (a <= t <= b2): return False
            w = hw * (1 if t < tip - 0.5 else max(0.0, (tip - t) / 0.5))  # the point
            return abs(q.dot(wv)) <= w + 1e-6 and abs(q.dot(nv)) <= th
        v.fill("ArmL2", col, J - V(3, 3, 3), J + V(3, 3, 3), inside)
    v.cap("ArmL2", "Strap", J - bd * 0.32, J + bd * 0.22, 0.09, 0.09)  # the grip through the paw
    v.ell("ArmL2", "Brass", J - bd * 0.38, (0.12, 0.12, 0.12))  # the pommel
    slab("Brass", 0.36, 0.09, 0.22, 0.34)  # the guard
    slab("Edge", 0.19, 0.06, 0.34, 2.15, tip=2.15)  # the steel blade
    slab("Glow", 0.06, 0.075, 0.5, 1.75, tip=2.15)  # the fuller, still glowing
    slab("Ember", 0.2, 0.065, 1.6, 2.15, tip=2.15)  # the red-hot tip
    slab("Glow", 0.1, 0.075, 1.75, 2.05, tip=2.15)
    v.anchor("blade", "ArmL2", J + bd * 1.2)
    # stout legs in dark trousers, big paws
    for s, L in ((-1, "LegL"), (1, "LegR")):
        hip, knee, foot = V(s * 0.6, 0.0, 1.62), V(s * 1.0, 0.42, 0.82), V(s * 1.28, 0.2, 0.0)  # round 17: wider, daylight between the boots  # round 11: a wider smith's stance, a gap between the boots  # round 8: a bent knee
        v.joint(L + "1", tuple(hip), "Body", "leg")
        v.cap(L + "1", "FurDark", hip, knee, 0.38, 0.32)
        v.joint(L + "2", tuple(knee), L + "1", "leg")
        v.cap(L + "2", "FurDark", knee, foot + V(0, 0, 0.2), 0.3, 0.22)  # tapers to the ankle
        v.ell(L + "2", "Mask", foot + V(0, 0.16, 0.17), (0.36, 0.44, 0.19))  # round 9: a domed paw, not a slab
        v.torus(L + "2", "Strap", foot + V(0, 0.04, 0.62), (0, 0, 1), 0.3, 0.08)  # round 13: a leather boot cuff at the ankle
        v.torus(L + "2", "Brass", foot + V(0, 0.04, 0.5), (0, 0, 1), 0.27, 0.04)
        for k in (-1, 0, 1): v.ell(L + "2", "Mask", foot + V(k * 0.17, 0.52, 0.12), (0.11, 0.12, 0.12))  # three toes
        for k in (-1, 0, 1): v.crystal(L + "2", "Claw", foot + V(k * 0.17, 0.62, 0.08), (0, 1, -0.3), 0.1, 0.045, sides=4)
        v.anchor("foot" + L[3:], L + "2", foot + V(0, 0.2, 0.1))
    # the banded tail: two bones, thick and curled up behind, dark rings on grey
    tp = [V(-0.3, -0.6, 1.75), V(-1.3, -1.3, 1.2), V(-2.5, -1.6, 1.1), V(-3.4, -1.45, 1.55), V(-3.75, -1.15, 2.25)]  # b20: low on the sword side  # round 14: the tail sweeps out back-right, under the hammer, the tongs alone on the other side  # round 12: a low curl under the raised off arm; round 11 rose past the tongs  # round 11: the curl rises past the tongs to above the shoulder, so the blackout shows it (r9 graders: the tail hid behind the off arm)  # round 8: the tip a little further out and back; round 7: flared out to the side so it reads from the front (round 6 hid it behind the body)  # round 5: farther out and back, clear of the leg (Gemini: the tail clumped into the hip in the blackout)
    for i, (a, b2, nm) in enumerate(((0, 2, "Tail1"), (2, 4, "Tail2"))):
        v.joint(nm, tuple(tp[a]), "Body" if i == 0 else "Tail1", "tail")
        v.tube(nm, "Fur", tp[a:b2 + 1], [0.3, 0.5, 0.56][:b2 - a + 1] if i == 0 else [0.56, 0.42, 0.14])
    for k in range(5):
        t = (k + 0.5) / 5
        seg = int(t * 4); u = t * 4 - seg
        c = tp[seg].lerp(tp[seg + 1], u); d = (tp[seg + 1] - tp[seg]).normalized()
        v.torus("Tail1" if seg < 2 else "Tail2", "Mask", c, d, [0.46, 0.55, 0.54, 0.44, 0.3][k], 0.1)
    for k in range(9):  # round 9: tufts notched along the outer edge, so the side view is fur and not an extrusion
        t = 0.12 + k * 0.095; seg = min(int(t * 4), 3); u = t * 4 - seg
        c = tp[seg].lerp(tp[seg + 1], u); d = (tp[seg + 1] - tp[seg]).normalized()
        out = d.cross(V(0, 0, 1)).normalized() * (1 if k % 2 else -1) + V(0, 0, 0.6)
        v.crystal("Tail1" if seg < 2 else "Tail2", "Fur", c + out.normalized() * [0.3, 0.45, 0.52, 0.52, 0.5, 0.44, 0.36, 0.28, 0.18][k], tuple(out), 0.22, 0.09, sides=4)
    v.ell("Tail2", "Edge", tp[4] + (tp[4] - tp[3]).normalized() * 0.05, (0.16, 0.16, 0.2))  # a pale tip
    v.anchor("tail", "Tail2", tp[4])
    P.ground(v)



# ---------------------------------------------------------------- MARIBEL: the hatchery keeper (the Egg Hatchery)
# a lop-eared rabbit (2026-11-27: the brief leaves the species open; the town's named folk are creatures like Bolt) in a layered
# mint-and-lavender hooded cloak with a scalloped trim and a brass egg clasp, a wide-brimmed botanist hat with glowing crystal
# feathers, cradling a woven straw nest with a softly glowing spotted egg
@char("Maribel", dict(P.palette(form=("Fur", "Cloak", "Cape"), Fur="#f2e4d4", FurDark="#c8ad94", White="#fffaf2", Cloak="#98e8ce", CloakDark="#488874",
                           Cape="#8a6cc0", CapeDark="#583b68", Trim="#fff1d6", Hat="#5d4a8e", HatDark="#3c2f62", Band="#86dcb8", Brass="#e0b04a",
                           Straw="#c48c3e", StrawDark="#7a4c1c", Egg="#ffd27a", Spot="#e0703a", Glow="#fff4c0", Lash="#2f1b38", Shadow="#261d3b", Grain="#4a2a14", Crystal="#9ff0ff", Pink="#f4b2c6",
                           Blush="#f39ab4", Nose="#d86a8a", Eye="#241638", Iris="#241638", Shine="#ffffff", Boot="#6a4a3a", Leaf="#6fcf8a"), FurLo="#dcc4ae", FurLoTop="#e2cab4", FurCrease="#bf9f86", FurCreaseTop="#c6a78e"))  # m5: warm face shading (the cool Lo read olive)
def maribel(v):
    E = P.E
    v.joint("Body", (0, 0, 1.9))
    # the cloak: a bell that flares to the ground, mint, in two tiers, with a lavender capelet over the shoulders
    v.muscle("Body", "Cloak", (0, 0, 1.1), (1.15, 1.0, 1.0), cut=lambda x, y, z: z >= 0.12)
    v.muscle("Body", "Cloak", (0, 0, 2.3), (0.9, 0.78, 0.85))
    P.shade(v, "Cloak")
    v.ell("Body", "Cloak", (0, 0, 0.55), (1.42, 1.24, 0.6), cut=lambda x, y, z: z >= 0.12)  # m3: the skirt flares at the hem
    for k in range(18):  # the scalloped hem: a ring of cream scallops round the cloak's foot
        a = k / 18 * math.tau
        v.ell("Body", "Trim", (math.cos(a) * 1.4, math.sin(a) * 1.22, 0.3), (0.27, 0.27, 0.2))
    v.ell("Body", "CloakDark", (0, 0.92, 1.0), (0.12, 0.1, 0.8))  # the front seam
    for k in range(8):  # m15: eight fluted box pleats, a recessed darker channel between each
        a0 = (k + 0.5) / 8 * math.tau
        v.paint("CloakDark", lambda x, y, z, a0=a0: z < 1.85 and abs((math.atan2(y, x) - a0 + math.pi) % math.tau - math.pi) < 0.07, part="Body", only={"Cloak", "CloakHi", "CloakLo", "CloakCrease"})
    v.carve(lambda x, y, z: 1.92 < z < 2.22 and (x / 0.84) ** 2 + (y / 0.74) ** 2 > 1, part="Body")  # m7: a nipped waist (m6: a blocky slab from chest to skirt)
    v.torus("Body", "HatDark", (0, 0.0, 2.07), (0, 0, 1), 0.84, 0.14)  # a deep plum sash in the notch (m12: graders asked for a darker waist)
    v.ell("Body", "Cape", (0, -0.05, 2.75), (1.12, 0.98, 0.62), cut=lambda x, y, z: z >= 2.35)
    P.shade(v, "Cape")
    v.torus("Body", "CapeDark", (0, -0.05, 2.42), (0, 0, 1), 1.06, 0.1)
    v.torus("Body", "Shadow", (0, -0.05, 2.3), (0, 0, 1), 1.0, 0.11)  # m13: a dark crevice under the capelet (m15: two rows, near black)
    v.torus("Body", "Shadow", (0, -0.05, 2.21), (0, 0, 1), 0.94, 0.09)  # m6: a dark border, so the capelet parts from the mint skirt
    for k in range(12):  # the capelet's scalloped edge
        a = k / 12 * math.tau
        v.ell("Body", "Trim", (math.cos(a) * 1.08, math.sin(a) * 0.95, 2.3), (0.2, 0.2, 0.14))
    v.torus("Body", "Brass", (0, 0.9, 3.0), (0, 1, 0.2), 0.2, 0.06)  # the brass egg clasp
    v.ell("Body", "Egg", (0, 0.95, 3.0), (0.13, 0.08, 0.17))
    # the hood falls in folds down her back, under the hat
    v.ell("Body", "HatDark", (0, -0.78, 3.25), (0.78, 0.36, 0.62))  # m10: the hood in the hat's deep plum, apart from the lavender cape from behind
    v.ell("Body", "Hat", (0, -0.86, 3.4), (0.62, 0.3, 0.46))
    v.ell("Body", "White", (0, -1.28, 0.95), (0.34, 0.3, 0.32))  # a cotton tail peeking out of the cloak
    for s in (-1, 1):  # m3: a big lavender bow at the small of the back, its ribbons down the skirt
        v.ell("Body", "CapeDark", (s * 0.42, -1.02, 2.12), (0.38, 0.16, 0.24), rot=E(0, s * -20, 0))
        v.ell("Body", "Cape", (s * 0.42, -1.08, 2.14), (0.3, 0.12, 0.18), rot=E(0, s * -20, 0))
        v.cap("Body", "Cape", V(s * 0.12, -1.0, 2.0), V(s * 0.45, -1.22, 1.15), 0.1, 0.12)
    v.ell("Body", "Brass", (0, -1.08, 2.1), (0.14, 0.1, 0.14))
    v.torus("Body", "Trim", (0, 0.0, 3.3), (0, 0, 1), 0.62, 0.12)  # m17: a cream collar parting the hat from the capelet
    v.anchor("chest", "Body", (0, 0.9, 2.9))
    # the head: a round rabbit head, cream fur, white muzzle, big violet eyes, long lop ears hanging past the cheeks
    v.joint("Head", (0, 0.05, 3.45), "Body", "head")
    v.muscle("Head", "Fur", (0, 0.05, 4.3), (0.92, 0.84, 0.8))
    v.muscle("Head", "Fur", (0, 0.32, 4.1), (0.74, 0.66, 0.6))
    P.shade(v, "Fur", parts={"Head"})
    v.ell("Head", "White", (0, 1.04, 3.98), (0.4, 0.38, 0.3))  # the muzzle, a step forward (m5)
    v.ell("Head", "White", (0, 1.28, 4.06), (0.26, 0.28, 0.2))  # m14: a tapered snout tip, depth in the side view (m15: a step longer)
    v.ell("Head", "Nose", (0, 1.52, 4.16), (0.14, 0.09, 0.1))
    v.box("Head", "Nose", (0, 1.36, 3.92), (0.05, 0.05, 0.12))  # the mouth line, a soft rose
    for s in (-1, 1):
        v.box("Head", "Nose", (s * 0.1, 1.33, 3.86), (0.14, 0.05, 0.05))
        round_eye(v, "Head", (s * 0.37, 0.87, 4.42), (s * 0.35, 1, 0.1), 0.38, 0.46, skin="Fur")  # m18: solid dark eyes, rounded corners; m17: the m13 eyes (a painted flush eye read as half closed)
        v.box("Head", "Lash", (s * 0.4, 0.92, 4.7), (0.46, 0.1, 0.08), rot=E(0, s * -8, s * 18))  # m15: a dark lash line over each eye  # m13: m10 eyes plus a second catchlight (m12: a bright iris read as glasses)
        v.ell("Head", "Blush", (s * 0.6, 0.78, 4.08), (0.15, 0.06, 0.09))
        for k in range(3): v.crystal("Head", "White", V(s * (0.82 + 0.06 * k), 0.45 - 0.1 * k, 4.0 + 0.1 * k), (s * 1, -0.1, -0.2), 0.26, 0.1, sides=4)  # cheek fluff
        # m11: tall upright ears up through the hat brim, the left tip folded forward (m10 lop ears read as flat slabs in the blackout)
        ear = [V(s * 0.36, -0.12, 4.9), V(s * 0.52, -0.2, 5.6), V(s * 0.6, -0.22, 6.25), V(s * 0.62, -0.2, 6.7)]
        if s < 0: ear = ear[:3] + [V(-0.78, 0.05, 6.75), V(-1.0, 0.32, 6.55)]
        v.tube("Head", "Fur", ear, [0.2, 0.27, 0.27, 0.22, 0.15][:len(ear)])
        v.tube("Head", "Pink", [e + V(0, 0.16, 0) for e in ear[1:3]], [0.13, 0.13])  # the pale inside, turned to the front
        v.ell("Head", "FurDark", ear[-1] + V(0, 0, 0.0), (0.14, 0.14, 0.12))  # a darker tip
    v.paint("Fur", lambda x, y, z: y > 0.55 and abs(z - 4.42) < 0.42 and abs(x) < 0.85, part="Head", only={"FurLo", "FurCrease", "FurLoTop", "FurCreaseTop"})  # m16: no grey mask round the eyes
    v.anchor("eyes", "Head", (0, 0.9, 4.42)); v.anchor("speech", "Head", (0, 0.0, 6.3))
    # the hat: a wide soft brim (the silhouette), a tall plum crown, a mint band, glowing crystal feathers and an egg charm
    tilt = E(26, 0, 0)  # m4: the brim tips up at the front, off the eyes and open to the town camera (m3: a flat slab shading the face)
    v.ell("Head", "Hat", (0, 0.0, 5.12), (1.42, 1.32, 0.24), rot=tilt)  # m17: a thicker brim
    v.ell("Head", "Hat", (0, 0.0, 5.0), (1.36, 1.26, 0.1), rot=tilt)  # m13: a lighter underside, less shadow on the face
    v.torus("Head", "HatDark", (0, 0.0, 5.2), (0, -0.28, 0.96), 1.38, 0.15)  # the brim's thick rolled edge
    v.muscle("Head", "Hat", (0, -0.05, 5.42), (0.78, 0.72, 0.5), cut=lambda x, y, z: z >= 5.1)  # m11: a low crown (the ears give the height)
    v.torus("Head", "Band", (0, -0.05, 5.32), (0, 0, 1), 0.72, 0.12)
    v.torus("Head", "HatDark", (0, -0.05, 5.62), (0, 0, 1), 0.6, 0.06)  # m18: a stitched ring round the crown
    v.ell("Head", "Trim", (-0.2, 0.15, 5.86), (0.2, 0.2, 0.08))  # a cream crescent moon on top of the crown
    v.ell("Head", "Hat", (-0.12, 0.22, 5.9), (0.16, 0.16, 0.08))
    for k, (dx, dy, L) in enumerate(((0.55, -0.5, 0.8), (0.75, -0.3, 0.6), (0.35, -0.68, 0.55))):  # crystal feathers tucked in the band, behind the right ear
        v.crystal("Head", "Crystal", V(dx, dy, 5.35), (0.5 + 0.1 * k, -0.6, 0.7), L, 0.13, sides=4)
        v.crystal("Head", "Glow", V(dx, dy, 5.35), (0.5 + 0.1 * k, -0.6, 0.7), L * 0.55, 0.07, sides=4)
    v.ell("Head", "Egg", (-0.55, 0.45, 5.34), (0.13, 0.11, 0.16))  # an egg charm on the band
    v.ell("Head", "Spot", (-0.55, 0.56, 5.36), (0.05, 0.03, 0.05))
    # m11 arms (both graders m10: arms and nest one mass with the torso): the right paw on a tall hatchery crook out to the side, an egg
    # lantern swinging from its hook; the left arm holds the nest basket out forward-left by its handle, daylight under it
    arms = {"ArmL": (V(-0.95, 0.15, 2.95), V(-1.72, 0.85, 2.45), V(-2.15, 1.7, 2.4)),  # m15: further out
            "ArmR": (V(0.95, 0.1, 2.95), V(1.75, -0.05, 2.4), V(2.38, 0.08, 2.8))}
    for A, (sh, el, wr) in arms.items():
        s = -1 if A == "ArmL" else 1
        v.joint(A + "1", tuple(sh), "Body", "arm")
        v.cap(A + "1", "Cape", sh, el, 0.34, 0.3)
        v.joint(A + "2", tuple(el), A + "1", "arm")
        v.cap(A + "2", "Cape", el, wr, 0.3, 0.32)  # m16: plum sleeves, apart from the mint skirt
        v.torus(A + "2", "Trim", wr + (el - wr).normalized() * 0.1, (wr - el).normalized(), 0.32, 0.1)
        v.ell(A + "2", "Fur", wr, (0.24, 0.22, 0.22))
        v.anchor("hand" + A[3:], A + "2", wr)
    # the crook: a straw-brown shaft from the ground to above the ears, a curled hook, brass ferrules, an egg lantern on a chain
    cx, cy = 2.52, 0.1
    v.tube("ArmR2", "StrawDark", [V(cx - 0.35, cy + 0.2, 0.05), V(cx, cy, 3.0), V(cx + 0.55, cy - 0.05, 6.0)], [0.15, 0.15, 0.14])  # m14: a 3-voxel shaft (m15: canted out at the top)
    v.paint("Grain", lambda x, y, z: (z * 10) % 4 < 1 and abs(x - cx) < 0.7 and z < 6.0, part="ArmR2", only={"StrawDark"})  # wood grain
    v.tube("ArmR2", "StrawDark", [V(cx + 0.55, cy - 0.05, 6.0), V(cx + 0.62, cy, 6.5), V(cx + 0.94, cy, 6.82), V(cx + 1.3, cy, 6.64), V(cx + 1.4, cy, 6.28)], [0.14, 0.14, 0.14, 0.13, 0.12])
    for z in (2.15, 3.45, 5.95): v.torus("ArmR2", "Brass", V(cx + (z - 3.0) * 0.185, cy, z), (0.18, 0, 1), 0.17, 0.06)
    v.cap("ArmR2", "Boot", V(cx - 0.12, cy, 2.35), V(cx + 0.05, cy, 3.25), 0.18, 0.18)  # a leather grip under the paw
    for z in (1.1, 4.4, 5.2): v.ell("ArmR2", "Straw", (cx + (z - 3.0) * 0.185 + 0.1, cy + 0.08, z), (0.12, 0.12, 0.1))  # carved knots in the wood
    v.crystal("ArmR2", "Leaf", V(cx + 0.42, cy + 0.1, 4.75), (1, 0.4, 0.5), 0.42, 0.12, sides=4)  # a sprig tied on
    v.line("ArmR2", "Lash", [V(cx + 1.4, cy, 6.25), V(cx + 1.4, cy, 5.62)], r=0.07)
    lan = V(cx + 1.4, cy, 5.42)
    v.ell("ArmR2", "Egg", lan, (0.22, 0.22, 0.28))
    v.ell("ArmR2", "Glow", lan + V(0, 0.08, 0.02), (0.2, 0.2, 0.25))  # m15: a bright core
    for d in ((0.12, 0.17, 0.08), (-0.1, 0.16, -0.06), (0.0, 0.18, 0.2)): v.ell("ArmR2", "Spot", lan + V(*d), (0.06, 0.04, 0.06))
    v.torus("ArmR2", "Lash", lan + V(0, 0, 0.26), (0, 0, 1), 0.15, 0.06)  # dark iron bands
    v.torus("ArmR2", "Lash", lan + V(0, 0, -0.25), (0, 0, 1), 0.13, 0.06)
    v.anchor("lantern", "ArmR2", lan)
    # the nest basket, hanging from the left paw by an arched handle
    nest = V(-2.15, 1.7, 1.38)
    v.ell("ArmL2", "Straw", nest, (0.72, 0.6, 0.42), cut=lambda x, y, z: z <= nest.z + 0.14)
    v.torus("ArmL2", "StrawDark", nest + V(0, 0, 0.14), (0, 0, 1), 0.68, 0.11)
    v.paint("StrawDark", lambda x, y, z: (int((x + 10) * 5) + int((z + 10) * 5)) % 2 == 0, part="ArmL2", only={"Straw"})  # m15: a 2x2 wicker check
    v.tube("ArmL2", "StrawDark", [nest + V(-0.6, 0, 0.16), nest + V(-0.42, 0, 0.66), nest + V(0, 0, 0.86), nest + V(0.42, 0, 0.66), nest + V(0.6, 0, 0.16)], [0.08, 0.08, 0.08, 0.08, 0.08])
    for k in range(8):
        a = k / 8 * math.tau
        v.crystal("ArmL2", "Straw" if k % 2 else "StrawDark", nest + V(math.cos(a) * 0.5, math.sin(a) * 0.4, 0.12), (math.cos(a), math.sin(a), 0.5), 0.24, 0.05, sides=4)
    egg = nest + V(0.08, 0.05, 0.42)
    v.ell("ArmL2", "Egg", egg, (0.3, 0.27, 0.38))
    v.ell("ArmL2", "Glow", tuple(egg + V(0.05, 0.1, 0.12)), (0.22, 0.22, 0.28))  # m17: a warm-white core showing through
    v.ell("ArmL2", "Shine", tuple(egg + V(0.04, 0.18, 0.2)), (0.08, 0.08, 0.1))
    for d in ((0.17, 0.2, 0.1), (-0.15, 0.21, -0.04), (0.04, 0.25, 0.23), (0.25, 0.04, -0.08)):
        v.ell("ArmL2", "Spot", egg + V(*d), (0.07, 0.04, 0.07))
    v.anchor("egg", "ArmL2", egg)
    # little boots peeking under the hem
    for s, L in ((-1, "LegL"), (1, "LegR")):
        hip, foot = V(s * 0.42, 0.1, 0.9), V(s * 0.6, 1.2, 0.0)  # m6: the toes well past the hem
        v.joint(L + "1", tuple(hip), "Body", "leg")
        v.cap(L + "1", "Fur", hip, foot + V(0, -0.3, 0.18), 0.26, 0.22)
        v.ell(L + "1", "Fur", foot + V(0, 0.2, 0.18), (0.28, 0.5, 0.2))  # m5: long rabbit feet out under the hem
        v.ell(L + "1", "Fur", foot + V(0, -0.15, 0.3), (0.22, 0.24, 0.24))  # m16: a heel and ankle
        for k in (-1, 0, 1): v.ell(L + "1", "White", foot + V(k * 0.15, 0.68, 0.12), (0.12, 0.16, 0.13))  # three toes
        v.carve(lambda x, y, z, f=foot: any(abs(x - (f.x + kk * 0.075)) < 0.04 for kk in (-1, 1)) and y > f.y + 0.55 and z > 0.05, part=L + "1")  # m18: deep notches between them
        v.ell(L + "1", "Pink", foot + V(0, 0.45, 0.02), (0.16, 0.14, 0.04))  # a pink sole pad
        v.anchor("foot" + L[3:], L + "1", foot + V(0, 0.2, 0.1))
    P.ground(v)



# ---------------------------------------------------------------- WICK: the elder glowworm (Camp 1, by the rail station)
# a chubby ringed mint-jade glowworm coiled on the ground and rising into an S, oversized eyes behind tiny brass spectacles, a
# tattered rust knit beanie between two curled feelers with amber glow bulbs, a patchwork travel cape, a tin camp mug in its
# stubby hands, and the lantern bulb of its tail held up behind it
@char("Wick", P.palette(form=("Body", "Body2", "Head"), Body="#7cd6b2", Body2="#4fb08e", Head="#86dcb8", Ring="#2c7a62", Belly="#dcf6cc", Eye="#1a1228", Iris="#ffb347",
                        Shine="#ffffff", Brass="#e0b04a", BrassLo="#a87a2a", Beanie="#c8643c", BeanieDark="#86381f", Patch="#e3bf5e", Patch2="#6f7fd0",
                        Cape="#9a6a48", CapeDark="#6a4430", Tin="#b8c0c8", TinDark="#f4ecdc", TailGlow="#b8f0b0", TailGlow2="#f0f8a8", Cocoa="#5e3420", Glow="#ffd27a", Ember="#ff9a30",
                        Blush="#f39ab4", Mouth="#2a1a2a", Stitch="#f4e6c8"))
def wick(v):
    E = P.E
    # the spine from the tail's lantern to the neck: on the ground it coils round to the left, then the front rises in an S
    sp = [V(1.3, -1.45, 3.35), V(1.75, -1.7, 2.2), V(1.6, -1.6, 0.85), V(0.55, -1.75, 0.5), V(-0.65, -1.35, 0.5), V(-1.05, -0.35, 0.55), V(-0.45, 0.45, 0.85), V(0.0, 0.4, 1.9), V(0.0, 0.3, 2.7)]  # w6: the coil swings wider, daylight inside it  # w5: the tail rises behind, the lantern held high
    rad = [0.2, 0.28, 0.4, 0.5, 0.56, 0.6, 0.62, 0.6, 0.52]
    v.joint("Body", tuple(sp[6]))
    v.joint("Seg2", tuple(sp[5]), "Body", "tail")
    v.joint("Tail", tuple(sp[3]), "Seg2", "tail")
    owner = ["Tail", "Tail", "Tail", "Tail", "Seg2", "Seg2", "Body", "Body", "Body"]
    n = 36
    rings = []
    for k in range(n + 1):  # chubby segments: a ball every step along the spine, ringed every third
        t = k / n * (len(sp) - 1); i = min(int(t), len(sp) - 2); u = t - i
        c = sp[i].lerp(sp[i + 1], u); r = rad[i] + (rad[i + 1] - rad[i]) * u
        part = owner[i if u < 0.5 else i + 1]
        v.muscle(part, "Body", tuple(c), (r, r, r))
        if k % 3 == 0 and 2 < k < n - 1:
            d = (sp[i + 1] - sp[i]).normalized()
            rings.append((part, c, d, r))
    P.shade(v, "Body", "Body2")
    for part, c0, d0, r0 in rings:  # w2: a groove cut between the segments (w1: "a smooth extruded tube"), its floor dark
        def cut(x, y, z, c0=c0, d0=d0, r0=r0):
            q = V(x, y, z) - c0; h = q.dot(d0)
            return abs(h) < 0.07 and (q - d0 * h).length > r0 * 0.86
        v.carve(cut, part=part)
        v.torus(part, "Ring", c0, tuple(d0), r0 * 0.84, 0.08)  # w6: a deeper, darker crease
    v.paint("TailGlow", lambda x, y, z: z > 1.6 and x > 1.0 and y < -1.2, part="Tail", only={"Body", "BodyHi", "BodyLo", "BodyCrease"})  # w7: the tail lightens toward the bulb
    v.paint("TailGlow2", lambda x, y, z: z > 2.7 and x > 1.0 and y < -1.2, part="Tail", only={"TailGlow"})
    for k in range(6):  # the pale belly scutes up the front of the rising neck
        z = 1.0 + k * 0.3
        v.ell("Body", "Belly", (0, 0.62 + (0.12 if 1 < k < 4 else 0), z), (0.34, 0.12, 0.13))
    # the tail lantern: a glass bulb with a glowing heart and a brass cap
    tip = sp[0] + (sp[0] - sp[1]).normalized() * 0.25
    v.torus("Tail", "Brass", tip, tuple((sp[0] - sp[1]).normalized()), 0.24, 0.07)
    v.cap("Tail", "BrassLo", tip - (sp[0] - sp[1]).normalized() * 0.05, tip + V(-0.1, -0.05, 0.12), 0.27, 0.32)  # w6: a stepped brass collar seating the bulb
    v.ell("Tail", "Glow", tuple(tip + V(-0.1, -0.05, 0.42)), (0.42, 0.42, 0.48))  # w5: a bigger bulb held up high
    v.ell("Tail", "Ember", tuple(tip + V(-0.1, -0.05, 0.42)), (0.22, 0.22, 0.26))
    v.box("Tail", "Brass", tuple(tip + V(-0.1, -0.05, 0.95)), (0.16, 0.16, 0.14))
    v.anchor("tail", "Tail", tuple(tip + V(-0.1, -0.05, 0.42)))
    # the cape: a patchwork shoulder cape down the back of the rising neck
    v.ell("Body", "Cape", (0, -0.32, 2.2), (0.84, 0.56, 0.68), cut=lambda x, y, z: y < -0.05 and z < 2.6)  # w5: a fuller cape
    v.ell("Body", "CapeDark", (0, -0.2, 2.65), (0.66, 0.5, 0.12))  # its collar
    for (x, z, col) in ((-0.35, 1.85, "Patch"), (0.3, 2.2, "Patch2"), (-0.1, 1.6, "Patch2")):
        v.box("Body", col, (x, -0.78, z), (0.32, 0.1, 0.28))
        v.box("Body", "Stitch", (x, -0.84, z + 0.13), (0.3, 0.04, 0.04))
    # the head: big and round, giant amber eyes behind round brass spectacles, a small smile, blush
    v.joint("Head", (0, 0.25, 2.85), "Body", "head")
    v.muscle("Head", "Head", (0, 0.3, 3.45), (0.86, 0.78, 0.74))
    P.shade(v, "Head", parts={"Head"})
    for s in (-1, 1):
        v.eye("Head", (s * 0.34, 0.98, 3.5), (s * 0.3, 1, 0.08), w=0.38, h=0.46, iris="Iris")
        v.torus("Head", "Brass", V(s * 0.34, 1.06, 3.5), (s * 0.3, 1, 0.08), 0.32, 0.055)  # spectacles
        v.cap("Head", "Brass", V(s * 0.64, 0.95, 3.55), V(s * 0.8, 0.55, 3.6), 0.04, 0.04)  # the arms of the spectacles
        v.ell("Head", "Blush", (s * 0.6, 0.86, 3.12), (0.15, 0.06, 0.08))
        # feelers: up through the beanie, curling outward, each ending in a glowing bulb
        fe = [V(s * 0.3, 0.15, 4.05), V(s * 0.45, 0.2, 4.6), V(s * 0.75, 0.3, 4.95), V(s * 1.0, 0.45, 4.85)]
        v.tube("Head", "Ring", fe, [0.07, 0.06, 0.055, 0.05])
        v.ell("Head", "Glow", tuple(fe[3] + V(s * 0.08, 0.04, 0.02)), (0.17, 0.17, 0.17))
        v.ell("Head", "Ember", tuple(fe[3] + V(s * 0.08, 0.04, 0.02)), (0.08, 0.08, 0.08))
    v.box("Head", "Brass", (0, 1.07, 3.55), (0.18, 0.05, 0.05))  # the bridge
    v.box("Head", "Mouth", (0, 1.04, 3.08), (0.22, 0.05, 0.05))
    for s in (-1, 1): v.box("Head", "Mouth", (s * 0.14, 1.02, 3.12), (0.06, 0.05, 0.05))  # the smile's turned-up corners
    # the beanie: a knit cap with ribbed stripes, a folded brim, a patch, a frayed hole and a little pompom
    v.ell("Head", "Beanie", (0, 0.2, 3.95), (0.8, 0.74, 0.52), cut=lambda x, y, z: z >= 3.82)
    v.torus("Head", "BeanieDark", (0, 0.2, 3.88), (0, 0, 1), 0.78, 0.13)  # the folded brim
    for k in range(4): v.torus("Head", "BeanieDark", (0, 0.2, 4.05 + k * 0.1), (0, 0, 1), 0.74 - k * 0.1, 0.03)
    v.box("Head", "Patch", (0.4, 0.75, 4.12), (0.24, 0.1, 0.2), rot=E(0, 0, -30))
    v.box("Head", "Stitch", (0.4, 0.8, 4.12), (0.26, 0.04, 0.04), rot=E(0, 0, -30))
    v.ell("Head", "Beanie", (-0.15, 0.1, 4.5), (0.2, 0.2, 0.2))  # the pompom
    v.ell("Head", "BeanieDark", (-0.15, 0.1, 4.46), (0.14, 0.22, 0.14))
    v.anchor("eyes", "Head", (0, 1.0, 3.5)); v.anchor("speech", "Head", (0, 0.2, 5.3))
    # stubby arms from the front of the neck holding a tin camp mug of cocoa
    mug = V(-1.35, 1.6, 2.2)  # w5: held out forward-left in one paw, daylight round it (w4: merged with the chest)
    for s, A in ((-1, "ArmL"), (1, "ArmR")):
        sh = V(s * 0.52, 0.55, 2.3)
        el, wr = (V(-1.1, 0.95, 2.05), V(-1.3, 1.4, 2.25)) if s < 0 else (V(1.05, 0.45, 2.55), V(1.45, 0.55, 3.05))  # the other paw waves, out clear of the face
        v.joint(A + "1", tuple(sh), "Body", "arm")
        v.cap(A + "1", "Body", sh, el, 0.17, 0.16)
        v.cap(A + "1", "Body", el, wr, 0.16, 0.15)
        v.ell(A + "1", "Belly", tuple(wr + V(0, 0.05, 0)), (0.14, 0.12, 0.12))
        v.anchor("hand" + A[3:], A + "1", tuple(wr))
    v.cap("ArmL1", "Tin", mug - V(0, 0, 0.22), mug + V(0, 0, 0.18), 0.24, 0.24)
    v.torus("ArmL1", "Stitch", mug + V(0, 0, 0.2), (0, 0, 1), 0.25, 0.05)  # w6: a bright rim
    v.ell("ArmL1", "Cocoa", tuple(mug + V(0, 0, 0.17)), (0.19, 0.19, 0.03))
    v.torus("ArmL1", "TinDark", mug + V(0.26, 0.12, 0.0), (0.5, 0.86, 0), 0.11, 0.035)  # the handle
    for k in range(3): v.crystal("ArmL1", "Stitch", mug + V(-0.08 + k * 0.08, 0, 0.3 + k * 0.06), (0.2 * (k - 1), 0, 1), 0.3, 0.04, sides=4)  # w4: steam, so it reads as a hot mug (w3: "a grey book")
    v.anchor("mug", "ArmL1", tuple(mug))
    P.ground(v)



# ---------------------------------------------------------------- KILN KEEPER: the mole potter (Camp 2, the Kiln Camp)
# a round plush plum-velvet mole in a terracotta tunic under a clay-smudged cream apron, a big pink digging nose, tiny round
# brass spectacles low on the snout, a tilted terracotta beret, wide pale digging paws cradling a freshly painted clay pot
@char("KilnKeeper", dict(P.palette(form=("Velvet", "Tunic"), Velvet="#6e4a86", VelvetDark="#4a2f5e", Snout="#8c68a2", Nose="#f49ab2", NoseLo="#d8708e",
                              Tunic="#c86a44", TunicDark="#8e4428", Apron="#f2e2c2", ApronLo="#d8c4a0", Smudge="#b8643e", Paw="#f2dcd2", Claw="#fff6e8",
                              Brass="#e0b04a", Eye="#1a1228", Iris="#3a2450", Shine="#ffffff", Pot="#4fb8b0", PotDark="#2a6e6a", Paint="#f2e2c2",
                              PaintHi="#c8fff4", Beret="#e07a48", BeretDark="#a04a28", White="#fff8ee", Blush="#f39ab4"), TunicLo="#a8553a", TunicLoTop="#b05c40", TunicCrease="#7a3a26", TunicCreaseTop="#82402a", VelvetLo="#5c3c74", VelvetLoTop="#62427a", VelvetCrease="#3e2652", VelvetCreaseTop="#442a58"))  # k2: warm shading (the cool Lo read olive)
def keeper(v):
    E = P.E
    v.joint("Body", (0, 0, 1.6))
    # a round pear of a body: velvet, a terracotta tunic over the trunk, a cream apron proud of the front
    v.muscle("Body", "Velvet", (0, 0, 1.45), (1.12, 0.98, 1.2))
    v.muscle("Body", "Tunic", (0, 0, 1.75), (1.16, 1.02, 0.86))
    P.shade(v, "Velvet", "Tunic")
    v.ell("Body", "Apron", (0, 0.55, 1.45), (0.9, 0.5, 1.0), cut=lambda x, y, z: y >= 0.58 and z >= 0.35)
    v.torus("Body", "TunicDark", (0, 0.0, 2.55), (0, 0, 1), 0.72, 0.1)  # the tunic's collar
    v.box("Body", "ApronLo", (0, 1.04, 2.28), (0.7, 0.06, 0.08))  # the apron's hem stitch at the bib
    for s in (-1, 1): v.cap("Body", "ApronLo", V(s * 0.42, 0.95, 2.3), V(s * 0.62, 0.2, 2.6), 0.06, 0.06)  # its neck straps
    v.box("Body", "ApronLo", (0.38, 1.04, 1.25), (0.38, 0.08, 0.32))  # a pocket with brushes in it
    for k in range(3): v.cap("Body", "PotDark", V(0.28 + k * 0.09, 1.04, 1.3), V(0.25 + k * 0.12, 1.08, 1.7), 0.035, 0.03)
    v.ell("Body", "Paint", (0.37, 1.08, 1.72), (0.05, 0.05, 0.06))
    v.ell("Body", "VelvetDark", (0, -0.95, 1.0), (0.2, 0.2, 0.24))  # a stubby tail
    for s in (-1, 1):  # k3: the apron's straps cross the back to a tied bow, and a potter's tool roll on the belt (k2: a bare back)
        v.curve("Body", "ApronLo", [(s * 0.62, 0.2, 2.6), (s * 0.4, -0.9, 2.2), (-s * 0.25, -1.08, 1.55)], [0.07, 0.07, 0.07])
        v.ell("Body", "Apron", (s * 0.3, -1.12, 1.5), (0.26, 0.12, 0.16), rot=E(0, s * -25, 0))
        v.cap("Body", "Apron", V(s * 0.06, -1.12, 1.45), V(s * 0.22, -1.08, 1.05), 0.07, 0.08)
    v.ell("Body", "ApronLo", (0, -1.14, 1.5), (0.1, 0.08, 0.1))
    v.torus("Body", "TunicDark", (0, 0.0, 1.32), (0, 0, 1), 1.02, 0.08)  # a belt
    v.box("Body", "Smudge", (0.62, -0.82, 1.3), (0.5, 0.2, 0.34), rot=E(0, 0, 32))  # the tool roll
    for k in range(3): v.cap("Body", "PotDark", V(0.5 + k * 0.1, -0.88, 1.4), V(0.45 + k * 0.12, -0.95, 1.72), 0.035, 0.03)
    v.anchor("chest", "Body", (0, 1.0, 2.0))
    # the head: no neck, a round velvet head, a long snout, the big pink digging nose, tiny eyes behind low brass spectacles
    v.joint("Head", (0, 0.2, 2.65), "Body", "head")
    v.muscle("Head", "Velvet", (0, 0.2, 3.2), (0.86, 0.82, 0.72))
    P.shade(v, "Velvet", parts={"Head"})
    v.cap("Head", "Snout", V(0, 0.75, 3.12), V(0, 1.45, 3.02), 0.42, 0.26)
    v.ell("Head", "Nose", (0, 1.6, 3.03), (0.22, 0.12, 0.2))  # k4: a star nose, a ring of pink feelers round the nostril pad
    for k in range(11):
        a = k / 11 * math.tau
        d = V(math.cos(a), 0.55, math.sin(a)).normalized()
        v.crystal("Head", "Nose", V(0, 1.62, 3.03) + V(math.cos(a) * 0.13, 0, math.sin(a) * 0.11), tuple(d), 0.17, 0.05, sides=4)
    v.ell("Head", "NoseLo", (0, 1.7, 3.03), (0.12, 0.06, 0.1))
    for s in (-1, 1):
        v.ell("Head", "NoseLo", (s * 0.09, 1.76, 3.05), (0.04, 0.03, 0.05))  # nostrils
        round_eye(v, "Head", (s * 0.28, 0.93, 3.44), (s * 0.4, 1, 0.15), 0.3, 0.34, skin="Velvet")  # k5: bigger, two catchlights (k6: rounded)
        v.ell("Head", "VelvetDark", (s * 0.78, -0.05, 3.62), (0.2, 0.12, 0.2))  # k5: small round mole ears under the beret
        v.ell("Head", "Nose", (s * 0.8, 0.02, 3.62), (0.11, 0.06, 0.11))
        v.torus("Head", "Brass", V(s * 0.28, 1.02, 3.42), (s * 0.3, 1, 0.1), 0.25, 0.045)  # the spectacles, round, a little low (k1: thin rims read as yellow brows)
        v.cap("Head", "Brass", V(s * 0.46, 0.96, 3.4), V(s * 0.74, 0.55, 3.45), 0.04, 0.04)
        v.ell("Head", "Blush", (s * 0.42, 1.08, 3.0), (0.14, 0.06, 0.08))
    v.box("Head", "Brass", (0, 1.12, 3.4), (0.14, 0.05, 0.05))
    # the beret: soft, tilted to one side, a little stem on top
    v.ell("Head", "Beret", (0.28, -0.3, 3.98), (0.88, 0.82, 0.28), rot=E(-22, 20, 0))  # k4: a floppy beret (k6: smaller, tipped back off the face)
    v.ell("Head", "BeretDark", (0.2, -0.3, 3.8), (0.72, 0.68, 0.08), rot=E(-22, 20, 0))
    v.cap("Head", "BeretDark", V(0.36, -0.2, 4.2), V(0.44, -0.24, 4.47), 0.08, 0.05)
    v.ell("Head", "Paint", (0.9, 0.25, 3.86), (0.12, 0.1, 0.08))  # a glaze drip on the brim
    v.anchor("eyes", "Head", (0, 0.95, 3.42)); v.anchor("speech", "Head", (0, 0.1, 4.8))
    # k4 arms: the left paw holds a tall painted amphora up beside the head, the right a long glaze brush out to the side
    arms = {"ArmL": (V(-1.0, 0.2, 2.3), V(-1.72, 0.55, 1.95), V(-1.6, 1.28, 2.42)), "ArmR": (V(1.0, 0.2, 2.3), V(1.72, 0.05, 1.95), V(1.95, 0.35, 2.55))}
    for A, (sh, el, wr) in arms.items():
        s = -1 if A == "ArmL" else 1
        v.joint(A + "1", tuple(sh), "Body", "arm")
        v.cap(A + "1", "Tunic", sh, el, 0.32, 0.28)
        v.joint(A + "2", tuple(el), A + "1", "arm")
        v.cap(A + "2", "Velvet", el, wr, 0.26, 0.25)
        v.ell(A + "2", "Paw", tuple(wr + V(0, 0.05, 0.02)), (0.34, 0.3, 0.16), rot=E(0, s * 20, 0))  # a wide flat digging paw
        for k in range(4): v.crystal(A + "2", "Claw", wr + V((k - 1.5) * 0.13, 0.3, 0.0), (0, 1, 0.2), 0.2, 0.05, sides=4)
        v.anchor("hand" + A[3:], A + "2", tuple(wr))
    # the amphora: a tall slender vase standing on the raised paw, two looped handles, a teal glaze band and dots, a darker lip
    pot = V(-1.62, 1.3, 2.62)
    v.tube("ArmL2", "Pot", [pot + V(0, 0, dz) for dz in (0.0, 0.2, 0.42, 0.66, 0.86, 1.02, 1.16)], [0.24, 0.38, 0.45, 0.4, 0.26, 0.17, 0.18])
    v.torus("ArmL2", "PotDark", pot + V(0, 0, 1.2), (0, 0, 1), 0.22, 0.07)  # the lip
    v.torus("ArmL2", "Paint", pot + V(0, 0, 0.45), (0, 0, 1), 0.44, 0.07)
    v.torus("ArmL2", "PotDark", pot + V(0, 0, 0.66), (0, 0, 1), 0.39, 0.04)
    for k in range(6):
        a = k / 6 * math.tau
        v.ell("ArmL2", "PaintHi" if k % 2 else "Paint", tuple(pot + V(math.cos(a) * 0.42, math.sin(a) * 0.42, 0.24)), (0.05, 0.05, 0.05))
    for s2 in (-1, 1): v.tube("ArmL2", "PotDark", [pot + V(s2 * 0.2, 0, 1.0), pot + V(s2 * 0.42, 0, 1.0), pot + V(s2 * 0.42, 0, 0.72), pot + V(s2 * 0.36, 0, 0.62)], [0.05, 0.05, 0.05, 0.05])
    v.anchor("pot", "ArmL2", tuple(pot + V(0, 0, 0.5)))
    # the glaze brush: a long wooden handle with a brass ferrule and a teal-loaded tip
    b0, b1 = V(1.95, 0.42, 2.2), V(2.35, 0.3, 3.85)
    v.cap("ArmR2", "PotDark", b0, b1, 0.07, 0.06)
    v.torus("ArmR2", "Brass", b1 - (b1 - b0).normalized() * 0.05, tuple((b1 - b0).normalized()), 0.09, 0.04)
    v.cap("ArmR2", "Paint", b1, b1 + (b1 - b0).normalized() * 0.32, 0.12, 0.04)
    v.ell("ArmR2", "PaintHi", tuple(b1 + (b1 - b0).normalized() * 0.12 + V(0.05, 0.05, 0)), (0.05, 0.05, 0.05))
    v.anchor("brush", "ArmR2", tuple(b1))
    # short legs with pale clawed feet
    for s, L in ((-1, "LegL"), (1, "LegR")):
        hip, foot = V(s * 0.55, 0.05, 0.7), V(s * 0.62, 0.35, 0.0)
        v.joint(L + "1", tuple(hip), "Body", "leg")
        v.cap(L + "1", "VelvetDark", hip, foot + V(0, 0, 0.2), 0.3, 0.26)
        v.ell(L + "1", "Paw", tuple(foot + V(0, 0.2, 0.13)), (0.32, 0.42, 0.15))
        for k in (-1, 0, 1): v.crystal(L + "1", "Claw", foot + V(k * 0.13, 0.58, 0.08), (0, 1, -0.3), 0.14, 0.045, sides=4)
        v.anchor("foot" + L[3:], L + "1", tuple(foot + V(0, 0.2, 0.1)))
    P.ground(v)



# ---------------------------------------------------------------- MOSS: the lost apprentice miner (layer 1, by the Swallow Hole)
# a young hedgehog (2026-11-27: the town's named folk are creatures; spines give him a silhouette) crouched a little, scared:
# an oversized dented butter-brass helmet with a working headlamp, a long moss-green knit scarf trailing down one shoulder,
# a dusty lilac coat, a leather field satchel, wide anxious eyes, a glowing hand lantern clutched to his chest
@char("Moss", soft_tops(P.palette(form=("Coat", "Face"), Coat="#a998d4", CoatDark="#5f4f8a", Face="#efd4b0", FaceDark="#9a6a48", Spine="#6a4428",
                        SpineTip="#e6c69a", Nose="#2a1a1a", Helm="#f0c85a", HelmDark="#a8822a", Lamp="#fff2b0", Glow="#ffd27a", Ember="#ffa040",
                        Scarf="#6aa84f", ScarfDark="#3f7a32", Leather="#8a5a34", LeatherDark="#5e3a20", Boot="#4a3a44", Brass="#e0b04a",
                        Eye="#1a1228", Iris="#1a1228", Shine="#ffffff", Blush="#f39ab4", Brow="#5a3a2a", Smudge="#7a6a80"), ("Helm", "Coat")))
def moss(v):
    # s4 (s1 critique: a pear-shaped blob, the lantern fused to the body, quills read as stripes): a fan of long quills behind the
    # head and shoulders (the hedgehog silhouette), the lantern held out forward-left at arm's length, the helmet tipped back with a
    # brim and headlamp, a hedgehog face with round worried eyes, the scarf tail blowing back-right, longer legs apart
    E = P.E
    v.joint("Body", (0, 0, 1.6))
    v.muscle("Body", "Coat", (0, 0.0, 1.75), (0.82, 0.7, 0.78))
    v.ell("Body", "Coat", (0, 0.0, 1.15), (0.92, 0.8, 0.5), cut=lambda x, y, z: z >= 0.78)  # the coat's flared skirt
    P.shade(v, "Coat")
    v.paint("CoatDark", lambda x, y, z: z < 0.92, part="Body", only={"Coat", "CoatHi", "CoatLo", "CoatCrease"})  # a darker hem band
    v.box("Body", "CoatDark", (0, 0.76, 1.6), (0.08, 0.06, 0.95))  # the button placket
    for z in (1.3, 1.65, 2.0): v.ell("Body", "Brass", (0, 0.8, z), (0.07, 0.05, 0.07))
    # the quills: a fan radiating from behind the head over the shoulders, long, dark with pale tips, in three shingled rows
    hub = V(0, -0.35, 2.55)
    for row, (L, w, n, spread) in enumerate(((1.45, 0.17, 11, 200), (1.2, 0.15, 9, 170), (0.95, 0.13, 7, 140))):
        for k in range(n):
            a = math.radians(-spread / 2 + k * spread / (n - 1))
            d = V(math.sin(a) * 1.15, -0.5 - row * 0.12, math.cos(a) * 1.0).normalized()  # outward and up, a spiky halo in every view
            base = hub + V(math.sin(a) * 0.35, -0.12 * row, math.cos(a) * 0.3 - 0.3 * row)
            v.crystal("Body", "Spine", base, tuple(d), L, w, sides=4)
            v.crystal("Body", "SpineTip", base + d * L * 0.62, tuple(d), L * 0.38, w * 0.55, sides=4)
    # the satchel: a strap across the chest, a fat leather bag at the right hip
    v.curve("Body", "Leather", [(-0.55, 0.45, 2.35), (-0.1, 0.78, 1.85), (0.5, 0.62, 1.35)], [0.08, 0.08, 0.08])
    v.box("Body", "Leather", (0.86, 0.2, 1.2), (0.34, 0.66, 0.56))
    v.box("Body", "LeatherDark", (1.02, 0.2, 1.36), (0.06, 0.68, 0.3))  # the flap
    v.box("Body", "Brass", (1.06, 0.2, 1.26), (0.04, 0.14, 0.1))
    v.anchor("chest", "Body", (0, 0.8, 2.0))
    # the head: a round hedgehog head, a cream face mask inside darker fur, a pointed snout, a black nose, round worried eyes
    v.joint("Head", (0, 0.1, 2.5), "Body", "head")
    v.muscle("Head", "FaceDark", (0, 0.05, 3.05), (0.78, 0.72, 0.68))
    v.muscle("Head", "Face", (0, 0.32, 2.98), (0.66, 0.56, 0.56))
    P.shade(v, "Face", parts={"Head"})
    v.cap("Head", "Face", V(0, 0.7, 2.9), V(0, 1.3, 2.8), 0.34, 0.14)  # the snout
    v.ell("Head", "Nose", (0, 1.38, 2.82), (0.12, 0.09, 0.1))
    for s in (-1, 1):
        round_eye(v, "Head", (s * 0.3, 0.8, 3.08), (s * 0.3, 1, 0.05), 0.3, 0.38, skin="Face")
        v.box("Head", "Brow", (s * 0.3, 0.84, 3.34), (0.26, 0.07, 0.07), rot=E(0, s * -24, 0))  # brows up in the middle: worried
        v.ell("Head", "Blush", (s * 0.5, 0.72, 2.8), (0.13, 0.06, 0.07))
        v.ell("Head", "FaceDark", (s * 0.66, 0.1, 3.32), (0.18, 0.12, 0.18))  # a small round ear
        v.ell("Head", "Blush", (s * 0.68, 0.18, 3.32), (0.09, 0.05, 0.09))
    v.box("Head", "Nose", (0, 1.14, 2.66), (0.14, 0.05, 0.04))  # a small wobbly mouth
    # the helmet: oversized butter brass, tipped back, a front brim, a dent, a ridge, a big headlamp
    tilt = E(18, 8, 0)
    v.ell("Head", "Helm", (0.05, -0.05, 3.48), (0.86, 0.84, 0.58), rot=tilt, cut=lambda x, y, z: z >= 3.3 + y * 0.32)
    v.ell("Head", "HelmDark", (0, 0.55, 3.38), (0.7, 0.42, 0.06), rot=tilt)  # the front brim
    v.torus("Head", "HelmDark", (0, -0.05, 3.38), (0, -0.3, 1), 0.84, 0.08)  # the rim
    v.carve(lambda x, y, z: (V(x, y, z) - V(0.72, 0.0, 3.82)).length < 0.22, part="Head")  # the dent
    v.box("Head", "HelmDark", (0, -0.05, 4.02), (0.12, 1.3, 0.08), rot=tilt)  # a ridge front to back
    v.cap("Head", "Brass", V(0, 0.62, 3.72), V(0, 0.92, 3.78), 0.24, 0.24)  # the headlamp
    v.ell("Head", "Lamp", (0, 0.95, 3.78), (0.19, 0.05, 0.19))
    v.anchor("lamp", "Head", (0, 0.98, 3.78))
    v.anchor("eyes", "Head", (0, 0.85, 3.08)); v.anchor("speech", "Head", (0, 0.1, 4.6))
    # the scarf: a knit loop round the neck, its tail blowing out back-right, fringed
    v.torus("Body", "Scarf", (0, 0.05, 2.42), (0, 0, 1), 0.58, 0.18)
    for k in (1, 3): v.torus("Body", "ScarfDark", (0, 0.05, 2.32 + k * 0.05), (0, 0, 1), 0.64, 0.025)
    tail = [V(0.45, -0.3, 2.4), V(0.95, -0.75, 2.3), V(1.45, -1.05, 2.0), V(1.85, -1.25, 1.75)]
    v.tube("Body", "Scarf", tail, [0.17, 0.16, 0.15, 0.13])
    for t in (0.33, 0.66): v.torus("Body", "ScarfDark", tail[1].lerp(tail[2], t), tuple((tail[2] - tail[1]).normalized()), 0.16, 0.04)
    for k in range(4): v.crystal("Body", "ScarfDark", tail[3] + V(0.05, -0.1 + k * 0.06, -0.05), (0.6, -0.4, -0.6), 0.24, 0.04, sides=4)
    # arms: the left paw holds the lantern out forward-left at arm's length, the right clutches the satchel strap
    lan = V(-1.75, 1.3, 1.75)
    arms = {"ArmL": (V(-0.78, 0.1, 2.25), V(-1.3, 0.6, 2.0), V(-1.7, 1.2, 2.25)), "ArmR": (V(0.78, 0.1, 2.25), V(0.95, 0.6, 1.75), V(0.4, 0.82, 1.95))}
    for A, (sh, el, wr) in arms.items():
        v.joint(A + "1", tuple(sh), "Body", "arm")
        v.cap(A + "1", "Coat", sh, el, 0.22, 0.2)
        v.joint(A + "2", tuple(el), A + "1", "arm")
        v.cap(A + "2", "Coat", el, wr, 0.2, 0.18)
        v.torus(A + "2", "CoatDark", wr + (el - wr).normalized() * 0.08, tuple((wr - el).normalized()), 0.19, 0.05)
        v.ell(A + "2", "Face", tuple(wr + V(0, 0.06, 0)), (0.16, 0.15, 0.15))
        v.anchor("hand" + A[3:], A + "2", tuple(wr))
    # the hand lantern: hanging under the paw from a ring, a brass cage round a glowing heart
    v.line("ArmL2", "Brass", [V(-1.7, 1.25, 2.12), lan + V(0, 0, 0.36)], r=0.04)
    v.box("ArmL2", "Brass", tuple(lan + V(0, 0, -0.42)), (0.56, 0.56, 0.1))
    v.box("ArmL2", "Brass", tuple(lan + V(0, 0, 0.3)), (0.46, 0.46, 0.1))
    v.cap("ArmL2", "Brass", lan + V(0, 0, 0.34), lan + V(0, 0, 0.5), 0.18, 0.08)
    for cx in (-1, 1):
        for cy in (-1, 1): v.box("ArmL2", "Brass", tuple(lan + V(cx * 0.23, cy * 0.23, -0.06)), (0.06, 0.06, 0.7))
    v.ell("ArmL2", "Glow", tuple(lan + V(0, 0, -0.06)), (0.22, 0.22, 0.32))
    v.ell("ArmL2", "Ember", tuple(lan + V(0, 0, -0.08)), (0.1, 0.1, 0.14))
    v.anchor("lantern", "ArmL2", tuple(lan))
    # crouched legs apart in dark boots, knees bent, daylight between them
    for s, L in ((-1, "LegL"), (1, "LegR")):
        hip, knee, foot = V(s * 0.4, 0.0, 1.0), V(s * 0.6, 0.38, 0.55), V(s * 0.68, 0.2, 0.0)
        v.joint(L + "1", tuple(hip), "Body", "leg")
        v.cap(L + "1", "CoatDark", hip, knee, 0.22, 0.2)
        v.joint(L + "2", tuple(knee), L + "1", "leg")
        v.cap(L + "2", "Boot", knee, foot + V(0, 0, 0.2), 0.2, 0.19)
        v.ell(L + "2", "Boot", tuple(foot + V(0, 0.18, 0.13)), (0.24, 0.36, 0.15))
        v.torus(L + "2", "LeatherDark", foot + V(0, 0.05, 0.42), (0, 0, 1), 0.22, 0.05)
        v.anchor("foot" + L[3:], L + "2", tuple(foot + V(0, 0.2, 0.1)))
    P.ground(v)



# ---------------------------------------------------------------- SMUDGE: the shy soot-sprite (Camp 1, behind the lantern post)
# a timid charcoal-violet fluffball: wispy jagged fur all round, jagged tufted ears, big wide butter-gold eyes, a crooked
# oversized miner cap with a tiny lamp, a warm glowing pebble held in both little paws, a wispy curl of a tail
@char("Smudge", P.palette(form=("Soot",), Soot="#4a3c5c", SootLo="#2e2440", Wisp="#6c5a84", WispTip="#9a88b4", Eye="#1a1228", Iris="#ffd24a",
                          Shine="#ffffff", Cap="#e8c25a", CapDark="#a8822a", Lamp="#fff2b0", Pebble="#ff9a40", PebbleHot="#ffd27a", Blush="#e888b0",
                          Paw="#5c4c70"))
def smudge(v):
    E = P.E
    v.joint("Body", (0, 0, 0.7))
    v.muscle("Body", "Soot", (0, 0, 0.72), (0.66, 0.6, 0.6))
    P.shade(v, "Soot")
    for row, (z, n, L) in enumerate(((0.45, 6, 0.48), (0.9, 7, 0.5))):  # s2: two rows of big soot tufts (d1 random wisps and three thin rows read as noise)
        for q in range(n):
            a = (q + row * 0.5) / n * math.tau
            d = V(math.cos(a), math.sin(a), 0.35 + row * 0.25)
            if d.y > 0.6 and row < 2: continue  # the belly front stays clear for the paws and pebble
            base = V(math.cos(a) * 0.6, math.sin(a) * 0.54, z + 0.1)
            v.crystal("Body", "Wisp" if q % 2 else "WispTip", base, tuple(d), L, 0.2, sides=4)
    # the wispy tail: a curl behind, ending in a pale flick
    tl = [V(0, -0.5, 0.45), V(0.15, -0.95, 0.55), V(0.35, -1.1, 0.95), V(0.2, -0.95, 1.2)]
    v.joint("Tail", tuple(tl[0]), "Body", "tail")
    v.tube("Tail", "Soot", tl, [0.16, 0.14, 0.11, 0.07])
    v.crystal("Tail", "WispTip", tl[3], (-0.3, 0.6, 0.8), 0.3, 0.08, sides=4)
    v.anchor("tail", "Tail", tuple(tl[3]))
    # the head: round, big golden eyes, tufted ears, the cap pushed crooked
    v.joint("Head", (0, 0.05, 1.12), "Body", "head")
    v.muscle("Head", "Soot", (0, 0.05, 1.45), (0.6, 0.56, 0.52))
    P.shade(v, "Soot", parts={"Head"})
    for s in (-1, 1):
        v.eye("Head", (s * 0.25, 0.48, 1.45), (s * 0.3, 1, 0.05), w=0.34, h=0.42, iris="Iris")
        v.ell("Head", "Blush", (s * 0.42, 0.46, 1.22), (0.12, 0.05, 0.06))
        for k in range(3):  # a jagged tufted ear: three wisps fanned out
            v.crystal("Head", "Wisp" if k != 1 else "WispTip", V(s * 0.38, -0.05, 1.82), (s * (0.5 + 0.25 * k), -0.2 + 0.15 * k, 1), 0.55 - 0.1 * k, 0.1, sides=4)
    v.box("Head", "SootLo", (0, 0.56, 1.18), (0.12, 0.05, 0.04))  # a small worried mouth
    # the cap: oversized, crooked over one eye, a brim, a tiny lamp
    tilt = E(0, -18, 10)
    v.ell("Head", "Cap", (-0.1, 0.0, 1.82), (0.56, 0.54, 0.4), rot=tilt, cut=lambda x, y, z: z >= 1.74 - x * 0.3)
    v.ell("Head", "CapDark", (-0.08, 0.22, 1.72), (0.6, 0.45, 0.07), rot=tilt)  # the brim
    v.cap("Head", "CapDark", V(-0.2, 0.48, 1.92), V(-0.22, 0.6, 1.94), 0.11, 0.11)
    v.ell("Head", "Lamp", (-0.22, 0.62, 1.94), (0.08, 0.03, 0.08))
    v.anchor("eyes", "Head", (0, 0.5, 1.45)); v.anchor("speech", "Head", (0, 0.0, 2.6))
    # little paws holding a warm pebble against the belly
    peb = V(0, 0.66, 0.78)
    for s, A in ((-1, "ArmL"), (1, "ArmR")):
        sh, wr = V(s * 0.45, 0.35, 0.92), V(s * 0.2, 0.68, 0.82)
        v.joint(A + "1", tuple(sh), "Body", "arm")
        v.cap(A + "1", "Paw", sh, wr, 0.11, 0.1)
        v.anchor("hand" + A[3:], A + "1", tuple(wr))
    v.ell("ArmR1", "Pebble", tuple(peb), (0.16, 0.13, 0.13))
    v.ell("ArmR1", "PebbleHot", tuple(peb + V(0.02, 0.06, 0.04)), (0.08, 0.06, 0.06))
    v.anchor("pebble", "ArmR1", tuple(peb))
    for s, L in ((-1, "LegL"), (1, "LegR")):  # stubby feet peeking out under the fluff
        v.joint(L + "1", (s * 0.25, 0.1, 0.2), "Body", "leg")
        v.ell(L + "1", "Paw", (s * 0.27, 0.25, 0.1), (0.16, 0.22, 0.11))
        v.anchor("foot" + L[3:], L + "1", (s * 0.27, 0.25, 0.05))
    P.ground(v)



# ---------------------------------------------------------------- PIP: the town scout and messenger (the notice plaza)
# a sprightly red squirrel (2026-11-27: the named folk are creatures; the big tail is the silhouette): a layered coral scarf,
# a navy postman cap with a brass badge, a leather shoulder bag stuffed with rolled map scrolls, one paw up in a wave
@char("Pip", P.palette(form=("Fur", "Vest"), Fur="#d8743a", FurDark="#9a4a24", Cream="#f6e2c4", Vest="#3e5a9c", VestDark="#28386a",
                       Scarf="#ff7a6a", ScarfDark="#c84a46", Cap="#2e3e72", CapDark="#1c2648", Brass="#e8b84a", Leather="#8a5a34",
                       LeatherDark="#5e3a20", Paper="#f8eed8", PaperDark="#d8c8a4", Ribbon="#e84a5a", Eye="#1a1228", Iris="#5a3418",
                       Shine="#ffffff", Blush="#f39ab4", Nose="#3a2020", Boot="#4a3430"))
def pip(v):
    E = P.E
    v.joint("Body", (0, 0, 1.55))
    v.muscle("Body", "Fur", (0, 0, 1.55), (0.72, 0.62, 0.8))
    v.muscle("Body", "Vest", (0, 0.02, 1.75), (0.76, 0.66, 0.62))
    P.shade(v, "Fur", "Vest")
    v.ell("Body", "Cream", (0, 0.5, 1.3), (0.42, 0.18, 0.5))  # the cream belly
    v.box("Body", "VestDark", (0, 0.66, 1.78), (0.07, 0.05, 0.6))
    for z in (1.55, 1.8, 2.05): v.ell("Body", "Brass", (0, 0.68, z), (0.06, 0.04, 0.06))
    # the scarf: two layered coral wraps and a long end flying back over the shoulder
    v.torus("Body", "Scarf", (0, 0.0, 2.25), (0, 0, 1), 0.56, 0.17)
    v.torus("Body", "ScarfDark", (0.02, 0.02, 2.08), (0.1, 0, 1), 0.6, 0.12)
    v.tube("Body", "Scarf", [V(-0.35, -0.35, 2.25), V(-0.75, -0.85, 2.35), V(-1.05, -1.25, 2.6)], [0.14, 0.13, 0.11])
    for k in range(3): v.crystal("Body", "ScarfDark", V(-1.05, -1.25, 2.6), (-0.4 + k * 0.2, -1, 0.3), 0.26, 0.04, sides=4)
    # the bag: a strap from the right shoulder to the left hip, a leather satchel stuffed with rolled maps
    v.curve("Body", "Leather", [(0.48, 0.3, 2.2), (0.1, 0.66, 1.7), (-0.55, 0.42, 1.15)], [0.07, 0.07, 0.07])
    v.box("Body", "Leather", (-0.78, 0.1, 1.05), (0.34, 0.7, 0.56))
    v.box("Body", "LeatherDark", (-0.92, 0.1, 1.24), (0.08, 0.72, 0.22))
    v.box("Body", "Brass", (-0.97, 0.1, 1.15), (0.04, 0.12, 0.1))
    for k, (dy, h) in enumerate(((-0.2, 0.7), (0.05, 0.85), (0.28, 0.6))):  # rolled maps sticking out of the bag
        c0 = V(-0.74 + (k - 1) * 0.06, dy, 1.3)
        v.cap("Body", "Paper", c0, c0 + V(-0.12, 0.02, h), 0.1, 0.1)
        v.torus("Body", "Ribbon", c0 + V(-0.08, 0.01, h * 0.55), (-0.15, 0, 1), 0.11, 0.03)
        v.ell("Body", "PaperDark", tuple(c0 + V(-0.12, 0.02, h + 0.04)), (0.07, 0.07, 0.03))
    v.anchor("chest", "Body", (0, 0.66, 1.9))
    # the tail: a huge bushy S-curve up behind, a darker underside, a cream tip
    tp = [V(-0.1, -0.55, 1.0), V(-0.65, -1.3, 0.95), V(-1.55, -1.45, 1.6), V(-2.05, -1.2, 2.5), V(-1.85, -0.8, 3.05)]  # p3: out past the flank, a gap at the root, the S plume clear of the back  # p2: a thin root, swept to one side under the hat line (d1: a blob behind the head)
    v.joint("Tail", tuple(tp[0]), "Body", "tail")
    v.tube("Tail", "Fur", tp, [0.2, 0.42, 0.58, 0.5, 0.3])
    for t in (0.35, 0.55, 0.75): v.torus("Tail", "Cream", tp[1].lerp(tp[3], t), tuple((tp[3] - tp[1]).normalized()), 0.55 - 0.1 * abs(t - 0.55) * 4, 0.07)  # cream bands
    v.tube("Tail", "FurDark", [t + V(0, 0.12, -0.05) for t in tp[1:4]], [0.36, 0.42, 0.36])
    for k in range(10):  # tufts round the tail's edge so it reads as fur
        t = 0.1 + k * 0.085; i = min(int(t * 4), 3); u = t * 4 - i
        c = tp[i].lerp(tp[i + 1], u); d = (tp[i + 1] - tp[i]).normalized()
        out = d.cross(V(1, 0, 0)).normalized() * (1 if k % 2 else -1)
        v.crystal("Tail", "Fur", c + out * 0.45, tuple(out + V(0.3 * (1 if k % 3 else -1), 0, 0)), 0.3, 0.1, sides=4)
    v.ell("Tail", "Cream", tuple(tp[4] + V(0, 0.08, 0.05)), (0.3, 0.26, 0.24))
    v.anchor("tail", "Tail", tuple(tp[4]))
    # the head: round, a cream muzzle, big eyes, tufted ears, the postman cap with a brass badge and a short peak
    v.joint("Head", (0, 0.1, 2.4), "Body", "head")
    v.muscle("Head", "Fur", (0, 0.12, 2.98), (0.66, 0.62, 0.6))
    P.shade(v, "Fur", parts={"Head"})
    v.ell("Head", "Cream", (0, 0.6, 2.78), (0.36, 0.22, 0.26))
    v.ell("Head", "Nose", (0, 0.82, 2.86), (0.08, 0.05, 0.06))
    v.box("Head", "Nose", (0, 0.8, 2.66), (0.12, 0.05, 0.04))
    for s in (-1, 1):
        v.eye("Head", (s * 0.27, 0.6, 3.05), (s * 0.3, 1, 0.05), w=0.32, h=0.4, iris="Iris")
        v.ell("Head", "Blush", (s * 0.45, 0.52, 2.78), (0.12, 0.05, 0.06))
        v.ell("Head", "FurDark", (s * 0.42, -0.05, 3.62), (0.14, 0.1, 0.24))  # an ear
        v.crystal("Head", "FurDark", V(s * 0.44, -0.05, 3.8), (s * 0.2, -0.1, 1), 0.3, 0.07, sides=4)  # its tuft
        v.ell("Head", "Cream", (s * 0.42, 0.04, 3.6), (0.07, 0.04, 0.14))
    v.ell("Head", "Cap", (0, 0.08, 3.42), (0.6, 0.58, 0.26), cut=lambda x, y, z: z >= 3.32)
    v.ell("Head", "CapDark", (0, 0.42, 3.36), (0.5, 0.34, 0.06), cut=lambda x, y, z: y >= 0.3)  # the peak
    v.torus("Head", "CapDark", (0, 0.08, 3.36), (0, 0, 1), 0.6, 0.06)
    v.ell("Head", "Brass", (0, 0.66, 3.5), (0.1, 0.04, 0.09))
    v.anchor("eyes", "Head", (0, 0.62, 3.05)); v.anchor("speech", "Head", (0, 0.1, 4.2))
    # arms: the right waves high, the left rests on the bag
    for s, A, el, wr in ((1, "ArmR", V(1.15, 0.15, 2.5), V(1.55, 0.3, 3.15)), (-1, "ArmL", V(-0.85, 0.3, 1.55), V(-0.62, 0.55, 1.4))):
        sh = V(s * 0.66, 0.05, 2.05)
        v.joint(A + "1", tuple(sh), "Body", "arm")
        v.cap(A + "1", "Vest", sh, el, 0.17, 0.15)
        v.joint(A + "2", tuple(el), A + "1", "arm")
        v.cap(A + "2", "Fur", el, wr, 0.14, 0.13)
        v.ell(A + "2", "Cream", tuple(wr + V(0, 0.04, 0.05)), (0.15, 0.12, 0.16))
        v.anchor("hand" + A[3:], A + "2", tuple(wr))
    for s, L in ((-1, "LegL"), (1, "LegR")):
        hip, foot = V(s * 0.32, 0.0, 0.95), V(s * 0.4, 0.2, 0.0)
        v.joint(L + "1", tuple(hip), "Body", "leg")
        v.cap(L + "1", "Fur", hip, foot + V(0, 0, 0.2), 0.2, 0.15)
        v.ell(L + "1", "Boot", tuple(foot + V(0, 0.2, 0.12)), (0.2, 0.34, 0.14))
        v.anchor("foot" + L[3:], L + "1", tuple(foot + V(0, 0.2, 0.1)))
    P.ground(v)



# ---------------------------------------------------------------- JUNIPER and TOCK: the marshmallow roasters (the town campfire)
# two townsfolk toasting marshmallows on long sticks: Juniper a badger in a knit pom beanie and a mossy shawl, Tock a fox in
# a dusk hood and a buttoned vest. One body plan, its own head, clothes and colours each.
def roaster(v, fox):
    E = P.E
    v.joint("Body", (0, 0, 1.5))
    v.muscle("Body", "Fur", (0, 0, 1.45), (0.74, 0.64, 0.82))
    v.muscle("Body", "Cloth", (0, 0.02, 1.68), (0.8, 0.7, 0.66))
    P.shade(v, "Fur", "Cloth")
    v.ell("Body", "Belly", (0, 0.52, 1.2), (0.44, 0.18, 0.5))
    if fox:  # Tock: a buttoned dusk vest with a pocket watch chain, a big white-tipped brush tail
        v.box("Body", "ClothDark", (0, 0.72, 1.75), (0.07, 0.05, 0.6))
        for z in (1.5, 1.75, 2.0): v.ell("Body", "Brass", (0, 0.74, z), (0.06, 0.04, 0.06))
        v.curve("Body", "Brass", [(0.05, 0.74, 1.62), (0.3, 0.74, 1.5), (0.42, 0.7, 1.62)], [0.03, 0.03, 0.03])
        tp = [V(-0.1, -0.55, 0.95), V(-0.75, -1.2, 0.85), V(-1.45, -1.3, 1.4), V(-1.6, -0.95, 2.05)]  # d2: flared out past the flank
        v.joint("Tail", tuple(tp[0]), "Body", "tail")
        v.tube("Tail", "Fur", tp, [0.22, 0.42, 0.44, 0.28])
        v.ell("Tail", "Belly", tuple(tp[3] + V(0, 0.05, 0.12)), (0.3, 0.28, 0.3))
        v.anchor("tail", "Tail", tuple(tp[3]))
    else:  # Juniper: a mossy knitted shawl over the shoulders with a leaf brooch, a short striped tail
        v.ell("Body", "Shawl", (0, 0.0, 2.05), (0.92, 0.82, 0.5), cut=lambda x, y, z: z >= 1.75)
        v.torus("Body", "ShawlDark", (0, 0.0, 1.78), (0, 0, 1), 0.86, 0.08)
        for k in range(12):  # its fringe
            a = k / 12 * math.tau
            v.crystal("Body", "ShawlDark", V(math.cos(a) * 0.86, math.sin(a) * 0.78, 1.74), (math.cos(a) * 0.2, math.sin(a) * 0.2, -1), 0.22, 0.04, sides=4)
        v.ell("Body", "Leaf", (0.3, 0.74, 2.05), (0.14, 0.05, 0.1), rot=E(0, 30, 0))
        v.joint("Tail", (0, -0.6, 0.95), "Body", "tail")
        v.cap("Tail", "Fur", V(0, -0.6, 0.95), V(0, -0.95, 0.75), 0.2, 0.12)
        v.anchor("tail", "Tail", (0, -0.95, 0.75))
    v.anchor("chest", "Body", (0, 0.7, 1.9))
    # the head
    v.joint("Head", (0, 0.1, 2.3), "Body", "head")
    v.muscle("Head", "Fur", (0, 0.12, 2.9), (0.7, 0.64, 0.6))
    P.shade(v, "Fur", parts={"Head"})
    if fox:
        v.cap("Head", "Belly", V(0, 0.5, 2.72), V(0, 1.05, 2.66), 0.32, 0.12)  # a long pale muzzle
        v.ell("Head", "Nose", (0, 1.12, 2.68), (0.08, 0.06, 0.06))
        for s in (-1, 1):
            v.crystal("Head", "Fur", V(s * 0.42, 0.0, 3.3), (s * 0.35, 0.05, 1), 0.62, 0.22, sides=4)  # tall pointed ears
            v.crystal("Head", "Ear", V(s * 0.42, 0.06, 3.32), (s * 0.35, 0.05, 1), 0.42, 0.12, sides=4)
            v.ell("Head", "Belly", (s * 0.48, 0.4, 2.68), (0.18, 0.14, 0.14))  # white cheek tufts
        # the dusk hood, pushed back off the ears, draping to the shoulders
        v.ell("Head", "Hood", (0, -0.42, 2.85), (0.78, 0.5, 0.7), cut=lambda x, y, z: y <= -0.12)
        v.torus("Head", "HoodDark", (0, -0.2, 2.85), (0, 1, 0.15), 0.72, 0.09)
    else:
        v.cap("Head", "Belly", V(0, 0.45, 2.8), V(0, 0.98, 2.72), 0.3, 0.13)  # d2: a wedge muzzle
        v.box("Head", "Belly", (0, 0.3, 3.15), (0.2, 0.7, 0.5))  # the white stripe up over the head
        for s in (-1, 1):
            v.box("Head", "Stripe", (s * 0.3, 0.3, 3.05), (0.18, 0.7, 0.55))  # the dark badger bands over the eyes
            v.ell("Head", "Stripe", (s * 0.66, 0.0, 3.22), (0.18, 0.1, 0.17))  # d2: round badger ears out beside the beanie
            v.ell("Head", "Belly", (s * 0.66, 0.07, 3.22), (0.1, 0.05, 0.1))
        v.ell("Head", "Nose", (0, 1.04, 2.74), (0.1, 0.07, 0.08))
        # the knit beanie with ribs and a big pom
        v.ell("Head", "Hat", (0, 0.05, 3.3), (0.68, 0.64, 0.46), cut=lambda x, y, z: z >= 3.24)
        v.torus("Head", "HatDark", (0, 0.05, 3.27), (0, 0, 1), 0.66, 0.1)
        for k in range(4): v.torus("Head", "HatDark", (0, 0.05, 3.42 + k * 0.09), (0, 0, 1), 0.62 - k * 0.1, 0.025)
        v.ell("Head", "Pom", (0, 0.0, 3.85), (0.22, 0.22, 0.2))
    for s in (-1, 1):
        v.eye("Head", (s * 0.27, 0.58, 3.0), (s * 0.3, 1, 0.05), w=0.3, h=0.36, iris="Iris")
        v.ell("Head", "Blush", (s * 0.46, 0.5, 2.74), (0.12, 0.05, 0.06))
    v.box("Head", "Nose", (0, 0.68 if not fox else 0.95, 2.6), (0.12, 0.05, 0.04))
    v.anchor("eyes", "Head", (0, 0.6, 3.0)); v.anchor("speech", "Head", (0, 0.1, 4.2))
    # arms: both paws on a long roasting stick held out over the fire, a toasted marshmallow at its end
    for s, A in ((-1, "ArmL"), (1, "ArmR")):
        sh, el, wr = V(s * 0.7, 0.05, 2.05), V(s * 0.85, 0.5, 1.6), V(s * 0.25 + 0.3, 0.95, 1.75)
        v.joint(A + "1", tuple(sh), "Body", "arm")
        v.cap(A + "1", "Cloth", sh, el, 0.17, 0.15)
        v.joint(A + "2", tuple(el), A + "1", "arm")
        v.cap(A + "2", "Fur", el, wr, 0.15, 0.13)
        v.ell(A + "2", "Paw", tuple(wr + V(0, 0.05, 0)), (0.14, 0.13, 0.13))
        v.anchor("hand" + A[3:], A + "2", tuple(wr))
    st0, st1 = V(0.2, 0.75, 1.6), V(0.55, 3.2, 2.55)
    v.cap("ArmR2", "Stick", st0, st1, 0.1, 0.08)  # d2: a branch, not a wire
    v.ell("ArmR2", "Mallow", tuple(st1 + V(0, 0.18, 0.05)), (0.24, 0.26, 0.22))
    v.ell("ArmR2", "Toast", tuple(st1 + V(0, 0.36, 0.02)), (0.18, 0.1, 0.16))
    v.anchor("marshmallow", "ArmR2", tuple(st1 + V(0, 0.18, 0.05)))
    for s, L in ((-1, "LegL"), (1, "LegR")):
        hip, foot = V(s * 0.34, 0.0, 0.9), V(s * 0.42, 0.2, 0.0)
        v.joint(L + "1", tuple(hip), "Body", "leg")
        v.cap(L + "1", "Fur" if fox else "Stripe", hip, foot + V(0, 0, 0.2), 0.22, 0.16)
        v.ell(L + "1", "Boot", tuple(foot + V(0, 0.2, 0.12)), (0.21, 0.34, 0.14))
        v.anchor("foot" + L[3:], L + "1", tuple(foot + V(0, 0.2, 0.1)))
    P.ground(v)


@char("Juniper", P.palette(form=("Fur", "Cloth"), Fur="#8a8494", Stripe="#2e2a36", Belly="#f4f0ea", Cloth="#d86a8a", ClothDark="#9a4060",
                           Shawl="#6aa06a", ShawlDark="#3e6e44", Leaf="#9ad86a", Hat="#e0a03a", HatDark="#a8701e", Pom="#fff4dc",
                           Nose="#1e1a22", Eye="#1a1228", Iris="#3a2a1a", Shine="#ffffff", Blush="#f39ab4", Paw="#4a4452", Boot="#5a3a30",
                           Stick="#8a5a30", Mallow="#fff6ec", Toast="#c88a4a", Brass="#e0b04a", Ear="#2e2a36", Hood="#5a4a7a", HoodDark="#3a2e56"))
def juniper(v): roaster(v, False)


@char("Tock", P.palette(form=("Fur", "Cloth"), Fur="#e0783a", Stripe="#3a2a2a", Belly="#fff4e6", Cloth="#4a5a8c", ClothDark="#2c3660",
                        Shawl="#6aa06a", ShawlDark="#3e6e44", Leaf="#9ad86a", Hat="#e0a03a", HatDark="#a8701e", Pom="#fff4dc",
                        Nose="#1e1a22", Eye="#1a1228", Iris="#3a2a1a", Shine="#ffffff", Blush="#f39ab4", Paw="#3a2a2e", Boot="#3a2e36",
                        Stick="#8a5a30", Mallow="#fff6ec", Toast="#c88a4a", Brass="#e0b04a", Ear="#3a2a2e", Hood="#6a5aa0", HoodDark="#40346a"))
def tock(v): roaster(v, True)



# ---------------------------------------------------------------- GLOOMLING: the layer 1 darkness prowler (an enemy)
# a hunched shadow-cat gremlin: jagged soot fur, tall tufted cat ears, a curled smoke tail that pales to its tip, sharp pale
# claws, glowing amber ring eyes with dark slit pupils, a jagged grin
@char("Gloomling", P.palette(form=("Soot",), Soot="#2c2438", SootHi="#4a3c5e", Smoke="#5e4e78", Smoke2="#8e7eac", Smoke3="#c4b8dc",
                             Ring="#ffb030", Pupil="#0a0610", Claw="#e4dcec", Teeth="#f4eefa", Mouth="#120a18", Inner="#ff6a8a",
                             Eye="#0a0610", Shine="#ffffff"))
def gloomling(v):
    E = P.E
    import random
    rnd = random.Random(11)
    v.joint("Body", (0, 0, 1.2))
    # hunched: the chest pitched forward over bent legs, the back a high arch
    v.muscle("Body", "Soot", (0, 0.1, 1.35), (0.72, 0.8, 0.62), rot=E(-25, 0, 0))
    v.muscle("Body", "Soot", (0, -0.45, 1.05), (0.6, 0.55, 0.5))
    P.shade(v, "Soot")
    for k in range(80):  # jagged fur: spiky soot tufts along the back, shoulders and flanks
        a = rnd.uniform(-2.6, 2.6); h = rnd.uniform(0.85, 1.75)
        base = V(math.sin(a) * 0.62, -math.cos(a) * 0.55 + 0.05, h)
        d = V(math.sin(a) * 0.6, -0.8, 0.6).normalized()
        v.crystal("Body", "SootHi" if k % 4 == 0 else "Soot", base, tuple(d), rnd.uniform(0.25, 0.5), 0.09, sides=4)
    for k in range(4):  # d3: four smoke plates down the spine (d2's seven thin shards read as noise)
        v.crystal("Body", "Smoke2", V(0, -0.4 - k * 0.16, 1.9 - k * 0.22), (0, -0.4, 1), 0.55 - k * 0.07, 0.17, sides=4)
    # the smoke tail: segments that curl up and pale from soot to smoke, ending in a wisp
    tp = [V(0, -0.85, 0.95), V(0.2, -1.45, 0.85), V(0.55, -1.8, 1.35), V(0.6, -1.6, 2.1), V(0.3, -1.2, 2.45)]
    v.joint("Tail", tuple(tp[0]), "Body", "tail")
    cols = ["Soot", "Smoke", "Smoke", "Smoke2", "Smoke3"]
    for k in range(13):
        t = k / 12 * 3.999; i = int(t); u = t - i
        c = tp[i].lerp(tp[i + 1], u); r = 0.26 * (1 - k / 16)
        v.ell("Tail", cols[min(int(k / 13 * 5), 4)], tuple(c), (r, r, r))
    for k in range(3): v.crystal("Tail", "Smoke3", tp[4], (-0.3 + k * 0.3, 0.4, 1), 0.4 - k * 0.08, 0.07, sides=4)
    v.anchor("tail", "Tail", tuple(tp[4]))
    # the head: low and forward, ring eyes, slit pupils, tall tufted ears, a jagged grin
    v.joint("Head", (0, 0.65, 1.7), "Body", "head")
    v.muscle("Head", "Soot", (0, 0.85, 1.95), (0.58, 0.52, 0.48))
    P.shade(v, "Soot", parts={"Head"})
    for s in (-1, 1):
        v.eye("Head", (s * 0.25, 1.28, 2.04), (s * 0.35, 1, 0.05), w=0.3, h=0.3, iris="Ring")  # d3: the kit's eye (d1/d2 boxes read as goggles)
        v.ell("Head", "SootHi", (s * 0.27, 1.22, 2.27), (0.2, 0.08, 0.06), rot=E(0, s * -18, 0))  # a heavy brow over it
        v.crystal("Head", "Soot", V(s * 0.32, 0.75, 2.35), (s * 0.35, -0.1, 1), 0.85, 0.22, sides=4)  # tall cat ears
        v.crystal("Head", "Inner", V(s * 0.32, 0.82, 2.4), (s * 0.35, -0.1, 1), 0.5, 0.09, sides=4)
        v.crystal("Head", "SootHi", V(s * 0.45, 0.72, 3.1), (s * 0.4, 0, 1), 0.3, 0.05, sides=4)  # ear tufts
    v.box("Head", "Mouth", (0, 1.27, 1.72), (0.5, 0.06, 0.12))
    for k in range(5): v.crystal("Head", "Teeth", V(-0.2 + k * 0.1, 1.3, 1.78), (0, 0.2, -1), 0.12, 0.035, sides=4)  # the jagged grin
    v.anchor("eyes", "Head", (0, 1.3, 2.02)); v.anchor("speech", "Head", (0, 0.8, 3.0))
    # long thin arms reaching forward, sharp pale claws
    for s, A in ((-1, "ArmL"), (1, "ArmR")):
        sh, el, wr = V(s * 0.6, 0.45, 1.55), V(s * 0.85, 0.95, 1.0), V(s * 0.6, 1.35, 0.4)
        v.joint(A + "1", tuple(sh), "Body", "arm")
        v.cap(A + "1", "Soot", sh, el, 0.17, 0.13)
        v.joint(A + "2", tuple(el), A + "1", "arm")
        v.cap(A + "2", "Soot", el, wr, 0.13, 0.12)
        for k in range(3): v.crystal(A + "2", "Claw", wr + V((k - 1) * 0.08, 0.1, -0.05), ((k - 1) * 0.3, 1, -0.8), 0.3, 0.04, sides=4)
        v.anchor("hand" + A[3:], A + "2", tuple(wr))
    for s, L in ((-1, "LegL"), (1, "LegR")):  # crouched hind legs
        hip, knee, foot = V(s * 0.4, -0.4, 0.85), V(s * 0.5, 0.1, 0.45), V(s * 0.48, -0.15, 0.0)
        v.joint(L + "1", tuple(hip), "Body", "leg")
        v.cap(L + "1", "Soot", hip, knee, 0.24, 0.17)
        v.cap(L + "1", "Soot", knee, foot + V(0, 0, 0.12), 0.15, 0.12)
        v.ell(L + "1", "Soot", tuple(foot + V(0, 0.15, 0.08)), (0.16, 0.28, 0.1))
        for k in range(3): v.crystal(L + "1", "Claw", foot + V((k - 1) * 0.08, 0.3, 0.06), (0, 1, -0.4), 0.14, 0.04, sides=4)  # d3: on the toes, not on the floor in front
        v.anchor("foot" + L[3:], L + "1", tuple(foot))
    P.ground(v)


# ---------------------------------------------------------------- CLAYLING: the layer 2 weeping-angel pottery idol (an enemy)
# a fired-clay guardian jar on chunky legs: a cracked terracotta amphora torso with mint glaze drips and glowing amber seams
# in the cracks, a carved lid-crown head with slanted brow fissures and a jagged glowing grin, chunky clawed arms
@char("Clayling", P.palette(form=("Clay",), Clay="#c4643a", ClayDark="#8a3e22", ClayLi="#e08a5a", Glaze="#7ae8c8", GlazeDark="#3ea88a",
                            Seam="#ffb040", SeamHot="#fff0a0", Crack="#3a1a10", Eye="#1a0c08", Shine="#ffffff", Claw="#f0e0c8"))
def clayling(v):
    E = P.E
    v.joint("Body", (0, 0, 1.6))
    # the amphora: a round belly, a waist, a shoulder, a neck
    v.muscle("Body", "Clay", (0, 0, 1.55), (0.85, 0.85, 0.85))
    v.ell("Body", "Clay", (0, 0, 2.35), (0.6, 0.6, 0.28))
    v.cap("Body", "Clay", V(0, 0, 0.75), V(0, 0, 1.0), 0.45, 0.6)
    P.shade(v, "Clay")
    v.torus("Body", "ClayDark", (0, 0, 2.12), (0, 0, 1), 0.72, 0.07)
    v.torus("Body", "ClayLi", (0, 0, 1.25), (0, 0, 1), 0.82, 0.05)
    # mint glaze poured over the shoulder, running down in drips
    v.ell("Body", "Glaze", (0, 0, 2.3), (0.66, 0.66, 0.2))
    for k in range(9):
        a = k / 9 * math.tau + 0.2; L = 0.35 + (k * 37 % 5) * 0.12
        top = V(math.cos(a) * 0.74, math.sin(a) * 0.74, 2.2)
        v.cap("Body", "Glaze" if k % 2 else "GlazeDark", top, top + V(math.cos(a) * 0.1, math.sin(a) * 0.1, -L), 0.07, 0.09)
    # cracks with molten seams: zigzag lines on the belly, dark rims round glowing cores
    for pts in ([(-0.5, 0.7, 1.9), (-0.3, 0.8, 1.6), (-0.45, 0.75, 1.3), (-0.2, 0.82, 1.0)], [(0.35, 0.75, 2.0), (0.5, 0.68, 1.7), (0.3, 0.78, 1.45)],
                [(0.6, -0.55, 1.8), (0.75, -0.35, 1.5), (0.55, -0.6, 1.2)], [(-0.7, -0.4, 1.7), (-0.55, -0.62, 1.35)]):
        v.line("Body", "Crack", pts, r=0.07)
        v.line("Body", "Seam", [(x * 1.03, y * 1.03, z) for (x, y, z) in pts], r=0.04)
    v.anchor("chest", "Body", (0, 0.85, 1.7))
    # the head: a carved lid crown on the neck, slanted brow fissures over glowing eyes, a jagged glowing grin
    v.joint("Head", (0, 0, 2.5), "Body", "head")
    v.cap("Head", "Clay", V(0, 0, 2.5), V(0, 0, 2.75), 0.36, 0.42)
    v.ell("Head", "Clay", (0, 0.05, 3.1), (0.56, 0.5, 0.42))
    P.shade(v, "Clay", parts={"Head"})
    for k in range(6):  # the crown's carved points
        a = k / 6 * math.tau
        v.crystal("Head", "ClayLi" if k % 2 else "ClayDark", V(math.cos(a) * 0.42, math.sin(a) * 0.38, 3.4), (math.cos(a) * 0.3, math.sin(a) * 0.3, 1), 0.36, 0.1, sides=4)
    v.ell("Head", "Glaze", (0, 0.0, 3.45), (0.3, 0.28, 0.12))
    for s in (-1, 1):
        v.box("Head", "Crack", (s * 0.22, 0.5, 3.22), (0.32, 0.08, 0.08), rot=E(0, s * 28, 0))  # slanted brow fissures
        v.carve(lambda x, y, z, s=s: abs(x - s * 0.2) < 0.14 and y > 0.4 and 3.0 < z < 3.16, part="Head")  # d2: a socket (d1: proud pegs)
        v.ell("Head", "Seam", (s * 0.2, 0.38, 3.08), (0.12, 0.05, 0.08))
        v.ell("Head", "SeamHot", (s * 0.2, 0.42, 3.08), (0.06, 0.03, 0.04))
    v.box("Head", "Crack", (0, 0.52, 2.86), (0.46, 0.08, 0.14))
    for k in range(5): v.crystal("Head", "Seam", V(-0.18 + k * 0.09, 0.56, 2.93 if k % 2 else 2.79), (0, 0.3, -1 if k % 2 else 1), 0.1, 0.03, sides=4)
    v.anchor("eyes", "Head", (0, 0.55, 3.08)); v.anchor("speech", "Head", (0, 0.0, 4.0))
    # chunky arms: clay segments, banded joints, three-fingered claws
    for s, A in ((-1, "ArmL"), (1, "ArmR")):
        sh, el, wr = V(s * 0.82, 0.0, 2.15), V(s * 1.5, 0.35, 1.6), V(s * 1.55, 0.85, 1.05)  # d2: daylight under the arms
        v.joint(A + "1", tuple(sh), "Body", "arm")
        v.cap(A + "1", "Clay", sh, el, 0.24, 0.2)
        v.torus(A + "1", "ClayDark", el, tuple((el - sh).normalized()), 0.2, 0.05)
        v.joint(A + "2", tuple(el), A + "1", "arm")
        v.cap(A + "2", "ClayLi", el, wr, 0.2, 0.22)
        for k in range(3): v.crystal(A + "2", "Claw", wr + V((k - 1) * 0.1, 0.1, -0.08), ((k - 1) * 0.4, 0.8, -1), 0.32, 0.06, sides=4)
        v.anchor("hand" + A[3:], A + "2", tuple(wr))
    for s, L in ((-1, "LegL"), (1, "LegR")):
        hip, foot = V(s * 0.38, 0.0, 0.8), V(s * 0.5, 0.15, 0.0)
        v.joint(L + "1", tuple(hip), "Body", "leg")
        v.cap(L + "1", "ClayDark", hip, foot + V(0, 0, 0.2), 0.24, 0.22)
        v.ell(L + "1", "Clay", tuple(foot + V(0, 0.18, 0.12)), (0.26, 0.36, 0.14))
        v.anchor("foot" + L[3:], L + "1", tuple(foot))
    P.ground(v)



# ---------------------------------------------------------------- ROOT WARDEN: the Camp 1 deep gate boss (13 studs, 0.17-stud voxels)
# a hunched slate-and-moss titan: a forward-pitched wedge chest laced with twisted petrified root cords, a heavy brow over
# turquoise slit eyes, a hinged moss-rock jaw, asymmetric turquoise crystal spires out of the spine, shoulders and crest,
# huge gorilla arms ending in root-bound boulder fists with crystal knuckles and glowing fissures, short pillar legs,
# and three dark sockets (left shoulder, right chest, solar plexus) where the amber knot hearts lock in
SCALE = {"RootWarden": 0.17, "KilnGolem": 0.17}


@char("RootWarden", soft_tops(P.palette(form=("Slate", "Moss"), Slate="#4c5668", SlateDark="#30384a", Moss="#5a8c4c", MossDark="#3a6a34", Bark="#3c2c24",
                              BarkHi="#5c4434", Crystal="#4ae0d8", CrystalHi="#c8fff8", Glow="#7afff0", Socket="#1a1418", Amber="#ffb040",
                              Teeth="#cfc6b4", Eye="#0a1418", Shine="#ffffff"), ("Slate", "SlateDark", "Moss")))
def warden(v):
    E = P.E
    v.joint("Body", (0, 0, 6.2))
    v.muscle("Body", "Slate", (0, 0.7, 7.6), (3.1, 2.2, 2.4), rot=E(-22, 0, 0))  # the wedge chest, pitched forward
    v.muscle("Body", "Slate", (0, -0.3, 5.3), (2.3, 1.9, 1.7))  # the hips
    for s in (-1, 1): v.muscle("Body", "Slate", (s * 2.5, 0.3, 8.6), (1.4, 1.4, 1.2))  # shoulder masses
    v.muscle("Body", "Moss", (0, -0.4, 9.0), (2.6, 1.8, 0.8))  # moss over the shoulders and upper back
    v.ell("Body", "SlateDark", (0, 2.6, 8.4), (1.5, 0.5, 0.45))  # d9: a dark contact shadow under the jaw
    for s in (-1, 1): v.muscle("Body", "Moss", (s * 2.6, 0.1, 9.55), (1.2, 1.1, 0.45))
    P.shade(v, "Slate", "Moss")
    # twisted petrified root cords across the chest and over the shoulders
    for s in (-1, 1):
        v.tube("Body", "Bark", [V(s * 3.0, 0.9, 9.2), V(s * 1.6, 2.4, 8.2), V(-s * 0.4, 2.7, 6.9), V(-s * 1.8, 2.0, 5.6)], [0.32, 0.36, 0.32, 0.26])
        v.tube("Body", "BarkHi", [V(s * 3.1, 0.7, 9.4), V(s * 2.6, -0.8, 9.5), V(s * 1.2, -2.0, 8.4)], [0.26, 0.3, 0.22])
    v.tube("Body", "Bark", [V(-2.2, -1.6, 7.5), V(0, -2.2, 6.8), V(2.2, -1.7, 6.0)], [0.3, 0.34, 0.28])
    for pts in ([(-1.6, 2.6, 8.4), (-1.1, 2.9, 7.6), (-1.5, 2.7, 6.8), (-1.0, 2.5, 6.0)], [(2.4, 2.0, 8.6), (2.0, 2.4, 7.9)], [(1.3, -2.0, 8.6), (0.8, -2.3, 7.8), (1.2, -2.1, 7.0)]):
        v.line("Body", "Glow", [V(*q) for q in pts], r=0.11)  # d6: glowing fissures in the slate
    for (x, y, z, r) in ((2.2, 1.6, 6.4, 0.7), (-2.4, -0.6, 6.6, 0.6), (0.6, -2.0, 5.4, 0.55)):
        v.ell("Body", "Moss", (x, y, z), (r, r, r * 0.6))  # moss patches on the slate
    # crystal spires: asymmetric clusters out of the spine and the left shoulder
    for (x, y, z, dx, dy, dz, L, w) in ((-0.6, -1.6, 9.2, -0.2, -0.6, 1, 3.4, 0.55), (0.5, -1.8, 8.6, 0.3, -0.7, 1, 2.6, 0.45), (-0.1, -2.1, 7.6, 0, -1, 0.6, 2.2, 0.4),
                                        (-2.9, 0.0, 9.8, -0.5, -0.2, 1, 2.8, 0.5), (-3.3, 0.5, 9.4, -1, 0.1, 0.8, 1.8, 0.35), (2.9, -0.4, 9.7, 0.3, -0.4, 1, 1.5, 0.3),
                                        (0.0, -2.0, 6.0, 0.2, -1, 0.3, 1.6, 0.35)):
        v.crystal("Body", "Crystal", V(x, y, z), (dx, dy, dz), L, w, sides=5)
        v.crystal("Body", "CrystalHi", V(x, y, z) + V(dx, dy, dz).normalized() * L * 0.35, (dx, dy, dz), L * 0.45, w * 0.35, sides=4)
    # the knot sockets: dark rings where the amber hearts lock in
    for key, c, n in (("Knot1", V(-2.7, 1.2, 9.1), (-0.4, 0.6, 0.6)), ("Knot2", V(1.5, 2.6, 7.7), (0.2, 1, 0.1)), ("Knot3", V(0, 2.25, 6.1), (0, 1, -0.1))):
        v.torus("Body", "Socket", c, n, 0.55, 0.16)
        v.ell("Body", "Socket", tuple(c), (0.45, 0.45, 0.45))
        v.ell("Body", "Amber", tuple(c + V(*n).normalized() * 0.2), (0.3, 0.3, 0.3))
        v.anchor(key, "Body", tuple(c))
    # the head: low and forward between the shoulders, a heavy brow, slit eyes, a crest of crystals
    v.joint("Head", (0, 2.2, 9.2), "Body", "head")
    v.muscle("Head", "Slate", (0, 3.70, 10.20), (1.7, 1.5, 1.35))  # d6: bigger, up and forward of the shoulders
    P.shade(v, "Slate", parts={"Head"})
    v.box("Head", "SlateDark", (0, 4.90, 10.95), (2.9, 0.62, 0.45), rot=E(-10, 0, 0))  # the brow ridge, pulled back off the eyes (d4: the face vanished from the town camera)
    v.muscle("Head", "Moss", (0, 3.40, 11.30), (1.35, 1.2, 0.42))
    for s in (-1, 1):
        v.carve(lambda x, y, z, s=s: abs(x - s * 0.7) < 0.5 and y > 5.0 and 10.2 < z < 10.7, part="Head")
        v.box("Head", "Slate", (s * 0.7, 5.02, 10.45), (1.04, 0.14, 0.58))  # d9: a lit stone socket, not a dark cavity
        v.box("Head", "Glow", (s * 0.7, 5.10, 10.45), (0.86, 0.12, 0.42))
        v.box("Head", "Eye", (s * 0.62, 5.16, 10.43), (0.22, 0.06, 0.22))  # d10: a dark pupil core in the glow
        v.box("Head", "SlateDark", (s * 0.75, 5.05, 10.77), (1.1, 0.4, 0.2), rot=P.E(0, s * -12, 0))  # an angled stone brow plane over each eye
        v.box("Head", "Crystal", (s * 0.7, 5.12, 10.29), (0.86, 0.12, 0.12))  # d8: a darker lower lid, a two-tone eye  # d6: big glowing eyes in carved sockets
        v.box("Head", "CrystalHi", (s * 0.7, 5.17, 10.49), (0.44, 0.06, 0.18))
    for k, (x, L) in enumerate(((-0.45, 1.0), (0.15, 1.3), (0.6, 0.8))):  # the forehead crest (d11: cut back so the face shows from above)
        v.crystal("Head", "Crystal", V(x, 3.00, 11.45), (x * 0.4, -0.6, 1), L * 1.15, 0.36, sides=5)
    v.anchor("eyes", "Head", (0, 4.85, 10.45)); v.anchor("speech", "Head", (0, 2.0, 13.5))
    # the jaw: a hinged moss-rock mandible with stone teeth
    v.joint("Jaw", (0, 3.60, 9.30), "Head", "head")
    v.ell("Jaw", "Slate", (0, 4.35, 9.10), (1.45, 1.15, 0.6))
    v.ell("Jaw", "Moss", (0, 4.25, 8.75), (1.15, 1.0, 0.25))
    v.ell("Jaw", "Socket", (0, 5.25, 9.60), (1.0, 0.14, 0.22))  # a dark open mouth line above the teeth
    for s in (-1, 1): v.crystal("Jaw", "Teeth", V(s * 0.85, 5.05, 9.35), (s * 0.25, 0.2, 1), 0.7, 0.2, sides=4)  # d8: two stone tusks at the corners (d7: a row of white teeth read as a derpy grin)
    v.box("Jaw", "SlateDark", (0, 5.25, 9.40), (1.5, 0.16, 0.14))  # a heavy lower lip under the dark mouth
    # arms: huge gorilla arms knuckling forward, root-bound forearms, boulder fists with crystal knuckles
    for s, A in ((-1, "ArmL"), (1, "ArmR")):
        sh, el, wr = (V(3.3, 0.4, 8.9), V(5.7, -0.4, 10.1), V(6.3, -0.7, 12.3)) if s > 0 else (V(-3.4, 0.8, 8.5), V(-6.4, 1.6, 6.8), V(-7.0, 3.2, 3.2))  # d6: the right crystal fist raised, the left planted forward
        v.joint(A, tuple(sh), "Body", "arm")
        v.cap(A, "Slate", sh, el, 1.15, 0.95)
        v.muscle(A, "Moss", tuple(sh + V(0, 0, 0.7)), (1.0, 1.0, 0.5))
        v.joint(A + "2", tuple(el), A, "arm")
        v.cap(A + "2", "Slate", el, wr, 0.95, 1.05)
        for t in (0.25, 0.55, 0.8): v.torus(A + "2", "Bark", el.lerp(wr, t), tuple((wr - el).normalized()), 1.0, 0.18)  # root bindings
        dirn = (wr - el).normalized()
        fist = wr + dirn * 1.0
        v.muscle(A + "2", "Slate", tuple(fist), (1.55, 1.5, 1.35))
        kd = dirn if s > 0 else V(0, 1, -0.5).normalized()  # the knuckle crystals point up the raised arm, forward on the planted one
        for k in range(4): v.crystal(A + "2", "Crystal", fist + V((k - 1.5) * 0.7, 0, 0) + kd * 1.1, V((k - 1.5) * (0.5 if s > 0 else 0.2), 0, 0) + kd, 1.25, 0.3, sides=5)  # crystal knuckles, splayed on the raised fist

        v.anchor("hand" + A[3:], A + "2", tuple(fist))
    # short pillar legs, wide feet
    for s, L in ((-1, "LegL"), (1, "LegR")):
        hip, foot = V(s * 1.7, -0.6, 4.6), V(s * 2.1, -0.2, 0.0)
        v.joint(L, tuple(hip), "Body", "leg")
        v.cap(L, "Slate", hip, foot + V(0, 0, 0.8), 1.2, 1.0)
        v.ell(L, "SlateDark", tuple(foot + V(0, 0.4, 0.5)), (1.25, 1.55, 0.6))
        v.ell(L, "Moss", tuple(hip + V(0, 0, 0.2)), (1.0, 0.9, 0.4))
        for z in (1.3, 2.4, 3.4): v.paint("SlateDark", lambda x, y, zz, z=z: abs(zz - z - 0.15 * math.sin(x * 3)) < 0.1, part=L, only={"Slate", "SlateHi", "SlateLo", "SlateCrease"})  # rock strata

        v.ell(L, "Moss", tuple(foot + V(s * 0.6, 0.3, 1.2)), (0.5, 0.5, 0.3))
        v.anchor("foot" + L[3:], L, tuple(foot + V(0, 0.4, 0.3)))
    P.ground(v)



# ---------------------------------------------------------------- KILN GOLEM: the Camp 2 Clay Caves boss (14 studs, 0.17-stud voxels)
# a barrel-chested furnace colossus: fired terracotta and smoked bronze, banded amphora-rim bronze collars, riveted iron boiler
# straps, cream glaze bands, magma seams, an open iron grille in the belly full of glowing coals, a kiln-dome head under a heavy
# clay visor with molten slit eyes, a hinged bronze chimney lid on top, colossal forge-hammer fists studded with rivets,
# and three vent sockets (Knot1..3) for the glowing kiln vents
@char("KilnGolem", P.palette(form=("Clay", "Bronze"), Clay="#bc5c36", ClayDark="#7e3820", Cream="#f2e2c2", Bronze="#86663a", BronzeDark="#4a3620",
                             Patina="#5cae96", PatinaHi="#8ad8c0", Iron="#4a4650", IronDark="#2c2a32", Rivet="#e0b860", Coal="#ff7a20", CoalHot="#ffd860",
                             Seam="#ffb040", Socket="#1a1210", Soot="#3e3438", SootLo="#2a2226", Smoke="#9a929a", Smoke2="#c2bcc2", Eye="#120806", Shine="#ffffff"))
def golem(v):
    # g7 (g6 graders: a monochrome orange blob, a small face, a tiny chimney): a beehive-kiln head with an arched furnace mouth,
    # a tall chimney trailing smoke, two back exhaust stacks, verdigris bronze against the terracotta, soot down the back,
    # cream glaze drips; one fist raised, the other hanging forward, a wide stance
    E = P.E
    v.joint("Body", (0, 0, 6.5))
    v.muscle("Body", "Clay", (0, 0.2, 7.4), (3.2, 3.0, 2.9))  # the barrel chest (g9: deeper, a round pot from the side)
    v.muscle("Body", "Clay", (0, 0.0, 5.0), (2.6, 2.5, 1.6))  # the belly and hips
    for s in (-1, 1): v.muscle("Body", "Bronze", (s * 2.9, 0.1, 9.0), (1.5, 1.45, 1.15))  # bronze shoulder caps
    P.shade(v, "Clay", "Bronze")
    for z0, z1, col in ((9.25, 9.55, "Bronze"), (8.05, 8.4, "Bronze"), (5.85, 6.15, "Bronze"), (7.1, 7.3, "Cream")):  # banded collars painted on the barrel
        v.paint(col, lambda x, y, z, z0=z0, z1=z1: z0 <= z <= z1, part="Body", only={"Clay", "ClayHi", "ClayLo", "ClayCrease"})
    v.paint("Patina", lambda x, y, z: z > 9.55 or (abs(x) > 3.6 and z > 9.2), part="Body", only={"Bronze", "BronzeHi", "BronzeLo", "BronzeCrease"})  # verdigris on the caps' tops
    v.paint("Soot", lambda x, y, z: y < -0.9 and z > 8.6 - 0.6 * abs(x) / 3, part="Body", only={"Clay", "ClayHi", "ClayLo", "ClayCrease", "Bronze", "Cream"})  # soot down the back from the stacks
    v.paint("SootLo", lambda x, y, z: y < -1.6 and z > 9.3, part="Body", only={"Soot"})
    for s in (-1, 1):  # riveted iron boiler straps over the shoulders
        v.tube("Body", "Iron", [V(s * 1.4, 2.65, 9.0), V(s * 1.6, 3.10, 7.4), V(s * 1.3, 2.85, 5.6)], [0.22, 0.24, 0.22])
        for z in (8.6, 7.8, 7.0, 6.2): v.ell("Body", "Rivet", (s * 1.55, 3.27 if z > 6.5 else 3.0, z), (0.12, 0.08, 0.12))
    # the furnace: an open iron grille across the lower chest, coals glowing behind the bars
    v.ell("Body", "IronDark", (0, 2.65, 6.4), (1.5, 0.5, 0.9))
    v.ell("Body", "Coal", (0, 2.80, 6.35), (1.25, 0.35, 0.72))
    for k in range(6): v.ell("Body", "CoalHot", (-1.0 + k * 0.4, 3.0, 6.1 + (k % 2) * 0.35), (0.16, 0.1, 0.14))
    for k in range(5): v.box("Body", "Iron", (-0.96 + k * 0.48, 3.20, 6.4), (0.14, 0.14, 1.7))  # the bars
    v.box("Body", "Iron", (0, 3.20, 7.2), (2.4, 0.16, 0.16)); v.box("Body", "Iron", (0, 3.20, 5.6), (2.4, 0.16, 0.16))
    # two back exhaust stacks with glowing mouths and smoke
    for s in (-1, 1):
        b0, b1 = V(s * 1.5, -1.9, 8.4), V(s * 1.95, -2.35, 11.4)
        v.cap("Body", "Bronze", b0, b1, 0.5, 0.42)
        for t in (0.35, 0.75): v.torus("Body", "Patina", b0.lerp(b1, t), tuple((b1 - b0).normalized()), 0.5, 0.12)
        v.torus("Body", "BronzeDark", b1, tuple((b1 - b0).normalized()), 0.46, 0.13)
        v.ell("Body", "Coal", b1, (0.3, 0.3, 0.1))
        v.ell("Body", "Smoke", b1 + V(s * 0.25, -0.35, 0.7), (0.45, 0.45, 0.38))
        v.ell("Body", "Smoke2", b1 + V(s * 0.55, -0.75, 1.3), (0.32, 0.32, 0.28))
    # magma seams in the clay
    for pts in ([(-2.4, 1.6, 8.6), (-2.0, 1.9, 7.9), (-2.3, 1.7, 7.4)], [(2.2, 1.7, 8.8), (2.5, 1.4, 8.0)], [(1.8, -1.9, 7.5), (2.2, -1.5, 6.8), (1.9, -1.8, 6.2)]):
        v.line("Body", "Seam", pts, r=0.12)
    for key, c, n in (("Knot1", V(-2.0, 2.3, 8.9), (-0.4, 0.8, 0.4)), ("Knot2", V(2.1, 2.45, 7.4), (0.4, 1, 0.1)), ("Knot3", V(0, -2.8, 7.0), (0, -1, 0.2))):
        v.torus("Body", "Patina", c, n, 0.6, 0.18)
        v.ell("Body", "Socket", tuple(c), (0.48, 0.48, 0.48))
        v.ell("Body", "Seam", tuple(c + V(*n).normalized() * 0.2), (0.3, 0.3, 0.3))
        v.anchor(key, "Body", tuple(c))
    # the head: a big beehive kiln dome, molten slit eyes under a heavy brow, an arched furnace mouth glowing inside
    v.joint("Head", (0, 0.4, 9.6), "Body", "head")
    v.muscle("Head", "Clay", (0, 0.8, 11.0), (2.35, 2.1, 1.85))  # g9: a bigger head
    P.shade(v, "Clay", parts={"Head"})
    for z in (10.0, 11.0, 11.9): v.paint("ClayDark", lambda x, y, zz, z=z: abs(zz - z) < 0.09, part="Head", only={"Clay", "ClayHi", "ClayLo", "ClayCrease"})  # brick courses
    v.paint("Soot", lambda x, y, z: z > 12.0, part="Head", only={"Clay", "ClayHi", "ClayLo", "ClayCrease", "ClayDark"})  # soot round the crown
    v.box("Head", "ClayDark", (0, 2.35, 12.25), (3.2, 0.45, 0.32), rot=E(-8, 0, 0))  # the brow, higher and set back (g7: it hid the eyes)
    for s in (-1, 1):
        v.carve(lambda x, y, z, s=s: abs(x - s * 0.9) < 0.6 and y > 2.45 and 11.15 < z < 11.95, part="Head")
        v.box("Head", "Eye", (s * 0.9, 2.42, 11.55), (1.2, 0.12, 0.8))
        v.box("Head", "Coal", (s * 0.9, 2.5, 11.55), (1.04, 0.1, 0.64))  # g9: big glowing peepholes at the face plane
        v.box("Head", "CoalHot", (s * 0.9, 2.57, 11.57), (0.66, 0.08, 0.36))
        v.box("Head", "Shine", (s * 0.9 - s * 0.28, 2.62, 11.72), (0.17, 0.05, 0.14))
    def mouth(x, y, z):  # an arched furnace mouth
        return y > 2.1 and abs(x) < 1.0 and 10.0 < z < 10.7 + 0.35 * max(0.0, 1 - (x / 1.0) ** 2)
    v.carve(mouth, part="Head")
    v.ell("Head", "Socket", (0, 2.15, 10.45), (1.0, 0.2, 0.6))
    v.ell("Head", "Coal", (0, 2.25, 10.35), (0.85, 0.14, 0.45))
    v.ell("Head", "CoalHot", (0, 2.35, 10.25), (0.48, 0.1, 0.22))
    for k in (-1, 0, 1): v.box("Head", "Iron", (k * 0.48, 2.7, 10.45), (0.14, 0.16, 0.9))  # grate teeth
    v.box("Head", "Iron", (0, 2.7, 10.0), (2.1, 0.18, 0.16))
    v.torus("Head", "Patina", (0, 0.8, 12.5), (0, 0, 1), 1.25, 0.18)
    v.anchor("eyes", "Head", (0, 2.6, 11.55)); v.anchor("speech", "Head", (0, 0.4, 16.0))
    # the chimney lid: a tall hinged bronze stack on the crown, its mouth glowing, smoke trailing back
    v.joint("Lid", (0, 0.3, 12.6), "Head", "head")
    v.cap("Lid", "Bronze", V(0, 0.4, 12.5), V(0, 0.2, 14.1), 0.82, 0.62)
    for z in (12.9, 13.6): v.torus("Lid", "Patina", V(0, 0.32, z), (0, 0, 1), 0.74 - (z - 12.9) * 0.12, 0.13)
    v.torus("Lid", "BronzeDark", V(0, 0.2, 14.1), (0, 0, 1), 0.68, 0.17)
    v.ell("Lid", "Coal", (0, 0.2, 14.18), (0.5, 0.5, 0.1))
    for (dx, dy, dz, r, col) in ((0.1, -0.2, 14.85, 0.78, "Smoke"), (0.7, -0.9, 15.75, 0.62, "Smoke2")):
        v.ell("Lid", col, (dx, dy, dz), (r, r, r * 0.85))
    # arms: the right fist raised (a slam wind-up), the left hanging forward; bronze bands with verdigris, gauntlet fists
    arms = {"ArmR": (V(3.4, 0.2, 8.6), V(5.5, -0.4, 9.5), V(6.3, -0.6, 11.7)), "ArmL": (V(-3.4, 0.2, 8.6), V(-5.4, 0.6, 6.9), V(-6.0, 1.1, 4.7))}  # g8: the off arm swings a molten crucible out at its side (g7: the resting arm clumped with the torso)
    for A, (sh, el, wr) in arms.items():
        s = 1 if A == "ArmR" else -1
        v.joint(A, tuple(sh), "Body", "arm")
        v.cap(A, "Clay", sh, el, 1.15, 1.0)
        v.joint(A + "2", tuple(el), A, "arm")
        v.cap(A + "2", "Clay", el, wr, 1.0, 1.1)
        dirn = (wr - el).normalized()
        for t, col in ((0.2, "Bronze"), (0.6, "Patina")): v.torus(A + "2", col, el.lerp(wr, t), tuple(dirn), 1.08, 0.2)
        fist = wr + dirn * 1.05
        v.muscle(A + "2", "Bronze", tuple(fist), (1.3, 1.2, 1.1))
        fw = V(0, 1, 0) - dirn * dirn.y
        fw = fw.normalized() if fw.length > 0.1 else V(0, 1, 0)
        for k in range(4): v.cap(A + "2", "BronzeDark", fist + V((k - 1.5) * 0.55, 0, 0) + fw * 0.9 + dirn * 0.4, fist + V((k - 1.5) * 0.6, 0, 0) + fw * 1.35 - dirn * 0.5, 0.32, 0.28)  # curled fingers
        for cx in (-0.8, 0, 0.8):
            for cz in (-0.5, 0.5): v.ell(A + "2", "Rivet", tuple(fist + V(cx, 0, 0) + fw * 1.15 + dirn * cz), (0.18, 0.1, 0.18))
        v.line(A + "2", "Seam", [fist + V(s * 1.25, 0, 0) + fw * 0.5 + dirn * 0.6, fist + V(s * 1.3, 0, 0), fist + V(s * 1.25, 0, 0) + fw * 0.4 - dirn * 0.6], r=0.12)
        v.anchor("hand" + A[3:], A + "2", tuple(fist))
        if A == "ArmL":  # an iron crucible of molten glaze hanging from the fist by a bail
            cb = fist + V(-0.15, 0.2, -2.3)
            v.tube(A + "2", "Iron", [cb + V(1.3, 0, 0.6), fist + V(0.7, 0, -0.4), fist + V(-0.7, 0, -0.4), cb + V(-1.3, 0, 0.6)], [0.14, 0.14, 0.14, 0.14])
            v.cap(A + "2", "IronDark", cb + V(0, 0, 0.65), cb + V(0, 0, -0.7), 1.3, 0.9)
            v.torus(A + "2", "Iron", cb + V(0, 0, 0.62), (0, 0, 1), 1.3, 0.15)
            v.torus(A + "2", "Patina", cb + V(0, 0, 0.0), (0, 0, 1), 1.18, 0.12)
            v.ell(A + "2", "Coal", tuple(cb + V(0, 0, 0.66)), (1.15, 1.15, 0.12))
            v.ell(A + "2", "CoalHot", tuple(cb + V(0.15, 0.1, 0.74)), (0.6, 0.6, 0.07))
            v.cap(A + "2", "Iron", cb + V(-0.75, 0.55, 0.55), cb + V(-1.2, 0.95, 0.75), 0.22, 0.12)  # the pour lip
            v.cap(A + "2", "Seam", cb + V(-1.2, 0.95, 0.65), cb + V(-1.25, 1.0, -0.2), 0.1, 0.06)  # a molten drip off the lip
            v.anchor("crucible", A + "2", tuple(cb + V(0, 0, 0.66)))
    for s, L in ((-1, "LegL"), (1, "LegR")):
        hip, foot = V(s * 1.9, -0.2, 4.4), V(s * 2.7, 0.2, 0.0)  # a wider stance, daylight between the legs
        v.joint(L, tuple(hip), "Body", "leg")
        v.cap(L, "Clay", hip, foot + V(0, 0, 0.9), 1.25, 1.1)
        v.torus(L, "Patina", hip.lerp(foot, 0.5), (0, 0, 1), 1.22, 0.2)
        v.torus(L, "Bronze", hip.lerp(foot, 0.7), (0, 0, 1), 1.16, 0.16)
        v.ell(L, "ClayDark", tuple(foot + V(0, 0.4, 0.5)), (1.3, 1.6, 0.6))
        for k in (-1, 0, 1): v.ell(L, "BronzeDark", tuple(foot + V(k * 0.6, 1.7, 0.35)), (0.32, 0.3, 0.3))  # toe caps
        v.anchor("foot" + L[3:], L, tuple(foot + V(0, 0.4, 0.3)))
    P.ground(v)

HERE_CHARS = os.path.dirname(os.path.abspath(__file__))


if __name__ == "__main__":
    rp = os.path.join(HERE_CHARS, "rigs_npc.json")  # NPC rigs stay out of the pets' rigs.json (make_rig_lua.py would list them as pets)
    db = json.load(open(rp)) if os.path.exists(rp) else {}
    for name, (pal, fn) in D.items():
        if ONLY and name not in ONLY: continue
        v = X.Vox(name, pal, s=SCALE.get(name, 0.1))  # the bosses build in chunkier 0.17-stud voxels (v17 brief)
        fn(v)
        despeckle(v)
        c = v.build()
        d = K.export(c, OUT)
        d["cells"] = len(v.cells); d["proportions"] = P.proportions(v); d["npc"] = True
        db[name] = d
        print(f"{name}: {len(v.cells)} cells, {d['tris']} triangles, {d['parts']} parts, {d['objects']} objects, size {d['size']}", flush=True)
    json.dump(db, open(rp, "w"), indent=1)
