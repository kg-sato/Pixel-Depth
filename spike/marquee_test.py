"""The server marquee: is everyone told of a Mythic or Secret hatch, and of nothing less?   python spike/marquee_test.py
Shortcut: the player attribute DevMarquee = a pet name stands in for a real hatch of that pet."""
import time
import night as N
C1 = lambda code: (N.lua(code, "Client").splitlines() or ["?"])[-1]
S1 = lambda code: (N.lua(code, "Server").splitlines() or ["?"])[-1]
P = "local p=game.Players:GetPlayers()[1] "
N.play(True); time.sleep(6)
# everything is read by code on the client that waits itself: a slow Studio takes seconds between two calls
WATCH = ("local m=game.Players.LocalPlayer.PlayerGui:FindFirstChild('Marquee',true) if not m then return 'no marquee' end "
         "local t=os.clock() while os.clock()-t<%d and not m.Visible do task.wait(0.1) end return tostring(m.Visible)..' '..m.Line.Text")
S1(P + "task.delay(1.5,function() p:SetAttribute('DevMarquee','Kobold') end) return 1")
print("a Common hatch:", C1(WATCH % 5))
S1(P + "task.delay(1.5,function() p:SetAttribute('DevMarquee','Ninering') end) return 1")
print("a Secret hatch:", C1(WATCH % 8))
print("gone after its time:", C1("local m=game.Players.LocalPlayer.PlayerGui:FindFirstChild('Marquee',true) local t=os.clock() while m.Visible and os.clock()-t<9 do task.wait(0.2) end return 'visible '..tostring(m.Visible)"))
S1(P + "task.delay(1.5,function() p:SetAttribute('DevMarquee','Ouro') end) return 1")
print("overlaps with the marquee up:", C1("do local m=game.Players.LocalPlayer.PlayerGui:FindFirstChild('Marquee',true) local t=os.clock() while os.clock()-t<12 and not m.Visible do task.wait(0.1) end task.wait(0.7) end " + open(N.pathlib.Path(N.__file__).resolve().parent / "hud_overlap.luau", encoding="utf-8").read()))
print("client errors:", C1("local t={} for _,m in game:GetService('LogService'):GetLogHistory() do if m.messageType==Enum.MessageType.MessageError and not string.find(m.message,'Requester') then t[#t+1]=string.sub(m.message,1,140) end end return #t..' '..table.concat(t,' | ')"))
print("server errors:", S1("local t={} for _,m in game:GetService('LogService'):GetLogHistory() do if m.messageType==Enum.MessageType.MessageError and not string.find(m.message,'Requester') and not string.find(m.message,'AssistantCommand') then t[#t+1]=string.sub(m.message,1,140) end end return #t..' '..table.concat(t,' | ')"))
N.play(False)
