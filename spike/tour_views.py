"""Directive v14: pick one tour still per graded view from a loop_stills run and write a blind Gemini brief for them.
    python spike/tour_views.py <tour name>      -> Overnight/judge/views_<name>/NN.png + brief.md + map.txt
Then: python ../../tools/agy_task.py Overnight/judge/views_<name>/brief.md --files Overnight/judge/views_<name> --name views_<name>"""
import os, shutil, sys, pathlib
name = sys.argv[1]
here = pathlib.Path(__file__).resolve().parent
src = here.parent / "captures" / "loop" / name
dest = here.parent.parent.parent / "Overnight" / "judge" / f"views_{name}"
dest.mkdir(parents=True, exist_ok=True)
# view name, the tour step label it belongs to, which still of that step (0 = its first; -1 = its last). By label, not by second:
# the tour's timing drifts from run to run (full1122e: every view landed one step late)
WANT = [("loading splash", "loading logo", -1), ("town HUD", "town HUD", 1), ("settings", "settings:", 1), ("forge", "forge", 2),
        ("Camp 1 arrival", "arrival at Camp 1", 1), ("mining strike", "minigames", 3), ("boss fight and strike reticle", "strike reticle on a knot|Root Warden: the whole fight", 0),
        ("boss reward chest", "fight over", 1), ("glass lift ride", "glass lift", 2), ("Clay Caves hall", "Camp 2: the hall", 2),
        ("crew escape HUD", "crew ride from the stoker", 1), ("escape result card", "the escape result card|crew ride from the stoker", 0), ("town arrival", "back in town after the escape card|crew ride over", 0),
        ("Deep Chronicle monolith", "the Deep Chronicle: close|the Deep Chronicle", 0), ("refinery crucible", "the crucible: melting|the crucible", 0), ("forge HEAT & BLOW gauge", "HEAT & BLOW: PERFECT FORGE|HEAT & BLOW", 0),
        ("Soul Tree constellations", "the Soul Tree: open|the Soul Tree at the campfire", 0), ("Legendary hatch showcase", "the hatch showcase: the roar|a Legendary hatch: Fafnir", 0)]  # v15: each label's first still is the forced one
rows = [l.split("	") for l in (src / "labels.txt").read_text(encoding="utf-8").splitlines() if l.count("	") >= 2]
lines = []
for i, (view, key, k) in enumerate(WANT, 1):
    hits = []
    for n_alt, alt in enumerate(key.split("|")):  # the first label that has stills wins; a fallback label takes its own still (6: mid-fight)
        if not hits:
            hits = [r[0] for r in rows if alt in r[2]]
            if hits and n_alt > 0: k = 6
    if view == "mining strike" and (here.parent / "captures" / "night" / f"loop_{name}_strike.png").exists():  # mg_night's own shot right as the dial opens (Orchestrator round 3)
        shutil.copy(here.parent / "captures" / "night" / f"loop_{name}_strike.png", dest / f"{i:02d}.png")
        lines.append(f"{i:02d} {view}")
        continue
    if not hits:
        print("no still for", view); continue
    f = hits[max(-len(hits), min(k, len(hits) - 1))]
    shutil.copy(src / f, dest / f"{i:02d}.png")
    lines.append(f"{i:02d} {view}")
(dest / "map.txt").write_text("\n".join(lines), encoding="utf-8")
(dest / "brief.md").write_text(
    "Blind grade of screenshots from a Roblox first-person cave-mining game (chunky voxel world, dark violet jelly-glass UI). One still per view:\n"
    + "\n".join(lines) + "\n"
    "For EACH image give a 1-10 score. Be harsh: 5 = average, 7 = good, 8 = rare, 9 = front-page Roblox quality.\n"
    "Judge readability, overlaps, clutter, contrast, anything broken. A torch flame or a pickaxe in first-person frames is the player's own.\n"
    "Answer as a table: image | score | biggest defect (concrete) | one fix. Then one line: the lowest image.\n", encoding="utf-8")
print("wrote", dest)
