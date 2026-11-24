"""UI text A/B (2026-11-24, the owner: "rework UI and HUD to be a little more generic, use the font without the 3D effects and
test it against our current ones"). For each look in Config.UI_TEXT ("jelly" now, "flat" Gumdrop without its 3D effects) it sets
the Studio attribute workspace.DevUIText, plays fresh and takes the same screens, with the word-overlap check on each.
    python spike/ui_text_ab.py [modes...]     -> captures/night/uiab_<mode>_<state>.png, captures/night/uiab_report.txt"""
import pathlib, sys, time
here = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(here))
import night as N
from prompt_test import trigger
TXT = (here / "text_overlap.luau").read_text(encoding="utf-8")
modes = sys.argv[1:] or ["jelly", "flat"]  # "plain" (Roblox fonts) was dropped: Studio crashed twice stopping Play after its forge screen
report = []
def S(c): return (N.lua(c, "Server").splitlines() or ["?"])[-1]
def C(c): return (N.lua(c, "Client").splitlines() or ["?"])[-1]
def shot(mode, state):
    time.sleep(1.2)
    t = " | ".join(N.lua(TXT, "Client").strip().splitlines()[-3:])
    N.shot(f"uiab_{mode}_{state}")
    report.append(f"{mode} {state}: {t}")
    print(report[-1], flush=True)
def fresh(mode):
    N.play(False); time.sleep(2)
    N.lua(f"workspace:SetAttribute('DevUIText','{mode}') return 1", "Edit")
    N.play(True); time.sleep(10)
    got = C("return require(game.ReplicatedStorage.Shared.Config).uiText()")
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
    N.lua("workspace:SetAttribute('DevUIText',nil) return 1", "Edit")  # never leave the override in the saved place
(N.out / "uiab_report.txt").write_text("\n".join(report) + "\n", encoding="utf-8")
print("done")
