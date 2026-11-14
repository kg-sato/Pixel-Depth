-- MinecartEscape (ReplicatedStorage.Shared.MinecartEscape): the ride up from Camp 1 to town as a minigame (feedback batch phase 4).
-- Storyboard panels: https://claude.ai/artifact/RbfNa2PVyTuRTwyVzdbWTs (vault Briefs/Minecart Ride (2026-11-08).md, "Ride up").
-- Client only; the server keeps the clock and pays the coin bonus. 3-2-1 ESCAPE, then the cart races up an endless rail tunnel
-- (pieces are recycled ahead of the cart): rocks fall into one of three lanes, shown 1 s ahead by a shadow and a red ring;
-- lean left or right (A/D, arrows, left stick, hold a screen half) to dodge. A hit is a BONK and slows you for 1.5 s (no ore
-- lost). Gold orbs boost +20% speed for 1.5 s, stacking to 3. At the end the cart bursts out of the town's mine shaft and a
-- result card shows time, dodges, boosts and the bonus.
-- Playtest 2 (the user, 2026-11-09: "too linear with no twists and turns"; vault Refs/Minecart Escape Redesign, items 1, 2 and 4):
-- the track is now a seeded path that curves, dips and climbs, the camera looks ahead into the bends, and there are three verbs:
-- lean, JUMP (Space / A / swipe up) and DUCK (S / Down / B / swipe down). Obstacles: falling rocks (lean), low timber beams
-- (duck), buckled rails (jump) and parked carts with a gloomling inside (lean or jump). Each is shown alone once with a hint,
-- warned by a sound a second ahead, and the speed rises in a wave (calm, build, a gold-rush breather, the climax).
-- Items 5 and 6: the Gloom chases you (each BONK lets it close in; boosts pull away; caught halves the bonus) and halfway up the
-- tunnel opens onto a great cavern crossed on a timber trestle, crystals glowing far below and the town's lights high above.
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
local SND = { clack = { 9113120822, 0, true }, wind = { 9125742262, 0, true }, rumble = { 9125875511, 0.6 }, bonk = { 3765689841, 0.8 }, whoosh = { 9126229255, 0.7 },
	creak = { 9120839010, 0.7 }, thud = { 9120798134, 0.6 }, screech = { 9116893799, 0.45 } }
local E = C.ESCAPE

local CartFX = require(script.Parent:WaitForChild("CartFX"))
local EscapeHUD = require(script.Parent:WaitForChild("EscapeHUD"))
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
	local o = (k % 2) * 0.03 -- neighbours sit 0.03 apart, and every piece is 0.7 longer, so curves close their wedges with no coplanar faces
	local L = PIECE + 0.7
	local root = part(m, Vector3.new(9, 1, L), cf * CFrame.new(0, -0.5 - o, 0), ROCKC[1], ROCK)
	m.PrimaryPart = root
	local wallC = ROCKC[rng:NextInteger(2, 3)]
	for _, s in { -1, 1 } do part(m, Vector3.new(1.6, 10, L), cf * CFrame.new(s * (5.3 + o), 4.5, 0), wallC, ROCK) end
	part(m, Vector3.new(12.2, 1.6, L), cf * CFrame.new(0, 10.2 + o, 0), ROCKC[1], ROCK)
	for _, x in { -1.25, 1.25 } do part(m, Vector3.new(0.3, 0.3, L), cf * CFrame.new(x, 0.45 + o * 0.7, 0), RAIL, { Material = Enum.Material.Metal }) end
	for _, z in { -1, 1 } do part(m, Vector3.new(3.4, 0.25, 0.7), cf * CFrame.new(0, 0.15, z), BARK) end
	if k % 2 == 0 then -- a support frame and a lantern on every second piece
		for _, s in { -1, 1 } do
			part(m, Vector3.new(0.8, 8.6, 0.8), cf * CFrame.new(s * 4, 4.3, 0), BARK, { Material = Enum.Material.Wood })
			part(m, Vector3.new(0.5, 2.6, 0.5), cf * CFrame.new(s * 3.1, 7.6, 0) * CFrame.Angles(0, 0, s * 0.8), BARK_LT, { Material = Enum.Material.Wood }) -- a knee brace in each corner
			part(m, Vector3.new(1.0, 0.7, 0.92), cf * CFrame.new(s * 4, 8.2, 0), Color3.fromRGB(58, 52, 72), { Material = Enum.Material.Metal }) -- an iron bracket plate
		end
		part(m, Vector3.new(9, 0.9, 0.9), cf * CFrame.new(0, 8.9, 0), BARK_LT, { Material = Enum.Material.Wood })
		CartFX.lantern(part(m, Vector3.new(0.7, 0.9, 0.7), cf * CFrame.new(0, 7.2, 0), Color3.fromRGB(255, 212, 160))) -- a glass lantern, not a bare neon block (audit 09)
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

-- the path (redesign item 1): one frame per piece, chained from authored segments, seeded per run so the server could rebuild it
local PATH_N = math.ceil((E.dist + 260) / PIECE)
local function buildPath(seed)
	local rng = Random.new(seed)
	local segs = {}
	local function add(n, yaw, pitch) for _ = 1, n do table.insert(segs, { yaw, pitch }) end end
	add(12, 0, 0) -- a calm straight start
	local dir, heading = (rng:NextNumber() < 0.5) and 1 or -1, 0
	while #segs < PATH_N + 4 do
		local r = rng:NextNumber()
		if r < 0.45 then -- a bend: 45-70 degrees over 14-18 pieces (at most ~4 degrees a piece), sides alternate so the track snakes on
			local n = rng:NextInteger(14, 18)
			local total = math.rad(rng:NextNumber(45, 70))
			if math.abs(heading + dir * total) > math.rad(75) then dir = -dir end
			add(n, dir * total / n, 0)
			heading += dir * total
			dir = -dir
		elseif r < 0.65 then -- a dip: down 12 degrees, a short run, back up
			add(4, 0, -math.rad(3))
			add(rng:NextInteger(3, 6), 0, 0)
			add(4, 0, math.rad(3))
		elseif r < 0.82 then -- a climb toward town
			add(4, 0, math.rad(2.5))
			add(rng:NextInteger(4, 8), 0, 0)
			add(4, 0, -math.rad(2.5))
		else
			add(rng:NextInteger(6, 12), 0, 0)
		end
	end
	local P, YAW = { [0] = CFrame.new(ORIGIN) }, { [0] = 0 }
	for i = 1, PATH_N + 4 do
		local sg = segs[i]
		P[i] = P[i - 1] * CFrame.Angles(sg[2], sg[1], 0) * CFrame.new(0, 0, -PIECE)
		YAW[i] = sg[1]
	end
	return P, YAW
