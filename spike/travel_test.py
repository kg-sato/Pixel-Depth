"""Phase B travelling: does the server check every new way to move? Starts Play and tries the hearthstone and the root
ziplines from a wrong place, in a wrong state and twice in a row, then the right way.   python spike/travel_test.py
Shortcuts: the player is put in the caves by the server (attribute InCave and a teleport), prompts are pressed by script
(InputHoldBegin), DevRawHearth keeps the client's own hold out of the way so the test can send every message itself."""
import time
import night as N
C1 = lambda code: N.lua(code, "Client").splitlines()[-1]
S1 = lambda code: N.lua(code, "Server").splitlines()[-1]
P = "local p=game.Players:GetPlayers()[1] local h=p.Character.HumanoidRootPart local cv=workspace.Caves local land=cv:FindFirstChild('LiftLanding',true) "
# send the listed messages on the Travel remote (a number = wait that long) and return every Fx "home" answer
def home(*steps):
    body = " ".join(f"task.wait({s})" if isinstance(s, (int, float)) else f"R:FireServer('{s}')" for s in steps)
    return C1("local R=game.ReplicatedStorage.Remotes.Travel local got={} local con=game.ReplicatedStorage.Remotes.Fx.OnClientEvent:Connect(function(k,w,a) if k=='home' then got[#got+1]=w..':'..(type(a)=='number' and tostring(math.floor(a+0.5)) or tostring(a)) end end) "
              + body + " task.wait(0.6) con:Disconnect() return #got..' '..table.concat(got,' ')")
DIST = P + "local d=(h.Position-(land.Position+Vector3.new(0,3,0))).Magnitude return (d<8 and 'near ' or 'far ')..math.floor(d)"  # near = within 8 studs
# press the nearest zipline handle of rope number k (1, 2 chasm; 3 grotto) and count the Fx "zip" answers within w seconds
def zip_(k, presses, w, fake="false"):  # fake: move the grip to the player on this client only, as a cheat would, so the prompt fires far from the real grip
    return C1("local pr for _,d in workspace.Caves.Ziplines:GetDescendants() do if d:GetAttribute('Zip')==%d then pr=d end end local n=0 "
              "local con=game.ReplicatedStorage.Remotes.Fx.OnClientEvent:Connect(function(kd) if kd=='zip' then n+=1 end end) local cam=workspace.CurrentCamera local was=pr.Parent.CFrame if %s then pr.Parent.CFrame=cam.CFrame*CFrame.new(0,0,-4) end cam.CFrame=CFrame.lookAt(cam.CFrame.Position,pr.Parent.Position) local fired=0 pr.Triggered:Connect(function() fired+=1 end) task.wait(0.4) for i=1,%d do pr:InputHoldBegin() task.wait(0.15) pr:InputHoldEnd() task.wait(0.15) end task.wait(%s) con:Disconnect() pr.Parent.CFrame=was return 'prompt fired '..fired..', '..n" % (k, fake, presses, w))
AT = P + "local pr for _,d in cv.Ziplines:GetDescendants() do if d:GetAttribute('Zip')==%d then pr=d end end h.AssemblyLinearVelocity=Vector3.zero h.CFrame=CFrame.new(pr.Parent.Position+Vector3.new(3,0,0)) return 1"
# how far the player is from the far end of rope k (the end the ride from handle k leads to)
FAR = P + "local r for _,d in cv.Ziplines:GetChildren() do if d:GetAttribute('Rope')==%d then r=d end end local e=r:GetAttribute('%s') local d=((h.Position-e)*Vector3.new(1,0,1)).Magnitude return (d<8 and 'near ' or 'far ')..math.floor(d)"

