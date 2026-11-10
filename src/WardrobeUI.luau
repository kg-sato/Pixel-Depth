-- WardrobeUI (ReplicatedStorage.Shared.WardrobeUI): the avatar wardrobe (overnight brief 2026-11-09, phase 4; reference clip
-- instagram.com/p/Dev0tcyj7-s: a category list on the left, the character on a lit round pedestal in the middle, an item grid on
-- the right). Shared by both sides:
--   * M.ITEMS / M.apply(character, wear)   the cosmetics as voxel part lists and the one function that puts them on a character.
--     The server calls it on the real character (it decides what is worn: PixelServer, remote "Wear"); the client calls it on
--     the preview copy, so a pick shows at once.
--   * M.start(E)   the client screen: categories (Head, Face, Hats, Outfits, Lanterns, Pickaxes, Presets) in a glass column, the
--     player's own character on a turning stone pedestal (drag to spin, it breathes while idle), a 3 x 3 grid of item cards with
--     rarity borders, an EQUIPPED badge and a hover lift. Opened with the WARDROBE button in the left column or the V key.
-- Everything here is free and cosmetic: nothing is bought, rolled or locked (pickaxes list the ones you already own).
local M = {}

local function rgb(r, g, b) return Color3.fromRGB(r, g, b) end
local GOLD, MINT, PINKC, LILAC, CREAM, INKC, SKYC = rgb(255, 206, 84), rgb(127, 220, 180), rgb(255, 157, 176), rgb(185, 164, 238), rgb(255, 247, 236), rgb(62, 42, 86), rgb(142, 200, 255)
-- a part: { size x, y, z, offset x, y, z, colour, neon?, rotation z (radians)? }. Offsets are from the head's (or the upper
-- torso's) centre, -Z is the face side, sized for a 1.2 stud head; M.apply scales them to the character.
M.CATS = {
	{ key = "head", label = "HEAD", on = "Head" }, { key = "face", label = "FACE", on = "Head" }, { key = "hat", label = "HATS", on = "Head" },
	{ key = "outfit", label = "OUTFITS", on = "Torso" }, { key = "lantern", label = "LANTERNS" }, { key = "pick", label = "PICKAXES" }, { key = "preset", label = "PRESETS" },
}
M.ITEMS = {
	hat = {
		{ id = "none", name = "No Hat", rar = 1 },
		{ id = "helmet", name = "Miner Helmet", rar = 1, parts = { { 1.36, 0.5, 1.36, 0, 0.72, 0, rgb(255, 205, 96) }, { 1.56, 0.12, 1.66, 0, 0.5, -0.08, rgb(232, 170, 70) }, { 0.34, 0.3, 0.2, 0, 0.74, -0.72, CREAM, true }, { 0.5, 0.42, 0.1, 0, 0.74, -0.66, rgb(96, 84, 110) } } },
		{ id = "beanie", name = "Wool Beanie", rar = 1, parts = { { 1.32, 0.46, 1.32, 0, 0.74, 0, PINKC }, { 1.4, 0.22, 1.4, 0, 0.5, 0, CREAM }, { 0.36, 0.36, 0.36, 0, 1.12, 0, CREAM } } },
		{ id = "mushroom", name = "Mushroom Cap", rar = 2, parts = { { 1.8, 0.4, 1.8, 0, 0.66, 0, rgb(240, 110, 130) }, { 1.3, 0.34, 1.3, 0, 1.0, 0, rgb(250, 132, 148) }, { 0.34, 0.1, 0.34, -0.4, 1.2, 0.2, CREAM }, { 0.28, 0.1, 0.28, 0.42, 1.2, -0.3, CREAM }, { 0.3, 0.1, 0.3, 0.55, 0.88, 0.5, CREAM } } },
		{ id = "wizard", name = "Wizard Cap", rar = 3, parts = { { 1.9, 0.1, 1.9, 0, 0.5, 0, rgb(120, 96, 190) }, { 1.3, 0.34, 1.3, 0, 0.7, 0, LILAC }, { 0.94, 0.36, 0.94, 0.05, 1.04, 0.05, LILAC }, { 0.58, 0.36, 0.58, 0.12, 1.38, 0.1, rgb(160, 138, 220) }, { 0.3, 0.34, 0.3, 0.22, 1.7, 0.16, rgb(160, 138, 220) }, { 0.26, 0.26, 0.1, 0, 0.76, -0.68, GOLD, true, 0.785 } } },
		{ id = "crown", name = "Root Crown", rar = 4, parts = { { 1.34, 0.22, 1.34, 0, 0.58, 0, GOLD }, { 0.24, 0.34, 0.24, -0.52, 0.84, -0.52, GOLD }, { 0.24, 0.34, 0.24, 0.52, 0.84, -0.52, GOLD }, { 0.24, 0.34, 0.24, -0.52, 0.84, 0.52, GOLD }, { 0.24, 0.34, 0.24, 0.52, 0.84, 0.52, GOLD }, { 0.26, 0.44, 0.24, 0, 0.9, -0.56, GOLD }, { 0.2, 0.2, 0.1, 0, 0.6, -0.69, MINT, true, 0.785 } } },
	},
	head = {
		{ id = "none", name = "Nothing", rar = 1 },
		{ id = "muffs", name = "Ear Muffs", rar = 1, parts = { { 0.26, 0.6, 0.6, -0.72, 0, 0, MINT }, { 0.26, 0.6, 0.6, 0.72, 0, 0, MINT }, { 1.5, 0.12, 0.2, 0, 0.66, 0, rgb(96, 84, 110) }, { 0.12, 0.5, 0.2, -0.72, 0.44, 0, rgb(96, 84, 110) }, { 0.12, 0.5, 0.2, 0.72, 0.44, 0, rgb(96, 84, 110) } } },
		{ id = "bow", name = "Big Bow", rar = 2, parts = { { 0.5, 0.44, 0.22, -0.34, 0.5, 0.62, PINKC, false, 0.3 }, { 0.5, 0.44, 0.22, 0.34, 0.5, 0.62, PINKC, false, -0.3 }, { 0.24, 0.26, 0.26, 0, 0.5, 0.64, rgb(214, 110, 136) } } },
		{ id = "antlers", name = "Root Antlers", rar = 3, parts = { { 0.16, 0.6, 0.16, -0.42, 0.86, 0, rgb(120, 84, 70), false, 0.3 }, { 0.16, 0.6, 0.16, 0.42, 0.86, 0, rgb(120, 84, 70), false, -0.3 }, { 0.14, 0.34, 0.14, -0.7, 1.06, 0, rgb(150, 104, 90), false, 0.9 }, { 0.14, 0.34, 0.14, 0.7, 1.06, 0, rgb(150, 104, 90), false, -0.9 }, { 0.14, 0.14, 0.14, -0.56, 1.24, 0, MINT, true }, { 0.14, 0.14, 0.14, 0.56, 1.24, 0, MINT, true } } },
		{ id = "halo", name = "Glow Halo", rar = 4, parts = { { 1.0, 0.1, 0.16, 0, 1.0, -0.42, GOLD, true }, { 1.0, 0.1, 0.16, 0, 1.0, 0.42, GOLD, true }, { 0.16, 0.1, 1.0, -0.42, 1.0, 0, GOLD, true }, { 0.16, 0.1, 1.0, 0.42, 1.0, 0, GOLD, true } } },
	},
	face = {
		{ id = "none", name = "Bare Face", rar = 1 },
		{ id = "blush", name = "Rosy Cheeks", rar = 1, parts = { { 0.26, 0.14, 0.05, -0.36, -0.14, -0.62, PINKC }, { 0.26, 0.14, 0.05, 0.36, -0.14, -0.62, PINKC } } },
		{ id = "bandana", name = "Dust Bandana", rar = 1, parts = { { 1.28, 0.42, 0.14, 0, -0.34, -0.58, rgb(240, 110, 130) }, { 0.16, 0.42, 1.2, -0.62, -0.34, 0, rgb(214, 96, 116) }, { 0.16, 0.42, 1.2, 0.62, -0.34, 0, rgb(214, 96, 116) }, { 0.3, 0.3, 0.14, 0.2, -0.3, 0.66, rgb(214, 96, 116), false, 0.5 } } },
		{ id = "glasses", name = "Round Glasses", rar = 2, parts = { { 0.44, 0.4, 0.06, -0.3, 0.1, -0.63, GOLD }, { 0.44, 0.4, 0.06, 0.3, 0.1, -0.63, GOLD }, { 0.3, 0.26, 0.08, -0.3, 0.1, -0.64, SKYC }, { 0.3, 0.26, 0.08, 0.3, 0.1, -0.64, SKYC }, { 0.2, 0.08, 0.06, 0, 0.14, -0.63, GOLD } } },
		{ id = "goggles", name = "Deep Goggles", rar = 3, parts = { { 1.3, 0.3, 1.3, 0, 0.14, 0, rgb(96, 84, 110) }, { 0.48, 0.42, 0.16, -0.3, 0.12, -0.64, rgb(150, 108, 60) }, { 0.48, 0.42, 0.16, 0.3, 0.12, -0.64, rgb(150, 108, 60) }, { 0.32, 0.26, 0.18, -0.3, 0.12, -0.66, MINT, true }, { 0.32, 0.26, 0.18, 0.3, 0.12, -0.66, MINT, true } } },
	},
	outfit = {
		{ id = "none", name = "Own Clothes", rar = 1 },
		{ id = "bib", name = "Miner Bib", rar = 1, parts = { { 1.3, 1.1, 0.12, 0, -0.1, -0.58, rgb(255, 205, 96) }, { 0.22, 0.7, 0.12, -0.5, 0.62, -0.58, rgb(232, 170, 70) }, { 0.22, 0.7, 0.12, 0.5, 0.62, -0.58, rgb(232, 170, 70) }, { 0.5, 0.36, 0.08, 0, -0.2, -0.66, rgb(232, 170, 70) } } },
		{ id = "scarf", name = "Explorer Scarf", rar = 2, parts = { { 1.6, 0.32, 1.3, 0, 0.82, 0, MINT }, { 0.36, 0.9, 0.14, -0.4, 0.3, -0.62, MINT, false, 0.12 }, { 0.36, 0.2, 0.14, -0.46, -0.2, -0.62, CREAM, false, 0.12 } } },
		{ id = "pack", name = "Crystal Pack", rar = 3, parts = { { 1.3, 1.3, 0.6, 0, 0, 0.82, rgb(150, 104, 90) }, { 1.34, 0.22, 0.64, 0, 0.3, 0.82, rgb(96, 70, 74) }, { 0.3, 0.7, 0.3, -0.34, 0.9, 0.82, MINT, true, 0.2 }, { 0.34, 0.9, 0.34, 0.06, 1.0, 0.86, LILAC, true }, { 0.26, 0.6, 0.26, 0.42, 0.86, 0.8, PINKC, true, -0.25 } } },
		{ id = "cape", name = "Royal Cape", rar = 4, parts = { { 2.0, 0.3, 1.2, 0, 0.84, 0.1, GOLD }, { 1.9, 1.1, 0.14, 0, 0.2, 0.64, rgb(150, 110, 220) }, { 2.06, 1.0, 0.14, 0, -0.8, 0.78, rgb(128, 92, 200) }, { 2.2, 0.3, 0.16, 0, -1.4, 0.86, CREAM }, { 0.3, 0.3, 0.1, 0, 0.84, -0.54, PINKC, true, 0.785 } } },
	},
	lantern = {
		{ id = "ember", name = "Ember Flame", rar = 1, color = rgb(255, 196, 120) }, { id = "mint", name = "Moss Flame", rar = 1, color = rgb(140, 240, 190) },
		{ id = "rose", name = "Rose Flame", rar = 2, color = rgb(255, 150, 190) }, { id = "lilac", name = "Dusk Flame", rar = 3, color = rgb(190, 160, 255) },
		{ id = "star", name = "Starlight", rar = 4, color = rgb(210, 232, 255) },
	},
}
M.DEFAULT = { hat = "none", head = "none", face = "none", outfit = "none", lantern = "ember" }

