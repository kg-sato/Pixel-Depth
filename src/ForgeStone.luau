-- ReplicatedStorage.Shared.ForgeStone (src/ForgeStone.luau): the Stone Pickaxe biography, played by ForgeStory.
-- BORN: a lilac pebble the river rolled for a hundred years (flood, summer, leaf fall and ice pass over it). MADE: a river
-- otter floats on her back and cracks it on her belly stone, then binds the shard to driftwood with reeds on the gravel bar.
-- NAMED: she holds it up, dripping, in the sun. "Rounded by patience."
-- The setting is a place of its own (references refs/forge/sheets/stone_setting_s11.png and otter_views_s11.png): a shallow
-- river in a canyon of pale layered limestone, gravel bars, alders and reeds, blue hills where the canyon opens.
-- Built from design3d/stone.mjs and stone_world.py (terrain, pictures, the map of every stone and plant in ForgeStoneMap).
-- Space: front of a model is -Z, the camera stands at -Z and looks up the river toward +Z. The action is on the gravel bar at
-- the origin; the water's edge is at x = 1.5 and the river lies toward +X (screen left).
-- Every time in this file is a story second; the clock runs at 0.58 of real time (see ForgeWood).
local M = { length = 11.2, named = 7.6, open = true, pace = 0.58, fastPace = 0.75 }
-- pictures made by design3d/stone_world.py (ids in design3d/assets.json); the ripple and the rain streak are the Wood scene's
local IMG = {
	summer = { side = "123739504725049", up = "81181571686796", dn = "95878689619602", sun = 7 },
	winter = { side = "76400901434536", up = "101637967336868", dn = "105487614033730" },
	ripple = "rbxassetid://108008922454214", rain = "rbxassetid://80922659043708",
}

local function hex(h) return Color3.fromHex(h) end
local function v3(x, y, z) return Vector3.new(x, y, z) end

