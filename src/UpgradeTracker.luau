-- UpgradeTracker (ReplicatedStorage.Shared.UpgradeTracker), started by PixelClient: always show what the next pickaxe needs
-- (playtest 2, the user 2026-11-09: "Players gain currency too fast and arent taught how to upgrade ... Add a tracking feature so
-- players know what their next upgrade needs"; boards PT2_HUD, PT2_Upgrade, PT2_VFX).
--
-- Demo audit 01 (2026-11-09 night): the card sat on fixed coordinates and collided with the tip ribbon, the currency pills and
-- the bag badge. Two changes, both here because this module owns the left side of the HUD:
--   1. THE LEFT COLUMN. Currency, bag, upgrade tracker, surface button and the pickup feed live in one container with a
--      vertical UIListLayout (8 px padding). Each widget sits in a row as tall as itself; a hidden widget's row folds away, so
--      the rest move up and nothing can overlap whatever shows or hides.
--   2. THE TRACKER IS A COMPACT PILL: a progress ring, the pickaxe's name and one summary line. Hover or tap unfolds the full
--      card (one chip per ore, the coin chip, the hint line) as the next row of the column; it also unfolds by itself for a
--      few seconds when banked ore or coins change, and when the pickaxe becomes ready.
-- It also keeps the top-centre widgets (step card, tip ribbon) between the two side columns on narrow screens: they lose
-- their fixed aspect ratio and take the free width, growing a line taller when squeezed.
local M = {}

function M.start(E)
	local C, R, plr, gui, new, S, text, panel, setKind = E.C, E.R, E.plr, E.gui, E.new, E.S, E.text, E.panel, E.setKind
	local toast, sfx, pop, tween, commas = E.toast, E.sfx, E.pop, E.tween, E.commas
	local INK, WHITE, MINT, BUTTER = E.INK, E.WHITE, E.MINT, E.BUTTER
	local MUTED, CORAL, DEEP_MINT = Color3.fromRGB(84, 66, 108), Color3.fromRGB(224, 96, 110), Color3.fromRGB(32, 156, 92)
	local HEAD = Color3.fromRGB(96, 68, 150)
	local Radial = require(script.Parent:WaitForChild("Radial"))
	local WHERE = { -- where each layer's ore lives (C.DEPOSIT.layer: tunnel/squeeze 1, chasm/grotto 2, mush 3)
		[1] = "the tunnels near camp", [2] = "the chasm and the grotto lake", [3] = "the mushroom hall",
	}
	local RARITY = { "common", "uncommon", "rare" }

	-- 1. the left column
	local col = new("Frame", gui, { Name = "LeftColumn", Size = UDim2.fromScale(1, 1), Position = S(20, 18), BackgroundTransparency = 1 })
	new("UIListLayout", col, { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Left })
	local order = 0
	local function row(name, h) -- h = the widget's height on the 592 px board
		order += 1
		return new("Frame", col, { Name = name, LayoutOrder = order, Size = UDim2.new(1, 0, h / 592, 0), BackgroundTransparency = 1 })
	end
	local function adopt(o, r, hShare) -- move a widget into its row: full row height (or a share of it), its own width
		if not o then return end
		o.AnchorPoint, o.Position = Vector2.zero, UDim2.new()
		o.Size = UDim2.fromScale(o.Size.X.Scale, hShare or 1)
		o.Parent = r
	end
	local money = row("Currency", 46)
	new("UIListLayout", money, { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder })
	for i, n in { "GoldPill", "GemPill", "EggPill" } do
		local o = gui:FindFirstChild(n)
		if o then
			adopt(o, money)
			o.LayoutOrder = i
		end
	end
	local pillRow = row("Tracker", 46)
	local cardRow = row("TrackerCard", 118)
	local btnRow = row("Buttons", 70 * 1.22) -- the square buttons side by side (the bag's count badge hangs under its button)
	new("UIListLayout", btnRow, { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder })
	local nBtn = 0
	E.addRow = function(o) -- a square button joins the row (the wardrobe)
		if not o then return end
		nBtn += 1
		adopt(o, btnRow, 1 / 1.22)
		o.LayoutOrder = nBtn
	end
	E.addRow(gui:WaitForChild("InventoryButton", 10))
	E.addRow(gui:FindFirstChild("Surface"))
	if gui:FindFirstChild("Surface", true) then setKind(gui:FindFirstChild("Surface", true), "lilac") end -- one colour family down the column (the cold sky blue stood apart)
	local feedRow = new("Frame", col, { Name = "Feed", LayoutOrder = 99, Size = UDim2.new(1, 0, 140 / 592, 0), BackgroundTransparency = 1 })
	adopt(E.feed, feedRow)

	-- 2. the tracker: compact pill + unfolding card
	local pill = panel(pillRow, UDim2.fromScale(1, 1), UDim2.new(), nil, "card")
	new("UIAspectRatioConstraint", pill, { AspectRatio = 236 / 46, DominantAxis = Enum.DominantAxis.Height })
	pill.Name = "TrackerPill"
	local ringBox = new("Frame", pill, { Size = UDim2.fromScale(0.17, 0.84), Position = UDim2.fromScale(0.025, 0.5), AnchorPoint = Vector2.new(0, 0.5), BackgroundTransparency = 1, ZIndex = 3 })
	new("UIAspectRatioConstraint", ringBox, { AspectRatio = 1 })
	local ring = Radial.arc(ringBox, { thick = 0.2, color = Color3.fromRGB(255, 184, 0), track = Color3.fromRGB(53, 29, 69), trackTransparency = 0.1, z = 3, value = 0 }) -- amber on a dark track: the progress reads without the numbers
	new("UIAspectRatioConstraint", new("ImageLabel", ringBox, { Image = E.ICON and E.ICON.pick or "", BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit, Size = UDim2.fromScale(0.56, 0.56), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 4 }), { AspectRatio = 1 })
	local nameT = text(pill, "", UDim2.fromScale(0.74, 0.4), UDim2.fromScale(0.2, 0.1), nil, INK, 700, false)
	nameT.TextXAlignment = Enum.TextXAlignment.Left
	local sumT = text(pill, "", UDim2.fromScale(0.74, 0.3), UDim2.fromScale(0.2, 0.56), nil, HEAD, 700, false)
	sumT.TextXAlignment = Enum.TextXAlignment.Left

	local card = panel(cardRow, UDim2.fromScale(1, 1), UDim2.new(), nil, "card")
	new("UIAspectRatioConstraint", card, { AspectRatio = 270 / 118, DominantAxis = Enum.DominantAxis.Height })
	card.Name = "TrackerDetail"
	if card:FindFirstChild("Skin") then card.Skin.ImageColor3 = Color3.fromRGB(244, 239, 248) end -- a soft lavender cream: plain white glared in the dark cave
	local head = text(card, "NEXT UPGRADE NEEDS", UDim2.fromScale(0.86, 0.14), UDim2.fromScale(0.07, 0.12), nil, HEAD, 700, false)
	head.TextXAlignment = Enum.TextXAlignment.Left
	local chips = new("Frame", card, { Size = UDim2.fromScale(0.88, 0.37), Position = UDim2.fromScale(0.07, 0.29), BackgroundTransparency = 1, ZIndex = 3 })
	new("UIListLayout", chips, { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0.025, 0), VerticalAlignment = Enum.VerticalAlignment.Center })
	local hint = text(card, "", UDim2.fromScale(0.86, 0.19), UDim2.fromScale(0.07, 0.7), nil, MUTED, 700, false)
	hint.TextWrapped = true -- two lines at a readable size
	hint.TextXAlignment = Enum.TextXAlignment.Left
	local shine = new("Frame", pill, { Size = UDim2.fromScale(0.18, 1.2), Position = UDim2.fromScale(-0.3, -0.1), BackgroundColor3 = WHITE, BackgroundTransparency = 0.55, BorderSizePixel = 0, Rotation = 18, ZIndex = 5, Visible = false })
	pill.ClipsDescendants = true

	local unlocked = false -- shown once the first ore exists
	local openUntil, hovering = 0, false
	local function unfold(sec) openUntil = math.max(openUntil, os.clock() + sec) end
	local hit = new("TextButton", pill, { Text = "", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 6 })
	hit.MouseEnter:Connect(function() hovering = true end)
	hit.MouseLeave:Connect(function() hovering = false unfold(0.5) end)
	hit.Activated:Connect(function()
		if os.clock() < openUntil and not hovering then openUntil = 0 else unfold(5) end
		sfx("click", 1.1)
	end)

	local beacon -- in town, over Bolt, when the next pickaxe is ready
	local function boltPart()
		local hub = workspace:FindFirstChild("Hub")
		local bolt = hub and hub:FindFirstChild("Bolt", true)
		return bolt and (bolt:IsA("Model") and (bolt.PrimaryPart or bolt:FindFirstChildWhichIsA("BasePart", true)) or bolt)
	end
	local function setBeacon(on)
		local p = on and boltPart()
		if p and not beacon then
			beacon = new("BillboardGui", p, { Name = "ForgeReady", Size = UDim2.fromScale(7, 2.6), StudsOffset = Vector3.new(0, 6, 0), AlwaysOnTop = true, LightInfluence = 0, MaxDistance = 220 })
			local bp = panel(beacon, UDim2.fromScale(1, 0.62), UDim2.fromScale(0.5, 0), Vector2.new(0.5, 0), "pillMint")
			text(bp, "FORGE READY", UDim2.fromScale(0.8, 0.55), UDim2.fromScale(0.5, 0.5), Vector2.new(0.5, 0.5), WHITE, 700)
			local arrow = text(beacon, "v", UDim2.fromScale(0.3, 0.4), UDim2.fromScale(0.5, 0.62), Vector2.new(0.5, 0), MINT, 700)
			arrow.Name = "Arrow"
		elseif not on and beacon then
			beacon:Destroy()
			beacon = nil
		end
	end

	local readyTier -- the tier we already celebrated
	local seenOnce = false
	local function chip(image, label, done, inBag)
		local c = panel(chips, UDim2.fromScale(0.3, 1), UDim2.new(), nil, inBag and "pillButter" or (done and "pillMint" or "pill"))
		c.ZIndex = 3
		local ic = new("ImageLabel", c, { Image = image, BackgroundTransparency = 1, Size = UDim2.fromScale(0.3, 0.8), Position = UDim2.fromScale(0.06, 0.5), AnchorPoint = Vector2.new(0, 0.5), ScaleType = Enum.ScaleType.Fit, ZIndex = 4 })
		new("UIAspectRatioConstraint", ic, { AspectRatio = 1 })
		local t = text(c, label, UDim2.fromScale(0.58, 0.62), UDim2.fromScale(0.68, 0.5), Vector2.new(0.5, 0.5), done and DEEP_MINT or CORAL, 700, false)
		t.ZIndex = 4
		return c
	end
	local last = {}
	R.State.OnClientEvent:Connect(function(s)
		local i = (s.pick or 1) + 1
		local nxt = C.PICKS[i]
		if not nxt then unlocked = false setBeacon(false) return end
		local need = C.PICK_ORE[i] or {}
		for _, c in chips:GetChildren() do if c:IsA("GuiObject") then c:Destroy() end end
		local keys = {}
		for k in need do table.insert(keys, k) end
		table.sort(keys)
		local ready, firstShort, changed = true, nil, false
		local got, want = 0, 0
		for _, k in keys do
			local have, inBag, n = (s.ores and s.ores[k]) or 0, (s.bagOres and s.bagOres[k]) or 0, need[k]
			local done = have >= n
			got += math.min(have, n)
			want += n
			if not done then ready = false firstShort = firstShort or k end
			local c = chip(C.ORE_ICON[k] or "", math.min(have, n) .. "/" .. n, done, not done and have + inBag >= n)
			if (last[k] or 0) < have then pop(c, 1.18, 0.3) changed = true end -- a chip bounces when banked ore lands (board 8)
			last[k] = have
		end
		local coinsOk = (s.gold or 0) >= nxt.cost
		if not coinsOk then ready = false end
		local cc = chip(E.ICON and E.ICON.coin or "", (coinsOk and commas(nxt.cost) or commas(s.gold or 0)) .. "/" .. commas(nxt.cost), coinsOk)
		if (last.coins or 0) < (s.gold or 0) then pop(cc, 1.1, 0.25) end
		last.coins = s.gold or 0
		nameT.Text = nxt.name
		-- the ring: ore and coins weigh the same, so it only closes when both are in
		local oreShare = want > 0 and got / want or 1
		ring.set((oreShare + math.clamp((s.gold or 0) / math.max(nxt.cost, 1), 0, 1)) / 2)
		if ready then
			sumT.Text, sumT.TextColor3 = "READY TO FORGE", DEEP_MINT
			head.Text, head.TextColor3 = "READY TO FORGE", DEEP_MINT
			hint.Text, hint.TextColor3 = plr:GetAttribute("InCave") and "Ride up and visit Bolt in town." or "Visit Bolt at the forge.", DEEP_MINT
			setKind(pill, "pillMint")
		else
			sumT.Text, sumT.TextColor3 = (want > 0 and ("ORE " .. got .. "/" .. want .. "   ") or "") .. "COINS " .. commas(math.min(s.gold or 0, nxt.cost)) .. "/" .. commas(nxt.cost), HEAD
			head.Text, head.TextColor3 = "NEXT UPGRADE NEEDS", HEAD
			setKind(pill, "card")
			if firstShort then
				local L, idx = firstShort:match("^(%d+)%.(%d+)$")
				hint.Text = C.oreName(firstShort) .. ": " .. (RARITY[tonumber(idx)] or "") .. " in " .. (WHERE[tonumber(L)] or "deeper caves") .. ". Bank at camp."
			else
				hint.Text = "Sell spare ore to Bolt for coins."
			end
			hint.TextColor3 = MUTED
		end
		if changed then unfold(4) end
		if not unlocked and (s.tips and (s.tips.obFirstDeposit or s.tips.banked) or (s.ores and next(s.ores))) then
			unlocked = true -- appears once the first ore exists, with the teaching line (board 4, step 2)
			pop(pill, 0.6, 0.4)
			unfold(6)
			if not seenOnce then
				seenOnce = true
				toast("YOUR NEXT PICKAXE NEEDS ORE: BANK IT AT CAMP, THEN FORGE AT BOLT", BUTTER, true)
			end
		end
		if ready and readyTier ~= i then -- ready: a shine sweeps the pill, it pulses twice and chimes (board 8)
			readyTier = i
			shine.Visible, shine.Position = true, UDim2.fromScale(-0.3, -0.1)
			tween(shine, 0.7, { Position = UDim2.fromScale(1.1, -0.1) }, Enum.EasingStyle.Quad).Completed:Connect(function() shine.Visible = false end)
			pop(pill, 1.12, 0.35)
			task.delay(0.4, function() pop(pill, 1.08, 0.35) end)
			unfold(5)
			sfx("upgrade", 1.3)
			toast(nxt.name:upper() .. " IS READY: VISIT BOLT", MINT, true)
		end
		setBeacon(ready and not plr:GetAttribute("InCave"))
	end)

	-- top-centre widgets keep clear of both side columns at any width
	local bands = {}
	local function band(o, w, h, label)
		if not o then return end
		local ar = o:FindFirstChildOfClass("UIAspectRatioConstraint")
		if ar then ar:Destroy() end
		if label then label.TextWrapped = true end
		table.insert(bands, { o = o, w = w, h = h })
	end
	band(gui:FindFirstChild("StepCard"), 560, 62, gui:FindFirstChild("StepCard") and gui.StepCard:FindFirstChildWhichIsA("TextLabel"))
	local caveHud = gui:FindFirstChild("CaveHud")
	local tipBanner = caveHud and caveHud:FindFirstChild("TipBanner")
	band(tipBanner, 700, 66, tipBanner and tipBanner:FindFirstChildWhichIsA("TextLabel"))
	local rights = { E.layerPill, caveHud and caveHud:FindFirstChild("Minimap"), caveHud and caveHud:FindFirstChild("CampPill") }
	local function shown(o)
		local p = o
		while p and p ~= gui do
			if p:IsA("GuiObject") and not p.Visible then return false end
			p = p.Parent
		end
		return true
	end

	game:GetService("RunService").Heartbeat:Connect(function()
		local scrim = gui:FindFirstChild("Scrim")
		local busy = (E.isBusy and E.isBusy()) or (scrim and scrim.Visible and scrim.BackgroundTransparency < 0.9) -- a minigame or a modal is up
		pillRow.Visible = unlocked and not busy
		local open = pillRow.Visible and (hovering or os.clock() < openUntil)
		cardRow.Visible = open
		feedRow.Visible = not open -- the feed gives its place to the open card
		local a = beacon and beacon:FindFirstChild("Arrow")
		if a then a.Position = UDim2.fromScale(0.5, 0.62 + math.sin(os.clock() * 5) * 0.06) end
		local vp = gui.AbsoluteSize
		for _, b in bands do
			if shown(b.o) then
				local k = vp.Y / 592
				local y0, y1 = b.o.AbsolutePosition.Y, b.o.AbsolutePosition.Y + b.h * k
				local left, right = 0, vp.X
				for _, r in col:GetChildren() do -- the left column's widgets level with this band
					if r:IsA("Frame") and r.Visible and col.Visible then
						for _, w in r:GetChildren() do
							if w:IsA("GuiObject") and w.Visible and w.AbsolutePosition.Y < y1 and w.AbsolutePosition.Y + w.AbsoluteSize.Y > y0 then
								left = math.max(left, w.AbsolutePosition.X + w.AbsoluteSize.X)
							end
						end
					end
				end
				local talisman = caveHud and caveHud:FindFirstChild("Survival")
				for _, w in { talisman, talisman and talisman:FindFirstChild("Flare") } do -- the survival talisman and its flare slot, bottom left
					if shown(w) and w.AbsolutePosition.Y < y1 and w.AbsolutePosition.Y + w.AbsoluteSize.Y > y0 then left = math.max(left, w.AbsolutePosition.X + w.AbsoluteSize.X) end
				end
				for _, w in rights do
					if w and shown(w) and w.AbsolutePosition.Y < y1 and w.AbsolutePosition.Y + w.AbsoluteSize.Y > y0 then
						right = math.min(right, w.AbsolutePosition.X)
					end
				end
				local free = 2 * (math.min(vp.X / 2 - left, right - vp.X / 2) - 26) -- a clear gap to both columns (the ribbon's tails stick out past its frame)
				local full = b.w * k
				local w = math.clamp(free, 120, full)
				b.o.Size = UDim2.fromOffset(w, b.h * k * (w < full * 0.62 and 1.45 or 1)) -- squeezed: a line taller, the text wraps
			end
		end
	end)
end

return M
