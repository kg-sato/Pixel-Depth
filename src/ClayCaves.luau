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
local jars, fossils, echoes, chimes = {}, {}, {}, {}

local mushroomPad -- set in M.build (directive v13): a spore-cap mushroom bounce pad
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
	local ROCK = { Material = Enum.Material.Sandstone } -- matte baked clay: the cave rock variant read as a wet, mottled oil slick here (Gemini, 2026-11-10)
	local function prompt(p, action, object, attr, value, dist)
		local pr = Instance.new("ProximityPrompt")
		pr.ActionText, pr.ObjectText, pr.KeyboardKeyCode, pr.GamepadKeyCode = action, object, Enum.KeyCode.F, Enum.KeyCode.ButtonX
		pr.MaxActivationDistance, pr.RequiresLineOfSight, pr.Style, pr.HoldDuration = dist or 9, false, Enum.ProximityPromptStyle.Custom, 0
		pr:SetAttribute(attr, value)
		pr.Parent = p
		return pr
	end
	local roofAt = function() return 71 end -- set once the shell is built (directive v14: the roof is a vault now)
	local function lamp(pos, b) -- a hanging clay lamp: a warm wick in a pot, well over head height
		part("LampPot", Vector3.new(1.6, 1.2, 1.6), O * CFrame.new(pos), CLAY_D, DECO)
		local wick = part("LampWick", Vector3.new(0.5, 0.5, 0.5), O * CFrame.new(pos + Vector3.new(0, 0.75, 0)), AMBER, { Material = Enum.Material.Neon, CanCollide = false, CastShadow = false })
		local top = roofAt(pos.X, pos.Z) + 1
		part("LampChain", Vector3.new(0.2, top - 2 - pos.Y, 0.2), O * CFrame.new(pos.X, (top + pos.Y) / 2, pos.Z), PLUM, DECO) -- from the wick up to the roof
		local l = Instance.new("PointLight")
		l.Color, l.Range, l.Brightness, l.Shadows = AMBER:Lerp(CREAM, 0.4), 60, b or 0.9, false
		l.Parent = wick
		l:SetAttribute("Fixture", true)
	end

	-- the shell (directive v14 phase 3; Gemini and the 2026-11-21 audit: "a flat 166 x 126 x 70 cuboid with house moulding"): a
	-- cavern of 4-stud voxels round the same playable floor (x -74..74, z -54..54, flat at y 0). Below 26 studs the walls keep
	-- the old planes, so every prop, prompt and echo wall along them keeps its place; above that they recede into alcoves between
	-- rock buttresses, and the roof rises from 70 in a corbelled vault, two tiers each a step narrower, to 86. Every block is
	-- cut from tilted clay strata (terracotta, ochre, red clay, cream, plum shale), darker overhead. Rimstone slip pools and
	-- breakdown talus are set along the wall feet at the end of build (decor, no collision).
	do -- a plum-brown floor under terracotta walls: one colour everywhere read as soup
		local fl = part("Floor", Vector3.new(166, 6, 126), O * CFrame.new(0, -3, 0), Color3.fromRGB(88, 50, 58), ROCK)
		local cr = Instance.new("Texture") -- dried-clay crack plates (art/tex/clay_cracks.png; Gemini full1122d: "large expanses of flat floor lack detail"), no parts
		cr.Name, cr.Texture, cr.Face, cr.StudsPerTileU, cr.StudsPerTileV, cr.Transparency = "ClayCracks", "rbxassetid://126454815185079", Enum.NormalId.Top, 26, 26, 0.15
		cr.Parent = fl
	end
	local OPEN = { { 6, 16, 14 }, { 45, 60, 34 } } -- the north openings: x from, x to, height (the Jar Gallery door, the Fossil Dig breach)
	local VX, X0, Y0, Z0, NXc, NYc, NZc = 4, -82, -2, -62, 41, 23, 31 -- cells: x -82..82, y -2..90, z -62..62
	local KEEP = { { -48, -32, -54, 30 }, { 36, 66, -54, 44 }, { -10, 14, 54, 30 }, { 36, 56, 54, 30 }, { -74, -74, -44, 30 } } -- x0, x1, wall z (or x for -74), top: wall-hung things stay on a flat face
	local function bandA(cx, cy, cz) return math.floor((cy + 0.24 * cx - 0.1 * cz + 5 * math.noise(cx / 40, cz / 40, 1.3)) / 10) % 5 + 1 end
	local function open(cx, cy, cz)
		if cy < 0 or cy >= 86 then return false end
		local ax, az = math.abs(cx), math.abs(cz)
		if ax < 74 and az < 54 and cy < 70 then return true end
		if C.CAVE_V2_L2 and ax < 82 and az < 10 and cy < 18 then return true end -- the side doors onto the Cave v2 galleries
		if cz < -50 then for _, o in OPEN do if cx > o[1] and cx < o[2] + 2 and cy < o[3] then return true end end end
		if cy > 26 and cy < 70 and ((az >= 54 and az < 58 and ax < 74) or (ax >= 74 and ax < 78 and az < 54)) then -- alcoves between buttresses
			for _, k in KEEP do
				if cy < k[4] and ((k[1] == -74 and ax >= 74 and cx < 0 and math.abs(cz - k[3]) < 10) or (k[1] ~= -74 and az >= 54 and (cz < 0) == (k[3] < 0) and cx > k[1] and cx < k[2])) then return false end
			end
			return bandA(cx, cy, cz) % 2 == 1 and math.noise((ax >= 74 and cz or cx) / 22, cy / 26, ax >= 74 and 5.3 or 2.1) > -0.45 -- the soft beds erode back, the hard beds stand out (Gemini v14p3_r2: no relief)
		end
		if cy >= 70 then -- the corbelled vault, its tiers stepping off toward the kiln (east) a little
			local t = math.floor((cy - 70) / 8) + 1
			local w = math.noise(cx / 30, cz / 30, t + 0.5) * 6
			return math.abs(cx - t * 6) < 74 - t * 13 + w and az < 54 - t * 11 + w
		end
		return false
	end
	local cell = {}
	for i = 0, NXc - 1 do for j = 0, NYc - 1 do for k = 0, NZc - 1 do
		cell[(i * NYc + j) * NZc + k] = open(X0 + VX * i + 2, Y0 + VX * j + 2, Z0 + VX * k + 2)
	end end end
	local function isOpen(i, j, k)
		if i < 0 or j < 0 or k < 0 or i >= NXc or j >= NYc or k >= NZc then return false end
		return cell[(i * NYc + j) * NZc + k]
	end
	local SB = { CLAY, Color3.fromRGB(176, 120, 72), Color3.fromRGB(150, 70, 50), CREAM:Lerp(CLAY, 0.45), Color3.fromRGB(86, 58, 80) } -- terracotta, ochre, red clay, cream, plum shale
	local function band(cx, cy, cz) return math.floor((cy + 0.24 * cx - 0.1 * cz + 5 * math.noise(cx / 40, cz / 40, 1.3)) / 10) % 5 + 1 end
	local ck = {}
	for i = 0, NXc - 1 do for j = 0, NYc - 1 do for k = 0, NZc - 1 do
		local cx, cy, cz = X0 + VX * i + 2, Y0 + VX * j + 2, Z0 + VX * k + 2
		if cy >= 0 and not isOpen(i, j, k) then
			local touch = false
			for dx = -1, 1 do for dy = -1, 1 do for dz = -1, 1 do if not touch and isOpen(i + dx, j + dy, k + dz) then touch = true end end end end
			if not touch and k == 0 and cy < 54 and ((cx > -8 and cx < 30) or (cx > 32 and cx < 76)) then touch = true end -- the back of the north wall, seen from the gallery rooms behind it
			if touch then ck[(i * NYc + j) * NZc + k] = isOpen(i, j - 1, k) and 10 + (cy >= 70 and 5 or band(cx, cy, cz)) or band(cx, cy, cz) end -- the vault's undersides share one shadowed shale tone, so they merge into big slabs (part budget)
		end
	end end end
	local used, nShell = {}, 0
	local function cid(i, j, k) return (i * NYc + j) * NZc + k end
	for j = 0, NYc - 1 do for i = 0, NXc - 1 do for k = 0, NZc - 1 do
		local kk = ck[cid(i, j, k)]
		if kk and not used[cid(i, j, k)] then
			local w, d, h = 1, 1, 1
			while i + w < NXc and ck[cid(i + w, j, k)] == kk and not used[cid(i + w, j, k)] and w < 10 do w += 1 end
			local ok = true
			while ok and k + d < NZc and d < 10 do
				for q = 0, w - 1 do local c2 = cid(i + q, j, k + d) if ck[c2] ~= kk or used[c2] then ok = false break end end
				if ok then d += 1 end
			end
			ok = true
			while ok and j + h < NYc and h < 8 do
				for q = 0, w - 1 do for r = 0, d - 1 do local c2 = cid(i + q, j + h, k + r) if ck[c2] ~= kk or used[c2] then ok = false end end end
				if ok then h += 1 end
			end
			for q = 0, w - 1 do for r = 0, d - 1 do for l = 0, h - 1 do used[cid(i + q, j + l, k + r)] = true end end end
			local col = SB[kk % 10]
			if kk >= 10 then col = col:Lerp(PLUM, 0.3) end -- the vault overhead sits in shadow
			part("CaveRock", Vector3.new(w * VX, h * VX, d * VX), O * CFrame.new(X0 + VX * (i + w / 2), Y0 + VX * (j + h / 2), Z0 + VX * (k + d / 2)), col, ROCK)
			nShell += 1
		end
	end end end
	folder:SetAttribute("ShellParts", nShell)
	for i, c in { { -60, -40 }, { -60, 40 }, { 60, -40 }, { 60, 40 }, { 0, -44 }, { 0, 44 } } do -- warm uplights grazing the vault tiers (Gemini v14p3_r2: a murky black crown)
		local up = part("VaultUplight", Vector3.new(0.4, 0.4, 0.4), O * CFrame.new(c[1], 56, c[2]), AMBER, { Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false })
		local sl = Instance.new("SpotLight")
		sl.Face, sl.Angle, sl.Range, sl.Brightness, sl.Color, sl.Shadows = Enum.NormalId.Top, 75, 40, 1.1, i % 2 == 0 and Color3.fromRGB(110, 214, 206) or Color3.fromRGB(255, 186, 120), false -- every other one cool teal (Gemini full1122f: "everything one ochre wash")
		sl.Parent = up
	end
	roofAt = function(x, z) -- the underside of the rock over a point of the floor
		local i, k = math.floor((x - X0) / VX), math.floor((z - Z0) / VX)
		for j = math.floor((70 - Y0) / VX), NYc - 1 do if not isOpen(i, j, k) then return Y0 + VX * j end end
		return 86
	end
	-- (the floor slabs went in directive v14: Gemini read the thin plates as debris glitches)

	-- dressing, so the hall reads as a dug and lived-in cavern and not a box (Gemini, 2026-11-10: flat walls, props not grounded):
	-- clay columns along both long walls with timber beams across the roof between them, a tiled path from the arrival ledge
	-- to the kiln, pot shelves on the south wall, roots hanging from the roof, rubble at the wall feet
	-- column places are picked by hand per wall, clear of the ore, fossils, echo walls, shelves, crystals and the Titan's hand
	for z, xs in { [-51] = { -66, -21, 1, 64.5 }, [51] = { -64, -38, -15, 32, 60 } } do
		for k, x in xs do
			local turn = CFrame.Angles(0, (k % 2) * 0.785 + 0.2, 0) -- directive v14: a flowstone buttress flared at floor and roof, not a plastered pillar
			part("Column", Vector3.new(5.2, 70.2, 5.2), O * CFrame.new(x, 34.9, z) * turn, k % 2 == 0 and CLAY or CLAY_D, ROCK)
			for q, e in { { 8.6, 1.4, 2.8 }, { 7, 4.2, 2.8 }, { 8.6, 68.6, 2.8 }, { 7, 65.8, 2.8 } } do
				part("ColumnFoot", Vector3.new(e[1], e[3], e[1]), O * CFrame.new(x, e[2], z) * turn * CFrame.Angles(0, q % 2 == 0 and 0.785 or 0, 0), (q % 2 == 0) and Color3.fromRGB(176, 120, 72) or CLAY_D, ROCK)
			end
		end
	end
	do -- directive v14: the vault's crown, a cluster of warm clay-glass crystals with a light, so the top of the vault is not a black hole
		local crown = roofAt(6, 0)
		for q = 0, 4 do
			local a = q * 1.26
			local cr = part("CrownCrystal", Vector3.new(1.6, 5 - q % 2 * 1.5, 1.6), O * CFrame.new(6 + math.cos(a) * 3, crown - 2.2, math.sin(a) * 3) * CFrame.Angles(math.pi + math.cos(a) * 0.4, a, math.sin(a) * 0.4), Color3.fromRGB(255, 170, 96), { Material = Enum.Material.Glass, Transparency = 0.2, CanCollide = false, CastShadow = false })
			if q == 0 then
				local l = Instance.new("PointLight")
				l.Color, l.Range, l.Brightness, l.Shadows = Color3.fromRGB(255, 176, 110), 40, 0.8, false
				l.Parent = cr
			end
		end
	end
	for k = 0, 11 do -- the path: worn cream tiles from the ledge toward the kiln ring
		part("PathTile", Vector3.new(3.4, 0.3, 3.4), O * CFrame.new(-55 + k * 4.2, 0.35, math.sin(k * 0.9) * 1.6) * CFrame.Angles(0, k * 0.4, 0), k % 3 == 0 and CREAM:Lerp(CLAY, 0.3) or CREAM:Lerp(CLAY, 0.55), { Material = Enum.Material.Sandstone, CanCollide = false })
	end
	for i, sx in { -52, 16 } do -- pot shelves against the south wall
		for lv = 0, 1 do
			part("Shelf", Vector3.new(10, 0.5, 2.2), O * CFrame.new(sx, 3 + lv * 3.2, 52.7), BARK, { Material = Enum.Material.Wood, CanCollide = false })
			for q = 0, 3 do
				local h = 1 + ((q + lv + i) % 3) * 0.4
				part("ShelfPot", Vector3.new(1.2, h, 1.2), O * CFrame.new(sx - 3.6 + q * 2.4, 3.25 + lv * 3.2 + h / 2, 52.7), (q + lv) % 2 == 0 and CLAY_L or CLAY, DECO)
			end
		end
		for _, dx in { -4.6, 4.6 } do part("ShelfPost", Vector3.new(0.5, 7.2, 0.5), O * CFrame.new(sx + dx, 3.6, 52.9), BARK, { Material = Enum.Material.Wood, CanCollide = false }) end
	end
	for k = 1, 12 do -- roots through the roof
		local len = rng:NextNumber(8, 22)
		local rx, rz = rng:NextNumber(-66, 66), rng:NextNumber(-44, 44)
		part("HangingRoot", Vector3.new(0.9, len, 0.9), O * CFrame.new(rx, roofAt(rx, rz) - len / 2 + 0.4, rz) * CFrame.Angles(rng:NextNumber(-0.08, 0.08), rng:NextNumber(0, 3), rng:NextNumber(-0.08, 0.08)), BARK:Lerp(PLUM, 0.3), { Material = Enum.Material.Wood, CanCollide = false, CastShadow = false })
	end
	for k = 1, 18 do -- rubble at the wall feet
		local side = k % 2 == 0 and 1 or -1
		local sz = rng:NextNumber(0.8, 2.2)
		part("Rubble", Vector3.new(sz, sz * 0.7, sz * 1.1), O * CFrame.new(rng:NextNumber(-70, 70), sz * 0.3, side * rng:NextNumber(46.5, 51.5)) * CFrame.Angles(rng:NextNumber(0, 1), rng:NextNumber(0, 3), rng:NextNumber(0, 1)), k % 3 == 0 and CLAY_L or CLAY_D, { Material = Enum.Material.Sandstone, CanCollide = false })
	end
	-- the arrival ledge (west): a root arch with the way back to Camp 1
	local arrive = O * CFrame.new(-64, 0, 0)
	part("Ledge", Vector3.new(14, 1.2, 18), arrive * CFrame.new(0, 0.6, 0), CLAY_L, ROCK)
	for _, z in { -5, 5 } do part("ArchRoot", Vector3.new(2, 12, 2), arrive * CFrame.new(-5.2, 7.2, z), BARK, { Material = Enum.Material.Wood }) end
	part("ArchRoot", Vector3.new(2, 2, 13), arrive * CFrame.new(-5.2, 13.4, 0), BARK, { Material = Enum.Material.Wood })
	local back = part("ArchDark", Vector3.new(0.6, 11, 8), arrive * CFrame.new(-5.6, 6.7, 0), Color3.fromRGB(14, 8, 22))
	prompt(back, "Climb back", "Camp 1", "ClayPortal", 1, 10)
	if C.CAVE_V2_L2 then back.CanCollide, back.Transparency = false, 0.7 end -- the arch is a real way out now: the west gallery of Cave v2 layer 2 lies behind it
	local land = part("ClayLanding", Vector3.new(4, 1, 4), arrive * CFrame.new(1, 1.7, 0) * CFrame.Angles(0, -math.pi / 2, 0), CLAY, -- faces east into the hall: the lift set riders down facing the crew cart's tool rack (Gemini full1121c)
		 { Transparency = 1, CanCollide = false, CanQuery = false })
	land.Parent = folder
	lamp(Vector3.new(-60, 16, 0), 0.7)
	do -- directive v13 (Group Cart Escape: CREW RIDE at the deeper camps): a parked crew cart on a rail stub by the ledge; the
		-- server puts a CREW RIDE sign and V prompt over "KilnCartBody" (PixelServer) that boards the same crew as Camp 1's cart
		local cart = arrive * CFrame.new(3.6, 1.2, -5.6)
		local IRONC, OAKC = Color3.fromRGB(62, 56, 78), Color3.fromRGB(128, 86, 54)
		for _, x in { -0.9, 0.9 } do part("KilnRail", Vector3.new(0.25, 0.2, 7.5), cart * CFrame.new(x, 0.1, 0), IRONC, { Material = Enum.Material.Metal, CanCollide = false }) end
		for z = -3, 3, 1.5 do part("KilnSleeper", Vector3.new(2.8, 0.14, 0.6), cart * CFrame.new(0, 0.03, z), BARK, { Material = Enum.Material.Wood, CanCollide = false }) end
		for _, w in { { -1.2, -1.1 }, { 1.2, -1.1 }, { -1.2, 1.1 }, { 1.2, 1.1 } } do
			part("KilnWheel", Vector3.new(0.3, 0.9, 0.9), cart * CFrame.new(w[1], 0.62, w[2]), IRONC, { Shape = Enum.PartType.Cylinder, Material = Enum.Material.Metal, CanCollide = false })
		end
		part("KilnCartBody", Vector3.new(3, 1.8, 3.6), cart * CFrame.new(0, 1.97, 0), OAKC, { Material = Enum.Material.WoodPlanks })
		part("KilnCartRim", Vector3.new(3.2, 0.25, 3.8), cart * CFrame.new(0, 2.93, 0), IRONC, { Material = Enum.Material.Metal, CanCollide = false })
		part("KilnCartOre", Vector3.new(2.2, 0.5, 2.6), cart * CFrame.new(0, 2.9, 0), CLAY_L, { CanCollide = false })
		-- a siding, not a stray rail (Gemini v13 round 4): striped buffer stops at both ends, an ore bin and a tool rack beside it
		for _, z in { -3.9, 3.9 } do
			part("KilnBuffer", Vector3.new(2.6, 0.9, 0.5), cart * CFrame.new(0, 0.75, z), BARK, { Material = Enum.Material.Wood })
			for k = -1, 1 do part("KilnBufferStripe", Vector3.new(0.42, 0.92, 0.52), cart * CFrame.new(k * 0.85, 0.75, z) * CFrame.Angles(0, 0, 0.5), Color3.fromRGB(255, 200, 60), { CanCollide = false, CastShadow = false }) end
		end
		local bin = cart * CFrame.new(-2.9, 0, 1.6)
		part("KilnOreBin", Vector3.new(1.8, 1.2, 1.6), bin * CFrame.new(0, 0.6, 0), OAKC, { Material = Enum.Material.WoodPlanks })
		for k = 0, 4 do part("KilnBinOre", Vector3.new(0.55, 0.45, 0.5), bin * CFrame.new(-0.5 + (k % 3) * 0.5, 1.32 + (k > 2 and 0.2 or 0), -0.3 + math.floor(k / 3) * 0.5) * CFrame.Angles(0, k, 0.3), k % 2 == 0 and Color3.fromRGB(196, 120, 80) or Color3.fromRGB(240, 200, 120), { CanCollide = false }) end
		local rack = cart * CFrame.new(-2.7, 0, -2.2)
		for _, x in { -0.8, 0.8 } do part("KilnRackPost", Vector3.new(0.25, 2.4, 0.25), rack * CFrame.new(x, 1.2, 0), BARK, { Material = Enum.Material.Wood }) end
		part("KilnRackBar", Vector3.new(1.9, 0.2, 0.25), rack * CFrame.new(0, 2.2, 0), BARK, { Material = Enum.Material.Wood, CanCollide = false })
		part("KilnToolHandle", Vector3.new(0.15, 1.6, 0.15), rack * CFrame.new(-0.35, 1.45, 0.2) * CFrame.Angles(0, 0, 0.12), Color3.fromRGB(150, 104, 64), { CanCollide = false })
		part("KilnToolHead", Vector3.new(0.9, 0.18, 0.2), rack * CFrame.new(-0.25, 2.2, 0.22) * CFrame.Angles(0, 0, 0.12), IRONC, { Material = Enum.Material.Metal, CanCollide = false })
		part("KilnShovel", Vector3.new(0.15, 1.5, 0.15), rack * CFrame.new(0.4, 1.4, 0.2) * CFrame.Angles(0, 0, -0.1), Color3.fromRGB(150, 104, 64), { CanCollide = false })
		part("KilnShovelBlade", Vector3.new(0.5, 0.6, 0.08), rack * CFrame.new(0.46, 0.55, 0.22), IRONC, { Material = Enum.Material.Metal, CanCollide = false })
	end

	-- the kiln camp (centre): the kiln, the Kiln Keeper's stall, a ring of butter tiles marking the safe ground
	for k = 0, 23 do
		local a = k / 24 * math.pi * 2
		part("RingTile", Vector3.new(3.4, 0.3, 1.4), O * CFrame.new(math.cos(a) * (C.CAMP_RING - 2), 0.75, math.sin(a) * (C.CAMP_RING - 2)) * CFrame.Angles(0, -a + math.pi / 2, 0), k % 2 == 0 and CREAM or AMBER, { CanCollide = false, CastShadow = false })
	end
	local kiln = O * CFrame.new(6, 0, -12)
	for i, s in { { 13, 4, 0 }, { 11.4, 4, 4 }, { 9, 3.4, 7.7 }, { 5.6, 2.6, 10.7 } } do -- a stepped beehive kiln
		part("Kiln", Vector3.new(s[1], s[2], s[1]), kiln * CFrame.new(0, s[3] + s[2] / 2, 0), i % 2 == 0 and CLAY_L or CLAY, ROCK)
	end
	part("KilnSkirt", Vector3.new(16.4, 0.7, 16.4), kiln * CFrame.new(0, 0.3, 0), CLAY_D, ROCK)
	for k = 1, 9 do -- broken clay round the kiln's foot, so it sits in the floor instead of on it
		local a = k * 0.7
		part("KilnShard", Vector3.new(0.8 + (k % 3) * 0.5, 0.5 + (k % 2) * 0.4, 0.9), kiln * CFrame.new(math.cos(a) * (9.4 + k % 3), 0.2, math.sin(a) * (9.4 + k % 2)) * CFrame.Angles(0.2 * k, a, 0.3), k % 2 == 0 and CLAY_L or CLAY_D, DECO)
	end
	part("KilnChimney", Vector3.new(2.4, 5, 2.4), kiln * CFrame.new(0, 15.8, 0), CLAY_D, ROCK)
	local mouth = part("KilnMouth", Vector3.new(4.4, 3, 0.3), kiln * CFrame.new(0, 1.7, 4.7), Color3.fromRGB(150, 56, 22), { Material = Enum.Material.Neon, CanCollide = false, CastShadow = false }) -- the glow sits deep in the throat, coals in front of it
	local ml = Instance.new("PointLight")
	ml.Color, ml.Range, ml.Brightness, ml.Shadows = Color3.fromRGB(255, 130, 50), 26, 0.5, false
	ml.Parent = mouth
	ml:SetAttribute("Fixture", true)
	part("KilnThroat", Vector3.new(3.6, 2.4, 1.4), kiln * CFrame.new(0, 1.5, 5.5), Color3.fromRGB(30, 14, 16), { CanCollide = false })
	for k = -1, 1 do
		local coal = part("KilnCoal", Vector3.new(0.9, 0.6, 0.7), kiln * CFrame.new(k * 1.1, 1.0 + (k % 2) * 0.07, 6.9) * CFrame.Angles(0, k * 0.5, 0.2 * k), Color3.fromRGB(255, 140, 50), { Material = Enum.Material.Neon, CanCollide = false, CastShadow = false })
		if k == 0 then -- chunky pixel flames licking out of the kiln mouth (Shared.PixelFire, as Camp 1's camp fire)
			local okPF, PF = pcall(require, game:GetService("ReplicatedStorage"):WaitForChild("Shared"):FindFirstChild("PixelFire"))
			if okPF then PF.attach(coal, Color3.fromRGB(255, 190, 90), Color3.fromRGB(240, 80, 30), 2) end
		end
	end
	local embers = Instance.new("ParticleEmitter")
	embers.Rate, embers.Lifetime, embers.Speed, embers.SpreadAngle = 7, NumberRange.new(1.2, 2.2), NumberRange.new(2, 4), Vector2.new(25, 25)
	embers.Size, embers.Color, embers.LightEmission = NumberSequence.new(0.22, 0), ColorSequence.new(Color3.fromRGB(255, 170, 70)), 0.8
	embers.Acceleration, embers.EmissionDirection = Vector3.new(0, 3, 0), Enum.NormalId.Top
	embers.Parent = mouth
	part("KilnArch", Vector3.new(6.2, 1.2, 1), kiln * CFrame.new(0, 3.8, 6.4), CLAY_D, ROCK)
	for _, x in { -2.7, 2.7 } do part("KilnArch", Vector3.new(0.9, 3.4, 1), kiln * CFrame.new(x, 1.5, 6.4), CLAY_D, ROCK) end -- sunk 0.2 into the floor: its foot was level with the kiln's
	-- the stall: a counter, an awning on four posts, pots on the counter, and the Kiln Keeper (a mole potter) behind it
	local stall = O * CFrame.new(-10, 0, -10) * CFrame.Angles(0, 0.5, 0)
	part("StallMat", Vector3.new(11, 0.3, 7.4), stall * CFrame.new(0, 0.84, -0.6), PLUM:Lerp(CLAY, 0.4), { CanCollide = false })
	part("Counter", Vector3.new(8, 2.6, 2.4), stall * CFrame.new(0, 2.05, 0), BARK, { Material = Enum.Material.Wood })
	part("CounterTop", Vector3.new(8.6, 0.4, 3), stall * CFrame.new(0, 3.55, 0), Color3.fromRGB(176, 150, 124), { Material = Enum.Material.Sandstone })
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
	-- the Keeper is also the caves' trader (roadmap pt2_21, the user 2026-11-09: rooms where eggs can be bought, some free):
	-- an egg in a clay pot on the counter, for coins (ClayCaves.init)
	local pot = part("EggPot", Vector3.new(1.5, 1.1, 1.5), stall * CFrame.new(3.2, 4.3, 0.2), CLAY_D, { CanCollide = false })
	part("EggPotEgg", Vector3.new(1, 1.3, 1), stall * CFrame.new(3.2, 5.2, 0.2), CREAM, DECO)
	part("EggPotSpot", Vector3.new(0.5, 0.3, 0.2), stall * CFrame.new(3.2, 5.3, 0.72), AMBER, DECO)
	local buy = prompt(pot, "Buy egg", K.eggCost .. " coins", "ClayEgg", true, 9)
	buy.KeyboardKeyCode = Enum.KeyCode.E
	lamp(Vector3.new(-2, 22, 6), 0.7)
	for _, x in { -42, -12, 18 } do for _, z in { -34, 34 } do lamp(Vector3.new(x, 26, z), 1.0) end end -- two rows of lamps down the hall: without them it was a dark red box

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
		l.Name, l.Color, l.Range, l.Brightness, l.Shadows = "Glint", ore[2], 9, 0.6, false
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
		lamp(Vector3.new(m[1] - 26, top + 6, m[2]), 0.35) -- 15 studs clear of the mesa wall: 1 stud from it, it burned the rock white
	end
	-- violet crystal clusters at the wall feet: the cool colour the warm clay needs (deep violet shadows, the user's directive)
	local VIOLET = Color3.fromRGB(150, 110, 255)
	for i, c in { { -56, -51 }, { -24, 51 }, { 30, -51 }, { 38, 51 }, { 71, 20 }, { 71, -44 }, { -71, -22 }, { 40, -51 } } do
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
	-- the Titan's hand (Camp 2 brief: "a terracotta cavern where a sleeping stone Titan's hand rests"): a giant grey stone hand
	-- lying palm up against the north wall, fingers curled, moss in its creases. It is the hall's landmark; you can climb it.
	do
		local STONE, STONE_D, MOSS = Color3.fromRGB(122, 112, 142), Color3.fromRGB(92, 84, 112), Color3.fromRGB(96, 150, 104)
		local H = O * CFrame.new(30, 0, -40) * CFrame.Angles(0, -0.25, 0)
		local SL = { Material = Enum.Material.Slate }
		part("TitanPalm", Vector3.new(16, 4.4, 13), H * CFrame.new(0, 2.2, 0), STONE, SL)
		part("TitanWrist", Vector3.new(11, 5.4, 9), H * CFrame.new(0, 2.7, -10.4), STONE_D, SL)
		part("TitanMoss", Vector3.new(9, 0.5, 6), H * CFrame.new(-1, 4.6, -1.4), MOSS, { Material = Enum.Material.Grass, CanCollide = false })
		for k = 0, 3 do -- four fingers: a knuckle lying on the floor, then a tip curling up
			local x = -6 + k * 4
			local len = k == 1 and 8.5 or (k == 3 and 6 or 7.5)
			part("TitanFinger", Vector3.new(3.3, 3.6, len), H * CFrame.new(x, 1.8, 6.5 + len / 2), k % 2 == 0 and STONE or STONE_D, SL)
			part("TitanFingerTip", Vector3.new(3.1, 3.2, 5.4), H * CFrame.new(x, 4.4, 6.5 + len + 1.2) * CFrame.Angles(-0.85, 0, 0), k % 2 == 0 and STONE_D or STONE, SL)
			part("TitanNail", Vector3.new(2.3, 0.4, 2.2), H * CFrame.new(x, 6.9, 6.5 + len + 2.9) * CFrame.Angles(-0.85, 0, 0), Color3.fromRGB(176, 166, 196), { CanCollide = false, CastShadow = false })
		end
		part("TitanThumb", Vector3.new(7.5, 3.4, 3.6), H * CFrame.new(-11.2, 1.7, 1) * CFrame.Angles(0, 0.5, 0), STONE_D, SL)
		part("TitanThumbTip", Vector3.new(4.6, 3, 3.2), H * CFrame.new(-15.2, 3.6, 3.6) * CFrame.Angles(0, 0.5, 0.7), STONE, SL)
		for i, r in { { -5, 4.9, 3 }, { 4, 4.9, -3 }, { 0, 4.9, 4.5 } } do -- runes cut in the palm, faintly lit
			part("TitanRune", Vector3.new(1.6, 0.2, 0.5), H * CFrame.new(r[1], r[2] - 0.38, r[3]) * CFrame.Angles(0, i * 1.1, 0), Color3.fromRGB(120, 200, 190), { Material = Enum.Material.Neon, CanCollide = false, CastShadow = false })
		end
	end
	-- spore bounce pads (the directive's cave traversal): three spongy teal caps that throw you up a step each, to a ledge on the
	-- north wall with a jar-sized reward of ore. Shared.ClayClient does the bounce.
	local TEAL = Color3.fromRGB(72, 200, 186)
	-- directive v13 (Gemini: bright neon slabs pulled the eye): a bounce pad is a glowing amber spore-cap mushroom in a wet stone
	-- collar: a cream stem, a domed amber cap (two stacked discs) with a softly lit underside of gills and cream spots on top.
	-- The part named BouncePad keeps its size and attribute (Shared.ClayClient reads them); it is the cap's lower disc.
	function mushroomPad(x, y, z, power)
		local UPc = CFrame.Angles(0, 0, math.pi / 2)
		for k = 0, 9 do -- the wet stone collar round the stem's foot
			local a = k / 10 * math.pi * 2
			local st = part("PadCollar", Vector3.new(0.9, 0.55, 0.9), O * CFrame.new(x + math.cos(a) * 1.55, y + 0.2, z + math.sin(a) * 1.55) * CFrame.Angles(0, a, 0.1), Color3.fromRGB(70, 74, 84), { Material = Enum.Material.Slate, CanCollide = false, Shape = Enum.PartType.Ball })
			st.Reflectance = 0.05
		end
		part("PadStem", Vector3.new(1.4, 1.5, 1.5), O * CFrame.new(x, y + 0.72, z) * UPc, CREAM, { CanCollide = false, Shape = Enum.PartType.Cylinder })
		local cap = part("BouncePad", Vector3.new(5.4, 1.1, 5.4), O * CFrame.new(x, y + 1.95, z), Color3.fromRGB(226, 140, 52), { Material = Enum.Material.SmoothPlastic, CanCollide = false, Transparency = 1 }) -- the pad's box: invisible, the mushroom draws it
		cap:SetAttribute("BouncePad", power)
		part("PadCap", Vector3.new(0.7, 5.2, 5.2), O * CFrame.new(x, y + 1.85, z) * UPc, Color3.fromRGB(214, 128, 46), { CanCollide = false, Shape = Enum.PartType.Cylinder })
		-- a fleshy domed cap (an ellipsoid sphere mesh) over the rim disc, with spore motes drifting up off it (Gemini v13 round 1:
		-- the stacked discs read as a plastic button)
		local dome = part("PadDome", Vector3.new(4.8, 2.2, 4.8), O * CFrame.new(x, y + 2.1, z), Color3.fromRGB(236, 158, 64), { CanCollide = false })
		local dm = Instance.new("SpecialMesh")
		dm.MeshType = Enum.MeshType.Sphere
		dm.Parent = dome
		local motes = Instance.new("ParticleEmitter")
		motes.Texture, motes.Rate, motes.Lifetime, motes.Speed, motes.SpreadAngle = "rbxasset://textures/particles/sparkles_main.dds", 2.5, NumberRange.new(3, 5), NumberRange.new(0.4, 1), Vector2.new(50, 50)
		motes.Color, motes.LightEmission, motes.Acceleration = ColorSequence.new(Color3.fromRGB(255, 226, 160)), 1, Vector3.new(0, 0.25, 0)
		motes.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.18), NumberSequenceKeypoint.new(1, 0.05) })
		motes.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.2, 0.3), NumberSequenceKeypoint.new(1, 1) })
		motes.Parent = dome
		local gills = part("PadGills", Vector3.new(0.16, 4.6, 4.6), O * CFrame.new(x, y + 1.42, z) * UPc, Color3.fromRGB(255, 196, 110), { Material = Enum.Material.Neon, CanCollide = false, Transparency = 0.35, Shape = Enum.PartType.Cylinder })
		local l = Instance.new("PointLight")
		l.Color, l.Range, l.Brightness, l.Shadows = Color3.fromRGB(255, 180, 90), 12, 0.7, false
		l.Parent = gills
		for k = 0, 4 do -- cream spots on the dome
			local a = k / 5 * math.pi * 2 + 0.4
			part("PadSpot", Vector3.new(0.6, 0.6, 0.6), O * CFrame.new(x + math.cos(a) * 1.3, y + 3.0, z + math.sin(a) * 1.3), CREAM, { CanCollide = false, Shape = Enum.PartType.Ball }) -- a cream bump half sunk in the dome
		end
	end
	part("PadLedge", Vector3.new(26, 2, 10), O * CFrame.new(-34, 21, -49.5), CLAY_L, ROCK)
	for i, pd in { { -62, 0, -44, 100 }, { -54, 9, -47, 95 } } do
		if pd[2] > 0 then part("PadStep", Vector3.new(8, pd[2], 8), O * CFrame.new(pd[1], pd[2] / 2, pd[3]), CLAY, ROCK) end
		mushroomPad(pd[1], pd[2], pd[3], pd[4])
	end
	deposit(O * CFrame.new(-30, 22, -51.4), 3)
	-- the zip line (roadmap i25, traversal): from the pad ledge down across the hall to a post by the path. The server only
	-- checks the prompt; Shared.ClayClient carries the rider (Fx "zip"). The rope's ends are its attributes ZipA and ZipB.
	do
		local a, b = (O * CFrame.new(-40, 28.6, -46)).Position, (O * CFrame.new(-30, 7.6, 10)).Position
		part("ZipPost", Vector3.new(0.9, 7.2, 0.9), O * CFrame.new(-40, 25.6, -46.6), BARK, { Material = Enum.Material.Wood })
		part("ZipPost", Vector3.new(0.9, 7.7, 0.9), O * CFrame.new(-30, 4.35, 10.6), BARK, { Material = Enum.Material.Wood })
		part("ZipFoot", Vector3.new(2.2, 0.5, 2.2), O * CFrame.new(-30, 0.25, 10.6), CLAY_D, { Material = Enum.Material.Sandstone })
		local rope = part("ZipRope", Vector3.new(0.24, 0.24, (b - a).Magnitude), CFrame.lookAt((a + b) / 2, b), CREAM:Lerp(BARK, 0.35), DECO)
		rope:SetAttribute("ZipA", a)
		rope:SetAttribute("ZipB", b)
		local handle = part("ZipHandle", Vector3.new(1.5, 0.3, 0.3), CFrame.new(a + (b - a).Unit * 1.6 - Vector3.new(0, 0.9, 0)), AMBER, { CanCollide = false, Material = Enum.Material.Wood })
		prompt(handle, "Ride", "Zip line", "ZipLine", 1, 10)
		for k = 0, 2 do part("ZipFlag", Vector3.new(0.1, 0.9, 0.7), CFrame.new(a + (b - a) * (0.25 + k * 0.25) - Vector3.new(0, 0.6, 0)), k % 2 == 0 and AMBER or CREAM, DECO) end -- little flags along the rope: it reads from the floor
	end
	-- the lost critter (pt2_21): a small cage at the end of the pad ledge. Free it once, ever: it leaves an egg behind.
	do
		local cage = Instance.new("Model")
		cage.Name = "CritterCage"
		local cf = O * CFrame.new(-24, 22, -48)
		local function cp(name, size, c, color, props)
			local p = part(name, size, cf * c, color, props)
			p.Parent = cage
			return p
		end
		local floor = cp("CageFloor", Vector3.new(3.2, 0.3, 3.2), CFrame.new(0, 0.15, 0), BARK)
		cp("CageTop", Vector3.new(3.2, 0.3, 3.2), CFrame.new(0, 3.05, 0), BARK)
		for k = 0, 7 do
			local a = k / 8 * math.pi * 2
			cp("CageBar", Vector3.new(0.2, 2.6, 0.2), CFrame.new(math.cos(a) * 1.4, 1.6, math.sin(a) * 1.4), PLUM, { CanCollide = false })
		end
		local PINK = Color3.fromRGB(255, 170, 190)
		cp("Critter", Vector3.new(1.2, 1.1, 1.2), CFrame.new(0, 0.85, 0), PINK, DECO)
		cp("Critter", Vector3.new(0.34, 0.5, 0.3), CFrame.new(-0.36, 1.6, 0), PINK, DECO)
		cp("Critter", Vector3.new(0.34, 0.5, 0.3), CFrame.new(0.36, 1.6, 0), PINK, DECO)
		for _, x in { -0.28, 0.28 } do cp("Critter", Vector3.new(0.2, 0.24, 0.08), CFrame.new(x, 0.95, 0.62), Color3.fromRGB(26, 18, 34), DECO) end
		cage.PrimaryPart = floor
		cage.Parent = folder
		local hold = Instance.new("Attachment")
		hold.Position = Vector3.new(0, 2.2, 0)
		hold.Parent = floor
		local pr = prompt(floor, "Free", "Lost critter", "Critter", 1, 8)
		pr.Parent = hold
	end
	deposit(O * CFrame.new(-40, 22, -51.4), 2)
	-- pale shafts of light through cracks in the roof (the directive's root god-rays): see-through slanted beams, no collision
	for i, r in { { -30, 10 }, { 8, -30 }, { 30, 28 }, { -8, 40 } } do
		local mid = O * CFrame.new(r[1], 34, r[2]) * CFrame.Angles(0, i * 0.9, 0) * CFrame.Angles(0, 0, 0.16) -- a soft camera-facing Beam shaft, as Camp 1's (2026-11-20)
		local anchor = part("GodRay", Vector3.new(0.2, 0.2, 0.2), mid * CFrame.new(0, 38, 0), Color3.fromRGB(150, 210, 190), { Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false })
		local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
		a0.Parent, a1.Parent = anchor, anchor
		a1.WorldPosition = (mid * CFrame.new(0, -38, 0)).Position
		local bm = Instance.new("Beam")
		bm.Attachment0, bm.Attachment1, bm.FaceCamera, bm.Segments = a0, a1, true, 1
		bm.Width0, bm.Width1, bm.Color, bm.LightEmission, bm.LightInfluence = 2.5 + i * 0.4, 5 + i * 0.6, ColorSequence.new(Color3.fromRGB(150, 210, 190)), 0.7, 0
		bm.Texture, bm.TextureMode, bm.TextureLength, bm.TextureSpeed = "rbxasset://textures/particles/smoke_main.dds", Enum.TextureMode.Stretch, 1, 0.02
		bm.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.2, 0.86), NumberSequenceKeypoint.new(0.75, 0.9), NumberSequenceKeypoint.new(1, 1) })
		bm.Parent = anchor
	end
	-- common ore along the walls
	for i, d in { { -40, -52.2, 0 }, { -12, -52.2, 0 }, { 22, -52.2, 0 }, { -44, 52.2, math.pi }, { -8, 52.2, math.pi }, { 26, 52.2, math.pi }, { 72.2, 44, -math.pi / 2 }, { -72.2, 30, math.pi / 2 } } do
		deposit(O * CFrame.new(d[1], 0.1, d[2]) * CFrame.Angles(0, d[3], 0), i % 3 == 0 and 2 or 1)
	end

	-- the Kiln Golem (boss 2; ServerScriptService.Boss runs the fight, Shared.BossClient shows it): a squat fired-clay golem asleep
	-- between the mesas, three glowing kiln vents on its chest. It needs the Titan Hammer (C.BOSS2).
	do
		local g = Instance.new("Model")
		g.Name = "KilnGolem"
		local base = O * CFrame.new(64, 0, 0) * CFrame.Angles(0, math.pi / 2, 0)
		local function gp(name, size, cf, color, props)
			local p = part(name, size, base * cf, color, props)
			p.Parent = g
			return p
		end
		local body = gp("GolemBody", Vector3.new(8, 6, 5.6), CFrame.new(0, 3.9, 0), CLAY)
		gp("GolemBand", Vector3.new(8.4, 1, 6), CFrame.new(0, 2.2, 0), CREAM)
		gp("GolemHead", Vector3.new(4.6, 3.6, 4), CFrame.new(0, 8.6, -1), CLAY_L)
		gp("GolemLid", Vector3.new(5, 0.8, 4.4), CFrame.new(0, 10.8, -1), CLAY_D)
		gp("GolemChimney", Vector3.new(1.6, 2, 1.6), CFrame.new(0, 12.2, -1), CLAY_D)
		for _, x in { -1, 1 } do
			gp("WardenEye", Vector3.new(0.9, 0.25, 0.1), CFrame.new(x, 9, -3.04), Color3.fromRGB(40, 28, 46), DECO)
			gp("GolemArm", Vector3.new(2.2, 5.6, 2.2), CFrame.new(x * 5.2, 3.6, -0.6) * CFrame.Angles(0, 0, x * 0.16), CLAY_D)
			gp("GolemFist", Vector3.new(3, 2.2, 3), CFrame.new(x * 5.7, 1.1, -1.2), CLAY_L)
			gp("GolemLeg", Vector3.new(2.6, 1.8, 2.8), CFrame.new(x * 2.3, 0.9, 0.6), CLAY_D)
		end
		for k, at in { { -2.3, 6.6 }, { 2.3, 5.6 }, { 0, 4.5 } } do -- directive v13: shoulders and chest (they sat by its knees)
			local km = Instance.new("Model")
			km.Name = "Knot" .. k
			local kn = part("KnotCore", Vector3.new(1.5, 1.5, 1.5), base * CFrame.new(at[1], at[2], -2.9), Color3.fromRGB(255, 130, 50), { Material = Enum.Material.Neon, Shape = Enum.PartType.Ball, CanCollide = false, CastShadow = false })
			kn.Parent = km
			km.PrimaryPart = kn
			km:SetAttribute("Layer", 2)
			km:SetAttribute("Ore", 3)
			km:SetAttribute("OreName", "Kiln Vent")
			km.Parent = g
			local l = Instance.new("PointLight")
			l.Color, l.Range, l.Brightness, l.Shadows = Color3.fromRGB(255, 130, 50), 8, 0.5, false
			l.Parent = kn
		end
		g.PrimaryPart = body
		g.Parent = folder
		prompt(body, "Challenge", "Kiln Golem", "BossGate", 2, 14)
	end
	-- clay jars: a body, a neck and a rim; the prompt sits on the body. Shared for everyone; the server pays per player.
	-- four in the hall, four in the Jar Gallery on its floor and its three stone steps (x, z, height of the ground there)
	for i, at in { { -30, 18 }, { -26, 22 }, { 20, 16 }, { 34, -4 }, { 14, -70 }, { 0, -74, 4 }, { 0, -96, 8 }, { 22, -98, 12 } } do
		local s = 0.9 + (i % 3) * 0.25
		local cf = O * CFrame.new(at[1], (at[3] or 0) - 0.05, at[2]) * CFrame.Angles(0, i, 0)
		local jar = Instance.new("Model")
		jar.Name = "ClayJar"
		local function jp(name, size, c, col)
			local p = part(name, size * s, cf * (c.Rotation + c.Position * s), col, { CanCollide = name == "JarBody" })
			p.Parent = jar
			return p
		end
		-- directive v13 (MET amphora DT374582): a tapered amphora, not a cube stack: a narrow foot, a swelling belly, a sloped
		-- shoulder, a slim neck and a flared lip ring, each a vertical cylinder (about 300 triangles in all)
		local UP = CFrame.Angles(0, 0, math.pi / 2)
		local body = i % 2 == 0 and CLAY_L or CLAY
		local function ring(name, d, h, y, col)
			local p = jp(name, Vector3.new(h, d, d), CFrame.new(0, y, 0) * UP, col)
			p.Shape = Enum.PartType.Cylinder
			return p
		end
		ring("JarFoot", 1.05, 0.34, 0.17, CLAY_D)
		ring("JarBase", 1.55, 0.36, 0.5, body)
		local b = ring("JarBody", 2.3, 0.95, 1.12, body) -- the belly (the part that collides and that the smash code finds)
		ring("JarBand", 2.36, 0.22, 1.25, CREAM:Lerp(CLAY_D, 0.55)) -- a painted band, not a bright stripe (Gemini v13 round 3: it read as a glowing ring)
		ring("JarShoulder", 1.85, 0.42, 1.78, body)
		ring("JarShoulder2", 1.3, 0.3, 2.13, CLAY_D)
		ring("JarNeck", 0.95, 0.62, 2.58, CLAY_D)
		ring("JarRim", 1.45, 0.22, 3.0, CLAY_L)
		for _, sx in { -1, 1 } do -- twin loop handles from the neck down to the shoulder (MET #17; Gemini v13 round 1)
			jp("JarHandle", Vector3.new(0.5, 0.16, 0.22), CFrame.new(sx * 0.66, 2.78, 0), CLAY_D)
			jp("JarHandle", Vector3.new(0.16, 0.85, 0.22), CFrame.new(sx * 0.92, 2.42, 0) * CFrame.Angles(0, 0, sx * 0.12), CLAY_D)
			jp("JarHandle", Vector3.new(0.34, 0.16, 0.22), CFrame.new(sx * 0.82, 2.02, 0), CLAY_D)
		end
		jar.PrimaryPart = b
		jar:SetAttribute("Jar", i)
		jar.Parent = folder
		do -- stand it on the real floor: some sat half a stud over the uneven clay (Gemini full1119b, 581 s)
			local rp = RaycastParams.new()
			rp.FilterType, rp.FilterDescendantsInstances = Enum.RaycastFilterType.Exclude, { jar }
			local foot = b.Position - Vector3.new(0, b.Size.Y / 2, 0)
			local hit = workspace:Raycast(foot + Vector3.new(0, 2, 0), Vector3.new(0, -5, 0), rp)
			if hit then jar:PivotTo(jar:GetPivot() + Vector3.new(0, hit.Position.Y - foot.Y - 0.02, 0)) end
		end
		jars[i] = prompt(b, "Smash", "Clay jar", "ClayJar", i, 7)
	end
	-- fossil spots: a slab of pale clay on the wall with the amber shape showing faintly through
	-- all three are on the walls of the Fossil Dig since 2026-11-13 (x, z, turn, height of the ground there)
	for i, f in { { 34.6, -72, math.pi / 2, 0 }, { 73.4, -84, -math.pi / 2, 1.4 }, { 42, -109.4, 0, 2.8 } } do
		local cf = O * CFrame.new(f[1], 4.5 + f[4], f[2]) * CFrame.Angles(0, f[3], 0)
		local slab = part("FossilSlab", Vector3.new(7, 6, 0.9), cf, CREAM:Lerp(CLAY_L, 0.45), ROCK)
		for k = 0, 4 do -- a curled amber shape, sunk 0.06 proud of the slab
			local a = k * 1.1
			part("FossilHint", Vector3.new(1.1 - k * 0.12, 1.1 - k * 0.12, 0.2), cf * CFrame.new(math.cos(a) * (1.6 - k * 0.28), math.sin(a) * (1.6 - k * 0.28), 0.42), AMBER:Lerp(CLAY, 0.45), { CanCollide = false, CastShadow = false })
		end
		slab:SetAttribute("Fossil", i)
		fossils[i] = prompt(slab, "Brush", "Old fossil", "Fossil", i, 9)
	end
	-- the geode anvil by the kiln (roadmap i31, the Geode Lock minigame): a stone block with a cradle and a sample geode.
	-- Geodes come from clay jars and Echo Tap wins; crack one here by repeating the order its facets light up in.
	do
		local at = O * CFrame.new(17, 0, 1) * CFrame.Angles(0, -0.6, 0)
		local block = part("GeodeAnvil", Vector3.new(4.4, 2.6, 3.4), at * CFrame.new(0, 1.3, 0), Color3.fromRGB(92, 84, 112), { Material = Enum.Material.Slate })
		part("GeodeCradle", Vector3.new(2.6, 0.5, 2.6), at * CFrame.new(0, 2.85, 0), CLAY_D, { CanCollide = false })
		part("GeodeShell", Vector3.new(1.9, 1.5, 1.9), at * CFrame.new(0, 3.8, 0), Color3.fromRGB(120, 112, 128), { Shape = Enum.PartType.Ball, CanCollide = false })
		part("GeodeHeart", Vector3.new(1.1, 0.9, 0.5), at * CFrame.new(0, 3.85, 0.72), Color3.fromRGB(150, 110, 255):Lerp(Color3.new(0, 0, 0), 0.25), { Material = Enum.Material.Neon, CanCollide = false, CastShadow = false })
		local hold = Instance.new("Attachment")
		hold.Position = Vector3.new(0, 2.6, 0)
		hold.Parent = block
		local pr = prompt(block, "Crack", "Geode", "GeodeAnvil", true, 9)
		pr.Parent = hold
	end
	-- Crystal Resonance Chimes (directive v10): three tall crystals on stone feet in a row on the hall floor, five studs apart
	-- so each has its own prompt. The crystals lean a little, so no face shares a plane with its foot.
	for k, d in { { 12, Color3.fromRGB(0, 240, 255), 2.8 }, { 17, Color3.fromRGB(255, 0, 127), 3.6 }, { 22, Color3.fromRGB(155, 31, 232), 3.2 } } do
		local at = O * CFrame.new(d[1], 0, 12)
		part("ChimeFoot", Vector3.new(2.2, 0.5, 2.2), at * CFrame.new(0, 0.25, 0), Color3.fromRGB(92, 84, 112), { Material = Enum.Material.Slate })
		local cr = part("ChimeCrystal", Vector3.new(1.1, d[3], 1.1), at * CFrame.new(0, 0.45 + d[3] / 2, 0) * CFrame.Angles(0.06, 0.7 * k, 0.05), d[2], { Material = Enum.Material.Glass, Transparency = 0.2, CanCollide = false })
		cr:SetAttribute("ChimeCrystal", k)
		part("ChimeCore", Vector3.new(0.3, d[3] * 0.8, 0.3), cr.CFrame, d[2], { Material = Enum.Material.Neon, CanCollide = false, CastShadow = false })
		local cl = Instance.new("PointLight")
		cl.Color, cl.Range, cl.Brightness, cl.Shadows = d[2], 10, 0.8, false
		cl.Parent = cr
		chimes[k] = prompt(cr, "Strike", "Crystal chime", "Chime", k, 6)
	end
	-- echo walls (roadmap i31, the Echo Tap minigame): a ribbed panel of five clay drums on the wall. One is hollow: tap them
	-- and listen (and watch the ring): the nearer to the hollow one, the deeper the note and the wider the ring.
	for i, e in { { 2, 53.4, math.pi }, { -73.4, -34, math.pi / 2 }, { 46, 53.4, math.pi } } do
		local cf = O * CFrame.new(e[1], 5, e[2]) * CFrame.Angles(0, e[3], 0)
		local back = part("EchoWall", Vector3.new(11, 4.4, 0.8), cf, CLAY_D, ROCK)
		for k = -2, 2 do
			part("EchoDrum", Vector3.new(1.7, 3.4, 0.5), cf * CFrame.new(k * 2.05, 0, 0.56), k % 2 == 0 and CLAY_L or CREAM, { CanCollide = false, CastShadow = false })
			part("EchoBand", Vector3.new(1.84, 0.3, 0.6), cf * CFrame.new(k * 2.05, 1.1, 0.56), PLUM, DECO)
		end
		back:SetAttribute("Echo", i)
		echoes[i] = prompt(back, "Tap", "Echo wall", "Echo", i, 10)
	end
	-- ------------------------------------------------------------------------------------------------------------------
	-- The two rooms behind the north wall (phase D, 2026-11-13). Their fronts are the hall's north wall (outer face z = -60).
	local TEALG = Color3.fromRGB(70, 214, 200)
	local function glow(pos, color, range, b) -- a light with nothing to see
		local p = part("Glow", Vector3.new(1, 1, 1), O * CFrame.new(pos), color, { Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false })
		local l = Instance.new("PointLight")
		l.Color, l.Range, l.Brightness, l.Shadows = color, range, b, false
		l.Parent = p
	end
	local function lantern(pos) -- a teal glass lantern on a short chain
		part("GlassLantern", Vector3.new(1.4, 1.8, 1.4), O * CFrame.new(pos), TEALG, { Material = Enum.Material.Glass, Transparency = 0.25, CanCollide = false, CastShadow = false })
		part("GlassLanternCore", Vector3.new(0.6, 0.9, 0.6), O * CFrame.new(pos), Color3.fromRGB(200, 255, 244), { Material = Enum.Material.Neon, CanCollide = false, CastShadow = false })
		part("GlassLanternCap", Vector3.new(1.7, 0.3, 1.7), O * CFrame.new(pos + Vector3.new(0, 1.05, 0)), BARK, DECO)
		part("GlassLanternChain", Vector3.new(0.16, 3, 0.16), O * CFrame.new(pos + Vector3.new(0, 2.7, 0)), PLUM, DECO)
		glow(pos, TEALG:Lerp(CREAM, 0.35), 44, 0.85)
	end
	local function sign(text, cf) -- a wooden board with the room's name
		local b = part("RoomSign", Vector3.new(11, 2.6, 0.5), cf, BARK, { Material = Enum.Material.Wood, CanCollide = false })
		local sg = Instance.new("SurfaceGui")
		sg.Face, sg.SizingMode, sg.PixelsPerStud, sg.LightInfluence = Enum.NormalId.Front, Enum.SurfaceGuiSizingMode.PixelsPerStud, 40, 0.2
		local tl = Instance.new("TextLabel")
		tl.Size, tl.BackgroundTransparency, tl.Text, tl.TextScaled, tl.Font, tl.TextColor3 = UDim2.fromScale(1, 1), 1, text, true, Enum.Font.FredokaOne, CREAM
		tl.Parent = sg
		sg.Parent = b
	end
	local function pad(x, y, z, power)
		mushroomPad(x, y, z, power)
	end

	-- THE JAR GALLERY: x -6..28, z -104..-60, 22 high. Four jars on the floor and on three stone steps, bounce pads between them.
	do
		part("GalleryFloor", Vector3.new(37, 6, 47), O * CFrame.new(9.5, -3, -86.5), Color3.fromRGB(96, 56, 60), ROCK) -- ends where the dig's floor begins (x 28)
		-- walls stand on the floors (from y 0): a wall that starts lower shares an outer face with its floor and z-fights
		part("GalleryRoof", Vector3.new(37, 6, 44), O * CFrame.new(9.5, 25, -82), PLUM, ROCK)
		part("GalleryWall", Vector3.new(6, 22, 44), O * CFrame.new(-9, 11, -82), CLAY, ROCK) -- up to the roof's underside: a top level with the roof's top would z-fight
		part("GalleryWall", Vector3.new(40, 28, 6), O * CFrame.new(8, 14, -107), CLAY_D, ROCK) -- ends at the dig's west wall (x 28)
		for k = 0, 2 do part("GalleryBeam", Vector3.new(34, 1.6, 1.6), O * CFrame.new(11, 21.2, -68 - k * 15), BARK, { Material = Enum.Material.Wood, CanCollide = false }) end
		part("GalleryBand", Vector3.new(0.4, 1.2, 43.6), O * CFrame.new(-5.8, 9, -82), CREAM:Lerp(CLAY, 0.35), ROCK)
		for _, z in { -64, -84 } do -- two clay wall sconces down the west wall: the way into the gallery was too dark to read the stepping stones (Gemini full1119i)
			part("SconcePot", Vector3.new(1.0, 1.0, 1.2), O * CFrame.new(-5.2, 8, z), CLAY_D, DECO)
			local wick = part("SconceWick", Vector3.new(0.45, 0.45, 0.45), O * CFrame.new(-5.2, 8.7, z), AMBER, { Material = Enum.Material.Neon, CanCollide = false, CastShadow = false })
			local l = Instance.new("PointLight")
			l.Color, l.Range, l.Brightness, l.Shadows = AMBER:Lerp(CREAM, 0.4), 26, 0.6, false
			l.Parent = wick
			l:SetAttribute("Fixture", true)
		end
		part("GalleryBand", Vector3.new(33.6, 1.1, 0.4), O * CFrame.new(11, 9, -103.8), CREAM:Lerp(CLAY, 0.35), ROCK)
		for _, s in { { 0, -74, 8, 4 }, { 0, -96, 8, 8 }, { 22, -98, 10, 12 }, { 22, -72, 8, 5 } } do -- stone steps: x, z, width, height
			part("GalleryStep", Vector3.new(s[3], s[4], 8), O * CFrame.new(s[1], s[4] / 2, s[2]), s[4] % 8 == 0 and CLAY_L or CLAY, ROCK)
			part("GalleryStepCap", Vector3.new(s[3] + 0.8, 0.5, 8.8), O * CFrame.new(s[1], s[4] + 0.25, s[2]), CREAM:Lerp(CLAY, 0.45), ROCK) -- a warmer cap: the pale white slab looked new against the old clay (Gemini full1119l)
			for _, sx in { -1, 1 } do -- a worn, darker lip along both long edges so the cap does not end in one hard white line
				part("GalleryStepLip", Vector3.new(0.5, 0.36, 8.6), O * CFrame.new(s[1] + sx * (s[3] / 2 + 0.25), s[4] + 0.44, s[2]), CLAY_D:Lerp(CLAY, 0.4), ROCK)
			end
			part("GalleryStepFoot", Vector3.new(s[3] + 1.0, 0.9, 9.0), O * CFrame.new(s[1], 0.45, s[2]), CLAY_D, ROCK) -- a darker plinth foot, so the step stands on the floor instead of sitting on it (Gemini full1120x)
			part("GalleryStepBand", Vector3.new(s[3] + 0.3, 0.3, 8.3), O * CFrame.new(s[1], math.max(1.3, s[4] * 0.55), s[2]), CREAM:Lerp(CLAY_D, 0.5), ROCK) -- one carved band round the middle
		end
		pad(11, 0, -86, 78) -- from the floor up to any step
		pad(22, 5.5, -72, 62) -- from the low step on to the tall one
		for i, sx in { -76, -92 } do -- pot shelves on the west wall
			for lv = 0, 1 do
				part("Shelf", Vector3.new(2.2, 0.5, 9), O * CFrame.new(-4.7, 12 + lv * 3.2, sx), BARK, { Material = Enum.Material.Wood, CanCollide = false })
				for q = 0, 3 do
					local v = (q * 3 + lv * 5 + i * 7) % 5 -- directive v14 round 5 (Gemini full1122e: "a hall of duplicated props"): one gap a shelf, three belly widths, squat and tall
					if v == 4 and q > 0 then continue end
					local h = 1 + ((q + lv + i) % 3) * 0.4
					local belly = ({ 1.05, 1.45, 1.25, 1.6 })[v + 1] or 1.25
					local pc = (q + lv) % 2 == 0 and CLAY_L or TEALG:Lerp(CLAY_D, 0.5)
					if v == 1 then pc = CREAM:Lerp(CLAY_L, 0.4) end
					local base = O * CFrame.new(-4.7, 12.25 + lv * 3.2, sx - 3.2 + q * 2.1) * CFrame.Angles(0, 0, math.pi / 2)
					for _, r in { { 0.7, 0.18, 0.09 }, { belly, h * 0.55, 0.18 + h * 0.275 }, { 0.65, h * 0.3, 0.18 + h * 0.55 + h * 0.15 }, { 0.95, 0.12, 0.18 + h * 0.85 + 0.06 } } do -- foot, belly, neck, lip (directive v13)
						local p = part("ShelfPot", Vector3.new(r[2], r[1], r[1]), base * CFrame.new(r[3], 0, 0), pc, DECO)
						p.Shape = Enum.PartType.Cylinder
					end
				end
			end
		end
		for k = 0, 9 do -- chunky flagstones sunk in the clay floor, each set on the floor under it (Gemini v13 round 2: paper-thin stickers)
			local at = O * CFrame.new(11 + math.sin(k) * 1.2, 0, -50 - k * 4) * CFrame.Angles(0, k * 0.5, 0)
			local hit = workspace:Raycast(at.Position + Vector3.new(0, 4, 0), Vector3.new(0, -9, 0))
			local y = hit and (hit.Position.Y - at.Position.Y) or 0.1
			local col = k % 3 == 0 and TEALG:Lerp(CLAY, 0.6) or CREAM:Lerp(CLAY_D, 0.55)
			part("PathTile", Vector3.new(3.2, 0.7, 3.2), at * CFrame.new(0, y - 0.2, 0), col, { CanCollide = false, Material = Enum.Material.Sandstone })
			part("PathTileTop", Vector3.new(2.7, 0.12, 2.7), at * CFrame.new(0, y + 0.19, 0), col:Lerp(Color3.new(1, 1, 1), 0.08), { CanCollide = false, Material = Enum.Material.Sandstone })
		end
		lantern(Vector3.new(11, 17.5, -70))
		lantern(Vector3.new(11, 17.5, -94))
		for _, x in { 5.2, 16.8 } do part("DoorPost", Vector3.new(1.4, 14.6, 1.4), O * CFrame.new(x, 7.3, -53.2), BARK, { Material = Enum.Material.Wood }) end
		part("DoorLintel", Vector3.new(14.4, 1.4, 1.6), O * CFrame.new(11, 15.3, -53.2), BARK, { Material = Enum.Material.Wood, CanCollide = false })
		sign("JAR GALLERY", O * CFrame.new(11, 18, -52) * CFrame.Angles(0, math.pi, 0)) -- 1.5 studs out from the wall: it cut into the rock (Gemini full1119e)
	end

	-- THE FOSSIL DIG: x 34..74, z -110..-60, 46 high. Two dug terraces rise to the back, where a giant hammer head lies half
	-- buried and lit from below (the landmark the owner asked for; seen from the hall through the breach). The three fossils
	-- are on its walls.
	do
		local IRON, IRON_L = Color3.fromRGB(70, 66, 92), Color3.fromRGB(112, 108, 138)
		part("DigFloor", Vector3.new(52, 6, 53), O * CFrame.new(54, -3, -89.5), Color3.fromRGB(84, 48, 52), ROCK)
		part("DigRoof", Vector3.new(52, 6, 56), O * CFrame.new(54, 49, -88), PLUM, ROCK)
		part("DigWall", Vector3.new(6, 46, 50), O * CFrame.new(31, 23, -85), CLAY, ROCK) -- also the gallery's east wall
		part("DigWall", Vector3.new(6, 46, 50), O * CFrame.new(77, 23, -85), CLAY, ROCK)
		part("DigWall", Vector3.new(52, 46, 6), O * CFrame.new(54, 23, -113), CLAY_D, ROCK)
		part("DigTerrace", Vector3.new(40, 1.4, 32), O * CFrame.new(54, 0.7, -94), CLAY_D:Lerp(CLAY, 0.4), ROCK)
		part("DigTerrace", Vector3.new(40, 1.4, 20), O * CFrame.new(54, 2.1, -100), CLAY_D, ROCK)
		for i = 1, 9 do -- strata on the walls
			local y, len = 8 + i * 3.9, 14 + (i * 7) % 16
			if i % 3 == 0 then
				part("Strata", Vector3.new(len, 2 + i % 3, 1.6 + (i % 4) * 0.3), O * CFrame.new(40 + (i * 11) % 26, y, -109.2 + (i % 4) * 0.15), i % 2 == 0 and CLAY_L or CLAY, ROCK)
			else
				part("Strata", Vector3.new(1.6 + (i % 4) * 0.3, 2 + i % 3, len), O * CFrame.new(i % 3 == 1 and 34.8 + (i % 4) * 0.15 or 73.2 - (i % 4) * 0.15, y, -70 - (i * 9) % 30), i % 2 == 0 and CLAY_L or CLAY, ROCK)
			end
		end
		-- the hammer: the head lies tilted in the back terrace, a broken handle stands out of it
		local H = O * CFrame.new(55, 6.2, -100) * CFrame.Angles(math.rad(-16), math.rad(28), math.rad(11))
		part("HammerHead", Vector3.new(14, 12, 24), H, IRON, { Material = Enum.Material.Slate })
		for _, z in { -12.4, 12.4 } do part("HammerFace", Vector3.new(15.4, 13.4, 1.6), H * CFrame.new(0, 0, z), IRON_L, { Material = Enum.Material.Slate }) end
		for _, z in { -5, 5 } do part("HammerBand", Vector3.new(14.5, 12.5, 1.4), H * CFrame.new(0, 0, z), TEALG, { Material = Enum.Material.Glass, Transparency = 0.2 }) end
		part("HammerCollar", Vector3.new(6.4, 2.2, 6.4), H * CFrame.new(0, 7, 0), IRON_L, { Material = Enum.Material.Slate })
		local handle = H * CFrame.new(0, 8, 0) * CFrame.Angles(math.rad(8), 0, math.rad(-6))
		part("HammerHandle", Vector3.new(4.2, 22, 4.2), handle * CFrame.new(0, 11, 0), BARK, { Material = Enum.Material.Wood })
		part("HammerHandleBreak", Vector3.new(3, 3, 3), handle * CFrame.new(0.5, 23, 0.4) * CFrame.Angles(0.5, 0.4, 0.3), BARK:Lerp(CREAM, 0.25), { Material = Enum.Material.Wood })
		for k = 1, 4 do part("HammerWrap", Vector3.new(4.5, 0.9, 4.5), handle * CFrame.new(0, 3 + k * 2.6, 0), k % 2 == 0 and TEALG:Lerp(BARK, 0.4) or CREAM:Lerp(BARK, 0.5), { CanCollide = false }) end
		for k = 0, 5 do -- glowing cracks in the terrace round the head: the light from below
			local a = k / 6 * math.pi * 2 + 0.4
			local at = Vector3.new(55 + math.cos(a) * 12, 2.84, -99 + math.sin(a) * 7.5)
			if at.Z > -109 then
				part("DigCrack", Vector3.new(5 + k % 3, 0.2, 0.7), O * CFrame.new(at) * CFrame.Angles(0, -a + 0.6 * (k % 2), 0), TEALG, { Material = Enum.Material.Neon, CanCollide = false, CastShadow = false })
				if k % 2 == 0 then glow(at + Vector3.new(0, 1.2, 0), TEALG, 30, 1.3) end
			end
		end
		glow(Vector3.new(55, 20, -92), CREAM:Lerp(TEALG, 0.5), 70, 1.1) -- a soft fill high in the room so the handle reads
		glow(Vector3.new(52, 11, -82), CREAM, 42, 0.8) -- on the face turned to the breach: the hammer shows from the hall
		for k = 1, 12 do -- dug earth: mounds on the terraces and at the wall feet
			local sz = 1.2 + (k * 7 % 5) * 0.5
			part("DigMound", Vector3.new(sz * 1.6, sz * 0.8, sz * 1.3), O * CFrame.new(37 + (k * 13) % 34, (k % 2 == 0 and 1.4 or 0) + sz * 0.3, -64 - (k * 17) % 28) * CFrame.Angles(0.2 * (k % 3), k, 0.15 * (k % 2)), k % 3 == 0 and CLAY_L or CLAY_D, ROCK)
		end
		-- a digger's scaffold by the west wall, a ladder, a crate with brushes
		for _, z in { -88, -96 } do part("ScaffoldPost", Vector3.new(0.8, 12, 0.8), O * CFrame.new(38, 7.3, z), BARK, { Material = Enum.Material.Wood }) end -- sunk 0.1 into the terrace
		part("ScaffoldPlank", Vector3.new(4.5, 0.5, 10.5), O * CFrame.new(37.6, 11.2, -92), BARK:Lerp(CREAM, 0.2), { Material = Enum.Material.Wood })
		part("Ladder", Vector3.new(0.5, 11, 2.6), O * CFrame.new(40.4, 6.6, -84.5) * CFrame.Angles(0, 0, math.rad(-12)), BARK:Lerp(CREAM, 0.15), { Material = Enum.Material.Wood, CanCollide = false })
		part("DigCrate", Vector3.new(3, 2.4, 3), O * CFrame.new(69, 1.2, -66) * CFrame.Angles(0, 0.4, 0), BARK, { Material = Enum.Material.Wood })
		for q = 0, 2 do part("DigBrush", Vector3.new(0.3, 1.6, 0.3), O * CFrame.new(68.4 + q * 0.6, 3, -66 + q * 0.4) * CFrame.Angles(0.3 * q, 0, 0.2), q == 1 and TEALG or CREAM, DECO) end
		lantern(Vector3.new(44, 15, -68))
		lantern(Vector3.new(66, 15, -78))
		for _, x in { 44.2, 60.8 } do part("BreachPost", Vector3.new(2, 34.6, 2), O * CFrame.new(x, 17.3, -53), BARK, { Material = Enum.Material.Wood }) end
		part("BreachLintel", Vector3.new(20.6, 2, 2.2), O * CFrame.new(52.5, 35.6, -53), BARK, { Material = Enum.Material.Wood, CanCollide = false })
		sign("FOSSIL DIG", O * CFrame.new(52.5, 38.6, -53.4) * CFrame.Angles(0, math.pi, 0))
	end
	do -- directive v14 (Gemini: "a dead-flat ballroom floor"): clay sediment mounds along the wall feet, two stepped blocks each, only where
		-- nothing else of the hall stands (doors, stalls, echo walls, crystals and ore keep their space); decor, no collision
		local qp = OverlapParams.new()
		qp.FilterType = Enum.RaycastFilterType.Include
		qp.FilterDescendantsInstances = { folder, depF }
		local spots, n = {}, 0
		for x = -66, 66, 7 do table.insert(spots, { x, -50.5, 0 }) table.insert(spots, { x, 50.5, math.pi }) end
		for z = -44, 44, 7 do table.insert(spots, { -70.5, z, math.pi / 2 }) table.insert(spots, { 70.5, z, -math.pi / 2 }) end
		for i, sp in spots do
			local door = (math.abs(sp[1]) > 69 and math.abs(sp[2]) < 13) or (sp[2] < 0 and math.abs(sp[1]) < 70 and ((sp[1] > 2 and sp[1] < 21) or (sp[1] > 40 and sp[1] < 66)))
			local s = 3.2 + ((i * 37) % 10) / 5
			local cf = O * CFrame.new(sp[1], 0.6, sp[2]) * CFrame.Angles(0, sp[3] + ((i * 13) % 7 - 3) * 0.08, 0)
			local clear = not door
			if clear then
				for _, p in workspace:GetPartBoundsInBox(cf * CFrame.new(0, 1.2, 0), Vector3.new(s + 1.5, 2.6, s * 0.8 + 1.5), qp) do
					if p.Name ~= "Floor" and p.Name ~= "CaveRock" then clear = false break end
				end
			end
			if clear then
				local tone = ({ CLAY_D, Color3.fromRGB(176, 120, 72), CLAY, Color3.fromRGB(150, 70, 50) })[i % 4 + 1]
				part("ClayMound", Vector3.new(s, 1.2, s * 0.8), cf, tone, DECO)
				part("ClayMound", Vector3.new(s * 0.6, 1, s * 0.5), cf * CFrame.new(0.3, 1, -0.4) * CFrame.Angles(0, 0.5, 0), tone:Lerp(CREAM, 0.12), DECO)
				n += 1
			end
		end
		folder:SetAttribute("Mounds", n)
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
	local brushing = {} -- [plr] = { i, started }; the jars' cooldowns are saved (ctx.coolSet)
	Players.PlayerRemoving:Connect(function(plr) brushing[plr] = nil end)

	local function travel(plr, to, from) -- from: the prompt used (nil for the Studio hook)
		local s, hrp = ctx.data[plr], ctx.hrpOf(plr)
		if not s or not hrp or ctx.busy(plr) or s.mg or not plr:GetAttribute("InCave") then return end
		if from and not ctx.nearPrompt(plr, from) then return end
		if os.clock() < (s.travelCool or 0) then return end
		s.travelCool = os.clock() + 2
		if to == 2 and not s.tips.gate1 then return end -- the Root Warden still guards the gate
		local goal = to == 2 and landing.CFrame or (stairs and stairs.CFrame * CFrame.new(0, 1, -4))
		if not goal then return end
		local secs = to == 2 and (s.tips.lift and 6 or 12) or 2.75 -- the glass lift down (the first ride is the long one), the tunnel cart back up
		if to == 2 then s.tips.lift = true end
		if ctx.hold then ctx.hold(plr, secs + 1.5) end -- anchored and left alone by Gloomlings until the client reports "arrived" (or the time runs out)
		ctx.fx:FireClient(plr, "clayTravel", to, secs)
		task.delay(0.35, function() -- under the client's fade
			if hrp.Parent then
				hrp.AssemblyLinearVelocity = Vector3.zero
				hrp.CFrame = goal + Vector3.new(0, 2, 0)
			end
		end)
		if to == 2 and ctx.quest then ctx.quest(s, "clay") end
		if to == 2 and not s.tips.clay then
			s.tips.clay = true
			ctx.sendState(s) -- the town cart now offers both camps (Shared.CampChoice reads the tips)
			if ctx.analytics then ctx.analytics.event(s, "ClayCavesReached") end
		end
	end
	local function near(plr, p, d)
		local hrp = ctx.hrpOf(plr)
		return hrp ~= nil and (hrp.Position - p.Position).Magnitude <= d
	end
	for _, d in clay:GetDescendants() do
		if d:IsA("ProximityPrompt") and d:GetAttribute("ClayPortal") then d.Triggered:Connect(function(plr) travel(plr, 1, d) end) end
		if d:IsA("ProximityPrompt") and d:GetAttribute("ZipLine") then
			d.Triggered:Connect(function(plr) -- nothing is paid: the server checks the place and the client rides (its own character)
				local s = ctx.data[plr]
				if not s or s.mg or ctx.busy(plr) or not ctx.nearPrompt(plr, d) then return end
				ctx.fx:FireClient(plr, "zip")
			end)
		end
	end
	if stairs then
		local pr = stairs:FindFirstChildOfClass("ProximityPrompt")
		if pr then pr.Triggered:Connect(function(plr) travel(plr, 2, pr) end) end
	end
	for i, pr in jars do
		pr.Triggered:Connect(function(plr)
			local s = ctx.data[plr]
			if not s or ctx.coolLeft(s, "jar" .. i) > 0 or not near(plr, pr.Parent, 14) then return end
			ctx.coolSet(s, "jar" .. i, K.jarEvery) -- saved: a rejoin does not refill the jar
			local rng = Random.new()
			local gold = rng:NextInteger(K.jarGold[1], K.jarGold[2])
			local shard = rng:NextNumber() < K.shardOdds
			local geode = rng:NextNumber() < K.geodeOdds
			if geode then s.geodes = (s.geodes or 0) + 1 end
			s.gold += gold
			if shard then s.shards = (s.shards or 0) + 1 end
			if ctx.analytics then ctx.analytics.earn(s, "Coins", gold, s.gold, "ClayJar") end
			if ctx.quest then ctx.quest(s, "jar") end
			ctx.fx:FireClient(plr, "jar", i, gold, shard and s.shards or nil, K.jarEvery, geode and s.geodes or nil)
			ctx.sendState(s)
		end)
	end
	-- Echo Tap: the server hides the hollow drum (1..5) and answers every tap with how far off it was; K.echoTaps taps at most
	local echo = {} -- [plr] = { i, target, taps }; the walls' cooldowns are saved (ctx.coolSet)
	Players.PlayerRemoving:Connect(function(plr) echo[plr] = nil end)
	for i, pr in echoes do
		pr.Triggered:Connect(function(plr)
			local s = ctx.data[plr]
			if not s or s.mg or ctx.busy(plr) or not near(plr, pr.Parent, 18) then return end
			if echo[plr] and echo[plr].i == i then return end -- a game on this wall is already running: no reroll of the hollow drum
			local wait = ctx.coolLeft(s, "echo" .. i)
			if wait > 0 then ctx.fx:FireClient(plr, "echoEmpty", math.ceil(wait / 60)) return end
			echo[plr] = { i = i, target = math.random(1, 5), taps = 0 }
			ctx.fx:FireClient(plr, "echoStart", i, K.echoTaps)
		end)
	end
	local function echoTap(plr, i, drum)
		local s, g = ctx.data[plr], echo[plr]
		if not s or not g or g.i ~= i or type(drum) ~= "number" or drum < 1 or drum > 5 or drum % 1 ~= 0 or not near(plr, echoes[i].Parent, 18) then return end
		g.taps += 1
		local off = math.abs(drum - g.target)
		if off == 0 then
			echo[plr] = nil
			ctx.coolSet(s, "echo" .. i, K.echoEvery)
			local gold = K.echoGold[1] + (K.echoTaps - g.taps) * K.echoGold[2] -- fewer taps, more coins
			s.gold += gold
			s.geodes = (s.geodes or 0) + 1 -- every hollow drum hides a geode
			if ctx.analytics then
				ctx.analytics.earn(s, "Coins", gold, s.gold, "EchoTap")
				ctx.analytics.event(s, "EchoTap", g.taps)
			end
			if ctx.quest then ctx.quest(s, "echo") end
			ctx.fx:FireClient(plr, "echoTap", drum, 0, gold)
			ctx.sendState(s)
		elseif g.taps >= K.echoTaps then
			echo[plr] = nil
			ctx.coolSet(s, "echo" .. i, 30) -- a miss: try again in half a minute
			ctx.fx:FireClient(plr, "echoTap", drum, off, -1, g.target)
		else
			ctx.fx:FireClient(plr, "echoTap", drum, off)
		end
	end
	-- Crystal Resonance Chimes: the first strike wakes them (the server picks the order and tells only this player); then
	-- every strike is checked here. Three right in time: coins, and the chimes rest. A wrong one ends the try.
	local chime = {} -- [plr] = { order = { which crystal is 1st, 2nd, 3rd }, at, till }
	Players.PlayerRemoving:Connect(function(plr) chime[plr] = nil end)
	for k, pr in chimes do
		pr.Triggered:Connect(function(plr)
			local s = ctx.data[plr]
			if not s or s.mg or ctx.busy(plr) or not near(plr, pr.Parent, 12) then return end
			local H = C.CHIMES
			local g = chime[plr]
			if not g or os.clock() > g.till then
				local wait = ctx.coolLeft(s, "chime")
				if wait > 0 then ctx.fx:FireClient(plr, "chime", "cool", math.ceil(wait / 60)) return end
				local order = { 1, 2, 3 }
				for i = 3, 2, -1 do
					local j = math.random(1, i)
					order[i], order[j] = order[j], order[i]
				end
				local slow = game:GetService("RunService"):IsStudio() and workspace:GetAttribute("DevChimeSlow") or 1 -- test hook: a slow Studio needs ~4 s a scripted strike
				chime[plr] = { order = order, at = 1, till = os.clock() + H.secs * slow }
				ctx.fx:FireClient(plr, "chime", "start", order, H.secs * slow)
			elseif g.order[g.at] == k then
				g.at += 1
				if g.at > 3 then
					chime[plr] = nil
					ctx.coolSet(s, "chime", H.every)
					s.gold += H.gold
					if ctx.analytics then ctx.analytics.earn(s, "Coins", H.gold, s.gold, "Chimes") end
					ctx.fx:FireClient(plr, "chime", "done", H.gold)
					ctx.sendState(s)
				else
					ctx.fx:FireClient(plr, "chime", "hit", k, g.at - 1)
				end
			else
				chime[plr] = nil
				ctx.coolSet(s, "chime", 10)
				ctx.fx:FireClient(plr, "chime", "miss", k)
			end
		end)
	end
	-- Geode Lock: the server makes the order (5 of 6 facets), shows 3, then 4, then 5; every facet the client taps is checked
	-- here. A wrong tap ends the try and keeps the geode. Three rounds right cracks it: gems and coins.
	local lock = {} -- [plr] = { seq, round, at, till }
	Players.PlayerRemoving:Connect(function(plr) lock[plr] = nil end)
	for _, d in clay:GetDescendants() do
		if d:IsA("ProximityPrompt") and d:GetAttribute("GeodeAnvil") then
			d.Triggered:Connect(function(plr)
				local s = ctx.data[plr]
				if not s or s.mg or ctx.busy(plr) or not ctx.nearPrompt(plr, d, 16) then return end
				if (s.geodes or 0) < 1 then ctx.fx:FireClient(plr, "geodeNone") return end
				if lock[plr] and os.clock() < lock[plr].till then return end -- one try at a time
				local seq = {}
				for k = 1, 5 do seq[k] = math.random(1, 6) end
				lock[plr] = { seq = seq, round = 1, at = 1, till = os.clock() + 75 }
				ctx.fx:FireClient(plr, "geodeStart", { seq[1], seq[2], seq[3] }, s.geodes)
			end)
		end
	end
	local function geodeTap(plr, facet)
		local s, g = ctx.data[plr], lock[plr]
		if not s or not g or os.clock() > g.till or type(facet) ~= "number" or facet % 1 ~= 0 or facet < 1 or facet > 6 or (s.geodes or 0) < 1 then return end
		if facet ~= g.seq[g.at] then
			lock[plr] = nil
			ctx.fx:FireClient(plr, "geodeMiss", g.seq[g.at])
			return
		end
		g.at += 1
		if g.at <= g.round + 2 then return end -- more facets to go in this round
		if g.round < 3 then
			g.round, g.at = g.round + 1, 1
			local show = {}
			for k = 1, g.round + 2 do show[k] = g.seq[k] end
			ctx.fx:FireClient(plr, "geodeRound", show, g.round)
			return
		end
		lock[plr] = nil
		s.geodes -= 1
		local gems, gold = math.random(K.geodeGems[1], K.geodeGems[2]), K.geodeGold
		s.gems += gems
		s.gold += gold
		if ctx.analytics then
			ctx.analytics.earn(s, "Gems", gems, s.gems, "Geode")
			ctx.analytics.earn(s, "Coins", gold, s.gold, "Geode")
		end
		if ctx.quest then ctx.quest(s, "geode") end
		ctx.fx:FireClient(plr, "geodeWin", gems, gold, s.geodes)
		ctx.sendState(s)
	end
	for i, pr in fossils do
		pr.Triggered:Connect(function(plr)
			local s = ctx.data[plr]
			if not s or s.mg or ctx.busy(plr) or not ctx.nearPrompt(plr, pr) then return end -- the distance check covers the quest credit below too (Codex)
			s.fossils = s.fossils or {}
			if s.fossils[tostring(i)] then
				if ctx.quest then ctx.quest(s, "fossil") end -- a fossil cleaned before the quest came up still counts: each pays once ever, so the chapter could not be finished (Codex)
				ctx.fx:FireClient(plr, "fossilHave", i)
				return
			end
			brushing[plr] = { i = i, t = os.clock() }
			ctx.fx:FireClient(plr, "fossilBrush", i)
		end)
	end
	remote.OnServerEvent:Connect(function(plr, what, i, ...)
		if what == "echo" then return echoTap(plr, i, ...) end
		if what == "geode" then return geodeTap(plr, i) end
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
		if ctx.quest then ctx.quest(s, "fossil") end
		ctx.fx:FireClient(plr, "fossilDone", i, K.fossilGems, n, #fossils)
		ctx.sendState(s)
	end)
	for _, d in clay:GetDescendants() do
		if d:IsA("ProximityPrompt") and d:GetAttribute("ClayEgg") then
			d.Triggered:Connect(function(plr) -- the Keeper's egg: coins for one egg (hatch it at the incubator in town)
				local s = ctx.data[plr]
				if not s or not near(plr, d.Parent, 16) then return end
				if s.gold < K.eggCost then ctx.fx:FireClient(plr, "clayEgg", false, K.eggCost - s.gold) return end
				s.gold -= K.eggCost
				s.eggs += 1
				if ctx.analytics then ctx.analytics.spend(s, "Coins", K.eggCost, s.gold, "KeeperEgg") end
				ctx.fx:FireClient(plr, "egg", s.eggs)
				ctx.fx:FireClient(plr, "clayEgg", true, K.eggCost)
				ctx.sendState(s)
			end)
		elseif d:IsA("ProximityPrompt") and d:GetAttribute("Critter") then
			d.Triggered:Connect(function(plr) -- the lost critter: free it once, ever; it leaves an egg
				local s = ctx.data[plr]
				if not s or not ctx.nearPrompt(plr, d, 16) then return end
				if s.tips.critter1 then ctx.fx:FireClient(plr, "critter", false) return end
				s.tips.critter1 = true
				s.eggs += 1
				if ctx.analytics then ctx.analytics.event(s, "LostCritterFreed") end
				ctx.fx:FireClient(plr, "egg", s.eggs)
				ctx.fx:FireClient(plr, "critter", true)
				ctx.sendState(s)
			end)
		end
	end
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
