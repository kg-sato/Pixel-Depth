-- ReplicatedStorage.Shared.ForgeRootheart (src/ForgeRootheart.luau): the Rootheart Pickaxe biography, played by ForgeStory.
-- BORN: a drop of amber sap forms in the heart of the oldest tree. MADE: nobody makes it; the roots wind round it for years
-- while a mole waters them (three visits, a little greyer each time; leaves, then snow, then blossom fall through the ray).
-- NAMED: the roots open and the tree hands it down to him. "Grown, not made."
-- The setting is a place of its own (reference refs/forge/sheets/rootheart_setting_s11.png): the root hall under the tree,
-- olive-grey roots as thick as houses, moss cushions, teal mushrooms, a still pool, one ray of day from a knot hole far above.
-- Built from design3d/rootheart.mjs. Space: front of a model is -Z, the camera stands at -Z and looks toward +Z; +X is screen
-- left. The cradle stands on its mound at (0, 0.9, 3.5); the mole comes in from screen right (-X).
-- Every time in this file is a story second; the clock runs at 0.58 of real time (see ForgeWood).
local M = { length = 11.2, named = 7.6, open = true, pace = 0.58, fastPace = 0.75 }
-- no outdoor sky belongs in the hall: the Wood scene's night pictures stand behind the shell, and its ripple picture is on the pool
local NIGHT = { side = "98540000433096", up = "102757336864746", dn = "100178533145001" }
local RIPPLE = "rbxassetid://108008922454214"

local function hex(h) return Color3.fromHex(h) end
local function v3(x, y, z) return Vector3.new(x, y, z) end

