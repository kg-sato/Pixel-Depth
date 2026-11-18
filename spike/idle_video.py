"""Pet idle actions on video (Play running): python spike/idle_video.py <out.mp4> [seconds]
Five crew-size pets in a row play their keyframed idle actions (Shared.PetVoxels) one after another while the window is
recorded (tools/record_window.py); judge with tools/video_judge.py."""
import subprocess, sys, pathlib
import night as N
out, secs = sys.argv[1], sys.argv[2] if len(sys.argv) > 2 else "14"
N.lua('''
local PV = require(game.ReplicatedStorage.Shared.PetVoxels)
local old = workspace:FindFirstChild("PoseLine") if old then old:Destroy() end
local f = Instance.new("Folder") f.Name = "PoseLine" f.Parent = workspace
local O = Vector3.new(3000, 300, 60)
local floor = Instance.new("Part") floor.Anchored = true floor.Size = Vector3.new(90, 1, 30) floor.Position = O - Vector3.new(0, 0.5, 0) floor.Color = Color3.fromRGB(70, 56, 92) floor.Parent = f
local names = { "Glimwisp", "Zharbird", "Kobold", "Kirin", "Fafnir" }
local ms = {}
local now0 = os.clock()
for i, n in names do
	local m = PV.build(n)
	if m then
		m:ScaleTo(2.5)
		m:PivotTo(CFrame.new(O + Vector3.new((i - 3) * 13, 0.92 * 2.5, 0)) * CFrame.Angles(0, math.rad(-30), 0))
		m.Parent = f
		table.insert(ms, m)
		PV.animate(m, now0, 0.016, false)
		PV.rigs[m].nextAct = now0 + 1 + (5 - i) * 2.2
	end
end
local cam = workspace.CurrentCamera
game:GetService("RunService"):BindToRenderStep("PoseLine", Enum.RenderPriority.Camera.Value + 30, function(dt)
	cam.CameraType = Enum.CameraType.Scriptable
	cam.CFrame = CFrame.lookAt(O + Vector3.new(0, 9, -30), O + Vector3.new(0, 4, 0))
	cam.FieldOfView = 55
	game.Lighting.ClockTime = 14 -- hold the light: the town's day cycle cut to night mid-recording
	for _, m in ms do PV.animate(m, os.clock(), dt, false) end
end)
task.delay(''' + str(float(secs) + 4) + ''', function() game:GetService("RunService"):UnbindFromRenderStep("PoseLine") f:Destroy() cam.CameraType = Enum.CameraType.Custom end)
return "ok"''', "Client")
root = pathlib.Path(__file__).resolve().parents[3]
subprocess.run([str(root / "Hunyuan3D/.venv/Scripts/python.exe"), "-I", str(root / "tools/record_window.py"), out, secs, "30"], check=True)
