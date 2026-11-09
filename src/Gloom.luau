-- Gloom (ServerScriptService.Gloom): gloomlings, HP, the catch and flares in the shared caves (roadmap phase 6, The Gloom).
-- Plan: vault Briefs/The Gloom (2026-11-09).md and Lore and Gameplay Plan A5. The server decides everything here:
-- - the torch: relit inside Camp 1's ring, then it burns down over C.TORCH.time; fear = (1 - fuel) * 1.15 - 0.1 (as the HUD shows).
--   Until a player has banked ore once, the torch does not dim and no gloomling comes (learn the rules first).
-- - gloomlings: soot sprites that slip through rock. At UNEASY one creeps in from the dark behind you, at SCARED two; they never
--   move as fast as you walk. A touch is a BONK (C.GLOOM.hit HP). At 0 HP you are caught: 25% of the unbanked ore is gone, HP
--   refills and a 3 s golden shield keeps them off. Back at camp they scatter, HP and flares refill.
-- - flares (C.GLOOM.flares per dive, key R or the FLARE button): every gloomling within 30 studs pancakes, then flees and is gone.
-- Each gloomling is an invisible anchored Part in workspace.Gloom moved here at 10 Hz; every client draws its own soot sprite on it.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local C = require(RS:WaitForChild("Shared"):WaitForChild("Config"))
local G = {}
local ctx
local folder, FlareR
local mobs = {} -- part -> { target = plr, state, t0, home }
local rng = Random.new()

local function serverNow() return workspace:GetServerTimeNow() end
local function st(s) -- the player's gloom state, kept on the session
	if not s.gloom then
		s.gloom = { relitAt = serverNow(), hp = C.GLOOM.hp, shieldUntil = 0, flares = C.GLOOM.flares, inCamp = true, nextSpawn = 0 }
		s.player:SetAttribute("HP", C.GLOOM.hp)
		s.player:SetAttribute("Flares", C.GLOOM.flares)
	end
	return s.gloom
end
local function publish(plr, g) -- the HUD reads these attributes
	plr:SetAttribute("HP", g.hp)
	plr:SetAttribute("Flares", g.flares)
	plr:SetAttribute("ShieldUntil", g.shieldUntil)
end
local function inCamp(pos)
	local o = C.CAVE_ORIGIN
	return Vector2.new(pos.X - o.X, pos.Z - o.Z).Magnitude < C.CAMP_RING and math.abs(pos.Y - o.Y) < 30
end
local function fearOf(s, g)
	if not s.tips.banked then return 0, 1 end
	local job = ctx.perks(s)
	local fuel = math.clamp(1 - (serverNow() - g.relitAt) / (C.TORCH.time * job.torch), 0, 1)
	return math.clamp(((1 - fuel) * 1.15 - 0.1) * job.fear, 0, 1), fuel
end
local function scatter(plr) -- every gloomling after this player flees
	for p, m in mobs do
		if m.target == plr and m.state ~= "flee" then
			m.state, m.t0 = "flee", os.clock()
			p:SetAttribute("State", "flee")
		end
	end
end

local function spawn(plr, hrp)
	local back = -hrp.CFrame.LookVector * Vector3.new(1, 0, 1)
	if back.Magnitude < 0.1 then back = Vector3.new(1, 0, 0) end
	local a = rng:NextNumber(-0.9, 0.9) -- from the dark behind you, a little to one side
	local dir = (CFrame.Angles(0, a, 0):VectorToWorldSpace(back.Unit))
	local pos = hrp.Position + dir * rng:NextNumber(26, 34) + Vector3.new(0, 0.5, 0)
	local p = Instance.new("Part")
	p.Name, p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.Transparency, p.Size = "Gloomling", true, false, false, false, 1, Vector3.new(2, 2, 2)
	p.CFrame = CFrame.lookAt(pos, hrp.Position)
	p:SetAttribute("Target", plr.UserId)
	p:SetAttribute("State", "creep")
	p.Parent = folder
	mobs[p] = { target = plr, state = "creep", t0 = os.clock(), seed = rng:NextNumber() * 6 }
end

