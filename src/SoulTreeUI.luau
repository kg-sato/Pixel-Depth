-- SoulTreeUI (ReplicatedStorage.Shared.SoulTreeUI), started by PixelClient. The Soul Tree panel at Camp 1's campfire
-- (prompt attribute SoulTree): the Gloom Shards you hold and three nodes, each with its ranks, what the next rank does and
-- what it costs. Display and requests only: ServerScriptService.SoulTree counts shards and checks every buy. Does nothing
-- while C.SOUL_TREE.on is false (the feature is behind the flag because it adds a saved field).
-- Master Directive v15 (after @spmovesets' constellation skill trees, vault Social References Review (2026-11-23)): the top
-- of the panel is a starlit sky where each node is a constellation round a central shard star (The Veiled Lantern, The
-- Sunburst Flare, The Aegis Crown); every rank bought lights a star and the lines to it, and a full constellation wears a
-- small gold crown. The bottom is a dark inspector for the picked node: its crest, name, ACTIVE / FULL, RANK k / MAX, the
-- number now and next, one tip and the INVEST button. The server protocol (Soul remote: "sync", "buy" id) is unchanged.
local RunService = game:GetService("RunService")
local M = {}

function M.start(E)
	local C, R, plr, gui, new, S, fit, text, panel, button = E.C, E.R, E.plr, E.gui, E.new, E.S, E.fit, E.text, E.panel, E.button
	local T = C.SOUL_TREE
	if not (T and T.on) then return end
	local SoulR = R:WaitForChild("Soul", 20)
	if not SoulR then return end
	local INK, WHITE, MID = E.INK, E.WHITE, Vector2.new(0.5, 0.5)
	local SHARD, GOLD, PALE = Color3.fromRGB(150, 110, 230), Color3.fromRGB(255, 214, 107), Color3.fromRGB(206, 194, 236)
	local UNLIT, LINE_OFF = Color3.fromRGB(58, 46, 92), Color3.fromRGB(70, 58, 110)
	-- per node: the constellation's name, its glow, the HUD icon (fallback when the crest cannot draw), one tip line, and the
	-- stars of its figure in sky coordinates: `rank` = the stars a rank lights (in order), `deco` = outline stars, `links` = lines
	local LOOK = {
		hide = { sky = "THE VEILED LANTERN", tint = Color3.fromRGB(120, 255, 196), icon = C.HUD_ICON.heart, tip = "Each rank: gloomlings hit 8 softer.",
			rank = { { 0.2, 0.47 }, { 0.2, 0.17 }, { 0.2, 0.79 } }, deco = { { 0.135, 0.32 }, { 0.265, 0.32 }, { 0.135, 0.64 }, { 0.265, 0.64 } },
			links = { { "r1", "r2" }, { "r1", "r3" }, { "r2", "d1" }, { "r2", "d2" }, { "d1", "d3" }, { "d2", "d4" }, { "d3", "r3" }, { "d4", "r3" } } },
		flare = { sky = "THE SUNBURST FLARE", tint = Color3.fromRGB(255, 160, 176), icon = C.HUD_ICON.flare, tip = "Each rank: +1 flare every dive.",
			rank = { { 0.5, 0.42 }, { 0.5, 0.15 } }, deco = { { 0.405, 0.29 }, { 0.595, 0.29 }, { 0.415, 0.55 }, { 0.585, 0.55 } },
			links = { { "r1", "r2" }, { "r1", "d1" }, { "r1", "d2" }, { "r1", "d3" }, { "r1", "d4" }, { "d1", "r2" }, { "d2", "r2" } } },
		shield = { sky = "THE AEGIS CROWN", tint = Color3.fromRGB(255, 200, 96), icon = E.ICON.star, tip = "Each rank: golden shield +2 s.",
			rank = { { 0.8, 0.45 }, { 0.8, 0.15 }, { 0.8, 0.8 } }, deco = { { 0.71, 0.28 }, { 0.89, 0.28 }, { 0.73, 0.6 }, { 0.87, 0.6 } },
			links = { { "r1", "r2" }, { "r1", "r3" }, { "r2", "d1" }, { "r2", "d2" }, { "d1", "d3" }, { "d2", "d4" }, { "d3", "r3" }, { "d4", "r3" } } },
	}
	local CORE = { 0.5, 0.8 }
	local soul = { shards = 0, nodes = {} }
	local pick = T.order[1]

	local win = panel(gui, S(780, 480), S(640, 300), MID, "panel")
	do -- an opaque obsidian core (directive v14: blueprint paper showed through)
		local backing = new("Frame", win, { Name = "Backing", Size = UDim2.fromScale(0.97, 0.95), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = MID, BackgroundColor3 = Color3.fromRGB(12, 7, 24), BackgroundTransparency = 0.03, BorderSizePixel = 0, ZIndex = 2 })
		new("UICorner", backing, { CornerRadius = UDim.new(0.04, 0) })
	end
	fit(win, 780, 480)
	win.Name, win.Visible = "SoulTree", false
	if E.addModal then E.addModal(win) end
	win:GetPropertyChangedSignal("Visible"):Connect(function() -- round 2 (Gemini: an NPC's chat bubble showed through the panel): bubble chat rests while the tree is open
		pcall(function() game:GetService("TextChatService").BubbleChatConfiguration.Enabled = not win.Visible end)
	end)
	local rb, rbT = E.ribbonTitle(win, "SOUL TREE", "ribbonLilac", 0.4)
	do -- a smoked obsidian ribbon with a gold rim (directive v14)
		local sk = rb:FindFirstChild("Skin")
		if sk then sk.Visible = false end
		rb.BackgroundColor3, rb.BackgroundTransparency = Color3.fromRGB(28, 16, 46), 0.04
		new("UICorner", rb, { CornerRadius = UDim.new(0.5, 0) })
		new("UIStroke", rb, { Color = GOLD, Thickness = 1.5, Transparency = 0.35 })
		rbT.TextStrokeColor3 = Color3.fromRGB(20, 10, 34)
	end
	local close = E.closeButton(win, "SoulClose")

	-- the sky: about 58% of the panel under the ribbon
	local sky = new("Frame", win, { Name = "Sky", Size = UDim2.fromScale(0.93, 0.52), Position = UDim2.fromScale(0.5, 0.375), AnchorPoint = MID, BackgroundColor3 = Color3.fromRGB(8, 5, 20), BorderSizePixel = 0, ClipsDescendants = true, ZIndex = 3 })
	new("UICorner", sky, { CornerRadius = UDim.new(0.05, 0) })
	new("UIStroke", sky, { Color = Color3.fromRGB(120, 96, 180), Thickness = 1.5, Transparency = 0.35 })
	new("UIGradient", sky, { Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(150, 130, 230), Color3.fromRGB(70, 50, 120)) })
	local far, near, twinkle = {}, {}, {}
	do -- two layers of pinpoint stars that drift at different speeds (a slow parallax while the panel is open)
		local rng = Random.new(7)
		for layer = 1, 2 do
			local holder = new("Frame", sky, { Name = layer == 1 and "Far" or "Near", Size = UDim2.fromScale(2, 1), BackgroundTransparency = 1, ZIndex = 3 })
			for _ = 1, layer == 1 and 70 or 34 do
				local k = layer == 1 and rng:NextNumber(0.008, 0.014) or rng:NextNumber(0.014, 0.022)
				local st = new("Frame", holder, { Size = UDim2.fromScale(k, k), SizeConstraint = Enum.SizeConstraint.RelativeYY, Position = UDim2.fromScale(rng:NextNumber(0, 0.5), rng:NextNumber(0.03, 0.97)), AnchorPoint = MID,
					BackgroundColor3 = rng:NextNumber() < 0.25 and Color3.fromRGB(200, 190, 255) or WHITE, BackgroundTransparency = rng:NextNumber(0.25, 0.7), BorderSizePixel = 0, ZIndex = 3 })
				if layer == 2 then new("UICorner", st, { CornerRadius = UDim.new(0.5, 0) }) end
				local twin = new("Frame", holder, { Size = st.Size, SizeConstraint = st.SizeConstraint, Position = st.Position + UDim2.fromScale(0.5, 0), AnchorPoint = MID, BackgroundColor3 = st.BackgroundColor3, BackgroundTransparency = st.BackgroundTransparency, BorderSizePixel = 0, ZIndex = 3 }) -- the wrap copy one sky width over (the holder is two skies wide), so the drift wraps without a jump
				table.insert(twinkle, { st, twin, st.BackgroundTransparency, rng:NextNumber(0, 6.28), rng:NextNumber(0.8, 2.2) })
			end
			if layer == 1 then far = holder else near = holder end
		end
		new("Frame", sky, { Name = "Haze", Size = UDim2.fromScale(0.7, 0.9), Position = UDim2.fromScale(0.5, 0.62), AnchorPoint = MID, BackgroundColor3 = Color3.fromRGB(110, 70, 190), BackgroundTransparency = 0.82, BorderSizePixel = 0, ZIndex = 3 }) -- a faint nebula behind the core
	end

	-- lines between sky points: a thin frame turned to the angle the two points make on screen (the sky is wide, not square)
	do -- round 2 (Gemini v15_r1: "a flat black box with uniform dots"): soft nebula glows behind the core and each constellation
		local GLOWIMG = "rbxassetid://77591933607769" -- the soft glow sprite (art/forge/fx), as the forging scenes use it
		for _, n in { { 0.5, 0.72, 0.62, 1.25, Color3.fromRGB(150, 90, 255), 0.6 }, { 0.2, 0.48, 0.34, 1.0, Color3.fromRGB(60, 220, 170), 0.72 },
			{ 0.5, 0.33, 0.32, 0.85, Color3.fromRGB(255, 110, 150), 0.74 }, { 0.8, 0.48, 0.34, 1.0, Color3.fromRGB(255, 180, 70), 0.74 } } do
			new("ImageLabel", sky, { Name = "Nebula", Image = GLOWIMG, ImageColor3 = n[5], ImageTransparency = n[6], BackgroundTransparency = 1, Size = UDim2.fromScale(n[3], n[4]), Position = UDim2.fromScale(n[1], n[2]), AnchorPoint = MID, ZIndex = 3 })
		end
	end
	local lines = {}
	local function line(a, b, color, z)
		local g = new("Frame", sky, { AnchorPoint = MID, BackgroundColor3 = color, BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 4 }) -- the soft glow under a lit line
		new("UICorner", g, { CornerRadius = UDim.new(0.5, 0) })
		local f = new("Frame", sky, { AnchorPoint = MID, BackgroundColor3 = color, BorderSizePixel = 0, ZIndex = z or 4 })
		local l = { f = f, g = g, a = a, b = b }
		table.insert(lines, l)
		return l
	end
	local function layout()
		local W, H = sky.AbsoluteSize.X, sky.AbsoluteSize.Y
		if W < 2 or H < 2 then return end
		for _, l in lines do
			local dx, dy = (l.b[1] - l.a[1]) * W, (l.b[2] - l.a[2]) * H
			local len = math.sqrt(dx * dx + dy * dy)
			l.f.Position = UDim2.fromScale((l.a[1] + l.b[1]) / 2, (l.a[2] + l.b[2]) / 2)
			l.f.Size = UDim2.new(0, len, 0, math.max(2, math.floor(H * 0.012 + 0.5)))
			l.f.Rotation = math.deg(math.atan2(dy, dx))
			l.g.Position, l.g.Size, l.g.Rotation = l.f.Position, UDim2.new(0, len + 6, 0, math.max(6, math.floor(H * 0.045 + 0.5))), l.f.Rotation
		end
	end
	sky:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)

	local function star(pos, size, color, z) -- a four-point star: a diamond, a thin cross for the points and a soft halo
		local holder = new("Frame", sky, { Size = UDim2.fromScale(size, size), SizeConstraint = Enum.SizeConstraint.RelativeYY, Position = UDim2.fromScale(pos[1], pos[2]), AnchorPoint = MID, BackgroundTransparency = 1, ZIndex = z })
		local halo = new("Frame", holder, { Name = "Halo", Size = UDim2.fromScale(1.9, 1.9), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = MID, BackgroundColor3 = color, BackgroundTransparency = 0.82, BorderSizePixel = 0, ZIndex = z })
		new("UICorner", halo, { CornerRadius = UDim.new(0.5, 0) })
		local h1 = new("Frame", holder, { Name = "RayH", Size = UDim2.fromScale(1.5, 0.1), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = MID, BackgroundColor3 = color, BorderSizePixel = 0, ZIndex = z + 1 })
		local v1 = new("Frame", holder, { Name = "RayV", Size = UDim2.fromScale(0.1, 1.5), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = MID, BackgroundColor3 = color, BorderSizePixel = 0, ZIndex = z + 1 })
		new("UICorner", h1, { CornerRadius = UDim.new(0.5, 0) })
		new("UICorner", v1, { CornerRadius = UDim.new(0.5, 0) })
		local gem = new("Frame", holder, { Name = "Gem", Size = UDim2.fromScale(0.58, 0.58), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = MID, Rotation = 45, BackgroundColor3 = color, BorderSizePixel = 0, ZIndex = z + 2 })
		new("UICorner", gem, { CornerRadius = UDim.new(0.18, 0) })
		local edge = new("UIStroke", gem, { Color = WHITE, Thickness = 1.5, Transparency = 0.5 })
		local core = new("Frame", gem, { Name = "Core", Size = UDim2.fromScale(0.42, 0.42), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = MID, BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = z + 3 })
		new("UICorner", core, { CornerRadius = UDim.new(0.3, 0) })
		return { holder = holder, halo = halo, rays = { h1, v1 }, gem = gem, edge = edge, core = core }
	end
	local function paintStar(s, color, lit, bright)
		s.gem.BackgroundColor3 = lit and color or UNLIT
		s.core.BackgroundTransparency = lit and 0.05 or 0.85
		s.edge.Color, s.edge.Transparency = lit and WHITE or color, lit and 0.35 or 0.55
		s.halo.BackgroundColor3, s.halo.BackgroundTransparency = color, lit and (bright and 0.6 or 0.78) or 0.94
		for _, r in s.rays do r.BackgroundColor3, r.BackgroundTransparency = lit and color or UNLIT, lit and 0.1 or 0.6 end
	end

	-- the central shard star: the anchor every constellation grows from; it holds your shard count
	local core = star(CORE, 0.3, SHARD, 9)
	paintStar(core, Color3.fromRGB(196, 160, 255), true, true)
	core.gem.Size = UDim2.fromScale(0.62, 0.62)
	local count = text(core.holder, "0", UDim2.fromScale(0.5, 0.32), UDim2.fromScale(0.5, 0.46), MID, Color3.fromRGB(40, 18, 70), 700, false)
	count.ZIndex = 14
	local shardsWord = text(core.holder, "SHARDS", UDim2.fromScale(0.9, 0.16), UDim2.fromScale(0.5, 0.9), MID, Color3.fromRGB(230, 214, 255), 700, false) -- under the core star (a word in the bottom row ran into the constellation names)
	shardsWord.ZIndex = 14

	local figs = {}
	for _, id in T.order do
		local look = LOOK[id]
		local fig = { id = id, look = look, ranks = {}, deco = {}, links = {}, crown = nil }
		local P = {}
		for k, p in look.rank do P["r" .. k] = p end
		for k, p in look.deco do P["d" .. k] = p end
		fig.branch = line(CORE, look.rank[1], LINE_OFF, 4)
		for _, ln in look.links do table.insert(fig.links, line(P[ln[1]], P[ln[2]], LINE_OFF, 4)) end
		for k, p in look.deco do fig.deco[k] = star(p, 0.07, look.tint, 5) end
		for k, p in look.rank do fig.ranks[k] = star(p, 0.13, look.tint, 6) end
		local top = look.rank[2] or look.rank[1]
		local crown = new("Frame", sky, { Name = "Crown", Size = UDim2.fromScale(0.09, 0.07), SizeConstraint = Enum.SizeConstraint.RelativeYY, Position = UDim2.fromScale(top[1] + 0.045, top[2] - 0.03), AnchorPoint = MID, BackgroundTransparency = 1, Visible = false, ZIndex = 10 })
		for c = 0, 2 do -- a small gold crown: three points on a band
			local pt = new("Frame", crown, { Size = UDim2.fromScale(0.22, 0.5), Position = UDim2.fromScale(0.2 + c * 0.3, c == 1 and 0.28 or 0.36), AnchorPoint = MID, Rotation = 45, BackgroundColor3 = GOLD, BorderSizePixel = 0, ZIndex = 10 })
			new("UIStroke", pt, { Color = Color3.fromRGB(120, 70, 20), Thickness = 1 })
		end
		local band = new("Frame", crown, { Size = UDim2.fromScale(1, 0.34), Position = UDim2.fromScale(0.5, 0.78), AnchorPoint = MID, BackgroundColor3 = GOLD, BorderSizePixel = 0, ZIndex = 11 })
		new("UIStroke", band, { Color = Color3.fromRGB(120, 70, 20), Thickness = 1 })
		fig.crown = crown
		local xs = look.rank[1][1]
		local name = text(sky, look.sky, UDim2.fromScale(0.3, 0.075), UDim2.fromScale(xs, 0.955), MID, look.tint, 700, false)
		name.ZIndex = 6
		if id == "flare" then name.Position = UDim2.fromScale(xs, 0.05) end -- the middle constellation is named over its crown star (the bottom row's middle is the shard star's)
		fig.name = name
		local hit = new("TextButton", sky, { Name = "Pick_" .. id, Text = "", AutoButtonColor = false, BackgroundTransparency = 1, Size = UDim2.fromScale(0.24, id == "flare" and 0.6 or 0.86), Position = UDim2.fromScale(xs, id == "flare" and 0.35 or 0.48), AnchorPoint = MID, ZIndex = 12 })
		hit.Activated:Connect(function()
			pick = id
			if E.sfxClick then pcall(E.sfxClick) else pcall(E.sfx, "click", 1.2) end
			M.refresh()
		end)
		local ring = new("Frame", sky, { Name = "PickRing", Size = UDim2.fromScale(0.25, 0.25), SizeConstraint = Enum.SizeConstraint.RelativeYY, Position = UDim2.fromScale(look.rank[1][1], look.rank[1][2]), AnchorPoint = MID, BackgroundTransparency = 1, ZIndex = 5 })
		new("UICorner", ring, { CornerRadius = UDim.new(0.5, 0) })
		fig.ring = new("UIStroke", ring, { Color = look.tint, Thickness = 3, Transparency = 1 })
		figs[id] = fig
	end
	layout()

	-- the inspector: the picked node's crest, name, state, rank, numbers, tip and the INVEST button
	local insp = new("Frame", win, { Name = "Inspector", Size = UDim2.fromScale(0.93, 0.33), Position = UDim2.fromScale(0.5, 0.81), AnchorPoint = MID, BackgroundColor3 = Color3.fromRGB(20, 12, 36), BorderSizePixel = 0, ZIndex = 3 })
	new("UICorner", insp, { CornerRadius = UDim.new(0.1, 0) })
	local inspEdge = new("UIStroke", insp, { Color = GOLD, Thickness = 1.5, Transparency = 0.3 })
	local crestBox = new("Frame", insp, { Name = "Crest", Size = UDim2.fromScale(0.78, 0.78), SizeConstraint = Enum.SizeConstraint.RelativeYY, Position = UDim2.fromScale(0.085, 0.5), AnchorPoint = MID, BackgroundColor3 = Color3.fromRGB(32, 20, 56), BorderSizePixel = 0, ZIndex = 4 })
	new("UICorner", crestBox, { CornerRadius = UDim.new(0.5, 0) })
	local crestEdge = new("UIStroke", crestBox, { Color = GOLD, Thickness = 2, Transparency = 0.2 })
	local crestIcon = new("ImageLabel", crestBox, { BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit, Size = UDim2.fromScale(0.62, 0.62), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = MID, ZIndex = 6 })
	local crest
	pcall(function() -- the node's live voxel crest (Shared.Crests, the boon cards' own); the icon stays if this fails (Codex 2026-11-20)
		local MC = script.Parent:WaitForChild("ModelCard", 5)
		crest = MC and require(MC).attach(crestBox, crestBox, { z = 5 })
	end)
	local Crests = script.Parent:FindFirstChild("Crests") and require(script.Parent.Crests)
	local nameL = text(insp, "", UDim2.fromScale(0.29, 0.27), UDim2.fromScale(0.19, 0.22), Vector2.new(0, 0.5), WHITE, 700, false)
	nameL.TextXAlignment, nameL.ZIndex = Enum.TextXAlignment.Left, 5
	if E.HEAD then nameL.Font = E.HEAD end
	local pillState = new("Frame", insp, { Size = UDim2.fromScale(0.12, 0.2), Position = UDim2.fromScale(0.545, 0.22), AnchorPoint = MID, BackgroundColor3 = Color3.fromRGB(40, 110, 80), BorderSizePixel = 0, ZIndex = 5 })
	new("UICorner", pillState, { CornerRadius = UDim.new(0.5, 0) })
	local stateL = text(pillState, "ACTIVE", UDim2.fromScale(0.84, 0.72), UDim2.fromScale(0.5, 0.5), MID, WHITE, 700, false)
	stateL.ZIndex = 6
	local pillRank = new("Frame", insp, { Size = UDim2.fromScale(0.13, 0.2), Position = UDim2.fromScale(0.68, 0.22), AnchorPoint = MID, BackgroundColor3 = Color3.fromRGB(46, 30, 78), BorderSizePixel = 0, ZIndex = 5 })
	new("UICorner", pillRank, { CornerRadius = UDim.new(0.5, 0) })
	new("UIStroke", pillRank, { Color = GOLD, Thickness = 1.5, Transparency = 0.3 })
	local rankL = text(pillRank, "RANK 0 / 3", UDim2.fromScale(0.86, 0.7), UDim2.fromScale(0.5, 0.5), MID, GOLD, 700, false)
	rankL.ZIndex = 6
	local statL = text(insp, "", UDim2.fromScale(0.56, 0.25), UDim2.fromScale(0.19, 0.52), Vector2.new(0, 0.5), PALE, 700, false)
	statL.TextXAlignment, statL.ZIndex, statL.RichText = Enum.TextXAlignment.Left, 5, true
	local tipL = text(insp, "", UDim2.fromScale(0.78, 0.2), UDim2.fromScale(0.19, 0.83), Vector2.new(0, 0.5), Color3.fromRGB(170, 156, 206), 700, false) -- under the button too: at a phone's 2.16:1 the tip ran out of a narrower box
	tipL.TextXAlignment, tipL.ZIndex, tipL.TextWrapped = Enum.TextXAlignment.Left, 5, true
	for _, l in { nameL, statL, tipL } do new("UITextSizeConstraint", l, { MinTextSize = 14 }) end
	local buy = button(insp, "", UDim2.fromScale(0.2, 0.5), UDim2.fromScale(0.875, 0.38), MID, "mint")
	buy.Name, buy.ZIndex = "Invest", 5
	buy.Label.ZIndex = 6
	buy.Activated:Connect(function() SoulR:FireServer("buy", pick) end)

	function M.refresh()
		count.Text = tostring(soul.shards)
		for id, fig in figs do
			local look, def = fig.look, T.nodes[id]
			local rank = soul.nodes[id] or 0
			local full = rank >= def.max
			local chosen = id == pick
			for k, s in fig.ranks do paintStar(s, look.tint, k <= rank, chosen) end
			for _, s in fig.deco do paintStar(s, look.tint, full, chosen) end
			fig.branch.f.BackgroundColor3, fig.branch.f.BackgroundTransparency = rank > 0 and look.tint or LINE_OFF, rank > 0 and 0.15 or 0.35
			fig.branch.g.BackgroundColor3, fig.branch.g.BackgroundTransparency = look.tint, rank > 0 and 0.7 or 1
			for i, l in fig.links do -- a rank line lights when both its stars are lit; the outline lights when the figure is full
				local la, lb = look.links[i][1], look.links[i][2]
				local function lit(n) return (n:sub(1, 1) == "r" and tonumber(n:sub(2)) <= rank) or (n:sub(1, 1) == "d" and full) end
				local on = lit(la) and lit(lb)
				l.f.BackgroundColor3, l.f.BackgroundTransparency = on and look.tint or LINE_OFF, on and 0.2 or (chosen and 0.3 or 0.5)
				l.g.BackgroundColor3, l.g.BackgroundTransparency = look.tint, on and 0.72 or 1
			end
			fig.crown.Visible = full
			fig.ring.Transparency = chosen and 0.15 or 1
		end
		-- the inspector
		local look, def = LOOK[pick], T.nodes[pick]
		local rank = soul.nodes[pick] or 0
		local full = rank >= def.max
		local cost = def.cost[rank + 1]
		nameL.Text = string.upper(def.name)
		nameL.TextColor3 = look.tint:Lerp(WHITE, 0.55)
		stateL.Text = full and "FULL" or (rank > 0 and "ACTIVE" or "DORMANT")
		pillState.BackgroundColor3 = full and Color3.fromRGB(150, 110, 30) or (rank > 0 and Color3.fromRGB(34, 110, 80) or Color3.fromRGB(60, 48, 90))
		rankL.Text = "RANK " .. rank .. " / " .. def.max
		local unit = def.unit or ""
		local gold = "<font color=\"#FFD66B\">"
		statL.Text = full and ("Now " .. gold .. rank * def.each .. unit .. "</font>  (full)")
			or ("Now " .. (rank > 0 and (rank * def.each .. unit) or "nothing") .. "   \u{2192}   Next " .. gold .. (rank + 1) * def.each .. unit .. "</font>")
		tipL.Text = (not full and cost and soul.shards < cost) and ("Need " .. (cost - soul.shards) .. " more: flare gloomlings for shards.") or look.tip
		inspEdge.Color, crestEdge.Color = look.tint:Lerp(GOLD, 0.5), look.tint
		if full or not cost then
			buy.Text = "FULL"
			E.setKind(buy, "off")
		else
			buy.Text = "INVEST " .. cost .. (cost == 1 and " SHARD" or " SHARDS")
			E.setKind(buy, soul.shards >= cost and "mint" or "off")
		end
		local shown = false
		if crest and Crests then shown = pcall(function() crest.set(Crests.model(pick), look.tint) end) end
		crestIcon.Image, crestIcon.Visible = look.icon, not shown
	end
	local function take(s)
		if type(s) == "table" and type(s.soul) == "table" then
			soul = { shards = s.soul.shards or 0, nodes = s.soul.nodes or {} }
			if win.Visible then M.refresh() end
		end
	end
	R.State.OnClientEvent:Connect(take)

	local drift
	local function open()
		if win.Visible or (E.isBusy and E.isBusy()) then return end
		SoulR:FireServer("sync")
		for _, id in T.order do -- open on the first node that can still grow
			if (soul.nodes[id] or 0) < T.nodes[id].max then pick = id break end
		end
		M.refresh()
		E.openPanel(win)
		E.sfx("sparkle", 0.9)
		task.defer(layout)
		if drift then drift:Disconnect() end
		local t0 = os.clock()
		drift = RunService.Heartbeat:Connect(function() -- the stars drift and twinkle only while the panel is up
			if not win.Visible then drift:Disconnect() drift = nil return end
			local t = os.clock() - t0
			far.Position = UDim2.fromScale(-((t * 0.006) % 1), 0)
			near.Position = UDim2.fromScale(-((t * 0.014) % 1), 0)
			for _, s in twinkle do
				local v = math.clamp(s[3] + math.sin(t * s[5] + s[4]) * 0.22, 0, 0.95)
				s[1].BackgroundTransparency, s[2].BackgroundTransparency = v, v
			end
			local pulse = 0.55 + math.sin(t * 2.4) * 0.08 -- the core breathes
			core.halo.BackgroundTransparency = pulse
			local f = figs[pick]
			if f then f.ring.Transparency = 0.1 + (math.sin(t * 4) + 1) * 0.18 end -- the picked constellation's ring pulses
		end)
	end
	close.Activated:Connect(function() if win.Visible then E.closePanel(win) end end)
	plr:GetAttributeChangedSignal("DevOpen"):Connect(function() if plr:GetAttribute("DevOpen") == "soul" and game:GetService("RunService"):IsStudio() then open() end end) -- Studio test hook (spike/p1_shots.py)
	plr:GetAttributeChangedSignal("DevSoulPick"):Connect(function() -- Studio test hook: pick a node in the open panel (spike/soul_test.py)
		local id = plr:GetAttribute("DevSoulPick")
		if id and figs[id] and game:GetService("RunService"):IsStudio() then pick = id M.refresh() end
	end)
	game:GetService("ProximityPromptService").PromptTriggered:Connect(function(prompt)
		if prompt:GetAttribute("SoulTree") then open() end
	end)
	R.Fx.OnClientEvent:Connect(function(kind, a, b)
		if kind == "soulShard" then
			E.toast("+" .. tostring(a) .. " Gloom Shard" .. (a == 1 and "" or "s") .. "  (" .. tostring(b) .. ")", nil, false, 2.5)
			pcall(E.sfx, "sparkle", 1.4)
		elseif kind == "soulBought" and figs[a] then
			pcall(E.sfx, "upgrade", 1)
			pick = a
			task.delay(0.15, function() -- the star the rank lit pops once the new state has arrived
				local fig = figs[a]
				local rank = soul.nodes[a] or 0
				local s = fig and fig.ranks[math.max(1, rank)]
				if s then pcall(E.pop, s.holder) end
			end)
			if E.vmHook.emote then E.vmHook.emote("cheer") end
		elseif kind == "soulNo" then
			pcall(E.sfx, "error", 1)
		end
	end)
end

return M
