-- UpgradeTracker (ReplicatedStorage.Shared.UpgradeTracker), started by PixelClient: always show what the next pickaxe needs
-- (playtest 2, the user 2026-11-09: "Players gain currency too fast and arent taught how to upgrade ... Add a tracking feature so
-- players know what their next upgrade needs"; boards PT2_HUD, PT2_Upgrade, PT2_VFX). A card under the coin pills: the next
-- pickaxe, one chip per ore (banked / needed; ore still in the bag counts as "in bag") and a coin chip, mint when done and coral
-- when short, one hint line saying where that ore is. When everything is in: a mint READY state with a shine and a chime once,
-- and in town a beacon over Bolt. The card steps back during minigames (the HUD focus list in PixelClient).
local M = {}

function M.start(E)
	local C, R, plr, gui, new, S, fit, text, panel, setKind = E.C, E.R, E.plr, E.gui, E.new, E.S, E.fit, E.text, E.panel, E.setKind
	local toast, sfx, pop, tween, commas = E.toast, E.sfx, E.pop, E.tween, E.commas
	local INK, WHITE, MINT, BUTTER = E.INK, E.WHITE, E.MINT, E.BUTTER
	local MUTED, CORAL, DEEP_MINT, DEEP_GOLD = Color3.fromRGB(107, 90, 128), Color3.fromRGB(224, 96, 110), Color3.fromRGB(32, 156, 92), Color3.fromRGB(184, 122, 26)
	local WHERE = { -- where each layer's ore lives (C.DEPOSIT.layer: tunnel/squeeze 1, chasm/grotto 2, mush 3)
		[1] = "the tunnels near camp", [2] = "the chasm and the grotto lake", [3] = "the mushroom hall",
	}
	local RARITY = { "common", "uncommon", "rare" }

	local card = panel(gui, S(270, 118), S(102, 88), nil, "card") -- right of the inventory button, under the step card, clear of the tip ribbon (no overlap: the user, 2026-11-09)
	fit(card, 270, 118)
	card.Name, card.Visible = "Tracker", false
	local head = text(card, "NEXT UPGRADE", UDim2.fromScale(0.6, 0.13), UDim2.fromScale(0.07, 0.1), nil, Color3.fromRGB(156, 134, 217), 700, false)
	head.TextXAlignment = Enum.TextXAlignment.Left
	local nameT = text(card, "", UDim2.fromScale(0.86, 0.2), UDim2.fromScale(0.07, 0.25), nil, INK, 700, false)
	nameT.TextXAlignment = Enum.TextXAlignment.Left
	local chips = new("Frame", card, { Size = UDim2.fromScale(0.88, 0.25), Position = UDim2.fromScale(0.07, 0.5), BackgroundTransparency = 1, ZIndex = 3 })
	new("UIListLayout", chips, { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0.025, 0), VerticalAlignment = Enum.VerticalAlignment.Center })
	local hint = text(card, "", UDim2.fromScale(0.86, 0.12), UDim2.fromScale(0.07, 0.8), nil, MUTED, 700, false)
	hint.TextXAlignment = Enum.TextXAlignment.Left
	local shine = new("Frame", card, { Size = UDim2.fromScale(0.18, 1.2), Position = UDim2.fromScale(-0.3, -0.1), BackgroundColor3 = WHITE, BackgroundTransparency = 0.55, BorderSizePixel = 0, Rotation = 18, ZIndex = 5, Visible = false })

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
			local pill = panel(beacon, UDim2.fromScale(1, 0.62), UDim2.fromScale(0.5, 0), Vector2.new(0.5, 0), "pillMint")
			text(pill, "FORGE READY", UDim2.fromScale(0.8, 0.55), UDim2.fromScale(0.5, 0.5), Vector2.new(0.5, 0.5), WHITE, 700)
			local arrow = text(beacon, "v", UDim2.fromScale(0.3, 0.4), UDim2.fromScale(0.5, 0.62), Vector2.new(0.5, 0), MINT, 700)
			arrow.Name = "Arrow"
		elseif not on and beacon then
			beacon:Destroy()
			beacon = nil
		end
	end

	local readyTier -- the tier we already celebrated
	local unlocked = false -- shown once the first ore exists
	local seenOnce = false
	local function chip(color, label, done, inBag)
		local c = panel(chips, UDim2.fromScale(0.3, 1), UDim2.new(), nil, inBag and "pillButter" or (done and "pillMint" or "pill"))
		c.ZIndex = 3
		local ic = new("ImageLabel", c, { Image = color, BackgroundTransparency = 1, Size = UDim2.fromScale(0.3, 0.8), Position = UDim2.fromScale(0.06, 0.5), AnchorPoint = Vector2.new(0, 0.5), ScaleType = Enum.ScaleType.Fit, ZIndex = 4 })
		new("UIAspectRatioConstraint", ic, { AspectRatio = 1 })
		local t = text(c, label, UDim2.fromScale(0.58, 0.62), UDim2.fromScale(0.68, 0.5), Vector2.new(0.5, 0.5), done and DEEP_MINT or CORAL, 700, false)
		t.ZIndex = 4
		return c
	end
	local last = {}
	R.State.OnClientEvent:Connect(function(s)
		local i = (s.pick or 1) + 1
		local nxt = C.PICKS[i]
		if not nxt then unlocked = false card.Visible = false setBeacon(false) return end
		local need = C.PICK_ORE[i] or {}
		for _, c in chips:GetChildren() do if c:IsA("GuiObject") then c:Destroy() end end
		local keys = {}
		for k in need do table.insert(keys, k) end
		table.sort(keys)
		local ready, firstShort = true, nil
		for _, k in keys do
			local have, inBag, n = (s.ores and s.ores[k]) or 0, (s.bagOres and s.bagOres[k]) or 0, need[k]
			local done = have >= n
			if not done then ready = false firstShort = firstShort or k end
			local c = chip(C.ORE_ICON[k] or "", math.min(have, n) .. "/" .. n, done, not done and have + inBag >= n)
			if (last[k] or 0) < have then pop(c, 1.18, 0.3) end -- a chip bounces when banked ore lands (board 8)
			last[k] = have
		end
		local coinsOk = (s.gold or 0) >= nxt.cost
		if not coinsOk then ready = false end
		local cc = chip(E.ICON and E.ICON.coin or "", (coinsOk and commas(nxt.cost) or commas(s.gold or 0)) .. "/" .. commas(nxt.cost), coinsOk)
		if (last.coins or 0) < (s.gold or 0) then pop(cc, 1.1, 0.25) end
		last.coins = s.gold or 0
		nameT.Text = nxt.name
		if ready then
			head.Text, head.TextColor3 = "READY TO FORGE", DEEP_MINT
			hint.Text, hint.TextColor3 = plr:GetAttribute("InCave") and "Ride up and visit Bolt in town." or "Visit Bolt at the forge.", DEEP_MINT
			setKind(card, "pillMint")
		else
			head.Text, head.TextColor3 = "NEXT UPGRADE", Color3.fromRGB(156, 134, 217)
			setKind(card, "card")
			if firstShort then
				local L, idx = firstShort:match("^(%d+)%.(%d+)$")
				hint.Text = C.oreName(firstShort) .. ": " .. (RARITY[tonumber(idx)] or "") .. " in " .. (WHERE[tonumber(L)] or "deeper caves") .. ". Bank at camp."
			else
				hint.Text = "Sell spare ore to Bolt for coins."
			end
			hint.TextColor3 = MUTED
		end
		if not unlocked and (s.tips and (s.tips.obFirstDeposit or s.tips.banked) or (s.ores and next(s.ores))) then
			unlocked = true
			card.Visible = true -- slides in once the first ore exists, with the teaching line (board 4, step 2)
			card.Position = S(-300, 88)
			tween(card, 0.45, { Position = S(102, 88) }, Enum.EasingStyle.Back)
			if not seenOnce then
				seenOnce = true
				toast("YOUR NEXT PICKAXE NEEDS ORE: BANK IT AT CAMP, THEN FORGE AT BOLT", BUTTER, true)
			end
		end
		if ready and readyTier ~= i then -- ready: a mint shine sweeps the card, it pulses twice and chimes (board 8)
			readyTier = i
			shine.Visible, shine.Position = true, UDim2.fromScale(-0.3, -0.1)
			tween(shine, 0.7, { Position = UDim2.fromScale(1.1, -0.1) }, Enum.EasingStyle.Quad).Completed:Connect(function() shine.Visible = false end)
			pop(card, 1.12, 0.35)
			task.delay(0.4, function() pop(card, 1.08, 0.35) end)
			sfx("upgrade", 1.3)
			toast(nxt.name:upper() .. " IS READY: VISIT BOLT", MINT, true)
		end
		setBeacon(ready and not plr:GetAttribute("InCave"))
	end)
	game:GetService("RunService").Heartbeat:Connect(function() -- the beacon arrow bobs; the card steps back during minigames
		card.Visible = unlocked and not (E.isBusy and E.isBusy())
		local a = beacon and beacon:FindFirstChild("Arrow")
		if a then a.Position = UDim2.fromScale(0.5, 0.62 + math.sin(os.clock() * 5) * 0.06) end
	end)
end

return M
