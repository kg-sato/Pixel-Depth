-- The Ashcoal Pickaxe's biography, played by ForgeStory: "Oak logs stacked in a ring and buried under turf; a badger charcoal
-- burner watched the mound for three nights." Closing line: "Three nights, no sleep."
-- The setting (scene bible entry "Ashcoal", refs/forge/sheets/ashcoal_setting_s11.png): a clearing in an old oak wood on a
-- hillside, a valley filling with mist behind it. Models: design3d/ashcoal.mjs. Ground, skies and the map: design3d/ashcoal_world.py.
-- Stage space: the camera stands at -Z and looks to +Z, +X is screen left. The mound stands at (2.6, 0, 1.5), the stool at
-- (-2.4, 0, -1.2), the lantern at (-1.3, 0, -2.7), the kettle's stone at (-4.0, 0, -2.3), the cordwood at (-7.2, 0, 1.4).
-- Every time in this file is a story second: the story's own clock runs at 0.58 of real time (0.75 in the short version).
local M = { length = 11.2, named = 7.6, open = true, pace = 0.58, fastPace = 0.75 }

-- the painted skies of design3d/ashcoal_world.py (design3d/tex/ashcoal_sky_<look>_side|up|dn.png), filled in at upload
local IMG = {
	dusk = { side = "77340433926072", up = "102317712123581", dn = "85476807382240" },
	night = { side = "88827071114631", up = "88230532641455", dn = "112799260521533" },
	dawn = { side = "85534544276704", up = "128939480822497", dn = "99543739469512" },
	rain = "rbxassetid://80922659043708",
	rays = "rbxassetid://98789616938156",
}

local function hex(h) return Color3.fromHex(h) end
local function v3(x, y, z) return Vector3.new(x, y, z) end

