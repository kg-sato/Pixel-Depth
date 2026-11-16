-- ReplicatedStorage.Shared.ForgeKiln (src/ForgeKiln.luau): the Kiln Pickaxe biography, played by ForgeStory.
-- BORN: wet clay, dug from the terrace bank by a mole potter and slapped onto her kick wheel. MADE: she throws the head on the
-- wheel, trims it, pours the glaze in one pass and fires it; the afternoon turns into a blue evening while the kiln burns, and
-- the teapot on the kiln whistles when it is done (she flinches, then laughs at herself). NAMED: she taps it and it rings
-- like a bell. "Fired once, right."
-- The setting is a place of its own (references refs/forge/sheets/kiln_setting_s11.png and molepotter_views_s11.png): a
-- potter's yard cut into a red clay cliff, a brick bottle kiln, a kick wheel under a reed awning, shelves of drying pots,
-- firewood, washing on a line; behind the yard terraced clay pits step down to a winding red river and clay hills.
-- Built from design3d/kiln.mjs and kiln_world.py (terrain, pictures, the map of every stone and plant in ForgeKilnMap).
-- Space: front of a model is -Z, the camera stands at -Z and looks toward +Z (the terraces and the river). +X is screen left.
-- The places below are the authoring places of kiln.mjs with x and z flipped: wheel (-1.5, 0), kiln (9, 7) with its fire door
-- facing the camera at z = 2.9, teapot ledge (5.7, 2.3, 4), chopping block (5.2, -0.6), dug bank at x = -20.5.
-- Every time in this file is a story second; the clock runs at 0.58 of real time (see ForgeWood). Every state is worked out
-- from t alone, so the short version that starts at NAMED needs nothing that happened before it.
local M = { length = 11.2, named = 7.6, open = true, pace = 0.58, fastPace = 0.75 }
-- pictures made by design3d/kiln_world.py (ids in design3d/assets.json); the ripple is the Wood scene's
local IMG = {
	afternoon = { side = "81643969019289", up = "86016281586438", dn = "78721086212999", sun = 8 },
	dusk = { side = "80928397749976", up = "136438363041912", dn = "72680942305539", stars = 500 },
	ripple = "rbxassetid://108008922454214",
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
	local HIDE = W(0, -60, 0)

	-- ===== the place =====
	local MAP = require(script.Parent:WaitForChild("ForgeKilnMap"))
	local WY = MAP.waterY
	local land = ctx.prop("KilnWorld")
	land:all(function(p, b) p.Material = Enum.Material.Rubber if b.name == "Far" then p.CastShadow = false end end)
	local SMALL = { PalePebble1 = true, PalePebble2 = true, PalePebble3 = true, WispyGrass = true, GrassTuft = true, FlowerPatch = true, FlowerPatch2 = true, Fern = true, Plant1 = true, Plant7 = true }
	for _, it in MAP.items do
		local r = ctx.prop(it[1], CFrame.new(it[2], it[3], it[4]) * CFrame.Angles(0, math.rad(it[5]), 0), it[6])
		local small = SMALL[it[1]]
		r:all(function(p)
			if p.Material ~= Enum.Material.Neon then p.Material = Enum.Material.Rubber end
			if small then p.CastShadow = false end
		end)
	end
	-- the red river at the foot of the terraces: an opaque sheet over the painted bed (only the near field has it; far off it is paint)
	local water = ctx.part(v3(220, 0.2, 90), CFrame.new(0, WY - 0.1, 138), hex("#a8452e"), { Transparency = 0.15, Reflectance = 0.16 })
	local ripple = Instance.new("Texture")
	ripple.Texture, ripple.Face, ripple.StudsPerTileU, ripple.StudsPerTileV, ripple.Transparency, ripple.Parent = IMG.ripple, Enum.NormalId.Top, 40, 26, 0.6, water

	-- the yard: kiln, awning, shelves, firewood, washing line (one model, its bones driven below)
	local yard = ctx.rig("KilnYard")
	local doorPart, peepPart
	yard:all(function(p, b)
		if p.Material ~= Enum.Material.Neon then p.Material = Enum.Material.Rubber end
		if b.name == "Door" then doorPart = p p.CastShadow = false end
		if b.name == "Peephole" then peepPart = p p.CastShadow = false end
	end)
	local WHEEL = V(-1.5, 0, 0)
	local HEAD_Y = 1.35 -- the top of the wheel head
	local SEAT = V(-1.5, 0.6, 1.25)
	local DOOR = V(9, 1.4, 2.9)
	local BLOCK = V(5.2, 0.6, -0.6)
	local DIG = V(-19.4, 0, -1)
	local HERO = V(5.6, 0, -3.4)
	local wheel = ctx.rig("KickWheel", CFrame.new(WHEEL))
	wheel:all(function(p) p.Material = Enum.Material.Rubber end)
	local TEA_S = 1.5
	local teapot = ctx.rig("Teapot", CFrame.new(5.7, 2.3, 4.0) * R(0, -72, 0), TEA_S)
	local sunRays = ctx.effect("SunRaysEffect", { Intensity = 0.06, Spread = 0.8 })

	-- the kiln's fire is the evening's key light: a real light in front of the fire door, with shadows
	local doorLP = ctx.part(v3(0.3, 0.3, 0.3), CFrame.new(DOOR.X, 1.6, DOOR.Z - 1.3), hex("#ffffff"), { Transparency = 1 })
	local doorLight = Instance.new("PointLight")
	doorLight.Color, doorLight.Range, doorLight.Brightness, doorLight.Shadows, doorLight.Parent = hex("#ffb060"), 42, 0, true, doorLP
	local peepLP = ctx.part(v3(0.2, 0.2, 0.2), CFrame.new(9, 4.3, 2.4), hex("#ffffff"), { Transparency = 1 })
	local peepLight = Instance.new("PointLight")
	peepLight.Color, peepLight.Range, peepLight.Brightness, peepLight.Shadows, peepLight.Parent = hex("#ffd9a0"), 12, 0, false, peepLP
	-- NAMED is shot with the kiln behind her: a soft fill from the camera's side, so her face and the pickaxe are not a silhouette
	local fillPart = ctx.part(v3(0.3, 0.3, 0.3), CFrame.new(4.6, 2.6, -8.0), hex("#ffffff"), { Transparency = 1 })
	local fill = Instance.new("PointLight")
	fill.Color, fill.Range, fill.Brightness, fill.Shadows, fill.Parent = hex("#ffdcb0"), 18, 0, false, fillPart

	-- smoke straight up from the chimney, heat shimmer over the kiln's shoulders, sparks at the fire door
	local chimPart = ctx.part(v3(1.6, 0.4, 1.6), CFrame.new(9, 14.0, 7), hex("#ffffff"), { Transparency = 1 })
	local smoke = ctx.emitter(chimPart, { Texture = S.SMOKE, Color = ColorSequence.new(hex("#cfc2ba")), Size = NumberSequence.new({ K(0, 1.3), K(1, 5.5) }), Transparency = NumberSequence.new({ K(0, 0.45), K(1, 1) }), Lifetime = NumberRange.new(6, 8), Speed = NumberRange.new(3, 4), EmissionDirection = Enum.NormalId.Top, SpreadAngle = Vector2.new(3, 3), LightEmission = 0, LightInfluence = 1, Rate = 5 })
	smoke:Emit(8)
	local shimPart = ctx.part(v3(5, 0.4, 5), CFrame.new(9, 8.6, 7), hex("#ffffff"), { Transparency = 1 })
	local shimmer = ctx.emitter(shimPart, { Texture = S.SMOKE, Color = ColorSequence.new(hex("#fff4e0")), Size = NumberSequence.new({ K(0, 1.6), K(1, 3.2) }), Transparency = NumberSequence.new({ K(0, 1), K(0.3, 0.92), K(1, 1) }), Lifetime = NumberRange.new(1, 1.5), Speed = NumberRange.new(3.5, 5), EmissionDirection = Enum.NormalId.Top, SpreadAngle = Vector2.new(6, 6), LightEmission = 0.3, LightInfluence = 0.6 })
	local emberPart = ctx.part(v3(1.8, 0.3, 0.3), CFrame.new(DOOR.X, 1.0, DOOR.Z - 0.3), hex("#ffffff"), { Transparency = 1 })
	local embers = ctx.emitter(emberPart, { Texture = S.SPARK, Color = ColorSequence.new(hex("#ffe58f"), hex("#ff7d4a")), Size = NumberSequence.new(0.2, 0), Transparency = NumberSequence.new(0, 1), Lifetime = NumberRange.new(0.8, 1.6), Speed = NumberRange.new(1.5, 4), SpreadAngle = Vector2.new(40, 40), Acceleration = v3(0, 2, -1.5), EmissionDirection = Enum.NormalId.Top })
	-- the teapot's steam: the spout points along the model's -X
	local spoutPart = ctx.part(v3(0.2, 0.2, 0.2), CFrame.new(5.7, 2.3, 4.0) * R(0, -72, 0) * CFrame.new(-0.86 * TEA_S, 0.78 * TEA_S, 0), hex("#ffffff"), { Transparency = 1 })
	local steam = ctx.emitter(spoutPart, { Texture = S.SMOKE, Color = ColorSequence.new(hex("#ffffff")), Size = NumberSequence.new({ K(0, 0.16), K(1, 1.1) }), Transparency = NumberSequence.new({ K(0, 0.25), K(1, 1) }), Lifetime = NumberRange.new(0.5, 0.8), Speed = NumberRange.new(7, 10), EmissionDirection = Enum.NormalId.Top, SpreadAngle = Vector2.new(10, 10), Acceleration = v3(-3, 2, -6), LightEmission = 0.4, LightInfluence = 0.6 })

	-- swallows over the terraces in the afternoon
	local swallows = {}
	for i = 1, 3 do swallows[i] = ctx.rig("Swallow", CFrame.new(0, -70, 0), 1.6) end

	-- ===== the cast =====
	local potter = ctx.rig("PotterKit", CFrame.new(0, -60, 0))
	potter:all(function(p) p.Material = Enum.Material.Rubber end)
	potter:show("EyesShut", false)
	local clay = ctx.rig("ClayHead", CFrame.new(0, -60, 0))
	clay:all(function(p) p.Material = Enum.Material.Rubber end)
	local jug = ctx.rig("GlazeJug", CFrame.new(0, -60, 0), 1.2)
	local trim = ctx.rig("TrimTool", CFrame.new(0, -60, 0), 1.1)
	for _, r in { jug, trim, teapot } do r:all(function(p) p.Material = Enum.Material.Rubber end) end
	local curls = {}
	for i = 1, 8 do curls[i] = { r = ctx.rig("ClayCurl", CFrame.new(0, -70, 0), 0.9), t0 = -1, from = Vector3.zero, vel = Vector3.zero, spin = 0 } end
	local curlN = 0
	local function tossCurl(from, t)
		curlN = curlN % #curls + 1
		local c = curls[curlN]
		local a = curlN * 2.4
		c.t0, c.from, c.vel, c.spin = t, from, v3(-2.4 + math.cos(a) * 1.4, 4.2 + (curlN % 3), -2.2 + math.sin(a) * 1.2), 300 + curlN * 40
	end
	local pick = ctx.pick()
	local pickScale0, pickH = 1, 5
	if pick then pickScale0, pickH = pick:GetScale(), math.max(pick:GetExtentsSize().Y, 0.1) pick:PivotTo(W(0, -60, 0)) end
	local function placePick(cf, height) -- stage-space frame, wanted height in studs
		if not pick then return end
		pick:ScaleTo(pickScale0 * height / pickH)
		pick:PivotTo(O * cf)
	end

	-- emitters that follow the work
	local digPart = ctx.part(v3(0.4, 0.4, 0.8), CFrame.new(-20.5, 0.9, -1.0), hex("#ffffff"), { Transparency = 1 })
	local dirt = ctx.emitter(digPart, { Texture = S.SMOKE, Color = ColorSequence.new(hex("#b5694a")), Size = NumberSequence.new({ K(0, 0.3), K(1, 1.3) }), Transparency = NumberSequence.new({ K(0, 0.3), K(1, 1) }), Lifetime = NumberRange.new(0.4, 0.8), Speed = NumberRange.new(4, 9), EmissionDirection = Enum.NormalId.Right, SpreadAngle = Vector2.new(35, 35), Acceleration = v3(0, -14, 0), LightEmission = 0, LightInfluence = 1, Drag = 2 })
	local clods = ctx.emitter(digPart, { Texture = S.GLOW, Color = ColorSequence.new(hex("#96533a")), Size = NumberSequence.new(0.2, 0.1), Transparency = NumberSequence.new(0, 0.4), Lifetime = NumberRange.new(0.4, 0.7), Speed = NumberRange.new(7, 13), EmissionDirection = Enum.NormalId.Right, SpreadAngle = Vector2.new(40, 40), Acceleration = v3(0, -40, 0), LightEmission = 0, LightInfluence = 1 })
	local slipPart = ctx.part(v3(0.9, 0.2, 0.9), CFrame.new(WHEEL.X, HEAD_Y + 0.25, WHEEL.Z), hex("#ffffff"), { Transparency = 1 })
	local slip = ctx.emitter(slipPart, { Texture = S.GLOW, Color = ColorSequence.new(hex("#c9b8a8")), Size = NumberSequence.new(0.14, 0.06), Transparency = NumberSequence.new(0.05, 0.5), Lifetime = NumberRange.new(0.35, 0.6), Speed = NumberRange.new(5, 10), EmissionDirection = Enum.NormalId.Top, SpreadAngle = Vector2.new(80, 80), Acceleration = v3(0, -34, 0), LightEmission = 0, LightInfluence = 1 })
	local lipPart = ctx.part(v3(0.12, 0.12, 0.12), CFrame.new(WHEEL.X + 0.25, HEAD_Y + 1.85, WHEEL.Z), hex("#ffffff"), { Transparency = 1 })
	local glazeFx = ctx.emitter(lipPart, { Texture = S.GLOW, Color = ColorSequence.new(hex("#4a6fa5")), Size = NumberSequence.new(0.17), Transparency = NumberSequence.new(0), Lifetime = NumberRange.new(0.2, 0.26), Speed = NumberRange.new(5, 7), EmissionDirection = Enum.NormalId.Bottom, SpreadAngle = Vector2.new(3, 3), Acceleration = v3(-2, -20, 0), LightEmission = 0, LightInfluence = 1 })
	local workPart = ctx.part(v3(0.3, 0.3, 0.3), CFrame.new(0, 2, 0), hex("#ffffff"), { Transparency = 1 })
	local sparkle = ctx.emitter(workPart, { Texture = S.SPARK, Color = ColorSequence.new(hex("#ffffff"), hex("#7fa3d4")), Size = NumberSequence.new({ K(0, 0), K(0.3, 0.6), K(1, 0) }), Transparency = NumberSequence.new(0, 1), Lifetime = NumberRange.new(0.5, 1), Speed = NumberRange.new(2, 7), SpreadAngle = Vector2.new(180, 180), Rotation = NumberRange.new(0, 360), Drag = 2 })
	local heroPart = ctx.part(v3(0.3, 0.3, 0.3), CFrame.new(HERO.X, 5.6, HERO.Z), hex("#ffffff"), { Transparency = 1 })
	local rays = Instance.new("BillboardGui")
	rays.Size, rays.LightInfluence, rays.Brightness, rays.Parent = UDim2.fromScale(13, 13), 0, 1.3, heroPart
	local raysIm = Instance.new("ImageLabel")
	raysIm.BackgroundTransparency, raysIm.Image, raysIm.ImageColor3, raysIm.ImageTransparency, raysIm.Size, raysIm.Parent = 1, "rbxassetid://98789616938156", hex("#ffe0a8"), 1, UDim2.fromScale(1, 1), rays
	local heroSpark = ctx.emitter(heroPart, { Texture = S.SPARK, Color = ColorSequence.new(hex("#ffffff"), hex("#ffb347")), Size = NumberSequence.new({ K(0, 0), K(0.3, 0.6), K(1, 0) }), Transparency = NumberSequence.new(0, 1), Lifetime = NumberRange.new(0.8, 1.6), Speed = NumberRange.new(2, 7), SpreadAngle = Vector2.new(180, 180), Rotation = NumberRange.new(0, 360), Drag = 1.5 })
	-- the ring of the fired clay, drawn in the air: wide soft rounds that swell from the pickaxe and fade
	local ringFx = ctx.emitter(heroPart, { Texture = S.GLOW, Color = ColorSequence.new(hex("#ffe9b0")), Size = NumberSequence.new({ K(0, 0.8), K(1, 9) }), Transparency = NumberSequence.new({ K(0, 0.55), K(1, 1) }), Lifetime = NumberRange.new(0.9, 1.1), Speed = NumberRange.new(0, 0.05), LightEmission = 0.6 })

	-- ===== looks: the low sun of the afternoon, the blue of the evening =====
	local LOOK = {
		afternoon = { Ambient = rgb(170, 140, 116), OutdoorAmbient = rgb(184, 156, 130), Brightness = 3.0, ColorShift_Top = rgb(255, 214, 160), ExposureCompensation = 0 },
		dusk = { Ambient = rgb(78, 70, 116), OutdoorAmbient = rgb(90, 82, 132), Brightness = 0.9, ColorShift_Top = rgb(190, 170, 235), ExposureCompensation = 0.2 },
	}
	local ATMO = {
		afternoon = { Density = 0.3, Haze = 2.0, Color = rgb(255, 214, 170), Decay = rgb(214, 150, 118), Glare = 0.25, Offset = 0.25 },
		dusk = { Density = 0.34, Haze = 2.2, Color = rgb(170, 124, 150), Decay = rgb(84, 74, 130), Glare = 0, Offset = 0.15 },
	}
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
	-- the afternoon sun is low, behind the camera's right shoulder: long shadows run toward the cliff and light comes in under
	-- the awning. In the evening the last sky light comes from over the terraces, and the fire door does the rest.
	local KEYS = { V(-0.7, 0.36, -0.3), V(0.35, 0.5, 0.6) }
	local keyNow = 0
	local function key(i) if keyNow ~= i then keyNow = i ctx.key(KEYS[i]) end end

	-- an event that belongs to its moment: it does not fire late when the story starts at NAMED or is skipped
	local function ev(name, at, t, fn) if t < at + 0.3 then ctx.once(name, at, t, fn) end end

	-- ===== the potter's acting =====
	local PAW_L, PAW_R = CFrame.new(-0.09, -0.5, -0.26), CFrame.new(0.09, -0.5, -0.26)
	local SIT = { LegL = R(74, 0, 10), LegR = R(62, 0, -16), Tail1 = R(-25, 0, 0), Tail2 = R(-20, 0, 0) }
	local STAND = { LegL = R(0, 0, 0), LegR = R(0, 0, 0), Tail1 = R(0, 0, 0), Tail2 = R(0, 0, 0) }
	local TRIMS = { 4.44, 4.6, 4.76 }
	local wkeys = {
		{ 2.2, { ArmL = R(60, 0, 18), ForeL = R(40, 0, 0), ArmR = R(60, 0, -18), ForeR = R(40, 0, 0), Head = R(10, 0, 0), Body = R(6, 0, 0) } },
		{ 2.52, { ArmL = R(160, 0, -10), ForeL = R(14, 0, 0), ArmR = R(160, 0, 10), ForeR = R(14, 0, 0), Head = R(-16, 0, 0), Body = R(-10, 0, 0) }, "out" },
		{ 2.7, { ArmL = R(52, 0, 20), ForeL = R(26, 0, 0), ArmR = R(52, 0, -20), ForeR = R(26, 0, 0), Head = R(26, 0, 0), Body = R(24, 0, 0) }, "in" },
		{ 2.84, { ArmL = R(60, 0, 22), ForeL = R(30, 0, 0), ArmR = R(60, 0, -22), ForeR = R(30, 0, 0), Head = R(16, 0, 0), Body = R(14, 0, 0) }, "back" },
		{ 3.2, { ArmL = R(50, 0, 16), ForeL = R(24, 0, 0), ArmR = R(50, 0, -16), ForeR = R(24, 0, 0), Head = R(18, 0, 0), Body = R(16, 0, 0) }, "inout" },
		{ 3.9, { ArmL = R(62, 0, 12), ForeL = R(20, 0, 0), ArmR = R(62, 0, -12), ForeR = R(20, 0, 0), Head = R(12, 0, 0), Body = R(12, 0, 0) }, "inout" },
		{ 4.3, { ArmL = R(68, 0, 10), ForeL = R(16, 0, 0), ArmR = R(40, 0, -12), ForeR = R(40, 0, 0), Head = R(22, 0, -6), Body = R(16, 4, 0) }, "inout" },
	}
	for _, at in TRIMS do
		table.insert(wkeys, { at - 0.07, { ArmR = R(34, 0, -20), ForeR = R(48, 0, 0) }, "out" })
		table.insert(wkeys, { at, { ArmR = R(44, 0, -8), ForeR = R(36, 0, 0) }, "in" })
	end
	table.insert(wkeys, { 4.92, { ArmL = R(30, 0, 22), ForeL = R(50, 0, 0), ArmR = R(60, 0, -24), ForeR = R(50, 0, 0), Head = R(8, 0, 0), Body = R(8, 0, 0) }, "inout" })
	table.insert(wkeys, { 5.06, { ArmR = R(124, 0, -28), ForeR = R(28, 0, 0), Head = R(4, -8, 0) }, "inout" })
	table.insert(wkeys, { 5.4, { ArmR = R(112, 0, -22), ForeR = R(40, 0, 0), Head = R(14, -6, 0) }, "inout" })
	table.insert(wkeys, { 5.5, { ArmR = R(60, 0, -24), ForeR = R(50, 0, 0), Head = R(6, 0, 0) }, "inout" })
	local wheelAct = S.track(wkeys)
	local kilnAct = S.track({
		{ 5.5, { ArmL = R(70, 0, 16), ForeL = R(30, 0, 0), ArmR = R(70, 0, -16), ForeR = R(30, 0, 0), Head = R(8, 0, 0), Body = R(6, 0, 0) } },
		{ 5.62, { ArmL = R(70, 0, 16), ForeL = R(30, 0, 0), ArmR = R(70, 0, -16), ForeR = R(30, 0, 0), Head = R(10, 0, 0), Body = R(8, 0, 0) }, "inout" },
		{ 5.8, { ArmL = R(92, 0, 8), ForeL = R(8, 0, 0), ArmR = R(92, 0, -8), ForeR = R(8, 0, 0), Head = R(14, 0, 0), Body = R(20, 0, 0) }, "inout" },
		{ 5.9, { ArmL = R(40, 0, 20), ForeL = R(40, 0, 0), ArmR = R(40, 0, -20), ForeR = R(40, 0, 0), Head = R(4, 0, 0), Body = R(4, 0, 0) }, "back" },
	})
	local waitAct = S.track({
		{ 5.9, { ArmL = R(30, 0, 16), ForeL = R(44, 0, 0), ArmR = R(30, 0, -16), ForeR = R(44, 0, 0), Head = R(4, 24, 0), Body = R(6, 10, 0) } },
		{ 6.88, { ArmL = R(30, 0, 16), ForeL = R(44, 0, 0), ArmR = R(30, 0, -16), ForeR = R(44, 0, 0), Head = R(6, 24, 0), Body = R(6, 10, 0) }, "inout" },
		{ 6.98, { ArmL = R(140, 0, -30), ForeL = R(50, 0, 0), ArmR = R(140, 0, 30), ForeR = R(50, 0, 0), Head = R(-14, -20, 0), Body = R(-10, -8, 0) }, "out" },
		{ 7.14, { ArmL = R(60, 0, 24), ForeL = R(70, 0, 0), ArmR = R(40, 0, -20), ForeR = R(50, 0, 0), Head = R(-4, 0, 0), Body = R(0, 0, 0) }, "inout" },
		{ 7.3, { Head = R(-22, 0, 6), Body = R(-8, 0, 0) }, "inout" },
		{ 7.5, { Head = R(-14, 0, -6), Body = R(-4, 0, 0) }, "inout" },
	})
	local named = S.track({
		{ 7.6, { ArmL = R(52, 0, 20), ForeL = R(44, 0, 0), ArmR = R(52, 0, -20), ForeR = R(44, 0, 0), Head = R(16, 0, 0), Body = R(8, 0, 0), LegL = R(0, 0, 0), LegR = R(0, 0, 0) } },
		{ 8.15, { ArmL = R(30, 0, 10), ForeL = R(70, 0, 0), ArmR = R(30, 0, -10), ForeR = R(70, 0, 0), Head = R(12, 0, 0), Body = R(14, 0, 0), LegL = R(-16, 0, 0), LegR = R(-16, 0, 0) }, "inout" },
		{ 8.45, { ArmL = R(166, 0, -8), ForeL = R(8, 0, 0), ArmR = R(60, 0, -30), ForeR = R(60, 0, 0), Head = R(-22, 8, 0), Body = R(-12, 0, 0), LegL = R(-8, 0, 8), LegR = R(-8, 0, -8) }, "back" },
		{ 8.8, { ArmR = R(96, 0, -40), ForeR = R(70, 0, 0) }, "inout" },
		{ 8.95, { ArmR = R(150, 0, 4), ForeR = R(24, 0, 0) }, "in" },
		{ 9.08, { ArmR = R(128, 0, -12), ForeR = R(40, 0, 0), Head = R(-20, 8, 10) }, "back" },
		{ 10.2, { ArmR = R(110, 0, -20), ForeR = R(50, 0, 0), Head = R(-24, 4, 12) }, "inout" },
	})
	-- as in ForgeWood: a positive first angle on Head and Body means "lean forward"; flipped here once for a model that faces -Z
	local function lean(p)
		for _, b in { "Head", "Body" } do
			local cf = p[b]
			if cf then local x, y, z = cf:ToEulerAnglesXYZ() p[b] = CFrame.Angles(-x, y, z) end
		end
		return p
	end

	-- sounds: this scene has none of its own yet. The fire loop and the bells are the Wood scene's files, the ring is the Stone
	-- scene's stone tap at a high pitch; there is no wheel hum, no wet slap and no kettle whistle (sfx names stand in).
	local SND = { fire = 129781180188795, dawn = 85010698086137, tap = 90326072989009 }
	local fireS = ctx.sound(SND.fire, 0, 1, true)
	local ang = 0 -- the wheel's turn, radians
	local slapT, hitT = 2.7, -1
	local TINKS = { 7.78, 7.94, 8.1, 8.26 }
	local RINGS = { 8.95, 9.07, 9.19 }

	return function(t, dt)
		-- ===== light, air, the fire =====
		local dusk = smooth(5.5, 6.4, t)
		local fire = 0.2 + 0.8 * smooth(5.75, 6.5, t)
		local white = smooth(6.3, 7.3, t)
		sky(t < 5.9 and "afternoon" or "dusk")
		key(t < 5.9 and 1 or 2)
		ctx.light(mixTo(LOOK.afternoon, LOOK.dusk, dusk))
		ctx.atmo(mixTo(ATMO.afternoon, ATMO.dusk, dusk))
		ctx.cc.TintColor = rgb(255, 244, 226):Lerp(rgb(236, 230, 255), dusk)
		ctx.cc.Saturation, ctx.cc.Contrast = -0.14, 0.06
		sunRays.Intensity = 0.06 * (1 - dusk)
		ripple.OffsetStudsU, ripple.OffsetStudsV = t * 1.4, math.sin(t * 0.4) * 2
		water.Color, water.Reflectance = hex("#a8452e"):Lerp(hex("#c9788a"), dusk), 0.16 + 0.2 * dusk
		local flick = 0.9 + 0.1 * math.sin(t * 11) + 0.04 * math.sin(t * 23)
		doorLight.Brightness = 2.8 * fire * flick
		peepLight.Brightness = 0.9 * white
		fill.Brightness = 1.3 * smooth(7.6, 7.9, t)
		yard:alpha("Door", 0.4 * (1 - smooth(5.75, 6.5, t)))
		if doorPart then doorPart.Color = hex("#ff8a3a"):Lerp(hex("#fff0c8"), smooth(5.9, 7.2, t)) end
		if peepPart then peepPart.Color = hex("#c8321e"):Lerp(hex("#ff9a3a"), smooth(6.0, 6.6, t)):Lerp(hex("#fffbe8"), white) end
		smoke.Rate = 5 + 7 * fire
		shimmer.Rate = 12 * fire
		embers.Rate = 14 * smooth(5.8, 6.5, t)
		fireS.Volume = (0.08 + 0.4 * smooth(5.75, 6.5, t)) * smooth(0, 0.4, t)
		yard:set("Washing", R(math.sin(t * 1.7) * 5, 0, math.sin(t * 1.1) * 2))
		for i, sw in swallows do
			if t < 5.9 then
				local a = t * (0.8 + i * 0.13) + i * 2.1
				local rad = 16 + i * 6
				sw.root = W(-8 + i * 12 + math.cos(a) * rad, 15 + i * 3 + math.sin(a * 2) * 2, 44 + i * 10 + math.sin(a) * rad) * R(0, 180 - math.deg(a), math.sin(a * 2) * 14)
				sw:set("WingL", R(0, 0, math.sin(t * 20 + i) * 38))
				sw:set("WingR", R(0, 0, -math.sin(t * 20 + i) * 38))
			else
				sw.root = W(0, -70, 0)
			end
		end

		-- ===== the wheel =====
		local w = 14 * smooth(2.75, 3.1, t) * (1 - 0.7 * smooth(4.85, 5.0, t)) * (1 - smooth(5.42, 5.9, t))
		ang += w * dt
		wheel:set("Wheel", CFrame.Angles(0, ang, 0))
		slip.Rate = (t >= 3.0 and t < 4.3) and 46 * (w / 14) or 0

		-- ===== the potter =====
		local breathe = math.sin(t * 2.6) * 0.012
		potter:size("Body", V(1 + breathe, 1 - breathe, 1 + breathe))
		local blink = (t % 2.3) < 0.1
		local laugh = t >= 7.18 and t < 7.58
		local shut = blink or laugh or (t >= 9.1)
		potter:show("Eyes", not shut) potter:show("EyesShut", shut)
		potter:size("Eyes", (t >= 6.92 and t < 7.14) and 1.35 or 1)
		potter:set("EarL", R(0, 0, math.sin(t * 3.1) * 4))
		potter:set("EarR", R(0, 0, -math.sin(t * 3.1 + 1) * 4))
		potter:set("Scarf", R(math.sin(t * 2.6) * 1.5, 0, 0))
		local phase = t < 2.2 and 0 or (t < 5.5 and 1 or (t < 5.9 and 2 or (t < 7.6 and 3 or 4)))
		if phase == 0 then -- at the bank, digging with both paws as only a mole can
			potter.root = W(DIG.X, DIG.Y, DIG.Z) * R(0, 90, 0)
			potter:pose(STAND)
			if t < 2.0 then
				local s = math.sin(t * 20)
				potter:pose(lean({ ArmL = R(64 + 34 * s, 0, 10), ForeL = R(30, 0, 0), ArmR = R(64 - 34 * s, 0, -10), ForeR = R(30, 0, 0), Head = R(22, 0, s * 4), Body = R(32, 0, 0) }))
			else
				potter:pose(lean({ ArmL = R(96, 0, 14), ForeL = R(30, 0, 0), ArmR = R(96, 0, -14), ForeR = R(30, 0, 0), Head = R(-6, 0, 0), Body = R(8, 0, 0) }))
			end
			potter:set("Tail1", R(0, math.sin(t * 14) * 16, 0)) potter:set("Tail2", R(0, math.sin(t * 14 - 0.8) * 20, 0))
			dirt.Rate, clods.Rate = (t >= 0.2 and t < 2.0) and 30 or 0, (t >= 0.2 and t < 2.0) and 22 or 0
			ev("lump", 2.0, t, function() dirt:Emit(14) clods:Emit(10) sfx("pop", 1.1) ctx.kick(1.4) end)
		elseif phase == 1 then -- at the wheel: the slap, the throwing, the trimming, the glaze
			dirt.Rate, clods.Rate = 0, 0
			potter.root = W(SEAT.X, SEAT.Y, SEAT.Z)
			potter:pose(SIT)
			local p = lean(wheelAct(t))
			if t >= 3.0 and t < 4.9 then p.Head = p.Head * R(0, math.sin(t * 5) * 7, math.sin(t * 5) * 5) end -- she hums: her head goes from side to side
			potter:pose(p)
			potter:set("LegR", R(62 - 14 * math.abs(math.sin(t * 9)) * (w / 14), 0, -16)) -- one foot kicks the flywheel
			potter:set("Tail1", R(-25, math.sin(t * 4) * 14, 0)) potter:set("Tail2", R(-20, math.sin(t * 4 - 0.8) * 18, 0))
		elseif phase == 2 then -- at the fire door
			potter.root = W(7.3, 0, 0.3) * R(0, -143, 0)
			potter:pose(STAND)
			potter:pose(lean(kilnAct(t)))
		elseif phase == 3 then -- on the chopping block while it burns; the teapot makes her jump
			local jump = math.sin(math.clamp((t - 6.9) / 0.22, 0, 1) * math.pi) * 0.5
			local shake = laugh and math.abs(math.sin(t * 26)) * 0.05 or 0
			potter.root = W(BLOCK.X, BLOCK.Y + jump + shake, BLOCK.Z) * R(0, -25, 0)
			potter:pose(SIT)
			local p = lean(waitAct(t))
			if t < 6.88 then p.Head = p.Head * R(0, 0, math.sin(t * 4.4) * 5) end
			potter:pose(p)
			potter:set("Tail1", R(-25, math.sin(t * 3) * 10, 0)) potter:set("Tail2", R(-20, math.sin(t * 3 - 0.8) * 14, 0))
		else -- NAMED: in front of the kiln, in the blue evening
			local hop = math.sin(math.clamp((t - 8.3) / 0.45, 0, 1) * math.pi) * 1.0
			potter.root = W(HERO.X, HERO.Y + hop, HERO.Z) * R(0, -18, 0)
			potter:pose(STAND)
			potter:pose(lean(named(t)))
			potter:set("Tail1", R(0, math.sin(t * 7) * 20, 0)) potter:set("Tail2", R(0, math.sin(t * 7 - 0.8) * 26, 0))
		end
		if phase ~= potter.phase then potter.phase = phase potter:snap() end
		local sinceHit = hitT > 0 and t - hitT or 1
		potter:smooth(dt, (phase == 0 or sinceHit < 0.1 or math.abs(t - slapT) < 0.12) and 34 or 13)
		potter:update()

		-- ===== the clay: lump, cone, the thrown head, the glaze, the crackle =====
		local pawL, pawR = (potter:joint("ForeL") * PAW_L).Position, (potter:joint("ForeR") * PAW_R).Position
		local paws = (pawL + pawR) / 2
		local onWheel = W(WHEEL.X, HEAD_Y, WHEEL.Z) * CFrame.Angles(0, ang, 0)
		local shaped = (t >= 3.9 and t < 5.82) or (t >= 7.6 and t < 8.45)
		clay:show("Lump", t >= 2.0 and t < 3.2)
		clay:show("Mid", t >= 3.2 and t < 3.9)
		clay:show("Shaped", shaped)
		clay:show("Glaze", shaped and t >= 5.0)
		clay:alpha("Glaze", t < 5.5 and 1 - smooth(5.05, 5.4, t) or 0)
		clay:show("Crackle", t >= 7.6 and t < 8.45)
		clay:alpha("Crackle", 1 - 0.95 * smooth(7.7, 8.3, t))
		local squash = t >= slapT and math.max(0, 1 - (t - slapT) / 0.3) or 0
		clay:size("Lump", V(1 + 0.25 * squash, 1 - 0.3 * squash, 1 + 0.25 * squash))
		local rise = smooth(3.2, 3.9, t)
		clay:size("Mid", V(1.15 - 0.15 * rise, 0.45 + 0.55 * rise, 1.15 - 0.15 * rise))
		local tall = (t < 5.5) and (0.82 + 0.18 * smooth(3.9, 4.3, t)) or 1
		clay:size("Shaped", V(1, tall, 1)) clay:size("Glaze", V(1, tall, 1))
		clay.scale = 1
		if t < 2.0 then
			clay.root = HIDE
		elseif t < slapT then -- in her paws: out of the bank, then up over her head at the wheel
			clay.root = CFrame.new(paws + V(0, -0.2, 0))
		elseif t < 5.5 then -- on the wheel; the lump runs a little off centre until her paws true it
			local off = 0.07 * (1 - smooth(2.9, 3.3, t))
			clay.root = onWheel * CFrame.new(off, 0, 0)
		elseif t < 5.82 then -- carried to the kiln and pushed into the fire
			local u = smooth(5.62, 5.8, t)
			clay.root = CFrame.new((paws + V(0, -0.5, 0)):Lerp(O:PointToWorldSpace(V(DOOR.X, 0.9, DOOR.Z + 0.6)), u))
			clay.scale = 1 - 0.3 * u
		elseif t < 7.6 then
			clay.root = HIDE
		elseif t < 8.45 then -- out of the kiln, cooling in her paws: the crackle spreads over the glaze
			clay.root = CFrame.new(paws + V(0, -0.45, 0))
			clay.scale = 0.9
		else
			clay.root = HIDE
		end
		ev("slap", slapT, t, function()
			slipPart.CFrame = W(WHEEL.X, HEAD_Y + 0.25, WHEEL.Z)
			slip:Emit(30) sfx("land", 0.9) sfx("pop", 0.7) ctx.hold(3 / 60) ctx.kick(2.2) ctx.shake(0.3)
		end)
		ev("cone", 3.2, t, function() slip:Emit(10) sfx("swing", 1.2) end)
		ev("head", 3.9, t, function() sparkle:Emit(8) sfx("pop", 1.3) end)

		-- the trimming: the loop tool at the foot of the head, ribbons of clay flying off
		if t >= 4.3 and t < 4.9 then
			trim.root = potter:joint("ForeR") * CFrame.new(0.09, -0.5, -0.3) * R(-100, 0, 0)
			for i, at in TRIMS do
				ev("trim" .. i, at, t, function()
					hitT = at
					local from = O:PointToWorldSpace(V(WHEEL.X + 0.35, HEAD_Y + 0.25, WHEEL.Z - 0.2))
					tossCurl(from, at) tossCurl(from + V(0, 0.1, 0), at + 0.02)
					sfx("swing", 1.5 + i * 0.1) ctx.kick(1.0)
				end)
			end
		else
			trim.root = HIDE
		end
		for _, c in curls do
			local u = t - c.t0
			if c.t0 > 0 and u >= 0 and u < 1.0 then
				c.r.root = CFrame.new(c.from + c.vel * u + V(0, -16 * u * u, 0)) * R(u * c.spin, u * c.spin * 0.7, 0)
				c.r:all(function(p) p.Transparency = math.clamp((u - 0.7) / 0.3, 0, 1) end)
			else
				c.r.root = HIDE
			end
		end

		-- the glaze, poured in one pass: the jug tips about its lip, which stays over the head
		if t >= 4.95 and t < 5.5 then
			local tilt = 78 * smooth(5.02, 5.14, t) * (1 - smooth(5.38, 5.48, t))
			local lip = W(WHEEL.X + 0.25, HEAD_Y + 1.85, WHEEL.Z)
			jug.root = lip * R(0, 0, tilt) * CFrame.new(0.36 * 1.2, -0.9 * 1.2, 0)
			glazeFx.Rate = (t >= 5.08 and t < 5.4) and 90 or 0
			ev("pour", 5.08, t, function() sfx("swing", 0.8) end)
		else
			jug.root = HIDE
			glazeFx.Rate = 0
		end
		ev("shut", 5.82, t, function() embers:Emit(16) sfx("land", 1.2) ctx.kick(1.4) end)

		-- the teapot: steam, a rattling lid, and her fright
		local whistle = t >= 6.9 and t < 7.5
		steam.Rate = whistle and 90 or ((t >= 6.4 and t < 6.9) and 8 or 0)
		teapot:set("Lid", whistle and CFrame.new(0, 0.05 * math.abs(math.sin(t * 50)), 0) * R(math.sin(t * 60) * 5, 0, 0) or CFrame.new())
		ev("whistle", 6.9, t, function() sfx("sparkle", 2.0) ctx.sound(SND.tap, 0.2, 3.0) sfx("pop", 1.6) ctx.kick(1.6) end)
		ev("laugh", 7.2, t, function() sfx("pop", 1.2) end)

		-- ===== NAMED: the crackle, the lift, the tap, the ring =====
		if t >= 7.6 then
			workPart.CFrame = CFrame.new(paws)
			for i, at in TINKS do
				ev("tink" .. i, at, t, function() sparkle:Emit(4) ctx.sound(SND.tap, 0.22, 2.6 + i * 0.15) end)
			end
			local lift = smooth(8.45, 9.0, t)
			if t >= 8.45 then
				local at = O:PointToObjectSpace(pawL) + V(0, 0.55 + 0.5 * lift, -0.25)
				local sinceRing = t - RINGS[1]
				local shiver = sinceRing >= 0 and math.sin(sinceRing * 60) * 5 * math.exp(-sinceRing * 4) or 0
				local spin = smooth(9.5, 10.7, t) * 360
				placePick(CFrame.new(at) * R(0, 180 + spin, -20 + shiver), 2.9 + 0.7 * lift)
				heroPart.CFrame = W(at.X, at.Y + 0.6, at.Z)
			else
				placePick(CFrame.new(0, -60, 0), 2.9)
			end
			raysIm.ImageTransparency = 1 - 0.7 * smooth(8.45, 8.8, t) * (1 - smooth(10.6, 11.1, t))
			raysIm.Rotation = t * 22
			ctx.once("reveal", 8.45, t, function() heroSpark:Emit(40) sfx("sparkle", 1.3) sfx("pop", 1.4) ctx.kick(4) ctx.hold(4 / 60) end)
			for i, at in RINGS do
				ctx.once("ring" .. i, at, t, function()
					ringFx:Emit(1)
					if i == 1 then
						hitT = at
						ctx.sound(SND.tap, 0.7, 2.2) ctx.sound(SND.dawn, 0.5, 1.2) heroSpark:Emit(14) ctx.kick(2.4) ctx.hold(3 / 60)
					end
				end)
			end
			heroSpark.Rate = t >= 9.0 and 7 or 0
			ctx.name("Fired once, right.")
			ctx.cardAlpha = smooth(9.2, 9.55, t) * (1 - smooth(10.7, 11.0, t))
		else
			placePick(CFrame.new(0, -60, 0), 2.9)
		end
		ctx.flashAlpha = math.max(0.15 * (1 - lin(slapT, slapT + 0.16, t)) * (t >= slapT and 1 or 0), 0.85 * (1 - lin(8.45, 8.8, t)) * (t >= 8.45 and 1 or 0))

		-- ===== chapters and camera =====
		if t >= 0.35 and t < 3.0 then ctx.chapter(1, "BORN", "Wet clay, dug from the terrace and slapped onto the wheel.")
		elseif t >= 3.2 and t < 7.6 then ctx.chapter(2, "MADE", "Thrown, trimmed, glazed and fired. The teapot whistles when it is done.")
		elseif t >= 7.8 then ctx.chapter(3, "NAMED", "She taps it, and it rings like a bell.") end
		local cf, fov, focus
		local function shot(from, aim, f) cf, fov, focus = CFrame.lookAt(from, aim), f, (from - aim).Magnitude end
		if t < 1.2 then -- the yard from above: the kiln, the awning, the terraces falling away to the red river
			local u = smooth(0, 1.2, t)
			shot(V(-15 + 7 * u, 13 - 8 * u, -30 + 11 * u), V(3, 3 - 0.5 * u, 12 + 6 * u), 56 - 6 * u)
		elseif t < 2.2 then -- from on top of the bank, down at her digging
			shot(V(-24.5, 4.2, -6.5 + 0.6 * smooth(1.2, 2.2, t)), V(-19.8, 1.0, -1.0), 44)
		elseif t < 3.0 then -- the wheel: up goes the lump, down it comes
			shot(V(-0.4, 2.7, -9.0 + 0.8 * smooth(2.2, 3.0, t)), V(-1.5, 2.6, 0.6), 46)
		elseif t < 4.3 then -- close: the clay rising between her paws
			shot(V(-0.9 + 0.3 * smooth(3.0, 4.3, t), 2.7, -5.6), V(-1.5, 2.2, 0.3), 36)
		elseif t < 4.9 then -- low and to one side for the trimming
			shot(V(1.6, 1.9, -4.2), V(-1.5, 2.0, 0.2), 36)
		elseif t < 5.5 then -- front on: the glaze in one pass
			shot(V(-2.2, 2.9, -6.6 + 0.4 * smooth(4.9, 5.5, t)), V(-1.5, 2.5, 0.5), 40)
		elseif t < 5.9 then -- into the fire
			shot(V(3.2, 2.6, -5.6), V(8.2, 2.0, 2.0), 46)
		elseif t < 6.85 then -- the blue evening: the whole yard painted by the fire door
			local u = smooth(5.9, 6.85, t)
			shot(V(-7 + 0.8 * u, 3.4, -16 + 1.2 * u), V(6.0, 3.2, 3.0), 50)
		elseif t < 7.6 then -- her, and the teapot on its ledge behind her
			shot(V(2.2, 2.3, -6.6 + 0.3 * smooth(6.85, 7.6, t)), V(5.4, 2.3, 1.2), 40)
		else -- low at her feet, the kiln and the evening sky behind her
			local up = smooth(8.3, 9.2, t)
			local s = smooth(8.4, 10.8, t)
			shot(V(3.0 - 0.3 * s, 0.8, -11.2 + 0.8 * s), V(HERO.X, 2.4, HERO.Z):Lerp(V(HERO.X, 4.8, HERO.Z), up), 58 - 2 * s)
		end
		ctx.cam, ctx.fov = O * cf, fov
		ctx.dof.FocusDistance = focus
		ctx.dof.InFocusRadius, ctx.dof.FarIntensity, ctx.dof.NearIntensity = 400, 0, 0
	end
end

return M
