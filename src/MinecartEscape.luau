-- MinecartEscape (ReplicatedStorage.Shared.MinecartEscape): the ride up from Camp 1 to town as a minigame (feedback batch phase 4).
-- Storyboard panels: https://claude.ai/artifact/RbfNa2PVyTuRTwyVzdbWTs (vault Briefs/Minecart Ride (2026-11-08).md, "Ride up").
-- Client only; the server keeps the clock and pays the coin bonus. 3-2-1 ESCAPE, then the cart races up an endless rail tunnel
-- (pieces are recycled ahead of the cart): rocks fall into one of three lanes, shown 1 s ahead by a shadow and a red ring;
-- lean left or right (A/D, arrows, left stick, hold a screen half) to dodge. A hit is a BONK and slows you for 1.5 s (no ore
-- lost). Gold orbs boost +20% speed for 1.5 s, stacking to 3. At the end the cart bursts out of the town's mine shaft and a
-- result card shows time, dodges, boosts and the bonus.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")
local Lighting = game:GetService("Lighting")
local C = require(script.Parent.Config)

local M = {}
local WHITE, INK, DARK = Color3.new(1, 1, 1), Color3.fromRGB(62, 42, 86), Color3.fromRGB(14, 8, 22)
local CREAM, BUTTER, PINK, MINT = Color3.fromRGB(255, 250, 243), Color3.fromRGB(255, 217, 112), Color3.fromRGB(255, 157, 176), Color3.fromRGB(127, 220, 180)
local BARK, BARK_LT, RAIL = Color3.fromRGB(78, 58, 72), Color3.fromRGB(112, 84, 96), Color3.fromRGB(138, 128, 168)
local ROCKC = { Color3.fromRGB(46, 32, 66), Color3.fromRGB(70, 50, 98), Color3.fromRGB(98, 72, 132) }
local CRYSTAL = { Color3.fromRGB(60, 200, 150), Color3.fromRGB(150, 100, 230), Color3.fromRGB(230, 90, 160), Color3.fromRGB(80, 150, 240) }
local SPARK = "rbxasset://textures/particles/sparkles_main.dds"
local ORIGIN = C.CAVE_ORIGIN + Vector3.new(260, 30, -260) -- beside the ride's far stage, south of the caves
local PIECE, NPIECE = 4, 40 -- tunnel pieces recycled ahead of the cart
local LANES = { -1.6, 0, 1.6 }
local SND = { clack = { 9113120822, 0, true }, wind = { 9125742262, 0, true }, rumble = { 9125875511, 0.6 }, bonk = { 3765689841, 0.8 }, whoosh = { 9126229255, 0.7 } }
local E = C.ESCAPE

local function part(parent, size, cf, color, props)
	local p = Instance.new("Part")
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
	p.Material, p.TopSurface, p.BottomSurface = Enum.Material.SmoothPlastic, Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.Size, p.CFrame, p.Color = size, cf, color
	for k, v in props or {} do p[k] = v end
	p.Parent = parent
	return p
end
local function smooth(a, b, t)
	local x = math.clamp((t - a) / (b - a), 0, 1)
	return x * x * (3 - 2 * x)
end

