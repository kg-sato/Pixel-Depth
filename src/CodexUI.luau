-- CodexUI (ReplicatedStorage.Shared.CodexUI), started by PixelClient. Directive v10, "Ore & Pet Codex": a glass gallery of
-- every ore and every pet. One you have found is lit in its own colour with its name; the others are dark with a question
-- mark. Finding a quarter, half and all of them makes Epic and better eggs more likely (Config.CODEX; the egg odds panel
-- shows the real numbers). Open it with K or the CODEX button in the menu.
-- The server keeps what is found (saved: profile field `codex`) and sends it with the state; this module only shows it.
local UIS = game:GetService("UserInputService")
local M = {}

function M.start(E)
	local C, plr = E.C, E.plr
	if not C.CODEX then return end
	local MID = Vector2.new(0.5, 0.5)
	local DARK, WHITE, GOLD = Color3.fromRGB(36, 17, 56), Color3.new(1, 1, 1), Color3.fromRGB(255, 214, 107)
	local win = E.panel(E.gui, E.S(600, 420), E.S(640, 330), MID, "panel")
	E.fit(win, 600, 420)
	win.Name, win.Visible, win.ClipsDescendants = "Codex", false, true
	if E.addModal then E.addModal(win) end
	local title = E.text(win, "CODEX", UDim2.fromScale(0.4, 0.1), UDim2.fromScale(0.5, 0.08), MID, WHITE, 700, false)
	title.Font, title.ZIndex = E.HEAD or title.Font, 6
	local status = E.text(win, "", UDim2.fromScale(0.9, 0.055), UDim2.fromScale(0.5, 0.17), MID, GOLD, 700, false)
	status.Name, status.ZIndex = "Status", 6
	local plate = E.new("Frame", win, { Name = "StatusPlate", Size = UDim2.fromScale(0.66, 0.075), Position = UDim2.fromScale(0.5, 0.17), AnchorPoint = MID, BackgroundColor3 = Color3.fromRGB(22, 8, 30), BackgroundTransparency = 0.15, BorderSizePixel = 0, ZIndex = 5 }) -- a dark pill: the panel is glass now
	E.new("UICorner", plate, { CornerRadius = UDim.new(0.5, 0) })
	E.new("UIStroke", plate, { Color = Color3.fromRGB(155, 31, 232), Thickness = 1, Transparency = 0.3 })
	local close = E.closeButton(win, "CodexClose")
	local grid = E.new("Frame", win, { Name = "Grid", Size = UDim2.fromScale(0.92, 0.72), Position = UDim2.fromScale(0.5, 0.6), AnchorPoint = MID, BackgroundTransparency = 1, ZIndex = 5 })
	E.new("UIGridLayout", grid, { CellSize = UDim2.fromScale(0.1, 0.2), CellPadding = UDim2.fromScale(0.011, 0.03), SortOrder = Enum.SortOrder.LayoutOrder })
	local cells = {} -- { frame, mark, name, kind ("ore" or "pet"), key, color, label }
	local function cell(kind, key, color, label, order)
		local f = E.new("Frame", grid, { Name = key, LayoutOrder = order, BackgroundColor3 = DARK, BackgroundTransparency = 0.4, BorderSizePixel = 0, ZIndex = 5 })
		E.new("UICorner", f, { CornerRadius = UDim.new(0.18, 0) })
		E.new("UIStroke", f, { Color = Color3.fromRGB(155, 31, 232), Thickness = 2, Transparency = 0.3 })
		local mark = E.text(f, "?", UDim2.fromScale(0.6, 0.6), UDim2.fromScale(0.5, 0.42), MID, Color3.fromRGB(150, 130, 190), 700, false)
		mark.ZIndex = 6
		-- v10 (Gemini: "muddy opaque squares"): a found entry is a cut gem of its colour in a dark glass cell, not a flat tile
		local gem = E.new("Frame", f, { Name = "Gem", Size = UDim2.fromScale(0.4, 0.4), SizeConstraint = Enum.SizeConstraint.RelativeYY, Position = UDim2.fromScale(0.5, 0.4), AnchorPoint = MID, Rotation = 45, BackgroundColor3 = color, BorderSizePixel = 0, Visible = false, ZIndex = 6 })
		E.new("UICorner", gem, { CornerRadius = UDim.new(0.16, 0) })
		E.new("UIStroke", gem, { Color = Color3.new(1, 1, 1), Thickness = 1.5, Transparency = 0.35 })
		E.new("UIGradient", gem, { Rotation = 90, Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(150, 150, 170)) })
		local sh = E.new("Frame", f, { Name = "DomeShine", Size = UDim2.fromScale(0.8, 0.3), Position = UDim2.fromScale(0.5, 0.06), AnchorPoint = Vector2.new(0.5, 0), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 7, ClipsDescendants = true }) -- the jelly dome shine (directive v10 re-run)
		E.new("UICorner", sh, { CornerRadius = UDim.new(0.5, 0) })
		E.new("UIGradient", sh, { Rotation = 90, Transparency = NumberSequence.new(0.6, 1) })
		local name = E.text(f, "", UDim2.fromScale(0.94, 0.26), UDim2.fromScale(0.5, 0.84), MID, WHITE, 600, false)
		name.ZIndex = 6
		table.insert(cells, { f = f, mark = mark, name = name, kind = kind, key = key, color = color, label = label, gem = gem })
	end
	local n = 0
	for L, layer in C.LAYERS do
		for i, ore in layer[4] do
			n += 1
			cell("ore", L .. "." .. i, ore[2], string.upper(ore[1]), n)
		end
	end
	local pets = {}
	for name in C.PETS do table.insert(pets, name) end
	table.sort(pets)
	for _, name in pets do
		n += 1
		cell("pet", name, C.PETS[name][5], string.upper(name), n)
	end
	local found = { ore = {}, pet = {} }
	local paint
	for _, c in cells do -- point at a cell: its name on the status line
		c.f.Active = true
		c.f.MouseEnter:Connect(function() status.Text = c.got and c.label or (c.kind == "pet" and "A PET YOU HAVE NOT HATCHED YET" or "AN ORE YOU HAVE NOT BANKED YET") end)
		c.f.MouseLeave:Connect(function() paint() end)
	end
	paint = function()
		local have = 0
		for _, c in cells do
			local got = found[c.kind] and found[c.kind][c.key] == true
			if got then have += 1 end
			c.f.BackgroundColor3 = got and Color3.fromRGB(52, 26, 82) or DARK
			if got and c.kind == "ore" and not c.icon then -- a found ore is a live 3D voxel ore, not a flat diamond (Gemini v10n_r11: "flat 2D diamond vectors")
				c.icon = require(script.Parent:WaitForChild("OreIcon")).make(c.f, { Size = UDim2.fromScale(0.78, 0.78), Position = UDim2.fromScale(0.5, 0.42), AnchorPoint = MID, ZIndex = 6 })
			end
			if c.icon then c.icon.set(c.color) end
			c.gem.Visible = got and not c.icon
			c.mark.Visible = not got
			c.name.Text = "" -- names are read by pointing at a cell (they were tiny inside it)
			c.got = got
		end
		local luck = C.codexLuck(have)
		local nextAt
		for _, a in C.CODEX.at do
			if have / #cells < a and not nextAt then nextAt = math.ceil(a * #cells) end
		end
		status.Text = "FOUND " .. have .. " OF " .. #cells .. "    EGG LUCK +" .. math.floor(luck * 100 + 0.5) .. "%" .. (nextAt and ("    NEXT AT " .. nextAt) or "")
	end
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
	local btn = E.button(E.gui, "CODEX", E.S(76, 76), E.S(20, 400), nil, "lilac", "map", true)
	E.fit(btn, 1, 1)
	btn.Name = "CodexButton"
	btn.Activated:Connect(toggle)
	if E.addRow then E.addRow(btn) end
	UIS.InputBegan:Connect(function(input, typing)
		if not typing and input.KeyCode == Enum.KeyCode.K and not (E.isBusy and E.isBusy()) then toggle() end
	end)
end

return M