function M.setup(ctx)
	local S = ctx.S
	local R, smooth = S.rot, S.smooth
	local O, sfx = ctx.O, ctx.sfx
	local function W(x, y, z) return O * CFrame.new(x, y, z) end
	local K = NumberSequenceKeypoint.new
	local CK = ColorSequenceKeypoint.new
	local rgb = Color3.fromRGB
	local V = Vector3.new
	local function back(u) -- 0..1 with a small overshoot
		u = math.clamp(u, 0, 1)
		local x = u - 1
		return 1 + 2.70158 * x * x * x + 1.70158 * x * x
	end
	local function matte(r) r:all(function(p) if p.Material ~= Enum.Material.Neon then p.Material = Enum.Material.Rubber end end) end
	local function once(key, at, t, fn) if t < at + 0.4 then ctx.once(key, at, t, fn) end end -- the short version starts at NAMED: earlier events stay silent

	-- ===== the place =====
	local MAP = require(script.Parent:WaitForChild("ForgeAshcoalMap"))
	local land = ctx.prop("AshcoalWorld")
	land:all(function(p) p.Material = Enum.Material.Rubber end)
	local SMALL = { Fern = true, FlowerPatch2 = true, Mushroom = true, WispyGrass = true, Clover = true, Plant1 = true, ShelfFungus = true, PineClump = true }
	for _, it in MAP.items do
		local cf = CFrame.new(it[2], it[3], it[4]) * CFrame.Angles(0, math.rad(it[5]), 0)
		local r = ctx.prop(it[1], cf, it[6])
		local small = SMALL[it[1]]
		r:all(function(p)
			if p.Material ~= Enum.Material.Neon then p.Material = Enum.Material.Rubber end
			if small then p.CastShadow = false end
		end)
	end
	local set = ctx.rig("AshcoalSet")
	matte(set)
	-- the woodland grass is fully modelled (design3d/ashcoal_grass.py): ring A is the clearing's rim, ring B the wood round it.
	-- A low graphics level takes ring A only. If the grass is not installed the painted floor shows instead.
	local level = 0
	pcall(function() level = UserSettings():GetService("UserGameSettings").SavedQualityLevel.Value end)
	local rings = (level ~= 0 and level <= 3) and { "AshcoalGrassA" } or { "AshcoalGrassA", "AshcoalGrassB" }
	if ctx.opt.noGrass then rings = {} end
	local windBones = {} -- { bone, its rest rotation turned back (stage wind to bone space), phase }: four in every grass mesh
	for _, n in rings do
		local ok, grass = pcall(ctx.asset, n)
		if ok and grass then
			for _, d in grass:GetDescendants() do
				if d:IsA("MeshPart") then
					d.Material, d.CastShadow = Enum.Material.Rubber, false
				elseif d:IsA("Bone") and string.find(d.Name, "_W%d") then
					table.insert(windBones, { d, d.WorldCFrame.Rotation:Inverse(), #windBones * 1.37 })
				end
			end
		end
	end

	-- ===== the cast =====
	local STOOL = CFrame.new(-2.4, 0.44, -1.2) * R(0, -30, 0)
	local WORKP = V(-1.3, 0, 0.1) -- where he stands to work on the mound
	local badger = ctx.rig("BadgerKit", STOOL)
	matte(badger)
	badger:show("EyesShut", false)
	local kettle = ctx.rig("AshKettle", CFrame.new(-4.0, 0.36, -2.3))
	local cup = ctx.rig("AshCup", CFrame.new(-3.4, 0, -1.9))
	local poker = ctx.rig("AshPoker", CFrame.new(-3.3, 0.5, -0.5) * R(0, 0, -22))
	local log = ctx.rig("AshLog", CFrame.new(0, -60, 0))
	matte(kettle) matte(cup) matte(poker) matte(log)
	local KETTLE_REST, CUP_REST = W(-4.0, 0.36, -2.3), W(-3.4, 0, -1.9)
	local POKER_REST = W(-3.3, 0.5, -0.5) * R(0, 0, -22)
	local puffs = {}
	local LANDS = { V(0.6, 0, -3.0), V(-0.4, 0, -2.3), V(1.7, 0, -3.7), V(2.7, 0, -2.9), V(0.2, 0, -1.6) }
	for i = 1, 5 do
		local r = ctx.rig("SootPuff", CFrame.new(0, -60, 0), 0.9)
		r:all(function(p) if p.Material ~= Enum.Material.Neon then p.Material = Enum.Material.Rubber end p.CastShadow = false end)
		puffs[i] = { r = r, t0 = 6.95 + 0.06 * i, land = LANDS[i], gone = 7.2 + 0.045 * i }
	end
	puffs[5].gone = 7.46 -- the last one stays: it becomes the charm

	local pick = ctx.pick()
	local pickScale0, pickH = 1, 1
	if pick then pickScale0, pickH = pick:GetScale(), math.max(pick:GetExtentsSize().Y, 0.1) end
	local function placePick(cf, height) -- stage-space frame, wanted height in studs
		if not pick then return end
		pick:ScaleTo(pickScale0 * height / pickH)
		pick:PivotTo(O * cf)
	end
	local PICK_LIE = CFrame.new(1.7, 1.3, 0.3)

	-- ===== lights: the lantern at his feet, the breath of the vents, the moon =====
	local lampPart = ctx.part(v3(0.3, 0.3, 0.3), CFrame.new(-1.3, 0.75, -2.7), hex("#ffb060"), { Transparency = 1 })
	local lamp = Instance.new("PointLight")
	lamp.Color, lamp.Range, lamp.Brightness, lamp.Shadows, lamp.Parent = hex("#ffb060"), 20, 2.4, true, lampPart
	local lampGlow = Instance.new("BillboardGui")
	lampGlow.Size, lampGlow.LightInfluence, lampGlow.Brightness, lampGlow.Parent = UDim2.fromScale(3.4, 3.4), 0, 1, lampPart
	local lampIm = Instance.new("ImageLabel")
	lampIm.BackgroundTransparency, lampIm.Image, lampIm.ImageColor3, lampIm.ImageTransparency, lampIm.Size, lampIm.Parent = 1, S.GLOW, hex("#ffb45a"), 0.5, UDim2.fromScale(1, 1), lampGlow
	local ventPart = ctx.part(v3(0.3, 0.3, 0.3), CFrame.new(0.5, 1.2, -1.5), hex("#ff7a2a"), { Transparency = 1 })
	local ventLight = Instance.new("PointLight")
	ventLight.Color, ventLight.Range, ventLight.Brightness, ventLight.Shadows, ventLight.Parent = hex("#ff7a2a"), 13, 0, false, ventPart
	local moon = ctx.part(v3(20, 20, 20), CFrame.new(0, -400, 0), hex("#fff3d0"), { Shape = Enum.PartType.Ball, Material = Enum.Material.Neon })
	local moonGlow = Instance.new("BillboardGui")
	moonGlow.Size, moonGlow.LightInfluence, moonGlow.Brightness, moonGlow.Parent = UDim2.fromScale(64, 64), 0, 1.4, moon
	local moonIm = Instance.new("ImageLabel")
	moonIm.BackgroundTransparency, moonIm.Image, moonIm.ImageColor3, moonIm.ImageTransparency, moonIm.Size, moonIm.Parent = 1, S.GLOW, hex("#dfe8ff"), 1, UDim2.fromScale(1, 1), moonGlow

	-- ===== smoke, sparks, moths, mist, drizzle =====
	local topPart = ctx.part(v3(0.5, 0.5, 0.5), CFrame.new(2.6, 4.1, 1.5), hex("#ffffff"), { Transparency = 1 })
	local smoke = ctx.emitter(topPart, { Texture = S.SMOKE, Color = ColorSequence.new({ CK(0, hex("#f2f2f2")), CK(0.4, hex("#9fb6dc")), CK(1, hex("#7f96bc")) }), Size = NumberSequence.new({ K(0, 0.5), K(1, 4.2) }), Transparency = NumberSequence.new({ K(0, 0.5), K(0.6, 0.8), K(1, 1) }), Lifetime = NumberRange.new(5, 8), Speed = NumberRange.new(1.6, 2.4), EmissionDirection = Enum.NormalId.Top, SpreadAngle = Vector2.new(6, 6), Acceleration = v3(-0.7, 0.25, 0.2), LightEmission = 0.15, LightInfluence = 0.4 })
	local wispPart = ctx.part(v3(2.4, 0.4, 0.4), CFrame.new(1.0, 1.4, -0.9), hex("#ffffff"), { Transparency = 1 })
	local wisps = ctx.emitter(wispPart, { Texture = S.SMOKE, Color = ColorSequence.new(hex("#ffc89a"), hex("#9fb6dc")), Size = NumberSequence.new({ K(0, 0.2), K(1, 1.6) }), Transparency = NumberSequence.new({ K(0, 0.6), K(1, 1) }), Lifetime = NumberRange.new(2.5, 4), Speed = NumberRange.new(0.7, 1.3), EmissionDirection = Enum.NormalId.Top, SpreadAngle = Vector2.new(14, 14), Acceleration = v3(-0.4, 0.3, 0), LightEmission = 0.3, LightInfluence = 0.3 })
	local burstPart = ctx.part(v3(4, 1, 4), CFrame.new(2.6, 1.6, 1.5), hex("#ffffff"), { Transparency = 1 })
	local burst = ctx.emitter(burstPart, { Texture = S.SMOKE, Color = ColorSequence.new(hex("#e8e4e0"), hex("#8a94a8")), Size = NumberSequence.new({ K(0, 1.6), K(1, 6.5) }), Transparency = NumberSequence.new({ K(0, 0.35), K(1, 1) }), Lifetime = NumberRange.new(1.6, 3), Speed = NumberRange.new(2, 6), SpreadAngle = Vector2.new(70, 70), EmissionDirection = Enum.NormalId.Top, Drag = 1.2, Acceleration = v3(-0.5, 1.2, 0), LightEmission = 0.2, LightInfluence = 0.3 })
	local sparks = ctx.emitter(burstPart, { Texture = S.SPARK, Color = ColorSequence.new(hex("#ffe58f"), hex("#ff6a2a")), Size = NumberSequence.new(0.26, 0), Transparency = NumberSequence.new(0, 1), Lifetime = NumberRange.new(0.8, 1.9), Speed = NumberRange.new(4, 11), SpreadAngle = Vector2.new(60, 60), EmissionDirection = Enum.NormalId.Top, Acceleration = v3(-0.6, -3, 0), Drag = 1.1 })
	local pokePart = ctx.part(v3(0.3, 0.3, 0.3), CFrame.new(-0.2, 0.8, -0.3), hex("#ffffff"), { Transparency = 1 })
	local pokeSparks = ctx.emitter(pokePart, { Texture = S.SPARK, Color = ColorSequence.new(hex("#ffe58f"), hex("#ff6a2a")), Size = NumberSequence.new(0.2, 0), Transparency = NumberSequence.new(0, 1), Lifetime = NumberRange.new(0.5, 1.2), Speed = NumberRange.new(3, 8), SpreadAngle = Vector2.new(40, 40), EmissionDirection = Enum.NormalId.Back, Acceleration = v3(0, -6, 0), Drag = 1.4 })
	local mothPart = ctx.part(v3(2.2, 1.6, 2.2), CFrame.new(-1.3, 1.6, -2.7), hex("#ffffff"), { Transparency = 1 })
	local moths = ctx.emitter(mothPart, { Texture = S.GLOW, Color = ColorSequence.new(hex("#fff0c8")), Size = NumberSequence.new({ K(0, 0), K(0.2, 0.16), K(0.5, 0.07), K(0.8, 0.17), K(1, 0) }), Transparency = NumberSequence.new(0.1), Lifetime = NumberRange.new(2.5, 4), Speed = NumberRange.new(0.6, 1.6), SpreadAngle = Vector2.new(180, 180), Drag = 0.5, Brightness = 2 })
	local mistPart = ctx.part(v3(300, 2, 150), CFrame.new(0, -24, 120), hex("#ffffff"), { Transparency = 1 })
	local mist = ctx.emitter(mistPart, { Texture = S.SMOKE, Color = ColorSequence.new(hex("#dfe6ee")), Size = NumberSequence.new({ K(0, 34), K(1, 60) }), Transparency = NumberSequence.new({ K(0, 1), K(0.25, 0.82), K(0.75, 0.86), K(1, 1) }), Lifetime = NumberRange.new(9, 13), Speed = NumberRange.new(0.4, 1.4), SpreadAngle = Vector2.new(180, 8), LightEmission = 0.08, LightInfluence = 1 })
	local nearMistPart = ctx.part(v3(70, 1, 30), CFrame.new(0, -3, 34), hex("#ffffff"), { Transparency = 1 })
	local nearMist = ctx.emitter(nearMistPart, { Texture = S.SMOKE, Color = ColorSequence.new(hex("#cfd8e4")), Size = NumberSequence.new({ K(0, 8), K(1, 16) }), Transparency = NumberSequence.new({ K(0, 1), K(0.3, 0.9), K(0.7, 0.92), K(1, 1) }), Lifetime = NumberRange.new(6, 9), Speed = NumberRange.new(0.3, 1), SpreadAngle = Vector2.new(180, 8), LightEmission = 0.05, LightInfluence = 1 })
	local rainPart = ctx.part(v3(70, 1, 50), CFrame.new(0, 30, 4), hex("#ffffff"), { Transparency = 1 })
	local drizzle = ctx.emitter(rainPart, { Texture = IMG.rain, Color = ColorSequence.new(hex("#cfe0f2")), Size = NumberSequence.new(0.4), Squash = NumberSequence.new(2.6), Transparency = NumberSequence.new(0.62), Lifetime = NumberRange.new(0.55, 0.65), Speed = NumberRange.new(52, 62), EmissionDirection = Enum.NormalId.Bottom, Orientation = Enum.ParticleOrientation.VelocityParallel, Rotation = NumberRange.new(90) })
	local steamPart = ctx.part(v3(0.2, 0.2, 0.2), CFrame.new(-3.4, 2.4, -1.9), hex("#ffffff"), { Transparency = 1 })
	local steam = ctx.emitter(steamPart, { Texture = S.SMOKE, Color = ColorSequence.new(hex("#f4f0ea")), Size = NumberSequence.new({ K(0, 0.12), K(1, 0.8) }), Transparency = NumberSequence.new({ K(0, 0.6), K(1, 1) }), Lifetime = NumberRange.new(0.8, 1.4), Speed = NumberRange.new(0.8, 1.5), EmissionDirection = Enum.NormalId.Top, SpreadAngle = Vector2.new(12, 12), LightEmission = 0.3, LightInfluence = 0.3 })
	local popPart = ctx.part(v3(0.2, 0.2, 0.2), CFrame.new(0, -60, 0), hex("#ffffff"), { Transparency = 1 })
	local pop = ctx.emitter(popPart, { Texture = S.SMOKE, Color = ColorSequence.new(hex("#3a363d")), Size = NumberSequence.new({ K(0, 0.3), K(1, 1.1) }), Transparency = NumberSequence.new({ K(0, 0.3), K(1, 1) }), Lifetime = NumberRange.new(0.35, 0.6), Speed = NumberRange.new(1, 3), SpreadAngle = Vector2.new(180, 180), LightEmission = 0, LightInfluence = 0.5 })
	local sparkle = ctx.emitter(popPart, { Texture = S.SPARK, Color = ColorSequence.new(hex("#ffffff"), hex("#ffb45a")), Size = NumberSequence.new({ K(0, 0), K(0.3, 0.6), K(1, 0) }), Transparency = NumberSequence.new(0, 1), Lifetime = NumberRange.new(0.4, 0.8), Speed = NumberRange.new(2, 6), SpreadAngle = Vector2.new(180, 180), Rotation = NumberRange.new(0, 360), Drag = 2 })
	local heroPart = ctx.part(v3(0.3, 0.3, 0.3), CFrame.new(0.4, 5.6, -4.2), hex("#ffffff"), { Transparency = 1 })
	local rays = Instance.new("BillboardGui")
	rays.Size, rays.LightInfluence, rays.Brightness, rays.Parent = UDim2.fromScale(13, 13), 0, 1.4, heroPart
	local raysIm = Instance.new("ImageLabel")
	raysIm.BackgroundTransparency, raysIm.Image, raysIm.ImageColor3, raysIm.ImageTransparency, raysIm.Size, raysIm.Parent = 1, IMG.rays, hex("#ffd9a8"), 1, UDim2.fromScale(1, 1), rays
	local heroSpark = ctx.emitter(heroPart, { Texture = S.SPARK, Color = ColorSequence.new(hex("#ffffff"), hex("#ffb45a")), Size = NumberSequence.new({ K(0, 0), K(0.3, 0.6), K(1, 0) }), Transparency = NumberSequence.new(0, 1), Lifetime = NumberRange.new(0.8, 1.6), Speed = NumberRange.new(2, 7), SpreadAngle = Vector2.new(180, 180), Rotation = NumberRange.new(0, 360), Drag = 1.5 })
	local ashPuff = ctx.emitter(heroPart, { Texture = S.SMOKE, Color = ColorSequence.new(hex("#b8b4b0")), Size = NumberSequence.new({ K(0, 0.4), K(1, 2.4) }), Transparency = NumberSequence.new({ K(0, 0.3), K(1, 1) }), Lifetime = NumberRange.new(0.8, 1.5), Speed = NumberRange.new(3, 7), SpreadAngle = Vector2.new(28, 28), EmissionDirection = Enum.NormalId.Front, Drag = 2.2, LightEmission = 0.1, LightInfluence = 0.6 })

	-- ===== the badger's acting. In every pose table a positive first angle on Head and Body means "lean forward, look down" =====
	local REST = {}
	for _, b in { "Hips", "Body", "Head", "ArmL", "ArmR", "ForeL", "ForeR", "LegL", "LegR", "Tail1", "Tail2", "EarL", "EarR" } do REST[b] = CFrame.new() end
	local SIT = { LegL = R(76, 0, 10), LegR = R(68, 0, -14), Tail1 = R(-20, 0, 0) }
	local CARRY = { ArmL = R(34, 0, 30), ForeL = R(62, 0, 0), ArmR = R(34, 0, -30), ForeR = R(62, 0, 0), Body = R(-6, 0, 0), Head = R(4, 0, 0) }
	local bornKeys = {
		{ 1.0, { ArmL = R(60, 0, 10), ForeL = R(20, 0, 0), ArmR = R(60, 0, -10), ForeR = R(20, 0, 0), Body = R(16, 0, 0), Head = R(10, 0, 0) } },
		{ 1.3, { ArmL = R(70, 0, 6), ForeL = R(30, 0, 0), ArmR = R(70, 0, -6), ForeR = R(30, 0, 0), Body = R(10, 0, 0), Head = R(6, 0, 0) }, "inout" },
	}
	local PATS = { 1.5, 1.75, 2.0 }
	for _, at in PATS do
		table.insert(bornKeys, { at - 0.1, { ArmL = R(112, 0, 10), ForeL = R(40, 0, 0), ArmR = R(112, 0, -10), ForeR = R(40, 0, 0), Body = R(4, 0, 0), Head = R(0, 0, 0) }, "out" })
		table.insert(bornKeys, { at, { ArmL = R(64, 0, 6), ForeL = R(10, 0, 0), ArmR = R(64, 0, -6), ForeR = R(10, 0, 0), Body = R(20, 0, 0), Head = R(12, 0, 0) }, "in" })
		table.insert(bornKeys, { at + 0.08, { ArmL = R(70, 0, 6), ForeL = R(16, 0, 0), ArmR = R(70, 0, -6), ForeR = R(16, 0, 0), Body = R(16, 0, 0) }, "back" })
	end
	table.insert(bornKeys, { 2.3, { ArmL = R(10, 0, 14), ForeL = R(20, 0, 0), ArmR = R(10, 0, -14), ForeR = R(20, 0, 0), Body = R(-4, 0, 0), Head = R(-6, 0, 0) }, "inout" })
	table.insert(bornKeys, { 2.6, { ArmR = R(130, 0, 30), ForeR = R(96, 0, 0), Head = R(-10, 0, 8) }, "inout" })
	table.insert(bornKeys, { 2.85, { ArmR = R(126, 0, 10), ForeR = R(100, 0, 0) }, "inout" })
	local born = S.track(bornKeys)
	-- night one: he sits, nods off, jerks awake
	local night1 = S.track({
		{ 3.0, { ArmL = R(30, 0, 30), ForeL = R(60, 0, 0), ArmR = R(30, 0, -30), ForeR = R(60, 0, 0), Head = R(4, 0, 0), Body = R(6, 0, 0) } },
		{ 3.5, { Head = R(8, 4, 0), Body = R(8, 0, 0) }, "inout" },
		{ 3.95, { Head = R(40, 6, 8), Body = R(16, 0, 0) }, "in" },
		{ 4.03, { Head = R(-14, 0, 0), Body = R(-4, 0, 0), ArmL = R(50, 0, 10), ArmR = R(50, 0, -10) }, "out" },
		{ 4.2, { Head = R(4, -10, 0), Body = R(4, 0, 0), ArmL = R(30, 0, 30), ArmR = R(30, 0, -30) }, "back" },
	})
	-- night two: he pokes a vent, then pours tea
	local poke = S.track({
		{ 4.3, { ArmR = R(60, 0, -10), ForeR = R(40, 0, 0), ArmL = R(10, 0, 16), ForeL = R(30, 0, 0), Body = R(8, 0, 0), Head = R(10, 0, 0) } },
		{ 4.62, { ArmR = R(30, 0, -20), ForeR = R(80, 0, 0), Body = R(0, 0, 0), Head = R(6, 0, 0) }, "out" },
		{ 4.72, { ArmR = R(84, 0, -4), ForeR = R(10, 0, 0), Body = R(18, 0, 0), Head = R(14, 0, 0) }, "in" },
		{ 4.9, { ArmR = R(70, 0, -8), ForeR = R(24, 0, 0), Body = R(12, 0, 0) }, "back" },
		{ 5.05, { ArmR = R(40, 0, -14), ForeR = R(50, 0, 0), Body = R(4, 0, 0), Head = R(-4, 0, 0) }, "inout" },
	})
	local tea = S.track({
		{ 5.1, { ArmR = R(50, 0, -10), ForeR = R(60, 0, 0), ArmL = R(40, 0, 24), ForeL = R(66, 0, 0), Head = R(12, 10, 0), Body = R(6, 0, 0) } },
		{ 5.3, { ArmR = R(64, 0, 6), ForeR = R(50, 0, 0), Head = R(16, 12, 0) }, "inout" },
		{ 5.5, { ArmR = R(50, 0, -10), ForeR = R(60, 0, 0), ArmL = R(60, 0, 10), ForeL = R(90, 0, 0), Head = R(-4, 0, 0) }, "inout" },
	})
	-- night three: drizzle and fog, he is hunched and falls asleep again
	local night3 = S.track({
		{ 5.6, { ArmL = R(34, 0, 36), ForeL = R(70, 0, 0), ArmR = R(34, 0, -36), ForeR = R(70, 0, 0), Head = R(14, 0, 0), Body = R(14, 0, 0) } },
		{ 6.0, { Head = R(42, -6, -8), Body = R(20, 0, 0) }, "inout" },
		{ 6.3, { Head = R(46, -6, -8), Body = R(22, 0, 0) }, "inout" },
		{ 6.36, { Head = R(-12, 0, 0), Body = R(-2, 0, 0) }, "out" },
		{ 6.48, { Head = R(2, 14, 0), Body = R(4, 0, 0) }, "back" },
	})
	-- the third dawn: he hooks the turf, heaves it off, throws both paws up, bends to look at what hopped out
	local rake = S.track({
		{ 6.5, { ArmR = R(80, 0, -6), ForeR = R(10, 0, 0), ArmL = R(70, 0, 10), ForeL = R(20, 0, 0), Body = R(14, 0, 0), Head = R(8, 0, 0) } },
		{ 6.78, { ArmR = R(90, 0, -4), ForeR = R(6, 0, 0), ArmL = R(84, 0, 6), ForeL = R(10, 0, 0), Body = R(22, 0, 0) }, "inout" },
		{ 6.92, { ArmR = R(30, 0, -16), ForeR = R(90, 0, 0), ArmL = R(30, 0, 16), ForeL = R(80, 0, 0), Body = R(-10, 0, 0), Head = R(-6, 0, 0) }, "in" },
		{ 7.1, { ArmR = R(150, 0, 24), ForeR = R(30, 0, 0), ArmL = R(150, 0, -24), ForeL = R(30, 0, 0), Body = R(-8, 0, 0), Head = R(-14, 0, 0) }, "back" },
		{ 7.4, { ArmR = R(40, 0, -20), ForeR = R(50, 0, 0), ArmL = R(40, 0, 20), ForeL = R(50, 0, 0), Body = R(10, 0, 0), Head = R(16, 0, 0) }, "inout" },
	})
	-- NAMED: he holds it to his chest, breathes in, blows the ash off, lifts it
	local named = S.track({
		{ 7.6, { ArmL = R(40, 0, 20), ForeL = R(40, 0, 0), ArmR = R(40, 0, -20), ForeR = R(40, 0, 0), Head = R(10, 0, 0), Body = R(8, 0, 0) } },
		{ 8.12, { ArmL = R(52, 0, 18), ForeL = R(60, 0, 0), ArmR = R(52, 0, -18), ForeR = R(60, 0, 0), Head = R(-14, 0, 0), Body = R(-8, 0, 0) }, "inout" },
		{ 8.4, { Head = R(22, 0, 0), Body = R(14, 0, 0) }, "in" },
		{ 8.75, { Head = R(8, 0, 0), Body = R(6, 0, 0) }, "back" },
		{ 9.3, { ArmL = R(60, 0, -56), ForeL = R(70, 0, 0), ArmR = R(166, 0, 14), ForeR = R(6, 0, 0), Head = R(-18, -12, 8), Body = R(-13, -8, 5) }, "back" },
		{ 10.2, { ArmR = R(160, 0, 20), Head = R(-22, -6, 6) }, "inout" },
	})
	local function lean(p) -- about the X axis "forward" is a negative turn for a model that faces -Z: flipped here, once
		for _, b in { "Head", "Body" } do
			local cf = p[b]
			if cf then local x, y, z = cf:ToEulerAnglesXYZ() p[b] = CFrame.Angles(-x, y, z) end
		end
		return p
	end

	-- ===== lighting looks: dusk, night (almost dark), the foggy small hours, the pale cold dawn =====
	local LOOK = {
		dusk = { Ambient = rgb(96, 84, 110), OutdoorAmbient = rgb(110, 96, 122), Brightness = 1.5, ColorShift_Top = rgb(255, 170, 120), ExposureCompensation = 0.1 },
		night = { Ambient = rgb(58, 70, 104), OutdoorAmbient = rgb(66, 80, 116), Brightness = 2.4, ColorShift_Top = rgb(150, 180, 255), ExposureCompensation = 0.1 },
		fog = { Ambient = rgb(78, 86, 104), OutdoorAmbient = rgb(84, 92, 112), Brightness = 1.5, ColorShift_Top = rgb(170, 185, 210), ExposureCompensation = 0.12 },
		dawn = { Ambient = rgb(150, 140, 146), OutdoorAmbient = rgb(160, 150, 152), Brightness = 2.2, ColorShift_Top = rgb(255, 214, 180), ExposureCompensation = 0 },
	}
	local ATMO = {
		dusk = { Density = 0.34, Haze = 2.2, Color = rgb(150, 146, 178), Decay = rgb(210, 140, 120), Glare = 0.1, Offset = 0.2 },
		night = { Density = 0.38, Haze = 2.3, Color = rgb(70, 96, 136), Decay = rgb(30, 44, 74), Glare = 0, Offset = 0.15 },
		fog = { Density = 0.52, Haze = 3.0, Color = rgb(120, 132, 150), Decay = rgb(70, 80, 98), Glare = 0, Offset = 0.3 },
		dawn = { Density = 0.36, Haze = 2.4, Color = rgb(236, 214, 200), Decay = rgb(170, 160, 170), Glare = 0.15, Offset = 0.3 },
	}
	local function mix(a, b, u)
		local out = {}
		for k, v in a do
			local w = b[k]
			if typeof(v) == "Color3" then out[k] = v:Lerp(w, u) else out[k] = v + (w - v) * u end
		end
		return out
	end
	local skyNow
	local function sky(name) if skyNow ~= name then skyNow = name ctx.sky(IMG[name]) end end
	-- the key light: the last sun low over the valley at dusk, the moon high over the valley at night, the first light at dawn
	local KEYS = { V(0.45, 0.3, 0.84), V(-0.25, 0.6, 0.76), V(-0.3, 0.24, 0.92) }
	local keyNow = 0
	local function key(i) if keyNow ~= i then keyNow = i ctx.key(KEYS[i]) end end

	local SND = { fire = 129781180188795, dawn = 85010698086137 }
	local fireS = ctx.sound(SND.fire, 0, 0.8, true)
	local NIGHTS = { { 3.0, 4.3 }, { 4.3, 5.6 }, { 5.6, 6.5 } }
	local VENT = V(-0.1, 0.75, -0.16) -- the vent he pokes (stage space)
	local phaseNow = -1

	return function(t, dt)
		local fog = smooth(5.6, 5.8, t) * (1 - smooth(6.4, 6.6, t))
		local dawn = smooth(6.45, 6.8, t)
		local open = t >= 6.92 -- the mound is raked open
		local lit = smooth(2.25, 2.7, t) -- the stack is alight under the turf

		-- ===== lighting and the painted sky =====
		local pulse = math.exp(-((t - 4.3) / 0.07) ^ 2) + math.exp(-((t - 5.6) / 0.07) ^ 2) -- a day goes by between two nights
		if t < 3.0 then
			key(1) sky("dusk")
			ctx.light(mix(LOOK.dusk, LOOK.night, 0.5 * smooth(1.4, 3.0, t)))
			ctx.atmo(mix(ATMO.dusk, ATMO.night, 0.4 * smooth(1.4, 3.0, t)))
		elseif t < 6.5 then
			key(2) sky("night")
			ctx.light(mix(mix(LOOK.night, LOOK.fog, fog), LOOK.dawn, math.min(0.6 * pulse, 0.6)))
			ctx.atmo(mix(ATMO.night, ATMO.fog, fog))
		else
			key(3) sky("dawn")
			ctx.light(mix(LOOK.fog, LOOK.dawn, dawn))
			ctx.atmo(mix(ATMO.fog, ATMO.dawn, dawn))
		end
		ctx.cc.TintColor = rgb(255, 232, 226):Lerp(rgb(214, 224, 255), smooth(2.9, 3.1, t)):Lerp(rgb(255, 246, 236), dawn)
		ctx.cc.Saturation, ctx.cc.Contrast = 0.05 - 0.15 * fog, 0.12
		-- a slow night breath in the grass, a little more in the drizzle
		local blow = 0.05 + 0.08 * fog
		for _, w in windBones do
			local ph = w[3]
			local along = (math.sin(t * 1.3 + ph) * 0.6 + math.sin(t * 3.1 + ph * 1.9) * 0.25) * blow
			local across = math.sin(t * 1.1 + ph * 0.7) * blow * 0.35
			w[1].Transform = CFrame.new(w[2] * (O.Rotation * Vector3.new(along, 0, across)))
		end

		-- the moon crosses the valley once a night; on the third night it is a blur behind the fog
		local mu, mi = -1, 0
		for i, n in NIGHTS do if t >= n[1] and t < n[2] then mu, mi = (t - n[1]) / (n[2] - n[1]), i end end
		if mu >= 0 then
			moon.CFrame = W(140 - 280 * mu, 130 + 70 * math.sin(mu * math.pi), 300)
			local edge = math.min(smooth(0, 0.08, mu), 1 - smooth(0.92, 1, mu))
			moon.Transparency = 1 - edge * (mi == 3 and 0.45 or 1)
			moonIm.ImageTransparency = 1 - edge * (mi == 3 and 0.3 or 0.55)
		else
			moon.CFrame = W(0, -400, 0)
			moon.Transparency, moonIm.ImageTransparency = 1, 1
		end

		-- the lantern flickers; the vents breathe; once the mound is open the whole heap glows
		local flick = 0.9 + 0.1 * math.sin(t * 17) * math.sin(t * 7.3)
		lamp.Brightness = 2.4 * flick * (1 - 0.5 * dawn)
		lampIm.ImageTransparency = 0.45 + 0.1 * math.sin(t * 13) + 0.3 * dawn
		set:size("Flame", Vector3.new(0.9 + 0.1 * math.sin(t * 13), 0.9 + 0.2 * flick, 0.9))
		local breath = 0.6 + 0.4 * math.sin(t * 3.4)
		ventLight.Brightness = open and (1.6 + 0.3 * breath) * (1 - 0.4 * smooth(7.6, 9, t)) or 1.1 * lit * breath
		ventLight.Range = open and 16 or 13
		set:show("Vents", lit > 0.02 and not open)
		set:size("Vents", Vector3.new(1, 1, 1) * (0.86 + 0.2 * breath))
		set:size("HearthGlow", 0.8 + 0.3 * breath)
		set:size("Embers", 0.85 + 0.25 * breath)

		-- ===== the mound: three rings of logs, the turf laid over them, and on the third dawn the charcoal =====
		local r2, r3 = back((t - 0.45) / 0.25), back((t - 1.0) / 0.25)
		local turf = smooth(1.25, 2.0, t)
		set:show("Ring1", not open) set:show("Ring2", not open and r2 > 0.01) set:show("Ring3", not open and r3 > 0.01)
		set:size("Ring2", math.max(r2, 0.001)) set:size("Ring3", math.max(r3, 0.001))
		local pat = 0
		for _, at in PATS do pat = math.max(pat, 1 - math.abs(t - at - 0.02) / 0.09) end
		set:show("Turf", turf > 0.01 and not open)
		set:size("Turf", Vector3.new(0.7 + 0.3 * turf + 0.012 * pat, math.max(turf, 0.001) * (1 - 0.02 * pat), 0.7 + 0.3 * turf + 0.012 * pat))
		local spill = back((t - 6.92) / 0.3)
		set:show("Coal", open) set:show("Embers", open) set:show("Sods", open)
		if open then
			set:size("Coal", Vector3.new(1, 0.6 + 0.4 * spill, 1))
			set:size("Sods", Vector3.new(0.8 + 0.2 * spill, 1, 0.8 + 0.2 * spill))
		end

		-- ===== smoke and weather =====
		smoke.Rate = open and 2 or 7 * lit
		wisps.Rate = open and 5 or 4 * lit
		moths.Rate = (t >= 3.0 and t < 6.5) and 4 * (1 - fog) or 0
		mist.Rate = 3 + 2 * fog
		nearMist.Rate = 1 + 5 * fog + 2 * dawn
		drizzle.Rate = 700 * fog
		once("mist0", 0, t, function() mist:Emit(22) nearMist:Emit(4) end)
		if t >= 7.6 then ctx.once("mistNamed", 7.6, t, function() mist:Emit(22) nearMist:Emit(8) end) end
		fireS.Volume = 0.3 * lit * (1 - 0.6 * smooth(7.6, 9, t))

		-- ===== the badger =====
		local phase = t < 1.0 and 0 or (t < 2.2 and 1 or (t < 3.0 and 2 or (t < 4.3 and 3 or (t < 5.1 and 4 or (t < 5.6 and 5 or (t < 6.5 and 6 or (t < 7.6 and 7 or 8)))))))
		badger:pose(REST)
		local shut = (t % 2.3) < 0.07
		if phase == 0 then -- he carries the last log from the cordwood to the ring
			local u = smooth(0.05, 0.95, t)
			local p = V(-5.2, 0, -0.6):Lerp(WORKP, u)
			local stride = math.sin(t * 15)
			badger.root = W(p.X, math.abs(stride) * 0.1 * (u < 1 and 1 or 0), p.Z) * R(0, -98, 0)
			badger:pose(lean({ ArmL = CARRY.ArmL, ForeL = CARRY.ForeL, ArmR = CARRY.ArmR, ForeR = CARRY.ForeR, Body = CARRY.Body, Head = CARRY.Head }))
			badger:set("LegL", R(26 * stride, 0, 0)) badger:set("LegR", R(-26 * stride, 0, 0))
			badger:set("Hips", R(0, 0, 3 * stride))
		elseif phase <= 2 then -- he sets it down, pats the turf flat, straightens his back and wipes his brow
			badger.root = W(WORKP.X, 0, WORKP.Z) * R(0, -98 + 52 * smooth(2.2, 2.55, t), 0)
			badger:pose(lean(born(t)))
		elseif phase == 3 then
			badger.root = O * STOOL
			badger:pose(SIT) badger:pose(lean(night1(t)))
			shut = t >= 3.6 and t < 4.0
		elseif phase == 4 then
			badger.root = W(WORKP.X, 0, WORKP.Z) * R(0, -80, 0)
			badger:pose(lean(poke(t)))
		elseif phase == 5 then
			badger.root = O * STOOL
			badger:pose(SIT) badger:pose(lean(tea(t)))
		elseif phase == 6 then
			badger.root = O * STOOL
			badger:pose(SIT) badger:pose(lean(night3(t)))
			shut = t >= 5.85 and t < 6.33
		elseif phase == 7 then
			badger.root = W(WORKP.X, 0, WORKP.Z) * R(0, -84 + 40 * smooth(7.0, 7.3, t), 0)
			badger:pose(lean(rake(t)))
			if t >= 7.0 and t < 7.25 then shut = true end
		else
			local hop = math.max(0, math.sin((t - 9.0) / 0.42 * math.pi)) * ((t >= 9.0 and t < 9.42) and 0.5 or 0)
			badger.root = W(0.4, hop, -4.2) * R(0, -14, 0)
			badger:pose(lean(named(t)))
			shut = t >= 9.5 and t < 10.9
		end
		local breathe = math.sin(t * 2.6) * 0.012
		badger:size("Body", Vector3.new(1 + breathe, 1 - breathe, 1 + breathe))
		badger:set("EarL", R(0, 0, math.sin(t * 3.1) * 4 + ((t % 1.7) < 0.14 and 9 or 0)))
		badger:set("EarR", R(0, 0, -math.sin(t * 3.1 + 1) * 4 - ((t % 2.1) < 0.14 and 9 or 0)))
		badger:set("Tail2", R(0, math.sin(t * 2.2) * 12, 0))
		badger:show("Eyes", not shut) badger:show("EyesShut", shut)
		if phase ~= phaseNow then
			if phase >= 3 or phaseNow < 0 then badger:snap() end -- a camera cut: no easing across it
			phaseNow = phase
		end
		local jolt = (t >= 3.95 and t < 4.1) or (t >= 6.3 and t < 6.45) or (t >= 4.62 and t < 4.8) or (t >= 6.78 and t < 7.0)
		badger:smooth(dt, jolt and 30 or 12)
		badger:update()
		local handR = (badger:joint("ForeR") * CFrame.new(0.11, -0.5, -0.2)).Position
		local handL = (badger:joint("ForeL") * CFrame.new(-0.11, -0.5, -0.2)).Position

		-- ===== what he holds =====
		if phase == 0 and t < 0.98 then
			log.root = badger:joint("Body") * CFrame.new(0, 0.5, -0.95)
		else
			log.root = W(0, -60, 0)
		end
		log:update()
		once("logDown", 1.0, t, function() sfx("land", 0.9) ctx.kick(1.2) end)
		once("ring2", 0.45, t, function() sfx("tab", 0.8) end)
		for i, at in PATS do once("pat" .. i, at, t, function() sfx("land", 1.1 + i * 0.08) ctx.kick(0.8) end) end
		once("alight", 2.3, t, function() wisps:Emit(6) sfx("swing", 0.6) end)

		if phase == 4 then -- the poker: from his paw to the vent, drawn back and thrust in
			local slide = -0.9 * smooth(4.45, 4.62, t) + 1.5 * smooth(4.62, 4.72, t) - 0.5 * smooth(4.8, 5.05, t)
			poker.root = CFrame.lookAt(handR, O:PointToWorldSpace(VENT)) * CFrame.Angles(-math.pi / 2, 0, 0) * CFrame.new(0, slide - 1.5, 0)
			once("poke", 4.72, t, function() pokeSparks:Emit(26) wisps:Emit(5) sfx("breakRock", 1.5) ctx.kick(1.6) ctx.hold(2 / 60) end)
		elseif phase == 7 and t < 6.95 then -- hooked over the turf, then heaved back
			local pull = smooth(6.78, 6.92, t)
			poker.root = CFrame.lookAt(handR, O:PointToWorldSpace(V(0.25, 2.2 - 0.9 * pull, 0.65 - 1.0 * pull))) * CFrame.Angles(-math.pi / 2, 0, 0) * CFrame.new(0, -1.8, 0)
		elseif phase >= 7 then
			poker.root = W(-2.2, 0.06, 1.3) * R(0, 30, 88) -- dropped in the grass
		else
			poker.root = POKER_REST
		end
		poker:update()

		local hold = phase == 5 and smooth(5.1, 5.2, t) * (1 - smooth(5.5, 5.6, t)) or 0
		local tilt = 40 * smooth(5.18, 5.3, t) * (1 - smooth(5.42, 5.52, t))
		kettle.root = KETTLE_REST:Lerp(CFrame.new(handR + Vector3.new(0, 0.15, 0)) * O.Rotation * R(0, 0, tilt) * CFrame.new(0, -1.26, 0), phase == 5 and 1 or 0)
		cup.root = CUP_REST:Lerp(CFrame.new(handL + Vector3.new(0, 0.05, 0)) * O.Rotation, phase == 5 and 1 or 0)
		kettle:update() cup:update()
		steamPart.CFrame = phase == 5 and CFrame.new(cup.root.Position + Vector3.new(0, 0.4, 0)) or CFrame.new(KETTLE_REST.Position + Vector3.new(-0.9, 0.9, 0))
		steam.Rate = phase == 5 and 14 * hold or ((t >= 3.0 and t < 6.5) and 3 or 0)
		once("pour", 5.2, t, function() sfx("tab", 1.4) end)

		-- ===== the opening: sparks when the turf is pulled back, then the soot puffs hop out =====
		once("open", 6.92, t, function() burst:Emit(26) sparks:Emit(70) sfx("breakRock", 0.7) sfx("swing", 0.6) ctx.shake(0.6) ctx.kick(3) ctx.hold(3 / 60) end)
		sparks.Rate = open and t < 7.6 and 8 or 0
		local START = V(2.0, 1.5, 0.6)
		for i, pf in puffs do
			local r = pf.r
			if t < pf.t0 or t >= pf.gone or t >= 7.6 then
				r.root = W(0, -60, 0)
			else
				local u = math.clamp((t - pf.t0) / 0.3, 0, 1)
				local p = START:Lerp(pf.land, u) + Vector3.new(0, math.sin(u * math.pi) * 1.7, 0)
				if u >= 1 then p += Vector3.new(0, math.abs(math.sin((t - pf.t0 - 0.3) * 11 + i)) * 0.4, 0) end
				if i == 5 and t >= 7.26 then -- the one that stays hops up onto the pickaxe
					local h = smooth(7.26, 7.46, t)
					p = pf.land:Lerp(PICK_LIE.Position + Vector3.new(0, 0.25, -0.3), h) + Vector3.new(0, math.sin(h * math.pi) * 1.3, 0)
				end
				local sq = u < 1 and 0 or math.abs(math.sin((t - pf.t0 - 0.3) * 11 + i))
				r.root = W(p.X, p.Y, p.Z) * R(0, math.sin(t * 9 + i * 2) * 20, math.sin(t * 13 + i) * 8)
				r:size("Body", Vector3.new(1.12 - 0.12 * sq, 0.86 + 0.14 * sq, 1.12 - 0.12 * sq))
				r:show("Eyes", ((t + i * 0.37) % 0.9) > 0.07)
			end
			r:update()
			once("puffOut" .. i, pf.t0, t, function() sfx("pop", 1.0 + i * 0.12) end)
			once("puffGone" .. i, pf.gone, t, function()
				local at = i == 5 and (PICK_LIE.Position + Vector3.new(0, 0.25, -0.3)) or pf.land + Vector3.new(0, 0.4, 0)
				popPart.CFrame = W(at.X, at.Y, at.Z)
				if i == 5 then sparkle:Emit(22) sfx("coin", 1.3) sfx("pop", 1.6) ctx.hold(2 / 60) ctx.kick(1.5) else pop:Emit(6) sfx("pop", 1.3 + i * 0.1) end
			end)
		end

		-- ===== the pickaxe: found in the charcoal, then NAMED =====
		if t < 6.95 then
			placePick(CFrame.new(0, -60, 0), 2.9)
		elseif t < 7.6 then
			local pop1 = 1 + 0.16 * math.max(0, 1 - math.abs(t - 7.5) / 0.1)
			placePick(PICK_LIE * R(0, 180, 78), 2.9 * (0.5 + 0.5 * back((t - 6.95) / 0.3)) * pop1)
		else
			local chest = (badger:joint("ForeL").Position + badger:joint("ForeR").Position) / 2
			local lift = smooth(8.85, 9.5, t)
			local hands = chest:Lerp(handR, lift)
			local at = O:PointToObjectSpace(hands) + Vector3.new(0.3 * lift, 0.5 + 0.9 * lift + math.sin(t * 2) * 0.12 * lift, -0.35 - 0.1 * lift)
			local spin = smooth(9.0, 10.3, t) * 360
			placePick(CFrame.new(at) * R(0, 180 + spin, 78 - 98 * smooth(8.8, 9.2, t)), 2.9 + 0.7 * lift)
			heroPart.CFrame = W(at.X, at.Y + 0.4, at.Z)
			raysIm.ImageTransparency = 1 - 0.75 * smooth(9.2, 9.55, t) * (1 - smooth(10.6, 11.1, t))
			raysIm.Rotation = t * 22
			ctx.once("blow", 8.4, t, function() ashPuff:Emit(34) sfx("swing", 0.5) ctx.kick(1.4) end)
			ctx.once("reveal", 9.25, t, function() heroSpark:Emit(46) ctx.sound(SND.dawn, 0.6, 1) sfx("sparkle", 1.3) ctx.kick(5) ctx.hold(4 / 60) end)
			heroSpark.Rate = t >= 9.4 and 10 or 0
			ctx.name("Three nights, no sleep.")
			ctx.cardAlpha = smooth(9.6, 9.95, t) * (1 - smooth(10.8, 11.1, t))
		end

		-- ===== chapters and camera =====
		if t >= 0.35 and t < 3.0 then ctx.chapter(1, "BORN", "Oak logs, stacked in a ring and buried under turf.")
		elseif t >= 3.2 and t < 7.6 then ctx.chapter(2, "MADE", "A badger watched the mound for three nights.")
		elseif t >= 7.8 then ctx.chapter(3, "NAMED", "On the third dawn he blew the ash off.") end
		local cf, fov, focus
		local function shot(from, aim, f) cf, fov, focus = CFrame.lookAt(from, aim), f, (from - aim).Magnitude end
		if t < 1.2 then -- the clearing at dusk: the oaks, the half-built stack, the valley behind
			local u = smooth(0, 1.2, t)
			shot(V(-8 + 3 * u, 5.6 - 1.6 * u, -23 + 5 * u), V(1.2, 2.6, 6), 50 - 4 * u)
		elseif t < 3.0 then -- the turf goes on; the first smoke
			shot(V(-5.2, 2.7, -9.6 + 0.8 * smooth(1.2, 3.0, t)), V(1.4, 2.2, 0.9), 44)
		elseif t < 3.62 then -- night one, low and wide: the moon starts across the valley
			shot(V(-6.2, 1.5, -14.5 + 0.6 * smooth(3.0, 3.62, t)), V(0.6, 4.6, 5), 55)
		elseif t < 4.3 then -- his face in the lantern light: he nods off
			shot(V(-4.6 + 0.2 * smooth(3.62, 4.3, t), 2.9, -9.6), V(-2.2, 2.5, -1.3), 40)
		elseif t < 4.55 then -- night two
			shot(V(-5.8, 1.5, -14.2), V(0.6, 4.6, 5), 55)
		elseif t < 5.1 then -- the poke
			shot(V(-2.6, 1.9, -7.6 + 0.4 * smooth(4.55, 5.1, t)), V(-0.2, 1.5, -0.1), 40)
		elseif t < 5.6 then -- tea
			shot(V(-4.9, 2.8, -9.4), V(-2.3, 2.3, -1.5), 40)
		elseif t < 6.5 then -- night three in the drizzle: a slow push
			local u = smooth(5.6, 6.5, t)
			shot(V(-4.4 + 0.4 * u, 2.3, -10.8 + 0.8 * u), V(-0.8, 2.3, 0.6), 46)
		elseif t < 7.18 then -- the third dawn: he rakes it open
			shot(V(-4.4, 2.6, -9.8 + 0.6 * smooth(6.5, 7.18, t)), V(1.0, 1.9, 0.6), 44)
		elseif t < 7.6 then -- close on the charcoal: the pickaxe, and the puff that stays
			shot(V(-2.2, 2.7, -6.4 + 0.3 * smooth(7.18, 7.6, t)), V(1.1, 1.4, 0.2), 42)
		else -- low at his feet, looking up: the pickaxe against the pale sky
			local s = smooth(8.4, 10.8, t)
			shot(V(1.9 - 0.3 * s, 0.8, -12.4 + 0.8 * s), V(0.4, 2.5, -4.2):Lerp(V(0.4, 4.1, -4.2), smooth(8.9, 9.6, t)), 56 - 2 * s)
		end
		ctx.cam, ctx.fov = O * cf, fov
		ctx.dof.FocusDistance = focus
		ctx.dof.InFocusRadius, ctx.dof.FarIntensity, ctx.dof.NearIntensity = 400, 0, 0 -- no blur anywhere (the owner, 2026-11-15)
	end
end

return M
