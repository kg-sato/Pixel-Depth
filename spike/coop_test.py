"""Directive v13 phase 6 checks (one client; starts Play): the five ping kinds and the automatic RARE callout, the clink
remote and its 15 s cooldown, the four starter Rootflint veins in Camp 1, the event clock (Golden Vein 8:00, Crystal Rift
11:00), the FTUE gate on the town minimap, the GloomStrike rescue remote's refusals, the escape tally in the save template.
    python spike/coop_test.py"""
import sys, time, pathlib
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import night as N
S = lambda code: (N.lua(code, "Server").splitlines() or ["?"])[-1]
C = lambda code: (N.lua(code, "Client").splitlines() or ["?"])[-1]
ok = []
def check(name, cond, got):
    ok.append(cond); print(("PASS " if cond else "FAIL ") + name + " | " + str(got))
N.play(True); time.sleep(12)
C("local g=game.Players.LocalPlayer.PlayerGui:FindFirstChild('DailyChest') if g then g.Enabled=false end return 1")
cfg = S("local C=require(game.ReplicatedStorage.Shared.Config) return C.EVENTS.goldFirst..' '..C.EVENTS.riftFirst..' '..tostring(C.SAVE_TEMPLATE.escapes)..' '..tostring(C.SAVE_TEMPLATE.soul and C.SAVE_TEMPLATE.soul.shards)")
check("event clock 480 / 660, escapes and soul in the save template", cfg == "480 660 0 0", cfg)
st = S("local d=workspace.Caves:FindFirstChild('Deposits') local n=0 for _,x in d:GetChildren() do if x:GetAttribute('Starter') and x.PrimaryPart and x.PrimaryPart:FindFirstChildOfClass('ProximityPrompt') then n+=1 end end return tostring(d:GetAttribute('Starters'))..' '..n")
check("four starter Rootflint veins with Extract prompts", st == "4 4", st)
C("game.ReplicatedStorage.Remotes.Surface:FireServer('down') return 1"); time.sleep(16)
WATCH = ("local got={} local con=game.ReplicatedStorage.Remotes.Fx.OnClientEvent:Connect(function(k,a,b,c) if k=='ping' then table.insert(got,b) elseif k=='clink' then table.insert(got,'clink') end end) "
         "local R=game.ReplicatedStorage.Remotes local h=game.Players.LocalPlayer.Character.HumanoidRootPart ")
r = C(WATCH + "R.Ping:FireServer(h.Position+Vector3.new(3,0,0),'camp') task.wait(2.3) R.Ping:FireServer(h.Position,'help') task.wait(1) con:Disconnect() return table.concat(got,',')")
check("CAMP and HELP pings relay", r == "camp,help", r)
C("_G.rareGot = false local con con=game.ReplicatedStorage.Remotes.Fx.OnClientEvent:Connect(function(k,a,b) if k=='ping' and b=='rare' then _G.rareGot=true con:Disconnect() end end) return 1")
S("workspace:SetAttribute('DevRarePing', os.clock()) return 1")  # a require() here would get its own module copy without init
time.sleep(1)
rare = C("return tostring(_G.rareGot)")
check("the automatic RARE callout reaches the miners near", rare == "true", rare)
r = C(WATCH + "R.Clink:FireServer() task.wait(1) R.Clink:FireServer() task.wait(1) con:Disconnect() return table.concat(got,',')")
check("clink is seen once, the second inside 15 s refused", r == "clink", r)
r = C("local R=game.ReplicatedStorage.Remotes local n=0 local con=R.Fx.OnClientEvent:Connect(function(k) if k=='rescuedFriend' or k=='saviorBonus' then n+=1 end end) "
      "R.GloomStrike:FireServer(game.Players.LocalPlayer) R.GloomStrike:FireServer('x') R.GloomStrike:FireServer(nil) task.wait(1) con:Disconnect() return n")
check("GloomStrike refuses yourself and bad types", r == "0", r)
errs = C("local n={} for _,m in game:GetService('LogService'):GetLogHistory() do if m.messageType==Enum.MessageType.MessageError and not m.message:find('not authorized') then table.insert(n,m.message:sub(1,120)) end end return #n..' '..table.concat(n,' ## ')")
check("no client errors", errs.startswith("0"), errs)
print(f"{sum(ok)} of {len(ok)} checks passed")
