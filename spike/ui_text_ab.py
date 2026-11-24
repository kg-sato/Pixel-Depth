"""UI text A/B (2026-11-24, the owner: "rework UI and HUD to be a little more generic, use the font without the 3D effects and
test it against our current ones"). For each look in Config.UI_TEXT ("jelly" now, "flat" Gumdrop without its 3D effects) it sets
the Studio attribute workspace.DevUIText, plays fresh and takes the same screens, with the word-overlap check on each.
    python spike/ui_text_ab.py [modes...]     -> captures/night/uiab_<mode>_<state>.png, captures/night/uiab_report.txt
    python spike/ui_text_ab.py --skin gel matte  the same for the button skins (Config.UI_SKIN, attribute DevUISkin) -> uisk_<mode>_<state>.png"""
import pathlib, sys, time
here = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(here))
import night as N
from prompt_test import trigger
TXT = (here / "text_overlap.luau").read_text(encoding="utf-8")
SKIN = "--skin" in sys.argv
ATTR, FN, PRE = ("DevUISkin", "uiSkin", "uisk") if SKIN else ("DevUIText", "uiText", "uiab")
modes = [a for a in sys.argv[1:] if a != "--skin"] or (["gel", "matte"] if SKIN else ["jelly", "flat"])  # "plain" (Roblox fonts) was dropped: Studio crashed twice stopping Play after its forge screen
report = []
def S(c): return (N.lua(c, "Server").splitlines() or ["?"])[-1]
def C(c): return (N.lua(c, "Client").splitlines() or ["?"])[-1]
def shot(mode, state):
    time.sleep(1.2)
    t = " | ".join(N.lua(TXT, "Client").strip().splitlines()[-3:])
    N.shot(f"{PRE}_{mode}_{state}")
    report.append(f"{mode} {state}: {t}")
    print(report[-1], flush=True)
def fresh(mode):
    N.play(False); time.sleep(2)
    N.lua(f"workspace:SetAttribute('{ATTR}','{mode}') return 1", "Edit")
    N.play(True); time.sleep(10)
    got = C(f"return require(game.ReplicatedStorage.Shared.Config).{FN}()")
    assert got == mode, f"client look {got!r}, wanted {mode!r}"
    C("local g=game.Players.LocalPlayer.PlayerGui:FindFirstChild('DailyChest') if g then g.Enabled=false end return 1")
try:
    for mode in modes:
        fresh(mode)
        shot(mode, "town")
        N.key("J"); shot(mode, "quests"); N.key("J")
        trigger("Station", "'forge'"); shot(mode, "forge")
        fresh(mode)
        trigger("Station", "'hatch'"); shot(mode, "hatch")
        fresh(mode)
        N.key("Q"); time.sleep(24); shot(mode, "cave")
        S("local p=game.Players:GetPlayers()[1] p:SetAttribute('DevSoul',12) return 1"); time.sleep(1)
        trigger("SoulTree", "true"); time.sleep(1.5); shot(mode, "soul")
        C("game.Players.LocalPlayer:SetAttribute('DevOpen',nil) local w=game.Players.LocalPlayer.PlayerGui:FindFirstChild('SoulTree',true) if w then w.Visible=false end return 1"); time.sleep(1)
        S("local p=game.Players:GetPlayers()[1] game.ReplicatedStorage.Remotes.Fx:FireClient(p,'grabbed',5) return 1"); time.sleep(0.9)
        shot(mode, "grab")
finally:
    N.play(False); time.sleep(2)
    N.lua(f"workspace:SetAttribute('{ATTR}',nil) return 1", "Edit")  # never leave the override in the saved place
(N.out / f"{PRE}_report.txt").write_text("\n".join(report) + "\n", encoding="utf-8")
print("done")
