"""Pets held mid idle-action for a still (Play running): python spike/pose_shot.py <name> [u]
Each pet plays one keyframed action from Shared.PetVoxels held at fraction u (default 0.5), at the crew size 2.5."""
import sys, time
import night as N
U = float(sys.argv[2]) if len(sys.argv) > 2 else 0.5
N.lua(f'''
local PV = require(game.ReplicatedStorage.Shared.PetVoxels)
local old = workspace:FindFirstChild("PoseLine") if old then old:Destroy() end
local f = Instance.new("Folder") f.Name = "PoseLine" f.Parent = workspace
local O = Vector3.new(3000, 300, 60)
local floor = Instance.new("Part") floor.Anchored = true floor.Size = Vector3.new(90, 1, 30) floor.Position = O - Vector3.new(0, 0.5, 0) floor.Color = Color3.fromRGB(70, 56, 92) floor.Parent = f
local set = {{ {{"Fafnir", "roar"}}, {{"Kirin", "rear"}}, {{"Kobold", "armflex"}}, {{"Zharbird", "flap"}}, {{"Glimwisp", "tailfan"}} }}
local ms = {{}}
for i, e in set do
	local m = PV.build(e[1])
	if m then
		m:ScaleTo(2.5)
		m:PivotTo(CFrame.new(O + Vector3.new((i - 3) * 13, 0.92 * 2.5, 0)) * CFrame.Angles(0, math.rad(-30), 0))
		m.Parent = f
		table.insert(ms, {{ m, e[2] }})
	end
end
local cam = workspace.CurrentCamera
local durs = {{ roar = 1.7, rear = 1.6, armflex = 1.6, flap = 1.5, tailfan = 1.8 }}
game:GetService("RunService"):BindToRenderStep("PoseLine", Enum.RenderPriority.Camera.Value + 30, function(dt)
	cam.CameraType = Enum.CameraType.Scriptable
	cam.CFrame = CFrame.lookAt(O + Vector3.new(0, 14, -42), O + Vector3.new(0, 4, 0))
	cam.FieldOfView = 50
	local now = os.clock()
	for _, x in ms do
		local rig = PV.rigs[x[1]]
		if rig then rig.act, rig.actT, rig.burst = x[2], now - {U} * durs[x[2]], true end
		PV.animate(x[1], now, dt, false)
	end
end)
return "ok"''', "Client")
time.sleep(2.5)
N.shot(sys.argv[1])
N.lua('game:GetService("RunService"):UnbindFromRenderStep("PoseLine") local f = workspace:FindFirstChild("PoseLine") if f then f:Destroy() end workspace.CurrentCamera.CameraType = Enum.CameraType.Custom return "ok"', "Client")
