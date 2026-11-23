"""v15: reproduce the tour's trophy close-up (full1123e 267s: a big opaque figure in front of the case) and name what the
camera sees. python spike/trophy_dbg.py"""
import pathlib, sys, time
here = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(here))
import night as N
P = "local p=game.Players:GetPlayers()[1] local h=p.Character.HumanoidRootPart "
G = "local g for _,d in workspace.Hub.TrophyHouse:GetChildren() do if d.Name=='TrophyGlass' and d:GetAttribute('Trophy')=='gate1' then g=d end end "
N.play(False); N.play(True); time.sleep(6)
print(N.lua("game.Players:GetPlayers()[1]:SetAttribute('DevPet','Shinemane') return 1", "Server")); time.sleep(3)
print(N.lua(P + G + "h.CFrame=g.CFrame*CFrame.new(14,0,9) return 1", "Server")); time.sleep(2)
print(N.lua(P + "p:SetAttribute('DevMarquee','Ninering') return 1", "Server")); time.sleep(3)
code = (here / "trophy_dbg.luau").read_text(encoding="utf-8")
print(N.lua(code, "Client"))
N.shot("trophy_dbg")
print(N.lua("game:GetService('RunService'):UnbindFromRenderStep('dbgcam') return 1", "Client"))
