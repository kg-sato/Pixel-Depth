"""The hatch grotto and egg as baked voxel meshes (2026-11-17 night; Gemini n17_hatch: the nest read as plain wood, the cave as
flat slabs). `python design3d/hatch/grotto.py` writes design3d/hatch/hatch.json in the pets' format, built and baked by
design3d/pets/build_pets.py (VOXEL_JSON, VOXEL_BAKE, VOXEL_KEEP=Crystal,Glow keeps the glowing parts unbaked for the game to
tint). Two models:
  HatchGrotto (0.5-stud voxels): a rock bowl with walls that curl in overhead and a gap in the roof on the far side, a stepped
    pedestal, a woven nest of twigs and moss, crystal clusters (Crystal1..5) and glow mushrooms (Cap1..4) as their own parts
  HatchEgg (0.12-stud voxels): a speckled egg, narrower at the top, with a band of darker speckles
Coordinates: x across, y up, z away from the camera (the camera stands at -z); the nest sits at the origin's x/z."""
import json, math, os, random, sys
here = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(here, "..", "pets"))
from pets import Pet

rnd = random.Random(11)


def grotto():
    p = Pet("HatchGrotto")
    R = 26
    for x in range(-R, R + 1):
        for z in range(-R, R + 1):
            r = math.hypot(x, z)
            if r > R: continue
            # the floor: a bowl, a little uneven, rising toward the walls
            h = int(max(0, (r - 18)) * 0.6 + rnd.random() * 0.8)
            for y in range(-1, h + 1):
                p.put(x, y, z, "Body", "Main" if (x * 3 + z * 7) % 5 else "Dark")
            # the walls: a ring curling in overhead; the camera side (-z) open low down; a gap in the roof far side
            if r > 19:
                a = math.atan2(z, x)
                camside = -z / max(r, 1) > 0.55
                top = 30
                for y in range(0, top):
                    inward = (y / top) ** 2 * 11
                    if r < 26 - inward - 2.5 or r > 26 - inward: continue
                    if camside and y < 16: continue
                    if y > 22 and z > 4 and abs(x) < 9: continue  # the light gap
                    role = "Main" if (y // 3 + int(a * 6)) % 4 else "Dark"
                    if y > 24: role = "Dark"
                    p.put(x, y, z, "Body", role)
    # roof cap over the rest
    # the pedestal: three stepped rock tiers, and the nest on top
    for i, (rr, y0) in enumerate(((4.6, 0), (3.8, 1), (3.0, 2))):
        for x in range(-5, 6):
            for z in range(-5, 6):
                if math.hypot(x, z) <= rr:
                    p.put(x, y0 + 1, z, "Pedestal", "Light" if i == 2 else "Main")
    for a in range(0, 360, 12):  # the nest: two twisted rings of twigs with moss tufts
        t = math.radians(a)
        for ring, (rr, y) in enumerate(((3.2, 4), (3.6, 5))):
            x, z = round(math.cos(t + ring * 0.2) * rr), round(math.sin(t + ring * 0.2) * rr)
            role = "Moss" if (a // 12 + ring) % 4 == 0 else ("Twig" if (a // 12) % 2 else "TwigDark")
            p.put(x, y, z, "Nest", role)
            if role == "Moss": p.put(x, y + 1, z, "Nest", "Moss")
    for x in range(-2, 3):
        for z in range(-2, 3):
            if math.hypot(x, z) <= 2.6: p.put(x, 4, z, "Nest", "TwigDark")
    # crystal clusters against the walls: columns of voxels leaning outward
    spots = [(-17, 10), (18, 7), (8, 19), (-10, 19), (-19, -4)]
    for i, (cx, cz) in enumerate(spots):
        for k in range(4):
            lx, lz = cx + rnd.randint(-2, 2), cz + rnd.randint(-2, 2)
            hgt = rnd.randint(6, 12)
            dx, dz = (1 if cx > 0 else -1) * 0.12, (1 if cz > 0 else -1) * 0.08
            base_y = int(max(0, (math.hypot(lx, lz) - 18)) * 0.6) + 1
            for y in range(hgt):
                w = 1 if y < hgt - 2 else 0
                for ox in range(-w, w + 1):
                    for oz in range(-w, w + 1):
                        if abs(ox) + abs(oz) <= w:
                            p.put(round(lx + dx * y) + ox, base_y + y, round(lz + dz * y) + oz, f"Crystal{i + 1}", "Crystal")
    # glow mushrooms: a stem and a domed cap
    for i, (mx, mz, s) in enumerate(((-12, 3, 2), (-10, 6, 1), (13, 15, 2), (11, 1, 1))):
        by = int(max(0, (math.hypot(mx, mz) - 18)) * 0.6) + 1
        for y in range(by, by + 2 + s):
            p.put(mx, y, mz, "Body", "Stem")
        cy = by + 2 + s
        for x in range(-s - 1, s + 2):
            for z in range(-s - 1, s + 2):
                if x * x + z * z <= (s + 1) ** 2: p.put(mx + x, cy, mz + z, f"Cap{i + 1}", "Glow")
                if x * x + z * z <= s * s: p.put(mx + x, cy + 1, mz + z, f"Cap{i + 1}", "Glow")
    d = p.data()
    d["vox"] = 0.5
    d["palette"] = {"Main": "#46304f", "Dark": "#2e1f38", "Light": "#7a6088", "Twig": "#8a6044", "TwigDark": "#5e3e2a", "Moss": "#6e9a5e", "Stem": "#d8c8e6", "Crystal": "#50e6ff", "Glow": "#ff50be"}
    d["pivots"] = {}
    return d


def egg():
    p = Pet("HatchEgg")
    for y in range(0, 24):
        yy = (y + 0.5) / 24 * 2 - 0.92  # -0.92 .. 1.08
        rx = 9.2 * math.sqrt(max(0, 1 - (yy / (1.08 if yy > 0 else 0.92)) ** 2)) * (0.92 if yy > 0 else 1.0)
        for x in range(-10, 11):
            for z in range(-10, 11):
                r = math.hypot(x, z)
                if r <= rx and r > rx - 2.2:
                    speck = (x * 7 + y * 3 + z * 5) % 11 == 0
                    # a dashed rune band round the belly on the outer layer: its own part, kept unbaked, that the game lights in the rarity colour (Gemini m13: the egg read as a plain rock)
                    if 9 <= y <= 10 and r > rx - 1.2 and int((math.atan2(z, x) + math.pi) / (2 * math.pi) * 16) % 4 != 3:
                        p.put(x, y, z, "Band", "Glow"); continue
                    p.put(x, y, z, "Body", "Speck" if speck else ("Top" if y > 15 else "Main"))
    d = p.data()
    d["vox"] = 0.12
    d["palette"] = {"Main": "#f8ecd6", "Top": "#efe4f4", "Speck": "#b096c4", "Glow": "#d8c0e8"}
    d["pivots"] = {}
    return d


if __name__ == "__main__":
    out = [grotto(), egg()]
    for d in out: print(d["name"], sum(len(v) for v in d["parts"].values()), "voxels", sorted(d["parts"]))
    json.dump(out, open(os.path.join(here, "hatch.json"), "w"), separators=(",", ":"))
