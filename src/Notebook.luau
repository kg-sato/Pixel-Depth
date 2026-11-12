-- Notebook (ReplicatedStorage.Shared.Notebook), started by PixelClient. The miner's field notebook: a spiral-bound book that
-- opens over the game (key N, the NOTEBOOK slot of the utility wheel, or the ribbon of another page). Its first page is the
-- settings: sound volume, screen shake, key hints, darker nights. The right page lists the keys. Ribbons along the top jump
-- to the bag, the quests and the wardrobe through the same functions their own keys call.
-- Look: design board "Pixel Depth Notebook UI" (vault brief UI Rework Field Notebook (2026-11-12)): Overcooked's notebook,
-- Moonlighter's ribbon tabs, a Hi-Fi Rush header bar, Yooka-Laylee's paint and torn paper.
-- Client only. shortcut: the settings last for the session; saving them needs a new saved field (the owner decides).
local M = {}

function M.start(E)
	local UIS, SoundService = game:GetService("UserInputService"), game:GetService("SoundService")
	local new, S, text, plr, hook = E.new, E.S, E.text, E.plr, E.vmHook
	local INK, WHITE = E.INK, E.WHITE
	local PAPER, RULE, COVER = Color3.fromRGB(243, 230, 196), Color3.fromRGB(217, 199, 154), Color3.fromRGB(58, 42, 69)
	local MARI, TEAL, BERRY, BLUE = Color3.fromRGB(246, 185, 59), Color3.fromRGB(37, 181, 160), Color3.fromRGB(224, 72, 109), Color3.fromRGB(79, 127, 224)
	local MID, HEAD = Vector2.new(0.5, 0.5), Enum.Font.Bangers

	-- a Modal button frees the mouse in first person while the book is open; it is also the dark scrim
	local root = new("TextButton", E.gui, { Name = "Notebook", Text = "", AutoButtonColor = false, Modal = true, BackgroundColor3 = Color3.fromRGB(18, 12, 26), BackgroundTransparency = 0.3, BorderSizePixel = 0, Size = UDim2.new(1, 0, 1, 80), Position = UDim2.fromOffset(0, -80), ZIndex = 30, Visible = false })
	local book = new("Frame", root, { Name = "Book", Size = S(900, 452), Position = UDim2.new(0.5, 0, 0.5, 52), AnchorPoint = MID, BackgroundColor3 = COVER, BorderSizePixel = 0, Rotation = -1, ZIndex = 31, Active = true }) -- Active: a click on the book must not reach the scrim
	E.fit(book, 900, 452)
	new("UICorner", book, { CornerRadius = UDim.new(0.03, 0) })
	new("UIStroke", book, { Color = Color3.fromRGB(30, 20, 38), Thickness = 3 })
	local pop = new("UIScale", book, { Scale = 1 })
	local function page(x)
		local p = new("Frame", book, { Size = UDim2.fromScale(0.474, 0.94), Position = UDim2.fromScale(x, 0.03), BackgroundColor3 = PAPER, BorderSizePixel = 0, ZIndex = 32 })
		new("UICorner", p, { CornerRadius = UDim.new(0.02, 0) })
		for i = 1, 11 do new("Frame", p, { Size = UDim2.new(1, 0, 0, 1), Position = UDim2.fromScale(0, 0.06 + i * 0.08), BackgroundColor3 = RULE, BorderSizePixel = 0, ZIndex = 32 }) end
		return p
	end
	local left, right = page(0.014), page(0.512)
	for i = 0, 10 do -- the spiral binding: wire rings over the fold
		local ring = new("Frame", book, { Size = UDim2.fromScale(0.05, 0.022), Position = UDim2.fromScale(0.5, 0.09 + i * 0.082), AnchorPoint = MID, BackgroundColor3 = Color3.fromRGB(190, 184, 198), BorderSizePixel = 0, ZIndex = 34 })
		new("UICorner", ring, { CornerRadius = UDim.new(0.5, 0) })
		new("UIStroke", ring, { Color = Color3.fromRGB(96, 90, 106), Thickness = 1.5 })
	end

	-- ribbons hanging over the top edge: the other pages of the book
	local function shut() end
	local RIBBONS = {
		{ icon = E.ICON.bag, color = TEAL, run = function() if hook.bag then hook.bag() end end },
		{ icon = E.ICON.star, color = BERRY, run = function() if hook.quests then hook.quests() end end },
		{ icon = E.ICON.crew, color = BLUE, run = function() if hook.wardrobe then hook.wardrobe() end end },
		{ icon = E.ICON.hammer, color = MARI, here = true },
	}
	for i, r in RIBBONS do
		local b = new("TextButton", book, { Name = "Ribbon" .. i, Text = "", AutoButtonColor = false, Size = UDim2.fromScale(0.062, r.here and 0.24 or 0.18), Position = UDim2.fromScale(0.2 + (i - 1) * 0.07, -0.1), BackgroundColor3 = r.color, BorderSizePixel = 0, ZIndex = r.here and 35 or 33 })
		new("UIStroke", b, { Color = r.color:Lerp(Color3.new(0, 0, 0), 0.4), Thickness = 2.5, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
		local ic = new("ImageLabel", b, { Image = r.icon, BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit, Size = UDim2.fromScale(0.8, 0.5), Position = UDim2.fromScale(0.5, r.here and 0.55 or 0.5), AnchorPoint = MID, ZIndex = 36 })
		new("UIAspectRatioConstraint", ic, { AspectRatio = 1 })
		if r.run then b.Activated:Connect(function()
			shut()
			r.run()
		end) end
	end

	-- left page: the settings under a paint splat and a comic header bar
	local splat = new("Frame", left, { Size = UDim2.fromScale(0.74, 0.17), Position = UDim2.fromScale(0.42, 0.135), AnchorPoint = MID, BackgroundColor3 = TEAL, BorderSizePixel = 0, Rotation = -4, ZIndex = 32 })
	new("UICorner", splat, { CornerRadius = UDim.new(0.5, 0) })
	local head = new("Frame", left, { Size = UDim2.fromScale(0.62, 0.17), Position = UDim2.fromScale(0.36, 0.13), AnchorPoint = MID, BackgroundTransparency = 1, Rotation = -3, ZIndex = 33 })
	new("ImageLabel", head, { Image = "rbxassetid://116014459402362", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ScaleType = Enum.ScaleType.Stretch, ZIndex = 33 }) -- the kit's comic header (ribbonLilac)
	local ht = text(head, "SETTINGS", UDim2.fromScale(0.72, 0.56), UDim2.fromScale(0.48, 0.44), MID, INK, 700, false)
	ht.Font, ht.ZIndex = HEAD, 34

	local rows, nRow = {}, 0
	local function row(label)
		nRow += 1
		local f = new("Frame", left, { Name = label, Size = UDim2.fromScale(0.86, 0.13), Position = UDim2.fromScale(0.07, 0.15 + nRow * 0.145), BackgroundTransparency = 1, ZIndex = 33 })
		local t = text(f, label, UDim2.fromScale(0.5, 0.7), UDim2.fromScale(0, 0.5), Vector2.new(0, 0.5), INK, nil, false)
		t.TextXAlignment, t.ZIndex = Enum.TextXAlignment.Left, 34
		return f
	end
	local function block(parent, label, size, pos, color) -- a small voxel block button
		local b = new("TextButton", parent, { Text = "", AutoButtonColor = false, Size = size, Position = pos, AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = color, BorderSizePixel = 0, ZIndex = 34 })
		new("UICorner", b, { CornerRadius = UDim.new(0.14, 0) })
		new("UIStroke", b, { Color = INK, Thickness = 3, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
		local t = text(b, label, UDim2.fromScale(0.8, 0.8), UDim2.fromScale(0.5, 0.5), MID, INK, 700, false)
		t.Font, t.ZIndex = HEAD, 35
		b.MouseButton1Down:Connect(function() pcall(E.sfx, "tick", 1.1) end)
		return b, t
	end

	-- 1. sound: ten pips between a minus and a plus block
	local set = { sound = 10, shake = true, hints = true, dark = false }
	local function group() return SoundService:FindFirstChild("PixelMaster") end
	local sRow = row("Sound")
	local pips = {}
	for i = 1, 10 do
		pips[i] = new("Frame", sRow, { Size = UDim2.fromScale(0.026, 0.5), Position = UDim2.fromScale(0.45 + i * 0.036, 0.5), AnchorPoint = MID, BorderSizePixel = 0, ZIndex = 34 })
		new("UICorner", pips[i], { CornerRadius = UDim.new(0.3, 0) })
	end
	local minus = block(sRow, "-", UDim2.fromScale(0.1, 0.84), UDim2.fromScale(0.41, 0.5), PAPER)
	local plus = block(sRow, "+", UDim2.fromScale(0.1, 0.84), UDim2.fromScale(0.93, 0.5), MARI)
	local function showSound()
		for i, p in pips do p.BackgroundColor3 = i <= set.sound and TEAL or Color3.fromRGB(190, 174, 132) end
		local g = group()
		if g then g.Volume = set.sound / 10 end
	end
	minus.Activated:Connect(function() set.sound = math.max(0, set.sound - 1); showSound() end)
	plus.Activated:Connect(function() set.sound = math.min(10, set.sound + 1); showSound() end)

	-- 2 to 4. tick boxes
	local function tick(label, key, apply)
		local f = row(label)
		local b, t = block(f, "", UDim2.fromScale(0.12, 0.9), UDim2.fromScale(0.92, 0.5), WHITE)
		t.TextColor3 = BERRY
		local function show()
			t.Text = set[key] and "X" or ""
			apply(set[key])
		end
		b.Activated:Connect(function() set[key] = not set[key]; show() end)
		rows[key] = show
	end
	tick("Screen shake", "shake", function(on) plr:SetAttribute("NoShake", (not on) or nil) end)
	tick("Key hints", "hints", function(on)
		for _, d in E.gui:GetDescendants() do
			if d.Name == "KeyHint" and d:IsA("GuiObject") then d.Visible = on end
		end
	end)
	tick("Darker nights", "dark", function(on) plr:SetAttribute("DevLowLight", on or nil) end) -- the light governor's switch
	local note = text(left, "Turn on if the town looks like day.", UDim2.fromScale(0.86, 0.075), UDim2.fromScale(0.07, 0.885), nil, Color3.fromRGB(110, 92, 70), nil, false)
	note.TextXAlignment, note.TextWrapped, note.ZIndex = Enum.TextXAlignment.Left, true, 34

	-- right page: the keys on a torn scrap, over a pink splat
	local splat2 = new("Frame", right, { Size = UDim2.fromScale(0.5, 0.2), Position = UDim2.fromScale(0.3, 0.14), AnchorPoint = MID, BackgroundColor3 = BERRY, BorderSizePixel = 0, Rotation = 5, ZIndex = 32 })
	new("UICorner", splat2, { CornerRadius = UDim.new(0.5, 0) })
	local kh = new("Frame", right, { Size = UDim2.fromScale(0.3, 0.1), Position = UDim2.fromScale(0.07, 0.07), BackgroundColor3 = INK, BorderSizePixel = 0, Rotation = -2, ZIndex = 33 })
	local kt = text(kh, "KEYS", UDim2.fromScale(0.8, 0.74), UDim2.fromScale(0.5, 0.5), MID, MARI, 700, false)
	kt.Font, kt.ZIndex = HEAD, 34
	local KEYS = { { "TAB", "Tool wheel" }, { "N", "This notebook" }, { "Q", "Minecart" }, { "B", "Bag" }, { "J", "Quests" }, { "V", "Outfits" }, { "T", "Sonar (caves)" }, { "R", "Flare (caves)" }, { "Z", "Ping friends" } }
	for i, k in KEYS do
		local f = new("Frame", right, { Size = UDim2.fromScale(0.86, 0.072), Position = UDim2.fromScale(0.07, 0.125 + i * 0.079), BackgroundTransparency = 1, ZIndex = 33 })
		local cap = new("Frame", f, { Size = UDim2.fromScale(0.17, 0.92), Position = UDim2.fromScale(0, 0.5), AnchorPoint = Vector2.new(0, 0.5), BackgroundColor3 = MARI, BorderSizePixel = 0, ZIndex = 33 })
		new("UICorner", cap, { CornerRadius = UDim.new(0.16, 0) })
		new("UIStroke", cap, { Color = INK, Thickness = 2 })
		local ct = text(cap, k[1], UDim2.fromScale(0.84, 0.76), UDim2.fromScale(0.5, 0.5), MID, INK, 700, false)
		ct.Font, ct.ZIndex = HEAD, 34
		local d = text(f, k[2], UDim2.fromScale(0.76, 0.9), UDim2.fromScale(0.22, 0.5), Vector2.new(0, 0.5), INK, nil, false)
		d.TextXAlignment, d.ZIndex = Enum.TextXAlignment.Left, 34
	end

	local done = block(book, "DONE", UDim2.fromScale(0.13, 0.11), UDim2.fromScale(0.9, 1.0), TEAL)
	done.ZIndex = 36

	local function open()
		if root.Visible or E.isBusy() then return end
		root.Visible = true
		pcall(E.sfx, "open")
		pop.Scale = 0.92
		E.tween(pop, 0.22, { Scale = 1 }, Enum.EasingStyle.Back)
	end
	shut = function()
		if not root.Visible then return end
		pcall(E.sfx, "close")
		root.Visible = false
	end
	done.Activated:Connect(shut)
	root.Activated:Connect(shut) -- a click on the dark scrim closes the book
	hook.notebook = function() if root.Visible then shut() else open() end end
	UIS.InputBegan:Connect(function(io, gp)
		if gp and not root.Visible then return end
		if io.KeyCode == Enum.KeyCode.N then hook.notebook() end
	end)
	if E.addModal then E.addModal(root) end
	showSound()
	for _, show in rows do show() end
end

return M
