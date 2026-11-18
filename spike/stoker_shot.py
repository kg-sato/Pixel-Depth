"""The stoker's gauge in a crew ride (Play running, player in town): python spike/stoker_shot.py <name>
Rides down to Camp 1, boards the crew cart with DevCrewBot (the server drives), and takes stills of the stoker's view."""
import sys, time
import night as N
S = lambda c: (N.lua(c, "Server").splitlines() or ["?"])[-1]
C = lambda c: (N.lua(c, "Client").splitlines() or ["?"])[-1]
P = "local p=game.Players:GetPlayers()[1] local h=p.Character.HumanoidRootPart local cv=workspace.Caves "
C("local g=game.Players.LocalPlayer.PlayerGui local w=g:FindFirstChild('CampChoice',true) if w then w.Visible=false end game.ReplicatedStorage.Remotes.Surface:FireServer('down',1) return 1"); time.sleep(30)
S(P + "local body=cv:FindFirstChild('CartBody',true) h.CFrame=body.CFrame*CFrame.new(0,3,8) return 1"); time.sleep(1)
C("game.Players.LocalPlayer:SetAttribute('DevCrew',true) return 1")
S(P + "p:SetAttribute('DevCrewBot',true) return 1")
time.sleep(26)
for i in range(3):
    N.shot(f"{sys.argv[1]}_{i}"); time.sleep(3)