local function caught(plr, s, g)
	local job = ctx.perks(s)
	if job.block and not g.blocked then -- Fafnir takes the first catch of the dive
		g.blocked = true
		g.hp = C.GLOOM.hp
		g.shieldUntil = serverNow() + C.GLOOM.shield
		publish(plr, g)
		scatter(plr)
		ctx.fx:FireClient(plr, "caught", -1)
		return
	end
	local lost = ctx.lose(s, job.loss or C.GLOOM.loss)
	g.hp = C.GLOOM.hp
	g.shieldUntil = serverNow() + C.GLOOM.shield
	publish(plr, g)
	scatter(plr)
	ctx.fx:FireClient(plr, "caught", lost)
	if ctx.analytics then ctx.analytics.event(s, "GloomCatch", lost) end
	ctx.sendState(s)
end

function G.init(c)
	ctx = c
	folder = Instance.new("Folder")
	folder.Name = "Gloom"
	folder.Parent = workspace
	FlareR = Instance.new("RemoteEvent")
	FlareR.Name = "Flare"
	FlareR.Parent = RS:WaitForChild("Remotes")
	FlareR.OnServerEvent:Connect(function(plr)
		local s = ctx.data[plr]
		local hrp = ctx.hrpOf(plr)
		if not s or not hrp or not plr:GetAttribute("InCave") or ctx.busy(plr) then return end
		local g = st(s)
		if g.flares <= 0 or os.clock() - (g.lastFlare or 0) < 0.8 then return end
		for other, os2 in ctx.data do -- a rescue: free every grabbed player in reach (yourself too)
			local og = os2.gloom
			local ohrp = ctx.hrpOf(other)
			if og and og.grabbedUntil and ohrp and (ohrp.Position - hrp.Position).Magnitude < C.GLOOM.flareRange then
				og.grabbedUntil = nil
				og.hp = C.GLOOM.hp
				og.shieldUntil = serverNow() + C.GLOOM.shield
				other:SetAttribute("GrabbedUntil", nil)
				publish(other, og)
				scatter(other)
				ctx.fx:FireClient(other, "rescued", plr.Name, other == plr)
				if ctx.analytics then ctx.analytics.event(os2, other == plr and "GloomSelfRescue" or "GloomRescue") end
				if other ~= plr then ctx.fx:FireClient(plr, "rescuedFriend", other.Name) end
			end
		end
		g.flares -= 1
		g.lastFlare = os.clock()
		publish(plr, g)
		ctx.fx:FireAllClients("flareFx", hrp.Position + hrp.CFrame.LookVector * 2 + Vector3.new(0, 2, 0), plr.UserId)
		for p, m in mobs do
			if (p.Position - hrp.Position).Magnitude < C.GLOOM.flareRange and m.state ~= "flee" then
				m.state, m.t0 = "pancake", os.clock()
				p:SetAttribute("State", "pancake")
			end
		end
	end)
	Players.PlayerRemoving:Connect(function(plr)
		for p, m in mobs do if m.target == plr then mobs[p] = nil p:Destroy() end end
	end)
end

