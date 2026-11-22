"""Directive v14: pick one tour still per graded view from a loop_stills run and write a blind Gemini brief for them.
    python spike/tour_views.py <tour name>      -> Overnight/judge/views_<name>/NN.png + brief.md + map.txt
Then: python ../../tools/agy_task.py Overnight/judge/views_<name>/brief.md --files Overnight/judge/views_<name> --name views_<name>"""
import os, shutil, sys, pathlib
name = sys.argv[1]
here = pathlib.Path(__file__).resolve().parent
src = here.parent / "captures" / "loop" / name
dest = here.parent.parent.parent / "Overnight" / "judge" / f"views_{name}"
dest.mkdir(parents=True, exist_ok=True)
# view name, tour second (loop_rec5's step times), what the grader should judge
WANT = [("loading splash", 13), ("town HUD", 25), ("settings", 110), ("forge", 122), ("boss fight and strike reticle", 242),
        ("boss reward chest", 278), ("glass lift ride", 286), ("Clay Caves hall", 310), ("crew escape HUD", 486), ("escape result card", 501),
        ("town arrival", 505)]
files = sorted(int(f[:4]) for f in os.listdir(src) if f.endswith(".png"))
lines = []
for i, (view, t) in enumerate(WANT, 1):
    f = min(files, key=lambda x: abs(x - t))
    shutil.copy(src / f"{f:04d}.png", dest / f"{i:02d}.png")
    lines.append(f"{i:02d} {view}")
(dest / "map.txt").write_text("\n".join(lines), encoding="utf-8")
(dest / "brief.md").write_text(
    "Blind grade of screenshots from a Roblox first-person cave-mining game (chunky voxel world, dark violet jelly-glass UI). One still per view:\n"
    + "\n".join(lines) + "\n"
    "For EACH image give a 1-10 score. Be harsh: 5 = average, 7 = good, 8 = rare, 9 = front-page Roblox quality.\n"
    "Judge readability, overlaps, clutter, contrast, anything broken. A torch flame or a pickaxe in first-person frames is the player's own.\n"
    "Answer as a table: image | score | biggest defect (concrete) | one fix. Then one line: the lowest image.\n", encoding="utf-8")
print("wrote", dest)
