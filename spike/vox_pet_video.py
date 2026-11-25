"""One v16 voxel pet in the game, close up: a slow orbiting camera, idle then walk on the spot then the hero act, recorded to
captures/video/vox_<Name>_<tag>.mp4 with stills, to check the animated VFX (orbit motes, pulsing glow, particles).
    python spike/vox_pet_video.py <Name> <tag>"""
import pathlib, subprocess, sys, time
here = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(here))
import night as N
name = sys.argv[1] if len(sys.argv) > 1 else "Tosk"
tag = sys.argv[2] if len(sys.argv) > 2 else "a"
def C(c): return (N.lua(c, "Client").splitlines() or ["?"])[-1]
N.play(False); N.play(True); time.sleep(12)
SETUP = r"""
local PV = require(game.ReplicatedStorage.Shared.PetVoxels)
local old = workspace:FindFirstChild("VoxPet") if old then old:Destroy() end
local f = Instance.new("Folder") f.Name = "VoxPet" f.Parent = workspace
local O = Vector3.new(0, 300, 0)
local floor = Instance.new("Part") floor.Anchored = true floor.Size = Vector3.new(80, 1, 80) floor.CFrame = CFrame.new(O + Vector3.new(0, -0.5, 0)) floor.Color = Color3.fromRGB(46, 40, 58) floor.Material = Enum.Material.Slate floor.Parent = f
for _, x in { -14, 14 } do local l = Instance.new("PointLight") l.Range = 40 l.Brightness = 1.1 l.Color = Color3.fromRGB(255, 236, 214) local a = Instance.new("Attachment") a.Position = Vector3.new(x, 16, 12) a.Parent = floor l.Parent = a end
local m
local t0 = os.clock()
repeat m = PV.build("NAME") if not m then task.wait(0.2) end until m or os.clock() - t0 > 20
if not m then return "no model" end
m.Parent = f
m:ScaleTo(1.5)
m:PivotTo(CFrame.new(O + Vector3.new(0, 0.92 * 1.5, 0)) * CFrame.Angles(0, math.rad(200), 0))
_G.VOXPET, _G.VOXWALK, _G.VOXA = m, false, 0
local RS = game:GetService("RunService")
pcall(function() RS:UnbindFromRenderStep("VoxPetCam7") end)
RS:BindToRenderStep("VoxPetCam7", Enum.RenderPriority.Camera.Value + 60, function(dt)
	_G.VOXA += dt * 0.18
	local cam = workspace.CurrentCamera
	cam.CameraType = Enum.CameraType.Scriptable
	local a = 0.6 + _G.VOXA
	cam.CFrame = CFrame.lookAt(O + Vector3.new(math.sin(a) * 17, 7.5, math.cos(a) * 17), O + Vector3.new(0, 4.2, 0))
	cam.FieldOfView = 50
	local ok, e = pcall(PV.animate, m, os.clock(), dt, _G.VOXWALK) if not ok then _G.VOXERR = tostring(e) end
end)
for _, g in game.Players.LocalPlayer.PlayerGui:GetChildren() do if g:IsA("ScreenGui") then g.Enabled = false end end
local n, glow, motes = 0, 0, 0
for _, p in m:GetDescendants() do if p:IsA("BasePart") then n += 1 if p.Material == Enum.Material.Neon then glow += 1 end if p.Name == "Fx_mote" then motes += 1 end end end
local em = 0 for _, e in m:GetDescendants() do if e:IsA("ParticleEmitter") then em += 1 end end
return string.format("%d parts, %d neon, %d orbit motes, %d emitters", n, glow, motes, em)
""".replace("NAME", name)
print(C(SETUP))
out = N.root / "Games" / "Pixel Depth" / "captures" / "video"; out.mkdir(parents=True, exist_ok=True)
mp4 = out / f"vox_{name.replace(' ', '')}_{tag}.mp4"
rec = subprocess.Popen([str(N.root / "Hunyuan3D" / ".venv" / "Scripts" / "python.exe"), "-I", str(N.root / "tools" / "record_window.py"), str(mp4), "12", "30"], stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
time.sleep(1.5)
print(N.shot(f"vox_{tag}_idle").name)
time.sleep(2.5)
C("_G.VOXWALK = true return 1"); time.sleep(3)
C("_G.VOXWALK = false local PV=require(game.ReplicatedStorage.Shared.PetVoxels) PV.hero(_G.VOXPET) return 1"); time.sleep(1.0)
print(N.shot(f"vox_{tag}_hero").name)
print("recorder:", (rec.communicate(timeout=60)[0] or "").strip()[-200:])
print("errors:", C("return tostring(_G.VOXERR)"))
C("game:GetService('RunService'):UnbindFromRenderStep('VoxPetCam7') workspace.VoxPet:Destroy() workspace.CurrentCamera.CameraType=Enum.CameraType.Custom return 1")
N.play(False)
print(mp4)
