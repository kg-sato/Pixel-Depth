"""Crystal Resonance Chimes in the Clay Caves: does the server own the order, the clock, the pay and the rest?
    python spike/chime_test.py
Shortcuts: DevClay = 2 takes the lift down; the server stands the player at each crystal; prompts are pressed by script."""
import time
import night as N
C1 = lambda code: (N.lua(code, "Client").splitlines() or ["?"])[-1]
S1 = lambda code: (N.lua(code, "Server").splitlines() or ["?"])[-1]
P = "local p=game.Players:GetPlayers()[1] local h=p.Character.HumanoidRootPart local cv=workspace.Caves "
N.play(True); time.sleep(6)
S1("workspace:SetAttribute('DevChimeSlow', 4) return 1")  # each scripted strike takes ~4 s in a long-running Studio (2026-11-20)
N.key("Q"); time.sleep(33)
S1(P + "p:SetAttribute('DevClay',2) return 1"); time.sleep(17)
C1("local p=game.Players.LocalPlayer p:SetAttribute('DevChime','') game.ReplicatedStorage.Remotes.Fx.OnClientEvent:Connect(function(k,w,a,b) if k=='chime' then "
   "p:SetAttribute('DevChime',(p:GetAttribute('DevChime') or '')..' '..tostring(w)..':'..(type(a)=='table' and table.concat(a,'') or tostring(a))) end end) return 1")
def strike(k):
    S1(P + "local c for _,d in cv:GetDescendants() do if d:IsA('BasePart') and d:GetAttribute('ChimeCrystal')==%d then c=d end end h.CFrame=CFrame.lookAt(c.Position+Vector3.new(0,1.5,3),c.Position) return 1" % k)
    time.sleep(0.5)
    return C1("local c for _,d in workspace.Caves:GetDescendants() do if d:IsA('BasePart') and d:GetAttribute('ChimeCrystal')==%d then c=d end end local pr=c:FindFirstChildOfClass('ProximityPrompt') local cam=workspace.CurrentCamera "
              "cam.CFrame=CFrame.lookAt(cam.CFrame.Position,c.Position) task.wait(0.35) pr:InputHoldBegin() task.wait(0.1) pr:InputHoldEnd() task.wait(0.7) return tostring(game.Players.LocalPlayer:GetAttribute('DevChime'))" % k)
def order(log):
    return [int(ch) for ch in log.split("start:")[-1].strip().split()[0]]
log = strike(1); o = order(log)
print("woken:", "start" in log, "| three crystals in the order:", sorted(o) == [1, 2, 3])
print("next badge big:", C1("local big,small=0,0 for _,d in workspace.Caves:GetDescendants() do if d.Name=='ChimeNumber' and d.Enabled then if d.Size.X.Offset==62 then big+=1 elseif d.Size.X.Offset==40 then small+=1 end end end return big..' big '..small..' small'"))  # the crystal to strike next wears the big gold badge (2026-11-23)
log = strike(o[1])
print("the second crystal first:", log.split()[-1])
time.sleep(41)
log = strike(2); o = order(log)
for k in o: log = strike(k)
print("in order:", " ".join(w.split(":")[0] + (":" + w.split(":")[1] if w.startswith("done") else "") for w in log.split()[-3:]))
print("again at once:", strike(1).split()[-1])
print("numbers shown:", C1("local n=0 for _,d in workspace.Caves:GetDescendants() do if d.Name=='ChimeNumber' then n+=1 end end return n"))
print("client errors:", C1("local t={} for _,m in game:GetService('LogService'):GetLogHistory() do if m.messageType==Enum.MessageType.MessageError and not string.find(m.message,'Requester') and not string.find(m.message,'not authorized') then t[#t+1]=string.sub(m.message,1,140) end end return #t..' '..table.concat(t,' | ')"))
print("server errors:", S1("local t={} for _,m in game:GetService('LogService'):GetLogHistory() do if m.messageType==Enum.MessageType.MessageError and not string.find(m.message,'Requester') and not string.find(m.message,'not authorized') and not string.find(m.message,'AssistantCommand') then t[#t+1]=string.sub(m.message,1,140) end end return #t..' '..table.concat(t,' | ')"))
N.play(False)
