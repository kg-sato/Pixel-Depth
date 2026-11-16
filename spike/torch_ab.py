"""A/B for the dead-torch look (cave readability graded 3 six times): the same three first-person views with the torch
burnt out, as built (A) and with a stronger last glow (B, C) faked by a second PointLight on the player's LanternAnchor.
Nothing in the game changes. Writes captures/night/tab_<view>_<A|B|C>.png and a 3 x 3 sheet for Gemini.
    python spike/torch_ab.py"""
import pathlib, subprocess, sys, time
from PIL import Image, ImageDraw
here = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(here))
from prompt_test import SAFE, night
game, ws = here.parent, here.parent.parent.parent
P = "local p=game.Players:GetPlayers()[1] local h=p.Character.HumanoidRootPart local C=require(game.ReplicatedStorage.Shared.Config) local O=C.CAVE_ORIGIN "
VIEWS = {  # where to stand (server Luau giving `at`) and where to look, relative to the standing point
    "tunnel": ("local at=O+Vector3.new(48,3,0)", "Vector3.new(30,-2,6)"),
    "shrine": ("local s=workspace.Caves:FindFirstChild('LostLanternSpot',true) local at=safe(s.Position)", "Vector3.new(-20,-1,-14)"),
    "deposit": ("local best,bd for _,d in workspace.Caves.Deposits:GetChildren() do local m=(d.PrimaryPart.Position-O).Magnitude if m>60 and m<110 and (not bd or m<bd) then best,bd=d,m end end local at=safe(best.PrimaryPart.Position)", "Vector3.new(18,-1,-18)"),
}
VARIANTS = {"A": None, "B": (16, 0.25), "C": (22, 0.32)}  # extra light: range, brightness
night("play"); time.sleep(8); night("key", "Q"); time.sleep(33)
night("lua", "Server", P + "p:SetAttribute('DevBanked',true) return 1")
age = 300
for vname, (stand, look) in VIEWS.items():
    for var, light in VARIANTS.items():
        age += 1
        night("lua", "Server", P + "h.CFrame=CFrame.new(O+Vector3.new(4,3,4)) return 1"); time.sleep(1.2)  # relight at camp, monsters scatter
        night("lua", "Server", SAFE + P + stand + f" h.CFrame=CFrame.new(at) task.wait(0.3) p:SetAttribute('DevTorchAge',{age}) return 1")
        extra = (f"local l=Instance.new('PointLight') l.Name='ABLight' l.Range={light[0]} l.Brightness={light[1]} l.Color=Color3.fromRGB(255,190,120) l.Shadows=false l.Parent=a " if light else "")
        hold = subprocess.Popen([sys.executable, str(here / "night.py"), "lua", "Client",
            "local c=workspace.CurrentCamera local root=game.Players.LocalPlayer.Character.HumanoidRootPart local a=root:FindFirstChild('LanternAnchor') or root "
            "for _,x in a:GetChildren() do if x.Name=='ABLight' then x:Destroy() end end " + extra +
            f"local t0=os.clock() while os.clock()-t0<3.2 do c.CFrame=CFrame.lookAt(c.CFrame.Position,c.CFrame.Position+{look}) task.wait() end "
            "for _,x in a:GetChildren() do if x.Name=='ABLight' then x:Destroy() end end return 1"], stdout=subprocess.DEVNULL)
        time.sleep(1.9); night("shot", f"tab_{vname}_{var}"); hold.wait()
        print(vname, var, flush=True)
night("stop")
tiles = []
for vname in VIEWS:
    for var in VARIANTS:
        im = Image.open(game / "captures" / "night" / f"tab_{vname}_{var}.png").convert("RGB").resize((957, 390))
        ImageDraw.Draw(im).rectangle((0, 0, 150, 26), fill=(0, 0, 0)); ImageDraw.Draw(im).text((6, 6), f"{vname}  {var}", fill=(255, 255, 0))
        tiles.append(im)
sheet = Image.new("RGB", (957 * 3, 390 * 3))
for i, im in enumerate(tiles): sheet.paste(im, ((i % 3) * 957, (i // 3) * 390))
out = ws / "Overnight" / "judge" / "torch_ab.jpg"; sheet.save(out, quality=88); print("sheet", out)
