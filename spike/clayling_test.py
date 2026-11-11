"""Claylings (Gloom kind 2, the Clay Caves hall): they spawn there, close in while unseen and stand still while looked at.
Starts Play itself. Prints PASS/FAIL per check."""
import pathlib, subprocess, sys, time
here = pathlib.Path(__file__).resolve().parent
def night(*a): return (subprocess.run([sys.executable, str(here / "night.py"), *a], capture_output=True, text=True).stdout.strip().splitlines() or ["?"])[-1]
P = "local p=game.Players:GetPlayers()[1] local h=p.Character.HumanoidRootPart local C=require(game.ReplicatedStorage.Shared.Config) "
NEAR = P + "local n,bd=0 for _,m in workspace.Gloom:GetChildren() do if m:GetAttribute('Kind')==2 and m:GetAttribute('State')~='flee' then n+=1 local d=(m.Position-h.Position).Magnitude if not bd or d<bd then bd=d end end end return n..' '..math.floor(bd or -1)"
night("play"); time.sleep(8); night("key", "Q"); time.sleep(32)
night("lua", "Server", P + "p:SetAttribute('DevClay',2) return 1"); time.sleep(8)
night("lua", "Server", P + "h.CFrame=CFrame.new(C.CAVE2_ORIGIN+Vector3.new(-50,3,30)) p:SetAttribute('DevBanked',true) p:SetAttribute('DevTorchAge',C.TORCH.time*0.92) return 1")
time.sleep(8)
n, d0 = night("lua", "Server", NEAR).split()
print("PASS" if int(n) > 0 else "FAIL", "claylings spawned:", n)
# hold the camera on the nearest one: it must not come closer
look = subprocess.Popen([sys.executable, str(here / "night.py"), "lua", "Client", "local cam=workspace.CurrentCamera local t0=os.clock() while os.clock()-t0<6 do local best,bd for _,m in workspace.Gloom:GetChildren() do local d=(m.Position-cam.CFrame.Position).Magnitude if m:GetAttribute('State')~='flee' and (not bd or d<bd) then best,bd=m,d end end if best then cam.CFrame=CFrame.lookAt(cam.CFrame.Position,best.Position) end task.wait() end return 1"], stdout=subprocess.DEVNULL)
time.sleep(2)
res = night("lua", "Server", "local ok,bad=0,0 for i=1,30 do local snap={} for _,x in workspace.Gloom:GetChildren() do if x:GetAttribute('Seen') and x:GetAttribute('State')=='creep' then snap[x]=x.Position end end task.wait(0.1) for x,a in snap do if x.Parent and x:GetAttribute('Seen') and x:GetAttribute('State')=='creep' then if (x.Position-a).Magnitude<0.01 then ok+=1 else bad+=1 end end end end return ok..' '..bad")
look.wait()
ok, bad = res.split()
print("PASS" if int(ok) > 5 and bad == "0" else "FAIL", "stands still while seen (still samples, moving samples):", ok, bad)
errs = night("lua", "Server", "local n=0 for _,m in game:GetService('LogService'):GetLogHistory() do if m.messageType==Enum.MessageType.MessageError then n+=1 end end return n")
print("PASS" if errs == "1" else "FAIL", "server errors (1 = the asset permission baseline):", errs)
night("stop")
