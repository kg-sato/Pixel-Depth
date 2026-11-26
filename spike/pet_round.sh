#!/bin/bash
# one calibrated pet round: build, render, two blind Gemini grades (different shuffles) with the A1/A2 8.0 anchors.
# anchors: render them first with python spike/pet_turntable_grade.py design3d/pets/out_vox captures/pets161/anchors Zharbird Shinemane
# usage: bash spike/pet_round.sh <rN> <seed>
R=$1; SEED=$2
cd "/c/Users/kgsat/Documents/Roblox/Games/Pixel Depth"
BL="/c/Users/kgsat/Downloads/blender-5.3.0-beta+v53.32f5c9c48bca-windows.amd64-release/blender-5.3.0-beta+v53.32f5c9c48bca-windows.amd64-release/blender.exe"
"$BL" -b -P design3d/pets/pet_vox.py -- design3d/pets/out161 Glimwisp Selkie Kirin Ninering Fafnir Ouro 2>&1 | grep "cells,\|Traceback\|line [0-9]"
python spike/pet_turntable_grade.py design3d/pets/out161 captures/pets161/$R Glimwisp Selkie Kirin Ninering Fafnir Ouro 2>&1 | tail -1
for g in a b; do
  mkdir -p captures/pets161/$R/blind_$g
  python - "$R" "$SEED$g" "$g" <<'PY'
import random, json, shutil, pathlib, sys
d = pathlib.Path("captures/pets161") / sys.argv[1]
names = ["Glimwisp", "Selkie", "Kirin", "Ninering", "Fafnir", "Ouro"]
rnd = random.Random(sys.argv[2]); order = names[:]; rnd.shuffle(order)
b = d / ("blind_" + sys.argv[3]); key = {}
for i, n in enumerate(order):
    shutil.copy(d / f"{n}_sheet.png", b / f"P{i+1:02d}.png"); key[f"P{i+1:02d}"] = n
shutil.copy("captures/pets161/anchors/Zharbird_sheet.png", b / "A1.png"); shutil.copy("captures/pets161/anchors/Shinemane_sheet.png", b / "A2.png")
json.dump(key, open(b / "key.json", "w")); print(key)
PY
  cp spike/pet_grade_brief.md captures/pets161/$R/blind_$g/brief.md
done
cd "/c/Users/kgsat/Documents/Roblox"
for g in a b; do
  P="Games/Pixel Depth/captures/pets161/$R/blind_$g"
  python tools/agy_task.py "$P/brief.md" --files "$P/A1.png" "$P/A2.png" "$P/P01.png" "$P/P02.png" "$P/P03.png" "$P/P04.png" "$P/P05.png" "$P/P06.png" --name pets161_${R}_$g > "$P/grade.txt" 2>&1 &
done
wait
echo "ROUND $R DONE"
