"""Checks for the four Codex review fixes of 2026-11-11. Needs C.SOUL_TREE.on = true pushed.
    python spike/review_fix_test.py"""
import sys, time, pathlib
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import night
from prompt_test import trigger
C1 = lambda code: night.lua(code, "Client").splitlines()[-1]
S1 = lambda code: night.lua(code, "Server").splitlines()[-1]
night.play(True); time.sleep(8); night.key("Q"); time.sleep(33)
EARN = "local got local con=game.ReplicatedStorage.Remotes.State.OnClientEvent:Connect(function(s) got=s.soul end) "
for n in (5, 5, 5, 5):
    S1(f"local p=game.Players:GetPlayers()[1] p:SetAttribute('DevSoulEarn',nil) p:SetAttribute('DevSoulEarn',{n}) return 1")
    time.sleep(0.6)
print("shards after earning 5+5+5+5 under a cap of 12:", C1(EARN + "game.ReplicatedStorage.Remotes.Soul:FireServer('sync') task.wait(1) con:Disconnect() return got and got.shards or 'no state'"))
HIDE = "game.Players.LocalPlayer.PlayerGui.PixelHUD.Boon.Visible=false return 1"
a = trigger("BoonShrine", "1"); C1(HIDE)
b = trigger("BoonShrine", "2"); C1(HIDE)
a2 = trigger("BoonShrine", "1"); C1(HIDE)
print("shrine 1:", a, "| shrine 2:", b, "| shrine 1 again:", a2)
print("offer kept:", C1("return 'see lines above'"))
# take a flare boon if one is on offer at shrine 1, else shield; then ride up and read the state in town
print("pick 1:", C1("local fx={} local con=game.ReplicatedStorage.Remotes.Fx.OnClientEvent:Connect(function(k,a) if k=='boonTaken' then table.insert(fx,tostring(a)) end end) game.ReplicatedStorage.Remotes.Boon:FireServer('pick',1) task.wait(1.2) con:Disconnect() local p=game.Players.LocalPlayer return 'took '..table.concat(fx,',')..' flares '..tostring(p:GetAttribute('Flares'))..' shield '..tostring(math.max(0,math.floor((p:GetAttribute('ShieldUntil') or 0)-workspace:GetServerTimeNow())))"))
C1("game.ReplicatedStorage.Remotes.Surface:FireServer('up') return 1"); time.sleep(70)
print("back in town:", C1("local p=game.Players.LocalPlayer return 'incave '..tostring(p:GetAttribute('InCave'))..' flares '..tostring(p:GetAttribute('Flares'))..' shield left '..tostring(math.max(0,math.floor((p:GetAttribute('ShieldUntil') or 0)-workspace:GetServerTimeNow())))"))