N.play(True); time.sleep(8)
C1("game.Players.LocalPlayer:SetAttribute('DevRawHearth',true) return 1")
print("hearth in town:", home("home"))
C1("game.ReplicatedStorage.Remotes.Surface:FireServer('down',2) return 1"); time.sleep(9)  # a new player asks for Camp 2: the ride goes to Camp 1
print("camp 2 asked with the gate shut:", S1(P + "local d=(h.Position-land.Position).Magnitude return 'in cave '..tostring(p:GetAttribute('InCave'))..' studs from Camp 1 '..(d<8 and 'near ' or 'far ')..math.floor(d)"))
S1(AT % 1); time.sleep(1.5)  # the chasm ledge, about 140 studs from camp
S1(P + "p:SetAttribute('GrabbedUntil',1) return 1")
print("hearth while grabbed:", home("home"))
S1(P + "p:SetAttribute('GrabbedUntil',nil) return 1")
print("hearth ended early:", home("home", 0.5, "homeEnd"), "| studs from camp:", S1(DIST))
print("hearth end without a start:", home("homeEnd"), "| studs from camp:", S1(DIST))
r = home("home", 1.0)
S1(AT % 2)  # the other side of the bridge: 24 studs away
print("hearth after walking away:", r, home(2.2, "homeEnd"), "| studs from camp:", S1(DIST))
S1(AT % 1); time.sleep(1.5)
print("hearth held 3 s:", home("home", 0.1, "home", 3.05, "homeEnd"), "| studs from camp:", S1(DIST))
print("hearth again at once:", home("home"))
print("ziplines built:", S1("local n,p=0,0 for _,d in workspace.Caves.Ziplines:GetChildren() do if d.Name=='ZipRope' then n+=1 end if d.Name=='ZipHandle' then p+=1 end end return n..' ropes '..p..' handles'"))
print("zip from camp, grip moved on the client:", zip_(1, 1, 1.0, "true"), "rides")
S1(AT % 1); time.sleep(1.5)
S1(P + "p:SetAttribute('GrabbedUntil',1) return 1")
print("zip while grabbed:", zip_(1, 1, 1.0), "rides")
S1(P + "p:SetAttribute('GrabbedUntil',nil) return 1")
print("zip pressed 3 times at the handle:", zip_(1, 3, 5.0), "rides | studs from the far post:", S1(FAR % (1, "ZipB")))
S1(AT % 4); time.sleep(1.5)
print("grotto zip back (handle 4):", zip_(4, 1, 5.5), "rides | studs from the near post:", S1(FAR % (3, "ZipA")))
# the glass lift: the Studio hook DevClay opens the gate and travels; pressed twice, held, left alone
CLAY = P + "local l2=cv:FindFirstChild('ClayLanding',true) local d=(h.Position-l2.Position).Magnitude return 'anchored '..tostring(h.Anchored)..' studs from Camp 2 '..(d<8 and 'near ' or 'far ')..math.floor(d)"
S1(P + "h.AssemblyLinearVelocity=Vector3.zero h.CFrame=land.CFrame+Vector3.new(0,3,0) return 1"); time.sleep(1.5)
C1("local p=game.Players.LocalPlayer local n=0 game.ReplicatedStorage.Remotes.Fx.OnClientEvent:Connect(function(k,a,b) if k=='clayTravel' then n+=1 p:SetAttribute('DevLiftSeen',n..' ride of '..tostring(b)..' s') end end) return 1")
S1(P + "p:SetAttribute('DevClay',2) task.wait(0.2) p:SetAttribute('DevClay',2) return 1"); time.sleep(2)
print("lift asked twice:", C1("return tostring(game.Players.LocalPlayer:GetAttribute('DevLiftSeen'))"))
print("lift, 2 s in:", S1(CLAY), "| picture up:", C1("return tostring(game.Players.LocalPlayer.PlayerGui:FindFirstChild('GlassLift',true).Visible)"), "| hearth:", home("home"))
time.sleep(13)
print("lift, 16 s in:", S1(CLAY), "| picture up:", C1("return tostring(game.Players.LocalPlayer.PlayerGui:FindFirstChild('GlassLift',true).Visible)..' hud '..tostring(game.Players.LocalPlayer.PlayerGui.PixelHUD.Enabled)"))
# choose your camp: back in town (by the server), Q opens the panel, the pick rides to Camp 2
S1(P + "p:SetAttribute('InCave',false) h.CFrame=workspace.Hub:FindFirstChild('HubCart',true):GetPivot()+Vector3.new(6,5,0) return 1"); time.sleep(2)
N.key("Q"); time.sleep(1.5)
print("Q in town with both camps open:", C1("local w=game.Players.LocalPlayer.PlayerGui:FindFirstChild('CampChoice',true) return 'panel '..tostring(w.Visible)..' in cave '..tostring(game.Players.LocalPlayer:GetAttribute('InCave'))"))
C1("game.ReplicatedStorage.Remotes.Surface:FireServer('down',2) return 1"); time.sleep(9)
print("picked Camp 2:", S1(CLAY))
print("client errors:", C1("local t={} for _,m in game:GetService('LogService'):GetLogHistory() do if m.messageType==Enum.MessageType.MessageError and not string.find(m.message,'Requester') then t[#t+1]=string.sub(m.message,1,140) end end return #t..' '..table.concat(t,' | ')"))
N.play(False)
