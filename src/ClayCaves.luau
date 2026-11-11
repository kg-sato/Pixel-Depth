-- ClayCaves (ServerScriptService.ClayCaves): the foundation of Camp 2, the Clay Caves (roadmap phase 10; the user's overnight
-- directive of 2026-11-10; brief: vault Briefs/Camp 2 Clay Caves (2026-11-09).md). One closed terracotta hall at
-- C.CAVE2_ORIGIN, built from parts (not the cell caves): a foundation to play and react to, not the final art or layout.
--   build(caves)  the hall under workspace.Caves.Clay, and its ore as normal deposits in Caves.Deposits (PixelServer then
--                 gives them prompts and loot like any other deposit). Call right after CaveBuilder.build.
--   init(ctx)     the prompts: the way down in Camp 1's Deep Gate alcove and the way back, clay jars, fossil spots.
-- In the hall: an arrival ledge, the kiln camp with the Kiln Keeper's stall (Camp 2's safe ring, C.CAMPS[2]), two steam
-- vents that throw you up to two high mesas with rare ore (Shared.ClayClient does the launch and the glide), eight clay jars
-- to smash (coins, sometimes a relic shard) and three fossil spots to brush clean (Shared.ClayClient plays the brushing; the
-- server pays once per fossil, ever). The server decides every reward.
local Players = game:GetService("Players")
local C = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"))
local M = {}
local K = C.CLAY

local CLAY, CLAY_D, CLAY_L = Color3.fromRGB(150, 78, 58), Color3.fromRGB(104, 52, 46), Color3.fromRGB(196, 112, 78)
local PLUM, CREAM, BARK, AMBER = Color3.fromRGB(58, 36, 72), Color3.fromRGB(240, 222, 190), Color3.fromRGB(92, 62, 48), Color3.fromRGB(255, 176, 84)
local DECO = { CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false }
local jars, fossils = {}, {}

