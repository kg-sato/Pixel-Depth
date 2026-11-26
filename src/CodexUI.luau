-- CodexUI (ReplicatedStorage.Shared.CodexUI), started by PixelClient. Directive v10, "Ore & Pet Codex": a glass gallery of
-- every ore and every pet. One you have found is lit in its own colour with its name; the others are dark with a question
-- mark. Finding a quarter, half and all of them makes Epic and better eggs more likely (Config.CODEX; the egg odds panel
-- shows the real numbers). Open it with K or the CODEX button in the menu.
-- Directive v13 (Gemini 4.0, "cramped 10-column grid, names hidden"): a field archive. A scrolling five-column gallery on a
-- dark rune-slate sheet, every found entry with its name under its live 3D model, and an inspector card on the right with a
-- large turning model, the name, a rarity pill, where it is found, its badge, and the collection meter with its luck steps.
-- Pointing at a cell (mouse) or tapping it (touch) shows it in the inspector.
-- The server keeps what is found (saved: profile field `codex`) and sends it with the state; this module only shows it.
local UIS = game:GetService("UserInputService")
local M = {}

function M.start(E)
	local C, plr = E.C, E.plr
	if not C.CODEX then return end
	local MID = Vector2.new(0.5, 0.5)
	local DARK, SLATE, WHITE, GOLD = Color3.fromRGB(36, 17, 56), Color3.fromRGB(20, 12, 34), Color3.new(1, 1, 1), Color3.fromRGB(255, 214, 107)
	local VIOLET, CYAN, PALE = Color3.fromRGB(155, 31, 232), Color3.fromRGB(110, 225, 255), Color3.fromRGB(200, 186, 232)
	local win = E.panel(E.gui, E.S(860, 480), E.S(640, 300), MID, "panel")
	E.fit(win, 860, 480)
	win.Name, win.Visible, win.ClipsDescendants = "Codex", false, true
	if E.addModal then E.addModal(win) end
	local title = E.text(win, "CODEX", UDim2.fromScale(0.3, 0.085), UDim2.fromScale(0.5, 0.075), MID, WHITE, 700, false)
	title.Font, title.ZIndex = E.HEAD or title.Font, 6
	local close = E.closeButton(win, "CodexClose")
	do -- directive v13 round 2 (Gemini: the bright town bled through the glass): an opaque dark core behind the content
		local backing = E.new("Frame", win, { Name = "Backing", Size = UDim2.fromScale(0.97, 0.94), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = MID, BackgroundColor3 = Color3.fromRGB(14, 8, 28), BackgroundTransparency = 0.12, BorderSizePixel = 0, ZIndex = 2 })
		E.new("UICorner", backing, { CornerRadius = UDim.new(0.04, 0) })
	end

	local function sheet(name, pos, size) -- a dark rune-slate sheet with a violet rim and a faint top shine
		local f = E.new("Frame", win, { Name = name, Position = pos, Size = size, BackgroundColor3 = SLATE, BackgroundTransparency = 0.12, BorderSizePixel = 0, ZIndex = 5 })
		E.new("UICorner", f, { CornerRadius = UDim.new(0.035, 0) })
		E.new("UIStroke", f, { Color = VIOLET, Thickness = 1.5, Transparency = 0.35 })
		E.new("UIGradient", f, { Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(150, 140, 190)) })
		return f
	end
	-- ALL / ORES / PETS: glass tabs with their found counts, over the gallery
	local tab, tabs = "all", {}
	for i, t in { { "all", "ALL" }, { "ore", "ORES" }, { "pet", "PETS" } } do
		local b = E.new("TextButton", win, { Name = "Tab_" .. t[1], Size = UDim2.fromScale(0.17, 0.065), Position = UDim2.fromScale(0.035 + (i - 1) * 0.19, 0.155), AnchorPoint = Vector2.new(0, 0),
			BackgroundColor3 = DARK, BackgroundTransparency = 0.2, Text = t[2], Font = E.HEAD or Enum.Font.FredokaOne, TextScaled = true, TextColor3 = WHITE, AutoButtonColor = false, ZIndex = 6 })
		E.new("UICorner", b, { CornerRadius = UDim.new(0.5, 0) })
		E.new("UIStroke", b, { Color = VIOLET, Thickness = 1.5, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
		E.new("UIPadding", b, { PaddingTop = UDim.new(0.2, 0), PaddingBottom = UDim.new(0.2, 0), PaddingLeft = UDim.new(0.06, 0), PaddingRight = UDim.new(0.06, 0) })
		tabs[t[1]] = { b = b, word = t[2] }
	end

	-- the gallery: five columns, scrolling
	local gallery = sheet("Gallery", UDim2.fromScale(0.035, 0.24), UDim2.fromScale(0.59, 0.715))
	local grid = E.new("ScrollingFrame", gallery, { Name = "Grid", Size = UDim2.fromScale(0.96, 0.94), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = MID, BackgroundTransparency = 1, BorderSizePixel = 0,
		CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y, ScrollBarThickness = 6,
		ScrollBarImageColor3 = Color3.fromRGB(196, 160, 255), ScrollBarImageTransparency = 0.2, ElasticBehavior = Enum.ElasticBehavior.Never, ZIndex = 5 })
	E.new("UIPadding", grid, { PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 8), PaddingLeft = UDim.new(0.01, 0), PaddingRight = UDim.new(0.03, 0) })
	local layout = E.new("UIGridLayout", grid, { CellSize = UDim2.fromScale(0.186, 1), CellPadding = UDim2.new(0.015, 0, 0, 7), SortOrder = Enum.SortOrder.LayoutOrder })
	E.new("UIAspectRatioConstraint", layout, { AspectRatio = 0.86 })

	-- the inspector card
	local insp = sheet("Inspector", UDim2.fromScale(0.645, 0.155), UDim2.fromScale(0.32, 0.8))
	local stage = E.new("Frame", insp, { Name = "Stage", Size = UDim2.fromScale(0.86, 0.44), Position = UDim2.fromScale(0.5, 0.26), AnchorPoint = MID, BackgroundColor3 = Color3.fromRGB(34, 20, 58), BackgroundTransparency = 0.25, BorderSizePixel = 0, ZIndex = 6 })
	E.new("UICorner", stage, { CornerRadius = UDim.new(0.08, 0) })
	local stageGlow = E.new("UIStroke", stage, { Color = VIOLET, Thickness = 2, Transparency = 0.25 })
	E.new("UIGradient", stage, { Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(120, 110, 170), Color3.fromRGB(255, 255, 255)) })
	local plinth = E.new("Frame", stage, { Name = "Plinth", Size = UDim2.fromScale(0.6, 0.08), Position = UDim2.fromScale(0.5, 0.88), AnchorPoint = MID, BackgroundColor3 = Color3.fromRGB(120, 100, 180), BackgroundTransparency = 0.35, BorderSizePixel = 0, ZIndex = 6 })
	E.new("UICorner", plinth, { CornerRadius = UDim.new(0.5, 0) })
	local unknown = E.text(stage, "?", UDim2.fromScale(0.5, 0.6), UDim2.fromScale(0.5, 0.46), MID, Color3.fromRGB(120, 100, 170), 700, false)
	unknown.ZIndex = 7
	local iName = E.text(insp, "", UDim2.fromScale(0.9, 0.075), UDim2.fromScale(0.5, 0.535), MID, WHITE, 700, false)
	iName.Name, iName.Font, iName.ZIndex = "Name", E.HEAD or iName.Font, 7
	local rarity = E.new("Frame", insp, { Name = "Rarity", Size = UDim2.fromScale(0.46, 0.06), Position = UDim2.fromScale(0.5, 0.615), AnchorPoint = MID, BackgroundColor3 = VIOLET, BackgroundTransparency = 0.1, BorderSizePixel = 0, ZIndex = 7 })
	E.new("UICorner", rarity, { CornerRadius = UDim.new(0.5, 0) })
	local rarityT = E.text(rarity, "", UDim2.fromScale(0.86, 0.7), UDim2.fromScale(0.5, 0.5), MID, WHITE, 700, false)
	rarityT.ZIndex = 8
	local where = E.text(insp, "", UDim2.fromScale(0.88, 0.05), UDim2.fromScale(0.5, 0.69), MID, PALE, 600, false)
	where.Name, where.ZIndex = "Where", 7
	local badge = E.new("Frame", insp, { Name = "Badge", Size = UDim2.fromScale(0.62, 0.056), Position = UDim2.fromScale(0.5, 0.76), AnchorPoint = MID, BackgroundColor3 = Color3.fromRGB(46, 30, 20), BackgroundTransparency = 0.15, BorderSizePixel = 0, ZIndex = 7 })
	E.new("UICorner", badge, { CornerRadius = UDim.new(0.5, 0) })
	local badgeStroke = E.new("UIStroke", badge, { Color = GOLD, Thickness = 1.2, Transparency = 0.3 })
	local badgeT = E.text(badge, "", UDim2.fromScale(0.88, 0.64), UDim2.fromScale(0.5, 0.5), MID, GOLD, 700, false)
	badgeT.ZIndex = 8
	-- the collection meter: found / all, with gold notches where the egg luck steps up (Config.CODEX.at)
	local status = E.text(insp, "", UDim2.fromScale(0.9, 0.044), UDim2.fromScale(0.5, 0.80), MID, GOLD, 700, false) -- directive v14: was 0.845, on top of the meter
	status.Name, status.ZIndex = "Status", 7
	local meter = E.new("Frame", insp, { Name = "Meter", Size = UDim2.fromScale(0.84, 0.03), Position = UDim2.fromScale(0.5, 0.90), AnchorPoint = MID, BackgroundColor3 = Color3.fromRGB(14, 8, 26), BorderSizePixel = 0, ZIndex = 7 })
	E.new("UICorner", meter, { CornerRadius = UDim.new(0.5, 0) })
	E.new("UIStroke", meter, { Color = VIOLET, Thickness = 1, Transparency = 0.3 })
	local fill = E.new("Frame", meter, { Name = "Fill", Size = UDim2.fromScale(0, 1), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 8 })
	E.new("UICorner", fill, { CornerRadius = UDim.new(0.5, 0) })
	E.new("UIGradient", fill, { Color = ColorSequence.new(CYAN, Color3.fromRGB(255, 120, 220)) })
	for _, a in C.CODEX.at do
		if a < 1 then
			E.new("Frame", meter, { Name = "Notch", Size = UDim2.new(0, 3, 1.8, 0), Position = UDim2.fromScale(a, 0.5), AnchorPoint = MID, BackgroundColor3 = GOLD, BorderSizePixel = 0, ZIndex = 9 })
		end
	end

	local RARE = { Common = Color3.fromRGB(120, 130, 150), Rare = Color3.fromRGB(70, 146, 255), Epic = Color3.fromRGB(176, 80, 240), Legendary = Color3.fromRGB(255, 170, 40), Mythic = Color3.fromRGB(255, 70, 140), Secret = Color3.fromRGB(30, 230, 200) }
	local ORE_RARITY = { "COMMON", "UNCOMMON", "RARE" }
	local ORE_RARE_C = { Color3.fromRGB(120, 130, 150), Color3.fromRGB(70, 190, 140), Color3.fromRGB(70, 146, 255) }

	local cells = {} -- { f, mark, name, kind ("ore" or "pet"), key, color, label, gem, strip }
	local function cell(kind, key, color, label, order, tint)
		local f = E.new("TextButton", grid, { Name = key, Text = "", AutoButtonColor = false, LayoutOrder = order, BackgroundColor3 = DARK, BackgroundTransparency = 0.25, BorderSizePixel = 0, ZIndex = 5 })
		E.new("UICorner", f, { CornerRadius = UDim.new(0.12, 0) })
		E.new("UIStroke", f, { Color = VIOLET, Thickness = 1.5, Transparency = 0.4, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
		local strip = E.new("Frame", f, { Name = "Strip", Size = UDim2.fromScale(0.5, 0.035), Position = UDim2.fromScale(0.5, 0.035), AnchorPoint = Vector2.new(0.5, 0), BackgroundColor3 = tint, BackgroundTransparency = 0.6, BorderSizePixel = 0, ZIndex = 6 })
		E.new("UICorner", strip, { CornerRadius = UDim.new(0.5, 0) })
		local mark = E.text(f, "?", UDim2.fromScale(0.5, 0.42), UDim2.fromScale(0.5, 0.4), MID, Color3.fromRGB(110, 92, 160), 700, false)
		mark.ZIndex = 6
		local gem = E.new("Frame", f, { Name = "Gem", Size = UDim2.fromScale(0.36, 0.36), SizeConstraint = Enum.SizeConstraint.RelativeXX, Position = UDim2.fromScale(0.5, 0.4), AnchorPoint = MID, Rotation = 45, BackgroundColor3 = color, BorderSizePixel = 0, Visible = false, ZIndex = 6 })
		E.new("UICorner", gem, { CornerRadius = UDim.new(0.16, 0) })
		local name = E.text(f, "???", UDim2.fromScale(0.94, 0.22), UDim2.fromScale(0.5, 0.86), MID, PALE, 600, false)
		name.Name, name.ZIndex = "Label", 7
		name.TextScaled, name.TextWrapped = false, true -- round 2 (Gemini: long names shrank to 8 px): one size for every label, long ones wrap
		name.TextStrokeColor3, name.TextStrokeTransparency = Color3.fromRGB(14, 8, 26), 0.35 -- v16.1 (audit 4:21): a dark edge so the small names read crisp on the glass
		table.insert(cells, { f = f, mark = mark, name = name, kind = kind, key = key, color = color, label = label, gem = gem, strip = strip, tint = tint })
	end
	local n = 0
	for L, layer in C.LAYERS do
		for i, ore in layer[4] do
			n += 1
			cell("ore", L .. "." .. i, ore[2], string.upper(ore[1]), n, ORE_RARE_C[i] or ORE_RARE_C[1])
		end
	end
	local pets = {}
	for name in C.PETS do table.insert(pets, name) end
	table.sort(pets, function(a, b) -- by rarity, then name
		local ra, rb = C.PETS[a][3] or 0, C.PETS[b][3] or 0
		if ra ~= rb then return ra < rb end
		return a < b
	end)
	for _, name in pets do
		n += 1
		cell("pet", name, C.PETS[name][5], string.upper(name), n, RARE[C.PETS[name][1]] or VIOLET)
	end
	local found = { ore = {}, pet = {} }
	local paint, show
	local selected
	local view -- the inspector's live model: { kind, key, card or icon }

	local function oreInfo(c)
		local L, i = c.key:match("^(%d+)%.(%d+)$")
		local layer = C.LAYERS[tonumber(L)]
		return layer, tonumber(i)
	end
	local function clearView()
		if view then
			if view.frame then view.frame:Destroy() end
			for _, d in stage:GetChildren() do
				if d.Name == "Card3D" or d.Name == "CardGlow" or d.Name == "CardShine" then d:Destroy() end
			end
			view = nil
		end
	end
	show = function(c)
		selected = c
		for _, o in cells do
			local st = o.f:FindFirstChildOfClass("UIStroke")
			if st then st.Thickness = o == c and 3 or (o.got and 2 or 1.5) end
		end
		if not c then return end
		local got = c.got
		unknown.Visible = not got
		stageGlow.Color = got and c.color:Lerp(WHITE, 0.3) or VIOLET
		plinth.BackgroundColor3 = got and c.color:Lerp(WHITE, 0.4) or Color3.fromRGB(120, 100, 180)
		if not view or view.key ~= c.key or view.got ~= got then
			clearView()
			if got and c.kind == "ore" then
				local icon = require(script.Parent:WaitForChild("OreIcon")).make(stage, { Size = UDim2.fromScale(0.9, 0.9), Position = UDim2.fromScale(0.5, 0.46), AnchorPoint = MID, ZIndex = 8 })
				icon.set(c.color)
				view = { key = c.key, got = got, frame = icon.frame or stage:FindFirstChild("OreIcon") }
			elseif got and c.kind == "pet" then
				local PV = require(script.Parent:WaitForChild("PetVoxels"))
				local m = PV.build(c.key)
				if m then
					local card = require(script.Parent:WaitForChild("ModelCard")).attach(stage, stage, { z = 8, animate = PV.animate })
					card.set(m, c.color)
				end
				view = { key = c.key, got = got }
			else
				view = { key = c.key, got = got }
			end
		end
		iName.Text = got and c.label or "UNDISCOVERED"
		if c.kind == "ore" then
			local layer, i = oreInfo(c)
			rarityT.Text = got and (ORE_RARITY[i] or "ORE") or "ORE"
			rarity.BackgroundColor3 = got and (ORE_RARE_C[i] or VIOLET) or DARK
			where.Text = got and ("FOUND IN  " .. (layer and string.upper(layer[2]) or "THE CAVES")) or "BANK IT TO LEARN MORE"
			badgeT.Text = got and ("GILDED VARIANT  " .. string.format("%.1f", (C.GILDED_CHANCE or 0.012) * 100) .. "%") or "MUTATIONS HIDDEN"
		else
			local p = C.PETS[c.key]
			rarityT.Text = p and string.upper(p[1]) or "PET"
			rarity.BackgroundColor3 = got and (p and RARE[p[1]] or VIOLET) or DARK
			where.Text = got and ("JOB  " .. (p and string.upper(p[2]) or "")) or "HATCH IT TO LEARN MORE"
			badgeT.Text = got and "HATCHED  \u{2713}" or "NOT HATCHED YET"
		end
		badgeStroke.Transparency = got and 0.3 or 0.8
		badgeT.TextTransparency = got and 0 or 0.4
	end
	for _, c in cells do
		c.f.MouseEnter:Connect(function() show(c) end)
		c.f.Activated:Connect(function() E.sfx("click", 1.2) show(c) end)
	end
	paint = function()
		local have = 0
		for _, c in cells do
			local got = found[c.kind] and found[c.kind][c.key] == true
			if got then have += 1 end
			c.f.BackgroundColor3 = got and c.color:Lerp(DARK, 0.62) or DARK
			c.f.BackgroundTransparency = got and 0.1 or 0.35
			if got and c.kind == "ore" and not c.icon then -- a found ore is a live 3D voxel ore
				c.icon = require(script.Parent:WaitForChild("OreIcon")).make(c.f, { Size = UDim2.fromScale(0.72, 0.62), Position = UDim2.fromScale(0.5, 0.42), AnchorPoint = MID, ZIndex = 6 })
			end
			if c.icon then c.icon.set(c.color) end
			if got and c.kind == "pet" and not c.card then -- a hatched pet stands in its cell as its live voxel model
				local PV = require(script.Parent:WaitForChild("PetVoxels"))
				local m = PV.build(c.key)
				if m then
					local holder = E.new("Frame", c.f, { Name = "PetStage", Size = UDim2.fromScale(0.86, 0.66), Position = UDim2.fromScale(0.5, 0.42), AnchorPoint = MID, BackgroundTransparency = 1, ZIndex = 6 })
					c.card = require(script.Parent:WaitForChild("ModelCard")).attach(holder, c.f, { z = 6, animate = PV.animate })
					c.card.set(m, c.color)
				end
			end
			c.gem.Visible = got and not c.icon and not c.card
			c.mark.Visible = not got
			c.strip.BackgroundTransparency = got and 0.05 or 0.6
			local st = c.f:FindFirstChildOfClass("UIStroke")
			if st then st.Color, st.Transparency = got and c.color:Lerp(WHITE, 0.3) or VIOLET, got and 0.1 or 0.45 end
			c.name.Text = got and c.label or "???"
			c.name.TextColor3 = got and WHITE or Color3.fromRGB(150, 136, 192) -- v16.1: the ??? brighter too
			c.got = got
		end
		local px = math.clamp(math.floor((cells[1] and cells[1].f.AbsoluteSize.Y or 90) * 0.125), 11, 17) -- v16.1 (audit 4:21): was 0.105 and 9 px, micro-text
		for _, c in cells do c.name.TextSize = px end
		local per = { all = { 0, 0 }, ore = { 0, 0 }, pet = { 0, 0 } }
		for _, c in cells do
			c.f.Visible = tab == "all" or c.kind == tab
			for _, k in { "all", c.kind } do per[k][2] += 1 if c.got then per[k][1] += 1 end end
		end
		for k, t in tabs do
			t.b.Text = t.word .. "  " .. per[k][1] .. "/" .. per[k][2]
			t.b.BackgroundColor3 = k == tab and VIOLET or DARK
		end
		local luck = C.codexLuck(have)
		local nextAt
		for _, a in C.CODEX.at do
			if have / #cells < a and not nextAt then nextAt = math.ceil(a * #cells) end
		end
		status.Text = "FOUND " .. have .. "/" .. #cells .. "  \u{00B7}  EGG LUCK +" .. math.floor(luck * 100 + 0.5) .. "%" .. (nextAt and ("  \u{00B7}  NEXT " .. nextAt) or "")
		fill.Size = UDim2.fromScale(math.clamp(have / #cells, 0, 1), 1)
		if not selected or not selected.f.Visible then -- the inspector starts on the first found entry of this tab (or the first one)
			local first
			for _, c in cells do
				if c.f.Visible and (c.got or not first) then
					if c.got then first = c break end
					first = first or c
				end
			end
			show(first)
		else
			show(selected)
		end
	end
	for k, t in tabs do t.b.Activated:Connect(function() tab = k selected = nil E.sfx("click", 1.1) paint() grid.CanvasPosition = Vector2.zero end) end
	E.R.State.OnClientEvent:Connect(function(st)
		if st and type(st.codex) == "table" then
			found = { ore = st.codex.ore or {}, pet = st.codex.pet or {} }
			paint()
		end
	end)
	paint()
	local function toggle()
		if win.Visible then E.closePanel(win) else E.openPanel(win) task.defer(paint) end -- paint again once shown: the 3D ores only turn while their cell is on screen
	end
	close.Activated:Connect(function() E.closePanel(win) end)
	local btn = E.button(E.gui, "CODEX", E.S(76, 76), E.S(20, 400), nil, "lilac", "book", true)
	E.fit(btn, 1, 1)
	btn.Name = "CodexButton"
	btn.Activated:Connect(toggle)
	if E.addRow then E.addRow(btn) end
	UIS.InputBegan:Connect(function(input, typing)
		if not typing and input.KeyCode == Enum.KeyCode.K and not (E.isBusy and E.isBusy()) then toggle() end
	end)
end

return M
