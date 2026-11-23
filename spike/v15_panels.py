"""Master Directive v15: the new Soul Tree panel and the grab card with its crimson shatter, checked at 16:9 and at a phone's
2.16:1 (the Studio window is resized as in sizes_overlap.py): spike/text_overlap.luau (word ink overlaps and spills) and
spike/hud_overlap.luau on each, plus a still.   python spike/v15_panels.py   -> captures/night/v15p_<shape>_<view>.png"""
import ctypes, time, pathlib, sys
from ctypes import wintypes
here = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(here))
import night as N
from prompt_test import trigger
import sizes_overlap_win as W
TXT = (here / "text_overlap.luau").read_text(encoding="utf-8")
HUD = (here / "hud_overlap.luau").read_text(encoding="utf-8")
out = []
def check(tag):
    time.sleep(1.2)
    t = " | ".join(N.lua(TXT, "Client").strip().splitlines()[-6:])
    h = " | ".join(N.lua(HUD, "Client").strip().splitlines()[-4:])
    N.shot(f"v15p_{tag}")
    out.append(f"{tag}: text {t} || hud {h}")
try:
    for name, aspect in (("16x9", 16 / 9), ("phone", 844 / 390)):
        N.play(False); time.sleep(2); N.play(True); time.sleep(9)
        vx, vy = W.shape(aspect)
        time.sleep(2)
        N.lua("local p=game.Players:GetPlayers()[1] game.ReplicatedStorage.Remotes.Fx:FireClient(p,'grabbed',5) return 1", "Server")
        check(f"{name}_grab")
        time.sleep(6)
        N.lua("local g=game.Players.LocalPlayer.PlayerGui:FindFirstChild('DailyChest') if g then g.Enabled=false end return 1", "Client")
        N.key("Q"); time.sleep(30)
        N.lua("game.Players:GetPlayers()[1]:SetAttribute('DevSoul',12) return 1", "Server"); time.sleep(1.2)
        trigger("SoulTree", "true"); time.sleep(1.5)
        check(f"{name}_soul")
        out[-1] = f"[{vx}x{vy}] " + out[-1]
finally:
    N.play(False)
    W.restore()
(N.out / "v15_panels.txt").write_text("\n".join(out) + "\n", encoding="utf-8")
print("\n".join(out))
