"""Respawn regression: reload the character in town and in the caves, then check the logs and that the wheel, the sonar
and a ping still work with the new character.     python spike/respawn_test.py"""
import sys, time, pathlib
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import night
C1 = lambda code: night.lua(code, "Client").splitlines()[-1]
S1 = lambda code: night.lua(code, "Server").splitlines()[-1]
ERR = "local t={} for _,m in game:GetService('LogService'):GetLogHistory() do if m.messageType==Enum.MessageType.MessageError or m.messageType==Enum.MessageType.MessageWarning then local s=string.sub(m.message,1,170) if not string.find(s,'Requester does not have permission') then t[s]=true end end end local e={} for k in t do table.insert(e,k) end return #e..' '..table.concat(e,' ## ')"
night.play(True); time.sleep(5)
print("town reload:", S1("local p=game.Players:GetPlayers()[1] p:LoadCharacter() task.wait(3) return tostring(p.Character and p.Character:FindFirstChild('HumanoidRootPart') ~= nil)"))
night.key("Tab"); time.sleep(0.6)
print("wheel after town reload:", C1("local w=game.Players.LocalPlayer.PlayerGui.PixelHUD.UtilityWheel local v=w.Visible return tostring(v)")); night.key("Tab"); time.sleep(0.4)
night.key("Q"); time.sleep(33)
print("in caves:", C1("return tostring(game.Players.LocalPlayer:GetAttribute('InCave'))"))
print("cave reload:", S1("local p=game.Players:GetPlayers()[1] local before=p.Character.HumanoidRootPart.Position p:LoadCharacter() task.wait(4) local h=p.Character and p.Character:FindFirstChild('HumanoidRootPart') return 'incave '..tostring(p:GetAttribute('InCave'))..' moved '..(h and math.floor((h.Position-before).Magnitude) or -1)"))
time.sleep(2)
print("state after:", C1("local p=game.Players.LocalPlayer return 'incave '..tostring(p:GetAttribute('InCave'))..' hud '..tostring(p.PlayerGui.PixelHUD.Enabled)..' flares '..tostring(p:GetAttribute('Flares'))"))
print("sonar via wheel:", C1("local p=game.Players.LocalPlayer if not p:GetAttribute('InCave') then return 'not in the caves any more (skipped)' end p:SetAttribute('DevSonarSlow',6) p:SetAttribute('DevWheel',1) task.wait(0.5) local f=workspace:FindFirstChild('Sonar') return tostring(f and f:FindFirstChild('Shell') ~= nil)"))
night.key("Z"); time.sleep(0.8)
print("ping marks:", C1("local n=0 for _,d in game.Players.LocalPlayer.PlayerGui.PixelHUD:GetChildren() do if d.Name=='PingMark' then n+=1 end end return n"))
for w in ("Client", "Server"): print(w, "errors and warnings:", night.lua(ERR, w).splitlines()[-1][:900])
night.play(False)