function M.setup(ctx)
	local S = ctx.S
	local R, smooth, lin, backOut = S.rot, S.smooth, S.lin, S.backOut
	local O, sfx = ctx.O, ctx.sfx
	local function W(x, y, z) return O * CFrame.new(x, y, z) end -- stage space to world
	local K = NumberSequenceKeypoint.new
	local rgb = Color3.fromRGB
	local V = Vector3.new

	-- ===== the place =====
	local MAP = require(script.Parent:WaitForChild("ForgeStoneMap"))
	local WY = MAP.waterY
	local land = ctx.prop("StoneWorld")
	land:all(function(p, b) p.Material = Enum.Material.Rubber if b.name == "Far" then p.CastShadow = false end end)
	local SMALL = { Pebble1 = true, Pebble2 = true, PebblePath = true, WispyGrass = true, GrassTuft = true, FlowerPatch = true, Fern = true, Plant1 = true }
	for _, it in MAP.items do
		local r = ctx.prop(it[1], CFrame.new(it[2], it[3], it[4]) * CFrame.Angles(0, math.rad(it[5]), 0), it[6])
		local small = SMALL[it[1]]
		r:all(function(p)
			if p.Material ~= Enum.Material.Neon then p.Material = Enum.Material.Rubber end
			if small then p.CastShadow = false end
		end)
	end
	-- the fallen alder across the current, up-river of the bar (the reference's fallen tree)
	local fallen = ctx.prop("DeadTree1", CFrame.new(-3, 1.3, 30) * R(0, 20, 82), 1.5)
	fallen:all(function(p) p.Material = Enum.Material.Rubber end)
	-- the river: a clear sheet over the painted bed, the ripple picture sliding down it
	local water = ctx.part(v3(60, 0.2, 330), CFrame.new(10, WY - 0.1, 75), hex("#5fa8a0"), { Transparency = 0.7, Reflectance = 0.12 })
	local ripple = Instance.new("Texture")
	ripple.Texture, ripple.Face, ripple.StudsPerTileU, ripple.StudsPerTileV, ripple.Transparency, ripple.Parent = IMG.ripple, Enum.NormalId.Top, 22, 14, 0.55, water
	local ripple2 = ripple:Clone() -- a second layer the other way: the two cross and the light lines move like real ones
	ripple2.StudsPerTileU, ripple2.StudsPerTileV, ripple2.Transparency, ripple2.Parent = 31, 19, 0.7, water
	local function riverX(z) return 10 + 5 * math.sin(z / 42) end
	local function bedY(x, z) -- the height function of stone_world.py, without its small noise
		local d = math.abs(x - riverX(z)) - 8.5
		if d >= 0 then return 0.2 end
		local bed = WY - 0.75 - 0.5 * smooth(0, 6, -d)
		return (WY - 0.1) + (bed - (WY - 0.1)) * smooth(0, 2.5, -d)
	end
	local sunRays = ctx.effect("SunRaysEffect", { Intensity = 0.05, Spread = 0.8 })

	-- weather for the hundred years: flood rain, sun glints, falling leaves, snow
	local rainPart = ctx.part(v3(70, 1, 60), CFrame.new(4, 30, 10), hex("#ffffff"), { Transparency = 1 })
	local rainFx = ctx.emitter(rainPart, { Texture = IMG.rain, Color = ColorSequence.new(hex("#d6e2ee")), Size = NumberSequence.new(0.55), Squash = NumberSequence.new(3.2), Transparency = NumberSequence.new(0.45), Lifetime = NumberRange.new(0.4, 0.5), Speed = NumberRange.new(70, 84), EmissionDirection = Enum.NormalId.Bottom, Orientation = Enum.ParticleOrientation.VelocityParallel, Rotation = NumberRange.new(90), Acceleration = v3(14, 0, 0), LightEmission = 0.3, LightInfluence = 0.5, SpreadAngle = Vector2.new(2, 2) })
	local surfPart = ctx.part(v3(15, 0.2, 40), CFrame.new(9, WY + 0.05, 12), hex("#ffffff"), { Transparency = 1 })
	local foam = ctx.emitter(surfPart, { Texture = S.SMOKE, Color = ColorSequence.new(hex("#e9efe6")), Size = NumberSequence.new({ K(0, 0.5), K(1, 1.6) }), Transparency = NumberSequence.new({ K(0, 1), K(0.2, 0.5), K(1, 1) }), Lifetime = NumberRange.new(0.7, 1.1), Speed = NumberRange.new(9, 14), EmissionDirection = Enum.NormalId.Front, SpreadAngle = Vector2.new(6, 0), Orientation = Enum.ParticleOrientation.VelocityPerpendicular, LightEmission = 0.1, LightInfluence = 1 })
	local glint = ctx.emitter(surfPart, { Texture = S.SPARK, Color = ColorSequence.new(hex("#ffffff"), hex("#fff3c8")), Size = NumberSequence.new({ K(0, 0), K(0.5, 0.45), K(1, 0) }), Transparency = NumberSequence.new(0.1), Lifetime = NumberRange.new(0.25, 0.5), Speed = NumberRange.new(0.5, 1.5), EmissionDirection = Enum.NormalId.Front, Rotation = NumberRange.new(0, 360) })
	local snowPart = ctx.part(v3(60, 1, 50), CFrame.new(4, 16, 8), hex("#ffffff"), { Transparency = 1 })
	local snow = ctx.emitter(snowPart, { Texture = S.GLOW, Color = ColorSequence.new(hex("#ffffff")), Size = NumberSequence.new(0.16), Transparency = NumberSequence.new({ K(0, 0.1), K(0.9, 0.1), K(1, 1) }), Lifetime = NumberRange.new(4, 5), Speed = NumberRange.new(3.2, 4.6), EmissionDirection = Enum.NormalId.Bottom, SpreadAngle = Vector2.new(14, 14), Acceleration = v3(0.8, 0, 0), LightEmission = 0.5, LightInfluence = 0.6 })
	local ice = ctx.part(v3(60, 0.16, 330), CFrame.new(10, WY + 0.04, 75), hex("#e6eef4"), { Transparency = 1, Reflectance = 0.2 })
	local leaves = {} -- autumn: alder leaves come down and ride the current
	for i = 1, 14 do
		local r = ctx.rig("Leaf", CFrame.new(0, -70, 0), 0.5)
		local tint = ({ hex("#e08a2c"), hex("#c9542a"), hex("#e8b23a") })[i % 3 + 1]
		r:all(function(p)
			p.Color = tint
			local sa = p:FindFirstChildOfClass("SurfaceAppearance")
			if sa then pcall(function() sa.Color = tint end) end
		end)
		leaves[i] = { r = r, ph = (i * 0.37) % 1, x = 2.2 + (i * 1.7) % 7, z = (i * 2.9) % 9 }
	end

	-- ===== the cast =====
	local otter = ctx.rig("OtterKit", CFrame.new(0, -60, 0))
	otter:all(function(p) p.Material = Enum.Material.Rubber end)
	otter:show("EyesShut", false)
	local pebble = ctx.rig("StonePebble", CFrame.new(0, -60, 0))
	local belly = ctx.rig("BellyStone", CFrame.new(0, -60, 0))
	local shard = ctx.rig("StoneShard", CFrame.new(0, -60, 0))
	local shard2 = ctx.rig("StoneShard", CFrame.new(0, -60, 0)) -- the other half: it drops in the river
	local handle = ctx.rig("StoneHandle", CFrame.new(0, -60, 0), 0.8)
	for _, r in { pebble, belly, shard, shard2, handle } do r:all(function(p) p.Material = Enum.Material.Rubber end) end
	handle:show("Reeds", false)
	local pick = ctx.pick()
	local pickScale0, pickH = 1, 5
	if pick then pickScale0, pickH = pick:GetScale(), math.max(pick:GetExtentsSize().Y, 0.1) pick:PivotTo(W(0, -60, 0)) end
	local function placePick(cf, height) -- stage-space frame, wanted height in studs
		if not pick then return end
		pick:ScaleTo(pickScale0 * height / pickH)
		pick:PivotTo(O * cf)
	end

	-- emitters that follow the work
	local workPart = ctx.part(v3(0.3, 0.3, 0.3), CFrame.new(0, 2, 0), hex("#ffffff"), { Transparency = 1 })
	local chips = ctx.emitter(workPart, { Texture = S.SPARK, Color = ColorSequence.new(hex("#f4eeff"), hex("#b9a7d6")), Size = NumberSequence.new(0.26, 0), Transparency = NumberSequence.new(0, 1), Lifetime = NumberRange.new(0.3, 0.6), Speed = NumberRange.new(5, 11), SpreadAngle = Vector2.new(70, 70), Acceleration = v3(0, -30, 0), LightEmission = 0.4 })
	local dust = ctx.emitter(workPart, { Texture = S.SMOKE, Color = ColorSequence.new(hex("#e6def2")), Size = NumberSequence.new({ K(0, 0.3), K(1, 1.3) }), Transparency = NumberSequence.new({ K(0, 0.4), K(1, 1) }), Lifetime = NumberRange.new(0.4, 0.8), Speed = NumberRange.new(2, 5), SpreadAngle = Vector2.new(60, 60), LightEmission = 0.2, Drag = 3 })
	local reedFx = ctx.emitter(workPart, { Texture = S.GLOW, Color = ColorSequence.new(hex("#86bb62"), hex("#d6f0b8")), Size = NumberSequence.new({ K(0, 0.3), K(1, 0) }), Transparency = NumberSequence.new(0.35, 1), Lifetime = NumberRange.new(0.4, 0.6), Speed = NumberRange.new(0, 0.4), LightEmission = 0.3 })
	local sparkle = ctx.emitter(workPart, { Texture = S.SPARK, Color = ColorSequence.new(hex("#ffffff"), hex("#d8cdea")), Size = NumberSequence.new({ K(0, 0), K(0.3, 0.7), K(1, 0) }), Transparency = NumberSequence.new(0, 1), Lifetime = NumberRange.new(0.6, 1.2), Speed = NumberRange.new(3, 9), SpreadAngle = Vector2.new(180, 180), Rotation = NumberRange.new(0, 360), Drag = 2 })
	local splashPart = ctx.part(v3(0.6, 0.2, 0.6), CFrame.new(7, WY + 0.1, 3), hex("#ffffff"), { Transparency = 1 })
	local splash = ctx.emitter(splashPart, { Texture = S.GLOW, Color = ColorSequence.new(hex("#f2fbff")), Size = NumberSequence.new({ K(0, 0.12), K(1, 0.3) }), Transparency = NumberSequence.new({ K(0, 0.2), K(1, 1) }), Lifetime = NumberRange.new(0.35, 0.7), Speed = NumberRange.new(6, 13), SpreadAngle = Vector2.new(38, 38), EmissionDirection = Enum.NormalId.Top, Acceleration = v3(0, -34, 0), LightEmission = 0.5 })
	local ringFx = ctx.emitter(splashPart, { Texture = S.GLOW, Color = ColorSequence.new(hex("#e8f6ff")), Size = NumberSequence.new({ K(0, 0.6), K(1, 5.5) }), Transparency = NumberSequence.new({ K(0, 0.55), K(1, 1) }), Lifetime = NumberRange.new(0.8, 1.1), Speed = NumberRange.new(0, 0.05), Orientation = Enum.ParticleOrientation.VelocityPerpendicular, EmissionDirection = Enum.NormalId.Top, LightEmission = 0.3 })
	local heroPart = ctx.part(v3(0.3, 0.3, 0.3), CFrame.new(-1, 5.6, -2), hex("#ffffff"), { Transparency = 1 })
	local rays = Instance.new("BillboardGui")
	rays.Size, rays.LightInfluence, rays.Brightness, rays.Parent = UDim2.fromScale(13, 13), 0, 1.3, heroPart
	local raysIm = Instance.new("ImageLabel")
	raysIm.BackgroundTransparency, raysIm.Image, raysIm.ImageColor3, raysIm.ImageTransparency, raysIm.Size, raysIm.Parent = 1, "rbxassetid://98789616938156", hex("#fff0c8"), 1, UDim2.fromScale(1, 1), rays
	-- NAMED is shot into the sun: a soft warm fill from the camera's side, as the pale gravel would bounce it, so her face and the pickaxe are not a silhouette
	local fillPart = ctx.part(v3(0.3, 0.3, 0.3), CFrame.new(-1.4, 2.6, -7.4), hex("#ffffff"), { Transparency = 1 })
	local fill = Instance.new("PointLight")
	fill.Color, fill.Range, fill.Brightness, fill.Shadows, fill.Parent = hex("#ffe9c4"), 18, 0, false, fillPart
	local heroSpark = ctx.emitter(heroPart, { Texture = S.SPARK, Color = ColorSequence.new(hex("#ffffff"), hex("#b9a7d6")), Size = NumberSequence.new({ K(0, 0), K(0.3, 0.6), K(1, 0) }), Transparency = NumberSequence.new(0, 1), Lifetime = NumberRange.new(0.8, 1.6), Speed = NumberRange.new(2, 7), SpreadAngle = Vector2.new(180, 180), Rotation = NumberRange.new(0, 360), Drag = 1.5 })
	local drips = ctx.emitter(heroPart, { Texture = S.GLOW, Color = ColorSequence.new(hex("#dff4ff")), Size = NumberSequence.new({ K(0, 0.14), K(1, 0.08) }), Transparency = NumberSequence.new({ K(0, 0.1), K(1, 0.6) }), Lifetime = NumberRange.new(0.5, 0.7), Speed = NumberRange.new(0.2, 1), SpreadAngle = Vector2.new(30, 30), EmissionDirection = Enum.NormalId.Bottom, Acceleration = v3(0, -40, 0), LightEmission = 0.5 })

	-- ===== looks: four seasons of light and air =====
	local LOOK = {
		spring = { Ambient = rgb(128, 136, 140), OutdoorAmbient = rgb(136, 146, 150), Brightness = 1.7, ColorShift_Top = rgb(200, 212, 225), ExposureCompensation = 0.1 },
		summer = { Ambient = rgb(150, 148, 136), OutdoorAmbient = rgb(164, 166, 158), Brightness = 2.4, ColorShift_Top = rgb(255, 238, 206), ExposureCompensation = 0 },
		autumn = { Ambient = rgb(160, 132, 110), OutdoorAmbient = rgb(172, 146, 122), Brightness = 2.6, ColorShift_Top = rgb(255, 200, 140), ExposureCompensation = 0 },
		winter = { Ambient = rgb(150, 160, 176), OutdoorAmbient = rgb(164, 174, 190), Brightness = 1.8, ColorShift_Top = rgb(214, 226, 245), ExposureCompensation = 0.25 },
	}
	local ATMO = {
		spring = { Density = 0.4, Haze = 2.5, Color = rgb(160, 170, 174), Decay = rgb(104, 114, 120), Glare = 0, Offset = 0.2 },
		summer = { Density = 0.3, Haze = 1.9, Color = rgb(240, 228, 200), Decay = rgb(170, 190, 205), Glare = 0.05, Offset = 0.25 },
		autumn = { Density = 0.33, Haze = 2.2, Color = rgb(250, 206, 150), Decay = rgb(190, 140, 110), Glare = 0.2, Offset = 0.25 },
		winter = { Density = 0.42, Haze = 2.6, Color = rgb(214, 222, 232), Decay = rgb(150, 162, 180), Glare = 0, Offset = 0.2 },
	}
	local WATER = { -- colour, how clear, how fast it runs
		spring = { hex("#6f7d5e"), 0.3, 9 }, summer = { hex("#5fa8a0"), 0.7, 2.4 }, autumn = { hex("#6a8f86"), 0.62, 1.8 }, winter = { hex("#9fb6c2"), 0.55, 0.2 },
	}
	local TINT = { spring = rgb(226, 232, 240), summer = rgb(255, 250, 240), autumn = rgb(255, 236, 214), winter = rgb(232, 240, 255) }
	local SAT = { spring = -0.2, summer = 0.12, autumn = 0.18, winter = -0.45 }
	local function mixTo(a, b, u)
		local out = {}
		for k, v in a do
			local w = b[k]
			if typeof(v) == "Color3" then out[k] = v:Lerp(w, u) else out[k] = v + (w - v) * u end
		end
		return out
	end
	local skyNow
	local function sky(name) if skyNow ~= name then skyNow = name ctx.sky(IMG[name]) end end
	-- the sun stands high up the canyon and a little to the bar's side: the walls throw long soft shadows down toward the camera,
	-- wet stones get a bright rim, the otter is lit from behind and above (the reference's backlit haze)
	local KEYS = { V(-0.3, 0.72, 0.62), V(-0.2, 0.5, 0.84), V(-0.12, 0.42, 0.9) }
	local keyNow = 0
	local function key(i) if keyNow ~= i then keyNow = i ctx.key(KEYS[i]) end end

	-- the hundred years: where one season hands over to the next (story seconds)
	local SEASONS = { { 0, "summer" }, { 1.3, "spring" }, { 1.85, "summer" }, { 2.35, "autumn" }, { 2.85, "winter" }, { 3.4, "summer" } }
	local function season(t)
		for i = #SEASONS, 1, -1 do
			if t >= SEASONS[i][1] then
				local prev = SEASONS[math.max(i - 1, 1)][2]
				return prev, SEASONS[i][2], smooth(SEASONS[i][1], SEASONS[i][1] + 0.16, t)
			end
		end
		return "summer", "summer", 1
	end

	-- ===== the otter's acting =====
	local PAW_L, PAW_R = CFrame.new(-0.09, -0.5, -0.26), CFrame.new(0.09, -0.5, -0.26)
	local TAPS = { 4.72, 5.1, 5.46 } -- the third one cracks it
	local FLOAT = { LegL = R(18, 0, 14), LegR = R(22, 0, -14), Tail1 = R(8, 0, 0), Tail2 = R(4, 0, 0) }
	local fkeys = { { 4.2, { ArmL = R(100, 0, 18), ForeL = R(30, 0, 0), ArmR = R(100, 0, -18), ForeR = R(30, 0, 0), Head = R(-10, 0, 0), Body = R(0, 0, 0) } }, -- up she comes, the pebble held high
		{ 4.5, { ArmL = R(44, 0, 26), ForeL = R(56, 0, 0), ArmR = R(44, 0, -26), ForeR = R(56, 0, 0), Head = R(26, 22, 0) }, "inout" } } -- she looks it over on her chest
	for i, at in TAPS do
		table.insert(fkeys, { at - 0.17, { ArmL = R(84, 0, 14), ForeL = R(40, 0, 0), ArmR = R(84, 0, -14), ForeR = R(40, 0, 0), Head = R(14, 22, i % 2 == 0 and 5 or -5) }, "out" }) -- anticipation: both paws lift it
		table.insert(fkeys, { at, { ArmL = R(34, 0, 26), ForeL = R(62, 0, 0), ArmR = R(34, 0, -26), ForeR = R(62, 0, 0), Head = R(30, 22, 0) }, "in" }) -- the strike on the belly stone
		table.insert(fkeys, { at + 0.1, { ArmL = R(42, 0, 26), ForeL = R(56, 0, 0), ArmR = R(42, 0, -26), ForeR = R(56, 0, 0), Head = R(26, 22, 0) }, "back" })
	end
	table.insert(fkeys, { 5.62, { ArmL = R(74, 0, 34), ForeL = R(50, 0, 0), ArmR = R(100, 0, -8), ForeR = R(28, 0, 0), Head = R(4, -14, 6) }, "back" }) -- she holds the good half up to the light
	local float = S.track(fkeys)
	local SIT = { LegL = R(74, 0, 10), LegR = R(62, 0, -16), Tail1 = R(-25, 30, 0), Tail2 = R(-20, 26, 0) }
	local sit = S.track({
		{ 5.8, { ArmL = R(26, 0, 24), ForeL = R(54, 0, 0), ArmR = R(24, 0, -20), ForeR = R(56, 0, 0), Head = R(20, 6, -6), Body = R(14, 6, 2) } },
		{ 6.05, { ArmR = R(40, 0, -34), ForeR = R(70, 0, 0), ArmL = R(34, 0, 36), ForeL = R(66, 0, 0), Head = R(24, -8, 6) }, "inout" }, -- winding the reeds: one paw round and round
		{ 6.2, { ArmR = R(22, 0, -14), ForeR = R(50, 0, 0) }, "inout" },
		{ 6.35, { ArmR = R(42, 0, -36), ForeR = R(72, 0, 0) }, "inout" },
		{ 6.5, { ArmR = R(20, 0, -12), ForeR = R(48, 0, 0), ArmL = R(30, 0, 30), ForeL = R(60, 0, 0), Head = R(22, 0, 0), Body = R(16, 4, 0) }, "inout" },
		{ 6.62, { ArmR = R(-10, 0, -40), ForeR = R(40, 0, 0), ArmL = R(-10, 0, 40), ForeL = R(40, 0, 0), Head = R(14, 0, 0), Body = R(8, 0, 0) }, "out" }, -- the knot: both paws pull apart
		{ 6.8, { ArmR = R(30, 0, -22), ForeR = R(60, 0, 0), ArmL = R(30, 0, 22), ForeL = R(60, 0, 0), Head = R(10, 0, 0), Body = R(6, 0, 0) }, "back" },
		{ 7.0, { ArmR = R(96, 0, -10), ForeR = R(40, 0, 0), ArmL = R(34, 0, 30), ForeL = R(60, 0, 0), Head = R(-4, 12, 4), Body = R(0, 8, 0) }, "inout" }, -- she lifts it in one paw and turns it over
		{ 7.2, { ArmR = R(40, 0, -6), ForeR = R(20, 0, 0), Head = R(22, 6, -4), Body = R(18, 8, 2) }, "in" }, -- and tries it on the stone beside her
		{ 7.32, { ArmR = R(52, 0, -12), ForeR = R(34, 0, 0), Head = R(14, 4, -3), Body = R(12, 6, 2) }, "back" },
		{ 7.5, { ArmR = R(70, 0, -16), ForeR = R(50, 0, 0), Head = R(-6, 16, 6), Body = R(2, 6, 0) }, "inout" }, -- a nod: it holds
	})
	local named = S.track({
		{ 7.6, { LegL = R(0, 0, 0), LegR = R(0, 0, 0), ArmL = R(40, 0, 20), ForeL = R(40, 0, 0), ArmR = R(40, 0, -20), ForeR = R(40, 0, 0), Head = R(6, 0, 0), Body = R(8, 0, 0), Tail1 = R(0, 0, 0), Tail2 = R(0, 0, 0) } },
		{ 8.15, { ArmL = R(20, 0, 10), ForeL = R(70, 0, 0), ArmR = R(20, 0, -10), ForeR = R(70, 0, 0), Head = R(12, 0, 0), Body = R(14, 0, 0), LegL = R(-16, 0, 0), LegR = R(-16, 0, 0) }, "inout" }, -- she dips it in the river: a crouch
		{ 8.45, { ArmL = R(164, 0, -8), ForeL = R(8, 0, 0), ArmR = R(168, 0, 8), ForeR = R(8, 0, 0), Head = R(-24, 0, 0), Body = R(-14, 0, 0), LegL = R(-8, 0, 8), LegR = R(-8, 0, -8) }, "back" }, -- up, in both paws, over her head
		{ 9.4, { ArmL = R(160, 0, -10), ArmR = R(166, 0, 12), Head = R(-20, -8, 6), Body = R(-12, -5, 3) }, "inout" },
		{ 10.2, { ArmL = R(156, 0, -12), ArmR = R(162, 0, 14), Head = R(-24, 4, -4) }, "inout" },
	})
	-- as in ForgeWood: a positive first angle on Head and Body means "lean forward"; flipped here once for a model that faces -Z
	local function lean(p)
		for _, b in { "Head", "Body" } do
			local cf = p[b]
			if cf then local x, y, z = cf:ToEulerAnglesXYZ() p[b] = CFrame.Angles(-x, y, z) end
		end
		return p
	end
	-- lying in the water: roll 0 is on her belly (swimming), 180 on her back; the head points along the yaw
	local function lying(x, y, z, yaw, roll, pitch) return W(x, y, z) * R(0, yaw, 0) * R(-90 + (pitch or 0), 0, 0) * R(0, roll, 0) * CFrame.new(0, -1.3, 0) end

	-- this scene's own sounds (audio/pd_forge_sfx.py, synthesised): the river loop and the stone tap; rain and the bells are the Wood scene's
	local SND = { river = 117253485620174, tap = 90326072989009, rain = 71766947362966, dawn = 85010698086137 }
	local riverS = ctx.sound(SND.river, 0, 1, true)
	local rainS = ctx.sound(SND.rain, 0, 1, true)
	local hitT = -1
	local stage = 0 -- 0 pebble, 1 shard, 2 pickaxe
	local FLOAT_AT = V(6.6, WY + 0.3, 2.2)
	local SIT_AT = V(-1.2, 0.2, -1.6)

	return function(t, dt)
		-- ===== season, light, air, water =====
		local sa, sb, su = season(t)
		local winter = (sb == "winter" and su or 0) + (sa == "winter" and 1 - su or 0)
		local spring = (sb == "spring" and su or 0) + (sa == "spring" and 1 - su or 0)
		local autumn = (sb == "autumn" and su or 0) + (sa == "autumn" and 1 - su or 0)
		sky(winter > 0.5 and "winter" or "summer")
		key(t < 3.4 and 1 or (t < 7.6 and 2 or 3))
		ctx.light(mixTo(LOOK[sa], LOOK[sb], su))
		ctx.atmo(mixTo(ATMO[sa], ATMO[sb], su))
		ctx.cc.TintColor = TINT[sa]:Lerp(TINT[sb], su)
		ctx.cc.Saturation, ctx.cc.Contrast = SAT[sa] + (SAT[sb] - SAT[sa]) * su, 0.08
		sunRays.Intensity = 0.05 * (1 - winter) * (1 - spring) + 0.02 * smooth(7.6, 8.4, t)
		fill.Brightness = 1.6 * smooth(7.6, 7.9, t)
		local wa, wb = WATER[sa], WATER[sb]
		water.Color, water.Transparency = wa[1]:Lerp(wb[1], su), wa[2] + (wb[2] - wa[2]) * su
		local run = wa[3] + (wb[3] - wa[3]) * su
		M._flow = (M._flow or 0) + run * dt
		ripple.OffsetStudsV, ripple.OffsetStudsU = -M._flow, math.sin(t * 0.5) * 1.5
		ripple2.OffsetStudsV, ripple2.OffsetStudsU = -M._flow * 0.6, t * 0.7
		ripple.Transparency = 0.55 + 0.3 * winter
		ice.Transparency = 1 - 0.72 * winter
		rainFx.Rate, foam.Rate = 1700 * spring, 60 * spring
		glint.Rate = 26 * (1 - winter) * (1 - spring)
		snow.Rate = 240 * winter
		ctx.once("snowIn", 2.85, t, function() snow:Emit(160) end)
		riverS.Volume = (0.26 + 0.2 * spring) * (1 - 0.85 * winter) * smooth(0, 0.4, t)
		riverS.PlaybackSpeed = 1 + 0.25 * spring
		rainS.Volume = 0.34 * spring
		for _, l in leaves do
			local u = (t * 0.9 + l.ph) % 1
			local fall = math.clamp(u / 0.45, 0, 1)
			local y = (WY + 0.12) + (1 - fall) * (1 - fall) * 9
			l.r.root = W(l.x + math.sin(u * 7 + l.ph * 9) * 0.8 * (1 - fall), y, l.z - (u - 0.45) * 9 * (fall >= 1 and 1 or 0)) * R(fall >= 1 and 90 or t * 260 + l.ph * 360, t * 40 + l.ph * 360, 0)
			l.r:all(function(p) p.Transparency = autumn > 0.05 and 0 or 1 end)
		end

		-- ===== BORN: the pebble on the bed, rolled a little further by every season =====
		if t < 3.4 then
			local roll = smooth(1.3, 1.85, t) * 0.5 + smooth(1.85, 2.35, t) * 0.25 + smooth(2.35, 2.85, t) * 0.25 -- the flood carries it furthest; under the ice it lies still
			local z = 7.5 - 5.5 * roll
			local x = 3.4 + 1.9 * roll + 0.4 * math.sin(roll * 5)
			local sc = 1.7 - 0.7 * roll -- and every year it is a little smaller and rounder
			pebble.scale = sc
			pebble.root = W(x, bedY(x, z) + 0.3 * sc, z) * R(-roll * 2200, roll * 240, 20)
			otter.root = W(0, -60, 0)
		end

		-- ===== the otter =====
		local breathe = math.sin(t * 2.6) * 0.012
		otter:size("Body", V(1 + breathe, 1 - breathe, 1 + breathe))
		local blink = (t % 2.3) < 0.1
		local shut = blink or (t >= 7.42 and t < 7.6) or t >= 8.45
		otter:show("Eyes", not shut) otter:show("EyesShut", shut)
		otter:set("EarL", R(0, 0, math.sin(t * 3.1) * 4 + ((t % 1.7) < 0.14 and 9 or 0)))
		otter:set("EarR", R(0, 0, -math.sin(t * 3.1 + 1) * 4 - ((t % 2.1) < 0.14 and 9 or 0)))
		local bob = math.sin(t * 3.4) * 0.06
		if t >= 3.4 and t < 4.2 then -- she comes down the river on her belly, ducks under for the pebble, and rolls over
			local swim, duck, over = smooth(3.4, 3.85, t), math.sin(lin(3.82, 4.12, t) * math.pi), smooth(4.02, 4.2, t)
			local from = V(8.6, WY + 0.05, 15)
			local p = from:Lerp(FLOAT_AT, swim)
			otter.root = lying(p.X, p.Y + bob - 0.5 * duck, p.Z, -4 + math.sin(t * 9) * 5 * (1 - swim) - 96 * over, 180 * over, -58 * duck)
			otter:pose({ ArmL = R(150 - 110 * math.abs(math.sin(t * 9)), 0, 20), ForeL = R(20, 0, 0), ArmR = R(150 - 110 * math.abs(math.cos(t * 9)), 0, -20), ForeR = R(20, 0, 0), LegL = R(-20 + math.sin(t * 12) * 26, 0, 8), LegR = R(-20 - math.sin(t * 12) * 26, 0, -8), Head = R(46 - 40 * over, 0, 0), Body = R(0, 0, 0), Tail1 = R(-6, math.sin(t * 9) * 24, 0), Tail2 = R(0, math.sin(t * 9 - 0.9) * 30, 0) })
			if t >= 3.95 then pebble.root = W(0, -60, 0) end -- she has it
			ctx.once("duck", 3.86, t, function() splashPart.CFrame = W(FLOAT_AT.X, WY + 0.1, FLOAT_AT.Z) splash:Emit(26) ringFx:Emit(2) sfx("land", 1.3) end)
			ctx.once("up", 4.1, t, function() splash:Emit(34) ringFx:Emit(2) sfx("pop", 1.2) ctx.kick(1.5) end)
		elseif t >= 4.2 and t < 5.8 then -- floating on her back, the belly stone on her chest
			local jolt = hitT > 0 and math.max(0, 1 - (t - hitT) / 0.14) or 0
			otter.root = lying(FLOAT_AT.X, FLOAT_AT.Y + bob - 0.1 * jolt, FLOAT_AT.Z + (t - 4.2) * 0.25, -100 + math.sin(t * 1.1) * 4, 180, -6)
			otter:pose(FLOAT)
			otter:pose(lean(float(t)))
			otter:set("Tail1", R(8, math.sin(t * 3) * 14, 0)) otter:set("Tail2", R(4, math.sin(t * 3 - 0.8) * 20, 0))
			otter:set("LegL", R(18 + math.sin(t * 4) * 10, 0, 14)) otter:set("LegR", R(22 - math.sin(t * 4) * 10, 0, -14))
		elseif t >= 5.8 and t < 7.6 then -- on the gravel bar: the binding, and the first try
			otter.root = W(SIT_AT.X, SIT_AT.Y + 0.36, SIT_AT.Z) * R(0, 26, 0)
			otter:pose(SIT)
			otter:pose(lean(sit(t)))
			otter:set("Tail1", R(-25, 30 + math.sin(t * 4) * 12, 0)) otter:set("Tail2", R(-20, 26 + math.sin(t * 4 - 0.8) * 16, 0))
		elseif t >= 7.6 then -- NAMED: at the water's edge, the canyon and the sun behind her
			local hop = math.sin(math.clamp((t - 8.3) / 0.45, 0, 1) * math.pi) * 1.0
			otter.root = W(0.4, 0.2 + hop, -2.6) * R(0, -14, 0)
			otter:pose(lean(named(t)))
			otter:set("Tail1", R(0, math.sin(t * 7) * 20, 0)) otter:set("Tail2", R(0, math.sin(t * 7 - 0.8) * 26, 0))
		end
		local phase = t < 3.4 and 0 or (t < 4.2 and 1 or (t < 5.8 and 2 or (t < 7.6 and 3 or 4)))
		if phase ~= otter.phase then otter.phase = phase otter:snap() end
		local sinceHit = hitT > 0 and t - hitT or 1
		otter:smooth(dt, (phase == 1 or sinceHit < 0.1) and 34 or 13)
		otter:update()

		-- ===== the work =====
		local pawL, pawR = (otter:joint("ForeL") * PAW_L).Position, (otter:joint("ForeR") * PAW_R).Position
		local paws = (pawL + pawR) / 2
		local chest = otter:joint("Body") * CFrame.new(0, 0.22, -0.9)
		if t >= 4.1 and t < 5.8 then
			belly.root = chest * R(90, 0, 0)
			local held = CFrame.new(paws) * (chest - chest.Position) * CFrame.new(0, 0, -0.2)
			pebble.scale = 1
			pebble.root = stage == 0 and held or W(0, -60, 0)
			shard.root = stage == 1 and CFrame.new(pawR) * (chest - chest.Position) * R(-90, 0, 0) * CFrame.new(0, 0.1, 0) or W(0, -60, 0)
			if stage == 1 then -- the other half slides off her chest into the river
				local u = t - TAPS[3]
				shard2.root = CFrame.new((chest * CFrame.new(-0.5, 0, 0)).Position + V(1.2 * u, 2.2 * u - 9 * u * u, -0.8 * u)) * R(u * 400, u * 200, 0)
				ctx.once("plop", TAPS[3] + 0.45, t, function() splashPart.CFrame = CFrame.new(shard2.root.Position.X, O.Position.Y + WY + 0.1, shard2.root.Position.Z) splash:Emit(10) ringFx:Emit(1) sfx("pop", 0.8) end)
			end
			workPart.CFrame = chest
			for i, at in TAPS do
				ctx.once("tap" .. i, at, t, function()
					hitT = at
					ctx.sound(SND.tap, 0.6, 0.9 + i * 0.1)
					ctx.hold(2 / 60) ctx.kick(1.4 + i * 0.5)
					chips:Emit(6 + i * 5)
					splashPart.CFrame = W(FLOAT_AT.X, WY + 0.1, FLOAT_AT.Z)
					ringFx:Emit(1)
					if i == 3 then stage = 1 dust:Emit(16) sparkle:Emit(14) sfx("breakRock", 1.25) ctx.shake(0.4) ctx.hold(4 / 60) end
				end)
			end
		elseif t >= 5.8 and t < 7.6 then
			if stage < 1 then stage = 1 end
			belly.root, pebble.root, shard2.root = W(0, -60, 0), W(0, -60, 0), W(0, -60, 0)
			local lap = otter:joint("Body") * CFrame.new(0, 0.42, -1.1)
			workPart.CFrame = lap
			reedFx.Rate = (t >= 5.95 and t < 6.6) and 60 or 0
			if t >= 5.95 and t < 6.6 then
				local a = (t - 5.95) * 24
				workPart.CFrame = lap * CFrame.new(0.5 + math.cos(a) * 0.5, 0.2 + math.sin(a) * 0.5, math.sin(a) * 0.4)
			end
			ctx.once("tie", 6.62, t, function() stage = 2 sparkle:Emit(26) sfx("sparkle", 1.2) sfx("pop", 1.4) ctx.kick(1.6) end)
			if stage == 1 then
				local stick = lap * CFrame.new(-0.1, -0.1, 0.1) * R(0, 0, 78)
				handle.root = stick
				handle:show("Reeds", t >= 6.2)
				shard.root = stick * CFrame.new(0, 1.0, 0) * R(0, 0, 90)
			else
				handle.root, shard.root = W(0, -60, 0), W(0, -60, 0)
				local pop = backOut(lin(6.62, 6.86, t))
				local inPaw = CFrame.new(pawR) * (otter:joint("ForeR") - otter:joint("ForeR").Position)
				local rest = lap * CFrame.new(0.15, -0.2, -0.15) * R(0, 180, 78)
				local hand = inPaw * R(-80, 0, 0) * CFrame.new(0, 0.9, 0)
				placePick(O:ToObjectSpace(rest:Lerp(hand, smooth(6.86, 7.0, t))), 2.9 * (0.6 + 0.4 * pop))
				ctx.once("try", 7.2, t, function()
					hitT = 7.2
					workPart.CFrame = CFrame.new(pawR + V(0, -0.8, 0))
					chips:Emit(14) ctx.sound(SND.tap, 0.6, 1.3) sfx("breakRock", 1.6) ctx.hold(3 / 60) ctx.kick(2.2)
				end)
			end
		elseif t >= 7.6 then
			belly.root, pebble.root, shard.root, shard2.root, handle.root = W(0, -60, 0), W(0, -60, 0), W(0, -60, 0), W(0, -60, 0), W(0, -60, 0)
			reedFx.Rate = 0
		end

		-- ===== NAMED: the dip, the lift, the drops in the sun =====
		if t >= 7.6 then
			local hands = (otter:joint("ForeL").Position + otter:joint("ForeR").Position) / 2
			local lift = smooth(8.45, 9.3, t)
			local at = O:PointToObjectSpace(hands) + V(0, 0.5 + 1.0 * lift + math.sin(t * 2) * 0.1 * lift, -0.3)
			local spin = smooth(8.5, 10.0, t) * 360
			placePick(CFrame.new(at) * R(0, 180 + spin, 78 - 98 * smooth(8.2, 8.5, t)), 2.9 + 0.7 * lift)
			heroPart.CFrame = W(at.X, at.Y + 0.6, at.Z)
			raysIm.ImageTransparency = 1 - 0.7 * smooth(8.45, 8.8, t) * (1 - smooth(10.6, 11.1, t))
			raysIm.Rotation = t * 22
			ctx.once("dip", 8.15, t, function() splashPart.CFrame = W(1.9, WY + 0.1, -2.9) splash:Emit(22) ringFx:Emit(2) sfx("land", 1.5) end)
			ctx.once("reveal", 8.45, t, function() heroSpark:Emit(40) drips:Emit(30) ctx.sound(SND.dawn, 0.6, 1.1) sfx("sparkle", 1.3) ctx.kick(5) ctx.hold(4 / 60) end)
			heroSpark.Rate = t >= 8.6 and 8 or 0
			drips.Rate = t >= 8.45 and 46 * (1 - smooth(9.4, 10.6, t)) or 0
			ctx.name("Rounded by patience.")
			ctx.cardAlpha = smooth(9.0, 9.35, t) * (1 - smooth(10.7, 11.0, t))
		end
		ctx.flashAlpha = math.max(0.5 * (1 - lin(TAPS[3], TAPS[3] + 0.22, t)) * (t >= TAPS[3] and 1 or 0), 0.85 * (1 - lin(8.45, 8.8, t)) * (t >= 8.45 and 1 or 0))

		-- ===== chapters and camera =====
		if t >= 0.35 and t < 3.4 then ctx.chapter(1, "BORN", "A lilac pebble the river rolled for a hundred years.")
		elseif t >= 3.6 and t < 7.6 then ctx.chapter(2, "MADE", "Cracked on an otter's belly stone, bound with river reeds.")
		elseif t >= 7.8 then ctx.chapter(3, "NAMED", "She holds it up, dripping, in the sun.") end
		local cf, fov, focus
		local function shot(from, aim, f) cf, fov, focus = CFrame.lookAt(from, aim), f, (from - aim).Magnitude end
		if t < 1.3 then -- the canyon: from high over the bar, down the pale walls to the river
			local u = smooth(0, 1.3, t)
			shot(V(-7 + 5 * u, 11 - 9.6 * u, -24 + 15 * u), V(5, 8 - 8.6 * u, 40 - 33 * u), 56 - 6 * u)
		elseif t < 3.4 then -- low at the water's edge: the pebble near, the river and the canyon beyond; the years go by over it
			local pp = O:PointToObjectSpace(pebble.root.Position)
			shot(V(0.9, 0.75, pp.Z - 4.4), V(pp.X + 1.2, pp.Y + 0.5, pp.Z + 2.5), 50)
		elseif t < 4.2 then -- she comes down the river
			local op = O:PointToObjectSpace(otter:joint("Body").Position)
			shot(V(1.2, 2.3, -5.2), V(op.X, WY + 0.5, op.Z):Lerp(V(FLOAT_AT.X, WY + 0.7, FLOAT_AT.Z), 0.5), 46)
		elseif t < 5.8 then -- over her, from the bar: her face, the stone on her chest, the pebble in her paws
			shot(V(3.6 - 0.3 * smooth(4.2, 5.8, t), 3.5, -2.9), V(FLOAT_AT.X - 0.2, WY + 0.9, FLOAT_AT.Z + 0.5), 38)
		elseif t < 7.0 then -- on the bar: the reeds go round the stick
			shot(V(-0.2 + 0.3 * smooth(5.8, 7.0, t), 2.7, -8.8), V(-1.3, 2.55, -1.9), 40)
		elseif t < 7.6 then -- wider: she tries it on the stone beside her
			shot(V(1.6, 2.3, -9.4), V(-1.2, 2.5, -1.8), 42)
		else -- low at her feet, looking up the canyon into the sun
			local up = smooth(8.3, 9.2, t)
			shot(V(-1.6 - 0.3 * smooth(8.4, 10.8, t), 0.7, -10.2 + 0.8 * smooth(8.4, 10.8, t)), V(0.4, 2.4, -2.6):Lerp(V(0.4, 4.1, -2.6), up), 56 - 2 * smooth(8.4, 10.8, t))
		end
		ctx.cam, ctx.fov = O * cf, fov
		ctx.dof.FocusDistance = focus
		ctx.dof.InFocusRadius, ctx.dof.FarIntensity, ctx.dof.NearIntensity = 400, 0, 0
	end
end

return M
