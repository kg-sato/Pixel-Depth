-- ReplicatedStorage.Shared.ForgeBog (src/ForgeBog.luau): the Bog-Iron Pickaxe biography, played by ForgeStory.
-- BORN: rusty nodules under the lily pads in the dawn mist; a frog nets them from the plank walkway. MADE: he stacks the clay
-- chimney, jumps on the bellows with his whole body until the stack roars and rakes out a glowing bloom; while it cools, moss
-- and a mushroom move in. NAMED: morning, he tugs the finished pickaxe out of the mud. "The bog wanted it back."
-- Nothing here is shared with another scene. The setting is a place of its own (scene bible "Bog-Iron"; reference
-- refs/forge/sheets/bog_setting_s11.png): a blackwater bog ringed by dead silver trees, a tiny island with the furnace, a plank
-- walkway across lily pads, a dark pine line beyond the mist. It is built from design3d/bog.mjs and bog_world.py (terrain,
-- pictures, the map of every tree in ForgeBogMap). The water reflects: tall things have an upside-down twin under a clear dark
-- sheet, and the sky pictures carry the mirrored sky in their lower half.
-- Space: front of a model is -Z, the camera stands at -Z and looks toward +Z. The models and the map are authored with x to
-- screen right and z toward the camera, so every place in this file goes through A(x, y, z), which flips x and z.
-- Pace: the story's clock runs at 0.58 of real time; every time in this file is a story second. No blur anywhere.
local M = { length = 11.2, named = 7.6, open = true, pace = 0.58, fastPace = 0.75 }
-- pictures made by design3d/bog_world.py: design3d/tex/bog_sky_<look>_side.png, _up.png, _dn.png (ids to be filled in after upload)
local IMG = {
	mist = { side = "71358875792381", up = "89444930502808", dn = "121914463396689" },
	fire = { side = "98224934611845", up = "128666251386950", dn = "82798387632006" },
	morning = { side = "82500581528706", up = "86966216231522", dn = "97760956161507", sun = 6 },
	ripple = "rbxassetid://108008922454214",
}

local function hex(h) return Color3.fromHex(h) end
local function v3(x, y, z) return Vector3.new(x, y, z) end
local function A(x, y, z) return Vector3.new(-x, y, -z) end

