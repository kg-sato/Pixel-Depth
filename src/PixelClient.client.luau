-- StarterPlayerScripts.PixelClient: side camera, tap/hold + DIG button input, HUD, tutorial pointer, juice FX, hatch show, crew followers.
-- UI layout follows the Gemini board HUD and Forge screens (References/Gemini Board 2026-11-07, page 02).
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local C = require(RS:WaitForChild("Shared"):WaitForChild("Config"))
local PixelText = require(RS.Shared:WaitForChild("PixelText")) -- Pixelify Sans bitmap font (the board's display face)
local R = RS:WaitForChild("Remotes")

local plr = Players.LocalPlayer
local cam = workspace.CurrentCamera
local B = C.B
local state, blocks
local hatchBusy = false

local function hrp()
	local ch = plr.Character
	return ch and ch:FindFirstChild("HumanoidRootPart")
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

-- UI kit (navy panels, tan-gold 2 px border, pixel font with dark outline, big green primary)
local NAVY, EDGE, CREAM, GOLD = Color3.fromRGB(20, 24, 48), Color3.fromRGB(200, 160, 92), Color3.fromRGB(255, 244, 214), Color3.fromRGB(255, 206, 70)
local GREEN, RED, BLUE, BLACK = Color3.fromRGB(64, 190, 72), Color3.fromRGB(214, 64, 58), Color3.fromRGB(80, 170, 255), Color3.new(0, 0, 0)
local FONT = Enum.Font.Arcade -- fallback metrics only; PixelText draws the visible glyphs

local gui = Instance.new("ScreenGui")
gui.Name, gui.ResetOnSpawn, gui.ZIndexBehavior = "PixelHUD", false, Enum.ZIndexBehavior.Sibling
gui.Parent = plr:WaitForChild("PlayerGui")
local top = Instance.new("ScreenGui") -- full-screen layer for the hatch show and frenzy edge
top.Name, top.ResetOnSpawn, top.IgnoreGuiInset, top.DisplayOrder = "PixelTop", false, true, 10
top.Parent = gui.Parent

local function new(cls, parent, props)
	local o = Instance.new(cls)
	for k, v in props do o[k] = v end
	o.Parent = parent
	return o
end
local function panel(parent, size, pos, anchor, color)
	local f = new("Frame", parent, { Size = size, Position = pos, AnchorPoint = anchor or Vector2.zero, BackgroundColor3 = color or NAVY, BorderSizePixel = 0 })
	new("UICorner", f, { CornerRadius = UDim.new(0, 6) })
	new("UIStroke", f, { Color = EDGE, Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
	return f
end
local function text(parent, s, size, pos, anchor, color, weight)
	return PixelText.attach(new("TextLabel", parent, {
		Size = size or UDim2.fromScale(1, 1), Position = pos or UDim2.new(), AnchorPoint = anchor or Vector2.zero,
		BackgroundTransparency = 1, Font = FONT, TextScaled = true, Text = s, TextColor3 = color or CREAM,
		TextStrokeTransparency = 0, TextStrokeColor3 = BLACK,
	}), weight or 500)
end
local function button(parent, s, size, pos, anchor, color)
	local b = new("TextButton", parent, {
		Size = size, Position = pos, AnchorPoint = anchor or Vector2.zero, BackgroundColor3 = color or GREEN, BorderSizePixel = 0,
		AutoButtonColor = true, Font = FONT, TextScaled = true, Text = s, TextColor3 = CREAM, TextStrokeTransparency = 0,
	})
	new("UICorner", b, { CornerRadius = UDim.new(0, 8) })
	new("UIStroke", b, { Color = BLACK, Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
	new("UIPadding", b, { PaddingTop = UDim.new(0.2, 0), PaddingBottom = UDim.new(0.2, 0), PaddingLeft = UDim.new(0.1, 0), PaddingRight = UDim.new(0.1, 0) })
	new("UISizeConstraint", b, { MinSize = Vector2.new(44, 44) })
	return PixelText.attach(b, 700)
end
local function pop(o, from)
	local sc = o:FindFirstChildOfClass("UIScale") or new("UIScale", o, {})
	sc.Scale = from or 1.25
	tween(sc, 0.3, { Scale = 1 }, Enum.EasingStyle.Back)
end

-- HUD: currency top-left, layer pill top-right, rail left, bag under currency, DIG bottom centre
local goldPill = panel(gui, UDim2.fromScale(0.16, 0.065), UDim2.fromScale(0.012, 0.02))
new("UIAspectRatioConstraint", goldPill, { AspectRatio = 3.6 })
local coin = new("Frame", goldPill, { Size = UDim2.fromScale(0.2, 0.7), Position = UDim2.fromScale(0.05, 0.15), BackgroundColor3 = GOLD, BorderSizePixel = 0 })
new("UICorner", coin, { CornerRadius = UDim.new(1, 0) })
new("UIAspectRatioConstraint", coin, { AspectRatio = 1 })
local goldText = text(goldPill, "0", UDim2.fromScale(0.7, 0.96), UDim2.fromScale(0.27, 0.02), nil, GOLD, 700)
goldText.TextXAlignment = Enum.TextXAlignment.Left

local bagPill = panel(gui, UDim2.fromScale(0.16, 0.065), UDim2.fromScale(0.012, 0.1))
new("UIAspectRatioConstraint", bagPill, { AspectRatio = 3.6 })
local bagText = text(bagPill, "", UDim2.fromScale(0.92, 0.56), UDim2.fromScale(0.04, 0.02), nil, nil, 700)
bagText.TextXAlignment = Enum.TextXAlignment.Left
local bagTrack = new("Frame", bagPill, { Size = UDim2.fromScale(0.9, 0.18), Position = UDim2.fromScale(0.05, 0.74), BackgroundColor3 = Color3.fromRGB(8, 10, 22), BorderSizePixel = 0 })
local bagFill = new("Frame", bagTrack, { Size = UDim2.fromScale(0, 1), BackgroundColor3 = GOLD, BorderSizePixel = 0 })

-- Eggs waiting for the camp incubator
local eggPill = panel(gui, UDim2.fromScale(0.16, 0.05), UDim2.fromScale(0.182, 0.1))
new("UIAspectRatioConstraint", eggPill, { AspectRatio = 4.6 })
local eggText = text(eggPill, "", UDim2.fromScale(0.9, 0.7), UDim2.fromScale(0.05, 0.15), nil, Color3.fromRGB(255, 230, 160))
eggText.TextXAlignment = Enum.TextXAlignment.Left
eggPill.Visible, eggPill.Name = false, "EggPill"

-- Night Shaft report (spec 5.7)
local night = panel(gui, UDim2.fromScale(0.36, 0.34), UDim2.fromScale(0.5, 0.5), Vector2.new(0.5, 0.5), Color3.fromRGB(24, 20, 52))
night.Visible, night.Name = false, "NightReport"
text(night, "Night Shaft report", UDim2.fromScale(0.86, 0.18), UDim2.fromScale(0.5, 0.06), Vector2.new(0.5, 0), GOLD, 700)
local nightInfo = text(night, "", UDim2.fromScale(0.86, 0.13), UDim2.fromScale(0.5, 0.32), Vector2.new(0.5, 0))
local nightGold = text(night, "", UDim2.fromScale(0.7, 0.2), UDim2.fromScale(0.5, 0.48), Vector2.new(0.5, 0), GOLD, 700)
local nightOk = button(night, "COLLECT", UDim2.fromScale(0.5, 0.22), UDim2.fromScale(0.5, 0.93), Vector2.new(0.5, 1))
nightOk.Name = "NightCollect"
nightOk.Activated:Connect(function() night.Visible = false end)

local layerPill = panel(gui, UDim2.fromScale(0.24, 0.055), UDim2.fromScale(0.988, 0.02), Vector2.new(1, 0))
new("UIAspectRatioConstraint", layerPill, { AspectRatio = 6.5 })
local layerText = text(layerPill, "", UDim2.fromScale(0.94, 0.84), UDim2.fromScale(0.5, 0.5), Vector2.new(0.5, 0.5))

local railUp = button(gui, "UPGRADES", UDim2.fromScale(0.1, 0.085), UDim2.fromScale(0.012, 0.2), nil, NAVY)
local railSurface = button(gui, "SURFACE", UDim2.fromScale(0.1, 0.085), UDim2.fromScale(0.012, 0.3), nil, NAVY)
for _, b in { railUp, railSurface } do
	b:FindFirstChildOfClass("UIStroke").Color = EDGE
end

local digBtn = button(gui, "DIG", UDim2.fromScale(0.16, 0.11), UDim2.fromScale(0.5, 0.97), Vector2.new(0.5, 1))
new("UIAspectRatioConstraint", digBtn, { AspectRatio = 2.6 })

local stepCard = panel(gui, UDim2.fromScale(0.44, 0.07), UDim2.fromScale(0.5, 0.11), Vector2.new(0.5, 0), Color3.fromRGB(44, 34, 18))
local stepText = text(stepCard, "", UDim2.fromScale(0.94, 0.78), UDim2.fromScale(0.5, 0.5), Vector2.new(0.5, 0.5), Color3.fromRGB(255, 244, 208))

-- Backpack full popup (UI-02)
local sellPop = panel(gui, UDim2.fromScale(0.32, 0.3), UDim2.fromScale(0.5, 0.48), Vector2.new(0.5, 0.5))
sellPop.Visible = false
text(sellPop, "BACKPACK FULL!", UDim2.fromScale(0.9, 0.2), UDim2.fromScale(0.5, 0.1), Vector2.new(0.5, 0), GOLD, 700)
local sellInfo = text(sellPop, "", UDim2.fromScale(0.9, 0.15), UDim2.fromScale(0.5, 0.36), Vector2.new(0.5, 0))
local sellBtn = button(sellPop, "SELL", UDim2.fromScale(0.62, 0.32), UDim2.fromScale(0.5, 0.92), Vector2.new(0.5, 1))

-- Forge & Upgrades (UI-03)
local shop = panel(gui, UDim2.fromScale(0.5, 0.58), UDim2.fromScale(0.5, 0.52), Vector2.new(0.5, 0.5))
shop.Visible = false
text(shop, "FORGE & UPGRADES", UDim2.fromScale(0.7, 0.12), UDim2.fromScale(0.5, 0.04), Vector2.new(0.5, 0), GOLD, 700)
local closeBtn = button(shop, "X", UDim2.fromScale(0.08, 0.12), UDim2.fromScale(0.975, 0.03), Vector2.new(1, 0), RED)
local rows = {}
for i, what in { "pick", "pack" } do
	local row = panel(shop, UDim2.fromScale(0.92, 0.33), UDim2.fromScale(0.5, 0.2 + (i - 1) * 0.38), Vector2.new(0.5, 0), Color3.fromRGB(32, 38, 72))
	local title = text(row, "", UDim2.fromScale(0.6, 0.38), UDim2.fromScale(0.04, 0.1))
	title.TextXAlignment = Enum.TextXAlignment.Left
	local sub = text(row, "", UDim2.fromScale(0.6, 0.3), UDim2.fromScale(0.04, 0.58), nil, Color3.fromRGB(150, 230, 120))
	sub.TextXAlignment = Enum.TextXAlignment.Left
	local buy = button(row, "UPGRADE", UDim2.fromScale(0.32, 0.72), UDim2.fromScale(0.97, 0.5), Vector2.new(1, 0.5))
	buy.Activated:Connect(function() R.Buy:FireServer(what) end)
	row.Name = what == "pick" and "RowPick" or "RowPack"
	rows[what] = { title = title, sub = sub, buy = buy }
end

-- Egg odds panel (spec 5.4 and 5.12: every random item shows its odds; pity is visible)
do
	local total = 0
	for _, t in C.RARITIES do total += t[2] end
	assert(math.abs(total - 100) < 1e-6, "egg odds must sum to 100")
end
local railOdds = button(gui, "ODDS", UDim2.fromScale(0.1, 0.085), UDim2.fromScale(0.012, 0.4), nil, NAVY)
railOdds:FindFirstChildOfClass("UIStroke").Color = EDGE
local odds = panel(gui, UDim2.fromScale(0.34, 0.6), UDim2.fromScale(0.5, 0.5), Vector2.new(0.5, 0.5))
odds.Visible = false
new("UIAspectRatioConstraint", odds, { AspectRatio = 0.95 })
text(odds, "Egg odds", UDim2.fromScale(0.7, 0.1), UDim2.fromScale(0.5, 0.04), Vector2.new(0.5, 0), GOLD, 700)
local oddsClose = button(odds, "X", UDim2.fromScale(0.12, 0.1), UDim2.fromScale(0.97, 0.03), Vector2.new(1, 0), RED)
for i, t in C.RARITIES do
	local y = 0.18 + (i - 1) * 0.105
	local swatch = new("Frame", odds, { Size = UDim2.fromScale(0.05, 0.06), Position = UDim2.fromScale(0.06, y + 0.008), BackgroundColor3 = t[3], BorderSizePixel = 0 })
	new("UICorner", swatch, { CornerRadius = UDim.new(0, 3) })
	local nameT = text(odds, t[1], UDim2.fromScale(0.5, 0.075), UDim2.fromScale(0.15, y), nil, t[3], 700)
	nameT.TextXAlignment = Enum.TextXAlignment.Left
	local pct = text(odds, (t[2] >= 1 and tostring(t[2]) or string.format("%.1f", t[2])) .. "%", UDim2.fromScale(0.3, 0.075), UDim2.fromScale(0.94, y), Vector2.new(1, 0), CREAM, 700)
	pct.TextXAlignment = Enum.TextXAlignment.Right
end
local pityText = text(odds, "", UDim2.fromScale(0.88, 0.065), UDim2.fromScale(0.5, 0.84), Vector2.new(0.5, 0), Color3.fromRGB(150, 230, 120))
odds.Name, railOdds.Name, oddsClose.Name = "Odds", "OddsButton", "OddsClose"

digBtn.Name, sellBtn.Name, railUp.Name, railSurface.Name, closeBtn.Name = "Dig", "Sell", "Upgrades", "Surface", "Close"
rows.pick.buy.Name, rows.pack.buy.Name, shop.Name, sellPop.Name = "BuyPick", "BuyPack", "Forge", "SellPopup"

local banner = text(gui, "", UDim2.fromScale(0.6, 0.085), UDim2.fromScale(0.5, 0.2), Vector2.new(0.5, 0), GOLD, 700)
banner.Visible = false
local edge = new("Frame", top, { Size = UDim2.new(1, -24, 1, -24), Position = UDim2.fromOffset(12, 12), BackgroundTransparency = 1, Visible = false })
local edgeStroke = new("UIStroke", edge, { Color = GOLD, Thickness = 12, Transparency = 0.35 })

local toasts = 0 -- live toasts stack downwards instead of overlapping
local function toast(msg, color, big, delay)
	task.delay(delay or 0, function()
		local y = 0.34 + (toasts % 3) * 0.1
		toasts += 1
		local t = text(gui, msg, UDim2.fromScale(big and 0.6 or 0.4, big and 0.08 or 0.06), UDim2.fromScale(0.5, y), Vector2.new(0.5, 0.5), color, big and 700 or 500)
		pop(t, 0.3)
		task.delay(1.6, function()
			tween(t, 0.45, { TextTransparency = 1, TextStrokeTransparency = 1, Position = UDim2.fromScale(0.5, y - 0.05) })
			task.delay(0.5, function()
				t:Destroy()
				toasts -= 1
			end)
		end)
	end)
end

-- World FX
local fx = new("Folder", workspace, { Name = "ClientFX" })
local function anchor(size)
	return new("Part", fx, { Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, Transparency = 1, Size = size or Vector3.one })
end
local spark = anchor()
local sparkEm = new("ParticleEmitter", spark, {
	Rate = 0, Lifetime = NumberRange.new(0.25, 0.5), Speed = NumberRange.new(10, 20), SpreadAngle = Vector2.new(80, 80),
	Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 0) }),
	LightEmission = 1, Drag = 5, Acceleration = Vector3.new(0, -40, 0), EmissionDirection = Enum.NormalId.Back,
})
local function burst(pos, color, n)
	spark.Position = pos
	sparkEm.Color = ColorSequence.new(color)
	sparkEm:Emit(n)
end
local rain = anchor(Vector3.new(110, 1, 2))
local rainEm = new("ParticleEmitter", rain, {
	Rate = 0, Color = ColorSequence.new(GOLD), Lifetime = NumberRange.new(1.4, 2), Speed = NumberRange.new(14, 24),
	EmissionDirection = Enum.NormalId.Bottom, Size = NumberSequence.new(0.9), LightEmission = 0.7, Shape = Enum.ParticleEmitterShape.Box,
	Rotation = NumberRange.new(0, 360), RotSpeed = NumberRange.new(-200, 200),
})

local shakeAmp = 0
local function shake(a) shakeAmp = math.max(shakeAmp, a) end

local function floatText(pos, msg, color)
	local a = anchor()
	a.Position = pos + Vector3.new(0, 1, 3)
	local bb = new("BillboardGui", a, { Size = UDim2.fromScale(14, 2.6), LightInfluence = 0 }) -- in front of the blocks (z +3), so no AlwaysOnTop needed
	local t = text(bb, msg, nil, nil, nil, color, 700)
	tween(a, 0.9, { Position = a.Position + Vector3.new(0, 5, 0) })
	task.delay(0.55, function() tween(t, 0.35, { TextTransparency = 1, TextStrokeTransparency = 1 }) end)
	task.delay(1, function() a:Destroy() end)
end

local function oreFly(pos, color)
	local o = new("Part", fx, { Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, Size = Vector3.new(1.3, 1.3, 1.3), Color = color, Material = Enum.Material.Neon })
	local a0 = new("Attachment", o, { Position = Vector3.new(0, 0.5, 0) })
	local a1 = new("Attachment", o, { Position = Vector3.new(0, -0.5, 0) })
	new("Trail", o, { Attachment0 = a0, Attachment1 = a1, Lifetime = 0.25, Color = ColorSequence.new(color), LightEmission = 1, Transparency = NumberSequence.new(0, 1) })
	local p0, t0 = pos + Vector3.new(0, 0, 2.5), os.clock()
	local conn
	conn = RunService.RenderStepped:Connect(function()
		local h = hrp()
		local a = math.min((os.clock() - t0) / 0.42, 1)
		local goal = h and h.Position or p0
		o.Position = p0:Lerp(goal, a * a) + Vector3.new(0, math.sin(a * math.pi) * 4, 0)
		o.Size = Vector3.one * 1.3 * (1 - a * 0.6)
		if a >= 1 then
			conn:Disconnect()
			o:Destroy()
			pop(bagPill, 1.12)
		end
	end)
end

-- Dig reach ring around the miner (Delve reference): blocks inside it can be dug
local ringAnchor = anchor()
new("CylinderHandleAdornment", ringAnchor, { Adornee = ringAnchor, Radius = C.REACH, InnerRadius = C.REACH - 0.18, Height = 0.05, Color3 = Color3.new(1, 1, 1), Transparency = 0.45 })

-- Hit-timing ring: closes on the block every CRIT_PERIOD; tap while it is gold for a crit (the server checks the timing)
local critAnchor = anchor()
local critBB = new("BillboardGui", critAnchor, { Size = UDim2.fromScale(B * 2.4, B * 2.4), LightInfluence = 0, Enabled = false })
local function circle(parent, size, thick, color)
	local f = new("Frame", parent, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(size, size), BackgroundTransparency = 1 })
	new("UICorner", f, { CornerRadius = UDim.new(1, 0) })
	return f, new("UIStroke", f, { Color = color, Thickness = thick, Transparency = 0.2 })
end
local _, critGoal = circle(critBB, 0.42, 2, Color3.new(1, 1, 1)) -- where the ring has to be
critGoal.Transparency = 0.55
local critRing, critStroke = circle(critBB, 1, 3, Color3.new(1, 1, 1))
local critPart, critT0, critUntil = nil, 0, 0
local function shockwave(pos, color)
	local a = anchor()
	a.Position = pos + Vector3.new(0, 0, 2.8)
	local bb = new("BillboardGui", a, { Size = UDim2.fromScale(B * 3, B * 3), LightInfluence = 0 })
	local f, st = circle(bb, 0.3, 6, color)
	tween(f, 0.35, { Size = UDim2.fromScale(1, 1) })
	tween(st, 0.35, { Transparency = 1, Thickness = 1 })
	task.delay(0.4, function() a:Destroy() end)
end

-- Tutorial pointer on the target block
-- (both live in the client FX folder and follow the block: a child of the block would die with it)
local hl = new("Highlight", fx, { FillColor = GOLD, OutlineColor = Color3.new(1, 1, 1), DepthMode = Enum.HighlightDepthMode.AlwaysOnTop, Enabled = false })
local arrowAnchor = anchor()
local arrow = new("BillboardGui", arrowAnchor, { Size = UDim2.fromScale(9, 3.4), Enabled = false, LightInfluence = 0 })
local arrowText = text(arrow, "TAP!", nil, nil, nil, GOLD, 700)

-- Crew followers (voxel chibis built from parts; real models come from the Gemini board later)
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
	cube(Vector3.new(1.5, 1.3, 1.3), Vector3.new(0.3, 1.05, 0.05), body) -- head about 45% of height
	cube(Vector3.new(0.3, 0.6, 0.3), Vector3.new(-0.15, 1.95, 0.05), body)
	cube(Vector3.new(0.3, 0.6, 0.3), Vector3.new(0.75, 1.95, 0.05), body)
	for _, x in { -0.05, 0.65 } do -- 2x2 eyes with a white highlight, on the camera side
		cube(Vector3.new(0.3, 0.32, 0.1), Vector3.new(x, 1.1, 0.72), BLACK)
		cube(Vector3.new(0.1, 0.1, 0.06), Vector3.new(x + 0.06, 1.18, 0.78), Color3.new(1, 1, 1))
	end
	cube(Vector3.new(0.3, 0.4, 0.3), Vector3.new(-0.4, -0.72, 0.3), body)
	cube(Vector3.new(0.3, 0.4, 0.3), Vector3.new(0.4, -0.72, 0.3), body)
	local glow = cube(Vector3.new(0.55, 0.55, 0.55), Vector3.new(-0.95, 0.35, 0), acc, true) -- signature glow
	new("PointLight", glow, { Color = acc, Range = 7, Brightness = 1.4 })
	new("ParticleEmitter", glow, {
		Rate = 6, Lifetime = NumberRange.new(0.6, 1), Speed = NumberRange.new(0.5, 1.5), Color = ColorSequence.new(acc),
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 0) }), LightEmission = 1, SpreadAngle = Vector2.new(180, 180),
	})
	return m
