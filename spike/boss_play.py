"""Root Warden play test (Play running): ride down, hold the Rootheart (DevEquip 6), stand before the Warden, challenge it
(DevBoss), strike each knot perfectly through the real remote, take the first slam and jump the second, and capture the beats.
    python "Games/Pixel Depth/spike/boss_play.py" <prefix>     captures go to captures/phase9/<prefix>_*.png"""
import json, os, subprocess, sys, time
root = r"C:\Users\kgsat\Documents\Roblox"
out = os.path.join(root, "Games", "Pixel Depth", "captures", "phase9"); os.makedirs(out, exist_ok=True)
pre = sys.argv[1] if len(sys.argv) > 1 else "b1"
def run(tool, args, shot=None):
    env = dict(os.environ)
    if shot: env["STUDIO_SHOT"] = shot
    r = subprocess.run([sys.executable, os.path.join(root, "tools", "studio_live.py"), tool, json.dumps(args)], capture_output=True, text=True, cwd=root, env=env, encoding="utf-8")
    return ((r.stdout or "") + (r.stderr or "")).strip().splitlines()[-1:] or [""]
def lua(code, where="Server"): return run("execute_luau", {"code": code, "datamodel_type": where})[0]
def shot(name): run("screen_capture", {"capture_id": name}, shot=os.path.join(out, f"{pre}_{name}.png"))
STATE = 'local p=game.Players:GetPlayers()[1] return "hp "..tostring(p:GetAttribute("HP")).." gate "..tostring(p:GetAttribute("GateTest"))'

if "true" not in lua('return tostring(game.Players:GetPlayers()[1]:GetAttribute("InCave"))'):
    lua('game.ReplicatedStorage.Remotes.Surface:FireServer("down") return 1', "Client"); time.sleep(13)
lua('local p=game.Players:GetPlayers()[1] p:SetAttribute("DevEquip", 6) local b=workspace.Caves:FindFirstChild("WardenBody",true) '
    'local at=b.Position+Vector3.new(10,0,0) p.Character.HumanoidRootPart.CFrame=CFrame.lookAt(Vector3.new(at.X,3,at.Z), Vector3.new(b.Position.X,3,b.Position.Z)) return 1')
time.sleep(1.5)
# the camera looks at the Warden for the whole fight (the first-person camera would face anywhere)
lua('''local RS=game:GetService("RunService") local cam=workspace.CurrentCamera local b=workspace.Caves:FindFirstChild("WardenBody",true)
pcall(function() RS:UnbindFromRenderStep("ClaudeCam") end)
RS:BindToRenderStep("ClaudeCam", Enum.RenderPriority.Camera.Value+40, function() local h=game.Players.LocalPlayer.Character.Head
cam.CameraType=Enum.CameraType.Scriptable cam.CFrame=CFrame.lookAt(h.Position+Vector3.new(0,1.5,0), b.Position+Vector3.new(0,1,0)) end)
-- jump the second slam: the client hears bossSlam and jumps just before it lands
_G.SLAMS = 0 _G.FIRSTJUMP = 1
_G.BOSSLOG = {}
game.ReplicatedStorage.Remotes.Fx.OnClientEvent:Connect(function(kind, a) if string.sub(kind, 1, 4) == "boss" or kind == "mgEnd" then table.insert(_G.BOSSLOG, kind .. (kind == "bossKnot" and (":" .. tostring(a)) or "")) end end)
game.ReplicatedStorage.Remotes.Fx.OnClientEvent:Connect(function(kind, land)
  if kind == "bossSlam" then _G.SLAMS += 1 if _G.SLAMS >= (_G.FIRSTJUMP or 2) then task.delay(math.max(0, land - workspace:GetServerTimeNow() - 0.4), function()
    game.Players.LocalPlayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end) end end end)
return 1''', "Client")
lua('game.Players:GetPlayers()[1]:SetAttribute("DevBoss", true) return 1')
time.sleep(1.2); shot("wake")
STRIKE = ('local hud=game.Players.LocalPlayer.PlayerGui.PixelHUD.CaveHud.PerfectStrike local nd,ar=hud:FindFirstChild("Needle",true),hud:FindFirstChild("Arc",true) '
          'local t00=os.clock() while not hud.Visible and os.clock()-t00<8 do task.wait() end if not hud.Visible then return "no strike ui" end '
          'local R=game.ReplicatedStorage.Remotes.Extract local out={} for n=1,3 do local t0=os.clock() '
          'while os.clock()-t0<3 do local d=math.abs((nd.Rotation-ar.Rotation+180)%360-180) if d<4 then break end task.wait() end '
          'table.insert(out,string.format("%d:%.0f",n,math.abs((nd.Rotation-ar.Rotation+180)%360-180))) local a0=ar.Rotation R:FireServer("strike",workspace:GetServerTimeNow()) local tw=os.clock() while ar.Rotation==a0 and os.clock()-tw<1 do task.wait() end task.wait(0.1) end return table.concat(out," ")')
for k in range(1, 4):
    print("knot", k, lua(STRIKE, "Client"))
    time.sleep(0.4); shot(f"knot{k}")
    if k < 3:
        time.sleep(2.2); shot(f"slam{k}")
        time.sleep(1.2); print("after slam", k, lua(STATE))
        time.sleep(1.6)
time.sleep(1.5); shot("win")
print("log", lua('return table.concat(_G.BOSSLOG or {}, ",")', "Client"))
print("end", lua('local p=game.Players:GetPlayers()[1] return "hp "..tostring(p:GetAttribute("HP"))', "Server"))
lua('game:GetService("RunService"):UnbindFromRenderStep("ClaudeCam") return 1', "Client")
