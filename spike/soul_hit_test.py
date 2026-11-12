"""Soul Tree and boon checks that need a real gloomling or distance. Needs C.SOUL_TREE.on = true pushed.
    python spike/soul_hit_test.py    1) buy two ranks of Thick Hide, stand in the dark, read the first hit (expect 100 - (34 - 16) = 82)
                                     2) take a boon offer, walk away, pick from afar (must be refused)"""
import sys, time, pathlib
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import night
from prompt_test import trigger, SAFE
C1 = lambda code: night.lua(code, "Client").splitlines()[-1]
S1 = lambda code: night.lua(code, "Server").splitlines()[-1]
P = "local p=game.Players:GetPlayers()[1] local h=p.Character.HumanoidRootPart "
night.play(True); time.sleep(8); night.key("Q"); time.sleep(33)
S1("game.Players:GetPlayers()[1]:SetAttribute('DevSoul',20) return 1")
trigger("SoulTree", "true"); time.sleep(1)
print("buy hide twice:", C1("local got local con=game.ReplicatedStorage.Remotes.State.OnClientEvent:Connect(function(s) got=s.soul end) local R=game.ReplicatedStorage.Remotes.Soul R:FireServer('buy','hide') task.wait(0.6) R:FireServer('buy','hide') task.wait(1) con:Disconnect() game.Players.LocalPlayer.PlayerGui.PixelHUD.SoulTree.Visible=false return got and ('hide '..tostring(got.nodes.hide)..' shards '..got.shards) or 'no state'"))
print("boon offer:", trigger("BoonShrine", "1")); time.sleep(0.5)
C1("game.Players.LocalPlayer.PlayerGui:FindFirstChild('Boon',true).Visible=false return 1")
S1(SAFE + P + "local s=workspace.Caves:FindFirstChild('LostLanternSpot',true) local far for _,d in workspace.Caves.Deposits:GetChildren() do if d:IsA('Model') and d.PrimaryPart and (d.PrimaryPart.Position-h.Position).Magnitude>40 then far=d break end end h.CFrame=CFrame.new(safe(far.PrimaryPart.Position)) return 1"); time.sleep(2)
print("boon pick from afar (no boonTaken expected):", C1("local fx={} local con=game.ReplicatedStorage.Remotes.Fx.OnClientEvent:Connect(function(k) if string.sub(tostring(k),1,4)=='boon' then table.insert(fx,k) end end) game.ReplicatedStorage.Remotes.Boon:FireServer('pick',1) task.wait(1.2) con:Disconnect() return 'fx '..table.concat(fx,',')"))
S1(P + "p:SetAttribute('DevBanked',true) p:SetAttribute('DevTorchAge',900) return 1")
print("first hit:", S1(P + "local t0=os.clock() while os.clock()-t0<75 do local hp=p:GetAttribute('HP') if hp and hp<100 then return 'HP after the first hit '..hp..' ('..math.floor(os.clock()-t0)..' s)' end task.wait(0.1) end return 'no hit in 75 s'"))
