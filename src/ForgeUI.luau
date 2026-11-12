-- ForgeUI (ReplicatedStorage.Shared.ForgeUI), started by PixelClient with the helpers it needs (moved out 2026-11-09: PixelClient
-- reached Roblox's 200,000-character Source limit). Forge v2 (2026-11-08; board Forge2 artboard): the user's Delve forge video for the structure (art/forge/refs), two ChatGPT
-- concepts in our soft kit (art/forge/concepts) for the look, reward clips from Pinterest (art/forge/refs/motion) for the motion.
-- Category tabs, a grid of gear cards with rarity rims, a detail card with before/after stats, the level track and the actions.
-- Coins buy the next pickaxe, gems level an owned one, any owned pickaxe can be held; the server checks every action.
-- Its own function: the main chunk is at Luau's 200-register limit.
local M = {}
function M.start(E)
	local RS, UIS, RunService, C, R, cam, tween, commas = E.RS, E.UIS, E.RunService, E.C, E.R, E.cam, E.tween, E.commas
	local DEEP, SPRITE, ICON, INK, WHITE, MINT, PINK, LILAC = E.DEEP, E.SPRITE, E.ICON, E.INK, E.WHITE, E.MINT, E.PINK, E.LILAC
	local BUTTER, SKY, gui, new, S, fit, text, panel = E.BUTTER, E.SKY, E.gui, E.new, E.S, E.fit, E.text, E.panel
	local icon, scaler, pop, openPanel, closePanel, sfxClick, button, setKind = E.icon, E.scaler, E.pop, E.openPanel, E.closePanel, E.sfxClick, E.button, E.setKind
	local ribbonTitle, closeButton, forge, forgeUI, toast, sfx, anchor, shake = E.ribbonTitle, E.closeButton, E.forge, E.forgeUI, E.toast, E.sfx, E.anchor, E.shake
	local head, PLUM_SOFT, scrim, fx, burst = E.head, E.PLUM_SOFT, E.scrim, E.fx, E.burst
	local function getState() return E.getState() end -- the State event replaces the table, so read it fresh
	-- forge art per pickaxe model: { full icon, head-focused card crop } (transparent renders, art/forge/icons, ids in asset_ids.json);
	-- a tier without its render yet shows the generic pick icon
	local ART = {
		WoodPickaxe = { 84674903872144, 74345038954875 }, StonePickaxe = { 76950059301165, 103286217212511 },
		StarlightPickaxe = { 132794152773137, 119884085006157 }, MoonlitPickaxe = { 84853376787476, 107875989974673 },
		GalaxyPickaxe = { 89557713111747, 114644891397243 }, RoyalHeartPickaxe = { 113248414659515, 80049267894218 },
		SilverWingPickaxe = { 110656342327557, 135052327149896 },
		CopperPickaxe = { 86517658742403, 76083498097914 }, BogIronPickaxe = { 91548313668205, 138795024880397 },
		RootflintPickaxe = { 130080565379273, 124674813837609 }, AshcoalPickaxe = { 127052936984931, 140040166870114 },
		RootheartPickaxe = { 130047070419141, 76503784350216 }, TitanClayPickaxe = { 120604253045668, 131778715725323 },
	}
	local PICK_ART, CARD_ART = {}, {}
	for i, d in C.PICKS do
		local a = d.model and ART[d.model]
		PICK_ART[i] = a and ("rbxassetid://" .. a[1]) or ICON.pick
		CARD_ART[i] = a and ("rbxassetid://" .. a[2]) or ICON.pick
	end
	local FX_GLOW, FX_RAYS = "rbxassetid://77591933607769", "rbxassetid://98789616938156" -- soft radial glow and feathered rays (art/forge/fx)
	local Lighting = game:GetService("Lighting")
	local DEEP_MINT = Color3.fromRGB(32, 156, 92) -- gains read as bright green
	local function rarityOf(what, i) return C.RARITIES[what == "pick" and C.PICK_RARITY[i] or math.min(i, #C.RARITIES)] end
	local PARCH, CHALK = Color3.fromRGB(243, 230, 196), Color3.fromRGB(255, 250, 235) -- blueprint pass 2026-11-12: plans on parchment, chalk-white lines
	local function tones(col) return col:Lerp(PARCH, 0.8), col:Lerp(INK, 0.18) end -- card fill (a parchment note tinted by rarity), card rim
	local function short(name) return (name:gsub(" Pickaxe", "")) end
	local function shortNum(n) return n >= 1e6 and (string.format("%.1fM", n / 1e6):gsub("%.0M", "M")) or (n >= 1e4 and (math.floor(n / 1e3) .. "K") or commas(n)) end
	local function lvOf(i) return getState() and getState().lv and getState().lv[tostring(i)] or 1 end
	local function hex(c) return string.format("#%02x%02x%02x", c.R * 255, c.G * 255, c.B * 255) end
	local function round(o, r) return new("UICorner", o, { CornerRadius = UDim.new(r or 0.5, 0) }) end
	local function shake(o) -- "not enough": a quick sideways wobble
		local p = o.Position
		for k, dx in { 0.014, -0.011, 0.008, -0.004, 0 } do task.delay(k * 0.05, function() o.Position = p + UDim2.fromScale(dx, 0) end) end
	end
	local function check(parent, size, pos, anchor) -- a mint coin with a white tick drawn from two bars
		local c = new("Frame", parent, { Name = "Check", Size = size, Position = pos, AnchorPoint = anchor, BackgroundColor3 = MINT, BorderSizePixel = 0, ZIndex = 5 })
		new("UIAspectRatioConstraint", c, { AspectRatio = 1 })
		round(c)
		new("UIStroke", c, { Color = DEEP_MINT, Thickness = 2 })
		for _, b in { { 0.16, 0.36, 0.36, 0.6, -45 }, { 0.16, 0.62, 0.6, 0.48, 40 } } do
			round(new("Frame", c, { Size = UDim2.fromScale(b[1], b[2]), Position = UDim2.fromScale(b[3], b[4]), AnchorPoint = Vector2.new(0.5, 0.5), Rotation = b[5], BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 6 }))
		end
		return c
	end
	local tab, selBy, cards, tabBtn, pageBy = "pick", {}, {}, {}, {}
	local pager, pagerT, refreshPage -- the page pill under the grid (set below)

	-- frame: ribbon, close, coin and gem pills
	local ribbon = ribbonTitle(forge, "FORGE", "ribbonPink", 0.3)
	for _, x in { 0.17, 0.83 } do
		new("ImageLabel", ribbon, { Name = "Star", BackgroundTransparency = 1, Image = SPRITE.star, Size = UDim2.fromScale(0.13, 0.62), Position = UDim2.fromScale(x, 0.4), AnchorPoint = Vector2.new(0.5, 0.5), ScaleType = Enum.ScaleType.Fit, ZIndex = 5 })
	end
	local closeBtn = closeButton(forge, "Close")
	closeBtn.Position = UDim2.fromScale(0.978, 0.06)
	local function pill(x, w, iconName, color)
		local p = panel(forge, UDim2.fromScale(w, 0.095), UDim2.fromScale(x, 0.085), Vector2.new(0, 0.5), iconName == "gem" and "pillPink" or "pillButter")
		local ic = icon(p, iconName, UDim2.fromScale(0.3, 0.8), UDim2.fromScale(0.05, 0.5), Vector2.new(0, 0.5))
		new("UIAspectRatioConstraint", ic, { AspectRatio = 1, DominantAxis = Enum.DominantAxis.Height })
		local t = text(p, "0", UDim2.fromScale(0.56, 0.7), UDim2.fromScale(0.4, 0.5), Vector2.new(0, 0.5), color, 700, false)
		t.Font = Enum.Font.Bangers
		t.TextXAlignment = Enum.TextXAlignment.Left
		return p, t
	end
	local coinP, coinT = pill(0.67, 0.15, "coin", Color3.fromRGB(59, 36, 22))
	local gemP, gemT = pill(0.83, 0.12, "gem", Color3.fromRGB(140, 30, 62))

	-- left: category tabs
	for i, t in { { "pick", "PICKAXES", "pick" }, { "pack", "BACKPACKS", "bag" }, { "charm", "CHARMS", "star" } } do
		local b = button(forge, t[2], UDim2.fromScale(0.175, 0.15), UDim2.fromScale(0.025, 0.2 + (i - 1) * 0.18), nil, "lilac", t[3])
		b.Name = "Tab" .. t[2]
		tabBtn[t[1]] = b
		if t[1] == "charm" then
			local l = icon(b, "lock", UDim2.fromScale(0.2, 0.46), UDim2.fromScale(0.95, 0.12), Vector2.new(0.5, 0.5))
			new("UIAspectRatioConstraint", l, { AspectRatio = 1, DominantAxis = Enum.DominantAxis.Height })
			l.ZIndex = 4
		end
	end

	-- middle: the gear grid (4 x 3), one card per tier
	local tray = panel(forge, UDim2.fromScale(0.44, 0.78), UDim2.fromScale(0.215, 0.17), nil, "slot")
	tray.Name = "Grid"
	tray.Skin.Visible = false -- the plans lie straight on the blueprint, inside a chalk frame
	round(tray, 0.03)
	new("UIStroke", tray, { Color = CHALK, Thickness = 2, Transparency = 0.35 })
	for i = 1, 12 do
		local col, row = (i - 1) % 4, (i - 1) // 4
		local b = new("TextButton", tray, {
			Name = "Card" .. i, Text = "", AutoButtonColor = false, BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromScale(0.215, 0.29), Position = UDim2.fromScale(0.035 + (col + 0.5) * 0.2325, 0.04 + (row + 0.5) * 0.3133), ZIndex = 2,
		})
		round(new("Frame", b, { Name = "Shadow", Size = UDim2.fromScale(1, 1), Position = UDim2.new(0.5, 0, 0.5, 5), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Color3.fromRGB(12, 28, 74), BackgroundTransparency = 0.55, BorderSizePixel = 0, ZIndex = 2 }), 0.14)
		local face = new("Frame", b, { Name = "Face", Size = UDim2.fromScale(1, 1), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), BorderSizePixel = 0, ZIndex = 3 })
		round(face, 0.14)
		local rim = new("UIStroke", face, { ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Thickness = 3 })
		new("UIGradient", face, { Rotation = 90, Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)), ColorSequenceKeypoint.new(0.55, Color3.fromRGB(250, 244, 230)), ColorSequenceKeypoint.new(1, Color3.fromRGB(222, 206, 168)) }) })
		round(new("Frame", face, { Name = "Gloss", Size = UDim2.fromScale(0.86, 0.075), Position = UDim2.fromScale(0.5, 0.03), AnchorPoint = Vector2.new(0.5, 0), BackgroundColor3 = WHITE, BackgroundTransparency = 0.35, BorderSizePixel = 0, ZIndex = 4 }))
		local lip = new("Frame", face, { Name = "Lip", Size = UDim2.fromScale(0.9, 0.06), Position = UDim2.fromScale(0.5, 0.985), AnchorPoint = Vector2.new(0.5, 1), BackgroundTransparency = 0.55, BorderSizePixel = 0, ZIndex = 4 })
		round(lip)
		local glow = new("Frame", b, { Name = "Selected", Size = UDim2.new(1, 10, 1, 10), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, ZIndex = 3, Visible = false })
		round(glow, 0.16)
		new("UIStroke", glow, { Color = WHITE, Thickness = 3 })
		local nm = text(face, "", UDim2.fromScale(0.9, 0.13), UDim2.fromScale(0.5, 0.06), Vector2.new(0.5, 0), INK, 700, false)
		nm.ZIndex = 6
		local art = new("ImageLabel", face, { Name = "Art", BackgroundTransparency = 1, Size = UDim2.fromScale(0.94, 0.7), Position = UDim2.fromScale(0.5, 0.53), AnchorPoint = Vector2.new(0.5, 0.5), ScaleType = Enum.ScaleType.Fit, ZIndex = 5 })
		local lvBox = panel(face, UDim2.fromScale(0.38, 0.17), UDim2.fromScale(0.04, 0.96), Vector2.new(0, 1), "dark")
		lvBox.ZIndex = 6
		local lv = text(lvBox, "LV 1", UDim2.fromScale(0.8, 0.62), UDim2.fromScale(0.5, 0.48), Vector2.new(0.5, 0.5), WHITE, 700, false)
		lv.ZIndex = 7
		local ok = check(face, UDim2.fromScale(0.22, 0.22), UDim2.fromScale(0.95, 0.96), Vector2.new(1, 1))
		ok.ZIndex = 7
		local eq = panel(face, UDim2.fromScale(0.56, 0.17), UDim2.fromScale(0.97, 0.96), Vector2.new(1, 1), "mint")
		eq.Name, eq.ZIndex = "Equipped", 7
		text(eq, "EQUIPPED", UDim2.fromScale(0.86, 0.56), UDim2.fromScale(0.5, 0.46), Vector2.new(0.5, 0.5), WHITE).ZIndex = 8
		local price = panel(face, UDim2.fromScale(0.62, 0.18), UDim2.fromScale(0.96, 0.96), Vector2.new(1, 1), "butter")
		price.ZIndex = 7
		local pic = icon(price, "coin", UDim2.fromScale(0.3, 0.74), UDim2.fromScale(0.07, 0.48), Vector2.new(0, 0.5))
		new("UIAspectRatioConstraint", pic, { AspectRatio = 1, DominantAxis = Enum.DominantAxis.Height })
		pic.ZIndex = 8
		local pt = text(price, "", UDim2.fromScale(0.6, 0.56), UDim2.fromScale(0.62, 0.46), Vector2.new(0.5, 0.5), WHITE)
		pt.ZIndex = 8
		local lock = icon(face, "lock", UDim2.fromScale(0.22, 0.22), UDim2.fromScale(0.5, 0.56), Vector2.new(0.5, 0.5))
		new("UIAspectRatioConstraint", lock, { AspectRatio = 1 })
		lock.ZIndex = 8
		local sc = scaler(b)
		cards[i] = { lip = lip, btn = b, rim = rim, glow = glow, name = nm, art = art, lvBox = lvBox, lv = lv, ok = ok, eq = eq, price = price, priceT = pt, lock = lock, sc = sc }
		b.MouseEnter:Connect(function() if not glow.Visible then tween(sc, 0.12, { Scale = 1.04 }) end end)
		b.MouseLeave:Connect(function() if not glow.Visible then tween(sc, 0.15, { Scale = 1 }) end end)
		b.MouseButton1Down:Connect(function() tween(sc, 0.07, { Scale = 0.94 }) if sfxClick then sfxClick() end end)
		face:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() rim.Thickness = math.max(2, face.AbsoluteSize.Y * 0.03) end)
		cards[i].face = face
	end

	pager = panel(forge, UDim2.fromScale(0.15, 0.07), UDim2.fromScale(0.435, 0.955), Vector2.new(0.5, 0.5), "pillLilac")
	pager.Name, pager.ZIndex = "Pager", 4
	pagerT = text(pager, "1 / 2", UDim2.fromScale(0.4, 0.6), UDim2.fromScale(0.5, 0.46), Vector2.new(0.5, 0.5), INK, 700, false)
	pagerT.ZIndex = 5
	for k, d in { { 0.13, -1, "<" }, { 0.87, 1, ">" } } do
		local b = button(pager, d[3], UDim2.fromScale(0.26, 1.15), UDim2.fromScale(d[1], 0.46), Vector2.new(0.5, 0.5), "lilac")
		b.Name, b.ZIndex = k == 1 and "PagePrev" or "PageNext", 5
		b.Activated:Connect(function()
			local list = tab == "pick" and C.PICKS or C.PACKS
			local pages = math.max(1, math.ceil(#list / 12))
			pageBy[tab] = math.clamp((pageBy[tab] or 1) + d[2], 1, pages)
			refreshPage()
		end)
	end

	-- right: the detail card for the selected tier
	local det = panel(forge, UDim2.fromScale(0.305, 0.78), UDim2.fromScale(0.668, 0.17), nil, "panel")
	det.Name = "Detail"
	det.Skin.Visible = false -- drawn on the blueprint: a chalk frame, a dashed-look circle round the tool and a callout line
	round(det, 0.04)
	new("UIStroke", det, { Color = CHALK, Thickness = 2, Transparency = 0.35 })
	do
		local ring = new("Frame", det, { Name = "PlanRing", Size = UDim2.fromScale(0.62, 0.62), Position = UDim2.fromScale(0.5, 0.235), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, ZIndex = 2 })
		new("UIAspectRatioConstraint", ring, { AspectRatio = 1, DominantAxis = Enum.DominantAxis.Width })
		round(ring)
		new("UIStroke", ring, { Color = CHALK, Thickness = 2, Transparency = 0.45 })
		for _, a in { 0, 90 } do -- centre lines, like a drawn plan
			new("Frame", ring, { Size = UDim2.new(1.16, 0, 0, 1), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), Rotation = a, BackgroundColor3 = CHALK, BackgroundTransparency = 0.7, BorderSizePixel = 0, ZIndex = 2 })
		end
		local stamp = new("Frame", det, { Name = "Stamp", Size = UDim2.fromScale(0.36, 0.058), Position = UDim2.fromScale(0.2, 0.04), AnchorPoint = Vector2.new(0.5, 0.5), Rotation = -6, BackgroundTransparency = 1, ZIndex = 6 })
		new("UIStroke", stamp, { Color = Color3.fromRGB(255, 143, 168), Thickness = 2.5 })
		local st = text(stamp, "BOLT'S PLANS", UDim2.fromScale(0.86, 0.72), UDim2.fromScale(0.5, 0.5), Vector2.new(0.5, 0.5), Color3.fromRGB(255, 143, 168), 700, false)
		st.Font, st.ZIndex = Enum.Font.Bangers, 6
	end
	local stage = new("Frame", det, { Name = "Stage", Size = UDim2.fromScale(0.9, 0.42), Position = UDim2.fromScale(0.5, 0.235), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, ZIndex = 2 })
	local glows = {}
	local rays = new("ImageLabel", stage, { Name = "Rays", Image = FX_RAYS, ImageTransparency = 0.6, BackgroundTransparency = 1, Size = UDim2.fromScale(1.3, 1.3), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 2 })
	new("UIAspectRatioConstraint", rays, { AspectRatio = 1, DominantAxis = Enum.DominantAxis.Height })
	for k, g in { { 1.25, 0.1 }, { 0.7, 0.25 } } do -- a wide soft glow in the rarity colour, a brighter core
		local c = new("ImageLabel", stage, { Image = FX_GLOW, ImageTransparency = g[2], BackgroundTransparency = 1, Size = UDim2.fromScale(g[1], g[1]), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 3 })
		new("UIAspectRatioConstraint", c, { AspectRatio = 1, DominantAxis = Enum.DominantAxis.Height })
		glows[k] = c
	end
	local big = new("ImageLabel", stage, { Name = "Art", BackgroundTransparency = 1, Size = UDim2.fromScale(0.95, 0.95), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), ScaleType = Enum.ScaleType.Fit, ZIndex = 4 })
	local bigSc = scaler(big)
	local twinkles = {}
	for k, p in { { 0.12, 0.2, 0.13 }, { 0.88, 0.32, 0.1 }, { 0.2, 0.82, 0.09 }, { 0.84, 0.86, 0.12 } } do
		local s = new("ImageLabel", stage, { BackgroundTransparency = 1, Image = SPRITE.sparkle, Size = UDim2.fromScale(p[3], p[3]), Position = UDim2.fromScale(p[1], p[2]), AnchorPoint = Vector2.new(0.5, 0.5), ScaleType = Enum.ScaleType.Fit, ZIndex = 5 })
		new("UIAspectRatioConstraint", s, { AspectRatio = 1 })
		twinkles[k] = scaler(s)
	end
	local dName = text(det, "", UDim2.fromScale(0.92, 0.085), UDim2.fromScale(0.5, 0.47), Vector2.new(0.5, 0.5), CHALK, 700, false)
	dName.Font = Enum.Font.Bangers
	local rar = new("Frame", det, { Name = "Rarity", Size = UDim2.fromScale(0.36, 0.062), Position = UDim2.fromScale(0.5, 0.548), AnchorPoint = Vector2.new(0.5, 0.5), BorderSizePixel = 0, ZIndex = 2 })
	round(rar)
	new("UIStroke", rar, { Color = WHITE, Thickness = 2 })
	local rarT = text(rar, "", UDim2.fromScale(0.8, 0.66), UDim2.fromScale(0.5, 0.48), Vector2.new(0.5, 0.5), WHITE)
	rarT.ZIndex = 3
	local rows = {}
	for k = 1, 2 do
		local r = panel(det, UDim2.fromScale(0.92, 0.072), UDim2.fromScale(0.5, 0.62 + (k - 1) * 0.08), Vector2.new(0.5, 0.5), "pill")
		local ic = icon(r, k == 1 and "coin" or "star", UDim2.fromScale(0.1, 0.72), UDim2.fromScale(0.035, 0.5), Vector2.new(0, 0.5))
		new("UIAspectRatioConstraint", ic, { AspectRatio = 1, DominantAxis = Enum.DominantAxis.Height })
		local l = text(r, "", UDim2.fromScale(0.46, 0.68), UDim2.fromScale(0.15, 0.5), Vector2.new(0, 0.5), INK, 700, false) -- 0.68: the stat rows were tiny at phone size
		l.TextXAlignment = Enum.TextXAlignment.Left
		local v = text(r, "", UDim2.fromScale(0.44, 0.68), UDim2.fromScale(0.95, 0.5), Vector2.new(1, 0.5), INK, 700, false)
		v.TextXAlignment, v.RichText = Enum.TextXAlignment.Right, true
		rows[k] = { frame = r, icon = ic, label = l, value = v }
	end
	local oreNeed = text(det, "", UDim2.fromScale(0.9, 0.05), UDim2.fromScale(0.5, 0.77), Vector2.new(0.5, 0.5), INK, 700, false)
	oreNeed.RichText, oreNeed.Name, oreNeed.TextTransparency = true, "OreNeed", 1 -- kept for tests; the chips below draw it
	local chips = new("Frame", det, { Name = "OreChips", Size = UDim2.fromScale(0.92, 0.07), Position = UDim2.fromScale(0.5, 0.77), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, Visible = false, ZIndex = 3 })
	new("UIListLayout", chips, { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0.03, 0) })
	local function drawChips(i)
		for _, c in chips:GetChildren() do if c:IsA("Frame") then c:Destroy() end end
		local need = C.PICK_ORE[i]
		chips.Visible = need ~= nil
		if not need then return end
		local keys = {}
		for k in need do table.insert(keys, k) end
		table.sort(keys)
		local have = getState().ores or {}
		for _, k in keys do
			local h, n = have[k] or 0, need[k]
			local chip = new("Frame", chips, { Size = UDim2.fromScale(0.3, 1), BackgroundColor3 = Color3.fromRGB(255, 250, 243), BorderSizePixel = 0, ZIndex = 3 })
			round(chip)
			new("UIStroke", chip, { Color = h >= n and DEEP_MINT or Color3.fromRGB(242, 139, 130), Thickness = 2 })
			local ic = new("ImageLabel", chip, { Image = C.ORE_ICON[k] or "", BackgroundTransparency = 1, Size = UDim2.fromScale(0.34, 1.3), Position = UDim2.fromScale(0.04, 0.5), AnchorPoint = Vector2.new(0, 0.5), ScaleType = Enum.ScaleType.Fit, ZIndex = 4 })
			new("UIAspectRatioConstraint", ic, { AspectRatio = 1 })
			local t = text(chip, math.min(h, n) .. "/" .. n, UDim2.fromScale(0.56, 0.72), UDim2.fromScale(0.68, 0.5), Vector2.new(0.5, 0.5), h >= n and DEEP_MINT or INK, 700, false) -- dark counts read better than pale red (Gemini)
			t.ZIndex = 4
			chip:SetAttribute("Ore", C.oreName(k))
		end
	end
	local function oreLine(i) -- "NEEDS 6/6 Rootflint  3/4 Ashcoal", short counts in pink; ok = every count is there
		local need = C.PICK_ORE[i]
		if not need then return nil, true end
		local have, parts, ok = getState().ores or {}, {}, true
		local keys = {}
		for k in need do table.insert(keys, k) end
		table.sort(keys)
		for _, k in keys do
			local h, n = have[k] or 0, need[k]
			if h < n then ok = false end
			table.insert(parts, string.format('<font color="%s">%d/%d</font> %s', h >= n and hex(DEEP_MINT) or "#f28b82", math.min(h, n), n, C.oreName(k)))
		end
		return "NEEDS  " .. table.concat(parts, "   "), ok
	end
	local lvLabel = text(det, "", UDim2.fromScale(0.5, 0.038), UDim2.fromScale(0.06, 0.743), nil, CHALK, 700, false)
	lvLabel.TextXAlignment = Enum.TextXAlignment.Left
	local pips = {}
	for k = 1, C.FORGE.maxLv do
		local p = new("Frame", det, { Size = UDim2.fromScale(0.08, 0.032), Position = UDim2.fromScale(0.06 + (k - 1) * 0.0889, 0.788), BorderSizePixel = 0, ZIndex = 2 })
		round(p, 0.45)
		pips[k] = { frame = p, stroke = new("UIStroke", p, { Thickness = 2 }) }
	end
	local act = button(det, "UPGRADE", UDim2.fromScale(0.58, 0.15), UDim2.fromScale(0.05, 0.975), Vector2.new(0, 1), "mint", "gem")
	act.Name = "Action"
	local eqB = button(det, "EQUIP", UDim2.fromScale(0.33, 0.15), UDim2.fromScale(0.95, 0.975), Vector2.new(1, 1), "butter")
	eqB.Name = "Equip"
	-- two lines on the action button: the verb, then the price with its currency (Gemini r3: one line read cramped)
	act.Label.Visible = false
	local actTop = text(act, "", UDim2.fromScale(0.86, 0.4), UDim2.fromScale(0.5, 0.33), Vector2.new(0.5, 0.5), WHITE)
	local actCost = text(act, "", UDim2.fromScale(0.42, 0.32), UDim2.fromScale(0.55, 0.7), Vector2.new(0, 0.5), WHITE)
	actCost.TextXAlignment = Enum.TextXAlignment.Left
	local ai = act:FindFirstChild("Icon")
	ai.Size, ai.Position, ai.AnchorPoint = UDim2.fromScale(0.2, 0.38), UDim2.fromScale(0.52, 0.7), Vector2.new(1, 0.5)
	local function splitAct()
		local a, b = act.Text:match("^(.-)%s%s+(%S+)$")
		actTop.Text, actCost.Text, actCost.Visible = a or act.Text, b or "", b ~= nil
		actTop.Position = b and UDim2.fromScale(0.5, 0.33) or UDim2.fromScale(0.5, 0.48)
		local deep = DEEP[act:GetAttribute("Kind")] or INK
		actTop.TextStrokeColor3, actCost.TextStrokeColor3 = deep, deep
	end
	act:GetPropertyChangedSignal("Text"):Connect(splitAct)
	act:GetAttributeChangedSignal("Kind"):Connect(splitAct)
	splitAct()
	local mode = {} -- what the action button does right now

	local function setRow(k, label, iconName, from, to)
		local r = rows[k]
		r.label.Text, r.icon.Image = label, ICON[iconName]
		r.value.Text = to and to ~= from and (from .. '  <font color="' .. hex(PLUM_SOFT) .. '">></font>  <font color="' .. hex(DEEP_MINT) .. '">' .. to .. " \u{25B2}</font>") or from
	end
	local function val(i, lv) return string.format("x%.1f", C.pickValue(i, lv)) end
	local function zone(lv) return math.floor(C.strikeArc(lv) + 0.5) .. "°" end

	local function detail(i, animate)
		local list = tab == "pick" and C.PICKS or C.PACKS
		local def = list[i]
		if not def or not getState() then return end
		local r = rarityOf(tab, i)
		local fill, rim = tones(r[3])
		glows[1].ImageColor3, glows[2].ImageColor3, rays.ImageColor3 = r[3]:Lerp(WHITE, 0.35), r[3]:Lerp(WHITE, 0.75), r[3]:Lerp(WHITE, 0.55)
		big.Image = tab == "pick" and PICK_ART[i] or ICON.bag
		dName.Text = def.name
		rar.BackgroundColor3, rarT.Text = rim, r[1]:upper()
		local cur = getState()[tab]
		local own, nxt = i <= cur, i == cur + 1
		local eqI = math.clamp(getState().equip or cur, 1, cur)
		local showLv = tab == "pick" and own
		lvLabel.Visible = showLv
		oreNeed.Visible = false
		chips.Visible = false
		for _, p in pips do p.frame.Visible = showLv end
		eqB.Visible = tab == "pick" and own
		act.Size = eqB.Visible and UDim2.fromScale(0.58, 0.15) or UDim2.fromScale(0.9, 0.15)
		local actIcon = act:FindFirstChild("Icon")
		if tab == "pick" then
			local lv = own and lvOf(i) or 1
			if own then
				local maxed = lv >= C.FORGE.maxLv
				setRow(1, "Ore Value", "coin", val(i, lv), not maxed and val(i, lv + 1) or nil)
				setRow(2, "Strike Zone", "star", zone(lv), not maxed and zone(lv + 1) or nil)
				lvLabel.Text = "LV " .. lv .. " / " .. C.FORGE.maxLv
				for k, p in pips do
					p.frame.BackgroundColor3 = k <= lv and BUTTER or Color3.fromRGB(30, 62, 140)
					p.stroke.Color = k <= lv and Color3.fromRGB(196, 138, 46) or CHALK
				end
				local cost = C.upgradeCost(i, lv)
				mode = { kind = cost and "upgrade" or "none", cost = cost }
				act.Text = cost and ("UPGRADE  " .. cost) or "MAX LEVEL"
				setKind(act, cost and ((getState().gems or 0) >= cost and "mint" or "off") or "off")
				if actIcon then actIcon.Image, actIcon.Visible = ICON.gem, cost ~= nil end
				eqB.Text = i == eqI and "EQUIPPED" or "EQUIP"
				setKind(eqB, i == eqI and "off" or "butter")
			else
				setRow(1, "Ore Value", "coin", val(eqI, lvOf(eqI)), val(i, 1))
				setRow(2, "Strike Zone", "star", zone(lvOf(eqI)), zone(1))
				local line, oreOk = oreLine(i)
				mode = nxt and { kind = oreOk and "buy" or "needOre", cost = def.cost } or { kind = "none" }
				act.Text = nxt and (oreOk and ("BUY  " .. shortNum(def.cost)) or "NEED ORE") or ("BUY " .. short(list[cur + 1] and list[cur + 1].name or "") .. " FIRST"):upper()
				setKind(act, nxt and oreOk and (getState().gold >= def.cost and "mint" or "off") or "off")
				if actIcon then actIcon.Image, actIcon.Visible = ICON.coin, nxt and oreOk end
				oreNeed.Text, oreNeed.Visible = line or "", line ~= nil
				if nxt then drawChips(i) end
			end
		else
			setRow(1, "Bag Space", "bag", tostring(list[cur].cap), not own and tostring(def.cap) or nil)
			setRow(2, "In the caves", "star", "no limit")
			mode = nxt and { kind = "buy", cost = def.cost } or { kind = "none" }
			act.Text = own and "OWNED" or (nxt and ("BUY  " .. shortNum(def.cost)) or "LOCKED")
			setKind(act, nxt and (getState().gold >= def.cost and "mint" or "off") or "off")
			if actIcon then actIcon.Image, actIcon.Visible = ICON.coin, nxt end
		end
		if animate then -- the new item pops onto the stage
			bigSc.Scale = 0.55
			tween(bigSc, 0.4, { Scale = 1 }, Enum.EasingStyle.Back)
			for _, g in glows do
				local s = scaler(g)
				s.Scale = 0.6
				tween(s, 0.45, { Scale = 1 }, Enum.EasingStyle.Back)
			end
		end
	end

	local function refresh(animate)
		local flip = animate == "page" -- a page turn: stagger the cards, keep the chosen page
		if flip then animate = true end
		if not getState() then return end
		coinT.Text, gemT.Text = commas(getState().gold), commas(getState().gems or 0)
		for key, b in tabBtn do setKind(b, key == tab and "butter" or (key == "charm" and "off" or "lilac")) end
		local list = tab == "pick" and C.PICKS or C.PACKS
		local cur = getState()[tab]
		local eqI = tab == "pick" and math.clamp(getState().equip or cur, 1, cur) or cur
		local sel = math.min(selBy[tab] or eqI, #list)
		selBy[tab] = sel
		local pages = math.max(1, math.ceil(#list / 12))
		if (animate and not flip) or not pageBy[tab] then pageBy[tab] = math.ceil(sel / 12) end -- open on the page of the selected tier
		pageBy[tab] = math.clamp(pageBy[tab], 1, pages)
		pager.Visible = pages > 1
		pagerT.Text = pageBy[tab] .. " / " .. pages
		local base = (pageBy[tab] - 1) * 12
		for slot, cd in cards do
			local i = base + slot
			cd.tier = i
			local def = list[i]
			cd.btn.Visible = def ~= nil
			if def then
				local fill, rim = tones(rarityOf(tab, i)[3])
				cd.face.BackgroundColor3, cd.rim.Color, cd.lip.BackgroundColor3 = fill, rim, rim
				cd.name.Text = short(def.name) -- mixed case: capitals crowded the tile edges (Gemini UI review, 2026-11-10)
				cd.art.Image = tab == "pick" and (CARD_ART[i] or PICK_ART[i]) or ICON.bag
				local own, nxt = i <= cur, i == cur + 1
				cd.art.ImageColor3 = (own or nxt) and WHITE or rim:Lerp(WHITE, 0.25)
				cd.art.ImageTransparency = (own or nxt) and 0 or 0.35
				cd.lvBox.Visible = own
				cd.lv.Text = tab == "pick" and ("LV " .. lvOf(i)) or (def.cap .. " ORE")
				cd.ok.Visible = own and not (tab == "pick" and i == eqI)
				cd.eq.Visible = tab == "pick" and own and i == eqI
				if cd.eq.Visible then cd.rim.Color = Color3.fromRGB(63, 186, 140) end
				cd.price.Visible = nxt
				cd.priceT.Text = shortNum(def.cost)
				cd.lock.Visible = not own and not nxt
				cd.glow.Visible = i == sel
				if animate then
					cd.sc.Scale = 0.4
					task.delay(slot * 0.035, function() tween(cd.sc, 0.32, { Scale = i == sel and 1.06 or 1 }, Enum.EasingStyle.Back) end)
				else
					tween(cd.sc, 0.2, { Scale = i == sel and 1.06 or 1 }, Enum.EasingStyle.Back)
				end
			end
		end
		detail(sel, animate)
	end

	refreshPage = function() refresh("page") end

	-- the world blurs behind the open forge
	local blur = new("BlurEffect", cam, { Name = "ForgeBlur", Size = 0 })
	local BLUR = UIS.TouchEnabled and 10 or 12
	workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function() blur.Parent = workspace.CurrentCamera end)
	local spin
	local function open()
		tab = tab == "charm" and "pick" or tab
		refresh(true)
		openPanel(forge)
		det.Position = UDim2.fromScale(0.7, 0.17)
		tween(det, 0.4, { Position = UDim2.fromScale(0.668, 0.17) }, Enum.EasingStyle.Quint)
		tween(blur, 0.3, { Size = BLUR })
		if spin then spin:Disconnect() end
		spin = RunService.RenderStepped:Connect(function()
			local t = os.clock()
			rays.Rotation = t * 14 % 360
			for k, s in twinkles do s.Scale = 0.55 + 0.45 * math.abs(math.sin(t * 2 + k * 1.3)) end
		end)
	end
	local function close()
		closePanel(forge)
		tween(blur, 0.2, { Size = 0 })
		if spin then spin:Disconnect() spin = nil end
	end
	forgeUI.open, forgeUI.close = open, close
	forgeUI.toggle = function() if forge.Visible then close() else open() end end
	forgeUI.refresh = function() if forge.Visible then refresh(false) end end
	closeBtn.Activated:Connect(close)

	for key, b in tabBtn do
		b.Activated:Connect(function()
			if key == "charm" then
				shake(b)
				toast("CHARMS ARE COMING SOON", LILAC)
				return
			end
			if tab ~= key then
				tab = key
				refresh(true)
			end
		end)
	end
	for _, cd in cards do
		cd.btn.Activated:Connect(function()
			local i = cd.tier
			if selBy[tab] ~= i then
				selBy[tab] = i
				refresh(false)
				detail(i, true)
			else
				tween(cd.sc, 0.3, { Scale = 1.06 }, Enum.EasingStyle.Back)
			end
		end)
	end
	act.Activated:Connect(function()
		local i = selBy[tab]
		if mode.kind == "buy" then
			if getState().gold < mode.cost then shake(act) pop(coinP, 1.2) toast("NOT ENOUGH COINS", PINK) return end
			R.Buy:FireServer(tab)
		elseif mode.kind == "needOre" then
			shake(act)
			toast("MINE MORE ORE FIRST: BANK IT AT CAMP", PINK)
		elseif mode.kind == "upgrade" then
			if (getState().gems or 0) < mode.cost then shake(act) pop(gemP, 1.2) toast("NOT ENOUGH GEMS", PINK) return end
			R.Buy:FireServer("upgrade", i)
		else
			shake(act)
		end
	end)
	eqB.Activated:Connect(function()
		local i = selBy[tab]
		if tab == "pick" and getState() and i <= getState().pick and i ~= getState().equip then R.Buy:FireServer("equip", i) end
	end)

	-- LEVEL UP / NEW PICKAXE celebration (concept forge_concept_b; motion from the badge and level-up clips): the scrim fades in,
	-- light rays and the item pop, the title ribbon drops, confetti falls, the level ribbon unfurls, the stats count up, NICE! pops.
	local celGui = new("ScreenGui", gui.Parent, { Name = "ForgeCelebrate", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 11, ZIndexBehavior = Enum.ZIndexBehavior.Sibling })
	local cel = new("Frame", celGui, { Name = "Stage", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(26, 18, 40), BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false, ZIndex = 20, Active = true }) -- Active: clicks never fall through to the forge
	local cRays = new("Frame", cel, { Size = S(640, 640), Position = S(640, 250), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, ZIndex = 20 })
	new("UIAspectRatioConstraint", cRays, { AspectRatio = 1, DominantAxis = Enum.DominantAxis.Height })
	local cRaysA = new("ImageLabel", cRays, { Image = FX_RAYS, ImageColor3 = Color3.fromRGB(255, 196, 228), BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 20 })
	local cRaysB = new("ImageLabel", cRays, { Image = FX_RAYS, ImageColor3 = Color3.fromRGB(255, 232, 160), ImageTransparency = 0.3, BackgroundTransparency = 1, Size = UDim2.fromScale(0.8, 0.8), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), Rotation = 15, ZIndex = 20 })
	local cGlow = new("Frame", cel, { Size = S(340, 340), Position = S(640, 250), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, ZIndex = 21 })
	new("UIAspectRatioConstraint", cGlow, { AspectRatio = 1, DominantAxis = Enum.DominantAxis.Height })
	for _, g in { { 1.5, 0.15, PINK }, { 0.95, 0.1, Color3.fromRGB(255, 220, 240) }, { 0.5, 0, WHITE } } do -- a soft radial burst
		new("ImageLabel", cGlow, { Image = FX_GLOW, ImageColor3 = g[3], ImageTransparency = g[2], BackgroundTransparency = 1, Size = UDim2.fromScale(g[1], g[1]), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 21 })
	end
	local cArt = new("ImageLabel", cel, { BackgroundTransparency = 1, Size = S(340, 340), Position = S(640, 252), AnchorPoint = Vector2.new(0.5, 0.5), ScaleType = Enum.ScaleType.Fit, ZIndex = 22 })
	new("UIAspectRatioConstraint", cArt, { AspectRatio = 1, DominantAxis = Enum.DominantAxis.Height })
	local cTitle = panel(cel, S(470, 92), S(640, 62), Vector2.new(0.5, 0.5), "ribbonPink")
	fit(cTitle, 470, 92)
	cTitle.ZIndex = 23
	local cTitleT = text(cTitle, "LEVEL UP!", UDim2.fromScale(0.62, 0.52), UDim2.fromScale(0.5, 0.42), Vector2.new(0.5, 0.5), WHITE)
	cTitleT.TextStrokeColor3, cTitleT.ZIndex = DEEP.ribbonPink, 24
	local cLv = panel(cel, S(320, 58), S(640, 420), Vector2.new(0.5, 0.5), "ribbonLilac")
	fit(cLv, 320, 58)
	cLv.ZIndex = 23
	local cLvT = text(cLv, "", UDim2.fromScale(0.62, 0.52), UDim2.fromScale(0.5, 0.42), Vector2.new(0.5, 0.5), WHITE)
	cLvT.TextStrokeColor3, cLvT.ZIndex = DEEP.ribbonLilac, 24
	local cStats = panel(cel, S(440, 92), S(640, 494), Vector2.new(0.5, 0.5), "panel")
	fit(cStats, 440, 92)
	cStats.ZIndex = 23
	local cRows = {}
	for k = 1, 2 do -- an icon medallion, then the change
		local m = new("Frame", cStats, { Size = UDim2.fromScale(0.09, 0.36), Position = UDim2.fromScale(0.1, 0.3 + (k - 1) * 0.38), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = k == 1 and BUTTER or PINK, BorderSizePixel = 0, ZIndex = 24 })
		new("UIAspectRatioConstraint", m, { AspectRatio = 1 })
		round(m)
		new("UIStroke", m, { Color = k == 1 and Color3.fromRGB(196, 138, 46) or DEEP.pink, Thickness = 2 })
		icon(m, k == 1 and "coin" or "star", UDim2.fromScale(0.8, 0.8), UDim2.fromScale(0.5, 0.5), Vector2.new(0.5, 0.5)).ZIndex = 25
		local t = text(cStats, "", UDim2.fromScale(0.76, 0.3), UDim2.fromScale(0.55, 0.3 + (k - 1) * 0.38), Vector2.new(0.5, 0.5), INK, 700, false)
		t.RichText, t.ZIndex = true, 24
		cRows[k] = { text = t, medal = m }
	end
	local cNice = button(cel, "NICE!", S(220, 64), S(640, 566), Vector2.new(0.5, 0.5), "mint")
	fit(cNice, 220, 64)
	cNice.ZIndex = 23
	local cSpin
	local function confetti()
		for k = 1, 46 do
			local c = new("Frame", cel, {
				Size = S(10 + math.random(0, 8), 6 + math.random(0, 6)), Position = UDim2.fromScale(math.random(), -0.05 - math.random() * 0.2),
				Rotation = math.random(0, 360), BackgroundColor3 = ({ MINT, PINK, LILAC, BUTTER, SKY })[k % 5 + 1], BorderSizePixel = 0, ZIndex = 25,
			})
			round(c, 0.3)
			local t = 1.6 + math.random() * 1.4
			tween(c, t, { Position = UDim2.fromScale(c.Position.X.Scale + (math.random() - 0.5) * 0.2, 1.05), Rotation = c.Rotation + math.random(-540, 540) }, Enum.EasingStyle.Sine, Enum.EasingDirection.In)
			task.delay(t, function() c:Destroy() end)
		end
	end
	local function celebrate(title, art, lvText, row1, row2)
		cTitleT.Text, cArt.Image, cLvT.Text = title, art, lvText
		cLv.Visible = lvText ~= nil
		for k, r in { row1, row2 } do cRows[k].text.Text, cRows[k].medal.Visible = r or "", r ~= nil end
		cRows[2].text.Text, cRows[2].medal.Visible = row2 or "", row2 ~= nil
		cel.Visible, cel.BackgroundTransparency = true, 1
		tween(cel, 0.25, { BackgroundTransparency = 0.14 })
		for _, o in { cRays, cGlow, cArt, cTitle, cLv, cStats, cNice } do scaler(o).Scale = 0.6 end
		for _, o in { cTitle, cLv, cStats, cNice } do o.Visible = false end
		tween(scaler(cRays), 0.5, { Scale = 1 }, Enum.EasingStyle.Back)
		tween(scaler(cGlow), 0.4, { Scale = 1 }, Enum.EasingStyle.Back)
		task.delay(0.1, function()
			sfx("upgrade")
			local s = scaler(cArt)
			tween(s, 0.25, { Scale = 1.18 }, Enum.EasingStyle.Quad).Completed:Connect(function() tween(s, 0.3, { Scale = 1 }, Enum.EasingStyle.Back) end)
		end)
		task.delay(0.3, function()
			cTitle.Visible, cTitle.Position = true, S(640, 62)
			scaler(cTitle).Scale = 1.4
			tween(scaler(cTitle), 0.18, { Scale = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In) -- the slam
			confetti()
			sfx("sparkle", 1.1)
		end)
		task.delay(0.55, function() -- the level ribbon unfurls sideways
			local s = scaler(cLv)
			s.Scale, cLv.Visible = 1, lvText ~= nil
			cLv.Size = S(60, 58)
			tween(cLv, 0.35, { Size = S(320, 58) }, Enum.EasingStyle.Back)
		end)
		task.delay(0.75, function()
			cStats.Visible, cStats.Position = true, S(640, 520)
			tween(cStats, 0.35, { Position = S(640, 494) }, Enum.EasingStyle.Quint)
			tween(scaler(cStats), 0.3, { Scale = 1 }, Enum.EasingStyle.Back)
			sfx("coin", 1.2)
		end)
		task.delay(1.1, function() cNice.Visible = true tween(scaler(cNice), 0.3, { Scale = 1 }, Enum.EasingStyle.Back) end)
		if cSpin then cSpin:Disconnect() end
		cSpin = RunService.RenderStepped:Connect(function()
			cRaysA.Rotation = os.clock() * 16 % 360
			cRaysB.Rotation = -os.clock() * 10 % 360
		end)
	end
	cNice.Activated:Connect(function()
		tween(cel, 0.2, { BackgroundTransparency = 1 })
		for _, o in { cRays, cGlow, cArt, cTitle, cLv, cStats, cNice } do tween(scaler(o), 0.18, { Scale = 0 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In) end
		task.delay(0.22, function()
			cel.Visible = false
			if cSpin then cSpin:Disconnect() cSpin = nil end
		end)
	end)
	local function row(label, a, b) return label .. "  " .. a .. '  <font color="' .. hex(PLUM_SOFT) .. '">></font>  <font color="' .. hex(DEEP_MINT) .. '">' .. b .. " \u{25B2}</font>" end
	forgeUI.fx = function(kind, a, b)
		if kind == "upgraded" then -- a = tier, b = new level: a quick anvil scene (ForgeCutscene, opt.quick), then the overlay
			local function show() celebrate("LEVEL UP!", PICK_ART[a] or ICON.pick, "LV " .. (b - 1) .. "  >  LV " .. b, row("Ore Value", val(a, b - 1), val(a, b)), row("Strike Zone", zone(b - 1), zone(b))) end
			local fc = RS.Shared:FindFirstChild("ForgeCutscene")
			if fc and C.PICKS[a] then
				task.spawn(function()
					local r = rarityOf("pick", a)
					local ok, err = pcall(function() require(fc).play({ name = C.PICKS[a].name, model = C.PICKS[a].model, rarity = { "LEVEL " .. b, r[2], r[3] }, sfx = sfx, quick = true }) end)
					if not ok then warn("[ForgeCutscene] " .. tostring(err)) end
					show()
				end)
			else
				show()
			end
		elseif kind == "bought" then -- a = name, b = "pick" or "pack"; the Fx arrives before the new state
			local list, i = b == "pick" and C.PICKS or C.PACKS, 1
			for k, d in list do if d.name == a then i = k end end
			local was = math.max(i - 1, 1)
			if b == "pick" then -- the forging cutscene first (ReplicatedStorage.Shared.ForgeCutscene), then the overlay
				local function show() celebrate("NEW PICKAXE!", PICK_ART[i] or ICON.pick, short(a):upper(), row("Ore Value", val(was, lvOf(was)), val(i, 1)), "Equipped and ready to dig") end
				local fc = RS.Shared:FindFirstChild("ForgeCutscene")
				if fc and C.PICKS[i] then
					task.spawn(function()
						local ok, err = pcall(function() require(fc).play({ name = a, model = C.PICKS[i].model, rarity = rarityOf("pick", i), sfx = sfx }) end)
						if not ok then warn("[ForgeCutscene] " .. tostring(err)) end
						show()
					end)
				else
					show()
				end
			else
				celebrate("NEW BACKPACK!", ICON.bag, a:upper(), row("Bag Space", tostring(list[was].cap), tostring(list[i].cap)), nil)
			end
			selBy[b] = i
		elseif kind == "equipped" then
			local cd
			for _, c in cards do if c.tier == a then cd = c end end
			if cd and tab == "pick" then
				task.defer(function() pop(cd.eq, 1.5, 0.35) end)
			end
			sfx("sparkle", 1.3)
		end
		if forge.Visible then refresh(false) end
	end
end

return M