function G.step(dt)
	local nowC = os.clock()
	-- players: torch, camp, spawning
	for plr, s in ctx.data do
		local hrp = ctx.hrpOf(plr)
		local g = st(s)
		local caving = hrp and plr:GetAttribute("InCave") and not ctx.busy(plr)
		if not caving then
			if hrp and not plr:GetAttribute("InCave") then -- in town: a fresh torch, full HP and flares for the next dive
				g.inCamp, g.relitAt, g.blocked = true, serverNow(), false
				if g.hp < C.GLOOM.hp or g.flares < C.GLOOM.flares then g.hp, g.flares = C.GLOOM.hp, C.GLOOM.flares publish(plr, g) end
			end
			scatter(plr)
		else
			local here = inCamp(hrp.Position)
			if plr:GetAttribute("DevBanked") then s.tips.banked = true end -- Studio test hook: skip the first-bank rule
			local dev = plr:GetAttribute("DevTorchAge") -- Studio test hook (the client applies it too)
			if dev and dev ~= g.devAge then g.devAge = dev g.relitAt = serverNow() - dev g.inCamp = false end
			if here then
				g.relitAt = serverNow()
				if g.hp < C.GLOOM.hp or g.flares < C.GLOOM.flares then g.hp, g.flares = C.GLOOM.hp, C.GLOOM.flares publish(plr, g) end
				scatter(plr)
			elseif g.inCamp then -- just left the ring: the HUD's torch counts from here
				plr:SetAttribute("RelitAt", g.relitAt)
			end
			if not s.tips.banked then g.relitAt = serverNow() end -- learn the rules first
			if plr:GetAttribute("TorchFrozen") ~= not s.tips.banked then plr:SetAttribute("TorchFrozen", not s.tips.banked) end
			g.inCamp = here
			local fear = fearOf(s, g)
			local want = (not here and fear >= 0.6 and 2) or (not here and fear >= 0.25 and 1) or 0
			local have = 0
			for _, m in mobs do if m.target == plr and m.state ~= "flee" then have += 1 end end
			if have < want and nowC >= g.nextSpawn then
				spawn(plr, hrp)
				g.nextSpawn = nowC + C.GLOOM.spawnGap
			end
		end
	end
	-- grabbed players: the catch lands when the window runs out
	for plr, s in ctx.data do
		local g = s.gloom
		if g and g.grabbedUntil and serverNow() >= g.grabbedUntil then
			g.grabbedUntil = nil
			plr:SetAttribute("GrabbedUntil", nil)
			caught(plr, s, g)
		end
	end
	-- gloomlings: creep, BONK, stun, pancake, flee
	for p, m in mobs do
		local plr = m.target
		local s = ctx.data[plr]
		local hrp = plr.Parent and ctx.hrpOf(plr)
		local age = nowC - m.t0
		if not s or not hrp then
			mobs[p] = nil
			p:Destroy()
			continue
		end
		local g = st(s)
		local pos = p.Position
		local to = hrp.Position + Vector3.new(0, 0.5, 0) - pos
		local dist = to.Magnitude
		local fear = fearOf(s, g)
		if m.state == "creep" then
			local speed = fear >= 0.6 and C.GLOOM.speed[2] or C.GLOOM.speed[1]
			local side = Vector3.new(-to.Z, 0, to.X).Unit * math.sin(nowC * 2.3 + m.seed) * 0.35 -- a little weave
			local step = (to.Unit + side).Unit * math.min(speed * dt, math.max(dist - 1.5, 0))
			p.CFrame = CFrame.lookAt(pos + step, hrp.Position)
			if dist < C.GLOOM.reach and serverNow() > g.shieldUntil and not g.grabbedUntil then -- BONK
				g.hp = math.max(0, g.hp - C.GLOOM.hit)
				m.state, m.t0, m.from = "stun", nowC, pos
				p:SetAttribute("State", "stun")
				if g.hp <= 0 then -- GRABBED: a flare (yours or a friend's) within C.GLOOM.grab seconds frees you
					g.grabbedUntil = serverNow() + C.GLOOM.grab
					plr:SetAttribute("GrabbedUntil", g.grabbedUntil)
					publish(plr, g)
					ctx.fx:FireClient(plr, "grabbed", C.GLOOM.grab)
				else
					publish(plr, g)
					ctx.fx:FireClient(plr, "gloomBonk", g.hp)
				end
			elseif dist > 70 then
				mobs[p] = nil
				p:Destroy()
			end
		elseif m.state == "stun" then -- knocked back, dazed, then creeps again
			local k = math.min(age / 0.4, 1)
			local away = (pos - hrp.Position) * Vector3.new(1, 0, 1)
			if away.Magnitude > 0.1 and k < 1 then p.CFrame = CFrame.lookAt(pos + away.Unit * 20 * dt, hrp.Position) end
			if age > C.GLOOM.stun then
				m.state, m.t0 = "creep", nowC
				p:SetAttribute("State", "creep")
			end
		elseif m.state == "pancake" then -- squashed flat by the flare, then off into the cracks
			if age > 0.6 then
				m.state, m.t0 = "flee", nowC
				p:SetAttribute("State", "flee")
			end
		elseif m.state == "flee" then
			local away = (pos - hrp.Position)
			if away.Magnitude < 0.1 then away = Vector3.new(1, 0, 0) end
			p.CFrame = CFrame.lookAt(pos + away.Unit * 16 * dt, pos + away.Unit * 2)
			if age > 1.8 then
				mobs[p] = nil
				p:Destroy()
			end
		end
	end
end

return G
