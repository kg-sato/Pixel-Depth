"""The showcase opening of the full playthrough video (the owner, 2026-11-25: "record a full playthrough pc ver only ... Showcase
all the features in the game aswell as models and terrain"): a fly-over of the town and its terrain, then every pet in
rarity order, each idling, walking a circle, doing its own act and its hero act, with its signature effects, captioned
with its name and rarity. Runs in Play, in real time, driven by one client script (no MCP calls while it records).
    python spike/showcase_rec.py <out.mp4>
Studio open on the place; the display is woken first (record_window.py froze on one frame while it slept)."""
import ctypes, pathlib, subprocess, sys, time
here = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(here))
import night as N
out = pathlib.Path(sys.argv[1]); out.parent.mkdir(parents=True, exist_ok=True)
VENV = str(N.root / "Hunyuan3D" / ".venv" / "Scripts" / "python.exe")
ORDER = ["Tosk", "Kobold", "Kepri Scarab", "Shinemane", "Goldbristle", "Pixiu", "Glimwisp", "Selkie", "Zharbird", "Fafnir", "Kirin", "Ouro", "Ninering"]
ACT1 = {"Tosk": "stomp", "Kobold": "armflex", "Kepri Scarab": "hop", "Shinemane": "rear", "Goldbristle": "stretch", "Pixiu": "roar",
        "Glimwisp": "tailfan", "Selkie": "roar", "Zharbird": "preen", "Fafnir": "roar", "Kirin": "rear", "Ouro": "sway", "Ninering": "spin"}
FLY, PER = 30.0, 9.0
SECS = FLY + PER * len(ORDER) + 4


def C(code): return (N.lua(code, "Client").splitlines() or ["?"])[-1]


def wake():  # a 1-pixel mouse nudge wakes a sleeping display; then keep it on while this process lives
    u = ctypes.windll.user32
    u.mouse_event(0x0001, 1, 0, 0, 0); time.sleep(0.05); u.mouse_event(0x0001, -1, 0, 0, 0)
    ctypes.windll.kernel32.SetThreadExecutionState(0x80000000 | 0x00000002 | 0x00000001)


