-- MinecartRide (ReplicatedStorage.Shared.MinecartRide): the minecart ride from the town's mine mouth down to Camp 1.
-- Feedback batch phase 4. Storyboard: https://claude.ai/artifact/RbfNa2PVyTuRTwyVzdbWTs (vault Briefs/Minecart Ride (2026-11-08).md).
-- Client only. One clock drives the film (T = 0 to 11 s). The server owns the trip: it stands the rider in the town cart, then
-- moves the character to the Camp 1 landing at T = 2.15 (CUT1). S1-S2 play in town (third person, the cart tips over the lip),
-- S3-S6 on a far stage (rail tunnel, cavern, drop, brakes; first person), S7-S8 on the real Camp 1 rails (arrive, step out).
-- A repeat ride plays a 5.7 s cut of the same film and shows SKIP. Reduce motion: no roll, no FOV punch, no shake, no speed lines.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local C = require(script.Parent.Config)

local M = {}
local WHITE, INK, DARK = Color3.new(1, 1, 1), Color3.fromRGB(62, 42, 86), Color3.fromRGB(14, 8, 22)
local BARK, BARK_LT, RAIL = Color3.fromRGB(78, 58, 72), Color3.fromRGB(112, 84, 96), Color3.fromRGB(138, 128, 168) -- timber reads orange under the lanterns: start dusky
local WARM = Color3.fromRGB(255, 212, 160)
local ROCKC = { Color3.fromRGB(46, 32, 66), Color3.fromRGB(70, 50, 98), Color3.fromRGB(98, 72, 132) }
local CRYSTAL = { Color3.fromRGB(60, 200, 150), Color3.fromRGB(150, 100, 230), Color3.fromRGB(230, 90, 160), Color3.fromRGB(80, 150, 240) } -- deep: pastel neon blooms to white
local SPARK = "rbxasset://textures/particles/sparkles_main.dds"
-- the far stage sits just south of the caves (they span z -56 to 252 round C.CAVE_ORIGIN), so the camera's jump to Camp 1 at
-- CUT2 is short: after a long camera jump Studio's lights stay dark for a few seconds
local STAGE = C.CAVE_ORIGIN + Vector3.new(0, 20, -200)
-- ProSoundEffects (Creator Store, free): { id, volume, looped }
local SND = {
	clack = { 9113120822, 0, true }, wind = { 9125742262, 0, true },
	creak = { 9120839010, 0.6 }, whoosh = { 9126229255, 0.7 }, brake = { 9116893799, 0.5 }, thud = { 9120798134, 0.8 }, rumble = { 9125875511, 0.45 },
}

-- speed keys (film time s, studs/s), smoothstep between; DIST[k] = studs travelled at T = k * DT
local SPEED = { { 0, 0 }, { 1.4, 0 }, { 2.0, 6 }, { 2.4, 28 }, { 3.5, 34 }, { 4.5, 36 }, { 5.3, 20 }, { 6.2, 22 }, { 6.9, 60 }, { 7.6, 56 }, { 8.7, 8 }, { 9.3, 0 } }
local function speedAt(t)
	for i = 2, #SPEED do
		local a, b = SPEED[i - 1], SPEED[i]
		if t <= b[1] then
			local u = math.clamp((t - a[1]) / (b[1] - a[1]), 0, 1)
			return a[2] + (b[2] - a[2]) * u * u * (3 - 2 * u)
		end
	end
	return 0
end
local DT, T_END = 1 / 240, 11
local DIST, NDIST = { [0] = 0 }, math.ceil(T_END / DT)
for k = 1, NDIST do DIST[k] = DIST[k - 1] + speedAt((k - 0.5) * DT) * DT end
local function distAt(t)
	local f = math.clamp(t, 0, T_END) / DT
	local k = math.min(math.floor(f), NDIST - 1)
	return DIST[k] + (DIST[k + 1] - DIST[k]) * (f - k)
end
local function smooth(a, b, t)
	local x = math.clamp((t - a) / (b - a), 0, 1)
	return x * x * (3 - 2 * x)
end

-- the cuts: CUT1 town -> far stage (the server moves the character then), CUT2 far stage -> the real Camp 1 rails
local CUT1, ST_LEN = 2.15, 18 -- the last 18 studs run out of the Camp 1 tunnel mouth (station z -15) to the buffers (z +3)
local S0, SEND = distAt(CUT1), distAt(9.3)
local SCUT = SEND - ST_LEN
local CUT2 = 9.3
for k = 0, NDIST do
	if DIST[k] >= SCUT then
		CUT2 = k * DT
		break
	end
end
-- the far stage path, by studs d from its start: rail tunnel (S-curve, gentle fall), cavern (trestle), drop, brake straight
local D1, D2, D3 = distAt(4.6) - S0, distAt(6.2) - S0, distAt(7.6) - S0
local DN = math.ceil(SCUT - S0) + 12
local function section(d) return d < D1 and "tunnel" or (d < D2 and "cavern" or (d < D3 and "drop" or "brake")) end
local function yawAt(d)
	if d < D1 then return 0.45 * math.sin(2 * math.pi * d / D1) end
	if d < D2 then return 0.35 * math.sin(math.pi * (d - D1) / (D2 - D1)) end
	return 0
