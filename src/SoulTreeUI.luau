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
	do -- directive v14 (audit: blueprint paper behind the rune plates): an opaque obsidian core, as the Boon stone has
		local backing = new("Frame", win, { Name = "Backing", Size = UDim2.fromScale(0.97, 0.94), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = MID, BackgroundColor3 = Color3.fromRGB(14, 8, 28), BackgroundTransparency = 0.06, BorderSizePixel = 0, ZIndex = 1 })
		new("UICorner", backing, { CornerRadius = UDim.new(0.04, 0) })
	end
	fit(win, 760, 430)
	win.Name, win.Visible = "SoulTree", false
	if E.addModal then E.addModal(win) end
	local rb, rbT = E.ribbonTitle(win, "SOUL TREE", "ribbonLilac", 0.4)
	do -- directive v14 (audit: pale lilac ribbons on the ritual screens): a smoked obsidian ribbon with a gold rim
		local sk = rb:FindFirstChild("Skin")
		if sk then sk.Visible = false end
		rb.BackgroundColor3, rb.BackgroundTransparency = Color3.fromRGB(28, 16, 46), 0.04
		new("UICorner", rb, { CornerRadius = UDim.new(0.5, 0) })
		new("UIStroke", rb, { Color = Color3.fromRGB(255, 214, 107), Thickness = 1.5, Transparency = 0.35 })
		rbT.TextStrokeColor3 = Color3.fromRGB(20, 10, 34)
	end
	local close = E.closeButton(win, "SoulClose")

	local function shardGem(parent, k, pos, z)
		local g = new("Frame", parent, { Size = UDim2.fromScale(k, k), SizeConstraint = Enum.SizeConstraint.RelativeYY, Position = pos, AnchorPoint = MID, Rotation = 45, BackgroundColor3 = SHARD, BorderSizePixel = 0, ZIndex = z })
		new("UICorner", g, { CornerRadius = UDim.new(0.22, 0) })
		new("UIStroke", g, { Color = INK, Thickness = 2 })
		new("UIGradient", g, { Rotation = 45, Color = ColorSequence.new(Color3.fromRGB(226, 208, 255), SHARD) })
		return g
	end
	do -- directive v13 round 2 (Gemini: the bright town bled through the glass): an opaque dark core behind the content
		local backing = new("Frame", win, { Name = "Backing", Size = UDim2.fromScale(0.97, 0.94), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = MID, BackgroundColor3 = Color3.fromRGB(14, 8, 28), BackgroundTransparency = 0.12, BorderSizePixel = 0, ZIndex = 2 })
		new("UICorner", backing, { CornerRadius = UDim.new(0.04, 0) })
	end
	local pill = panel(win, UDim2.fromScale(0.16, 0.085), UDim2.fromScale(0.5, 0.155), MID, "pillLilac") -- round 2: centred under the title
	pill.ZIndex = 6
	shardGem(pill, 0.46, UDim2.fromScale(0.2, 0.5), 7)
	local count = text(pill, "0", UDim2.fromScale(0.56, 0.6), UDim2.fromScale(0.64, 0.5), MID, INK, 700, false)
	count.ZIndex = 7
	local note = text(win, "Flatten gloomlings with a flare to gather Gloom Shards.", UDim2.fromScale(0.27, 0.075), UDim2.fromScale(0.2, 0.155), MID, Color3.fromRGB(206, 194, 236), 700, false) -- round 3: beside the pill, clear of the crown node
	note.TextWrapped = true
	note.ZIndex = 6

	-- the tree: a trunk rising behind the middle card and a bough the three node discs hang on
	local function wood(size, pos, rot)
		-- round 2 (Gemini: "a raw brown stick"): a crystal arbor: deep violet limbs with a glowing cyan core line
		local f = new("Frame", win, { Size = size, Position = pos, AnchorPoint = MID, Rotation = rot or 0, BackgroundColor3 = Color3.fromRGB(70, 40, 128), BorderSizePixel = 0, ZIndex = 5 })
		new("UICorner", f, { CornerRadius = UDim.new(0.5, 0) })
		new("UIStroke", f, { Color = Color3.fromRGB(110, 225, 255), Thickness = 1.5, Transparency = 0.45 })
		new("UIGradient", f, { Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(190, 160, 255), Color3.fromRGB(60, 30, 110)) })
		local long = size.X.Scale > size.Y.Scale
		local core = new("Frame", f, { Size = UDim2.fromScale(long and 1 or 0.28, long and 0.28 or 1), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = MID, BackgroundColor3 = Color3.fromRGB(150, 240, 255), BackgroundTransparency = 0.35, BorderSizePixel = 0, ZIndex = 5 })
		new("UICorner", core, { CornerRadius = UDim.new(0.5, 0) })
		return f
	end
	-- (Gemini r1: a straight bough over three cards read as a shop shelf, tree 2.5) a canopy of soft leaf clouds, a trunk
	-- from the roots and three boughs fanning up to nodes at different heights
	local canopy = {}
	for _, c in {} do -- round 2: the leaf-cloud rings read as a radar; the arbor stands alone
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

	local PALE, GOLDRIM, CYANRIM, UNLIT = Color3.fromRGB(206, 194, 236), Color3.fromRGB(255, 206, 110), Color3.fromRGB(110, 225, 255), Color3.fromRGB(44, 32, 70)
	-- directive v13 (Hades crest card, Slay the Spire reward focus): each node is a dark rune-slate plate with a gold outer rule
	-- and a glowing cyan inner rim, not pale shop paper
	local function runePlate(parent, size, pos)
		local f = new("Frame", parent, { Size = size, Position = pos, AnchorPoint = MID, BackgroundColor3 = Color3.fromRGB(24, 14, 42), BackgroundTransparency = 0.04, BorderSizePixel = 0, ZIndex = 6 })
		new("UICorner", f, { CornerRadius = UDim.new(0.08, 0) })
		new("UIStroke", f, { Color = GOLDRIM, Thickness = 2, Transparency = 0.15 })
		new("UIGradient", f, { Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(110, 100, 150)) })
		local inner = new("Frame", f, { Name = "InnerRim", Size = UDim2.new(1, -10, 1, -10), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = MID, BackgroundTransparency = 1, ZIndex = 6 })
		new("UICorner", inner, { CornerRadius = UDim.new(0.075, 0) })
		new("UIStroke", inner, { Color = CYANRIM, Thickness = 1.5, Transparency = 0.32 })
		return f
	end
	local cards = {}
	for i, id in T.order do
		local def, look = T.nodes[id], LOOK[id]
		local x = 0.19 + (i - 1) * 0.31
		local top = i == 2 and 0.3 or 0.4 -- the middle node is the crown
		local card = runePlate(win, UDim2.fromScale(0.25, 0.44), UDim2.fromScale(x, top + 0.27))
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
		new("UIStroke", disc, { Color = GOLDRIM, Thickness = 3 })
		new("UIGradient", disc, { Rotation = 45, Color = ColorSequence.new(WHITE, Color3.fromRGB(120, 100, 150)) })
		local icon = new("ImageLabel", disc, { Image = look[2], BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit, Size = UDim2.fromScale(0.64, 0.64), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = MID, ZIndex = 8 })
		do -- directive v13 (Gemini: emoji clipart): the node's voxel crest turning in the disc (Shared.Crests, the boon cards' own)
			local ok = pcall(function() -- the image icon stays if anything here fails (Codex 2026-11-20)
				local Cr, MC = script.Parent:WaitForChild("Crests", 5), script.Parent:WaitForChild("ModelCard", 5)
				local m = Cr and MC and require(Cr).model(id)
				if not m then error("no crest") end
				require(MC).attach(disc, disc, { z = 8 }).set(m, look[1])
			end)
			if ok then icon.Visible = false else
				for _, n in { "Card3D", "CardGlow", "CardShine" } do local x = disc:FindFirstChild(n) if x then x:Destroy() end end
			end
		end
		local name = text(card, string.upper(def.name), UDim2.fromScale(0.9, 0.13), UDim2.fromScale(0.5, 0.3), MID, WHITE, 700, false)
		if E.HEAD then name.Font = E.HEAD end
		name.ZIndex = 7
		local what = text(card, def.text, UDim2.fromScale(0.86, 0.1), UDim2.fromScale(0.5, 0.44), MID, PALE, 700, false)
		what.ZIndex = 7
		local pips = {}
		for k = 1, def.max do
			local p = new("Frame", card, { Rotation = 45, Size = UDim2.fromScale(0.13, 0.13), SizeConstraint = Enum.SizeConstraint.RelativeYY, Position = UDim2.fromScale(0.5 + (k - (def.max + 1) / 2) * 0.13, 0.59), AnchorPoint = MID, BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 7 })
			new("UICorner", p, { CornerRadius = UDim.new(0.22, 0) })
			new("UIStroke", p, { Color = GOLDRIM, Thickness = 2, Transparency = 0.1 })
			new("UIGradient", p, { Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(150, 140, 180)) }) -- a cut gem pip (round 2: hairline circles)
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
			for k, p in c.pips do p.BackgroundColor3 = k <= rank and c.look[1] or UNLIT end
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
	plr:GetAttributeChangedSignal("DevOpen"):Connect(function() if plr:GetAttribute("DevOpen") == "soul" and game:GetService("RunService"):IsStudio() then open() end end) -- Studio test hook (spike/p1_shots.py)
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
