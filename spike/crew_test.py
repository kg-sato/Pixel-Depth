"""The crew ride, step 1: the boarding clock on Camp 1's cart, and a passenger's view of a run the driver plays.
    python spike/crew_test.py
One player only: part A boards alone (the sign, the seat, the solo ride blocked while aboard, the driver's "go now"); part B
uses the Studio hook DevCrewBot, where the server plays the driver and this player is the passenger. Two real players in one
cart are NOT tested here. Shortcuts: key Q rides down, teleports to the cart, prompts pressed by script."""
import time
import night as N
C1 = lambda code: (N.lua(code, "Client").splitlines() or ["?"])[-1]
S1 = lambda code: (N.lua(code, "Server").splitlines() or ["?"])[-1]
P = "local p=game.Players:GetPlayers()[1] local h=p.Character.HumanoidRootPart local body=workspace.Caves:FindFirstChild('CartBody',true) "
PRESS = ("local p=game.Players.LocalPlayer local a=workspace.Caves:FindFirstChild('%s',true) local pr=a:FindFirstChildOfClass('ProximityPrompt') local cam=workspace.CurrentCamera "
         "cam.CFrame=CFrame.lookAt(cam.CFrame.Position,a.Position) task.wait(0.5) pr:InputHoldBegin() task.wait(0.15) pr:InputHoldEnd() task.wait(1.6) "
         "local line=workspace.Caves:FindFirstChild('CrewAnchor',true):FindFirstChild('Line',true) "
         "return 'seat '..tostring(p:GetAttribute('CrewSeat'))..' | '..line.Text..' | seated '..tostring(p:GetAttribute('Seated'))..' | ride '..tostring(workspace:FindFirstChild('MinecartEscape')~=nil)")

def down():
    N.play(True); time.sleep(6)
    N.key("Q"); time.sleep(32)
    print("in the caves:", S1(P + "if (h.Position-body.Position).Magnitude>9 then h.CFrame=body.CFrame*CFrame.new(0,3,6) end return tostring(p:GetAttribute('InCave'))"))
    time.sleep(1.5)

# A: boarding alone
down()
print("sign before:", S1("return workspace.Caves:FindFirstChild('CrewAnchor',true):FindFirstChild('Line',true).Text"))
print("board:", C1(PRESS % "CrewAnchor"))
print("solo ride while aboard:", C1(PRESS % "CartBody"))
print("driver presses again:", C1(PRESS % "CrewAnchor"))
print("driver's own run:", C1("local t=os.clock() while os.clock()-t<6 and not workspace:FindFirstChild('MinecartEscape') do task.wait(0.1) end return 'ride '..tostring(workspace:FindFirstChild('MinecartEscape')~=nil)"))
print("client errors A:", C1("local t={} for _,m in game:GetService('LogService'):GetLogHistory() do if m.messageType==Enum.MessageType.MessageError and not string.find(m.message,'Requester') then t[#t+1]=string.sub(m.message,1,140) end end return #t..' '..table.concat(t,' | ')"))
N.play(False); time.sleep(2)

# B: a passenger of the server's own driver
down()
C1("local p=game.Players.LocalPlayer p:SetAttribute('DevCrew',true) p:SetAttribute('DevCrewPaid',nil) game.ReplicatedStorage.Remotes.Fx.OnClientEvent:Connect(function(k,a,b) if k=='escapeDone' then "
   "p:SetAttribute('DevCrewCard', type(b)=='table' and ('gem '..b.gem..' riders '..b.n..' x'..b.mult..' hits '..b.hits..' flares '..b.flares..' moves '..b.moHit..'/'..b.moN) or 'no crew') p:SetAttribute('DevCrewPaid',a) end end) return 1")
# step 3, crew moments: the server's driver calls two; a watcher armed now answers the first in time and lets the second pass
C1("local p=game.Players.LocalPlayer local R=game.ReplicatedStorage.Remotes.Crew local n,log=0,'' R.OnClientEvent:Connect(function(k,a) "
   "if k=='m' then n+=1 log=log..' call:'..tostring(a) if n==1 then task.delay(0.3,function() R:FireServer('a') R:FireServer('a') end) end "
   "elseif k=='M' then log=log..' verdict:'..tostring(a) end p:SetAttribute('DevCrewMoments',log) end) return 1")
