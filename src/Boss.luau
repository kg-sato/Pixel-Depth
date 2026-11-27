-- Boss (ServerScriptService.Boss): the gate bosses (roadmap phase 9; the user 2026-11-08: the next camp needs a boss fight
-- that needs the camp's top pickaxe). Per player; the server runs every step. Two bosses share one fight (DEFS below):
--   1 the Root Warden at Camp 1's Deep Gate (C.BOSS; the Rootheart Pickaxe or better; win = tips.gate1, the way to the Clay Caves)
--   2 the Kiln Golem at the east end of the Clay Caves hall (C.BOSS2; the Titan Hammer; win = tips.gate2; phase 10)
-- Challenge (F on the boss) with the needed pickaxe in hand. Three rounds: a Perfect Strike on one of its glowing knots (a
-- faster needle and a narrower zone than ore; `perfects` good swings crack it), then the boss winds up and SLAMS the ground:
-- be in the air (jump) or far away when it lands, or lose `slamHit` HP. Crack all three knots and it steps aside for good, with
-- coins and gems. Run out of HP and it only pushes you back to try again (no ore lost).
-- Three attacks since 2026-11-13 (Next Systems Plan, phase C), each drawn on the floor by the client before it lands
-- (numbers in C.BOSS_ATK): the SLAM (jump, or be far away), the SWEEP (a lane from the boss through where you stood: step out
-- of it) and the RINGS (three bands round the boss land one after another: stand in a gap). After the first knot comes the
-- slam, after the second the sweep and then the rings; a knot that holds brings the next attack of the three in turn.
-- The server picks the attack, keeps its clock and decides the hit; one attack hurts at most once.
-- Every Fx event carries the boss number last, so Shared.BossClient moves the right model.
-- Three phases since 2026-11-27 (vault Briefs/Progression and Boss Fight Overhaul 2.1): the knots left are the boss's health
-- (3 = phase 1, 2 = phase 2, 1 = phase 3). Phase 1: the signature attack and the slam; after every slam the boss's core lies
-- open for 3 s (Fx bossCore) and a flare thrown then STAGGERS it (Fx bossStagger): the next knot cracked counts twice. Phase 2
-- (ENRAGED): wind-ups 20% faster and the attacks chain. Phase 3 (OVERDRIVE): 30% faster, three in a row. The last knot shatters
-- it (Fx bossShatter, a slow-motion burst on the client) and a Boss Relic Chest stands where it fell: gold, gems, two soul
-- shards and, the first time, the boss's relic (saved as tips.relic<id>). Signatures: the Root Warden's ROOT WALL SNARE (three
-- thorn pillars erupt between you and it; a flare burns them and staggers it), the Kiln Golem's MAGMA RAIN (bombs with shadow
-- rings) and LAVA TIDE (a low wave rolls out from it: be in the air when it passes; the client puffs two steam vents).
-- Shared.BossPhases draws all of these. Shared.JourneyUI lists the relics.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local C = require(RS:WaitForChild("Shared"):WaitForChild("Config"))
local M = {}
local ctx

local DEFS = {
	{ id = 1, model = "Warden", B = C.BOSS, tip = "gate1", knot = "Root Knot", event = "RootWarden" },
	{ id = 2, model = "KilnGolem", B = C.BOSS2, tip = "gate2", knot = "Kiln Vent", event = "KilnGolem" },
}

local function modelOf(def) return workspace:FindFirstChild("Caves") and workspace.Caves:FindFirstChild(def.model, true) end
local RELIC = { "Heartwood Sigil", "Kiln Crown Emblem" }
local function pace(b) return b.phase == 3 and 0.7 or (b.phase == 2 and 0.8 or 1) end -- wind-ups shrink with each phase