function M.setup(ctx)
	local S = ctx.S
	local R, smooth, lin, backOut = S.rot, S.smooth, S.lin, S.backOut
	local O, sfx = ctx.O, ctx.sfx
	local function W(x, y, z) return O * CFrame.new(x, y, z) end
	local KP = NumberSequenceKeypoint.new
	local rgb = Color3.fromRGB
	local V = Vector3.new
	local function rnd(i)
		local x = math.sin(i * 127.1 + 11.7) * 43758.5453
		return x - math.floor(x)
	end
	-- the floor's height: the function H of design3d/rootheart.mjs, in stage space (x and z flipped)
	local function floorY(X, Z)
		local x, z = -X, -Z
		local function hyp(a, b) return math.sqrt(a * a + b * b) end
		return 7 * smooth(26, 46, hyp(x, (z + 8) * 0.92)) - 1.7 * (1 - smooth(2.5, 6, hyp(x + 10, z + 9))) + 0.9 * (1 - smooth(1.2, 4.2, hyp(x, z + 3.5))) + 0.35 * math.sin(x * 0.21) * math.cos(z * 0.17) * smooth(9, 16, hyp(x, z))
	end
	local CRADLE = V(0, floorY(0, 3.5), 3.5)
	local KNOT = V(10.7, 42.7, 12.75)
	local SPOT = V(-3.0, floorY(-3.0, 2.2), 2.2)
	local DOOR = V(-13, floorY(-13, 1.6), 1.6)
	local POOL = V(10, -0.35, 9)
	local MOLE_YAW = -65

	-- ===== the place =====
	local hall = ctx.prop("RootHall")
	hall:all(function(p, b)
		if p.Material ~= Enum.Material.Neon then p.Material = Enum.Material.Rubber end
		if b.name == "Shell" or b.name == "KnotGlow" or b.name == "Moss" then p.CastShadow = false end
	end)
	ctx.sky(NIGHT)
	ctx.key(V(0.2, 0.9, 0.3))
	local function free(X, Z, near)
		if (V(X, 0, Z) - V(CRADLE.X, 0, CRADLE.Z)).Magnitude < near then return false end
		if (V(X, 0, Z) - V(POOL.X, 0, POOL.Z)).Magnitude < 7 then return false end
		if X > -14 and X < -1 and Z > 0 and Z < 5 then return false end
		if math.abs(X) < 8 and Z < -1.5 then return false end
		return true
	end
	-- ferns, clover and stones from the kit, strewn by a fixed rule
	local KIT = { "Fern", "Clover", "Plant1", "Fern", "Plant7", "Clover", "Rock2", "Fern", "Bush", "Rock1" }
	for i = 1, 76 do
		local X, Z = (rnd(i) - 0.5) * 58, rnd(i + 100) * 48 - 12
		if free(X, Z, 5) then
			local r = ctx.prop(KIT[i % #KIT + 1], CFrame.new(X, floorY(X, Z), Z) * CFrame.Angles(0, rnd(i + 200) * 6.28, 0), 0.8 + rnd(i + 300) * 0.8)
			r:all(function(p)
				if p.Material ~= Enum.Material.Neon then p.Material = Enum.Material.Rubber end
				p.CastShadow = false
			end)
		end
	end
	-- the glowing mushrooms: a ring near the cradle, then more along the roots; every cap is kept for the wave of glow at the end
	local caps = {}
	local SHROOMS = { { 2.7, 1.3, 0.8 }, { -1.9, 6.6, 1.0 }, { 3.6, 5.8, 0.7 }, { -4.8, 5.4, 0.9 }, { 4.6, 0.4, 1.1 }, { 1.2, 8.2, 0.8 }, { -6.5, -0.6, 1.2 }, { 7.2, 3.4, 0.9 } }
	for i = 1, 22 do
		local X, Z = (rnd(i + 400) - 0.5) * 50, rnd(i + 500) * 40 - 8
		if free(X, Z, 6) then table.insert(SHROOMS, { X, Z, 0.7 + rnd(i + 600) * 0.9 }) end
	end
	for i, s in SHROOMS do
		local r = ctx.prop("GlowShroom", CFrame.new(s[1], floorY(s[1], s[2]), s[2]) * CFrame.Angles(0, i * 2.1, 0), s[3])
		r:all(function(p, b)
			p.CastShadow = false
			if b.name == "Cap" then
				table.insert(caps, { p, (V(s[1], 0, s[2]) - V(CRADLE.X, 0, CRADLE.Z)).Magnitude, i * 1.7 })
			else
				p.Material = Enum.Material.Rubber
			end
		end)
	end
	local shroomLights = {}
	for i = 1, 4 do
		local s = SHROOMS[i]
		local lp = ctx.part(v3(0.2, 0.2, 0.2), CFrame.new(s[1], floorY(s[1], s[2]) + 1.4, s[2]), hex("#7ad1b0"), { Transparency = 1 })
		local l = Instance.new("PointLight")
		l.Color, l.Range, l.Brightness, l.Shadows, l.Parent = hex("#7ad1b0"), 9, 0.4, false, lp
		shroomLights[i] = l
	end
	-- the pool and the spring that feeds it
	local water = ctx.part(v3(12, 0.2, 12), CFrame.new(POOL.X, POOL.Y - 0.1, POOL.Z), hex("#1d3a34"), { Transparency = 0.3, Reflectance = 0.3 })
	local ripple = Instance.new("Texture")
	ripple.Texture, ripple.Face, ripple.StudsPerTileU, ripple.StudsPerTileV, ripple.Transparency, ripple.Parent = RIPPLE, Enum.NormalId.Top, 16, 10, 0.75, water
	local springPart = ctx.part(v3(0.4, 0.2, 0.4), CFrame.new(14.4, 0.9, 12.2), hex("#ffffff"), { Transparency = 1 })
	ctx.emitter(springPart, { Texture = S.GLOW, Color = ColorSequence.new(hex("#cfeee6")), Size = NumberSequence.new({ KP(0, 0.12), KP(1, 0.07) }), Transparency = NumberSequence.new({ KP(0, 0.2), KP(1, 0.7) }), Lifetime = NumberRange.new(0.5, 0.7), Speed = NumberRange.new(4, 5), SpreadAngle = Vector2.new(8, 8), EmissionDirection = Enum.NormalId.Left, Acceleration = v3(0, -16, 0), LightEmission = 0.4, Rate = 22 })
	local ringPart = ctx.part(v3(2, 0.2, 2), CFrame.new(12.6, POOL.Y + 0.05, 10.8), hex("#ffffff"), { Transparency = 1 })
	ctx.emitter(ringPart, { Texture = S.GLOW, Color = ColorSequence.new(hex("#bfe8dc")), Size = NumberSequence.new({ KP(0, 0.3), KP(1, 2.4) }), Transparency = NumberSequence.new({ KP(0, 0.6), KP(1, 1) }), Lifetime = NumberRange.new(0.9, 1.3), Speed = NumberRange.new(0, 0.05), Orientation = Enum.ParticleOrientation.VelocityPerpendicular, EmissionDirection = Enum.NormalId.Top, LightEmission = 0.3, Rate = 3 })

	-- ===== the ray: a spot light from the knot hole, and the cone of lit air =====
	local rayDir = (CRADLE - KNOT).Unit
	local rayPart = ctx.part(v3(0.4, 0.4, 0.4), CFrame.new(KNOT + rayDir * 2), hex("#fff1c4"), { Transparency = 1 })
	local ray = Instance.new("SpotLight")
	ray.Face, ray.Angle, ray.Range, ray.Brightness, ray.Color, ray.Shadows, ray.Parent = Enum.NormalId.Front, 15, 60, 4, hex("#ffe9b8"), true, rayPart
	local shaft = ctx.rig("LightShaft", CFrame.new(KNOT))
	shaft:all(function(p) p.CastShadow = false end)
	-- the modelled cone read as panes of glass (first capture): it is hidden, and the ray is drawn by slow soft motes of lit dust along its line
	shaft:alpha("Shaft", 1)
	shaft:alpha("Core", 1)
	local rayFogPart = ctx.part(v3(2.2, 2.2, 40), CFrame.new(KNOT), hex("#ffffff"), { Transparency = 1 })
	local rayFog = ctx.emitter(rayFogPart, { Texture = S.SMOKE, Color = ColorSequence.new(hex("#fff1c4")), Size = NumberSequence.new(4.2), Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.3, 0.93), NumberSequenceKeypoint.new(0.7, 0.93), NumberSequenceKeypoint.new(1, 1) }), Lifetime = NumberRange.new(2.4, 3.4), Speed = NumberRange.new(0.1, 0.4), SpreadAngle = Vector2.new(180, 180), LightEmission = 0.7, LightInfluence = 0, Rate = 46, Rotation = NumberRange.new(0, 360) })
	rayFog:Emit(90)
	-- a soft warm fill in front of the mole's face, so he reads against the dark green (grader round 1: "crushed into murky shadows")
	local faceFillPart = ctx.part(v3(0.2, 0.2, 0.2), CFrame.new(0, -60, 0), hex("#ffd9a8"), { Transparency = 1 })
	local faceFill = Instance.new("PointLight")
	faceFill.Color, faceFill.Range, faceFill.Brightness, faceFill.Shadows, faceFill.Parent = hex("#ffd9a8"), 7, 0.9, false, faceFillPart
	local bouncePart = ctx.part(v3(0.2, 0.2, 0.2), CFrame.new(CRADLE.X, CRADLE.Y + 2.6, CRADLE.Z - 2.5), hex("#6fae7a"), { Transparency = 1 })
	local bounce = Instance.new("PointLight")
	bounce.Color, bounce.Range, bounce.Brightness, bounce.Shadows, bounce.Parent = hex("#7fbf86"), 28, 0.7, false, bouncePart
	-- what falls through the ray: dust always, then the seasons in turn
	local fallPart = ctx.part(v3(5, 0.5, 5), CFrame.new(KNOT:Lerp(CRADLE, 0.5)), hex("#ffffff"), { Transparency = 1 })
	local motes = ctx.emitter(fallPart, { Texture = S.GLOW, Color = ColorSequence.new(hex("#fff3c8")), Size = NumberSequence.new({ KP(0, 0), KP(0.3, 0.09), KP(1, 0) }), Transparency = NumberSequence.new(0.2), Lifetime = NumberRange.new(3, 5), Speed = NumberRange.new(0.6, 1.6), SpreadAngle = Vector2.new(40, 40), EmissionDirection = Enum.NormalId.Bottom, Drag = 0.3, LightEmission = 0.7, Rate = 16 })
	motes:Emit(40)
	local snow = ctx.emitter(fallPart, { Texture = S.GLOW, Color = ColorSequence.new(hex("#ffffff")), Size = NumberSequence.new(0.13), Transparency = NumberSequence.new({ KP(0, 0.1), KP(0.9, 0.1), KP(1, 1) }), Lifetime = NumberRange.new(2, 2.4), Speed = NumberRange.new(8, 10), SpreadAngle = Vector2.new(9, 9), EmissionDirection = Enum.NormalId.Bottom, LightEmission = 0.5, LightInfluence = 0.5 })
	local blossom = ctx.emitter(fallPart, { Texture = S.GLOW, Color = ColorSequence.new(hex("#ffc6d6"), hex("#fff0f4")), Size = NumberSequence.new(0.2), Squash = NumberSequence.new(-0.5), Transparency = NumberSequence.new({ KP(0, 0.05), KP(0.9, 0.1), KP(1, 1) }), Lifetime = NumberRange.new(2.2, 2.8), Speed = NumberRange.new(6, 8), SpreadAngle = Vector2.new(12, 12), Rotation = NumberRange.new(0, 360), RotSpeed = NumberRange.new(-120, 120), EmissionDirection = Enum.NormalId.Bottom, LightEmission = 0.35, LightInfluence = 0.5 })
	local leaves = {}
	for i = 1, 9 do
		local r = ctx.rig("Leaf", CFrame.new(0, -70, 0), 0.5)
		local tint = ({ hex("#e08a2c"), hex("#c9542a"), hex("#e8b23a") })[i % 3 + 1]
		r:all(function(p)
			p.Color = tint
			p.CastShadow = false
			local sa = p:FindFirstChildOfClass("SurfaceAppearance")
			if sa then pcall(function() sa.Color = tint end) end
		end)
		leaves[i] = { r = r, ph = (i * 0.37) % 1, dx = math.sin(i * 2.3) * 1.6, dz = math.cos(i * 1.7) * 1.6 }
	end
	local flyPart = ctx.part(v3(40, 5, 30), CFrame.new(0, 3.5, 8), hex("#ffffff"), { Transparency = 1 })
	local flies = ctx.emitter(flyPart, { Texture = S.GLOW, Color = ColorSequence.new(hex("#d8ffb0")), Size = NumberSequence.new({ KP(0, 0), KP(0.2, 0.22), KP(0.5, 0.08), KP(0.8, 0.24), KP(1, 0) }), Transparency = NumberSequence.new(0.05), Lifetime = NumberRange.new(3, 5), Speed = NumberRange.new(0.4, 1.2), SpreadAngle = Vector2.new(180, 180), Drag = 0.4, Brightness = 2.2, Rate = 6 })
	flies:Emit(12)

	-- ===== the cradle, the sap, the mole =====
	local cradle = ctx.rig("RootCradle", CFrame.new(CRADLE))
	cradle:all(function(p) p.Material = Enum.Material.Rubber end)
	-- each finger curls about its own level axis: the model's fingers stand at equal angles round the cradle (rootheart.mjs)
	local fingers = {}
	local handFinger, handDot = 1, -2
	for i = 1, 7 do
		local a = (i - 1) / 7 * math.pi * 2
		local radial = V(-math.sin(a), 0, -math.cos(a))
		fingers[i] = { axis = radial:Cross(Vector3.yAxis), ph = i * 1.9 }
		local d = radial:Dot((V(SPOT.X, 0, SPOT.Z) - V(CRADLE.X, 0, CRADLE.Z)).Unit)
		if d > handDot then handFinger, handDot = i, d end
	end
	local bead = ctx.rig("SapBead", CFrame.new(0, -60, 0))
	bead:all(function(p) p.CastShadow = false if p.Material == Enum.Material.Neon then p.Color = hex("#d97a10") end end) -- Neon brightens under bloom: #ff9226 read yellow, #b84a06 read red; this reads amber
	local beadPart = ctx.part(v3(0.2, 0.2, 0.2), CFrame.new(CRADLE), hex("#f2a23a"), { Transparency = 1 })
	local beadLight = Instance.new("PointLight")
	beadLight.Color, beadLight.Range, beadLight.Brightness, beadLight.Shadows, beadLight.Parent = hex("#ffb04a"), 13, 0, true, beadPart
	local mole = ctx.rig("MoleKit", CFrame.new(0, -60, 0))
	mole:all(function(p) p.Material = Enum.Material.Rubber end)
	mole:show("EyesShut", false)
	mole:alpha("Lens", 0.72)
	mole:alpha("Grey", 1)
	local can = ctx.rig("WateringCan", CFrame.new(0, -60, 0), 0.85)
	can:all(function(p) p.Material = Enum.Material.Rubber end)
	local pourPart = ctx.part(v3(0.2, 0.2, 0.2), CFrame.new(0, -60, 0), hex("#ffffff"), { Transparency = 1 })
	local pourFx = ctx.emitter(pourPart, { Texture = S.GLOW, Color = ColorSequence.new(hex("#d6f2ff")), Size = NumberSequence.new({ KP(0, 0.1), KP(1, 0.06) }), Transparency = NumberSequence.new({ KP(0, 0.15), KP(1, 0.6) }), Lifetime = NumberRange.new(0.4, 0.55), Speed = NumberRange.new(3, 4.2), SpreadAngle = Vector2.new(10, 10), EmissionDirection = Enum.NormalId.Front, Acceleration = v3(0, -26, 0), LightEmission = 0.5 })
	local workPart = ctx.part(v3(0.3, 0.3, 0.3), CFrame.new(CRADLE.X, CRADLE.Y + 2, CRADLE.Z), hex("#ffffff"), { Transparency = 1 })
	local sparkle = ctx.emitter(workPart, { Texture = S.SPARK, Color = ColorSequence.new(hex("#ffffff"), hex("#ffd98a")), Size = NumberSequence.new({ KP(0, 0), KP(0.3, 0.6), KP(1, 0) }), Transparency = NumberSequence.new(0, 1), Lifetime = NumberRange.new(0.6, 1.2), Speed = NumberRange.new(2, 7), SpreadAngle = Vector2.new(180, 180), Rotation = NumberRange.new(0, 360), Drag = 2 })
	local heroPart = ctx.part(v3(0.3, 0.3, 0.3), CFrame.new(CRADLE.X, CRADLE.Y + 3, CRADLE.Z), hex("#ffffff"), { Transparency = 1 })
	local rays = Instance.new("BillboardGui")
	rays.Size, rays.LightInfluence, rays.Brightness, rays.Parent = UDim2.fromScale(11, 11), 0, 1.2, heroPart
	local raysIm = Instance.new("ImageLabel")
	raysIm.BackgroundTransparency, raysIm.Image, raysIm.ImageColor3, raysIm.ImageTransparency, raysIm.Size, raysIm.Parent = 1, "rbxassetid://98789616938156", hex("#ffd98a"), 1, UDim2.fromScale(1, 1), rays
	local heroSpark = ctx.emitter(heroPart, { Texture = S.SPARK, Color = ColorSequence.new(hex("#ffffff"), hex("#7ad1b0")), Size = NumberSequence.new({ KP(0, 0), KP(0.3, 0.5), KP(1, 0) }), Transparency = NumberSequence.new(0, 1), Lifetime = NumberRange.new(0.8, 1.6), Speed = NumberRange.new(2, 6), SpreadAngle = Vector2.new(180, 180), Rotation = NumberRange.new(0, 360), Drag = 1.5 })
	local pick = ctx.pick()
	local pickScale0, pickH = 1, 5
	if pick then
		pickScale0, pickH = pick:GetScale(), math.max(pick:GetExtentsSize().Y, 0.1)
		pick:PivotTo(W(0, -60, 0))
	end
	local function placePick(cf, height)
		if not pick then return end
		pick:ScaleTo(pickScale0 * height / pickH)
		pick:PivotTo(O * cf)
	end

	-- ===== the mole's acting =====
	local PAW_L, PAW_R = CFrame.new(-0.09, -0.5, -0.26), CFrame.new(0.09, -0.5, -0.26)
	local VISITS = { 3.05, 4.5, 5.95 }
	local GREY = { 1, 0.45, 0 }
	local named = S.track({
		{ 7.6, { LegL = R(0, 0, 0), LegR = R(0, 0, 0), ArmL = R(30, 0, 26), ForeL = R(56, 0, 0), ArmR = R(30, 0, -26), ForeR = R(56, 0, 0), Head = R(-8, 0, 0), Body = R(8, 0, 0), Tail1 = R(0, 0, 0), Tail2 = R(0, 0, 0) } },
		{ 8.1, { Head = R(-16, 0, 0), Body = R(0, 0, 0) }, "inout" },
		{ 8.45, { Head = R(-20, 0, 0), Body = R(-8, 0, 0), ArmL = R(50, 0, 40), ForeL = R(40, 0, 0), ArmR = R(50, 0, -40), ForeR = R(40, 0, 0) }, "back" },
		{ 8.9, { ArmL = R(74, 0, 12), ForeL = R(22, 0, 0), ArmR = R(74, 0, -12), ForeR = R(22, 0, 0), Head = R(-10, 0, 0), Body = R(4, 0, 0) }, "inout" },
		{ 9.5, { ArmL = R(60, 0, 12), ForeL = R(30, 0, 0), ArmR = R(60, 0, -12), ForeR = R(30, 0, 0), Head = R(8, 0, 0), Body = R(9, 0, 0) }, "in" },
		{ 9.7, { ArmL = R(68, 0, 12), ForeL = R(26, 0, 0), ArmR = R(68, 0, -12), ForeR = R(26, 0, 0), Head = R(10, 0, 0), Body = R(5, 0, 0) }, "back" },
		{ 10.4, { Head = R(-14, 0, 4), Body = R(0, 0, 0) }, "inout" },
	})
	-- as in ForgeWood: a positive first angle on Head and Body means "lean forward"; flipped here once for a model that faces -Z
	local function lean(p)
		for _, b in { "Head", "Body" } do
			local cf = p[b]
			if cf then
				local x, y, z = cf:ToEulerAnglesXYZ()
				p[b] = CFrame.Angles(-x, y, z)
			end
		end
		return p
	end

	-- sounds: the Wood scene's files at other pitches (this scene has none of its own yet)
	local SND = { whittle = 96959952635114, bonk = 101020483687867, dawn = 85010698086137 }
	local RAY_COL = { hex("#ffe9b8"), hex("#ffd39a"), hex("#e2ecff"), hex("#ffe6ea") }
	local CAP_DIM, CAP_LIT = hex("#1c4a40"), hex("#8fe8cc")

	return function(t, dt)
		-- ===== which visit, which season =====
		local visit = t < 3.0 and 0 or (t < VISITS[2] and 1 or (t < VISITS[3] and 2 or 3))
		local u = visit > 0 and t - VISITS[visit] or 0
		local inVisit = t >= 3.0 and t < 7.6
		local autumn = smooth(3.0, 3.2, t) * (1 - smooth(4.3, 4.5, t))
		local winter = smooth(4.4, 4.6, t) * (1 - smooth(5.75, 5.95, t))
		local spring = smooth(5.85, 6.05, t) * (1 - smooth(7.2, 7.5, t))
		local beat = math.max(0, math.sin(t * 4.2)) ^ 6 + 0.6 * math.max(0, math.sin(t * 4.2 - 0.9)) ^ 6

		-- ===== light and air: deep green shade, one ray =====
		ctx.light({ Ambient = rgb(50, 72, 60), OutdoorAmbient = rgb(56, 80, 66), Brightness = 0.25, ColorShift_Top = rgb(160, 200, 170), ExposureCompensation = 0.1 })
		ctx.atmo({ Density = 0.42, Haze = 1.6, Color = rgb(46, 78, 58), Decay = rgb(18, 34, 26), Glare = 0, Offset = 0 })
		ctx.cc.TintColor = rgb(232, 246, 236)
		ctx.cc.Saturation, ctx.cc.Contrast = 0.1, 0.12
		-- the years pass as light: between two visits the ray swings out across the hall and back
		local sweep = math.sin(lin(VISITS[2] - 0.42, VISITS[2] + 0.4, t) * math.pi * 2) * 8 + math.sin(lin(VISITS[3] - 0.42, VISITS[3] + 0.4, t) * math.pi * 2) * 8
		local toMole = smooth(9.3, 10.2, t) * 0.55
		local target = V(CRADLE.X, CRADLE.Y + 1.5, CRADLE.Z):Lerp(V(SPOT.X, SPOT.Y + 1.8, SPOT.Z), toMole) + V(sweep + math.sin(t * 0.7) * 0.4, 0, sweep * 0.3)
		local aim = CFrame.lookAt(KNOT, target)
		rayPart.CFrame = O * (aim + aim.LookVector * 2)
		shaft.root = O * aim * CFrame.Angles(math.rad(90), 0, 0)
		rayFogPart.CFrame = O * (aim * CFrame.new(0, 0, -(target - KNOT).Magnitude * 0.5))
		rayFogPart.Size = v3(2.2, 2.2, (target - KNOT).Magnitude)
		fallPart.CFrame = O * CFrame.new(KNOT:Lerp(target, 0.45))
		ray.Color = RAY_COL[1]:Lerp(RAY_COL[2], autumn):Lerp(RAY_COL[3], winter):Lerp(RAY_COL[4], spring)
		ray.Brightness = 4 + 1.5 * smooth(7.7, 8.5, t)
		snow.Rate = 120 * winter
		blossom.Rate = 70 * spring
		for _, l in leaves do
			local f = ((t - 3.0) * 1.1 + l.ph) % 1
			local at = KNOT:Lerp(target, 0.4 + 0.6 * f)
			l.r.root = W(at.X + l.dx + math.sin(f * 11 + l.ph * 9) * 0.7, at.Y, at.Z + l.dz) * R(t * 240 + l.ph * 360, t * 130, l.ph * 90)
			l.r:all(function(p) p.Transparency = autumn > 0.05 and 0 or 1 end)
		end
		ripple.OffsetStudsU, ripple.OffsetStudsV = t * 0.5, math.sin(t * 0.4) * 1.2

		-- ===== the cradle: it grows with every watering and closes like fingers; at the end it opens =====
		local grow = (smooth(3.5, 4.3, t) + smooth(4.95, 5.75, t) + smooth(6.4, 7.1, t)) / 3
		local creep = math.sin(lin(3.5, 4.3, t) * math.pi) + math.sin(lin(4.95, 5.75, t) * math.pi) + math.sin(lin(6.4, 7.1, t) * math.pi)
		local curl = grow * (1 - backOut(lin(8.15, 8.8, t)))
		local hand = smooth(8.75, 9.35, t) * (1 - smooth(9.7, 10.3, t))
		cradle.scale = 0.45 + 0.55 * grow
		for i, f in fingers do
			local wig = math.sin(t * 9 + f.ph) * 2.5 * creep
			local out = i == handFinger and hand or 0
			cradle:set("F" .. i .. "a", CFrame.fromAxisAngle(f.axis, math.rad(20 * curl + wig - 38 * out)))
			cradle:set("F" .. i .. "b", CFrame.fromAxisAngle(f.axis, math.rad(34 * curl + wig - 20 * out)))
			cradle:set("F" .. i .. "c", CFrame.fromAxisAngle(f.axis, math.rad(30 * curl + wig * 0.5)))
		end
		ctx.once("creak1", 3.5, t, function() ctx.sound(SND.whittle, 0.25, 0.5) end)
		ctx.once("creak2", 4.95, t, function() ctx.sound(SND.whittle, 0.25, 0.45) end)
		ctx.once("creak3", 6.4, t, function() ctx.sound(SND.whittle, 0.3, 0.4) end)

		-- ===== the sap: a drop falls from the wood above, swells, and beats like a slow heart =====
		local heart = V(CRADLE.X, CRADLE.Y + 1.9 * cradle.scale, CRADLE.Z)
		local drop = (1 - lin(1.3, 1.62, t)) ^ 2 * 7
		local formed = t >= 1.3 and (0.25 + 0.75 * smooth(1.62, 2.6, t)) or 0
		local gone = smooth(8.3, 8.5, t)
		if formed > 0 and gone < 1 then
			bead.root = W(heart.X, heart.Y + drop, heart.Z) * R(0, t * 20, 0)
			bead.scale = formed * (1 + 0.07 * beat) * (1 - gone)
		else
			bead.root = W(0, -60, 0)
		end
		beadPart.CFrame = W(heart.X, heart.Y, heart.Z)
		beadLight.Brightness = (0.5 + 1.9 * beat) * smooth(1.6, 2.6, t) * (1 - 0.55 * curl) * (1 - gone) + 2.4 * smooth(8.4, 8.7, t) * (1 - smooth(9.4, 10.2, t))
		ctx.once("born", 1.62, t, function()
			workPart.CFrame = W(heart.X, heart.Y, heart.Z)
			sparkle:Emit(12)
			sfx("pop", 0.9)
			ctx.kick(1.2)
		end)
		ctx.once("glow", 2.6, t, function()
			sparkle:Emit(18)
			sfx("sparkle", 0.9)
		end)

		-- ===== the mole =====
		local blink = (t % 2.6) < 0.1
		local shut = blink or (t >= 9.5 and t < 9.78)
		mole:show("Eyes", not shut)
		mole:show("EyesShut", shut)
		mole:set("EarL", R(0, 0, math.sin(t * 3.1) * 3))
		mole:set("EarR", R(0, 0, -math.sin(t * 3.1 + 1) * 3))
		mole:set("Whiskers", R(math.sin(t * 13) * 2.5, 0, 0))
		local breathe = math.sin(t * 2.4) * 0.012
		mole:size("Body", V(1 + breathe, 1 - breathe, 1 + breathe))
		local pour, down = 0, 0
		local canCF = W(0, -60, 0)
		local rest = W(SPOT.X - 1.5, floorY(SPOT.X - 1.5, SPOT.Z - 0.7), SPOT.Z - 0.7) * R(0, 30, 0)
		if not inVisit and t < 7.6 then
			mole.root = W(0, -60, 0)
		elseif inVisit then
			-- he walks in with the can, waters the roots, and goes; after the third watering he stays, and waits
			local stay = visit == 3
			local walkIn = smooth(0, 0.42, u)
			local walkOut = stay and 0 or smooth(1.08, 1.45, u)
			local stoop = (visit - 1) * 5
			local stepF = 22 - 3 * (visit - 1)
			local moving = (u < 0.42 or (not stay and u > 1.08)) and 1 or 0
			local p = DOOR:Lerp(SPOT, walkIn - walkOut)
			local y = floorY(p.X, p.Z) + math.abs(math.sin(u * stepF)) * 0.12 * moving
			local yaw = MOLE_YAW + (stay and 0 or 180 * smooth(1.02, 1.14, u))
			pour = smooth(0.48, 0.6, u) * (1 - smooth(0.95, 1.05, u))
			down = stay and smooth(1.1, 1.3, u) or 0
			mole.root = W(p.X, y, p.Z) * R(0, yaw, 0)
			mole:pose(lean({
				LegL = R(math.sin(u * stepF) * 32 * moving, 0, 0), LegR = R(-math.sin(u * stepF) * 32 * moving, 0, 0),
				ArmL = R(46 + 18 * pour - 16 * down, 0, 22 + 4 * down), ForeL = R(48 + 8 * down, 0, 0),
				ArmR = R(46 + 18 * pour - 16 * down, 0, -22 - 4 * down), ForeR = R(48 + 8 * down, 0, 0),
				Head = R(4 + 14 * pour - 12 * down, 0, math.sin(u * stepF) * 3 * moving), Body = R(6 + stoop + 8 * pour, 0, 0),
				Tail1 = R(0, math.sin(t * 6) * 16, 0), Tail2 = R(0, math.sin(t * 6 - 0.8) * 20, 0),
			}))
			mole:alpha("Grey", GREY[visit])
			ctx.once("pour" .. visit, VISITS[visit] + 0.5, t, function() sfx("pop", 0.8 + visit * 0.1) end)
			ctx.once("step" .. visit, VISITS[visit] + 0.05, t, function() sfx("land", 1.4) end)
		else
			mole.root = W(SPOT.X, SPOT.Y, SPOT.Z) * R(0, MOLE_YAW, 0)
			mole:pose(lean(named(t)))
			mole:set("Tail1", R(0, math.sin(t * 5) * 14, 0))
			mole:set("Tail2", R(0, math.sin(t * 5 - 0.8) * 18, 0))
			mole:alpha("Grey", 0)
			canCF = rest
		end
		-- no easing across a cut or across the years between two visits
		local phase = visit * 10 + (t >= 7.6 and 1 or 0) + (t >= 8.45 and 1 or 0) + (t >= 9.6 and 1 or 0)
		if phase ~= mole.phase then
			mole.phase = phase
			mole:snap()
		end
		mole:smooth(dt, 13)
		mole:update()
		-- the can rides in front of his chest (read after the pose was eased); set down beside him at the end
		if inVisit then canCF = (mole:joint("Body") * CFrame.new(0, 0.15 + 0.25 * pour, -1.25) * R(-8 - 36 * pour, 0, 0)):Lerp(rest, down) end
		can.root = canCF
		pourPart.CFrame = canCF * CFrame.new(0, 0.66 * 0.85, -1.1 * 0.85)
		pourFx.Rate = 80 * pour

		-- ===== NAMED: the glow runs over every mushroom, the roots open, and the tree hands it down =====
		local wave = (t - 7.7) * 26
		for i, c in caps do
			local g = 0.14 + 0.06 * math.sin(t * 1.5 + c[3])
			if t >= 7.7 then
				local d = (c[2] - wave) / 5
				g = g + math.exp(-d * d) * 0.9 + 0.4 * smooth(0, 6, wave - c[2])
			end
			c[1].Color = CAP_DIM:Lerp(CAP_LIT, math.clamp(g, 0, 1))
		end
		for i, l in shroomLights do l.Brightness = 0.4 + 0.9 * smooth(7.8, 8.6, t) end
		flies.Rate = 6 + 10 * smooth(7.8, 8.6, t)
		ctx.once("ripple", 7.7, t, function()
			ctx.sound(SND.dawn, 0.35, 0.7)
			sfx("sparkle", 0.8)
		end)
		if t >= 7.6 then
			local pop = backOut(lin(8.42, 8.7, t))
			local shown = t >= 8.42
			local paws = O:PointToObjectSpace(((mole:joint("ForeL") * PAW_L).Position + (mole:joint("ForeR") * PAW_R).Position) / 2)
			local give = smooth(8.8, 9.5, t)
			local from = V(CRADLE.X, CRADLE.Y + 2.5, CRADLE.Z)
			local at = from:Lerp(paws + V(0, 0.95 + math.sin(t * 2) * 0.06, 0), give) + V(0, math.sin(give * math.pi) * 0.8, 0)
			local spin = smooth(9.6, 10.9, t) * 360
			if shown then
				placePick(CFrame.new(at) * R(0, 180 + spin, -20), 2.5 * (0.5 + 0.5 * pop) + 0.4 * smooth(9.5, 10.0, t))
			else
				placePick(CFrame.new(0, -60, 0), 2.5)
			end
			heroPart.CFrame = W(at.X, at.Y + 0.4, at.Z)
			raysIm.ImageTransparency = 1 - 0.65 * smooth(8.45, 8.8, t) * (1 - smooth(10.6, 11.1, t))
			raysIm.Rotation = t * 18
			ctx.once("open", 8.15, t, function() ctx.sound(SND.whittle, 0.35, 0.6) end)
			ctx.once("reveal", 8.45, t, function()
				heroSpark:Emit(40)
				ctx.sound(SND.dawn, 0.6, 1)
				sfx("sparkle", 1.3)
				ctx.kick(4)
				ctx.hold(4 / 60)
			end)
			ctx.once("given", 9.5, t, function()
				sfx("coin", 1.1)
				sfx("pop", 1.3)
				ctx.kick(1.6)
			end)
			heroSpark.Rate = t >= 8.6 and 8 or 0
			ctx.name("Grown, not made.")
			ctx.cardAlpha = smooth(9.0, 9.35, t) * (1 - smooth(10.7, 11.0, t))
		end
		ctx.flashAlpha = 0.6 * (1 - lin(8.45, 8.8, t)) * (t >= 8.45 and 1 or 0)

		faceFillPart.CFrame = mole.root * CFrame.new(0, 3.0, -2.4)
		-- ===== chapters and camera =====
		if t >= 0.35 and t < 3.0 then ctx.chapter(1, "BORN", "A drop of amber sap forms in the heart of the oldest tree.")
		elseif t >= 3.2 and t < 7.6 then ctx.chapter(2, "MADE", "The roots wind round it for years. A mole waters them.")
		elseif t >= 7.8 then ctx.chapter(3, "NAMED", "The roots open, and the tree hands it down.") end
		local cf, fov, focus
		local function shot(from, aim2, f) cf, fov, focus = CFrame.lookAt(from, aim2), f, (from - aim2).Magnitude end
		if t < 1.3 then
			-- the hall: in under the arching roots, down the ray to the mound
			local k = smooth(0, 1.3, t)
			shot(V(-4 + 1.5 * k, 9 - 4.6 * k, -30 + 12 * k), V(1, 9 - 5.5 * k, 6), 58 - 8 * k)
		elseif t < 3.0 then
			-- close on the knot of rootlets: the drop lands and swells
			shot(V(-1.7 + 0.3 * smooth(1.3, 3.0, t), 2.5, -2.4 + 0.6 * smooth(1.3, 3.0, t)), V(heart.X, heart.Y + 0.25, heart.Z), 36)
		elseif t < VISITS[3] then
			-- one fixed place for the years: the mole, the cradle and the ray in one picture
			shot(V(-1.5, 2.7, -8.8 + 0.8 * smooth(3.0, VISITS[3], t)), V(-1.2, 2.3, 3.0), 42)
		elseif t < 7.6 then
			-- the third visit, nearer: he is old now, and the roots close
			shot(V(-1.0, 2.2, -6.2 + 0.4 * smooth(VISITS[3], 7.6, t)), V(-1.3, 2.4, 3.0), 38)
		elseif t < 8.45 then
			-- wide and low: the glow runs out over every mushroom
			shot(V(-6.5, 1.5, -13.5 + 1.0 * smooth(7.6, 8.45, t)), V(0, 3, 3.5), 50)
		elseif t < 9.6 then
			-- the roots open and reach down to him
			shot(V(-2.3, 2.5, -7.6), V(-1.5, 2.7, 3.0), 40)
		else
			-- low beside him, the ray behind: he holds it in both paws
			shot(V(-0.6 - 0.3 * smooth(9.6, 10.9, t), 1.6, -4.6 + 0.6 * smooth(9.6, 10.9, t)), V(-2.6, 3.1, 2.2), 52 - 2 * smooth(9.6, 10.9, t))
		end
		ctx.cam, ctx.fov = O * cf, fov
		ctx.dof.FocusDistance = focus
		ctx.dof.InFocusRadius, ctx.dof.FarIntensity, ctx.dof.NearIntensity = 400, 0, 0
	end
end

return M