S1(P + "p:SetAttribute('DevCrewBot',true) return 1")
print("passenger:", C1("local p=game.Players.LocalPlayer local function st() local r={} for w in string.gmatch(p:GetAttribute('DevCrewState') or '', '%S+') do r[#r+1]=w end return r end "
      "local t=os.clock() while os.clock()-t<10 and not workspace:FindFirstChild('MinecartEscape') do task.wait(0.1) end task.wait(7) "
      "local a=st() local top=0 for _=1,30 do task.wait(0.1) top=math.max(top,tonumber(st()[4]) or 0) end local b=st() "
      "return 'replica '..tostring(b[1])..' seat x '..tostring(b[6])..' moved '..tostring(tonumber(b[2])-tonumber(a[2])>40)..' near the driver '..tostring(math.abs(tonumber(b[2])-tonumber(b[3]))<12)..' things on the rail '..tostring(top>=1)..' mates '..tostring(b[5])"))
# step 2, the stoker (this passenger's job in a crew of two): a press in the gold is a hit, a press outside is a miss, and
# presses faster than the cooldown are not judged. The client works out the needle with the same sums as the server.
HEAD = ("local p=game.Players.LocalPlayer local RS=game.ReplicatedStorage local C=require(RS.Shared.Config) local S=C.CREW.stoke local R=RS.Remotes.Crew "
        "local got={} local c=R.OnClientEvent:Connect(function(k,a,b,cc) if k=='k' then got[#got+1]=tostring(a)..' '..string.format('%.1f',b)..' '..tostring(cc) end end) "
        "local function st() local r={} for w in string.gmatch(p:GetAttribute('DevCrewState') or '', '%S+') do r[#r+1]=w end return r end ")
print("stoker:", C1(HEAD +
      "local t0=p:GetAttribute('DevCrewT0') local hits=0 "
      "local function waitFor(inside) local t=os.clock() while os.clock()-t<6 do local z=C.stokeZone(4242,hits) local x=C.stokeAt(t0,workspace:GetServerTimeNow()) "
      "if (inside and x>z+0.08 and x<z+S.zone-0.08) or (not inside and (x<z-0.25 or x>z+S.zone+0.25)) then return end task.wait() end end "
      "waitFor(true) R:FireServer('k') task.wait(0.7) hits=1 waitFor(false) R:FireServer('k') task.wait(0.7) "
      "R:FireServer('k') R:FireServer('k') R:FireServer('k') task.wait(0.8) c:Disconnect() "
      "return 'job '..tostring(st()[10])..' | in the gold: '..tostring(got[1])..' | outside: '..tostring(got[2])..' | three at once judged: '..(#got-2)..' | bar '..tostring(p.PlayerGui:FindFirstChild('Stoke',true)~=nil)"))
# step 3, flares (the stoker throws them in a crew of two): one throw is counted, a second at once is not
print("flares:", C1("local p=game.Players.LocalPlayer local R=game.ReplicatedStorage.Remotes.Crew local got={} local c=R.OnClientEvent:Connect(function(k,a) if k=='t' then got[#got+1]=tostring(a) end end) "
      "R:FireServer('f') task.wait(0.4) R:FireServer('f') task.wait(0.9) c:Disconnect() local s='' for w in string.gmatch(p:GetAttribute('DevCrewState') or '', '%S+') do s=w end "
      "return 'thrown '..#got..' left '..tostring(got[1])..' | on screen '..s..' | button '..tostring(p.PlayerGui:FindFirstChild('Flares',true)~=nil)"))
time.sleep(4)
print("moments:", C1("local p=game.Players.LocalPlayer local t=os.clock() while os.clock()-t<30 and not string.find(p:GetAttribute('DevCrewMoments') or '', 'verdict.*verdict') do task.wait(0.2) end return tostring(p:GetAttribute('DevCrewMoments'))"))
print("home:", C1("local p=game.Players.LocalPlayer local t=os.clock() while os.clock()-t<25 and p:GetAttribute('DevCrewPaid')==nil do task.wait(0.2) end task.wait(1) return 'paid '..tostring(p:GetAttribute('DevCrewPaid'))..' in cave '..tostring(p:GetAttribute('InCave'))"))
# step 4: the crew's numbers reach the client and its result card; a second crew ride the same day pays no gem
print("crew numbers:", C1("return tostring(game.Players.LocalPlayer:GetAttribute('DevCrewCard'))"))
print("result card:", C1("local g=game.Players.LocalPlayer.PlayerGui local t=os.clock() local out='no card' while os.clock()-t<12 do local e=g:FindFirstChild('MinecartEscapeGui') local r={} "
      "for _,d in e and e:GetDescendants() or {} do if d:IsA('TextLabel') and (string.find(d.Text,'RIDERS') or string.find(d.Text,'COINS') or string.find(d.Text,' OF ')) then r[#r+1]=d.Text end end "
      "if #r>=3 then table.sort(r) out=table.concat(r,' | ') break end task.wait(0.2) end return out"))
