"""Master Directive v15 security test (Play, solo): the crucible's STIR is once per refine job, and the forge's HEAT & BLOW rebate
token cannot be replayed, forged, used out of order or late.   python spike/v15_sec_test.py [shots]
With "shots" it also buys a pickaxe with the forging scene on and takes stills of the HEARTH HEAT gauge and PERFECT FORGE!."""
import pathlib, sys, time
here = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(here))
import night as N
P = "local p=game.Players:GetPlayers()[1] local h=p.Character.HumanoidRootPart "
def S(c): return (N.lua(c, "Server").splitlines() or ["?"])[-1]
def C(c): return (N.lua(c, "Client").splitlines() or ["?"])[-1]
res = []
def check(name, ok, detail=""):
    res.append(ok)
    print(("PASS " if ok else "FAIL ") + name + (" | " + detail if detail else ""), flush=True)
N.play(False); N.play(True); time.sleep(10)

# 1 STIR: once per job, refused without a job, refused twice
S(P + "local m=workspace.Hub.RefineryMouth h.CFrame=CFrame.lookAt(m.Position+m.CFrame.LookVector*-3.5+Vector3.new(0,2,0),m.Position) p:SetAttribute('DevGeodes',2) return 1"); time.sleep(1.2)
STIR = ("local pt=workspace.Hub:FindFirstChild('CrucibleStirPoint',true) local pr=pt:FindFirstChildOfClass('ProximityPrompt') local c=workspace.CurrentCamera "
        "c.CFrame=CFrame.lookAt(c.CFrame.Position,pt.Position) task.wait(0.6) local a0=game.Players.LocalPlayer:GetAttribute('RefineAt') pr.Enabled=true pr:InputHoldBegin() task.wait(0.15) pr:InputHoldEnd() task.wait(0.9) "
        "local a1=game.Players.LocalPlayer:GetAttribute('RefineAt') return string.format('%.2f', (a0 or 0)-(a1 or 0))")
r = C(STIR)
check("no job: a stir changes nothing", r == "0.00", r)
C("local pr=workspace.Hub.RefineryMouth:FindFirstChildOfClass('ProximityPrompt') local c=workspace.CurrentCamera c.CFrame=CFrame.lookAt(c.CFrame.Position,pr.Parent.Position) task.wait(0.6) pr:InputHoldBegin() task.wait(0.15) pr:InputHoldEnd() task.wait(1) return 1")
S(P + "p:SetAttribute('DevRefine',60) return 1"); time.sleep(1.5)
r = C(STIR)
check("first stir takes 5 s off", abs(float(r) - 5) < 1.2, r)
time.sleep(1)
r = C(STIR)
check("second stir on the same job is refused", r == "0.00", r)

# 2 HEAT token (FastCine on: no scene, the test drives the remote itself)
C("local p=game.Players.LocalPlayer p:SetAttribute('FastCine',true) _G.HT={} game.ReplicatedStorage.Remotes.Fx.OnClientEvent:Connect(function(k,a,b,c) if k=='bought' and b=='pick' then _G.HT.id=c end end) "
  "game.ReplicatedStorage.Remotes.Heat.OnClientEvent:Connect(function(k,id,a) table.insert(_G.HT,k..':'..tostring(a)) if k=='start' then _G.HT.start=a end end) return 1")
def buy():
    S(P + "p:SetAttribute('DevGold',100000) p:SetAttribute('DevOres',60) return 1"); time.sleep(1.2)
    C("_G.HT.id=nil game.ReplicatedStorage.Remotes.Buy:FireServer('pick') return 1"); time.sleep(1.5)
    return C("return tostring(_G.HT.id)")
