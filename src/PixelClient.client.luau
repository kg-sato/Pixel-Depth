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

-- Pastel kit (art/ui_pastel, uploaded 2026-11-08) and the pixel icons (art/ui)
local SKIN = {
	panel = "rbxassetid://79278954190104", card = "rbxassetid://128742357396382", pill = "rbxassetid://125517514288079", dark = "rbxassetid://140361213038970",
	mint = "rbxassetid://99245432768431", pink = "rbxassetid://81976695173406", lilac = "rbxassetid://85859816296944",
	butter = "rbxassetid://75394361548245", sky = "rbxassetid://136700517340299", off = "rbxassetid://124402708705242",
}
local ICON = {
	coin = "rbxassetid://127130970164674", gem = "rbxassetid://112281160766494", pick = "rbxassetid://135042498218444", bag = "rbxassetid://90942769596950",
	crew = "rbxassetid://110749239504965", surface = "rbxassetid://93205212525623", egg = "rbxassetid://93427201556099", star = "rbxassetid://76832160806647",
	dice = "rbxassetid://80139731330207", map = "rbxassetid://86298215875780",
}
local INK, CREAM, WHITE = Color3.fromRGB(62, 42, 86), Color3.fromRGB(255, 247, 238), Color3.new(1, 1, 1)
local MINT, PINK, LILAC, BUTTER, SKY = Color3.fromRGB(127, 220, 180), Color3.fromRGB(255, 157, 176), Color3.fromRGB(185, 164, 238), Color3.fromRGB(255, 217, 112), Color3.fromRGB(142, 200, 255)
local GOLD, PLUM_SOFT = Color3.fromRGB(255, 206, 84), Color3.fromRGB(122, 98, 150)
local FONT = Enum.Font.Arcade -- fallback metrics only; PixelText draws the visible glyphs

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
local function skin(o, kind)
	o.BackgroundTransparency = 1
	local s = o:FindFirstChild("Skin") or new("ImageLabel", o, {
		Name = "Skin", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(16, 16, 48, 48), SliceScale = 0.5, ResampleMode = Enum.ResamplerMode.Pixelated, ZIndex = 0,
	})
	s.Image = SKIN[kind] or SKIN.panel
	o:SetAttribute("Kind", kind)
	return s
end
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
	return PixelText.attach(l, weight or 700)
end
local function panel(parent, size, pos, anchor, kind)
	local f = new("Frame", parent, { Size = size, Position = pos, AnchorPoint = anchor or Vector2.zero })
	skin(f, kind or "panel")
	return f
