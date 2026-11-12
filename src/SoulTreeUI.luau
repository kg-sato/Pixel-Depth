-- SoulTreeUI (ReplicatedStorage.Shared.SoulTreeUI), started by PixelClient. The Soul Tree panel at Camp 1's campfire
-- (prompt attribute SoulTree): the Gloom Shards you hold and three nodes on a bough, each with its ranks, what the next
-- rank does and what it costs. Display and requests only: ServerScriptService.SoulTree counts shards and checks every
-- buy. Does nothing while C.SOUL_TREE.on is false (the feature is behind the flag because it adds a saved field).
local M = {}

function M.start(E)
	local C, R, plr, gui, new, S, fit, text, panel, button = E.C, E.R, E.plr, E.gui, E.new, E.S, E.fit, E.text, E.panel, E.button
	local T = C.SOUL_TREE
	if not (T and T.on) then return end
	local SoulR = R:WaitForChild("Soul", 20)
	if not SoulR then return end
	local INK, WHITE, MID = E.INK, E.WHITE, Vector2.new(0.5, 0.5)
	local MUTED, SHARD, BARK = Color3.fromRGB(107, 90, 128), Color3.fromRGB(150, 110, 230), Color3.fromRGB(150, 104, 78)
	local LOOK = { -- per node: tint, icon
		hide = { E.MINT, C.HUD_ICON.heart }, flare = { E.PINK, C.HUD_ICON.flare }, shield = { E.BUTTER, E.ICON.star },
	}
	local soul = { shards = 0, nodes = {} }

	local win = panel(gui, S(760, 430), S(640, 300), MID, "panel")
	fit(win, 760, 430)
	win.Name, win.Visible = "SoulTree", false
	if E.addModal then E.addModal(win) end
	E.ribbonTitle(win, "SOUL TREE", "ribbonLilac", 0.4)
	local close = E.closeButton(win, "SoulClose")

	local function shardGem(parent, k, pos, z)
		local g = new("Frame", parent, { Size = UDim2.fromScale(k, k), SizeConstraint = Enum.SizeConstraint.RelativeYY, Position = pos, AnchorPoint = MID, Rotation = 45, BackgroundColor3 = SHARD, BorderSizePixel = 0, ZIndex = z })
		new("UICorner", g, { CornerRadius = UDim.new(0.22, 0) })
		new("UIStroke", g, { Color = INK, Thickness = 2 })
		new("UIGradient", g, { Rotation = 45, Color = ColorSequence.new(Color3.fromRGB(226, 208, 255), SHARD) })
		return g
	end
	local pill = panel(win, UDim2.fromScale(0.2, 0.1), UDim2.fromScale(0.06, 0.12), nil, "pillLilac")
	pill.ZIndex = 6
	shardGem(pill, 0.46, UDim2.fromScale(0.2, 0.5), 7)
	local count = text(pill, "0", UDim2.fromScale(0.56, 0.6), UDim2.fromScale(0.64, 0.5), MID, INK, 700, false)
	count.ZIndex = 7
	local note = text(win, "Flatten gloomlings with a flare to gather Gloom Shards.", UDim2.fromScale(0.58, 0.05), UDim2.fromScale(0.6, 0.17), MID, MUTED, 700, false)
	note.ZIndex = 6

	-- the tree: a trunk rising behind the middle card and a bough the three node discs hang on
	local function wood(size, pos, rot)
		local f = new("Frame", win, { Size = size, Position = pos, AnchorPoint = MID, Rotation = rot or 0, BackgroundColor3 = BARK, BorderSizePixel = 0, ZIndex = 5 })
		new("UICorner", f, { CornerRadius = UDim.new(0.5, 0) })
		new("UIStroke", f, { Color = INK, Thickness = 2 })
		return f
	end
	-- (Gemini r1: a straight bough over three cards read as a shop shelf, tree 2.5) a canopy of soft leaf clouds, a trunk
	-- from the roots and three boughs fanning up to nodes at different heights
	local canopy = {}
	for _, c in { { 0.5, 0.36, 0.62 }, { 0.24, 0.44, 0.5 }, { 0.76, 0.44, 0.5 }, { 0.37, 0.3, 0.4 }, { 0.63, 0.3, 0.4 } } do
		local leafCloud = new("Frame", win, { Size = UDim2.fromScale(c[3], c[3]), SizeConstraint = Enum.SizeConstraint.RelativeYY, Position = UDim2.fromScale(c[1], c[2]), AnchorPoint = MID, BackgroundColor3 = E.MINT, BackgroundTransparency = 0.8, BorderSizePixel = 0, ZIndex = 4 })
		new("UICorner", leafCloud, { CornerRadius = UDim.new(0.5, 0) })
		table.insert(canopy, leafCloud)
	end
	wood(UDim2.fromScale(0.04, 0.5), UDim2.fromScale(0.5, 0.74)) -- trunk
	wood(UDim2.fromScale(0.3, 0.03), UDim2.fromScale(0.36, 0.5), 32) -- left bough
	wood(UDim2.fromScale(0.3, 0.03), UDim2.fromScale(0.64, 0.5), -32) -- right bough
	wood(UDim2.fromScale(0.12, 0.035), UDim2.fromScale(0.43, 0.95), -12) -- roots
	wood(UDim2.fromScale(0.12, 0.035), UDim2.fromScale(0.57, 0.95), 12)
	for _, l in { { 0.3, 0.47, -30 }, { 0.41, 0.6, 30 }, { 0.7, 0.47, 30 }, { 0.59, 0.6, -30 }, { 0.46, 0.4, -40 }, { 0.54, 0.4, 40 } } do -- leaves on the boughs
		local leaf = new("Frame", win, { Size = UDim2.fromScale(0.035, 0.045), Position = UDim2.fromScale(l[1], l[2]), AnchorPoint = MID, Rotation = l[3], BackgroundColor3 = E.MINT, BorderSizePixel = 0, ZIndex = 5 })
		new("UICorner", leaf, { CornerRadius = UDim.new(0.5, 0) })
		new("UIStroke", leaf, { Color = INK, Thickness = 2 })
	end

	local cards = {}
	for i, id in T.order do
		local def, look = T.nodes[id], LOOK[id]
		local x = 0.19 + (i - 1) * 0.31
		local top = i == 2 and 0.3 or 0.4 -- the middle node is the crown
		local card = panel(win, UDim2.fromScale(0.25, 0.44), UDim2.fromScale(x, top + 0.27), MID, "card")
		card.ZIndex = 6
		card.Skin.ImageTransparency = 0.06
		local fruit = {} -- one fruit ripens beside the node for every rank bought: the tree itself shows your growth
		for k = 1, def.max do
			local side = (k % 2 == 0) and 1 or -1
			local f = new("Frame", win, { Size = UDim2.fromScale(0.065, 0.065), SizeConstraint = Enum.SizeConstraint.RelativeYY, Position = UDim2.fromScale(x + side * (0.085 + 0.012 * k), top - 0.07 + 0.045 * k), AnchorPoint = MID, BackgroundColor3 = look[1], BorderSizePixel = 0, ZIndex = 7, Visible = false })
			new("UICorner", f, { CornerRadius = UDim.new(0.5, 0) })
			new("UIStroke", f, { Color = INK, Thickness = 2 })
			new("UIGradient", f, { Rotation = 90, Color = ColorSequence.new(WHITE, Color3.fromRGB(214, 206, 226)) })
			fruit[k] = f
		end
		local disc = new("Frame", win, { Size = UDim2.fromScale(0.2, 0.2), SizeConstraint = Enum.SizeConstraint.RelativeYY, Position = UDim2.fromScale(x, top + 0.02), AnchorPoint = MID, BackgroundColor3 = look[1], BorderSizePixel = 0, ZIndex = 7 })
		new("UICorner", disc, { CornerRadius = UDim.new(0.5, 0) })
		new("UIStroke", disc, { Color = INK, Thickness = 3 })
		new("UIGradient", disc, { Rotation = 90, Color = ColorSequence.new(WHITE, Color3.fromRGB(226, 220, 236)) })
		new("ImageLabel", disc, { Image = look[2], BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit, Size = UDim2.fromScale(0.64, 0.64), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = MID, ZIndex = 8 })
		local name = text(card, string.upper(def.name), UDim2.fromScale(0.9, 0.13), UDim2.fromScale(0.5, 0.3), MID, INK, 700, false)
		name.ZIndex = 7
		local what = text(card, def.text, UDim2.fromScale(0.86, 0.1), UDim2.fromScale(0.5, 0.44), MID, MUTED, 700, false)
		what.ZIndex = 7
		local pips = {}
		for k = 1, def.max do
			local p = new("Frame", card, { Size = UDim2.fromScale(0.1, 0.1), SizeConstraint = Enum.SizeConstraint.RelativeYY, Position = UDim2.fromScale(0.5 + (k - (def.max + 1) / 2) * 0.13, 0.59), AnchorPoint = MID, BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 7 })
			new("UICorner", p, { CornerRadius = UDim.new(0.5, 0) })
			new("UIStroke", p, { Color = INK, Thickness = 2 })
			pips[k] = p
		end
		local buy = button(card, "", UDim2.fromScale(0.78, 0.2), UDim2.fromScale(0.5, 0.82), MID, "mint")
		buy.ZIndex = 7
		buy.Label.ZIndex = 8
		buy.Activated:Connect(function() SoulR:FireServer("buy", id) end)
		cards[id] = { def = def, look = look, pips = pips, buy = buy, disc = disc, what = what, fruit = fruit }
	end

	local function refresh()
		count.Text = tostring(soul.shards)
		local grown = 0
		for _, r in soul.nodes do grown += r end
		for _, cl in canopy do cl.BackgroundTransparency = math.max(0.45, 0.8 - grown * 0.045) end -- the canopy fills in as the tree grows
		for id, c in cards do
			local rank = soul.nodes[id] or 0
			for k, f in c.fruit do f.Visible = k <= rank end
			for k, p in c.pips do p.BackgroundColor3 = k <= rank and c.look[1] or WHITE end
			local cost = c.def.cost[rank + 1]
			local unit = c.def.unit or ""
			c.what.Text = rank == 0 and c.def.text -- what you have now and what the next rank gives
				or (rank >= c.def.max and ("Now " .. rank * c.def.each .. unit .. " (full)") or ("Now " .. rank * c.def.each .. ", next " .. (rank + 1) * c.def.each .. unit))
			if rank >= c.def.max or not cost then
				c.buy.Text = "FULL"
				E.setKind(c.buy, "off")
			else
				c.buy.Text = cost .. (cost == 1 and " SHARD" or " SHARDS")
				E.setKind(c.buy, soul.shards >= cost and "mint" or "off")
			end
		end
	end
	local function take(s)
		if type(s) == "table" and type(s.soul) == "table" then
			soul = { shards = s.soul.shards or 0, nodes = s.soul.nodes or {} }
			if win.Visible then refresh() end
		end
	end
	R.State.OnClientEvent:Connect(take)

	local function open()
		if win.Visible or (E.isBusy and E.isBusy()) then return end
		SoulR:FireServer("sync")
		refresh()
		E.openPanel(win)
		E.sfx("sparkle", 0.9)
	end
	close.Activated:Connect(function() if win.Visible then E.closePanel(win) end end)
	game:GetService("ProximityPromptService").PromptTriggered:Connect(function(prompt)
		if prompt:GetAttribute("SoulTree") then open() end
	end)
	R.Fx.OnClientEvent:Connect(function(kind, a, b)
		if kind == "soulShard" then
			E.toast("+" .. tostring(a) .. " Gloom Shard" .. (a == 1 and "" or "s") .. "  (" .. tostring(b) .. ")", nil, false, 2.5)
			pcall(E.sfx, "sparkle", 1.4)
		elseif kind == "soulBought" and cards[a] then
			pcall(E.sfx, "upgrade", 1)
			pcall(E.pop, cards[a].disc)
			if E.vmHook.emote then E.vmHook.emote("cheer") end
		elseif kind == "soulNo" then
			pcall(E.sfx, "error", 1)
		end
	end)
end

return M