PREP = r"""
local PV = require(game.ReplicatedStorage.Shared.PetVoxels)
local hold = game.ReplicatedStorage:FindFirstChild("ShowPets") or Instance.new("Folder")
hold.Name = "ShowPets" hold.Parent = game.ReplicatedStorage
for _, n in { NAMES } do
	if not hold:FindFirstChild(n) then
		local m local t0 = os.clock()
		repeat m = PV.build(n) if not m then task.wait(0.2) end until m or os.clock() - t0 > 20
		if m then m.Parent = hold m:ScaleTo(1.5) end
	end
end
return #hold:GetChildren()
"""
RUN = r"""
local RS = game:GetService("RunService")
local PV = require(game.ReplicatedStorage.Shared.PetVoxels)
local p = game.Players.LocalPlayer
local cam = workspace.CurrentCamera
local hold = game.ReplicatedStorage.ShowPets
for _, g in p.PlayerGui:GetChildren() do if g:IsA("ScreenGui") then g.Enabled = false end end
p:SetAttribute("HidePetsUntil", os.clock() + 600)
local hrp = p.Character.HumanoidRootPart
local spawnAt = hrp.Position
-- an open flat spot near the spawn for the pets (nothing that collides in a 26 x 10 x 26 box above it)
local rp = RaycastParams.new() rp.FilterType = Enum.RaycastFilterType.Exclude rp.FilterDescendantsInstances = { p.Character }
local op = OverlapParams.new() op.RespectCanCollide = true op.FilterType = Enum.RaycastFilterType.Exclude op.FilterDescendantsInstances = { p.Character }
local stage
for r = 0, 90, 6 do
	for a = 0, 330, 30 do
		local x = spawnAt + Vector3.new(math.cos(math.rad(a)) * r, 0, math.sin(math.rad(a)) * r)
		local hit = workspace:Raycast(x + Vector3.new(0, 40, 0), Vector3.new(0, -90, 0), rp)
		if hit and hit.Normal.Y > 0.97 and #workspace:GetPartBoundsInBox(CFrame.new(hit.Position + Vector3.new(0, 5.5, 0)), Vector3.new(26, 10, 26), op) == 0 then stage = hit.Position break end
	end
	if stage then break end
end
stage = stage or (spawnAt - Vector3.new(0, 3, 0))
hrp.Anchored = true hrp.CFrame = CFrame.new(stage + Vector3.new(60, 4, 60)) -- the miner steps out of shot
local cap = Instance.new("ScreenGui") cap.Name = "ShowCap" cap.IgnoreGuiInset = true cap.DisplayOrder = 50 cap.Parent = p.PlayerGui
local lab = Instance.new("TextLabel") lab.Parent = cap lab.BackgroundTransparency = 0.35 lab.BackgroundColor3 = Color3.fromRGB(18, 16, 30)
lab.Size = UDim2.fromScale(0.36, 0.07) lab.Position = UDim2.fromScale(0.32, 0.86) lab.TextScaled = true lab.Font = Enum.Font.GothamBold lab.TextColor3 = Color3.new(1, 1, 1)
Instance.new("UICorner", lab).CornerRadius = UDim.new(0.3, 0)
local pad = Instance.new("UIPadding", lab) pad.PaddingTop = UDim.new(0.15, 0) pad.PaddingBottom = UDim.new(0.15, 0)
local RCOL = { Common = Color3.fromRGB(200, 205, 215), Rare = Color3.fromRGB(110, 190, 255), Epic = Color3.fromRGB(200, 120, 255), Legendary = Color3.fromRGB(255, 200, 70), Mythic = Color3.fromRGB(255, 110, 180), Secret = Color3.fromRGB(150, 255, 240) }
local Cfg = require(game.ReplicatedStorage.Shared.Config)
local function caption(t, col) lab.Text = t lab.TextColor3 = col or Color3.new(1, 1, 1) end
_G.SHOW = "fly"
task.spawn(function()
	-- 1. the town and its terrain from the air: a high orbit, then a lower sweep
	caption("Pixel Depth  ·  the town")
	local t0 = os.clock()
	local C0 = Vector3.new(0, 6, 0)
	RS:BindToRenderStep("ShowCam", 2001, function()
		local u = os.clock() - t0
		cam.CameraType = Enum.CameraType.Scriptable
		if u < FLY * 0.55 then
			local a = 0.6 + u / (FLY * 0.55) * math.pi * 1.1
			cam.CFrame = CFrame.lookAt(C0 + Vector3.new(math.cos(a) * 110, 62 - u * 0.8, math.sin(a) * 110), C0)
		else
			local k = (u - FLY * 0.55) / (FLY * 0.45)
			local a = 0.6 + math.pi * 1.1 + k * 1.2
			cam.CFrame = CFrame.lookAt(C0 + Vector3.new(math.cos(a) * (70 - 25 * k), 30 - 8 * k, math.sin(a) * (70 - 25 * k)), C0 + Vector3.new(0, 4, 0))
		end
	end)
	task.wait(FLY)
	RS:UnbindFromRenderStep("ShowCam")
	-- 2. the pets in rarity order
	for _, n in { NAMES } do
		local m = hold:FindFirstChild(n)
		if m then
			_G.SHOW = n
			local rar = Cfg.PETS[n] and Cfg.PETS[n][1] or ""
			caption(n .. "  ·  " .. rar, RCOL[rar])
			m.Parent = workspace
			local ext = m:GetExtentsSize()
			local Y = 0.92 * 1.5
			local R = 7
			local pos, yawA, ang = stage, math.rad(200), 0
			local T, base = 0, os.clock()
			local acted, heroed = false, false
			local dist = 10 + math.max(ext.X, ext.Y, ext.Z) * 1.15
			m:PivotTo(CFrame.new(stage + Vector3.new(0, Y, 0)) * CFrame.Angles(0, yawA, 0))
			RS:BindToRenderStep("ShowPet", 2001, function(dt)
				dt = math.min(dt, 1 / 20)
				T += dt
				local now = base + T
				local v = 0
				if T >= 1.3 and T < 3.6 then v = 11 elseif T >= 3.6 and T < 4.0 then v = 11 * (1 - (T - 3.6) / 0.4) end
				if v > 0 then
					ang += v / R * dt
					pos = stage + Vector3.new(math.cos(ang) * R - R, 0, math.sin(ang) * R)
					local tan = Vector3.new(-math.sin(ang), 0, math.cos(ang))
					yawA = math.atan2(-tan.X, -tan.Z)
				end
				local rig = PV.rigs[m]
				if T >= 4.2 and not acted and rig then acted = true rig.act, rig.actT, rig.burst, rig.hit, rig.actSide = "ACTN", now, false, false, nil end
				if T >= 6.4 and not heroed and rig then heroed = true rig.act, rig.actT, rig.burst, rig.hit, rig.actSide = "hero", now, false, false, nil end
				m:PivotTo(CFrame.new(pos + Vector3.new(0, Y, 0)) * CFrame.Angles(0, yawA, 0))
				pcall(PV.animate, m, now, dt)
				local a = 0.5 + T * 0.22
				local tgt = stage + Vector3.new(-R * 0.4, ext.Y * 0.45, 0)
				cam.CameraType = Enum.CameraType.Scriptable
				cam.CFrame = CFrame.lookAt(tgt + Vector3.new(math.sin(a) * dist, ext.Y * 0.35 + 3, math.cos(a) * dist), tgt)
				cam.FieldOfView = 55
			end)
			task.wait(PER)
			RS:UnbindFromRenderStep("ShowPet")
			m.Parent = hold
		end
	end
	cap:Destroy()
	hrp.Anchored = false
	cam.CameraType = Enum.CameraType.Custom cam.FieldOfView = 70
	_G.SHOW = "done"
end)
return "started"
"""