end

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
		petObjs[i] = { model = m, pos = h and h.Position or Vector3.zero, digUntil = 0, digPos = Vector3.zero }
	end
end

-- Hatch show (EGG-02): found, shake, crack, silhouette, reveal, celebrate
local function hatchShow(name)
	hatchBusy = true
	local p = C.PETS[name]
	local rc = rarityColor(p[1])
	local ov = new("TextButton", top, { Size = UDim2.fromScale(1, 1), BackgroundColor3 = BLACK, BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 20 })
	tween(ov, 0.3, { BackgroundTransparency = 0.2 })
	local rays = new("Frame", ov, { Size = UDim2.fromScale(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.45), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = rc, BackgroundTransparency = 1, ZIndex = 21 })
	new("UIAspectRatioConstraint", rays, { AspectRatio = 1 })
	for i = 0, 5 do -- sunburst: six bars that fade at both ends
		local bar = new("Frame", rays, { Size = UDim2.fromScale(1.6, 0.07), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), Rotation = i * 30, BackgroundColor3 = rc, BorderSizePixel = 0, ZIndex = 21 })
		new("UIGradient", bar, { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.25), NumberSequenceKeypoint.new(1, 1) }) })
		bar.BackgroundTransparency = 1
		task.delay(2.4, function() tween(bar, 0.45, { BackgroundTransparency = 0 }) end)
	end
	local vp = new("ViewportFrame", ov, {
		Size = UDim2.fromScale(0.42, 0.42), Position = UDim2.fromScale(0.5, 0.45), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1,
		Ambient = Color3.fromRGB(180, 180, 190), LightColor = Color3.new(1, 1, 1), LightDirection = Vector3.new(-1, -1, -1), ZIndex = 22,
	})
	new("UIAspectRatioConstraint", vp, { AspectRatio = 1 })
	local world = new("WorldModel", vp, {})
	local vcam = new("Camera", vp, { FieldOfView = 30 })
	vp.CurrentCamera = vcam
	vcam.CFrame = CFrame.lookAt(Vector3.new(0, 0.8, 9), Vector3.new(0, 0.6, 0))
	local egg = new("Part", world, { Anchored = true, Size = Vector3.new(2.2, 2.8, 2.2), Color = C.EGG_COLOR, CFrame = CFrame.new(0, 0.6, 0) })
	new("SpecialMesh", egg, { MeshType = Enum.MeshType.Sphere })
	local title = text(ov, "A FOSSIL EGG!", UDim2.fromScale(0.5, 0.08), UDim2.fromScale(0.5, 0.12), Vector2.new(0.5, 0), CREAM, 700)
	title.ZIndex = 23
	local t0 = os.clock()
	local conn = RunService.RenderStepped:Connect(function()
		local t = os.clock() - t0
		if egg.Parent then
			local amp = math.min(t / 1.4, 1) * 0.35
			egg.CFrame = CFrame.new(0, 0.6, 0) * CFrame.Angles(0, 0, math.sin(t * 22) * amp)
		end
		rays.Rotation = t * 40
	end)
	task.wait(1.5)
	local flash = new("Frame", ov, { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0, ZIndex = 30 })
	tween(flash, 0.4, { BackgroundTransparency = 1 })
	egg:Destroy()
	local m = petModel(name)
	m:PivotTo(CFrame.new(0, 0, 0) * CFrame.Angles(0, math.rad(-20), 0))
	m.Parent = world
	vp.ImageColor3 = BLACK -- silhouette first, always the real pet (no fake near-miss)
	title.Text = "???"
	task.wait(0.9)
	tween(vp, 0.45, { ImageColor3 = Color3.new(1, 1, 1) })
	title.Text = string.upper(name)
	title.TextColor3 = rc
	pop(title, 0.4)
	local sub = text(ov, p[1]:upper() .. "  -  " .. p[2]:upper(), UDim2.fromScale(0.5, 0.06), UDim2.fromScale(0.5, 0.74), Vector2.new(0.5, 0), rc)
	sub.ZIndex = 23
	for i = 1, 14 do -- confetti squares
		local a = i / 14 * math.pi * 2
		local q = new("Frame", ov, { Size = UDim2.fromScale(0.012, 0.02), Position = UDim2.fromScale(0.5, 0.45), BackgroundColor3 = i % 2 == 0 and rc or GOLD, BorderSizePixel = 0, ZIndex = 24 })
		tween(q, 0.9, { Position = UDim2.fromScale(0.5 + math.cos(a) * 0.3, 0.45 + math.sin(a) * 0.35), BackgroundTransparency = 1 })
	end
	local hint = text(ov, "TAP TO CONTINUE", UDim2.fromScale(0.3, 0.04), UDim2.fromScale(0.5, 0.86), Vector2.new(0.5, 0), CREAM)
	hint.ZIndex = 23
	local spinT = os.clock()
	local spin = RunService.RenderStepped:Connect(function()
		m:PivotTo(CFrame.Angles(0, math.rad(-20) + math.sin((os.clock() - spinT) * 1.5) * 0.5, 0))
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

-- Input: tap/click a block, hold to keep digging; DIG button digs below (or sideways while moving)
local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Include
local function blockAt(screenPos)
	if not blocks then return nil end
	params.FilterDescendantsInstances = { blocks }
	local ray = cam:ScreenPointToRay(screenPos.X, screenPos.Y)
	local res = workspace:Raycast(ray.Origin, ray.Direction * 800, params)
	local p = res and res.Instance
	if p and p.Parent ~= blocks then p = p.Parent end
	return (p and p.Parent == blocks) and p or nil
end
local lastDir = 1
local function blockNearPlayer()
	local h = hrp()
	if not h or not blocks or not state then return nil end
	local row = math.floor(-(h.Position.Y - 1) / B) + 1
	local col = math.floor((h.Position.X - state.x0) / B) + 1
	local hum = plr.Character:FindFirstChildOfClass("Humanoid")
	local mx = hum and hum.MoveDirection.X or 0
	local tries = math.abs(mx) > 0.3 and { { 0, mx > 0 and 1 or -1 }, { 1, 0 } } or { { 1, 0 }, { 0, lastDir }, { 0, -lastDir } }
	for _, d in tries do
		local p = blocks:FindFirstChild((row + d[1]) .. "_" .. (col + d[2]))
		if p then return p end
	end
	return nil
end
local swingT0 = -10
local stirTold, stirRocks = false, {}
local function digPart(p)
	local h = hrp()
	if not p or not h or (h.Position - p.Position).Magnitude > C.REACH then return end
	swingT0 = os.clock()
	R.Dig:FireServer(p)
	burst(p.Position + Vector3.new(0, 0, 2.4), p.Color:Lerp(Color3.new(1, 1, 1), 0.4), 7)
	shake(0.35)
end

local holding, holdPos, digHeld, nextTry = nil, Vector2.zero, false, 0
UIS.InputBegan:Connect(function(input, gp)
	if gp or hatchBusy then return end
	local t = input.UserInputType
	if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
		holding, holdPos = input, Vector2.new(input.Position.X, input.Position.Y)
		local p = blockAt(holdPos) -- dig now: a quick tap can end before the next frame
		if p and os.clock() >= nextTry then
			nextTry = os.clock() + C.DIG_COOLDOWN + 0.03
			digPart(p)
		end
	elseif input.KeyCode == Enum.KeyCode.E or input.KeyCode == Enum.KeyCode.ButtonX then
		digHeld = true
	end
end)
UIS.InputChanged:Connect(function(input)
	if holding and (input == holding or input.UserInputType == Enum.UserInputType.MouseMovement) then
		holdPos = Vector2.new(input.Position.X, input.Position.Y)
	end
end)
UIS.InputEnded:Connect(function(input)
	if input == holding then holding = nil end
	if input.KeyCode == Enum.KeyCode.E or input.KeyCode == Enum.KeyCode.ButtonX then digHeld = false end
end)
digBtn.MouseButton1Down:Connect(function() digHeld = true end)
digBtn.MouseButton1Up:Connect(function() digHeld = false end)
digBtn.MouseLeave:Connect(function() digHeld = false end)
railUp.Activated:Connect(function()
	shop.Visible = not shop.Visible
	pop(shop, 0.85)
end)
closeBtn.Activated:Connect(function() shop.Visible = false end)
railOdds.Activated:Connect(function()
	odds.Visible = not odds.Visible
	pop(odds, 0.85)
end)
oddsClose.Activated:Connect(function() odds.Visible = false end)
railSurface.Activated:Connect(function() R.Surface:FireServer() end)
sellBtn.Activated:Connect(function() R.Sell:FireServer() end)

-- State from the server
local STEPS = {
	"Tap the glowing block to dig!",
	"Keep digging down to the shiny vein!",
	"Backpack full! Sell your ore!",
	"Open Upgrades and buy a new pickaxe!",
	"A fossil egg is buried below. Dig it out!",
	"Your crew digs with you. Go deeper!",
}
local stepShown, stepDoneAt = 0, nil
local function refreshShop()
	for what, row in rows do
		local list = what == "pick" and C.PICKS or C.PACKS
		local cur, nxt = list[state[what]], list[state[what] + 1]
		if nxt then
			row.title.Text = cur.name .. "  >  " .. nxt.name
			row.sub.Text = what == "pick" and ("MINING POWER " .. cur.power .. " > " .. nxt.power) or ("CAPACITY " .. cur.cap .. " > " .. nxt.cap)
			row.buy.Text = nxt.cost .. " GOLD"
			row.buy.BackgroundColor3 = state.gold >= nxt.cost and GREEN or Color3.fromRGB(70, 74, 92)
		else
			row.title.Text, row.sub.Text, row.buy.Text = cur.name, "MAXED", "MAX"
			row.buy.BackgroundColor3 = Color3.fromRGB(70, 74, 92)
		end
	end
end

R.State.OnClientEvent:Connect(function(s)
	local prev = state
	state = s
	if not blocks then
		blocks = workspace:WaitForChild("Shafts"):WaitForChild("Shaft_" .. plr.UserId):WaitForChild("Blocks")
		local static = blocks.Parent:WaitForChild("Static", 5)
		for _, l in static and static:GetDescendants() or {} do -- camp signs made by the server get the pixel font too
			if l:IsA("TextLabel") then PixelText.attach(l, 700) end
		end
	end
	goldText.Text = tostring(s.gold)
	if prev and prev.gold ~= s.gold then pop(goldPill, 1.15) end
	bagText.Text = "Bag " .. s.bag .. " / " .. s.cap
	local full = s.bag >= s.cap
	tween(bagFill, 0.2, { Size = UDim2.fromScale(math.clamp(s.bag / s.cap, 0, 1), 1), BackgroundColor3 = full and RED or GOLD })
	if full and not sellPop.Visible then pop(sellPop, 0.6) end
	sellPop.Visible = full
	sellInfo.Text = s.bag .. " ORE READY TO SELL"
	if s.step ~= stepShown then
		stepShown = s.step
		stepText.Text = STEPS[s.step] or ""
		stepCard.Visible = true
		pop(stepCard, 1.1)
		stepDoneAt = s.step >= 6 and os.clock() + 6 or nil
	end
	eggPill.Visible = (s.eggs or 0) > 0
	eggText.Text = "Eggs " .. (s.eggs or 0) .. "  hatch at camp"
	pityText.Text = "Legendary or better in " .. math.max(1, C.PITY - (s.pity or 0)) .. " eggs at most"
	refreshShop()
	syncPets()
end)

-- Server FX events
R.Fx.OnClientEvent:Connect(function(kind, ...)
	if kind == "ring" then
		local r, c, t0 = ...
		critPart, critT0, critUntil = blocks and blocks:FindFirstChild(r .. "_" .. c), t0, os.clock() + 2.5
	elseif kind == "hit" then
		local r, c, frac, _, crit = ...
		local p = blocks and blocks:FindFirstChild(r .. "_" .. c)
		if p then
			p.Color = p.Color:Lerp(BLACK, 0.2 * (1 - frac))
			critUntil = os.clock() + 2.5
			if crit then
				floatText(p.Position, "CRIT!", Color3.fromRGB(255, 110, 180))
				shockwave(p.Position, GOLD)
				burst(p.Position + Vector3.new(0, 0, 2.4), GOLD, 22)
				shake(1.1)
			end
		end
	elseif kind == "break" then
		local _, _, pos, ore, v, who, combo, col, crit = ...
		if crit then
			shockwave(pos, GOLD)
			floatText(pos + Vector3.new(0, 2.2, 0), "CRIT!", Color3.fromRGB(255, 110, 180))
		end
		burst(pos + Vector3.new(0, 0, 2.4), col, combo > 0 and 26 or 14)
		shake(combo > 0 and 1.2 or 0.7)
		if v > 0 then
			oreFly(pos, col)
			floatText(pos, "+" .. v .. " " .. ore, combo > 0 and GOLD or (who == "you" and CREAM or BLUE))
		end
		if combo > 0 then
			banner.Text = "GILDED FRENZY!  x" .. combo
			pop(banner, 1.4)
		end
	elseif kind == "frenzy" then
		banner.Text, banner.Visible = "GILDED FRENZY!", true
		pop(banner, 0.4)
		rainEm.Rate, edge.Visible = 45, true
	elseif kind == "frenzyEnd" then
		local bank, combo, newBest = ...
		rainEm.Rate, edge.Visible, banner.Visible = 0, false, false
		toast("FRENZY  +" .. bank .. " ORE VALUE", GOLD, true)
		if newBest then toast("NEW BEST!  " .. combo .. " COMBO", Color3.fromRGB(255, 110, 180), true, 1.3) end
	elseif kind == "sold" then
		local gold = ...
		toast("+" .. gold .. " GOLD", GOLD, true)
		burst((hrp() and hrp().Position or Vector3.zero) + Vector3.new(0, 2, 2), GOLD, 30)
	elseif kind == "bought" then
		toast((...):upper() .. "!", GREEN, true)
	elseif kind == "full" then
		toast("BACKPACK FULL!", RED)
	elseif kind == "stir" then -- a boulder shakes loose above the hole, then drops (server decides where it lands)
		local r, c = ...
		local pos = Vector3.new(state.x0 + (c - 0.5) * B, -(r - 0.5) * B, 0.6)
		local rock = new("Part", fx, { Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, Size = Vector3.new(B * 0.8, B * 0.8, B * 0.8),
			Position = pos, Color = Color3.fromRGB(150, 96, 70), Material = Enum.Material.Slate })
		new("Highlight", rock, { FillTransparency = 1, OutlineColor = Color3.fromRGB(255, 140, 70), DepthMode = Enum.HighlightDepthMode.AlwaysOnTop })
		stirRocks[c] = rock
		local t0 = os.clock()
		task.spawn(function()
			while rock.Parent and os.clock() - t0 < C.STIR_WARN do
				rock.CFrame = CFrame.new(pos + Vector3.new((math.random() - 0.5) * 0.35, 0, 0)) * CFrame.Angles(0, 0, (math.random() - 0.5) * 0.12)
				task.wait(0.03)
			end
		end)
		burst(pos + Vector3.new(0, B / 2, 2.4), Color3.fromRGB(150, 120, 100), 6)
		shake(0.6)
		task.delay(C.STIR_WARN + 0.6, function() rock:Destroy() end)
		if not stirTold then
			stirTold = true
			toast("Titan's Stir! Rocks fall after you dig. Move!", Color3.fromRGB(255, 160, 90), true)
		end
	elseif kind == "fell" then
		local _, c, pos = ...
		local rock = stirRocks[c]
		stirRocks[c] = nil
		if rock and rock.Parent then
			tween(rock, 0.22, { Position = pos }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			task.delay(0.24, function() rock:Destroy() end)
		end
		task.delay(0.22, function()
			burst(pos + Vector3.new(0, -B / 2, 2.4), Color3.fromRGB(170, 140, 110), 16)
			shake(1.4)
		end)
	elseif kind == "bonk" then
		local lost = ...
		toast(lost > 0 and ("Bonk! Spilled " .. lost .. " ore") or "Bonk!", RED, true)
	elseif kind == "egg" then
		toast("Fossil egg! Hatch it at the camp incubator", Color3.fromRGB(255, 230, 160), true)
		pop(eggPill, 1.3)
	elseif kind == "night" then
		local mins, gold, crew = ...
		nightInfo.Text = "Your crew of " .. crew .. " dug for " .. (mins >= 60 and (mins // 60 .. " h " .. mins % 60 .. " m") or (mins .. " m"))
		nightGold.Text = "+" .. gold .. " gold"
		night.Visible = true
		pop(night, 0.6)
	elseif kind == "hatch" then
		task.spawn(hatchShow, ...)
	elseif kind == "petDig" then
		local i, r, c = ...
		local p, pet = blocks and blocks:FindFirstChild(r .. "_" .. c), petObjs[i]
		if p and pet then
			pet.digUntil, pet.digPos = os.clock() + 0.35, p.Position + Vector3.new(0, 1.5, 2.6)
			burst(p.Position + Vector3.new(0, 0, 2.4), C.PETS[pet.model.Name][6], 8)
		end
	end
end)

-- Per frame: camera, held digging, pointer, crew, depth label
local focus, lastLayer, lastRow = nil, 0, -1
RunService:BindToRenderStep("PixelCam", Enum.RenderPriority.Camera.Value + 1, function(dt)
	local h = hrp()
	if not h or not state then return end
	local now = os.clock()
	cam.CameraType = Enum.CameraType.Scriptable
	cam.FieldOfView = C.CAM_FOV
	local goal = Vector3.new(state.x0 + C.COLS * B / 2, h.Position.Y - 10, 0) -- player in the upper third: you dig down
	focus = focus and focus:Lerp(goal, 1 - math.exp(-dt * 7)) or goal
	shakeAmp *= math.exp(-dt * 14)
	local off = Vector3.new(math.random() - 0.5, math.random() - 0.5, 0) * shakeAmp
	local dir = Vector3.new(math.sin(C.CAM_YAW) * math.cos(C.CAM_PITCH), math.sin(C.CAM_PITCH), math.cos(C.CAM_YAW) * math.cos(C.CAM_PITCH))
	cam.CFrame = CFrame.lookAt(focus + dir * C.CAM_DIST + off, focus + off)
	ringAnchor.Position = h.Position
	-- crit ring
	local showRing = critPart and critPart.Parent and now < critUntil
	critBB.Enabled = showRing and true or false
	if showRing then
		critAnchor.Position = critPart.Position + Vector3.new(0, 0, 2.7)
		local phase = ((workspace:GetServerTimeNow() - critT0) % C.CRIT_PERIOD) / C.CRIT_PERIOD
		critRing.Size = UDim2.fromScale(1 - 0.58 * phase, 1 - 0.58 * phase)
		local hot = phase >= C.CRIT_FROM
		critStroke.Color, critStroke.Thickness = hot and GOLD or Color3.new(1, 1, 1), hot and 5 or 3
	end
	-- pickaxe swing: wind-up, fast strike, short hold, recover (local only; the weld belongs to the server)
	local held = plr.Character:FindFirstChild("HeldPickaxe")
	local grip = held and held:FindFirstChild("PickGrip", true)
	local base = grip and grip:GetAttribute("BaseC0")
	if base then
		local t = now - swingT0
		local a = 0
		if t < 0.06 then a = -0.5 * t / 0.06
		elseif t < 0.12 then a = -0.5 + 1.7 * ((t - 0.06) / 0.06) ^ 2
		elseif t < 0.17 then a = 1.2
		elseif t < 0.4 then a = 1.2 * (1 - (t - 0.17) / 0.23) ^ 2 end
		grip.C0 = base * CFrame.Angles(0, 0, -a)
	end
	rain.Position = focus + Vector3.new(0, 36, 8)
	if edge.Visible then edgeStroke.Transparency = 0.35 + math.sin(now * 5) * 0.2 end -- under 1 pulse per second

	if now >= nextTry and not hatchBusy then
		local p = (holding and blockAt(holdPos)) or (digHeld and blockNearPlayer())
		if p then
			nextTry = now + C.DIG_COOLDOWN + 0.03
			digPart(p)
		end
	end

	local hum = plr.Character:FindFirstChildOfClass("Humanoid")
	if hum and math.abs(hum.MoveDirection.X) > 0.3 then lastDir = hum.MoveDirection.X > 0 and 1 or -1 end

	local t = state.target
	local tp = (t and blocks and blocks:FindFirstChild(t[1] .. "_" .. t[2])) or nil
	hl.Adornee, hl.Enabled = tp, tp ~= nil
	hl.FillTransparency = 0.45 + math.sin(now * 4) * 0.2
	arrow.Enabled = tp ~= nil
	if tp then arrowAnchor.Position = tp.Position + Vector3.new(6.5 + math.abs(math.sin(now * 4)) * 1.2, 0, 3) end -- beside the block, clear of the miner
	arrowText.Text = state.step == 1 and "TAP!" or "DIG!"
	if stepDoneAt and now > stepDoneAt then
		stepCard.Visible, stepDoneAt = false, nil
	end

	for i, pet in petObjs do
		local goalP = h.Position + Vector3.new(-lastDir * (2.6 + (i - 1) * 1.8), -0.6 + math.sin(now * 5 + i) * 0.3, 1.8)
		if now < pet.digUntil then goalP = pet.digPos end
		pet.pos = pet.pos:Lerp(goalP, 1 - math.exp(-dt * 10))
		pet.model:PivotTo(CFrame.new(pet.pos) * CFrame.Angles(0, lastDir * 0.5, 0))
	end

	local row = math.max(0, math.floor(-(h.Position.Y - 1) / B) + 1)
	if row ~= lastRow then
		lastRow = row
		local L = layerOf(math.max(row, 1))
		layerText.Text = "Layer " .. L .. ": " .. C.LAYERS[L][1] .. "  " .. row * B .. " m"
		if L ~= lastLayer then
			if lastLayer ~= 0 then toast(C.LAYERS[L][1]:upper() .. " - " .. C.LAYERS[L][2]:upper(), GOLD, true) end
			lastLayer = L
		end
	end
end)
