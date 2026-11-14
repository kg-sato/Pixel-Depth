"""Directive v9 retention and friends boost: does the server decide the playtime gifts, the Golden Vein Surge and the
Lantern Tether?   python spike/retention_test.py
Shortcuts: DevGiftSecs sets the seconds played today, DevGold starts a short surge, DevFriends counts as friends in the server;
the player is put in the caves by the ride (key Q)."""
import time
import night as N
C1 = lambda code: (N.lua(code, "Client").splitlines() or ["?"])[-1]
S1 = lambda code: (N.lua(code, "Server").splitlines() or ["?"])[-1]
P = "local p=game.Players:GetPlayers()[1] local h=p.Character.HumanoidRootPart "
N.play(True); time.sleep(8)
C1("local p=game.Players.LocalPlayer p:SetAttribute('DevPaid','') game.ReplicatedStorage.Remotes.Fx.OnClientEvent:Connect(function(k,a,b,c) if k=='giftPaid' then p:SetAttribute('DevPaid',(p:GetAttribute('DevPaid') or '')..' '..tostring(a)..':'..tostring(b)) end end) return 1")
PILL = "local g=game.Players.LocalPlayer.PlayerGui:FindFirstChild('Timers',true) return g and (g.Gift.Line.Text..' | '..tostring(g.Event.Visible and g.Event.Line.Text)) or 'no pills'"
print("pills at the start:", C1(PILL))
CLAIM = "game.ReplicatedStorage.Remotes.Gift:FireServer('claim') task.wait(0.9) return tostring(game.Players.LocalPlayer:GetAttribute('DevPaid'))"
print("claim with nothing due:", C1(CLAIM))
S1(P + "p:SetAttribute('DevGiftSecs',301) return 1"); time.sleep(2.5)
print("pill at 5 minutes:", C1(PILL))
print("claim at 5 minutes:", C1(CLAIM))
print("claim again at once:", C1(CLAIM))
S1(P + "p:SetAttribute('DevGiftSecs',1300) return 1"); time.sleep(2.5)
print("two claims at 21 minutes:", C1("local R=game.ReplicatedStorage.Remotes.Gift R:FireServer('claim') task.wait(0.6) R:FireServer('claim') task.wait(0.9) R:FireServer('claim') task.wait(0.9) return tostring(game.Players.LocalPlayer:GetAttribute('DevPaid'))"))
print("bad messages:", C1("local R=game.ReplicatedStorage.Remotes.Gift R:FireServer(7) R:FireServer({}) R:FireServer('claim', 99) task.wait(0.9) return tostring(game.Players.LocalPlayer:GetAttribute('DevPaid'))"))
# the Golden Vein Surge: the strike zone the server sends is twice as wide
N.key("Q"); time.sleep(44)  # the ride down: 30 s, longer in a slow Studio
ZONE = ("local z local con=game.ReplicatedStorage.Remotes.Fx.OnClientEvent:Connect(function(k,dep,kind,t0,arc,zone) if k=='mgStart' and kind=='strike' then z=zone end end) "
        "local h=game.Players.LocalPlayer.Character.HumanoidRootPart local best,bd for _,d in workspace.Caves.Deposits:GetChildren() do local pp=d.PrimaryPart if pp and d:GetAttribute('Game')~='rush' then local m=(pp.Position-h.Position).Magnitude if not bd or m<bd then best,bd=d,m end end end "
        "return 1")
