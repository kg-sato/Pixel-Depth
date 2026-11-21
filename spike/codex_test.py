"""The Codex: does the server keep what was found, turn it into egg luck, and does the gallery show it?
    python spike/codex_test.py
Shortcuts: DevMarquee = a pet name stands in for hatching it; DevCodex = n marks n ores as found."""
import time
import night as N
C1 = lambda code: (N.lua(code, "Client").splitlines() or ["?"])[-1]
S1 = lambda code: (N.lua(code, "Server").splitlines() or ["?"])[-1]
P = "local p=game.Players:GetPlayers()[1] "
STATE = ("local p=game.Players.LocalPlayer local w=p.PlayerGui:FindFirstChild('Codex',true) local lit=0 for _,c in w:FindFirstChild('Grid',true):GetChildren() do if c:IsA('GuiObject') then for _,t in c:GetChildren() do if t:IsA('TextLabel') and t.Text=='?' and not t.Visible then lit+=1 end end end end "
         "return 'luck '..tostring(p:GetAttribute('CodexLuck'))..' | lit '..lit..' | '..w:FindFirstChild('Status',true).Text..' | odds: '..p.PlayerGui:FindFirstChild('Odds',true).Luck.Text")
N.play(True); time.sleep(8)
print("sums:", S1("local C=require(game.ReplicatedStorage.Shared.Config) local t=C.codexTotal() local q=math.ceil(t*0.25) local o,sum=C.eggOdds(0,0.2),0 for _,v in o do sum+=v[2] end "
      "return 'total '..t..' luck at 0, a quarter less one, a quarter, half, all: '..C.codexLuck(0)..' '..C.codexLuck(q-1)..' '..C.codexLuck(q)..' '..C.codexLuck(math.ceil(t*0.5))..' '..C.codexLuck(t)..' | odds with 20% add up to '..string.format('%.2f',sum)..' epic '..string.format('%.1f',o[3][2])"))
print("at the start:", C1(STATE))
S1(P + "p:SetAttribute('DevMarquee','Kobold') return 1"); time.sleep(2.5)
print("a pet hatched:", C1(STATE))
q = int(S1("local C=require(game.ReplicatedStorage.Shared.Config) return math.ceil(C.codexTotal()*0.25)"))
S1(P + "p:SetAttribute('DevCodex',%d) return 1" % (q - 1)); time.sleep(2.5)
print("a quarter found:", C1(STATE).replace(str(q), "Q"))
N.key("K"); time.sleep(1.2)
print("K opens the gallery:", C1("return tostring(game.Players.LocalPlayer.PlayerGui:FindFirstChild('Codex',true).Visible)"))
N.key("K"); time.sleep(0.8)
print("client errors:", C1("local t={} for _,m in game:GetService('LogService'):GetLogHistory() do if m.messageType==Enum.MessageType.MessageError and not string.find(m.message,'Requester') then t[#t+1]=string.sub(m.message,1,140) end end return #t..' '..table.concat(t,' | ')"))
print("server errors:", S1("local t={} for _,m in game:GetService('LogService'):GetLogHistory() do if m.messageType==Enum.MessageType.MessageError and not string.find(m.message,'Requester') and not string.find(m.message,'AssistantCommand') then t[#t+1]=string.sub(m.message,1,140) end end return #t..' '..table.concat(t,' | ')"))
N.play(False)
