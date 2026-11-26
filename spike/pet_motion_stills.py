"""The v16b creature motion and signature VFX of the voxel pets, in slow motion as stills (record_window.py freezes while the
display sleeps). Per pet a 15.5 s script runs on a slowed clock (x0.06 while walking and running, x0.15 otherwise) and MCP stills
are taken back to back (about 1.3 s each), labelled with the script time and state: idle 0-3 (gaze, breathing), walk a circle
3-6, run 6-8, stop 8-8.6, turn on the spot 8.6-10, a one-sided act at 10.2, the hero act at 13.
    python spike/pet_motion_stills.py <tag> <Name> [<Name> ...]
Stills: captures/motion/<tag>_<Name>/ with labels.txt; sheets: <workspace>/Overnight/judge/motion_<tag>_<Name>/"""
import pathlib, subprocess, sys, time
here = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(here))
import night as N
tag = sys.argv[1] if len(sys.argv) > 1 else "a"
names = sys.argv[2:] or ["Tosk"]
def C(c): return (N.lua(c, "Client").splitlines() or ["?"])[-1]
ACT1 = {"Tosk": "stomp", "Kobold": "armflex", "Kepri Scarab": "hop", "Shinemane": "rear", "Goldbristle": "stretch", "Pixiu": "roar",
        "Glimwisp": "tailfan", "Selkie": "roar", "Zharbird": "preen", "Fafnir": "roar", "Kirin": "rear", "Ouro": "sway", "Ninering": "spin"}