end
local function pitchAt(d)
	if d < D1 then return -0.06 * math.min(1, d / 6, (D1 - d) / 6) end
	if d < D2 then return 0 end
	if d < D3 then return -0.9 * math.sin(math.pi * (d - D2) / (D3 - D2)) ^ 1.3 end
	return 0
end
local function rotAt(d) return CFrame.Angles(0, yawAt(d), 0) * CFrame.Angles(pitchAt(d), 0, 0) end
local PATH = { [0] = CFrame.new(STAGE) * rotAt(0) }
do
	local pos = STAGE
	for i = 1, DN do
		pos += rotAt(i - 0.5).LookVector
		PATH[i] = CFrame.new(pos) * rotAt(i)
	end
end
local function pathAt(d)
	d = math.clamp(d, 0, DN)
	local i = math.min(math.floor(d), DN - 1)
	return PATH[i]:Lerp(PATH[i + 1], d - i)
end

local function part(parent, size, cf, color, props)
	local p = Instance.new("Part")
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
	p.Material, p.TopSurface, p.BottomSurface = Enum.Material.SmoothPlastic, Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.Size, p.CFrame, p.Color = size, cf, color
	for k, v in props or {} do p[k] = v end
	p.Parent = parent
	return p
end
local function light(p, color, range, brightness)
	local l = Instance.new("PointLight")
	l.Color, l.Range, l.Brightness = color, range, brightness
	l.Parent = p
	return l
end

