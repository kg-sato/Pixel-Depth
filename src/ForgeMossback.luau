-- ReplicatedStorage.Shared.ForgeMossback (src/ForgeMossback.luau): the Mossback Pickaxe biography, played by ForgeStory.
-- BORN: a boulder breaks from the canyon rim and tumbles down the clay benches. MADE: a giant snail carries it for forty years,
-- one slow stretch at a time (dust wind, monsoon, a rainbow, a green morning), her silver trail behind her, until moss, ferns,
-- a nest and a tiny tree have taken it over. NAMED: she sets it down by the waterfall, and it has become something else.
-- "It grew on me."
-- The setting is a place of its own (references refs/forge/sheets/mossback_setting_s11.png and snail_views_s11.png): a
-- terraced canyon of red clay, rounded ledges, cave mouths, a rope bridge, a trickle of a stream falling from terrace to
-- terrace, and a mossy shelf at the bottom. Built from design3d/mossback.mjs and mossback_world.py (terrain, pictures, the map
-- of every stone, plant and ledge, the snail's route and the boulder's fall line in ForgeMossbackMap).
-- Space: front of a model is -Z, the camera stands at -Z and looks up the canyon toward +Z. The shelf is at the origin; the
-- terraces climb toward +Z; the stream and its pool are at x = +10 (screen left).
-- Every time in this file is a story second; the clock runs at 0.58 of real time (see ForgeWood).
-- Everything is computed from t, so the scene can start at NAMED (the short level-up version) with nothing fired before.
local M = { length = 11.2, named = 7.6, open = true, pace = 0.58, fastPace = 0.75 }
-- pictures made by design3d/mossback_world.py (ids in design3d/assets.json); the ripple and the rain streak are the Wood scene's
local IMG = {
	dust = { side = "135928594349171", up = "127781181542758", dn = "112129912933088", sun = 8 },
	rain = { side = "108912787317698", up = "114455606387198", dn = "123525661921145" },
	morning = { side = "128776022028146", up = "83606819437002", dn = "103742458121058", sun = 7 },
	ripple = "rbxassetid://108008922454214", streak = "rbxassetid://80922659043708",
}

local function hex(h) return Color3.fromHex(h) end
local function v3(x, y, z) return Vector3.new(x, y, z) end

