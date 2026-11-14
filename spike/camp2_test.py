"""Phase D, Camp 2 as a real place: the walk test (openings clear, every room's set points reachable from the landing), the
z-fight scan, the moved jars and fossils, and the Kiln Surge (jars refill, vents never rest, it ends on the server's clock).
    python spike/camp2_test.py
Shortcuts: the player is put in the Clay Caves by the server; prompts are pressed by script with the camera turned to them;
DevSurge starts a short surge."""
import pathlib, time
import night as N
here = pathlib.Path(__file__).resolve().parent
C1 = lambda code: (N.lua(code, "Client").splitlines() or ["?"])[-1]
S1 = lambda code: (N.lua(code, "Server").splitlines() or ["?"])[-1]
P = "local p=game.Players:GetPlayers()[1] local h=p.Character.HumanoidRootPart local C=require(game.ReplicatedStorage.Shared.Config) local O=CFrame.new(C.CAVE2_ORIGIN) local clay=workspace.Caves.Clay "
N.play(True); time.sleep(8)
print("walk:", S1((here / "camp2_walk.luau").read_text(encoding="utf-8")))
print("z-fight:", S1((here / "zfight_scan.luau").read_text(encoding="utf-8"))[-70:])
print("rooms:", S1(P + "local j,f=0,0 for _,d in clay:GetChildren() do local l=O:PointToObjectSpace(d:IsA('Model') and d:GetPivot().Position or d.Position) "
                     "if d:GetAttribute('Jar') and l.Z<-60 and l.X>-6 and l.X<28 then j+=1 end if d:GetAttribute('Fossil') and l.Z<-60 and l.X>33 then f+=1 end end "
                     "return j..' jars in the gallery, '..f..' fossils in the dig, hammer '..tostring(clay:FindFirstChild('HammerHead')~=nil)"))
# smash a gallery jar (number 5, on the floor), try again (cooldown), surge, smash again
S1(P + "p:SetAttribute('InCave',true) h.CFrame=O*CFrame.new(14,3,-66) return 1"); time.sleep(2)
SMASH = ("local pr for _,d in workspace.Caves.Clay:GetDescendants() do if d:IsA('ProximityPrompt') and d:GetAttribute('ClayJar')==5 then pr=d end end local n=0 "
         "local con=game.ReplicatedStorage.Remotes.Fx.OnClientEvent:Connect(function(k) if k=='jar' then n+=1 end end) local cam=workspace.CurrentCamera "
         "cam.CFrame=CFrame.lookAt(cam.CFrame.Position,pr.Parent.Position) task.wait(0.4) if pr.Enabled then pr:InputHoldBegin() task.wait(0.15) pr:InputHoldEnd() end task.wait(0.8) con:Disconnect() "
         "return 'prompt on '..tostring(pr.Enabled)..', paid '..n")
print("jar 5, first smash:", C1(SMASH))
print("jar 5, again at once:", C1(SMASH))
S1("workspace:SetAttribute('DevSurge',6) return 1"); time.sleep(2.2)
print("surge on:", S1("local e=workspace:GetAttribute('KilnSurge') return tostring(e~=nil and e>workspace:GetServerTimeNow())"))
print("jar 5, after the surge began:", C1(SMASH))
# the vents: in a surge they never rest; without one each rests 2.8 s of every 6 (read from the emitters over 7 s)
VENT = ("local f=workspace.Caves.Clay local v for _,d in f:GetChildren() do if d:GetAttribute('SteamVent')==1 then v=d end end local em=v:FindFirstChildWhichIsA('ParticleEmitter',true) "
        "local off=0 for i=1,14 do if em.Rate==0 then off+=1 end task.wait(0.5) end return off")
S1("workspace:SetAttribute('DevSurge',30) return 1"); time.sleep(1.5)
hi = C1(VENT)
S1("workspace:SetAttribute('DevSurge',1) return 1"); time.sleep(4)
print("surge over:", S1("return tostring(workspace:GetAttribute('KilnSurge')==nil)"))
lo = C1(VENT)
print("vent 1 resting, of 14 looks over 7 s: %s in a surge, %s without" % (hi, lo), "| never rests in a surge:", hi == "0" and lo.isdigit() and int(lo) >= 3)
print("client errors:", C1("local t={} for _,m in game:GetService('LogService'):GetLogHistory() do if m.messageType==Enum.MessageType.MessageError and not string.find(m.message,'Requester') then t[#t+1]=string.sub(m.message,1,140) end end return #t..' '..table.concat(t,' | ')"))
N.play(False)
