"""Soul Tree test. Needs C.SOUL_TREE.on = true pushed (the script flips nothing itself).
    python spike/soul_test.py     starts Play, rides down, opens the panel at the campfire (shot captures/night/soul_panel.png),
    buys through the remote and prints what the server allowed."""
import sys, time, pathlib
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import night
from prompt_test import trigger, SAFE
C1 = lambda code: night.lua(code, "Client").splitlines()[-1]
S1 = lambda code: night.lua(code, "Server").splitlines()[-1]
night.play(True); time.sleep(8); night.key("Q"); time.sleep(33)
print("shards hook:", S1("local p=game.Players:GetPlayers()[1] p:SetAttribute('DevSoul',20) return 'set'"))
print("open at the campfire:", trigger("SoulTree", "true"))
time.sleep(1.2); print(night.shot("soul_panel").name)
WATCH = "local got local con=game.ReplicatedStorage.Remotes.State.OnClientEvent:Connect(function(s) got=s.soul end) local fx={} local c2=game.ReplicatedStorage.Remotes.Fx.OnClientEvent:Connect(function(k,a,b) if string.sub(tostring(k),1,4)=='soul' then table.insert(fx,k..':'..tostring(a)..':'..tostring(b)) end end) "
DONE = " task.wait(1.2) con:Disconnect() c2:Disconnect() local n={} for k,v in (got and got.nodes or {}) do table.insert(n,k..'='..v) end return (got and ('shards '..got.shards..' nodes '..table.concat(n,',')) or 'no state')..' fx '..table.concat(fx,',')"
print("buy flare (4):", C1(WATCH + "game.ReplicatedStorage.Remotes.Soul:FireServer('buy','flare')" + DONE))
print("buy hide (3):", C1(WATCH + "game.ReplicatedStorage.Remotes.Soul:FireServer('buy','hide')" + DONE))
print("bad node:", C1(WATCH + "game.ReplicatedStorage.Remotes.Soul:FireServer('buy','gold')" + DONE))
print("bad types:", C1(WATCH + "game.ReplicatedStorage.Remotes.Soul:FireServer('buy',{}) task.wait(0.4) game.ReplicatedStorage.Remotes.Soul:FireServer(5,5)" + DONE))
print("buy flare 2 (9):", C1(WATCH + "game.ReplicatedStorage.Remotes.Soul:FireServer('buy','flare')" + DONE))
print("buy flare 3 (full):", C1(WATCH + "game.ReplicatedStorage.Remotes.Soul:FireServer('buy','flare')" + DONE))
print("buy shield, too poor (4 left, costs 3 then 6):", C1(WATCH + "game.ReplicatedStorage.Remotes.Soul:FireServer('buy','shield') task.wait(0.5) game.ReplicatedStorage.Remotes.Soul:FireServer('buy','shield')" + DONE))
time.sleep(1); print(night.shot("soul_panel2").name)
night.lua("local w=game.Players.LocalPlayer.PlayerGui:FindFirstChild('SoulTree',true) w.Visible=false return 1", "Client")
print("flares at camp now:", S1("task.wait(1.5) return tostring(game.Players:GetPlayers()[1]:GetAttribute('Flares'))"))
S1(SAFE + "local C=require(game.ReplicatedStorage.Shared.Config) local best for _,d in workspace.Caves.Deposits:GetChildren() do if d:IsA('Model') and d.PrimaryPart then local m=(d.PrimaryPart.Position-C.CAVE_ORIGIN).Magnitude if m>45 and m<95 then best=d break end end end "
   "game.Players:GetPlayers()[1].Character.HumanoidRootPart.CFrame=CFrame.new(safe(best.PrimaryPart.Position)) game.Players:GetPlayers()[1]:SetAttribute('DevSoul',30) return 1"); time.sleep(3)
print("buy far from the fire (must refuse):", C1(WATCH + "game.ReplicatedStorage.Remotes.Soul:FireServer('buy','hide')" + DONE))
print(night.lua(open(pathlib.Path(__file__).resolve().parent / "hud_overlap.luau", encoding="utf-8").read(), "Client").splitlines()[-1])