end
local function icon(parent, name, size, pos, anchor)
	return new("ImageLabel", parent, {
		Name = "Icon", BackgroundTransparency = 1, Image = ICON[name], Size = size, Position = pos, AnchorPoint = anchor or Vector2.zero,
		ResampleMode = Enum.ResamplerMode.Pixelated, ScaleType = Enum.ScaleType.Fit, ZIndex = 2,
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
	sc.Scale = 0.55
	tween(sc, 0.38, { Scale = 1 }, Enum.EasingStyle.Back)
end
local function closePanel(o)
	local sc = scaler(o)
	tween(sc, 0.14, { Scale = 0.7 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	task.delay(0.14, function()
		o.Visible = false
		sc.Scale = 1
	end)
end

-- Button: transparent TextButton, pastel skin, an optional icon and a PixelText label that mirrors .Text; squash on press
local function button(parent, label, size, pos, anchor, kind, iconName, vertical)
	local b = new("TextButton", parent, {
		Size = size, Position = pos, AnchorPoint = anchor or Vector2.zero, BackgroundTransparency = 1, AutoButtonColor = false,
		Font = FONT, Text = label, TextTransparency = 1, MaxVisibleGraphemes = 0, ZIndex = 1,
	})
	skin(b, kind or "mint")
	local lab
	if iconName and vertical then
		icon(b, iconName, UDim2.fromScale(0.5, 0.46), UDim2.fromScale(0.5, 0.1), Vector2.new(0.5, 0))
		lab = text(b, label, UDim2.fromScale(0.86, 0.24), UDim2.fromScale(0.5, 0.62), Vector2.new(0.5, 0), WHITE)
	elseif iconName then
		local ic = icon(b, iconName, UDim2.fromScale(0.3, 0.62), UDim2.fromScale(0.08, 0.5), Vector2.new(0, 0.5))
		new("UIAspectRatioConstraint", ic, { AspectRatio = 1 })
		lab = text(b, label, UDim2.fromScale(0.52, 0.46), UDim2.fromScale(0.68, 0.48), Vector2.new(0.5, 0.5), WHITE)
	else
		lab = text(b, label, UDim2.fromScale(0.84, 0.5), UDim2.fromScale(0.5, 0.47), Vector2.new(0.5, 0.5), WHITE)
	end
	lab.Name = "Label"
	b:GetPropertyChangedSignal("Text"):Connect(function() lab.Text = b.Text end)
	local sc = scaler(b)
	b.MouseEnter:Connect(function() tween(sc, 0.12, { Scale = 1.06 }) end)
	b.MouseLeave:Connect(function() tween(sc, 0.15, { Scale = 1 }) end)
	b.MouseButton1Down:Connect(function() tween(sc, 0.07, { Scale = 0.88 }) end)
	b.MouseButton1Up:Connect(function() tween(sc, 0.45, { Scale = 1 }, Enum.EasingStyle.Elastic) end)
	return b
end
local function setKind(b, kind)
	if b:GetAttribute("Kind") ~= kind then skin(b, kind) end
end

-- HUD (board HUD artboard): gold and egg pills, bag pill, left rail, layer pill and depth strip, tutorial card, DIG, crosshair
local goldPill = panel(gui, S(170, 46), S(20, 18), nil, "pill")
fit(goldPill, 170, 46)
local coinIcon = icon(goldPill, "coin", UDim2.fromScale(0.2, 0.68), UDim2.fromScale(0.06, 0.5), Vector2.new(0, 0.5))
new("UIAspectRatioConstraint", coinIcon, { AspectRatio = 1 })
local goldText = text(goldPill, "0", UDim2.fromScale(0.64, 0.56), UDim2.fromScale(0.3, 0.5), Vector2.new(0, 0.5), GOLD)
goldText.TextXAlignment = Enum.TextXAlignment.Left
goldPill.Name = "GoldPill"

local eggPill = panel(gui, S(112, 46), S(200, 18), nil, "pill")
fit(eggPill, 112, 46)
local eggIc = icon(eggPill, "egg", UDim2.fromScale(0.3, 0.68), UDim2.fromScale(0.08, 0.5), Vector2.new(0, 0.5))
new("UIAspectRatioConstraint", eggIc, { AspectRatio = 1 })
local eggText = text(eggPill, "0", UDim2.fromScale(0.5, 0.56), UDim2.fromScale(0.44, 0.5), Vector2.new(0, 0.5), PINK)
eggText.TextXAlignment = Enum.TextXAlignment.Left
eggPill.Name, eggPill.Visible = "EggPill", false

local bagPill = panel(gui, S(292, 56), S(20, 74), nil, "pill")
fit(bagPill, 292, 56)
bagPill.Name = "BagPill"
local bagIc = icon(bagPill, "bag", UDim2.fromScale(0.13, 0.66), UDim2.fromScale(0.04, 0.5), Vector2.new(0, 0.5))
new("UIAspectRatioConstraint", bagIc, { AspectRatio = 1 })
local bagText = text(bagPill, "BAG", UDim2.fromScale(0.6, 0.32), UDim2.fromScale(0.21, 0.16), nil, WHITE)
bagText.TextXAlignment = Enum.TextXAlignment.Left
local bagTrack = new("Frame", bagPill, { Size = UDim2.fromScale(0.72, 0.22), Position = UDim2.fromScale(0.21, 0.6), BackgroundColor3 = INK, BorderSizePixel = 0, ZIndex = 2 })
local bagFill = new("Frame", bagTrack, { Size = UDim2.fromScale(0, 1), BackgroundColor3 = BUTTER, BorderSizePixel = 0, ZIndex = 3 })
new("Frame", bagFill, { Size = UDim2.fromScale(1, 0.3), Position = UDim2.fromScale(0, 0.7), BackgroundColor3 = Color3.fromRGB(217, 150, 46), BorderSizePixel = 0, ZIndex = 4, BackgroundTransparency = 0.2 })

local railForge = button(gui, "FORGE", S(72, 72), S(20, 142), nil, "lilac", "pick", true)
local railOdds = button(gui, "ODDS", S(72, 72), S(20, 222), nil, "lilac", "dice", true)
local railLift = button(gui, "SURFACE", S(72, 72), S(20, 302), nil, "sky", "surface", true)
for _, b in { railForge, railOdds, railLift } do fit(b, 1, 1) end
railForge.Name, railOdds.Name, railLift.Name = "Upgrades", "OddsButton", "Surface"

local layerPill = panel(gui, S(300, 46), S(1260, 18), Vector2.new(1, 0), "pill")
fit(layerPill, 300, 46)
local layerNum = text(layerPill, "CAMP", UDim2.fromScale(0.27, 0.42), UDim2.fromScale(0.05, 0.5), Vector2.new(0, 0.5), GOLD)
layerNum.TextXAlignment = Enum.TextXAlignment.Left
local layerName = text(layerPill, "", UDim2.fromScale(0.4, 0.42), UDim2.fromScale(0.35, 0.5), Vector2.new(0, 0.5), WHITE)
layerName.TextXAlignment = Enum.TextXAlignment.Left
local layerDepth = text(layerPill, "", UDim2.fromScale(0.18, 0.42), UDim2.fromScale(0.95, 0.5), Vector2.new(1, 0.5), LILAC)
layerDepth.TextXAlignment = Enum.TextXAlignment.Right
local strip = new("Frame", gui, { Size = S(18, 300), Position = S(1242, 82), BackgroundColor3 = INK, BorderSizePixel = 0 })
new("UIStroke", strip, { Color = INK, Thickness = 3 })
for i, lay in C.LAYERS do
	new("Frame", strip, { Size = UDim2.fromScale(1, 1 / #C.LAYERS), Position = UDim2.fromScale(0, (i - 1) / #C.LAYERS), BackgroundColor3 = lay[4][1][2], BorderSizePixel = 0 })
end
local marker = new("Frame", strip, { Size = UDim2.new(1.9, 0, 0, 8), Position = UDim2.fromScale(0.5, 0), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = BUTTER, BorderSizePixel = 0, ZIndex = 3 })
new("UIStroke", marker, { Color = INK, Thickness = 2 })

local stepCard = panel(gui, S(560, 58), S(640, 18), Vector2.new(0.5, 0), "card")
fit(stepCard, 560, 58)
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
	local row = new("Frame", feed, { Size = UDim2.fromScale(0.9, 0.2), BackgroundColor3 = INK, BackgroundTransparency = 0.35, BorderSizePixel = 0, LayoutOrder = -feedN })
	new("UICorner", row, { CornerRadius = UDim.new(0, 4) })
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
			tween(row, 0.3, { BackgroundTransparency = 1 })
			tween(t, 0.3, { TextTransparency = 1, TextStrokeTransparency = 1 })
			task.delay(0.32, function() row:Destroy() end)
		end
	end)
end

-- A dim scrim behind modal panels so they read over the busy world
local scrim = new("Frame", gui, { Name = "Scrim", Size = UDim2.new(1, 0, 1, 60), Position = UDim2.fromOffset(0, -60), BackgroundColor3 = Color3.fromRGB(26, 18, 40), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 0, Visible = false })

-- Night Shaft report (spec 5.7)
local night = panel(gui, S(460, 230), S(640, 296), Vector2.new(0.5, 0.5), "panel")
fit(night, 460, 230)
night.Visible, night.Name = false, "NightReport"
text(night, "NIGHT SHAFT REPORT", UDim2.fromScale(0.8, 0.14), UDim2.fromScale(0.5, 0.08), Vector2.new(0.5, 0), LILAC)
local nightInfo = text(night, "", UDim2.fromScale(0.86, 0.11), UDim2.fromScale(0.5, 0.3), Vector2.new(0.5, 0), INK, 500, false)
local nightGold = text(night, "", UDim2.fromScale(0.6, 0.18), UDim2.fromScale(0.5, 0.46), Vector2.new(0.5, 0), GOLD)
local nightOk = button(night, "COLLECT", UDim2.fromScale(0.5, 0.24), UDim2.fromScale(0.5, 0.92), Vector2.new(0.5, 1), "mint", "coin")
nightOk.Name = "NightCollect"
nightOk.Activated:Connect(function() closePanel(night) end)

-- Backpack full (board Moments artboard)
local sellPop = panel(gui, S(420, 210), S(640, 300), Vector2.new(0.5, 0.5), "panel")
fit(sellPop, 420, 210)
sellPop.Visible, sellPop.Name = false, "SellPopup"
local spIc = icon(sellPop, "bag", UDim2.fromScale(0.16, 0.3), UDim2.fromScale(0.08, 0.08))
new("UIAspectRatioConstraint", spIc, { AspectRatio = 1 })
text(sellPop, "BACKPACK FULL!", UDim2.fromScale(0.66, 0.16), UDim2.fromScale(0.27, 0.12), nil, PINK)
local sellInfo = text(sellPop, "", UDim2.fromScale(0.66, 0.11), UDim2.fromScale(0.27, 0.32), nil, INK, 500, false)
local sellBtn = button(sellPop, "SELL", UDim2.fromScale(0.56, 0.3), UDim2.fromScale(0.5, 0.82), Vector2.new(0.5, 1), "mint", "surface")
sellBtn.Name = "Sell"
text(sellPop, "Rides the lift up to the sell stall", UDim2.fromScale(0.84, 0.08), UDim2.fromScale(0.5, 0.86), Vector2.new(0.5, 0), PLUM_SOFT, 500, false)

-- Forge (board Forge artboard): tabs, four tier cards, stats, UPGRADE
local forge = panel(gui, S(680, 420), S(640, 300), Vector2.new(0.5, 0.5), "panel")
fit(forge, 680, 420)
forge.Visible, forge.Name = false, "Forge"
local fIc1 = icon(forge, "pick", UDim2.fromScale(0.06, 0.1), UDim2.fromScale(0.36, 0.05))
local fIc2 = icon(forge, "pick", UDim2.fromScale(0.06, 0.1), UDim2.fromScale(0.58, 0.05))
for _, ic in { fIc1, fIc2 } do new("UIAspectRatioConstraint", ic, { AspectRatio = 1 }) end
text(forge, "FORGE", UDim2.fromScale(0.2, 0.1), UDim2.fromScale(0.5, 0.05), Vector2.new(0.5, 0), LILAC)
local closeBtn = button(forge, "X", UDim2.fromScale(0.08, 0.12), UDim2.fromScale(0.97, 0.03), Vector2.new(1, 0), "pink")
fit(closeBtn, 1, 1)
closeBtn.Name = "Close"
local tabs, tabWhat = {}, "pick"
for i, t in { { "pick", "PICKAXE" }, { "pack", "BACKPACK" } } do
	local tb = button(forge, t[2], UDim2.fromScale(0.2, 0.09), UDim2.fromScale(0.05 + (i - 1) * 0.215, 0.18), nil, i == 1 and "lilac" or "off")
	tb.Name = "Tab" .. t[2]
	tabs[t[1]] = tb
end
local cards = {}
for i = 1, 4 do
	local cd = panel(forge, UDim2.fromScale(0.215, 0.3), UDim2.fromScale(0.05 + (i - 1) * 0.228, 0.3), nil, "pill")
	cd.Name = "Card" .. i
	local nm = text(cd, "", UDim2.fromScale(0.86, 0.13), UDim2.fromScale(0.5, 0.08), Vector2.new(0.5, 0), INK, 700, false)
	local ic = icon(cd, "pick", UDim2.fromScale(0.5, 0.42), UDim2.fromScale(0.5, 0.26), Vector2.new(0.5, 0))
	new("UIAspectRatioConstraint", ic, { AspectRatio = 1 })
	local st = text(cd, "", UDim2.fromScale(0.8, 0.13), UDim2.fromScale(0.5, 0.78), Vector2.new(0.5, 0), MINT)
	cards[i] = { frame = cd, name = nm, icon = ic, status = st }
end
local stats = panel(forge, UDim2.fromScale(0.58, 0.26), UDim2.fromScale(0.05, 0.66), nil, "card")
local statA = text(stats, "", UDim2.fromScale(0.9, 0.26), UDim2.fromScale(0.05, 0.1), nil, INK, 700, false)
statA.TextXAlignment = Enum.TextXAlignment.Left
local statB = text(stats, "", UDim2.fromScale(0.9, 0.24), UDim2.fromScale(0.05, 0.42), nil, Color3.fromRGB(40, 128, 104), 700, false)
statB.TextXAlignment = Enum.TextXAlignment.Left
local statC = text(stats, "", UDim2.fromScale(0.9, 0.18), UDim2.fromScale(0.05, 0.7), nil, PLUM_SOFT, 500, false)
statC.TextXAlignment = Enum.TextXAlignment.Left
local buyBtn = button(forge, "UPGRADE", UDim2.fromScale(0.3, 0.26), UDim2.fromScale(0.95, 0.66), Vector2.new(1, 0), "mint", "coin")
buyBtn.Name = "Buy"

-- Egg odds (spec 5.4 and 5.12: every random item shows its odds; pity is visible)
do
	local total = 0
	for _, t in C.RARITIES do total += t[2] end
	assert(math.abs(total - 100) < 1e-6, "egg odds must sum to 100")
end
local odds = panel(gui, S(380, 400), S(640, 300), Vector2.new(0.5, 0.5), "panel")
fit(odds, 380, 400)
odds.Visible, odds.Name = false, "Odds"
text(odds, "EGG ODDS", UDim2.fromScale(0.6, 0.08), UDim2.fromScale(0.5, 0.05), Vector2.new(0.5, 0), LILAC)
local oddsClose = button(odds, "X", UDim2.fromScale(0.13, 0.11), UDim2.fromScale(0.96, 0.03), Vector2.new(1, 0), "pink")
fit(oddsClose, 1, 1)
oddsClose.Name = "OddsClose"
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
text(mapP, "THE HOLLOW MOUNTAIN", UDim2.fromScale(0.8, 0.07), UDim2.fromScale(0.5, 0.05), Vector2.new(0.5, 0), LILAC)
local mapClose = button(mapP, "X", UDim2.fromScale(0.12, 0.11), UDim2.fromScale(0.96, 0.03), Vector2.new(1, 0), "pink")
fit(mapClose, 1, 1)
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
	if ore then -- valuable ore glints so the walls are not one muddy colour
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

-- Hatch show (EGG-02): found, squash and stretch, crack, silhouette, reveal, celebrate
local function hatchShow(name)
	hatchBusy = true
	local p = C.PETS[name]
	local rc = rarityColor(p[1])
	local ov = new("TextButton", top, { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(26, 18, 40), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 20 })
	tween(ov, 0.3, { BackgroundTransparency = 0.15 })
	local rays = new("Frame", ov, { Size = UDim2.fromScale(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.45), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, ZIndex = 21 })
	new("UIAspectRatioConstraint", rays, { AspectRatio = 1 })
	for i = 0, 5 do
		local bar = new("Frame", rays, { Size = UDim2.fromScale(1.6, 0.07), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), Rotation = i * 30, BackgroundColor3 = rc, BorderSizePixel = 0, ZIndex = 21, BackgroundTransparency = 1 })
		new("UIGradient", bar, { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.25), NumberSequenceKeypoint.new(1, 1) }) })
		task.delay(2.4, function() tween(bar, 0.45, { BackgroundTransparency = 0 }) end)
	end
	local vp = new("ViewportFrame", ov, {
		Size = UDim2.fromScale(0.42, 0.42), Position = UDim2.fromScale(0.5, 0.45), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1,
		Ambient = Color3.fromRGB(190, 180, 210), LightColor = WHITE, LightDirection = Vector3.new(-1, -1, -1), ZIndex = 22,
	})
	new("UIAspectRatioConstraint", vp, { AspectRatio = 1 })
	local world = new("WorldModel", vp, {})
	local vcam = new("Camera", vp, { FieldOfView = 30 })
	vp.CurrentCamera = vcam
	vcam.CFrame = CFrame.lookAt(Vector3.new(0, 0.8, -9), Vector3.new(0, 0.6, 0))
	local egg = new("Part", world, { Anchored = true, Size = Vector3.new(2.2, 2.8, 2.2), Color = C.EGG_COLOR, CFrame = CFrame.new(0, 0.6, 0) })
	local eggMesh = new("SpecialMesh", egg, { MeshType = Enum.MeshType.Sphere })
	local title = text(ov, "A FOSSIL EGG!", UDim2.fromScale(0.5, 0.08), UDim2.fromScale(0.5, 0.12), Vector2.new(0.5, 0), CREAM, 700)
	title.ZIndex = 23
	local t0 = os.clock()
	local conn = RunService.RenderStepped:Connect(function()
		local t = os.clock() - t0
		if egg.Parent then
			local amp = math.min(t / 1.4, 1)
			egg.CFrame = CFrame.new(0, 0.6, 0) * CFrame.Angles(0, 0, math.sin(t * 22) * amp * 0.35)
			local sq = 1 + math.sin(t * 11) * 0.12 * amp -- squash and stretch, volume kept
			eggMesh.Scale = Vector3.new(1 / math.sqrt(sq), sq, 1 / math.sqrt(sq))
		end
		rays.Rotation = t * 40
	end)
	task.wait(1.5)
	local flash = new("Frame", ov, { Size = UDim2.fromScale(1, 1), BackgroundColor3 = WHITE, BackgroundTransparency = 0, ZIndex = 30 })
	tween(flash, 0.4, { BackgroundTransparency = 1 })
	egg:Destroy()
	local m = petModel(name)
	m:PivotTo(CFrame.Angles(0, math.rad(200), 0))
	m.Parent = world
	vp.ImageColor3 = Color3.new() -- silhouette first, always the real pet (no fake near-miss)
	title.Text = "???"
	task.wait(0.9)
	tween(vp, 0.45, { ImageColor3 = WHITE })
	title.Text = string.upper(name)
	title.TextColor3 = rc
	pop(title, 0.4)
	local sub = text(ov, p[1]:upper() .. "  -  " .. p[2]:upper(), UDim2.fromScale(0.5, 0.06), UDim2.fromScale(0.5, 0.74), Vector2.new(0.5, 0), rc)
	sub.ZIndex = 23
	for i = 1, 16 do -- confetti squares
		local a = i / 16 * math.pi * 2
		local q = new("Frame", ov, { Size = UDim2.fromScale(0.012, 0.02), Position = UDim2.fromScale(0.5, 0.45), BackgroundColor3 = ({ rc, PINK, MINT, BUTTER })[i % 4 + 1], BorderSizePixel = 0, ZIndex = 24 })
		tween(q, 0.9, { Position = UDim2.fromScale(0.5 + math.cos(a) * 0.3, 0.45 + math.sin(a) * 0.35), BackgroundTransparency = 1, Rotation = 180 })
	end
	local hint = text(ov, "TAP TO CONTINUE", UDim2.fromScale(0.3, 0.04), UDim2.fromScale(0.5, 0.86), Vector2.new(0.5, 0), CREAM)
	hint.ZIndex = 23
	local spinT = os.clock()
	local spin = RunService.RenderStepped:Connect(function()
		local t = os.clock() - spinT
		m:PivotTo(CFrame.new(0, math.abs(math.sin(t * 4)) * 0.4, 0) * CFrame.Angles(0, math.rad(200) + math.sin(t * 1.5) * 0.5, 0))
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
	task.delay(4, close)
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
	vm:ScaleTo(vm:GetScale() * (1.9 / math.max(size.Y, 0.1)))
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

local refreshForge
railForge.Activated:Connect(function()
	if forge.Visible then closePanel(forge) else refreshForge(); openPanel(forge) end
end)
closeBtn.Activated:Connect(function() closePanel(forge) end)
railOdds.Activated:Connect(function()
	if odds.Visible then closePanel(odds) else openPanel(odds) end
end)
oddsClose.Activated:Connect(function() closePanel(odds) end)
mapClose.Activated:Connect(function() closePanel(mapP) end)
railLift.Activated:Connect(function() R.Surface:FireServer(inMine and "up" or "down") end)
sellBtn.Activated:Connect(function() R.Sell:FireServer() end)
for what, tb in tabs do
	tb.Activated:Connect(function()
		tabWhat = what
		refreshForge()
	end)
end
buyBtn.Activated:Connect(function() R.Buy:FireServer(tabWhat) end)

-- Keyboard: first person locks the mouse, so every rail button also has a key (shown on the button on PC)
local KEYS = { [Enum.KeyCode.G] = railForge, [Enum.KeyCode.T] = railOdds, [Enum.KeyCode.Q] = railLift }
if UIS.KeyboardEnabled then
	for key, b in KEYS do
		local k = text(b, key.Name, UDim2.fromScale(0.3, 0.22), UDim2.fromScale(0.94, 0.06), Vector2.new(1, 0), BUTTER)
		k.Name = "KeyHint"
	end
	local dk = text(digBtn, "E", UDim2.fromScale(0.12, 0.26), UDim2.fromScale(0.95, 0.1), Vector2.new(1, 0), BUTTER)
	dk.Name = "KeyHint"
end
UIS.InputBegan:Connect(function(input, gp)
	if gp or hatchBusy then return end
	local k = input.KeyCode
	if k == Enum.KeyCode.Q then
		R.Surface:FireServer(inMine and "up" or "down")
	elseif k == Enum.KeyCode.G then
		if forge.Visible then closePanel(forge) else refreshForge(); openPanel(forge) end
	elseif k == Enum.KeyCode.T then
		if odds.Visible then closePanel(odds) else openPanel(odds) end
	elseif k == Enum.KeyCode.Return and sellPop.Visible then
		R.Sell:FireServer()
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
local stepShown, stepDoneAt = "", nil
local function stepMessage()
	if not state then return "" end
	if not inMine and state.step <= 2 then return "Jump into the glowing mine shaft!" end
	if not inMine and state.step == 5 then return "Ride the lift back down to find the egg!" end
	return STEPS[state.step] or ""
end
local TIER_TINT = { -- one colour per pickaxe (Pickaxe Forge palette)
	Color3.fromRGB(230, 180, 130), Color3.fromRGB(200, 200, 215), Color3.fromRGB(255, 150, 180), Color3.fromRGB(255, 230, 140),
	Color3.fromRGB(200, 180, 255), Color3.fromRGB(255, 120, 150), Color3.fromRGB(150, 230, 230), Color3.fromRGB(170, 130, 255),
	Color3.fromRGB(255, 190, 220), Color3.fromRGB(170, 255, 210), Color3.fromRGB(255, 110, 120), Color3.fromRGB(235, 240, 255),
}
local function tierIcon(card, def, owned, isNext, locked)
	card.icon.ImageColor3 = card.icon:GetAttribute("Tint") or WHITE
	card.icon.ImageTransparency = 0
	setKind(card.frame, isNext and "card" or "pill")
end
refreshForge = function()
	if not state then return end
	for what, tb in tabs do setKind(tb, what == tabWhat and "lilac" or "off") end
	local list = tabWhat == "pick" and C.PICKS or C.PACKS
	local cur = state[tabWhat]
	for i, card in cards do
		local idx = cur + i - 1 -- the tier you own, the next one, then two more
		local def = list[idx]
		card.frame.Visible = def ~= nil
		if def then
			card.name.Text = def.name:upper():gsub(" PICKAXE", ""):gsub("THE ", "")
			card.icon.Image = tabWhat == "pick" and ICON.pick or ICON.bag
			card.icon:SetAttribute("Tint", TIER_TINT[idx] and tabWhat == "pick" and TIER_TINT[idx] or WHITE)
			local owned, isNext, locked = idx <= cur, idx == cur + 1, idx > cur + 1
			card.status.Text = owned and "OWNED" or commas(def.cost)
			card.status.TextColor3 = owned and Color3.fromRGB(63, 156, 132) or (isNext and GOLD or PLUM_SOFT)
			tierIcon(card, def, owned, isNext, locked)
		end
	end
	local nxt = list[cur + 1]
	if tabWhat == "pick" then
		statA.Text = "DIG POWER  " .. list[cur].power .. (nxt and ("  >  " .. nxt.power) or "")
		statB.Text = nxt and ("+" .. math.floor((nxt.power / list[cur].power - 1) * 100) .. "% FASTER DIGGING") or "MAXED"
		statC.Text = nxt and ("Next: " .. nxt.name) or "The strongest pickaxe!"
	else
		statA.Text = "CAPACITY  " .. list[cur].cap .. (nxt and ("  >  " .. nxt.cap) or "")
		statB.Text = nxt and ("+" .. (nxt.cap - list[cur].cap) .. " ORE PER TRIP") or "MAXED"
		statC.Text = nxt and ("Next: " .. nxt.name) or "The biggest bag!"
	end
	buyBtn.Text = nxt and ("BUY " .. commas(nxt.cost)) or "MAX"
	setKind(buyBtn, (nxt and state.gold >= nxt.cost) and "mint" or (nxt and "butter" or "off"))
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
	bagText.Text = "BAG " .. s.bag .. " / " .. s.cap
	local full = s.bag >= s.cap
	tween(bagFill, 0.25, { Size = UDim2.fromScale(math.clamp(s.bag / s.cap, 0, 1), 1), BackgroundColor3 = full and PINK or BUTTER }, Enum.EasingStyle.Back)
	if full and not sellPop.Visible then openPanel(sellPop) end
	if not full and sellPop.Visible then closePanel(sellPop) end
	sellInfo.Text = s.bag .. " ORE READY TO SELL"
	eggPill.Visible = (s.eggs or 0) > 0
	eggText.Text = tostring(s.eggs or 0)
	pityText.Text = "Legendary or better in " .. math.max(1, C.PITY - (s.pity or 0)) .. " eggs at most"
	if forge.Visible then refreshForge() end
	syncPets()
end)

-- Camera modes: bird's-eye follow camera in the hub, first person in the mine
local lookDownUntil = 0
local atmo = game:GetService("Lighting"):FindFirstChildOfClass("Atmosphere")
local atmoCamp = atmo and { Density = atmo.Density, Offset = atmo.Offset, Haze = atmo.Haze, Color = atmo.Color, Decay = atmo.Decay }
local ATMO_MINE = { Density = 0.5, Offset = 0, Haze = 0.6, Color = Color3.fromRGB(46, 32, 70), Decay = Color3.fromRGB(26, 18, 44) }
local function setMode(mine)
	inMine = mine
	if mine then lookDownUntil = os.clock() + 0.35 end
	atmo = atmo or game:GetService("Lighting"):FindFirstChildOfClass("Atmosphere")
	if atmo then
		atmoCamp = atmoCamp or { Density = atmo.Density, Offset = atmo.Offset, Haze = atmo.Haze, Color = atmo.Color, Decay = atmo.Decay }
		for k, v in (mine and ATMO_MINE or atmoCamp) do atmo[k] = v end
	end
	cross.Visible, digBtn.Visible = mine, mine
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
	end
end
plr:GetAttributeChangedSignal("InMine"):Connect(function() setMode(plr:GetAttribute("InMine") == true) end)
plr.CharacterAdded:Connect(function()
	vm, vmTier = nil, nil
	task.defer(setMode, plr:GetAttribute("InMine") == true)
end)
setMode(plr:GetAttribute("InMine") == true)

-- Server FX events
R.Fx.OnClientEvent:Connect(function(kind, ...)
	if kind == "ring" then
		local p, t0 = ...
		critPart, critT0, critUntil = p, t0, os.clock() + 2.5
	elseif kind == "hit" then
		local p, frac, _, crit = ...
		if p and p.Parent then
			critUntil = os.clock() + 2.5
			crack(p, frac)
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
		if crit then
			shockwave(pos, BUTTER)
			floatText(pos + Vector3.new(0, 2.2, 0), "CRIT!", PINK)
		end
		burst(pos, lastHitNormal, col, combo > 0 and 26 or 14)
		shake(combo > 0 and 0.7 or 0.35)
		fovKick = combo > 0 and 6 or 3
		if v > 0 then
			oreFly(pos, col)
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
	elseif kind == "frenzyEnd" then
		local bank, combo, newBest = ...
		rainEm.Rate, edge.Visible, banner.Visible, frenzyBar.Visible = 0, false, false, false
		toast("FRENZY  +" .. bank .. " ORE VALUE", GOLD, true)
		if newBest then toast("NEW BEST!  " .. combo .. " COMBO", PINK, true, 1.3) end
	elseif kind == "sold" then
		local gold = ...
		toast("+" .. commas(gold) .. " GOLD", GOLD, true)
		local h = hrp()
		if h then burst(h.Position + Vector3.new(0, 3, 0), Vector3.yAxis, GOLD, 30) end
	elseif kind == "bought" then
		local name = ...
		toast(name:upper() .. "!", MINT, true)
		task.delay(0.3, buildViewmodel)
		for i, card in cards do if i == 2 then pop(card.frame, 1.3) end end
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
		refreshForge()
		openPanel(forge)
	elseif kind == "map" then
		local deepest = ...
		local L = layerOf(math.max(deepest or 1, 1))
		for i, row in mapRows do row.BackgroundTransparency = i > L and 0.6 or 0 end
		openPanel(mapP)
	elseif kind == "noEggs" then
		toast("No eggs yet. Fossil eggs are buried in the mine!", LILAC, true)
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
	elseif kind == "dailyChest" then
		local gold, streak = ...
		toast("DAILY CHEST  +" .. commas(gold) .. " GOLD", GOLD, true)
		toast("Streak " .. streak .. " day" .. (streak == 1 and "" or "s") .. "!", PINK, false, 1.1)
	elseif kind == "chestWait" then
		local secs = ...
		toast("Next chest in " .. math.floor(secs / 3600) .. " h " .. math.floor(secs % 3600 / 60) .. " m", LILAC)
	elseif kind == "lift" then
		local down = ...
		fadeText.Text = down and "RIDING THE LIFT DOWN..." or "BACK TO CAMP!"
		fade.BackgroundTransparency = 0
		fadeText.TextTransparency = 0
		task.delay(0.35, function()
			tween(fade, 0.45, { BackgroundTransparency = 1 })
			tween(fadeText, 0.45, { TextTransparency = 1, TextStrokeTransparency = 1 })
			task.delay(0.46, function() fadeText.TextStrokeTransparency = 0 end)
		end)
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
	if inMine then
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
	if modal ~= scrim.Visible then
		scrim.Visible = true
		tween(scrim, 0.2, { BackgroundTransparency = modal and 0.3 or 1 })
		if not modal then task.delay(0.2, function() if scrim.BackgroundTransparency > 0.95 then scrim.Visible = false end end) end
	end
	-- a free mouse while a panel is open (or Left Alt is held) so PC players can click the HUD in first person
	if inMine then
		local free = forge.Visible or odds.Visible or sellPop.Visible or mapP.Visible or night.Visible or UIS:IsKeyDown(Enum.KeyCode.LeftAlt)
		if free then
			UIS.MouseBehavior = Enum.MouseBehavior.Default
		end
		UIS.MouseIconEnabled = free
	else
		UIS.MouseIconEnabled = true
	end
	-- first-person pickaxe swing: wind-up, fast strike, short hold, recover; walking bob
	if vm and inMine then
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
		stepShown = msg
		stepText.Text = msg
		stepCard.Visible = msg ~= ""
		stepCard.Position = S(640, -40)
		tween(stepCard, 0.5, { Position = S(640, 18) }, Enum.EasingStyle.Bounce)
		stepDoneAt = state.step >= 6 and now + 6 or nil
	end
	if stepDoneAt and now > stepDoneAt then
		stepCard.Visible, stepDoneAt = false, nil
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
	local row = inMine and math.max(1, math.floor((-C.CRUST * B - h.Position.Y + 3) / B) + 1) or 0
	if row ~= lastRow then
		local L = layerOf(math.max(row, 1))
		if inMine then
			layerNum.Text = "LAYER " .. L
			layerName.Text = C.LAYERS[L][1]:upper()
			layerDepth.Text = row * B .. " M"
		else
			layerNum.Text, layerName.Text, layerDepth.Text = "CAMP", "HOLLOW MOUNTAIN", ""
		end
		lastRow = row
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
