#!/bin/sh
# build_all.sh [samples] [tags...] : build, render, export and sheet each pickaxe (default all ten)
BL="C:/Users/kgsat/Downloads/blender-5.3.0-beta+v53.32f5c9c48bca-windows.amd64-release/blender-5.3.0-beta+v53.32f5c9c48bca-windows.amd64-release/blender.exe"
cd "$(dirname "$0")"
S=${1:-48}; shift
TAGS=${*:-"pick_01 pick_02 pick_03 pick_04 pick_05 pick_06 pick_07 pick_08 pick_09 pick_10"}
for t in $TAGS; do
  "$BL" -b -P pickaxe_hero.py -- "specs/$t.json" "$(pwd -W)/out/$t" "$S" game 2>&1 | grep -v "Auto-detect\|HIPEW" | grep -E "PICKAXE|EXPORTED|Error|Traceback|line [0-9]+," | grep -v "Auto-detect|HIPEW" | sed "s/^/$t /"
  /c/Python314/python.exe vs_sheet.py "$t" > /dev/null
done