-- the far stage, built on the first ride and kept (unparented) between rides
local stage, lamps
local function buildStage()
	local f = Instance.new("Folder")
	f.Name = "MinecartStage"
	lamps = {}
	local rng = Random.new(7)
	local ROCK = { Material = Enum.Material.Slate, MaterialVariant = "PixelCaveRock" }
	local cavFrom, cavTo
	for d = 0, DN - 4, 4 do
		local mid, sec = pathAt(d + 2), section(d + 2)
		local ang = math.acos(math.clamp(pathAt(d).LookVector:Dot(pathAt(d + 4).LookVector), -1, 1))
		local len = ang < 0.01 and 4 or 4 + ang * 12 -- curves: the pieces overlap so the outer side shows no gap
		for _, x in { -1.25, 1.25 } do part(f, Vector3.new(0.3, 0.3, len), mid * CFrame.new(x, 0.45, 0), RAIL, { Material = Enum.Material.Metal }) end
		for _, o in { 1, 3 } do part(f, Vector3.new(3.4, 0.25, 0.7), pathAt(d + o) * CFrame.new(0, 0.15, 0), BARK) end
		if sec == "cavern" then
			cavFrom = cavFrom or d
			cavTo = d + 4
			for _, s in { -1, 1 } do -- the trestle: tall posts down into the lake, a cap beam, a cross brace
				part(f, Vector3.new(0.7, 26, 0.7), mid * CFrame.new(s * 1.9, -13.3, 0), BARK)
			end
			part(f, Vector3.new(4.6, 0.6, 0.8), mid * CFrame.new(0, -0.3, 0), BARK_LT)
			part(f, Vector3.new(0.4, 8, 0.4), mid * CFrame.new(0, -5, 0) * CFrame.Angles(0, 0, d % 8 == 0 and 0.42 or -0.42), BARK_LT)
		else
			local wallC = ROCKC[rng:NextInteger(2, 3)]
			part(f, Vector3.new(9, 1, len), mid * CFrame.new(0, -0.5, 0), ROCKC[1], ROCK)
			for _, s in { -1, 1 } do part(f, Vector3.new(1.6, 10, len), mid * CFrame.new(s * 5.3, 4.5, 0), wallC, ROCK) end
			part(f, Vector3.new(12.2, 1.6, len), mid * CFrame.new(0, 10.2, 0), ROCKC[1], ROCK)
			if d % 8 == 0 then -- a support frame: two posts, a beam, knee braces; a lantern on every second frame
				local cf = pathAt(d)
				for _, s in { -1, 1 } do
					part(f, Vector3.new(0.8, 8.6, 0.8), cf * CFrame.new(s * 4, 4.3, 0), BARK)
					part(f, Vector3.new(0.5, 2.6, 0.5), cf * CFrame.new(s * 3.1, 7.6, 0) * CFrame.Angles(0, 0, s * 0.8), BARK_LT)
				end
				part(f, Vector3.new(9, 0.9, 0.9), cf * CFrame.new(0, 8.9, 0), BARK_LT)
				if d % 16 == 0 then
					local pivot = cf * CFrame.new(0, 8.45, 0)
					local chain = part(f, Vector3.new(0.15, 0.8, 0.15), pivot * CFrame.new(0, -0.4, 0), INK)
					local lamp = part(f, Vector3.new(0.7, 0.9, 0.7), pivot * CFrame.new(0, -1.25, 0), WARM, { Material = Enum.Material.Neon })
					light(lamp, WARM, 20, d % 32 == 0 and 1.3 or 0.9)
					table.insert(lamps, { chain = chain, lamp = lamp, pivot = pivot, seed = rng:NextNumber() * 6 })
				end
			end
			if rng:NextNumber() < 0.5 then -- a crystal vein: 3 or 4 glowing shards out of one wall, leaning over the rails
				local s = rng:NextNumber() < 0.5 and -1 or 1
				local base = pathAt(d + rng:NextNumber() * 4) * CFrame.new(s * 4.4, rng:NextNumber(0.6, 5.5), 0)
				local col = CRYSTAL[rng:NextInteger(1, #CRYSTAL)]
				for k = 1, rng:NextInteger(3, 4) do
					local w = rng:NextNumber(0.5, 1.1)
					part(f, Vector3.new(w, rng:NextNumber(1.4, 3), w), base * CFrame.new(0, k * 0.3, rng:NextNumber(-0.8, 0.8)) * CFrame.Angles(rng:NextNumber(-0.4, 0.4), 0, s * rng:NextNumber(0.5, 1.1)), col, { Material = Enum.Material.Neon })
				end
				if rng:NextNumber() < 0.35 then light(f:GetChildren()[#f:GetChildren()], col, 10, 0.8) end
			end
		end
	end
	-- the cavern: a huge room round the trestle with a glowing lake, crystal spires and World Tree roots; holes in its end
	-- walls where the tunnel comes in and goes out
	if cavFrom then
		local R = CFrame.new(pathAt(cavFrom).Position) * CFrame.Angles(0, yawAt(cavFrom), 0)
		local ex = R:PointToObjectSpace(pathAt(cavTo).Position)
		local halfW, yB, yT = 80, -32, 60
		local function slab(x0, x1, y0, y1, zc)
			if x1 - x0 > 0.05 and y1 - y0 > 0.05 then part(f, Vector3.new(x1 - x0, y1 - y0, 4), R * CFrame.new((x0 + x1) / 2, (y0 + y1) / 2, zc), ROCKC[2], ROCK) end
		end
		local function holeWall(zc, hx, hy)
			slab(-halfW, hx - 5, yB, yT, zc)
			slab(hx + 5, halfW, yB, yT, zc)
			slab(hx - 5, hx + 5, hy + 10.6, yT, zc)
			slab(hx - 5, hx + 5, yB, hy - 1, zc)
		end
		holeWall(2, 0, 0)
		holeWall(ex.Z - 2, ex.X, ex.Y)
		local L = -ex.Z + 8
		for _, s in { -1, 1 } do part(f, Vector3.new(4, yT - yB, L), R * CFrame.new(s * (halfW + 2), (yB + yT) / 2, ex.Z / 2), ROCKC[2], ROCK) end
		part(f, Vector3.new(halfW * 2 + 8, 4, L), R * CFrame.new(0, yT + 2, ex.Z / 2), ROCKC[1], ROCK)
		local lake = part(f, Vector3.new(halfW * 2, 1, -ex.Z), R * CFrame.new(0, -24, ex.Z / 2), Color3.fromRGB(30, 112, 132), { Material = Enum.Material.Neon, Transparency = 0.1 })
		for _, spec in { { Color3.fromRGB(120, 230, 230), 26, 0.9 }, { Color3.fromRGB(200, 170, 255), 6, 0.94 } } do -- mist over the lake, motes in the air
			local e = Instance.new("ParticleEmitter")
			e.Color, e.LightEmission, e.LightInfluence = ColorSequence.new(spec[1]), 0.6, 0
			e.Size = NumberSequence.new(spec[2], spec[2] * 1.3)
			e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.4, spec[3]), NumberSequenceKeypoint.new(1, 1) })
			e.Lifetime, e.Speed, e.Rate = NumberRange.new(6, 9), NumberRange.new(1, 3), spec[2] > 10 and 5 or 14
			e.Shape, e.ShapeInOut, e.EmissionDirection = Enum.ParticleEmitterShape.Box, Enum.ParticleEmitterShapeInOut.Outward, Enum.NormalId.Top
			if spec[2] < 10 then e.Texture = SPARK e.Size = NumberSequence.new(0.5, 0) e.LightEmission = 1 end
			e.Parent = lake
		end
		for _, sx in { -1, 1 } do -- light on the far walls so the room reads as huge
			for _, k in { 0.3, 0.7 } do light(part(f, Vector3.one, R * CFrame.new(sx * 66, 4, ex.Z * k), WHITE, { Transparency = 1 }), sx < 0 and Color3.fromRGB(150, 220, 230) or Color3.fromRGB(200, 170, 255), 60, 0.9) end
		end
		part(f, Vector3.new(halfW * 2, 4, -ex.Z), R * CFrame.new(0, yB, ex.Z / 2), ROCKC[1], ROCK)
		for k = 1, 3 do light(part(f, Vector3.one, R * CFrame.new((k - 2) * 50, -14, ex.Z / 2), WHITE, { Transparency = 1 }), Color3.fromRGB(120, 230, 230), 60, 1.1) end
		local placed = 0
		for _ = 1, 60 do -- spires rising out of the lake, away from the track
			if placed >= 12 then break end
			local x, z = rng:NextNumber(-halfW + 8, halfW - 8), rng:NextNumber(ex.Z + 6, -6)
			local trackX = ex.X * (z / ex.Z)
			if math.abs(x - trackX) > 10 and (placed < 5 and math.abs(x - trackX) < 36 or placed >= 5) then -- the first few close by
				placed += 1
				local h, w = rng:NextNumber(18, 50), rng:NextNumber(3, 6)
				local col = CRYSTAL[rng:NextInteger(1, #CRYSTAL)]
				local sp = part(f, Vector3.new(w, h, w), R * CFrame.new(x, -24 + h / 2, z) * CFrame.Angles(rng:NextNumber(-0.15, 0.15), rng:NextNumber(0, 1.5), rng:NextNumber(-0.15, 0.15)), col, { Material = Enum.Material.Neon, Transparency = 0.15 })
				part(f, Vector3.new(w * 0.6, h * 0.3, w * 0.6), sp.CFrame * CFrame.new(0, h * 0.62, 0) * CFrame.Angles(0, 0.7, 0), col:Lerp(WHITE, 0.3), { Material = Enum.Material.Neon })
				if placed % 3 == 0 then light(sp, col, 30, 1) end
			end
		end
		for k = 1, 5 do -- World Tree roots arching from the ceiling down into the lake
			local x = (k - 3) * 30 + rng:NextNumber(-6, 6)
			local top = R * Vector3.new(x, yT, ex.Z * rng:NextNumber(0.1, 0.9))
			local bot = R * Vector3.new(x + rng:NextNumber(-20, 20), -26, ex.Z * rng:NextNumber(0.1, 0.9))
			if math.abs(x) > 14 then
				part(f, Vector3.new(5, 5, (top - bot).Magnitude), CFrame.lookAt((top + bot) / 2, bot), BARK, { Material = Enum.Material.Wood })
			end
		end
	end
	part(f, Vector3.new(12, 12, 1), pathAt(DN) * CFrame.new(0, 5, -1), DARK) -- the end of the far track, never seen (CUT2 dips)
	return f
end

-- a client copy of a model with no prompts or scripts, every part anchored and out of the physics
local SIT_ANIM = { [Enum.HumanoidRigType.R15] = "rbxassetid://2506281703", [Enum.HumanoidRigType.R6] = "rbxassetid://178130996" } -- Roblox's own sit poses
local function sitDown(rider) -- the rider's copy plays the sit pose: its root stays anchored, the limbs follow their joints (playtest 2)
	local hum = rider:FindFirstChildOfClass("Humanoid")
	local root = rider:FindFirstChild("HumanoidRootPart")
	if not hum or not root then return false end
	for _, p in rider:GetDescendants() do
		if p:IsA("BasePart") and p ~= root then p.Anchored = false end
	end
	local function play() -- an Animator only loads once the copy is in the world
		local an = hum:FindFirstChildOfClass("Animator") or Instance.new("Animator")
		an.Parent = hum
		local a = Instance.new("Animation")
		a.AnimationId = SIT_ANIM[hum.RigType] or SIT_ANIM[Enum.HumanoidRigType.R15]
		local ok, tr = pcall(function() return an:LoadAnimation(a) end)
		if ok and tr then
			tr.Priority, tr.Looped = Enum.AnimationPriority.Action4, true
			tr:Play(0)
		end
	end
	if rider:IsDescendantOf(game) then
		play()
	else
		local c
		c = rider.AncestryChanged:Connect(function()
			if rider:IsDescendantOf(game) then
				c:Disconnect()
				play()
			end
		end)
	end
	return true
end
local function ghost(model)
	local was = model.Archivable
	model.Archivable = true
	local ok, c = pcall(function() return model:Clone() end)
	model.Archivable = was
	if not ok or not c then return nil end
	for _, d in c:GetDescendants() do
		if d:IsA("ProximityPrompt") or d:IsA("BaseScript") or d:IsA("Sound") then
			d:Destroy()
		elseif d:IsA("BasePart") then
			d.Anchored, d.CanCollide, d.CanQuery, d.CanTouch = true, false, false, false
		end
	end
	local hum = c:FindFirstChildOfClass("Humanoid")
	if hum then hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None end
	return c
end
local function hideModel(model, list)
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") or d:IsA("Decal") then
			table.insert(list, { d, d.LocalTransparencyModifier })
			d.LocalTransparencyModifier = 1
		end
	end
end

-- opt: { cart = the town cart Model (PrimaryPart at the rail base, facing the shaft), camp = workspace Caves Camp folder,
--        full = the first ride (no SKIP), reduceMotion = bool, sfx = fn(name, pitch), inCave = fn() -> bool, arrived = fn(),
--        restore = fn() puts the game's camera back }
-- yields until the ride has ended (11 s, 5.7 s for a repeat ride, less when skipped)
function M.play(opt)
	local plr = Players.LocalPlayer
	local cam = workspace.CurrentCamera
	local sfx = opt.sfx or function() end
	local calm = opt.reduceMotion == true
	if not opt.cart or not opt.cart.PrimaryPart then return end
	M.prepare()
	local world = Instance.new("Folder")
	world.Name = "MinecartRide"
	world.Parent = workspace

	-- the riding cart and a copy of the rider (the real ones are hidden here and stay put for everyone else)
	local hidden = {}
	local cart0 = opt.cart:GetPivot()
	local cart = ghost(opt.cart)
	cart.Parent = world
	hideModel(opt.cart, hidden)
	local char = plr.Character
	local rider = char and ghost(char)
	local riderOff = CFrame.new(0, 3.3, 0.3)
	if rider and char then
		local hrp, hum = char:FindFirstChild("HumanoidRootPart"), char:FindFirstChildOfClass("Humanoid")
		local sat = rider and sitDown(rider)
		if hrp and hum then riderOff = CFrame.new(0, 1.05 + hrp.Size.Y / 2 + (sat and 0.7 or hum.HipHeight), 0.3) end -- seated: hips just above the cart floor
		rider.Parent = world
		hideModel(char, hidden)
	end
	local stationCF -- the Camp 1 rail station frame (from the parked cart: station z +3)
	local campCart = {}
	if opt.camp then
		local body = opt.camp:FindFirstChild("CartBody")
		if body then stationCF = body.CFrame * CFrame.new(0, -1.65, -3) end
		for _, d in opt.camp:GetChildren() do
			if d.Name:sub(1, 4) == "Cart" then table.insert(campCart, d) end
		end
	end
	for _, p in cart:GetDescendants() do -- the pastel tub blows out under the lanterns; a shade darker for the ride
		if p:IsA("BasePart") and p.Transparency < 1 then p.Color = p.Color:Lerp(INK, 0.42) end
	end
	local lampA = Instance.new("Attachment")
	lampA.Position = Vector3.new(0, 2.7, -1.9)
	lampA.Parent = cart.PrimaryPart
	local headLamp = Instance.new("SpotLight")
	headLamp.Face, headLamp.Angle, headLamp.Range, headLamp.Brightness, headLamp.Color, headLamp.Shadows = Enum.NormalId.Front, 75, 44, 2.2, Color3.fromRGB(255, 226, 180), false
	headLamp.Parent = lampA
	-- wheel sparks: two emitters at the front wheels, pointing back along the rails
	local sparks = {}
	for _, x in { -1.5, 1.5 } do
		local a = Instance.new("Attachment")
		a.Position = Vector3.new(x, 0.4, -1.4)
		a.Orientation = Vector3.new(0, 180, 0)
		a.Parent = cart.PrimaryPart
		local e = Instance.new("ParticleEmitter")
		e.Texture, e.Rate, e.LightEmission, e.LightInfluence = SPARK, 0, 1, 0
		e.Color = ColorSequence.new(Color3.fromRGB(255, 224, 140), Color3.fromRGB(255, 157, 176))
		e.Size = NumberSequence.new(0.35, 0)
		e.Lifetime, e.Speed, e.SpreadAngle = NumberRange.new(0.2, 0.35), NumberRange.new(8, 16), Vector2.new(25, 25)
		e.Acceleration, e.Drag, e.Squash = Vector3.new(0, -30, 0), 2, NumberSequence.new(-1)
		e.EmissionDirection = Enum.NormalId.Front
		e.Parent = a
		table.insert(sparks, e)
	end
	-- sounds: loops follow the speed
	local snd = {}
	for name, s in SND do
		local o = Instance.new("Sound")
		o.SoundId, o.Volume, o.Looped = "rbxassetid://" .. s[1], s[2], s[3] == true
		o.Parent = SoundService
		snd[name] = o
	end
	local function play(name, pitch)
		local o = snd[name]
		if o then
			o.PlaybackSpeed = (pitch or 1) * (0.95 + math.random() * 0.1)
			o.TimePosition = 0
			o:Play()
			task.delay(1.6, function() if o.Parent and not o.Looped then o:Stop() end end)
		end
	end
	snd.clack:Play()
	snd.wind:Play()

	-- the screen: letterbox, dips to dark at the cuts, speed lines, the cavern card, SKIP
	local pg = plr:WaitForChild("PlayerGui")
	local guiHidden = {}
	for _, g in pg:GetChildren() do
		if g:IsA("ScreenGui") and g.Enabled then g.Enabled = false table.insert(guiHidden, g) end
	end
	local gui = Instance.new("ScreenGui")
	gui.Name, gui.IgnoreGuiInset, gui.ResetOnSpawn, gui.DisplayOrder, gui.ZIndexBehavior = "MinecartRideGui", true, false, 30, Enum.ZIndexBehavior.Sibling
	gui.Parent = pg
	local function frame(props)
		local f = Instance.new("Frame")
		f.BorderSizePixel = 0
		for k, v in props do f[k] = v end
		f.Parent = props.Parent or gui
		return f
	end
	local barT = frame({ Size = UDim2.fromScale(1, 0.1), Position = UDim2.fromScale(0, -0.1), BackgroundColor3 = DARK, ZIndex = 5 })
	local barB = frame({ Size = UDim2.fromScale(1, 0.1), Position = UDim2.fromScale(0, 1), BackgroundColor3 = DARK, ZIndex = 5 })
	local dip = frame({ Size = UDim2.fromScale(1, 1), BackgroundColor3 = DARK, BackgroundTransparency = 1, ZIndex = 8 })
	local lines = {}
	for k = 1, 18 do
		local a = (k / 18) * math.pi * 2 + (k % 3) * 0.13
		local l = frame({ Size = UDim2.fromScale(0.004, 0.13), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = WHITE, BackgroundTransparency = 1, Rotation = math.deg(a) + 90, ZIndex = 3 })
		table.insert(lines, { f = l, a = a, phase = (k * 0.37) % 1 })
	end
	local cardText = Instance.new("TextLabel")
	cardText.BackgroundTransparency, cardText.Font, cardText.TextScaled, cardText.Text = 1, Enum.Font.FredokaOne, true, "ROOT CAVERN"
	cardText.TextColor3, cardText.TextTransparency, cardText.ZIndex = WHITE, 1, 6
	cardText.Size, cardText.Position, cardText.AnchorPoint = UDim2.fromScale(0.42, 0.07), UDim2.fromScale(0.5, 0.2), Vector2.new(0.5, 0.5)
	local cardStroke = Instance.new("UIStroke")
	cardStroke.Color, cardStroke.Thickness, cardStroke.Transparency = INK, 3, 1
	cardStroke.Parent = cardText
	cardText.Parent = gui
	local skip = Instance.new("TextButton")
	skip.Size, skip.Position, skip.AnchorPoint = UDim2.fromScale(0.09, 0.055), UDim2.fromScale(0.95, 0.06), Vector2.new(1, 0)
	skip.BackgroundColor3, skip.BackgroundTransparency, skip.Font, skip.TextScaled, skip.Text = Color3.fromRGB(255, 250, 243), 0.1, Enum.Font.FredokaOne, true, "SKIP"
	skip.TextColor3, skip.ZIndex, skip.Visible = INK, 9, false
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = skip
	skip.Parent = gui

	-- camera, viewmodel and blur: saved here, put back at the end
	local camSaved = { CameraType = cam.CameraType, CameraSubject = cam.CameraSubject, FieldOfView = cam.FieldOfView }
	for _, m in cam:GetChildren() do -- the first-person pickaxe would float in front of the ride
		hideModel(m, hidden)
	end
	local vmSeen = {}
	local Lighting = game:GetService("Lighting")
	local amb -- the ambient lift: once the cave look is on, lift Ambient so the tunnel reads while its lanterns warm up, then ease back
	local AMB_UP, OAMB_UP = Color3.fromRGB(96, 80, 132), Color3.fromRGB(86, 72, 120)
	local atmo = Lighting:FindFirstChildOfClass("Atmosphere") -- the cave fog hides the cavern's far walls: thinner for the ride
	local blurOff = {}
	for _, root in { game:GetService("Lighting"), cam } do
		for _, e in root:GetChildren() do
			if (e:IsA("BlurEffect") or e:IsA("DepthOfFieldEffect")) and e.Enabled then e.Enabled = false table.insert(blurOff, e) end
		end
	end

	-- the film: segments of film time to play; a repeat ride plays a cut (tip, cavern, the top of the drop, arrival)
	local segs = opt.full and { { 0, T_END } } or { { 0.9, 2.3 }, { 4.8, 5.8 }, { 6.7, 7.3 }, { 8.3, T_END } }
	local seg, segT, T = 1, 0, segs[1][1]
	local dipUntil, skipWanted, done, fired = 0, false, false, {}
	local fov, shakeAmp, lastD, campHidden = C.FP_FOV, 0, 0, false
	local function once(key, at, fn)
		if T >= at and not fired[key] then
			fired[key] = true
			fn()
		end
	end
	skip.Activated:Connect(function() skipWanted = true end)
	local last = os.clock()
	local playStart = last
	RunService:BindToRenderStep("MinecartRide", Enum.RenderPriority.Camera.Value + 20, function()
		local now = os.clock()
		local dt = math.min(now - last, 0.1)
		last = now
		segT += dt
		T = segs[seg][1] + segT
		if T >= segs[seg][2] and seg < #segs then -- the next segment of the cut, through a dip to dark
			seg, segT = seg + 1, 0
			T = segs[seg][1]
			dipUntil = now + 0.22
		end
		if skipWanted and (opt.inCave == nil or opt.inCave()) and T < 10 then -- SKIP: straight to stepping out (once the server has moved us)
			skipWanted = false
			segs, seg, segT, T = { { 10, T_END } }, 1, 0, 10
			for _, k in { "tip", "drop", "brake", "bump", "cave" } do fired[k] = true end
			dipUntil = now + 0.3
		end
		skip.Visible = not opt.full and now - playStart > 0.5 and T < 9.5
		for _, g in pg:GetChildren() do -- the game turns its cave HUD on when the server moves us; keep every other layer off
			if g ~= gui and g:IsA("ScreenGui") and g.Enabled then g.Enabled = false table.insert(guiHidden, g) end
		end
		for _, m in cam:GetChildren() do -- the cave viewmodel (pickaxe, torch) is built mid-ride; keep it out of the shot
			for _, p in m:GetDescendants() do
				if p:IsA("BasePart") and p.LocalTransparencyModifier < 1 then
					vmSeen[p] = true
					p.LocalTransparencyModifier = 1
				end
			end
		end

		-- where the cart is: town (T < CUT1), far stage (CUT1 to CUT2), the real Camp 1 rails (after CUT2)
		local d = distAt(T)
		local speed = speedAt(T)
		local cartCF, firstPerson
		if T < CUT1 then
			local tip = math.max(0, d - 2.2)
			cartCF = cart0 * CFrame.new(0, -tip * tip * 0.8, -math.min(d, 2.2) - tip * 0.8) * CFrame.Angles(-math.min(tip * 0.6, 0.9), 0, 0)
		elseif T < CUT2 or not stationCF then
			cartCF = pathAt(d - S0)
			firstPerson = true
		else
			cartCF = stationCF * CFrame.new(0, 0, -15 + math.min(d - SCUT, ST_LEN)) * CFrame.Angles(0, math.pi, 0)
			firstPerson = true
			if not campHidden then
				campHidden = true
				for _, p in campCart do
					table.insert(hidden, { p, p.LocalTransparencyModifier })
					p.LocalTransparencyModifier = 1
				end
			end
		end
		cart:PivotTo(cartCF)
		if rider then
			rider:PivotTo(cartCF * riderOff)
			for _, p in rider:GetDescendants() do
				if p:IsA("BasePart") then p.LocalTransparencyModifier = firstPerson and 1 or 0 end
			end
		end
		for _, L in lamps do -- lanterns swing more the faster we pass
			local a = math.sin(now * 3 + L.seed) * (calm and 0.05 or 0.08 + speed * 0.004)
			local pv = L.pivot * CFrame.Angles(a, 0, a * 0.5)
			L.chain.CFrame = pv * CFrame.new(0, -0.4, 0)
			L.lamp.CFrame = pv * CFrame.new(0, -1.25, 0)
		end

		-- beats
		once("letterbox", 0, function()
			barT:TweenPosition(UDim2.fromScale(0, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.3, true)
			barB:TweenPosition(UDim2.fromScale(0, 0.9), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.3, true)
		end)
		once("creak", 1.3, function() play("creak", 0.9) end)
		once("tip", 1.9, function() shakeAmp = math.max(shakeAmp, 0.3) play("rumble", 1.2) sfx("swing", 0.6) end)
		once("chime", 4.7, function() sfx("sparkle", 0.9) end)
		once("drop", 6.3, function() shakeAmp = math.max(shakeAmp, 0.15) play("whoosh", 0.9) end)
		once("brake", 7.7, function() play("brake", 1.1) end)
		once("bump", 9.3, function() shakeAmp = math.max(shakeAmp, 0.35) play("thud", 1) sfx("clink", 0.7) end)
		once("out", 10, function()
			barT:TweenPosition(UDim2.fromScale(0, -0.1), Enum.EasingDirection.In, Enum.EasingStyle.Quad, 0.35, true)
			barB:TweenPosition(UDim2.fromScale(0, 1), Enum.EasingDirection.In, Enum.EasingStyle.Quad, 0.35, true)
		end)
		-- dips to dark: at the town cut, the station cut and between the segments of a repeat ride
		local dk = 0
		if T > 1.95 and T < 2.4 then dk = math.max(dk, smooth(1.95, 2.12, T) * (1 - smooth(2.18, 2.4, T))) end
		if T > CUT2 - 0.14 and T < CUT2 + 0.2 then dk = math.max(dk, smooth(CUT2 - 0.14, CUT2 - 0.02, T) * (1 - smooth(CUT2 + 0.02, CUT2 + 0.2, T))) end
		if seg < #segs and segs[seg][2] - T < 0.1 then dk = math.max(dk, 1 - (segs[seg][2] - T) / 0.1) end
		if now < dipUntil then dk = math.max(dk, (dipUntil - now) / 0.22) end
		dip.BackgroundTransparency = 1 - math.clamp(dk, 0, 1)
		-- the cavern card, sparks, speed lines, sound
		cardText.TextTransparency = 1 - smooth(4.75, 5.05, T) * (1 - smooth(5.8, 6.1, T))
		cardStroke.Transparency = cardText.TextTransparency
		local braking = T > 7.6 and T < 9.25 and speed > 3
		for _, e in sparks do e.Rate = (braking and 60) or (speed > 42 and 25) or 0 end
		local lineA = calm and 0 or math.clamp((speed - 42) / 14, 0, 1)
		for _, L in lines do
			local r = 0.28 + ((now * 1.6 + L.phase) % 1) * 0.45
			L.f.Position = UDim2.fromScale(0.5 + math.cos(L.a) * r * 0.62, 0.5 + math.sin(L.a) * r)
			L.f.BackgroundTransparency = 1 - lineA * 0.55 * (1 - (r - 0.28) / 0.45)
		end
		snd.clack.Volume = (T > 1.4 and T < 9.4) and 0.15 + math.min(speed / 60, 1) * 0.4 or 0
		snd.clack.PlaybackSpeed = 0.6 + math.min(speed / 60, 1)
		snd.wind.Volume = math.min(speed / 60, 1) * 0.5
		if not amb and T > CUT1 and (opt.inCave == nil or opt.inCave()) then
			amb = { a = Lighting.Ambient, o = Lighting.OutdoorAmbient, t0 = T, d = atmo and atmo.Density }
		end
		if amb then
			local k = smooth(amb.t0, amb.t0 + 0.3, T) * (1 - smooth(9.8, 10.9, T))
			Lighting.Ambient = amb.a:Lerp(AMB_UP, k)
			Lighting.OutdoorAmbient = amb.o:Lerp(OAMB_UP, k)
			if atmo and amb.d then atmo.Density = amb.d + (0.12 - amb.d) * k end
		end

		-- the camera
		local camCF
		if not firstPerson then -- S1-S2: third person behind and above the cart, a slow push-in
			local push = smooth(0, 2, T) * 0.15
			local eye = (cart0 * CFrame.new(0, 7.5 * (1 - push), 11 * (1 - push))).Position
			camCF = CFrame.lookAt(eye, cartCF.Position + Vector3.new(0, 1.5, 0) + cart0.LookVector * 3)
		else
			local seat = cartCF * CFrame.new(0, 3.3, 0.6)
			local ahead
			if T < CUT2 or not stationCF then
				ahead = pathAt(d - S0 + 7) * Vector3.new(0, 2.4, 0)
			else
				ahead = cartCF * Vector3.new(0, 2.6, -8)
			end
			camCF = CFrame.lookAt(seat.Position, ahead, cartCF.UpVector)
			local look = smooth(4.6, 5.0, T) * (1 - smooth(5.8, 6.15, T)) -- S4: look out over the lake and the spires, then back
			if look > 0 then camCF = (camCF + cartCF.UpVector * 1.1 * look) * CFrame.Angles(-0.32 * look, -0.62 * look, 0) end -- lean up over the rim, out to the open side of the curve
			if T < CUT2 and not calm then -- lean into curves (curvature x gain, at most 3 degrees)
				local yr = (yawAt(d - S0 + 1) - yawAt(d - S0 - 1)) / 2
				camCF *= CFrame.Angles(0, 0, math.clamp(-yr * 1.5, -0.052, 0.052))
			end
			if T > 8.8 and T < 9.6 then camCF *= CFrame.Angles(-0.035 * smooth(8.8, 9.3, T) * (1 - smooth(9.3, 9.6, T)), 0, 0) end -- the brake nod
			if T > 10 then -- S8: rise and step left onto the platform, into the rider's own eyes
				local head = char and char:FindFirstChild("Head")
				local hrp = char and char:FindFirstChild("HumanoidRootPart")
				if head and hrp then
					local eyes = CFrame.lookAt(head.Position + Vector3.new(0, 0.3, 0), head.Position + Vector3.new(0, 0.3, 0) + hrp.CFrame.LookVector * 10)
					camCF = camCF:Lerp(eyes, smooth(10, 10.9, T))
				end
			end
		end
		local target = (not calm and T > 6.2 and T < 7.6) and 92 or C.FP_FOV
		if not firstPerson then target = 70 end
		fov += (target - fov) * (1 - math.exp(-dt / 0.35))
		if T < CUT1 + 0.05 and T > CUT1 - 0.05 then fov = target end
		shakeAmp = math.max(0, shakeAmp - dt * 1.2)
		local sh = calm and 0 or shakeAmp
		cam.CameraType = Enum.CameraType.Scriptable
		cam.CFrame = camCF * CFrame.Angles((math.random() - 0.5) * sh * 0.06, (math.random() - 0.5) * sh * 0.06, 0)
		cam.FieldOfView = fov
		lastD = d
		if T >= T_END then done = true end
	end)
	local started = os.clock()
	while not done and os.clock() - started < 20 do task.wait() end -- never hang the player in the ride
	RunService:UnbindFromRenderStep("MinecartRide")
	for _, h in hidden do if h[1].Parent then h[1].LocalTransparencyModifier = h[2] end end
	for _, e in blurOff do e.Enabled = true end
	for _, g in guiHidden do if g.Parent then g.Enabled = true end end
	for p in vmSeen do if p.Parent then p.LocalTransparencyModifier = 0 end end
	if amb then
		Lighting.Ambient, Lighting.OutdoorAmbient = amb.a, amb.o
		if atmo and amb.d then atmo.Density = amb.d end
	end
	if opt.restore then -- the game puts its own camera back (first person in the caves, the town camera above)
		opt.restore()
	else
		for k, v in camSaved do pcall(function() cam[k] = v end) end
	end
	for _, o in snd do o:Destroy() end
	world:Destroy()
	gui:Destroy()
	if opt.arrived then opt.arrived() end
end

-- build the far stage and leave it parented (far out of sight): its lanterns need a few seconds to light up the first time,
-- so the client calls this soon after joining
function M.prepare()
	stage = stage or buildStage()
	stage.Parent = workspace
	return stage
end
function M.debugStage() -- Studio tests: the far stage and its path
	return M.prepare(), pathAt, { D1 = D1, D2 = D2, D3 = D3, DN = DN }
end

return M
