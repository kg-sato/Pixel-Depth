-- StarterPlayerScripts.PixelClient: cameras (bird's-eye in the camp hub, first person in the mine), digging input, the pastel HUD
-- (layout from the Claude Design board HUD/Forge artboards, pastel kit art/ui_pastel), juice FX, hatch show, crew followers,
-- rarity tags and the hub's idle animations.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local C = require(RS:WaitForChild("Shared"):WaitForChild("Config"))
local PixelText = require(RS.Shared:WaitForChild("PixelText")) -- Pixelify Sans bitmap font
local R = RS:WaitForChild("Remotes")

local plr = Players.LocalPlayer
local cam = workspace.CurrentCamera
local B = C.B
local state, blocks
local hatchBusy, inMine = false, false
local inCave = false -- in the shared caves (cave rework): first person, torch and fear, no block digging

local function hrp()
	local ch = plr.Character
	return ch and ch:FindFirstChild("HumanoidRootPart")
end
local function head()
	local ch = plr.Character
	return ch and (ch:FindFirstChild("Head") or ch:FindFirstChild("HumanoidRootPart"))
end
local function tween(o, t, props, style, dir)
	local tw = TweenService:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end
local function layerOf(r)
	return math.clamp(math.ceil(r / C.LAYER_ROWS), 1, #C.LAYERS)
end
local function rarityColor(name)
	for _, t in C.RARITIES do
		if t[1] == name then return t[3] end
	end
	return Color3.new(1, 1, 1)
end
local function commas(n)
	local s = tostring(math.floor(n))
	local out = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	return out:sub(1, 1) == "," and out:sub(2) or out
end

-- Soft pastel UI kit v3 (art/ui_soft from art/pd_ui_soft.py, 2026-11-08; the user: the pixel style did not fit the HUD).
-- Refs: art/ui_soft/refs.md (casual soft GUI kits and three local FLUX sheets): rounded glossy shapes, outlines in a deeper shade
-- of their own colour, a white rim on top, a darker lip below, soft plum shadows. SLICE is each skin's 9-slice centre in image pixels.
local SKIN = {
	panel = "rbxassetid://113415316875605", card = "rbxassetid://81633677346028", pill = "rbxassetid://119090200856398", dark = "rbxassetid://121498621263299",
	mint = "rbxassetid://83808029416788", pink = "rbxassetid://136217450602282", lilac = "rbxassetid://77616401786163", butter = "rbxassetid://83179311853804",
	sky = "rbxassetid://128441056159318", off = "rbxassetid://111104085286106", keycap = "rbxassetid://139715689953072", keycapDown = "rbxassetid://125800119532458",
	slot = "rbxassetid://93694333526600", tab = "rbxassetid://123295883549695", tabOn = "rbxassetid://124239785302537", ribbonPink = "rbxassetid://91362224784143",
	ribbonLilac = "rbxassetid://138043867629077",
	pillButter = "rbxassetid://89904114967253", pillLilac = "rbxassetid://129953065739484", pillMint = "rbxassetid://86008192630288", pillPink = "rbxassetid://103351763502280", -- puffy tone-on-tone pills (kit round 4)
}
local SLICE = {
	panel = { 64, 64, 136, 126 }, card = { 50, 50, 126, 78 }, pill = { 40, 31, 136, 37 }, dark = { 36, 36, 76, 64 },
	mint = { 42, 40, 118, 52 }, pink = { 42, 40, 118, 52 }, lilac = { 42, 40, 118, 52 }, butter = { 42, 40, 118, 52 },
	sky = { 42, 40, 118, 52 }, off = { 42, 40, 118, 52 }, keycap = { 24, 24, 48, 44 }, keycapDown = { 24, 24, 48, 50 },
	slot = { 32, 32, 72, 72 }, tab = { 38, 36, 98, 46 }, tabOn = { 38, 36, 98, 46 }, ribbonPink = { 100, 30, 252, 50 },
	ribbonLilac = { 100, 30, 252, 50 }, pillButter = { 40, 33, 136, 41 }, pillLilac = { 40, 33, 136, 41 }, pillMint = { 40, 33, 136, 41 }, pillPink = { 40, 33, 136, 41 },
	button = { 42, 40, 118, 52 },
}
local DEEP = { -- each button colour's deep shade, for its label outline
	mint = Color3.fromRGB(63, 156, 124), pink = Color3.fromRGB(194, 86, 116), lilac = Color3.fromRGB(111, 88, 176),
	butter = Color3.fromRGB(196, 138, 46), sky = Color3.fromRGB(74, 131, 196), off = Color3.fromRGB(124, 111, 147),
	ribbonPink = Color3.fromRGB(194, 86, 116), ribbonLilac = Color3.fromRGB(111, 88, 176),
}
local SPRITE = {
	wisteria = "rbxassetid://133392597906841", sakura = "rbxassetid://113252916003793", sparkle = "rbxassetid://101352828199322",
	pointer = "rbxassetid://128266643608103", close = "rbxassetid://132260797395561",
	star = "rbxassetid://100737048426546", starOff = "rbxassetid://89117534881571",
}
local ICON = { -- smooth soft-kit icons (art/icons_soft, ids in art/icons_soft/asset_ids.json; 2026-11-08 replaced the pixel set)
	coin = "rbxassetid://108767995994321", gem = "rbxassetid://109272506073747", pick = "rbxassetid://82124767195252", bag = "rbxassetid://70678886244636",
	crew = "rbxassetid://121813663831714", surface = "rbxassetid://113100619996978", egg = "rbxassetid://81100985418912", star = "rbxassetid://98230996667759",
	dice = "rbxassetid://124755060203655", map = "rbxassetid://109855398030402", camp = "rbxassetid://125775176311436", chisel = "rbxassetid://131827804757525",
	hammer = "rbxassetid://118028256132989", lock = "rbxassetid://129198159082909",
}
local INK, CREAM, WHITE = Color3.fromRGB(62, 42, 86), Color3.fromRGB(255, 247, 238), Color3.new(1, 1, 1)
local MINT, PINK, LILAC, BUTTER, SKY = Color3.fromRGB(127, 220, 180), Color3.fromRGB(255, 157, 176), Color3.fromRGB(185, 164, 238), Color3.fromRGB(255, 217, 112), Color3.fromRGB(142, 200, 255)
local GOLD, PLUM_SOFT = Color3.fromRGB(255, 206, 84), Color3.fromRGB(122, 98, 150)
local FONT = Enum.Font.FredokaOne -- the rounded game font of the soft kit (was the Pixelify bitmap font)

local gui = Instance.new("ScreenGui")
gui.Name, gui.ResetOnSpawn, gui.ZIndexBehavior = "PixelHUD", false, Enum.ZIndexBehavior.Sibling
gui.Parent = plr:WaitForChild("PlayerGui")
local top = Instance.new("ScreenGui") -- full-screen layer for the hatch show, the lift fade and the frenzy edge
top.Name, top.ResetOnSpawn, top.IgnoreGuiInset, top.DisplayOrder = "PixelTop", false, true, 10
top.Parent = gui.Parent

local function new(cls, parent, props)
	local o = Instance.new(cls)
	for k, v in props do o[k] = v end
	o.Parent = parent
	return o
end
local function S(x, y) -- board pixels (1280 x 592 phone landscape) to scale
	return UDim2.fromScale(x / 1280, y / 592)
end
local skinned = {} -- every skin image, so the art pixel size follows the screen height (a weak table loses Instance keys)
local function pixelScale() -- skin and sprite image pixels to screen pixels: the soft kit is drawn at 4x, so 0.45 at 720 px high
	return 0.45 * math.clamp(workspace.CurrentCamera.ViewportSize.Y / 720, 0.5, 3)
end
local SPRITE_PX = { wisteria = { 64, 52 }, sakura = { 48, 40 }, sparkle = { 64, 64 }, pointer = { 80, 48 }, close = { 96, 100 } } -- image pixels
local strokes = {} -- text outlines, thickness follows the screen height
local gridded = {} -- sprites sized on the same pixel grid as the skins
local function skin(o, kind)
	o.BackgroundTransparency = 1
	local s = o:FindFirstChild("Skin") or new("ImageLabel", o, {
		Name = "Skin", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ScaleType = Enum.ScaleType.Slice, ZIndex = 0,
	})
	local r = SLICE[kind] or SLICE.button
	s.SliceCenter, s.SliceScale = Rect.new(r[1], r[2], r[3], r[4]), pixelScale()
	s.Image = SKIN[kind] or SKIN.panel
	if not skinned[s] then
		skinned[s] = true
		s.Destroying:Connect(function() skinned[s] = nil end)
	end
	o:SetAttribute("Kind", kind)
	local lab = o:FindFirstChild("Label")
	if lab and DEEP[kind] then lab.TextStrokeColor3 = DEEP[kind] end
	return s
end
local function gridSize(o, name)
	local px, k = SPRITE_PX[name], pixelScale()
	o.Size = UDim2.fromOffset(px[1] * k, px[2] * k)
	if not gridded[o] then o.Destroying:Connect(function() gridded[o] = nil end) end
	gridded[o] = name
end
task.spawn(function() -- the camera (and its viewport size) can be replaced or resized at any time: re-check every half second
	local last = 0
	while true do
		local k = pixelScale()
		if k ~= last then
			last = k
			for sk in skinned do sk.SliceScale = k end
			for o, name in gridded do gridSize(o, name) end
			for st in strokes do st.Thickness = math.max(1, k * 4.4) end
		end
		task.wait(0.5)
	end
end)
local function fit(o, w, h)
	new("UIAspectRatioConstraint", o, { AspectRatio = w / h, DominantAxis = Enum.DominantAxis.Height })
	return o
end
local function text(parent, s, size, pos, anchor, color, weight, stroke)
	local l = new("TextLabel", parent, {
		Size = size or UDim2.fromScale(1, 1), Position = pos or UDim2.new(), AnchorPoint = anchor or Vector2.zero,
		BackgroundTransparency = 1, Font = FONT, TextScaled = true, Text = s, TextColor3 = color or INK,
		TextStrokeTransparency = stroke == false and 1 or 0, TextStrokeColor3 = INK, ZIndex = 2,
	})
	-- a rounded ink outline that follows the label's stroke and text transparency (fades and toggles keep working)
	local st = new("UIStroke", l, { Color = INK, LineJoinMode = Enum.LineJoinMode.Round, Thickness = math.max(1, pixelScale() * 4.4) })
	local function sync() st.Transparency = math.max(l.TextStrokeTransparency, l.TextTransparency) end
	l:GetPropertyChangedSignal("TextStrokeTransparency"):Connect(sync)
	l:GetPropertyChangedSignal("TextTransparency"):Connect(sync)
	l:GetPropertyChangedSignal("TextStrokeColor3"):Connect(function() st.Color = l.TextStrokeColor3 end)
	sync()
	strokes[st] = true
	st.Destroying:Connect(function() strokes[st] = nil end)
	return l
end
local function panel(parent, size, pos, anchor, kind)
	local f = new("Frame", parent, { Size = size, Position = pos, AnchorPoint = anchor or Vector2.zero })
	skin(f, kind or "panel")
	return f
end
local function icon(parent, name, size, pos, anchor)
	return new("ImageLabel", parent, {
		Name = "Icon", BackgroundTransparency = 1, Image = ICON[name], Size = size, Position = pos, AnchorPoint = anchor or Vector2.zero,
		ScaleType = Enum.ScaleType.Fit, ZIndex = 2,
	})
end
local function scaler(o)
	return o:FindFirstChild("Pop") or new("UIScale", o, { Name = "Pop" })
end
local function pop(o, from, t)
	local sc = scaler(o)
	sc.Scale = from or 1.25
	tween(sc, t or 0.35, { Scale = 1 }, Enum.EasingStyle.Back)
end
local function openPanel(o)
	o.Visible = true
	o.ZIndex = 5
	local sc = scaler(o)
	sc.Scale = 0.9 -- a small, quick grow reads as premium; 0.55 felt like a toy pop (VFX note 2026-11-08)
	tween(sc, 0.28, { Scale = 1 }, Enum.EasingStyle.Back)
end
local function closePanel(o)
	local sc = scaler(o)
	tween(sc, 0.15, { Scale = 0.9 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	task.delay(0.15, function()
		o.Visible = false
		sc.Scale = 1
	end)
end

local sfxClick -- set once the sound bank exists
-- Button: transparent TextButton, pastel skin, an optional icon and a PixelText label that mirrors .Text; squash on press
local function button(parent, label, size, pos, anchor, kind, iconName, vertical)
	local b = new("TextButton", parent, {
		Size = size, Position = pos, AnchorPoint = anchor or Vector2.zero, BackgroundTransparency = 1, AutoButtonColor = false,
		Font = FONT, Text = label, TextTransparency = 1, MaxVisibleGraphemes = 0, ZIndex = 1,
	})
	skin(b, kind or "mint")
	local lab
	if iconName and vertical then
		icon(b, iconName, UDim2.fromScale(0.5, 0.42), UDim2.fromScale(0.5, 0.34), Vector2.new(0.5, 0.5))
		lab = text(b, label, UDim2.fromScale(0.8, 0.19), UDim2.fromScale(0.5, 0.67), Vector2.new(0.5, 0.5), WHITE)
	elseif iconName then
		local ic = icon(b, iconName, UDim2.fromScale(0.3, 0.62), UDim2.fromScale(0.08, 0.5), Vector2.new(0, 0.5))
		new("UIAspectRatioConstraint", ic, { AspectRatio = 1 })
		lab = text(b, label, UDim2.fromScale(0.52, 0.46), UDim2.fromScale(0.68, 0.48), Vector2.new(0.5, 0.5), WHITE)
	else
		lab = text(b, label, UDim2.fromScale(0.84, 0.5), UDim2.fromScale(0.5, 0.47), Vector2.new(0.5, 0.5), WHITE)
	end
	lab.Name = "Label"
	lab.TextStrokeColor3 = DEEP[kind or "mint"] or INK
	b:GetPropertyChangedSignal("Text"):Connect(function() lab.Text = b.Text end)
	local sc = scaler(b)
	b.MouseEnter:Connect(function() tween(sc, 0.12, { Scale = 1.06 }) end)
	b.MouseLeave:Connect(function() tween(sc, 0.15, { Scale = 1 }) end)
	b.MouseButton1Down:Connect(function()
		tween(sc, 0.07, { Scale = 0.88 })
		if sfxClick then sfxClick() end
	end)
	b.MouseButton1Up:Connect(function() tween(sc, 0.45, { Scale = 1 }, Enum.EasingStyle.Elastic) end)
	return b
end
local function setKind(b, kind)
	if b:GetAttribute("Kind") ~= kind then skin(b, kind) end
end
-- A sprite (flower cluster, sparkle) pinned over a corner of a frame, poking out over the edge like the reference kits
local function deco(parent, name, size, pos, rot)
	if true then return nil end -- the pixel flower sprites do not fit the soft kit (2026-11-08); kept for a smooth flower set later
	local d = new("ImageLabel", parent, {
		Name = "Deco", BackgroundTransparency = 1, Image = SPRITE[name], Position = pos, AnchorPoint = Vector2.new(0.5, 0.5),
		ResampleMode = Enum.ResamplerMode.Pixelated, ScaleType = Enum.ScaleType.Stretch, ZIndex = 4, -- unrotated: rotation would break the pixel grid
	})
	gridSize(d, name)
	return d
end
-- A ribbon banner across the top edge of a panel, carrying its title
local function ribbonTitle(parent, label, kind, width)
	local r = new("Frame", parent, { Name = "Ribbon", Size = UDim2.fromScale(width or 0.6, 0.15), Position = UDim2.fromScale(0.5, 0.01), AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 3 })
	skin(r, kind or "ribbonPink")
	local t = text(r, label, UDim2.fromScale(0.7, 0.46), UDim2.fromScale(0.5, 0.4), Vector2.new(0.5, 0.5), WHITE)
	t.TextStrokeColor3 = DEEP[kind or "ribbonPink"] or INK
	t.ZIndex = 4
	return r, t
end
-- The butter close button (a pixel sprite), top-right corner of a panel
local function closeButton(parent, name)
	local b = new("ImageButton", parent, {
		Name = name, BackgroundTransparency = 1, Image = SPRITE.close, AutoButtonColor = false,
		Position = UDim2.fromScale(0.955, 0.075), AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 4,
	})
	gridSize(b, "close")
	local sc = scaler(b)
	b.MouseEnter:Connect(function() tween(sc, 0.12, { Scale = 1.12 }) end)
	b.MouseLeave:Connect(function() tween(sc, 0.15, { Scale = 1 }) end)
	b.MouseButton1Down:Connect(function()
		tween(sc, 0.07, { Scale = 0.85 })
		if sfxClick then sfxClick() end
	end)
	b.MouseButton1Up:Connect(function() tween(sc, 0.4, { Scale = 1 }, Enum.EasingStyle.Elastic) end)
	return b
end
-- A small cream keycap with a key letter (key hints on buttons, the prompt key)
local function keyCap(parent, key, size, pos)
	local k = new("Frame", parent, { Name = "KeyHint", Size = size, Position = pos, AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 4 })
	skin(k, "keycap")
	new("UIAspectRatioConstraint", k, { AspectRatio = 16 / 17 })
	local t = text(k, key, UDim2.fromScale(0.64, 0.5), UDim2.fromScale(0.5, 0.42), Vector2.new(0.5, 0.5), INK, 700, false)
	t.ZIndex = 5
	return k, t
end

-- HUD (board HUD artboard): gold and egg pills, bag pill, left rail, layer pill and depth strip, tutorial card, DIG, crosshair
local goldPill = panel(gui, S(170, 46), S(20, 18), nil, "pillButter")
fit(goldPill, 170, 46)
local coinIcon = icon(goldPill, "coin", UDim2.fromScale(0.2, 0.68), UDim2.fromScale(0.06, 0.5), Vector2.new(0, 0.5))
new("UIAspectRatioConstraint", coinIcon, { AspectRatio = 1 })
local goldText = text(goldPill, "0", UDim2.fromScale(0.64, 0.56), UDim2.fromScale(0.3, 0.5), Vector2.new(0, 0.5), Color3.fromRGB(184, 122, 26), 700, false)
goldText.TextXAlignment = Enum.TextXAlignment.Left
goldPill.Name = "GoldPill"

local eggPill = panel(gui, S(112, 46), S(200, 18), nil, "pillPink")
fit(eggPill, 112, 46)
local eggIc = icon(eggPill, "egg", UDim2.fromScale(0.3, 0.68), UDim2.fromScale(0.08, 0.5), Vector2.new(0, 0.5))
new("UIAspectRatioConstraint", eggIc, { AspectRatio = 1 })
local eggText = text(eggPill, "0", UDim2.fromScale(0.5, 0.56), UDim2.fromScale(0.44, 0.5), Vector2.new(0, 0.5), PINK)
eggText.TextXAlignment = Enum.TextXAlignment.Left
eggPill.Name, eggPill.Visible = "EggPill", false

local bagPill = panel(gui, S(292, 56), S(20, 74), nil, "pillLilac")
fit(bagPill, 292, 56)
bagPill.Name = "BagPill"
local bagIc = icon(bagPill, "bag", UDim2.fromScale(0.13, 0.66), UDim2.fromScale(0.04, 0.5), Vector2.new(0, 0.5))
new("UIAspectRatioConstraint", bagIc, { AspectRatio = 1 })
local bagText = text(bagPill, "BAG", UDim2.fromScale(0.72, 0.4), UDim2.fromScale(0.21, 0.08), nil, INK, 700, false)
bagText.TextXAlignment = Enum.TextXAlignment.Left
local bagTrack = new("Frame", bagPill, { Size = UDim2.fromScale(0.72, 0.2), Position = UDim2.fromScale(0.21, 0.6), BackgroundColor3 = INK, BorderSizePixel = 0, ZIndex = 2 })
new("UICorner", bagTrack, { CornerRadius = UDim.new(0.5, 0) })
local bagFill = new("Frame", bagTrack, { Size = UDim2.fromScale(0, 1), BackgroundColor3 = BUTTER, BorderSizePixel = 0, ZIndex = 3 })
new("Frame", bagFill, { Size = UDim2.fromScale(1, 0.3), Position = UDim2.fromScale(0, 0.7), BackgroundColor3 = Color3.fromRGB(217, 150, 46), BorderSizePixel = 0, ZIndex = 4, BackgroundTransparency = 0.2 })

local railForge = button(gui, "FORGE", S(76, 76), S(20, 146), nil, "lilac", "pick", true)
local railLift = button(gui, "SURFACE", S(76, 76), S(20, 232), nil, "sky", "surface", true)
for _, b in { railForge, railLift } do fit(b, 1, 1) end
railForge.Name, railLift.Name = "Upgrades", "Surface"

local layerPill = panel(gui, S(300, 46), S(1260, 18), Vector2.new(1, 0), "pillLilac")
fit(layerPill, 300, 46)
local layerNum = text(layerPill, "CAMP", UDim2.fromScale(0.27, 0.46), UDim2.fromScale(0.05, 0.5), Vector2.new(0, 0.5), Color3.fromRGB(184, 122, 26), 700, false)
layerNum.TextXAlignment = Enum.TextXAlignment.Left
local layerName = text(layerPill, "", UDim2.fromScale(0.4, 0.42), UDim2.fromScale(0.35, 0.5), Vector2.new(0, 0.5), INK, 700, false)
layerName.TextXAlignment = Enum.TextXAlignment.Left
local layerDepth = text(layerPill, "", UDim2.fromScale(0.18, 0.42), UDim2.fromScale(0.95, 0.5), Vector2.new(1, 0.5), LILAC)
layerDepth.TextXAlignment = Enum.TextXAlignment.Right
local strip = new("Frame", gui, { Size = S(18, 300), Position = S(1242, 82), BackgroundColor3 = INK, BorderSizePixel = 0 })
new("UIStroke", strip, { Color = INK, Thickness = 3 })
for i, lay in C.LAYERS do
	new("Frame", strip, { Size = UDim2.fromScale(1, 1 / #C.LAYERS), Position = UDim2.fromScale(0, (i - 1) / #C.LAYERS), BackgroundColor3 = lay[4][1][2], BorderSizePixel = 0 })
end
for i = 1, #C.LAYERS do
	local n = text(strip, tostring(i), UDim2.new(1.4, 0, 0.6 / #C.LAYERS, 0), UDim2.fromScale(-0.3, (i - 0.5) / #C.LAYERS), Vector2.new(1, 0.5), WHITE)
	n.Name = "LayerNum"
end
local marker = new("Frame", strip, { Size = UDim2.new(1.9, 0, 0, 8), Position = UDim2.fromScale(0.5, 0), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = BUTTER, BorderSizePixel = 0, ZIndex = 3 })
new("UIStroke", marker, { Color = INK, Thickness = 2 })

local stepCard = panel(gui, S(560, 62), S(640, 18), Vector2.new(0.5, 0), "card")
fit(stepCard, 560, 62)
local stepIcon = icon(stepCard, "pick", UDim2.fromScale(0.07, 0.6), UDim2.fromScale(0.03, 0.5), Vector2.new(0, 0.5))
new("UIAspectRatioConstraint", stepIcon, { AspectRatio = 1 })
local stepText = text(stepCard, "", UDim2.fromScale(0.84, 0.48), UDim2.fromScale(0.55, 0.5), Vector2.new(0.5, 0.5), INK, 700, false)
stepCard.Name = "StepCard"

local digBtn = button(gui, "DIG", S(220, 82), S(640, 570), Vector2.new(0.5, 1), "mint", "pick")
fit(digBtn, 220, 82)
digBtn.Name = "Dig"

local cross = new("Frame", gui, { Size = UDim2.fromOffset(22, 22), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, Visible = false })
for _, sz in { { 22, 4 }, { 4, 22 } } do
	local bar = new("Frame", cross, { Size = UDim2.fromOffset(sz[1], sz[2]), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = WHITE, BorderSizePixel = 0 })
	new("UIStroke", bar, { Color = INK, Thickness = 2 })
end
local crossScale = scaler(cross)

-- Pickup feed (board: under the pills, newest on top)
local feed = new("Frame", gui, { Size = S(300, 140), Position = S(112, 160), BackgroundTransparency = 1 })
new("UIListLayout", feed, { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4), VerticalAlignment = Enum.VerticalAlignment.Top })
local feedN = 0
local function feedLine(msg, color)
	feedN += 1
	local row = new("Frame", feed, { Size = UDim2.fromScale(0.9, 0.2), BorderSizePixel = 0, LayoutOrder = -feedN })
	local rowSkin = skin(row, "dark")
	local sw = new("Frame", row, { Size = UDim2.fromScale(0.06, 0.6), Position = UDim2.fromScale(0.03, 0.5), AnchorPoint = Vector2.new(0, 0.5), BackgroundColor3 = color, BorderSizePixel = 0 })
	new("UIAspectRatioConstraint", sw, { AspectRatio = 1 })
	new("UIStroke", sw, { Color = WHITE, Thickness = 1 })
	local t = text(row, msg, UDim2.fromScale(0.82, 0.62), UDim2.fromScale(0.13, 0.5), Vector2.new(0, 0.5), color:Lerp(WHITE, 0.35))
	t.TextXAlignment = Enum.TextXAlignment.Left
	local sc = scaler(row)
	sc.Scale = 0.3
	tween(sc, 0.3, { Scale = 1 }, Enum.EasingStyle.Back)
	local kids = {}
	for _, k in feed:GetChildren() do if k:IsA("Frame") then table.insert(kids, k) end end
	if #kids > 4 then
		table.sort(kids, function(a, b2) return a.LayoutOrder > b2.LayoutOrder end)
		kids[1]:Destroy()
	end
	task.delay(2.4, function()
		if row.Parent then
			tween(rowSkin, 0.3, { ImageTransparency = 1 })
			tween(t, 0.3, { TextTransparency = 1, TextStrokeTransparency = 1 })
			task.delay(0.32, function() row:Destroy() end)
		end
	end)
end

-- A dim scrim behind modal panels so they read over the busy world
local scrim = new("Frame", gui, { Name = "Scrim", Size = UDim2.new(1, 0, 1, 60), Position = UDim2.fromOffset(0, -60), BackgroundColor3 = Color3.fromRGB(26, 18, 40), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 3, Visible = false })

-- Night Shaft report (spec 5.7)
local night = panel(gui, S(460, 230), S(640, 296), Vector2.new(0.5, 0.5), "panel")
fit(night, 460, 230)
night.Visible, night.Name = false, "NightReport"
ribbonTitle(night, "NIGHT SHAFT REPORT", "ribbonLilac", 0.84)
deco(night, "wisteria", UDim2.fromScale(0.13, 0.13), UDim2.fromScale(0.02, 0.06), -12)
local nightInfo = text(night, "", UDim2.fromScale(0.86, 0.11), UDim2.fromScale(0.5, 0.3), Vector2.new(0.5, 0), INK, 500, false)
local nightGold = text(night, "", UDim2.fromScale(0.6, 0.18), UDim2.fromScale(0.5, 0.46), Vector2.new(0.5, 0), GOLD)
local nightOk = button(night, "COLLECT", UDim2.fromScale(0.5, 0.24), UDim2.fromScale(0.5, 0.92), Vector2.new(0.5, 1), "mint", "coin")
nightOk.Name = "NightCollect"
nightOk.Activated:Connect(function() closePanel(night) end)

-- Backpack full (board Moments artboard)
local sellPop = panel(gui, S(420, 210), S(640, 300), Vector2.new(0.5, 0.5), "panel")
fit(sellPop, 420, 210)
sellPop.Visible, sellPop.Name = false, "SellPopup"
local spIc = icon(sellPop, "bag", UDim2.fromScale(0.16, 0.3), UDim2.fromScale(0.08, 0.16))
new("UIAspectRatioConstraint", spIc, { AspectRatio = 1 })
ribbonTitle(sellPop, "BACKPACK FULL!", "ribbonPink", 0.72)
deco(sellPop, "wisteria", nil, UDim2.fromScale(0.02, 0.06), -12)
local sellInfo = text(sellPop, "", UDim2.fromScale(0.62, 0.12), UDim2.fromScale(0.29, 0.26), nil, INK, 700, false)
local sellBtn = button(sellPop, "SELL", UDim2.fromScale(0.56, 0.3), UDim2.fromScale(0.5, 0.82), Vector2.new(0.5, 1), "mint", "surface")
sellBtn.Name = "Sell"
text(sellPop, "Rides the lift up to the sell stall", UDim2.fromScale(0.84, 0.08), UDim2.fromScale(0.5, 0.86), Vector2.new(0.5, 0), PLUM_SOFT, 500, false)

-- Forge v2: the panel is made here (other code checks forge.Visible), its contents in the forge function further down
local forge = panel(gui, S(1140, 520), S(640, 304), Vector2.new(0.5, 0.5), "panel")
fit(forge, 1140, 520)
forge.Visible, forge.Name = false, "Forge"
local forgeUI = { open = function() end, toggle = function() end, refresh = function() end, fx = function() end }

-- Egg odds (spec 5.4 and 5.12: every random item shows its odds; pity is visible)
do
	local total = 0
	for _, t in C.RARITIES do total += t[2] end
	assert(math.abs(total - 100) < 1e-6, "egg odds must sum to 100")
end
local odds = panel(gui, S(380, 400), S(640, 300), Vector2.new(0.5, 0.5), "panel")
fit(odds, 380, 400)
odds.Visible, odds.Name = false, "Odds"
ribbonTitle(odds, "EGG ODDS", "ribbonLilac", 0.62)
deco(odds, "wisteria", nil, UDim2.fromScale(0.02, 0.05), -12)
local oddsClose = closeButton(odds, "OddsClose")
for i, t in C.RARITIES do
	local y = 0.18 + (i - 1) * 0.1
	local sw = new("Frame", odds, { Size = UDim2.fromScale(0.06, 0.06), Position = UDim2.fromScale(0.07, y + 0.005), BackgroundColor3 = t[3], BorderSizePixel = 0, ZIndex = 2 })
	new("UIStroke", sw, { Color = INK, Thickness = 2 })
	local nameT = text(odds, t[1]:upper(), UDim2.fromScale(0.5, 0.065), UDim2.fromScale(0.17, y), nil, t[3], 700)
	nameT.TextXAlignment = Enum.TextXAlignment.Left
	local pct = text(odds, (t[2] >= 1 and tostring(t[2]) or string.format("%.1f", t[2])) .. "%", UDim2.fromScale(0.3, 0.065), UDim2.fromScale(0.93, y), Vector2.new(1, 0), INK, 700, false)
	pct.TextXAlignment = Enum.TextXAlignment.Right
end
local pityText = text(odds, "", UDim2.fromScale(0.86, 0.06), UDim2.fromScale(0.5, 0.82), Vector2.new(0.5, 0), Color3.fromRGB(63, 156, 132), 500, false)

-- Map (seven layers, your deepest point)
local mapP = panel(gui, S(420, 420), S(640, 300), Vector2.new(0.5, 0.5), "panel")
fit(mapP, 420, 420)
mapP.Visible, mapP.Name = false, "Map"
ribbonTitle(mapP, "THE HOLLOW MOUNTAIN", "ribbonLilac", 0.82)
deco(mapP, "wisteria", UDim2.fromScale(0.12, 0.12), UDim2.fromScale(0.02, 0.06), -12)
local mapClose = closeButton(mapP, "MapClose")
local mapRows = {}
for i, lay in C.LAYERS do
	local y = 0.16 + (i - 1) * 0.11
	local row = new("Frame", mapP, { Size = UDim2.fromScale(0.86, 0.095), Position = UDim2.fromScale(0.07, y), BackgroundColor3 = lay[4][1][2], BorderSizePixel = 0, ZIndex = 2 })
	new("UIStroke", row, { Color = INK, Thickness = 2 })
	local t = text(row, i .. "  " .. lay[1]:upper(), UDim2.fromScale(0.62, 0.6), UDim2.fromScale(0.04, 0.5), Vector2.new(0, 0.5), WHITE)
	t.TextXAlignment = Enum.TextXAlignment.Left
	local d = text(row, (i - 1) * C.LAYER_ROWS * B .. " M", UDim2.fromScale(0.3, 0.5), UDim2.fromScale(0.96, 0.5), Vector2.new(1, 0.5), BUTTER)
	d.TextXAlignment = Enum.TextXAlignment.Right
	mapRows[i] = row
end

digBtn.Name, railLift.Name = "Dig", "Surface"

local banner = text(gui, "", S(640, 64), S(640, 92), Vector2.new(0.5, 0), GOLD)
banner.Visible, banner.Name = false, "Banner"
local frenzyBar = new("Frame", gui, { Size = S(300, 10), Position = S(640, 160), AnchorPoint = Vector2.new(0.5, 0), BackgroundColor3 = INK, BorderSizePixel = 0, Visible = false })
local frenzyFill = new("Frame", frenzyBar, { Size = UDim2.fromScale(1, 1), BackgroundColor3 = BUTTER, BorderSizePixel = 0 })
local edge = new("Frame", top, { Size = UDim2.new(1, -24, 1, -24), Position = UDim2.fromOffset(12, 12), BackgroundTransparency = 1, Visible = false })
local edgeStroke = new("UIStroke", edge, { Color = BUTTER, Thickness = 12, Transparency = 0.35 })
local fade = new("Frame", top, { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(26, 18, 40), BackgroundTransparency = 1, ZIndex = 50 })
local fadeText = text(fade, "", UDim2.fromScale(0.5, 0.07), UDim2.fromScale(0.5, 0.5), Vector2.new(0.5, 0.5), LILAC)
fadeText.ZIndex = 51

local toasts = 0 -- live toasts stack downwards instead of overlapping
local function toast(msg, color, big, delay)
	task.delay(delay or 0, function()
		local y = 0.7 - (toasts % 3) * 0.09 -- above the DIG button, clear of the centre panels
		toasts += 1
		local t = text(gui, msg, UDim2.fromScale(big and 0.6 or 0.4, big and 0.08 or 0.06), UDim2.fromScale(0.5, y + 0.06), Vector2.new(0.5, 0.5), color, 700)
		tween(t, 0.35, { Position = UDim2.fromScale(0.5, y) }, Enum.EasingStyle.Back)
		pop(t, 0.4)
		task.delay(1.7, function()
			tween(t, 0.45, { TextTransparency = 1, TextStrokeTransparency = 1, Position = UDim2.fromScale(0.5, y - 0.06) })
			task.delay(0.5, function()
				t:Destroy()
				toasts -= 1
			end)
		end)
	end)
end

-- Gold count-up with a coin flip
local goldShown, goldGoal = 0, 0
local function setGold(n)
	goldGoal = n
	if n > goldShown then
		tween(coinIcon, 0.25, { Rotation = 360 }).Completed:Connect(function() coinIcon.Rotation = 0 end)
		pop(goldPill, 1.15)
	end
end

-- Sound effects (Creator Store audio, free: ProSoundEffects where available). Each play varies the pitch a little.
local SFX = {
	-- name = { asset id, volume, seconds to play at most (some library sounds are long takes) }
	swing = { 9119710806, 0.35 }, hit = { 9118582313, 0.45, 0.28 }, clink = { 9116651251, 0.5, 0.6 }, breakRock = { 9118587698, 0.55, 0.9 },
	coin = { 113730061669739, 0.5 }, click = { 17779566040, 0.5, 0.4 }, upgrade = { 135996502799215, 0.6 }, sparkle = { 132381858621446, 0.55, 1.4 },
}
local soundBank = {}
for name, s in SFX do
	soundBank[name] = new("Sound", game:GetService("SoundService"), { Name = "Pixel_" .. name, SoundId = "rbxassetid://" .. s[1], Volume = s[2] })
end
local sfx
sfx = function(name, pitch)
	local base = soundBank[name]
	if not base then return end
	local s = base:Clone()
	s.PlaybackSpeed = (pitch or 1) * (0.94 + math.random() * 0.12)
	s.Parent = game:GetService("SoundService")
	s:Play()
	local len = SFX[name][3]
	if len then task.delay(len, function() tween(s, 0.08, { Volume = 0 }) end) end
	task.delay(math.min(s.TimeLength > 0 and s.TimeLength or 3, len and len + 0.2 or 3), function() s:Destroy() end)
end
sfxClick = function() sfx("click") end

-- World FX
local fx = new("Folder", workspace, { Name = "ClientFX" })
local function anchor(size)
	return new("Part", fx, { Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, Transparency = 1, Size = size or Vector3.one })
end
local spark = anchor()
local sparkEm = new("ParticleEmitter", spark, {
	Rate = 0, Lifetime = NumberRange.new(0.25, 0.5), Speed = NumberRange.new(10, 22), SpreadAngle = Vector2.new(70, 70),
	Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0) }),
	LightEmission = 1, Drag = 5, Acceleration = Vector3.new(0, -40, 0), EmissionDirection = Enum.NormalId.Front,
})
local function burst(pos, normal, color, n)
	spark.CFrame = CFrame.lookAt(pos, pos + (normal or Vector3.yAxis))
	sparkEm.Color = ColorSequence.new(color)
	sparkEm:Emit(n)
end
local rain = anchor(Vector3.new(40, 1, 40))
local rainEm = new("ParticleEmitter", rain, {
	Rate = 0, Color = ColorSequence.new(GOLD), Lifetime = NumberRange.new(1.2, 1.8), Speed = NumberRange.new(10, 18),
	EmissionDirection = Enum.NormalId.Bottom, Size = NumberSequence.new(0.6), LightEmission = 0.7, Shape = Enum.ParticleEmitterShape.Box,
	Rotation = NumberRange.new(0, 360), RotSpeed = NumberRange.new(-200, 200),
})

local shakeAmp, fovKick = 0, 0
local function shake(a) shakeAmp = math.max(shakeAmp, a) end

local function floatText(pos, msg, color)
	local a = anchor()
	a.Position = pos
	local bb = new("BillboardGui", a, { Size = UDim2.fromScale(9, 1.8), LightInfluence = 0, AlwaysOnTop = true, MaxDistance = 80 })
	local t = text(bb, msg, nil, nil, nil, color, 700)
	local sc = scaler(t)
	sc.Scale = 0.2
	tween(sc, 0.3, { Scale = 1 }, Enum.EasingStyle.Back)
	tween(a, 0.9, { Position = pos + Vector3.new(0, 3.5, 0) })
	task.delay(0.6, function() tween(t, 0.3, { TextTransparency = 1, TextStrokeTransparency = 1 }) end)
	task.delay(1, function() a:Destroy() end)
end

-- Break: white flash, voxel shards with spin and gravity
local shards = {}
local function breakFx(pos, color)
	local flash = new("Part", fx, { Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, Size = Vector3.one * B * 1.06, Position = pos, Color = WHITE, Material = Enum.Material.Neon, Transparency = 0.2 })
	tween(flash, 0.16, { Transparency = 1, Size = Vector3.one * B * 1.25 })
	task.delay(0.18, function() flash:Destroy() end)
	for _ = 1, 8 do
		local sz = math.random(45, 95) / 100
		local p = new("Part", fx, { Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, Size = Vector3.one * sz, Color = color:Lerp(WHITE, math.random() * 0.25), Material = Enum.Material.SmoothPlastic })
		p.CFrame = CFrame.new(pos + Vector3.new(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5) * B * 0.6)
		table.insert(shards, { part = p, v = Vector3.new(math.random(-12, 12), math.random(6, 18), math.random(-12, 12)), spin = Vector3.new(math.random(-9, 9), math.random(-9, 9), math.random(-9, 9)), t = 0 })
	end
end

local function oreFly(pos, color)
	local o = new("Part", fx, { Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, Size = Vector3.new(1, 1, 1), Color = color, Material = Enum.Material.Neon })
	local a0 = new("Attachment", o, { Position = Vector3.new(0, 0.4, 0) })
	local a1 = new("Attachment", o, { Position = Vector3.new(0, -0.4, 0) })
	new("Trail", o, { Attachment0 = a0, Attachment1 = a1, Lifetime = 0.2, Color = ColorSequence.new(color), LightEmission = 1, Transparency = NumberSequence.new(0, 1) })
	local p0, t0 = pos, os.clock()
	local conn
	conn = RunService.RenderStepped:Connect(function()
		local a = math.min((os.clock() - t0) / 0.45, 1)
		local goal = (cam.CFrame * CFrame.new(-2.2, 1.2, -3)).Position -- toward the bag pill at the top left
		o.Position = p0:Lerp(goal, a * a) + Vector3.new(0, math.sin(a * math.pi) * 2.5, 0)
		o.Size = Vector3.one * (1 - a * 0.6)
		if a >= 1 then
			conn:Disconnect()
			o:Destroy()
			pop(bagPill, 1.1)
		end
	end)
end

-- Hit-timing ring: closes on the block every CRIT_PERIOD; tap while it is gold for a crit (the server checks the timing)
local critAnchor = anchor()
local critBB = new("BillboardGui", critAnchor, { Size = UDim2.fromScale(B * 1.6, B * 1.6), LightInfluence = 0, Enabled = false, AlwaysOnTop = true })
local function circle(parent, size, thick, color)
	local f = new("Frame", parent, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(size, size), BackgroundTransparency = 1 })
	new("UICorner", f, { CornerRadius = UDim.new(1, 0) })
	return f, new("UIStroke", f, { Color = color, Thickness = thick, Transparency = 0.2 })
end
local _, critGoal = circle(critBB, 0.42, 2, WHITE)
critGoal.Transparency = 0.55
local critRing, critStroke = circle(critBB, 1, 3, WHITE)
local critPart, critT0, critUntil = nil, 0, 0
local function shockwave(pos, color)
	local a = anchor()
	a.Position = pos
	local bb = new("BillboardGui", a, { Size = UDim2.fromScale(B * 2.6, B * 2.6), LightInfluence = 0, AlwaysOnTop = true })
	local f, st = circle(bb, 0.3, 6, color)
	tween(f, 0.35, { Size = UDim2.fromScale(1, 1) })
	tween(st, 0.35, { Transparency = 1, Thickness = 1 })
	task.delay(0.4, function() a:Destroy() end)
end

-- Tutorial pointer and the targeted block outline
local hl = new("Highlight", fx, { FillColor = BUTTER, OutlineColor = WHITE, DepthMode = Enum.HighlightDepthMode.AlwaysOnTop, Enabled = false })
local arrowAnchor = anchor()
local arrow = new("BillboardGui", arrowAnchor, { Size = UDim2.fromScale(6, 2.2), Enabled = false, LightInfluence = 0, AlwaysOnTop = true })
local arrowText = text(arrow, "TAP!", nil, nil, nil, BUTTER, 700)
local aim = new("Highlight", fx, { FillColor = WHITE, FillTransparency = 0.82, OutlineColor = BUTTER, OutlineTransparency = 0.35, DepthMode = Enum.HighlightDepthMode.Occluded })

-- Rarity tags: rare blocks carry Tag ("1 IN 104") and TagColor; draw a framed tag and an outline when they appear
local function tagBlock(p)
	local ore = p:GetAttribute("Ore")
	if ore then -- valuable ore pokes out of the rock in chunky facets and glints
		for _, d in p:GetChildren() do
			if d:IsA("Decal") and not d.Name:find("^Crack") then
				local n = Vector3.FromNormalId(d.Face)
				for k = 1, 2 do
					local sz = 0.6 + ((p.Position.X * 7 + k * 13) % 4) * 0.12
					local off = Vector3.new(((k * 37 + p.Position.Y) % 3) - 1, ((k * 53 + p.Position.Z) % 3) - 1, ((k * 71 + p.Position.X) % 3) - 1) * 0.9
					off = off - n * off:Dot(n)
					new("Part", p, {
						Name = "Chunk", Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false,
						Size = Vector3.one * sz, Color = ore:Lerp(WHITE, 0.15), Material = Enum.Material.SmoothPlastic,
						CFrame = CFrame.new(p.Position + n * (B / 2 + sz * 0.15) + off) * CFrame.Angles(0.6, 0.8 * k, 0.4),
					})
				end
			end
		end

		new("ParticleEmitter", p, {
			Rate = 0.8, Lifetime = NumberRange.new(0.5, 0.9), Speed = NumberRange.new(0, 0.2), Color = ColorSequence.new(ore:Lerp(WHITE, 0.5)),
			LightEmission = 1, Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.5, 0.45), NumberSequenceKeypoint.new(1, 0) }),
			Shape = Enum.ParticleEmitterShape.Box, ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface, Rotation = NumberRange.new(45),
		})
	end
	local tag = p:GetAttribute("Tag")
	if not tag then return end
	local col = p:GetAttribute("TagColor") or BUTTER
	new("SelectionBox", p, { Adornee = p, Color3 = col, LineThickness = 0.08, SurfaceTransparency = 0.85, SurfaceColor3 = col })
	local bb = new("BillboardGui", p, { Size = UDim2.fromScale(5.5, 1.8), StudsOffset = Vector3.new(0, B * 0.95, 0), LightInfluence = 0, MaxDistance = 40, AlwaysOnTop = false })
	local f = new("Frame", bb, { Size = UDim2.fromScale(1, 1), BackgroundColor3 = INK, BorderSizePixel = 0 })
	new("UIStroke", f, { Color = col, Thickness = 2 })
	new("UICorner", f, { CornerRadius = UDim.new(0, 4) })
	text(f, tag, UDim2.fromScale(0.9, 0.6), UDim2.fromScale(0.5, 0.5), Vector2.new(0.5, 0.5), col)
end

-- Cracks: the block shows a crack stage on every textured face while you dig it
local function crack(p, frac)
	local tex = frac > 0.66 and C.TEX.crack1 or (frac > 0.33 and C.TEX.crack2 or C.TEX.crack3)
	for _, d in p:GetChildren() do
		if d:IsA("Decal") and not d.Name:find("^Crack") then
			local key = "Crack" .. d.Name
			local c = p:FindFirstChild(key) or new("Decal", p, { Name = key, Face = d.Face, ZIndex = 2 })
			c.Texture = tex
		end
	end
end

-- Crew followers (voxel chibis from parts)
local function petModel(name)
	local p = C.PETS[name]
	local body, acc = p[5], p[6]
	local m = Instance.new("Model")
	m.Name = name
	local function cube(size, pos, color, neon)
		return new("Part", m, {
			Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, Size = size, Color = color, CFrame = CFrame.new(pos),
			Material = neon and Enum.Material.Neon or Enum.Material.SmoothPlastic, TopSurface = Enum.SurfaceType.Smooth, BottomSurface = Enum.SurfaceType.Smooth,
		})
	end
	m.PrimaryPart = cube(Vector3.new(1.4, 1.1, 1.2), Vector3.zero, body)
	cube(Vector3.new(1.5, 1.3, 1.3), Vector3.new(0, 1.05, -0.05), body) -- head about 45% of height
	cube(Vector3.new(0.3, 0.6, 0.3), Vector3.new(-0.45, 1.95, 0), body)
	cube(Vector3.new(0.3, 0.6, 0.3), Vector3.new(0.45, 1.95, 0), body)
	for _, x in { -0.35, 0.35 } do -- 2x2 eyes with a white highlight, facing forward (-Z)
		cube(Vector3.new(0.3, 0.32, 0.1), Vector3.new(x, 1.1, -0.72), INK)
		cube(Vector3.new(0.1, 0.1, 0.06), Vector3.new(x + 0.06, 1.18, -0.78), WHITE)
	end
	cube(Vector3.new(0.3, 0.4, 0.3), Vector3.new(-0.4, -0.72, -0.3), body)
	cube(Vector3.new(0.3, 0.4, 0.3), Vector3.new(0.4, -0.72, -0.3), body)
	local glowP = cube(Vector3.new(0.55, 0.55, 0.55), Vector3.new(0, 0.35, 0.95), acc, true) -- signature glow on the back
	new("PointLight", glowP, { Color = acc, Range = 8, Brightness = 1.2 })
	return m
end

local ripples = {} -- water surface textures that drift
local petObjs, petKey = {}, ""
local function syncPets()
	local names = state and state.pets or {}
	local key = table.concat(names, ",")
	if key == petKey or hatchBusy then return end
	petKey = key
	for _, p in petObjs do p.model:Destroy() end
	petObjs = {}
	local h = hrp()
	for i, n in names do
		local m = petModel(n)
		m.Parent = fx
		petObjs[i] = { model = m, pos = h and h.Position or Vector3.zero, digUntil = 0, digPos = Vector3.zero, hop = 0 }
	end
end

-- Hatch show v2 (EGG-02). Beats from motionbykrit's "make a card reveal feel epic" (Roblox Dev/Research/VFX and Animation/
-- Reveal Juice - motionbykrit (2026-11-08).md): 1 build-up (the egg floats up off its plinth, shakes harder and harder and
-- leaks its rarity colour), 2 hang then snap (it squashes and holds a beat, then stretches and pops), 3 light burst (a short
-- flash, rays, a ring rolling across the plinth), 4 foil shine (a rainbow sheen sweeps the card as the pet tilts, Epic and up),
-- 5 sound on every beat (ticks that climb in pitch, a whoosh on the snap, a boom on the burst, a chime). Rarer pets get a
-- longer build-up, more shake, a bigger glow and more confetti, so the player feels the tier before they see it.
local function hatchShow(name)
	hatchBusy = true
	local p = C.PETS[name]
	local rc = rarityColor(p[1])
	local tier = 1
	for i, t in C.RARITIES do if t[1] == p[1] then tier = i end end
	local k = (tier - 1) / (#C.RARITIES - 1) -- 0 for Common, 1 for Secret
	local buildT = 1.1 + k * 1.1
	local ov = new("TextButton", top, { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(26, 18, 40), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 20 })
	tween(ov, 0.3, { BackgroundTransparency = 0.12 })
	local stage = new("Frame", ov, { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 20 }) -- shaken as one piece
	local function circle(size, trans)
		local c = new("Frame", stage, { Size = UDim2.fromScale(size, size), Position = UDim2.fromScale(0.5, 0.47), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = rc, BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 21 })
		new("UIAspectRatioConstraint", c, { AspectRatio = 1 })
		new("UICorner", c, { CornerRadius = UDim.new(0.5, 0) })
		return c, trans
	end
	local glows = { { circle(0.62, 0.9) }, { circle(0.44, 0.8) }, { circle(0.28, 0.7) } } -- a soft radial glow from stacked discs
	local rays = new("Frame", stage, { Size = UDim2.fromScale(0.6, 0.6), Position = UDim2.fromScale(0.5, 0.47), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, ZIndex = 21 })
	new("UIAspectRatioConstraint", rays, { AspectRatio = 1 })
	local raySc = new("UIScale", rays, { Scale = 0 })
	for i = 0, 7 do
		local bar = new("Frame", rays, { Size = UDim2.fromScale(1.7, i % 2 == 0 and 0.09 or 0.05), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), Rotation = i * 22.5, BackgroundColor3 = i % 2 == 0 and rc or WHITE, BorderSizePixel = 0, ZIndex = 21 })
		new("UIGradient", bar, { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.15), NumberSequenceKeypoint.new(1, 1) }) })
	end
	-- the reveal card behind the pet: dark face, rarity border, clipped so the foil sheen stays on it
	local card = new("Frame", stage, { Size = UDim2.fromScale(0.26, 0.5), Position = UDim2.fromScale(0.5, 0.45), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Color3.fromRGB(44, 32, 66), BackgroundTransparency = 1, ClipsDescendants = true, ZIndex = 22 })
	new("UIAspectRatioConstraint", card, { AspectRatio = 0.72 })
	new("UICorner", card, { CornerRadius = UDim.new(0.06, 0) })
	local cardStroke = new("UIStroke", card, { Color = rc, Thickness = 4, Transparency = 1 })
	local cardSc = new("UIScale", card, { Scale = 1.4 })
	local sheen = new("Frame", card, { Size = UDim2.fromScale(0.45, 1.6), Position = UDim2.fromScale(-0.6, -0.3), Rotation = 18, BackgroundColor3 = WHITE, BackgroundTransparency = 0.55, BorderSizePixel = 0, ZIndex = 23, Visible = false })
	new("UIGradient", sheen, {
		Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 140, 190)), ColorSequenceKeypoint.new(0.25, Color3.fromRGB(255, 230, 140)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(150, 255, 210)), ColorSequenceKeypoint.new(0.75, Color3.fromRGB(140, 200, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(210, 150, 255)) }),
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.2), NumberSequenceKeypoint.new(1, 1) }),
	})
	-- the floor ring that rolls out across the plinth on the burst (an ellipse, so it reads as lying on the ground)
	local ring = new("Frame", stage, { Size = UDim2.fromScale(0.1, 0.03), Position = UDim2.fromScale(0.5, 0.66), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, ZIndex = 24 })
	new("UICorner", ring, { CornerRadius = UDim.new(0.5, 0) })
	local ringStroke = new("UIStroke", ring, { Color = rc:Lerp(WHITE, 0.4), Thickness = 5, Transparency = 1 })
	local vp = new("ViewportFrame", stage, {
		Size = UDim2.fromScale(0.42, 0.42), Position = UDim2.fromScale(0.5, 0.47), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1,
		Ambient = Color3.fromRGB(190, 180, 210), LightColor = WHITE, LightDirection = Vector3.new(-1, -1, -1), ZIndex = 25,
	})
	new("UIAspectRatioConstraint", vp, { AspectRatio = 1 })
	local vpSc = new("UIScale", vp, { Scale = 0.3 })
	tween(vpSc, 0.4, { Scale = 1 }, Enum.EasingStyle.Back) -- the egg and plinth drop in
	local world = new("WorldModel", vp, {})
	local vcam = new("Camera", vp, { FieldOfView = 30 })
	vp.CurrentCamera = vcam
	vcam.CFrame = CFrame.lookAt(Vector3.new(0, 1.2, -9), Vector3.new(0, 0.6, 0))
	local plinth = new("Part", world, { Anchored = true, Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.5, 3.6, 3.6), Color = Color3.fromRGB(96, 76, 128), CFrame = CFrame.new(0, -1.05, 0) * CFrame.Angles(0, 0, math.rad(90)) })
	local rim = new("Part", world, { Anchored = true, Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.12, 3.9, 3.9), Color = rc, Material = Enum.Material.Neon, Transparency = 0.85, CFrame = CFrame.new(0, -0.78, 0) * CFrame.Angles(0, 0, math.rad(90)) })
	local egg = new("Part", world, { Anchored = true, Size = Vector3.new(2.2, 2.8, 2.2), Color = C.EGG_COLOR, CFrame = CFrame.new(0, 0.6, 0) })
	local eggMesh = new("SpecialMesh", egg, { MeshType = Enum.MeshType.Sphere })
	local leak = new("Part", world, { Anchored = true, Size = Vector3.new(2.45, 3.05, 2.45), Color = rc, Material = Enum.Material.Neon, Transparency = 1, CFrame = egg.CFrame }) -- rarity light leaking through the shell
	local leakMesh = new("SpecialMesh", leak, { MeshType = Enum.MeshType.Sphere })
	local cracks = {}
	for i = 1, 4 do -- crack lines that appear one by one during the build-up
		local a = i * 1.7
		cracks[i] = new("Part", world, { Anchored = true, Size = Vector3.new(0.12, 0.8 + i * 0.15, 0.12), Color = rc:Lerp(WHITE, 0.3), Material = Enum.Material.Neon, Transparency = 1, CFrame = CFrame.new(math.sin(a) * 0.3, 0.9 + (i % 2) * 0.4, -1.08) * CFrame.Angles(0, 0, (i % 2 == 0 and 1 or -1) * 0.5) })
	end
	local title = text(ov, "A FOSSIL EGG!", UDim2.fromScale(0.5, 0.08), UDim2.fromScale(0.5, 0.09), Vector2.new(0.5, 0), CREAM, 700)
	title.ZIndex = 26
	pop(title, 0.6, 0.4)

	-- 1 BUILD-UP: float, shake harder, leak light; ticks climb in pitch and speed
	local t0 = os.clock()
	local phase = "build"
	local hold0 = 0
	local conn = RunService.RenderStepped:Connect(function()
		local t = os.clock() - t0
		local u = math.clamp(t / buildT, 0, 1)
		if phase == "build" and egg.Parent then
			local amp = (0.03 + 0.34 * u * u * u) * (0.7 + k * 0.6)
			local lift = 0.6 + 0.8 * (1 - (1 - u) ^ 3)
			local cf = CFrame.new(math.sin(t * (20 + 50 * u)) * amp * 0.35, lift, 0) * CFrame.Angles(0, 0, math.sin(t * (16 + 40 * u)) * amp)
			egg.CFrame, leak.CFrame = cf, cf
			leak.Transparency = 1 - u * (0.12 + k * 0.12) -- a thin halo; the cracks carry the light
			for i, c in cracks do
				c.CFrame = cf * CFrame.new(math.sin(i * 1.7) * 0.3, (i % 2) * 0.4 + 0.2, -1.08) * CFrame.Angles(0, 0, (i % 2 == 0 and 1 or -1) * 0.5)
				c.Transparency = u > i / 5 and 0 or 1
			end
			for i, g in glows do g[1].BackgroundTransparency = 1 - (1 - g[2]) * u * (0.6 + k * 0.6) end
			stage.Position = UDim2.fromOffset(math.sin(t * 53) * u * u * u * 7 * (0.5 + k), math.cos(t * 41) * u * u * u * 5 * (0.5 + k))
		elseif phase == "hold" and egg.Parent then -- 2 HANG: squash down and hold still, the light pulsing
			local h = math.clamp((os.clock() - hold0) / 0.22, 0, 1)
			h = h * h -- ease in to the squash, then the hold
			eggMesh.Scale = Vector3.new(1 + 0.3 * h, 1 - 0.3 * h, 1 + 0.3 * h)
			leakMesh.Scale = eggMesh.Scale
			leak.Transparency = 0.84 + math.sin(os.clock() * 30) * 0.06
			stage.Position = UDim2.fromOffset(0, 0)
		end
		rays.Rotation = t * (25 + k * 30)
		rim.Transparency = 0.85 - math.min(u, 1) * 0.25
	end)
	while os.clock() - t0 < buildT do
		local u = (os.clock() - t0) / buildT
		sfx("hit", 0.8 + u * 0.9)
		task.wait(0.32 - u * 0.22)
	end
	phase, hold0 = "hold", os.clock()
	title.Text = "..."
	task.wait(0.34 + k * 0.2) -- 0.22 s squash, then a dead hold
	-- SNAP: stretch up for a frame, a whoosh, then the burst
	sfx("swing", 1.4)
	tween(eggMesh, 0.08, { Scale = Vector3.new(0.65, 1.45, 0.65) }, Enum.EasingStyle.Exponential, Enum.EasingDirection.In)
	task.wait(0.08)
	phase = "done"

	-- TIER CLIMB (Rare and up, from ropilotai's rare rolling reels): the egg hides, a four-point star flare steps up through the
	-- rarity colours one flash at a time until it reaches this pet's tier, so the tier rises in front of the player.
	-- Mythic and Secret first cut to near black with a caption, so the colour flood lands harder.
	if tier >= 2 then
		vp.Visible = false
		for _, g in glows do g[1].BackgroundTransparency = 1 end
		if tier >= 5 then
			local dark = new("Frame", ov, { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(8, 5, 14), BackgroundTransparency = 1, ZIndex = 21 })
			tween(dark, 0.25, { BackgroundTransparency = 0.05 })
			title.Text = tier >= 6 and "THE ROOTS AWAKEN..." or "THE DEEP STIRS..."
			title.TextColor3 = CREAM
			pop(title, 0.8, 0.5)
			task.wait(0.9)
			task.delay(1.6 + tier * 0.1, function() tween(dark, 0.3, { BackgroundTransparency = 1 }); task.delay(0.35, function() dark:Destroy() end) end)
		end
		local bloom = new("Frame", ov, { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 22 })
		local flare = new("Frame", ov, { Size = UDim2.fromScale(0.55, 0.55), Position = UDim2.fromScale(0.5, 0.47), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, ZIndex = 24 })
		new("UIAspectRatioConstraint", flare, { AspectRatio = 1 })
		local fSc = new("UIScale", flare, { Scale = 0.5 })
		local parts = {}
		for i, sz in { { 1, 0.035 }, { 0.035, 1 }, { 0.55, 0.02 }, { 0.02, 0.55 } } do -- long and short spikes of the star
			local b = new("Frame", flare, { Size = UDim2.fromScale(sz[1], sz[2]), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), Rotation = i > 2 and 45 or 0, BorderSizePixel = 0, ZIndex = 24 })
			new("UIGradient", b, { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(1, 1) }), Rotation = sz[1] > sz[2] and 0 or 90 })
			table.insert(parts, b)
		end
		local core = new("Frame", flare, { Size = UDim2.fromScale(0.2, 0.2), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), BorderSizePixel = 0, ZIndex = 25 })
		new("UICorner", core, { CornerRadius = UDim.new(0.5, 0) })
		local halo = new("Frame", flare, { Size = UDim2.fromScale(0.6, 0.6), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, ZIndex = 23 })
		new("UICorner", halo, { CornerRadius = UDim.new(0.5, 0) })
		local haloStroke = new("UIStroke", halo, { Thickness = 2, Transparency = 0.4 })
		local label = text(ov, "", UDim2.fromScale(0.3, 0.045), UDim2.fromScale(0.5, 0.66), Vector2.new(0.5, 0), CREAM, 700)
		label.ZIndex = 26
		for i = 1, tier do
			local col = C.RARITIES[i][3]
			for _, b in parts do b.BackgroundColor3 = col end
			core.BackgroundColor3, haloStroke.Color = col:Lerp(WHITE, 0.6), col
			label.Text, label.TextColor3 = string.upper(C.RARITIES[i][1]), col
			pop(label, 1.3, 0.25)
			fSc.Scale = 0.55 + i * 0.12
			tween(fSc, 0.28, { Scale = 0.45 + i * 0.12 }, Enum.EasingStyle.Back)
			tween(halo, 0.3, { Size = UDim2.fromScale(0.6 + i * 0.12, 0.6 + i * 0.12) })
			flare.Rotation = (i % 2) * 8
			bloom.BackgroundColor3, bloom.BackgroundTransparency = col, 0.55 -- the whole screen flashes the tier colour
			tween(bloom, 0.3, { BackgroundTransparency = 0.9 })
			sfx("hit", 1 + i * 0.18)
			if i > 1 then sfx("sparkle", 0.8 + i * 0.1) end
			task.wait(i == tier and 0.5 or 0.34)
		end
		label:Destroy()
		flare:Destroy()
		bloom:Destroy()
		vp.Visible = true
	end

	-- 3 LIGHT BURST: a short white flash, rays scale in, the ring rolls out, the card flips in behind the pet
	local flash = new("Frame", ov, { Size = UDim2.fromScale(1, 1), BackgroundColor3 = rc:Lerp(WHITE, 0.75), BackgroundTransparency = 0, ZIndex = 30 })
	tween(flash, 0.12, { BackgroundTransparency = 1 })
	task.delay(0.25, function() flash:Destroy() end)
	sfx("breakRock", 0.7)
	sfx("upgrade")
	egg:Destroy()
	leak:Destroy()
	for _, c in cracks do c:Destroy() end
	raySc.Scale = 0.1
	tween(raySc, 0.3, { Scale = 0.8 + k * 0.5 }, Enum.EasingStyle.Back)
	task.spawn(function() -- a decaying screen kick on the burst
		for i = 1, 8 do
			local a = (1 - i / 8) * 9
			stage.Position = UDim2.fromOffset((math.random() - 0.5) * 2 * a, (math.random() - 0.5) * 2 * a)
			task.wait(1 / 60)
		end
		stage.Position = UDim2.fromOffset(0, 0)
	end)
	for i, g in glows do tween(g[1], 0.3, { BackgroundTransparency = g[2] - 0.15 * k }) end
	ringStroke.Transparency = 0
	ringStroke.Thickness = 8
	tween(ring, 0.6, { Size = UDim2.fromScale(0.75, 0.2) }, Enum.EasingStyle.Circular)
	tween(ringStroke, 0.6, { Transparency = 1, Thickness = 2 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	if tier >= 4 then -- a second, slower ring for Legendary and up
		local r2 = ring:Clone()
		r2.Parent = stage
		r2.Size = UDim2.fromScale(0.1, 0.03)
		local s2 = r2:FindFirstChildOfClass("UIStroke")
		s2.Transparency, s2.Thickness = 0, 5
		task.delay(0.12, function()
			tween(r2, 0.8, { Size = UDim2.fromScale(0.8, 0.22) }, Enum.EasingStyle.Quart)
			tween(s2, 0.8, { Transparency = 1, Thickness = 1 })
		end)
	end
	card.BackgroundTransparency, cardStroke.Transparency = 0.1, 0
	tween(cardSc, 0.45, { Scale = 1 }, Enum.EasingStyle.Back)
	local m = petModel(name)
	m:PivotTo(CFrame.Angles(0, math.rad(20), 0))
	m.Parent = world
	vcam.FieldOfView = 70 -- the pet punches in big and settles (camera zoom, so the model keeps its pivot)
	tween(vcam, 0.45, { FieldOfView = 30 }, Enum.EasingStyle.Back)
	title.Text = string.upper(name)
	title.TextColor3 = rc
	pop(title, 1.6, 0.45)
	local pct = C.RARITIES[tier][2]
	local odds = pct >= 5 and "" or ("  -  1 IN " .. commas(math.floor(100 / pct + 0.5)))
	local sub = text(ov, p[1]:upper() .. "  -  " .. p[2]:upper() .. odds, UDim2.fromScale(0.5, 0.06), UDim2.fromScale(0.5, 0.76), Vector2.new(0.5, 0), rc)
	sub.ZIndex = 26
	pop(sub, 0.5, 0.35)
	task.delay(0.15, function() sfx("sparkle") end)
	local nConf = 12 + tier * 4
	for i = 1, nConf do -- confetti squares that fly out and fall
		local a = i / nConf * math.pi * 2 + math.random() * 0.3
		local dist = 0.22 + math.random() * 0.18
		local q = new("Frame", ov, { Size = UDim2.fromScale(0.011, 0.019), Position = UDim2.fromScale(0.5, 0.47), BackgroundColor3 = ({ rc, PINK, MINT, BUTTER })[i % 4 + 1], BorderSizePixel = 0, ZIndex = 27 })
		local mid = UDim2.fromScale(0.5 + math.cos(a) * dist, 0.47 + math.sin(a) * dist * 1.2)
		tween(q, 0.45, { Position = mid, Rotation = 120 }, Enum.EasingStyle.Quart)
		task.delay(0.45, function()
			tween(q, 0.9, { Position = mid + UDim2.fromScale(0, 0.18), BackgroundTransparency = 1, Rotation = 300 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			task.delay(1, function() q:Destroy() end)
		end)
	end
	local hint = text(ov, "TAP TO CONTINUE", UDim2.fromScale(0.3, 0.04), UDim2.fromScale(0.5, 0.87), Vector2.new(0.5, 0), CREAM)
	hint.ZIndex = 26
	hint.TextTransparency = 1
	task.delay(0.8, function() tween(hint, 0.3, { TextTransparency = 0 }) end)

	-- 4 FOIL SHINE (Epic and up): the pet tilts and a rainbow sheen sweeps the card, again every couple of seconds
	local shine = tier >= 3
	local spinT = os.clock()
	local spin = RunService.RenderStepped:Connect(function()
		local t = os.clock() - spinT
		m:ScaleTo(1 + math.sin(t * 5) * 0.035) -- breathing, so the pet never freezes
		m:PivotTo(CFrame.new(0, math.abs(math.sin(t * 4)) * 0.35 * math.exp(-t * 0.8) + math.sin(t * 4.5) * 0.08, 0) * CFrame.Angles(0, math.rad(20) + math.sin(t * 1.6) * 0.45, math.sin(t * 1.6) * 0.06))
		if shine then
			local s = (t * 0.8) % 1.15 -- sweeps back to back with a short gap
			sheen.Visible = s < 1
			sheen.Position = UDim2.fromScale(-0.6 + s * 1.8, -0.3)
		end
	end)
	local closed = false
	local function close()
		if closed then return end
		closed = true
		conn:Disconnect()
		spin:Disconnect()
		ov:Destroy()
		hatchBusy = false
		syncPets()
	end
	task.delay(0.6, function() ov.Activated:Connect(close) end)
	task.delay(4.5, close)
end

-- First-person pickaxe (a local copy of the held pickaxe in front of the camera) with a wind-up, strike and recover swing
local vm, vmTier, vmTrail = nil, nil, nil
local swingT0 = -10
local function buildViewmodel()
	local ch = plr.Character
	local held = ch and ch:FindFirstChild("HeldPickaxe")
	local tier = held and held:GetAttribute("Tier")
	if vm and vmTier == tier then return end
	if vm then vm:Destroy() vm = nil end
	if not held then return end
	vmTier = tier
	vm = held:Clone()
	vm.Name = "ViewPick"
	local grip = vm:FindFirstChild("PickGrip", true)
	if grip then grip:Destroy() end
	local root = vm.PrimaryPart or vm:FindFirstChildWhichIsA("BasePart", true)
	for _, p in vm:GetDescendants() do
		if p:IsA("BasePart") then p.Anchored, p.CastShadow, p.CanCollide, p.CanQuery = p == root, false, false, false end
	end
	local cf, size = vm:GetBoundingBox()
	vm.WorldPivot = CFrame.new(cf.Position - Vector3.new(0, size.Y * 0.38, 0)) -- swing from the grip
	vm:ScaleTo(vm:GetScale() * (1.55 / math.max(size.Y, 0.1)))
	new("Highlight", vm, { FillTransparency = 1, OutlineColor = Color3.fromRGB(255, 236, 200), OutlineTransparency = 0.7, DepthMode = Enum.HighlightDepthMode.Occluded })
	local _, sz = vm:GetBoundingBox()
	local a0 = new("Attachment", root, { Position = root.CFrame:PointToObjectSpace(vm:GetBoundingBox().Position + Vector3.new(0, sz.Y * 0.45, 0)) })
	local a1 = new("Attachment", root, { Position = a0.Position + Vector3.new(0.6, 0, 0) })
	vmTrail = new("Trail", root, { Attachment0 = a0, Attachment1 = a1, Lifetime = 0.12, LightEmission = 0.8, Color = ColorSequence.new(WHITE), Transparency = NumberSequence.new(0.3, 1), Enabled = false })
	vm.Parent = cam
end

-- Input: tap/click a block (first person: the crosshair), hold to keep digging; DIG digs what the crosshair looks at
local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Include
local function pickRay(ray)
	if not blocks then return nil end
	params.FilterDescendantsInstances = { blocks }
	local res = workspace:Raycast(ray.Origin, ray.Direction * 60, params)
	local p = res and res.Instance
	if p and p.Parent == blocks and not p:GetAttribute("Fake") then
		local hd = head()
		if hd and (hd.Position - p.Position).Magnitude <= C.REACH then return p, res end
	end
	return nil
end
local function blockAt(screenPos)
	return pickRay(cam:ScreenPointToRay(screenPos.X, screenPos.Y))
end
local function blockAtCross()
	local vs = cam.ViewportSize
	return pickRay(cam:ViewportPointToRay(vs.X / 2, vs.Y / 2))
end
local function tutorialBlock()
	local t = state and state.target
	local p = t and blocks and blocks:FindFirstChild(t[1] .. "_" .. t[2] .. "_" .. t[3])
	local hd = head()
	if p and hd and (hd.Position - p.Position).Magnitude <= C.REACH then return p, nil end
	return nil
end
local function blockBelow() -- DIG with nothing in the crosshair digs the block under your feet
	local h = hrp()
	if not h or not state or not blocks then return nil end
	local W = C.MINE_W
	local feet = h.Position - Vector3.new(0, 3, 0)
	local r = math.floor((-C.CRUST * B - feet.Y) / B) + 1
	local c = math.floor((feet.X - state.ox) / B + W / 2) + 1
	local d = math.floor((feet.Z - state.oz) / B + W / 2) + 1
	local p = blocks:FindFirstChild((r + 1) .. "_" .. c .. "_" .. d) or blocks:FindFirstChild(r .. "_" .. c .. "_" .. d)
	return p, nil
end
local function digTarget() -- the DIG button: the tutorial block, straight down when you look down (or must dig down), else the crosshair
	local p, res = tutorialBlock()
	if p then return p, res end
	if (state and state.step == 2) or cam.CFrame.LookVector.Y < -0.75 then
		p, res = blockBelow()
		if p then return p, res end
	end
	p, res = blockAtCross()
	if p then return p, res end
	return blockBelow()
end

local lastHitPos, lastHitNormal = nil, nil
local nextTry = 0
local function digPart(p, res)
	if not p then return end
	swingT0 = os.clock()
	sfx("swing", 1.1)
	R.Dig:FireServer(p)
	lastHitPos, lastHitNormal = res and res.Position or p.Position, res and res.Normal or Vector3.yAxis
	burst(lastHitPos, lastHitNormal, p.Color:Lerp(WHITE, 0.4), 6)
	shake(0.12)
	pop(cross, 1.6, 0.25)
end

local holding, holdPos, digHeld = nil, Vector2.zero, false
UIS.InputBegan:Connect(function(input, gp)
	if gp or hatchBusy or not inMine then return end
	local t = input.UserInputType
	if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
		holding, holdPos = input, Vector2.new(input.Position.X, input.Position.Y)
		local p, res
		if t == Enum.UserInputType.MouseButton1 then p, res = blockAtCross() else p, res = blockAt(holdPos) end
		if p and os.clock() >= nextTry then
			nextTry = os.clock() + C.DIG_COOLDOWN + 0.03
			digPart(p, res)
		end
	elseif input.KeyCode == Enum.KeyCode.E or input.KeyCode == Enum.KeyCode.ButtonR2 then
		digHeld = true
	end
end)
UIS.InputChanged:Connect(function(input)
	if holding and input == holding then holdPos = Vector2.new(input.Position.X, input.Position.Y) end
end)
UIS.InputEnded:Connect(function(input)
	if input == holding then holding = nil end
	if input.KeyCode == Enum.KeyCode.E or input.KeyCode == Enum.KeyCode.ButtonR2 then digHeld = false end
end)
digBtn.MouseButton1Down:Connect(function() digHeld = true end)
digBtn.Activated:Connect(function() -- a single tap (and scripted clicks) digs once
	if inMine and os.clock() >= nextTry then
		local p, res = digTarget()
		if p then
			nextTry = os.clock() + C.DIG_COOLDOWN + 0.03
			digPart(p, res)
		end
	end
end)
digBtn.MouseButton1Up:Connect(function() digHeld = false end)
digBtn.MouseLeave:Connect(function() digHeld = false end)

railForge.Activated:Connect(function() forgeUI.toggle() end)
oddsClose.Activated:Connect(function() closePanel(odds) end)
mapClose.Activated:Connect(function() closePanel(mapP) end)
railLift.Activated:Connect(function() R.Surface:FireServer((inMine or inCave) and "up" or "down") end)
sellBtn.Activated:Connect(function() R.Sell:FireServer() end)

-- Keyboard: first person locks the mouse, so every rail button also has a key (shown on the button on PC)
local KEYS = { [Enum.KeyCode.G] = railForge, [Enum.KeyCode.Q] = railLift }
if UIS.KeyboardEnabled then
	for key, b in KEYS do keyCap(b, key.Name, UDim2.fromScale(0.24, 0.24), UDim2.fromScale(0.76, 0.22)) end
	keyCap(digBtn, "E", UDim2.fromScale(0.11, 0.42), UDim2.fromScale(0.88, 0.48))
end
UIS.InputBegan:Connect(function(input, gp)
	if gp or hatchBusy then return end
	local k = input.KeyCode
	if k == Enum.KeyCode.Q then
		R.Surface:FireServer((inMine or inCave) and "up" or "down")
	elseif k == Enum.KeyCode.G then
		forgeUI.toggle()
	elseif k == Enum.KeyCode.Return and sellPop.Visible then
		R.Sell:FireServer()
	end
end)

-- Custom interaction prompts (the user, 2026-11-08: no default Roblox prompt buttons). A cream keycap and a butter tooltip
-- bubble with a pointer float over the object: they pop in, bob, fill while held and squash when used. Mouse and touch press
-- the bubble itself; keys and gamepad buttons work as usual. Prompts carry Style = Custom (HubBuilder, PixelServer).
local PPS = game:GetService("ProximityPromptService")
local promptUI = {}
local function promptScale() return math.clamp(workspace.CurrentCamera.ViewportSize.Y / 720, 0.7, 1.4) end
PPS.PromptShown:Connect(function(prompt, inputType)
	if prompt.Style ~= Enum.ProximityPromptStyle.Custom or promptUI[prompt] then return end
	local k = promptScale()
	local adornee = prompt.Parent
	local lift = adornee:IsA("BasePart") and adornee.Size.Y / 2 + 2 or 2
	-- drawn in screen space and moved to the object every frame, so it shares the HUD's pixel scale
	local bb = new("Frame", gui, { Name = "PromptUI", BackgroundTransparency = 1, Size = UDim2.fromOffset(260 * k, 96 * k), AnchorPoint = Vector2.new(0.62, 1), ZIndex = 2 })
	local root = new("TextButton", bb, { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", AutoButtonColor = false })
	local sc = new("UIScale", root, { Scale = 0.35 })
	local bubble = new("Frame", root, { Name = "Bubble", Size = UDim2.fromScale(0.76, 0.78), Position = UDim2.fromScale(1, 0.02), AnchorPoint = Vector2.new(1, 0) })
	skin(bubble, "card")
	local action = text(bubble, prompt.ActionText, UDim2.fromScale(0.72, 0.36), UDim2.fromScale(0.57, 0.36), Vector2.new(0.5, 0.5), INK, 700, false)
	local object = text(bubble, prompt.ObjectText, UDim2.fromScale(0.68, 0.22), UDim2.fromScale(0.57, 0.66), Vector2.new(0.5, 0.5), INK, 700, false) -- full ink: the soft plum was too faint on the butter bubble (Gemini HUD v5 r1)
	if prompt.ObjectText == "" then
		object.Visible = false
		action.Position = UDim2.fromScale(0.57, 0.46)
	end
	new("ImageLabel", root, {
		Name = "Pointer", BackgroundTransparency = 1, Image = SPRITE.pointer, ScaleType = Enum.ScaleType.Fit,
		Size = UDim2.fromScale(0.12, 0.2), Position = UDim2.fromScale(0.62, 0.74), AnchorPoint = Vector2.new(0.5, 0), ZIndex = 2,
	})
	local spark = new("ImageLabel", bubble, {
		BackgroundTransparency = 1, Image = SPRITE.sparkle, ScaleType = Enum.ScaleType.Fit,
		Size = UDim2.fromScale(0.13, 0.34), Position = UDim2.fromScale(0.97, 0.04), AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 4,
	})
	local cap = new("Frame", root, { Name = "Key", Size = UDim2.fromScale(0.2, 0.56), Position = UDim2.fromScale(0.27, 0.41), AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 3 })
	skin(cap, "keycap")
	new("UIAspectRatioConstraint", cap, { AspectRatio = 16 / 17 })
	if inputType == Enum.ProximityPromptInputType.Gamepad then
		new("ImageLabel", cap, { BackgroundTransparency = 1, Image = UIS:GetImageForKeyCode(prompt.GamepadKeyCode), Size = UDim2.fromScale(0.6, 0.6), Position = UDim2.fromScale(0.5, 0.42), AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 4 })
	else
		local key = inputType == Enum.ProximityPromptInputType.Touch and "TAP" or UIS:GetStringForKeyCode(prompt.KeyboardKeyCode)
		local kt = text(cap, key, UDim2.fromScale(#key > 1 and 0.74 or 0.5, 0.42), UDim2.fromScale(0.5, 0.42), Vector2.new(0.5, 0.5), INK, 700, false)
		kt.ZIndex = 4
	end
	local hold = new("Frame", bubble, { Size = UDim2.fromScale(0, 0.08), Position = UDim2.fromScale(0.1, 0.82), BackgroundColor3 = Color3.fromRGB(63, 156, 132), BorderSizePixel = 0, ZIndex = 3 })
	tween(sc, 0.32, { Scale = 1 }, Enum.EasingStyle.Back)
	local bob = TweenService:Create(root, TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Position = UDim2.fromScale(0, -0.06) })
	bob:Play()
	local twinkle = TweenService:Create(spark, TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Rotation = 45, ImageTransparency = 0.5 })
	twinkle:Play()
	root.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then prompt:InputHoldBegin() end
	end)
	root.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then prompt:InputHoldEnd() end
	end)
	local conns = {
		prompt.PromptButtonHoldBegan:Connect(function()
			skin(cap, "keycapDown")
			hold.Size = UDim2.fromScale(0, 0.08)
			tween(hold, prompt.HoldDuration, { Size = UDim2.fromScale(0.8, 0.08) }, Enum.EasingStyle.Linear)
		end),
		prompt.PromptButtonHoldEnded:Connect(function()
			skin(cap, "keycap")
			tween(hold, 0.15, { Size = UDim2.fromScale(0, 0.08) })
		end),
		prompt.Triggered:Connect(function()
			sc.Scale = 0.8
			tween(sc, 0.45, { Scale = 1 }, Enum.EasingStyle.Elastic)
			skin(cap, "keycapDown")
			task.delay(0.12, function() if cap.Parent then skin(cap, "keycap") end end)
			if sfxClick then sfxClick() end
		end),
	}
	promptUI[prompt] = { bb = bb, sc = sc, conns = conns, tweens = { bob, twinkle }, adornee = adornee, lift = lift }
end)
PPS.PromptHidden:Connect(function(prompt)
	local u = promptUI[prompt]
	if not u then return end
	promptUI[prompt] = nil
	for _, c in u.conns do c:Disconnect() end
	for _, t in u.tweens do t:Cancel() end
	tween(u.sc, 0.14, { Scale = 0.3 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	task.delay(0.15, function() u.bb:Destroy() end)
end)
RunService.RenderStepped:Connect(function()
	local cam = workspace.CurrentCamera
	for _, u in promptUI do
		local a = u.adornee
		local p = (a:IsA("BasePart") and a.Position or (a:IsA("Attachment") and a.WorldPosition or Vector3.zero)) + Vector3.new(0, u.lift, 0)
		local v, on = cam:WorldToScreenPoint(p)
		u.bb.Visible = on
		u.bb.Position = UDim2.fromOffset(v.X, v.Y)
	end
end)
PPS.PromptTriggered:Connect(function(prompt) -- client-only stations
	if prompt.Parent and prompt.Parent:GetAttribute("Station") == "odds" then
		if odds.Visible then closePanel(odds) else openPanel(odds) end
	end
end)

-- State from the server
local STEPS = {
	"Tap the glowing block to dig!",
	"Dig down to the shiny gold vein!",
	"Backpack full! Sell your ore!",
	"Open the Forge and buy a new pickaxe!",
	"A fossil egg is buried below. Dig it out!",
	"Your crew digs with you. Go deeper!",
}
local stepShown, stepDoneAt, stepExpired = "", nil, false
local function stepMessage()
	if not state then return "" end
	if not inMine and state.step <= 2 then return C.CAVES_ON and "Ride the minecart down into the mine!" or "Jump into the glowing mine shaft!" end
	if not inMine and state.step == 5 then return "Ride the minecart back down to find the egg!" end
	return STEPS[state.step] or ""
end
R.State.OnClientEvent:Connect(function(s)
	local prev = state
	state = s
	if not blocks then
		blocks = workspace:WaitForChild("Shafts"):WaitForChild("Shaft_" .. plr.UserId):WaitForChild("Blocks")
		for _, p in blocks:GetChildren() do tagBlock(p) end
		blocks.ChildAdded:Connect(function(p)
			task.defer(tagBlock, p)
		end)
		local deco = blocks.Parent:WaitForChild("Deco", 5)
		if deco then
			deco.ChildAdded:Connect(function(f)
				task.defer(function()
					for _, d in f:GetDescendants() do
						if d:IsA("Texture") and d.Parent:GetAttribute("Ripple") then table.insert(ripples, d) end
					end
				end)
			end)
		end
		local hub = workspace:FindFirstChild("Hub")
		for _, l in hub and hub:GetDescendants() or {} do -- hub signs get the pixel font too
			if l:IsA("TextLabel") then PixelText.attach(l, 700) end
		end
	end
	setGold(s.gold)
	if not prev then goldShown = s.gold end
	local caving = plr:GetAttribute("InCave") == true -- no bag limit in the caves: the pill counts the ore not yet banked at camp
	bagText.Text = caving and ("ORE " .. s.bag .. "  UNBANKED") or ("BAG " .. s.bag .. " / " .. s.cap)
	local full = not caving and s.bag >= s.cap
	tween(bagFill, 0.25, { Size = UDim2.fromScale(math.clamp(s.bag / (caving and 40 or s.cap), 0, 1), 1), BackgroundColor3 = full and PINK or BUTTER }, Enum.EasingStyle.Back)
	if full and not sellPop.Visible then openPanel(sellPop) end
	if not full and sellPop.Visible then closePanel(sellPop) end
	sellInfo.Text = s.bag .. " ORE READY TO SELL"
	eggPill.Visible = (s.eggs or 0) > 0
	eggText.Text = tostring(s.eggs or 0)
	pityText.Text = "Legendary or better in " .. math.max(1, C.PITY - (s.pity or 0)) .. " eggs at most"
	forgeUI.refresh()
	syncPets()
end)

;(function() -- the forge (ReplicatedStorage.Shared.ForgeUI; moved out of this script for the 200,000-character limit)
	require(RS.Shared:WaitForChild("ForgeUI")).start({
		RS = RS, UIS = UIS, RunService = RunService, C = C, R = R, cam = cam, tween = tween, commas = commas,
		DEEP = DEEP, SPRITE = SPRITE, ICON = ICON, INK = INK, WHITE = WHITE, MINT = MINT, PINK = PINK, LILAC = LILAC,
		BUTTER = BUTTER, SKY = SKY, gui = gui, new = new, S = S, fit = fit, text = text, panel = panel,
		icon = icon, scaler = scaler, pop = pop, openPanel = openPanel, closePanel = closePanel, sfxClick = sfxClick, button = button, setKind = setKind,
		ribbonTitle = ribbonTitle, closeButton = closeButton, forge = forge, forgeUI = forgeUI, toast = toast, sfx = sfx, anchor = anchor, shake = shake,
		head = head, PLUM_SOFT = PLUM_SOFT, scrim = scrim, fx = fx, burst = burst,
		getState = function() return state end,
	})
end)()


-- Gems in the HUD and the daily chest show (feedback batch phase 3, roadmap i52-i53). The gem pill counts up and pops when
-- the server grants gems (rare deposit, perfect grade, daily chest); the daily chest drops in, shakes three times harder each
-- time, bursts open with a flash and rays, coins and gems fly into the pills, and a 7-day streak track shows the run.
;(function()
	local GuiService = game:GetService("GuiService")
	local CHEST = { closed = "rbxassetid://97587431872757", open = "rbxassetid://130450967787337" } -- art/icons_soft/out (ChatGPT)
	task.spawn(function() -- load the chest art up front, or the open frame blinks empty on first use
		local warm = {}
		for _, id in CHEST do table.insert(warm, new("ImageLabel", nil, { Image = id })) end
		pcall(function() game:GetService("ContentProvider"):PreloadAsync(warm) end)
	end)
	local FX_GLOW, FX_RAYS = "rbxassetid://77591933607769", "rbxassetid://98789616938156"
	local DEEP_GEM = Color3.fromRGB(214, 74, 126)
	-- the gem pill, right of the gold pill
	local gemPill = panel(gui, S(128, 46), S(198, 18), nil, "pillPink")
	fit(gemPill, 128, 46)
	gemPill.Name = "GemPill"
	local gemIc = icon(gemPill, "gem", UDim2.fromScale(0.34, 0.74), UDim2.fromScale(0.06, 0.5), Vector2.new(0, 0.5))
	new("UIAspectRatioConstraint", gemIc, { AspectRatio = 1 })
	local gemText = text(gemPill, "0", UDim2.fromScale(0.5, 0.56), UDim2.fromScale(0.44, 0.5), Vector2.new(0, 0.5), DEEP_GEM, 700, false)
	gemText.TextXAlignment = Enum.TextXAlignment.Left
	eggPill.Position = S(320, 84) -- the egg pill moves under the gem pill's row, right of the bag
	local shown, goal = nil, 0
	RunService.RenderStepped:Connect(function(dt)
		if shown and shown ~= goal then
			shown += (goal - shown) * math.min(1, dt * 8)
			if math.abs(goal - shown) < 0.5 then shown = goal end
			gemText.Text = commas(math.floor(shown + 0.5))
		end
	end)
	R.State.OnClientEvent:Connect(function(s)
		local g = s.gems or 0
		if shown == nil then shown = g gemText.Text = commas(g) end
		if g > goal and shown then
			pop(gemPill, 1.2)
			tween(gemIc, 0.3, { Rotation = 20 }).Completed:Connect(function() tween(gemIc, 0.4, { Rotation = 0 }, Enum.EasingStyle.Elastic) end)
		end
		goal = g
	end)

	-- the daily chest show, in its own layer above everything
	local layer = new("ScreenGui", gui.Parent, { Name = "DailyChest", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 12, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Enabled = false })
	local scrim = new("TextButton", layer, { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(26, 18, 40), BackgroundTransparency = 1, Text = "", AutoButtonColor = false })
	local rays = new("ImageLabel", layer, { Image = FX_RAYS, ImageColor3 = Color3.fromRGB(255, 196, 228), BackgroundTransparency = 1, ImageTransparency = 1, Size = S(560, 560), Position = S(640, 268), AnchorPoint = Vector2.new(0.5, 0.5) })
	new("UIAspectRatioConstraint", rays, { AspectRatio = 1, DominantAxis = Enum.DominantAxis.Height })
	local glow = new("ImageLabel", layer, { Image = FX_GLOW, ImageColor3 = Color3.fromRGB(255, 220, 160), BackgroundTransparency = 1, ImageTransparency = 1, Size = S(420, 420), Position = S(640, 268), AnchorPoint = Vector2.new(0.5, 0.5) })
	new("UIAspectRatioConstraint", glow, { AspectRatio = 1, DominantAxis = Enum.DominantAxis.Height })
	local chest = new("ImageLabel", layer, { Image = CHEST.closed, BackgroundTransparency = 1, Size = S(250, 250), Position = S(640, 268), AnchorPoint = Vector2.new(0.5, 0.5), ScaleType = Enum.ScaleType.Fit })
	new("UIAspectRatioConstraint", chest, { AspectRatio = 1, DominantAxis = Enum.DominantAxis.Height })
	local title = panel(layer, S(440, 84), S(640, 70), Vector2.new(0.5, 0.5), "ribbonPink")
	fit(title, 440, 84)
	local titleT = text(title, "DAILY CHEST", UDim2.fromScale(0.62, 0.52), UDim2.fromScale(0.5, 0.42), Vector2.new(0.5, 0.5), WHITE)
	titleT.TextStrokeColor3 = DEEP.ribbonPink
	local card = panel(layer, S(640, 210), S(640, 486), Vector2.new(0.5, 0.5), "panel") -- the kit card holding rewards, streak and COLLECT
	fit(card, 640, 210)
	card.Visible = false
	local reward = panel(layer, S(420, 64), S(640, 418), Vector2.new(0.5, 0.5), "pill")
	fit(reward, 420, 64)
	local rCoin = icon(reward, "coin", UDim2.fromScale(0.12, 0.62), UDim2.fromScale(0.12, 0.5), Vector2.new(0.5, 0.5))
	new("UIAspectRatioConstraint", rCoin, { AspectRatio = 1 })
	local rGold = text(reward, "", UDim2.fromScale(0.3, 0.5), UDim2.fromScale(0.2, 0.5), Vector2.new(0, 0.5), Color3.fromRGB(184, 122, 26), 700, false)
	rGold.TextXAlignment = Enum.TextXAlignment.Left
	local rGemI = icon(reward, "gem", UDim2.fromScale(0.12, 0.62), UDim2.fromScale(0.58, 0.5), Vector2.new(0.5, 0.5))
	new("UIAspectRatioConstraint", rGemI, { AspectRatio = 1 })
	local rGems = text(reward, "", UDim2.fromScale(0.3, 0.5), UDim2.fromScale(0.66, 0.5), Vector2.new(0, 0.5), DEEP_GEM, 700, false)
	rGems.TextXAlignment = Enum.TextXAlignment.Left
	local track = new("Frame", layer, { Size = S(560, 56), Position = S(640, 500), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1 })
	local bar = new("Frame", track, { Size = UDim2.fromScale(6 / 7, 0.22), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Color3.fromRGB(226, 218, 246), BorderSizePixel = 0 })
	new("UICorner", bar, { CornerRadius = UDim.new(0.5, 0) })
	new("UIStroke", bar, { Color = LILAC, Thickness = 2 })
	local barFill = new("Frame", bar, { Size = UDim2.fromScale(0, 1), BackgroundColor3 = BUTTER, BorderSizePixel = 0 })
	new("UICorner", barFill, { CornerRadius = UDim.new(0.5, 0) })
	local streakT = text(track, "", UDim2.fromScale(0.4, 0.36), UDim2.fromScale(0.5, -0.22), Vector2.new(0.5, 0.5), PLUM_SOFT, 700, false)
	local days = {}
	for d = 1, 7 do
		local c = new("Frame", track, { Size = UDim2.fromScale(0.11, 0.9), Position = UDim2.fromScale((d - 0.5) / 7, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), BorderSizePixel = 0 })
		new("UIAspectRatioConstraint", c, { AspectRatio = 1 })
		new("UICorner", c, { CornerRadius = UDim.new(0.5, 0) })
		local st = new("UIStroke", c, { Thickness = 3 })
		local l = text(c, tostring(d), UDim2.fromScale(0.6, 0.55), UDim2.fromScale(0.5, 0.5), Vector2.new(0.5, 0.5), WHITE)
		if d == 7 then -- the day 7 jackpot: a little chest instead of the number
			l.Visible = false
			new("ImageLabel", c, { Image = CHEST.closed, BackgroundTransparency = 1, Size = UDim2.fromScale(1.25, 1.25), Position = UDim2.fromScale(0.5, 0.45), AnchorPoint = Vector2.new(0.5, 0.5), ScaleType = Enum.ScaleType.Fit, ZIndex = 3 })
		end
		days[d] = { c = c, st = st, l = l }
	end
	local collect = button(layer, "COLLECT", S(220, 64), S(640, 560), Vector2.new(0.5, 0.5), "mint", "coin")
	fit(collect, 220, 64)
	local busy, spin = false, nil
	local flyLayer = new("ScreenGui", gui.Parent, { Name = "RewardFly", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 13 })
	local fly
	fly = function(iconName, from, toObj, n, delay0)
		local inset = GuiService:GetGuiInset()
		for k = 1, n do
			task.delay(delay0 + k * 0.05, function()
				local to = toObj.AbsolutePosition + toObj.AbsoluteSize * Vector2.new(0.15, 0.5) + inset
				local ic = icon(flyLayer, iconName, UDim2.fromOffset(34, 34), from, Vector2.new(0.5, 0.5))
				ic.ZIndex = 20
				local mid = from + UDim2.fromOffset(math.random(-160, 160), -math.random(80, 180))
				tween(ic, 0.35, { Position = mid, Rotation = math.random(-90, 90) }, Enum.EasingStyle.Quad, Enum.EasingDirection.Out).Completed:Connect(function()
					tween(ic, 0.4, { Position = UDim2.fromOffset(to.X, to.Y), Size = UDim2.fromOffset(20, 20) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In).Completed:Connect(function()
						ic:Destroy()
						sfx("coin", 1 + k * 0.03)
					end)
				end)
			end)
		end
	end
	forgeUI.fly = fly -- shared: selling ore flies coins too
	local function show(gold, streak, gems)
		if busy then return end
		busy = true
		layer.Enabled = true
		chest.Image, chest.Rotation = CHEST.closed, 0
		rays.ImageTransparency, glow.ImageTransparency, scrim.BackgroundTransparency = 1, 1, 1
		titleT.Text = "DAY " .. streak .. " CHEST"
		rGold.Text, rGems.Text = "+" .. commas(gold), "+" .. commas(gems)
		for _, o in { title, reward, track, collect, card } do o.Visible = false end
		barFill.Size = UDim2.fromScale(0, 1)
		streakT.Text = streak >= 7 and "7 DAY STREAK! JACKPOT" or (streak .. " DAY STREAK  -  DAY 7 JACKPOT")
		tween(scrim, 0.25, { BackgroundTransparency = 0.25 })
		-- drop in
		chest.Position = S(640, 120)
		scaler(chest).Scale = 0.8
		tween(chest, 0.45, { Position = S(640, 268) }, Enum.EasingStyle.Bounce)
		tween(scaler(chest), 0.45, { Scale = 1 }, Enum.EasingStyle.Back)
		title.Visible = true
		pop(title, 0.6, 0.35)
		-- three shakes, each harder and higher in pitch
		for k = 1, 3 do
			task.delay(0.55 + (k - 1) * 0.32, function()
				sfx("swing", 0.8 + k * 0.15)
				local a = 4 + k * 3
				tween(scaler(chest), 0.08, { Scale = 1 + k * 0.04 })
				tween(chest, 0.06, { Rotation = a }).Completed:Connect(function()
					tween(chest, 0.06, { Rotation = -a }).Completed:Connect(function()
						tween(chest, 0.1, { Rotation = 0 }, Enum.EasingStyle.Back)
					end)
				end)
			end)
		end
		-- burst open: a flash, rays and glow, the lid flips (open art), coins and gems fly to the pills
		task.delay(1.6, function()
			chest.Image = CHEST.open
			sfx("upgrade", 1)
			sfx("sparkle", 1.2)
			scaler(chest).Scale = 1.25
			tween(scaler(chest), 0.35, { Scale = 1 }, Enum.EasingStyle.Back)
			glow.ImageTransparency, rays.ImageTransparency = 0, 0.2
			scaler(glow).Scale = 0.4
			tween(scaler(glow), 0.4, { Scale = 1 }, Enum.EasingStyle.Back)
			tween(glow, 0.6, { ImageTransparency = 0.35 })
			if spin then spin:Disconnect() end
			spin = RunService.RenderStepped:Connect(function() rays.Rotation = os.clock() * 20 % 360 end)
			local from = S(640, 250)
			fly("coin", from, goldPill, 10, 0.1)
			fly("gem", from, gemPill, math.min(8, gems), 0.25)
			card.Visible, reward.Visible = true, true
			pop(card, 0.8, 0.3)
			pop(reward, 0.6, 0.35)
			shake(0.6)
			for k = 1, 8 do -- four-point sparkles pop round the open chest
				local a = k / 8 * math.pi * 2
				local sp = new("ImageLabel", layer, { Image = SPRITE.sparkle, BackgroundTransparency = 1, Size = S(46, 46), Position = S(640 + math.cos(a) * 150, 262 + math.sin(a) * 120), AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 5 })
				new("UIAspectRatioConstraint", sp, { AspectRatio = 1 })
				scaler(sp).Scale = 0
				task.delay(k * 0.04, function()
					tween(scaler(sp), 0.25, { Scale = 1.2 }, Enum.EasingStyle.Back).Completed:Connect(function()
						tween(scaler(sp), 0.35, { Scale = 0 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In).Completed:Connect(function() sp:Destroy() end)
					end)
				end)
			end
		end)
		-- the streak track fills up to today, today pops
		task.delay(2.1, function()
			track.Visible = true
			tween(barFill, 0.5, { Size = UDim2.fromScale(math.clamp((streak - 1) / 6, 0, 1), 1) }, Enum.EasingStyle.Quad)
			for d, o in days do
				local done, today = d < streak, d == streak
				o.c.BackgroundColor3 = (done or today) and (d == 7 and PINK or BUTTER) or Color3.fromRGB(226, 218, 246)
				o.st.Color = (done or today) and Color3.fromRGB(196, 138, 46) or LILAC
				o.l.TextColor3 = (done or today) and WHITE or PLUM_SOFT
				scaler(o.c).Scale = 0.3
				task.delay(d * 0.05, function() tween(scaler(o.c), 0.3, { Scale = today and 1.25 or 1 }, Enum.EasingStyle.Back) end)
			end
		end)
		task.delay(2.6, function()
			collect.Visible = true
			pop(collect, 0.5, 0.3)
		end)
	end
	local function hide()
		if not collect.Visible then return end
		tween(scrim, 0.2, { BackgroundTransparency = 1 })
		for _, o in { chest, title, reward, track, collect, rays, glow, card } do tween(scaler(o), 0.18, { Scale = 0 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In) end
		task.delay(0.22, function()
			layer.Enabled = false
			for _, o in { chest, title, reward, track, collect, rays, glow, card } do scaler(o).Scale = 1 end
			if spin then spin:Disconnect() spin = nil end
			busy = false
		end)
	end
	collect.Activated:Connect(hide)
	scrim.Activated:Connect(hide)

	R.Fx.OnClientEvent:Connect(function(kind, ...)
		if kind == "dailyChest" then
			local gold, streak, gems = ...
			show(gold, streak, gems or 0)
		elseif kind == "chestWait" then
			local secs = ...
			toast("Next chest in " .. math.floor(secs / 3600) .. " h " .. math.floor(secs % 3600 / 60) .. " m", LILAC)
		elseif kind == "noEggs" then
			local short = ...
			toast(short and ("An egg roll costs " .. C.EGG_GEMS .. " gems: " .. short .. " more to go!") or "No eggs yet!", LILAC, true)
			pop(gemPill, 1.2)
		elseif kind == "gemSpent" then
			local n = ...
			toast("-" .. n .. " GEMS: ROLLING AN EGG", PINK)
		elseif kind == "mgEnd" then
			local gems = select(7, ...)
			if gems and gems > 0 then
				task.delay(1.0, function()
					toast("+" .. gems .. " GEM" .. (gems > 1 and "S" or "") .. "!", DEEP_GEM, true)
					local inset = game:GetService("GuiService"):GetGuiInset()
					local c = workspace.CurrentCamera.ViewportSize / 2
					fly("gem", UDim2.fromOffset(c.X, c.Y + inset.Y), gemPill, gems * 2, 0)
				end)
			end
		end
	end)
	gemPill:SetAttribute("Ready", true)
end)()

-- Caves (cave rework, refs LGT-01, HUD-01): torch meter and fear badge bottom left; the compass to camp lives on the minimap.
-- The torch dims from full to its dimmest glow over C.TORCH.time (5 minutes); inside Camp 1's ring it relights and fear clears.
-- shortcut: the torch and fear run on the client for the prototype; move them to the server when gloomling catches cost ore.
local caveHud, cave, caveLighting, caveStep -- one scope for the cave HUD keeps the script under Luau's 200-local limit
do
	caveHud = new("Frame", gui, { Name = "CaveHud", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false })
	local torchPill = panel(caveHud, S(270, 52), S(20, 470), nil, "pillButter")
	fit(torchPill, 270, 52)
	torchPill.Name = "TorchPill"
	local flameBox = new("Frame", torchPill, { Size = UDim2.fromScale(0.12, 0.62), Position = UDim2.fromScale(0.05, 0.5), AnchorPoint = Vector2.new(0, 0.5), BackgroundColor3 = Color3.fromRGB(255, 150, 60), BorderSizePixel = 0, ZIndex = 3 })
	new("UIAspectRatioConstraint", flameBox, { AspectRatio = 0.75 })
	local flameCore = new("Frame", flameBox, { Size = UDim2.fromScale(0.5, 0.55), Position = UDim2.fromScale(0.5, 0.62), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Color3.fromRGB(255, 236, 160), BorderSizePixel = 0, ZIndex = 4 })
	local torchText = text(torchPill, "TORCH 100%", UDim2.fromScale(0.72, 0.42), UDim2.fromScale(0.22, 0.08), nil, INK, 700, false)
	torchText.TextXAlignment = Enum.TextXAlignment.Left
	local torchTrack = new("Frame", torchPill, { Size = UDim2.fromScale(0.72, 0.2), Position = UDim2.fromScale(0.22, 0.62), BackgroundColor3 = INK, BorderSizePixel = 0, ZIndex = 2 })
	local torchFill = new("Frame", torchTrack, { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(255, 176, 70), BorderSizePixel = 0, ZIndex = 3 })

	local fearPill = panel(caveHud, S(270, 52), S(20, 528), nil, "pillLilac")
	fit(fearPill, 270, 52)
	fearPill.Name = "FearPill"
	local face = new("Frame", fearPill, { Size = UDim2.fromScale(0.15, 0.7), Position = UDim2.fromScale(0.04, 0.5), AnchorPoint = Vector2.new(0, 0.5), BackgroundColor3 = CREAM, BorderSizePixel = 0, ZIndex = 3 })
	new("UIAspectRatioConstraint", face, { AspectRatio = 1 })
	new("UIStroke", face, { Color = INK, Thickness = 2 })
	local eyes = {}
	for _, x in { 0.3, 0.7 } do eyes[#eyes + 1] = new("Frame", face, { Size = UDim2.fromScale(0.16, 0.2), Position = UDim2.fromScale(x, 0.38), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = INK, BorderSizePixel = 0, ZIndex = 4 }) end
	local mouth = new("Frame", face, { Size = UDim2.fromScale(0.4, 0.1), Position = UDim2.fromScale(0.5, 0.72), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = INK, BorderSizePixel = 0, ZIndex = 4 })
	local fearText = text(fearPill, "CALM", UDim2.fromScale(0.71, 0.42), UDim2.fromScale(0.23, 0.08), nil, INK, 700, false)
	fearText.TextXAlignment = Enum.TextXAlignment.Left
	local fearTrack = new("Frame", fearPill, { Size = UDim2.fromScale(0.71, 0.2), Position = UDim2.fromScale(0.23, 0.62), BackgroundColor3 = INK, BorderSizePixel = 0, ZIndex = 2 })
	local fearFill = new("Frame", fearTrack, { Size = UDim2.fromScale(0, 1), BackgroundColor3 = LILAC, BorderSizePixel = 0, ZIndex = 3 })

	local relitBanner = panel(caveHud, S(420, 54), S(640, 150), Vector2.new(0.5, 0), "card")
	fit(relitBanner, 420, 54)
	relitBanner.Visible = false
	local relitText = text(relitBanner, "TORCH RELIT", UDim2.fromScale(0.86, 0.5), UDim2.fromScale(0.5, 0.5), Vector2.new(0.5, 0.5), INK, 700, false)

	cave = { relitAt = os.clock(), saved = nil, wasInCamp = true, fuel = 1, fear = 0 }
	local Lighting = game:GetService("Lighting")
	caveLighting = function(on) -- swap the camp look for C.CAVE_LIGHT and back (each property in a pcall: some may be locked)
		if on and not cave.saved then
			cave.saved = {}
			for name, props in C.CAVE_LIGHT do
				local o = name == "Lighting" and Lighting or Lighting:FindFirstChild(name)
				if not o and name == "DepthOfField" then
					o = new("DepthOfFieldEffect", Lighting, { Name = "DepthOfField" })
					cave.dof = o
				end
				if o then
					for k, v in props do
						local ok, old = pcall(function() return o[k] end)
						if ok then
							table.insert(cave.saved, { o, k, old })
							pcall(function() o[k] = v end)
						end
					end
				end
			end
		elseif not on and cave.saved then
			for _, e in cave.saved do pcall(function() e[1][e[2]] = e[3] end) end
			cave.saved = nil
			if cave.dof then cave.dof:Destroy() cave.dof = nil end
		end
	end
	local function inCamp(pos)
		local o = C.CAVE_ORIGIN
		return Vector2.new(pos.X - o.X, pos.Z - o.Z).Magnitude < C.CAMP_RING and math.abs(pos.Y - o.Y) < 30
	end
	caveStep = function(now)
		local h = hrp()
		if not h then return end
		local here = inCamp(h.Position)
		if here then
			if cave.fuel < 0.95 and not cave.wasInCamp then -- coming home: TORCH RELIT banner (HUD-02)
				relitBanner.Visible = true
				relitText.Text = "TORCH RELIT  -  SAFE AT CAMP"
				pop(relitBanner, 1.3, 0.3)
				task.delay(2.2, function() relitBanner.Visible = false end)
			end
			cave.relitAt = now
		end
		cave.wasInCamp = here
		if plr:GetAttribute("TorchFrozen") then cave.relitAt = now end -- the server: no dimming until the first bank
		local age = plr:GetAttribute("DevTorchAge") -- Studio test hook: age the torch by this many seconds
		if age then cave.relitAt = now - age plr:SetAttribute("DevTorchAge", nil) end
		if state and cave.jobFor ~= state.pets and RS.Shared:FindFirstChild("PetJobs") then -- crew pets' cave jobs (Shared.PetJobs)
			cave.jobFor, cave.job = state.pets, require(RS.Shared.PetJobs).perks(state.pets)
		end
		local job = cave.job or { torch = 1, fear = 1, light = 0, air = 1 }
		cave.fuel = math.clamp(1 - (now - cave.relitAt) / (C.TORCH.time * job.torch), 0, 1)
		cave.fear = here and 0 or math.clamp(((1 - cave.fuel) * 1.15 - 0.1) * job.fear, 0, 1)
		-- the torch: the head lantern shrinks and dims with the fuel and flickers like a flame (LGT-01)
		local lantern = plr.Character and plr.Character:FindFirstChild("Lantern", true) -- on the torch in the left hand
		if lantern then
			local flick = math.noise(now * 6, 1.7) * 0.18 + math.noise(now * 17, 4.2) * 0.08
			lantern.Color = Color3.fromRGB(255, 196, 120)
			lantern.Range = C.TORCH.minRange + (C.TORCH.range - C.TORCH.minRange) * cave.fuel ^ 0.7 + flick * 2 + job.light
			lantern.Brightness = 0.25 + 0.6 * cave.fuel + flick * 0.4 -- soft: the torch sits low in the hand, close to the floor, and blew it out
		end
		torchFill.Size = UDim2.fromScale(cave.fuel, 1)
		torchFill.BackgroundColor3 = cave.fuel > 0.3 and Color3.fromRGB(255, 176, 70) or Color3.fromRGB(255, 110, 90)
		torchText.Text = "TORCH " .. math.floor(cave.fuel * 100 + 0.5) .. "%"
		flameBox.Size = UDim2.fromScale(0.08 + 0.05 * cave.fuel + math.abs(math.noise(now * 5)) * 0.01, 0.4 + 0.25 * cave.fuel)
		fearFill.Size = UDim2.fromScale(cave.fear, 1)
		fearFill.BackgroundColor3 = LILAC:Lerp(PINK, cave.fear)
		fearText.Text = cave.fear < 0.25 and "CALM" or (cave.fear < 0.6 and "UNEASY" or "SCARED")
		-- the face badge: eyes widen and the mouth drops open as fear rises (HUD-01 fear face)
		for _, e in eyes do e.Size = UDim2.fromScale(0.16 + cave.fear * 0.08, 0.2 + cave.fear * 0.12) end
		mouth.Size = UDim2.fromScale(0.4 - cave.fear * 0.18, 0.1 + cave.fear * 0.18)
		face.Rotation = cave.fear > 0.6 and math.sin(now * 40) * 4 * (cave.fear - 0.6) or 0
		if cave.tick then cave.tick(now, h) end
	end
end

-- Cave minimap (HUD-01, fog of war), ore glints (ORE-01) and the two extraction minigames: Perfect Strike (EXT-01) and Vein Rush
-- (EXT-02). Spec: the design board's CaveUI artboard. The server grades every swing and chisel; this only draws and sends input.
-- A function of its own, not a do block: the main chunk is at Luau's 200-register limit.
;(function()
	local D = C.DEPOSIT
	local ExtractR = R:WaitForChild("Extract")
	local PPS2 = game:GetService("ProximityPromptService")
	-- minimap: top right under the location pill, north up; a floor shows once your torchlight reaches it
	local mapPanel = panel(caveHud, S(168, 168), S(1262, 150), Vector2.new(1, 0), "panel")
	fit(mapPanel, 168, 168)
	mapPanel.Name = "Minimap"
	local view = new("Frame", mapPanel, { Size = UDim2.fromScale(0.8, 0.8), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Color3.fromRGB(18, 13, 28), BorderSizePixel = 0, ClipsDescendants = true, ZIndex = 2 })
	new("UIStroke", view, { Color = INK, Thickness = 2 })
	local canvas = new("Frame", view, { BackgroundTransparency = 1, ZIndex = 2 })
	-- compass on the minimap (the user, 2026-11-08: the top ribbon goes): north is always up, so N sits on the top rim; the camp
	-- campfire icon shows where Camp 1 is and sticks to the rim, pointing the way, once it leaves the view
	local north = panel(mapPanel, UDim2.fromScale(0.24, 0.16), UDim2.fromScale(0.5, 0.03), Vector2.new(0.5, 0.5), "pink")
	north.ZIndex = 6
	text(north, "N", UDim2.fromScale(0.6, 0.62), UDim2.fromScale(0.5, 0.46), Vector2.new(0.5, 0.5), WHITE).ZIndex = 7
	local campIcon = icon(mapPanel, "camp", UDim2.fromScale(0.2, 0.2), UDim2.fromScale(0.5, 0.5), Vector2.new(0.5, 0.5)) -- the smooth campfire icon
	campIcon.Name, campIcon.ZIndex = "CampIcon", 6
	new("UIAspectRatioConstraint", campIcon, { AspectRatio = 1 })
	local campPill = panel(caveHud, S(168, 34), S(1262, 324), Vector2.new(1, 0), "pillButter")
	fit(campPill, 168, 34)
	campPill.Name = "CampPill"
	local campDist = text(campPill, "CAMP", UDim2.fromScale(0.84, 0.5), UDim2.fromScale(0.5, 0.48), Vector2.new(0.5, 0.5), Color3.fromRGB(184, 122, 26), 700, false)
	-- each cave area its own colour (the user, 2026-11-08): camp butter, tunnels lilac, chasm teal, grotto aqua, mushroom hall pink
	local AREA = { camp = BUTTER, tunnel = LILAC, chasm = Color3.fromRGB(104, 214, 196), grotto = Color3.fromRGB(120, 200, 255), mush = Color3.fromRGB(255, 160, 200), squeeze = Color3.fromRGB(214, 160, 190) }
	local me = new("Frame", view, { Size = UDim2.fromScale(0.2, 0.2), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, ZIndex = 5 })
	local meDot = new("Frame", me, { Size = UDim2.fromScale(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.55), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = BUTTER, BorderSizePixel = 0, ZIndex = 5 })
	new("UIStroke", meDot, { Color = INK, Thickness = 1 })
	new("Frame", me, { Size = UDim2.fromScale(0.24, 0.28), Position = UDim2.fromScale(0.5, 0.16), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = CREAM, BorderSizePixel = 0, ZIndex = 5 })
	local map = { floors = {}, deps = {}, next = 0 }
	local function onMap(x, z, w) -- a square of w studs at world (x, z) on the canvas
		return UDim2.fromScale((x - w / 2 - map.lo.X) / map.span.X, (z - w / 2 - map.lo.Y) / map.span.Y), UDim2.fromScale(w / map.span.X, w / map.span.Y)
	end

	-- a starburst glint on each deposit every D.glint seconds (ORE-01): a cream 4-point star that grows and fades, its light flaring.
	-- Drawn in screen space at the deposit (like the prompts) and hidden by a raycast when rock is in the way: a 3D billboard
	-- got cut by the walls next to the cluster.
	local glints = new("Frame", caveHud, { Name = "Glints", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 1 })
	local function starburst(core, col)
		local out = core.CFrame.LookVector * Vector3.new(1, 0, 1) -- the cluster faces its wall: the star sits just in front of it
		local bb = new("Frame", glints, { Name = "Glint", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Visible = false, ZIndex = 1 })
		bb:SetAttribute("At", core.Position + (out.Magnitude > 0.1 and -out.Unit * 1.5 or Vector3.zero) + Vector3.new(0, 0.8, 0))
		local star = new("Frame", bb, { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 })
		local sc = new("UIScale", star, {})
		for _, h in { { 0.7, 0.8 }, { 0.36, 0.55 } } do -- a soft glow in the ore colour behind the rays
			new("UICorner", new("Frame", star, { Size = UDim2.fromScale(h[1], h[1]), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = col:Lerp(CREAM, 0.3), BackgroundTransparency = h[2], BorderSizePixel = 0 }), { CornerRadius = UDim.new(0.5, 0) })
		end
		for _, r in { { 1.3, 0.05, 0 }, { 0.05, 0.85, 0 }, { 0.42, 0.04, 45 }, { 0.42, 0.04, -45 } } do -- long thin rays, the horizontal one longest
			new("Frame", star, { Size = UDim2.fromScale(r[1], r[2]), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), Rotation = r[3], BackgroundColor3 = col:Lerp(CREAM, 0.65), BorderSizePixel = 0 })
		end
		new("Frame", star, { Size = UDim2.fromScale(0.14, 0.14), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), Rotation = 45, BackgroundColor3 = WHITE, BorderSizePixel = 0 })
		return bb, star, sc
	end
	local function claim(g) -- this player has mined it: hide it for them only (it grows back: Fx "regrow")
		g.claimed = true
		g.wasT = g.wasT or {}
		for _, p in g.dep:GetDescendants() do
			if p:IsA("BasePart") then g.wasT[p] = g.wasT[p] or p.Transparency p.Transparency = 1 end
			if p:IsA("ProximityPrompt") or p:IsA("PointLight") then p.Enabled = false end
		end
		g.bb.Visible = false
		if g.dot then g.dot:Destroy() g.dot = nil end
	end
	R.Fx.OnClientEvent:Connect(function(kind, dep)
		if kind == "regrow" then
			for _, g in map.deps do
				if g.dep == dep and g.claimed then
					g.claimed = false
					for _, p in g.dep:GetDescendants() do
						if p:IsA("BasePart") and g.wasT and g.wasT[p] then p.Transparency = g.wasT[p] end
						if p:IsA("ProximityPrompt") or p:IsA("PointLight") then p.Enabled = true end
					end
				end
			end
		elseif kind == "caveFrenzy" then
			toast("FRENZY!  x1.5 ORE FOR " .. dep .. " S", GOLD, true)
			shake(0.3)
		end
	end)
	local function mapBuild(caves)
		canvas:ClearAllChildren()
		for _, g in map.deps do if g.bb then g.bb:Destroy() end end
		map.caves, map.floors, map.deps = caves, {}, {}
		local x0, z0, x1, z1 = math.huge, math.huge, -math.huge, -math.huge
		local floorF = caves:FindFirstChild("Floor")
		for _, p in floorF and floorF:GetChildren() or {} do
			local a = Vector2.new(p.Position.X - p.Size.X / 2, p.Position.Z - p.Size.Z / 2)
			local b = Vector2.new(p.Position.X + p.Size.X / 2, p.Position.Z + p.Size.Z / 2)
			x0, z0, x1, z1 = math.min(x0, a.X), math.min(z0, a.Y), math.max(x1, b.X), math.max(z1, b.Y)
			table.insert(map.floors, { a = a, b = b, top = p.Position.Y + p.Size.Y / 2, theme = p:GetAttribute("Theme") })
		end
		if #map.floors == 0 then return end
		map.lo, map.span = Vector2.new(x0, z0), Vector2.new(x1 - x0, z1 - z0)
		canvas.Size = UDim2.fromScale(map.span.X / C.MAP_VIEW, map.span.Y / C.MAP_VIEW)
		local depF = caves:FindFirstChild("Deposits")
		for k, dep in depF and depF:GetChildren() or {} do
			local core = dep.PrimaryPart or dep:FindFirstChild("Core")
			if core then
				local col = C.LAYERS[dep:GetAttribute("Layer")][4][dep:GetAttribute("Ore")][2]
				local bb, star, sc = starburst(core, col)
				table.insert(map.deps, { dep = dep, core = core, col = col, light = core:FindFirstChildOfClass("PointLight"), bb = bb, at = bb:GetAttribute("At"), star = star, sc = sc, phase = (k * 0.618) % 1 * D.glint, rar = dep:GetAttribute("Ore") or 1 })
			end
		end
	end
	local function mapStep(now, h)
		local caves = workspace:FindFirstChild("Caves")
		if not caves then return end
		if caves ~= map.caves then mapBuild(caves) end
		if not map.lo then return end
		local p = h.Position
		canvas.Position = UDim2.fromScale(0.5 - (p.X - map.lo.X) / C.MAP_VIEW, 0.5 - (p.Z - map.lo.Y) / C.MAP_VIEW)
		local lv = cam.CFrame.LookVector
		me.Rotation = math.deg(math.atan2(lv.X, -lv.Z))
		local to = C.CAVE_ORIGIN - p
		local cv = Vector2.new(to.X, to.Z) / C.MAP_VIEW -- camp offset in view widths
		local edge = math.max(math.abs(cv.X), math.abs(cv.Y))
		if edge > 0.42 then cv *= 0.42 / edge end -- off the view: stick to the rim, pointing the way
		campIcon.Position = UDim2.fromScale(0.5 + cv.X * 0.8, 0.5 + cv.Y * 0.8)
		local dist = Vector2.new(to.X, to.Z).Magnitude
		campDist.Text = dist < C.CAMP_RING and "SAFE AT CAMP" or ("CAMP " .. math.floor(dist / 4 + 0.5) .. "m")
		local hold = plr:GetAttribute("DevGlint") and 0.25 -- Studio test hook: freeze every glint at its peak for captures
		for _, g in map.deps do -- glints run every frame (cheap: a scale and a light per deposit)
			if not g.claimed then
				local ph = hold or (now + g.phase) % D.glint
				local burst = ph < 0.5 and math.sin(ph / 0.5 * math.pi) or 0
				-- a constant twinkle between bursts (the user, 2026-11-08: shine all the time, stronger for rarer ore)
				local idle = (0.16 + 0.1 * g.rar) * (0.75 + 0.25 * math.sin(now * 2.4 + g.phase * 3))
				local s = math.max(idle, burst)
				local v, on = cam:WorldToScreenPoint(g.at) -- the HUD sits under the top bar inset, like the prompts
				g.bb.Visible = g.seen == true and on
				if g.bb.Visible then -- 5.5 to 8.5 studs across at its distance, by rarity
					local px = math.min((4 + 1.5 * g.rar) * cam.ViewportSize.Y / (2 * v.Z * math.tan(math.rad(cam.FieldOfView) / 2)), cam.ViewportSize.Y * 0.22)
					g.bb.Position, g.bb.Size = UDim2.fromOffset(v.X, v.Y), UDim2.fromOffset(px, px)
					g.sc.Scale = s
					g.star.Rotation = now * 12 + ph * 50
				end
				if g.light then
					g.light.Brightness = 0.5 + 0.45 * g.rar + burst * 2.5
					g.light.Range = 7 + 2 * g.rar + burst * 7
				end
			end
		end
		if now < map.next then return end
		map.next = now + 0.15
		local lantern = plr.Character and plr.Character:FindFirstChild("Lantern", true)
		local r = (lantern and lantern.Range or C.TORCH.range) + 10
		for i = #map.floors, 1, -1 do -- fog of war: reveal floors your light reaches, then forget them
			local f = map.floors[i]
			local dx = math.max(f.a.X - p.X, 0, p.X - f.b.X)
			local dz = math.max(f.a.Y - p.Z, 0, p.Z - f.b.Y)
			local dy = f.top - (p.Y - 3)
			if dx * dx + dz * dz + dy * dy < r * r then
				map.floors[i] = map.floors[#map.floors]
				map.floors[#map.floors] = nil
				new("Frame", canvas, {
					Position = UDim2.fromScale((f.a.X - map.lo.X) / map.span.X, (f.a.Y - map.lo.Y) / map.span.Y),
					Size = UDim2.fromScale((f.b.X - f.a.X) / map.span.X, (f.b.Y - f.a.Y) / map.span.Y),
					BackgroundColor3 = Color3.fromRGB(40, 30, 62):Lerp(AREA[f.theme] or LILAC, 0.45 + 0.55 * math.clamp((f.top + 40) / 50, 0, 1)), BorderSizePixel = 0, ZIndex = 2,
				})
			end
		end
		local camPos = cam.CFrame.Position
		local rp = RaycastParams.new()
		for _, g in map.deps do -- line of sight to each glint, so the always-on-top star never shows through rock
			if not g.claimed and (g.core.Position - camPos).Magnitude < 150 then
				rp.FilterDescendantsInstances = { plr.Character, g.dep }
				local to = g.at
				g.seen = workspace:Raycast(camPos, to - camPos, rp) == nil
			end
		end
		for _, g in map.deps do -- a found deposit stays on the map as a dot in its ore colour until you mine it
			if not g.claimed and not g.dot and (g.core.Position - p).Magnitude < r then
				local pos, size = onMap(g.core.Position.X, g.core.Position.Z, 5)
				g.dot = new("Frame", canvas, { Position = pos, Size = size, BackgroundColor3 = g.col, BorderSizePixel = 0, ZIndex = 3 })
				new("UIStroke", g.dot, { Color = CREAM, Thickness = 1 })
			end
		end
	end

	-- minigames: one live at a time; movement and prompts pause while it runs
	local mg
	local held = {}
	local function freeze(on)
		local hum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
		if hum and on then
			held.walk, held.jump = hum.WalkSpeed, hum.JumpHeight
			hum.WalkSpeed, hum.JumpHeight = 0, 0
		elseif hum and held.walk then
			hum.WalkSpeed, hum.JumpHeight = held.walk, held.jump
			held.walk = nil
		end
		cave.mgBusy = on -- prompts pause (the camera loop owns ProximityPromptService.Enabled)
		for _, n in { "TorchPill", "FearPill", "Minimap", "CampPill", "GoldPill", "BagPill", "Upgrades", "Surface" } do -- focus: every HUD widget steps back while a minigame is up
			local o = caveHud:FindFirstChild(n) or gui:FindFirstChild(n)
			if o then o.Visible = not on end
		end
		if vm then -- the held pickaxe covered the STRIKE button
			if on then vm.Parent = nil else vm.Parent = cam end
		end
		local compass = caveHud:FindFirstChild("Compass") -- the minigame title sits where the compass ribbon is
		if compass then compass.Visible = not on end
	end
	-- Perfect Strike (EXT-01): a needle turns once per second; strike while it crosses the 15 degree gold arc
	local ps = new("Frame", caveHud, { Name = "PerfectStrike", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false, ZIndex = 10 })
	new("Frame", ps, { Name = "Dim", Size = UDim2.new(1, 0, 1, 60), Position = UDim2.fromOffset(0, -60), BackgroundColor3 = Color3.fromRGB(26, 18, 40), BackgroundTransparency = 0.45, BorderSizePixel = 0, ZIndex = 9 })
	local dialShadow = new("Frame", ps, { Size = S(300, 300), Position = S(640, 298), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Color3.fromRGB(20, 12, 34), BackgroundTransparency = 0.45, BorderSizePixel = 0, ZIndex = 10 })
	fit(dialShadow, 1, 1)
	new("UICorner", dialShadow, { CornerRadius = UDim.new(0.5, 0) })
	local dial = new("Frame", ps, { Size = S(300, 300), Position = S(640, 290), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Color3.fromRGB(111, 88, 176), BorderSizePixel = 0, ZIndex = 10 })
	fit(dial, 1, 1)
	new("UICorner", dial, { CornerRadius = UDim.new(0.5, 0) })
	for _, ring in { { 0.965, LILAC }, { 0.93, CREAM }, { 0.86, Color3.fromRGB(185, 164, 238) }, { 0.84, Color3.fromRGB(232, 224, 252) }, { 0.36, Color3.fromRGB(214, 202, 248) } } do
		new("UICorner", new("Frame", dial, { Size = UDim2.fromScale(ring[1], ring[1]), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = ring[2], BorderSizePixel = 0, ZIndex = 10 }), { CornerRadius = UDim.new(0.5, 0) })
	end
	for i = 0, 23 do -- soft dots every 15 degrees, bigger every 45
		local t = new("Frame", dial, { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Rotation = i * 15, ZIndex = 11 })
		local d = i % 3 == 0 and 0.026 or 0.016
		new("UICorner", new("Frame", t, { Size = UDim2.fromScale(d, d), Position = UDim2.fromScale(0.5, 0.115), BackgroundColor3 = Color3.fromRGB(111, 88, 176), BackgroundTransparency = i % 3 == 0 and 0.1 or 0.45, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 11 }), { CornerRadius = UDim.new(0.5, 0) })
	end
	local arcPivot = new("Frame", dial, { Name = "Arc", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 11 })
	local function drawArc(z) -- the gold zone (15 degrees, wider with forge levels) as a fan of thin spokes, darker gold on its edges
		arcPivot:ClearAllChildren()
		local h = z / 2 - 0.75
		for a = -h, h + 0.01, 1.5 do
			local f = new("Frame", arcPivot, { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Rotation = a, ZIndex = 11 })
			new("Frame", f, { Size = UDim2.fromScale(0.022, 0.36), Position = UDim2.fromScale(0.5, 0.08), AnchorPoint = Vector2.new(0.5, 0), BackgroundColor3 = math.abs(a) > h - 0.8 and GOLD or BUTTER, BorderSizePixel = 0, ZIndex = 11 })
		end
	end
	drawArc(D.arc)
	local needle = new("Frame", dial, { Name = "Needle", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 12 })
	new("UICorner", new("Frame", needle, { Size = UDim2.fromScale(0.04, 0.4), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 1), BackgroundColor3 = INK, BorderSizePixel = 0, ZIndex = 12 }), { CornerRadius = UDim.new(0.5, 0) })
	local hub = new("Frame", dial, { Size = UDim2.fromScale(0.11, 0.11), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = BUTTER, BorderSizePixel = 0, ZIndex = 13 })
	new("UICorner", hub, { CornerRadius = UDim.new(0.5, 0) })
	new("UIStroke", hub, { Color = Color3.fromRGB(196, 138, 46), Thickness = 3 })
	local psTitleBar = panel(ps, S(560, 50), S(640, 110), Vector2.new(0.5, 0.5), "pill")
	fit(psTitleBar, 560, 50)
	psTitleBar.ZIndex = 12 -- above the minigame's dim backdrop
	local psTitle = text(psTitleBar, "PERFECT STRIKE", UDim2.fromScale(0.86, 0.44), UDim2.fromScale(0.5, 0.48), Vector2.new(0.5, 0.5), INK, 700, false)
	psTitle.ZIndex = 3
	local psPop = text(ps, "PERFECT!", S(360, 52), S(640, 290), Vector2.new(0.5, 0.5), BUTTER)
	psPop.ZIndex, psPop.Visible = 14, false
	local pipTrack = new("Frame", ps, { Size = S(130, 36), Position = S(640, 460), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Color3.fromRGB(214, 202, 248), BorderSizePixel = 0, ZIndex = 11 })
	new("UICorner", pipTrack, { CornerRadius = UDim.new(0.5, 0) })
	new("UIStroke", pipTrack, { Color = Color3.fromRGB(111, 88, 176), Thickness = 3 })
	local pips = {}
	for i = 1, D.strikes do
		pips[i] = new("Frame", ps, { Size = S(22, 22), Position = S(640 + (i - (D.strikes + 1) / 2) * 34, 460), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = CREAM, BorderSizePixel = 0, ZIndex = 12 })
		fit(pips[i], 1, 1)
		new("UICorner", pips[i], { CornerRadius = UDim.new(0.5, 0) })
		new("UIStroke", pips[i], { Color = Color3.fromRGB(111, 88, 176), Thickness = 3 })
	end
	local psHintBar = panel(ps, S(440, 36), S(640, 152), Vector2.new(0.5, 0.5), "dark")
	fit(psHintBar, 440, 36)
	psHintBar.ZIndex = 12
	local psHint = text(psHintBar, UIS.KeyboardEnabled and "STRIKE (OR SPACE) WHEN THE NEEDLE IS ON GOLD" or "TAP STRIKE WHEN THE NEEDLE IS ON GOLD", UDim2.fromScale(0.88, 0.5), UDim2.fromScale(0.5, 0.5), Vector2.new(0.5, 0.5), CREAM)
	psHint.ZIndex = 3
	-- UI juice: pastel pixel confetti and expanding rings from a point on screen
	local CONFETTI = { BUTTER, MINT, PINK, LILAC, SKY, CREAM }
	local function uiBurst(parent, at, cols, n, reach)
		for _ = 1, n do
			local sz = 0.008 + math.random() * 0.012
			local f = new("Frame", parent, { Size = UDim2.fromScale(sz, sz * 2.16), Position = at, AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = cols[math.random(#cols)], BorderSizePixel = 0, Rotation = math.random(0, 90), ZIndex = 16 })
			local a, d = math.random() * math.pi * 2, (0.5 + math.random() * 0.5) * (reach or 0.22)
			tween(f, 0.5 + math.random() * 0.25, { Position = at + UDim2.fromScale(math.cos(a) * d * 0.46, math.sin(a) * d + 0.05), Rotation = f.Rotation + math.random(-180, 180), BackgroundTransparency = 1 }, Enum.EasingStyle.Quad)
			task.delay(0.8, function() f:Destroy() end)
		end
	end
	local function uiRing(parent, at, col, delay)
		task.delay(delay or 0, function()
			local r = new("Frame", parent, { Size = S(120, 120), Position = at, AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, ZIndex = 15 })
			fit(r, 1, 1)
			new("UICorner", r, { CornerRadius = UDim.new(0.5, 0) })
			local st = new("UIStroke", r, { Color = col, Thickness = 6 })
			tween(r, 0.45, { Size = S(420, 420) }, Enum.EasingStyle.Quad)
			tween(st, 0.45, { Transparency = 1, Thickness = 1 })
			task.delay(0.5, function() r:Destroy() end)
		end)
	end
	local strikeBtn = button(ps, "STRIKE!", S(250, 74), S(640, 546), Vector2.new(0.5, 0.5), "mint", "hammer") -- under the dial (kit round 4)
	strikeBtn.ZIndex = 12

	-- Vein Rush (EXT-02): the vein drops a segment per chisel; red cracks sit on one side, chisel the other
	local vr = new("Frame", caveHud, { Name = "VeinRush", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false, ZIndex = 10 })
	new("Frame", vr, { Name = "Dim", Size = UDim2.new(1, 0, 1, 60), Position = UDim2.fromOffset(0, -60), BackgroundColor3 = Color3.fromRGB(26, 18, 40), BackgroundTransparency = 0.45, BorderSizePixel = 0, ZIndex = 9 })
	local quality = panel(vr, S(560, 84), S(640, 18), Vector2.new(0.5, 0), "card")
	fit(quality, 560, 84)
	quality.ZIndex = 12
	local qText = text(quality, "VEIN RUSH  FLAWLESS", UDim2.fromScale(0.6, 0.4), UDim2.fromScale(0.07, 0.26), nil, INK, 700, false)
	qText.TextXAlignment = Enum.TextXAlignment.Left
	local stars = {}
	for i = 1, 3 do
		stars[i] = new("ImageLabel", quality, { Image = SPRITE.star, BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit, Size = UDim2.fromScale(0.09, 0.56), Position = UDim2.fromScale(0.73 + i * 0.065, 0.46), AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 3 })
	end
	local timeBar = panel(vr, S(460, 42), S(640, 110), Vector2.new(0.5, 0), "dark")
	fit(timeBar, 460, 42)
	timeBar.ZIndex = 12
	local timeTrack = new("Frame", timeBar, { Size = UDim2.fromScale(0.9, 0.5), Position = UDim2.fromScale(0.5, 0.45), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Color3.fromRGB(30, 20, 48), BorderSizePixel = 0, ZIndex = 2 })
	new("UICorner", timeTrack, { CornerRadius = UDim.new(0.5, 0) })
	local timeFill = new("Frame", timeTrack, { Size = UDim2.fromScale(1, 1), BackgroundColor3 = MINT, BorderSizePixel = 0, ZIndex = 3 })
	new("UICorner", timeFill, { CornerRadius = UDim.new(0.5, 0) })
	local plate = new("Frame", vr, { Size = S(300, 318), Position = S(640, 459), AnchorPoint = Vector2.new(0.5, 1), BackgroundColor3 = Color3.fromRGB(74, 56, 110), BackgroundTransparency = 0.3, BorderSizePixel = 0, ZIndex = 10 })
	new("UICorner", plate, { CornerRadius = UDim.new(0.08, 0) })
	new("UIStroke", plate, { Color = LILAC, Thickness = 3, Transparency = 0.2 })
	local column = new("Frame", vr, { Size = S(280, 300), Position = S(640, 450), AnchorPoint = Vector2.new(0.5, 1), BackgroundTransparency = 1, ZIndex = 10 })
	local slots = {}
	for k = 1, 5 do -- slot 1 is the bottom segment, the one you chisel now
		local y = 1 - (k - 1) * 0.18
		local seg = new("Frame", column, { Size = UDim2.fromScale(0.32, 0.17), Position = UDim2.fromScale(0.5, y), AnchorPoint = Vector2.new(0.5, 1), BorderSizePixel = 0, ZIndex = 11, ClipsDescendants = true })
		new("UICorner", seg, { CornerRadius = UDim.new(0.22, 0) })
		new("UIStroke", seg, { Color = INK, Thickness = 2 })
		-- a cut crystal: a light top band, a dark bottom band and a pale diagonal facet
		local lite = new("Frame", seg, { Size = UDim2.fromScale(1, 0.24), BorderSizePixel = 0, ZIndex = 12 })
		local dark = new("Frame", seg, { Size = UDim2.fromScale(1, 0.24), Position = UDim2.fromScale(0, 0.76), BorderSizePixel = 0, ZIndex = 12 })
		new("Frame", seg, { Size = UDim2.fromScale(0.14, 0.62), Position = UDim2.fromScale(0.28, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), Rotation = 24, BackgroundColor3 = WHITE, BackgroundTransparency = 0.55, BorderSizePixel = 0, ZIndex = 12 })
		local lines = {}
		for side = 1, 2 do -- the red fracture running into the vein on the cracked side
			lines[side] = new("Frame", seg, { Size = UDim2.fromScale(0.3, 0.1), Position = UDim2.fromScale(side == 1 and 0 or 1, 0.55), AnchorPoint = Vector2.new(side == 1 and 0 or 1, 0.5), Rotation = side == 1 and -14 or 14, BackgroundColor3 = Color3.fromRGB(230, 50, 80), BorderSizePixel = 0, ZIndex = 13 })
		end
		local cracks = {}
		for side = 1, 2 do
			local c = new("Frame", column, { Size = UDim2.fromScale(0.34, 0.17), Position = UDim2.fromScale(side == 1 and 0.17 or 0.83, y - 0.085), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, ZIndex = 11 })
			for n, w in { 0.9, 0.62, 0.32 } do -- a red crystal spike jutting out of the vein, stepped like pixels
				local spike = new("Frame", c, { Size = UDim2.fromScale(w, 0.22), Position = UDim2.fromScale(side == 1 and 1 or 0, 0.2 + n * 0.17), AnchorPoint = Vector2.new(side == 1 and 1 or 0, 0.5), BackgroundColor3 = n == 1 and Color3.fromRGB(255, 140, 120) or Color3.fromRGB(240, 106, 100), BorderSizePixel = 0, ZIndex = 11 })
				new("UICorner", spike, { CornerRadius = UDim.new(0.5, 0) })
				new("UIStroke", spike, { Color = Color3.fromRGB(150, 56, 70), Thickness = 2 }) -- soft coral, not alarm red (kit round 4)
			end
			cracks[side] = c
		end
		slots[k] = { seg = seg, cracks = cracks, lite = lite, dark = dark, lines = lines }
	end
	local miner = new("ImageLabel", column, { Image = ICON.pick, BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit, Size = UDim2.fromScale(0.17, 0.16), Position = UDim2.fromScale(0.12, 1), AnchorPoint = Vector2.new(0.5, 1), ZIndex = 13 })
	local beatBar = panel(vr, S(200, 36), S(640, 480), Vector2.new(0.5, 0.5), "dark")
	fit(beatBar, 200, 36)
	beatBar.ZIndex = 12
	local beatText = text(beatBar, "BEAT 1 / 10", UDim2.fromScale(0.84, 0.5), UDim2.fromScale(0.5, 0.5), Vector2.new(0.5, 0.5), CREAM)
	beatText.ZIndex = 3
	local leftBtn = button(vr, "< CHISEL LEFT", S(300, 86), S(190, 470), Vector2.new(0, 1), "mint", "chisel") -- clear of the vein and the stick/jump zones
	local rightBtn = button(vr, "CHISEL RIGHT >", S(300, 86), S(1090, 470), Vector2.new(1, 1), "pink", "chisel")
	rightBtn.Icon.Rotation = 90 -- the chisel points the other way
	leftBtn.ZIndex, rightBtn.ZIndex = 12, 12
	if UIS.KeyboardEnabled then
		keyCap(leftBtn, "A", UDim2.fromScale(0.1, 0.5), UDim2.fromScale(0.06, 0.12))
		keyCap(rightBtn, "D", UDim2.fromScale(0.1, 0.5), UDim2.fromScale(0.94, 0.12))
	end
	-- the result card (both minigames): ore swatch, amount, gold value, grade and stars
	local resultDim = new("Frame", caveHud, { Name = "ResultDim", Size = UDim2.new(1, 0, 1, 60), Position = UDim2.fromOffset(0, -60), BackgroundColor3 = Color3.fromRGB(26, 18, 40), BackgroundTransparency = 0.5, BorderSizePixel = 0, ZIndex = 14, Visible = false })
	local result = panel(caveHud, S(470, 190), S(640, 270), Vector2.new(0.5, 0.5), "panel")
	fit(result, 470, 190)
	result.Name, result.Visible, result.ZIndex = "ExtractResult", false, 15
	local ribbon = ribbonTitle(result, "ORE EXTRACTED!", "ribbonPink", 0.66)
	ribbon.Size = UDim2.fromScale(0.66, 0.26)
	local swatch = new("Frame", result, { Size = UDim2.fromScale(0.2, 0.5), Position = UDim2.fromScale(0.08, 0.55), AnchorPoint = Vector2.new(0, 0.5), BorderSizePixel = 0, ZIndex = 3 })
	fit(swatch, 1, 1)
	new("UICorner", swatch, { CornerRadius = UDim.new(0.5, 0) })
	new("UIStroke", swatch, { Color = Color3.fromRGB(111, 88, 176), Thickness = 4 })
	new("UIGradient", swatch, { Rotation = 90, Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(150, 140, 175)) }) -- glossy: lit on top, shaded below
	local swGlow = new("ImageLabel", result, { Image = "rbxassetid://77591933607769", BackgroundTransparency = 1, ImageTransparency = 0.2, Size = UDim2.fromScale(0.42, 1.04), Position = UDim2.fromScale(0.18, 0.55), AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 2 })
	new("UIAspectRatioConstraint", swGlow, { AspectRatio = 1 })
	local swLite = new("Frame", swatch, { Size = UDim2.fromScale(0.44, 0.3), Position = UDim2.fromScale(0.3, 0.26), AnchorPoint = Vector2.new(0.5, 0.5), BorderSizePixel = 0, BackgroundTransparency = 0.25, ZIndex = 4 })
	new("UICorner", new("Frame", swatch, { Size = UDim2.fromScale(0.12, 0.12), Position = UDim2.fromScale(0.62, 0.22), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = WHITE, BackgroundTransparency = 0.1, BorderSizePixel = 0, ZIndex = 4 }), { CornerRadius = UDim.new(0.5, 0) })
	new("UICorner", swLite, { CornerRadius = UDim.new(0.5, 0) })
	local rOre = text(result, "+6 ORE", UDim2.fromScale(0.6, 0.2), UDim2.fromScale(0.33, 0.2), nil, INK, 700, false)
	rOre.TextXAlignment = Enum.TextXAlignment.Left
	local coinI = icon(result, "coin", UDim2.fromScale(0.06, 0.15), UDim2.fromScale(0.33, 0.43))
	new("UIAspectRatioConstraint", coinI, { AspectRatio = 1 })
	local rGold = text(result, "72 GOLD", UDim2.fromScale(0.5, 0.15), UDim2.fromScale(0.41, 0.43), nil, INK, 700, false)
	rGold.TextXAlignment = Enum.TextXAlignment.Left
	local rGrade = text(result, "PRISTINE VEIN", UDim2.fromScale(0.42, 0.13), UDim2.fromScale(0.33, 0.62), nil, PLUM_SOFT, 700, false)
	rGrade.TextXAlignment = Enum.TextXAlignment.Left
	local rStars = {}
	for i = 1, 3 do
		rStars[i] = new("ImageLabel", result, { Image = SPRITE.star, BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit, Size = UDim2.fromScale(0.1, 0.22), Position = UDim2.fromScale(0.37 + (i - 1) * 0.09, 0.8), AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 3 })
	end
	local resultSeq = 0
	local function showResult(oreName, count, value, col, gradeText, nStars)
		resultSeq += 1
		local my = resultSeq
		swatch.BackgroundColor3, swLite.BackgroundColor3, swGlow.ImageColor3 = col:Lerp(WHITE, 0.15), col:Lerp(WHITE, 0.55), col
		rOre.Text = "+" .. count .. " " .. string.upper(oreName)
		rGold.Text = commas(value) .. " GOLD"
		rGrade.Text = gradeText
		for i, st in rStars do
			st.Image = i <= nStars and SPRITE.star or SPRITE.starOff
			if i <= nStars then task.delay(0.15 + i * 0.12, function() pop(st, 1.8, 0.3) sfx("sparkle", 1 + i * 0.12) end) end
		end
		result.Visible, resultDim.Visible = true, true
		pop(result, 0.5, 0.35)
		uiBurst(caveHud, S(640, 262), CONFETTI, 18 + nStars * 6, 0.3)
		task.delay(2.2, function()
			if resultSeq == my then
				closePanel(result)
				resultDim.Visible = false
			end
		end)
	end
	local function gradeOf(slips)
		for _, g in D.grades do
			if slips <= g[2] then return g end
		end
	end
	local function drawVein()
		for k, sl in slots do
			local beat = mg.i + k
			local on = beat <= #mg.seq
			sl.seg.Visible = on
			local base = mg.col:Lerp(LILAC, 0.2):Lerp(beat % 2 == 0 and WHITE or Color3.new(0, 0, 0), 0.12)
			sl.seg.BackgroundColor3, sl.lite.BackgroundColor3, sl.dark.BackgroundColor3 = base, base:Lerp(WHITE, 0.4), base:Lerp(INK, 0.35)
			for side = 1, 2 do
				sl.cracks[side].Visible = on and mg.seq[beat] == side
				sl.lines[side].Visible = on and mg.seq[beat] == side
				for _, sp in sl.cracks[side]:GetChildren() do -- only the next two cracks are bold; the look-ahead stays faint
					sp.BackgroundTransparency = k <= 2 and 0 or 0.65
				end
			end
		end
		local g = gradeOf(mg.slips)
		qText.Text = "VEIN RUSH  " .. g[1]
		for i, st in stars do st.Image = i <= g[4] and SPRITE.star or SPRITE.starOff end
		beatText.Text = "BEAT " .. math.min(mg.i + 1, #mg.seq) .. " / " .. #mg.seq
	end
	local function close()
		if not mg then return end
		mg = nil
		ps.Visible, vr.Visible = false, false
		freeze(false)
	end
	cave.mgClose = close
	local function sendRush()
		if mg and mg.kind == "rush" and not mg.sent then
			mg.sent = true
			ExtractR:FireServer("rush", mg.choices)
		end
	end
	local function chisel(side)
		if not mg or mg.kind ~= "rush" or mg.sent then return end
		mg.i += 1
		mg.choices[mg.i] = side
		miner.Position = UDim2.fromScale(side == 1 and 0.12 or 0.88, 1)
		miner.Rotation = side == 1 and -30 or 30
		tween(miner, 0.15, { Rotation = 0 }, Enum.EasingStyle.Back)
		local at = S(640 + (side == 1 and -50 or 50), 420)
		if mg.seq[mg.i] == side then -- hit the crack: a slip
			mg.slips += 1
			sfx("hit", 0.6)
			shake(0.5)
			uiBurst(vr, at, { Color3.fromRGB(255, 90, 110), PINK }, 10, 0.16)
			miner.ImageColor3 = PINK
			tween(miner, 0.3, { ImageColor3 = WHITE })
		else
			sfx("clink", 1.1 + mg.i * 0.04)
			uiBurst(vr, at, { mg.col:Lerp(WHITE, 0.3), mg.col, CREAM }, 9, 0.18)
		end
		column.Position = S(640, 450 - 72) -- the vein drops one segment
		tween(column, 0.12, { Position = S(640, 450) }, Enum.EasingStyle.Quad)
		drawVein()
		if mg.i >= #mg.seq then sendRush() end
	end
	local function strike()
		if not mg or mg.kind ~= "strike" or mg.done or os.clock() < mg.cool then return end
		mg.cool = os.clock() + 0.28
		ExtractR:FireServer("strike", workspace:GetServerTimeNow())
		sfx("swing", 1.2)
		pop(dial, 1.05, 0.15)
	end
	strikeBtn.Activated:Connect(strike)
	leftBtn.Activated:Connect(function() chisel(1) end)
	rightBtn.Activated:Connect(function() chisel(2) end)
	UIS.InputBegan:Connect(function(input, gp)
		if not mg or gp then return end
		local k, t = input.KeyCode, input.UserInputType
		if mg.kind == "strike" and (k == Enum.KeyCode.Space or k == Enum.KeyCode.E or k == Enum.KeyCode.ButtonA or k == Enum.KeyCode.ButtonR2 or t == Enum.UserInputType.MouseButton1) then
			strike()
		elseif mg.kind == "rush" then
			if k == Enum.KeyCode.A or k == Enum.KeyCode.Left or k == Enum.KeyCode.ButtonL1 or k == Enum.KeyCode.DPadLeft or t == Enum.UserInputType.MouseButton1 then
				chisel(1)
			elseif k == Enum.KeyCode.D or k == Enum.KeyCode.Right or k == Enum.KeyCode.ButtonR1 or k == Enum.KeyCode.DPadRight or t == Enum.UserInputType.MouseButton2 then
				chisel(2)
			end
		end
	end)

	cave.mg = function(kind, ...)
		if kind == "mgStart" then
			local dep, which, t0, param, zone, period = ...
			local col = C.LAYERS[dep:GetAttribute("Layer")][4][dep:GetAttribute("Ore")][2]
			mg = { kind = which, dep = dep, t0 = t0, col = col, cool = 0, period = period }
			freeze(true)
			if which == "strike" then
				mg.arc = param
				drawArc(zone or D.arc)
				for _, p in pips do p.BackgroundColor3 = CREAM end
				psTitle.Text = "PERFECT STRIKE  -  " .. string.upper(dep:GetAttribute("OreName"))
				ps.Visible = true
				pop(dial, 0.6, 0.3)
			else
				mg.seq, mg.i, mg.slips, mg.choices = param, 0, 0, {}
				vr:SetAttribute("Seq", table.concat(param, "")) -- for the Play test script (the player sees the cracks anyway)
				drawVein()
				vr.Visible = true
				pop(column, 0.7, 0.3)
			end
			sfx("sparkle", 1.1)
		elseif kind == "mgStrike" and mg and mg.kind == "strike" then
			local n, perfect, arc = ...
			mg.arc = arc
			if pips[n] then pips[n].BackgroundColor3 = perfect and BUTTER or LILAC end
			psPop.Text, psPop.TextColor3 = perfect and "PERFECT!" or "OK", perfect and BUTTER or LILAC
			psPop.Visible = true
			pop(psPop, perfect and 1.8 or 1.2, 0.3)
			task.delay(0.45, function() psPop.Visible = false end)
			if perfect then -- the hit recipe from the VFX note: hit-stop, FOV punch, a soft brightness lift, rising pitch
				mg.streak = (mg.streak or 0) + 1
				mg.freezeUntil = os.clock() + 0.07 -- the needle holds for 70 ms; UI and sound keep going
				sfx("clink", 1.5 * (1 + 0.06 * (mg.streak - 1)))
				sfx("sparkle", 1.25)
				shake(0.3)
				fovKick = -4 -- a punch in, then the camera eases back
				local cc = game:GetService("Lighting"):FindFirstChildOfClass("ColorCorrectionEffect")
				if cc then
					local b = cc.Brightness
					tween(cc, 0.06, { Brightness = b + 0.06 }).Completed:Connect(function() tween(cc, 0.12, { Brightness = b }) end)
				end
				if mg.streak >= 3 then uiRing(ps, S(640, 290), PINK, 0.16) end
				uiRing(ps, S(640, 290), BUTTER)
				uiRing(ps, S(640, 290), CREAM, 0.08)
				uiBurst(ps, S(640, 290), CONFETTI, 24, 0.34)
				psPop.Rotation = math.random(-8, 8)
			else
				mg.streak = 0
				sfx("hit", 0.9)
				uiBurst(ps, S(640, 290), { LILAC, PLUM_SOFT }, 6, 0.14)
				psPop.Rotation = 0
			end
			if n >= D.strikes then mg.done = true end
		elseif kind == "mgEnd" then
			local dep, oreName, count, value, col, grade = ...
			for _, g in map.deps do if g.dep == dep then claim(g) end end
			local core = dep.PrimaryPart
			if core then
				burst(core.Position, Vector3.yAxis, col, 26)
				shockwave(core.Position, col)
				for i = 1, math.min(count, 6) do task.delay(i * 0.07, function() oreFly(core.Position, col) end) end
			end
			sfx("breakRock", 0.9)
			task.delay(0.3, function() sfx("coin", 1.1) end)
			task.delay(mg and mg.kind == "strike" and 0.5 or 0.7, function()
				close()
				if type(grade) == "number" then
					showResult(oreName, count, value, col, grade .. " / " .. D.strikes .. " PERFECT", grade)
				else
					local n = 0
					for _, g in D.grades do if g[1] == grade then n = g[4] end end
					showResult(oreName, count, value, col, grade .. " VEIN", n)
				end
			end)
		end
	end

	cave.tick = function(now, h)
		glints.Visible = not (ps.Visible or vr.Visible or result.Visible)
		mapStep(now, h)
		if mg and mg.kind == "strike" then
			if not (mg.freezeUntil and os.clock() < mg.freezeUntil) then needle.Rotation = ((workspace:GetServerTimeNow() - mg.t0) / (mg.period or D.strikePeriod) % 1) * 360 end
			arcPivot.Rotation = mg.arc
		elseif mg and mg.kind == "rush" then
			local left = 1 - (workspace:GetServerTimeNow() - mg.t0) / (#mg.seq * D.rushBeat)
			timeFill.Size = UDim2.fromScale(math.clamp(left, 0, 1), 1)
			timeFill.BackgroundColor3 = left > 0.3 and MINT or PINK
			if left <= 0 then sendRush() end
		end
	end
end)()

-- First-visit cave tips and minigame how-to cards (feedback batch item 11, roadmap i49). A lilac ribbon banner under the location
-- pill teaches one thing at a time the first time it matters: camp banks ore, the torch burns down, fear in the dark, sparkles
-- are ore. Each minigame shows a how-to card beside it on its first run. Seen tips are saved on the server (state.tips).
;(function()
	local TipR = R:WaitForChild("Tip")
	local keys = UIS.KeyboardEnabled
	local TIPS = {
		camp = { "camp", "CAMP IS SAFE: ORE YOU CARRY IS BANKED HERE" },
		torch = { "camp", "YOUR TORCH BURNS DOWN: COME BACK TO CAMP TO RELIGHT IT" },
		ore = { "gem", keys and "SPARKLES MEAN ORE! WALK UP AND PRESS E" or "SPARKLES MEAN ORE! WALK UP AND TAP EXTRACT" },
		fear = { "crew", "THE DARK IS SCARY: HEAD BACK TO THE LIGHT" },
	}
	local banner = panel(caveHud, S(700, 66), S(640, 96), Vector2.new(0.5, 0), "ribbonLilac")
	fit(banner, 700, 66)
	banner.Name, banner.Visible, banner.ZIndex = "TipBanner", false, 6
	local bIcon = icon(banner, "camp", UDim2.fromScale(0.08, 0.7), UDim2.fromScale(0.17, 0.42), Vector2.new(0.5, 0.5))
	new("UIAspectRatioConstraint", bIcon, { AspectRatio = 1, DominantAxis = Enum.DominantAxis.Height })
	bIcon.ZIndex = 7
	local bText = text(banner, "", UDim2.fromScale(0.62, 0.4), UDim2.fromScale(0.54, 0.42), Vector2.new(0.5, 0.5), WHITE)
	bText.TextColor3, bText.TextStrokeTransparency, bText.ZIndex = INK, 1, 7 -- ink on the light ribbon reads at phone size
	local shown, queue, busy = {}, {}, false
	local function seen(name) return shown[name] or (state and state.tips and state.tips[name]) end
	local function nextTip()
		if busy or #queue == 0 then return end
		busy = true
		local name = table.remove(queue, 1)
		bIcon.Image, bText.Text = ICON[TIPS[name][1]], TIPS[name][2]
		banner.Visible = true
		banner.Position = S(640, 70)
		tween(banner, 0.4, { Position = S(640, 96) }, Enum.EasingStyle.Back)
		pop(banner, 0.6, 0.35)
		sfx("sparkle", 1.25)
		task.delay(5.5, function()
			tween(scaler(banner), 0.18, { Scale = 0.6 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			task.delay(0.2, function()
				banner.Visible = false
				scaler(banner).Scale = 1
				busy = false
				nextTip()
			end)
		end)
	end
	local function tip(name)
		if seen(name) then return end
		shown[name] = true
		TipR:FireServer(name)
		if TIPS[name] then -- the minigame how-to names are only marked seen, they have no banner
			table.insert(queue, name)
			nextTip()
		end
	end

	-- how-to cards beside the minigames, first run of each
	local HOWTO = {
		strike = { "PERFECT STRIKE", { { "hammer", "The needle spins round the dial" }, { "star", "Strike when it crosses the GOLD" }, { "gem", "3 swings: each PERFECT gives bonus ore" } } },
		rush = { "VEIN RUSH", { { "chisel", "A red crack shows on one side" }, { "chisel", "Chisel the OTHER side, fast!" }, { "star", "No slips = FLAWLESS, 3 stars" } } },
	}
	local card = panel(caveHud, S(330, 250), S(36, 140), nil, "panel")
	fit(card, 330, 250)
	card.Name, card.Visible, card.ZIndex = "HowTo", false, 13
	local cTitle = ribbonTitle(card, "HOW TO PLAY", "ribbonPink", 0.78)
	cTitle.ZIndex = 14
	local cName = text(card, "", UDim2.fromScale(0.84, 0.11), UDim2.fromScale(0.5, 0.16), Vector2.new(0.5, 0), PLUM_SOFT, 700, false)
	cName.ZIndex = 14
	local rows = {}
	for k = 1, 3 do
		local y = 0.36 + (k - 1) * 0.2
		local m = new("Frame", card, { Size = UDim2.fromScale(0.16, 0.16), Position = UDim2.fromScale(0.13, y), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = ({ BUTTER, MINT, PINK })[k], BorderSizePixel = 0, ZIndex = 14 })
		new("UIAspectRatioConstraint", m, { AspectRatio = 1 })
		new("UICorner", m, { CornerRadius = UDim.new(0.5, 0) })
		new("UIStroke", m, { Color = WHITE, Thickness = 2 })
		local ic = icon(m, "star", UDim2.fromScale(0.8, 0.8), UDim2.fromScale(0.5, 0.5), Vector2.new(0.5, 0.5))
		ic.ZIndex = 15
		local num = text(m, tostring(k), UDim2.fromScale(0.45, 0.45), UDim2.fromScale(0.92, 0.12), Vector2.new(0.5, 0.5), WHITE)
		num.ZIndex = 16
		local t = text(card, "", UDim2.fromScale(0.68, 0.15), UDim2.fromScale(0.25, y), Vector2.new(0, 0.5), INK, 700, false)
		t.TextXAlignment, t.TextWrapped, t.ZIndex = Enum.TextXAlignment.Left, true, 14
		rows[k] = { icon = ic, text = t }
	end
	local current
	local prevMg = cave.mg
	cave.mg = function(kind, ...)
		prevMg(kind, ...)
		if kind == "mgStart" then
			local _, which = ...
			if HOWTO[which] and not seen(which) then
				current = which
				cName.Text = HOWTO[which][1]
				for k, r in rows do r.icon.Image, r.text.Text = ICON[HOWTO[which][2][k][1]], HOWTO[which][2][k][2] end
				rows[2].icon.Rotation = which == "rush" and 90 or 0 -- the second chisel points the other way
				card.Visible = true
				pop(card, 0.6, 0.35)
				for k, r in rows do -- the steps arrive one by one
					r.text.TextTransparency = 1
					task.delay(0.15 + k * 0.18, function() tween(r.text, 0.25, { TextTransparency = 0 }) end)
				end
			end
		elseif kind == "mgEnd" and current then
			tip(current) -- seen once it has been played through
			current = nil
			closePanel(card)
		end
	end

	-- triggers, checked on the cave tick
	local prevTick = cave.tick
	local inside = true
	cave.tick = function(now, h)
		prevTick(now, h)
		if cave.mgBusy then banner.Visible = false end -- the minigame title sits there
		if not state then return end
		local o = C.CAVE_ORIGIN
		local here = Vector2.new(h.Position.X - o.X, h.Position.Z - o.Z).Magnitude < C.CAMP_RING
		tip("camp")
		if inside and not here then tip("torch") end
		inside = here
		if (cave.fear or 0) >= 0.25 then tip("fear") end
		local g = caveHud:FindFirstChild("Glints")
		if g and not seen("ore") then
			for _, s in g:GetChildren() do
				if s.Visible then tip("ore") break end
			end
		end
	end
end)()

-- Camera modes: bird's-eye follow camera in the hub, first person in the mine and the caves
local lookDownUntil = 0
local atmo = game:GetService("Lighting"):FindFirstChildOfClass("Atmosphere")
local atmoCamp = atmo and { Density = atmo.Density, Offset = atmo.Offset, Haze = atmo.Haze, Color = atmo.Color, Decay = atmo.Decay }
local ATMO_MINE = { Density = 0.62, Offset = 0, Haze = 0.8, Color = Color3.fromRGB(46, 32, 70), Decay = Color3.fromRGB(26, 18, 44) }
local function setMode(mine, inCaves)
	inMine = mine and not inCaves
	inCave = inCaves == true
	if inMine then lookDownUntil = os.clock() + 0.35 end
	atmo = atmo or game:GetService("Lighting"):FindFirstChildOfClass("Atmosphere")
	if atmo and not inCave then
		atmoCamp = atmoCamp or { Density = atmo.Density, Offset = atmo.Offset, Haze = atmo.Haze, Color = atmo.Color, Decay = atmo.Decay }
		for k, v in (inMine and ATMO_MINE or atmoCamp) do atmo[k] = v end
	end
	caveLighting(inCave)
	caveHud.Visible = inCave
	if not inCave and cave.mgClose then cave.mgClose() end
	strip.Visible = inMine -- the block-mine depth strip only means something in the old block mines
	if inCave then cave.relitAt, cave.wasInCamp = os.clock(), true end
	mine = inMine or inCave
	cross.Visible, digBtn.Visible = inMine, inMine
	railLift.Text = mine and "SURFACE" or "MINE"
	setKind(railLift, mine and "sky" or "butter")
	if mine then
		local h = head()
		cam.CameraType = Enum.CameraType.Custom
		plr.CameraMinZoomDistance, plr.CameraMaxZoomDistance = 0.5, 0.5
		plr.CameraMode = Enum.CameraMode.LockFirstPerson
		cam.FieldOfView = C.FP_FOV
		if h then cam.CFrame = CFrame.lookAt(h.Position, h.Position + h.CFrame.LookVector - Vector3.new(0, 1.1, 0)) end -- start looking down at the first block
		buildViewmodel()
	else
		plr.CameraMode = Enum.CameraMode.Classic
		plr.CameraMinZoomDistance, plr.CameraMaxZoomDistance = 0.5, 128
		cam.CameraType = Enum.CameraType.Scriptable
		cam.FieldOfView = C.CAM_FOV
		if vm then vm:Destroy() vm = nil vmTier = nil end
		if cave.tvm then cave.tvm:Destroy() cave.tvm = nil end
		-- the first-person camera left the character invisible and turning with the camera (it always faced north in town):
		-- the Scriptable town camera stops the camera scripts, so undo both here
		pcall(function() UserSettings():GetService("UserGameSettings").RotationType = Enum.RotationType.MovementRelative end)
		for _, p in (plr.Character and plr.Character:GetDescendants() or {}) do
			if p:IsA("BasePart") or p:IsA("Decal") then p.LocalTransparencyModifier = 0 end
		end
	end
end
local function modeNow() return plr:GetAttribute("InMine") == true or plr:GetAttribute("InCave") == true, plr:GetAttribute("InCave") == true end
plr:GetAttributeChangedSignal("InMine"):Connect(function() setMode(modeNow()) end)
plr:GetAttributeChangedSignal("InCave"):Connect(function() setMode(modeNow()) end)
plr.CharacterAdded:Connect(function()
	vm, vmTier = nil, nil
	task.defer(function() setMode(modeNow()) end)
end)
setMode(modeNow())

-- Server FX events
R.Fx.OnClientEvent:Connect(function(kind, ...)
	if kind == "mgStart" or kind == "mgStrike" or kind == "mgEnd" then -- cave extraction minigames
		cave.mg(kind, ...)
	elseif kind == "ring" then
		local p, t0 = ...
		critPart, critT0, critUntil = p, t0, os.clock() + 2.5
	elseif kind == "hit" then
		local p, frac, _, crit = ...
		if p and p.Parent then
			critUntil = os.clock() + 2.5
			crack(p, frac)
			sfx(crit and "clink" or "hit", 1 + (1 - frac) * 0.2)
			p.Size = Vector3.one * B * 0.9 -- squash punch (local only)
			tween(p, 0.22, { Size = Vector3.one * B }, Enum.EasingStyle.Back)
			if crit then
				floatText(p.Position + Vector3.new(0, B * 0.7, 0), "CRIT!", PINK)
				shockwave(p.Position, BUTTER)
				burst(lastHitPos or p.Position, lastHitNormal, BUTTER, 22)
				shake(0.6)
			end
		end
	elseif kind == "break" then
		local pos, ore, v, who, combo, col, crit, bkind = ...
		breakFx(pos, col)
		sfx("breakRock")
		if v > 0 then task.delay(0.35, function() sfx("coin", 1 + math.min(combo, 12) * 0.05) end) end
		if bkind == "gild" or bkind == "egg" then sfx("sparkle") end
		if crit then
			shockwave(pos, BUTTER)
			floatText(pos + Vector3.new(0, 2.2, 0), "CRIT!", PINK)
		end
		burst(pos, lastHitNormal, col, combo > 0 and 26 or 14)
		shake(combo > 0 and 0.7 or 0.35)
		fovKick = combo > 0 and 6 or 3
		if v > 0 then
			oreFly(pos, col)
			for g = 1, (combo > 0 or bkind == "gild") and 4 or (bkind == "ore3" and 2 or 0) do
				local gem = new("Part", fx, { Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, Size = Vector3.one * 0.55, Color = col:Lerp(WHITE, 0.25), Material = Enum.Material.Neon })
				gem.CFrame = CFrame.new(pos) * CFrame.Angles(0, g, math.pi / 4)
				table.insert(shards, { part = gem, v = Vector3.new(math.random(-6, 6), math.random(12, 18), math.random(-6, 6)), spin = Vector3.new(0, 8, 0), t = -0.2 })
			end
			floatText(pos, "+" .. v .. " " .. ore, combo > 0 and GOLD or (who == "you" and CREAM or SKY))
			feedLine("+" .. v .. " " .. ore:upper(), col)
		elseif bkind == "egg" then
			feedLine("FOSSIL EGG!", PINK)
		end
		if combo > 0 then
			banner.Text = "GILDED FRENZY!  x" .. combo
			pop(banner, 1.4)
		end
	elseif kind == "bedrock" then
		toast("Bedrock! Too hard to dig.", LILAC)
	elseif kind == "frenzy" then
		local dur = ...
		banner.Text, banner.Visible, frenzyBar.Visible = "GILDED FRENZY!", true, true
		frenzyFill.Size = UDim2.fromScale(1, 1)
		tween(frenzyFill, dur, { Size = UDim2.fromScale(0, 1) }, Enum.EasingStyle.Linear)
		pop(banner, 0.4)
		rainEm.Rate, edge.Visible = 40, true
		sfx("sparkle", 0.9)
	elseif kind == "frenzyEnd" then
		local bank, combo, newBest = ...
		rainEm.Rate, edge.Visible, banner.Visible, frenzyBar.Visible = 0, false, false, false
		toast("FRENZY  +" .. bank .. " ORE VALUE", GOLD, true)
		if newBest then toast("NEW BEST!  " .. combo .. " COMBO", PINK, true, 1.3) end
	elseif kind == "sold" then
		local gold, _, moved = ...
		toast("+" .. commas(gold) .. " GOLD", GOLD, true)
		local parts = {}
		for k, n in moved or {} do if n > 0 then table.insert(parts, n .. " " .. C.oreName(k)) end end
		if #parts > 0 then toast("ORE BANK  +" .. table.concat(parts, "  +"), MINT, false, 0.6) end
		sfx("coin", 0.9)
		if forgeUI.fly and bagPill.Visible then -- coins fly from the bag into the gold pill (each lands with a coin tick)
			local inset = game:GetService("GuiService"):GetGuiInset()
			local from = bagPill.AbsolutePosition + bagPill.AbsoluteSize / 2 + inset
			forgeUI.fly("coin", UDim2.fromOffset(from.X, from.Y), goldPill, math.clamp(math.floor(gold / 4), 5, 12), 0.05)
			pop(bagPill, 0.85)
		else
			task.delay(0.12, function() sfx("coin", 1.1) end)
		end
		local h = hrp()
		if h then burst(h.Position + Vector3.new(0, 3, 0), Vector3.yAxis, GOLD, 30) end
	elseif kind == "bought" then
		local name = ...
		forgeUI.fx("bought", name, select(2, ...))
		task.delay(0.3, buildViewmodel)
	elseif kind == "upgraded" or kind == "equipped" then
		forgeUI.fx(kind, ...)
		if kind == "equipped" then task.delay(0.3, buildViewmodel) end
	elseif kind == "full" then
		pop(bagPill, 1.2) -- the popup already says it; no toast spam while you keep digging
		if not sellPop.Visible then openPanel(sellPop) end
	elseif kind == "stir" then -- a boulder shakes loose above the hole, then drops (server decides where it lands)
		local pos = ...
		local rock = new("Part", fx, { Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, Size = Vector3.one * B * 0.8, Position = pos, Color = Color3.fromRGB(188, 120, 96), Material = Enum.Material.Slate })
		new("Highlight", rock, { FillTransparency = 1, OutlineColor = PINK, DepthMode = Enum.HighlightDepthMode.AlwaysOnTop })
		rock.Name = "StirRock"
		local t0 = os.clock()
		task.spawn(function()
			while rock.Parent and os.clock() - t0 < C.STIR_WARN do
				rock.CFrame = CFrame.new(pos + Vector3.new((math.random() - 0.5) * 0.35, 0, (math.random() - 0.5) * 0.35)) * CFrame.Angles(0, 0, (math.random() - 0.5) * 0.12)
				task.wait(0.03)
			end
		end)
		shake(0.3)
		task.delay(C.STIR_WARN + 0.6, function() rock:Destroy() end)
		toast("Titan's Stir! A rock is shaking loose. Move!", Color3.fromRGB(255, 180, 120), true)
	elseif kind == "fell" then
		local pos = ...
		for _, rock in fx:GetChildren() do
			if rock.Name == "StirRock" then tween(rock, 0.22, { Position = pos }, Enum.EasingStyle.Quad, Enum.EasingDirection.In) end
		end
		task.delay(0.22, function()
			burst(pos - Vector3.new(0, B / 2, 0), Vector3.yAxis, Color3.fromRGB(200, 170, 140), 16)
			shake(0.8)
		end)
	elseif kind == "bonk" then
		local lost = ...
		toast(lost > 0 and ("Bonk! Spilled " .. lost .. " ore") or "Bonk!", PINK, true)
	elseif kind == "egg" then
		toast("Fossil egg! Hatch it at the camp incubator", PINK, true)
		pop(eggPill, 1.3)
	elseif kind == "night" then
		local mins, gold, crew = ...
		nightInfo.Text = "Your crew of " .. crew .. " dug for " .. (mins >= 60 and (mins // 60 .. " h " .. mins % 60 .. " m") or (mins .. " m"))
		nightGold.Text = "+" .. commas(gold) .. " GOLD"
		openPanel(night)
	elseif kind == "hatch" then
		task.spawn(hatchShow, ...)
	elseif kind == "petDig" then
		local i, p = ...
		local pet = petObjs[i]
		if p and pet then
			pet.digUntil, pet.digPos, pet.hop = os.clock() + 0.35, p.Position + (cam.CFrame.Position - p.Position).Unit * (B * 0.7), os.clock()
			burst(p.Position, Vector3.yAxis, C.PETS[pet.model.Name][6], 8)
		end
	elseif kind == "openForge" then
		if not forge.Visible then forgeUI.open() end
	elseif kind == "map" then
		local deepest = ...
		local L = layerOf(math.max(deepest or 1, 1))
		for i, row in mapRows do row.BackgroundTransparency = i > L and 0.6 or 0 end
		openPanel(mapP)
	elseif kind == "chest" then
		local chest, gold, layer = ...
		local lid = chest and chest.Parent and chest.Parent:FindFirstChild(chest:GetAttribute("Lid") or "ChestLid")
		if lid then tween(lid, 0.35, { CFrame = lid.CFrame * CFrame.new(0, 0.6, 0.8) * CFrame.Angles(math.rad(-100), 0, 0) }, Enum.EasingStyle.Back) end
		if chest then burst(chest.Position + Vector3.new(0, 1.5, 0), Vector3.yAxis, GOLD, 40) end
		toast("SHRINE CHEST  +" .. commas(gold) .. " GOLD", GOLD, true)
	elseif kind == "shrine" then
		toast("A HIDDEN SHRINE!", LILAC, true)
		shake(0.3)
	elseif kind == "newLayer" then
		local L, bonus = ...
		toast("NEW LAYER: " .. C.LAYERS[L][1]:upper(), GOLD, true)
		toast("Depth reward +" .. commas(bonus) .. " gold", MINT, false, 1.2)
	elseif kind == "escape" then -- the ride up: the minecart escape minigame (ReplicatedStorage.Shared.MinecartEscape)
		local seed = ...
		local mod = RS.Shared:FindFirstChild("MinecartEscape")
		local hub = workspace:FindFirstChild("Hub")
		cave.escapeBonus = nil -- the server's answer arrives as Fx "escapeDone"
		task.spawn(function()
			local ok, err = pcall(function()
				require(mod).play({
					seed = seed, cart = hub and hub:FindFirstChild("HubCart", true), sfx = sfx,
					report = function(r) R.Surface:FireServer("escaped", r) end,
					result = function() return cave.escapeBonus end,
					restore = function() setMode(modeNow()) end,
				})
			end)
			if not ok then
				warn("[MinecartEscape] " .. tostring(err))
				if not cave.escapeBonus then R.Surface:FireServer("escaped", nil) end
			end
			R.Surface:FireServer("arrived")
			if ok and cave.escapeBonus and cave.escapeBonus > 0 then toast("ESCAPE BONUS  +" .. commas(cave.escapeBonus) .. " COINS", GOLD, true) end
		end)
	elseif kind == "drowned" then -- out of air in the lake: the server woke us at Camp 1
		local lost = ...
		fadeText.Text = "YOU PASSED OUT..."
		fade.BackgroundTransparency = 0
		fadeText.TextTransparency = 0
		task.delay(1.1, function()
			tween(fade, 0.6, { BackgroundTransparency = 1 })
			tween(fadeText, 0.6, { TextTransparency = 1, TextStrokeTransparency = 1 })
			task.delay(0.61, function() fadeText.TextStrokeTransparency = 0 end)
		end)
		toast(lost > 0 and ("The lake took " .. commas(lost) .. " ore") or "You woke up at camp", PINK, true, 1.2)
	elseif kind == "escapeDone" then
		cave.escapeBonus = (...) or 0
	elseif kind == "ride" then -- the minecart ride down to Camp 1 (ReplicatedStorage.Shared.MinecartRide)
		local full = ...
		local mod = RS.Shared:FindFirstChild("MinecartRide")
		local hub = workspace:FindFirstChild("Hub")
		local cartM = hub and hub:FindFirstChild("HubCart", true)
		local caves = workspace:FindFirstChild("Caves")
		task.spawn(function()
			local ok, err = pcall(function()
				require(mod).play({
					cart = cartM, camp = caves and caves:FindFirstChild("Camp"), full = full, sfx = sfx,
					inCave = function() return plr:GetAttribute("InCave") == true end,
					restore = function() setMode(modeNow()) end,
				})
			end)
			if not ok then warn("[MinecartRide] " .. tostring(err)) end
			R.Surface:FireServer("arrived")
			if ok then toast("CAMP 1  ·  ORE IS SAFE HERE", MINT, true) end
		end)
	elseif kind == "lift" then
		local down = ...
		fadeText.Text = down and "RIDING THE LIFT DOWN..." or "BACK TO CAMP!"
		sfx("swing", 0.6)
		fade.BackgroundTransparency = 0
		fadeText.TextTransparency = 0
		task.delay(0.35, function()
			tween(fade, 0.45, { BackgroundTransparency = 1 })
			tween(fadeText, 0.45, { TextTransparency = 1, TextStrokeTransparency = 1 })
			task.delay(0.46, function() fadeText.TextStrokeTransparency = 0 end)
		end)
	end
end)

;(function() -- swimming in the grotto lake with an air bar (ReplicatedStorage.Shared.CaveSwim), on while in the caves
	local stop
	local swimGui = new("ScreenGui", plr:WaitForChild("PlayerGui"), { Name = "SwimGui", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 4 })
	local function update()
		local on = plr:GetAttribute("InCave") == true
		if on and not stop then
			local mod = RS.Shared:FindFirstChild("CaveSwim")
			local caves = workspace:FindFirstChild("Caves")
			local water = caves and caves:FindFirstChild("Water", true)
			if mod and water then
				stop = require(mod).start({
					water = water, gui = swimGui, sfx = sfx,
					drown = function() R.Surface:FireServer("drown") end,
					airScale = function() return cave.job and cave.job.air or 1 end,
					active = function() return not cave.mgBusy end,
				})
			end
		elseif not on and stop then
			stop()
			stop = nil
		end
	end
	plr:GetAttributeChangedSignal("InCave"):Connect(update)
	task.defer(update)
end)()

;(function() -- the gem shop (ReplicatedStorage.Shared.GemShop): opened from the gem pill
	task.spawn(function()
		local mod = RS.Shared:WaitForChild("GemShop", 10)
		if not mod then return end
		local ok, err = pcall(function()
			require(mod).start({ C = C, R = R, plr = plr, gui = gui, new = new, S = S, fit = fit, panel = panel, button = button, text = text, icon = icon,
				openPanel = openPanel, closePanel = closePanel, closeButton = closeButton, ribbonTitle = ribbonTitle, toast = toast, sfx = sfx, INK = INK, GOLD = GOLD })
		end)
		if not ok then warn("[GemShop] " .. tostring(err)) end
	end)
end)()

;(function() -- the Gloom client (ReplicatedStorage.Shared.GloomClient): HP pill, FLARE, soot sprites, BONK and catch, Wick and Smudge
	local mod = RS.Shared:WaitForChild("GloomClient", 10)
	if not mod then return end
	task.spawn(function() -- start waits for the server's Flare remote; never hold up the rest of this script
	local ok, err = pcall(function()
		require(mod).start({
			R = R, C = C, plr = plr, cave = cave, caveHud = caveHud, panel = panel, fit = fit, S = S, new = new, text = text, button = button,
			setKind = setKind, tween = tween, burst = burst, sfx = sfx, shake = shake, toast = toast, commas = commas, hrp = hrp,
			INK = INK, PINK = PINK, GOLD = GOLD, CREAM = CREAM, FONT = FONT,
		})
	end)
	if not ok then warn("[GloomClient] " .. tostring(err)) end
	end)
end)()

task.delay(4, function() -- the minecart ride's far stage and the escape tunnel, built early so their lanterns are lit by the first ride
	for _, n in { "MinecartRide", "MinecartEscape" } do
		local mod = RS.Shared:FindFirstChild(n)
		if mod then pcall(function() require(mod).prepare() end) end
	end
end)

-- Hub idle animations: spinning wheel, bobbing eggs and crystals, flickering fires, swaying lanterns, dancing flames
local anims = {}
local function collectAnims()
	local hub = workspace:FindFirstChild("Hub")
	if not hub then return end
	for _, d in hub:GetDescendants() do
		if d:IsA("Model") and (d:GetAttribute("SpinX") or d:GetAttribute("Bob")) then
			table.insert(anims, { obj = d, base = d:GetPivot(), spin = d:GetAttribute("SpinX"), bob = d:GetAttribute("Bob"), seed = math.random() * 6 })
		elseif d:IsA("BasePart") and (d:GetAttribute("Bob") or d:GetAttribute("Sway")) then
			table.insert(anims, { obj = d, base = d.CFrame, bob = d:GetAttribute("Bob"), sway = d:GetAttribute("Sway"), seed = math.random() * 6 })
		elseif d:IsA("PointLight") and d:GetAttribute("Flicker") then
			table.insert(anims, { obj = d, light = d.Brightness, seed = math.random() * 6 })
		elseif d:IsA("Model") and d:GetAttribute("Flames") then
			for _, f in d:GetChildren() do table.insert(anims, { obj = f, base = f.CFrame, flame = f.Size, seed = math.random() * 6 }) end
		end
	end
end
task.defer(collectAnims)

-- Per frame: cameras, held digging, aim outline, crit ring, shards, pointer, crew, depth label, hub animations
local focus, lastRow = nil, -999
RunService:BindToRenderStep("PixelCam", Enum.RenderPriority.Camera.Value + 1, function(dt)
	local h = hrp()
	if not h or not state then return end
	local now = os.clock()
	-- gold count-up
	if goldShown ~= goldGoal then
		goldShown = goldShown + (goldGoal - goldShown) * math.min(1, dt * 10)
		if math.abs(goldGoal - goldShown) < 1 then goldShown = goldGoal end
		goldText.Text = commas(goldShown)
	end
	shakeAmp *= math.exp(-dt * 12)
	fovKick *= math.exp(-dt * 8)
	if inCave then caveStep(now) end
	if inMine or inCave then
		cam.FieldOfView = C.FP_FOV + fovKick
		local hd = head()
		if now < lookDownUntil and hd then
			local lv = h.CFrame.LookVector
			cam.CFrame = CFrame.lookAt(cam.CFrame.Position, cam.CFrame.Position + Vector3.new(lv.X, 0, lv.Z).Unit - Vector3.new(0, 0.9, 0))
		end
		if shakeAmp > 0.01 then
			cam.CFrame = cam.CFrame * CFrame.Angles((math.random() - 0.5) * shakeAmp * 0.08, (math.random() - 0.5) * shakeAmp * 0.08, 0)
		end
	else
		cam.CameraType = Enum.CameraType.Scriptable
		local goal = h.Position + Vector3.new(0, 1, 0)
		focus = focus and focus:Lerp(goal, 1 - math.exp(-dt * 8)) or goal
		local dir = Vector3.new(math.sin(C.CAM_YAW) * math.cos(C.CAM_PITCH), math.sin(C.CAM_PITCH), math.cos(C.CAM_YAW) * math.cos(C.CAM_PITCH))
		local off = Vector3.new(math.random() - 0.5, math.random() - 0.5, 0) * shakeAmp
		cam.CFrame = CFrame.lookAt(focus + dir * C.CAM_DIST + off, focus + off)
	end
	local modal = forge.Visible or odds.Visible or mapP.Visible or night.Visible
	local promptsOn = not (modal or cave.mgBusy)
	if PPS.Enabled ~= promptsOn then PPS.Enabled = promptsOn end
	stepCard.Visible = not modal and stepShown ~= "" and not stepExpired and not inCave
	if modal ~= scrim.Visible then
		scrim.Visible = true
		tween(scrim, 0.2, { BackgroundTransparency = modal and 0.25 or 1 })
		if not modal then task.delay(0.2, function() if scrim.BackgroundTransparency > 0.95 then scrim.Visible = false end end) end
	end
	-- a free mouse while a panel is open (or Left Alt is held) so PC players can click the HUD in first person
	if inMine or inCave then
		local free = forge.Visible or odds.Visible or sellPop.Visible or mapP.Visible or night.Visible or UIS:IsKeyDown(Enum.KeyCode.LeftAlt)
		if free then
			UIS.MouseBehavior = Enum.MouseBehavior.Default
		end
		UIS.MouseIconEnabled = free
	else
		UIS.MouseIconEnabled = true
	end
	-- first-person torch in the left hand (the light itself stays on the character's torch)
	if (inMine or inCave) and not cave.tvm and plr.Character and plr.Character:FindFirstChild("HeldTorch") then
		cave.tvm = plr.Character.HeldTorch:Clone()
		for _, d in cave.tvm:GetDescendants() do
			if d:IsA("PointLight") or (d:IsA("JointInstance") and d.Name == "TorchGrip") then d:Destroy() end
		end
		for _, d in cave.tvm:GetDescendants() do
			if d:IsA("BasePart") then d.Anchored, d.Transparency, d.CastShadow = d == cave.tvm.PrimaryPart, 0, false end
			if d.Name == "Flame" then d.Color = Color3.fromRGB(205, 112, 42) end -- dimmer neon: a full-bright flame at the lens blooms into a blob
			if d.Name == "Core" then d.Color = Color3.fromRGB(235, 190, 120) end
		end
		cave.tvm:ScaleTo(0.6)
		cave.tvm.Name = "ViewTorch"
		cave.tvm.Parent = cam
	end
	if cave.tvm and (inMine or inCave) and not cave.mgBusy then
		local hum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
		local bob = hum and hum.MoveDirection.Magnitude > 0.1 and math.sin(now * 10 + 1.5) * 0.07 or math.sin(now * 2 + 1) * 0.02
		cave.tvm:PivotTo(cam.CFrame * CFrame.new(-1.15, -1.05 + bob, -2.4) * CFrame.Angles(0.3, 0.25, -0.15))
	elseif cave.tvm then
		cave.tvm:PivotTo(CFrame.new(0, -1e4, 0)) -- out of sight during minigames
	end
	-- first-person pickaxe swing: wind-up, fast strike, short hold, recover; walking bob
	if vm and (inMine or inCave) then
		local t = now - swingT0
		local a = 0
		if t < 0.07 then a = -0.8 * t / 0.07
		elseif t < 0.13 then a = -0.8 + 2.4 * ((t - 0.07) / 0.06) ^ 2
		elseif t < 0.18 then a = 1.6
		elseif t < 0.42 then a = 1.6 * (1 - (t - 0.18) / 0.24) ^ 2 end
		if vmTrail then vmTrail.Enabled = t > 0.06 and t < 0.2 end
		local hum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
		local moving = hum and hum.MoveDirection.Magnitude > 0.1
		local bob = moving and math.sin(now * 10) * 0.08 or math.sin(now * 2) * 0.02
		vm:PivotTo(cam.CFrame * CFrame.new(1.3, -1.5 + bob, -2.1) * CFrame.Angles(0.15, -0.35, 0.35) * CFrame.Angles(-a, 0, 0))
	end
	-- aim outline on the block under the crosshair
	if inMine then
		local p = blockAtCross()
		aim.Adornee = p
	else
		aim.Adornee = nil
	end
	-- crit ring
	local showRing = inMine and critPart and critPart.Parent and now < critUntil
	critBB.Enabled = showRing and true or false
	if showRing then
		critAnchor.Position = critPart.Position + (cam.CFrame.Position - critPart.Position).Unit * (B * 0.6)
		local phase = ((workspace:GetServerTimeNow() - critT0) % C.CRIT_PERIOD) / C.CRIT_PERIOD
		critRing.Size = UDim2.fromScale(1 - 0.58 * phase, 1 - 0.58 * phase)
		local hot = phase >= C.CRIT_FROM
		critStroke.Color, critStroke.Thickness = hot and BUTTER or WHITE, hot and 5 or 3
	end
	-- shards
	for i = #shards, 1, -1 do
		local s = shards[i]
		s.t += dt
		s.v += Vector3.new(0, -60 * dt, 0)
		s.part.CFrame = (s.part.CFrame + s.v * dt) * CFrame.Angles(s.spin.X * dt, s.spin.Y * dt, s.spin.Z * dt)
		s.part.Transparency = math.clamp((s.t - 0.4) / 0.3, 0, 1)
		if s.t > 0.7 then
			s.part:Destroy()
			table.remove(shards, i)
		end
	end
	rain.Position = h.Position + Vector3.new(0, 18, 0)
	for i = #ripples, 1, -1 do
		local t = ripples[i]
		if t.Parent then
			t.OffsetStudsU, t.OffsetStudsV = (now * 0.7) % B, (now * 0.4) % B
		else
			table.remove(ripples, i)
		end
	end
	if edge.Visible then edgeStroke.Transparency = 0.35 + math.sin(now * 5) * 0.2 end -- under 1 pulse per second
	-- DIG idle pulse and the tutorial card bob
	if digBtn.Visible and not digHeld then scaler(digBtn).Scale = 1 + math.max(0, math.sin(now * 3)) * 0.035 end

	if inMine and now >= nextTry and not hatchBusy then
		local p, res
		if holding then
			if holding.UserInputType == Enum.UserInputType.MouseButton1 then p, res = blockAtCross() else p, res = blockAt(holdPos) end
		elseif digHeld then
			p, res = digTarget()
		end
		if p then
			nextTry = now + C.DIG_COOLDOWN + 0.03
			digPart(p, res)
		end
	end

	-- tutorial
	local msg = stepMessage()
	if msg ~= stepShown then
		stepShown, stepExpired = msg, false
		stepText.Text = msg
		stepCard.Visible = msg ~= ""
		stepCard.Position = S(640, -40)
		tween(stepCard, 0.5, { Position = S(640, 18) }, Enum.EasingStyle.Bounce)
		stepDoneAt = state.step >= 6 and now + 6 or nil
	end
	if stepDoneAt and now > stepDoneAt then
		stepExpired, stepDoneAt = true, nil
	end
	local t = state.target
	local tp = (inMine and t and blocks and blocks:FindFirstChild(t[1] .. "_" .. t[2] .. "_" .. t[3])) or nil
	hl.Adornee, hl.Enabled = tp, tp ~= nil
	hl.FillTransparency = 0.45 + math.sin(now * 4) * 0.2
	arrow.Enabled = tp ~= nil
	if tp then arrowAnchor.Position = tp.Position + Vector3.new(0, B * 0.9 + math.abs(math.sin(now * 4)) * 0.8, 0) end
	arrowText.Text = state.step == 1 and "TAP!" or "DIG!"

	-- crew
	local look = h.CFrame.LookVector
	local right = h.CFrame.RightVector
	for i, pet in petObjs do
		local side = (i % 2 == 0) and 1 or -1
		local goalP = h.Position - look * (3 + math.floor((i - 1) / 2) * 2) + right * side * 2.2 + Vector3.new(0, -1.2 + math.sin(now * 5 + i) * 0.25, 0)
		if now < pet.digUntil then goalP = pet.digPos + Vector3.new(0, math.abs(math.sin((now - pet.hop) * 18)) * 0.6, 0) end
		pet.pos = pet.pos:Lerp(goalP, 1 - math.exp(-dt * 10))
		pet.model:PivotTo(CFrame.lookAt(pet.pos, pet.pos + Vector3.new(look.X, 0, look.Z)))
	end

	-- depth label
	local row = inMine and math.max(1, math.floor((-C.CRUST * B - h.Position.Y + 3) / B) + 1) or (inCave and -1 or 0)
	if row ~= lastRow then
		local L = layerOf(math.max(row, 1))
		layerName.Size = UDim2.fromScale(inMine and 0.4 or 0.58, 0.46) -- the wide font needs the room when no depth shows
		if inMine then
			layerNum.Text = "LAYER " .. L
			layerName.Text = C.LAYERS[L][1]:upper()
			layerDepth.Text = row * B .. " M"
		elseif inCave then
			layerNum.Text, layerName.Text, layerDepth.Text = "CAVES", "CAMP 1 DEPTHS", ""
		else
			layerNum.Text, layerName.Text, layerDepth.Text = "CAMP", "HOLLOW MOUNTAIN", ""
		end
		lastRow = row
		if inMine and atmo then
			local tintCol = C.LAYERS[L][3]:Lerp(Color3.fromRGB(46, 32, 70), 0.55)
			tween(atmo, 1.2, { Color = tintCol, Decay = tintCol:Lerp(Color3.new(), 0.45) })
		end
		tween(marker, 0.3, { Position = UDim2.fromScale(0.5, math.clamp(row / (#C.LAYERS * C.LAYER_ROWS), 0, 1)) }, Enum.EasingStyle.Back)
	end

	-- hub animations (only while you are in the hub)
	if not inMine then
		for _, a in anims do
			local o = a.obj
			if o.Parent then
				if a.light then
					o.Brightness = a.light * (0.85 + math.noise(now * 6, a.seed) * 0.5)
				elseif a.flame then
					local k = 1 + math.sin(now * 9 + a.seed * 3) * 0.18
					o.Size = a.flame * k
					o.CFrame = a.base * CFrame.new(0, (k - 1) * 0.6, 0) * CFrame.Angles(0, now * 2 + a.seed, 0)
				elseif o:IsA("Model") then
					local cf = a.base
					if a.spin then cf = cf * CFrame.Angles(now * a.spin, 0, 0) end
					if a.bob then cf = cf + Vector3.new(0, math.sin(now * 2 + a.seed) * a.bob, 0) end
					o:PivotTo(cf)
				else
					local cf = a.base
					if a.bob then cf = cf + Vector3.new(0, math.sin(now * 2 + a.seed) * a.bob, 0) end
					if a.sway then cf = cf * CFrame.Angles(0, 0, math.sin(now * 1.6 + a.seed) * a.sway) end
					o.CFrame = cf
				end
			end
		end
	end
end)
