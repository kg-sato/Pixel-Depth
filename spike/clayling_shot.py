"""Two pictures of a clayling for grading: frozen where first seen, then from 9 studs. Starts Play itself.
    python spike/clayling_shot.py <name>   ->  captures/night/<name>_far.png, <name>_near.png"""
import pathlib, subprocess, sys, time
here = pathlib.Path(__file__).resolve().parent
name = sys.argv[1] if len(sys.argv) > 1 else "clayling"
def night(*a): return (subprocess.run([sys.executable, str(here / "night.py"), *a], capture_output=True, text=True).stdout.strip().splitlines() or ["?"])[-1]
P = "local p=game.Players:GetPlayers()[1] local h=p.Character.HumanoidRootPart local C=require(game.ReplicatedStorage.Shared.Config) "
night("play"); time.sleep(8); night("key", "Q"); time.sleep(32)
night("lua", "Server", P + "p:SetAttribute('DevClay',2) return 1"); time.sleep(8)
# the camera holds the nearest clayling in view (a prompt-style hold: the call must stay alive while the pictures are taken)
look = subprocess.Popen([sys.executable, str(here / "night.py"), "lua", "Client", "local cam=workspace.CurrentCamera local t0=os.clock() while os.clock()-t0<40 do local best,bd for _,m in workspace.Gloom:GetChildren() do local d=(m.Position-cam.CFrame.Position).Magnitude if m:GetAttribute('State')~='flee' and (not bd or d<bd) then best,bd=m,d end end if best then cam.CFrame=CFrame.lookAt(cam.CFrame.Position,best.Position+Vector3.new(0,1.5,0)) end task.wait() end return 1"], stdout=subprocess.DEVNULL)
time.sleep(2)
print("first seen at", night("lua", "Server", P + "h.CFrame=CFrame.new(C.CAVE2_ORIGIN+Vector3.new(-50,3,30)) p:SetAttribute('DevBanked',true) p:SetAttribute('DevTorchAge',C.TORCH.time*0.5) for i=1,300 do task.wait(0.05) for _,m in workspace.Gloom:GetChildren() do if m:GetAttribute('Seen') then return math.floor((m.Position-h.Position).Magnitude) end end end return 0"), "studs")
time.sleep(0.8); night("shot", name + "_far")
night("lua", "Server", P + "for _,m in workspace.Gloom:GetChildren() do if m:GetAttribute('Seen') then h.CFrame=CFrame.new(m.Position+(h.Position-m.Position).Unit*9+Vector3.new(0,2,0)) return 1 end end return 0")
time.sleep(1.5); night("shot", name + "_near")
print("client errors", night("lua", "Client", "local n=0 for _,m in game:GetService('LogService'):GetLogHistory() do if m.messageType==Enum.MessageType.MessageError then n+=1 end end return n"))
night("stop"); look.wait()
