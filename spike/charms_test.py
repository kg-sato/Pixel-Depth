"""Charms check (Play running, fresh session): buys the Ore Courier with Dev gold, closes the card, rides down, fills the bag to one
short of full away from camp, extracts a deposit and expects the server's "courier" Fx (the full bag banked for a fee).
Also prints the Extract prompt reach (20 with the Ore Magnet, 10 without).   python spike/charms_test.py"""
import time, night as N
N.lua("local p=game.Players:GetPlayers()[1] p:SetAttribute('DevGold',5000) return 1", "Server"); time.sleep(1.5)
for i in (2, 1): N.lua(f"game.ReplicatedStorage.Remotes.Buy:FireServer('charm',{i}) return 1", "Client"); time.sleep(1.5)
for _ in range(2):
    path = N.lua("for _,d in game.Players.LocalPlayer.PlayerGui:GetDescendants() do if d:IsA('GuiButton') and d.Visible and d.Parent and d.Parent.Name=='Stage' and d:FindFirstAncestor('ForgeCelebrate') then return d:GetFullName() end end return 'none'", "Client").splitlines()[-1]
    if path != "none": N.run("user_mouse_input", {"actions": [{"action": "mouseButtonClick", "mouse_button": "left", "instance_path": path}], "datamodel_type": "Client"}); time.sleep(1)
src = open(__file__.replace("charms_test.py", "sj_test.py"), encoding="utf-8").read()
exec(src.split("SW = (")[0].split('pre = sys.argv[1]\n')[1])
print(go_to("d:GetAttribute('Ore')<3")); time.sleep(1.5); face()
N.lua("local p=game.Players:GetPlayers()[1] p:SetAttribute('DevBag',9) return 1", "Server"); time.sleep(1.5)
N.lua("_G.cour='none' game.ReplicatedStorage.Remotes.Fx.OnClientEvent:Connect(function(k,l) if k=='courier' then _G.cour=tostring(l) end end) return 1", "Client")
N.key("E"); time.sleep(1.0)
for _ in range(3): N.lua("game.Players.LocalPlayer:SetAttribute('DevStrike',os.clock()) return 1", "Client"); time.sleep(0.8)
time.sleep(3.5)
print(N.lua("local d=0 for _,x in workspace.Caves.Deposits:GetDescendants() do if x:IsA('ProximityPrompt') and x.ActionText=='Extract' then d=x.MaxActivationDistance end end return 'courier fee='..tostring(_G.cour)..' reach='..d", "Client").splitlines()[-1])
