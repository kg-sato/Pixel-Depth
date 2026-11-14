-- Retention (ServerScriptService.Retention): reasons to stay and to play together (directive v9, 2026-11-13, section 5B).
--   * Playtime gifts: C.GIFTS is a ladder of minutes played today and a gift for each (coins, flares, gems, an egg). The
--     server counts the seconds, tells the client where the ladder stands (Fx "gift"), and pays a gift only when the client
--     asks for one that is due (remote Gift, "claim"). The ladder starts again each day (UTC). Saved: profile field `gift`
--     = { day, secs, got }.
--   * Lantern Tether: friends in the same server help each other. With one friend or more here, ore is worth C.TETHER.value
--     more (PixelServer asks M.valueMult); in the caves, within C.TETHER.reach studs of a friend, the torch burns
--     C.TETHER.torch slower (Gloom.slow). The player attributes Friends (how many, 5 at most) and TetherTo (the friend beside
--     you, or nil) tell the client what to draw (Shared.LanternTether). A party board by the MINE shaft invites friends.
--   * Surface Refinery: a furnace by the MINE shaft. Put a geode in (the prompt): the server takes it, notes when it will be done
--     (saved: profile field `refine`, the finishing time, 0 = empty) and pays the gems and coins when you come back for it.
--     The player attribute RefineAt (server clock) lets the client count down (Shared.RetentionTimers).
-- Studio hooks: player attribute DevGeodes = geodes to hold, DevRefine = seconds until the running job is done; DevGiftSecs = seconds played today; DevFriends = number of friends (every other player counts as one).
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local C = require(RS:WaitForChild("Shared"):WaitForChild("Config"))
local M = {}
local ctx
local friends = {} -- [plr] = { [other] = true }

local function day() return os.time() // 86400 end