SETUP = r"""
local PV = require(game.ReplicatedStorage.Shared.PetVoxels)
local old = workspace:FindFirstChild("VoxPet") if old then old:Destroy() end
local f = Instance.new("Folder") f.Name = "VoxPet" f.Parent = workspace
local O = Vector3.new(0, 300, 0)
local floor = Instance.new("Part") floor.Anchored = true floor.Size = Vector3.new(120, 1, 120) floor.CFrame = CFrame.new(O + Vector3.new(0, -0.5, 0)) floor.Color = Color3.fromRGB(62, 56, 76) floor.Material = Enum.Material.Slate floor.Parent = f
game.Lighting.ClockTime = 14.5 game.Lighting.Brightness = 2.2 game.Lighting.ExposureCompensation = 0.3 -- daylight for the stills (Play only)
for _, x in { -14, 14 } do local l = Instance.new("PointLight") l.Range = 60 l.Brightness = 1.6 l.Color = Color3.fromRGB(255, 236, 214) local a = Instance.new("Attachment") a.Position = Vector3.new(x, 18, 12) a.Parent = floor l.Parent = a end
local m
local t0 = os.clock()
repeat m = PV.build("NAME") if not m then task.wait(0.2) end until m or os.clock() - t0 > 20
if not m then return "no model" end
m.Parent = f
m:ScaleTo(1.5)
local Y = 0.92 * 1.5
local yawA, pos, ang = math.rad(200), O, 0
m:PivotTo(CFrame.new(O + Vector3.new(0, Y, 0)) * CFrame.Angles(0, yawA, 0))
_G.VOXPET, _G.VOXT, _G.VOXRUN, _G.VOXERR, _G.VOXSTATE = m, 0, false, nil, "idle"
local base = os.clock()
local acted, heroed = false, false
local RS = game:GetService("RunService")
pcall(function() RS:UnbindFromRenderStep("VoxPetCam9") end)
local function simStep(dt)
	local T = _G.VOXT + dt
	_G.VOXT = T
	local now = base + T
	local R = 11
	local v, st = 0, "idle"
	if T >= 2 and T < 4.2 then v, st = 12, "walk" elseif T >= 4.2 and T < 5.8 then v, st = 27, "run" elseif T >= 5.8 and T < 6.4 then v, st = 27 * (1 - (T - 5.8) / 0.6), "stop" end
	if v > 0 then
		ang += v / R * dt
		pos = O + Vector3.new(math.cos(ang) * R - R, 0, math.sin(ang) * R)
		local tan = Vector3.new(-math.sin(ang), 0, math.cos(ang))
		yawA = math.atan2(-tan.X, -tan.Z)
	elseif T >= 6.4 and T < 7.6 then
		yawA += math.pi / 1.2 * dt
		st = "turn on the spot"
	end
	local rig = PV.rigs[m]
	if T >= 7.8 and not acted and rig then acted = true rig.act, rig.actT, rig.burst, rig.hit = "ACT1", now, false, false end
	if T >= 10.6 and not heroed and rig then heroed = true rig.act, rig.actT, rig.burst, rig.hit = "hero", now, false, false end
	if T >= 7.8 then st = T >= 10.6 and "hero act" or "act ACT1" end
	_G.VOXSTATE = st
	m:PivotTo(CFrame.new(pos + Vector3.new(0, Y, 0)) * CFrame.Angles(0, yawA, 0))
	local ok, e = pcall(PV.animate, m, now, dt) if not ok and not _G.VOXERR then _G.VOXERR = tostring(e) end
end
_G.VOXADV = 0
local function placeCam()
	local cam = workspace.CurrentCamera
	cam.CameraType = Enum.CameraType.Scriptable
	local a = 0.7 + _G.VOXT * 0.3
	local tgt = pos + Vector3.new(0, 4.4, 0)
	cam.CFrame = CFrame.lookAt(tgt + Vector3.new(math.sin(a) * 15, 3.5, math.cos(a) * 15), tgt)
	cam.FieldOfView = 50
end
RS:BindToRenderStep("VoxPetCam9", Enum.RenderPriority.Camera.Value + 60, function()
	placeCam() -- first: the pet's effects and gaze read the camera while it steps (the game's camera script moves it every frame)
	local adv = _G.VOXADV
	if adv > 0 then -- advance the script by exactly this much, in 60 Hz steps, then hold still for the capture
		_G.VOXADV = 0
		local n = math.max(1, math.ceil(adv * 60 - 1e-6))
		for _ = 1, n do simStep(adv / n) placeCam() end
	end
end)
for _, g in game.Players.LocalPlayer.PlayerGui:GetChildren() do if g:IsA("ScreenGui") then g.Enabled = false end end
return "ready"
"""
N.play(False); N.play(True); time.sleep(12)
for name in names:
    print(name, C(SETUP.replace("NAME", name).replace("ACT1", ACT1.get(name, "look"))))
    key = f"{tag}_{name.replace(' ', '')}"
    outdir = N.game / "captures" / "motion" / key
    outdir.mkdir(parents=True, exist_ok=True)
    for old in outdir.glob("*.png"): old.unlink()
    labels = open(outdir / "labels.txt", "w", encoding="utf-8")
    i, T = 0, 0.0
    while T < 12.3:
        d = 0.12 if 2 <= T < 6.4 else 0.25  # finer through the walk, run and stop
        r = C(f"_G.VOXADV = {d} return 1")
        time.sleep(0.15)
        for _ in range(6):  # an MCP call can come back empty now and then: ask again
            r = C("return string.format('%.2f|%s', _G.VOXT, _G.VOXSTATE)")
            if "|" in r: break
            time.sleep(2)
        try:
            T, st = r.split("|", 1); T = float(T)
        except Exception:
            print("bad", r); break
        dst = outdir / f"{i:04d}.png"
        try:
            pathlib.Path(N.shot("_mstill")).replace(dst)
        except Exception as e:
            print("shot failed", T, e); continue
        labels.write(f"{dst.name}\t{T:.2f}\t{st}\n"); labels.flush()
        i += 1
    labels.close()
    print("stills", i, "errors:", C("return tostring(_G.VOXERR)"))
    C("game:GetService('RunService'):UnbindFromRenderStep('VoxPetCam9') workspace.VoxPet:Destroy() _G.VOXRUN = false return 1")
    sheets = N.root / "Overnight" / "judge" / f"motion_{key}"
    subprocess.run([str(N.root / "Hunyuan3D" / ".venv" / "Scripts" / "python.exe"), "-I", str(here / "stills_sheets.py"), str(outdir), str(sheets)])
    print(sheets)
C("workspace.CurrentCamera.CameraType=Enum.CameraType.Custom return 1")
N.play(False)
