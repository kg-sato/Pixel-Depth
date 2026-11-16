-- ReplicatedStorage.Shared.ForgeCopper (src/ForgeCopper.luau): the Kobold-Copper Pickaxe biography, played by ForgeStory.
-- BORN: a pick opens the wall and the vein shines green in the lantern light. MADE: three kobolds hammer the cold copper in
-- turn, three hammers and three notes that become a tune, and stop twice to argue. NAMED: all three hold it up at once, and
-- pull. "Made by committee."
-- The setting is a place of its own (references refs/forge/sheets/copper_setting_s11.png and kobold_views_s11.png): a cramped
-- mine tunnel under the roots, crooked timber, a green copper vein across the back wall, a stump for an anvil.
-- Built from design3d/copper.mjs. The tunnel is one model seen from inside; ONE swinging lantern is the whole light: the sun
-- is switched off (Lighting.Brightness 0), so every shadow on the wall is a hammer or an ear moving in front of the lantern.
-- Space: front of a model is -Z, the camera stands at -Z and looks at the back wall at z = +8. +X is screen left.
-- Every time in this file is a story second; the clock runs at 0.58 of real time (see ForgeWood).
local M = { length = 11.2, named = 7.6, open = true, pace = 0.58, fastPace = 0.75 }
-- an interior has no sky of its own: the Wood scene's night pictures stand behind the rock, in case a gap shows
local IMG = { night = { side = "98540000433096", up = "102757336864746", dn = "100178533145001" } }

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
	local FAR = W(0, -60, 0)

	-- ===== the place =====
	local function matte(r, shiny)
		r:all(function(p, b)
			if p.Material ~= Enum.Material.Neon and not (shiny and shiny[b.name]) then p.Material = Enum.Material.Rubber end
		end)
	end
	local mine = ctx.prop("CopperMine")
	matte(mine)
	mine:all(function(p, b) if b.name == "FarLights" or b.name == "VeinGlow" then p.CastShadow = false end end)
	local stump = ctx.prop("StumpAnvil", CFrame.new(0, 0, 1.2))
	matte(stump)
	matte(ctx.prop("CratesTable", CFrame.new(5.0, 0, -2.2) * R(0, 35, 0)))
	local lift = ctx.rig("BucketLift", CFrame.new(-5.0, 0, 5.4) * R(0, -30, 0))
	matte(lift)
	ctx.sky(IMG.night)
	ctx.atmo({ Density = 0.45, Haze = 0, Color = rgb(34, 24, 38), Decay = rgb(20, 14, 24), Glare = 0, Offset = 0 })
	ctx.light({ Brightness = 0, Ambient = rgb(84, 70, 80), OutdoorAmbient = rgb(84, 70, 80), ColorShift_Top = rgb(0, 0, 0), ExposureCompensation = 0, EnvironmentDiffuseScale = 0, EnvironmentSpecularScale = 0 })

	-- the lantern: it hangs from the pole over the stump and swings; its light is the scene's key light and casts the shadows
	local HOOK = V(0.4, 6.92, 1.6)
	local lantern = ctx.rig("Lantern", CFrame.new(HOOK))
	lantern:all(function(p, b) if b.name == "Glass" then p.CastShadow = false else p.Material = Enum.Material.Rubber end end)
	local lampPart = ctx.part(v3(0.2, 0.2, 0.2), CFrame.new(HOOK + V(0, -2.0, 0)), hex("#ffd98a"), { Transparency = 1 })
	local lamp = Instance.new("PointLight")
	lamp.Color, lamp.Range, lamp.Brightness, lamp.Shadows, lamp.Parent = hex("#ffd6a8"), 38, 1.5, true, lampPart
	local lampGlow = Instance.new("BillboardGui")
	lampGlow.Size, lampGlow.LightInfluence, lampGlow.Brightness, lampGlow.Parent = UDim2.fromScale(5, 5), 0, 1, lampPart
	local lampGlowIm = Instance.new("ImageLabel")
	lampGlowIm.BackgroundTransparency, lampGlowIm.Image, lampGlowIm.ImageColor3, lampGlowIm.ImageTransparency, lampGlowIm.Size, lampGlowIm.Parent = 1, S.GLOW, hex("#ffb45a"), 0.55, UDim2.fromScale(1, 1), lampGlow
	-- the far lanterns in the two side tunnels: a dim warm breath of light at each mouth
	for _, at in { V(-14.5, 3.4, 5.4), V(14.5, 3.4, -1.6) } do
		local lp = ctx.part(v3(0.2, 0.2, 0.2), CFrame.new(at), hex("#ffd98a"), { Transparency = 1 })
		local l = Instance.new("PointLight")
		l.Color, l.Range, l.Brightness, l.Shadows, l.Parent = hex("#ffa850"), 20, 1.1, false, lp
	end
	-- the vein: its own green light on the rock once the wall is open, and glints that travel along it
	local veinLightPart = ctx.part(v3(0.2, 0.2, 0.2), CFrame.new(-0.4, 3.8, 6.2), hex("#6fe8b8"), { Transparency = 1 })
	local veinLight = Instance.new("PointLight")
	veinLight.Color, veinLight.Range, veinLight.Brightness, veinLight.Shadows, veinLight.Parent = hex("#6fe8b8"), 17, 0, false, veinLightPart
	local veinPart = ctx.part(v3(14.5, 1.2, 0.3), CFrame.new(-0.1, 3.8, 7.3) * R(0, 0, -18), hex("#ffffff"), { Transparency = 1 })
	local veinGlint = ctx.emitter(veinPart, { Texture = S.SPARK, Color = ColorSequence.new(hex("#d8fff0"), hex("#3fa58c")), Size = NumberSequence.new({ K(0, 0), K(0.5, 0.5), K(1, 0) }), Transparency = NumberSequence.new(0.05), Lifetime = NumberRange.new(0.35, 0.7), Speed = NumberRange.new(0, 0.3), Rotation = NumberRange.new(0, 360) })
	local breakPart = ctx.part(v3(4, 3, 0.4), CFrame.new(-0.6, 3.4, 7.0), hex("#ffffff"), { Transparency = 1 })
	local rockDust = ctx.emitter(breakPart, { Texture = S.SMOKE, Color = ColorSequence.new(hex("#8a7490")), Size = NumberSequence.new({ K(0, 0.8), K(1, 3.6) }), Transparency = NumberSequence.new({ K(0, 0.35), K(1, 1) }), Lifetime = NumberRange.new(0.9, 1.6), Speed = NumberRange.new(3, 9), SpreadAngle = Vector2.new(50, 50), EmissionDirection = Enum.NormalId.Front, Drag = 2.5, LightEmission = 0, LightInfluence = 1 })
	local rockChips = ctx.emitter(breakPart, { Texture = S.GLOW, Color = ColorSequence.new(hex("#62496a"), hex("#3fa58c")), Size = NumberSequence.new({ K(0, 0.34), K(1, 0.16) }), Transparency = NumberSequence.new({ K(0, 0), K(0.8, 0), K(1, 1) }), Lifetime = NumberRange.new(0.5, 0.9), Speed = NumberRange.new(8, 17), SpreadAngle = Vector2.new(48, 48), EmissionDirection = Enum.NormalId.Front, Acceleration = v3(0, -38, 0), LightEmission = 0, LightInfluence = 1 })
	-- the air: dust motes turning in the lantern light, drips from the roots, dust shaken from the timbers by the hammering
	local airPart = ctx.part(v3(13, 6.5, 22), CFrame.new(0, 3.8, -2), hex("#ffffff"), { Transparency = 1 })
	local motes = ctx.emitter(airPart, { Texture = S.GLOW, Color = ColorSequence.new(hex("#ffd9a0")), Size = NumberSequence.new({ K(0, 0), K(0.2, 0.08), K(0.8, 0.08), K(1, 0) }), Transparency = NumberSequence.new(0.45), Lifetime = NumberRange.new(5, 8), Speed = NumberRange.new(0.1, 0.4), SpreadAngle = Vector2.new(180, 180), LightEmission = 0.4, LightInfluence = 0.6, Rate = 26 })
	motes:Emit(90)
	local roofPart = ctx.part(v3(10, 0.2, 18), CFrame.new(0, 7.5, 0), hex("#ffffff"), { Transparency = 1 })
	ctx.emitter(roofPart, { Texture = S.GLOW, Color = ColorSequence.new(hex("#bfe6ff")), Size = NumberSequence.new(0.09), Transparency = NumberSequence.new(0.3), Lifetime = NumberRange.new(0.5, 0.55), Speed = NumberRange.new(14, 16), EmissionDirection = Enum.NormalId.Bottom, SpreadAngle = Vector2.new(0, 0), LightEmission = 0.3, LightInfluence = 0.7, Rate = 2.5 })
	local beamPart = ctx.part(v3(12, 0.2, 0.8), CFrame.new(0, 6.5, 5.2), hex("#ffffff"), { Transparency = 1 })
	local beamDust = ctx.emitter(beamPart, { Texture = S.SMOKE, Color = ColorSequence.new(hex("#c9a98a")), Size = NumberSequence.new({ K(0, 0.2), K(1, 0.7) }), Transparency = NumberSequence.new({ K(0, 0.5), K(1, 1) }), Lifetime = NumberRange.new(0.9, 1.4), Speed = NumberRange.new(0.5, 1.5), EmissionDirection = Enum.NormalId.Bottom, SpreadAngle = Vector2.new(20, 20), Acceleration = v3(0, -7, 0), LightEmission = 0, LightInfluence = 1 })

	-- ===== the cast: one kit, three kobolds =====
	-- the bossy one (a whistle), the dreamy one (flowers in her helmet), the tiny one (a helmet and a hammer too big for him)
	local SHINY = { Helmet = true }
	local function kobold(scale, whistle, flowers, helmetSize)
		local r = ctx.rig("KoboldKit", CFrame.new(0, -60, 0), scale)
		matte(r, SHINY)
		r:all(function(p, b) if b.name == "Eyes" or b.name == "Flame" then p.CastShadow = false end if b.name == "Eyes" then p.Material = Enum.Material.SmoothPlastic end end)
		r:show("EyesShut", false)
		r:show("Whistle", whistle)
		r:show("Flowers", flowers)
		r:size("Helmet", helmetSize)
		return r
	end
	local KOB = {
		{ rig = kobold(1.0, true, false, 1), s = 1.0, hs = 1.0, ph = 0, note = 1.0, born = CFrame.new(2.5, 0, 4.2) * R(0, 122, 0), made = CFrame.new(2.05, 0, 0.9) * R(0, 62, 0), named = V(1.75, 0, -0.9), yaw = 28 },
		{ rig = kobold(0.94, false, true, 1), s = 0.94, hs = 0.9, ph = 1.3, note = 1.26, born = CFrame.new(-1.2, 0, 5.3) * R(0, 158, 0), made = CFrame.new(-2.05, 0, 0.9) * R(0, -62, 0), named = V(-1.75, 0, -0.9), yaw = -28 },
		{ rig = kobold(0.68, false, false, 1.14), s = 0.68, hs = 1.3, ph = 2.9, note = 1.5, born = CFrame.new(-3.4, 0, 3.9) * R(0, -150, 0), made = CFrame.new(0, 0.9, 3.0), named = V(0, 0, -1.1), yaw = 0 },
	}
	for _, k in KOB do
		k.hammer = ctx.rig("Hammer", CFrame.new(0, -60, 0), k.hs)
		k.hammer:all(function(p) p.Material = Enum.Material.Rubber end)
	end
	local minePick = ctx.rig("MinePick", CFrame.new(0, -60, 0), 0.95)
	minePick:all(function(p) p.Material = Enum.Material.Rubber end)
	local lump = ctx.rig("CopperLump", CFrame.new(0, -60, 0))
	lump:all(function(p, b) if b.name == "Dull" then p.Material = Enum.Material.Rubber end end)
	local pick = ctx.pick()
	local pickScale0, pickH = 1, 5
	if pick then pickScale0, pickH = pick:GetScale(), math.max(pick:GetExtentsSize().Y, 0.1) pick:PivotTo(FAR) end
	local function placePick(cf, height) -- stage-space frame, wanted height in studs
		if not pick then return end
		pick:ScaleTo(pickScale0 * height / pickH)
		pick:PivotTo(O * cf)
	end

	-- the work: three spark colours, one for each hammer
	local ANVIL = V(0, 1.93, 1.2)
	local workPart = ctx.part(v3(0.3, 0.3, 0.3), CFrame.new(ANVIL + V(0, 0.3, 0)), hex("#ffffff"), { Transparency = 1 })
	local function sparks(c0, c1)
		return ctx.emitter(workPart, { Texture = S.SPARK, Color = ColorSequence.new(hex(c0), hex(c1)), Size = NumberSequence.new(0.3, 0), Transparency = NumberSequence.new(0, 1), Lifetime = NumberRange.new(0.3, 0.65), Speed = NumberRange.new(6, 13), SpreadAngle = Vector2.new(70, 70), EmissionDirection = Enum.NormalId.Top, Acceleration = v3(0, -32, 0), LightEmission = 0.6 })
	end
	KOB[1].sparks, KOB[2].sparks, KOB[3].sparks = sparks("#fff0c0", "#ff9c4a"), sparks("#d8fff0", "#3fa58c"), sparks("#ffe0ec", "#ff7aa8")
	local flakes = ctx.emitter(workPart, { Texture = S.GLOW, Color = ColorSequence.new(hex("#e8a064"), hex("#c8743a")), Size = NumberSequence.new({ K(0, 0.16), K(1, 0.06) }), Transparency = NumberSequence.new({ K(0, 0), K(1, 0.7) }), Lifetime = NumberRange.new(0.5, 0.8), Speed = NumberRange.new(2, 5), SpreadAngle = Vector2.new(80, 80), EmissionDirection = Enum.NormalId.Top, Acceleration = v3(0, -18, 0), LightEmission = 0.2, LightInfluence = 1 })
	local sparkle = ctx.emitter(workPart, { Texture = S.SPARK, Color = ColorSequence.new(hex("#ffffff"), hex("#ffd98a")), Size = NumberSequence.new({ K(0, 0), K(0.3, 0.7), K(1, 0) }), Transparency = NumberSequence.new(0, 1), Lifetime = NumberRange.new(0.6, 1.2), Speed = NumberRange.new(3, 9), SpreadAngle = Vector2.new(180, 180), Rotation = NumberRange.new(0, 360), Drag = 2 })
	local hitLight = Instance.new("PointLight") -- every blow lights the faces round the anvil for a moment
	hitLight.Color, hitLight.Range, hitLight.Brightness, hitLight.Shadows, hitLight.Parent = hex("#ffd98a"), 12, 0, false, workPart
	local heroPart = ctx.part(v3(0.3, 0.3, 0.3), CFrame.new(0, 3.4, -1.1), hex("#ffffff"), { Transparency = 1 })
	local rays = Instance.new("BillboardGui")
	rays.Size, rays.LightInfluence, rays.Brightness, rays.Parent = UDim2.fromScale(12, 12), 0, 1.2, heroPart
	local raysIm = Instance.new("ImageLabel")
	raysIm.BackgroundTransparency, raysIm.Image, raysIm.ImageColor3, raysIm.ImageTransparency, raysIm.Size, raysIm.Parent = 1, "rbxassetid://98789616938156", hex("#ffd98a"), 1, UDim2.fromScale(1, 1), rays
	local heroSpark = ctx.emitter(heroPart, { Texture = S.SPARK, Color = ColorSequence.new(hex("#ffffff"), hex("#e8a064")), Size = NumberSequence.new({ K(0, 0), K(0.3, 0.6), K(1, 0) }), Transparency = NumberSequence.new(0, 1), Lifetime = NumberRange.new(0.8, 1.6), Speed = NumberRange.new(2, 7), SpreadAngle = Vector2.new(180, 180), Rotation = NumberRange.new(0, 360), Drag = 1.5 })
	local heroLight = Instance.new("PointLight")
	heroLight.Color, heroLight.Range, heroLight.Brightness, heroLight.Shadows, heroLight.Parent = hex("#ffc27a"), 14, 0, false, heroPart

	-- ===== the timetable =====
	-- the hammer song: who strikes when. Three rounds, each faster; between them they argue. The last blow is the smallest one's.
	local HITS = {
		{ 3.5, 1 }, { 3.86, 2 }, { 4.22, 3 },
		{ 5.0, 1 }, { 5.22, 2 }, { 5.44, 3 }, { 5.66, 1 }, { 5.88, 2 }, { 6.1, 3 },
		{ 6.72, 1 }, { 6.86, 2 }, { 7.0, 3 }, { 7.14, 1 }, { 7.28, 2 }, { 7.44, 3 },
	}
	local WALL = { 1.3, 1.75 } -- the dreamy one's two blows with the old pick; the second opens the wall
	local OPEN, DONE = WALL[2], HITS[#HITS][1]
	local ARG1, ARG1_END, ARG2, ARG2_END = 4.36, 4.94, 6.18, 6.66
	local function around(list, who, t) -- seconds since this kobold's last blow, seconds to the next one
		local since, to = 9, 9
		for _, h in list do
			local at = typeof(h) == "number" and h or (h[2] == who and h[1] or nil)
			if at then
				if at <= t then since = t - at elseif at - t < to then to = at - t end
			end
		end
		return since, to
	end
	-- as in ForgeWood: a positive first angle on Head and Body means "lean forward"; flipped here once for a model that faces -Z
	local function lean(p)
		for _, b in { "Head", "Body" } do
			local cf = p[b]
			if cf then local x, y, z = cf:ToEulerAnglesXYZ() p[b] = CFrame.Angles(-x, y, z) end
		end
		return p
	end
	-- one swing of a tool in the right paw: ready, drawn back over the head, down on the mark
	local function swingPose(since, to, ant, both)
		if since < 0.07 then
			return { ArmR = R(58, 0, -2), ForeR = R(8, 0, 0), ArmL = both and R(58, 0, 14) or R(40, 0, 22), ForeL = both and R(14, 0, 0) or R(40, 0, 0), Head = R(16, 0, 0), Body = R(22, 0, 0) }
		elseif to < ant then
			return { ArmR = R(168, 0, -6), ForeR = R(26, 0, 0), ArmL = both and R(160, 0, 14) or R(30, 0, 30), ForeL = both and R(30, 0, 0) or R(50, 0, 0), Head = R(-12, 0, 0), Body = R(-12, 0, 0) }
		end
		return { ArmR = R(72, 0, -10), ForeR = R(62, 0, 0), ArmL = both and R(66, 0, 16) or R(22, 0, 16), ForeL = both and R(60, 0, 0) or R(34, 0, 0), Head = R(8, 0, 0), Body = R(6, 0, 0) }
	end
	local PAW_L, PAW_R = V(-0.09, -0.5, -0.26), V(0.09, -0.5, -0.26)
	local function paw(k, side) return k.rig:joint(side == "L" and "ForeL" or "ForeR") * CFrame.new((side == "L" and PAW_L or PAW_R) * k.s) end

	-- sounds: the hammer notes are the Wood scene's bonk file at three pitches (this scene has no sounds of its own yet)
	local BONK = 101020483687867
	local function once(key, at, t, fn) if t - at < 0.25 then ctx.once(key, at, t, fn) end end
	local swing = 0 -- the lantern's phase: it runs faster as the tempo rises
	local hitT = -1

	return function(t, dt)
		local open = t >= OPEN
		local tempo = t < 7.6 and smooth(3.3, 7.3, t) or 0.25

		-- ===== the lantern, the light, the vein =====
		swing += dt * (2.6 + 2.4 * tempo)
		local sinceOpen = t - OPEN
		local amp = 4 + 11 * tempo + 13 * smooth(ARG2 + 0.1, ARG2 + 0.3, t) * (1 - smooth(ARG2_END, ARG2_END + 0.5, t)) + ((sinceOpen >= 0 and sinceOpen < 1.4) and 10 * math.exp(-sinceOpen * 2.6) or 0)
		lantern.root = W(HOOK.X, HOOK.Y, HOOK.Z) * R(math.sin(swing * 0.7 + 1) * amp * 0.3, 0, math.sin(swing) * amp)
		lampPart.CFrame = lantern.root * CFrame.new(0, -2.0, 0)
		lamp.Brightness = 1.5 * (0.93 + 0.07 * math.sin(t * 23) * math.sin(t * 7.3))
		lift:set("Bucket", R(math.sin(t * 1.7) * 2.5, 0, math.sin(t * 1.3 + 1) * 3))
		mine:show("Cover", not open)
		mine:show("Vein", open)
		mine:show("VeinGlow", open)
		local shine = open and smooth(OPEN, OPEN + 0.5, t) or 0
		veinLight.Brightness = shine * (0.7 + 0.2 * math.sin(t * 3.1))
		veinGlint.Rate = 16 * shine
		ctx.cc.TintColor = rgb(255, 238, 220)
		ctx.cc.Saturation, ctx.cc.Contrast = -0.08, 0.08
		hitLight.Brightness = hitT > 0 and 2.2 * math.max(0, 1 - (t - hitT) / 0.16) or 0

		-- ===== the kobolds =====
		local phase = t < 3.0 and 0 or (t < 7.6 and 1 or 2)
		local arguing = (t >= ARG1 and t < ARG1_END) or (t >= ARG2 and t < ARG2_END)
		local lift8 = smooth(8.3, 8.5, t)
		local tug = math.sin((t - 9.2) * 5.2) * smooth(9.2, 9.5, t) * (1 - smooth(10.6, 11.1, t))
		local pickY = 1.75 + 1.2 * lift8 - 0.25 * math.sin(lin(8.15, 8.3, t) * math.pi) + 0.06 * math.sin(t * 3) * lift8
		local pickAt = V(tug * 0.5, pickY, -1.15)
		for i, k in KOB do
			local r = k.rig
			local ts = t + k.ph
			local breathe = math.sin(ts * 2.6) * 0.012
			r:size("Body", V(1 + breathe, 1 - breathe, 1 + breathe))
			local shut = (ts % 2.6) < 0.1
			local earL, earR = math.sin(ts * 3.1) * 4 + ((ts % 1.7) < 0.14 and 9 or 0), -math.sin(ts * 3.1 + 1) * 4 - ((ts % 2.1) < 0.14 and 9 or 0)
			r:set("Tail1", R(-10, math.sin(ts * 3) * 16, 0))
			r:set("Tail2", R(10, math.sin(ts * 3 - 0.8) * 22, 0))
			r:pose({ LegL = R(0, 0, 0), LegR = R(0, 0, 0) })
			local quick = false
			if phase == 0 then
				-- BORN: at the wall. The dreamy one swings the old pick, the bossy one points and whistles, the tiny one holds his ears
				local hop = sinceOpen > 0.12 and math.abs(math.sin((sinceOpen - 0.12) * 8)) * 0.8 * math.exp(-(sinceOpen - 0.12) * 1.6) or 0
				r.root = O * k.born * CFrame.new(0, hop * k.s, 0)
				local since, to = around(WALL, i, t)
				if sinceOpen > 0.12 then -- it is copper: all three throw their arms up
					r:pose(lean({ ArmL = R(158 + math.sin(ts * 14) * 12, 0, 22), ForeL = R(20, 0, 0), ArmR = R(158 - math.sin(ts * 14) * 12, 0, -22), ForeR = R(20, 0, 0), Head = R(-14, 0, 0), Body = R(-6, 0, 0) }))
					earL, earR = earL + 16, earR - 16
				elseif i == 2 then
					r:pose(lean(swingPose(since, to, 0.24, true)))
					quick = since < 0.1
				elseif i == 1 then
					local blow = t >= 0.85 and t < 1.1
					r:pose(lean({ ArmL = R(96, 0, 8), ForeL = R(8, 0, 0), ArmR = blow and R(60, 0, -30) or R(24, 0, -16), ForeR = blow and R(120, 0, 0) or R(30, 0, 0), Head = R(blow and -10 or 4, 0, 0), Body = R(blow and -8 or 4, 0, 0) }))
				else
					local flinch = (to < 0.3 or since < 0.25) and 1 or 0
					r:pose(lean({ ArmL = R(30 + 118 * flinch, 0, 14 - 44 * flinch), ForeL = R(30 + 86 * flinch, 0, 0), ArmR = R(30 + 118 * flinch, 0, -14 + 44 * flinch), ForeR = R(30 + 86 * flinch, 0, 0), Head = R(6 + 12 * flinch, 0, 0), Body = R(4 + 8 * flinch, 0, 0) }))
					shut = shut or flinch > 0
				end
			elseif phase == 1 then
				-- MADE: round the stump. Each waits with the hammer ready, draws back before a blow, and comes down on the copper
				local hopA = (arguing and i < 3) and math.abs(math.sin(ts * 17)) * 0.22 or 0
				r.root = O * k.made * CFrame.new(0, hopA, 0)
				local since, to = around(HITS, i, t)
				if arguing and i < 3 then -- the two big ones, nose to nose; the hammers forgotten in their paws
					local up = t >= ARG2 and 1 or 0 -- the second quarrel is about the lantern: both point up at it
					r:pose(lean({ ArmL = R(96 + 60 * up + math.sin(ts * 21) * 26, 0, 30 - 20 * up), ForeL = R(40 - 30 * up, 0, 0), ArmR = R(64 + math.sin(ts * 19 + 1) * 22, 0, -26), ForeR = R(70, 0, 0), Head = R(14 - 30 * up + math.sin(ts * 23) * 5, 0, math.sin(ts * 12) * 6), Body = R(16 - 14 * up, 0, 0) }))
					earL, earR = math.sin(ts * 27) * 20, -math.sin(ts * 27 + 0.6) * 20
				elseif arguing then -- the tiny one looks from one to the other, then gives up and covers his eyes
					local a = t >= ARG2 and (t - ARG2) or (t - ARG1)
					local cover = a > 0.3 and 1 or 0
					r:pose(lean({ ArmL = R(24 + 100 * cover, 0, 14 - 40 * cover), ForeL = R(34 + 80 * cover, 0, 0), ArmR = R(72, 0, -10), ForeR = R(62, 0, 0), Head = R(4 + 10 * cover, math.sin(a * 16) * 38 * (1 - cover), 0), Body = R(4, 0, 0) }))
					shut = shut or cover > 0
				else
					local gap = t < ARG1 and 0.36 or (t < ARG2 and 0.22 or 0.14)
					r:pose(lean(swingPose(since, to, gap * 0.62, false)))
					quick = since < 0.1
					if since < 0.12 then earL, earR = earL - 14, earR + 14 end -- the ears jump at his own blow
					r:pose({ LegL = R(-8 * math.max(0, 1 - since / 0.2), 0, 0) })
				end
			else
				-- NAMED: all three have hold of it. Low at first, then up over their heads at once; then the two big ones pull
				local side = i == 1 and 1 or (i == 2 and -1 or 0)
				local crouch = math.sin(lin(8.15, 8.3, t) * math.pi)
				if i < 3 then
					local toe = 0.18 * lift8 * (i == 2 and 1 or 0.3) + math.abs(math.sin((t - 8.45) * 9)) * 0.3 * (t >= 8.45 and math.exp(-(t - 8.45) * 3) or 0)
					r.root = W(k.named.X + tug * 0.55, toe - 0.12 * crouch, k.named.Z) * R(0, k.yaw, -tug * side * 7)
					local armUp = 52 + 114 * lift8
					r:pose(lean({ ArmL = R(armUp, 0, 10 - side * 14 * lift8), ForeL = R(36 - 28 * lift8, 0, 0), ArmR = R(armUp, 0, -10 - side * 14 * lift8), ForeR = R(36 - 28 * lift8, 0, 0), Head = R(8 - 28 * lift8, 0, tug * side * 6), Body = R(10 * crouch - 8 * lift8 - tug * side * 8, 0, 0) }))
					r:pose({ LegL = R(-14 * crouch, 0, 0), LegR = R(-14 * crouch, 0, 0) })
				else -- the tiny one will not let go: he goes up with it and hangs there, legs running in the air
					local hang = pickAt.Y - 2.8 * k.s
					r.root = W(pickAt.X, math.max(0, hang), k.named.Z) * R(0, 0, -tug * 14 * lift8)
					r:pose(lean({ ArmL = R(170, 0, 8), ForeL = R(6, 0, 0), ArmR = R(170, 0, -8), ForeR = R(6, 0, 0), Head = R(-20, 0, 0), Body = R(-4, 0, 0) }))
					r:pose({ LegL = R(math.sin(ts * 13) * 34 * lift8, 0, 6), LegR = R(-math.sin(ts * 13) * 34 * lift8, 0, -6) })
				end
				shut = shut or (t >= 8.45 and t < 9.1)
				earL, earR = earL + 10 * lift8, earR - 10 * lift8
			end
			r:set("EarL", R(0, 0, earL))
			r:set("EarR", R(0, 0, earR))
			r:show("Eyes", not shut)
			r:show("Pupils", not shut)
			r:show("EyesShut", shut)
			if phase ~= k.phase then k.phase = phase r:snap() end
			r:smooth(dt, quick and 36 or (arguing and 22 or 14))
			r:update()
		end

		-- ===== the tools =====
		local K1, K2, K3 = KOB[1], KOB[2], KOB[3]
		if phase == 0 then
			minePick.root = paw(K2, "R") * R(-100, 0, 0)
			K1.hammer.root = W(0.5, 2.0, 1.0) * R(0, 40, 90)
			K2.hammer.root = W(-0.4, 2.0, 1.4) * R(0, -70, 90)
			K3.hammer.root = W(1.0, 0.25, 2.7) * R(0, 20, 78)
		else
			minePick.root = W(-3.7, 0.3, 6.6) * R(-14, 0, -8)
			for i, k in KOB do
				if phase == 1 then
					k.hammer.root = paw(k, "R") * R(-100, 0, 0)
				else
					k.hammer.root = (i == 1 and W(3.0, 0.2, 0.6) * R(0, 30, 90)) or (i == 2 and W(-2.9, 0.2, 0.8) * R(0, -50, 90)) or W(0.1, 2.02, 1.2) * R(0, 96, 90)
				end
			end
		end

		-- ===== BORN: two blows, the wall opens, a lump of copper drops out =====
		once("whistle", 0.88, t, function() sfx("pop", 2.1) end)
		once("wall1", WALL[1], t, function()
			hitT = WALL[1]
			rockChips:Emit(10) rockDust:Emit(4) beamDust:Emit(5)
			ctx.sound(BONK, 0.5, 0.7) sfx("breakRock", 1.5) ctx.shake(0.35) ctx.hold(2 / 60) ctx.kick(1.4)
		end)
		once("wall2", OPEN, t, function()
			hitT = OPEN
			rockChips:Emit(46) rockDust:Emit(22) beamDust:Emit(14) veinGlint:Emit(24)
			ctx.sound(BONK, 0.6, 0.6) sfx("breakRock", 0.9) sfx("sparkle", 1.1) ctx.shake(1.0) ctx.hold(4 / 60) ctx.kick(3)
		end)
		once("cheer", OPEN + 0.3, t, function() sfx("pop", 1.5) sfx("pop", 1.9) end)

		-- ===== the copper: dull from the wall, brighter and flatter with every blow =====
		local done = 0
		for _, h in HITS do if h[1] <= t then done += 1 end end
		local p = done / #HITS
		local jolt = (hitT > 3 and t < 7.6) and math.max(0, 1 - (t - hitT) / 0.12) or 0
		if t < OPEN or t >= DONE then
			lump.root = FAR
		elseif t < 3.0 then -- it falls out of the wall and bounces between them
			local u = t - OPEN
			local fall = math.min(u / 0.42, 1)
			local b = u > 0.42 and math.abs(math.sin((u - 0.42) * 10)) * 0.9 * math.exp(-(u - 0.42) * 4) or 0
			lump.root = W(-0.5, 3.5 - 3.4 * fall * fall + b, 6.9 - 1.5 * fall) * R(fall * 220, fall * 80, 0)
			once("lumpLand", OPEN + 0.42, t, function() sfx("land", 1.2) ctx.kick(1.2) end)
		else
			lump.root = W(ANVIL.X, ANVIL.Y, ANVIL.Z)
		end
		local flat = V(1 + 0.7 * p + 0.12 * jolt, 1 - 0.55 * p - 0.1 * jolt, 1 + 0.25 * p + 0.08 * jolt)
		lump:size("Dull", flat)
		lump:size("Bright", flat)
		lump:alpha("Dull", math.clamp(p * 1.7, 0, 1))
		for n, h in HITS do
			once("hit" .. n, h[1], t, function()
				local k = KOB[h[2]]
				hitT = h[1]
				local round = n <= 3 and 1 or (n <= 9 and 2 or 3)
				ctx.sound(BONK, 0.5, k.note * (round == 3 and 1.335 or 1))
				k.sparks:Emit(7 + round * 4)
				flakes:Emit(3 + round)
				if round == 3 then beamDust:Emit(4) end
				ctx.hold((n == #HITS and 4 or 2) / 60) ctx.kick(1.2 + round * 0.5) ctx.shake(0.12 * round)
				if n == #HITS then -- the last blow: all three notes at once, and it is a pickaxe
					ctx.sound(BONK, 0.4, KOB[1].note * 1.335) ctx.sound(BONK, 0.4, KOB[2].note * 1.335)
					sparkle:Emit(30) sfx("sparkle", 1.2) sfx("pop", 1.4) ctx.shake(0.5)
				end
			end)
		end
		once("arg1", ARG1, t, function() sfx("pop", 1.7) end)
		once("arg1b", ARG1 + 0.16, t, function() sfx("pop", 2.2) end)
		once("arg1c", ARG1 + 0.34, t, function() sfx("pop", 1.9) end)
		once("arg2", ARG2, t, function() sfx("pop", 2.0) end)
		once("arg2b", ARG2 + 0.14, t, function() sfx("pop", 1.6) end)
		once("arg2c", ARG2 + 0.3, t, function() sfx("swing", 1.3) end)

		-- ===== the pickaxe: it pops on the anvil, then all three have hold of it =====
		if t >= DONE and t < 7.6 then
			local pop = backOut(lin(DONE, DONE + 0.14, t))
			placePick(CFrame.new(ANVIL.X, ANVIL.Y + 0.35, ANVIL.Z) * R(0, 180, 78), 2.9 * (0.6 + 0.4 * pop))
		elseif t >= 7.6 then
			placePick(CFrame.new(pickAt) * R(0, 180, 90 + tug * 9), 3.1 + 0.3 * lift8)
			heroPart.CFrame = W(pickAt.X, pickAt.Y + 0.3, pickAt.Z)
			raysIm.ImageTransparency = 1 - 0.7 * smooth(8.45, 8.8, t) * (1 - smooth(10.6, 11.1, t))
			raysIm.Rotation = t * 22
			heroLight.Brightness = 1.6 * smooth(8.4, 8.7, t) * (1 - smooth(10.6, 11.1, t))
			once("reveal", 8.45, t, function()
				heroSpark:Emit(44)
				ctx.sound(BONK, 0.45, 1.0) ctx.sound(BONK, 0.45, 1.26) ctx.sound(BONK, 0.45, 1.5)
				sfx("sparkle", 1.3) ctx.kick(5) ctx.hold(4 / 60)
			end)
			once("pull", 9.25, t, function() sfx("pop", 1.8) sfx("swing", 1.1) end)
			once("pull2", 9.85, t, function() sfx("pop", 2.1) end)
			heroSpark.Rate = t >= 8.6 and 8 or 0
			ctx.name("Made by committee.")
			ctx.cardAlpha = smooth(9.0, 9.35, t) * (1 - smooth(10.7, 11.0, t))
		end
		ctx.flashAlpha = math.max(0.4 * (1 - lin(OPEN, OPEN + 0.25, t)) * (t >= OPEN and 1 or 0), 0.5 * (1 - lin(DONE, DONE + 0.2, t)) * (t >= DONE and 1 or 0), 0.8 * (1 - lin(8.45, 8.8, t)) * (t >= 8.45 and 1 or 0))

		-- ===== chapters and camera =====
		if t >= 0.35 and t < 3.0 then ctx.chapter(1, "BORN", "A pick opens the wall, and the vein shines green.")
		elseif t >= 3.2 and t < 7.6 then ctx.chapter(2, "MADE", "Three hammers, three notes. And two arguments.")
		elseif t >= 7.8 then ctx.chapter(3, "NAMED", "All three hold it up at once. And pull.") end
		local cf, fov, focus
		local function shot(from, aim, f) cf, fov, focus = CFrame.lookAt(from, aim), f, (from - aim).Magnitude end
		if t < 1.1 then -- the tunnel: down its length to the three at the back wall, the lantern swinging over the stump
			local u = smooth(0, 1.1, t)
			shot(V(0.6 - 0.3 * u, 3.7 - 0.5 * u, -14 + 4.5 * u), V(0, 3.1, 8), 58 - 6 * u)
		elseif t < 2.2 then -- beside her at the wall: the pick goes back, and in
			shot(V(-4.6, 3.0, 2.8 + 0.5 * smooth(1.1, 2.2, t)), V(-0.6, 2.8, 7.2), 48) -- from the side: the pick, the wall it opens
		elseif t < 3.0 then -- the vein, green in the rock, over their heads
			shot(V(-2.4, 2.1, 0.8 + 1.0 * smooth(2.2, 3.0, t)), V(-0.2, 3.8, 8), 50 - 4 * smooth(2.2, 3.0, t))
		elseif t < ARG1 then -- the stump and the three round it: the first slow round
			shot(V(0.9, 3.5 - 0.3 * smooth(3.0, ARG1, t), -8.4 + 0.8 * smooth(3.0, ARG1, t)), V(0, 2.2, 1.3), 44)
		elseif t < ARG1_END then -- the quarrel: the two big ones across the anvil, the tiny one between and behind
			shot(V(-0.5, 2.7, -6.6), V(0, 2.5, 1.2), 44)
		elseif t < ARG2 then -- close on the copper: the hammers come in turn and the tune finds itself
			local u = smooth(ARG1_END, ARG2, t)
			shot(V(1.6 - 1.2 * u, 3.3, -3.9 - 0.3 * u), V(0, 2.0, 1.2), 40)
		elseif t < ARG2_END then -- from the floor, up at the lantern they are fighting over
			shot(V(0.9, 1.1, -5.2), V(0.3, 4.3, 1.4), 50)
		elseif t < 7.6 then -- the last round, fast: in on the anvil
			shot(V(-1.1, 2.9, -4.6 + 0.9 * smooth(ARG2_END, 7.5, t)), V(0, 2.05, 1.2), 38 - 3 * smooth(ARG2_END, 7.5, t))
		else -- low in front of them, looking up: the pickaxe under the lantern
			local up = smooth(8.3, 9.2, t)
			shot(V(-1.3 - 0.3 * smooth(8.4, 10.8, t), 0.9, -8.6 + 0.8 * smooth(8.4, 10.8, t)), V(0, 2.2, -1.1):Lerp(V(0, 3.4, -1.1), up), 50 - 2 * smooth(8.4, 10.8, t))
		end
		ctx.cam, ctx.fov = O * cf, fov
		ctx.dof.FocusDistance = focus
		ctx.dof.InFocusRadius, ctx.dof.FarIntensity, ctx.dof.NearIntensity = 400, 0, 0
	end
end

return M
