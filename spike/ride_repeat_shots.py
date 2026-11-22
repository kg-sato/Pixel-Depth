"""Repeat minecart rides (2026-11-22, the transit card): rides down once, comes back to town, then takes stills of a repeat ride to
Camp 1 and one to Camp 2.   python spike/ride_repeat_shots.py <tag>     stills: captures/night/rr_<tag>_<camp>_<n>.png"""
import sys, time
import night as N
tag = sys.argv[1] if len(sys.argv) > 1 else "a"
P = "local p=game.Players:GetPlayers()[1] local h=p.Character.HumanoidRootPart "
S = lambda c: (N.lua(c, "Server").splitlines() or ["?"])[-1]
C = lambda c: (N.lua(c, "Client").splitlines() or ["?"])[-1]
N.play(False); time.sleep(2); N.play(); time.sleep(10)
C("local g=game.Players.LocalPlayer.PlayerGui:FindFirstChild('DailyChest') if g then g.Enabled=false end return 1")
N.key("Q"); time.sleep(26)
def to_town():
    S(P + "p:SetAttribute('InCave',false) h.CFrame=workspace.Hub:FindFirstChild('HubCart',true):GetPivot()+Vector3.new(6,5,0) game.ReplicatedStorage.Remotes.Fx:FireClient(p,'lift',false) return 1"); time.sleep(4)
    S(P + "h.CFrame=workspace.Hub:FindFirstChild('HubCart',true):GetPivot()+Vector3.new(6,5,0) return 1"); time.sleep(2.5)
for camp in (1, 2):
    to_town()
    C("local g=game.Players.LocalPlayer.PlayerGui local w=g:FindFirstChild('CampChoice',true) if w then w.Visible=false end game.ReplicatedStorage.Remotes.Surface:FireServer('down',%d) return 1" % camp)
    for n in range(5):
        time.sleep(1.6)
        N.shot(f"rr_{tag}_c{camp}_{n}")
    time.sleep(6)
N.play(False)
print("done")
