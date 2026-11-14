"""Phase C bosses: one whole Root Warden fight, won without a hit. An autopilot on the client strikes each knot when the
needle is on the gold (through the real remote), jumps the slam, steps out of the sweep lane and stands in a ring gap.
Checks the order of the fight, the boss frame and the reward chest.     python spike/boss_fight_test.py [shots]
Shortcuts: the player is put in the caves and before the Warden by the server, DevEquip gives the needed pickaxe, DevBoss
starts the fight from there; the autopilot moves its own character (as a player's client may)."""
import sys, time
import night as N
C1 = lambda code: (N.lua(code, "Client").splitlines() or ["?"])[-1]
S1 = lambda code: (N.lua(code, "Server").splitlines() or ["?"])[-1]
SHOTS = "shots" in sys.argv
P = "local p=game.Players:GetPlayers()[1] local h=p.Character.HumanoidRootPart local cv=workspace.Caves "
PILOT = r'''
local p = game.Players.LocalPlayer
local R = game.ReplicatedStorage.Remotes
local w = workspace.Caves:FindFirstChild("Warden", true)
p:SetAttribute("DevBossLog", "")
local function note(s) p:SetAttribute("DevBossLog", (p:GetAttribute("DevBossLog") or "") .. " " .. s) end
local function hrp() return p.Character.HumanoidRootPart end
local function ring(r, turn) -- stand r studs from the boss, turned by this many radians round it
	local o = w.PrimaryPart.Position
	local d = ((hrp().Position - o) * Vector3.new(1, 0, 1)).Unit
	d = CFrame.Angles(0, turn or 0, 0):VectorToWorldSpace(d)
	hrp().CFrame = CFrame.new(o.X + d.X * r, hrp().Position.Y, o.Z + d.Z * r)
end
R.Fx.OnClientEvent:Connect(function(kind, a, b, c)
	if string.sub(kind, 1, 4) == "boss" then note(kind .. (kind == "bossKnot" and (":" .. tostring(a)) or "") .. (kind == "bossHit" and (":" .. tostring(c)) or "")) end
	if kind == "bossSlam" then
		task.delay(math.max(0, a - workspace:GetServerTimeNow() - 0.4), function() p.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end)
	elseif kind == "bossSweep" then
		task.delay(0.5, function() ring(10, -math.pi / 4) end) -- 7 studs out of the lane's middle
		task.delay(3, function() ring(10, math.pi / 4) end)
	elseif kind == "bossRings" then
		task.delay(0.5, function() ring(10.5) end) -- the first gap
	elseif kind == "mgStart" and b == "strike" then
		task.spawn(function()
			local hud = p.PlayerGui:FindFirstChild("PerfectStrike", true)
			local t0 = os.clock()
			while hud and not hud.Visible and os.clock() - t0 < 4 do task.wait() end
			local nd, ar = hud and hud:FindFirstChild("Needle", true), hud and hud:FindFirstChild("Arc", true)
			if not nd or not ar then return note("no-dial") end
			for n = 1, 6 do
				local t1 = os.clock()
				while hud.Visible and os.clock() - t1 < 3 do
					if math.abs((nd.Rotation - ar.Rotation + 180) % 360 - 180) < 4 then break end
					task.wait()
				end
				if not hud.Visible then break end
				R.Extract:FireServer("strike", workspace:GetServerTimeNow())
				task.wait(0.35)
			end
		end)
	end
end)
return 1
'''
AT = (P + "local w=cv:FindFirstChild('Warden',true) local o=w.PrimaryPart.Position local d=Vector3.new(math.cos(math.rad(315)),0,math.sin(math.rad(315))) "
      "local rp=RaycastParams.new() rp.FilterDescendantsInstances={w,p.Character} rp.FilterType=Enum.RaycastFilterType.Exclude "
      "local hit=workspace:Raycast(o+d*10+Vector3.new(0,6,0),Vector3.new(0,-14,0),rp) "
      "h.AssemblyLinearVelocity=Vector3.zero h.CFrame=CFrame.lookAt(hit.Position+Vector3.new(0,3,0),Vector3.new(o.X,hit.Position.Y+3,o.Z)) return 1")
N.play(True); time.sleep(8)
S1(P + "p:SetAttribute('InCave',true) p:SetAttribute('DevEquip',6) return 1"); time.sleep(1)
S1(AT); time.sleep(1.5)
C1("local w=workspace.Caves:FindFirstChild('Warden',true) local cam=workspace.CurrentCamera cam.CFrame=CFrame.lookAt(cam.CFrame.Position,w.PrimaryPart.Position) return 1")
C1(PILOT)
S1(P + "p:SetAttribute('DevBoss',1) return 1"); time.sleep(1.1)
print("frame at the start:", C1("local g=game.Players.LocalPlayer.PlayerGui local b,n=g:FindFirstChild('BossBar',true),g:FindFirstChild('BossBanner',true) return 'bar '..tostring(b.Visible)..' banner '..tostring(n.Visible)..' '..n.Text"))
if SHOTS: N.shot("boss_wake")
if SHOTS: time.sleep(3.2); N.shot("boss_knot")
for _ in range(40):
    time.sleep(2)
    log = C1("return tostring(game.Players.LocalPlayer:GetAttribute('DevBossLog'))")
    if "bossWin" in log or "bossLose" in log: break
print("fight:", log.strip())
# a knot may hold when Studio is slow (the autopilot swings late): the order then has more attacks, the result must be the same
print("fight summary: won %s, hits %d, slam %s, sweep %s, rings %s" % ("bossWin" in log, log.count("bossHit"), "bossSlam" in log, "bossSweep" in log, "bossRings" in log))
time.sleep(4.2)
print("reward:", C1("local g=game.Players.LocalPlayer.PlayerGui local d=g:FindFirstChild('DailyChest') local t='' if d then for _,o in d:GetDescendants() do if o:IsA('TextLabel') and string.find(o.Text,'CHEST') then t=o.Text end end end "
                    "return 'chest layer '..tostring(d and d.Enabled)..' title '..t..' bar '..tostring(g:FindFirstChild('BossBar',true).Visible)"))
if SHOTS: N.shot("boss_chest")
print("after:", S1(P + "return 'hp '..tostring(p:GetAttribute('HP'))"))
print("client errors:", C1("local t={} for _,m in game:GetService('LogService'):GetLogHistory() do if m.messageType==Enum.MessageType.MessageError and not string.find(m.message,'Requester') then t[#t+1]=string.sub(m.message,1,140) end end return #t..' '..table.concat(t,' | ')"))
N.play(False)
