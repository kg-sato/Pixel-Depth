-- InventoryUI (ReplicatedStorage.Shared.InventoryUI), started by PixelClient: the backpack as an inventory (playtest 2, the user
-- 2026-11-09; boards PT2_Inventory, PT2_Sell and PT2_VFX). The top-left BAG bar became an inventory button (top right) with a
-- count badge; the panel has BAG, BANK and ITEMS tabs. Over capacity you keep mining but walk slower (the user's pick: "Slower
-- when overfull"). Selling happens at Bolt: his SELL prompt and the old sell stall open the BANK tab in sell mode, where you pick
-- stacks or SELECT ALL; nothing is locked (the user: "make nothing locked so players have more freedom"). The server checks
-- every pick (PixelServer, SellPick) and pays.
local M = {}

function M.start(E)
	local C, R, plr, gui, new, S, fit, text, panel, button, setKind = E.C, E.R, E.plr, E.gui, E.new, E.S, E.fit, E.text, E.panel, E.button, E.setKind
	local openPanel, closePanel, ribbonTitle, closeButton, toast, sfx, pop, tween, commas = E.openPanel, E.closePanel, E.ribbonTitle, E.closeButton, E.toast, E.sfx, E.pop, E.tween, E.commas
	local INK, WHITE, MINT, PINK, BUTTER, GOLD = E.INK, E.WHITE, E.MINT, E.PINK, E.BUTTER, E.GOLD
	local bagPill, goldPill, isBusy, burst = E.bagPill, E.goldPill, E.isBusy, E.burst
	local SellPickR = R:WaitForChild("SellPick")
	local MUTED, CORAL, DEEP_GOLD = Color3.fromRGB(58, 34, 82), Color3.fromRGB(224, 96, 110), Color3.fromRGB(184, 122, 26)
	local HEAVY = 0.75 -- walk speed share over capacity
	local st -- the latest state from the server
	local ui = { tab = "bag", sell = false, picks = {}, slots = {} }

	bagPill.Visible = false -- the BAG bar is now the inventory (the user: "the bag should be another section of the setting / inventory")

	-- the inventory button (left column, where the BAG bar was) with the bag count on a badge
	local invBtn = button(gui, "BAG", S(70, 70), S(20, 74), nil, "butter", "bag", true)
	fit(invBtn, 1, 1)
	invBtn.Name = "InventoryButton"
	local badge = panel(invBtn, UDim2.fromScale(1.05, 0.36), UDim2.fromScale(0.5, 0.93), -- tucked onto the button's foot: at 1.02 it read as a loose label
		 Vector2.new(0.5, 0.5), "pillButter")
	badge.ZIndex = 3
	local badgeT = text(badge, "0/10", UDim2.fromScale(0.82, 0.62), UDim2.fromScale(0.5, 0.5), Vector2.new(0.5, 0.5), Color3.fromRGB(146, 96, 10), 700, false) -- deeper than DEEP_GOLD: 3.0:1 measured, now about 4:1
	badgeT.ZIndex = 4
	local nubs = {} -- ore bits poke out of a full bag (board 8)
	for _, d in { { 0.3, 10, 1 }, { 0.52, -12, 3 }, { 0.73, 16, 2 } } do
		local n = new("Frame", invBtn, { Name = "OreNub", Size = UDim2.fromScale(0.17, 0.17), Position = UDim2.fromScale(d[1], 0.07), AnchorPoint = Vector2.new(0.5, 0.5), Rotation = d[2], BackgroundColor3 = C.LAYERS[1][4][d[3]][2], BorderSizePixel = 0, Visible = false, ZIndex = 3 })
		new("UICorner", n, { CornerRadius = UDim.new(0.25, 0) })
		new("UIStroke", n, { Color = Color3.fromRGB(62, 42, 86), Thickness = 1.5 })
		table.insert(nubs, { f = n, x = d[1], r = d[2] })
	end

	-- a heavy bag shows on the bag button only (red count, a beat) and in the footsteps: the bottom ribbon and the centre
	-- headline said the same thing three times (the user, 2026-11-10)
	-- the panel
	local inv = panel(gui, S(880, 480), S(640, 312), Vector2.new(0.5, 0.5), "panel")
	fit(inv, 880, 480)
	local invHome = inv.Position
	inv.Name, inv.Visible = "Inventory", false
	if inv:FindFirstChild("Skin") then inv.Skin.ImageColor3 = Color3.fromRGB(245, 239, 251) end -- frosted parchment, not clinical white (Gemini r3)
	if E.addModal then E.addModal(inv) end -- audit 03: the scrim, the blur and the prompt pause follow this panel
	local _, titleT = ribbonTitle(inv, "BACKPACK", "ribbonLilac", 0.42)
	local close = closeButton(inv, "InventoryClose")
	local tabs = {}
	for i, t in { { "bag", "BAG" }, { "bank", "ORE BANK" }, { "items", "ITEMS" } } do
		local b = button(inv, t[2], UDim2.fromScale(0.2, 0.1), UDim2.fromScale(0.06 + (i - 1) * 0.215, 0.13), nil, "tab")
		b.ZIndex = 6
		tabs[t[1]] = b
	end
	local capT = text(inv, "", UDim2.fromScale(0.56, 0.065), UDim2.fromScale(0.06, 0.27), nil, INK, 700, false)
	capT.TextXAlignment, capT.ZIndex = Enum.TextXAlignment.Left, 6
	local capTrack = new("Frame", inv, { Size = UDim2.fromScale(0.3, 0.04), Position = UDim2.fromScale(0.64, 0.29), BackgroundColor3 = Color3.fromRGB(230, 220, 245), BorderSizePixel = 0, ZIndex = 6 })
	new("UICorner", capTrack, { CornerRadius = UDim.new(0.5, 0) })
	new("UIStroke", capTrack, { Color = INK, Thickness = 2 })
	local capFill = new("Frame", capTrack, { Size = UDim2.fromScale(0, 1), BackgroundColor3 = MINT, BorderSizePixel = 0, ZIndex = 7 })
	new("UICorner", capFill, { CornerRadius = UDim.new(0.5, 0) })
	local grid = new("ScrollingFrame", inv, {
		Name = "Grid", Size = UDim2.fromScale(0.88, 0.42), Position = UDim2.fromScale(0.5, 0.35), AnchorPoint = Vector2.new(0.5, 0),
		BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 6, ScrollBarImageColor3 = INK, CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y, ZIndex = 6,
	})
	new("UIGridLayout", grid, { CellSize = UDim2.fromScale(0.155, 0.46), CellPadding = UDim2.fromScale(0.014, 0.05), SortOrder = Enum.SortOrder.LayoutOrder })
	local emptyT = text(inv, "", UDim2.fromScale(0.8, 0.07), UDim2.fromScale(0.5, 0.56), Vector2.new(0.5, 0.5), MUTED, 700, false)
	emptyT.ZIndex = 6
	local emptyIc = new("ImageLabel", inv, { Image = E.ICON and E.ICON.bag or "", BackgroundTransparency = 1, ImageTransparency = 0.25, ScaleType = Enum.ScaleType.Fit, Size = UDim2.fromScale(0.42, 0.42), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 6 }) -- a sleepy open pouch fills the empty panel
	new("UIAspectRatioConstraint", emptyIc, { AspectRatio = 1 })
	emptyT.Position, emptyT.Size = UDim2.fromScale(0.5, 0.74), UDim2.fromScale(0.8, 0.09)
	for k = 1, 9 do new("Frame", capTrack, { Size = UDim2.new(0, 4, 1, 0), Position = UDim2.fromScale(k / 10, 0), AnchorPoint = Vector2.new(0.5, 0), BackgroundColor3 = INK, BackgroundTransparency = 0.15, BorderSizePixel = 0, ZIndex = 8 }) end -- ten slots
	emptyT:GetPropertyChangedSignal("Visible"):Connect(function() emptyIc.Visible = emptyT.Visible end)
	-- sell mode footer
	local foot = new("Frame", inv, { Size = UDim2.fromScale(0.88, 0.11), Position = UDim2.fromScale(0.5, 0.86), AnchorPoint = Vector2.new(0.5, 0), BackgroundTransparency = 1, Visible = false, ZIndex = 6 })
	local allBtn = button(foot, "SELECT ALL", UDim2.fromScale(0.2, 1), UDim2.fromScale(0, 0), nil, "lilac")
	local clearBtn = button(foot, "CLEAR", UDim2.fromScale(0.14, 1), UDim2.fromScale(0.215, 0), nil, "off")
	local totalT = text(foot, "", UDim2.fromScale(0.26, 0.6), UDim2.fromScale(0.39, 0.2), nil, INK, 700, false)
	totalT.TextXAlignment = Enum.TextXAlignment.Left
	local sellBtn = button(foot, "SELL", UDim2.fromScale(0.32, 1), UDim2.fromScale(1, 0), Vector2.new(1, 0), "butter", "coin")
	for _, o in { allBtn, clearBtn, sellBtn } do o.ZIndex = 7 end
	local hintT = text(inv, "", UDim2.fromScale(0.88, 0.058), UDim2.fromScale(0.5, 0.81), Vector2.new(0.5, 0.5), INK, 700, false) -- larger, full ink: too faint to read (Gemini loop review, 2026-11-10)
	hintT.ZIndex = 6

	local function price(key) -- coins per ore, the same formula the server uses (layer value x 3 per layer x the held pickaxe)
		local L, i = key:match("^(%d+)%.(%d+)$")
		L, i = tonumber(L), tonumber(i)
		local o = L and C.LAYERS[L] and C.LAYERS[L][4][i]
		if not o or not st then return 0 end
		local eq = st.equip or 1
		return math.max(1, math.floor(o[4] * 3 ^ (L - 1) * C.pickValue(eq, st.lv and st.lv[tostring(eq)]) + 0.5))
	end
	local function neededBy(key) -- how many of this ore the next pickaxe asks for (a reminder tag, never a lock)
		local nxt = st and C.PICK_ORE[(st.pick or 1) + 1]
		return nxt and nxt[key] or 0
	end
	local function sortedKeys(t)
		local keys = {}
		for k, n in t or {} do if n > 0 then table.insert(keys, k) end end
		table.sort(keys)
		return keys
	end
	local function total()
		local sum = 0
		for k in ui.picks do sum += ((st and st.ores and st.ores[k]) or 0) * price(k) end
		return sum
	end
	local refresh
	local function slot(i, iconImg, name, count, key)
		local f = panel(grid, UDim2.new(), UDim2.new(), nil, "slot")
		f.LayoutOrder, f.ZIndex = i, 7
		local ic = new("ImageLabel", f, { Image = iconImg or "", BackgroundTransparency = 1, Size = UDim2.fromScale(0.52, 0.46), Position = UDim2.fromScale(0.5, 0.33), AnchorPoint = Vector2.new(0.5, 0.5), ScaleType = Enum.ScaleType.Fit, ZIndex = 8 })
		new("UIAspectRatioConstraint", ic, { AspectRatio = 1 })
		local nm = text(f, name, UDim2.fromScale(0.9, 0.15), UDim2.fromScale(0.5, 0.67), Vector2.new(0.5, 0.5), INK, 700, false)
		local ct = text(f, count, UDim2.fromScale(0.9, 0.15), UDim2.fromScale(0.5, 0.85), Vector2.new(0.5, 0.5), MUTED, 700, false)
		nm.ZIndex, ct.ZIndex = 8, 8
		if key and neededBy(key) > 0 then -- a reminder that the next pickaxe uses this ore
			local tag = panel(f, UDim2.fromScale(0.9, 0.16), UDim2.fromScale(0.5, 0.11), Vector2.new(0.5, 0.5), "pillButter") -- inside the card: on its top edge it hung over the row above
			ic.Position, ic.Size = UDim2.fromScale(0.5, 0.4), UDim2.fromScale(0.44, 0.38)
			tag.ZIndex = 9
			local tt = text(tag, "NEXT PICK: " .. neededBy(key), UDim2.fromScale(0.86, 0.6), UDim2.fromScale(0.5, 0.5), Vector2.new(0.5, 0.5), DEEP_GOLD, 700, false)
			tt.ZIndex = 10
		end
		if key and ui.sell then
			if ui.picks[key] then setKind(f, "mint") end
			local hit = new("TextButton", f, { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", ZIndex = 11 })
			hit.Activated:Connect(function()
				ui.picks[key] = not ui.picks[key] or nil
				setKind(f, ui.picks[key] and "mint" or "slot")
				pop(f, ui.picks[key] and 1.12 or 0.92, 0.25) -- a picked stack hops (board 8)
				sfx("click", ui.picks[key] and 1.2 or 0.9)
				totalT.Text = "SELL FOR " .. commas(total()) .. " COINS"
			end)
		end
		ui.slots[#ui.slots + 1] = f
		return f
	end
	refresh = function()
		if not st then return end
		for _, f in ui.slots do f:Destroy() end
		ui.slots = {}
		local pack = C.PACKS[st.pack or 1]
		local heavy = (st.bag or 0) > (st.cap or pack.cap)
		capT.Visible, capTrack.Visible = ui.tab == "bag", ui.tab == "bag"
		capT.Text = pack.name .. "   " .. commas(st.bag or 0) .. " / " .. commas(st.cap or pack.cap) .. (heavy and "   HEAVY" or "")
		capT.TextColor3 = heavy and DEEP_GOLD or INK
		tween(capFill, 0.3, { Size = UDim2.fromScale(math.clamp((st.bag or 0) / (st.cap or pack.cap), 0, 1), 1), BackgroundColor3 = heavy and BUTTER or MINT }, Enum.EasingStyle.Back)
		for k, b in tabs do setKind(b, k == ui.tab and "tabOn" or "tab") end
		local n = 0
		if ui.tab == "bag" or ui.tab == "bank" then
			local src = ui.tab == "bag" and st.bagOres or st.ores
			ui.seen = ui.seen or { bag = {}, bank = {} }
			local seen = ui.seen[ui.tab]
			for _, k in sortedKeys(src) do
				n += 1
				slot(n, C.ORE_ICON[k], C.oreName(k), "x" .. commas(src[k]) .. (ui.tab == "bank" and ("  ·  " .. commas(src[k] * price(k)) .. "c") or ""), ui.tab == "bank" and k or nil)
				if inv.Visible and src[k] > (seen[k] or 0) then -- more of this ore than the last look: its slot flashes the ore's colour
					local L, i = k:match("^(%d+)%.(%d+)$")
					local o = C.LAYERS[tonumber(L)] and C.LAYERS[tonumber(L)][4][tonumber(i)]
					local fl = new("Frame", ui.slots[#ui.slots], { Size = UDim2.fromScale(1, 1), BackgroundColor3 = o and o[2] or MINT, BackgroundTransparency = 0.25, BorderSizePixel = 0, ZIndex = 12 })
					new("UICorner", fl, { CornerRadius = UDim.new(0.12, 0) })
					tween(fl, 0.7, { BackgroundTransparency = 1 })
					task.delay(0.75, function() fl:Destroy() end)
				end
				seen[k] = src[k]
			end
			if ui.tab == "bag" then -- blocks dug in the block mine fill the bag too: without this row the header said 4 / 10 over an "empty" bag
				local ore = 0
				for _, v in st.bagOres or {} do ore += v end
				local blocks = (st.bag or 0) - ore
				if blocks > 0 then
					n += 1
					slot(n, E.ICON and E.ICON.pick, "Mine blocks", "x" .. commas(blocks))
				end
			end
			emptyT.Text = ui.tab == "bag" and "Your bag is empty. Mine a glowing vein!" or "No banked ore yet. Bank at the camp fire."
		else
			if (st.eggs or 0) > 0 then n += 1 slot(n, E.ICON and E.ICON.egg, "Eggs", "x" .. st.eggs) end
			local flares = plr:GetAttribute("Flares") or 0
			if flares > 0 then n += 1 slot(n, E.ICON and E.ICON.star, "Flares", "x" .. flares) end
			emptyT.Text = "No items yet. Eggs and flares go here."
		end
		emptyT.Visible = n == 0
		for i, f in ui.slots do -- slots stagger in, 25 ms apart (board 8)
			local sc = f:FindFirstChild("Pop") or new("UIScale", f, { Name = "Pop" })
			sc.Scale = 0.6
			task.delay(i * 0.025, function() tween(sc, 0.28, { Scale = 1 }, Enum.EasingStyle.Back) end)
		end
		foot.Visible = ui.sell
		titleT.Text = ui.sell and "SELL TO BOLT" or "BACKPACK"
		totalT.Text = "SELL FOR " .. commas(total()) .. " COINS"
		hintT.Text = ui.sell and "Tap stacks to pick them. Ore your next pickaxe needs is tagged, never locked." or "Over capacity you walk slower. Bank at the camp fire; sell at Bolt in town."
	end

	local function open(sellMode)
		ui.sell = sellMode == true
		ui.tab = ui.sell and "bank" or ui.tab
		ui.picks = {}
		if not inv.Visible then
			openPanel(inv)
			if not ui.sell and invBtn.Visible then -- the panel grows out of the bag button (board 8)
				local gs = gui.AbsoluteSize
				local c = invBtn.AbsolutePosition + invBtn.AbsoluteSize / 2 - gui.AbsolutePosition
				inv.Position = UDim2.fromScale(c.X / gs.X, c.Y / gs.Y)
				tween(inv, 0.28, { Position = invHome }, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			else
				inv.Position = invHome
			end
		end
		refresh() -- after the panel shows: the new-ore flash only plays on a visible panel (Codex)
		pop(invBtn, 0.85)
		sfx("click", 1)
	end
	local function shut()
		if inv.Visible then closePanel(inv) end
		ui.sell = false
	end
	for k, b in tabs do
		b.Activated:Connect(function()
			if ui.sell and k ~= "bank" then return end -- selling works on the ore bank
			ui.tab = k
			refresh()
			pop(b, 1.12, 0.22) -- the picked tab lifts
			sfx("tab", 1)
		end)
	end
	invBtn.Activated:Connect(function() if inv.Visible then shut() else open(false) end end)
	close.Activated:Connect(shut)
	allBtn.Activated:Connect(function()
		if not st then return end
		for _, k in sortedKeys(st.ores) do ui.picks[k] = true end
		refresh()
		for i, f in ui.slots do task.delay(i * 0.03, function() pop(f, 1.15, 0.25) end) end -- a wave left to right
		sfx("sparkle", 1.1)
	end)
	clearBtn.Activated:Connect(function()
		ui.picks = {}
		refresh()
	end)
	sellBtn.Activated:Connect(function()
		local list = {}
		for k in ui.picks do
			local have = st and st.ores and st.ores[k] or 0
			if have > 0 then list[k] = have end
		end
		if next(list) == nil then
			toast("PICK SOME ORE TO SELL FIRST", PINK, false)
			E.shake(0.15)
			return
		end
		SellPickR:FireServer(list)
	end)
	if E.vmHook then E.vmHook.bag = function() if inv.Visible then shut() else open(false) end end end -- the utility wheel and the notebook's ribbon
	game:GetService("UserInputService").InputBegan:Connect(function(input, gp)
		if gp then return end
		if input.KeyCode == Enum.KeyCode.B then
			if inv.Visible then shut() else open(false) end
		end
	end)

	R.State.OnClientEvent:Connect(function(s)
		st = s
		local pack = C.PACKS[s.pack or 1]
		local heavy = (s.bag or 0) > (s.cap or pack.cap)
		badgeT.Text = commas(s.bag or 0) .. "/" .. commas(s.cap or pack.cap)
		setKind(badge, heavy and "pillPink" or "pillButter")
		ui.heavy, ui.full = heavy, (s.bag or 0) >= (s.cap or pack.cap)
		E.vmHook.heavy = heavy -- Juice adds a clink to heavy footsteps
		if inv.Visible then refresh() end
		-- egg tip (board 4/5): after the first forge, with no egg in hand, point to Maribel's stall once
		if (s.pick or 1) >= 2 and (s.eggs or 0) == 0 and not (s.tips and s.tips.eggTip) and not ui.eggTip then
			ui.eggTip = true
			R.Tip:FireServer("eggTip")
			task.delay(2.5, function()
				toast("EGGS HATCH HELPERS! MARIBEL SELLS STARTER EGGS; RARER ONES HIDE IN CAVE NESTS", PINK, true)
				local hub = workspace:FindFirstChild("Hub")
				local mar = hub and hub:FindFirstChild("Maribel", true)
				local body = mar and mar:FindFirstChild("Body")
				if body then
					local bb = E.new("BillboardGui", body, { Name = "EggBeacon", Size = UDim2.fromScale(6, 2.2), StudsOffset = Vector3.new(0, 6, 0), AlwaysOnTop = true, LightInfluence = 0, MaxDistance = 250 })
					local pill = panel(bb, UDim2.fromScale(1, 0.62), UDim2.fromScale(0.5, 0), Vector2.new(0.5, 0), "pillPink")
					text(pill, "EGGS HERE", UDim2.fromScale(0.8, 0.55), UDim2.fromScale(0.5, 0.5), Vector2.new(0.5, 0.5), WHITE, 700)
					task.delay(90, function() bb:Destroy() end)
				end
			end)
		end
	end)
	R.Fx.OnClientEvent:Connect(function(kind, gold, moved)
		if kind == "openSell" then
			open(true)
		elseif kind == "nestEgg" then -- gold = the egg part, moved = its regrow seconds: the egg leaves the nest for us until it regrows
			local egg = gold
			if egg and egg:IsA("BasePart") then
				if burst then burst(egg.Position, Vector3.yAxis, Color3.fromRGB(255, 220, 240), 28) end
				local core = egg:FindFirstChild("EggCore") -- the glowing heart inside the glass egg (Glossify)
				egg.LocalTransparencyModifier = 1
				if core then core.LocalTransparencyModifier = 1 end
				task.delay(moved or 3600, function()
					if egg.Parent then egg.LocalTransparencyModifier = 0 end
					if core and core.Parent then core.LocalTransparencyModifier = 0 end
				end)
			end
			sfx("sparkle", 1.4)
			toast("+1 EGG FROM THE NEST! HATCH IT AT MARIBEL'S INCUBATOR", PINK, true)
		elseif kind == "altarRoll" then -- the pedestals light in turn, the chosen egg rises in a beam, then the hatch reveal plays
			local pick, dais = gold, moved
			local altar = dais and dais.Parent
			local eggs = {}
			for k = 1, 3 do eggs[k] = altar and altar:FindFirstChild("AltarEgg" .. k) end
			local AL = C.ALTAR
			sfx("click", 1)
			for step = 0, 8 do -- a light chase that slows down onto the chosen egg
				task.delay(step * 0.12 + step * step * 0.008, function()
					local k = step < 8 and (step % 3) + 1 or pick
					for j, e in eggs do if e then e.Material = (j == k) and Enum.Material.Neon or Enum.Material.Glass end end -- the eggs are glass (Glossify)
					sfx("click", 1 + step * 0.06)
				end)
			end
			task.delay(1.2, function()
				local e = eggs[pick]
				if e then
					if burst then burst(e.Position, Vector3.yAxis, AL.eggs[pick][4], 40) end
					local beam = E.new("Part", workspace, { Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, Material = Enum.Material.Neon, Color = AL.eggs[pick][4], Transparency = 0.5, Size = Vector3.new(1.4, 16, 1.4), CFrame = CFrame.new(e.Position + Vector3.new(0, 8, 0)) })
					tween(beam, 0.8, { Transparency = 1, Size = Vector3.new(0.2, 22, 0.2) }).Completed:Connect(function() beam:Destroy() end)
				end
				sfx("upgrade", 1.2)
				toast(string.upper(AL.eggs[pick][1]) .. " EGG!", AL.eggs[pick][4], true)
			end)
		elseif kind == "altarPoor" then
			toast("THE ALTAR ASKS " .. commas(C.ALTAR.cost) .. " COINS. YOU NEED " .. commas(gold) .. " MORE", PINK, false)
		elseif kind == "nestEmpty" then
			toast("This nest is empty. A new egg in " .. tostring(gold) .. " min", PINK, false)
		elseif kind == "noCoins" then
			toast("YOU NEED " .. commas(gold) .. " MORE COINS FOR AN EGG. SELL ORE TO BOLT", PINK, false)
			E.shake(0.12)
		elseif kind == "boughtEgg" then
			sfx("coin", 0.9)
			toast("-" .. commas(gold) .. " COINS: A STARTER EGG! HATCH IT AT THE INCUBATOR", PINK, false)
		elseif kind == "soldPick" then -- coins burst from the SELL button into the gold pill
			local inset = game:GetService("GuiService"):GetGuiInset()
			local from = sellBtn.AbsolutePosition + sellBtn.AbsoluteSize / 2 + inset
			if E.fly then E.fly("coin", UDim2.fromOffset(from.X, from.Y), goldPill, math.clamp(math.floor(gold / 3), 6, 16), 0.04) end
			toast("+" .. commas(gold) .. " COINS FROM BOLT", GOLD, true)
			sfx("coin", 1.2)
			task.delay(0.15, function() sfx("sparkle", 1.3) end)
			pop(sellBtn, 1.2)
			ui.picks = {}
		end
	end)

	-- heavy walk, a swaying badge and dust puffs at the feet (board 8)
	local base = game:GetService("StarterPlayer").CharacterWalkSpeed
	local lastPuff = 0
	game:GetService("RunService").Heartbeat:Connect(function()
		local now = os.clock()
		badge.Rotation = ui.heavy and math.sin(now * 3) * 6 or 0
		for i, n in nubs do
			n.f.Visible = ui.full == true
			n.f.Rotation = n.r + (ui.heavy and math.sin(now * 4 + i) * 8 or 0)
		end
		if ui.full and os.clock() >= (ui.beat or 0) then -- a full bag beats on its button, faster once it is over the limit
			ui.beat = os.clock() + (ui.heavy and 0.9 or 1.8)
			pop(invBtn, ui.heavy and 1.14 or 1.07, 0.4)
		end
		local hum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
		if not hum or isBusy() then return end
		local want = ui.heavy and base * HEAVY or base
		if hum.WalkSpeed > 0 and math.abs(hum.WalkSpeed - want) > 0.01 then hum.WalkSpeed = want end
		if ui.heavy and hum.MoveDirection.Magnitude > 0.1 and now - lastPuff > 0.55 and burst then
			lastPuff = now
			local root = plr.Character:FindFirstChild("HumanoidRootPart")
			if root then burst(root.Position - Vector3.new(0, 2.8, 0), Vector3.yAxis, Color3.fromRGB(170, 150, 140), 4) end
		end
	end)
end

return M
