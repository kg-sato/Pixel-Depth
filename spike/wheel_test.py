"""The utility wheel: captures of the open wheel in town and in the caves, then the sonar, the flare (away from camp:
the camp refills flares at once) and the refused wardrobe picked through it.
    python spike/wheel_test.py     (starts Play itself; shots captures/night/wheel_town.png, wheel_cave.png)"""
import sys, time, pathlib
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import night
from prompt_test import SAFE
night.play(True); time.sleep(5)
night.key("Tab"); time.sleep(0.6); print(night.shot("wheel_town").name); night.key("Tab"); time.sleep(0.5)
night.key("Q"); time.sleep(33)
night.key("Tab"); time.sleep(0.6); print(night.shot("wheel_cave").name); night.key("Tab")
print("sonar:", night.lua("local p=game.Players.LocalPlayer p:SetAttribute('DevSonarSlow',6) p:SetAttribute('DevWheel',1) task.wait(0.5) local f=workspace:FindFirstChild('Sonar') return tostring(f and f:FindFirstChild('Shell') ~= nil)", "Client").splitlines()[-1])
night.lua(SAFE + "local C=require(game.ReplicatedStorage.Shared.Config) local best for _,d in workspace.Caves.Deposits:GetChildren() do if d:IsA('Model') and d.PrimaryPart then local m=(d.PrimaryPart.Position-C.CAVE_ORIGIN).Magnitude if m>45 and m<95 then best=d break end end end "
          "game.Players:GetPlayers()[1].Character.HumanoidRootPart.CFrame=CFrame.new(safe(best.PrimaryPart.Position)) return 1", "Server"); time.sleep(3)
print("flare:", night.lua("local p=game.Players.LocalPlayer local a=p:GetAttribute('Flares') p:SetAttribute('DevWheel',nil) p:SetAttribute('DevWheel',2) task.wait(1.5) return tostring(a)..' -> '..tostring(p:GetAttribute('Flares'))", "Client").splitlines()[-1])
print("wardrobe slot in a cave (it is HOME there, the wardrobe must stay shut):", night.lua("local p=game.Players.LocalPlayer p:SetAttribute('DevWheel',nil) p:SetAttribute('DevWheel',4) task.wait(0.8) local n=0 for _,m in p.PlayerGui.PixelHUD:GetChildren() do if m.Name=='Wardrobe' and m.Visible then n+=1 end end local w=p.PlayerGui.PixelHUD.UtilityWheel local v=w.Visible return n..' open, wheel stayed '..tostring(v)", "Client").splitlines()[-1])
night.key("Tab"); time.sleep(0.4)
print(night.lua(open(pathlib.Path(__file__).resolve().parent / "hud_overlap.luau", encoding="utf-8").read(), "Client").splitlines()[-1])