time.sleep(12)
N.key("Q"); time.sleep(32)
C1("local p=game.Players.LocalPlayer p:SetAttribute('DevCrewPaid',nil) p:SetAttribute('DevCrewCard',nil) return 1")
S1(P + "if (h.Position-body.Position).Magnitude>9 then h.CFrame=body.CFrame*CFrame.new(0,3,6) end p:SetAttribute('DevCrewBot',true) return tostring(p:GetAttribute('InCave'))")
print("second crew ride the same day:", C1("local p=game.Players.LocalPlayer local t=os.clock() while os.clock()-t<75 and p:GetAttribute('DevCrewPaid')==nil do task.wait(0.2) end return 'paid '..tostring(p:GetAttribute('DevCrewPaid'))..' | '..tostring(p:GetAttribute('DevCrewCard'))"))
# a passenger (or anyone not driving) cannot feed the relay: nothing errors and nothing comes back
print("messages from a non-driver:", C1("local R=game.ReplicatedStorage.Remotes.Crew local got=0 local c=R.OnClientEvent:Connect(function() got+=1 end) R:FireServer('s',1,1,0,1) R:FireServer('r',9,1e9,true) R:FireServer({}) R:FireServer('p','x') task.wait(1.2) c:Disconnect() return 'echoes '..got"))
print("client errors B:", C1("local t={} for _,m in game:GetService('LogService'):GetLogHistory() do if m.messageType==Enum.MessageType.MessageError and not string.find(m.message,'Requester') then t[#t+1]=string.sub(m.message,1,140) end end return #t..' '..table.concat(t,' | ')"))
print("server errors:", S1("local t={} for _,m in game:GetService('LogService'):GetLogHistory() do if m.messageType==Enum.MessageType.MessageError and not string.find(m.message,'Requester') and not string.find(m.message,'AssistantCommand') then t[#t+1]=string.sub(m.message,1,140) end end return #t..' '..table.concat(t,' | ')"))
N.play(False); time.sleep(2)

# C: step 2, the lookout (seat 2 of three): its jump reaches the cart, a stoke press from it is ignored
down()
C1("game.Players.LocalPlayer:SetAttribute('DevCrew',true) return 1")
S1(P + "p:SetAttribute('DevCrewBot','lookout') return 1")
print("lookout:", C1(HEAD + "local t=os.clock() while os.clock()-t<10 and not workspace:FindFirstChild('MinecartEscape') do task.wait(0.1) end task.wait(6) "
      "local fl=0 local c2=R.OnClientEvent:Connect(function(k) if k=='t' then fl+=1 end end) "
      "local a=tonumber(st()[7]) or -1 R:FireServer('j') task.wait(1.2) local b=tonumber(st()[7]) or -1 R:FireServer('k') R:FireServer('f') task.wait(0.9) c:Disconnect() c2:Disconnect() "
      "return 'job '..tostring(st()[10])..' | jumps the cart made: '..(b-a)..' | stoke replies: '..#got..' | flares thrown: '..fl..' | bar '..tostring(p.PlayerGui:FindFirstChild('Stoke',true)~=nil)"))
# step 4: the driver leaves and this rider is next: its screen becomes the run and the cart keeps going
S1(P + "p:SetAttribute('DevCrewPromote',true) return 1")
print("the driver left:", C1("local p=game.Players.LocalPlayer local function st() local r={} for w in string.gmatch(p:GetAttribute('DevCrewState') or '', '%S+') do r[#r+1]=w end return r end "
      "task.wait(2.5) local a=st() task.wait(5) local b=st() return 'replica '..tostring(b[1])..' job '..tostring(b[10])..' still moving '..tostring(tonumber(b[2])-tonumber(a[2])>40)..' in the cave '..tostring(p:GetAttribute('InCave'))"))
print("client errors C:", C1("local t={} for _,m in game:GetService('LogService'):GetLogHistory() do if m.messageType==Enum.MessageType.MessageError and not string.find(m.message,'Requester') then t[#t+1]=string.sub(m.message,1,140) end end return #t..' '..table.concat(t,' | ')"))
print("server errors C:", S1("local t={} for _,m in game:GetService('LogService'):GetLogHistory() do if m.messageType==Enum.MessageType.MessageError and not string.find(m.message,'Requester') and not string.find(m.message,'AssistantCommand') then t[#t+1]=string.sub(m.message,1,140) end end return #t..' '..table.concat(t,' | ')"))
N.play(False)