def main():
    names = ", ".join(f'"{n}"' for n in ORDER)
    N.play(False); time.sleep(1); N.play(True); time.sleep(8)
    print("prebuilt:", C(PREP.replace("NAMES", names)))
    C('local p=game.Players.LocalPlayer p:SetAttribute("DevNoIntro",true) for _,g in p.PlayerGui:GetChildren() do if g:IsA("ScreenGui") then g.Enabled=false end end return 1')
    N.restore(); wake(); time.sleep(1)
    if out.exists(): out.unlink()
    rec = subprocess.Popen([VENV, "-I", str(N.root / "tools" / "record_window.py"), str(out), str(SECS), "20"], stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    time.sleep(1.0)
    code = RUN.replace("NAMES", names).replace("FLY", repr(FLY)).replace("PER", repr(PER)).replace('"ACTN"', "ACT1[n] or \"look\"")
    code = "local ACT1 = {" + ", ".join(f'["{k}"] = "{v}"' for k, v in ACT1.items()) + "}\n" + code
    print(C(code), flush=True)
    t0 = time.time()
    while time.time() - t0 < SECS + 5:
        time.sleep(10); print(f"{time.time() - t0:4.0f} s", C("return tostring(_G.SHOW)"), flush=True)
        if C("return tostring(_G.SHOW)") == "done": break
    print((rec.communicate(timeout=600)[0] or "").strip().splitlines()[-2:])
    print("client errors:", C("local t={} for _,m in game:GetService('LogService'):GetLogHistory() do if m.messageType==Enum.MessageType.MessageError then t[string.sub(m.message,1,140)]=true end end local e={} for k in t do table.insert(e,k) end return #e..' '..table.concat(e,' | ')"))
    N.play(False)


main()