def zone(tries=4):  # walk to deposits further and further away until one starts a Perfect Strike; return the zone the server sent
    for k in range(tries):
        # the deposits nearest the camp, one after another (near the camp no Gloomling comes: a test that wandered off lost its character once)
        S1("local p=game.Players:GetPlayers()[1] local h=p.Character:WaitForChild('HumanoidRootPart',10) local land=workspace.Caves:FindFirstChild('LiftLanding',true) "
           "local list={} for _,d in workspace.Caves.Deposits:GetChildren() do local pp=d.PrimaryPart local pr=pp and d:FindFirstChildWhichIsA('ProximityPrompt',true) if pr and pr.Enabled and not d:GetAttribute('DevUsed') then list[#list+1]={d,(pp.Position-land.Position).Magnitude} end end "
               "table.sort(list,function(a,b) return a[2]<b[2] end) local d=list[1][1] d:SetAttribute('DevUsed',true) local c=d.PrimaryPart.Position local rp=RaycastParams.new() rp.FilterDescendantsInstances={d,p.Character} rp.FilterType=Enum.RaycastFilterType.Exclude local spot for _,r in {5,4,6,3} do for k=0,7 do local a=k*math.pi/4 local at=c+Vector3.new(math.cos(a)*r,0,math.sin(a)*r) local wall=workspace:Raycast(c,at-c,rp) local floor=workspace:Raycast(at+Vector3.new(0,4,0),Vector3.new(0,-10,0),rp) local roof=floor and workspace:Raycast(floor.Position+Vector3.new(0,0.5,0),Vector3.new(0,6,0),rp) if floor and not wall and not roof then spot=floor.Position break end end if spot then break end end if not spot then return 'no floor' end h.AssemblyLinearVelocity=Vector3.zero h.CFrame=CFrame.new(spot+Vector3.new(0,3,0)) return 1")  # on open floor beside the deposit (a blind offset once put the character inside rock)
        time.sleep(1.5)
        r = C1("local z,kd local con=game.ReplicatedStorage.Remotes.Fx.OnClientEvent:Connect(function(k,dep,kind,t0,arc,zn) if k=='mgStart' then z,kd=zn,kind end end) "
               "local h=game.Players.LocalPlayer.Character:WaitForChild('HumanoidRootPart',15) local best,bd for _,d in workspace.Caves.Deposits:GetDescendants() do if d:IsA('ProximityPrompt') and d.Enabled then local m=(d.Parent.Position-h.Position).Magnitude if not bd or m<bd then best,bd=d,m end end end "
               "local cam=workspace.CurrentCamera cam.CFrame=CFrame.lookAt(cam.CFrame.Position,best.Parent.Position) task.wait(0.4) best:InputHoldBegin() task.wait(0.15) best:InputHoldEnd() task.wait(1) con:Disconnect() return tostring(kd)..' '..tostring(z)")
        time.sleep(10)  # let the minigame run out
        if r.startswith("strike"): return r
    return r
z1 = zone()
S1("workspace:SetAttribute('DevGold',60) return 1"); time.sleep(2)
print("event pill in a surge:", C1(PILL))
z2 = zone()
print("strike zone: %s without, %s in a Golden Vein Surge" % (z1, z2))
try: print("zone doubled:", abs(float(z2.split()[1]) - 2 * float(z1.split()[1])) < 0.01)
except Exception: print("zone doubled: unknown")
# the Crystal Rift: the factor the server uses for ore value, in the Clay Caves and in Camp 1, on and off
RIFT = "local E=require(game.ServerScriptService.CaveEvents) local C=require(game.ReplicatedStorage.Shared.Config) return E.riftMult(C.CAVE2_ORIGIN)..' in the Clay Caves, '..E.riftMult(C.CAVE_ORIGIN)..' in Camp 1'"
print("rift off:", S1(RIFT))
S1("workspace:SetAttribute('DevRift',30) return 1"); time.sleep(2.5)
print("rift on:", S1(RIFT), "| pill:", C1(PILL), "| crystal:", C1("return tostring(workspace:FindFirstChild('CrystalRiftFX')~=nil)"))
# the Surface Refinery: no geode, then a geode, a second press while it runs, the pay when it is done, a press from far away
C1("local p=game.Players.LocalPlayer p:SetAttribute('DevRef','') game.ReplicatedStorage.Remotes.Fx.OnClientEvent:Connect(function(k,a,b,c) if k=='refine' then p:SetAttribute('DevRef',(p:GetAttribute('DevRef') or '')..' '..tostring(a)) end end) return 1")
S1(P + "p:SetAttribute('InCave',false) local m=workspace.Hub:FindFirstChild('RefineryMouth') h.CFrame=CFrame.lookAt(m.Position+m.CFrame.LookVector*3.5+Vector3.new(0,2,0),m.Position) return 1"); time.sleep(2.5)
PRESS = ("local pr=workspace.Hub.RefineryMouth:FindFirstChildOfClass('ProximityPrompt') local cam=workspace.CurrentCamera if %s then pr.Parent.CFrame=cam.CFrame*CFrame.new(0,0,-4) end "
         "cam.CFrame=CFrame.lookAt(cam.CFrame.Position,pr.Parent.Position) task.wait(0.5) pr:InputHoldBegin() task.wait(0.15) pr:InputHoldEnd() task.wait(1.2) return tostring(game.Players.LocalPlayer:GetAttribute('DevRef'))")