function M.build(caves)
	local O = CFrame.new(C.CAVE2_ORIGIN)
	local folder = Instance.new("Folder")
	folder.Name = "Clay"
	folder.Parent = caves
	local depF = caves:FindFirstChild("Deposits")
	local rng = Random.new(2)
	local function part(name, size, cf, color, props)
		local p = Instance.new("Part")
		p.Name, p.Size, p.CFrame, p.Color = name, size, cf, color
		p.Material, p.Anchored, p.TopSurface, p.BottomSurface = Enum.Material.SmoothPlastic, true, Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		for k, v in props or {} do p[k] = v end
		p.Parent = folder
		return p
	end
	local ROCK = { Material = Enum.Material.Slate, MaterialVariant = "PixelCaveRock" }
	local function prompt(p, action, object, attr, value, dist)
		local pr = Instance.new("ProximityPrompt")
		pr.ActionText, pr.ObjectText, pr.KeyboardKeyCode, pr.GamepadKeyCode = action, object, Enum.KeyCode.F, Enum.KeyCode.ButtonX
		pr.MaxActivationDistance, pr.RequiresLineOfSight, pr.Style, pr.HoldDuration = dist or 9, false, Enum.ProximityPromptStyle.Custom, 0
		pr:SetAttribute(attr, value)
		pr.Parent = p
		return pr
	end
	local function lamp(pos, b) -- a hanging clay lamp: a warm wick in a pot, well over head height
		part("LampPot", Vector3.new(1.6, 1.2, 1.6), O * CFrame.new(pos), CLAY_D, DECO)
		local wick = part("LampWick", Vector3.new(0.5, 0.5, 0.5), O * CFrame.new(pos + Vector3.new(0, 0.75, 0)), AMBER, { Material = Enum.Material.Neon, CanCollide = false, CastShadow = false })
		part("LampChain", Vector3.new(0.2, 69 - pos.Y, 0.2), O * CFrame.new(pos.X, (71 + pos.Y) / 2, pos.Z), PLUM, DECO) -- from the wick up to the roof
		local l = Instance.new("PointLight")
		l.Color, l.Range, l.Brightness, l.Shadows = AMBER:Lerp(CREAM, 0.4), 60, b or 0.9, false
		l.Parent = wick
		l:SetAttribute("Fixture", true)
	end

	-- the shell: floor, four walls, roof (the hall is 150 x 110, 70 high; x runs east, the arrival ledge is at the west end)
	part("Floor", Vector3.new(166, 6, 126), O * CFrame.new(0, -3, 0), CLAY_D, ROCK)
	part("Roof", Vector3.new(164, 6, 124), O * CFrame.new(0, 73, 0), PLUM, ROCK)
	for _, z in { -57, 57 } do part("Wall", Vector3.new(158, 76, 6), O * CFrame.new(0, 35, z), CLAY, ROCK) end
	for _, x in { -77, 77 } do part("Wall", Vector3.new(6, 76, 110), O * CFrame.new(x, 35, 0), CLAY, ROCK) end
	for i = 1, 26 do -- clay strata: long ledges of a lighter band stepping round the walls, so the box reads as dug rock
		local side, y = i % 4, 6 + rng:NextNumber() * 52
		local len, deep = rng:NextNumber(18, 44), rng:NextNumber(1.2, 3)
		if side < 2 then
			local z = (side == 0 and -1 or 1) * (54 - deep / 2 + 0.05 + i * 0.05) -- each ledge's hidden back face at its own depth in the wall
			part("Strata", Vector3.new(len, rng:NextNumber(2, 5), deep), O * CFrame.new(rng:NextNumber(-55, 55), y, z), i % 3 == 0 and CLAY_L or CLAY_D, ROCK)
		else
			local x = (side == 2 and -1 or 1) * (74 - deep / 2 + 0.05 + i * 0.05)
			part("Strata", Vector3.new(deep, rng:NextNumber(2, 5), len), O * CFrame.new(x, y, rng:NextNumber(-36, 36)), i % 3 == 0 and CLAY_L or CLAY_D, ROCK)
		end
	end
	for i = 0, 29 do -- floor slabs of baked clay on a loose grid (one per 24 x 20 cell, so no two overlap), sunk 0.05 into the floor
		local s, k = rng:NextNumber(6, 10), i % 4
		part("Slab", Vector3.new(s, 0.24 + k * 0.12, s * rng:NextNumber(0.8, 1.1)), O * CFrame.new(-60 + (i % 6) * 24 + rng:NextNumber(-3, 3), 0.07 + k * 0.06, -40 + (i // 6) * 20 + rng:NextNumber(-2, 2)) * CFrame.Angles(0, rng:NextNumber(0, 3), 0), i % 2 == 0 and CLAY or CLAY_L, { Material = Enum.Material.Slate, CanCollide = false })
	end

	-- the arrival ledge (west): a root arch with the way back to Camp 1
	local arrive = O * CFrame.new(-64, 0, 0)
	part("Ledge", Vector3.new(14, 1.2, 18), arrive * CFrame.new(0, 0.6, 0), CLAY_L, ROCK)
	for _, z in { -5, 5 } do part("ArchRoot", Vector3.new(2, 12, 2), arrive * CFrame.new(-5.2, 7.2, z), BARK, { Material = Enum.Material.Wood }) end
	part("ArchRoot", Vector3.new(2, 2, 13), arrive * CFrame.new(-5.2, 13.4, 0), BARK, { Material = Enum.Material.Wood })
	local back = part("ArchDark", Vector3.new(0.6, 11, 8), arrive * CFrame.new(-5.6, 6.7, 0), Color3.fromRGB(14, 8, 22))
	prompt(back, "Climb back", "Camp 1", "ClayPortal", 1, 10)
	local land = part("ClayLanding", Vector3.new(4, 1, 4), arrive * CFrame.new(1, 1.7, 0), CLAY, { Transparency = 1, CanCollide = false, CanQuery = false })
	land.Parent = folder
	lamp(Vector3.new(-60, 16, 0), 0.7)

	-- the kiln camp (centre): the kiln, the Kiln Keeper's stall, a ring of butter tiles marking the safe ground
	for k = 0, 23 do
		local a = k / 24 * math.pi * 2
		part("RingTile", Vector3.new(3.4, 0.3, 1.4), O * CFrame.new(math.cos(a) * (C.CAMP_RING - 2), 0.75, math.sin(a) * (C.CAMP_RING - 2)) * CFrame.Angles(0, -a + math.pi / 2, 0), k % 2 == 0 and CREAM or AMBER, { CanCollide = false, CastShadow = false })
	end
	local kiln = O * CFrame.new(6, 0, -12)
	for i, s in { { 13, 4, 0 }, { 11.4, 4, 4 }, { 9, 3.4, 7.7 }, { 5.6, 2.6, 10.7 } } do -- a stepped beehive kiln
		part("Kiln", Vector3.new(s[1], s[2], s[1]), kiln * CFrame.new(0, s[3] + s[2] / 2, 0), i % 2 == 0 and CLAY_L or CLAY, ROCK)
	end
	part("KilnChimney", Vector3.new(2.4, 5, 2.4), kiln * CFrame.new(0, 15.8, 0), CLAY_D, ROCK)
	local mouth = part("KilnMouth", Vector3.new(4.4, 3, 0.5), kiln * CFrame.new(0, 1.7, 6.3), AMBER, { Material = Enum.Material.Neon, CanCollide = false, CastShadow = false })
	local ml = Instance.new("PointLight")
	ml.Color, ml.Range, ml.Brightness, ml.Shadows = AMBER, 30, 0.8, false
	ml.Parent = mouth
	ml:SetAttribute("Fixture", true)
	part("KilnArch", Vector3.new(6.2, 1.2, 1), kiln * CFrame.new(0, 3.8, 6.4), CLAY_D, ROCK)
	for _, x in { -2.7, 2.7 } do part("KilnArch", Vector3.new(0.9, 3.4, 1), kiln * CFrame.new(x, 1.5, 6.4), CLAY_D, ROCK) end -- sunk 0.2 into the floor: its foot was level with the kiln's
	-- the stall: a counter, an awning on four posts, pots on the counter, and the Kiln Keeper (a mole potter) behind it
	local stall = O * CFrame.new(-10, 0, -10) * CFrame.Angles(0, 0.5, 0)
	part("Counter", Vector3.new(8, 2.6, 2.4), stall * CFrame.new(0, 2.05, 0), BARK, { Material = Enum.Material.Wood })
	part("CounterTop", Vector3.new(8.6, 0.4, 3), stall * CFrame.new(0, 3.55, 0), CREAM)
	for _, x in { -4, 4 } do for _, z in { -2.6, 1.4 } do part("Post", Vector3.new(0.5, 8, 0.5), stall * CFrame.new(x, 4.75, z), BARK, { Material = Enum.Material.Wood }) end end
	for k = 0, 4 do part("Awning", Vector3.new(1.84, 0.4, 5.4), stall * CFrame.new(-3.68 + k * 1.84, 9 + (k % 2) * 0.06, -0.6) * CFrame.Angles(0.14, 0, 0), k % 2 == 0 and CLAY_L or CREAM, DECO) end
	for i, x in { -2.6, -0.6, 1.6 } do
		part("Pot", Vector3.new(1.1, 1.2 + i * 0.2, 1.1), stall * CFrame.new(x, 4.35 + i * 0.1, 0.2), i % 2 == 0 and CLAY_L or CLAY, DECO)
		part("PotRim", Vector3.new(1.34, 0.26, 1.34), stall * CFrame.new(x, 5.08 + i * 0.2, 0.2), CLAY_D, DECO)
	end
	local keeper = stall * CFrame.new(0.4, 0, -1.9)
	local MOLE, SNOUT = Color3.fromRGB(88, 70, 84), Color3.fromRGB(232, 168, 160)
	local body = part("Keeper", Vector3.new(3, 3.2, 2.6), keeper * CFrame.new(0, 2.35, 0), MOLE, { CanCollide = false })
	part("KeeperHead", Vector3.new(2.8, 2.4, 2.5), keeper * CFrame.new(0, 5.15, 0.1), MOLE, DECO)
	part("KeeperSnout", Vector3.new(1, 0.8, 0.7), keeper * CFrame.new(0, 4.75, 1.5), SNOUT, DECO)
	for _, x in { -0.7, 0.7 } do part("KeeperEye", Vector3.new(0.34, 0.4, 0.12), keeper * CFrame.new(x, 5.5, 1.36), Color3.fromRGB(26, 18, 34), DECO) end
	part("KeeperApron", Vector3.new(2.4, 2.2, 0.2), keeper * CFrame.new(0, 2.3, 1.36), CREAM, DECO)
	for _, x in { -1.9, 1.9 } do part("KeeperPaw", Vector3.new(0.9, 0.9, 1.1), keeper * CFrame.new(x, 3.2, 0.9), SNOUT, DECO) end
	part("KeeperHat", Vector3.new(3, 0.5, 2.7), keeper * CFrame.new(0, 6.6, 0.1), CLAY_L, DECO)
	prompt(body, "Talk", "Kiln Keeper", "Keeper", true, 12)
	lamp(Vector3.new(-2, 20, 4), 1.1)
	for _, x in { -42, -12, 20, 46 } do for _, z in { -34, 34 } do lamp(Vector3.new(x, 24, z), 1.5) end end -- two rows of lamps down the hall: without them it was a dark red box

	-- two mesas (east) with rare ore on top, and a steam vent in front of each
	local function deposit(cf, idx) -- the same shape and attributes as CaveBuilder's deposits
		local ore = C.LAYERS[2][4][idx]
		local dep = Instance.new("Model")
		dep.Name = "Deposit"
		dep:SetAttribute("Layer", 2)
		dep:SetAttribute("Ore", idx)
		dep:SetAttribute("OreName", ore[1])
		local k = 0.85 + idx * 0.3
		local function shard(size, c, col, props)
			local p = part("Shard", size * k, cf * c, col, props)
			p.Parent = dep
			return p
		end
		shard(Vector3.new(2.2, 0.8, 1.6), CFrame.new(0, 0.3 * k, 0), CLAY_D, { CastShadow = false })
		local core = shard(Vector3.new(0.9, 1.9, 0.9), CFrame.new(0, 1.15 * k, -0.1) * CFrame.Angles(0.15, 0, 0.1), ore[2]:Lerp(Color3.new(0, 0, 0), 0.28 - idx * 0.08), { Material = Enum.Material.Neon, CastShadow = false })
		core.Name = "Core"
		for s = 1, 1 + idx do
			local a = (s / (1 + idx) - 0.5) * 2.4
			local h = 1 + rng:NextNumber() * 1.1
			shard(Vector3.new(0.7, h, 0.7), CFrame.new(math.sin(a) * 0.8, h * 0.45 * k, math.cos(a) * 0.3 - 0.4) * CFrame.Angles(0.35, 0, -a * 0.4), ore[2]:Lerp(Color3.new(0, 0, 0), rng:NextNumber(0, 0.35)), { CastShadow = false })
		end
		local l = Instance.new("PointLight")
		l.Name, l.Color, l.Range, l.Brightness, l.Shadows = "Glint", ore[2], 7, 0.35, false
		l.Parent = core
		dep.PrimaryPart = core
		dep.Parent = depF
	end
	for i, m in { { 58, -26, K.mesa[1] }, { 58, 26, K.mesa[2] } } do
		local top = m[3]
		part("Mesa", Vector3.new(22, top, 22), O * CFrame.new(m[1], top / 2, m[2]), CLAY, ROCK)
		part("MesaCap", Vector3.new(24, 1.4, 24), O * CFrame.new(m[1], top + 0.7, m[2]), CLAY_L, ROCK)
		for k = 1, 3 do part("MesaBand", Vector3.new(22.6, 1.6, 22.6), O * CFrame.new(m[1], top * k / 4, m[2]), CLAY_D, ROCK) end
		deposit(O * CFrame.new(m[1] + 6, top + 1.4, m[2]) * CFrame.Angles(0, -math.pi / 2, 0), 3)
		deposit(O * CFrame.new(m[1] - 2, top + 1.4, m[2] + 7 * (i == 1 and 1 or -1)) * CFrame.Angles(0, i == 1 and math.pi or 0, 0), 2)
		local v = O * CFrame.new(m[1] - 20, 0, m[2]) -- the vent: a ring of clay blocks round a dark hole
		for k = 0, 7 do
			local a = k / 8 * math.pi * 2
			part("VentRim", Vector3.new(2.2, 1.2 + (k % 2) * 0.5, 1.6), v * CFrame.new(math.cos(a) * 3.2, 0.6 + (k % 2) * 0.25, math.sin(a) * 3.2) * CFrame.Angles(0, -a + math.pi / 2, 0), k % 2 == 0 and CLAY_L or CLAY_D, ROCK)
		end
		local hole = part("SteamVent", Vector3.new(4.6, 0.3, 4.6), v * CFrame.new(0, 0.75, 0), Color3.fromRGB(20, 12, 26), { CanCollide = false })
		hole:SetAttribute("SteamVent", i) -- Shared.ClayClient erupts it on a rhythm and launches whoever stands in it
		hole:SetAttribute("Top", top)
		lamp(Vector3.new(m[1] - 12, top + 18, m[2]), 0.4) -- low: at 0.8 it burned the mesa cap white
	end
	-- violet crystal clusters at the wall feet: the cool colour the warm clay needs (deep violet shadows, the user's directive)
	local VIOLET = Color3.fromRGB(150, 110, 255)
	for i, c in { { -56, -51 }, { -24, 51 }, { 6, -51 }, { 38, 51 }, { 71, 20 }, { 71, -44 }, { -71, -22 }, { 52, -51 } } do
		local base = O * CFrame.new(c[1], 0, c[2])
		for k = 1, 3 do
			local h = 2 + rng:NextNumber() * 3.5
			local cr = part("VioletCrystal", Vector3.new(0.9, h, 0.9), base * CFrame.new((k - 2) * 1.1, h / 2 - 0.2, (k % 2) * 0.8) * CFrame.Angles(rng:NextNumber(-0.3, 0.3), k, rng:NextNumber(-0.3, 0.3)), VIOLET:Lerp(Color3.new(0, 0, 0), 0.3), { Material = Enum.Material.Neon, CanCollide = false, CastShadow = false })
			if k == 2 then
				local l = Instance.new("PointLight")
				l.Color, l.Range, l.Brightness, l.Shadows = VIOLET, 26, 0.7, false
				l.Parent = cr
			end
		end
	end
	-- common ore along the walls
	for i, d in { { -40, -52.2, 0 }, { -12, -52.2, 0 }, { 22, -52.2, 0 }, { -44, 52.2, math.pi }, { -8, 52.2, math.pi }, { 26, 52.2, math.pi }, { 72.2, 0, -math.pi / 2 }, { -72.2, 30, math.pi / 2 } } do
		deposit(O * CFrame.new(d[1], 0.1, d[2]) * CFrame.Angles(0, d[3], 0), i % 3 == 0 and 2 or 1)
	end

	-- clay jars: a body, a neck and a rim; the prompt sits on the body. Shared for everyone; the server pays per player.
	for i, at in { { -30, 18 }, { -26, 22 }, { 20, 16 }, { 34, -4 }, { -46, -30 }, { 12, 38 }, { 44, 40 }, { -20, -40 } } do
		local s = 0.9 + (i % 3) * 0.25
		local cf = O * CFrame.new(at[1], -0.05, at[2]) * CFrame.Angles(0, i, 0)
		local jar = Instance.new("Model")
		jar.Name = "ClayJar"
		local function jp(name, size, c, col)
			local p = part(name, size * s, cf * (c.Rotation + c.Position * s), col, { CanCollide = name == "JarBody" })
			p.Parent = jar
			return p
		end
		local b = jp("JarBody", Vector3.new(2.2, 2.4, 2.2), CFrame.new(0, 1.2, 0), i % 2 == 0 and CLAY_L or CLAY)
		jp("JarBand", Vector3.new(2.36, 0.4, 2.36), CFrame.new(0, 1.5, 0), CREAM)
		jp("JarNeck", Vector3.new(1.3, 0.6, 1.3), CFrame.new(0, 2.7, 0), CLAY_D)
		jp("JarRim", Vector3.new(1.7, 0.3, 1.7), CFrame.new(0, 3.15, 0), CLAY_L)
		jar.PrimaryPart = b
		jar:SetAttribute("Jar", i)
		jar.Parent = folder
		jars[i] = prompt(b, "Smash", "Clay jar", "ClayJar", i, 7)
	end
	-- fossil spots: a slab of pale clay on the wall with the amber shape showing faintly through
	for i, f in { { -30, 53.4, math.pi }, { 40, -53.4, 0 }, { 73.4, -30, -math.pi / 2 } } do
		local cf = O * CFrame.new(f[1], 4.5, f[2]) * CFrame.Angles(0, f[3], 0)
		local slab = part("FossilSlab", Vector3.new(7, 6, 0.9), cf, CREAM:Lerp(CLAY_L, 0.45), ROCK)
		for k = 0, 4 do -- a curled amber shape, sunk 0.06 proud of the slab
			local a = k * 1.1
			part("FossilHint", Vector3.new(1.1 - k * 0.12, 1.1 - k * 0.12, 0.2), cf * CFrame.new(math.cos(a) * (1.6 - k * 0.28), math.sin(a) * (1.6 - k * 0.28), 0.42), AMBER:Lerp(CLAY, 0.45), { CanCollide = false, CastShadow = false })
		end
		slab:SetAttribute("Fossil", i)
		fossils[i] = prompt(slab, "Brush", "Old fossil", "Fossil", i, 9)
	end
	return folder
end

function M.init(ctx)
	local caves = workspace:FindFirstChild("Caves")
	local clay = caves and caves:FindFirstChild("Clay")
	if not clay then return end
	local remote = ctx.remote("Clay")
	local landing = clay:FindFirstChild("ClayLanding")
	local stairs = caves:FindFirstChild("ClayStairs", true) -- in Camp 1's Deep Gate alcove (CaveBuilder)
	local jarAt, brushing = {}, {} -- [plr] = { [jar] = next time }, [plr] = { i, started }
	Players.PlayerRemoving:Connect(function(plr) jarAt[plr], brushing[plr] = nil, nil end)

	local function travel(plr, to)
		local s, hrp = ctx.data[plr], ctx.hrpOf(plr)
		if not s or not hrp or ctx.busy(plr) or s.mg then return end
		if to == 2 and not s.tips.gate1 then return end -- the Root Warden still guards the gate
		local goal = to == 2 and landing.CFrame or (stairs and stairs.CFrame * CFrame.new(0, 1, -4))
		if not goal then return end
		ctx.fx:FireClient(plr, "clayTravel", to)
		task.delay(0.35, function() -- under the client's fade
			if hrp.Parent then
				hrp.AssemblyLinearVelocity = Vector3.zero
				hrp.CFrame = goal + Vector3.new(0, 2, 0)
			end
		end)
		if to == 2 and not s.tips.clay then
			s.tips.clay = true
			if ctx.analytics then ctx.analytics.event(s, "ClayCavesReached") end
		end
	end
	local function near(plr, p, d)
		local hrp = ctx.hrpOf(plr)
		return hrp ~= nil and (hrp.Position - p.Position).Magnitude <= d
	end
	for _, d in clay:GetDescendants() do
		if d:IsA("ProximityPrompt") and d:GetAttribute("ClayPortal") then d.Triggered:Connect(function(plr) travel(plr, 1) end) end
	end
	if stairs then
		local pr = stairs:FindFirstChildOfClass("ProximityPrompt")
		if pr then pr.Triggered:Connect(function(plr) travel(plr, 2) end) end
	end
	for i, pr in jars do
		pr.Triggered:Connect(function(plr)
			local s = ctx.data[plr]
			jarAt[plr] = jarAt[plr] or {}
			if not s or os.clock() < (jarAt[plr][i] or 0) or not near(plr, pr.Parent, 14) then return end
			jarAt[plr][i] = os.clock() + K.jarEvery
			local rng = Random.new()
			local gold = rng:NextInteger(K.jarGold[1], K.jarGold[2])
			local shard = rng:NextNumber() < K.shardOdds
			s.gold += gold
			if shard then s.shards = (s.shards or 0) + 1 end
			if ctx.analytics then ctx.analytics.earn(s, "Coins", gold, s.gold, "ClayJar") end
			ctx.fx:FireClient(plr, "jar", i, gold, shard and s.shards or nil, K.jarEvery)
			ctx.sendState(s)
		end)
	end
	for i, pr in fossils do
		pr.Triggered:Connect(function(plr)
			local s = ctx.data[plr]
			if not s or s.mg or ctx.busy(plr) then return end
			s.fossils = s.fossils or {}
			if s.fossils[tostring(i)] then ctx.fx:FireClient(plr, "fossilHave", i) return end
			brushing[plr] = { i = i, t = os.clock() }
			ctx.fx:FireClient(plr, "fossilBrush", i)
		end)
	end
	remote.OnServerEvent:Connect(function(plr, what, i)
		local s, b = ctx.data[plr], brushing[plr]
		if what ~= "fossil" or not s or not b or b.i ~= i or not fossils[i] then return end
		brushing[plr] = nil
		-- the client plays the brushing; the server checks the place, the time it must take, and pays once per fossil ever
		if os.clock() - b.t < K.brushMin or not near(plr, fossils[i].Parent, 16) then return end
		s.fossils = s.fossils or {}
		if s.fossils[tostring(i)] then return end
		s.fossils[tostring(i)] = true
		s.gems += K.fossilGems
		local n = 0
		for _ in s.fossils do n += 1 end
		if ctx.analytics then
			ctx.analytics.earn(s, "Gems", K.fossilGems, s.gems, "Fossil")
			ctx.analytics.event(s, "Fossil_" .. i)
		end
		ctx.fx:FireClient(plr, "fossilDone", i, K.fossilGems, n, #fossils)
		ctx.sendState(s)
	end)
	if game:GetService("RunService"):IsStudio() then -- Studio test hook: player attribute DevClay = 2 (go down, gate or not) or 1 (back)
		local function hook(plr)
			plr:GetAttributeChangedSignal("DevClay"):Connect(function()
				local to = plr:GetAttribute("DevClay")
				if not to then return end
				plr:SetAttribute("DevClay", nil)
				local s = ctx.data[plr]
				if s and to == 2 then s.tips.gate1 = true end
				travel(plr, to)
			end)
		end
		for _, p in Players:GetPlayers() do hook(p) end
		Players.PlayerAdded:Connect(hook)
	end
end

return M