local function spawnChest(plr, s, def)
	local w = modelOf(def)
	if not w or not w.PrimaryPart then return end
	local look = w.PrimaryPart.CFrame.LookVector * Vector3.new(1, 0, 1)
	look = look.Magnitude > 0.1 and look.Unit or Vector3.zAxis
	local at = w.PrimaryPart.Position + look * 9
	local rp = RaycastParams.new()
	rp.FilterType, rp.FilterDescendantsInstances = Enum.RaycastFilterType.Exclude, { w, plr.Character }
	local hit = workspace:Raycast(at + Vector3.new(0, 6, 0), Vector3.new(0, -30, 0), rp)
	local base = CFrame.lookAt(hit and hit.Position or at, (hit and hit.Position or at) - look)
	local m = Instance.new("Model")
	m.Name = "BossRelicChest"
	local function part(name, size, cf, color, mat)
		local q = Instance.new("Part")
		q.Name, q.Size, q.CFrame, q.Color, q.Material, q.Anchored, q.CanCollide = name, size, base * cf, color, mat or Enum.Material.SmoothPlastic, true, false
		q.Parent = m
		return q
	end
	local GOLDC, WOOD = Color3.fromRGB(240, 186, 64), Color3.fromRGB(110, 70, 48)
	local body = part("ChestBody", Vector3.new(4.4, 2.4, 3), CFrame.new(0, 1.2, 0), WOOD, Enum.Material.Wood)
	part("ChestLid", Vector3.new(4.5, 0.7, 3.1), CFrame.new(0, 2.75, 0), WOOD:Lerp(Color3.new(0, 0, 0), 0.15), Enum.Material.Wood)
	part("ChestLid2", Vector3.new(4.5, 0.5, 2.3), CFrame.new(0, 3.35, 0), WOOD:Lerp(Color3.new(0, 0, 0), 0.15), Enum.Material.Wood)
	for _, x in { -1.7, 0, 1.7 } do part("ChestBand", Vector3.new(0.4, 3.7, 3.2), CFrame.new(x, 1.85, 0), GOLDC, Enum.Material.Metal) end
	local seam = part("ChestSeam", Vector3.new(4.3, 0.14, 2.9), CFrame.new(0, 2.42, 0), Color3.fromRGB(255, 230, 140), Enum.Material.Neon)
	local l = Instance.new("PointLight")
	l.Color, l.Range, l.Brightness = Color3.fromRGB(255, 220, 140), 14, 1.2
	l.Parent = seam
	m.PrimaryPart = body
	m:SetAttribute("Owner", plr.UserId)
	local pr = Instance.new("ProximityPrompt")
	pr.ActionText, pr.ObjectText, pr.KeyboardKeyCode, pr.GamepadKeyCode = "Open", "Boss Relic Chest", Enum.KeyCode.F, Enum.KeyCode.ButtonX
	pr.MaxActivationDistance, pr.RequiresLineOfSight, pr.HoldDuration, pr.Style = 12, false, 0, Enum.ProximityPromptStyle.Custom
	pr:SetAttribute("BossChest", def.id)
	pr.Parent = body
	m.Parent = w.Parent
	local opened = false
	pr.Triggered:Connect(function(who)
		if opened or who ~= plr or ctx.data[plr] ~= s or (ctx.nearPrompt and not ctx.nearPrompt(plr, pr)) then return end
		opened = true
		local B = def.B
		local gold, gems = math.floor(B.gold / 2), 5
		local first = not s.tips["relic" .. def.id]
		if first then gems += 10 s.tips["relic" .. def.id] = true end
		s.gold += gold
		s.gems += gems
		if type(s.soul) == "table" and type(s.soul.shards) == "number" then s.soul.shards += 2 end
		if ctx.analytics then
			ctx.analytics.earn(s, "Coins", gold, s.gold, def.event .. "Chest")
			ctx.analytics.earn(s, "Gems", gems, s.gems, def.event .. "Chest")
		end
		ctx.fx:FireClient(plr, "bossChest", gold, gems, first and RELIC[def.id] or "", def.id, body.Position)
		ctx.sendState(s)
		m:Destroy()
	end)
	task.delay(120, function() if m.Parent and not opened then m:Destroy() end end) -- a chest nobody opens goes after two minutes
end

local function finish(plr, s, won)
	local def = s.boss and s.boss.def
	s.boss = nil
	if s.mg and s.mg.boss then s.mg = nil end
	if not def then return end
	local B = def.B
	if won then
		s.tips[def.tip] = true
		s.gold += B.gold
		s.gems += B.gems
		if ctx.analytics then
			ctx.analytics.earn(s, "Coins", B.gold, s.gold, def.event)
			ctx.analytics.earn(s, "Gems", B.gems, s.gems, def.event)
			ctx.analytics.event(s, def.event .. "Defeated")
		end
		ctx.fx:FireClient(plr, "bossWin", B.gold, B.gems, def.id)
		if def.id == 1 and ctx.quest then ctx.quest(s, "warden") end
		task.delay(1.2, function() pcall(spawnChest, plr, s, def) end)
	else
		ctx.fx:FireClient(plr, "bossLose", def.id)
	end
	ctx.heal(plr)
	ctx.sendState(s)