function M.cleanGift(t) -- the saved ladder: today's seconds and gifts taken, or a fresh one
	if type(t) ~= "table" or t.day ~= day() or type(t.secs) ~= "number" or type(t.got) ~= "number" then return { day = day(), secs = 0, got = 0 } end
	return { day = t.day, secs = math.clamp(math.floor(t.secs), 0, 86400), got = math.clamp(math.floor(t.got), 0, #C.GIFTS) }
end

local function tell(plr, s) -- the gifts taken, the seconds played, sent on join, each minute and after a claim
	ctx.fx:FireClient(plr, "gift", s.gift.got, s.gift.secs)
end

function M.cleanRefine(t) return (type(t) == "number" and t == t and t > 0) and math.floor(t) or 0 end -- the saved finishing time (os.time), 0 = nothing in the furnace
local function tellRefine(plr, s) -- nil = empty; otherwise the server-clock time the job is done
	plr:SetAttribute("RefineAt", s.refine > 0 and workspace:GetServerTimeNow() + (s.refine - os.time()) or nil)
end
local function refinery(plr, prompt)
	local s = ctx.data[plr]
	if not s or s.refine == nil or not ctx.nearPrompt(plr, prompt) or os.clock() < (s.refineCool or 0) then return end
	s.refineCool = os.clock() + 0.5
	if s.refine > 0 then
		local left = s.refine - os.time()
		if left > 0 then return ctx.fx:FireClient(plr, "refine", "wait", left) end
		s.refine = 0 -- done: the pay of a geode cracked by hand
		local gems = math.random(C.CLAY.geodeGems[1], C.CLAY.geodeGems[2])
		s.gems += gems
		s.gold += C.CLAY.geodeGold
		if ctx.analytics then
			ctx.analytics.earn(s, "Gems", gems, s.gems, "Refinery")
			ctx.analytics.earn(s, "Coins", C.CLAY.geodeGold, s.gold, "Refinery")
		end
		ctx.fx:FireClient(plr, "refine", "paid", gems, C.CLAY.geodeGold)
	elseif (s.geodes or 0) > 0 then
		s.geodes -= 1
		s.refine = os.time() + C.REFINE.secs
		ctx.fx:FireClient(plr, "refine", "start", C.REFINE.secs)
	else
		return ctx.fx:FireClient(plr, "refine", "none")
	end
	tellRefine(plr, s)
	ctx.sendState(s)
end

function M.friendCount(plr)
	local dev = plr:GetAttribute("DevFriends")
	if type(dev) == "number" then return math.clamp(dev, 0, C.TETHER.max) end
	local n = 0
	for other in friends[plr] or {} do if other.Parent then n += 1 end end
	return math.min(n, C.TETHER.max)
end
function M.valueMult(plr) return M.friendCount(plr) >= 1 and 1 + C.TETHER.value or 1 end

function M.init(c)
	ctx = c
	-- ------------------------------------------------------------ playtime gifts
	local R = ctx.remote("Gift")
	R.OnServerEvent:Connect(function(plr, what)
		local s = ctx.data[plr]
		if not s or not s.gift or what ~= "claim" or os.clock() < (s.giftCool or 0) then return end
		s.giftCool = os.clock() + 0.4
		local g = C.GIFTS[s.gift.got + 1]
		if not g or s.gift.secs < g[1] then return end -- nothing due yet
		s.gift.got += 1
		local kind, n = g[2], g[3]
		if kind == "coins" then
			s.gold += n
			if ctx.analytics then ctx.analytics.earn(s, "Coins", n, s.gold, "PlaytimeGift") end
		elseif kind == "gems" then
			s.gems += n
			if ctx.analytics then ctx.analytics.earn(s, "Gems", n, s.gems, "PlaytimeGift") end
		elseif kind == "egg" then
			s.eggs += n
		elseif kind == "flares" then
			ctx.flares(plr, n)
		end
		ctx.fx:FireClient(plr, "giftPaid", kind, n, s.gift.got)
		ctx.sendState(s)
		tell(plr, s)
	end)
	local function watch(plr)
		task.spawn(function() -- once the data is there: where the ladder stands
			for _ = 1, 40 do
				local s = ctx.data[plr]
				if s and s.gift then
					if s.refine then tellRefine(plr, s) end
					return tell(plr, s)
				end
				task.wait(0.5)
			end
		end)
		friends[plr] = {}
		for _, other in Players:GetPlayers() do
			if other ~= plr then
				task.spawn(function()
					local ok, yes = pcall(function() return plr:IsFriendsWith(other.UserId) end)
					if ok and yes and friends[plr] and friends[other] then friends[plr][other], friends[other][plr] = true, true end
				end)
			end
		end
	end
	Players.PlayerAdded:Connect(watch)
	for _, p in Players:GetPlayers() do watch(p) end
	Players.PlayerRemoving:Connect(function(plr)
		friends[plr] = nil
		for _, t in friends do t[plr] = nil end
	end)
	task.spawn(function()
		local tick = 0
		while true do
			task.wait(1)
			tick += 1
			for plr, s in ctx.data do
				if s.gift then
					if s.gift.day ~= day() then s.gift = { day = day(), secs = 0, got = 0 } tell(plr, s) end
					local dev = plr:GetAttribute("DevGiftSecs")
					if type(dev) == "number" then
						plr:SetAttribute("DevGiftSecs", nil)
						s.gift.secs = math.clamp(math.floor(dev), 0, 86400)
						tell(plr, s)
					end
					local dg, dr = plr:GetAttribute("DevGeodes"), plr:GetAttribute("DevRefine")
					if type(dg) == "number" then plr:SetAttribute("DevGeodes", nil) s.geodes = dg end
					if type(dr) == "number" and s.refine and s.refine > 0 then plr:SetAttribute("DevRefine", nil) s.refine = os.time() + dr tellRefine(plr, s) end
					s.gift.secs += 1
					if tick % 60 == 0 then tell(plr, s) end -- the client counts between these
				end
				-- the Lantern Tether
				local n = M.friendCount(plr)
				if plr:GetAttribute("Friends") ~= n then plr:SetAttribute("Friends", n) end
				local beside
				local hrp = ctx.hrpOf(plr)
				if n > 0 and hrp and plr:GetAttribute("InCave") then
					for _, other in Players:GetPlayers() do
						local oh = other ~= plr and ctx.hrpOf(other)
						if oh and (friends[plr] and friends[plr][other] or plr:GetAttribute("DevFriends")) and (oh.Position - hrp.Position).Magnitude <= C.TETHER.reach then
							beside = other.Name
							break
						end
					end
				end
				if plr:GetAttribute("TetherTo") ~= beside then plr:SetAttribute("TetherTo", beside) end
				if beside then ctx.slowTorch(plr, C.TETHER.torch) end -- each second beside a friend gives this share of a second back
			end
		end
	end)
	-- ------------------------------------------------------------ the party board by the MINE shaft
	local hub = workspace:FindFirstChild("Hub")
	local cart = hub and hub:FindFirstChild("HubCart", true)
	if cart then
		local at = cart:GetPivot() * CFrame.new(-9, 3.2, 2) * CFrame.Angles(0, math.rad(25), 0)
		local function part(name, size, cf, color, mat)
			local p = Instance.new("Part")
			p.Name, p.Size, p.CFrame, p.Color, p.Material, p.Anchored = name, size, cf, color, mat or Enum.Material.Wood, true
			p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
			p.Parent = hub
			return p
		end
		local wood = Color3.fromRGB(92, 62, 48)
		for _, x in { -2.6, 2.6 } do part("PartyPost", Vector3.new(0.5, 5.2, 0.5), at * CFrame.new(x, -0.9, 0.1), wood) end
		local board = part("PartyBoard", Vector3.new(6, 3, 0.3), at, Color3.fromRGB(36, 17, 56), Enum.Material.Glass)
		board.Transparency = 0.15
		part("PartyBoardRim", Vector3.new(6.4, 3.4, 0.16), at * CFrame.new(0, 0, 0.14), Color3.fromRGB(150, 110, 220), Enum.Material.Glass) -- Neon glared white in the town view
		local sg = Instance.new("SurfaceGui")
		sg.Name, sg.Face, sg.SizingMode, sg.PixelsPerStud, sg.LightInfluence = "PartyGui", Enum.NormalId.Front, Enum.SurfaceGuiSizingMode.PixelsPerStud, 50, 0
		for i, d in { { "PARTY", 0.3, 0.2, Color3.fromRGB(255, 214, 107) }, { "0/5 FRIENDS HERE", 0.2, 0.52, Color3.new(1, 1, 1) }, { "+15% ORE VALUE WITH A FRIEND", 0.16, 0.8, Color3.fromRGB(0, 240, 255) } } do
			local t = Instance.new("TextLabel")
			t.Name, t.Size, t.Position, t.AnchorPoint, t.BackgroundTransparency = "Line" .. i, UDim2.fromScale(0.9, d[2]), UDim2.fromScale(0.5, d[3]), Vector2.new(0.5, 0.5), 1
			t.Text, t.TextScaled, t.Font, t.TextColor3 = d[1], true, Enum.Font.FredokaOne, d[4]
			t.Parent = sg
		end
		sg.Parent = board
		local pr = Instance.new("ProximityPrompt")
		pr.ActionText, pr.ObjectText, pr.KeyboardKeyCode, pr.GamepadKeyCode = "Invite", "Friends", Enum.KeyCode.F, Enum.KeyCode.ButtonX
		pr.MaxActivationDistance, pr.RequiresLineOfSight, pr.Style, pr.HoldDuration = 9, false, Enum.ProximityPromptStyle.Custom, 0
		pr:SetAttribute("PartyInvite", true)
		pr.Parent = board
		-- the refinery: a stone furnace with a glowing mouth on the other side of the shaft
		-- it stands on the first clear patch of ground round the shaft (2026-11-14: a fixed place put it on the daily chest's spot)
		local fat
		local op = OverlapParams.new()
		local rpm = RaycastParams.new()
		rpm.FilterType = Enum.RaycastFilterType.Exclude
		rpm.FilterDescendantsInstances = { cart }
		-- 2026-11-14 (the owner: "fix the furnace"): it belongs to the smith, so it stands in front of the FORGE on the side of the
		-- shaft; the ring round the shaft is only the fallback
		-- flowers and grass tufts do not count as "in the way" (they stood on every free patch): they are looked through here and
		-- the ones under the furnace are taken away once it has its place
		local soft = { cart }
		for _, d in hub:GetDescendants() do
			if d:IsA("BasePart") and (d.Name == "Flower" or d.Name == "Tuft" or d.Name == "EdgeTuft" or d.Name == "Stem" or d.Name == "Bloom") then soft[#soft + 1] = d end
		end
		rpm.FilterDescendantsInstances = soft
		op.FilterType = Enum.RaycastFilterType.Exclude
		op.FilterDescendantsInstances = soft
		local offLane = true -- first try: not on a path
		local function clearAt(at)
			local hit = workspace:Raycast(at + Vector3.new(0, 12, 0), Vector3.new(0, -24, 0), rpm)
			if hit and offLane and hit.Instance.Name == "Lane" then return nil end
			if hit and offLane then -- flat town ground only: the first try stood it on the lip of a terrace
				if hit.Position.Y > cart:GetPivot().Position.Y - 0.8 then return nil end
				for _, o in { Vector3.new(2.6, 0, 2.6), Vector3.new(-2.6, 0, 2.6), Vector3.new(2.6, 0, -2.6), Vector3.new(-2.6, 0, -2.6) } do
					local h2 = workspace:Raycast(at + o + Vector3.new(0, 12, 0), Vector3.new(0, -24, 0), rpm)
					if not h2 or math.abs(h2.Position.Y - hit.Position.Y) > 0.35 then return nil end
				end
			end
			if hit and math.abs(hit.Position.Y - cart:GetPivot().Position.Y) < 3 and #workspace:GetPartBoundsInBox(CFrame.new(hit.Position + Vector3.new(0, 4.8, 0)), Vector3.new(9, 8.4, 9), op) == 0 then
				return CFrame.lookAt(hit.Position, Vector3.new(cart:GetPivot().Position.X, hit.Position.Y, cart:GetPivot().Position.Z)) -- its mouth faces the shaft
			end
			return nil
		end
		local forge = hub:FindFirstChild("Forge")
		if forge then
			local fp = forge:GetPivot().Position
			local u = (cart:GetPivot().Position - fp) * Vector3.new(1, 0, 1)
			if u.Magnitude > 1 then
				u = u.Unit
				for _, r in { 14, 16, 18, 20, 22, 26 } do
					for _, deg in { 45, 30, -15, 15, -30, 60, 0, -45, 75, -75 } do
						fat = clearAt(Vector3.new(fp.X, cart:GetPivot().Position.Y, fp.Z) + CFrame.Angles(0, math.rad(deg), 0):VectorToWorldSpace(u) * r)
						if fat then break end
					end
					if fat then break end
				end
			end
		end
		offLane = false
		for _, r in { 13, 16, 19, 22 } do
			if fat then break end
			for _, k in { 1, 4, 7, 10, 2, 5, 8, 11, 0, 3, 6, 9 } do -- the diagonals first: the paths run straight out from the shaft
				local a = k / 12 * math.pi * 2
				fat = clearAt(cart:GetPivot().Position + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r))
				if fat then break end
			end
		end
		fat = fat or cart:GetPivot() * CFrame.new(16, 0.6, 14)
		for _, d in workspace:GetPartBoundsInBox(fat * CFrame.new(0, 2, 0), Vector3.new(9.4, 6, 6.4)) do
			if table.find(soft, d) and d ~= cart then d:Destroy() end
		end
		-- a voxel kiln: plinth, body with a pale band, a stepped hood and a chimney; an iron arch with grate bars round the glowing
		-- mouth; a crate of geodes on one side and the cut crystals on the other. No two faces share a plane (z-fight scan).
		local stone, stoneD, stoneL, iron = Color3.fromRGB(150, 138, 176), Color3.fromRGB(112, 100, 140), Color3.fromRGB(190, 180, 212), Color3.fromRGB(52, 44, 72)
		local SL = Enum.Material.Slate
		part("RefineryPlinth", Vector3.new(5.4, 0.5, 5), fat * CFrame.new(0, 0.25, 0), stoneD, SL)
		part("RefineryBase", Vector3.new(4.4, 2.9, 4), fat * CFrame.new(0, 1.95, 0), stone, SL)
		part("RefineryBand", Vector3.new(4.6, 0.35, 4.2), fat * CFrame.new(0, 3.3, 0), stoneL, SL)
		part("RefineryTop", Vector3.new(3.8, 0.7, 3.4), fat * CFrame.new(0, 3.825, 0), stoneD, SL)
		part("RefineryTop2", Vector3.new(3, 0.7, 2.6), fat * CFrame.new(0, 4.525, 0), stone, SL)
		part("RefineryChimney", Vector3.new(1.4, 2.6, 1.4), fat * CFrame.new(0.5, 6.175, 0.3), stoneD, SL)
		part("RefineryChimneyRim", Vector3.new(1.8, 0.35, 1.8), fat * CFrame.new(0.5, 7.65, 0.3), stoneL, SL)
		local glow = part("RefineryChimneyGlow", Vector3.new(0.9, 0.12, 0.9), fat * CFrame.new(0.5, 7.885, 0.3), Color3.fromRGB(255, 190, 90), Enum.Material.Neon)
		part("RefineryShelf", Vector3.new(3.4, 0.2, 0.9), fat * CFrame.new(0, 0.6, -2.45), stoneL, SL)
		for _, x in { -1.3, 1.3 } do part("RefineryJamb", Vector3.new(0.4, 1.9, 0.35), fat * CFrame.new(x, 1.65, -2.1), iron, Enum.Material.Metal) end
		part("RefineryLintel", Vector3.new(3, 0.4, 0.35), fat * CFrame.new(0, 2.8, -2.1), iron, Enum.Material.Metal)
		for _, x in { -0.55, 0, 0.55 } do part("RefineryBar", Vector3.new(0.12, 1.9, 0.12), fat * CFrame.new(x, 1.65, -2.19), iron, Enum.Material.Metal) end
		local mouth = part("RefineryMouth", Vector3.new(2.2, 1.9, 0.2), fat * CFrame.new(0, 1.65, -2), Color3.fromRGB(255, 140, 60), Enum.Material.Neon)
		for _, x in { -2.1, 2.1 } do part("RefinerySignPost", Vector3.new(0.25, 2.9, 0.25), fat * CFrame.new(x, 4.925, -1.7), wood) end
		-- the geodes that wait (a crate) and the crystals that came out (a stone block)
		part("RefineryCrate", Vector3.new(1.4, 1, 1.4), fat * CFrame.new(3.5, 0.5, -0.8) * CFrame.Angles(0, math.rad(12), 0), wood)
		for _, g in { { 3.4, 1.38, -0.9, 0.8, 20, Color3.fromRGB(64, 224, 208) }, { 3.75, 1.28, -0.35, 0.56, 48, Color3.fromRGB(255, 130, 200) } } do
			local gcf = fat * CFrame.new(g[1], g[2], g[3]) * CFrame.Angles(0, math.rad(g[5]), math.rad(8))
			part("RefineryGeode", Vector3.new(g[4], g[4], g[4]), gcf, Color3.fromRGB(70, 62, 92), SL)
			part("RefineryGeodeGem", Vector3.new(g[4] * 0.42, g[4] * 0.8, g[4] * 0.42), gcf * CFrame.new(0.05, g[4] * 0.5, 0) * CFrame.Angles(math.rad(14), 0, math.rad(-10)), g[6], Enum.Material.Glass).Transparency = 0.15
		end
		part("RefineryBlock", Vector3.new(1.3, 0.6, 1.3), fat * CFrame.new(-3.5, 0.3, -0.8) * CFrame.Angles(0, math.rad(-14), 0), stoneD, SL)
		for _, g in { { -3.6, 1.15, -0.9, 1.1, 10, -8 }, { -3.2, 0.95, -0.6, 0.7, -16, 14 }, { -3.75, 0.9, -0.45, 0.6, 20, 18 } } do
			local c = part("RefineryCrystal", Vector3.new(0.34, g[4], 0.34), fat * CFrame.new(g[1], g[2], g[3]) * CFrame.Angles(math.rad(g[5]), math.rad(30), math.rad(g[6])), Color3.fromRGB(64, 224, 208), Enum.Material.Glass)
			c.Transparency = 0.2
		end
		local smoke = Instance.new("ParticleEmitter")
		smoke.Texture, smoke.Rate, smoke.Lifetime, smoke.Speed, smoke.SpreadAngle = "rbxasset://textures/particles/smoke_main.dds", 3, NumberRange.new(3, 4), NumberRange.new(1.6, 2.2), Vector2.new(10, 10)
		smoke.Size, smoke.Transparency = NumberSequence.new(0.8, 2.4), NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.55), NumberSequenceKeypoint.new(1, 1) })
		smoke.Color, smoke.EmissionDirection, smoke.Acceleration, smoke.LightInfluence = ColorSequence.new(Color3.fromRGB(214, 200, 236)), Enum.NormalId.Top, Vector3.new(0.4, 0.3, 0), 0
		smoke.Parent = glow
		local sparks = Instance.new("ParticleEmitter")
		sparks.Texture, sparks.Rate, sparks.Lifetime, sparks.Speed, sparks.SpreadAngle = "rbxasset://textures/particles/sparkles_main.dds", 5, NumberRange.new(0.7, 1.3), NumberRange.new(1.5, 3), Vector2.new(35, 35)
		sparks.Size, sparks.Color, sparks.LightEmission, sparks.EmissionDirection, sparks.Acceleration = NumberSequence.new(0.22, 0), ColorSequence.new(Color3.fromRGB(255, 190, 90)), 1, Enum.NormalId.Front, Vector3.new(0, 3, 0)
		sparks.Parent = mouth
		local ml = Instance.new("PointLight")
		ml.Color, ml.Range, ml.Brightness, ml.Shadows = Color3.fromRGB(255, 150, 70), 14, 1, false
		ml.Parent = mouth
		local sign = part("RefinerySign", Vector3.new(4.6, 1.3, 0.2), fat * CFrame.new(0, 5.4, -1.7), wood)
		local rg = Instance.new("SurfaceGui")
		rg.Name, rg.Face, rg.SizingMode, rg.PixelsPerStud, rg.LightInfluence = "RefineryGui", Enum.NormalId.Front, Enum.SurfaceGuiSizingMode.PixelsPerStud, 50, 0
		local rt = Instance.new("TextLabel")
		rt.Position, rt.AnchorPoint = UDim2.fromScale(0.5, 0.5), Vector2.new(0.5, 0.5) -- inside the board: the first and last letter were cut
		rt.Name, rt.Size, rt.BackgroundTransparency, rt.Text, rt.TextScaled, rt.Font, rt.TextColor3 = "Line", UDim2.fromScale(0.84, 0.78), 1, "REFINERY", true, Enum.Font.FredokaOne, Color3.fromRGB(255, 214, 107)
		rt.Parent = rg
		rg.Parent = sign
		local rp = Instance.new("ProximityPrompt")
		rp.ActionText, rp.ObjectText, rp.KeyboardKeyCode, rp.GamepadKeyCode = "Refine", "A geode", Enum.KeyCode.F, Enum.KeyCode.ButtonX
		rp.MaxActivationDistance, rp.RequiresLineOfSight, rp.Style, rp.HoldDuration = 9, false, Enum.ProximityPromptStyle.Custom, 0
		rp:SetAttribute("Refinery", true)
		rp.Parent = mouth
		rp.Triggered:Connect(function(plr) refinery(plr, rp) end)
	end
end

return M