function M.find(slot, id)
	for _, it in M.ITEMS[slot] or {} do
		if it.id == id then return it end
	end
end
-- a clean copy of a wear table: only known slots and items (the server runs every client value through this)
function M.clean(wear)
	local out = {}
	for slot, def in M.DEFAULT do
		local id = type(wear) == "table" and wear[slot]
		out[slot] = (type(id) == "string" and M.find(slot, id)) and id or def
	end
	return out
end
local function buildParts(parent, anchor, it, k)
	for _, s in it.parts or {} do
		local p = Instance.new("Part")
		p.Name, p.Size, p.Color = "Wear", Vector3.new(s[1], s[2], s[3]) * k, s[7]
		p.Material = s[8] and Enum.Material.Neon or Enum.Material.SmoothPlastic
		p.CFrame = anchor.CFrame * CFrame.new(s[4] * k, s[5] * k, s[6] * k) * CFrame.Angles(0, 0, s[9] or 0)
		p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		p.CanCollide, p.CanQuery, p.CanTouch, p.Massless, p.CastShadow = false, false, false, true, false
		p.Anchored = anchor.Anchored
		local w = Instance.new("WeldConstraint")
		w.Part0, w.Part1 = anchor, p
		w.Parent = p
		p.Parent = parent
	end
end
function M.apply(char, wear)
	local old = char:FindFirstChild("Wardrobe")
	if old then old:Destroy() end
	local head = char:FindFirstChild("Head")
	local torso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
	if not head or not torso then return end
	local m = Instance.new("Model")
	m.Name = "Wardrobe"
	local hk = head.Size.Y / 1.2 -- R6 heads are 1 high with a wider mesh: close enough at this scale
	local up = torso.Name == "Torso" and 0.2 or 0
	for _, c in M.CATS do
		local it = c.on and M.find(c.key, wear[c.key])
		if it and it.parts then
			if c.on == "Head" then
				buildParts(m, head, it, hk)
			else
				local shifted = { parts = {} }
				for i, s in it.parts do shifted.parts[i] = { s[1], s[2], s[3], s[4], s[5] + up, s[6], s[7], s[8], s[9] } end
				buildParts(m, torso, shifted, torso.Size.X / 2)
			end
		end
	end
	m.Parent = char
