"""Play test for the Clay Caves hall (ServerScriptService.ClayCaves, Shared.ClayClient). Studio open in Edit mode.
Goes down with the DevClay hook, smashes a jar, rides a steam vent, opens a fossil and has the server pay it, comes back.
Captures captures/night/clay_*.png and prints one line per check."""
import subprocess, sys, time, pathlib
here = pathlib.Path(__file__).resolve().parent
def night(*a): return (subprocess.run([sys.executable, str(here / "night.py"), *a], capture_output=True, text=True).stdout.strip().splitlines() or ["?"])[-1]
P = "local p=game.Players:GetPlayers()[1] local h=p.Character.HumanoidRootPart local C=require(game.ReplicatedStorage.Shared.Config) local O=C.CAVE2_ORIGIN "
TRIG = "local h=game.Players.LocalPlayer.Character.HumanoidRootPart local best,bd for _,d in workspace.Caves:GetDescendants() do if d:IsA('ProximityPrompt') and d:GetAttribute('%s') and d.Enabled then local m=(d.Parent.Position-h.Position).Magnitude if not bd or m<bd then best,bd=d,m end end end if best then best:InputHoldBegin() task.wait(0.1) best:InputHoldEnd() end return best and math.floor(bd) or 'none'"
night("play"); time.sleep(2); night("key", "Q"); time.sleep(25)
night("lua", "Server", P + "p:SetAttribute('DevClay',2) return 1"); time.sleep(3)
print("arrived:", night("lua", "Server", P + "return tostring((h.Position-O).Magnitude < 90)..' Camp='..tostring(p:GetAttribute('Camp'))..' deposits='..#workspace.Caves.Deposits:GetChildren()"))
night("lua", "Client", "local c=workspace.CurrentCamera return 1"); night("shot", "clay_arrive")
night("lua", "Server", P + "h.CFrame=CFrame.new(O+Vector3.new(-6,3,6), O+Vector3.new(0,6,-12)) return 1"); time.sleep(2); night("shot", "clay_camp")
print("camp ring:", night("lua", "Server", P + "return 'Camp='..tostring(p:GetAttribute('Camp'))"))
g0 = night("lua", "Server", "local s=game.Players:GetPlayers()[1] return 1")
night("lua", "Server", P + "h.CFrame=CFrame.new(O+Vector3.new(-30,3,14), O+Vector3.new(-30,2,18)) return 1"); time.sleep(1.5)
print("jar prompt dist:", night("lua", "Client", TRIG % "ClayJar")); time.sleep(1.5); night("shot", "clay_jar")
print("jar hidden:", night("lua", "Client", "for _,m in workspace.Caves.Clay:GetChildren() do if m:GetAttribute('Jar')==1 then return tostring(m.PrimaryPart.Transparency) end end return 'no jar'"))
night("lua", "Server", P + "h.CFrame=CFrame.new(O+Vector3.new(38,3,-26), O+Vector3.new(58,3,-26)) return 1")
print("vent apex:", night("lua", "Client", "local h=game.Players.LocalPlayer.Character.HumanoidRootPart local y0,top=h.Position.Y,-1e9 for i=1,90 do top=math.max(top,h.Position.Y) task.wait(0.1) end return math.floor(top-y0)..' studs up, umbrella seen='..tostring(workspace:FindFirstChild('GlideUmbrella',true)~=nil)"))
night("lua", "Server", P + "h.CFrame=CFrame.new(O+Vector3.new(38,3,-26), O+Vector3.new(58,3,-26)) return 1"); time.sleep(0.2)
for _ in range(40):
    if "up" in night("lua", "Client", "local h=game.Players.LocalPlayer.Character.HumanoidRootPart return h.AssemblyLinearVelocity.Y>40 and 'up' or 'no'"): break
time.sleep(1.2); night("shot", "clay_glide")
night("lua", "Server", P + "h.CFrame=CFrame.new(O+Vector3.new(-30,3,46), O+Vector3.new(-30,5,53)) return 1"); time.sleep(1.5)
print("fossil prompt dist:", night("lua", "Client", TRIG % "Fossil")); time.sleep(1.2); night("shot", "clay_fossil")
time.sleep(4)
print("fossil paid:", night("lua", "Client", "game.ReplicatedStorage.Remotes.Clay:FireServer('fossil',1) task.wait(1) return 'sent'"))
night("lua", "Server", P + "p:SetAttribute('DevClay',1) return 1"); time.sleep(3)
print("back:", night("lua", "Server", P + "return tostring((h.Position-C.CAVE_ORIGIN).Magnitude < 120)"))
ERR = "local n=0 for _,m in game:GetService('LogService'):GetLogHistory() do if m.messageType==Enum.MessageType.MessageError or (m.messageType==Enum.MessageType.MessageWarning and m.message:find('%[')) then n+=1 print(m.message) end end return n"
for w in ("Client", "Server"): print(w, "errors:", subprocess.run([sys.executable, str(here / "night.py"), "lua", w, ERR], capture_output=True, text=True).stdout.strip()[-600:])
