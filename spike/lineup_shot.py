"""All 13 voxel pets in a row on a plain stage in Play, for grading models in game light: python spike/lineup_shot.py <name>"""
import sys, time
import night as N
SC = float(sys.argv[2]) if len(sys.argv) > 2 else 1  # pet scale (Config.PET_SCALE is 2.5)
N.lua(f'''
local PV = require(game.ReplicatedStorage.Shared.PetVoxels)
local old = workspace:FindFirstChild("PetLineup") if old then old:Destroy() end
local f = Instance.new("Folder") f.Name = "PetLineup" f.Parent = workspace
local O = Vector3.new(3000, 300, 0)
local floor = Instance.new("Part") floor.Anchored = true floor.Size = Vector3.new(60, 1, 14) floor.Position = O - Vector3.new(0, 0.5, 0) floor.Color = Color3.fromRGB(70, 56, 92) floor.Parent = f
local names = {{ "Tosk", "Kobold", "Kepri Scarab", "Shinemane", "Goldbristle", "Pixiu", "Glimwisp", "Selkie", "Zharbird", "Fafnir", "Kirin", "Ouro", "Ninering" }}
for i, n in names do
	local m = PV.build(n)
	if m then
		local row, col = (i - 1) // 7, (i - 1) % 7
		m:ScaleTo({SC}) m:PivotTo(CFrame.new(O + Vector3.new((col - 3) * 3.4 * {SC} + row * 1.7 * {SC}, 0.92 * {SC}, row * 4 * {SC})) * CFrame.Angles(0, math.rad(-25), 0))
		m.Parent = f
	end
end
local cam = workspace.CurrentCamera
game:GetService("RunService"):BindToRenderStep("PetLineup", Enum.RenderPriority.Camera.Value + 30, function(dt)
	cam.CameraType = Enum.CameraType.Scriptable
	cam.CFrame = CFrame.lookAt(O + Vector3.new(0, 4.5, -13) * {SC}, O + Vector3.new(0, 1.2, 1.5) * {SC})
	cam.FieldOfView = 45
	for _, m in f:GetChildren() do if m:IsA("Model") then PV.animate(m, os.clock(), dt, false) end end
end)
return "ok"''', "Client")
time.sleep(2)
N.shot(sys.argv[1])
N.lua('game:GetService("RunService"):UnbindFromRenderStep("PetLineup") local f = workspace:FindFirstChild("PetLineup") if f then f:Destroy() end workspace.CurrentCamera.CameraType = Enum.CameraType.Custom return "ok"', "Client")
