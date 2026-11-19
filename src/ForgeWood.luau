-- ReplicatedStorage.Shared.ForgeWood (src/ForgeWood.luau): the Wood Pickaxe biography, played by ForgeStory.
-- BORN: a birch branch, dropped by a spring storm. MADE: whittled by a young raccoon (Bolt as a kit) in one long night; an acorn
-- falls on his head and becomes the charm. NAMED: sunrise, he holds it up. "His first."
-- Nothing here is shared with another scene: the lake, the storm, the whittling and the sunrise belong to this pickaxe.
-- The setting is a place of its own (the owner, 2026-11-15; reference refs/forge/scene_cabin_lake.jpg): a mountain lake at the
-- edge of a spruce forest, the maker's cabin lit on the far bank, wildflower meadows, two forested slopes crossing behind.
-- It is built once per play from design3d/wood.mjs and wood_world.py (terrain, pictures, the map of every tree in ForgeWoodMap).
-- The lake reflects: every tall thing has an upside-down twin under a clear water sheet, and the sky pictures carry the
-- mirrored sky in their lower half. Space: front of a model is -Z, the camera stands at -Z and looks toward the lake at +Z.
-- Pace (the owner, 2026-11-15: "too fast"): the story's own clock runs at 0.58 of real time, so the whole biography takes
-- about 19 s and the short level-up version about 5 s. Every time in this file is a story second.
local M = { length = 11.2, named = 7.6, open = true, pace = 0.58, fastPace = 0.75 }
-- pictures made by design3d/wood_world.py (uploaded 2026-11-15; ids in design3d/assets.json)
local IMG = {
	storm = { side = "80840484137760", up = "102725166168479", dn = "88932717958951" },
	night = { side = "98540000433096", up = "102757336864746", dn = "100178533145001" },
	dawn = { side = "73285214976026", up = "92565812712365", dn = "75186259090239", sun = 9 },
	ripple = "rbxassetid://108008922454214", rain = "rbxassetid://80922659043708",
}

local function hex(h) return Color3.fromHex(h) end
local function v3(x, y, z) return Vector3.new(x, y, z) end

