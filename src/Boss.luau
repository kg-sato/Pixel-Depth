-- Boss (ServerScriptService.Boss): the Root Warden at Camp 1's Deep Gate (roadmap phase 9; the user 2026-11-08: the next camp
-- needs a boss fight that needs the camp's top pickaxe). Per player; the server runs every step.
-- Challenge (F on the Warden) with the Rootheart Pickaxe or better in hand. Three rounds: a Perfect Strike on one of its amber
-- knots (a faster needle and a narrower zone than ore; C.BOSS.perfects good swings crack it), then the Warden winds up and
-- SLAMS the ground: be in the air (jump) or far away when it lands, or lose C.BOSS.slamHit HP. Crack all three knots and it
-- steps aside: the Deep Gate opens for you for good (tips.gate1), with coins, gems and Old Gran's first lost lantern.
-- Run out of HP and the Warden only pushes you back to try again (no ore lost).
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local C = require(RS:WaitForChild("Shared"):WaitForChild("Config"))
local M = {}
local ctx
local B = C.BOSS

local function warden() return workspace:FindFirstChild("Caves") and workspace.Caves:FindFirstChild("Warden", true) end

local function finish(plr, s, won)
	s.boss = nil
	if s.mg and s.mg.boss then s.mg = nil end
	if won then
		s.tips.gate1 = true
		s.gold += B.gold
		s.gems += B.gems
		if ctx.analytics then
			ctx.analytics.earn(s, "Coins", B.gold, s.gold, "RootWarden")
			ctx.analytics.earn(s, "Gems", B.gems, s.gems, "RootWarden")
			ctx.analytics.event(s, "RootWardenDefeated")
		end
		ctx.fx:FireClient(plr, "bossWin", B.gold, B.gems)
	else
		ctx.fx:FireClient(plr, "bossLose")
	end
	ctx.heal(plr)
	ctx.sendState(s)
end

local round
local function slam(plr, s)
	local b = s.boss
	if not b or ctx.data[plr] ~= s then return end
	local w = warden()
	local land = workspace:GetServerTimeNow() + B.windup
	ctx.fx:FireClient(plr, "bossSlam", land)
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
				local hp = ctx.hurt(plr, B.slamHit)
				ctx.fx:FireClient(plr, "bossHit", hp)
				if hp <= 0 then return finish(plr, s, false) end
			else
				ctx.fx:FireClient(plr, "bossDodge")
			end
		end
		task.delay(1.4, function() round(plr, s) end)
	end)
end

local function knotDone(s, mg)
	local plr = s.player
	local b = s.boss
	if not b then return end
	local cracked = mg.perfects >= B.perfects
	ctx.fx:FireClient(plr, "mgEnd", mg.dep, "Root Knot", cracked and 1 or 0, 0, Color3.fromRGB(255, 186, 92), mg.perfects)
	if cracked then
		b.knots -= 1
		ctx.fx:FireClient(plr, "bossKnot", b.knots, mg.dep)
	else
		ctx.fx:FireClient(plr, "bossHold")
	end
	if b.knots <= 0 then
		task.delay(1.2, function() if s.boss == b then finish(plr, s, true) end end)
		return
	end
	task.delay(1.6, function() slam(plr, s) end)
end

round = function(plr, s)
	local b = s.boss
	local w = warden()
	if not b or not w or ctx.data[plr] ~= s or s.mg then return end
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
	local function challenge(plr)
		local s = ctx.data[plr]
		if not s or s.mg or s.boss or not plr:GetAttribute("InCave") or ctx.busy(plr) then return end
		if s.tips.gate1 then
			ctx.fx:FireClient(plr, "bossOpen")
			return
		end
		if (s.equip or 1) < B.needTier then
			ctx.fx:FireClient(plr, "bossLocked", C.PICKS[B.needTier].name)
			return
		end
		s.boss = { knots = B.knots }
		ctx.fx:FireClient(plr, "bossStart", B.knots)
		task.delay(2.6, function() round(plr, s) end)
	end
	game:GetService("ProximityPromptService").PromptTriggered:Connect(function(prompt, plr)
		if prompt:GetAttribute("BossGate") then challenge(plr) end
	end)
	if game:GetService("RunService"):IsStudio() then -- Studio test hook: set the player attribute DevBoss to challenge from anywhere
		local function watch(plr)
			plr:GetAttributeChangedSignal("DevBoss"):Connect(function()
				if plr:GetAttribute("DevBoss") then plr:SetAttribute("DevBoss", nil) challenge(plr) end
			end)
		end
		Players.PlayerAdded:Connect(watch)
		for _, p in Players:GetPlayers() do watch(p) end
	end
	Players.PlayerRemoving:Connect(function(plr) local s = ctx.data[plr] if s then s.boss = nil end end)
end

return M