end

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
		if p:IsA("BasePart") and p.Transparency < 1 then p.Color = p.Color:Lerp(INK, 0.12) end -- the cart is dark oak now (audit 14)
	end
	cart.Parent = world
	local hands = CartFX.hands(cart, 2.62, -1.65) -- the rider's gloved hands on the front rim
	local bounce = CartFX.spring(210, 16)
	local air = CartFX.air(world)
	local lastTie = 0
	local char = plr.Character
	local rider = char and ghost(char)
	local riderOff = CFrame.new(0, 3.3, 0.3)
	if rider and char then
		local hrp, hum = char:FindFirstChild("HumanoidRootPart"), char:FindFirstChildOfClass("Humanoid")
		local sat = rider and sitDown(rider)
		if hrp and hum then riderOff = CFrame.new(0, 1.05 + hrp.Size.Y / 2 + (sat and 0.7 or hum.HipHeight), 0.3) end -- seated: hips just above the cart floor
	end
	local hubHidden = {}
	local lampA = Instance.new("Attachment")
	lampA.Position = Vector3.new(0, 2.7, -1.9)
	lampA.Parent = cart.PrimaryPart
	local headLamp = Instance.new("SpotLight")
	headLamp.Face, headLamp.Angle, headLamp.Range, headLamp.Brightness, headLamp.Color = Enum.NormalId.Front, 75, 44, 1.5, Color3.fromRGB(255, 226, 180)
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
	local speedLines = CartFX.speedLines(gui, 16)
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
	-- directive v9 and Gemini (2026-11-13): the bar was a flat white strip. Now a smoked glass tube with a lit rim, a gold jelly
	-- fill and a white shine along the top
	local bar = frame({ Size = UDim2.fromScale(0.36, 0.044), Position = UDim2.fromScale(0.5, 0.06), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Color3.fromRGB(36, 17, 56), BackgroundTransparency = 0.12, ZIndex = 3 })
	round(bar)
	stroke(bar, Color3.fromRGB(224, 176, 255), 2)
	local fill = frame({ Parent = bar, Size = UDim2.fromScale(0, 1), BackgroundColor3 = WHITE, ZIndex = 4 })
	round(fill)
	local fg = Instance.new("UIGradient")
	fg.Rotation, fg.Color = 90, ColorSequence.new(Color3.fromRGB(255, 226, 120), Color3.fromRGB(255, 150, 40))
	fg.Parent = fill
	local shine = frame({ Parent = bar, Size = UDim2.fromScale(0.96, 0.34), Position = UDim2.fromScale(0.5, 0.1), AnchorPoint = Vector2.new(0.5, 0), BackgroundColor3 = WHITE, ZIndex = 5 })
	round(shine)
	local sg = Instance.new("UIGradient")
	sg.Rotation, sg.Transparency = 90, NumberSequence.new(0.5, 1)
	sg.Parent = shine
	local barText = label(bar, "ESCAPE", UDim2.fromScale(0.5, 0.74), UDim2.fromScale(0.5, 0.5), WHITE, 6)
	stroke(barText, Color3.fromRGB(60, 24, 90), 2)
	local hud = EscapeHUD.start({ gui = gui, calm = calm, keys = UIS.KeyboardEnabled }) -- the stopwatch chip, the gap meter, the warning chevrons
	local pips = {}
	for i = 1, 3 do
		local p = frame({ Size = UDim2.fromScale(0.022, 0.04), Position = UDim2.fromScale(0.5 - 0.03 + (i - 1) * 0.03, 0.115), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = BUTTER, BackgroundTransparency = 0.75, ZIndex = 3 })
		local a = Instance.new("UIAspectRatioConstraint")
		a.Parent = p
		round(p)
		stroke(p, Color3.fromRGB(255, 226, 120), 2) -- a lit gold rim: the dark outline vanished against the tunnel
		local glint = frame({ Parent = p, Size = UDim2.fromScale(0.5, 0.3), Position = UDim2.fromScale(0.5, 0.14), AnchorPoint = Vector2.new(0.5, 0), BackgroundColor3 = WHITE, BackgroundTransparency = 0.45, ZIndex = 4 })
		round(glint)
		pips[i] = p
	end
	local pipWord = label(gui, "BOOST", UDim2.fromScale(0.05, 0.026), UDim2.fromScale(0.5 - 0.085, 0.115), WHITE, 3) -- directive v8: the three circles had no name
	stroke(pipWord, INK, 2)
	local big = label(gui, "", UDim2.fromScale(0.5, 0.16), UDim2.fromScale(0.5, 0.42), WHITE, 6)
	local bigStroke = stroke(big, INK, 5)
	if C.UI_KIT == "glass" then -- the big words (3, 2, 1, ESCAPE!, BONK!) are jelly glass letters (the user, 2026-11-12)
		require(script.Parent:WaitForChild("JellyText")).mirror(big, { color = WHITE, glow = true, popOnChange = true, followColor = true })
	end
	local touch = UIS.TouchEnabled and not UIS.KeyboardEnabled
	local hint = label(gui, touch and "HOLD LEFT OR RIGHT TO LEAN, SWIPE UP TO JUMP, DOWN TO DUCK" or "LEAN  A / D    JUMP  SPACE    DUCK  S", UDim2.fromScale(0.6, 0.045), UDim2.fromScale(0.5, 0.83), WHITE, 4)
	local hintStroke = stroke(hint, INK, 2)
	local hintPlate = frame({ Size = UDim2.fromScale(0.64, 0.066), Position = UDim2.fromScale(0.5, 0.83), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Color3.fromRGB(24, 16, 46), BackgroundTransparency = 0.25, ZIndex = 3 }) -- a smoked-glass plate: the raw white line had nothing behind it (directive v8)
	round(hintPlate, 0.3)
	local hintEdge = stroke(hintPlate, Color3.fromRGB(214, 200, 255), 1.5)
	-- Directive v9: the controls as three jelly badges (a key cap and a word each) in place of the raw line of white text
	local badges
	if not touch then
		hint.Text = ""
		badges = Instance.new("CanvasGroup")
		badges.Name, badges.Size, badges.Position, badges.AnchorPoint, badges.BackgroundTransparency, badges.ZIndex = "Controls", UDim2.fromScale(0.46, 0.07), UDim2.fromScale(0.5, 0.83), Vector2.new(0.5, 0.5), 1, 4
		badges.Parent = gui
		for i, d in { { "A / D", "LEAN", Color3.fromRGB(0, 240, 255) }, { "SPACE", "JUMP", Color3.fromRGB(255, 214, 107) }, { "S", "DUCK", Color3.fromRGB(255, 79, 160) } } do
			local b = frame({ Parent = badges, Size = UDim2.fromScale(0.3, 0.9), Position = UDim2.fromScale(0.17 + (i - 1) * 0.33, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = WHITE, ZIndex = 4 })
			round(b, 0.4)
			stroke(b, d[3], 1.5)
			local g = Instance.new("UIGradient")
			g.Rotation, g.Color = 90, ColorSequence.new(Color3.fromRGB(75, 28, 113), Color3.fromRGB(36, 17, 56))
			g.Parent = b
			local dome = frame({ Parent = b, Size = UDim2.fromScale(0.92, 0.42), Position = UDim2.fromScale(0.5, 0.06), AnchorPoint = Vector2.new(0.5, 0), BackgroundColor3 = WHITE, ZIndex = 5 })
			round(dome, 0.5)
			local dg = Instance.new("UIGradient")
			dg.Rotation, dg.Transparency = 90, NumberSequence.new(0.55, 1)
			dg.Parent = dome
			local cap = frame({ Parent = b, Size = UDim2.fromScale(0.44, 0.66), Position = UDim2.fromScale(0.27, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = d[3], ZIndex = 6 })
			round(cap, 0.3)
			local kt = label(cap, d[1], UDim2.fromScale(0.86, 0.7), UDim2.fromScale(0.5, 0.5), Color3.fromRGB(36, 17, 56), 7)
			kt.Font = Enum.Font.FredokaOne
			local wt = label(b, d[2], UDim2.fromScale(0.44, 0.6), UDim2.fromScale(0.74, 0.5), WHITE, 6)
			wt.Font = Enum.Font.FredokaOne
		end
	end
	local flash = frame({ Size = UDim2.fromScale(1, 1), BackgroundColor3 = WHITE, BackgroundTransparency = 1, ZIndex = 8 })
	local soot = {} -- the Gloom closing in: the screen edges go sooty
	for i, e in { { UDim2.fromScale(1, 0.3), UDim2.fromScale(0, 0), 90 }, { UDim2.fromScale(1, 0.3), UDim2.fromScale(0, 0.7), -90 }, { UDim2.fromScale(0.25, 1), UDim2.fromScale(0, 0), 0 }, { UDim2.fromScale(0.25, 1), UDim2.fromScale(0.75, 0), 180 } } do
		local f = frame({ Size = e[1], Position = e[2], BackgroundColor3 = DARK, BackgroundTransparency = 1, ZIndex = 2 })
		local g = Instance.new("UIGradient")
		g.Rotation, g.Transparency = e[3], NumberSequence.new(0, 1)
		g.Parent = f
		soot[i] = f
	end

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

	-- the run, on the seeded path
	local P, YAW = buildPath(opt.seed or 1)
	local function pathCF(s)
		local i = math.clamp(math.floor(s / PIECE), 0, PATH_N + 3)
		return P[i]:Lerp(P[i + 1], math.clamp(s / PIECE - i, 0, 1))
	end
	for _, pc in tunnel.pieces do pc.m:PivotTo(pathCF((pc.k + 0.5) * PIECE) * CFrame.new(0, -0.5 - (pc.k % 2) * 0.03, 0)) end
	local CAV0, CAV1 = E.dist * 0.46, E.dist * 0.46 + 130 -- the cavern bridge set piece (redesign item 6)
	local function dress(pc) -- inside the cavern a piece keeps only its floor and rails, standing on a trestle
		local s = (pc.k + 0.5) * PIECE
		local open = s > CAV0 and s < CAV1
		if pc.open == open then return end
		pc.open = open
		for _, p in pc.m:GetChildren() do
			if p:IsA("BasePart") and p ~= pc.m.PrimaryPart and p.Name ~= "Trestle" and p.Size.Y > 0.6 and p.Size.X ~= 0.3 then
				p.LocalTransparencyModifier = open and 1 or 0
			end
		end
		if open and not pc.m:FindFirstChild("Trestle") then
			local root = pc.m.PrimaryPart
			for _, x in { -3.6, 3.6 } do part(pc.m, Vector3.new(0.9, 26, 0.9), root.CFrame * CFrame.new(x, -13.4, 0), BARK, { Name = "Trestle" }) end
			part(pc.m, Vector3.new(8.2, 0.7, 0.7), root.CFrame * CFrame.new(0, -6, 0), BARK_LT, { Name = "Trestle" })
		end
		for _, p in pc.m:GetChildren() do if p.Name == "Trestle" then p.LocalTransparencyModifier = open and 0 or 1 end end
	end
	for _, pc in tunnel.pieces do dress(pc) end
	do -- the cavern itself: giant crystals far below and around, the town's warm lights high above
		for k = 0, 9 do
			local s = CAV0 + 8 + k * 12
			local side = k % 2 == 0 and 1 or -1
			local cf = pathCF(s) * CFrame.new(side * rng:NextNumber(18, 34), rng:NextNumber(-26, -8), 0)
			local col = CRYSTAL[k % #CRYSTAL + 1]
			for q = 0, 2 do
				part(world, Vector3.new(2.4, rng:NextNumber(6, 12), 2.4), cf * CFrame.new(q * 2 - 2, 0, (q % 2) * 2) * CFrame.Angles(rng:NextNumber(-0.4, 0.4), q, rng:NextNumber(-0.4, 0.4)), col:Lerp(Color3.new(1, 1, 1), 0.2), { Material = q == 1 and Enum.Material.Neon or Enum.Material.Glass, Transparency = q == 1 and 0 or 0.2 })
			end
			local l = Instance.new("PointLight")
			l.Color, l.Range, l.Brightness = col, 26, 1.3
			l.Parent = world:GetChildren()[#world:GetChildren()]
		end
		-- demo audit 12: the bridge crossed an open void. The cavern has rock now: side walls, a roof, a glowing lake far below
		-- and an end wall at each tunnel mouth (a hole just the tunnel's size), with dim fill lights so the far rock reads.
		local midCF = pathCF(CAV0 + 65)
		local R = CFrame.new(midCF.Position) * CFrame.Angles(0, select(2, midCF:ToOrientation()), 0)
		local ROCKP = { Material = Enum.Material.Slate, MaterialVariant = "PixelCaveRock" }
		for _, sx in { -1, 1 } do part(world, Vector3.new(6, 156, 440), R * CFrame.new(sx * 96, 26, 0), ROCKC[2], ROCKP) end
		part(world, Vector3.new(204, 6, 440), R * CFrame.new(0, 102, 0), ROCKC[1], ROCKP)
		part(world, Vector3.new(204, 4, 440), R * CFrame.new(0, -50, 0), ROCKC[1], ROCKP)
		part(world, Vector3.new(190, 1, 430), R * CFrame.new(0, -46, 0), Color3.fromRGB(26, 96, 116), { Material = Enum.Material.Neon, Transparency = 0.15 })
		for _, s in { CAV0 - 1, CAV1 + 1 } do
			local ecf = pathCF(s)
			for _, sx in { -1, 1 } do part(world, Vector3.new(300, 170, 5), ecf * CFrame.new(sx * 155.7, 26, 0), ROCKC[2], ROCKP) end
			part(world, Vector3.new(11.4, 100, 5), ecf * CFrame.new(0, 61, 0), ROCKC[2], ROCKP)
			part(world, Vector3.new(11.4, 58, 5), ecf * CFrame.new(0, -30.4, 0), ROCKC[2], ROCKP)
		end
		for _, sx in { -1, 1 } do
			for _, z in { -45, 45 } do
				local l = Instance.new("PointLight")
				l.Color, l.Range, l.Brightness = sx < 0 and Color3.fromRGB(120, 210, 230) or Color3.fromRGB(190, 160, 255), 60, 1.3
				l.Parent = part(world, Vector3.one, R * CFrame.new(sx * 78, 6, z), WHITE, { Transparency = 1 })
			end
		end
		for k = 0, 5 do -- the town's lanterns, small and warm, far overhead
			part(world, Vector3.new(1.2, 1.2, 1.2), pathCF(CAV0 + 20 + k * 18) * CFrame.new(rng:NextNumber(-40, 40), rng:NextNumber(60, 80), rng:NextNumber(-20, 20)), Color3.fromRGB(255, 214, 150), { Material = Enum.Material.Neon })
		end
	end
	local atmo = Lighting:FindFirstChildOfClass("Atmosphere") -- thinned so every obstacle reads 0.9 s ahead
	local atmoDensity = atmo and atmo.Density
	if atmo then atmo.Density = math.min(atmo.Density, 0.14) end
	local jumpT, duckUntil, jumpY, duckY = -10, 0, 0, 0
	local gloom = { gap = 1, caught = false } -- the Gloom pursuer (redesign item 5): 1 = far behind, 0 = it has you
	local JUMP_T, JUMP_H = 0.6, 2.6
	local taught = {}
	local dist, speed, t, lean, roll = 0, 0, -3.2, 0, 0
	local function jump() if t > 0 and os.clock() - jumpT > JUMP_T then jumpT = os.clock() play("whoosh", 1.5) end end
	local function duck() if t > 0 then duckUntil = os.clock() + 0.7 end end
	table.insert(cons, UIS.InputBegan:Connect(function(input)
		local k = input.KeyCode
		if k == Enum.KeyCode.Space or k == Enum.KeyCode.ButtonA or k == Enum.KeyCode.W or k == Enum.KeyCode.Up then jump()
		elseif k == Enum.KeyCode.S or k == Enum.KeyCode.Down or k == Enum.KeyCode.C or k == Enum.KeyCode.ButtonB then duck() end
	end))
	local swipe = {}
	table.insert(cons, UIS.TouchStarted:Connect(function(tch) swipe[tch] = { tch.Position, os.clock() } end))
	table.insert(cons, UIS.TouchEnded:Connect(function(tch)
		local s0 = swipe[tch]
		swipe[tch] = nil
		if not s0 then return end
		local d = tch.Position - s0[1]
		if os.clock() - s0[2] < 0.4 and math.abs(d.Y) > 50 and math.abs(d.Y) > math.abs(d.X) * 1.3 then
			if d.Y < 0 then jump() else duck() end
		end
	end))
	local boosts, boostUntil, slowUntil, dodges, hits = 0, {}, 0, 0, 0
	local hazards, nextSpawn = {}, 1.2
	local forks = 0 -- forks passed (roadmap pt2_22): twice a run the lanes offer a choice, gold with a rock or a clear side
	local shakeAmp, phase, done, resultAt, bonus = 0, "run", false, nil, nil
	local runTime, landed, card = 0, false, nil
	local lastCount = 4
	local function laneX() return lean * 1.6 end
	-- A warning board beside the rail, 30 studs ahead of a hazard: one jelly word on smoked glass, standing in the tunnel
	-- (directive v8: "rail-side warning signs"). side: -1 left wall, 1 right wall. It is part of the world, so it is cleaned
	-- up with it. Only with the cut-glass kit.
	local JellyText = C.UI_KIT == "glass" and require(script.Parent:WaitForChild("JellyText"))
	local function warnBoard(at, word, color, side)
		if not JellyText or calm then return end
		local cf = pathCF(math.max(at - 30, 2)) * CFrame.new(side * 3.0, 3.3, 0)
		local board = part(world, Vector3.new(3.8, 1.6, 0.12), CFrame.lookAt(cf.Position, pathCF(math.max(at - 48, 0)).Position + Vector3.new(0, 3.3, 0)), Color3.fromRGB(46, 32, 92), { Material = Enum.Material.Glass, Transparency = 0.1 })
		part(world, Vector3.new(0.16, 3, 0.16), board.CFrame * CFrame.new(0, -2.1, 0.1), Color3.fromRGB(70, 52, 60), {})
		local sg = Instance.new("SurfaceGui")
		sg.Face, sg.SizingMode, sg.PixelsPerStud, sg.LightInfluence, sg.Brightness = Enum.NormalId.Front, Enum.SurfaceGuiSizingMode.PixelsPerStud, 60, 0, 1.6
		sg.Parent = board
		local holder = Instance.new("Frame")
		holder.Size, holder.Position, holder.AnchorPoint, holder.BackgroundTransparency = UDim2.fromScale(0.9, 0.8), UDim2.fromScale(0.5, 0.5), Vector2.new(0.5, 0.5), 1
		holder.Parent = sg
		JellyText.new(holder, word, { color = color, sway = false })
		local l = Instance.new("PointLight")
		l.Color, l.Range, l.Brightness, l.Parent = color, 7, 0.8, board
	end
	local function spawnRock(lane, at, threat)
		local x = LANES[lane]
		local here = pathCF(at)
		local ring = part(world, Vector3.new(0.15, 3, 3), here * CFrame.new(x, 0.35, 0) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(255, 60, 90), { Shape = Enum.PartType.Cylinder, Material = Enum.Material.Neon, Transparency = 0.1 })
		local rock = Instance.new("Model")
		local r1 = part(rock, Vector3.new(2.6, 2.1, 2.4), here * CFrame.new(x, 9, 0) * CFrame.Angles(0.3, 0.6, 0.2), ROCKC[3], { Material = Enum.Material.Slate, MaterialVariant = "PixelCaveRock" })
		part(rock, Vector3.new(1.7, 1.4, 1.7), r1.CFrame * CFrame.new(0.7, 0.7, -0.4) * CFrame.Angles(0.4, 0.2, 0.5), ROCKC[2], { Material = Enum.Material.Slate, MaterialVariant = "PixelCaveRock" })
		for k = 1, 2 do -- glowing pink cracks so a falling rock reads at a glance (Gemini r1)
			part(rock, Vector3.new(0.18, 2.3, 0.18), r1.CFrame * CFrame.new(k == 1 and -0.5 or 0.6, 0, -1.22) * CFrame.Angles(0, 0, k == 1 and 0.5 or -0.4), Color3.fromRGB(255, 119, 168), { Material = Enum.Material.Neon })
		end
		rock.PrimaryPart = r1
		rock.Parent = world
		table.insert(hazards, { kind = "rock", lane = lane, at = at, ring = ring, rock = rock, base = r1.CFrame, threat = threat })
	end
	local function spawnOrb(lane, at)
		-- a boost pickup. Directive v9: the 1.3 stud butter ball read as a big opaque sphere blocking the rail right before the
		-- cart. Now a small clear bead inside a thin ring with chevrons, so the rail shows through it.
		local orb = part(world, Vector3.new(0.7, 0.7, 0.7), pathCF(at) * CFrame.new(LANES[lane], 2.6, 0), BUTTER, { Shape = Enum.PartType.Ball, Material = Enum.Material.Glass, Transparency = 0.55 })
		local ol = Instance.new("PointLight")
		ol.Color, ol.Range, ol.Brightness, ol.Parent = BUTTER, 7, 0.9, orb
		local bb = Instance.new("BillboardGui")
		bb.Size, bb.LightInfluence, bb.AlwaysOnTop, bb.MaxDistance = UDim2.fromScale(1.9, 1.9), 0, false, 140
		local ringF = Instance.new("Frame")
		ringF.Size, ringF.Position, ringF.AnchorPoint, ringF.BackgroundTransparency = UDim2.fromScale(0.86, 0.86), UDim2.fromScale(0.5, 0.5), Vector2.new(0.5, 0.5), 1
		round(ringF, 0.5)
		stroke(ringF, BUTTER, 2.5)
		ringF.Parent = bb
		local chev = Instance.new("TextLabel")
		chev.Size, chev.Position, chev.AnchorPoint, chev.BackgroundTransparency = UDim2.fromScale(0.6, 0.6), UDim2.fromScale(0.5, 0.48), Vector2.new(0.5, 0.5), 1
		chev.Text, chev.TextScaled, chev.Font, chev.TextColor3, chev.TextStrokeTransparency, chev.TextStrokeColor3 = ">>", true, Enum.Font.FredokaOne, Color3.new(1, 1, 1), 0.2, Color3.fromRGB(150, 90, 10)
		chev.Parent = bb
		bb.Parent = orb
		local e = Instance.new("ParticleEmitter")
		e.Texture, e.Rate, e.LightEmission, e.Color = SPARK, 8, 1, ColorSequence.new(BUTTER, PINK)
		e.Size, e.Lifetime, e.Speed = NumberSequence.new(0.4, 0), NumberRange.new(0.4, 0.7), NumberRange.new(1, 2)
		e.Parent = orb
		table.insert(hazards, { kind = "orb", lane = lane, at = at, orb = orb })
	end
	local TAPE = Color3.fromRGB(255, 210, 80)
	local function spawnBeam(at) -- a low timber across the tunnel in warning stripes, a lantern swinging from it: DUCK
		local here = pathCF(at)
		local m = Instance.new("Model")
		-- a low timber beam (Gemini r5: the neon striped bar read as a placeholder): a split log banded in iron, two red flare lanterns hanging from it
		part(m, Vector3.new(9.6, 0.9, 0.9), here * CFrame.new(0, 3.35, 0), BARK_LT, { Material = Enum.Material.Wood })
		part(m, Vector3.new(3.2, 0.5, 0.7), here * CFrame.new(-2.2, 2.85, 0.05) * CFrame.Angles(0, 0, 0.12), BARK, { Material = Enum.Material.Wood }) -- a splintered half hanging lower
		for _, x in { -3.4, 0, 3.4 } do part(m, Vector3.new(0.5, 1.0, 1.0), here * CFrame.new(x, 3.35, 0), Color3.fromRGB(58, 52, 72), { Material = Enum.Material.Metal }) end
		for _, x in { -1.7, 3.0 } do
			part(m, Vector3.new(0.08, 0.5, 0.08), here * CFrame.new(x, 2.65, 0), INK)
			part(m, Vector3.new(0.34, 0.42, 0.34), here * CFrame.new(x, 2.25, 0), Color3.fromRGB(255, 84, 96), { Material = Enum.Material.Neon })
		end
		for _, s in { -1, 1 } do part(m, Vector3.new(0.8, 3.4, 0.8), here * CFrame.new(s * 4.75, 1.7, 0), BARK) end
		local lamp = CartFX.lantern(part(m, Vector3.new(0.6, 0.8, 0.6), here * CFrame.new(1.8, 2.45, 0), Color3.fromRGB(255, 196, 120)))
		local l = Instance.new("PointLight")
		l.Color, l.Range, l.Brightness = Color3.fromRGB(255, 196, 120), 14, 1.4
		l.Parent = lamp
		m.Parent = world
		warnBoard(at, "DUCK!", Color3.fromRGB(255, 120, 190), 1)
		table.insert(hazards, { kind = "beam", lane = 0, at = at, model = m, lamp = lamp, lampBase = lamp.CFrame })
	end
	local function spawnGap(at, lane) -- buckled rails curling up over a dark crack (one lane, or all three): JUMP
		local here = pathCF(at)
		local m = Instance.new("Model")
		local xs = lane == 0 and { -1.6, 0, 1.6 } or { LANES[lane] }
		for _, x in xs do
			part(m, Vector3.new(2.4, 0.08, 2.6), here * CFrame.new(x, 0.06, 0), DARK)
			part(m, Vector3.new(2.4, 0.1, 0.12), here * CFrame.new(x, 0.12, -1.3), Color3.fromRGB(90, 230, 220), { Material = Enum.Material.Neon })
			for _, s in { -1, 1 } do -- the two rail ends bent up into a hump
				part(m, Vector3.new(0.3, 0.3, 1.8), here * CFrame.new(x + s * 0.7, 0.9, 0.5) * CFrame.Angles(0.7, 0, s * 0.12), RAIL, { Material = Enum.Material.Metal })
				part(m, Vector3.new(0.3, 0.3, 1.6), here * CFrame.new(x + s * 0.7, 0.85, -0.7) * CFrame.Angles(-0.8, 0, -s * 0.1), RAIL, { Material = Enum.Material.Metal })
			end
			part(m, Vector3.new(1.8, 0.3, 0.5), here * CFrame.new(x, 0.35, 1.4) * CFrame.Angles(0, 0.4, 0.25), BARK_LT) -- a split sleeper
		end
		m.Parent = world
		warnBoard(at, "JUMP!", Color3.fromRGB(110, 215, 255), -1)
		table.insert(hazards, { kind = "gap", lane = lane, at = at, model = m })
	end
	local function spawnCart(at, lane) -- a rusty parked cart with a gloomling peeking out: LEAN (or JUMP it)
		local here = pathCF(at) * CFrame.new(LANES[lane], 0, 0)
		local m = Instance.new("Model")
		local rust = Color3.fromRGB(150, 92, 76)
		part(m, Vector3.new(2.6, 1.6, 3.0), here * CFrame.new(0, 1.15, 0), rust, { Material = Enum.Material.Metal })
		part(m, Vector3.new(2.8, 0.3, 3.2), here * CFrame.new(0, 2.05, 0), rust:Lerp(INK, 0.3), { Material = Enum.Material.Metal })
		for _, x in { -1.05, 1.05 } do for _, z in { -0.9, 0.9 } do part(m, Vector3.new(0.4, 0.7, 0.7), here * CFrame.new(x, 0.35, z), INK) end end
		part(m, Vector3.new(1.3, 1.1, 1.3), here * CFrame.new(0, 2.5, 0.2), DARK, { Shape = Enum.PartType.Ball })
		for _, x in { -0.25, 0.25 } do part(m, Vector3.new(0.22, 0.28, 0.1), here * CFrame.new(x, 2.65, -0.42), Color3.fromRGB(255, 240, 200), { Material = Enum.Material.Neon }) end
		m.Parent = world
		warnBoard(at, LANES[lane] < 0 and "RIGHT >" or (LANES[lane] > 0 and "< LEFT" or "LEAN!"), Color3.fromRGB(255, 205, 80), LANES[lane] < 0 and 1 or -1) -- the board stands on the side to lean to
		table.insert(hazards, { kind = "cart", lane = lane, at = at, model = m })
	end
	local function cleanup(h)
		for _, k in { "ring", "rock", "orb", "model" } do if h[k] then h[k]:Destroy() end end
	end
	local WARN = { rock = { "rumble", 1.4 }, beam = { "creak", 1.1 }, gap = { "screech", 1.5 }, cart = { "thud", 0.7 } }
	local TEACH = {
		beam = touch and "DUCK!  SWIPE DOWN" or "DUCK!  PRESS S",
		gap = touch and "JUMP!  SWIPE UP" or "JUMP!  PRESS SPACE",
		cart = touch and "LEAN AWAY OR JUMP IT!" or "LEAN AWAY OR JUMP IT!",
	}
	local function wave(p) -- the speed wave (redesign item 4): calm, build, a gold-rush breather, the climax
		if p < 0.15 then return 0.9 end
		if p < 0.45 then return 0.9 + (p - 0.15) / 0.3 * 0.25 end
		if p < 0.6 then return 1.15 end
		if p < 0.7 then return 1.08 end
		return math.min(E.top or 1.45, 1.2 + (p - 0.7) / 0.3 * 0.25)
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
				hud.pop(big)
				sfx("click", 1 + (3 - count) * 0.15)
			elseif t >= 0 and lastCount > 0 then
				lastCount = 0
				big.Text = "ESCAPE!"
				hud.pop(big)
				sfx("upgrade", 1.1)
				play("whoosh", 1)
				snd.clack:Play()
				snd.wind:Play()
			end
			big.TextTransparency = t < 0 and 0 or smooth(0.5, 0.9, t)
			bigStroke.Transparency = big.TextTransparency
			hint.TextTransparency = smooth(4, 5, t)
			hintStroke.Transparency = hint.TextTransparency
			hintPlate.BackgroundTransparency, hintEdge.Transparency = 0.25 + 0.75 * hint.TextTransparency, hint.TextTransparency
			if badges then
				badges.GroupTransparency = hint.TextTransparency
				hintPlate.BackgroundTransparency, hintEdge.Transparency = 1, 1
			end
			-- speed: base, boosts stack, a bonk halves it
			local live = 0
			for i = #boostUntil, 1, -1 do if now < boostUntil[i] then live += 1 else table.remove(boostUntil, i) end end
			local target = t < 0 and 0 or E.speed * wave(dist / E.dist) * (1 + 0.2 * live) * (now < slowUntil and 0.5 or 1)
			speed += (target - speed) * (1 - math.exp(-dt / 0.25))
			dist += speed * dt
			for i, p in pips do p.BackgroundTransparency = i <= live and 0 or 0.75 end
			-- lean with a little spring
			local want = steer()
			lean += (want - lean) * (1 - math.exp(-dt / 0.08))
			roll += ((calm and 0 or -want * 0.052) - roll) * (1 - math.exp(-dt / 0.1))
			-- spawn ahead: rocks every 1.1-1.6 s (two lanes at once later on), an orb now and then
			if t > 0 and t >= nextSpawn and dist < E.dist - 80 then
				local p = dist / E.dist
				local ahead = dist + math.max(speed, E.speed) * 1.8
				local cur = lean < -0.5 and 1 or (lean > 0.5 and 3 or 2)
				local kind
				if p > 0.6 and p < 0.7 then kind = "orbs" -- the breather: a gold rush
				elseif not taught.beam and t > 6 then kind = "beam" -- each new verb alone once, with a hint
				elseif not taught.gap and t > 9.5 then kind = "gap"
				elseif not taught.cart and t > 13 then kind = "cart"
				elseif taught.cart and ((p > 0.28 and forks == 0) or (p > 0.8 and forks == 1)) then kind = "fork"
				elseif t < 6 then kind = "rock"
				else
					local r = rng:NextNumber()
					kind = r < 0.4 and "rock" or (r < 0.6 and "beam" or (r < 0.8 and "gap" or "cart"))
				end
				if kind == "orbs" then
					local l = rng:NextInteger(1, 3)
					for k = 0, 3 do
						spawnOrb(l, ahead + k * 5)
						l = math.clamp(l + rng:NextInteger(-1, 1), 1, 3)
					end
				elseif kind == "rock" then
					local lane = rng:NextNumber() < 0.6 and cur or rng:NextInteger(1, 3) -- most rocks aim at you
					spawnRock(lane, ahead, lane == cur)
					if p > 0.45 and rng:NextNumber() < 0.35 then
						local l2 = lane % 3 + 1
						spawnRock(l2, ahead, l2 == cur)
					end
				elseif kind == "fork" then -- a signpost, the middle blocked by a cart: one side is a line of gold orbs ending in a rock, the other is clear
					forks += 1
					local gold = rng:NextNumber() < 0.5 and 1 or 3
					local post = pathCF(ahead - 5)
					part(world, Vector3.new(0.5, 4.6, 0.5), post * CFrame.new(0, 2.3, 0), BARK)
					part(world, Vector3.new(2.4, 1.1, 0.3), post * CFrame.new(LANES[gold] * 0.6, 4.1, 0), BUTTER, { Material = Enum.Material.Neon })
					part(world, Vector3.new(2.4, 1.1, 0.3), post * CFrame.new(-LANES[gold] * 0.6, 4.1, 0), MINT, { Material = Enum.Material.Neon })
					spawnCart(ahead + 6, 2)
					if not taught.fork then hazards[#hazards].teach = "FORK!  GOLD SIDE: ORBS, THEN A ROCK.  MINT SIDE: CLEAR" end
					taught.fork = true
					for k = 0, 3 do spawnOrb(gold, ahead + 6 + k * 5) end
					spawnRock(gold, ahead + 32, false)
				elseif kind == "beam" then
					spawnBeam(ahead)
				elseif kind == "gap" then
					spawnGap(ahead, (not taught.gap or p > 0.7 and rng:NextNumber() < 0.5) and 0 or cur)
				else
					spawnCart(ahead, taught.cart and cur or 2)
				end
				if TEACH[kind] and not taught[kind] then hazards[#hazards].teach = TEACH[kind] end
				taught[kind] = true
				if kind ~= "orbs" and rng:NextNumber() < 0.45 then spawnOrb(rng:NextInteger(1, 3), ahead + math.max(speed, E.speed) * 0.6) end
				local dens = p < 0.15 and 1.15 or (p < 0.6 and 1 - (p - 0.15) * 0.33 or (p < 0.7 and 0.8 or 0.75))
				nextSpawn = t + rng:NextNumber(1.1, 1.6) * dens
			end
			-- verbs: the jump is a sine hop, the duck drops the eye
			local ju = (now - jumpT) / JUMP_T
			jumpY = (ju >= 0 and ju <= 1) and math.sin(ju * math.pi) * JUMP_H or 0
			local ducking = now < duckUntil
			duckY += ((ducking and 1.4 or 0) - duckY) * (1 - math.exp(-dt / 0.06))
			-- hazards: rocks drop to land as the cart arrives; passing a lane checks the lean
			local myLane = lean < -0.5 and 1 or (lean > 0.5 and 3 or 2)
			local warnDir, warnGap = nil, math.max(speed, 1) * 1.3 -- the nearest thing that will hit within 1.3 s says what to do (0.9 measured as 0.58 to 0.85 s on screen, mean 0.76: too short to read and lean)
			for i = #hazards, 1, -1 do
				local h = hazards[i]
				local gap = h.at - dist
				if h.kind ~= "orb" and not h.passed and gap > 0 and gap < warnGap then
					local mine = h.lane == myLane or h.lane == 0
					if h.kind == "beam" then
						warnGap, warnDir = gap, now < duckUntil and nil or "down"
					elseif mine and (h.kind == "gap" or h.lane == 0) then
						warnGap, warnDir = gap, jumpY > 0 and nil or "up"
					elseif mine then
						local side = myLane == 3 and "left" or "right"
						if myLane == 2 then -- from the middle: lean away from a second hazard beside this one
							for _, o in hazards do
								if o ~= h and o.kind ~= "orb" and o.lane == 3 and math.abs(o.at - h.at) < 8 then side = "left" end
							end
						end
						warnGap, warnDir = gap, side
					end
				end
				if h.kind == "rock" then
					local fall = 1 - math.clamp(gap / math.max(speed * 0.6, 8), 0, 1) -- the last 0.6 s: falls from the ceiling
					h.rock:PivotTo(h.base * CFrame.new(0, -fall * 8, 0) * CFrame.Angles(fall * 2, 0, fall))
					h.ring.Transparency = 0.05 + 0.4 * (0.5 + 0.5 * math.sin(now * 18))
				elseif h.kind == "orb" then
					h.orb.CFrame = pathCF(h.at) * CFrame.new(LANES[h.lane], 2.6 + math.sin(now * 4 + h.at) * 0.3, 0)
				elseif h.kind == "beam" then
					h.lamp.CFrame = h.lampBase * CFrame.Angles(0, 0, math.sin(now * 3 + h.at) * 0.25)
				end
				if not h.warned and h.kind ~= "orb" and gap < math.max(speed, 1) * 1.05 then -- a sound a second ahead, a hint the first time
					h.warned = true
					local w = WARN[h.kind]
					if w then play(w[1], w[2]) end
					if h.teach then
						big.Text, big.TextTransparency, big.TextColor3 = h.teach, 0, BUTTER
						bigStroke.Transparency = 0
						task.delay(1.1, function() big.TextTransparency = 1 bigStroke.Transparency = 1 big.TextColor3 = WHITE end)
					end
				end
				local inLane = h.lane == myLane or h.lane == 0
				local struck
				if h.kind == "beam" then struck = not ducking
				elseif h.kind == "gap" then struck = inLane and jumpY < 0.9
				elseif h.kind == "cart" then struck = inLane and jumpY < 1.5
				else struck = inLane end
				if gap < 0.8 and not h.passed then
					h.passed = true
					if struck then
						if h.kind ~= "orb" then
							hits += 1
							hud.hit(now)
							slowUntil = now + 1.5
							shakeAmp = calm and 0 or 0.5
							play("bonk", 1)
							big.Text, big.TextTransparency, big.TextColor3 = "BONK!", 0, PINK
							bigStroke.Transparency = 0
							task.delay(0.6, function() big.TextTransparency = 1 bigStroke.Transparency = 1 big.TextColor3 = WHITE end)
							vignette.BackgroundTransparency = 0.6
							gloom.gap = math.max(0, gloom.gap - 0.35) -- a stumble lets the Gloom close in
						else
							boosts += 1
							table.insert(boostUntil, now + 1.5)
							if #boostUntil > 3 then table.remove(boostUntil, 1) end
							sfx("sparkle", 1 + #boostUntil * 0.1)
							play("whoosh", 1.3)
						end
						cleanup(h)
						table.remove(hazards, i)
					elseif (h.kind == "rock" and h.threat) or h.kind == "beam" or ((h.kind == "gap" or h.kind == "cart") and h.lane ~= myLane and h.lane ~= 0 and h.threat) or ((h.kind == "gap" or h.kind == "cart") and (h.lane == myLane or h.lane == 0)) then
						dodges += 1 -- it was coming for you and you answered it
					end
				end
				if gap < -6 and hazards[i] == h then
					cleanup(h)
					table.remove(hazards, i)
				end
			end
			vignette.BackgroundTransparency = math.min(1, vignette.BackgroundTransparency + dt * 1.2)
			if t > 0 then -- the Gloom: falls back slowly, faster on boosts; at 0 it nips you once
				gloom.gap = math.min(1, gloom.gap + dt * (live > 0 and 0.1 or 0.045))
				if gloom.gap <= 0.02 and not gloom.caught then
					gloom.caught = true
					big.Text, big.TextTransparency, big.TextColor3 = "THE GLOOM NIPPED YOU!", 0, Color3.fromRGB(190, 150, 240)
					bigStroke.Transparency = 0
					task.delay(1.2, function() big.TextTransparency = 1 bigStroke.Transparency = 1 big.TextColor3 = WHITE end)
					shakeAmp = calm and 0 or 0.6
					play("bonk", 0.6)
				end
			end
			local near = 1 - gloom.gap
			for _, f in soot do f.BackgroundTransparency = 1 - near * (0.75 + 0.1 * math.sin(now * 7)) end
			hud.gap(gloom.gap, now)
			hud.warn(t > 0 and warnDir or nil, now)
			snd.rumble.Volume = 0.15 + near * 0.6
			local inCav = dist > CAV0 and dist < CAV1
			if atmo then atmo.Density = inCav and 0.05 or math.min(atmoDensity or 0.14, 0.14) end
			-- recycle tunnel pieces that fell behind
			for _, pc in tunnel.pieces do
				if pc.k * PIECE < dist - 8 then
					pc.k += NPIECE
					pc.m:PivotTo(pathCF((pc.k + 0.5) * PIECE) * CFrame.new(0, -0.5 - (pc.k % 2) * 0.03, 0))
					dress(pc)
				end
			end
			tunnel.exit.CFrame = pathCF(E.dist + 6) * CFrame.new(0, 4.5, 0)
			fill.Size = UDim2.fromScale(math.clamp(dist / E.dist, 0, 1), 1)
			barText.Text = string.format("ESCAPE  %d%%", math.clamp(math.floor(dist / E.dist * 100), 0, 100))
			hud.time(t)
			for _, e in sparks do e.Rate = (live > 0 or now < slowUntil) and 30 or 0 end
			snd.clack.Volume = t > 0 and 0.2 + math.min(speed / 48, 1) * 0.4 or 0
			snd.clack.PlaybackSpeed = 0.7 + math.min(speed / 48, 1) * 0.8
			snd.wind.Volume = math.min(speed / 48, 1) * 0.5
			flash.BackgroundTransparency = 1 - smooth(E.dist - 25, E.dist, dist)
			-- camera: first person in the cart, leaning
			local base = pathCF(dist)
			local bank = calm and 0 or math.clamp(-(YAW[math.floor(dist / PIECE)] or 0) * 2.5, -math.rad(3), math.rad(3)) -- the camera rolls only on bends, 3 degrees at most (comfort); the cart body leans four times as far, to 12
			local tie = math.floor(dist / 2)
			if tie ~= lastTie then -- the chassis bounces on its springs over each rail tie
				lastTie = tie
				if not calm and jumpY == 0 then bounce.kick(0.35 + math.min(speed / 48, 1) * 0.8) end
			end
			local by = calm and 0 or bounce.step(dt)
			local cartCF = base * CFrame.new(laneX(), jumpY + by, 0) * CFrame.Angles(by * 0.25, 0, roll * 0.6 + bank * 4)
			cart:PivotTo(cartCF)
			shakeAmp = math.max(0, shakeAmp - dt * 1.2)
			local sh = calm and 0 or shakeAmp + math.min(speed / 48, 1) * 0.02
			cam.CameraType = Enum.CameraType.Scriptable
			local eye = (base * CFrame.new(laneX() * 0.9, 3.8 + jumpY * 0.85 - duckY, 0.6)).Position
			local look = (pathCF(dist + 7) * CFrame.new(laneX() * 0.4, 3.0 + jumpY * 0.5 - duckY * 0.5, 0)).Position -- looks into the bend before it arrives
			cam.CFrame = CFrame.lookAt(eye, look, base.UpVector) * CFrame.Angles(0, 0, roll + bank) * CFrame.Angles((math.random() - 0.5) * sh * 0.06, (math.random() - 0.5) * sh * 0.06, 0)
			cam.FieldOfView = C.FP_FOV + (calm and 0 or math.min(#boostUntil, 3) * 3 + math.clamp(speed / 48, 0, 1) * 5) -- widens with speed and with each boost
			air.step(cam.CFrame, speed, calm)
			speedLines(now, calm and 0 or math.clamp((speed - 30) / 18, 0, 1)) -- streaks at the screen edges as the cart picks up speed
			if dist >= E.dist then -- out of the tunnel: tell the server, wait for it to move us to town, then burst out of the shaft
				phase = "wait"
				resultAt, runTime = t, t
				Lighting.Ambient, Lighting.OutdoorAmbient = amb.a, amb.o -- the cave look back before the server switches us to town
				for _, e in sparks do e.Rate = 0 end
				snd.clack:Stop()
				snd.wind:Stop()
				for _, h in hazards do cleanup(h) end
				hazards = {}
				if opt.report then opt.report({ time = t, dodges = dodges, boosts = boosts, hits = hits, caught = gloom.caught }) end
			end
		elseif phase == "wait" then
			flash.BackgroundTransparency = 0
			bonus = opt.result and opt.result()
			if bonus or t - resultAt > 4 then
				phase = "town"
				resultAt = t
				bar.Visible, hint.Visible, hintPlate.Visible, pipWord.Visible = false, false, false, false
				hud.hide()
				for _, f in soot do f.BackgroundTransparency = 1 end
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
				local rows = { { "TIME", string.format("%.1f s", runTime) }, { "DODGES", tostring(dodges) }, { gloom.caught and "THE GLOOM" or "BOOSTS", gloom.caught and "NIPPED YOU" or tostring(boosts) }, { "BONUS", "+" .. tostring(bonus or 0) .. " COINS" } }
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
	if atmo and atmoDensity then atmo.Density = atmoDensity end
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