end

function M.start(E)
	local C, R, plr, gui, new, S, fit, text, panel, button = E.C, E.R, E.plr, E.gui, E.new, E.S, E.fit, E.text, E.panel, E.button
	local openPanel, closePanel, ribbonTitle, closeButton, sfx, pop, tween, setKind = E.openPanel, E.closePanel, E.ribbonTitle, E.closeButton, E.sfx, E.pop, E.tween, E.setKind
	local INK, WHITE = E.INK, E.WHITE
	local UIS, RunService = game:GetService("UserInputService"), game:GetService("RunService")
	local WearR = R:WaitForChild("Wear", 20)
	if not WearR then return end
	local MUTED = rgb(107, 90, 128)
	local wear = table.clone(M.DEFAULT)
	local presets, st = {}, nil
	local cat = "hat"

	local win = panel(gui, S(1060, 500), S(640, 306), Vector2.new(0.5, 0.5), "panel")
	fit(win, 1060, 500)
	win.Name, win.Visible = "Wardrobe", false
	if E.addModal then E.addModal(win) end
	ribbonTitle(win, "WARDROBE", "ribbonLilac", 0.36)
	local close = closeButton(win, "WardrobeClose")

	-- left: the category stack
	local tabs = {}
	for i, c in M.CATS do
		local b = button(win, c.label, UDim2.fromScale(0.17, 0.092), UDim2.fromScale(0.045, 0.15 + (i - 1) * 0.108), nil, "tab")
		b.ZIndex = 6
		tabs[c.key] = b
	end

	-- centre: the character on its pedestal, in a viewport
	local stage = new("Frame", win, { Size = UDim2.fromScale(0.34, 0.76), Position = UDim2.fromScale(0.24, 0.15), BackgroundColor3 = rgb(40, 30, 62), BackgroundTransparency = 0.25, BorderSizePixel = 0, ZIndex = 6 })
	new("UICorner", stage, { CornerRadius = UDim.new(0.06, 0) })
	new("UIStroke", stage, { Color = LILAC, Thickness = 2, Transparency = 0.3 })
	new("UIGradient", stage, { Rotation = 90, Color = ColorSequence.new(rgb(120, 100, 190), rgb(36, 26, 58)) }) -- a pastel night wash behind the figure
	local vf = new("ViewportFrame", stage, { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 7, Ambient = rgb(196, 178, 226), LightColor = rgb(255, 244, 226), LightDirection = Vector3.new(0.4, -0.7, 1) }) -- a key light on the face (the camera looks along +Z)
	local world = new("WorldModel", vf, {})
	local vcam = new("Camera", vf, { FieldOfView = 30 })
	vf.CurrentCamera = vcam
	local hintT = text(stage, "DRAG TO TURN", UDim2.fromScale(0.5, 0.04), UDim2.fromScale(0.5, 0.965), Vector2.new(0.5, 0.5), CREAM, 700, false)
	hintT.ZIndex, hintT.TextTransparency = 8, 0.35
	local pedestal = new("Model", world, { Name = "Pedestal" })
	local function disc(d, h, y, color, neon)
		return new("Part", pedestal, { Shape = Enum.PartType.Cylinder, Size = Vector3.new(h, d, d), CFrame = CFrame.new(0, y, 0) * CFrame.Angles(0, 0, math.pi / 2), Color = color, Anchored = true, Material = neon and Enum.Material.Neon or Enum.Material.Slate, TopSurface = Enum.SurfaceType.Smooth, BottomSurface = Enum.SurfaceType.Smooth })
	end
	disc(6.4, 0.5, -0.25, rgb(70, 54, 100))
	disc(5.6, 0.3, 0.15, rgb(98, 78, 134))
	disc(5.9, 0.08, 0.02, MINT, true) -- the lit ring round the top step
	disc(4.6, 0.06, 0.32, rgb(126, 104, 168))
	local figure, yaw, yawV, dragging, lastX = nil, 0.5, 0, false, 0
	local function rebuild() -- a fresh copy of the character (it carries the pickaxe, the torch and whatever the server last put on it)
		if figure then figure:Destroy() figure = nil end
		local ch = plr.Character
		if not ch or not ch:FindFirstChild("HumanoidRootPart") then return end
		ch.Archivable = true
		local c = ch:Clone()
		for _, d in c:GetDescendants() do
			if d:IsA("LuaSourceContainer") or d:IsA("Sound") or d:IsA("ParticleEmitter") or d:IsA("PointLight") or d:IsA("BillboardGui") then d:Destroy()
			elseif d:IsA("BasePart") then d.Anchored, d.LocalTransparencyModifier = true, 0 end
		end
		local hum = c:FindFirstChildOfClass("Humanoid")
		if hum then hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None end
		c.Name = "Figure"
		c.Parent = world
		local cf, size = c:GetBoundingBox()
		c:PivotTo(CFrame.new(-cf.Position.X, 0.36 - (cf.Position.Y - size.Y / 2), -cf.Position.Z) * c:GetPivot()) -- feet on the pedestal, centred
		figure = c
		M.apply(figure, wear)
		for _, p in figure.Wardrobe:GetChildren() do p.Anchored = true end
		vcam.CFrame = CFrame.lookAt(Vector3.new(0, 4.0, -15.5), Vector3.new(0, 2.5, 0))
	end
	local basePivot
	local function redress()
		if not figure then return end
		figure:PivotTo(basePivot or figure:GetPivot())
		M.apply(figure, wear)
		for _, p in figure.Wardrobe:GetChildren() do p.Anchored = true end
	end
	local grab = new("TextButton", stage, { Text = "", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 9 })
	grab.InputBegan:Connect(function(io)
		if io.UserInputType == Enum.UserInputType.MouseButton1 or io.UserInputType == Enum.UserInputType.Touch then dragging, lastX = true, io.Position.X end
	end)
	UIS.InputChanged:Connect(function(io)
		if dragging and (io.UserInputType == Enum.UserInputType.MouseMovement or io.UserInputType == Enum.UserInputType.Touch) then
			yawV = (io.Position.X - lastX) * 0.012
			yaw += yawV
			lastX = io.Position.X
		end
	end)
	UIS.InputEnded:Connect(function(io)
		if io.UserInputType == Enum.UserInputType.MouseButton1 or io.UserInputType == Enum.UserInputType.Touch then dragging = false end
	end)

	-- right: the item grid
	local head = text(win, "HATS", UDim2.fromScale(0.3, 0.06), UDim2.fromScale(0.61, 0.15), nil, INK, 700, false)
	head.TextXAlignment, head.ZIndex = Enum.TextXAlignment.Left, 6
	local grid = new("ScrollingFrame", win, { Size = UDim2.fromScale(0.345, 0.66), Position = UDim2.fromScale(0.605, 0.23), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 5, ScrollBarImageColor3 = INK, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ZIndex = 6 })
	new("UIGridLayout", grid, { CellSize = UDim2.fromScale(0.31, 0.31), CellPadding = UDim2.fromScale(0.03, 0.03), SortOrder = Enum.SortOrder.LayoutOrder })
	new("UIPadding", grid, { PaddingTop = UDim.new(0.02, 0), PaddingLeft = UDim.new(0.01, 0) })

	local function rarColor(i) return (C.RARITIES[i] and C.RARITIES[i][3]) or LILAC end
	local function send(...) WearR:FireServer(...) end
	local refresh
	local function card(i, name, rar, equipped, onPick)
		local f = panel(grid, UDim2.new(), UDim2.new(), nil, equipped and "mint" or "slot")
		f.LayoutOrder, f.ZIndex = i, 7
		new("UICorner", f, { CornerRadius = UDim.new(0.17, 0) })
		new("UIStroke", f, { Color = rarColor(rar), Thickness = 3, Transparency = 0.1 }) -- the rarity border follows the card's round corners
		local nm = text(f, name, UDim2.fromScale(0.9, 0.17), UDim2.fromScale(0.5, 0.86), Vector2.new(0.5, 0.5), INK, 700, false)
		nm.ZIndex = 9
		if equipped then
			local badge = panel(f, UDim2.fromScale(0.86, 0.2), UDim2.fromScale(0.5, 0.04), Vector2.new(0.5, 0.5), "pillMint")
			badge.ZIndex = 10
			text(badge, "EQUIPPED", UDim2.fromScale(0.84, 0.62), UDim2.fromScale(0.5, 0.5), Vector2.new(0.5, 0.5), rgb(32, 156, 92), 700, false).ZIndex = 11
		end
		local sc = new("UIScale", f, {})
		local hit = new("TextButton", f, { Text = "", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 12 })
		hit.MouseEnter:Connect(function() tween(sc, 0.22, { Scale = 1.07 }, Enum.EasingStyle.Back) end) -- the hover lift
		hit.MouseLeave:Connect(function() tween(sc, 0.18, { Scale = 1 }) end)
		hit.Activated:Connect(function()
			sfx("click", 1.15)
			sc.Scale = 0.9
			tween(sc, 0.35, { Scale = 1 }, Enum.EasingStyle.Elastic)
			onPick()
		end)
		return f
	end
	local function itemIcon(f, c, it) -- the item itself on a plain block head (or chest), in a small viewport
		local v = new("ViewportFrame", f, { Size = UDim2.fromScale(0.92, 0.7), Position = UDim2.fromScale(0.5, 0.4), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, ZIndex = 8, Ambient = rgb(180, 160, 215), LightColor = rgb(255, 242, 226), LightDirection = Vector3.new(0.5, -1, 0.8) })
		local wm = new("WorldModel", v, {})
		local body = c.on == "Torso"
		local proxy = new("Part", wm, { Name = body and "UpperTorso" or "Head", Size = body and Vector3.new(2, 1.6, 1) or Vector3.new(1.2, 1.2, 1.2), CFrame = CFrame.new(), Anchored = true, Color = rgb(214, 202, 236), Material = Enum.Material.SmoothPlastic, TopSurface = Enum.SurfaceType.Smooth, BottomSurface = Enum.SurfaceType.Smooth })
		proxy.Color = rgb(255, 226, 200) -- a chibi bust: skin, two eyes, shoulders
		if not body then
			for _, x in { -0.26, 0.26 } do new("Part", wm, { Size = Vector3.new(0.16, 0.24, 0.05), CFrame = CFrame.new(x, -0.02, -0.61), Anchored = true, Color = INKC, Material = Enum.Material.SmoothPlastic }) end
			new("Part", wm, { Size = Vector3.new(1.5, 0.5, 0.8), CFrame = CFrame.new(0, -0.86, 0), Anchored = true, Color = LILAC, Material = Enum.Material.SmoothPlastic })
		else
			proxy.Color = LILAC
			new("Part", wm, { Size = Vector3.new(1.2, 1.2, 1.2), CFrame = CFrame.new(0, 1.4, 0), Anchored = true, Color = rgb(255, 226, 200), Material = Enum.Material.SmoothPlastic })
		end
		if it.parts then buildParts(wm, proxy, it, 1) end
		local cam2 = new("Camera", v, { FieldOfView = 30 })
		cam2.CFrame = CFrame.lookAt(body and Vector3.new(-2.8, 1.5, it.id == "bib" and -4.8 or 4.8) or Vector3.new(-1.7, 1.7, -3.1), Vector3.new(0, body and 0 or 0.5, 0)) -- backs for capes and packs, fronts for the rest
		v.CurrentCamera = cam2
	end
	refresh = function()
		for _, o in grid:GetChildren() do if o:IsA("GuiObject") then o:Destroy() end end
		for k, b in tabs do setKind(b, k == cat and "tabOn" or "tab") end
		local def
		for _, c in M.CATS do if c.key == cat then def = c end end
		head.Text = def.label
		if cat == "pick" then
			for i = 1, (st and st.pick) or 1 do
				local pk = C.PICKS[i]
				local f = card(i, pk.name:gsub(" Pickaxe", ""):upper(), math.clamp(math.ceil(i / 2), 1, #C.RARITIES), st and st.equip == i, function() R.Buy:FireServer("equip", i) end)
				local ic = new("ImageLabel", f, { Image = E.ICON.pick, BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit, Size = UDim2.fromScale(0.56, 0.5), Position = UDim2.fromScale(0.5, 0.42), AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 8 })
				new("UIAspectRatioConstraint", ic, { AspectRatio = 1 })
			end
		elseif cat == "preset" then
			for k = 1, 3 do
				local p = presets[tostring(k)]
				local f = card(k, p and ("LOOK " .. k) or ("EMPTY " .. k), p and 3 or 1, false, function()
					if p then send("load", k) else send("save", k) end
				end)
				text(f, p and "TAP TO WEAR" or "TAP TO SAVE THIS LOOK", UDim2.fromScale(0.84, 0.3), UDim2.fromScale(0.5, 0.42), Vector2.new(0.5, 0.5), MUTED, 700, false).ZIndex = 8
				if p then
					local sv = button(f, "SAVE", UDim2.fromScale(0.6, 0.2), UDim2.fromScale(0.5, 0.66), Vector2.new(0.5, 0.5), "lilac")
					sv.ZIndex = 13
					sv.Activated:Connect(function() send("save", k) end)
				end
			end
		else
			for i, it in M.ITEMS[cat] do
				local f = card(i, it.name:upper(), it.rar, wear[cat] == it.id, function()
					wear[cat] = it.id -- shown at once on the preview; the server answers with the real state
					redress()
					refresh()
					send("set", cat, it.id)
				end)
				if it.color then
					local fl = new("Frame", f, { Size = UDim2.fromScale(0.3, 0.4), Position = UDim2.fromScale(0.5, 0.4), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = it.color, BorderSizePixel = 0, Rotation = 45, ZIndex = 8 })
					new("UICorner", fl, { CornerRadius = UDim.new(0.3, 0) })
					new("UIStroke", fl, { Color = WHITE, Thickness = 2, Transparency = 0.3 })
				else
					itemIcon(f, def, it)
				end
			end
		end
	end
	for k, b in tabs do
		b.Activated:Connect(function()
			cat = k
			refresh()
		end)
	end

	local function open()
		if win.Visible or (E.isBusy and E.isBusy()) then return end
		rebuild()
		basePivot = figure and figure:GetPivot()
		refresh()
		openPanel(win)
		sfx("sparkle", 1.1)
	end
	local function shut() if win.Visible then closePanel(win) end end
	close.Activated:Connect(shut)
	UIS.InputBegan:Connect(function(io, gp)
		if gp then return end
		if io.KeyCode == Enum.KeyCode.V then if win.Visible then shut() elseif not plr:GetAttribute("InCave") and not plr:GetAttribute("InMine") then open() end end -- a town thing
	end)
	-- the WARDROBE button joins the left column (UpgradeTracker owns it)
	local btn = button(gui, "WARDROBE", S(76, 76), S(20, 320), nil, "pink", "crew", true)
	fit(btn, 1, 1)
	btn.Name = "WardrobeButton"
	btn.Activated:Connect(function() if win.Visible then shut() else open() end end)
	local function inTown() btn.Visible = not plr:GetAttribute("InCave") and not plr:GetAttribute("InMine") end -- a town thing: the cave column stays short
	plr:GetAttributeChangedSignal("InCave"):Connect(inTown)
	plr:GetAttributeChangedSignal("InMine"):Connect(inTown)
	inTown()
	task.spawn(function()
		for _ = 1, 50 do
			if E.addRow then E.addRow(btn, 76) return end
			task.wait(0.1)
		end
	end)

	R.State.OnClientEvent:Connect(function(s)
		st = s
		if s.wear then
			local was = wear
			wear, presets = M.clean(s.wear), type(s.wear.presets) == "table" and s.wear.presets or {}
			if win.Visible then
				local changed = false
				for k, v in wear do if was[k] ~= v then changed = true end end
				if changed then redress() end
				refresh()
			end
		end
	end)
	plr:GetAttributeChangedSignal("TorchColor"):Connect(function() -- the first-person torch is rebuilt in the new flame colour
		if E.cave and E.cave.tvm then
			E.cave.tvm:Destroy()
			E.cave.tvm = nil
		end
	end)
	RunService.RenderStepped:Connect(function(dt)
		if not win.Visible or not figure or not basePivot then return end
		if not dragging then
			yaw += yawV
			yawV *= math.exp(-dt * 5) -- a flick keeps turning, then settles
		end
		local t = os.clock()
		figure:PivotTo(CFrame.new(0, math.sin(t * 1.8) * 0.03, 0) * CFrame.Angles(0, yaw + math.sin(t * 0.6) * 0.05, 0) * basePivot) -- breathing: a slow rise and a sway
		hintT.TextTransparency = dragging and 1 or 0.35
	end)
end

return M
