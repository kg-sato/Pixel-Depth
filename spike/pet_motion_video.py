"""The v16b creature motion and signature VFX of the voxel pets, one pet at a time in one Play session: a 22 s recording per pet
of every state (idle with gaze and breathing, a walk round a circle, a run, a stop, a turn on the spot, a one-sided act, the hero
act) with a following camera, to captures/video/motion_<Name>_<tag>.mp4, plus stills of the idle, the walk and the act.
    python spike/pet_motion_video.py <tag> <Name> [<Name> ...]"""
import pathlib, subprocess, sys, time
here = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(here))
import night as N
tag = sys.argv[1] if len(sys.argv) > 1 else "a"
names = sys.argv[2:] or ["Tosk"]
def C(c): return (N.lua(c, "Client").splitlines() or ["?"])[-1]
N.play(False); N.play(True); time.sleep(12)
SETUP = r"""
local PV = require(game.ReplicatedStorage.Shared.PetVoxels)
local old = workspace:FindFirstChild("VoxPet") if old then old:Destroy() end
local f = Instance.new("Folder") f.Name = "VoxPet" f.Parent = workspace
local O = Vector3.new(0, 300, 0)
local floor = Instance.new("Part") floor.Anchored = true floor.Size = Vector3.new(120, 1, 120) floor.CFrame = CFrame.new(O + Vector3.new(0, -0.5, 0)) floor.Color = Color3.fromRGB(46, 40, 58) floor.Material = Enum.Material.Slate floor.Parent = f
for _, x in { -14, 14 } do local l = Instance.new("PointLight") l.Range = 60 l.Brightness = 1.1 l.Color = Color3.fromRGB(255, 236, 214) local a = Instance.new("Attachment") a.Position = Vector3.new(x, 18, 12) a.Parent = floor l.Parent = a end
local m
local t0 = os.clock()
repeat m = PV.build("NAME") if not m then task.wait(0.2) end until m or os.clock() - t0 > 20
if not m then return "no model" end
m.Parent = f
m:ScaleTo(1.5)
local Y = 0.92 * 1.5
m:PivotTo(CFrame.new(O + Vector3.new(0, Y, 0)) * CFrame.Angles(0, math.rad(200), 0))
_G.VOXPET, _G.VOXT0, _G.VOXERR = m, nil, nil
local RS = game:GetService("RunService")
pcall(function() RS:UnbindFromRenderStep("VoxPetCam8") end)
local yawA, pos, ang = math.rad(200), O, 0
RS:BindToRenderStep("VoxPetCam8", Enum.RenderPriority.Camera.Value + 60, function(dt)
	local T = _G.VOXT0 and os.clock() - _G.VOXT0 or 0
	local R = 11
	-- the script: 0-4 idle, 4-9.5 walk a circle, 9.5-12 run, 12-13 stop, 13-14.6 turn on the spot, 15 an act, 18.5 the hero act
	local v = 0
	if T >= 4 and T < 9.5 then v = 12 elseif T >= 9.5 and T < 12 then v = 27 elseif T >= 12 and T < 12.6 then v = 27 * (1 - (T - 12) / 0.6) end
	if v > 0 then
		ang += v / R * dt
		pos = O + Vector3.new(math.cos(ang) * R - R, 0, math.sin(ang) * R)
		local tan = Vector3.new(-math.sin(ang), 0, math.cos(ang))
		yawA = math.atan2(-tan.X, -tan.Z)
	elseif T >= 13 and T < 14.6 then
		yawA += math.pi / 1.6 * dt
	end
	m:PivotTo(CFrame.new(pos + Vector3.new(0, Y, 0)) * CFrame.Angles(0, yawA, 0))
	local cam = workspace.CurrentCamera
	cam.CameraType = Enum.CameraType.Scriptable
	local a = 0.7 + T * 0.12
	local tgt = pos + Vector3.new(0, 4.4, 0)
	cam.CFrame = CFrame.lookAt(tgt + Vector3.new(math.sin(a) * 19, 4.5, math.cos(a) * 19), tgt)
	cam.FieldOfView = 50
	local ok, e = pcall(PV.animate, m, os.clock(), dt) if not ok and not _G.VOXERR then _G.VOXERR = tostring(e) end
end)
for _, g in game.Players.LocalPlayer.PlayerGui:GetChildren() do if g:IsA("ScreenGui") then g.Enabled = false end end
local n, sig = 0, 0
for _, p in m:GetDescendants() do if p:IsA("BasePart") then n += 1 if p.Name == "Fx_sig" then sig += 1 end end end
local rig = PV.rigs[m]
return string.format("%d parts, %d signature fx parts, %d effects, loco %s", n, sig, rig and rig.sig and #rig.sig.list or -1, tostring(rig and rig.loco))
"""
ACT1 = {"Tosk": "stomp", "Kobold": "armflex", "Kepri Scarab": "hop", "Shinemane": "rear", "Goldbristle": "stretch", "Pixiu": "roar",
        "Glimwisp": "tailfan", "Selkie": "roar", "Zharbird": "preen", "Fafnir": "roar", "Kirin": "rear", "Ouro": "sway", "Ninering": "spin"}
out = N.root / "Games" / "Pixel Depth" / "captures" / "video"; out.mkdir(parents=True, exist_ok=True)
for name in names:
    print(name, C(SETUP.replace("NAME", name)))
    mp4 = out / f"motion_{name.replace(' ', '')}_{tag}.mp4"
    N.restore(); time.sleep(1.0)  # a minimised or covered Studio records a frozen frame
    rec = subprocess.Popen([str(N.root / "Hunyuan3D" / ".venv" / "Scripts" / "python.exe"), "-I", str(N.root / "tools" / "record_window.py"), str(mp4), "22", "30"], stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    time.sleep(1.2)
    C("_G.VOXT0 = os.clock() return 1")
    time.sleep(2.5); print(N.shot(f"motion_{tag}_{name.replace(' ', '')}_idle").name)
    time.sleep(4.0); print(N.shot(f"motion_{tag}_{name.replace(' ', '')}_walk").name)
    time.sleep(8.5)
    C(f"local PV=require(game.ReplicatedStorage.Shared.PetVoxels) local r=PV.rigs[_G.VOXPET] r.act, r.actT, r.burst, r.hit = '{ACT1.get(name, 'look')}', os.clock(), false, false return 1")
    time.sleep(1.0); print(N.shot(f"motion_{tag}_{name.replace(' ', '')}_act").name)
    time.sleep(2.5)
    C("local PV=require(game.ReplicatedStorage.Shared.PetVoxels) PV.hero(_G.VOXPET) return 1")
    print("recorder:", (rec.communicate(timeout=90)[0] or "").strip()[-160:])
    print("errors:", C("return tostring(_G.VOXERR)"))
    C("game:GetService('RunService'):UnbindFromRenderStep('VoxPetCam8') workspace.VoxPet:Destroy() return 1")
    print(mp4)
C("workspace.CurrentCamera.CameraType=Enum.CameraType.Custom return 1")
N.play(False)
