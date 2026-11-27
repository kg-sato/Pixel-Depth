"""Three-phase boss play test (2026-11-27), Play running:  python spike/boss3_play.py <tag> [1|2]
   Rides down if needed, holds the needed pickaxe (DevEquip), stands 10 studs before the boss, challenges it (DevBoss) and plays
   the whole fight through the real remotes: strikes each knot perfectly, jumps every slam and tide, steps out of every sweep,
   throws a flare (R) into each open core. Prints the boss event log (phases, core, stagger, snare/magma/tide, shatter, win) and
   captures the beats to captures/night/boss3_<tag>_*.png. The client's camera looks at the boss for the whole fight."""
import sys, time, pathlib
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import night
tag = sys.argv[1] if len(sys.argv) > 1 else "t"
BID = int(sys.argv[2]) if len(sys.argv) > 2 else 1
BODY = "WardenBody" if BID == 1 else "GolemBody"
def L(code, where="Server"): return (night.lua(code, where).splitlines() or [""])[-1]
if L('return tostring(game.Players:GetPlayers()[1]:GetAttribute("InCave"))') != "true":
    L('game.ReplicatedStorage.Remotes.Surface:FireServer("down") return 1', "Client"); time.sleep(16)
if BID == 2:
    L('local p=game.Players:GetPlayers()[1] p:SetAttribute("DevClay", 2) return 1')
    time.sleep(12)
need = 6 if BID == 1 else 12
print("setup", L(f'''local p=game.Players:GetPlayers()[1] p:SetAttribute("DevEquip", {need})
local w=workspace.Caves:FindFirstChild("{'Warden' if BID == 1 else 'KilnGolem'}", true) if not w then return "no boss" end
local b=w.PrimaryPart local look=b.CFrame.LookVector*Vector3.new(1,0,1) if look.Magnitude<0.1 then look=Vector3.zAxis end
local at=b.Position+look.Unit*10 p.Character.HumanoidRootPart.CFrame=CFrame.lookAt(Vector3.new(at.X,b.Position.Y,at.Z), Vector3.new(b.Position.X,b.Position.Y,b.Position.Z)) return "ok "..tostring(b.Name)'''))
time.sleep(1.5)
L(f'''local RS=game:GetService("RunService") local cam=workspace.CurrentCamera
local w=workspace.Caves:FindFirstChild("{'Warden' if BID == 1 else 'KilnGolem'}", true) local b=w.PrimaryPart
pcall(function() RS:UnbindFromRenderStep("Boss3Cam") end)
RS:BindToRenderStep("Boss3Cam", Enum.RenderPriority.Camera.Value+40, function() local h=game.Players.LocalPlayer.Character.Head
cam.CameraType=Enum.CameraType.Scriptable cam.CFrame=CFrame.lookAt(h.Position+Vector3.new(0,3,0)-(b.Position-h.Position)*Vector3.new(1,0,1).Unit*6, b.Position+Vector3.new(0,1,0)) end)
_G.B3LOG = {{}}
local function jumpAt(t) task.delay(math.max(0, t - workspace:GetServerTimeNow() - 0.35), function() local h=game.Players.LocalPlayer.Character.Humanoid h:ChangeState(Enum.HumanoidStateType.Jumping) end) end
game.ReplicatedStorage.Remotes.Fx.OnClientEvent:Connect(function(kind, a, b2, c)
  if string.sub(kind, 1, 4) == "boss" then table.insert(_G.B3LOG, kind .. ((kind == "bossKnot" or kind == "bossPhase") and (":" .. tostring(a)) or "")) end
  if kind == "bossSlam" then jumpAt(a) end
  if kind == "bossTide" then local hrp=game.Players.LocalPlayer.Character.HumanoidRootPart local r=((hrp.Position-b.Position)*Vector3.new(1,0,1)).Magnitude jumpAt(a + r / b2) end
  if kind == "bossSweep" then task.delay(0.4, function() local hrp=game.Players.LocalPlayer.Character.HumanoidRootPart hrp.CFrame = hrp.CFrame + Vector3.new(-b2.Z, 0, b2.X) * 7 end) end
  if kind == "bossCore" then task.delay(0.5, function() _G.B3FLARE = true end) end
end)
return 1''', "Client")
L(f'game.Players:GetPlayers()[1]:SetAttribute("DevBoss", {BID}) return 1')
time.sleep(1.4); print("shot", night.shot(f"boss3_{tag}_wake"))
STRIKE = ('local hud=game.Players.LocalPlayer.PlayerGui.PixelHUD.CaveHud.PerfectStrike local nd,ar=hud:FindFirstChild("Needle",true),hud:FindFirstChild("Arc",true) '
          'local t00=os.clock() while not hud.Visible and os.clock()-t00<14 do if _G.B3FLARE then _G.B3FLARE=false return "flare" end task.wait() end if not hud.Visible then return "no strike ui" end '
          'local R=game.ReplicatedStorage.Remotes.Extract local out={} for n=1,3 do local t0=os.clock() if not hud.Visible then break end '
          'while os.clock()-t0<3 do local d=math.abs((nd.Rotation-ar.Rotation+180)%360-180) if d<4 then break end task.wait() end '
          'table.insert(out,string.format("%d:%.0f",n,math.abs((nd.Rotation-ar.Rotation+180)%360-180))) local a0=ar.Rotation R:FireServer("strike",workspace:GetServerTimeNow()) local tw=os.clock() while ar.Rotation==a0 and os.clock()-tw<1 do task.wait() end task.wait(0.1) end return table.concat(out," ")')
shots = 0
for k in range(14):
    r = L(STRIKE, "Client")
    print("step", k, r)
    if r == "flare":
        if len(sys.argv) <= 3: night.key("R")  # a third argument (noflare) skips the flares: the fight runs through phase 2
        time.sleep(0.6)
        if shots < 3: print("shot", night.shot(f"boss3_{tag}_core{k}")); shots += 1
        continue
    time.sleep(0.6)
    log = L('return table.concat(_G.B3LOG or {}, ",")', "Client")
    if "bossWin" in log or "bossLose" in log: break
    if k in (1, 3): print("shot", night.shot(f"boss3_{tag}_fight{k}"))
time.sleep(2.5); print("shot", night.shot(f"boss3_{tag}_end"))
time.sleep(2); print("chest", L('local n=0 for _,d in workspace.Caves:GetDescendants() do if d.Name=="BossRelicChest" then n+=1 end end return n'))
print("log", L('return table.concat(_G.B3LOG or {}, ",")', "Client"))
print("hp", L('return tostring(game.Players:GetPlayers()[1]:GetAttribute("HP"))'))
L('pcall(function() game:GetService("RunService"):UnbindFromRenderStep("Boss3Cam") end) return 1', "Client")
