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
		for _, r in { 13, 16, 19, 22 } do
			for _, k in { 1, 4, 7, 10, 2, 5, 8, 11, 0, 3, 6, 9 } do -- the diagonals first: the paths run straight out from the shaft
				local a = k / 12 * math.pi * 2
				local at = cart:GetPivot().Position + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)
				local hit = workspace:Raycast(at + Vector3.new(0, 12, 0), Vector3.new(0, -24, 0), rpm)
				if hit and math.abs(hit.Position.Y - cart:GetPivot().Position.Y) < 3 and #workspace:GetPartBoundsInBox(CFrame.new(hit.Position + Vector3.new(0, 4.6, 0)), Vector3.new(8, 8, 8), op) == 0 then
					fat = CFrame.lookAt(hit.Position, Vector3.new(cart:GetPivot().Position.X, hit.Position.Y, cart:GetPivot().Position.Z)) -- its mouth faces the shaft
					break
				end
			end
			if fat then break end
		end
		fat = fat or cart:GetPivot() * CFrame.new(16, 0.6, 14)
		local stone, stoneD = Color3.fromRGB(150, 138, 176), Color3.fromRGB(112, 100, 140) -- pale stone: the first, darker one read as a black block from the town camera
		part("RefineryBase", Vector3.new(4.4, 3.2, 4), fat * CFrame.new(0, 1.6, 0), stone, Enum.Material.Slate)
		part("RefineryTop", Vector3.new(3.6, 1.4, 3.2), fat * CFrame.new(0, 3.9, 0), stoneD, Enum.Material.Slate)
		part("RefineryChimney", Vector3.new(1.4, 3, 1.4), fat * CFrame.new(1, 6.1, 0.6), stoneD, Enum.Material.Slate)
		part("RefineryEmbers", Vector3.new(1.8, 0.2, 1.4), fat * CFrame.new(-0.6, 4.66, -0.2), Color3.fromRGB(255, 150, 60), Enum.Material.Neon) -- a glowing grate on top, seen from above
		part("RefineryChimneyGlow", Vector3.new(0.9, 0.2, 0.9), fat * CFrame.new(1, 7.66, 0.6), Color3.fromRGB(255, 190, 90), Enum.Material.Neon)
		local mouth = part("RefineryMouth", Vector3.new(2.2, 1.5, 0.3), fat * CFrame.new(0, 1.5, -2.02), Color3.fromRGB(255, 140, 60), Enum.Material.Neon)
		local ml = Instance.new("PointLight")
		ml.Color, ml.Range, ml.Brightness, ml.Shadows = Color3.fromRGB(255, 150, 70), 14, 1, false
		ml.Parent = mouth
		local sign = part("RefinerySign", Vector3.new(4.6, 1.3, 0.2), fat * CFrame.new(0, 5.4, -1.7), wood)
		local rg = Instance.new("SurfaceGui")
		rg.Name, rg.Face, rg.SizingMode, rg.PixelsPerStud, rg.LightInfluence = "RefineryGui", Enum.NormalId.Front, Enum.SurfaceGuiSizingMode.PixelsPerStud, 50, 0
		local rt = Instance.new("TextLabel")
		rt.Name, rt.Size, rt.BackgroundTransparency, rt.Text, rt.TextScaled, rt.Font, rt.TextColor3 = "Line", UDim2.fromScale(1, 1), 1, "REFINERY", true, Enum.Font.FredokaOne, Color3.fromRGB(255, 214, 107)
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