end

local ATK = C.BOSS_ATK
local round, step
local function flatFrom(plr, w) -- the player's place seen from the boss, on the floor plane
	local hrp = ctx.hrpOf(plr)
	return hrp and w and w.PrimaryPart and (hrp.Position - w.PrimaryPart.Position) * Vector3.new(1, 0, 1)
end
local function strike(plr, s, b, dmg, what) -- one hit of an attack; true = the fight ended
	local hp = ctx.hurt(plr, dmg)
	ctx.fx:FireClient(plr, "bossHit", hp, b.def.id, what)
	if hp <= 0 then
		finish(plr, s, false)
		return true
	end
	return false
end
local function sweep(plr, s)
	local b = s.boss
	if not b or ctx.data[plr] ~= s then return end
	local w = modelOf(b.def)
	local flat = flatFrom(plr, w)
	if not flat then return step(plr, s) end
	local dir = flat.Magnitude > 1 and flat.Unit or Vector3.zAxis
	local wind = ATK.sweepWind * pace(b)
	ctx.fx:FireClient(plr, "bossSweep", workspace:GetServerTimeNow() + wind, dir, b.def.id)
	task.delay(wind, function()
		if s.boss ~= b or ctx.data[plr] ~= s then return end
		local rel = flatFrom(plr, w)
		if rel then
			local along = rel:Dot(dir)
			if along > -2 and along < b.def.B.leash and (rel - dir * along).Magnitude < ATK.sweepW / 2 then
				if strike(plr, s, b, ATK.sweepHit, "sweep") then return end
			else
				ctx.fx:FireClient(plr, "bossDodge", b.def.id)
			end
		end
		task.delay(1.2, function() step(plr, s) end)
	end)
