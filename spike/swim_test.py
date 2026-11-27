"""Cave water check (2026-11-27), Play running with the player in the caves:  python spike/swim_test.py [tag]
   Finds the deepest terrain water column near Camp 1, drops the player into it and reports the Humanoid state (Swimming), the
   air bar, the splash folder and a capture."""
import sys, time, pathlib
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import night
tag = sys.argv[1] if len(sys.argv) > 1 else "t"
FIND = """local C=require(game.ReplicatedStorage.Shared.Config) local o=C.CAVE_ORIGIN
local r=Region3.new(o-Vector3.new(256,96,256), o+Vector3.new(256,64,256)):ExpandToGrid(4)
local mats,occ=workspace.Terrain:ReadVoxels(r,4) local sz=mats.Size local best,bd
for x=1,sz.X do for z=1,sz.Z do local d=0 local top for y=1,sz.Y do if mats[x][y][z]==Enum.Material.Water then d+=1 top=y end end
if d>0 and (not bd or d>bd) then bd=d best=r.CFrame.Position-r.Size/2+Vector3.new((x-0.5)*4,(top-0.5)*4,(z-0.5)*4) end end end
return best and string.format('%.1f,%.1f,%.1f,%d',best.X,best.Y,best.Z,bd) or 'none'"""
w = night.lua(FIND, "Server").splitlines()[-1]
print("deepest water", w)
if w == "none": sys.exit(1)
x, y, z, d = w.split(",")
night.lua(f"local p=game.Players:GetPlayers()[1] p:SetAttribute('InCave', true) p.Character.HumanoidRootPart.CFrame=CFrame.new({x},{float(y) - 1.5},{z}) return 'ok'", "Server")
time.sleep(2.5)
print("state", night.lua("local h=game.Players.LocalPlayer.Character.Humanoid local bar for _,g in game.Players.LocalPlayer.PlayerGui:GetDescendants() do if g.Name=='AirBar' then bar=g end end return tostring(h:GetState())..' airbar '..tostring(bar and bar.Visible)..' splashes '..tostring(workspace:FindFirstChild('WaterFX') and #workspace.WaterFX:GetChildren())", "Client").splitlines()[-1])
print("shot", night.shot(f"swim_{tag}"))
