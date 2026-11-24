"""Blind sheets for the UI text A/B: for each screen, the two looks stacked in a shuffled order labelled X, Y (the key
goes to captures/night/uiab_key.json, never to the grader).   python spike/ui_ab_sheets.py   -> captures/night/uiab_sheet_<state>.jpg"""
import json, pathlib, random, sys
from PIL import Image, ImageDraw, ImageFont
out = pathlib.Path(__file__).resolve().parent.parent / "captures" / "night"
MODES, STATES = ["jelly", "flat"], ["town", "quests", "forge", "hatch", "cave", "soul", "grab"]
args = [a for a in sys.argv[1:] if a not in ("--skin", "--flip")]
rng = random.Random(int(args[0]) if args else 20261124)  # a second round takes a new seed
PRE = "uisk" if "--skin" in sys.argv else "uiab"  # --skin: the button-skin A/B (gel, matte)
if PRE == "uisk": MODES = ["gel", "matte"]
key = {}
PREV = json.loads((out / f"{PRE}_key.json").read_text(encoding="utf-8")) if "--flip" in sys.argv else None  # --flip: every sheet the other way round from the last key
font = ImageFont.truetype("arialbd.ttf", 44)
for st in STATES:
    order = MODES[:]
    rng.shuffle(order)
    if PREV: order = [PREV[st]["Y"], PREV[st]["X"]]
    key[st] = dict(zip("XY", order))
    ims = [Image.open(out / f"{PRE}_{m}_{st}.png").convert("RGB") for m in order]
    w = 1100
    ims = [i.resize((w, round(i.height * w / i.width))) for i in ims]
    h = max(i.height for i in ims)
    sheet = Image.new("RGB", (w, (h + 70) * len(MODES)), (20, 20, 20))
    d = ImageDraw.Draw(sheet)
    for k, (lab, im) in enumerate(zip("XY", ims)):
        y = k * (h + 70)
        d.text((16, y + 10), lab, fill=(255, 255, 255), font=font)
        sheet.paste(im, (0, y + 64))
    sheet.save(out / f"{PRE}_sheet_{st}.jpg", quality=88)
(out / f"{PRE}_key.json").write_text(json.dumps(key, indent=1), encoding="utf-8")
print("sheets", len(STATES))