print("refinery, no geode:", C1(PRESS % "false"))
S1(P + "p:SetAttribute('DevGeodes',1) return 1"); time.sleep(2.5)
print("refinery, a geode in, pressed again:", C1(PRESS % "false"), "|", C1(PRESS % "false"))
S1(P + "p:SetAttribute('DevRefine',0) return 1"); time.sleep(2.5)
print("refinery, done:", C1(PRESS % "false"), "| sign:", C1("return workspace.Hub.RefinerySign.RefineryGui.Line.Text"))
print("refinery, empty again:", C1(PRESS % "false"))
# a geode in hand, the prompt pressed from 40 studs away with the furnace's mouth moved to the player on this client only (as a cheat would)
S1(P + "p:SetAttribute('DevGeodes',1) local m=workspace.Hub:FindFirstChild('RefineryMouth') h.CFrame=CFrame.new(m.Position+m.CFrame.LookVector*40+Vector3.new(0,3,0)) return 1"); time.sleep(2.5)
print("refinery, pressed from far away:", C1(PRESS % "true"))
# the Lantern Tether: ore is worth more with a friend here
print("friends 0:", S1(P + "return tostring(p:GetAttribute('Friends'))"))
S1(P + "p:SetAttribute('DevFriends',2) return 1"); time.sleep(2.5)
print("friends with the hook:", S1(P + "return tostring(p:GetAttribute('Friends'))"), "| board:", C1("local b=workspace.Hub:FindFirstChild('PartyBoard') return b and (b.PartyGui.Line2.Text..' / '..b.PartyGui.Line3.Text) or 'no board'"))
# friends luck on eggs: the table the server rolls from, and the same numbers on the odds panel
print("egg odds, 2 friends:", S1("local C=require(game.ReplicatedStorage.Shared.Config) local o,t=C.eggOdds(2),0 local r={} for i,v in o do t+=v[2] r[i]=string.format('%.2f',v[2]) end return table.concat(r,' ')..' sum '..string.format('%.2f',t)"),
      "| none:", S1("local C=require(game.ReplicatedStorage.Shared.Config) local r={} for i,v in C.eggOdds(0) do r[i]=string.format('%.2f',v[2]) end return table.concat(r,' ')"),
      "| 99 friends:", S1("local C=require(game.ReplicatedStorage.Shared.Config) return string.format('%.2f',C.eggOdds(99)[6][2])..' '..string.format('%.2f',C.eggOdds(-3)[6][2])..' '..string.format('%.2f',C.eggOdds('x')[1][2])"))
print("odds panel, 2 friends:", C1("local o=game.Players.LocalPlayer.PlayerGui:FindFirstChild('Odds',true) return o.Pct1.Text..' '..o.Pct3.Text..' '..o.Pct4.Text..' '..o.Pct5.Text..' '..o.Pct6.Text..' / '..o.Luck.Text"))
print("client errors:", C1("local t={} for _,m in game:GetService('LogService'):GetLogHistory() do if m.messageType==Enum.MessageType.MessageError and not string.find(m.message,'Requester') then t[#t+1]=string.sub(m.message,1,140) end end return #t..' '..table.concat(t,' | ')"))
print("server errors:", S1("local t={} for _,m in game:GetService('LogService'):GetLogHistory() do if m.messageType==Enum.MessageType.MessageError and not string.find(m.message,'Requester') and not string.find(m.message,'AssistantCommand') then t[#t+1]=string.sub(m.message,1,140) end end return #t..' '..table.concat(t,' | ')"))
N.play(False)
