"""Pixel Depth dark smoked glass pieces (2026-11-13, the owner: "Try dark smoked glass kit"). The surfaces of the cut-glass kit
(panel, card, pills, slot, tabs, key caps) as dark smoked glass with a lit cut rim; buttons, ribbons and the extras stay as
they are in art/ui_cutglass. Same sizes and 9-slice centres, so the game only swaps image ids (Config.UI_GLASS.smoked).
Text on these surfaces must be light: PixelClient flips dark text when Config.UI_SMOKED is true.
    python art/pd_ui_smoked.py        -> art/ui_smoked/*.png"""
import os, sys, tempfile, pathlib
from PIL import Image

here = pathlib.Path(__file__).resolve().parent
sys.argv = [sys.argv[0], tempfile.mkdtemp()]  # the kit module draws its own set on import: send that to a temp folder
sys.path.insert(0, str(here))
import pd_ui_cutglass as K

out = here / "ui_smoked"
out.mkdir(exist_ok=True)
H, cut = K.H, K.cut
done = []


def save(name, im):
    im.save(out / (name + ".png"))
    done.append(name)


SMOKE, DEEP = H("#4a3a78"), H("#120a24")
FACE = (H("#2a1e4e", 236), H("#191032", 240))  # the reading face: dark, a little lighter at the top
save("panel", cut(200, 200, 26, H("#6a56b0"), DEEP, a_top=240, a_bot=236, bevel=9, dark=True, face=FACE))
save("card", cut(176, 136, 20, H("#5a4a96"), DEEP, a_top=236, a_bot=232, bevel=6, dark=True, face=(H("#33265c", 232), H("#211640", 236))))
save("pill", cut(176, 76, 14, SMOKE, DEEP, a_top=226, a_bot=220, bevel=4.5, dark=True))
for n, (t, dp) in {"pillButter": ("#7a5a1e", "#221604"), "pillLilac": ("#5a45a0", "#150c2e"), "pillMint": ("#1f6a58", "#06201a"), "pillPink": ("#8a3460", "#260a18")}.items():
    save(n, cut(176, 80, 15, H(t), H(dp), a_top=232, a_bot=226, bevel=4.5, dark=True))
save("keycap", cut(72, 76, 10, H("#5a4a96"), DEEP, a_top=244, a_bot=240, bevel=5, sheen=False, dark=True))
save("keycapDown", cut(72, 76, 10, H("#3a2e66"), DEEP, a_top=244, a_bot=240, bevel=3, sheen=False, dark=True))
save("slot", cut(104, 104, 14, H("#2c2152"), H("#0c0618"), a_top=200, a_bot=214, bevel=5, sheen=False, inset=True, dark=True))
save("tab", cut(136, 84, 14, H("#3a2e66"), DEEP, a_top=224, a_bot=218, bevel=5, dark=True))
save("tabOn", cut(136, 84, 14, H("#8a6cff"), H("#3a22a0"), a_top=250, a_bot=244, bevel=5, wash=0.2))  # the chosen tab: bright violet glass, white words

sheet = Image.new("RGBA", (1200, 460), (0, 0, 0, 255))
sheet.alpha_composite(K.vgrad(sheet.size, H("#3a6a4a"), H("#1a0f2a"), 0, 460))
x, y, rowh = 20, 20, 0
for n in done:
    im = Image.open(out / (n + ".png"))
    if x + im.size[0] > 1180: x, y, rowh = 20, y + rowh + 16, 0
    sheet.alpha_composite(im, (x, y))
    x += im.size[0] + 16
    rowh = max(rowh, im.size[1])
sheet.convert("RGB").save(out / "_sheet.jpg", quality=92)
print("smoked pieces:", len(done), done)
