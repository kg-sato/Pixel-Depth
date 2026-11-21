"""Trophy cases at the Trophy House: are they each player's own, and filled only by what was earned?
    python spike/trophy_test.py
Shortcuts: DevMarquee = a pet name stands in for hatching it; DevTrophy = gate1 stands in for beating the Root Warden."""
import time
import night as N
C1 = lambda code: (N.lua(code, "Client").splitlines() or ["?"])[-1]
S1 = lambda code: (N.lua(code, "Server").splitlines() or ["?"])[-1]
P = "local p=game.Players:GetPlayers()[1] "
READ = ("local p=game.Players.LocalPlayer local h=workspace.Hub.TrophyHouse local r={} for _,k in {'gate1','gate2','Ouro','Ninering'} do local txt,earned='none',false "
        "for _,d in h:GetChildren() do if d.Name=='TrophyPlaque' and d:GetAttribute('Trophy')==k then txt=string.gsub(d.Gui.Line.Text,'\\n',' / ') end end "
        "local m=workspace.TrophyFX:FindFirstChild(k) earned=m and m:GetAttribute('Earned')==true r[#r+1]=k..'='..txt..(earned and ' [figure]' or '') end "
        "return '<'..tostring(p:GetAttribute('Trophies'))..'> '..table.concat(r,' ; ')")
N.play(True); time.sleep(8)
print("cases at the start:", C1(READ))
S1(P + "p:SetAttribute('DevMarquee','Kobold') return 1"); time.sleep(3)
print("after a Common hatch:", C1("return '<'..tostring(game.Players.LocalPlayer:GetAttribute('Trophies'))..'>'"))
S1(P + "p:SetAttribute('DevMarquee','Ninering') return 1"); time.sleep(3)
print("after a Secret hatch:", C1(READ))
S1(P + "p:SetAttribute('DevTrophy','gate1') return 1"); time.sleep(3)
print("after the Root Warden:", C1(READ))
print("a client cannot fill its own case:", C1("local p=game.Players.LocalPlayer p:SetAttribute('Trophies','gate1,gate2,Ouro,Ninering') task.wait(0.5) return 'server sees '..tostring(1)") , "|", S1(P + "return '<'..tostring(p:GetAttribute('Trophies'))..'>'"))
print("client errors:", C1("local t={} for _,m in game:GetService('LogService'):GetLogHistory() do if m.messageType==Enum.MessageType.MessageError and not string.find(m.message,'Requester') and not string.find(m.message,'not authorized') then t[#t+1]=string.sub(m.message,1,140) end end return #t..' '..table.concat(t,' | ')"))
print("server errors:", S1("local t={} for _,m in game:GetService('LogService'):GetLogHistory() do if m.messageType==Enum.MessageType.MessageError and not string.find(m.message,'Requester') and not string.find(m.message,'not authorized') and not string.find(m.message,'AssistantCommand') then t[#t+1]=string.sub(m.message,1,140) end end return #t..' '..table.concat(t,' | ')"))
N.play(False)