end
local function rings(plr, s)
	local b = s.boss
	if not b or ctx.data[plr] ~= s then return end
	local w = modelOf(b.def)
	local wind = ATK.ringWind * pace(b)
	ctx.fx:FireClient(plr, "bossRings", workspace:GetServerTimeNow() + wind, b.def.id)
	local hit = false
	for k, r in ATK.rings do
		task.delay(wind + (k - 1) * ATK.ringGap, function()
			if hit or s.boss ~= b or ctx.data[plr] ~= s then return end
			local rel = flatFrom(plr, w)
			if rel and math.abs(rel.Magnitude - r) < ATK.ringW / 2 then
				hit = true
				strike(plr, s, b, ATK.ringHit, "rings")
			end
		end)
	end
	task.delay(wind + (#ATK.rings - 1) * ATK.ringGap + 0.1, function()
		if s.boss ~= b or ctx.data[plr] ~= s then return end
		if not hit then ctx.fx:FireClient(plr, "bossDodge", b.def.id) end
		task.delay(1.2, function() step(plr, s) end)
	end)
end
local function slam(plr, s)
	local b = s.boss
	if not b or ctx.data[plr] ~= s then return end
	local B = b.def.B
	local w = modelOf(b.def)
	local windup = B.windup * pace(b)
	local land = workspace:GetServerTimeNow() + windup
	ctx.fx:FireClient(plr, "bossSlam", land, b.def.id)
	-- a jump only lasts about half a second, so look for the player in the air several times around the landing (kid friendly)
	local air = false
	local function inAir()
		local hrp = ctx.hrpOf(plr)
		local hum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
		if not hrp then return false end
		local rp = RaycastParams.new() -- the server's FloorMaterial reads Air for player characters, so measure the height
		rp.FilterDescendantsInstances = { plr.Character, w }
		rp.FilterType = Enum.RaycastFilterType.Exclude
		local hit = workspace:Raycast(hrp.Position, Vector3.new(0, -14, 0), rp)
		return not hit or (hrp.Position.Y - hit.Position.Y) > (hum and hum.HipHeight or 2) + hrp.Size.Y / 2 + 0.8
	end
	for _, t in { -0.35, -0.2, -0.05, 0.1, 0.22 } do
		task.delay(math.max(0, windup + t), function() if inAir() then air = true end end)
	end
	task.delay(windup + 0.25, function()
		if s.boss ~= b or ctx.data[plr] ~= s then return end
		local hrp = ctx.hrpOf(plr)
		if hrp and w and w.PrimaryPart then
			local flat = (hrp.Position - w.PrimaryPart.Position) * Vector3.new(1, 0, 1)
			if flat.Magnitude < B.slamReach and not air then
				if strike(plr, s, b, B.slamHit, "slam") then return end
			else
				ctx.fx:FireClient(plr, "bossDodge", b.def.id)
			end
		end
		-- the core lies open for 3 s after the slam (arms planted, lid up): a flare now staggers it
		b.coreUntil = workspace:GetServerTimeNow() + 3
		ctx.fx:FireClient(plr, "bossCore", 3, b.def.id)
		task.delay(1.4, function() step(plr, s) end)
	end)
end
local function inAirOf(plr, w) -- the same height test the slam uses
	local hrp = ctx.hrpOf(plr)
	local hum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
	if not hrp then return false end
	local rp = RaycastParams.new()
	rp.FilterDescendantsInstances, rp.FilterType = { plr.Character, w }, Enum.RaycastFilterType.Exclude
	local hit = workspace:Raycast(hrp.Position, Vector3.new(0, -14, 0), rp)
	return not hit or (hrp.Position.Y - hit.Position.Y) > (hum and hum.HipHeight or 2) + hrp.Size.Y / 2 + 0.8
end
local function snare(plr, s) -- the Root Warden's ROOT WALL SNARE: three thorn pillars erupt between you and it
	local b = s.boss
	if not b or ctx.data[plr] ~= s then return end
	local w = modelOf(b.def)
	local flat = flatFrom(plr, w)
	if not flat or not w then return step(plr, s) end
	local dir = flat.Magnitude > 1 and flat.Unit or Vector3.zAxis
	local side = Vector3.new(-dir.Z, 0, dir.X)
	local mid = w.PrimaryPart.Position * Vector3.new(1, 0, 1) + dir * math.clamp(flat.Magnitude * 0.55, 6, 18)
	local pts = { mid - side * 6, mid, mid + side * 6 }
	local wind = 1.4 * pace(b)
	b.snareUntil = workspace:GetServerTimeNow() + wind + 4
	ctx.fx:FireClient(plr, "bossSnare", workspace:GetServerTimeNow() + wind, pts, b.def.id)
	task.delay(wind, function()
		if s.boss ~= b or ctx.data[plr] ~= s then return end
		local rel = flatFrom(plr, w)
		local hrp = ctx.hrpOf(plr)
		local hitMe = false
		if hrp then for _, q in pts do if ((hrp.Position - q) * Vector3.new(1, 0, 1)).Magnitude < 3.4 then hitMe = true end end end
		if hitMe then
			if strike(plr, s, b, 25, "snare") then return end
		elseif rel then
			ctx.fx:FireClient(plr, "bossDodge", b.def.id)
		end
		task.delay(1.2, function() step(plr, s) end)
	end)
end
local function magma(plr, s) -- the Kiln Golem's MAGMA RAIN: four to six bombs, each drawn as a shadow ring before it lands
	local b = s.boss
	if not b or ctx.data[plr] ~= s then return end
	local hrp = ctx.hrpOf(plr)
	if not hrp then return step(plr, s) end
	local pts = { hrp.Position * Vector3.new(1, 0, 1) }
	for k = 1, 3 + math.random(0, 2) do
		local a = math.random() * math.pi * 2
		table.insert(pts, pts[1] + Vector3.new(math.cos(a), 0, math.sin(a)) * (4 + math.random() * 8))
	end
	local wind = 1.3 * pace(b)
	ctx.fx:FireClient(plr, "bossMagma", workspace:GetServerTimeNow() + wind, pts, b.def.id)
	task.delay(wind, function()
		if s.boss ~= b or ctx.data[plr] ~= s then return end
		local h = ctx.hrpOf(plr)
		local hitMe = false
		if h then for _, q in pts do if ((h.Position - q) * Vector3.new(1, 0, 1)).Magnitude < 3.5 then hitMe = true end end end
		if hitMe then
			if strike(plr, s, b, 25, "magma") then return end
		else
			ctx.fx:FireClient(plr, "bossDodge", b.def.id)
		end
		task.delay(1.0, function() step(plr, s) end)
	end)
end
local function tide(plr, s) -- the Kiln Golem's LAVA TIDE: a low wave rolls out from it; be in the air (jump, or glide on a vent) as it passes
	local b = s.boss
	if not b or ctx.data[plr] ~= s then return end
	local w = modelOf(b.def)
	local rel = flatFrom(plr, w)
	if not rel then return step(plr, s) end
	local wind, speed = 1.4 * pace(b), 16
	local t0 = workspace:GetServerTimeNow() + wind
	ctx.fx:FireClient(plr, "bossTide", t0, speed, b.def.id)
	local r = rel.Magnitude
	local pass = wind + r / speed
	local air = false
	for _, t in { -0.25, -0.1, 0.05, 0.18 } do task.delay(math.max(0, pass + t), function() if inAirOf(plr, w) then air = true end end) end
	task.delay(pass + 0.22, function()
		if s.boss ~= b or ctx.data[plr] ~= s then return end
		if r < b.def.B.leash and not air then
			if strike(plr, s, b, 30, "tide") then return end
		else
			ctx.fx:FireClient(plr, "bossDodge", b.def.id)
		end
		task.delay(1.0, function() step(plr, s) end)
	end)
end
local ATTACKS = { slam = slam, sweep = sweep, rings = rings, snare = snare, magma = magma, tide = tide }
local CYCLE = { "slam", "sweep", "rings" }
local SIGNATURE = { "snare", "magma" }
local CHAIN = { { "sweep", "rings" }, { "magma", "tide" } } -- phase 2's chained pair, per boss
step = function(plr, s) -- the next attack waiting, or the next knot
	local b = s.boss
	if not b or ctx.data[plr] ~= s then return end
	local kind = table.remove(b.queue, 1)
	if kind then ATTACKS[kind](plr, s) else round(plr, s) end
end

local function knotDone(s, mg)
	local plr = s.player
	local b = s.boss
	if not b then return end
	local cracked = mg.perfects >= (b.stagger and 1 or b.def.B.perfects) -- a staggered boss cracks with one PERFECT
	ctx.fx:FireClient(plr, "mgEnd", mg.dep, b.def.knot, cracked and 1 or 0, 0, Color3.fromRGB(255, 186, 92), mg.perfects)
	if cracked then
		b.knots = math.max(0, b.knots - (b.stagger and 2 or 1)) -- STAGGERED: this crack counts twice
		b.stagger = false
		ctx.fx:FireClient(plr, "bossKnot", b.knots, mg.dep, b.def.id)
	else
		ctx.fx:FireClient(plr, "bossHold", b.def.id)
	end
	if b.knots <= 0 then -- the shatter finisher: 1.5 s of slow motion on the client, then the win and the relic chest
		ctx.fx:FireClient(plr, "bossShatter", b.def.id)
		task.delay(1.6, function() if s.boss == b then finish(plr, s, true) end end)
		return
	end
	local phase = b.knots >= 3 and 1 or (b.knots == 2 and 2 or 3)
	if phase ~= b.phase then
		b.phase = phase
		ctx.fx:FireClient(plr, "bossPhase", phase, b.def.id)
	end
	local id = b.def.id
	if cracked then -- phase 1: the signature and the slam; phase 2: a chained pair; phase 3: three in a row
		b.queue = phase == 1 and { SIGNATURE[id] or "rings", "slam" } or (phase == 2 and table.clone(CHAIN[id] or CHAIN[1]) or { "slam", SIGNATURE[id] or "rings", "sweep" })
	else
		b.turn = (b.turn or 0) % #CYCLE + 1
		b.queue = phase >= 2 and { CYCLE[b.turn], SIGNATURE[id] or "rings" } or { CYCLE[b.turn] }
	end
	task.delay(phase == 1 and 1.6 or 1.2, function() step(plr, s) end)
end

round = function(plr, s)
	local b = s.boss
	if not b or ctx.data[plr] ~= s or s.mg or b.test then return end
	local B = b.def.B
	local w = modelOf(b.def)
	if not w then return end
	local hrp = ctx.hrpOf(plr)
	if not hrp or not plr:GetAttribute("InCave") or (hrp.Position - w.PrimaryPart.Position).Magnitude > B.leash then -- walked off
		return finish(plr, s, false)
	end
	local knot = w:FindFirstChild("Knot" .. (B.knots - b.knots + 1))
	local now = workspace:GetServerTimeNow()
	s.mg = { kind = "strike", dep = knot, t0 = now, arc = math.random() * 360, zone = B.zone, period = B.period, swings = 0, perfects = 0, last = 0,
		deadline = now + ctx.strikes * 4 * B.period + 2, boss = knotDone }
	ctx.fx:FireClient(plr, "mgStart", knot, "strike", now, s.mg.arc, s.mg.zone, s.mg.period)
end

function M.init(c)
	ctx = c
	local function challenge(plr, id, hook) -- hook: the Studio test hook may start it from anywhere
		local def = DEFS[id] or DEFS[1]
		local s = ctx.data[plr]
		if not s or s.mg or s.boss or not plr:GetAttribute("InCave") or ctx.busy(plr) or not modelOf(def) then return end
		local hrp, w = ctx.hrpOf(plr), modelOf(def)
		if not hook and (not hrp or (hrp.Position - w.PrimaryPart.Position).Magnitude > def.B.leash) then return end -- a client can fire the prompt from afar
		if s.tips[def.tip] then
			ctx.fx:FireClient(plr, "bossOpen", def.id)
			return
		end
		if (s.equip or 1) < def.B.needTier then
			ctx.fx:FireClient(plr, "bossLocked", C.PICKS[def.B.needTier].name, def.id)
			return
		end
		local b = { knots = def.B.knots, def = def, queue = {}, phase = 1 }
		s.boss = b
		ctx.fx:FireClient(plr, "bossStart", def.B.knots, def.id)
		local lastFlares = plr:GetAttribute("Flares")
		local fc
		fc = plr:GetAttributeChangedSignal("Flares"):Connect(function() -- a flare thrown at the open core or into the snare staggers it
			if s.boss ~= b then fc:Disconnect() return end
			local n = plr:GetAttribute("Flares")
			local used = type(n) == "number" and type(lastFlares) == "number" and n < lastFlares
			lastFlares = n
			local now = workspace:GetServerTimeNow()
			if used and not b.stagger and (now < (b.coreUntil or 0) or now < (b.snareUntil or 0)) then
				b.stagger = true
				ctx.fx:FireClient(plr, "bossStagger", 2.5, def.id, now < (b.snareUntil or 0))
			end
		end)
		b.queue = { SIGNATURE[def.id] or "rings", "slam" } -- phase 1 opens with the signature and the slam (its open core is the first chance to stagger)
		task.delay(2.6, function() step(plr, s) end)
	end
	game:GetService("ProximityPromptService").PromptTriggered:Connect(function(prompt, plr)
		local g = prompt:GetAttribute("BossGate") -- true (the Warden, as built before there were two) or the boss number
		if g then challenge(plr, g == true and 1 or g) end
	end)
	if game:GetService("RunService"):IsStudio() then -- Studio test hook: player attribute DevBoss = true or 1 (Warden), 2 (Kiln Golem), from anywhere
		local function watch(plr)
			plr:GetAttributeChangedSignal("DevBoss"):Connect(function()
				local v = plr:GetAttribute("DevBoss")
				if v then
					plr:SetAttribute("DevBoss", nil)
					challenge(plr, v == true and 1 or v, true)
				end
			end)
		end
		-- DevBossAtk = "slam", "sweep" or "rings" (the Warden), "sweep2" ... (the Kiln Golem): that one attack now, in a fight
		-- without knot rounds that lasts until the HP runs out (spike/boss_atk_test.py)
		local function watchAtk(plr)
			plr:GetAttributeChangedSignal("DevBossAtk"):Connect(function()
				local v, s = plr:GetAttribute("DevBossAtk"), ctx.data[plr]
				if not v then return end
				plr:SetAttribute("DevBossAtk", nil)
				local kind, id = string.match(v, "^(%a+)(%d?)$")
				local def = DEFS[tonumber(id) or 1]
				if not s or not ATTACKS[kind] or not def or s.mg or (s.boss and not s.boss.test) then return end
				if not s.boss or s.boss.def ~= def then s.boss = { knots = def.B.knots, def = def, queue = {}, test = true } end
				ATTACKS[kind](plr, s)
			end)
		end
		Players.PlayerAdded:Connect(function(p) watch(p) watchAtk(p) end)
		for _, p in Players:GetPlayers() do watch(p) watchAtk(p) end
	end
	Players.PlayerRemoving:Connect(function(plr) local s = ctx.data[plr] if s then s.boss = nil end end)
end

return M
