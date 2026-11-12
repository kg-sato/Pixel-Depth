"""Boon shrine test: pray at a shrine rune, capture the choice card, pick through the remote and print what the server did.
    python spike/boon_test.py     (starts Play itself; shot captures/night/boon_card.png)"""
import sys, time, pathlib
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import night
from prompt_test import trigger, SAFE
C1 = lambda code: night.lua(code, "Client").splitlines()[-1]
S1 = lambda code: night.lua(code, "Server").splitlines()[-1]
ATTR = "local p=game.Players.LocalPlayer local function a() return 'flares '..tostring(p:GetAttribute('Flares'))..' hp '..tostring(p:GetAttribute('HP'))..' shield '..tostring(math.max(0, math.floor((p:GetAttribute('ShieldUntil') or 0)-workspace:GetServerTimeNow()))) end "
FX = "local fx={} local con=game.ReplicatedStorage.Remotes.Fx.OnClientEvent:Connect(function(k,a,b) if string.sub(tostring(k),1,4)=='boon' then table.insert(fx,k..':'..tostring(a)..':'..tostring(b)) end end) "
night.play(True); time.sleep(8); night.key("Q"); time.sleep(33)
print("pray:", trigger("BoonShrine", "1"))
time.sleep(1.2); print(night.shot("boon_card").name)
print(night.lua(open(pathlib.Path(__file__).resolve().parent / "hud_overlap.luau", encoding="utf-8").read(), "Client").splitlines()[-1])
print("bad picks (3, nil, table):", C1(ATTR + FX + "local b=a() local R=game.ReplicatedStorage.Remotes.Boon R:FireServer('pick',3) task.wait(0.4) R:FireServer('pick') task.wait(0.4) R:FireServer({}, 1) task.wait(0.8) con:Disconnect() return b..' -> '..a()..' fx '..table.concat(fx,',')"))
print("pick 1:", C1(ATTR + FX + "local b=a() game.ReplicatedStorage.Remotes.Boon:FireServer('pick',1) task.wait(1.2) con:Disconnect() return b..' -> '..a()..' fx '..table.concat(fx,',')"))
print("pick again (nothing):", C1(ATTR + FX + "local b=a() game.ReplicatedStorage.Remotes.Boon:FireServer('pick',2) task.wait(1.2) con:Disconnect() return b..' -> '..a()..' fx '..table.concat(fx,',')"))
night.lua("local w=game.Players.LocalPlayer.PlayerGui.PixelHUD.Boon w.Visible=false return 1", "Client")
print("pray again (spent):", trigger("BoonShrine", "1"))
night.lua("local w=game.Players.LocalPlayer.PlayerGui.PixelHUD.Boon w.Visible=false return 1", "Client")
