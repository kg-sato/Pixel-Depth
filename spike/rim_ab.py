"""A/B sheet for the floor-edge rim experiment (spike/edge_rim.luau): three views with the torch burnt out, without and with
rims. Play must be running in the caves. Writes <workspace>/Overnight/judge/rim_ab.jpg."""
import pathlib, subprocess, sys, time
from PIL import Image, ImageDraw
here = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(here))
from prompt_test import SAFE, night
game, ws = here.parent, here.parent.parent.parent
P = "local p=game.Players:GetPlayers()[1] local h=p.Character.HumanoidRootPart local C=require(game.ReplicatedStorage.Shared.Config) local O=C.CAVE_ORIGIN "
VIEWS = {
    "chasm": ("local pl for _,x in workspace.Caves.Chasm:GetChildren() do if x.Name=='Plank' then pl=pl or x end end local at=pl.Position+Vector3.new(0,4,0)", "Vector3.new(24,-8,10)"),
    "tunnel": ("local at=O+Vector3.new(48,3,0)", "Vector3.new(30,-4,6)"),
    "deposit": ("local best,bd for _,d in workspace.Caves.Deposits:GetChildren() do local m=(d.PrimaryPart.Position-O).Magnitude if m>60 and m<110 and (not bd or m<bd) then best,bd=d,m end end local at=safe(best.PrimaryPart.Position)", "Vector3.new(18,-5,-18)"),
}
night("lua", "Server", P + "p:SetAttribute('DevBanked',true) return 1")
age, tiles = 400, []
for vname, (stand, look) in VIEWS.items():
    for var in ("A", "B"):
        age += 1
        night("lua", "Server", P + "h.CFrame=CFrame.new(O+Vector3.new(4,3,4)) return 1"); time.sleep(1.2)
        night("lua", "Server", SAFE + P + stand + f" h.CFrame=CFrame.new(at) task.wait(0.3) p:SetAttribute('DevTorchAge',{age}) return 1")
        night("lua", "Client", f"workspace:SetAttribute('RimOff',{'true' if var == 'A' else 'nil'}) return 1")
        print(vname, var, night("lua", "Client", "@" + str(here / "edge_rim.luau")), flush=True)
        hold = subprocess.Popen([sys.executable, str(here / "night.py"), "lua", "Client", f"local c=workspace.CurrentCamera local t0=os.clock() while os.clock()-t0<3 do c.CFrame=CFrame.lookAt(c.CFrame.Position,c.CFrame.Position+{look}) task.wait() end return 1"], stdout=subprocess.DEVNULL)
        time.sleep(1.8); night("shot", f"rim_{vname}_{var}"); hold.wait()
        im = Image.open(game / "captures" / "night" / f"rim_{vname}_{var}.png").convert("RGB").resize((957, 390))
        ImageDraw.Draw(im).rectangle((0, 0, 150, 26), fill=(0, 0, 0)); ImageDraw.Draw(im).text((6, 6), f"{vname}  {var}", fill=(255, 255, 0))
        tiles.append(im)
night("lua", "Client", "workspace:SetAttribute('RimOff',true) return 1"); night("lua", "Client", "@" + str(here / "edge_rim.luau"))
sheet = Image.new("RGB", (957 * 2, 390 * 3))
for i, im in enumerate(tiles): sheet.paste(im, ((i % 2) * 957, (i // 2) * 390))
out = ws / "Overnight" / "judge" / (sys.argv[1] if len(sys.argv) > 1 else "rim_ab.jpg"); sheet.save(out, quality=88); print("sheet", out)
