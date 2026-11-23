"""Debug (2026-11-23): runs the tour's chime step (loop_rec5) in a fresh Play after DevClay=2, printing what each strike returned."""
import time
import night as N
C = lambda code: (N.lua(code, "Client").splitlines() or ["?"])[-1]
S = lambda code: (N.lua(code, "Server").splitlines() or ["?"])[-1]
P = "local p=game.Players:GetPlayers()[1] local h=p.Character.HumanoidRootPart local cv=workspace.Caves local C=require(game.ReplicatedStorage.Shared.Config) local O=CFrame.new(C.CAVE2_ORIGIN) "
N.play(False); time.sleep(2); N.play(True); time.sleep(8)
N.key("Q"); time.sleep(33)
S(P + "h.CFrame=cv:FindFirstChild('LiftLanding',true).CFrame+Vector3.new(0,3,0) task.wait(1) p:SetAttribute('DevClay',2) return 1"); time.sleep(17)
C("local p=game.Players.LocalPlayer p:SetAttribute('DevChime','') game.ReplicatedStorage.Remotes.Fx.OnClientEvent:Connect(function(k,w,a) if k=='chime' then p:SetAttribute('DevChime',(p:GetAttribute('DevChime') or '')..' '..tostring(w)..':'..(type(a)=='table' and table.concat(a,'') or tostring(a))) end end) return 1")
S("workspace:SetAttribute('DevChimeSlow', 4) return 1")
def strike(k):
    S(P + "local c for _,d in cv:GetDescendants() do if d:IsA('BasePart') and d:GetAttribute('ChimeCrystal')==%d then c=d end end h.CFrame=CFrame.lookAt(c.Position+Vector3.new(0,1.5,4),c.Position) return 1" % k); time.sleep(0.5)
    print("strike", k, C("local c for _,d in workspace.Caves:GetDescendants() do if d:IsA('BasePart') and d:GetAttribute('ChimeCrystal')==%d then c=d end end local pr=c:FindFirstChildOfClass('ProximityPrompt') local cam=workspace.CurrentCamera "
      "cam.CFrame=CFrame.lookAt(cam.CFrame.Position,c.Position) task.wait(0.35) local P=game:GetService('ProximityPromptService') local info='pps '..tostring(P.Enabled)..' pr '..tostring(pr and pr.Enabled)..' hold '..tostring(pr and pr.HoldDuration) pr:InputHoldBegin() task.wait(0.1) pr:InputHoldEnd() task.wait(0.8) return info..' | '..tostring(game.Players.LocalPlayer:GetAttribute('DevChime'))" % k))
strike(2)
print("badges:", C("local n=0 for _,d in workspace.Caves:GetDescendants() do if d.Name=='ChimeNumber' and d.Enabled then n+=1 end end return n"))
S("workspace:SetAttribute('DevChimeSlow', nil) return 1")
N.play(False)
