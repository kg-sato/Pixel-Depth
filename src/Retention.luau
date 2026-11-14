-- Retention (ServerScriptService.Retention): reasons to stay and to play together (directive v9, 2026-11-13, section 5B).
--   * Playtime gifts: C.GIFTS is a ladder of minutes played today and a gift for each (coins, flares, gems, an egg). The
--     server counts the seconds, tells the client where the ladder stands (Fx "gift"), and pays a gift only when the client
--     asks for one that is due (remote Gift, "claim"). The ladder starts again each day (UTC). Saved: profile field `gift`
--     = { day, secs, got }.
--   * Lantern Tether: friends in the same server help each other. With one friend or more here, ore is worth C.TETHER.value
--     more (PixelServer asks M.valueMult); in the caves, within C.TETHER.reach studs of a friend, the torch burns
--     C.TETHER.torch slower (Gloom.slow). The player attributes Friends (how many, 5 at most) and TetherTo (the friend beside
--     you, or nil) tell the client what to draw (Shared.LanternTether). A party board by the MINE shaft invites friends.
-- Studio hooks: player attribute DevGiftSecs = seconds played today; DevFriends = number of friends (every other player counts as one).
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
				if s and s.gift then return tell(plr, s) end
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
	end
end

return M
