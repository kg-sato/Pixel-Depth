-- ReplicatedStorage.Shared.ForgeRuneTin (src/ForgeRuneTin.luau): the Rune-Tin Pickaxe biography, played by ForgeStory.
-- BORN: a plain grey tin blank is laid on the scribe's desk. MADE: a barn owl scribe engraves one rune a night and reads it
-- aloud; each rune lights cyan as she speaks it, seven nights in seven breaths (a candle burns down each night, the moon
-- moves on). NAMED: the last rune lights and all seven sound together; the pages blow off the desk; she holds it up.
-- "Read aloud, it answers."
-- The setting is a place of its own (references refs/forge/sheets/runetin_setting_s11.png and owl_views_s11.png): a round
-- tower room at the top of a clay spire, a domed window open on a sea of clay spires under the moon, a desk with a brass lamp.
-- Built from design3d/runetin.mjs. Light: the sun is off (Lighting.Brightness 0); the lamp, the moon through the window and
-- the runes themselves light the room.
-- Space: front of a model is -Z, the camera stands at -Z and looks at the window at z = +7.6. +X is screen left.
-- Every time in this file is a story second; the clock runs at 0.58 of real time (see ForgeWood).
local M = { length = 11.2, named = 7.6, open = true, pace = 0.58, fastPace = 0.75 }
-- an interior: the Wood scene's night pictures are the sky behind the spires
local IMG = { night = { side = "98540000433096", up = "102757336864746", dn = "100178533145001", stars = 900 } }
local SND = { tap = 90326072989009, bonk = 101020483687867, dawn = 85010698086137 }

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
	local function matte(r) r:all(function(p) if p.Material ~= Enum.Material.Neon then p.Material = Enum.Material.Rubber end end) end

	-- ===== the place =====
	matte(ctx.prop("RuneRoom"))
	local sea = ctx.prop("SpireSea", CFrame.new(0, 8, 0)) -- raised so the spire tops stand in the window, as in the setting sheet
	sea:all(function(p, b) p.CastShadow = false if b.name == "Spires" then p.Material, p.Color = Enum.Material.Neon, rgb(40, 52, 92) end end) -- unlit spires vanished into the night: flat moonlit silhouettes in the mist, as in the setting sheet
	local desk = ctx.rig("RuneDesk", CFrame.new(0, 0, 3.0))
	matte(desk)
	desk:all(function(p, b) if string.find(b.name, "Flame") then p.CastShadow = false end end)
	local stool = ctx.part(v3(0.5, 1.6, 1.6), CFrame.new(0, 0.25, 5.1) * R(0, 0, 90), hex("#5a3a26"), { Shape = Enum.PartType.Cylinder, Material = Enum.Material.Rubber, CastShadow = true })
	ctx.sky(IMG.night)
	ctx.atmo({ Density = 0.4, Haze = 2.2, Color = rgb(96, 118, 178), Decay = rgb(60, 76, 132), Glare = 0, Offset = 0 }) -- blue mist between the spires (setting sheet)
	ctx.light({ Brightness = 0, Ambient = rgb(70, 78, 116), OutdoorAmbient = rgb(96, 112, 160), ColorShift_Top = rgb(0, 0, 0), ExposureCompensation = 0.15, EnvironmentDiffuseScale = 0, EnvironmentSpecularScale = 0 })

	-- the moon: a disc beyond the window; a dark disc in front of it gives the phase, a little fuller each night
	local MOON = V(-5, 13, 62)
	local moon = ctx.part(v3(8, 8, 8), CFrame.new(MOON), hex("#e6ecff"), { Shape = Enum.PartType.Ball, Material = Enum.Material.Neon })
	local shade = ctx.part(v3(8.6, 8.6, 8.6), CFrame.new(MOON + V(0, 0, -3)), hex("#0c0f22"), { Shape = Enum.PartType.Ball, Material = Enum.Material.Neon, Transparency = 1 }) -- shortcut: the dark phase disc read as an eclipse against the stars, so it is hidden; the phases are not shown
	local moonGlow = Instance.new("BillboardGui")
	moonGlow.Size, moonGlow.LightInfluence, moonGlow.Brightness, moonGlow.Parent = UDim2.fromScale(26, 26), 0, 1, moon
	local moonIm = Instance.new("ImageLabel")
	moonIm.BackgroundTransparency, moonIm.Image, moonIm.ImageColor3, moonIm.ImageTransparency, moonIm.Size, moonIm.Parent = 1, S.GLOW, hex("#9fb4ff"), 0.55, UDim2.fromScale(1, 1), moonGlow
	-- moonlight through the window: a cool spot down across the floor and the desk
	local winPart = ctx.part(v3(0.2, 0.2, 0.2), CFrame.lookAt(V(0, 6.6, 8.4), V(0, 0.5, 0)), hex("#ffffff"), { Transparency = 1 })
	local moonLight = Instance.new("SpotLight")
	moonLight.Color, moonLight.Range, moonLight.Brightness, moonLight.Angle, moonLight.Shadows, moonLight.Face, moonLight.Parent = hex("#8fa8ff"), 26, 2.2, 70, true, Enum.NormalId.Front, winPart
	-- the lamp: the small warm circle on the desk (stage space: desk at z = 3, its lamp at x = +1.7, z = 3.5)
	local LAMP = V(1.7, 2.6, 3.5)
	local lampPart = ctx.part(v3(0.2, 0.2, 0.2), CFrame.new(LAMP), hex("#ffd166"), { Transparency = 1 })
	local lamp = Instance.new("PointLight")
	lamp.Color, lamp.Range, lamp.Brightness, lamp.Shadows, lamp.Parent = hex("#ffc27a"), 11, 0.9, true, lampPart
	local lampGlow = Instance.new("BillboardGui")
	lampGlow.Size, lampGlow.LightInfluence, lampGlow.Brightness, lampGlow.Parent = UDim2.fromScale(2.4, 2.4), 0, 1, lampPart
	local lampGlowIm = Instance.new("ImageLabel")
	lampGlowIm.BackgroundTransparency, lampGlowIm.Image, lampGlowIm.ImageColor3, lampGlowIm.ImageTransparency, lampGlowIm.Size, lampGlowIm.Parent = 1, S.GLOW, hex("#ffb45a"), 0.5, UDim2.fromScale(1, 1), lampGlow
	local moths = ctx.emitter(lampPart, { Texture = S.GLOW, Color = ColorSequence.new(hex("#5a4a3a")), Size = NumberSequence.new(0.07), Transparency = NumberSequence.new(0.1), Lifetime = NumberRange.new(2.5, 4), Speed = NumberRange.new(0.6, 1.2), SpreadAngle = Vector2.new(180, 180), RotSpeed = NumberRange.new(-300, 300), LightEmission = 0, LightInfluence = 1, Rate = 1.6 })
	moths:Emit(4)
	-- dust turning in the moonbeam
	local beamAir = ctx.part(v3(4, 4, 6), CFrame.new(0, 3.2, 5.2), hex("#ffffff"), { Transparency = 1 })
	local motes = ctx.emitter(beamAir, { Texture = S.GLOW, Color = ColorSequence.new(hex("#cfe0ff")), Size = NumberSequence.new({ K(0, 0), K(0.2, 0.05), K(0.8, 0.05), K(1, 0) }), Transparency = NumberSequence.new(0.4), Lifetime = NumberRange.new(5, 8), Speed = NumberRange.new(0.05, 0.25), SpreadAngle = Vector2.new(180, 180), LightEmission = 0.5, LightInfluence = 0.4, Rate = 10 })
	motes:Emit(40)

	-- ===== the scribe and the tin =====
	local owl = ctx.rig("OwlKit", CFrame.new(0, -60, 0))
	matte(owl)
	owl:all(function(p, b) if b.name == "Specs" then p.Material = Enum.Material.Metal end if b.name == "Eyes" then p.Material = Enum.Material.SmoothPlastic end end)
	owl:show("EyesShut", false)
	local STAND = V(0, 0.5, 5.1) -- on the stool behind the desk, facing the cameras
	local tool = ctx.rig("EngraveTool", CFrame.new(0, -60, 0))
	matte(tool)
	local plate = ctx.rig("RunePick", CFrame.new(0, -60, 0), 0.55) -- a pickaxe head, smaller than the desk
	plate:all(function(p, b) p.CastShadow = not string.find(b.name, "Rune") if b.name == "Head" then p.Material = Enum.Material.Metal end end)
	plate:show("Haft", false)
	for k = 1, 7 do plate:show("Cut" .. k, false) plate:show("Rune" .. k, false) end
	local ON_DESK = CFrame.new(0, 1.72, 2.7)
	local pages = {}
	for i = 1, 5 do
		local p = ctx.rig("Page", CFrame.new(0, -60, 0))
		matte(p)
		pages[i] = { r = p, ph = i * 1.37, x = -1.6 + (i % 3) * 0.3, z = 3.2 + (i % 2) * 0.3 }
	end
	-- the runes' light: cyan on her face and on the dome, a flash as each one answers
	local runePart = ctx.part(v3(0.2, 0.2, 0.2), CFrame.new(0, 2.2, 2.7), hex("#7fe9f5"), { Transparency = 1 })
	local runeLight = Instance.new("PointLight")
	runeLight.Color, runeLight.Range, runeLight.Brightness, runeLight.Shadows, runeLight.Parent = hex("#7fe9f5"), 14, 0, true, runePart
	local cutPart = ctx.part(v3(0.2, 0.2, 0.2), ON_DESK, hex("#ffffff"), { Transparency = 1 })
	local curls = ctx.emitter(cutPart, { Texture = S.SPARK, Color = ColorSequence.new(hex("#e6eef6"), hex("#9fb4c8")), Size = NumberSequence.new(0.12, 0), Transparency = NumberSequence.new(0, 1), Lifetime = NumberRange.new(0.25, 0.5), Speed = NumberRange.new(1.5, 4), SpreadAngle = Vector2.new(60, 60), EmissionDirection = Enum.NormalId.Top, Acceleration = v3(0, -20, 0), LightEmission = 0.3, LightInfluence = 0.8 })
	local answer = ctx.emitter(cutPart, { Texture = S.SPARK, Color = ColorSequence.new(hex("#ffffff"), hex("#7fe9f5")), Size = NumberSequence.new({ K(0, 0), K(0.3, 0.45), K(1, 0) }), Transparency = NumberSequence.new(0, 1), Lifetime = NumberRange.new(0.5, 1.0), Speed = NumberRange.new(1, 4), SpreadAngle = Vector2.new(70, 70), EmissionDirection = Enum.NormalId.Top, Rotation = NumberRange.new(0, 360), Drag = 2 })
	local heroPart = ctx.part(v3(0.3, 0.3, 0.3), CFrame.new(0, 4.6, 4.0), hex("#ffffff"), { Transparency = 1 })
	local rays = Instance.new("BillboardGui")
	rays.Size, rays.LightInfluence, rays.Brightness, rays.Parent = UDim2.fromScale(11, 11), 0, 1.1, heroPart
	local raysIm = Instance.new("ImageLabel")
	raysIm.BackgroundTransparency, raysIm.Image, raysIm.ImageColor3, raysIm.ImageTransparency, raysIm.Size, raysIm.Parent = 1, "rbxassetid://98789616938156", hex("#7fe9f5"), 1, UDim2.fromScale(1, 1), rays
	local heroSpark = ctx.emitter(heroPart, { Texture = S.SPARK, Color = ColorSequence.new(hex("#ffffff"), hex("#7fe9f5")), Size = NumberSequence.new({ K(0, 0), K(0.3, 0.55), K(1, 0) }), Transparency = NumberSequence.new(0, 1), Lifetime = NumberRange.new(0.8, 1.6), Speed = NumberRange.new(2, 6), SpreadAngle = Vector2.new(180, 180), Rotation = NumberRange.new(0, 360), Drag = 1.5 })

	-- ===== the timetable =====
	local NIGHTS = { 3.3, 3.9, 4.5, 5.1, 5.7, 6.3, 6.9 } -- each night: the cut (0 to 0.3), she reads it aloud, it answers at +0.34
	local ANSWER = 0.34
	local NOTES = { 1.0, 1.122, 1.26, 1.498, 1.682, 2.0, 2.245 } -- a pentatonic climb, one note a rune
	local function night(t) local n = 0 for i, s in NIGHTS do if t >= s then n = i end end return n end
	local function lean(p)
		for _, b in { "Head", "Body" } do
			local cf = p[b]
			if cf then local x, y, z = cf:ToEulerAnglesXYZ() p[b] = CFrame.Angles(-x, y, z) end
		end
		return p
	end
	local function once(key, at, t, fn) if t - at < 0.25 then ctx.once(key, at, t, fn) end end
	local lastPhase = -1

	return function(t, dt)
		local n = night(t)
		local named = t >= 7.6

		-- ===== the moon: a little fuller each night, full when it is named; it climbs across the window =====
		local fullness = named and 1 or (t < 3.3 and 0.05 or (n - 1) / 6 * 0.9)
		local mp = MOON + V(2.5 - 5 * lin(0, 11.2, t), 1.2 * math.sin(lin(0, 11.2, t) * math.pi), 0)
		moon.CFrame = W(mp.X, mp.Y, mp.Z)
		shade.CFrame = W(mp.X - 1.4 - 8.6 * fullness, mp.Y + 0.4, mp.Z - 3)
		moonLight.Brightness = 0.9 + 0.7 * fullness

		-- ===== the candles: one burns down each night =====
		for k = 1, 7 do
			local burnt = t >= NIGHTS[k] and math.min(1, (t - NIGHTS[k]) / 0.55) or 0
			if named then burnt = k < 7 and 1 or burnt end
			desk:size("Wax" .. k, V(1, 1 - 0.82 * burnt, 1))
			desk:show("Flame" .. k, (t >= NIGHTS[k] - 0.05 and burnt < 1) or (named and k == 7))
		end
		desk:size("LampFlame", 1 + 0.12 * math.sin(t * 19) * math.sin(t * 7.1))
		lamp.Brightness = 0.9 * (0.94 + 0.06 * math.sin(t * 23))

		-- ===== the tin and the runes =====
		local glow = 0
		for k = 1, 7 do
			local at = NIGHTS[k] + ANSWER
			plate:show("Cut" .. k, t >= NIGHTS[k] + 0.15)
			plate:show("Rune" .. k, t >= at)
			if t >= at then plate:alpha("Rune" .. k, named and 0 or 0.25 + 0.5 * smooth(at + 0.2, at + 0.5, t)) end
			if t >= at and t < at + 0.5 then glow = math.max(glow, 1 - (t - at) / 0.5) end
			once("cut" .. k, NIGHTS[k] + 0.05, t, function() ctx.sound(SND.tap, 0.22, 2.4) curls:Emit(10) end)
			once("cut" .. k .. "b", NIGHTS[k] + 0.17, t, function() ctx.sound(SND.tap, 0.18, 2.7) curls:Emit(8) end)
			once("say" .. k, NIGHTS[k] + 0.26, t, function() sfx("pop", 0.7 + k * 0.04) end)
			once("ans" .. k, at, t, function() ctx.sound(SND.bonk, 0.38, NOTES[k] * 1.5) answer:Emit(18) sfx("sparkle", 1.4 + k * 0.05) ctx.kick(1) end)
		end
		once("allSeven", 7.75, t, function()
			for k = 1, 7 do ctx.sound(SND.bonk, 0.26, NOTES[k] * 1.5) end
			ctx.sound(SND.dawn, 0.5, 1.1) answer:Emit(60) sfx("sparkle", 1.2) ctx.shake(0.4) ctx.kick(3) ctx.hold(4 / 60)
		end)
		local chord = named and smooth(7.7, 7.9, t) * (1 - 0.6 * smooth(8.4, 9.2, t)) or 0
		runeLight.Brightness = 0.2 * math.min(n, 7) / 7 + 1.4 * glow + 1.8 * chord + (named and 0.3 or 0)
		if t < 1.4 then plate.root = FAR end

		-- ===== the scribe =====
		local phase = t < 2.4 and 1 or (not named and 2 or 3)
		if phase ~= lastPhase then lastPhase = phase owl:snap() end
		local pose
		if phase == 1 then
			-- she comes to the desk with the blank in both wings and lays it down
			local down = smooth(1.5, 2.1, t)
			pose = { Body = R(8 + 14 * down, 0, 0), Head = R(14 + 10 * down, 0, 0), ArmL = R(60 + 10 * down, 0, 14), ArmR = R(60 + 10 * down, 0, -14), ForeL = R(40, 0, 0), ForeR = R(40, 0, 0) }
			if t >= 1.4 then
				local held = CFrame.new(0, 2.45, 4.2)
				plate.root = O * held:Lerp(ON_DESK, down)
			end
			tool.root = FAR
		elseif phase == 2 then
			local s = n >= 1 and t - NIGHTS[n] or 9
			local cutting = s < 0.28
			local speak = s >= 0.24 and s < 0.5
			local scratch = cutting and math.sin(t * 70) * 4 or 0
			pose = cutting and { Body = R(20, 0, 0), Head = R(28, 0, 0), ArmR = R(78, 0, -22), ForeR = R(46 + scratch, 0, 0), ArmL = R(40, 0, 18), ForeL = R(30, 0, 0) }
				or (speak and { Body = R(-4, 0, 0), Head = R(-10, 0, 0), ArmR = R(40, 0, -16), ForeR = R(30, 0, 0), ArmL = R(30, 0, 16), ForeL = R(24, 0, 0) })
				or { Body = R(10, 0, 0), Head = R(14, math.sin(t * 2) * 6, 0), ArmR = R(50, 0, -18), ForeR = R(36, 0, 0), ArmL = R(30, 0, 16), ForeL = R(26, 0, 0) }
			owl:size("Eyes", speak and 1 + 0.18 * math.sin((s - 0.24) / 0.26 * math.pi) or 1) -- her eyes widen as it answers
			plate.root = O * ON_DESK
			tool.root = owl:joint("ForeR") * CFrame.new(-0.05, -0.55, -0.25) * R(-150, 0, 0)
		else
			-- the last rune answers, she fits the haft and holds it up before the window
			local lift = smooth(8.4, 9.0, t)
			pose = { Body = R(14 - 20 * lift, 0, 0), Head = R(20 - 30 * lift, 0, 0), ArmL = R(70 + 40 * lift, 0, 14 + 6 * lift), ArmR = R(70 + 70 * lift, 0, -14 + 30 * lift), ForeL = R(36 - 16 * lift, 0, 0), ForeR = R(36 - 16 * lift, 0, 0) }
			plate:show("Haft", t >= 8.3)
			once("haft", 8.3, t, function() sfx("pop", 1.2) ctx.kick(1.5) end)
			local up = CFrame.new(-1.0, 3.05 + 0.06 * math.sin(t * 2.2), 3.75) * R(0, 0, 14) * R(-90, 0, 0) * CFrame.new(0, 0, 0.85) -- upright (local +Z is up after the turn), head on top, held at mid-haft
			local flat = ON_DESK * R(0, 0, 0)
			plate.root = O * (t < 8.3 and flat or flat:Lerp(up, lift))
			tool.root = W(-1.0, 1.75, 2.6) * R(0, 60, 90)
			heroPart.CFrame = plate.root * CFrame.new(0, 0.2, 0)
			raysIm.ImageTransparency = 1 - 0.65 * smooth(8.9, 9.3, t) * (1 - smooth(10.6, 11.1, t))
			raysIm.Rotation = t * 18
			heroSpark.Rate = t >= 9.0 and 8 or 0
			once("reveal", 9.0, t, function() heroSpark:Emit(40) ctx.sound(SND.bonk, 0.4, 1.5) ctx.sound(SND.bonk, 0.4, 2.245) sfx("sparkle", 1.3) ctx.kick(4) ctx.hold(3 / 60) end)
			ctx.name("Read aloud, it answers.")
			ctx.cardAlpha = smooth(9.2, 9.55, t) * (1 - smooth(10.7, 11.0, t))
		end
		owl:pose(lean(pose))
		owl:smooth(dt, phase == 2 and 26 or 14)
		owl.root = W(STAND.X, STAND.Y, STAND.Z) * CFrame.new(0, 0.03 * math.sin(t * 2.4), 0)

		-- ===== the pages: on the last rune they lift off the desk and blow toward the room =====
		for i, p in pages do
			if t < 7.75 then
				p.r.root = W(p.x, 1.73 + i * 0.012, p.z) * R(0, p.ph * 20, 0)
			else
				local u = math.min((t - 7.75) / 2.4, 1)
				local x = p.x + (i - 3) * 1.2 * u + math.sin(u * 6 + p.ph) * 0.4
				local y = 1.73 + 2.6 * math.sin(math.min(u, 0.6) / 0.6 * math.pi * 0.5) * (1 - 0.8 * smooth(0.6, 1, u)) - 1.6 * smooth(0.6, 1, u)
				p.r.root = W(x, math.max(0.02, y), p.z - 5.5 * u) * R(u * 300 + p.ph * 40, u * 200, u * 160)
			end
		end

		-- ===== chapters and camera =====
		if t >= 0.35 and t < 3.0 then ctx.chapter(1, "BORN", "A plain tin blank, laid on the scribe's desk.")
		elseif t >= 3.2 and t < 7.6 then ctx.chapter(2, "MADE", "One rune a night, read aloud. Each one answered.")
		elseif t >= 7.8 then ctx.chapter(3, "NAMED", "The seventh lit, and all seven sang together.") end
		local cf, fov, focus
		local function shot(from, aim, f) cf, fov, focus = CFrame.lookAt(from, aim), f, (from - aim).Magnitude end
		if t < 1.4 then -- the room from the door: the desk, the window, the spires and the moon
			local u = smooth(0, 1.4, t)
			shot(V(0.9 - 0.5 * u, 4.0 - 0.6 * u, -6.4 + 1.4 * u), V(0, 3.4, 7.6), 56 - 4 * u)
		elseif t < 2.4 then -- she lays it down
			shot(V(-2.2, 3.4, -0.4), V(0, 2.4, 3.8), 44)
		elseif t < 3.2 then -- the blank, plain and grey, under the lamp
			shot(V(0.8, 3.2, 0.4 + 0.3 * smooth(2.4, 3.2, t)), V(0, 1.75, 2.75), 40)
		elseif t < 4.5 then -- over the desk: the tool, the tin, her face
			shot(V(-1.2, 3.6, -0.4), V(0, 2.9, 4.2), 50)
		elseif t < 5.7 then -- her face, lit from below by what answers
			local u = smooth(4.5, 5.7, t)
			shot(V(-0.9 + 0.4 * u, 3.1, 1.2 + 0.3 * u), V(0, 3.3, 5.0), 44)
		elseif t < 6.9 then -- the whole room: the moon has moved on, the candles are going down
			local u = smooth(5.7, 6.9, t)
			shot(V(1.8 - 0.6 * u, 3.0, -5.6 + 0.8 * u), V(0, 3.2, 6.0), 50)
		elseif t < 7.6 then -- the tin, six runes lit, the seventh being cut
			shot(V(0.5, 3.7, -0.4), V(0, 2.3, 3.4), 50)
		elseif t < 8.4 then -- all seven: the room goes cyan
			shot(V(-1.6, 3.2, -1.2), V(0, 2.5, 4.0), 48)
		else -- low before the desk: she holds it up against the window and the full moon
			local s = smooth(8.4, 10.8, t)
			shot(V(-0.8 + 0.3 * s, 2.3, 0.2 + 0.5 * s), V(0, 3.3, 5.0):Lerp(V(0, 3.6, 5.0), smooth(8.6, 9.4, t)), 52 - 2 * s)
		end
		ctx.cam, ctx.fov = O * cf, fov
		ctx.dof.FocusDistance = focus
		ctx.dof.InFocusRadius, ctx.dof.FarIntensity, ctx.dof.NearIntensity = 400, 0, 0
		ctx.cc.TintColor = rgb(236, 240, 255)
		ctx.cc.Saturation, ctx.cc.Contrast = 0.04, 0.1
	end
end

return M
