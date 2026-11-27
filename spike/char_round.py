"""One NPC character round (2026-11-27): build with design3d/chars/npcs_vox.py, render the turntable sheet, two blind Gemini grades
with the two 8.0 pet anchors (spike/pet_grade_brief.md reworded for a character).   python spike/char_round.py <rN> <Name>
Writes captures/chars/<rN>/<Name>_sheet.png and blind_a/grade.txt, blind_b/grade.txt; prints both OVERALL lines."""
import os, re, shutil, subprocess, sys, pathlib
game = pathlib.Path(__file__).resolve().parent.parent
root = game.parent.parent
R, name = sys.argv[1], sys.argv[2]
BL = r"C:\Users\kgsat\Downloads\blender-5.3.0-beta+v53.32f5c9c48bca-windows.amd64-release\blender-5.3.0-beta+v53.32f5c9c48bca-windows.amd64-release\blender.exe"
r = subprocess.run([BL, "-b", "-P", str(game / "design3d/chars/npcs_vox.py"), "--", str(game / "design3d/chars/out_vox"), name], capture_output=True, text=True, cwd=game)
print([l for l in (r.stdout + r.stderr).splitlines() if "cells," in l or "Traceback" in l or "Error:" in l][:4])
out = game / "captures/chars" / R
subprocess.run([sys.executable, str(game / "spike/pet_turntable_grade.py"), str(game / "design3d/chars/out_vox"), str(out), name], capture_output=True, text=True, cwd=game)
brief = (game / "spike/pet_grade_brief.md").read_text(encoding="utf-8")
brief = brief.replace("Each other image (P01..P06) is ONE pet", "Each other image (P01) is ONE character (a town NPC, not a pet)").replace("For EACH of P01..P06", "For P01").replace("voxel-creature pet game", "voxel game with voxel creature pets and voxel NPC characters")
procs = []
for g in "ab":
    d = out / f"blind_{g}"; d.mkdir(parents=True, exist_ok=True)
    shutil.copy(game / "captures/pets161/anchors/Zharbird_sheet.png", d / ("A1.png" if g == "a" else "A2.png"))
    shutil.copy(game / "captures/pets161/anchors/Shinemane_sheet.png", d / ("A2.png" if g == "a" else "A1.png"))
    shutil.copy(out / f"{name}_sheet.png", d / "P01.png")
    (d / "brief.md").write_text(brief, encoding="utf-8")
    rel = d.relative_to(root).as_posix()
    procs.append((d, subprocess.Popen([sys.executable, str(root / "tools/agy_task.py"), f"{rel}/brief.md", "--files", f"{rel}/A1.png", f"{rel}/A2.png", f"{rel}/P01.png", "--name", f"char_{name}_{R}_{g}", "--timeout", "400"], cwd=root, stdout=open(d / "grade.txt", "w", encoding="utf-8"), stderr=subprocess.STDOUT)))
for d, p in procs:
    p.wait()
    t = (d / "grade.txt").read_text(encoding="utf-8", errors="replace")
    m = re.findall(r"\*\*P01\*\*.*", t)
    print(d.name, (m[-1] if m else t[-600:])[:900])
