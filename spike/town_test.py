"""Town overhaul checks (2026-11-27), Play running:  python spike/town_test.py [tag]
   1. the Egg Hatchery has one prompt and its panel opens (Fx openHatchery); BUY through the Hatchery remote gets an answer
   2. the Hatchery remote ignores a player far from the hatchery
   3. the signpost's guide lays a gold trail to the forge (Studio hook DevGuide) and captures it
   4. Bolt has no prompt; the forge has no geode bench; the crack prompt is on the refinery's bench"""
import sys, time, pathlib
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import night
tag = sys.argv[1] if len(sys.argv) > 1 else "t"
ok = True
def check(name, cond, info=""):
    global ok
    ok = ok and cond
    print(("PASS " if cond else "FAIL ") + name, info)
def last(code, where): return night.lua(code, where).splitlines()[-1]

r = last("""local h=workspace.Hub local inc=h.Incubator local n=0 for _,d in inc:GetDescendants() do if d:IsA('ProximityPrompt') then n+=1 end end
local bolt=h.Forge:FindFirstChild('Bolt',true) local bp=0 if bolt then for _,d in bolt:GetDescendants() do if d:IsA('ProximityPrompt') then bp+=1 end end end
local bench=h.Forge:FindFirstChild('Bench',true) local cb=h.GeodeRefinery.CrackBench:FindFirstChildOfClass('ProximityPrompt')
return n..' '..bp..' '..tostring(bench~=nil)..' '..tostring(cb~=nil)""", "Server").split()
check("hatchery has one prompt", r[0] == "1", r)
check("Bolt has no prompt", r[1] == "0")
check("forge has no geode bench", r[2] == "false")
check("crack prompt on the refinery bench", r[3] == "true")
BUY = """local got='' local c=game.ReplicatedStorage.Remotes.Fx.OnClientEvent:Connect(function(k) got=got..tostring(k)..',' end)
game.ReplicatedStorage.Remotes.Hatchery:FireServer('buyEgg') task.wait(1.5) c:Disconnect() return got=='' and 'none' or got"""
last("local p=game.Players:GetPlayers()[1] p.Character.HumanoidRootPart.CFrame=CFrame.new(0,6,16) return 'ok'", "Server")
time.sleep(1)
far = last(BUY, "Client")
check("far from the hatchery: ignored", far == "none", far)
last("local p=game.Players:GetPlayers()[1] local b=workspace.Hub.Incubator.Base p.Character.HumanoidRootPart.CFrame=CFrame.new(b.Position-b.CFrame.LookVector*9+Vector3.new(0,4,0)) return 'ok'", "Server")
time.sleep(1.5)
near = last(BUY, "Client")
check("beside the hatchery: answered", near != "none" and ("egg" in near or "noCoins" in near), near)
last("game.ReplicatedStorage.Remotes.Fx:FireClient(game.Players:GetPlayers()[1],'openHatchery') return 'ok'", "Server")
time.sleep(1.2)
vis = last("for _,d in game.Players.LocalPlayer.PlayerGui:GetDescendants() do if d.Name=='HatcheryUI' then return tostring(d.Visible) end end return 'missing'", "Client")
check("hatchery panel opens", vis == "true", vis)
print("shot", night.shot(f"town_{tag}_hatchery_panel"))
last("for _,d in game.Players.LocalPlayer.PlayerGui:GetDescendants() do if d.Name=='HatcheryUI' then d.Visible=false end end return 'ok'", "Client")
last("local p=game.Players:GetPlayers()[1] p.Character.HumanoidRootPart.CFrame=CFrame.new(11,6,-8) return 'ok'", "Server")
time.sleep(1.5)
last("local p=game.Players.LocalPlayer p:SetAttribute('DevGuide',nil) p:SetAttribute('DevGuide','forge') return 'ok'", "Client")
time.sleep(2.5)
n = last("local f=workspace.CurrentCamera:FindFirstChild('TownGuideTrail') return f and #f:GetChildren() or 0", "Client")
check("gold trail laid to the forge", n.isdigit() and int(n) > 5, n)
print("shot", night.shot(f"town_{tag}_guide"))
last("game.Players.LocalPlayer:SetAttribute('DevGuide','picker') return 'ok'", "Client")
time.sleep(1)
print("shot", night.shot(f"town_{tag}_guide_picker"))
last("game.Players.LocalPlayer:SetAttribute('DevGuide',nil) for _,d in game.Players.LocalPlayer.PlayerGui:GetDescendants() do if d.Name=='TownGuide' then d.Visible=false end end return 'ok'", "Client")
print("ALL PASS" if ok else "SOME FAIL")