GOLD = "return tostring(game.Players:GetPlayers()[1]:GetAttribute('Gold') or 'nil')"
gold = lambda: S("local p=game.Players:GetPlayers()[1] local ls=p:FindFirstChild('leaderstats') return tostring(ls and ls:FindFirstChildWhichIsA('IntValue') and ls:FindFirstChildWhichIsA('IntValue').Value)")
tok = buy()
check("a new pickaxe hands out a token", tok not in ("nil", "?"), tok)
r = C(f"table.clear(_G.HT) local R=game.ReplicatedStorage.Remotes.Heat R:FireServer('press','{tok}') task.wait(0.5) R:FireServer('start','{tok}') task.wait(0.6) return table.concat(_G.HT,',')")
check("a press before start uses the token up (no start after it)", "start" not in r, r)
tok2 = buy()
r = C(f"table.clear(_G.HT) local R=game.ReplicatedStorage.Remotes.Heat R:FireServer('start','forged-id') R:FireServer('start','{tok}') task.wait(0.6) return #_G.HT==0 and 'nothing' or table.concat(_G.HT,',')")
check("a forged or old token is ignored", r == "nothing", r)
r = C(f"table.clear(_G.HT) _G.HT.start=nil local R=game.ReplicatedStorage.Remotes.Heat local Cf=require(game.ReplicatedStorage.Shared.Config) R:FireServer('start','{tok2}') "
      "local t0=os.clock() while not _G.HT.start and os.clock()-t0<2 do task.wait() end if not _G.HT.start then return 'no start' end "
      "while true do local el=workspace:GetServerTimeNow()-_G.HT.start if math.abs(Cf.heatAt(el+0.05)-0.5)<0.03 or el>2.3 then break end task.wait() end "
      f"R:FireServer('press','{tok2}') task.wait(0.7) R:FireServer('press','{tok2}') task.wait(0.6) return table.concat(_G.HT,',')")
check("a press in the gold is PERFECT and pays the rebate once", r.count("perfect:") == 1 and r.count(":") == 2, r)
tok3 = buy()
r = C(f"table.clear(_G.HT) local R=game.ReplicatedStorage.Remotes.Heat task.wait(25.5) R:FireServer('start','{tok3}') task.wait(0.6) return #_G.HT==0 and 'nothing' or table.concat(_G.HT,',')")
check("a token older than C.HEAT.life (25 s) is dead", r == "nothing", r)
tok4 = buy()
r = C(f"table.clear(_G.HT) _G.HT.start=nil local R=game.ReplicatedStorage.Remotes.Heat local Cf=require(game.ReplicatedStorage.Shared.Config) R:FireServer('start','{tok4}') "
      "local t0=os.clock() while not _G.HT.start and os.clock()-t0<2 do task.wait() end "
      "while true do local el=workspace:GetServerTimeNow()-_G.HT.start if math.abs(Cf.heatAt(el)-0.5)>0.4 then break end task.wait() end "
      f"R:FireServer('press','{tok4}') task.wait(0.7) return table.concat(_G.HT,',')")
check("a press far from the gold is a miss (no pay)", "miss" in r and "perfect" not in r, r)
C("game.Players.LocalPlayer:SetAttribute('FastCine',nil) return 1")

if len(sys.argv) > 1 and sys.argv[1] == "shots":  # the scene itself: the gauge, then PERFECT FORGE! from a well-timed press
    S(P + "p:SetAttribute('DevGold',100000) p:SetAttribute('DevOres',60) return 1"); time.sleep(1.2)
    C("table.clear(_G.HT) _G.HT.start=nil _G.HT.id=nil game.ReplicatedStorage.Remotes.Buy:FireServer('pick') "
      "task.spawn(function() local Cf=require(game.ReplicatedStorage.Shared.Config) local t0=os.clock() while not _G.HT.start and os.clock()-t0<20 do task.wait() end if not _G.HT.start then return end "
      "task.wait(0.9) while true do local el=workspace:GetServerTimeNow()-_G.HT.start if math.abs(Cf.heatAt(el+0.05)-0.5)<0.03 or el>2.3 then break end task.wait() end "
      "game.ReplicatedStorage.Remotes.Heat:FireServer('press',_G.HT.id) end) return 1")
    for _ in range(120):
        if C("return tostring(_G.HT.start~=nil)") == "true": break
        time.sleep(0.15)
    time.sleep(0.4); print(N.shot("v15_heat_gauge").name)
    time.sleep(0.9); print(N.shot("v15_heat_perfect").name)
    time.sleep(6)
print(f"{sum(res)} of {len(res)} PASS")
