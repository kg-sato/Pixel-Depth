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


def char(name, pal):
    def deco(fn): D[name] = (pal, fn); return fn
    return deco


# ---------------------------------------------------------------- BOLT: the raccoon master smith (the Forge)
@char("Bolt", P.palette(form=("Fur", "Shirt", "Apron"), Fur="#8d8a9c", FurDark="#4a4656", Mask="#25212c", White="#eeedf3", Shirt="#3a4790",
                        Apron="#e6cb92", Strap="#8a5a34", Iron="#5c5e6c", Brass="#d9a843", Pink="#b04a52", Blush="#e88a9a", Glow="#ff9a36", Nose="#18131c",
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
        v.box("Body", "Iron", (s * 0.62, 1.0, 1.8), (0.16, 0.1, 0.55))  # tongs in it
    v.box("Body", "Strap", (0, 0.05, 1.98), (1.7, 1.38, 0.16))  # the belt
    for s in (-1, 1):  # round 8: a crossed tool harness on the back, and a hammer loop pouch at the belt
        v.curve("Body", "Strap", [(s * 0.62, -0.62, 3.65), (s * 0.2, -0.86, 3.0), (-s * 0.3, -0.84, 2.45), (-s * 0.6, -0.7, 2.05)], [0.08, 0.08, 0.08, 0.08])
    v.box("Body", "Iron", (0, -0.9, 2.85), (0.22, 0.1, 0.22))
    v.box("Body", "ApronLo", (0.55, -0.78, 1.82), (0.42, 0.2, 0.4))
    v.box("Body", "Brass", (0.55, -0.9, 1.92), (0.12, 0.06, 0.1))
    v.box("Body", "Brass", (0, 0.72, 1.98), (0.26, 0.08, 0.2))
    v.anchor("chest", "Body", (0, 0.8, 3.0))
    # the head: a big raccoon head, grey fur, a dark bandit mask round amber eyes, white cheek tufts and muzzle, notched ears
    v.joint("Head", (0, 0.1, 3.85), "Body", "head")
    v.muscle("Head", "Fur", (0, 0.05, 4.65), (0.98, 0.86, 0.82))
    v.muscle("Head", "Fur", (0, 0.35, 4.45), (0.8, 0.72, 0.62))
    P.shade(v, "Fur", parts={"Head"})
    for s in (-1, 1):
        v.ell("Head", "White", (s * 0.62, 0.55, 4.3), (0.42, 0.34, 0.32))  # cheek tufts
        for k in range(3): v.crystal("Head", "White", V(s * (0.8 + 0.08 * k), 0.45 - 0.12 * k, 4.18 + 0.12 * k), (s * 1, -0.2, -0.3), 0.32, 0.12, sides=4)
        v.ell("Head", "Mask", (s * 0.4, 0.78, 4.78), (0.36, 0.2, 0.24), rot=E(0, 0, s * -14))  # the mask band over each eye
        v.ell("Head", "Edge", (s * 0.37, 0.9, 4.8), (0.26, 0.06, 0.24))  # round 8: a pale rim so the eye reads against the mask
        v.eye("Head", (s * 0.37, 0.92, 4.8), (s * 0.35, 1, 0.12), w=0.34, h=0.32, iris="Iris")  # round 2: bigger, so the face reads from the town camera
        v.ell("Head", "Blush", (s * 0.62, 0.86, 4.42), (0.13, 0.05, 0.08))  # blush
        # notched ears with dark backs and pale insides
        v.ell("Head", "FurDark", (s * 0.6, -0.05, 5.5), (0.3, 0.16, 0.36), rot=E(0, s * -18, 0))
        v.ell("Head", "White", (s * 0.6, 0.06, 5.48), (0.18, 0.06, 0.24), rot=E(0, s * -18, 0))
    v.box("Head", "Mask", (0, 0.86, 4.8), (0.4, 0.12, 0.16))  # the mask's bridge
    v.ell("Head", "FurHi", (0, 0.72, 5.0), (0.62, 0.22, 0.14))  # round 6: a brow ridge one voxel proud over the mask
    v.ell("Head", "White", (0, 0.95, 4.38), (0.42, 0.38, 0.3))  # the muzzle
    v.ell("Head", "Nose", (0, 1.3, 4.5), (0.15, 0.1, 0.11))
    v.box("Head", "FurDark", (0, 1.2, 4.2), (0.24, 0.05, 0.05))  # the mouth line
    v.box("Head", "FurDark", (0, 0.4, 5.2), (0.2, 0.5, 0.2))  # a dark stripe up the brow
    for k in range(5): v.crystal("Body", "White", V(-0.3 + 0.15 * k, 0.55, 3.72), (0, 0.4, 1), 0.22, 0.08, sides=4)  # chest fur at the collar
    # the pink headband with brass smith goggles pushed up on it
    v.torus("Head", "Pink", (0, 0.02, 5.08), (0, 0, 1), 0.86, 0.09)
    for s in (-1, 1):
        v.torus("Head", "Brass", (s * 0.27, 0.78, 5.22), (0, 0.85, 0.5), 0.2, 0.06)
        v.ell("Head", "Crystal", (s * 0.27, 0.82, 5.24), (0.13, 0.04, 0.13))
    v.box("Head", "Brass", (0, 0.84, 5.22), (0.18, 0.06, 0.06))
    v.anchor("eyes", "Head", (0, 0.95, 4.8)); v.anchor("speech", "Head", (0, 0.0, 5.9))
    # arms: indigo sleeves rolled to the elbow (a cream cuff), grey furred forearms, dark paws; the right paw holds a forge hammer
    for s, A in ((-1, "ArmL"), (1, "ArmR")):
        sh, el, wr = V(s * 1.05, 0.05, 3.45), (V(s * 1.9, 0.1, 3.05) if s > 0 else V(s * 1.5, 0.25, 2.7)), (V(s * 2.45, 0.2, 3.65) if s > 0 else V(s * 1.75, 0.6, 2.05))  # round 3: arms clear of the body; the right one raises the hammer
        v.joint(A + "1", tuple(sh), "Body", "arm")
        v.cap(A + "1", "Shirt", sh, el, 0.42, 0.35)  # round 2: heavier smith's arms
        v.torus(A + "1", "Apron", el + (sh - el) * 0.12, (sh - el).normalized(), 0.31, 0.07)
        P.shade(v, "Shirt", parts={A + "1"})
        v.joint(A + "2", tuple(el), A + "1", "arm")
        v.cap(A + "2", "Fur", el, wr, 0.33, 0.27)
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
    v.box("ArmR2", "Iron", hand + V(0.45, 0.0, 1.55), (1.0, 0.5, 0.5), rot=up)
    v.box("ArmR2", "IronLo", hand + V(0.45, 0.0, 1.55), (1.08, 0.38, 0.38), rot=up)
    v.box("ArmR2", "Glow", hand + V(1.0, 0.0, 1.38), (0.1, 0.42, 0.42), rot=up)  # the glowing striking face
    v.box("ArmR2", "Ember", hand + V(1.04, 0.0, 1.37), (0.06, 0.28, 0.28), rot=up)
    v.box("ArmR2", "Brass", hand + V(0.33, 0.0, 1.22), (0.28, 0.28, 0.14), rot=up)
    v.box("ArmR2", "Brass", hand + V(0.0, 0.0, -0.1), (0.24, 0.24, 0.16), rot=up)  # the pommel
    v.anchor("hammer", "ArmR2", hand + V(1.05, 0.0, 1.4))
    # stout legs in dark trousers, big paws
    for s, L in ((-1, "LegL"), (1, "LegR")):
        hip, knee, foot = V(s * 0.45, 0.0, 1.62), V(s * 0.5, 0.28, 0.82), V(s * 0.5, 0.14, 0.0)  # round 8: a bent knee
        v.joint(L + "1", tuple(hip), "Body", "leg")
        v.cap(L + "1", "FurDark", hip, knee, 0.38, 0.32)
        v.joint(L + "2", tuple(knee), L + "1", "leg")
        v.cap(L + "2", "FurDark", knee, foot + V(0, 0, 0.2), 0.3, 0.22)  # tapers to the ankle
        v.ell(L + "2", "Mask", foot + V(0, 0.18, 0.14), (0.34, 0.42, 0.16))
        for k in (-1, 0, 1): v.crystal(L + "2", "Claw", foot + V(k * 0.12, 0.55, 0.08), (0, 1, -0.2), 0.12, 0.05, sides=4)
        v.anchor("foot" + L[3:], L + "2", foot + V(0, 0.2, 0.1))
    # the banded tail: two bones, thick and curled up behind, dark rings on grey
    tp = [V(-0.3, -0.6, 1.75), V(-1.2, -1.2, 1.45), V(-2.3, -1.15, 1.7), V(-3.1, -0.95, 2.4), V(-3.3, -0.85, 3.2)]  # round 8: the tip a little further out and back; round 7: flared out to the side so it reads from the front (round 6 hid it behind the body)  # round 5: farther out and back, clear of the leg (Gemini: the tail clumped into the hip in the blackout)
    for i, (a, b2, nm) in enumerate(((0, 2, "Tail1"), (2, 4, "Tail2"))):
        v.joint(nm, tuple(tp[a]), "Body" if i == 0 else "Tail1", "tail")
        v.tube(nm, "Fur", tp[a:b2 + 1], [0.42, 0.46, 0.44][:b2 - a + 1] if i == 0 else [0.44, 0.38, 0.24])
    for k in range(5):
        t = (k + 0.5) / 5
        seg = int(t * 4); u = t * 4 - seg
        c = tp[seg].lerp(tp[seg + 1], u); d = (tp[seg + 1] - tp[seg]).normalized()
        v.torus("Tail1" if seg < 2 else "Tail2", "Mask", c, d, 0.42 - 0.05 * k, 0.1)
    v.anchor("tail", "Tail2", tp[4])
    P.ground(v)


HERE_CHARS = os.path.dirname(os.path.abspath(__file__))


if __name__ == "__main__":
    rp = os.path.join(HERE_CHARS, "rigs_npc.json")  # NPC rigs stay out of the pets' rigs.json (make_rig_lua.py would list them as pets)
    db = json.load(open(rp)) if os.path.exists(rp) else {}
    for name, (pal, fn) in D.items():
        if ONLY and name not in ONLY: continue
        v = X.Vox(name, pal, s=0.1)
        fn(v)
        c = v.build()
        d = K.export(c, OUT)
        d["cells"] = len(v.cells); d["proportions"] = P.proportions(v); d["npc"] = True
        db[name] = d
        print(f"{name}: {len(v.cells)} cells, {d['tris']} triangles, {d['parts']} parts, {d['objects']} objects, size {d['size']}", flush=True)
    json.dump(db, open(rp, "w"), indent=1)
