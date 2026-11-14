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
	ctx.fx:FireClient(plr, "bossSweep", workspace:GetServerTimeNow() + ATK.sweepWind, dir, b.def.id)
	task.delay(ATK.sweepWind, function()
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
	ctx.fx:FireClient(plr, "bossRings", workspace:GetServerTimeNow() + ATK.ringWind, b.def.id)
	local hit = false
	for k, r in ATK.rings do
		task.delay(ATK.ringWind + (k - 1) * ATK.ringGap, function()
			if hit or s.boss ~= b or ctx.data[plr] ~= s then return end
			local rel = flatFrom(plr, w)
			if rel and math.abs(rel.Magnitude - r) < ATK.ringW / 2 then
				hit = true
				strike(plr, s, b, ATK.ringHit, "rings")
			end
		end)
	end
	task.delay(ATK.ringWind + (#ATK.rings - 1) * ATK.ringGap + 0.1, function()
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
	local land = workspace:GetServerTimeNow() + B.windup
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
		task.delay(B.windup + t, function() if inAir() then air = true end end)
	end
	task.delay(B.windup + 0.25, function()
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
		task.delay(1.4, function() step(plr, s) end)
	end)
end
local ATTACKS = { slam = slam, sweep = sweep, rings = rings }
local CYCLE = { "slam", "sweep", "rings" }
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
	local cracked = mg.perfects >= b.def.B.perfects
	ctx.fx:FireClient(plr, "mgEnd", mg.dep, b.def.knot, cracked and 1 or 0, 0, Color3.fromRGB(255, 186, 92), mg.perfects)
	if cracked then
		b.knots -= 1
		ctx.fx:FireClient(plr, "bossKnot", b.knots, mg.dep, b.def.id)
	else
		ctx.fx:FireClient(plr, "bossHold", b.def.id)
	end
	if b.knots <= 0 then
		task.delay(1.2, function() if s.boss == b then finish(plr, s, true) end end)
		return
	end
	-- knot 1 down: the slam; knot 2 down: the sweep, then the rings; a knot that held: the next of the three in turn
	if cracked then
		b.queue = b.knots == b.def.B.knots - 1 and { "slam" } or { "sweep", "rings" }
	else
		b.turn = (b.turn or 0) % #CYCLE + 1
		b.queue = { CYCLE[b.turn] }
	end
	task.delay(1.6, function() step(plr, s) end)
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
		s.boss = { knots = def.B.knots, def = def, queue = {} }
		ctx.fx:FireClient(plr, "bossStart", def.B.knots, def.id)
		task.delay(2.6, function() round(plr, s) end)
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
