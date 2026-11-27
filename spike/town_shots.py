"""Town station stills from the player's town camera (2026-11-27 night): stand at each station's front and capture.
python spike/town_shots.py <tag>   prints one path per still (Studio's screenshot folder)."""
import sys, time
import night as N
tag = sys.argv[1] if len(sys.argv) > 1 else "t"
# (name, where the player stands): just in front of each station, towards the plaza, so the town camera frames it
SPOTS = [("plaza_signpost", (13, 6, -4)), ("market", (-30, 6, -2)), ("forge", (-41, 6, -36)), ("refinery", (-32, 6, 31)),
         ("hatchery", (35, 6, 22)), ("terrace", (12, 6, -36))]
N.play(True); time.sleep(9)
N.lua("local g=game.Players.LocalPlayer.PlayerGui:FindFirstChild('DailyChest') if g then g.Enabled=false end return 1", "Client")
for name, (x, y, z) in SPOTS:
    N.lua(f"local p=game.Players:GetPlayers()[1] p.Character.HumanoidRootPart.CFrame=CFrame.new({x},{y},{z}) return 1", "Server")
    time.sleep(2.2)
    print(name, N.shot(f"town_{tag}_{name}"))
N.play(False)
