"""Master Directive v15: rare and better pets with glowing seams and back props, and the two-beat hero act.
Builds every pet on the client in a row on a dark stage above the town (client only), checks each builds, counts its seam
pieces, plays the hero act on all of them and takes stills: the idle lineup, beat 1 (gather) and beat 2 (rear-up roar).
    python spike/v15_pets.py <tag>   -> captures/night/v15pets_<tag>_<view>.png"""
import pathlib, sys, time
here = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(here))
import night as N
tag = sys.argv[1] if len(sys.argv) > 1 else "a"
def C(c): return (N.lua(c, "Client").splitlines() or ["?"])[-1]
N.play(False); N.play(True); time.sleep(10)
SETUP = r"""
local PV = require(game.ReplicatedStorage.Shared.PetVoxels)
local names = { "Shinemane", "Goldbristle", "Pixiu", "Fafnir", "Kirin", "Ouro", "Ninering", "Kobold" }
local old = workspace:FindFirstChild("V15Pets") if old then old:Destroy() end
local f = Instance.new("Folder") f.Name = "V15Pets" f.Parent = workspace
local O = Vector3.new(0, 300, 0)
local floor = Instance.new("Part") floor.Anchored = true floor.Size = Vector3.new(60, 1, 20) floor.CFrame = CFrame.new(O + Vector3.new(0, -0.5, 0)) floor.Color = Color3.fromRGB(46, 36, 66) floor.Material = Enum.Material.Slate floor.Parent = f
local back = Instance.new("Part") back.Anchored = true back.Size = Vector3.new(60, 30, 1) back.CFrame = CFrame.new(O + Vector3.new(0, 10, -8)) back.Color = Color3.fromRGB(24, 18, 40) back.Parent = f
local lamp = Instance.new("PointLight") lamp.Range = 40 lamp.Brightness = 0.8 lamp.Color = Color3.fromRGB(255, 230, 200) lamp.Parent = floor
local out, models = {}, {}
for i, n in names do
	local t0 = os.clock()
	local m
	repeat m = PV.build(n) if not m then task.wait(0.2) end until m or os.clock() - t0 > 15
	if not m then table.insert(out, n .. ": no model") continue end
	local seams = 0
	for _, p in m:GetChildren() do if p.Name == "Body_Seam" then seams += 1 end end
	m.Parent = f
	m:ScaleTo(1.6)
	m:PivotTo(CFrame.new(O + Vector3.new(-24.5 + (i - 1) * 7, 0.92 * 1.6, 0)) * CFrame.Angles(0, math.rad(200), 0))
	table.insert(models, m)
	table.insert(out, n .. ": " .. seams .. " seam pieces, " .. #m:GetDescendants() .. " parts")
end
_G.V15PETS = models
local RS = game:GetService("RunService")
pcall(function() RS:UnbindFromRenderStep("V15PetAnim") end)
RS:BindToRenderStep("V15PetAnim", Enum.RenderPriority.Camera.Value + 50, function(dt)
	local cam = workspace.CurrentCamera
	cam.CameraType = Enum.CameraType.Scriptable
	cam.CFrame = CFrame.lookAt(O + Vector3.new(0, 6, 26), O + Vector3.new(0, 2.2, 0))
	cam.FieldOfView = 55
	for _, m in _G.V15PETS or {} do local ok, e = pcall(PV.animate, m, os.clock(), dt, false) if not ok then _G.V15ERR = tostring(e) end end
end)
for _, g in game.Players.LocalPlayer.PlayerGui:GetChildren() do if g:IsA("ScreenGui") then g.Enabled = false end end
return table.concat(out, " | ")
"""
print(C(SETUP))
time.sleep(2.5)
print(N.shot(f"v15pets_{tag}_idle").name)
C("local PV=require(game.ReplicatedStorage.Shared.PetVoxels) for _,m in _G.V15PETS do PV.hero(m) end return 1")
time.sleep(0.25)
print(N.shot(f"v15pets_{tag}_gather").name)
C("local PV=require(game.ReplicatedStorage.Shared.PetVoxels) for _,m in _G.V15PETS do PV.hero(m) end task.wait(1.05) return 1")
print(N.shot(f"v15pets_{tag}_rear").name)
print("errors:", C("return tostring(_G.V15ERR)"))
C("game:GetService('RunService'):UnbindFromRenderStep('V15PetAnim') workspace.V15Pets:Destroy() workspace.CurrentCamera.CameraType=Enum.CameraType.Custom return 1")