-- the tunnel: NPIECE models along -Z from ORIGIN; a piece behind the cart jumps NPIECE * PIECE ahead
local tunnel
local function buildPiece(f, k, rng)
	local m = Instance.new("Model")
	m.Name = "Piece"
	local cf = CFrame.new(ORIGIN + Vector3.new(0, 0, -k * PIECE))
	local ROCK = { Material = Enum.Material.Slate, MaterialVariant = "PixelCaveRock" }
	local root = part(m, Vector3.new(9, 1, PIECE), cf * CFrame.new(0, -0.5, 0), ROCKC[1], ROCK)
	m.PrimaryPart = root
	local wallC = ROCKC[rng:NextInteger(2, 3)]
	for _, s in { -1, 1 } do part(m, Vector3.new(1.6, 10, PIECE), cf * CFrame.new(s * 5.3, 4.5, 0), wallC, ROCK) end
	part(m, Vector3.new(12.2, 1.6, PIECE), cf * CFrame.new(0, 10.2, 0), ROCKC[1], ROCK)
	for _, x in { -1.25, 1.25 } do part(m, Vector3.new(0.3, 0.3, PIECE), cf * CFrame.new(x, 0.45, 0), RAIL, { Material = Enum.Material.Metal }) end
	for _, z in { -1, 1 } do part(m, Vector3.new(3.4, 0.25, 0.7), cf * CFrame.new(0, 0.15, z), BARK) end
	if k % 2 == 0 then -- a support frame and a lantern on every second piece
		for _, s in { -1, 1 } do part(m, Vector3.new(0.8, 8.6, 0.8), cf * CFrame.new(s * 4, 4.3, 0), BARK) end
		part(m, Vector3.new(9, 0.9, 0.9), cf * CFrame.new(0, 8.9, 0), BARK_LT)
		part(m, Vector3.new(0.7, 0.9, 0.7), cf * CFrame.new(0, 7.2, 0), Color3.fromRGB(255, 212, 160), { Material = Enum.Material.Neon })
	elseif rng:NextNumber() < 0.6 then
		local s = rng:NextNumber() < 0.5 and -1 or 1
		local col = CRYSTAL[rng:NextInteger(1, #CRYSTAL)]
		for i = 1, 3 do
			part(m, Vector3.new(0.8, rng:NextNumber(1.4, 2.6), 0.8), cf * CFrame.new(s * 4.4, rng:NextNumber(1, 5), rng:NextNumber(-1.5, 1.5)) * CFrame.Angles(0, 0, s * rng:NextNumber(0.5, 1)), col:Lerp(Color3.new(1, 1, 1), 0.35), i == 1 and { Material = Enum.Material.Neon, Size = Vector3.new(0.45, 1.2, 0.45) } or { Material = Enum.Material.Glass, Transparency = 0.25 })
		end
	end
	m.Parent = f
	return m
end
function M.prepare()
	if tunnel then
		tunnel.folder.Parent = workspace
		for i, pc in tunnel.pieces do
			pc.k = i - 1
			pc.m:PivotTo(CFrame.new(ORIGIN + Vector3.new(0, -0.5, -pc.k * PIECE)))
		end
		return
	end
	local f = Instance.new("Folder")
	f.Name = "EscapeTunnel"
	local rng = Random.new(11)
	local pieces = {}
	for k = 0, NPIECE - 1 do pieces[k + 1] = { m = buildPiece(f, k, rng), k = k } end
	-- the exit: a bright portal that waits far down the tunnel until the last stretch
	local exit = part(f, Vector3.new(9, 10, 1), CFrame.new(ORIGIN + Vector3.new(0, 4.5, 400)), Color3.fromRGB(255, 244, 214), { Material = Enum.Material.Neon })
	f.Parent = workspace
	tunnel = { folder = f, pieces = pieces, exit = exit }
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

-- opt: { seed, cart = the town cart Model, sfx = fn(name, pitch), reduceMotion, report = fn(result) (tells the server),
--        result = fn() -> bonus or nil (the server's answer), restore = fn(), arrived = fn() }
-- yields until the player is back in town (about 40 s)
function M.play(opt)
	local plr = Players.LocalPlayer
	local cam = workspace.CurrentCamera
	local sfx = opt.sfx or function() end
	local calm = opt.reduceMotion == true
	M.prepare()
	local rng = Random.new(opt.seed or 1)
	local world = Instance.new("Folder")
	world.Name = "MinecartEscape"
	world.Parent = workspace
	local cart = opt.cart and ghost(opt.cart)
	if not cart then return end
	for _, p in cart:GetDescendants() do
		if p:IsA("BasePart") and p.Transparency < 1 then p.Color = p.Color:Lerp(INK, 0.42) end
	end
	cart.Parent = world
	local char = plr.Character
	local rider = char and ghost(char)
	local riderOff = CFrame.new(0, 3.3, 0.3)
	if rider and char then
		local hrp, hum = char:FindFirstChild("HumanoidRootPart"), char:FindFirstChildOfClass("Humanoid")
		if hrp and hum then riderOff = CFrame.new(0, 1.05 + hrp.Size.Y / 2 + hum.HipHeight, 0.3) end
	end
	local hubHidden = {}
	local lampA = Instance.new("Attachment")
	lampA.Position = Vector3.new(0, 2.7, -1.9)
	lampA.Parent = cart.PrimaryPart
	local headLamp = Instance.new("SpotLight")
	headLamp.Face, headLamp.Angle, headLamp.Range, headLamp.Brightness, headLamp.Color = Enum.NormalId.Front, 75, 44, 2, Color3.fromRGB(255, 226, 180)
	headLamp.Parent = lampA
	local sparks = {}
	for _, x in { -1.5, 1.5 } do
		local a = Instance.new("Attachment")
		a.Position, a.Orientation = Vector3.new(x, 0.4, -1.4), Vector3.new(0, 180, 0)
		a.Parent = cart.PrimaryPart
		local e = Instance.new("ParticleEmitter")
		e.Texture, e.Rate, e.LightEmission, e.LightInfluence = SPARK, 0, 1, 0
		e.Color = ColorSequence.new(Color3.fromRGB(255, 224, 140), PINK)
		e.Size, e.Lifetime, e.Speed, e.SpreadAngle = NumberSequence.new(0.35, 0), NumberRange.new(0.2, 0.35), NumberRange.new(8, 16), Vector2.new(25, 25)
		e.Acceleration, e.Squash, e.EmissionDirection = Vector3.new(0, -30, 0), NumberSequence.new(-1), Enum.NormalId.Front
		e.Parent = a
		table.insert(sparks, e)
	end
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
		end
	end

	-- the screen: progress bar, timer, boost pips, the 3-2-1, BONK, lean hint, the result card
	local pg = plr:WaitForChild("PlayerGui")
	local guiHidden = {}
	local gui = Instance.new("ScreenGui")
	gui.Name, gui.IgnoreGuiInset, gui.ResetOnSpawn, gui.DisplayOrder, gui.ZIndexBehavior = "MinecartEscapeGui", true, false, 30, Enum.ZIndexBehavior.Sibling
	gui.Parent = pg
	local function frame(props)
		local f = Instance.new("Frame")
		f.BorderSizePixel = 0
		for k, v in props do f[k] = v end
		f.Parent = props.Parent or gui
		return f
	end
	local function round(o, r)
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(r or 0.5, 0)
		c.Parent = o
	end
	local function stroke(o, col, th)
		local s = Instance.new("UIStroke")
		s.Color, s.Thickness = col, th
		s.Parent = o
		return s
	end
	local function label(parent, text, size, pos, color, z)
		local t = Instance.new("TextLabel")
		t.BackgroundTransparency, t.Font, t.TextScaled, t.Text, t.TextColor3 = 1, Enum.Font.FredokaOne, true, text, color or INK
		t.Size, t.Position, t.AnchorPoint, t.ZIndex = size, pos, Vector2.new(0.5, 0.5), z or 4
		t.Parent = parent
		return t
	end
	local bar = frame({ Size = UDim2.fromScale(0.36, 0.035), Position = UDim2.fromScale(0.5, 0.06), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = CREAM, ZIndex = 3 })
	round(bar)
	stroke(bar, INK, 3)
	local fill = frame({ Parent = bar, Size = UDim2.fromScale(0, 1), BackgroundColor3 = BUTTER, ZIndex = 4 })
	round(fill)
	local barText = label(bar, "ESCAPE", UDim2.fromScale(0.5, 0.8), UDim2.fromScale(0.5, 0.5), INK, 5)
	local timer = label(gui, "0.0", UDim2.fromScale(0.1, 0.05), UDim2.fromScale(0.74, 0.06), WHITE, 4)
	stroke(timer, INK, 3)
	local pips = {}
	for i = 1, 3 do
		local p = frame({ Size = UDim2.fromScale(0.022, 0.04), Position = UDim2.fromScale(0.5 - 0.03 + (i - 1) * 0.03, 0.115), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = BUTTER, BackgroundTransparency = 0.75, ZIndex = 3 })
		local a = Instance.new("UIAspectRatioConstraint")
		a.Parent = p
		round(p)
		stroke(p, INK, 2)
		pips[i] = p
	end
	local big = label(gui, "", UDim2.fromScale(0.5, 0.16), UDim2.fromScale(0.5, 0.42), WHITE, 6)
	local bigStroke = stroke(big, INK, 5)
	local touch = UIS.TouchEnabled and not UIS.KeyboardEnabled
	local hint = label(gui, touch and "HOLD LEFT OR RIGHT TO LEAN" or "LEAN WITH  A / D  OR  ← →", UDim2.fromScale(0.5, 0.045), UDim2.fromScale(0.5, 0.9), WHITE, 4)
	local hintStroke = stroke(hint, INK, 3)
	local flash = frame({ Size = UDim2.fromScale(1, 1), BackgroundColor3 = WHITE, BackgroundTransparency = 1, ZIndex = 8 })
	local vignette = frame({ Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(255, 80, 110), BackgroundTransparency = 1, ZIndex = 2 })

	-- input: keys, the left stick, or touches on a screen half
	local touches = {}
	local cons = {}
	table.insert(cons, UIS.TouchStarted:Connect(function(t) touches[t] = t.Position.X end))
	table.insert(cons, UIS.TouchMoved:Connect(function(t) if touches[t] then touches[t] = t.Position.X end end))
	table.insert(cons, UIS.TouchEnded:Connect(function(t) touches[t] = nil end))
	local function steer()
		local x = 0
		if UIS:IsKeyDown(Enum.KeyCode.A) or UIS:IsKeyDown(Enum.KeyCode.Left) then x -= 1 end
		if UIS:IsKeyDown(Enum.KeyCode.D) or UIS:IsKeyDown(Enum.KeyCode.Right) then x += 1 end
		local ok, pad = pcall(function() return UIS:GetGamepadState(Enum.UserInputType.Gamepad1) end)
		for _, st in ok and pad or {} do
			if st.KeyCode == Enum.KeyCode.Thumbstick1 and math.abs(st.Position.X) > 0.4 then x += st.Position.X > 0 and 1 or -1 end
		end
		local w = cam.ViewportSize.X
		for _, px in touches do x += px < w / 2 and -1 or 1 end
		return math.clamp(x, -1, 1)
	end

	-- camera and HUD: saved here, put back at the end
	local vmSeen, hiddenChar = {}, {}
	local amb = { a = Lighting.Ambient, o = Lighting.OutdoorAmbient }
	local AMB_UP, OAMB_UP = Color3.fromRGB(96, 80, 132), Color3.fromRGB(86, 72, 120)

	-- the run
	local dist, speed, t, lean, roll = 0, 0, -3.2, 0, 0
	local boosts, boostUntil, slowUntil, dodges, hits = 0, {}, 0, 0, 0
	local hazards, nextSpawn = {}, 1.2
	local shakeAmp, phase, done, resultAt, bonus = 0, "run", false, nil, nil
	local runTime, landed, card = 0, false, nil
	local lastCount = 4
	local function laneX() return lean * 1.6 end
	local function spawnRock(lane, at, threat)
		local x = LANES[lane]
		local z = ORIGIN.Z - at
		local ring = part(world, Vector3.new(0.15, 3, 3), CFrame.new(ORIGIN.X + x, ORIGIN.Y + 0.35, z) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(255, 60, 90), { Shape = Enum.PartType.Cylinder, Material = Enum.Material.Neon, Transparency = 0.1 })
		local rock = Instance.new("Model")
		local r1 = part(rock, Vector3.new(2.6, 2.1, 2.4), CFrame.new(ORIGIN.X + x, ORIGIN.Y + 9, z) * CFrame.Angles(0.3, 0.6, 0.2), ROCKC[3], { Material = Enum.Material.Slate, MaterialVariant = "PixelCaveRock" })
		part(rock, Vector3.new(1.7, 1.4, 1.7), r1.CFrame * CFrame.new(0.7, 0.7, -0.4) * CFrame.Angles(0.4, 0.2, 0.5), ROCKC[2], { Material = Enum.Material.Slate, MaterialVariant = "PixelCaveRock" })
		for k = 1, 2 do -- glowing pink cracks so a falling rock reads at a glance (Gemini r1)
			part(rock, Vector3.new(0.18, 2.3, 0.18), r1.CFrame * CFrame.new(k == 1 and -0.5 or 0.6, 0, -1.22) * CFrame.Angles(0, 0, k == 1 and 0.5 or -0.4), Color3.fromRGB(255, 119, 168), { Material = Enum.Material.Neon })
		end
		rock.PrimaryPart = r1
		rock.Parent = world
		table.insert(hazards, { kind = "rock", lane = lane, at = at, ring = ring, rock = rock, base = r1.CFrame, threat = threat })
	end
	local function spawnOrb(lane, at)
		local orb = part(world, Vector3.new(1.3, 1.3, 1.3), CFrame.new(ORIGIN.X + LANES[lane], ORIGIN.Y + 2.6, ORIGIN.Z - at), BUTTER, { Shape = Enum.PartType.Ball, Material = Enum.Material.Neon })
		local e = Instance.new("ParticleEmitter")
		e.Texture, e.Rate, e.LightEmission, e.Color = SPARK, 8, 1, ColorSequence.new(BUTTER, PINK)
		e.Size, e.Lifetime, e.Speed = NumberSequence.new(0.4, 0), NumberRange.new(0.4, 0.7), NumberRange.new(1, 2)
		e.Parent = orb
		table.insert(hazards, { kind = "orb", lane = lane, at = at, orb = orb })
	end
	local function cleanup(h)
		for _, k in { "ring", "rock", "orb" } do if h[k] then h[k]:Destroy() end end
	end

	local last = os.clock()
	snd.rumble:Play()
	shakeAmp = 0.3
	RunService:BindToRenderStep("MinecartEscape", Enum.RenderPriority.Camera.Value + 20, function()
		local now = os.clock()
		local dt = math.min(now - last, 0.1)
		last = now
		t += dt
		for _, g in pg:GetChildren() do -- every other layer stays off while the escape runs
			if g ~= gui and g:IsA("ScreenGui") and g.Enabled then g.Enabled = false table.insert(guiHidden, g) end
		end
		for _, m in cam:GetChildren() do
			for _, p in m:GetDescendants() do
				if p:IsA("BasePart") and p.LocalTransparencyModifier < 1 then vmSeen[p] = true p.LocalTransparencyModifier = 1 end
			end
		end
		if plr.Character then
			for _, p in plr.Character:GetDescendants() do
				if p:IsA("BasePart") and p.LocalTransparencyModifier < 1 then hiddenChar[p] = true p.LocalTransparencyModifier = 1 end
			end
		end
		if phase == "run" then
			local k = smooth(-3.2, -2.9, t)
			Lighting.Ambient, Lighting.OutdoorAmbient = amb.a:Lerp(AMB_UP, k), amb.o:Lerp(OAMB_UP, k)
		end

		if phase == "run" then
			-- 3-2-1 ESCAPE
			local count = math.ceil(-t)
			if t < 0 and count ~= lastCount then
				lastCount = count
				big.Text = tostring(count)
				sfx("click", 1 + (3 - count) * 0.15)
			elseif t >= 0 and lastCount > 0 then
				lastCount = 0
				big.Text = "ESCAPE!"
				sfx("upgrade", 1.1)
				play("whoosh", 1)
				snd.clack:Play()
				snd.wind:Play()
			end
			big.TextTransparency = t < 0 and 0 or smooth(0.5, 0.9, t)
			bigStroke.Transparency = big.TextTransparency
			hint.TextTransparency = smooth(4, 5, t)
			hintStroke.Transparency = hint.TextTransparency
			-- speed: base, boosts stack, a bonk halves it
			local live = 0
			for i = #boostUntil, 1, -1 do if now < boostUntil[i] then live += 1 else table.remove(boostUntil, i) end end
			local target = t < 0 and 0 or E.speed * (1 + 0.2 * live) * (now < slowUntil and 0.5 or 1)
			speed += (target - speed) * (1 - math.exp(-dt / 0.25))
			dist += speed * dt
			for i, p in pips do p.BackgroundTransparency = i <= live and 0 or 0.75 end
			-- lean with a little spring
			local want = steer()
			lean += (want - lean) * (1 - math.exp(-dt / 0.08))
			roll += ((calm and 0 or -want * 0.052) - roll) * (1 - math.exp(-dt / 0.1))
			-- spawn ahead: rocks every 1.1-1.6 s (two lanes at once later on), an orb now and then
			if t > 0 and t >= nextSpawn and dist < E.dist - 80 then
				local ahead = dist + math.max(speed, E.speed) * 1.6
				local cur = lean < -0.5 and 1 or (lean > 0.5 and 3 or 2)
				local lane = rng:NextNumber() < 0.6 and cur or rng:NextInteger(1, 3) -- most rocks aim at you
				spawnRock(lane, ahead, lane == cur)
				if dist > E.dist * 0.45 and rng:NextNumber() < 0.35 then
					local l2 = lane % 3 + 1
					spawnRock(l2, ahead, l2 == cur)
				end
				if rng:NextNumber() < 0.45 then spawnOrb(rng:NextInteger(1, 3), ahead + math.max(speed, E.speed) * 0.6) end
				nextSpawn = t + rng:NextNumber(1.1, 1.6) * (dist > E.dist * 0.6 and 0.85 or 1)
			end
			-- hazards: rocks drop to land as the cart arrives; passing a lane checks the lean
			local myLane = lean < -0.5 and 1 or (lean > 0.5 and 3 or 2)
			for i = #hazards, 1, -1 do
				local h = hazards[i]
				local gap = h.at - dist
				if h.kind == "rock" then
					local fall = 1 - math.clamp(gap / math.max(speed * 0.6, 8), 0, 1) -- the last 0.6 s: falls from the ceiling
					h.rock:PivotTo(h.base * CFrame.new(0, -fall * 8, 0) * CFrame.Angles(fall * 2, 0, fall))
					h.ring.Transparency = 0.05 + 0.4 * (0.5 + 0.5 * math.sin(now * 18))
				else
					h.orb.CFrame = CFrame.new(h.orb.Position.X, ORIGIN.Y + 2.6 + math.sin(now * 4 + h.at) * 0.3, h.orb.Position.Z)
				end
				if gap < 0.8 and not h.passed then
					h.passed = true
					if h.lane == myLane then
						if h.kind == "rock" then
							hits += 1
							slowUntil = now + 1.5
							shakeAmp = calm and 0 or 0.5
							play("bonk", 1)
							big.Text, big.TextTransparency, big.TextColor3 = "BONK!", 0, PINK
							bigStroke.Transparency = 0
							task.delay(0.6, function() big.TextTransparency = 1 bigStroke.Transparency = 1 big.TextColor3 = WHITE end)
							vignette.BackgroundTransparency = 0.6
						else
							boosts += 1
							table.insert(boostUntil, now + 1.5)
							if #boostUntil > 3 then table.remove(boostUntil, 1) end
							sfx("sparkle", 1 + #boostUntil * 0.1)
							play("whoosh", 1.3)
						end
						cleanup(h)
						table.remove(hazards, i)
					elseif h.kind == "rock" and h.threat then -- it was coming for you and you moved
						dodges += 1
					end
				end
				if gap < -6 and hazards[i] == h then
					cleanup(h)
					table.remove(hazards, i)
				end
			end
			vignette.BackgroundTransparency = math.min(1, vignette.BackgroundTransparency + dt * 1.2)
			-- recycle tunnel pieces that fell behind
			for _, pc in tunnel.pieces do
				if pc.k * PIECE < dist - 8 then
					pc.k += NPIECE
					pc.m:PivotTo(CFrame.new(ORIGIN + Vector3.new(0, -0.5, -pc.k * PIECE)))
				end
			end
			tunnel.exit.CFrame = CFrame.new(ORIGIN + Vector3.new(0, 4.5, -(E.dist + 6)))
			fill.Size = UDim2.fromScale(math.clamp(dist / E.dist, 0, 1), 1)
			barText.Text = string.format("ESCAPE  %d%%", math.clamp(math.floor(dist / E.dist * 100), 0, 100))
			timer.Text = string.format("%.1f", math.max(t, 0))
			for _, e in sparks do e.Rate = (live > 0 or now < slowUntil) and 30 or 0 end
			snd.clack.Volume = t > 0 and 0.2 + math.min(speed / 48, 1) * 0.4 or 0
			snd.clack.PlaybackSpeed = 0.7 + math.min(speed / 48, 1) * 0.8
			snd.wind.Volume = math.min(speed / 48, 1) * 0.5
			flash.BackgroundTransparency = 1 - smooth(E.dist - 25, E.dist, dist)
			-- camera: first person in the cart, leaning
			local cartCF = CFrame.new(ORIGIN + Vector3.new(laneX(), 0, -dist)) * CFrame.Angles(0, 0, roll * 0.6)
			cart:PivotTo(cartCF)
			shakeAmp = math.max(0, shakeAmp - dt * 1.2)
			local sh = calm and 0 or shakeAmp + math.min(speed / 48, 1) * 0.02
			cam.CameraType = Enum.CameraType.Scriptable
			cam.CFrame = cartCF * CFrame.new(0, 3.8, 0.6) * CFrame.Angles(-0.06, 0, roll) * CFrame.Angles((math.random() - 0.5) * sh * 0.06, (math.random() - 0.5) * sh * 0.06, 0)
			cam.FieldOfView = C.FP_FOV + (calm and 0 or math.min(#boostUntil, 3) * 2)
			if dist >= E.dist then -- out of the tunnel: tell the server, wait for it to move us to town, then burst out of the shaft
				phase = "wait"
				resultAt, runTime = t, t
				Lighting.Ambient, Lighting.OutdoorAmbient = amb.a, amb.o -- the cave look back before the server switches us to town
				for _, e in sparks do e.Rate = 0 end
				snd.clack:Stop()
				snd.wind:Stop()
				for _, h in hazards do cleanup(h) end
				hazards = {}
				if opt.report then opt.report({ time = t, dodges = dodges, boosts = boosts, hits = hits }) end
			end
		elseif phase == "wait" then
			flash.BackgroundTransparency = 0
			bonus = opt.result and opt.result()
			if bonus or t - resultAt > 4 then
				phase = "town"
				resultAt = t
				bar.Visible, timer.Visible, hint.Visible = false, false, false
				for _, p in pips do p.Visible = false end
				for _, p in cart:GetDescendants() do -- back to the town cart's own colours for the burst out of the shaft
					if p:IsA("BasePart") and opt.cart:FindFirstChild(p.Name, true) then p.Color = opt.cart:FindFirstChild(p.Name, true).Color end
				end
			end
		elseif phase == "town" then
			local u = t - resultAt
			flash.BackgroundTransparency = smooth(0, 0.5, u)
			local cart0 = opt.cart:GetPivot()
			local a = smooth(0, 0.9, u)
			local arc = math.sin(a * math.pi) * 6
			local from = cart0 * CFrame.new(0, -12, -6) * CFrame.Angles(1.1, 0, 0)
			local cf = from:Lerp(cart0, a) + Vector3.new(0, arc, 0)
			if u > 0.9 and u < 1.2 then cf *= CFrame.new(0, math.sin((u - 0.9) / 0.3 * math.pi) * 0.4, 0) end
			cart:PivotTo(cf)
			if rider then
				if not rider.Parent then
					rider.Parent = world
					for _, p in opt.cart:GetDescendants() do
						if p:IsA("BasePart") then hubHidden[p] = p.LocalTransparencyModifier p.LocalTransparencyModifier = 1 end
					end
				end
				rider:PivotTo(cf * riderOff)
			end
			if u > 0.9 and not landed then
				landed = true
				shakeAmp = calm and 0 or 0.4
				sfx("breakRock", 0.8)
				sfx("coin", 1.1)
			end
			local eye = (cart0 * CFrame.new(0, 9, 13)).Position
			cam.CameraType = Enum.CameraType.Scriptable
			cam.FieldOfView = 70
			shakeAmp = math.max(0, shakeAmp - dt * 1.2)
			cam.CFrame = CFrame.lookAt(eye, cf.Position + Vector3.new(0, 1.5, 0)) * CFrame.Angles((math.random() - 0.5) * shakeAmp * 0.06, (math.random() - 0.5) * shakeAmp * 0.06, 0)
			if u > 1 and not card then
				card = frame({ Size = UDim2.fromScale(0.34, 0.42), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = CREAM, ZIndex = 6 })
				round(card, 0.1)
				stroke(card, Color3.fromRGB(158, 142, 194), 4)
				local sc = Instance.new("UIScale")
				sc.Scale = 0.6
				sc.Parent = card
				game:GetService("TweenService"):Create(sc, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Scale = 1 }):Play()
				label(card, "ESCAPED!", UDim2.fromScale(0.8, 0.18), UDim2.fromScale(0.5, 0.2), INK, 7)
				local stars = hits == 0 and 3 or (hits <= 2 and 2 or 1) -- a clean run is three stars
				for k = 1, 3 do
					local st = label(card, "\u{2605}", UDim2.fromScale(0.13, 0.17), UDim2.fromScale(0.36 + (k - 1) * 0.14, 0.05), k <= stars and Color3.fromRGB(255, 196, 70) or Color3.fromRGB(220, 212, 236), 8)
					stroke(st, INK, 2)
				end
				local sub = frame({ Parent = card, Size = UDim2.fromScale(0.86, 0.46), Position = UDim2.fromScale(0.5, 0.56), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Color3.fromRGB(255, 249, 230), ZIndex = 6 })
				round(sub, 0.12)
				local go = Instance.new("TextButton")
				go.Size, go.Position, go.AnchorPoint, go.ZIndex = UDim2.fromScale(0.46, 0.12), UDim2.fromScale(0.5, 0.9), Vector2.new(0.5, 0.5), 8
				go.BackgroundColor3, go.Font, go.TextScaled, go.Text, go.TextColor3, go.AutoButtonColor = Color3.fromRGB(120, 224, 143), Enum.Font.FredokaOne, true, "CONTINUE", Color3.new(1, 1, 1)
				round(go, 0.3)
				stroke(go, Color3.fromRGB(63, 156, 124), 3)
				go.Parent = card
				go.Activated:Connect(function() done = true end)
				local rows = { { "TIME", string.format("%.1f s", runTime) }, { "DODGES", tostring(dodges) }, { "BOOSTS", tostring(boosts) }, { "BONUS", "+" .. tostring(bonus or 0) .. " COINS" } }
				for i, r in rows do
					label(card, r[1], UDim2.fromScale(0.4, 0.085), UDim2.fromScale(0.3, 0.30 + i * 0.104), Color3.fromRGB(122, 98, 160), 7)
					label(card, r[2], UDim2.fromScale(0.45, 0.085), UDim2.fromScale(0.7, 0.30 + i * 0.104), i == 4 and Color3.fromRGB(214, 140, 40) or INK, 7)
				end
			end
			if u > 7 then done = true end -- CONTINUE ends it sooner
		end
	end)
	local started = os.clock()
	while not done and os.clock() - started < 120 do task.wait() end
	RunService:UnbindFromRenderStep("MinecartEscape")
	for _, c in cons do c:Disconnect() end
	if phase == "run" then Lighting.Ambient, Lighting.OutdoorAmbient = amb.a, amb.o end
	for p in vmSeen do if p.Parent then p.LocalTransparencyModifier = 0 end end
	for p in hiddenChar do if p.Parent then p.LocalTransparencyModifier = 0 end end
	for p, v in hubHidden do if p.Parent then p.LocalTransparencyModifier = v end end
	for _, g in guiHidden do if g.Parent then g.Enabled = true end end
	for _, o in snd do o:Destroy() end
	world:Destroy()
	gui:Destroy()
	if opt.restore then opt.restore() end
	if opt.arrived then opt.arrived() end
end

return M