function M.setup(ctx)
	local S = ctx.S
	local R, smooth, lin, step, backOut = S.rot, S.smooth, S.lin, S.step, S.backOut
	local O, sfx = ctx.O, ctx.sfx
	local function W(x, y, z) return O * CFrame.new(x, y, z) end -- stage space to world

	local K = NumberSequenceKeypoint.new
	local rgb = Color3.fromRGB
	-- the place: ground and mountains, then every tree, flower patch, rock and the cabin from the map
	local MAP = require(script.Parent:WaitForChild("ForgeWoodMap"))
	local land = ctx.prop("WoodWorld")
	land:all(function(p, b) if b.name == "MeadowM" or b.name == "ValleyM" then p.CastShadow = false end end)
	local cabinCF, cabinS = CFrame.new(-20, -1.6, 92), 1
	local glints = {} -- the lights of the far bank lying long on the water, toward the camp
	local SMALL = { PineClump = true, FlowerPatch = true, FlowerPatch2 = true, Fern = true, Mushroom = true }
	for _, it in MAP.items do
		local cf = CFrame.new(it[2], it[3], it[4]) * CFrame.Angles(0, math.rad(it[5]), 0)
		local r = ctx.prop(it[1], cf, it[6], it[7] and MAP.lakeY or nil)
		if it[1] == "Cabin" then cabinCF, cabinS = cf, it[6] end
		if it[1] == "Dock" then
			local lamp = (cf * CFrame.new(-0.7 * it[6], 3.2 * it[6], -11.2 * it[6])).Position
			local lp = ctx.part(v3(0.2, 0.2, 0.2), CFrame.new(lamp), hex("#ffb44a"), { Transparency = 1 })
			local l = Instance.new("PointLight")
			l.Color, l.Range, l.Brightness, l.Shadows, l.Parent = hex("#ffb060"), 26, 2.4, false, lp
			table.insert(glints, { lamp, 0.8 })
		end
		local small = SMALL[it[1]]
		r:all(function(p) -- matte: the kit's smooth plastic shone like vinyl under this place's lighting (Gemini round 8)
			if p.Material ~= Enum.Material.Neon then p.Material = Enum.Material.Rubber end
			if small then p.CastShadow = false end
		end)
	end
	land:all(function(p) p.Material = Enum.Material.Rubber end)
	-- the grass is fully modelled (the owner, 2026-11-15): about 14,000 clumps baked into 14 meshes that follow the ground
	-- (design3d/wood_grass.py; 240,000 triangles, measured cost in the vault brief). Ring A is the camp, B and C the meadow and
	-- the banks. A low graphics level, or a phone, takes fewer rings and the painted ground shows beyond them.
	local level = 0
	pcall(function() level = UserSettings():GetService("UserGameSettings").SavedQualityLevel.Value end)
	local phone = game:GetService("UserInputService").TouchEnabled and not game:GetService("UserInputService").KeyboardEnabled
	local rings = (level ~= 0 and level <= 3) and { "WoodGrassA" } or ((phone or (level ~= 0 and level <= 6)) and { "WoodGrassA", "WoodGrassB" } or { "WoodGrassA", "WoodGrassB", "WoodGrassC" })
	if ctx.opt.noGrass then rings = {} end -- test hook: the frame cost is measured with and without it
	local windBones = {} -- { bone, its rest rotation turned back (stage wind to bone space), phase }: four in every grass mesh
	for _, n in rings do
		for _, d in ctx.asset(n):GetDescendants() do
			if d:IsA("MeshPart") then
				d.Material, d.CastShadow = Enum.Material.Rubber, false
			elseif d:IsA("Bone") and string.find(d.Name, "_W%d") then
				table.insert(windBones, { d, d.WorldCFrame.Rotation:Inverse(), #windBones * 1.37 })
			end
		end
	end
	-- the lake: a clear dark sheet over the mirror world, with slow glints drifting on it
	local water = ctx.part(v3(170, 0.2, 100), CFrame.new(12, MAP.lakeY - 0.1, 56), hex("#1b3436"), { Transparency = 0.5, Reflectance = 0.1 })
	local ripple = Instance.new("Texture")
	ripple.Texture, ripple.Face, ripple.StudsPerTileU, ripple.StudsPerTileV, ripple.Transparency, ripple.Parent = IMG.ripple, Enum.NormalId.Top, 52, 30, 0.8, water
	for _, w in { { -2.75, 2.9 }, { 2.75, 2.9 }, { -2.3, 5.9 }, { 2.3, 5.9 }, { 4.5, 3.6 } } do -- the cabin's windows throw warm light on its porch and bank
		local lp = ctx.part(v3(0.2, 0.2, 0.2), cabinCF * CFrame.new(-w[1] * cabinS, w[2] * cabinS, -5.2 * cabinS), hex("#ffb44a"), { Transparency = 1 })
		local l = Instance.new("PointLight")
		l.Color, l.Range, l.Brightness, l.Shadows, l.Parent = hex("#ffb060"), 44, 4, false, lp
		table.insert(glints, { lp.Position - O.Position, 1.6 })
	end
	-- each light draws a broken path of gold across the lake toward the camp (the reference's long reflections)
	local glintParts = {}
	for gi, g in glints do
		local from = Vector3.new(g[1].X, MAP.lakeY + 0.06, g[1].Z)
		local dir = (Vector3.new(0, from.Y, 0) - from).Unit
		local right = dir:Cross(Vector3.yAxis)
		do -- first one long soft bar of light straight under the window, as a still lake gives
			local at = from + dir * 15
			local p = ctx.part(v3(g[2] * 1.5, 0.04, 14), CFrame.lookAt(at, at + dir), hex("#ffb850"), { Material = Enum.Material.Neon, Transparency = 0.45 })
			table.insert(glintParts, { p, gi * 0.7, 0.3 })
		end
		for k = 1, 16 do -- many thin strokes, each a little off the line and shorter than the gap: light broken by ripples
			local at = from + dir * (21 + k * 2.4) + right * math.sin(k * 2.7 + gi * 1.3) * (0.25 + k * 0.03)
			local p = ctx.part(v3(g[2] * (0.75 - k * 0.025) * (0.7 + 0.5 * math.abs(math.sin(k * 1.9 + gi))), 0.04, 1.2 + 0.9 * math.abs(math.sin(k * 3.3 + gi))), CFrame.lookAt(at, at + dir), hex("#ffb850"), { Material = Enum.Material.Neon, Transparency = 0.6 })
			table.insert(glintParts, { p, k + gi * 1.7 })
		end
	end
	local smokePart = ctx.part(v3(0.6, 0.6, 0.6), cabinCF * CFrame.new(-2.0 * cabinS, 15.4 * cabinS, 1.4 * cabinS), hex("#ffffff"), { Transparency = 1 })
	local smoke = ctx.emitter(smokePart, { Texture = S.SMOKE, Color = ColorSequence.new(hex("#cfc8d6")), Size = NumberSequence.new({ K(0, 1.1), K(1, 6.5) }), Transparency = NumberSequence.new({ K(0, 0.5), K(1, 1) }), Lifetime = NumberRange.new(6, 9), Speed = NumberRange.new(2.4, 3.4), EmissionDirection = Enum.NormalId.Top, SpreadAngle = Vector2.new(7, 7), Acceleration = v3(1.4, 0.3, 0), LightEmission = 0, LightInfluence = 1, Rate = 5 })
	smoke:Emit(8)
	local mistPart = ctx.part(v3(120, 1, 56), CFrame.new(12, MAP.lakeY + 1.4, 56), hex("#ffffff"), { Transparency = 1 })
	local mist = ctx.emitter(mistPart, { Texture = S.SMOKE, Color = ColorSequence.new(hex("#dfe6ee")), Size = NumberSequence.new({ K(0, 9), K(1, 17) }), Transparency = NumberSequence.new({ K(0, 1), K(0.25, 0.88), K(0.75, 0.9), K(1, 1) }), Lifetime = NumberRange.new(6, 9), Speed = NumberRange.new(0.3, 1.1), SpreadAngle = Vector2.new(180, 8), LightEmission = 0.05, LightInfluence = 1 })
	-- the storm: slanting rain as streaks (the streak picture is drawn upright: turned a quarter so its length lies along the fall), splashes on the grass and rings on the lake
	local rainPart = ctx.part(v3(96, 1, 76), CFrame.new(0, 36, 8), hex("#ffffff"), { Transparency = 1 })
	local rainFx = ctx.emitter(rainPart, { Texture = IMG.rain, Color = ColorSequence.new(hex("#cfe0f2")), Size = NumberSequence.new(0.6), Squash = NumberSequence.new(3.4), Transparency = NumberSequence.new(0.4), Lifetime = NumberRange.new(0.44, 0.52), Speed = NumberRange.new(78, 94), EmissionDirection = Enum.NormalId.Bottom, Orientation = Enum.ParticleOrientation.VelocityParallel, Rotation = NumberRange.new(90), Acceleration = v3(24, 0, 0), LightEmission = 0.3, LightInfluence = 0.5, SpreadAngle = Vector2.new(2, 2) })
	local splashPart = ctx.part(v3(64, 0.2, 46), CFrame.new(0, 0.12, 2), hex("#ffffff"), { Transparency = 1 })
	local splash = ctx.emitter(splashPart, { Texture = S.GLOW, Color = ColorSequence.new(hex("#e4eef8")), Size = NumberSequence.new({ K(0, 0.08), K(1, 0.46) }), Transparency = NumberSequence.new({ K(0, 0.4), K(1, 1) }), Lifetime = NumberRange.new(0.16, 0.3), Speed = NumberRange.new(1.5, 4.5), SpreadAngle = Vector2.new(55, 55), EmissionDirection = Enum.NormalId.Top, Acceleration = v3(0, -22, 0), LightEmission = 0.4 })
	local ringPart = ctx.part(v3(110, 0.2, 52), CFrame.new(12, MAP.lakeY + 0.05, 56), hex("#ffffff"), { Transparency = 1 })
	local rings = ctx.emitter(ringPart, { Texture = S.GLOW, Color = ColorSequence.new(hex("#c8dcec")), Size = NumberSequence.new({ K(0, 0.1), K(1, 1.5) }), Transparency = NumberSequence.new({ K(0, 0.55), K(1, 1) }), Lifetime = NumberRange.new(0.3, 0.5), Speed = NumberRange.new(0, 0.2), Orientation = Enum.ParticleOrientation.VelocityPerpendicular, EmissionDirection = Enum.NormalId.Top, LightEmission = 0.3 })
	local flyPart = ctx.part(v3(50, 4, 32), CFrame.new(0, 2.8, 8), hex("#ffffff"), { Transparency = 1 })
	local flies = ctx.emitter(flyPart, { Texture = S.GLOW, Color = ColorSequence.new(hex("#e8ff9c")), Size = NumberSequence.new({ K(0, 0), K(0.2, 0.3), K(0.5, 0.1), K(0.8, 0.32), K(1, 0) }), Transparency = NumberSequence.new(0.05), Lifetime = NumberRange.new(3, 5), Speed = NumberRange.new(0.4, 1.3), SpreadAngle = Vector2.new(180, 180), Drag = 0.4, Brightness = 2.5 })
	local skyBolt = ctx.rig("Lightning", CFrame.new(50, 200, 330) * R(0, 180, 0), 16)
	skyBolt:show("Bolt", false)
	local sunRays = ctx.effect("SunRaysEffect", { Intensity = 0, Spread = 0.9 })

	local set = ctx.rig("WoodSet")
	-- the camp's three birches (models from the CC0 nature kit, with a white bark painted for them): their crowns are bones, so the storm shakes them
	local birches = {
		ctx.rig("KitBirch1", CFrame.new(6.4, 0, 4.2) * R(0, 40, 0)),
		ctx.rig("KitBirch2", CFrame.new(11.2, 0, 8.6) * R(0, 170, 0)),
		ctx.rig("KitBirch3", CFrame.new(13.4, 0, 0.6) * R(0, -70, 0)),
	}
	set:all(function(p) if p.Material ~= Enum.Material.Neon then p.Material = Enum.Material.Rubber end end)
	local bolt = ctx.rig("BoltKit", CFrame.new(-2.5, 0.56, -2.3) * R(0, -18, 0))
	bolt:all(function(p) p.Material = Enum.Material.Rubber end) -- fur, not vinyl
	local branch = ctx.rig("BirchBranch", CFrame.new(5.2, 6.4, 3.4))
	local blank = ctx.rig("WoodBlank", CFrame.new(0, -50, 0), 0.42)
	local knife = ctx.rig("Knife", CFrame.new(0, -50, 0), 1.25)
	local acorn = ctx.rig("Acorn", CFrame.new(0, -50, 0), 0.85)
	local pick = ctx.pick()
	local pickScale0, pickH = 1, 5
	if pick then pickScale0, pickH = pick:GetScale(), math.max(pick:GetExtentsSize().Y, 0.1) pick:PivotTo(W(0, -60, 0)) end
	local function placePick(cf, height) -- stage-space frame, wanted height in studs
		if not pick then return end
		pick:ScaleTo(pickScale0 * height / pickH)
		pick:PivotTo(O * cf)
	end

	-- pooled extras: wind leaves, wood shavings
	local leaves = {}
	for i = 1, 18 do leaves[i] = { r = ctx.rig("Leaf", CFrame.new(0, -70, 0), 0.5), ph = (i * 0.37) % 1, y = 2 + (i * 1.9) % 7, z = (i * 2.3) % 9 - 2 } end
	local curls = {}
	for i = 1, 12 do curls[i] = { r = ctx.rig("Shaving", CFrame.new(0, -70, 0), 0.7), t0 = -1, from = Vector3.zero, vel = Vector3.zero, spin = 0 } end
	local curlN = 0
	local function tossCurl(from, t)
		curlN = curlN % #curls + 1
		local c = curls[curlN]
		local a = curlN * 2.4
		c.t0, c.from, c.vel, c.spin = t, from, v3(2.2 + math.cos(a) * 1.6, 5.5 + (curlN % 3), -2.6 + math.sin(a) * 1.4), 300 + curlN * 40
	end

	-- lights and emitters
	local firePart = ctx.part(v3(0.4, 0.4, 0.4), CFrame.new(0.6, 1.0, -3.0), hex("#ffb14a"), { Transparency = 1 })
	local fireLightPart = ctx.part(v3(0.4, 0.4, 0.4), CFrame.new(0.4, 2.4, -5.2), hex("#ffb14a"), { Transparency = 1 })
	local fireLight = Instance.new("PointLight")
	fireLight.Color, fireLight.Range, fireLight.Brightness, fireLight.Shadows, fireLight.Parent = hex("#ff9c50"), 24, 0, true, fireLightPart -- a little toward the camera and above the flames, so his face takes the light and the grass by the fire is not burnt white
	local fireGlow = Instance.new("BillboardGui")
	fireGlow.Size, fireGlow.LightInfluence, fireGlow.Brightness, fireGlow.Parent = UDim2.fromScale(7, 7), 0, 1, firePart
	local fireGlowIm = Instance.new("ImageLabel")
	fireGlowIm.BackgroundTransparency, fireGlowIm.Image, fireGlowIm.ImageColor3, fireGlowIm.ImageTransparency, fireGlowIm.Size, fireGlowIm.Parent = 1, S.GLOW, hex("#ff9a4a"), 1, UDim2.fromScale(1, 1), fireGlow
	local embers = ctx.emitter(firePart, { Texture = S.SPARK, Color = ColorSequence.new(hex("#ffe58f"), hex("#ff7d4a")), Size = NumberSequence.new(0.22, 0), Transparency = NumberSequence.new(0, 1), Lifetime = NumberRange.new(1, 2.2), Speed = NumberRange.new(1.5, 3.5), SpreadAngle = Vector2.new(18, 18), Acceleration = v3(0.6, 1.5, 0), EmissionDirection = Enum.NormalId.Top })
	local fireFx = ctx.emitter(firePart, { Texture = S.FIRE, Color = ColorSequence.new(hex("#ffd070"), hex("#f2701c")), Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.9), NumberSequenceKeypoint.new(1, 0.1) }), Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 1) }), Lifetime = NumberRange.new(0.4, 0.7), Speed = NumberRange.new(1.5, 3), SpreadAngle = Vector2.new(12, 12), EmissionDirection = Enum.NormalId.Top, LightEmission = 0.7 })
	local workPart = ctx.part(v3(0.3, 0.3, 0.3), CFrame.new(-2.2, 2.0, -3.2), hex("#ffffff"), { Transparency = 1 })
	local dust = ctx.emitter(workPart, { Texture = S.SMOKE, Color = ColorSequence.new(hex("#f7e9c8")), Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1.5) }), Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 1) }), Lifetime = NumberRange.new(0.5, 0.9), Speed = NumberRange.new(2, 5), SpreadAngle = Vector2.new(35, 35), LightEmission = 0.2, EmissionDirection = Enum.NormalId.Front, Drag = 3 })
	local chips = ctx.emitter(workPart, { Texture = S.SPARK, Color = ColorSequence.new(hex("#fff3d0"), hex("#f0d7a8")), Size = NumberSequence.new(0.28, 0), Transparency = NumberSequence.new(0, 1), Lifetime = NumberRange.new(0.3, 0.6), Speed = NumberRange.new(5, 11), SpreadAngle = Vector2.new(60, 60), Acceleration = v3(0, -30, 0), LightEmission = 0.4 })
	local ribbon = ctx.emitter(workPart, { Texture = S.GLOW, Color = ColorSequence.new(hex("#9fe3c4"), hex("#d8f5e6")), Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.9), NumberSequenceKeypoint.new(1, 0) }), Transparency = NumberSequence.new(0.1, 1), Lifetime = NumberRange.new(0.45, 0.7), Speed = NumberRange.new(0, 0.4), LightEmission = 0.6 })
	local sparkle = ctx.emitter(workPart, { Texture = S.SPARK, Color = ColorSequence.new(hex("#ffffff"), hex("#ffe6a8")), Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.3, 0.7), NumberSequenceKeypoint.new(1, 0) }), Transparency = NumberSequence.new(0, 1), Lifetime = NumberRange.new(0.6, 1.2), Speed = NumberRange.new(3, 9), SpreadAngle = Vector2.new(180, 180), Rotation = NumberRange.new(0, 360), Drag = 2 })
	local heroPart = ctx.part(v3(0.3, 0.3, 0.3), CFrame.new(-7.0, 5.6, -5.0), hex("#ffffff"), { Transparency = 1 })
	local rays = Instance.new("BillboardGui")
	rays.Size, rays.LightInfluence, rays.Brightness, rays.Parent = UDim2.fromScale(13, 13), 0, 1.4, heroPart
	local raysIm = Instance.new("ImageLabel")
	raysIm.BackgroundTransparency, raysIm.Image, raysIm.ImageColor3, raysIm.ImageTransparency, raysIm.Size, raysIm.Parent = 1, "rbxassetid://98789616938156", hex("#ffe6a8"), 1, UDim2.fromScale(1, 1), rays
	local heroSpark = ctx.emitter(heroPart, { Texture = S.SPARK, Color = ColorSequence.new(hex("#ffffff"), hex("#9fe3c4")), Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.3, 0.6), NumberSequenceKeypoint.new(1, 0) }), Transparency = NumberSequence.new(0, 1), Lifetime = NumberRange.new(0.8, 1.6), Speed = NumberRange.new(2, 7), SpreadAngle = Vector2.new(180, 180), Rotation = NumberRange.new(0, 360), Drag = 1.5 })

	-- the raccoon's acting. Seated base, then five whittling strokes that speed up; the knife arm is the right one.
	local SIT = { LegL = R(74, 0, 10), LegR = R(62, 0, -16), Tail1 = R(-25, 0, 0), Tail2 = R(-20, 0, 0) }
	local HOLD = { ArmL = R(24, 0, 24), ForeL = R(52, 0, 0), ArmR = R(22, 0, -20), ForeR = R(56, 0, 0) }
	local STROKES = { 3.75, 4.2, 4.62, 5.0, 5.34 }
	local keys = { { 3.0, { ArmR = HOLD.ArmR, ForeR = HOLD.ForeR, ArmL = HOLD.ArmL, ForeL = HOLD.ForeL, Head = R(20, 8, -7), Body = R(14, 10, 3) } } }
	for i, at in STROKES do
		table.insert(keys, { at - 0.17, { ArmR = R(-6, 0, -30), ForeR = R(100, 0, 0), Head = R(12, -8, 4), Body = R(8, 6, 0) }, "out" }) -- anticipation: knife drawn back
		table.insert(keys, { at, { ArmR = R(48, 0, -6), ForeR = R(18, 0, 0), Head = R(26, 8, -8), Body = R(20, 12, 4) }, "in" }) -- the cut
		table.insert(keys, { at + 0.12, { ArmR = R(40, 0, -10), ForeR = R(30, 0, 0), Head = R(20, 6, -6), Body = R(15, 10, 3) }, "back" }) -- settle
	end
	table.insert(keys, { 5.55, { ArmR = R(14, 0, -30), ForeR = R(60, 0, 0), Head = R(14, 0, 0), Body = R(8, 0, 0) }, "inout" }) -- lean in to blow the dust
	table.insert(keys, { 5.72, { Head = R(18, 0, 0), Body = R(11, 0, 0) }, "out" })
	table.insert(keys, { 5.95, { Head = R(8, 0, 0), Body = R(4, 0, 0), ArmL = R(30, 0, 30), ForeL = R(58, 0, 0) }, "back" })
	table.insert(keys, { 6.25, { ArmR = R(34, 0, -34), ForeR = R(66, 0, 0), ArmL = R(34, 0, 36), ForeL = R(66, 0, 0), Head = R(12, -10, 6) }, "inout" }) -- tying the ribbon: paws together
	table.insert(keys, { 6.62, { Head = R(12, -10, 6), Body = R(4, 0, 0) }, "hold" })
	table.insert(keys, { 6.66, { Head = R(16, 0, 0), Body = R(10, 0, 0), ArmL = R(150, 0, -36), ForeL = R(70, 0, 0), ArmR = R(150, 0, 36), ForeR = R(70, 0, 0) }, "out" }) -- bonk: he flinches, paws over his head
	table.insert(keys, { 6.9, { Head = R(-26, 14, 0), Body = R(-6, 0, 0), ArmL = R(120, 0, -20), ForeL = R(40, 0, 0), ArmR = R(30, 0, -26), ForeR = R(60, 0, 0) }, "back" }) -- looks up, catches the acorn in his left paw
	table.insert(keys, { 7.18, { Head = R(-8, 26, 8), ArmL = R(96, 0, -6), ForeL = R(60, 0, 0) }, "inout" }) -- holds it up and looks at it
	table.insert(keys, { 7.42, { Head = R(14, 6, -6), Body = R(8, 0, 0), ArmL = R(34, 0, 34), ForeL = R(62, 0, 0) }, "back" }) -- ties it on
	local act = S.track(keys)
	-- NAMED: he stands on the grass and lifts it over his head
	local named = S.track({
		{ 7.6, { LegL = R(0, 0, 0), LegR = R(0, 0, 0), ArmL = R(40, 0, 20), ForeL = R(40, 0, 0), ArmR = R(40, 0, -20), ForeR = R(40, 0, 0), Head = R(6, 0, 0), Body = R(8, 0, 0), Tail1 = R(0, 0, 0), Tail2 = R(0, 0, 0) } },
		{ 8.15, { ArmL = R(20, 0, 10), ForeL = R(70, 0, 0), ArmR = R(20, 0, -10), ForeR = R(70, 0, 0), Head = R(10, 0, 0), Body = R(12, 0, 0), LegL = R(-18, 0, 0), LegR = R(-18, 0, 0) }, "inout" }, -- crouch: anticipation
		{ 8.45, { ArmL = R(120, 0, -30), ForeL = R(30, 0, 0), ArmR = R(170, 0, 10), ForeR = R(6, 0, 0), Head = R(-22, -10, 8), Body = R(-16, -8, 5), LegL = R(-10, 0, 10), LegR = R(14, 0, -8) }, "back" }, -- up it goes, one paw
		{ 9.4, { ArmL = R(60, 0, -56), ForeL = R(70, 0, 0), ArmR = R(166, 0, 14), Head = R(-18, -12, 8), Body = R(-13, -8, 5) }, "inout" }, -- the free paw on his hip
		{ 10.2, { ArmR = R(160, 0, 20), Head = R(-22, -6, 6) }, "inout" },
	})

	-- In the pose tables a positive first angle on Head and Body means "lean forward, look down". About the X axis that is a
	-- negative turn for a model that faces -Z, so the sign is flipped here, once, for every pose.
	local function lean(p)
		for _, b in { "Head", "Body" } do
			local cf = p[b]
			if cf then local x, y, z = cf:ToEulerAnglesXYZ() p[b] = CFrame.Angles(-x, y, z) end
		end
		return p
	end
	-- lighting looks: storm, fire night, dawn
	local LOOK = {
		storm = { Ambient = rgb(120, 130, 142), OutdoorAmbient = rgb(128, 138, 150), Brightness = 1.6, ColorShift_Top = rgb(190, 205, 225), ExposureCompensation = 0.15 },
		night = { Ambient = rgb(58, 72, 104), OutdoorAmbient = rgb(66, 82, 116), Brightness = 2.5, ColorShift_Top = rgb(160, 188, 255), ExposureCompensation = 0.2 },
		dawn = { Ambient = rgb(168, 140, 140), OutdoorAmbient = rgb(178, 150, 146), Brightness = 2.7, ColorShift_Top = rgb(255, 196, 140), ExposureCompensation = 0 },
	}
	-- the air between the layers: thick and grey in the storm, blue at night, gold at sunrise
	local ATMO = {
		storm = { Density = 0.4, Haze = 2.6, Color = rgb(150, 162, 170), Decay = rgb(96, 108, 118), Glare = 0, Offset = 0.2 },
		night = { Density = 0.38, Haze = 2.3, Color = rgb(84, 112, 150), Decay = rgb(40, 58, 90), Glare = 0, Offset = 0.15 },
		dawn = { Density = 0.3, Haze = 2.1, Color = rgb(255, 206, 160), Decay = rgb(196, 140, 130), Glare = 0.2, Offset = 0.25 },
	}
	local function air(a, b, u)
		local out = {}
		for k, v in a do
			local w = b[k]
			if typeof(v) == "Color3" then out[k] = v:Lerp(w, u) else out[k] = v + (w - v) * u end
		end
		ctx.atmo(out)
	end
	local skyNow
	local function sky(name) if skyNow ~= name then skyNow = name ctx.sky(IMG[name]) end end
	local function look(a, b, u)
		local out = {}
		for k, v in a do
			local w = b[k]
			if typeof(v) == "Color3" then out[k] = v:Lerp(w, u) else out[k] = v + (w - v) * u end
		end
		ctx.light(out)
	end
	-- the key light per chapter: flat and high in the storm; the moon over the far bank at night (long shadows toward the
	-- camera, the fire lights his face); at dawn the sun itself, low in the gap between the two slopes
	local KEYS = { Vector3.new(-0.3, 0.85, -0.3), Vector3.new(0.5, 0.52, 0.68), Vector3.new(0.14, 0.2, 0.97) }
	local keyNow = 0
	local function key(i) if keyNow ~= i then keyNow = i ctx.key(KEYS[i]) end end
	bolt:show("EyesShut", false)
	branch.root = W(5.2, 6.4, 3.4) * R(0, 20, -12)

	-- this scene's own sounds (audio/pd_forge_sfx.py, synthesised): ids of the uploaded files in audio/sfx/forge
	local SND = { thunder = 82890618685891, rain = 71766947362966, fire = 129781180188795, whittle = 96959952635114, bonk = 101020483687867, dawn = 85010698086137 }
	local rainS = ctx.sound(SND.rain, 0, 1, true)
	local fireS = ctx.sound(SND.fire, 0, 1, true)
	local hitT = -1 -- time of the last stroke that landed
	local stage = 0 -- 0 branch, 1 blank, 2 pickaxe
	local function workCF() return bolt:joint("Body") * CFrame.new(0, 0.42, -1.1) end -- in front of his chest, over his lap

	return function(t, dt)
		-- the owner, 2026-11-15: "too cartoonish and not fluid enough". The characters no longer step 12 poses a second: they
		-- move at the full frame rate and every joint eases into its pose (Rig:smooth below)
		local ts = t
		local storm = 1 - smooth(2.7, 3.0, t)
		local dawn = smooth(7.6, 9.2, t)

		-- ===== lighting and the paper sky =====
		if t < 3.0 then key(1) sky("storm") look(LOOK.storm, LOOK.night, 0) air(ATMO.storm, ATMO.night, 0)
		elseif t < 7.6 then key(2) sky("night") look(LOOK.night, LOOK.night, 0) air(ATMO.night, ATMO.night, 0)
		else key(3) sky("dawn") look(LOOK.dawn, LOOK.dawn, 0) air(ATMO.dawn, ATMO.dawn, 0) end
		ctx.cc.TintColor = rgb(226, 232, 244):Lerp(rgb(236, 240, 255), smooth(2.9, 3.1, t)):Lerp(rgb(255, 244, 232), dawn)
		ctx.cc.Saturation, ctx.cc.Contrast = (t < 3.0 and -0.22 or 0.1) + 0.12 * dawn, 0.1
		sunRays.Intensity = 0.07 * smooth(7.6, 8.4, t)
		ripple.OffsetStudsU, ripple.OffsetStudsV = t * 1.6, math.sin(t * 0.4) * 2
		-- wind in the grass: every wind bone carries the tips of a share of the blades; gusts roll across the meadow in the
		-- storm (toward screen left, with the rain), a slow breath at night and at dawn
		local blow = 0.05 + 0.42 * storm
		for _, w in windBones do
			local ph = w[3]
			local along = (0.55 * storm + math.sin(t * (1.3 + 2.2 * storm) + ph) * 0.6 + math.sin(t * 3.1 + ph * 1.9) * 0.25) * blow
			local across = math.sin(t * 1.1 + ph * 0.7) * blow * 0.35
			w[1].Transform = CFrame.new(w[2] * (O.Rotation * Vector3.new(along, 0, across)))
		end
		for _, g in glintParts do g[1].Transparency = math.min(1, (g[3] or 0.34) + 0.3 * (0.5 + 0.5 * math.sin(t * 5.2 + g[2] * 1.9)) + 0.3 * dawn + 0.3 * storm) end
		rainFx.Rate, splash.Rate, rings.Rate = 2400 * storm, 420 * storm, 260 * storm
		flies.Rate = (t >= 3.0 and t < 7.6) and 7 or 0
		mist.Rate = t >= 3.0 and 5 or 0
		ctx.once("mistNight", 3.0, t, function() mist:Emit(14) flies:Emit(10) end)
		ctx.once("mistDawn", 7.6, t, function() mist:Emit(22) end)
		-- lightning: two flickers far over the lake, the second one breaks the branch
		local bolt1 = (t >= 0.95 and t < 1.02) or (t >= 1.32 and t < 1.46)
		skyBolt:show("Bolt", bolt1)
		if bolt1 then ctx.light({ Brightness = 4, Ambient = rgb(190, 200, 225) }) end
		ctx.flashAlpha = math.max((t >= 0.95 and t < 1.0) and 0.35 or 0, 0.5 * (1 - lin(1.32, 1.62, t)) * (t >= 1.32 and 1 or 0), 0.55 * (1 - lin(3.0, 3.22, t)) * (t >= 2.94 and 1 or 0) * smooth(2.94, 3.0, t), 0.6 * (1 - lin(8.45, 8.8, t)) * (t >= 8.45 and 1 or 0)) -- peaks softened from 0.85 / 1 / 0.9: the two strikes read as near-white frames (Gemini, 2026-11-19)
		ctx.once("thunder1", 0.95, t, function() ctx.sound(SND.thunder, 0.3, 1.25) end)
		ctx.once("thunder2", 1.32, t, function() ctx.sound(SND.thunder, 0.75, 0.95) sfx("breakRock", 0.5) ctx.shake(1.1) ctx.hold(3 / 60) end)
		rainS.Volume = 0.4 * storm * smooth(0, 0.4, t)

		-- ===== storm: wind in the canopies, rain, leaves =====
		local gust = storm * (0.6 + 0.4 * math.sin(t * 2.3))
		for i = 1, 3 do
			birches[i]:set("Canopy", R(math.sin(t * 5 + i) * 3 * gust, 0, (6 + math.sin(t * 7.3 + i * 2) * 5) * gust + math.sin(t * 1.3 + i) * 0.8))
			birches[i]:set("Trunk", R(0, 0, 1.6 * gust))
		end
		for _, l in leaves do
			local u = (t * 0.55 + l.ph) % 1
			l.r.root = W(-16 + u * 32, l.y + math.sin(u * 9 + l.ph * 6) * 1.2 - u * 1.5, l.z) * R(t * 300 + l.ph * 360, t * 170, 0)
			l.r:all(function(p) p.Transparency = storm > 0.02 and 0 or 1 end)
		end

		-- ===== the branch: hangs, snaps, falls, bounces, then lies in his lap =====
		if t < 1.36 then
			branch.root = W(5.2, 6.4, 3.4) * R(0, 20, -12 + math.sin(t * 6) * 4 * gust)
			branch.scale = 1.5
		elseif t < 3.0 then
			local u = t - 1.36
			local fall = math.min(u / 0.62, 1)
			local y = 6.4 - (6.4 - 0.3) * fall * fall
			local b = u > 0.62 and math.abs(math.sin((u - 0.62) * 9)) * 1.1 * math.exp(-(u - 0.62) * 4.5) or 0
			branch.root = W(5.2 - 4.6 * fall, y + b, 3.4 - 6.6 * fall) * R(fall * 150 * (1 - fall) , 20 + fall * 60, -12 + fall * 384)
			branch.scale = 1.5 - 0.3 * smooth(2.0, 2.3, t)
			ctx.once("snap", 1.36, t, function() workPart.CFrame = W(5.2, 6.4, 3.4) chips:Emit(24) end)
			ctx.once("land", 1.36 + 0.62, t, function() sfx("land", 0.8) sfx("swing", 0.7) ctx.kick(3) ctx.hold(2 / 60) end)
		end

		-- ===== the fire =====
		local fire = smooth(3.0, 3.3, t) * (1 - 0.75 * smooth(8.2, 10, t))
		for i, n in { "Flame1", "Flame2", "Flame3", "FlameCore" } do
			local f = 0.82 + 0.3 * math.abs(math.sin(ts * 11 + i * 1.7))
			set:size(n, Vector3.new(0.9 + 0.1 * math.sin(ts * 13 + i), f, 0.9) * math.max(fire, 0.001))
			set:show(n, fire > 0.01)
			set:set(n, R(0, 0, math.sin(ts * 8 + i * 2) * 5))
		end
		fireLight.Brightness = 2.4 * fire * (0.85 + 0.15 * math.sin(ts * 12))
		fireGlowIm.ImageTransparency = 1 - 0.25 * fire
		embers.Rate = 9 * fire
		fireFx.Rate = 16 * fire
		fireS.Volume = 0.45 * fire

		-- ===== the raccoon =====
		local breathe = math.sin(ts * 2.6) * 0.012
		bolt:size("Body", Vector3.new(1 + breathe, 1 - breathe, 1 + breathe))
		local blink = (ts % 2.3) < 0.1
		local shut = blink or (t >= 6.62 and t < 6.95) or (t >= 8.45)
		bolt:show("Eyes", not shut) bolt:show("EyesShut", shut)
		bolt:set("EarL", R(0, 0, math.sin(ts * 3.1) * 4 + ((ts % 1.7) < 0.14 and 9 or 0)))
		bolt:set("EarR", R(0, 0, -math.sin(ts * 3.1 + 1) * 4 - ((ts % 2.1) < 0.14 and 9 or 0)))
		if t < 2.25 then
			bolt.root = W(0, -60, 0)
		elseif t < 3.0 then -- he heard it fall: up from behind the log, a look, then a hop to the branch
			local up, hop = smooth(2.25, 2.5, t), smooth(2.62, 2.95, t)
			local from, to = Vector3.new(-2.6, -2.4 + 2.7 * backOut(up), -0.9), Vector3.new(-0.6, 0, -2.7)
			bolt.root = W(0, 0, 0) * CFrame.new(from:Lerp(to, hop) + Vector3.new(0, math.sin(hop * math.pi) * 1.5, 0)) * R(0, -22 * (1 - hop) - 34 * hop, 0)
			bolt:pose(lean({ Head = R(-6 + 26 * hop, -24 + 4 * hop, 8 * (1 - hop)), Body = R(30 * hop, 0, 0), ArmL = R(20 + 36 * hop, 0, 10), ForeL = R(30 - 16 * hop, 0, 0), ArmR = R(20 + 52 * hop, 0, -10), ForeR = R(30 - 20 * hop, 0, 0), LegL = R(-20 * math.sin(hop * math.pi), 0, 0), LegR = R(30 * math.sin(hop * math.pi), 0, 0) }))
			bolt:set("EarL", R(0, 0, 14 * (1 - hop))) bolt:set("EarR", R(0, 0, -14 * (1 - hop)))
			ctx.once("peek", 2.3, t, function() sfx("pop", 1.3) end)
		elseif t < 7.6 then
			bolt.root = W(-2.5, 0.56, -2.3) * R(0, -18, 0)
			bolt:pose(SIT)
			bolt:pose(lean(act(ts)))
			bolt:set("Tail1", R(-25, 38 + math.sin(ts * 4) * 14, 0)) bolt:set("Tail2", R(-20, 30 + math.sin(ts * 4 - 0.8) * 18, 0))
			bolt:set("LegL", R(74 + math.sin(ts * 3) * 6, 0, 10)) bolt:set("LegR", R(60 - math.sin(ts * 3) * 8, 0, -16)) -- feet kick while he works
			local bonk = t >= 6.62 and math.max(0, 1 - (t - 6.62) / 0.3) or 0
			bolt:size("Head", Vector3.new(1 + 0.05 * bonk, 1 - 0.09 * bonk, 1 + 0.05 * bonk)) -- a small give, not a rubber squash
		else
			local hop = math.sin(math.clamp((t - 8.3) / 0.45, 0, 1) * math.pi) * 1.2 -- a little jump as he lifts it
			bolt.root = W(-7.0, hop, -5.0) * R(0, -16, 0) -- out from under the birches, the sunrise behind him
			bolt:pose(lean(named(ts)))
			bolt:set("Tail1", R(0, math.sin(ts * 9) * 26, 0)) bolt:set("Tail2", R(0, math.sin(ts * 9 - 0.8) * 30, 0))
			bolt:size("Head", Vector3.one)
		end
		local phase = t < 2.25 and 0 or (t < 3.0 and 1 or (t < 7.6 and 2 or 3))
		if phase ~= bolt.phase then bolt.phase = phase bolt:snap() end -- a camera cut: no easing across it
		local sinceHit = hitT > 0 and t - hitT or 1
		bolt:smooth(dt, sinceHit < 0.1 and 34 or 13) -- crisp on a knife stroke, soft everywhere else
		bolt:update()

		-- ===== the work: strokes, shavings, the three states of the wood =====
		local work = workCF()
		if t >= 3.0 then workPart.CFrame = work end
		for i, at in STROKES do
			ctx.once("stroke" .. i, at, t, function()
				hitT = at
				ctx.sound(SND.whittle, 0.6, 0.9 + i * 0.07) -- each cut a little higher
				ctx.hold(2 / 60) ctx.kick(1.6)
				chips:Emit(10)
				tossCurl(work.Position, at) tossCurl(work.Position + Vector3.new(0.3, 0, 0), at + 0.03)
				if i == 1 then branch:show("Leaves", false) end
				if i == 3 then stage = 1 dust:Emit(14) sfx("pop", 1.2) end
			end)
		end
		ctx.once("blow", 5.72, t, function() dust:Emit(26) sfx("swing", 1.6) end)
		ctx.once("tie", 6.25, t, function() stage = 2 sparkle:Emit(26) sfx("sparkle", 1.2) sfx("pop", 1.4) end)
		ribbon.Rate = (t >= 5.95 and t < 6.3) and 60 or 0
		if t >= 5.95 and t < 6.3 then -- the mint ribbon winds round it: the emitter circles the work
			local a = (t - 5.95) * 26
			workPart.CFrame = work * CFrame.new(math.cos(a) * 1.3, math.sin(a) * 0.5 + (t - 6.1) * 3, math.sin(a) * 0.7)
		end
		for _, c in curls do
			local u = t - c.t0
			if c.t0 > 0 and u >= 0 and u < 1.1 then
				c.r.root = CFrame.new(c.from + c.vel * u + Vector3.new(0, -16 * u * u, 0)) * R(u * c.spin, u * c.spin * 0.7, 0)
				c.r:all(function(p) p.Transparency = math.clamp((u - 0.8) / 0.3, 0, 1) end)
			else
				c.r.root = W(0, -70, 0)
			end
		end
		local jolt = hitT > 0 and math.max(0, 1 - (t - hitT) / 0.12) or 0
		if t >= 3.0 and t < 7.6 then
			local lap = work * CFrame.new(-0.25, -0.1 - 0.1 * jolt, 0.1) * R(0, 0, 18 - 6 * jolt)
			branch.root = stage == 0 and lap * R(0, 180, 0) * CFrame.new(-0.4, 0, 0) or W(0, -60, 0)
			branch.scale = 0.6
			blank.root = stage == 1 and lap * R(-70, 0, 72) * CFrame.new(0, 0.45, 0) or W(0, -60, 0)
			if stage == 2 then
				local pop = backOut(lin(6.25, 6.5, t))
				placePick(O:ToObjectSpace(lap) * CFrame.new(0.15, -0.2, -0.15) * R(0, 180, 78), 2.9 * (0.6 + 0.4 * pop) * (1 + 0.16 * math.max(0, 1 - math.abs(t - 7.5) / 0.1)))
			end
			knife.root = t < 5.9 and bolt:joint("ForeR") * CFrame.new(0.12, -0.62, -0.22) * R(-100, 0, 0) or W(0, -60, 0)
		elseif t >= 7.6 then
			branch.root, blank.root, knife.root = W(0, -60, 0), W(0, -60, 0), W(0, -60, 0)
		end

		-- ===== the acorn: falls, bonks him, hops onto the pickaxe =====
		if t >= 6.2 and t < 7.46 then
			local head = bolt:joint("Head").Position + Vector3.new(0, 1.95, 0)
			local cf
			if t < 6.62 then
				local u = (t - 6.2) / 0.42
				cf = CFrame.new(head + Vector3.new(0, 9 * (1 - u * u), 0)) * R(u * 300, 0, 20)
			elseif t < 6.9 then -- bounces off his head
				local u = (t - 6.62) / 0.28
				cf = CFrame.new(head + Vector3.new(0.5 * u, math.sin(u * math.pi * 0.8) * 2.2, -0.2 * u)) * R(u * 400, u * 200, 0)
			else -- caught: it sits in his left paw, then goes onto the pickaxe
				local paw = (bolt:joint("ForeL") * CFrame.new(-0.11, -0.62, -0.25)).Position
				local air = head + Vector3.new(0.5, math.sin(math.pi * 0.8) * 2.2, -0.2)
				local to = paw:Lerp(work.Position + Vector3.new(0, 0.25, -0.2), smooth(7.22, 7.44, t)) + Vector3.new(0, math.sin(lin(7.22, 7.44, t) * math.pi) * 0.5, 0)
				cf = CFrame.new(air:Lerp(to, smooth(6.9, 6.98, t))) * R(0, t * 90, 10)
			end
			acorn.root = cf
			ctx.once("bonk", 6.62, t, function() ctx.sound(SND.bonk, 0.7, 1) ctx.hold(3 / 60) ctx.kick(2.2) ctx.shake(0.35) end)
		else
			acorn.root = W(0, -60, 0)
			ctx.once("charm", 7.46, t, function() sparkle:Emit(22) sfx("coin", 1.3) sfx("pop", 1.5) ctx.hold(2 / 60) ctx.kick(1.5) end)
		end

		-- ===== NAMED: the lift and the hero turn =====
		if t >= 7.6 then
			local hands = (bolt:joint("ForeR") * CFrame.new(0.11, -0.5, -0.2)).Position:Lerp((bolt:joint("ForeL").Position + bolt:joint("ForeR").Position) / 2, 1 - smooth(8.15, 8.45, t))
			local lift = smooth(8.45, 9.3, t)
			local at = O:PointToObjectSpace(hands) + Vector3.new(0.3 * lift, 0.9 + 0.5 * lift + math.sin(t * 2) * 0.12 * lift, -0.3 * lift)
			local spin = smooth(8.5, 10.0, t) * 360
			placePick(CFrame.new(at) * R(0, 180 + spin, 78 - 98 * smooth(8.2, 8.5, t)), 2.9 + 0.7 * lift)
			heroPart.CFrame = W(at.X, at.Y + 0.6, at.Z)
			raysIm.ImageTransparency = 1 - 0.75 * smooth(8.45, 8.8, t) * (1 - smooth(10.6, 11.1, t))
			raysIm.Rotation = t * 22
			ctx.once("reveal", 8.45, t, function() heroSpark:Emit(46) ctx.sound(SND.dawn, 0.6, 1) sfx("sparkle", 1.3) ctx.kick(5) ctx.hold(4 / 60) end)
			heroSpark.Rate = t >= 8.6 and 10 or 0
			ctx.name("His first.")
			ctx.cardAlpha = smooth(9.0, 9.35, t) * (1 - smooth(10.7, 11.0, t))
		end

		-- ===== chapters and camera =====
		if t >= 0.35 and t < 3.0 then ctx.chapter(1, "BORN", "A birch branch, dropped by a spring storm.")
		elseif t >= 3.2 and t < 7.6 then ctx.chapter(2, "MADE", "Whittled by a young raccoon in one long night.")
		elseif t >= 7.8 then ctx.chapter(3, "NAMED", "Morning. The first pickaxe he ever made.") end
		local cf, fov, focus
		local function shot(from, aim, f) cf, fov, focus = CFrame.lookAt(from, aim), f, (from - aim).Magnitude end
		local V = Vector3.new
		if t < 1.36 then -- the place in the storm: the lake and the slopes behind the birch, then in on the branch the wind pulls at
			local u = smooth(0, 1.3, t)
			shot(V(-9 + 5.5 * u, 7.0 - 2.4 * u, -22 + 11 * u), V(0.5 + 4.4 * u, 3.0 + 3.4 * u, 14 - 10.7 * u), 52 - 10 * u)
		elseif t < 3.0 then -- it snaps: low and wide, the camera follows it down to the grass, where the raccoon finds it
			local bp = O:PointToObjectSpace(branch.root.Position)
			shot(V(-0.8, 0.9, -9.5 + 1.2 * smooth(1.6, 2.8, t)), V(4.6, 6.4, 3.4):Lerp(bp, smooth(1.36, 1.7, t)):Lerp(V(-0.9, 2.1, -2.4), smooth(2.2, 2.6, t)), 52 - 4 * smooth(1.6, 2.8, t))
		elseif t < 3.95 then -- the camp at night: the fire, the raccoon on his log, and behind him the lake with the cabin's lights on it
			shot(V(4.0, 6.6 - 0.8 * smooth(3.0, 3.95, t), -15.0 + 1.4 * smooth(3.0, 3.95, t)), V(-2.8, 1.9, 4), 48)
		elseif t < 5.5 then -- close on his paws for the knife work
			shot(V(-0.5 + 0.3 * smooth(3.62, 5.5, t), 2.8, -8.7), V(-2.75, 2.65, -3.2), 38)
		elseif t < 6.2 then -- front on: he blows the dust off and ties the ribbon
			shot(V(-1.9, 2.5, -8.6 + 0.5 * smooth(5.5, 6.2, t)), V(-2.7, 2.35, -3.0), 40)
		elseif t < 6.62 then -- room above his head: something is falling
			shot(V(-0.4, 1.9, -9.4), V(-2.6, 3.7, -2.6), 46)
		elseif t < 7.22 then -- his face, and the acorn in his paw
			shot(V(-1.3 - 0.2 * smooth(6.62, 7.22, t), 2.9, -7.2), V(-2.7, 2.85, -2.7), 38 - 3 * smooth(6.62, 7.22, t))
		else -- close on the pickaxe in his lap: the acorn is tied on and becomes the charm
			shot(V(-1.2, 2.9, -7.6 + 0.3 * smooth(7.22, 7.6, t)), V(-2.75, 2.55, -3.2), 36)
		end
		if t >= 7.6 then -- low at his feet, looking up: the pickaxe against the sunrise
			local up = smooth(8.3, 9.2, t)
			shot(V(-4.6 - 0.3 * smooth(8.4, 10.8, t), 0.8, -13.0 + 0.8 * smooth(8.4, 10.8, t)), V(-7.0, 2.5, -5.0):Lerp(V(-7.0, 3.6, -5.0), up), 47 - 2 * smooth(8.4, 10.8, t))
		end
		ctx.cam, ctx.fov = O * cf, fov
		ctx.dof.FocusDistance = focus
		ctx.dof.InFocusRadius, ctx.dof.FarIntensity, ctx.dof.NearIntensity = 400, 0, 0 -- no blur anywhere (the owner, 2026-11-15): the place stays sharp behind him
	end
end

return M