function M.setup(ctx)
	local S = ctx.S
	local R, smooth, lin, backOut = S.rot, S.smooth, S.lin, S.backOut
	local O, sfx = ctx.O, ctx.sfx
	local function W(x, y, z) return O * CFrame.new(x, y, z) end
	local K = NumberSequenceKeypoint.new
	local rgb = Color3.fromRGB
	local V = Vector3.new
	local HIDE = W(0, -80, 0)

	-- ===== the place =====
	local MAP = require(script.Parent:WaitForChild("ForgeMossbackMap"))
	local land = ctx.prop("MossbackWorld")
	-- the canyon and its big rocks answer the camera's line-of-sight ray (only this scene's ray: Include list). 2026-11-19
	local solid = {}
	land:all(function(p, b) p.Material = Enum.Material.Rubber if b.name == "Far" then p.CastShadow = false else p.CanQuery = true table.insert(solid, p) end end)
	local SMALL = { PalePebble1 = true, PalePebble2 = true, PalePebble3 = true, WispyGrass = true, GrassTuft = true, FlowerPatch = true, FlowerPatch2 = true, Fern = true, Clover = true, Plant1 = true, Plant7 = true, Mushroom = true }
	for _, it in MAP.items do
		local r = ctx.prop(it[1], CFrame.new(it[2], it[3], it[4]) * CFrame.Angles(0, math.rad(it[5]), 0), it[6])
		local small, fall = SMALL[it[1]], it[1] == "Waterfall"
		r:all(function(p, b)
			if fall then
				p.Material, p.CastShadow, p.Transparency = Enum.Material.Neon, false, b.name == "Foam" and 0.2 or 0.38
			elseif p.Material ~= Enum.Material.Neon then
				p.Material = Enum.Material.Rubber
			end
			if small then p.CastShadow = false end
			if not small and not fall then p.CanQuery = true table.insert(solid, p) end
		end)
	end
	local seeRp = RaycastParams.new()
	seeRp.FilterType, seeRp.FilterDescendantsInstances = Enum.RaycastFilterType.Include, solid
	local lift = 0
	local function clearShot(from, aim, dt) -- a canyon rock between the camera and her: lift the camera until she shows (the Mossback camera sat in a rock, 2026-11-19)
		local want = 0
		for k = 0, 12 do
			local f, a = O * (from + V(0, k * 0.75, 0)), O * aim
			want = k * 0.75
			if not workspace:Raycast(f, a - f, seeRp) then break end
		end
		lift += (want - lift) * math.min(1, dt * 5) -- eased, so the camera rises instead of jumping
		return from + V(0, lift, 0)
	end
	-- the pool under the fall behind the shelf: a round clear sheet with the ripple picture turning on it
	local pool = ctx.part(v3(0.2, 7.2, 7.2), CFrame.new(MAP.pool[1], -0.42, MAP.pool[3]) * CFrame.Angles(0, 0, math.rad(90)), hex("#6f9a96"), { Shape = Enum.PartType.Cylinder, Transparency = 0.45, Reflectance = 0.15 })
	local poolFx = ctx.part(v3(5, 0.2, 5), CFrame.new(MAP.pool[1], -0.3, MAP.pool[3] + 2.4), hex("#ffffff"), { Transparency = 1 })
	local mist = ctx.emitter(poolFx, { Texture = S.SMOKE, Color = ColorSequence.new(hex("#eef6f6")), Size = NumberSequence.new({ K(0, 1.2), K(1, 4.5) }), Transparency = NumberSequence.new({ K(0, 1), K(0.2, 0.78), K(1, 1) }), Lifetime = NumberRange.new(2.2, 3.4), Speed = NumberRange.new(0.6, 1.6), EmissionDirection = Enum.NormalId.Top, SpreadAngle = Vector2.new(40, 40), LightEmission = 0.1, LightInfluence = 1, Rate = 6 })
	mist:Emit(8)
	-- the monsoon fills the terraces: one muddy sheet under each of the two the snail crosses, raised through the ground by the rain
	local sheets = {}
	for i, lv in MAP.levels do
		local p = ctx.part(v3(190, 0.3, lv[3]), CFrame.new(0, lv[1] - 0.7, lv[2]), hex("#9a5f4c"), { Transparency = 1, Reflectance = 0.18 })
		local tx = Instance.new("Texture")
		tx.Texture, tx.Face, tx.StudsPerTileU, tx.StudsPerTileV, tx.Transparency, tx.Parent = IMG.ripple, Enum.NormalId.Top, 26, 16, 1, p
		local rings = ctx.emitter(p, { Texture = S.GLOW, Color = ColorSequence.new(hex("#f0e0d8")), Size = NumberSequence.new({ K(0, 0.1), K(1, 1.4) }), Transparency = NumberSequence.new({ K(0, 0.5), K(1, 1) }), Lifetime = NumberRange.new(0.3, 0.5), Speed = NumberRange.new(0, 0.2), Orientation = Enum.ParticleOrientation.VelocityPerpendicular, EmissionDirection = Enum.NormalId.Top, LightEmission = 0.3 })
		sheets[i] = { part = p, y = lv[1], z = lv[2], tex = tx, rings = rings }
	end
	local sunRays = ctx.effect("SunRaysEffect", { Intensity = 0.04, Spread = 0.8 })
	local bow = ctx.prop("Rainbow", CFrame.new(-10, 6, 250), 2.3)
	local bowParts = {}
	bow:all(function(p) p.Material, p.CastShadow, p.Transparency = Enum.Material.Neon, false, 1 table.insert(bowParts, p) end)

	-- ===== the route and the trail =====
	local route, cum = {}, { 0 }
	for i, p in MAP.route do route[i] = V(p[1], p[2], p[3]) end
	for i = 2, #route do cum[i] = cum[i - 1] + (route[i] - route[i - 1]).Magnitude end
	local LEN = cum[#route]
	local function at(f) -- 0 to 1 along the route: the point, and the index of the route point just behind it
		local d = math.clamp(f, 0, 1) * LEN
		local i = 1
		while i < #route - 1 and cum[i + 1] < d do i += 1 end
		return route[i]:Lerp(route[i + 1], math.clamp((d - cum[i]) / math.max(cum[i + 1] - cum[i], 0.001), 0, 1)), i
	end
	local function frame(f) -- where she is and which way she faces (the slope tips her with it)
		local p, i = at(f)
		local a, b = at(f - 1.6 / LEN), at(f + 1.6 / LEN)
		return CFrame.lookAt(p, p + (b - a).Unit), p, i
	end
	local trail = {} -- one silver stride between every two route points, shown once her tail has passed it
	for i = 1, #route - 1 do
		local a, b = route[i] + V(0, 0.05, 0), route[i + 1] + V(0, 0.05, 0)
		local r = ctx.prop("TrailBit", CFrame.lookAt(a:Lerp(b, 0.5), b), 1)
		r:all(function(p) p.Material, p.Reflectance, p.CastShadow, p.Transparency = Enum.Material.SmoothPlastic, 0.3, false, 1 trail[i] = { part = p, on = false } end)
	end
	local fall = {}
	for i, p in MAP.fall do fall[i] = V(p[1], p[2], p[3]) end
	local RIM, LAND = fall[1], fall[#fall]
	local function fallAt(u) -- 0 to 1 down the canyon side: the ground under the boulder
		local x = math.clamp(u, 0, 1) * (#fall - 1) + 1
		local i = math.min(math.floor(x), #fall - 1)
		return fall[i]:Lerp(fall[i + 1], x - i)
	end

	-- ===== the cast =====
	local snail = ctx.rig("SnailKit", CFrame.new(0, -80, 0))
	snail:all(function(p, b) p.Material = b.name == "Shell" and Enum.Material.SmoothPlastic or Enum.Material.Rubber end)
	snail:show("ShutL", false) snail:show("ShutR", false)
	local boulder = ctx.rig("MossBoulder", CFrame.new(0, -80, 0))
	boulder:all(function(p) p.Material = Enum.Material.Rubber end)
	local bird = ctx.rig("Bird", CFrame.new(0, -80, 0), 1.25)
	bird:all(function(p) p.Material = Enum.Material.Rubber end)
	local pick = ctx.pick()
	local pickScale0, pickH = 1, 5
	if pick then pickScale0, pickH = pick:GetScale(), math.max(pick:GetExtentsSize().Y, 0.1) pick:PivotTo(HIDE) end
	local function placePick(cf, height) -- stage-space frame, wanted height in studs
		if not pick then return end
		pick:ScaleTo(pickScale0 * height / pickH)
		pick:PivotTo(O * cf)
	end
	local ON_BACK = CFrame.new(0, 2.1, 0.15) -- the boulder's seat on top of the shell, from the Shell joint
	local END = route[#route]
	local SET = END + V(3.0, 0, -2.6) -- where she sets it down: between her and the camera, on the pool's side

	-- ===== weather and effects =====
	local skyPart = ctx.part(v3(60, 1, 50), CFrame.new(0, 30, 0), hex("#ffffff"), { Transparency = 1 })
	local rainFx = ctx.emitter(skyPart, { Texture = IMG.streak, Color = ColorSequence.new(hex("#d6e2ee")), Size = NumberSequence.new(0.55), Squash = NumberSequence.new(3.2), Transparency = NumberSequence.new(0.42), Lifetime = NumberRange.new(0.4, 0.5), Speed = NumberRange.new(70, 84), EmissionDirection = Enum.NormalId.Bottom, Orientation = Enum.ParticleOrientation.VelocityParallel, Rotation = NumberRange.new(90), Acceleration = v3(16, 0, 0), LightEmission = 0.3, LightInfluence = 0.5, SpreadAngle = Vector2.new(2, 2) })
	local groundPart = ctx.part(v3(34, 0.2, 26), CFrame.new(0, 0.2, 0), hex("#ffffff"), { Transparency = 1 })
	local splash = ctx.emitter(groundPart, { Texture = S.GLOW, Color = ColorSequence.new(hex("#f2e6e0")), Size = NumberSequence.new({ K(0, 0.08), K(1, 0.42) }), Transparency = NumberSequence.new({ K(0, 0.4), K(1, 1) }), Lifetime = NumberRange.new(0.16, 0.3), Speed = NumberRange.new(1.5, 4.5), SpreadAngle = Vector2.new(55, 55), EmissionDirection = Enum.NormalId.Top, Acceleration = v3(0, -22, 0), LightEmission = 0.4 })
	local dew = ctx.emitter(groundPart, { Texture = S.SPARK, Color = ColorSequence.new(hex("#ffffff"), hex("#eaffd0")), Size = NumberSequence.new({ K(0, 0), K(0.5, 0.36), K(1, 0) }), Transparency = NumberSequence.new(0.1), Lifetime = NumberRange.new(0.4, 0.9), Speed = NumberRange.new(0, 0.3), EmissionDirection = Enum.NormalId.Top, Rotation = NumberRange.new(0, 360) })
	local windPart = ctx.part(v3(1, 6, 30), CFrame.new(-20, 3, 0), hex("#ffffff"), { Transparency = 1 })
	local dustWind = ctx.emitter(windPart, { Texture = S.SMOKE, Color = ColorSequence.new(hex("#e0a888")), Size = NumberSequence.new({ K(0, 1.6), K(1, 4.5) }), Transparency = NumberSequence.new({ K(0, 1), K(0.2, 0.72), K(0.8, 0.8), K(1, 1) }), Lifetime = NumberRange.new(1.6, 2.4), Speed = NumberRange.new(16, 24), EmissionDirection = Enum.NormalId.Right, SpreadAngle = Vector2.new(8, 4), LightEmission = 0, LightInfluence = 1 })
	local rockPart = ctx.part(v3(0.5, 0.5, 0.5), CFrame.new(RIM), hex("#ffffff"), { Transparency = 1 })
	local rockDust = ctx.emitter(rockPart, { Texture = S.SMOKE, Color = ColorSequence.new(hex("#d8957a")), Size = NumberSequence.new({ K(0, 2.2), K(1, 9) }), Transparency = NumberSequence.new({ K(0, 0.3), K(1, 1) }), Lifetime = NumberRange.new(1.2, 2.2), Speed = NumberRange.new(3, 9), SpreadAngle = Vector2.new(180, 180), Drag = 2, LightEmission = 0, LightInfluence = 1 })
	local rockChips = ctx.emitter(rockPart, { Texture = S.SPARK, Color = ColorSequence.new(hex("#cb8369"), hex("#8b3f2e")), Size = NumberSequence.new(0.5, 0), Transparency = NumberSequence.new(0, 1), Lifetime = NumberRange.new(0.5, 1.0), Speed = NumberRange.new(8, 20), SpreadAngle = Vector2.new(70, 70), Acceleration = v3(0, -40, 0), LightEmission = 0, LightInfluence = 1 })
	local workPart = ctx.part(v3(0.3, 0.3, 0.3), CFrame.new(0, 2, 0), hex("#ffffff"), { Transparency = 1 })
	local sparkle = ctx.emitter(workPart, { Texture = S.SPARK, Color = ColorSequence.new(hex("#ffffff"), hex("#d6f0a8")), Size = NumberSequence.new({ K(0, 0), K(0.3, 0.6), K(1, 0) }), Transparency = NumberSequence.new(0, 1), Lifetime = NumberRange.new(0.6, 1.2), Speed = NumberRange.new(2, 7), SpreadAngle = Vector2.new(180, 180), Rotation = NumberRange.new(0, 360), Drag = 2 })
	local heroPart = ctx.part(v3(0.3, 0.3, 0.3), CFrame.new(SET + V(0, 4, 0)), hex("#ffffff"), { Transparency = 1 })
	local rays = Instance.new("BillboardGui")
	rays.Size, rays.LightInfluence, rays.Brightness, rays.Parent = UDim2.fromScale(13, 13), 0, 1.3, heroPart
	local raysIm = Instance.new("ImageLabel")
	raysIm.BackgroundTransparency, raysIm.Image, raysIm.ImageColor3, raysIm.ImageTransparency, raysIm.Size, raysIm.Parent = 1, "rbxassetid://98789616938156", hex("#f2ffd0"), 1, UDim2.fromScale(1, 1), rays
	local heroSpark = ctx.emitter(heroPart, { Texture = S.SPARK, Color = ColorSequence.new(hex("#ffffff"), hex("#a8c458")), Size = NumberSequence.new({ K(0, 0), K(0.3, 0.6), K(1, 0) }), Transparency = NumberSequence.new(0, 1), Lifetime = NumberRange.new(0.8, 1.6), Speed = NumberRange.new(2, 7), SpreadAngle = Vector2.new(180, 180), Rotation = NumberRange.new(0, 360), Drag = 1.5 })
	-- NAMED looks up the canyon into the light: a soft fill from the camera's side so her face and the pickaxe are not silhouettes
	local fillPart = ctx.part(v3(0.3, 0.3, 0.3), CFrame.new(END + V(1.5, 2.8, -7.5)), hex("#ffffff"), { Transparency = 1 })
	local fill = Instance.new("PointLight")
	fill.Color, fill.Range, fill.Brightness, fill.Shadows, fill.Parent = hex("#fff0c8"), 18, 0, false, fillPart

	-- ===== looks: the weather of forty years =====
	local LOOK = {
		dust = { Ambient = rgb(150, 122, 104), OutdoorAmbient = rgb(172, 142, 120), Brightness = 3.2, ColorShift_Top = rgb(255, 230, 194), ExposureCompensation = 0.05 },
		rain = { Ambient = rgb(112, 116, 124), OutdoorAmbient = rgb(122, 128, 136), Brightness = 1.3, ColorShift_Top = rgb(190, 200, 214), ExposureCompensation = 0.12 },
		bow = { Ambient = rgb(140, 138, 130), OutdoorAmbient = rgb(156, 156, 148), Brightness = 2.2, ColorShift_Top = rgb(255, 236, 200), ExposureCompensation = 0.05 },
		green = { Ambient = rgb(134, 146, 120), OutdoorAmbient = rgb(150, 162, 134), Brightness = 2.5, ColorShift_Top = rgb(240, 246, 210), ExposureCompensation = 0 },
		morning = { Ambient = rgb(140, 150, 132), OutdoorAmbient = rgb(156, 168, 150), Brightness = 2.7, ColorShift_Top = rgb(255, 240, 208), ExposureCompensation = 0 },
	}
	local ATMO = {
		dust = { Density = 0.36, Haze = 2.6, Color = rgb(236, 196, 160), Decay = rgb(190, 130, 100), Glare = 0.3, Offset = 0.25 },
		rain = { Density = 0.44, Haze = 2.7, Color = rgb(150, 156, 162), Decay = rgb(100, 106, 114), Glare = 0, Offset = 0.2 },
		bow = { Density = 0.36, Haze = 2.3, Color = rgb(226, 222, 208), Decay = rgb(160, 160, 160), Glare = 0.15, Offset = 0.2 },
		green = { Density = 0.32, Haze = 2.0, Color = rgb(228, 232, 210), Decay = rgb(160, 180, 160), Glare = 0.15, Offset = 0.25 },
		morning = { Density = 0.3, Haze = 1.9, Color = rgb(233, 225, 209), Decay = rgb(170, 186, 176), Glare = 0.2, Offset = 0.25 },
	}
	local TINT = { dust = rgb(255, 244, 226), rain = rgb(226, 232, 240), bow = rgb(250, 248, 240), green = rgb(244, 252, 236), morning = rgb(255, 250, 238) }
	local SAT = { dust = 0.05, rain = -0.22, bow = 0.08, green = 0.16, morning = 0.14 }
	local SKY = { dust = "dust", rain = "rain", bow = "morning", green = "morning", morning = "morning" }
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
	-- the sun: high and hard over the dry canyon; after the rain low up the canyon, so the ledges throw long soft shadows toward
	-- the camera and the moss is lit from behind
	local KEYS = { V(-0.3, 0.9, 0.2), V(0.2, 0.8, 0.3), V(0.35, 0.5, 0.75) }
	local keyNow = 0
	local function key(i) if keyNow ~= i then keyNow = i ctx.key(KEYS[i]) end end

	-- the forty years: five stretches of the route, each with its own weather { starts at, weather, where on the route it starts }
	local YEARS = { { 0, "dust", 0.04 }, { 3.0, "dust", 0.04 }, { 3.9, "rain", 0.25 }, { 4.8, "bow", 0.48 }, { 5.7, "green", 0.7 }, { 6.6, "morning", 0.9 } }
	local STEP = 0.038 -- how much of the route she covers inside one stretch
	local function year(t)
		for i = #YEARS, 1, -1 do
			if t >= YEARS[i][1] then return i, YEARS[math.max(i - 1, 1)][2], YEARS[i][2], smooth(YEARS[i][1], YEARS[i][1] + 0.16, t) end
		end
		return 1, "dust", "dust", 1
	end
	local function routeF(t) -- where she is on the route at story time t
		if t < 3.0 then return 0.04 end
		if t >= 7.6 then return 0.955 + 0.045 * smooth(7.6, 8.1, t) end
		local i = year(t)
		local t0, t1 = YEARS[i][1], YEARS[i + 1] and YEARS[i + 1][1] or 7.6
		return YEARS[i][3] + (i == #YEARS and 0.055 or STEP) * lin(t0, t1, t)
	end
	-- what has grown on the boulder, and from when
	local GROWTH = { { "Moss1", 3.95, 0.5 }, { "Moss2", 4.85, 0.5 }, { "Ferns", 5.0, 0.6 }, { "Moss3", 5.75, 0.6 }, { "Nest", 5.8, 0.3 }, { "Tree", 5.9, 1.3 } }
	-- the camera of each stretch, from her: always from down the canyon, so the terraces she came down stand behind her
	local CAMS = { V(5, 2.6, -8), V(-4.5, 2.1, -7.2), V(3.4, 3.4, -9.6), V(-5, 1.7, -6.8), V(2.4, 2.2, -8) }

	-- sounds: none of its own yet. The stream, the rain, the bells and the stone knock are the Stone and Wood scenes' files.
	local SND = { river = 117253485620174, rain = 71766947362966, dawn = 85010698086137, tap = 90326072989009 }
	local riverS = ctx.sound(SND.river, 0, 1, true)
	local rainS = ctx.sound(SND.rain, 0, 1, true)
	local T_BREAK, T_LAND, T_ROPE, T_SET = 1.1, 2.25, 2.62, 8.45

	return function(t, dt)
		-- an event fires only close to its own time: started at NAMED (the short version), the earlier ones stay silent
		local function once(key_, when, fn) if t < when + 0.3 then ctx.once(key_, when, t, fn) end end
		-- ===== weather, light, air =====
		local yi, wa, wb, wu = year(t)
		local function is(name) return (wb == name and wu or 0) + (wa == name and 1 - wu or 0) end
		local rain, dusty, bowW, morning = is("rain"), is("dust"), is("bow"), is("morning") + is("green")
		sky(SKY[wu > 0.5 and wb or wa])
		key(t < 3.9 and 1 or (t < 4.8 and 2 or 3))
		ctx.light(mixTo(LOOK[wa], LOOK[wb], wu))
		ctx.atmo(mixTo(ATMO[wa], ATMO[wb], wu))
		ctx.cc.TintColor = TINT[wa]:Lerp(TINT[wb], wu)
		ctx.cc.Saturation, ctx.cc.Contrast = SAT[wa] + (SAT[wb] - SAT[wa]) * wu, 0.08
		sunRays.Intensity = 0.04 * (1 - rain) + 0.03 * bowW
		fill.Brightness = 1.5 * smooth(7.6, 7.9, t)
		local wet = smooth(3.9, 4.7, t) * (1 - smooth(5.7, 6.5, t))
		for _, s in sheets do
			s.part.CFrame = W(0, s.y - 0.7 + 0.72 * wet, s.z)
			s.part.Transparency = 1 - 0.62 * smooth(0, 0.3, wet)
			s.tex.Transparency = 1 - 0.4 * smooth(0, 0.3, wet)
			s.tex.OffsetStudsU, s.tex.OffsetStudsV = t * 1.4, math.sin(t * 0.6) * 2
			s.rings.Rate = 320 * rain
		end
		for _, p in bowParts do p.Transparency = 1 - 0.5 * bowW * smooth(4.9, 5.2, t) end
		riverS.Volume = (0.07 + 0.25 * smooth(7.4, 8.0, t)) * smooth(0, 0.4, t)
		rainS.Volume = 0.36 * rain

		-- ===== the snail =====
		local f = routeF(t)
		local cf, pos, idx = frame(f)
		local crawling = (t >= 3.0 and t < 8.1) and 1 or 0
		local w = t * 5.2
		snail.root = O * cf
		snail:set("Head", CFrame.new(0, 0, -0.26 * (0.5 + 0.5 * math.sin(w)) * crawling))
		snail:set("Tail", CFrame.new(0, 0, 0.3 * (0.5 + 0.5 * math.sin(w - 1.7)) * crawling))
		snail:size("Body", V(1 - 0.03 * math.sin(w - 0.8) * crawling, 1 + 0.02 * math.sin(t * 2.2), 1 + 0.05 * math.sin(w - 0.8) * crawling))
		local startle = t >= T_LAND and math.max(0, 1 - (t - T_LAND) / 0.35) or 0 -- the boulder lands behind her: the stalks pull in
		local perk = smooth(T_LAND + 0.2, T_LAND + 0.5, t) * (1 - smooth(2.9, 3.0, t)) + smooth(8.45, 8.8, t)
		local stalk = 1 - 0.65 * startle + 0.12 * perk
		snail:size("StalkL", V(1, stalk, 1)) snail:size("StalkR", V(1, stalk, 1))
		snail:set("StalkL", R(math.sin(t * 2.1) * 6 - 10 * perk, 0, -8 + math.sin(t * 1.7) * 5 + 8 * perk))
		snail:set("StalkR", R(math.sin(t * 2.1 + 1) * 6 - 10 * perk, 0, 8 - math.sin(t * 1.7 + 0.6) * 5 - 8 * perk))
		local shut = (t % 2.9) < 0.24 or startle > 0.3 or t >= 9.4
		snail:show("EyeL", not shut) snail:show("EyeR", not shut) snail:show("ShutL", shut) snail:show("ShutR", shut)
		snail:show("Harness", t >= T_ROPE)
		if t >= T_LAND and t < 3.0 then -- she turns to look at what fell behind her
			snail:set("Head", R(0, 62 * smooth(T_LAND + 0.2, T_LAND + 0.55, t) * (1 - smooth(2.85, 3.0, t)), 0))
		elseif t >= 8.1 then -- NAMED: she tips the shell to let it slide off, then looks at what it has become
			snail:set("Shell", R(0, 0, -16 * math.sin(lin(8.1, 8.6, t) * math.pi)))
			snail:set("Head", R(-10 * smooth(8.5, 9.0, t), -48 * smooth(8.3, 8.8, t), 0))
		end
		if t < 8.1 then snail:set("Shell", R(math.sin(w - 0.8) * 1.5 * crawling, 0, math.sin(t * 1.3) * 1.2)) end
		local phase = t < 3.0 and 0 or (t < 7.6 and yi or 9)
		if phase ~= snail.phase then snail.phase = phase snail:snap() end
		snail:smooth(dt, startle > 0 and 30 or 12)
		snail:update()

		-- her silver trail: every stride her tail has passed
		for i, b in trail do
			local on = t >= 3.0 and i < idx - 1
			if on ~= b.on then b.on = on b.part.Transparency = on and 0.3 or 1 end
		end

		-- ===== the boulder =====
		local back = snail:joint("Shell") * ON_BACK
		for _, g in GROWTH do
			local grown = smooth(g[2], g[2] + g[3], t)
			boulder:show(g[1], t >= g[2] and t < T_SET)
			boulder:size(g[1], 0.15 + 0.85 * grown)
		end
		boulder:show("Rock", t < T_SET)
		if t < T_BREAK then
			boulder.root = W(RIM.X, RIM.Y + 0.2, RIM.Z)
		elseif t < T_LAND then -- down the benches: it follows the ground of the fall line and bounces on every bench
			local u = lin(T_BREAK, T_LAND, t) ^ 1.25
			local g = fallAt(u)
			local hop = math.abs(math.sin(u * math.pi * 7)) * 4.2 * (1 - u * 0.75)
			boulder.root = W(g.X, g.Y + 1.1 + hop, g.Z) * R(0, 0, -u * 2300) * CFrame.new(0, -1.1, 0)
			rockPart.CFrame = W(g.X, g.Y + 0.6, g.Z)
			rockDust.Rate = 26
			for k = 1, 6 do
				once("bounce" .. k, T_BREAK + (T_LAND - T_BREAK) * (k / 7) ^ 0.8, function() rockDust:Emit(10) rockChips:Emit(8) ctx.sound(SND.tap, 0.3 + k * 0.05, 0.42 + k * 0.03) ctx.shake(0.15 + k * 0.05) end)
			end
		elseif t < T_ROPE then
			boulder.root = W(LAND.X, LAND.Y, LAND.Z) * R(0, 40, 0)
			rockDust.Rate = 0
		elseif t < 2.92 then -- roped on: it hops up onto her shell
			local u = lin(T_ROPE, 2.92, t)
			local from = (O * CFrame.new(LAND)).Position
			boulder.root = CFrame.new(from:Lerp(back.Position, smooth(0, 1, u)) + V(0, math.sin(u * math.pi) * 2.6, 0)) * (back - back.Position) * R(0, 360 * u, 0)
		elseif t < 8.15 then
			boulder.root = back
		elseif t < T_SET then -- NAMED: it slides off her back and down to the moss
			local u = lin(8.15, T_SET, t)
			local to = (O * CFrame.new(SET)).Position
			boulder.root = CFrame.new(back.Position:Lerp(to, u * u) + V(0, math.sin(u * math.pi) * 0.8, 0)) * (back - back.Position) * R(0, 0, 40 * u)
		else
			boulder.root = HIDE
		end
		if t >= T_LAND then rockDust.Rate = 0 end
		once("break", T_BREAK, function() rockPart.CFrame = W(RIM.X, RIM.Y, RIM.Z) rockDust:Emit(40) rockChips:Emit(30) sfx("breakRock", 0.7) ctx.shake(0.9) ctx.hold(3 / 60) end)
		once("land", T_LAND, function() rockPart.CFrame = W(LAND.X, LAND.Y + 0.5, LAND.Z) rockDust:Emit(30) sfx("land", 0.7) ctx.sound(SND.tap, 0.6, 0.4) ctx.kick(3) ctx.shake(0.6) ctx.hold(3 / 60) end)
		once("rope", T_ROPE, function() sfx("swing", 0.9) end)
		once("roped", 2.92, function() workPart.CFrame = back sparkle:Emit(16) sfx("pop", 1.1) ctx.kick(1.5) end)
		for i, g in GROWTH do
			once("grow" .. i, g[2], function() workPart.CFrame = back * CFrame.new(0, 1.6, 0) sparkle:Emit(8) sfx("pop", 1.1 + i * 0.08) end)
		end

		-- ===== the bird: it nests on the boulder for some years, and leaves =====
		if t >= 5.8 and t < 7.5 then
			local nest = boulder:joint("Nest") * CFrame.new(0, 0.14, 0)
			local away = smooth(6.9, 7.5, t)
			local flap = away > 0 and math.sin(t * 40) * 55 or ((t % 0.9) < 0.18 and math.sin(t * 40) * 30 or 0)
			bird.root = CFrame.new(nest.Position + O:VectorToWorldSpace(V(-9 * away, 9 * away * away + math.sin(away * math.pi) * 2, 14 * away))) * (snail.root - snail.root.Position) * R(0, 150 + 60 * away, 0)
			bird:set("WingL", R(0, 0, -flap)) bird:set("WingR", R(0, 0, flap))
			once("birdOff", 6.9, function() sfx("swing", 1.5) end)
		else
			bird.root = HIDE
		end

		-- ===== weather that follows her =====
		local sp = (O * CFrame.new(pos))
		skyPart.CFrame = sp * CFrame.new(0, 30, 2)
		groundPart.CFrame = sp * CFrame.new(0, 0.25, 0)
		windPart.CFrame = sp * CFrame.new(-22, 3, 2)
		rainFx.Rate, splash.Rate = 2000 * rain, 380 * rain
		dustWind.Rate = (t >= 3.0 and 14 or 5) * dusty
		dew.Rate = 22 * morning * (t >= 5.7 and 1 or 0)

		-- ===== NAMED: set down, and it has become something else =====
		if t >= T_SET then
			local lift = smooth(T_SET, 9.3, t)
			local spin = smooth(8.5, 10.0, t) * 360
			local at_ = SET + V(0, 1.2 + 2.0 * lift + math.sin(t * 2) * 0.1 * lift, 0)
			placePick(CFrame.new(at_) * R(0, 180 + spin, -20), 2.9 + 0.7 * lift)
			heroPart.CFrame = W(at_.X, at_.Y + 0.4, at_.Z)
			raysIm.ImageTransparency = 1 - 0.7 * smooth(T_SET, 8.8, t) * (1 - smooth(10.6, 11.1, t))
			raysIm.Rotation = t * 22
			heroSpark.Rate = t >= 8.6 and 8 or 0
			ctx.name("It grew on me.")
			ctx.cardAlpha = smooth(9.0, 9.35, t) * (1 - smooth(10.7, 11.0, t))
		end
		once("reveal", T_SET, function() workPart.CFrame = W(SET.X, SET.Y + 1, SET.Z) sparkle:Emit(30) heroSpark:Emit(40) ctx.sound(SND.dawn, 0.6, 0.95) sfx("land", 0.9) sfx("sparkle", 1.3) ctx.kick(5) ctx.hold(4 / 60) end)
		ctx.flashAlpha = math.max(0.3 * (1 - lin(T_BREAK, T_BREAK + 0.2, t)) * (t >= T_BREAK and 1 or 0), 0.85 * (1 - lin(T_SET, T_SET + 0.35, t)) * (t >= T_SET and 1 or 0))

		-- ===== chapters and camera =====
		if t >= 0.35 and t < 3.0 then ctx.chapter(1, "BORN", "A boulder breaks from the canyon rim.")
		elseif t >= 3.2 and t < 7.6 then ctx.chapter(2, "MADE", "A snail carried it for forty years, until the moss took it over.")
		elseif t >= 7.8 then ctx.chapter(3, "NAMED", "She sets it down by the waterfall. It has become something else.") end
		local cam, fov, focus
		local function shot(from, aim, fv) cam, fov, focus = CFrame.lookAt(from, aim), fv, (from - aim).Magnitude end
		if t < 0.95 then -- the dry canyon from the shelf: terrace above terrace, the bridge, the rim
			local u = smooth(0, 0.95, t)
			shot(V(-6 + 2 * u, 4.6 + 1.2 * u, -13 + 3 * u), V(4 - 8 * u, 16 + 12 * u, 80), 56 - 4 * u)
		elseif t < T_LAND then -- from the terrace it will land on: long on the rim, then wider as it comes down at us
			local b = O:PointToObjectSpace(boulder.root.Position)
			local u = lin(T_BREAK, T_LAND, t)
			shot(V(LAND.X + 17, LAND.Y + 3.2, LAND.Z - 13), V(b.X, b.Y + 1, b.Z):Lerp(LAND + V(0, 2, 0), 0.25 * u), 24 + 24 * u * u)
		elseif t < 3.0 then -- she looks round at it; it is roped on
			shot(pos + V(6.5, 2.4, -7.5), pos:Lerp(LAND, 0.4) + V(0, 2.2, 0), 44)
		elseif t < 7.6 then
			local c = CAMS[math.clamp(yi - 1, 1, #CAMS)]
			local start = at(YEARS[yi][3])
			local aim = pos + V(0, 2.3, 0)
			local cf0 = clearShot(start + c + V(0, 0, 0.6 * lin(YEARS[yi][1], YEARS[yi][1] + 0.9, t)), pos + V(0, 0.9, 0), dt) -- clear down to her body, not just her head
			shot(cf0, aim, 44)
		else -- low on the shelf: her, the pickaxe, and behind them the fall and the whole canyon she came down
			local up = smooth(8.4, 9.3, t)
			shot(V(END.X + 1.0 - 0.3 * smooth(8.4, 10.8, t), 0.9, END.Z - 11.5 + 0.8 * smooth(8.4, 10.8, t)), (END + V(1.5, 2.3, -1.3)):Lerp(END + V(2.2, 3.8, -1.8), up), 56 - 2 * smooth(8.4, 10.8, t))
		end
		ctx.cam, ctx.fov = O * cam, fov
		ctx.dof.FocusDistance = focus
		ctx.dof.InFocusRadius, ctx.dof.FarIntensity, ctx.dof.NearIntensity = 400, 0, 0
	end
end

return M
