"""Play test for the lead pet, a spore storm and Roots Stirring (ServerScriptService.CaveEvents). Studio open in Edit mode.
Captures captures/night/ev_pet.png, ev_spore.png, ev_roots.png and prints where the roots left the player."""
import subprocess, sys, time, pathlib
here = pathlib.Path(__file__).resolve().parent
def night(*a): return subprocess.run([sys.executable, str(here / "night.py"), *a], capture_output=True, text=True).stdout.strip().splitlines()[-1:]
P = "local p=game.Players:GetPlayers()[1] local h=p.Character.HumanoidRootPart "
night("play")
night("lua", "Server", P + "p:SetAttribute('DevPet','Glimwisp') return 1")
time.sleep(2); night("key", "Q"); time.sleep(25)
# stand by a shrine out in the caves (an open floor far from camp)
print(night("lua", "Server", P + "local s=workspace.Caves:FindFirstChild('LostLanternSpot',true) h.CFrame=CFrame.new(s.Position+Vector3.new(4,3,4)) return 'at '..tostring(h.Position)"))
time.sleep(3); night("shot", "ev_pet")
night("lua", "Server", "workspace:SetAttribute('DevSpore',30) return 1")
time.sleep(6); night("shot", "ev_spore")
night("lua", "Server", "workspace:SetAttribute('DevRoots',9) return 1")
time.sleep(4); night("shot", "ev_roots")
time.sleep(8)
print(night("lua", "Server", P + "local l=workspace.Caves:FindFirstChild('LiftLanding',true) return 'after roots: '..math.floor((h.Position-l.Position).Magnitude)..' studs from the landing, InCave='..tostring(p:GetAttribute('InCave'))..' Camp='..tostring(p:GetAttribute('Camp'))"))
ERR = "local n=0 for _,m in game:GetService('LogService'):GetLogHistory() do if m.messageType==Enum.MessageType.MessageError or (m.messageType==Enum.MessageType.MessageWarning and m.message:find('%[')) then n+=1 print(m.message) end end return n"
for w in ("Client", "Server"): print(w, "errors", night("lua", w, ERR))