function M.setup(ctx)
	local S = ctx.S
	local R, smooth, backOut = S.rot, S.smooth, S.backOut
	local O, sfx = ctx.O, ctx.sfx
	local function W(p) return O * CFrame.new(p) end
	local K = NumberSequenceKeypoint.new
	local rgb = Color3.fromRGB

	-- the place: ground and moor, then every dead tree, spruce, lily raft, cotton grass tuft and rock from the map
	local MAP = require(script.Parent:WaitForChild("ForgeBogMap"))
	local WY = MAP.waterY
	local land = ctx.prop("BogWorld")
	land:all(function(p) p.Material = Enum.Material.Rubber end)
	for _, it in MAP.items do
		local cf = CFrame.new(it[2], it[3], it[4]) * CFrame.Angles(0, math.rad(it[5]), 0)
		local r = ctx.prop(it[1], cf, it[6], it[7] and WY or nil)
		r:all(function(p) if p.Material ~= Enum.Material.Neon then p.Material = Enum.Material.Rubber end end)
	end
	-- the black water: a clear dark sheet over the open bog, with slow ripples drawn on it
	local water = ctx.part(v3(230, 0.2, 230), CFrame.new(0, WY - 0.1, 62), hex("#17121a"), { Transparency = 0.42, Reflectance = 0.14 })
	local ripple = Instance.new("Texture")
	ripple.Texture, ripple.Face, ripple.StudsPerTileU, ripple.StudsPerTileV, ripple.Transparency, ripple.Parent = IMG.ripple, Enum.NormalId.Top, 64, 40, 0.88, water

	-- the island's things
	local set = ctx.rig("BogSet")
	local bloomPart, slagPart
	set:all(function(p, b)
		if b.name == "Bloom" then bloomPart = p elseif b.name == "Slag" then slagPart = p end
		if p.Material ~= Enum.Material.Neon then p.Material = Enum.Material.Rubber end
	end)
	set:set("Mirror", CFrame.new(0, 2 * WY, 0))
	local frog = ctx.rig("FrogKit", CFrame.new(A(-15.5, 0.08, 1.9)))
	frog:all(function(p) if p.Material ~= Enum.Material.Neon then p.Material = Enum.Material.Rubber end end)
	local net = ctx.rig("BogNet", CFrame.new(0, -50, 0), 0.85)
	local ore = ctx.rig("OreNodule", CFrame.new(0, -50, 0), 0.9)
	local charm = ctx.rig("MushroomCharm", CFrame.new(0, -50, 0), 1)
	local pick = ctx.pick()
	local pickScale0, pickH = 1, 5
	if pick then pickScale0, pickH = pick:GetScale(), math.max(pick:GetExtentsSize().Y, 0.1) pick:PivotTo(O * CFrame.new(0, -60, 0)) end
	local function placePick(cf, height)
		if not pick then return end
		pick:ScaleTo(pickScale0 * height / pickH)
		pick:PivotTo(O * cf)
	end
	frog:show("EyesShut", false)

	-- places (authoring space)
	local FUR = v3(1.6, 0, -0.8)
	local MOUTH = v3(1.6, 0.7, 0.55)
	local THROAT = v3(1.6, 4.3, -0.8)
	local PADS = v3(-16.1, WY, 4.9)
	local BLOOM_AT = v3(0.6, 0.3, 2.0)
	local STUCK = v3(-5.1, -0.1, 9.3)
	local MUD_Y = -0.6
	local HERO = v3(-4.6, 0, 8.3)

	-- the furnace's light, its glow on the water and its fire
	local mouthPart = ctx.part(v3(0.4, 0.4, 0.4), CFrame.new(A(MOUTH.X - 0.3, MOUTH.Y + 0.5, MOUTH.Z + 1.2)), hex("#ffb14a"), { Transparency = 1 })
	local fireLight = Instance.new("PointLight")
	fireLight.Color, fireLight.Range, fireLight.Brightness, fireLight.Shadows, fireLight.Parent = hex("#ff8c3a"), 22, 0, true, mouthPart
	local throatPart = ctx.part(v3(0.9, 0.2, 0.9), CFrame.new(A(THROAT.X, THROAT.Y, THROAT.Z)), hex("#ffb14a"), { Transparency = 1 })
	local topLight = Instance.new("PointLight")
	topLight.Color, topLight.Range, topLight.Brightness, topLight.Shadows, topLight.Parent = hex("#ff9c50"), 30, 0, false, throatPart
	local glints = {}
	for k = 1, 9 do
		local p = ctx.part(v3(2.6 - k * 0.2, 0.04, 0.5 + (k % 3) * 0.3), CFrame.new(A(1.5 + math.sin(k * 2.1) * 0.5, WY + 0.05, 13.0 + k * 1.15)), hex("#ff9a48"), { Material = Enum.Material.Neon, Transparency = 1 })
		glints[k] = p
	end
	local flame = ctx.emitter(throatPart, { Texture = S.FIRE, Color = ColorSequence.new(hex("#ffd070"), hex("#f2601c")), Size = NumberSequence.new({ K(0, 1.1), K(1, 0.1) }), Transparency = NumberSequence.new({ K(0, 0.1), K(1, 1) }), Lifetime = NumberRange.new(0.3, 0.6), Speed = NumberRange.new(5, 10), SpreadAngle = Vector2.new(8, 8), Rotation = NumberRange.new(0, 360), EmissionDirection = Enum.NormalId.Top })
	local sparks = ctx.emitter(throatPart, { Texture = S.SPARK, Color = ColorSequence.new(hex("#ffe58f"), hex("#ff6a2a")), Size = NumberSequence.new(0.26, 0), Transparency = NumberSequence.new(0, 1), Lifetime = NumberRange.new(0.8, 1.9), Speed = NumberRange.new(9, 18), SpreadAngle = Vector2.new(26, 26), Acceleration = v3(0, -14, 0), Drag = 0.6, EmissionDirection = Enum.NormalId.Top })
	local smoke = ctx.emitter(throatPart, { Texture = S.SMOKE, Color = ColorSequence.new(hex("#8a8f96")), LightEmission = 0, Size = NumberSequence.new({ K(0, 0.9), K(1, 5) }), Transparency = NumberSequence.new({ K(0, 0.55), K(1, 1) }), Lifetime = NumberRange.new(3, 5), Speed = NumberRange.new(2, 4), SpreadAngle = Vector2.new(10, 10), Rotation = NumberRange.new(0, 360), EmissionDirection = Enum.NormalId.Top })
	local nozzlePart = ctx.part(v3(0.3, 0.3, 0.3), CFrame.new(A(-1.2, 0.5, 0.3)), hex("#ffffff"), { Transparency = 1 })
	local puff = ctx.emitter(nozzlePart, { Texture = S.SMOKE, Color = ColorSequence.new(hex("#e6dccb")), Size = NumberSequence.new({ K(0, 0.3), K(1, 1.6) }), Transparency = NumberSequence.new({ K(0, 0.6), K(1, 1) }), Lifetime = NumberRange.new(0.4, 0.8), Speed = NumberRange.new(2, 5), SpreadAngle = Vector2.new(180, 30), Rotation = NumberRange.new(0, 360), Drag = 3 })
	local steamPart = ctx.part(v3(9, 0.2, 5), CFrame.new(A(0, WY + 0.2, 13.5)), hex("#ffffff"), { Transparency = 1 })
	local steam = ctx.emitter(steamPart, { Texture = S.SMOKE, Color = ColorSequence.new(hex("#f2ece4")), Size = NumberSequence.new({ K(0, 0.3), K(1, 1.8) }), Transparency = NumberSequence.new({ K(0, 0.5), K(1, 1) }), Lifetime = NumberRange.new(0.7, 1.4), Speed = NumberRange.new(1.5, 3.5), SpreadAngle = Vector2.new(12, 12), Rotation = NumberRange.new(0, 360), EmissionDirection = Enum.NormalId.Top })
	-- the air: mist in layers on the water, pale wisps of light over it, gnats, slow rings
	local mistPart = ctx.part(v3(150, 1, 110), CFrame.new(0, WY + 1.6, 34), hex("#ffffff"), { Transparency = 1 })
	local mist = ctx.emitter(mistPart, { Texture = S.SMOKE, Color = ColorSequence.new(hex("#e6dce6")), Size = NumberSequence.new({ K(0, 10), K(1, 19) }), Transparency = NumberSequence.new({ K(0, 1), K(0.25, 0.86), K(0.75, 0.88), K(1, 1) }), Lifetime = NumberRange.new(9, 14), Speed = NumberRange.new(0.3, 0.9), SpreadAngle = Vector2.new(180, 4), Rotation = NumberRange.new(0, 360), RotSpeed = NumberRange.new(-4, 4), Rate = 5 })
	local nearMistPart = ctx.part(v3(60, 0.6, 30), CFrame.new(0, WY + 0.7, -6), hex("#ffffff"), { Transparency = 1 })
	local nearMist = ctx.emitter(nearMistPart, { Texture = S.SMOKE, Color = ColorSequence.new(hex("#eef0ea")), Size = NumberSequence.new({ K(0, 4), K(1, 8) }), Transparency = NumberSequence.new({ K(0, 1), K(0.3, 0.9), K(0.7, 0.92), K(1, 1) }), Lifetime = NumberRange.new(7, 10), Speed = NumberRange.new(0.2, 0.6), SpreadAngle = Vector2.new(180, 3), Rotation = NumberRange.new(0, 360), Rate = 3 })
	local wispPart = ctx.part(v3(90, 3, 50), CFrame.new(0, WY + 2.4, 40), hex("#ffffff"), { Transparency = 1 })
	local wisps = ctx.emitter(wispPart, { Texture = S.GLOW, Color = ColorSequence.new(hex("#dff7e6")), Size = NumberSequence.new({ K(0, 0), K(0.3, 0.7), K(0.7, 0.5), K(1, 0) }), Transparency = NumberSequence.new({ K(0, 1), K(0.3, 0.3), K(1, 1) }), Lifetime = NumberRange.new(4, 7), Speed = NumberRange.new(0.2, 0.7), SpreadAngle = Vector2.new(180, 180), Rate = 3 })
	local gnatPart = ctx.part(v3(26, 2.5, 12), CFrame.new(A(-8, 2.2, 4)), hex("#ffffff"), { Transparency = 1 })
	local gnats = ctx.emitter(gnatPart, { Texture = S.GLOW, Color = ColorSequence.new(hex("#2a2a20")), LightEmission = 0, Size = NumberSequence.new(0.07), Transparency = NumberSequence.new({ K(0, 1), K(0.2, 0.1), K(0.8, 0.1), K(1, 1) }), Lifetime = NumberRange.new(1.5, 3), Speed = NumberRange.new(0.8, 2.2), SpreadAngle = Vector2.new(180, 180), Acceleration = v3(0, 0.4, 0), Rate = 14 })
	local ringPart = ctx.part(v3(70, 0.2, 40), CFrame.new(0, WY + 0.06, -18), hex("#ffffff"), { Transparency = 1 })
	local rings = ctx.emitter(ringPart, { Texture = S.GLOW, Color = ColorSequence.new(hex("#c9d6cf")), Size = NumberSequence.new({ K(0, 0.2), K(1, 2.6) }), Transparency = NumberSequence.new({ K(0, 0.6), K(1, 1) }), Lifetime = NumberRange.new(1.4, 2.2), Speed = NumberRange.new(0.01), Orientation = Enum.ParticleOrientation.VelocityPerpendicular, EmissionDirection = Enum.NormalId.Top, Rate = 4 })
	-- the work's own small effects
	local workPart = ctx.part(v3(0.3, 0.3, 0.3), CFrame.new(A(PADS.X, PADS.Y, PADS.Z)), hex("#ffffff"), { Transparency = 1 })
	local drips = ctx.emitter(workPart, { Texture = S.GLOW, Color = ColorSequence.new(hex("#cfe0e6")), Size = NumberSequence.new(0.12, 0.04), Transparency = NumberSequence.new(0.2, 0.8), Lifetime = NumberRange.new(0.35, 0.6), Speed = NumberRange.new(0.2, 1), SpreadAngle = Vector2.new(180, 180), Acceleration = v3(0, -22, 0) })
	local splash = ctx.emitter(workPart, { Texture = S.GLOW, Color = ColorSequence.new(hex("#dfe8e8")), Size = NumberSequence.new({ K(0, 0.1), K(1, 0.5) }), Transparency = NumberSequence.new({ K(0, 0.3), K(1, 1) }), Lifetime = NumberRange.new(0.3, 0.6), Speed = NumberRange.new(3, 7), SpreadAngle = Vector2.new(50, 50), Acceleration = v3(0, -20, 0), EmissionDirection = Enum.NormalId.Top })
	local mud = ctx.emitter(workPart, { Texture = S.GLOW, Color = ColorSequence.new(hex("#3a2c22")), LightEmission = 0, Size = NumberSequence.new(0.22, 0.08), Transparency = NumberSequence.new(0, 0.6), Lifetime = NumberRange.new(0.5, 0.9), Speed = NumberRange.new(4, 9), SpreadAngle = Vector2.new(60, 60), Acceleration = v3(0, -26, 0), EmissionDirection = Enum.NormalId.Top })
	local dust = ctx.emitter(workPart, { Texture = S.SMOKE, Color = ColorSequence.new(hex("#d9c4a8")), Size = NumberSequence.new({ K(0, 0.4), K(1, 1.8) }), Transparency = NumberSequence.new({ K(0, 0.6), K(1, 1) }), Lifetime = NumberRange.new(0.4, 0.9), Speed = NumberRange.new(1, 3), SpreadAngle = Vector2.new(180, 180), Rotation = NumberRange.new(0, 360), Drag = 2 })
	local sparkle = ctx.emitter(workPart, { Texture = S.SPARK, Color = ColorSequence.new(hex("#ffffff"), hex("#ffd9a0")), Size = NumberSequence.new({ K(0, 0), K(0.3, 0.6), K(1, 0) }), Transparency = NumberSequence.new(0, 1), Lifetime = NumberRange.new(0.7, 1.5), Speed = NumberRange.new(2, 7), SpreadAngle = Vector2.new(180, 180), Rotation = NumberRange.new(0, 360), Drag = 1.5 })
	local mudString = ctx.part(v3(0.1, 1, 0.1), CFrame.new(0, -50, 0), hex("#3a2c22"), { Transparency = 1, Shape = Enum.PartType.Cylinder })
	local sunRays = ctx.effect("SunRaysEffect", { Intensity = 0, Spread = 0.8 })

	-- the frog's acting. A positive first angle on Head and Body means "lean forward" (see lean below); arms: positive X is
	-- forward and up, ArmL turns inward with +Z, ArmR with -Z
	local born = S.track({
		{ 0, { ArmR = R(54, 0, -8), ForeR = R(40, 0, 0), ArmL = R(40, 0, 16), ForeL = R(50, 0, 0), Head = R(8, 10, 0), Body = R(8, 6, 0), LegL = R(0, 0, 0), LegR = R(0, 0, 0) } },
		{ 1.1, { ArmR = R(60, 0, -10), ForeR = R(36, 0, 0), Head = R(14, 14, 0), Body = R(12, 8, 0) }, "inout" },
		{ 1.5, { ArmR = R(40, 0, -6), ForeR = R(16, 0, 0), ArmL = R(52, 0, 22), ForeL = R(24, 0, 0), Head = R(26, 12, 0), Body = R(26, 8, 0), LegL = R(-14, 0, 0), LegR = R(-14, 0, 0) }, "inout" },
		{ 1.72, { ArmR = R(44, 0, -6), ForeR = R(20, 0, 0), Head = R(24, 12, 0), Body = R(24, 8, 0) }, "inout" },
		{ 2.0, { ArmR = R(96, 0, -14), ForeR = R(50, 0, 0), ArmL = R(84, 0, 24), ForeL = R(56, 0, 0), Head = R(-10, 8, 0), Body = R(-6, 4, 0), LegL = R(0, 0, 0), LegR = R(0, 0, 0) }, "back" },
		{ 2.4, { ArmR = R(84, 0, -24), ForeR = R(76, 0, 0), ArmL = R(70, 0, 30), ForeL = R(70, 0, 0), Head = R(10, -6, 4), Body = R(4, 0, 0) }, "inout" },
		{ 2.8, { Head = R(4, -8, -6), Body = R(0, 0, 0) }, "inout" },
	})
	local JUMPS = { 4.45, 4.85, 5.2, 5.5, 5.75 }
	local made = S.track({
		{ 3.0, { ArmR = R(20, 0, -10), ForeR = R(30, 0, 0), ArmL = R(20, 0, 10), ForeL = R(30, 0, 0), Head = R(-12, 0, 0), Body = R(-4, 0, 0), LegL = R(0, 0, 0), LegR = R(0, 0, 0) } },
		{ 3.2, { ArmR = R(150, 0, 10), ForeR = R(20, 0, 0), ArmL = R(150, 0, -10), ForeL = R(20, 0, 0), Head = R(-24, 0, 0), Body = R(-10, 0, 0) }, "out" },
		{ 3.36, { ArmR = R(110, 0, -6), ForeR = R(50, 0, 0), ArmL = R(110, 0, 6), ForeL = R(50, 0, 0), Head = R(-10, 0, 0), Body = R(4, 0, 0) }, "back" },
		{ 3.55, { ArmR = R(156, 0, 10), ForeR = R(16, 0, 0), ArmL = R(156, 0, -10), ForeL = R(16, 0, 0), Head = R(-28, 0, 0), Body = R(-12, 0, 0) }, "out" },
		{ 3.72, { ArmR = R(120, 0, -6), ForeR = R(46, 0, 0), ArmL = R(120, 0, 6), ForeL = R(46, 0, 0), Head = R(-14, 0, 0), Body = R(2, 0, 0) }, "back" },
		{ 4.05, { ArmR = R(30, 0, -30), ForeR = R(70, 0, 0), ArmL = R(30, 0, 30), ForeL = R(70, 0, 0), Head = R(8, 20, 0), Body = R(10, 10, 0) }, "inout" },
		{ 4.2, { ArmR = R(-30, 0, -20), ForeR = R(30, 0, 0), ArmL = R(-30, 0, 20), ForeL = R(30, 0, 0), Head = R(14, 0, 0), Body = R(16, 0, 0), LegL = R(-20, 0, 0), LegR = R(-20, 0, 0) }, "inout" },
		{ 5.9, { ArmR = R(60, 0, -10), ForeR = R(30, 0, 0), ArmL = R(50, 0, 14), ForeL = R(40, 0, 0), Head = R(10, 10, 0), Body = R(12, 6, 0), LegL = R(0, 0, 0), LegR = R(0, 0, 0) }, "hold" },
		{ 6.3, { ArmR = R(40, 0, -16), ForeR = R(70, 0, 0), ArmL = R(36, 0, 20), ForeL = R(70, 0, 0), Head = R(16, 6, 0), Body = R(4, 0, 0) }, "inout" },
		{ 6.6, { ArmR = R(10, 0, -24), ForeR = R(40, 0, 0), ArmL = R(10, 0, 24), ForeL = R(40, 0, 0), Head = R(14, -8, 6), Body = R(-10, 0, 0), LegL = R(82, 0, 12), LegR = R(74, 0, -14) }, "hold" },
		{ 7.2, { Head = R(22, -10, 8), Body = R(-12, 0, 0) }, "inout" },
		{ 7.32, { Head = R(-6, 16, 0), Body = R(-4, 0, 0), ArmL = R(40, 0, 10), ForeL = R(50, 0, 0) }, "back" },
	})
	local named = S.track({
		{ 7.6, { ArmL = R(64, 0, 22), ForeL = R(24, 0, 0), ArmR = R(64, 0, -22), ForeR = R(24, 0, 0), Head = R(16, 0, 0), Body = R(18, 0, 0), LegL = R(-12, 0, 6), LegR = R(-12, 0, -6) } },
		{ 7.85, { Head = R(20, 0, 0), Body = R(22, 0, 0) }, "inout" },
		{ 8.0, { ArmL = R(84, 0, 20), ForeL = R(10, 0, 0), ArmR = R(84, 0, -20), ForeR = R(10, 0, 0), Head = R(-14, 0, 0), Body = R(-20, 0, 0), LegL = R(20, 0, 6), LegR = R(20, 0, -6) }, "out" },
		{ 8.15, { ArmL = R(60, 0, 22), ForeL = R(26, 0, 0), ArmR = R(60, 0, -22), ForeR = R(26, 0, 0), Head = R(24, 0, 0), Body = R(26, 0, 0), LegL = R(-16, 0, 6), LegR = R(-16, 0, -6) }, "in" },
		{ 8.42, { ArmL = R(92, 0, 18), ForeL = R(6, 0, 0), ArmR = R(92, 0, -18), ForeR = R(6, 0, 0), Head = R(-24, 0, 0), Body = R(-30, 0, 0), LegL = R(30, 0, 8), LegR = R(30, 0, -8) }, "out" },
		{ 8.75, { ArmL = R(120, 0, -30), ForeL = R(30, 0, 0), ArmR = R(170, 0, 10), ForeR = R(6, 0, 0), Head = R(-22, -10, 8), Body = R(-14, -8, 5), LegL = R(-10, 0, 10), LegR = R(14, 0, -8) }, "back" },
		{ 9.5, { ArmL = R(60, 0, -56), ForeL = R(70, 0, 0), ArmR = R(166, 0, 14), Head = R(-18, -12, 8), Body = R(-12, -8, 5) }, "inout" },
		{ 10.3, { ArmR = R(160, 0, 20), Head = R(-22, -6, 6) }, "inout" },
	})
	local function lean(p)
		for _, b in { "Head", "Body" } do
			local cf = p[b]
			if cf then local x, y, z = cf:ToEulerAnglesXYZ() p[b] = CFrame.Angles(-x, y, z) end
		end
		return p
	end

	-- lighting looks (colours measured on refs/forge/sheets/bog_setting_s11.png: peach sky, lilac mist, purple-black water): milky dawn, the dim hour while the furnace burns, clear morning
	local LOOK = {
		mist = { Ambient = rgb(164, 152, 158), OutdoorAmbient = rgb(172, 160, 166), Brightness = 0.6, ColorShift_Top = rgb(255, 226, 214), ExposureCompensation = 0.1 },
		fire = { Ambient = rgb(80, 74, 96), OutdoorAmbient = rgb(88, 82, 104), Brightness = 0.5, ColorShift_Top = rgb(204, 176, 156), ExposureCompensation = 0 },
		morning = { Ambient = rgb(150, 150, 140), OutdoorAmbient = rgb(166, 166, 150), Brightness = 2.4, ColorShift_Top = rgb(255, 230, 180), ExposureCompensation = 0 },
	}
	local ATMO = {
		mist = { Density = 0.52, Haze = 2.8, Color = rgb(226, 214, 222), Decay = rgb(160, 146, 160), Glare = 0, Offset = 0.3 },
		fire = { Density = 0.48, Haze = 2.6, Color = rgb(176, 146, 140), Decay = rgb(90, 78, 92), Glare = 0, Offset = 0.2 },
		morning = { Density = 0.33, Haze = 2.0, Color = rgb(236, 226, 200), Decay = rgb(170, 170, 150), Glare = 0.15, Offset = 0.25 },
	}
	local function blend(fn, a, b, u)
		local out = {}
		for k, v in a do
			local w = b[k]
			if typeof(v) == "Color3" then out[k] = v:Lerp(w, u) else out[k] = v + (w - v) * u end
		end
		fn(out)
	end
	local skyNow
	local function sky(name) if skyNow ~= name then skyNow = name ctx.sky(IMG[name]) end end
	-- the key light: high and flat in the mist (no shadows to speak of), then the low morning sun from behind screen left
	local KEYS = { Vector3.new(-0.2, 0.9, -0.3), Vector3.new(0.3, 0.8, 0.4), Vector3.new(0.7, 0.36, 0.6) }
	local keyNow = 0
	local function key(i) if keyNow ~= i then keyNow = i ctx.key(KEYS[i]) end end

	local SND = { fire = 129781180188795, bonk = 101020483687867, dawn = 85010698086137 }
	local fireS = ctx.sound(SND.fire, 0, 0.8, true)
	mist:Emit(40) nearMist:Emit(14) wisps:Emit(8)

	-- a pole from the hand toward a point: the hoop's middle lands on `tip`
	local NET_L = 3.62 * 0.85
	local function poleTo(hand, tip)
		local dir = (tip - hand).Unit
		return CFrame.lookAt(tip - dir * NET_L, tip) * R(-90, 180, 0)
	end
	local function lerp3(a, b, u) return a:Lerp(b, u) end
	-- an event of the story, fired as its time passes. The short version starts at NAMED: what lies before it stays silent
	local function once(key, at, t, fn) if t < at + 0.5 then ctx.once(key, at, t, fn) end end

	return function(t, dt)
		local ts = t
		local lit = smooth(4.0, 4.3, t)
		local cool = smooth(6.5, 7.5, t)
		local morning = t >= 7.6
		-- how hard the furnace burns: it climbs with every jump on the bellows, roars at the last one, then dies down
		local blast = 0
		for i, at in JUMPS do if t >= at then blast = math.max(blast, (0.45 + 0.13 * i) * math.exp(-(t - at) * 2.2)) end end
		local roar = smooth(5.75, 5.85, t) * (1 - smooth(6.2, 6.9, t))
		local fire = math.clamp(lit * (0.35 + blast + 0.6 * roar) * (1 - cool), 0, 1.4)
		if morning then fire = 0 end

		-- ===== lighting and the paper sky =====
		if t < 4.2 then key(1) sky("mist") blend(ctx.light, LOOK.mist, LOOK.fire, lit) blend(ctx.atmo, ATMO.mist, ATMO.fire, lit)
		elseif not morning then key(2) sky("fire") blend(ctx.light, LOOK.fire, LOOK.morning, 0.35 * cool) blend(ctx.atmo, ATMO.fire, ATMO.mist, 0.5 * cool)
		else key(3) sky("morning") blend(ctx.light, LOOK.morning, LOOK.morning, 0) blend(ctx.atmo, ATMO.morning, ATMO.morning, 0) end
		ctx.cc.TintColor = rgb(244, 232, 236):Lerp(rgb(255, 232, 214), lit * (1 - cool)):Lerp(rgb(255, 246, 232), morning and 1 or 0)
		ctx.cc.Saturation, ctx.cc.Contrast = (morning and 0.12 or -0.16 + 0.2 * lit), 0.08
		sunRays.Intensity = morning and 0.06 * smooth(7.6, 8.4, t) or 0
		ripple.OffsetStudsU, ripple.OffsetStudsV = t * 0.7, math.sin(t * 0.3) * 1.5
		local flick = 0.86 + 0.14 * math.sin(t * 31) * math.sin(t * 17.3)
		fireLight.Brightness = math.min(2.6, 2.0 * fire * flick + 0.6 * math.min(fire, 1))
		topLight.Brightness = 1.6 * math.max(0, fire - 0.5) * flick
		for k, g in glints do g.Transparency = 1 - math.clamp(fire, 0, 1) * (0.28 + 0.3 * (0.5 + 0.5 * math.sin(t * 6.1 + k * 1.9))) end
		flame.Rate = fire > 0.05 and 14 + 60 * math.max(0, fire - 0.4) or 0
		smoke.Rate = fire > 0.05 and 5 or (lit * (1 - smooth(7.4, 7.6, t)) > 0 and 2 or 0)
		sparks.Rate = 46 * roar
		fireS.Volume = 0.5 * math.min(fire, 1.1)
		fireS.PlaybackSpeed = 0.8 + 0.5 * math.min(fire, 1.2)
		mist.Rate, nearMist.Rate = morning and 2 or 5, morning and 1 or 3
		gnats.Rate = morning and 8 or 14
		wisps.Rate = morning and 0 or 3

		-- ===== the furnace, the bellows, the bloom =====
		local s1, s2 = smooth(3.14, 3.3, t), smooth(3.5, 3.66, t)
		set:show("Stack1", t >= 3.14) set:show("Stack2", t >= 3.5) set:show("MirrorStack", t >= 3.66)
		set:set("Stack1", CFrame.new(0, 5 * (1 - s1) * (1 - s1), 0))
		set:set("Stack2", CFrame.new(0, 5 * (1 - s2) * (1 - s2), 0))
		set:show("Mouth", fire > 0.02)
		set:size("Mouth", Vector3.new(1, 0.8 + 0.2 * math.min(fire, 1) * flick, 1))
		set:show("Throat", fire > 0.3)
		once("stack1", 3.3, t, function() ctx.sound(SND.bonk, 0.5, 0.7) workPart.CFrame = W(A(FUR.X, 2.0, FUR.Z + 1)) dust:Emit(12) ctx.kick(1.4) end)
		once("stack2", 3.66, t, function() ctx.sound(SND.bonk, 0.55, 0.6) workPart.CFrame = W(A(FUR.X, 3.1, FUR.Z + 1)) dust:Emit(12) ctx.kick(1.8) ctx.hold(2 / 60) end)
		once("light", 4.05, t, function() sfx("swing", 0.5) sparks:Emit(10) end)
		local squeeze = 0
		for i, at in JUMPS do
			if t >= at then squeeze = math.max(squeeze, math.exp(-(t - at) * 5)) end
			once("jump" .. i, at, t, function()
				sfx("land", 0.7 + i * 0.06) sfx("swing", 0.5 + i * 0.12)
				puff:Emit(8) sparks:Emit(6 + i * 7) ctx.kick(1.2 + i * 0.5)
				if i >= 3 then steam:Emit(4 + i) end
				if i == 5 then ctx.shake(0.9) ctx.hold(3 / 60) sfx("breakRock", 0.5) end
			end)
		end
		set:set("BellowsTop", R(0, 0, -15 * squeeze))
		set:size("BellowsBag", Vector3.new(1 + 0.06 * squeeze, 1 - 0.78 * squeeze, 1 + 0.1 * squeeze))
		local slag = smooth(5.6, 6.3, t)
		set:show("Slag", slag > 0.01 and not morning)
		set:size("Slag", math.max(slag, 0.001))
		if slagPart then slagPart.Color = hex("#ff6a1c"):Lerp(hex("#4a2a22"), cool) end
		once("slag", 5.9, t, function() steam:Emit(10) end)
		-- the bloom: raked out of the mouth onto the ground, then it cools from yellow to red to dark iron
		local out = smooth(5.95, 6.4, t)
		set:show("Bloom", t >= 5.95 and not morning)
		local bd = BLOOM_AT - v3(FUR.X, 0.55, FUR.Z + 1.1)
		set:set("Bloom", CFrame.new(-bd.X * out, bd.Y * out + 0.35 * math.sin(out * math.pi), -bd.Z * out) * R(out * 200, 0, out * 90))
		if bloomPart then
			local c = hex("#ffd070"):Lerp(hex("#ff5a1c"), smooth(6.3, 6.9, t)):Lerp(hex("#5a3a34"), smooth(6.8, 7.3, t)):Lerp(hex("#4a4a52"), smooth(7.2, 7.5, t))
			bloomPart.Color = c
			bloomPart.Material = t < 7.2 and Enum.Material.Neon or Enum.Material.Slate
		end
		once("bloomOut", 6.38, t, function() workPart.CFrame = W(A(BLOOM_AT.X, 0.3, BLOOM_AT.Z)) dust:Emit(8) sparks:Emit(8) sfx("land", 0.6) ctx.kick(1.5) end)
		-- moss and a mushroom move in, in fast motion
		local moss = smooth(6.7, 7.5, t)
		set:show("Moss", moss > 0.01)
		set:size("Moss", math.max(moss, 0.001))
		local grown = backOut(math.clamp((t - 7.2) / 0.25, 0, 1))
		charm.scale = math.max(0.001, 1.4 * grown)
		charm.root = (t >= 7.2 and not morning) and W(A(BLOOM_AT.X + 0.05, 0.62, BLOOM_AT.Z)) or O * CFrame.new(0, -50, 0)
		charm:update()
		once("mushroom", 7.2, t, function() sfx("pop", 0.6) workPart.CFrame = W(A(BLOOM_AT.X, 0.9, BLOOM_AT.Z)) sparkle:Emit(10) ctx.kick(1.2) end)
		set:update()

		-- ===== the frog =====
		local phase = t < 3.0 and 0 or (t < 5.9 and 1 or (t < 6.6 and 2 or (t < 7.6 and 3 or 4)))
		local pos, yaw, effort, happy = A(-15.5, 0.08, 1.9), -14, 0, false
		if phase == 0 then
			frog:pose(lean(born(ts)))
			happy = t > 2.45
			effort = smooth(1.3, 1.5, t) * (1 - smooth(1.9, 2.1, t)) * 0.5 + ((t > 2.5 and t < 2.9) and 0.5 + 0.5 * math.sin(t * 34) or 0)
		elseif phase == 1 then
			frog:pose(lean(made(ts)))
			local stand, on = v3(-0.7, 0, 1.7), v3(-1.6, 1.08, -0.5)
			if t < 4.2 then
				pos, yaw = A(stand.X, 0, stand.Z), 58
			else
				local a, b, from = 4.2, JUMPS[1], stand
				for i = 1, #JUMPS - 1 do if t >= JUMPS[i] then a, b, from = JUMPS[i], JUMPS[i + 1], on end end
				local u = math.clamp((t - a) / (b - a), 0, 1)
				if t >= JUMPS[#JUMPS] then u, from = 1, on end
				local hop = 4 * (from == stand and 1.5 or 1.25) * u * (1 - u)
				local p = lerp3(from, on, smooth(0, 1, u))
				pos = A(p.X, p.Y - 0.5 * squeeze * (from == on and 1 or u) + hop, p.Z)
				yaw = 58 - 26 * smooth(4.2, 4.45, t)
				local air = math.sin(u * math.pi)
				frog:set("LegL", R(-34 * air + 30 * squeeze, 0, 8)) frog:set("LegR", R(-34 * air + 30 * squeeze, 0, -8))
				frog:set("ArmL", R(150 * air - 20, 0, 20 - 30 * air)) frog:set("ArmR", R(150 * air - 20, 0, -20 + 30 * air))
				effort = 0.6 + 0.4 * squeeze
			end
			frog:size("Body", Vector3.new(1 + 0.1 * squeeze, 1 - 0.12 * squeeze, 1 + 0.1 * squeeze))
		elseif phase == 2 then
			frog:pose(lean(made(ts)))
			pos, yaw = A(-0.6, 0, 3.3), 44
			frog:size("Body", Vector3.one)
			effort = 0.3 * (1 - smooth(6.3, 6.6, t))
		elseif phase == 3 then
			frog:pose(lean(made(ts)))
			pos, yaw = A(-2.6, -0.5, 1.5), 24
			happy = t < 7.24
		else
			frog:pose(lean(named(ts)))
			local back = smooth(8.42, 8.7, t)
			pos, yaw = A(HERO.X + 0.5 * back, 0, HERO.Z - 0.7 * back), -26 + 30 * smooth(8.5, 9.2, t)
			effort = smooth(7.85, 8.0, t) * (1 - smooth(8.02, 8.15, t)) + smooth(8.2, 8.4, t) * (1 - smooth(8.45, 8.6, t))
			happy = t > 9.3
		end
		frog.root = W(pos) * R(0, yaw, 0)
		local breathe = math.sin(ts * 2.6) * 0.012
		if phase ~= 1 then frog:size("Body", Vector3.new(1 + breathe, 1 - breathe, 1 + breathe)) end
		frog:size("Cheeks", 0.45 + 0.85 * math.clamp(effort, 0, 1))
		frog:set("Hat", R(-4 * math.clamp(effort, 0, 1) + math.sin(ts * 2.1) * 1.5, 0, 0))
		local shut = happy or (ts % 2.9) < 0.12
		frog:show("Eyes", not shut) frog:show("EyesShut", shut)
		if phase ~= frog.phase then frog.phase = phase frog:snap() end
		frog:smooth(dt, phase == 1 and 22 or 13)
		frog:update()

		-- ===== BORN: the net, the nodule, the water =====
		local hand = (frog:joint("ForeR") * CFrame.new(0.09, -0.45, -0.24)).Position
		if phase == 0 then
			local rest, dip, up, face = A(-16.4, 0.5, 4.3), A(PADS.X, WY - 0.25, PADS.Z), A(-16.0, 1.9, 4.2), A(-15.9, 2.3, 3.5)
			local tip = lerp3(lerp3(lerp3(rest, dip, smooth(1.2, 1.5, t)), up, smooth(1.72, 2.0, t)), face, smooth(2.1, 2.4, t))
			net.root = poleTo(hand, O * tip)
			local got = t >= 1.6
			ore.root = got and net.root * CFrame.new(0, 3.5 * 0.85, 0.22) * R(t * 40, t * 25, 0) or O * CFrame.new(0, -50, 0)
			workPart.CFrame = got and CFrame.new(ore.root.Position) or W(A(PADS.X, WY + 0.1, PADS.Z))
			drips.Rate = (got and t < 2.9) and 22 * (1 - smooth(2.2, 2.9, t)) + 4 or 0
			set:set("Pads", CFrame.new(0, math.sin(t * 1.7) * 0.03 - 0.1 * smooth(1.4, 1.5, t) * (1 - smooth(1.6, 2.1, t)), 0))
			once("dip", 1.5, t, function() splash:Emit(14) sfx("pop", 0.7) end)
			once("lift", 1.76, t, function() splash:Emit(22) sfx("swing", 0.8) ctx.kick(1.4) end)
			once("ribbit", 2.5, t, function() sfx("pop", 0.45) end)
		elseif phase == 2 then
			drips.Rate = 0
			local bp = set:joint("Bloom").Position
			net.root = poleTo(hand, bp + Vector3.new(0, 0.3, 0))
			ore.root = O * CFrame.new(0, -50, 0)
		else
			drips.Rate = 0
			net.root = phase == 3 and W(A(-3.6, 0.1, 0.4)) * R(0, 30, 78) or O * CFrame.new(0, -50, 0)
			ore.root = O * CFrame.new(0, -50, 0)
		end
		net:update() ore:update()

		-- ===== NAMED: the tug of war with the mud, and the lift =====
		if morning then
			local hands = (frog:joint("ForeL").Position + frog:joint("ForeR").Position) / 2
			local free = smooth(8.42, 8.5, t)
			local rise = 0.4 * smooth(7.85, 8.0, t) * (1 - smooth(8.02, 8.15, t)) - 0.2 * smooth(8.05, 8.2, t) * (1 - smooth(8.2, 8.3, t)) + 1.1 * smooth(8.2, 8.44, t)
			local stuck = A(STUCK.X, STUCK.Y + rise, STUCK.Z)
			local lift = smooth(8.5, 9.3, t)
			local held = O:PointToObjectSpace((frog:joint("ForeR") * CFrame.new(0.09, -0.45, -0.24)).Position) + Vector3.new(0.2 * lift, 0.9 + 0.5 * lift + math.sin(t * 2) * 0.1 * lift, -0.3 * lift)
			local at = stuck:Lerp(held, free)
			local wob = math.sin(t * 40) * 3 * smooth(7.85, 8.0, t) * (1 - free)
			local spin = smooth(8.7, 10.2, t) * 360
			placePick(CFrame.new(at) * R(0, 205 + spin, 166 + wob - 178 * smooth(8.44, 8.8, t)), 3.1 + 0.6 * lift)
			-- the string of mud between the pickaxe and the bog: it stretches, thins and snaps
			local m0, m1 = O * A(STUCK.X, MUD_Y, STUCK.Z), O * (at - Vector3.new(0, 1.2 * (1 - smooth(8.44, 8.8, t)), 0))
			local len = (m1 - m0).Magnitude
			local thin = smooth(8.3, 8.72, t)
			if t > 8.2 and t < 8.72 and len > 0.05 then
				mudString.Transparency = 0
				mudString.Size = Vector3.new(len, 0.22 * (1 - 0.85 * thin), 0.22 * (1 - 0.85 * thin))
				mudString.CFrame = CFrame.lookAt((m0 + m1) / 2, m1) * CFrame.Angles(0, math.rad(90), 0)
			else
				mudString.Transparency = 1
			end
			once("tug1", 7.98, t, function() sfx("swing", 0.6) workPart.CFrame = W(A(STUCK.X, MUD_Y + 0.1, STUCK.Z)) mud:Emit(6) end)
			once("suck", 8.14, t, function() sfx("pop", 0.4) splash:Emit(6) end)
			once("free", 8.44, t, function()
				workPart.CFrame = W(A(STUCK.X, MUD_Y + 0.1, STUCK.Z))
				mud:Emit(26) splash:Emit(18) sfx("pop", 0.55) sfx("breakRock", 0.7) ctx.kick(3) ctx.hold(4 / 60) ctx.shake(0.4)
			end)
			once("reveal", 8.8, t, function()
				workPart.CFrame = W(at + Vector3.new(0, 0.6, 0))
				sparkle:Emit(46) ctx.sound(SND.dawn, 0.6, 1) sfx("sparkle", 1.3) ctx.kick(4)
			end)
			if t > 8.9 then workPart.CFrame = W(at + Vector3.new(0, 0.6, 0)) end
			sparkle.Rate = t >= 8.9 and 10 or 0
			ctx.name("The bog wanted it back.")
			ctx.cardAlpha = smooth(9.0, 9.35, t) * (1 - smooth(10.7, 11.0, t))
		end

		-- ===== chapters and camera =====
		if t >= 0.35 and t < 3.0 then ctx.chapter(1, "BORN", "Rust-red nodules under the lily pads, netted at dawn.")
		elseif t >= 3.2 and t < 7.6 then ctx.chapter(2, "MADE", "Smelted by a frog who jumped on the bellows until the stack roared.")
		elseif t >= 7.8 then ctx.chapter(3, "NAMED", "Morning. The mud had it, and held on.") end
		local cf, fov, focus
		local function shot(from, aim, f) cf, fov, focus = CFrame.lookAt(from, aim), f, (from - aim).Magnitude end
		if t < 1.1 then
			local u = smooth(0, 1.1, t)
			shot(A(-7 + 2 * u, 3.2 - 0.6 * u, 30 - 5 * u), A(-6, 1.6, 0), 50 - 4 * u)
		elseif t < 2.25 then
			shot(A(-11.5, 1.5, 10.5 - 0.6 * smooth(1.1, 2.25, t)), A(-15.8, 1.0, 3.2), 40)
		elseif t < 3.0 then
			shot(A(-14.0, 2.0, 8.2 - 0.4 * smooth(2.25, 3.0, t)), A(-15.7, 2.2, 2.6), 34)
		elseif t < 4.2 then
			local u = smooth(3.0, 4.2, t)
			shot(A(-2.6 + 0.6 * u, 2.4, 11.5 - 1.0 * u), A(0.6, 2.0, -0.6), 44)
		elseif t < 5.5 then
			shot(A(-6.6 + 0.4 * smooth(4.2, 5.5, t), 1.5, 7.6), A(-0.3, 2.8, -0.6), 46)
		elseif t < 5.9 then
			shot(A(1.0, 2.6, 22 - 0.8 * smooth(5.5, 5.9, t)), A(0.6, 2.6, 0), 46)
		elseif t < 6.6 then
			shot(A(4.0, 3.2, 6.2), A(0.2, 1.3, 1.6), 50) -- from the far side of the bloom: the slag in front, the frog beside it
		elseif t < 7.6 then
			local u = smooth(6.6, 7.6, t)
			shot(A(2.8 - 0.4 * u, 2.8, 5.8 - 0.5 * u), A(-0.6, 1.5, 1.2), 48)
		elseif t < 8.45 then
			shot(A(-9.6, 1.4, 15.2 - 0.5 * smooth(7.6, 8.45, t)), A(-5.0, 1.2, 9.0), 38)
		else
			local u = smooth(8.45, 10.8, t)
			shot(A(-2.6 - 0.3 * u, 0.8, 14.4 - 0.6 * u), A(-4.6, 2.9 + 1.2 * smooth(8.5, 9.3, t), 8.2), 55 - 2 * u) -- from the open-water side: the pickaxe against sky, clear of the birch
		end
		ctx.cam, ctx.fov = O * cf, fov
		ctx.dof.FocusDistance = focus
		ctx.dof.InFocusRadius, ctx.dof.FarIntensity, ctx.dof.NearIntensity = 400, 0, 0
	end
end

return M
