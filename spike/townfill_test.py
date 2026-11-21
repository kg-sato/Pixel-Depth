"""The town's arrival fill: is the town lit at once after a join and after a return, and is its own ambient put back?
    python spike/townfill_test.py
Brightness is the mean of the lower half of a screenshot (lamps not yet in: about 27; lit town: about 89)."""
import time
import night as N
from PIL import Image
C1 = lambda code: (N.lua(code, "Client").splitlines() or ["?"])[-1]
S1 = lambda code: (N.lua(code, "Server").splitlines() or ["?"])[-1]
def bright(name):
    N.shot(name)
    im = Image.open(N.out / (name + ".png")).convert("RGB")
    w, h = im.size
    im = im.crop((int(w * 0.05), int(h * 0.45), int(w * 0.95), int(h * 0.98))).resize((64, 32))
    px = list(im.getdata())
    return sum(sum(p) for p in px) / len(px) / 3
STATE = "local L=game:GetService('Lighting') local a=L.Ambient return 'fill '..tostring(game.Players.LocalPlayer:GetAttribute('TownFill'))..' ambient '..math.floor(a.R*255+0.5)..','..math.floor(a.G*255+0.5)..','..math.floor(a.B*255+0.5)"
N.run("start_stop_play", {"is_start": True}); time.sleep(7)
C1("local g=game.Players.LocalPlayer.PlayerGui:FindFirstChild('PixelLoading') if g then g:Destroy() end return 1")
st = C1(STATE)  # read the flag first: on a slow Studio the capture took the rest of the 16 s fill hold (2026-11-20 flake)
b = bright("fill_join")
print("just after the join:", st, "| lit:", b > 55, "(%.0f)" % b)
time.sleep(20)
print("25 s later:", C1(STATE))
S1("local p=game.Players:GetPlayers()[1] p:SetAttribute('InCave',true) return 1"); time.sleep(1.5)
print("in the caves:", C1(STATE))
time.sleep(14)
print("in the caves, 15 s later:", C1(STATE))
S1("local p=game.Players:GetPlayers()[1] p:SetAttribute('InCave',false) return 1"); time.sleep(1.5)
print("back in town:", C1(STATE))
time.sleep(14)
print("15 s later:", C1(STATE))
print("client errors:", C1("local t={} for _,m in game:GetService('LogService'):GetLogHistory() do if m.messageType==Enum.MessageType.MessageError and not string.find(m.message,'Requester') and not string.find(m.message,'not authorized') then t[#t+1]=string.sub(m.message,1,140) end end return #t..' '..table.concat(t,' | ')"))
N.play(False)
