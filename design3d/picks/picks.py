"""Voxel pickaxes for Pixel Depth (2026-11-17; the owner: "the pickaxe models are too thin ... real pickaxes have this hammer
like shape, ours is just a stick ... remake them"). One generator builds all 29 forge tiers (Config.PICKS) in the game's voxel
look; `python design3d/picks/picks.py` writes design3d/picks/picks.json (same format as the pets, so design3d/pets/build_pets.py
builds the GLBs and design3d/picks/make_lua.py writes src/PickVoxelsData.luau).
Anatomy (a real pick-mattock, chunky): a 3x3-voxel handle with a pommel, leather grip wraps and metal bands; at the top a
collar block (the eye) that the head passes through; one side a heavy pick arm that tapers and curves down to a point, the
other side a hammer face, an adze blade or a second pick (VARIANT). Top edge light, underside dark, the edges bright, one
accent (a gem, glow cracks or runes) and a tier mark on the collar (star, heart, moon, sun, wings ...).
Axes: x across the head, y up the handle (the foot at 0), z through the head (its depth). Voxel = 0.12 studs."""
import json, math, os, sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "pets"))
from pets import Pet  # the voxel helper (box, put, paint, data)

VOX = 0.12
HL = 28  # handle length in voxels (3.36 studs)
HY = HL + 2  # the head's centre line height


def tier(name, head, dark, light, handle, grip, accent, band="#8a7f9e", variant="pickhammer", mark=None, glow=None, size=1.0):
    return dict(name=name, head=head, dark=dark, light=light, handle=handle, grip=grip, accent=accent, band=band, variant=variant, mark=mark, glow=glow, size=size)


TIERS = [
    tier("WoodPickaxe", "#c89a62", "#8e6440", "#e6c18c", "#a8744a", "#6e4a34", "#f2d49a", band="#6e4a34", variant="double"),
    tier("StonePickaxe", "#9a96a8", "#6a6678", "#c8c4d6", "#a8744a", "#6e4a34", "#d8d4e6", band="#6e4a34", variant="double"),
    tier("AshcoalPickaxe", "#4a4450", "#2c2832", "#6e6676", "#7a5a44", "#3e2c26", "#ff8a3c", glow="cracks"),
    tier("CopperPickaxe", "#d27c46", "#9a5230", "#f2a874", "#7a5a44", "#3e2c26", "#5ee0c0", band="#5ee0c0", mark="gem"),
    tier("BogIronPickaxe", "#5c6258", "#3a3e38", "#8a9282", "#5e4a3a", "#3a2e26", "#9ccf6a", variant="double", glow="cracks"),
    tier("RootheartPickaxe", "#6e4a34", "#4a3022", "#9a6c4a", "#5a3e2a", "#3a6a3a", "#7cff9c", mark="gem", glow="veins"),
    tier("MossbackPickaxe", "#7e8a74", "#55604e", "#a8b89a", "#6e5a44", "#3e4a32", "#8ad46a", variant="double", mark="moss"),
    tier("KilnPickaxe", "#d0784e", "#9a4e32", "#f0a47a", "#6e4a34", "#4a2e22", "#ffcf6a", glow="cracks"),
    tier("RuneTinPickaxe", "#b8bcc8", "#7e8294", "#e2e6f0", "#5a4a5e", "#3a2e40", "#6af0ff", variant="double", glow="runes"),
    tier("GeodePickaxe", "#8a7e8e", "#5e5462", "#b4a8b8", "#5a4a5e", "#3a2e40", "#c47cff", mark="geode"),
    tier("FossilPickaxe", "#ece2c8", "#bcae8e", "#fff8e6", "#6e5a44", "#4a3a2c", "#ffb04a", variant="double", mark="gem"),
    tier("TitanHammerPickaxe", "#c8964a", "#8e6630", "#f0c87a", "#5a4a5e", "#3a2e40", "#ffe08a", band="#f0c87a", variant="hammer", mark="gem", size=1.15),
    tier("FrostquartzPickaxe", "#9ad4f0", "#5a9ac0", "#e4f6ff", "#6a7a9a", "#3e4a66", "#ffffff", variant="double", glow="crystal"),
    tier("AmethystPickaxe", "#a46ae0", "#6e3ea8", "#d4a8ff", "#4e3e66", "#2e2444", "#f0d8ff", variant="double", glow="crystal"),
    tier("SongcrystalPickaxe", "#6ad8c8", "#3a9a98", "#b8fff0", "#4e3e66", "#2e2444", "#ff8ad8", glow="crystal", mark="gem"),
    tier("SapphirePickaxe", "#3c6ae0", "#22409e", "#8aa8ff", "#e0b04a", "#5a3e2a", "#ffe08a", band="#e0b04a", variant="double", mark="gem"),
    tier("PrismPickaxe", "#e8e4f8", "#a8a0c8", "#ffffff", "#5a4a7e", "#3a2e5a", "#ff6ad8", variant="double", glow="prism"),
    tier("AuroraPickaxe", "#46c8a0", "#2a7a8a", "#a8ffd8", "#3e3466", "#241e44", "#c88aff", glow="aurora"),
    tier("SurtshardPickaxe", "#2c2430", "#18121c", "#4a3e52", "#3a2a2a", "#1e1414", "#ff6a2c", variant="double", glow="cracks"),
    tier("FireglassPickaxe", "#ff9a4a", "#c85a26", "#ffd29a", "#4a2e2e", "#2e1a1a", "#ffffff", variant="double", glow="crystal"),
    tier("EmberPickaxe", "#e0542c", "#9a2e1a", "#ffa06a", "#3a2a2a", "#1e1414", "#ffe06a", mark="flame", glow="cracks"),
    tier("RubyPickaxe", "#d82a4a", "#8e1a30", "#ff7a90", "#e0b04a", "#5a2e2e", "#ffe08a", band="#e0b04a", variant="double", mark="gem"),
    tier("PhoenixPickaxe", "#ff6a3c", "#c0381e", "#ffc06a", "#e0b04a", "#5a2e2e", "#ffe08a", band="#e0b04a", variant="double", mark="wings"),
    tier("SunforgePickaxe", "#f0c03c", "#b0801e", "#fff0a0", "#e8e0c8", "#8a6a3a", "#ffffff", band="#fff0a0", variant="hammer", mark="sun", size=1.1),
    tier("StarlightPickaxe", "#f08ad0", "#b05a9e", "#ffd0f0", "#c8b0f0", "#7a5ab0", "#ffffff", band="#ffe08a", variant="double", mark="star"),
    tier("MoonlitPickaxe", "#c0ccf0", "#7a8ab8", "#f0f4ff", "#3a3e6a", "#22264a", "#ffe8a0", band="#c0ccf0", variant="double", mark="moon"),
    tier("GalaxyPickaxe", "#5a3ea8", "#2e1e6a", "#a07ef0", "#2a2244", "#160f2a", "#ff9ae0", band="#a07ef0", variant="double", mark="star", glow="specks"),
    tier("RoyalHeartPickaxe", "#ff6aa8", "#c03a78", "#ffc0dc", "#f0d08a", "#8a3a5a", "#ffffff", band="#f0d08a", mark="heart"),
    tier("SilverWingPickaxe", "#e6ecf8", "#9aa6c8", "#ffffff", "#c8d0e8", "#6a7aa8", "#7ab8ff", band="#ffffff", variant="double", mark="wings"),
]

