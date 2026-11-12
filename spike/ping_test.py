"""Ping test: press Z in the caves (a marker and a beam), then the server's refusals through the remote.
    python spike/ping_test.py     (starts Play itself; shot captures/night/ping.png)"""
import sys, time, pathlib
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import night
C1 = lambda code: night.lua(code, "Client").splitlines()[-1]
COUNT = "local fx=0 local con=game.ReplicatedStorage.Remotes.Fx.OnClientEvent:Connect(function(k) if k=='ping' then fx+=1 end end) local R=game.ReplicatedStorage.Remotes.Ping local h=game.Players.LocalPlayer.Character.HumanoidRootPart "
night.play(True); time.sleep(8); night.key("Q"); time.sleep(33)
night.key("Z"); time.sleep(0.8); print(night.shot("ping").name)
print("marks on screen:", C1("local n=0 for _,d in game.Players.LocalPlayer.PlayerGui.PixelHUD:GetChildren() do if d.Name=='PingMark' then n+=1 end end return n..' beam '..tostring(workspace:FindFirstChild('PingBeam')~=nil)"))
time.sleep(2.2)
print("too far, bad kind, bad types, NaN (0 expected):", C1(COUNT + "R:FireServer(h.Position+Vector3.new(500,0,0),'here') task.wait(2.2) R:FireServer(h.Position,'boo') task.wait(2.2) R:FireServer('x',5) R:FireServer(Vector3.new(0/0,0,0),'here') task.wait(1) con:Disconnect() return fx"))
print("two fast pings (1 expected):", C1(COUNT + "R:FireServer(h.Position+Vector3.new(5,0,0),'ore') R:FireServer(h.Position+Vector3.new(6,0,0),'ore') task.wait(1.2) con:Disconnect() return fx"))
print(night.lua(open(pathlib.Path(__file__).resolve().parent / "hud_overlap.luau", encoding="utf-8").read(), "Client").splitlines()[-1])
