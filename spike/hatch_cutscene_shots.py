"""Rarity-scaled hatch cutscenes (2026-11-27, vault Briefs/Pet Hatch Cutscenes): play each pet's hatch in Play and capture
four beats (act 1, apex, burst, reveal), plus a SKIP cleanup check.  python spike/hatch_cutscene_shots.py <tag> [Pet ...]
Stills: captures/night/hcut_<tag>_<pet>_<beat>.png. Prints the HatchCracks / Lighting state after a SKIP."""
import sys, time, pathlib
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import night
tag = sys.argv[1] if len(sys.argv) > 1 else "t"
# name -> omen seconds (the build-up before it is about 1.4 + 1.6 + k*1.6 s; the beats are sampled inside the omen)
PETS = {"Tosk": 0, "Shinemane": 1.8, "Goldbristle": 1.8, "Pixiu": 1.8, "Glimwisp": 3.2, "Selkie": 3.2, "Zharbird": 3.2, "Fafnir": 4.8, "Kirin": 4.8, "Ouro": 6.2, "Ninering": 8.0}
only = sys.argv[2:] or list(PETS)
def L(code, where="Server"): return (night.lua(code, where).splitlines() or [""])[-1]
def omenStart():  # waits until the client's omen begins: the caption changes from the default line
    t0 = time.time()
    while time.time() - t0 < 14:
        c = L("for _,d in game.Players.LocalPlayer.PlayerGui:GetDescendants() do if d.Name=='HatchSkip' then return 'on' end end return 'off'", "Client")
        if c == "on": return True
        time.sleep(0.3)
    return False
for pet in only:
    omen = PETS.get(pet, 0)
    L(f"game.ReplicatedStorage.Remotes.Fx:FireClient(game.Players:GetPlayers()[1], 'hatch', '{pet}') return 1")
    omenStart()
    build = 4.2 if omen >= 4 else (3.6 if omen >= 3 else 3.0)
    time.sleep(build)
    print(pet, "act1", night.shot(f"hcut_{tag}_{pet}_act1"))
    time.sleep(max(0.3, omen * 0.45))
    print(pet, "apex", night.shot(f"hcut_{tag}_{pet}_apex"))
    time.sleep(max(0.5, omen * 0.45 + 1.0))
    print(pet, "burst", night.shot(f"hcut_{tag}_{pet}_burst"))
    time.sleep(2.2)
    print(pet, "reveal", night.shot(f"hcut_{tag}_{pet}_reveal"))
    time.sleep(6)
    L("for _,d in game.Players.LocalPlayer.PlayerGui:GetDescendants() do if d:IsA('TextButton') and d.Visible and d.Size.X.Scale == 1 and d.Size.Y.Scale == 1 then pcall(function() d:Activate() end) end end return 1", "Client")
    time.sleep(3)
# SKIP cleanup: start Ninering, click SKIP mid-omen with the real mouse, then check the cracks gui and the lighting once it ends
amb0 = L("return tostring(game.Lighting.Ambient)..' '..tostring(game.Lighting.Brightness)..' '..tostring(game.Lighting.ClockTime)", "Client")
L("game.ReplicatedStorage.Remotes.Fx:FireClient(game.Players:GetPlayers()[1], 'hatch', 'Ninering') return 1")
omenStart(); time.sleep(5)
pos = L("for _,d in game.Players.LocalPlayer.PlayerGui:GetDescendants() do if d.Name=='HatchSkip' and d.Visible then local p=d.AbsolutePosition+d.AbsoluteSize/2 local i=game:GetService('GuiService'):GetGuiInset() return math.floor(p.X)..','..math.floor(p.Y+i.Y) end end return 'none'", "Client")
print("skip button at", pos)
L("local p=game.Players.LocalPlayer p:SetAttribute('DevHatchSkip', nil) p:SetAttribute('DevHatchSkip', true) return 1", "Client")
time.sleep(1.2)
print("after skip shot", night.shot(f"hcut_{tag}_skip"))
time.sleep(5)
L("local p=game.Players.LocalPlayer p:SetAttribute('DevHatchSkip', nil) p:SetAttribute('DevHatchSkip', true) return 1", "Client")
time.sleep(4)
print("cracks gui left:", L("return tostring(game.Players.LocalPlayer.PlayerGui:FindFirstChild('HatchCracks') ~= nil)", "Client"))
print("lighting before / after:", amb0, "/", L("return tostring(game.Lighting.Ambient)..' '..tostring(game.Lighting.Brightness)..' '..tostring(game.Lighting.ClockTime)", "Client"))