MARKS = {  # 5x5 pixel masks for the collar front, top row first
    "star": ["..#..", ".###.", "#####", ".###.", "#.#.#"],
    "heart": [".#.#.", "#####", "#####", ".###.", "..#.."],
    "moon": [".###.", "##...", "#....", "##...", ".###."],
    "sun": ["#.#.#", ".###.", "#####", ".###.", "#.#.#"],
    "gem": [".....", ".###.", "#####", ".###.", "..#.."],
    "flame": ["..#..", ".##..", ".###.", "#####", ".###."],
    "geode": [".###.", "#...#", "#.#.#", "#...#", ".###."],
}


def shade(h, k):
    h = h.lstrip("#")
    return "#" + "".join(f"{int(int(h[i:i + 2], 16) * k):02x}" for i in (0, 2, 4))


def build(t):
    p = Pet(t["name"])
    k = t["size"]
    # handle: 3x3, pommel, grip wraps, bands
    p.box("Handle", "Handle", -1, 1, 1, HL, -1, 1)
    p.box("Handle", "Band", -2, 2, 0, 1, -2, 2)  # the pommel
    for y in range(3, 11):
        p.box("Handle", "Grip" if y % 2 else "GripDark", -1, 1, y, y, -1, 1)
    for y in (11, HL - 1):
        p.box("Handle", "Band", -2, 2, y, y, -2, 2)
    # collar (the eye of the head)
    cy = HY
    p.box("Head", "Head", -3, 3, cy - 4, cy + 4, -3, 3)  # the eye: a big collar block
    p.box("Head", "Band", -3, 3, cy - 4, cy - 4, -3, 3)

    def arm(side, length, pointed=True, hhalf=3.0, dhalf=2.0, droop=3.5):  # heavy: the owner wanted a hammer-like head, not a stick
        """an arm from the collar out to x = side * (3 + length): it narrows and curves down to a point (or stays blunt)"""
        L = int(length * k)
        for i in range(L):
            u = i / max(L - 1, 1)
            x = side * (3 + i)
            yc = cy - droop * u * u
            h = hhalf * (1 - 0.72 * u) if pointed else hhalf
            d = dhalf * (1 - 0.6 * u) if pointed else dhalf
            for y in range(math.floor(yc - h), math.ceil(yc + h) + 1):
                for z in range(-math.ceil(d), math.ceil(d) + 1):
                    if abs(z) <= d + 0.3 and abs(y - yc) <= h + 0.3:
                        top, bot = y >= yc + h - 0.7, y <= yc - h + 0.7
                        role = "Light" if top or (pointed and u > 0.82) else ("Dark" if bot else "Head")
                        p.put(x, y, z, "Head", role)
        return L

    v = t["variant"]
    arm(1, 10, True)  # the pick
    if v == "double":
        arm(-1, 10, True)
    elif v == "hammer":  # a heavy hammer head both sides
        for s in (-1, 1):
            p.box("Head", "Head", s * 4, s * 8, cy - 4, cy + 4, -4, 4)
            p.box("Head", "Light", s * 8, s * 8, cy - 4, cy + 4, -4, 4)
            p.box("Head", "Dark", s * 4, s * 8, cy - 4, cy - 4, -4, 4)
            p.box("Head", "Band", s * 5, s * 5, cy - 4, cy + 4, -4, 4)
        p.v = {kk: vv for kk, vv in p.v.items() if not (kk[0] > 8 and vv[0] == "Head")}  # no pick on a pure hammer
    else:  # pickhammer: a squared hammer face on the other side
        p.box("Head", "Head", -4, -7, cy - 3, cy + 3, -3, 3)
        p.box("Head", "Light", -8, -8, cy - 3, cy + 3, -3, 3)  # the striking face
        p.box("Head", "Dark", -4, -7, cy - 3, cy - 3, -3, 3)
    # the tier mark on both faces of the collar
    m = t["mark"]
    if m in MARKS:
        for r, row in enumerate(MARKS[m]):
            for c, ch in enumerate(row):
                if ch == "#":
                    for z in (4, -4):
                        p.put(c - 2, cy + 2 - r, z, "Head", "Accent")
    elif m == "wings":
        for s in (-1, 1):
            for i in range(5):
                for y in range(cy + 1 + i // 2, cy + 4 + i):
                    p.put(s * (2 + i), y, 0, "Head", "Light" if i < 3 else "Accent")
    elif m == "moss":
        for x in range(-6, 9, 2):
            p.put(x, cy + 3, 0, "Head", "Accent")
            p.put(x + 1, cy + 4, 0, "Head", "Accent")
    # glow details on the head
    g = t["glow"]
    heads = [kk for kk, vv in p.v.items() if vv[0] == "Head" and vv[1] in ("Head", "Light", "Dark")]
    if g == "cracks":
        for (x, y, z) in heads:
            if (x * 7 + y * 13 + abs(z) * 5) % 11 == 0 and abs(z) >= 1: p.v[(x, y, z)] = ("Head", "Accent")
    elif g == "runes":
        for (x, y, z) in heads:
            if abs(x) in (5, 8) and abs(z) >= 1 and (y - cy) % 2 == 0: p.v[(x, y, z)] = ("Head", "Accent")
    elif g in ("crystal", "prism", "aurora"):
        for (x, y, z) in heads:
            if (x + y) % 4 == 0 and abs(z) >= 1: p.v[(x, y, z)] = ("Head", "Light" if g == "crystal" else "Accent")
    elif g == "specks":
        for (x, y, z) in heads:
            if (x * 5 + y * 3 + z * 7) % 13 == 0: p.v[(x, y, z)] = ("Head", "Accent")
    elif g == "veins":
        for (x, y, z) in heads:
            if abs(z) >= 1 and (abs(x) + y) % 5 == 0 and abs(x) < 9: p.v[(x, y, z)] = ("Head", "Accent")
    return p


if __name__ == "__main__":
    out = []
    for t in TIERS:
        p = build(t)
        d = p.data()
        d["vox"] = VOX
        d["palette"] = {"Head": t["head"], "Dark": t["dark"], "Light": t["light"], "Handle": t["handle"], "Grip": t["grip"], "GripDark": shade(t["grip"], 0.7),
                        "Band": t["band"], "Accent": t["accent"], "Gem": t["accent"], "Crystal": t["light"]}
        d["glowRoles"] = ["Accent"] if t["glow"] or t["mark"] else []
        d["pivots"] = {}
        out.append(d)
        print(f"{t['name']:20} {len(p.v):5} voxels  {d['height']} tall")
    here = os.path.dirname(os.path.abspath(__file__))
    json.dump(out, open(os.path.join(here, "picks.json"), "w"), separators=(",", ":"))
