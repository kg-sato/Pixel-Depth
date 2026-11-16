-- ReplicatedStorage.Shared.ForgeTitan (src/ForgeTitan.luau): the Titan Hammer Pickaxe biography, played by ForgeStory.
-- BORN: a stone giant sleeps as the far wall of a canyon; the tip of one finger has cracked along an old line. MADE: three
-- marmot masons tiptoe in and bow; the foreman blows his horn; the giant lifts one finger; three hammer rings put three
-- burning rune bands round the tip and it comes free; one eye opens a slit, closes, and he turns over and sleeps on.
-- NAMED: it takes all three to carry it. "On loan."
-- The setting is a place of its own (references refs/forge/sheets/titan_setting_s11.png and marmot_views_s11.png).
-- Built from design3d/titan.mjs. The sky is the Stone scene's summer picture.
-- Space: front of a model is -Z, the camera stands at -Z and looks up the valley at the giant (+Z). +X is screen left: his
-- head and shoulder are on the left, his open hand reaches toward the cameras on the right; the index fingertip is at
-- about (-5.3, 0.6, -4.3) once the model is flipped.
-- Every time in this file is a story second; the clock runs at 0.58 of real time (see ForgeWood).
local M = { length = 11.2, named = 7.6, open = true, pace = 0.58, fastPace = 0.75 }
local IMG = { morning = { side = "123739504725049", up = "81181571686796", dn = "95878689619602", sun = 7 } }
local SND = { tap = 90326072989009, bonk = 101020483687867, dawn = 85010698086137, thunder = 82890618685891 }

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
	matte(ctx.prop("GiantCanyon", CFrame.new(0, 0, 30))) -- pushed back so its walls stand behind the giant, not in front of his face
	ctx.part(v3(220, 0.4, 140), CFrame.new(0, -0.22, -30), hex("#9a8a6a"), { Material = Enum.Material.Rubber, CastShadow = false }) -- the valley floor under the cameras
	local GS = 1.7 -- the giant at 1.7 times his built size (grade round 1: "stone lumps on a flat baseplate"); the crew and cameras follow his fingertip
	local giant = ctx.rig("StoneGiant", CFrame.new(), GS)
	matte(giant)
	giant:show("Crack", true) giant:alpha("Crack", 0.85)
	for k = 1, 3 do giant:show("Band" .. k, false) end
	local scaffold = ctx.prop("Scaffold", CFrame.new(-7.8 * 1.7, 0, -1.4 * 1.7) * R(0, 20, 0), 1.3)
	matte(scaffold)
	ctx.sky(IMG.morning)
	ctx.atmo({ Density = 0.42, Haze = 2.8, Color = rgb(226, 214, 200), Decay = rgb(170, 160, 170), Glare = 0.2, Offset = 0.25 })
	ctx.light({ Brightness = 2.4, Ambient = rgb(128, 118, 112), OutdoorAmbient = rgb(150, 140, 132), ColorShift_Top = rgb(255, 214, 170), ExposureCompensation = -0.05, EnvironmentDiffuseScale = 0.3, EnvironmentSpecularScale = 0 })
	ctx.key(V(0.9, 0.55, 0.35)) -- a low morning sun raking across him from the left, so every crack throws a shadow
	ctx.cc.TintColor = rgb(255, 244, 230)
	ctx.cc.Saturation, ctx.cc.Contrast = 0.02, 0.1

	-- mist that moves when he breathes, birds on his shoulder, dust that falls like rain when he stirs
	local mistPart = ctx.part(v3(40, 2, 30), CFrame.new(0, 1.2, 8), hex("#ffffff"), { Transparency = 1 })
	local mist = ctx.emitter(mistPart, { Texture = S.SMOKE, Color = ColorSequence.new(hex("#f2ece4")), Size = NumberSequence.new({ K(0, 4), K(1, 9) }), Transparency = NumberSequence.new({ K(0, 1), K(0.4, 0.82), K(1, 1) }), Lifetime = NumberRange.new(6, 9), Speed = NumberRange.new(0.2, 0.6), SpreadAngle = Vector2.new(180, 20), LightEmission = 0.2, LightInfluence = 0.8, Rate = 5 })
	mist:Emit(30)
	local birdPart = ctx.part(v3(20, 2, 6), CFrame.new(18, 20, 36), hex("#ffffff"), { Transparency = 1 })
	local birds = ctx.emitter(birdPart, { Texture = S.GLOW, Color = ColorSequence.new(hex("#3a3030")), Size = NumberSequence.new(0.5), Transparency = NumberSequence.new(0), Lifetime = NumberRange.new(4, 6), Speed = NumberRange.new(4, 7), SpreadAngle = Vector2.new(40, 40), EmissionDirection = Enum.NormalId.Top, LightEmission = 0, LightInfluence = 1 })
	local dustPart = ctx.part(v3(30, 0.5, 14), CFrame.new(4, 16, 10), hex("#ffffff"), { Transparency = 1 })
	local dust = ctx.emitter(dustPart, { Texture = S.GLOW, Color = ColorSequence.new(hex("#c8bcae")), Size = NumberSequence.new(0.14), Transparency = NumberSequence.new(0.2), Lifetime = NumberRange.new(1.5, 2.5), Speed = NumberRange.new(6, 10), SpreadAngle = Vector2.new(8, 8), EmissionDirection = Enum.NormalId.Bottom, LightEmission = 0, LightInfluence = 1 })

	-- ===== the crew =====
	local TIP0 = V(-5.3, 0.9, -4.3)
	local TIP = V(TIP0.X * GS, TIP0.Y * GS, TIP0.Z * GS)
	local D = V(TIP.X - TIP0.X, 0, TIP.Z - TIP0.Z) -- everything built round the fingertip moves with it
	local crew = {}
	for i, at in { V(-3.5, 0, -6.8), V(-5.3, 0, -7.2), V(-7.1, 0, -6.8) } do
		local r = ctx.rig("MarmotKit", CFrame.new(0, -60, 0), i == 2 and 1.05 or 0.95)
		matte(r)
		r:all(function(p, b) if b.name == "Eyes" then p.Material = Enum.Material.SmoothPlastic end end)
		r:show("EyesShut", false)
		r:show("Horn", i == 2)
		local hammer = ctx.part(v3(0.5, 0.22, 0.22), CFrame.new(0, -60, 0), hex("#5a5660"), { Material = Enum.Material.Rubber, CastShadow = true })
		crew[i] = { r = r, at = at + D, ph = i * 0.9, hammer = hammer }
	end
	local workPart = ctx.part(v3(0.3, 0.3, 0.3), CFrame.new(TIP), hex("#ffffff"), { Transparency = 1 })
	local sparks = ctx.emitter(workPart, { Texture = S.SPARK, Color = ColorSequence.new(hex("#ffd080"), hex("#ff8030")), Size = NumberSequence.new(0.35, 0), Transparency = NumberSequence.new(0, 1), Lifetime = NumberRange.new(0.3, 0.6), Speed = NumberRange.new(6, 12), SpreadAngle = Vector2.new(70, 70), EmissionDirection = Enum.NormalId.Top, Acceleration = v3(0, -30, 0), LightEmission = 0.7 })
	local steam = ctx.emitter(workPart, { Texture = S.SMOKE, Color = ColorSequence.new(hex("#ffffff")), Size = NumberSequence.new({ K(0, 0.5), K(1, 2.4) }), Transparency = NumberSequence.new({ K(0, 0.4), K(1, 1) }), Lifetime = NumberRange.new(0.8, 1.4), Speed = NumberRange.new(1, 3), SpreadAngle = Vector2.new(30, 30), EmissionDirection = Enum.NormalId.Top, LightEmission = 0.2, LightInfluence = 0.8 })
	local runeLight = Instance.new("PointLight")
	runeLight.Color, runeLight.Range, runeLight.Brightness, runeLight.Shadows, runeLight.Parent = hex("#ffa040"), 12, 0, false, workPart
	local pick = ctx.pick() -- ForgeModels.TitanHammerPickaxe (design3d/titan.mjs): the banded fingertip on a haft
	local pickScale0, pickH = 1, 5
	if pick then pickScale0, pickH = pick:GetScale(), math.max(pick:GetExtentsSize().Y, 0.1) pick:PivotTo(FAR) end
	local heroPart = ctx.part(v3(0.3, 0.3, 0.3), CFrame.new(0, -60, 0), hex("#ffffff"), { Transparency = 1 })
	local rays = Instance.new("BillboardGui")
	rays.Size, rays.LightInfluence, rays.Brightness, rays.Parent = UDim2.fromScale(12, 12), 0, 1.1, heroPart
	local raysIm = Instance.new("ImageLabel")
	raysIm.BackgroundTransparency, raysIm.Image, raysIm.ImageColor3, raysIm.ImageTransparency, raysIm.Size, raysIm.Parent = 1, "rbxassetid://98789616938156", hex("#ffc070"), 1, UDim2.fromScale(1, 1), rays
	local heroSpark = ctx.emitter(heroPart, { Texture = S.SPARK, Color = ColorSequence.new(hex("#ffffff"), hex("#ffa040")), Size = NumberSequence.new({ K(0, 0), K(0.3, 0.5), K(1, 0) }), Transparency = NumberSequence.new(0, 1), Lifetime = NumberRange.new(0.8, 1.6), Speed = NumberRange.new(2, 6), SpreadAngle = Vector2.new(180, 180), Rotation = NumberRange.new(0, 360), Drag = 1.5 })

	-- ===== the timetable =====
	local BOW1, HORN, LIFT, FREE, EYE, TURN, BOW2 = 3.75, 4.1, 4.35, 6.35, 6.55, 6.9, 7.2
	local RINGS = { 5.0, 5.5, 6.0 }
	local function lean(p)
		for _, b in { "Head", "Body" } do
			local cf = p[b]
			if cf then local x, y, z = cf:ToEulerAnglesXYZ() p[b] = CFrame.Angles(-x, y, z) end
		end
		return p
	end
	local function once(key, at, t, fn) if t - at < 0.25 then ctx.once(key, at, t, fn) end end

	return function(t, dt)
		-- ===== the giant: breathing, the finger, the eye, the turn =====
		local breath = math.sin(t * 1.1)
		giant:size("Body", V(1, 1 + 0.004 * breath, 1))
		mist.Rate = 4 + 2 * (breath > 0 and breath or 0)
		local lift = smooth(LIFT, LIFT + 0.6, t) * (1 - smooth(TURN, TURN + 0.5, t))
		giant:set("Finger", R(26 * lift, 0, 0))
		local slit = smooth(EYE, EYE + 0.15, t) * (1 - smooth(EYE + 0.35, EYE + 0.5, t))
		giant:set("Eyelid", CFrame.new(0, 0.7 * slit, 0))
		local turn = smooth(TURN, TURN + 0.6, t)
		giant:set("Body", CFrame.new(0, 0, -0.6 * turn) * R(0, 0, 1.5 * turn))
		once("lift", LIFT, t, function() ctx.sound(SND.thunder, 0.4, 0.5) dust:Emit(60) ctx.shake(0.6) birds:Emit(8) end)
		once("eye", EYE, t, function() ctx.sound(SND.bonk, 0.3, 0.35) end)
		once("turn", TURN, t, function() ctx.sound(SND.thunder, 0.5, 0.4) dust:Emit(90) ctx.shake(1.0) end)
		dust.Rate = (t > LIFT and t < LIFT + 0.8) and 40 or ((t > TURN and t < TURN + 1) and 60 or 0)
		birds.Rate = 0

		-- the crack and the bands
		local bands = 0
		for k, rt in RINGS do
			giant:show("Band" .. k, t >= rt and t < FREE)
			if t >= rt then bands = k end
			once("ring" .. k, rt, t, function() ctx.sound(SND.bonk, 0.5, 1.0 + k * 0.25) sparks:Emit(20) steam:Emit(8) ctx.kick(1.5) ctx.hold(2 / 60) end)
		end
		giant:alpha("Crack", 0.85 - 0.75 * smooth(1.6, 2.6, t))
		giant:show("Tip", t < FREE) giant:show("Crack", t < FREE)
		runeLight.Brightness = 0.6 * bands + 1.6 * (t >= FREE and t < FREE + 0.3 and 1 or 0)
		workPart.CFrame = giant:joint("Tip") * CFrame.new(0, 0.6, -0.6)
		once("free", FREE, t, function() ctx.sound(SND.bonk, 0.6, 0.7) sfx("breakRock", 1.0) sparks:Emit(30) steam:Emit(14) ctx.shake(0.5) ctx.kick(3) end)

		-- ===== the crew =====
		for i, c in crew do
			local r = c.r
			local pose
			local walkIn = smooth(3.0, 3.7, t)
			local tip = math.sin(t * 9 + c.ph)
			if t < 3.0 then
				r.root = FAR
			elseif t < 7.6 then
				local bow = math.max(smooth(BOW1, BOW1 + 0.15, t) * (1 - smooth(BOW1 + 0.35, BOW1 + 0.5, t)), smooth(BOW2, BOW2 + 0.15, t) * (1 - smooth(BOW2 + 0.3, BOW2 + 0.4, t)))
				local horn = i == 2 and smooth(HORN, HORN + 0.1, t) * (1 - smooth(HORN + 0.5, HORN + 0.6, t)) or 0
				local since = 9
				if t >= RINGS[1] - 0.3 and t < FREE then for _, rt in RINGS do if t >= rt - 0.3 then since = t - rt end end end
				local swing = (i ~= 2 and since > -0.3 and since < 0.25) and (since < 0 and 1 or 0) or 0
				local carry = smooth(FREE, FREE + 0.4, t)
				pose = { Body = R(8 + 50 * bow, 0, 0), Head = R(10 + 20 * bow - 30 * lift, 0, 0),
					LegL = R(tip * 18 * (1 - walkIn), 0, 0), LegR = R(-tip * 18 * (1 - walkIn), 0, 0),
					ArmR = R(40 + 120 * swing + 60 * horn + 100 * carry, 0, -12), ForeR = R(40 - 30 * horn, 0, 0),
					ArmL = R(30 + 100 * carry, 0, 12), ForeL = R(40, 0, 0) }
				local from = c.at + V(0, 0, -6)
				local p = from:Lerp(c.at, walkIn)
				r.root = W(p.X, 0.03 * math.abs(tip) * (1 - walkIn), p.Z) * R(0, 180, 0)
				c.hammer.CFrame = (i ~= 2 and t < FREE) and r:joint("ForeR") * CFrame.new(0, -0.5, -0.3) * R(0, 90, 0) or FAR
				once("horn", HORN, t, function() ctx.sound(SND.dawn, 0.55, 0.55) end)
			else
				-- NAMED: all three carry it on their shoulders, toward us
				local walk = smooth(7.7, 10.4, t)
				local step = math.sin(t * 7 + c.ph)
				pose = { Body = R(-4, 0, 0), Head = R(-8 + 4 * step, 0, 0), ArmL = R(160, 0, 14), ArmR = R(160, 0, -14), ForeL = R(20, 0, 0), ForeR = R(20, 0, 0), LegL = R(step * 22, 0, 0), LegR = R(-step * 22, 0, 0) }
				r.root = W(c.at.X + 0.0, 0.04 * math.abs(step), c.at.Z - 3.2 * walk)
				c.hammer.CFrame = FAR
			end
			if pose then r:pose(lean(pose)) end
			r:smooth(dt, 16)
		end

		-- ===== the pickaxe: the freed tip, then carried by all three =====
		if pick then
			if t >= FREE and t < 7.6 then
				pick:ScaleTo(pickScale0 * 5.4 / pickH)
				pick:PivotTo(W(TIP.X, 4.1 + 0.4 * (1 - smooth(FREE, FREE + 0.4, t)), TIP0.Z - 2.3 + D.Z) * R(0, 0, 90))
			elseif t >= 7.6 then
				local walk = smooth(7.7, 10.4, t)
				pick:ScaleTo(pickScale0 * 5.4 / pickH)
				pick:PivotTo(W(TIP.X, 4.2 + 0.05 * math.sin(t * 7), -7.0 + D.Z - 3.2 * walk) * R(0, 0, 90))
				heroPart.CFrame = pick:GetPivot()
				raysIm.ImageTransparency = 1 - 0.6 * smooth(8.6, 9.1, t) * (1 - smooth(10.6, 11.1, t))
				raysIm.Rotation = t * 18
				heroSpark.Rate = t >= 9.0 and 6 or 0
				once("reveal", 9.0, t, function() heroSpark:Emit(40) ctx.sound(SND.dawn, 0.5, 1.0) sfx("sparkle", 1.3) ctx.kick(4) ctx.hold(3 / 60) end)
				ctx.name("On loan.")
				ctx.cardAlpha = smooth(9.2, 9.55, t) * (1 - smooth(10.7, 11.0, t))
			else
				pick:PivotTo(FAR)
			end
		end

		-- ===== chapters and camera =====
		if t >= 0.35 and t < 3.0 then ctx.chapter(1, "BORN", "A giant sleeps. One fingertip has cracked along an old line.")
		elseif t >= 3.2 and t < 7.6 then ctx.chapter(2, "MADE", "They asked. He lifted one finger. Three bands, three rings.")
		elseif t >= 7.8 then ctx.chapter(3, "NAMED", "It takes all three to carry it.") end
		local cf, fov, focus
		local function shot(from, aim, f) cf, fov, focus = CFrame.lookAt(from, aim), f, (from - aim).Magnitude end
		local function shotT(from, aim, f) shot(from + D, aim + D, f) end -- a shot built round the fingertip
		if t < 1.6 then -- the canyon in the morning: the sleeping giant is its far wall, his hand across the valley
			local u = smooth(0, 1.6, t)
			shot(V(-8 + 4 * u, 7 - 2 * u, -36 + 6 * u), V(14, 11, 26), 62)
		elseif t < 3.0 then -- the fingertip: a crack along an old line
			shotT(V(-1.0, 3.2, -14.5 + 0.8 * smooth(1.6, 3.0, t)), V(-5.3, 1.6, -4.3), 40)
		elseif t < 4.3 then -- the crew tiptoe in and bow; the horn
			shotT(V(-0.4, 2.6, -13.5), V(-5.3, 2.0, -5.5), 48)
		elseif t < 4.95 then -- he lifts one finger: look up at it
			shotT(V(-1.2, 1.0, -13.5), V(-5.5, 4.6, -3.5), 58)
		elseif t < FREE then -- the three rings: close on the bands
			shotT(V(-2.6, 8.4, -12.5), V(-5.3, 1.6, -4.4), 40) -- high over the crew: the bands going on
		elseif t < 6.75 then -- his eye opens a slit
			shot(V(10, 14, -14), V(30, 17, 17), 34)
		elseif t < 7.6 then -- he turns over; dust falls like rain; they bow
			shot(V(-2.0, 5.0, -24), V(8, 9, 20), 60)
		else -- low in front: the three carry it toward us
			local s = smooth(7.7, 10.8, t)
			shotT(V(-5.0 + 0.4 * s, 1.0, -15.6 + 0.6 * s), V(-5.3, 3.4, -7.0 - 3.0 * s), 52 - 2 * s)
		end
		ctx.cam, ctx.fov = O * cf, fov
		ctx.dof.FocusDistance = focus
		ctx.dof.InFocusRadius, ctx.dof.FarIntensity, ctx.dof.NearIntensity = 400, 0, 0
	end
end

return M
