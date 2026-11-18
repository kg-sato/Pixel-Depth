"""Codex pet cells as live 3D models: mark a few pets hatched (DevMarquee), open the gallery (K), capture, hover one cell.
    python spike/codex_pets_shot.py <prefix>"""
import sys, time
import night as N
pre = sys.argv[1]
S1 = lambda code: (N.lua(code, "Server").splitlines() or ["?"])[-1]
C1 = lambda code: (N.lua(code, "Client").splitlines() or ["?"])[-1]
N.play(True); time.sleep(12)
for pet in ("Fafnir", "Shinemane", "Kirin", "Tosk", "Zharbird", "Ninering"):
    S1("local p=game.Players:GetPlayers()[1] p:SetAttribute('DevMarquee','%s') return 1" % pet); time.sleep(1.5)
N.key("K"); time.sleep(1.5)
print("cards:", C1("local n=0 for _,d in game.Players.LocalPlayer.PlayerGui:GetDescendants() do if d.Name=='Card3D' and d.AbsoluteSize.X>4 then n+=1 end end return n"))
N.shot(pre + "_codex")
pos = C1("for _,d in game.Players.LocalPlayer.PlayerGui:GetDescendants() do if d.Name=='Card3D' and d.AbsoluteSize.X>4 then local c=d.AbsolutePosition+d.AbsoluteSize/2+game:GetService('GuiService'):GetGuiInset() return math.floor(c.X)..','..math.floor(c.Y) end end return 'none'")
if "," in pos:
    x, y = map(int, pos.split(","))
    N.run("user_mouse_input", {"actions": [{"action": "moveTo", "x": x, "y": y}], "datamodel_type": "Client"}); time.sleep(1)
    N.shot(pre + "_codex_hover")
N.key("K")
