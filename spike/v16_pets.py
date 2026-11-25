"""Master Directive v16: the plate pets in the game. Builds all 13 on the client in two rows on a dark stage above the town (client
only), checks each builds and counts its bones, lets them idle, walk on the spot and play the hero showcase, and takes stills.
    python spike/v16_pets.py <tag> [Name ...]   -> captures/night/v16pets_<tag>_<view>.png"""
import pathlib, sys, time
here = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(here))
import night as N
tag = sys.argv[1] if len(sys.argv) > 1 else "a"
names = sys.argv[2:] or ["Tosk", "Kobold", "Kepri Scarab", "Shinemane", "Goldbristle", "Pixiu", "Glimwisp", "Selkie", "Zharbird", "Fafnir", "Kirin", "Ouro", "Ninering"]
def C(c): return (N.lua(c, "Client").splitlines() or ["?"])[-1]
N.play(False); N.play(True); time.sleep(12)
lst = "{" + ", ".join('"%s"' % n for n in names) + "}"
SETUP = r"""
local PV = require(game.ReplicatedStorage.Shared.PetVoxels)
local names = NAMES
local old = workspace:FindFirstChild("V16Pets") if old then old:Destroy() end
local f = Instance.new("Folder") f.Name = "V16Pets" f.Parent = workspace
local O = Vector3.new(0, 300, 0)
local floor = Instance.new("Part") floor.Anchored = true floor.Size = Vector3.new(120, 1, 60) floor.CFrame = CFrame.new(O + Vector3.new(0, -0.5, 0)) floor.Color = Color3.fromRGB(46, 40, 58) floor.Material = Enum.Material.Slate floor.Parent = f
local back = Instance.new("Part") back.Anchored = true back.Size = Vector3.new(120, 50, 1) back.CFrame = CFrame.new(O + Vector3.new(0, 20, -22)) back.Color = Color3.fromRGB(24, 20, 34) back.Parent = f
for _, x in { -30, 0, 30 } do local l = Instance.new("PointLight") l.Range = 45 l.Brightness = 1.2 l.Color = Color3.fromRGB(255, 236, 214) local a = Instance.new("Attachment") a.Position = Vector3.new(x, 18, 14) a.Parent = floor l.Parent = a end
local out, models = {}, {}
for i, n in names do
	local t0 = os.clock()
	local m
	repeat m = PV.build(n) if not m then task.wait(0.2) end until m or os.clock() - t0 > 20
	if not m then table.insert(out, n .. ": no model") continue end
	local parts, glow = 0, 0
	for _, p in m:GetChildren() do if p:IsA("BasePart") then parts += 1 if p.Material == Enum.Material.Neon then glow += 1 end end end
	m.Parent = f
	local scale = SCALE
	m:ScaleTo(scale)
	local col, row = (i - 1) % 7, (i - 1) // 7
	m:PivotTo(CFrame.new(O + Vector3.new(-48 + col * 16, 0.92 * scale, -6 + row * 22)) * CFrame.Angles(0, math.rad(200), 0))
	table.insert(models, m)
	local ext = m:GetExtentsSize()
	table.insert(out, string.format("%s: %d pieces (%d glow) %.1fx%.1fx%.1f", n, parts, glow, ext.X, ext.Y, ext.Z))
end
_G.V16PETS = models
_G.V16WALK = false
local RS = game:GetService("RunService")
pcall(function() RS:UnbindFromRenderStep("V16PetAnimX") end)
RS:BindToRenderStep("V16PetAnimX", Enum.RenderPriority.Camera.Value + 50, function(dt)
	local cam = workspace.CurrentCamera
	cam.CameraType = Enum.CameraType.Scriptable
	cam.CFrame = _G.V16CAM or CFrame.lookAt(O + Vector3.new(0, 26, 62), O + Vector3.new(0, 3, 4))
	cam.FieldOfView = 50
	for _, m in _G.V16PETS or {} do local ok, e = pcall(PV.animate, m, os.clock(), dt, _G.V16WALK) if not ok then _G.V16ERR = tostring(e) end end
end)
for _, g in game.Players.LocalPlayer.PlayerGui:GetChildren() do if g:IsA("ScreenGui") then g.Enabled = false end end
return table.concat(out, " | ")
""".replace("NAMES", lst).replace("SCALE", sys.argv[0] and "1.0")
print(C(SETUP))
time.sleep(3)
print(N.shot(f"v16pets_{tag}_idle").name)
C("_G.V16WALK = true return 1"); time.sleep(1.2)
print(N.shot(f"v16pets_{tag}_walk").name)
C("_G.V16WALK = false local PV=require(game.ReplicatedStorage.Shared.PetVoxels) for _,m in _G.V16PETS do PV.hero(m) end task.wait(1.05) return 1")
print(N.shot(f"v16pets_{tag}_hero").name)
C("_G.V16CAM = CFrame.lookAt(Vector3.new(-30, 312, 26), Vector3.new(-40, 302, -2)) return 1"); time.sleep(1.0)
print(N.shot(f"v16pets_{tag}_close").name)
print("errors:", C("return tostring(_G.V16ERR)"))
C("_G.V16CAM = nil game:GetService('RunService'):UnbindFromRenderStep('V16PetAnimX') workspace.V16Pets:Destroy() workspace.CurrentCamera.CameraType=Enum.CameraType.Custom return 1")
