-- QuestUI (ReplicatedStorage.Shared.QuestUI), started by PixelClient. The quest menu and the tutorial guide, v1 (the user,
-- 2026-11-10). Rules and data: Shared.Quests; the server counts, pays and saves (remote "Quest").
--   * the QUESTS panel (the QUESTS button in the left column, the J key, or the notice board in town): STORY and DAILY tabs,
--     three rows each with a progress bar, the reward and a CLAIM button
--   * the tutorial: the open story quest's hint shows in the game's step card (E.vmHook.questHint) and a bobbing marker
--     hangs over the place it leads to (the cart, a deposit, Bolt's stall, the forge, the incubator, the relic chest)
local Quests = require(script.Parent:WaitForChild("Quests"))
local M = {}

function M.start(E)
	local R, plr, gui, new, S, fit, text, panel, button = E.R, E.plr, E.gui, E.new, E.S, E.fit, E.text, E.panel, E.button
	local openPanel, closePanel, ribbonTitle, closeButton, sfx, pop, tween, setKind, toast = E.openPanel, E.closePanel, E.ribbonTitle, E.closeButton, E.sfx, E.pop, E.tween, E.setKind, E.toast
	local INK, WHITE, MINT, GOLD, LILAC = E.INK, E.WHITE, E.MINT, E.GOLD, E.LILAC
	local MUTED, DEEP_MINT = Color3.fromRGB(107, 90, 128), Color3.fromRGB(32, 156, 92)
	local UIS, RunService = game:GetService("UserInputService"), game:GetService("RunService")
	local QuestR = R:WaitForChild("Quest", 20)
	if not QuestR then return end
	local hook = E.vmHook
	local q = Quests.clean(nil, Quests.day())
	local tab = "story"

	local win = panel(gui, S(820, 470), S(640, 300), Vector2.new(0.5, 0.5), "panel")
	fit(win, 820, 470)
	win.Name, win.Visible = "Quests", false
	if E.addModal then E.addModal(win) end
	ribbonTitle(win, "QUESTS", "ribbonLilac", 0.36)
	local close = closeButton(win, "QuestsClose")
	local tabs = {}
	for i, k in { "story", "daily" } do
		local b = button(win, k:upper(), UDim2.fromScale(0.2, 0.1), UDim2.fromScale(0.06 + (i - 1) * 0.22, 0.13), nil, "tab")
		b.ZIndex = 6
		tabs[k] = b
	end
	local note = text(win, "", UDim2.fromScale(0.4, 0.06), UDim2.fromScale(0.94, 0.18), Vector2.new(1, 0.5), MUTED, 700, false)
	note.TextXAlignment, note.ZIndex = Enum.TextXAlignment.Right, 6

	local rows = {}
	for i = 1, 3 do
		local f = panel(win, UDim2.fromScale(0.9, 0.205), UDim2.fromScale(0.5, 0.27 + (i - 1) * 0.225), Vector2.new(0.5, 0), "card")
		f.ZIndex = 6
		local r = { f = f }
		r.title = text(f, "", UDim2.fromScale(0.6, 0.38), UDim2.fromScale(0.04, 0.26), Vector2.new(0, 0.5), INK, 700, false)
		r.title.TextXAlignment, r.title.ZIndex = Enum.TextXAlignment.Left, 7
		r.reward = text(f, "", UDim2.fromScale(0.3, 0.26), UDim2.fromScale(0.04, 0.57), Vector2.new(0, 0.5), MUTED, 700, false)
		r.reward.TextXAlignment, r.reward.ZIndex = Enum.TextXAlignment.Left, 7
		local bar = new("Frame", f, { Size = UDim2.fromScale(0.6, 0.17), Position = UDim2.fromScale(0.04, 0.81), AnchorPoint = Vector2.new(0, 0.5), BackgroundColor3 = E.GLASS and Color3.fromRGB(186, 170, 232) or Color3.fromRGB(240, 234, 246), -- a pale, outlined, taller track: a filled-in empty bar read as a full one (Gemini UI review, twice)
		 BorderSizePixel = 0, ZIndex = 7 })
		new("UIStroke", bar, { Color = Color3.fromRGB(190, 176, 214), Thickness = 1.5 })
		new("UICorner", bar, { CornerRadius = UDim.new(0.5, 0) })
		r.fill = new("Frame", bar, { Size = UDim2.fromScale(0, 1), BackgroundColor3 = MINT, BorderSizePixel = 0, ZIndex = 8 })
		new("UICorner", r.fill, { CornerRadius = UDim.new(0.5, 0) })
		r.count = text(f, "", UDim2.fromScale(0.24, 0.3), UDim2.fromScale(0.82, 0.5), Vector2.new(0.5, 0.5), MUTED, 700, false)
		r.count.ZIndex = 7
		r.claim = button(f, "CLAIM", UDim2.fromScale(0.24, 0.56), UDim2.fromScale(0.82, 0.5), Vector2.new(0.5, 0.5), "mint")
		r.claim.ZIndex = 8
		r.claim.Activated:Connect(function()
			if r.id then QuestR:FireServer("claim", r.id) end
		end)
		rows[i] = r
	end

	local function rewardText(d) return d.coins and ("+" .. d.coins .. " COINS") or ("+" .. (d.gems or 0) .. " GEMS") end
	local function items() -- up to three { def, progress, state } for the open tab; state: "open" | "done" | "claimed" | "locked"
		local out = {}
		if tab == "story" then
			for k = q.story, math.min(q.story + 2, #Quests.STORY) do
				local d = Quests.STORY[k]
				local p = k == q.story and q.sp or (k == q.story + 1 and (q.np or 0) or 0) -- the next quest already counts while this one waits
				table.insert(out, { d, p, k > q.story and "locked" or (p >= d.n and "done" or "open") })
			end
		else
			for _, d in Quests.dailies(q.day) do
				local p = q.d[d.id] or 0
				table.insert(out, { d, p, q.c[d.id] and "claimed" or (p >= d.n and "done" or "open") })
			end
		end
		return out
	end
	local function claimable()
		local st = Quests.STORY[q.story]
		if st and q.sp >= st.n then return true end
		for _, d in Quests.dailies(q.day) do if (q.d[d.id] or 0) >= d.n and not q.c[d.id] then return true end end
		return false
	end

	local btn, dot
	local function refresh()
		for k, b in tabs do setKind(b, k == tab and "tabOn" or "tab") end
		local list = items()
		for i, r in rows do
			local it = list[i]
			r.f.Visible = it ~= nil
			if it then
				local d, p, state = it[1], it[2], it[3]
				r.id = state == "done" and d.id or nil
				r.title.Text = state == "locked" and ("NEXT: " .. d.title) or d.title
				r.title.TextTransparency = state == "locked" and 0.45 or 0
				r.reward.Text = rewardText(d)
				r.fill.BackgroundColor3 = state == "open" and MINT or DEEP_MINT
				tween(r.fill, 0.3, { Size = UDim2.fromScale(math.clamp(p / d.n, 0, 1), 1) })
				r.claim.Visible = state == "done"
				r.count.Visible = state ~= "done"
				r.count.Text = state == "claimed" and "CLAIMED" or (state == "locked" and p == 0) and "LOCKED" or (p .. " / " .. d.n)
			end
		end
		if tab == "story" then
			note.Text = q.story > #Quests.STORY and "ALL STORY QUESTS DONE. MORE SOON!" or ("QUEST " .. q.story .. " OF " .. #Quests.STORY)
		end
		local can = claimable()
		if dot then dot.Visible = can end
		-- the tutorial line in the step card
		local st = Quests.STORY[q.story]
		local g, gp = Quests.guide(q) -- a finished quest keeps leading: the next step, plus where the reward waits
		if g and st and q.sp >= st.n and gp >= g.n then g = nil end -- the next step is done too: only the claim is left to do
		local keys = game:GetService("UserInputService").KeyboardEnabled -- a phone has no J key: point at the QUESTS button
		hook.questHint = st and (q.sp >= st.n and (g and (g.hint .. (keys and " (Reward waiting: J)" or " (Reward waiting in QUESTS)")) or (keys and "Two quests done! Press J to claim your rewards." or "Two quests done! Open QUESTS to claim your rewards.")) or st.hint) or nil
	end
	for k, b in tabs do
		b.Activated:Connect(function()
			tab = k
			sfx("tab")
			refresh()
		end)
	end

	local function open()
		if win.Visible or (E.isBusy and E.isBusy()) then return end
		QuestR:FireServer("get")
		refresh()
		openPanel(win)
		sfx("sparkle", 1.2)
		for i, r in rows do -- the rows drop in one after another
			local sc = r.f:FindFirstChild("Pop") or new("UIScale", r.f, { Name = "Pop" })
			sc.Scale = 0.86
			task.delay(0.05 * i, function() tween(sc, 0.3, { Scale = 1 }, Enum.EasingStyle.Back) end)
		end
	end
	local function shut() if win.Visible then closePanel(win) end end
	if E.vmHook then E.vmHook.quests = function() if win.Visible then shut() else open() end end end -- the utility wheel and the notebook's ribbon
	close.Activated:Connect(shut)
	UIS.InputBegan:Connect(function(io, gp)
		if gp then return end
		if io.KeyCode == Enum.KeyCode.J then if win.Visible then shut() else open() end end
	end)
	btn = button(gui, "QUESTS", S(76, 76), S(20, 320), nil, "lilac", "star", true)
	fit(btn, 1, 1)
	btn.Name = "QuestsButton"
	btn.Activated:Connect(function() if win.Visible then shut() else open() end end)
	dot = new("Frame", btn, { Name = "Dot", Size = UDim2.fromScale(0.26, 0.26), Position = UDim2.fromScale(0.9, 0.1), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Color3.fromRGB(216, 69, 107), BorderSizePixel = 0, ZIndex = 5, Visible = false }) -- a berry wax seal with a bark edge (was a pink dot with a white ring)
	new("UICorner", dot, { CornerRadius = UDim.new(0.5, 0) })
	new("UIStroke", dot, { Color = Color3.fromRGB(59, 36, 22), Thickness = 3 })
	task.spawn(function()
		for _ = 1, 50 do
			if E.addRow then E.addRow(btn, 76) return end
			task.wait(0.1)
		end
	end)

	local got = false
	QuestR.OnClientEvent:Connect(function(state, paid)
		got = true
		local was = claimable()
		q = Quests.clean(state, type(state) == "table" and tonumber(state.day) or Quests.day())
		q.day = type(state) == "table" and tonumber(state.day) or q.day
		refresh()
		if paid then -- a claim went through: the row pops, coins fly to the purse, the miner cheers
			sfx("claim")
			toast(paid.coins and ("QUEST DONE  +" .. paid.coins .. " COINS") or ("QUEST DONE  +" .. (paid.gems or 0) .. " GEMS"), GOLD, true)
			for _, r in rows do if r.f.Visible then pop(r.f, 1.06, 0.3) end end
			if paid.coins and E.fly and E.goldPill and win.Visible then
				local at = win.AbsolutePosition + win.AbsoluteSize / 2 + game:GetService("GuiService"):GetGuiInset()
				E.fly("coin", UDim2.fromOffset(at.X, at.Y), E.goldPill, 8, 0.05)
			end
			if hook.emote then hook.emote("cheer") end
		elseif claimable() and not was then
			sfx("sparkle", 1.4)
			toast(game:GetService("UserInputService").KeyboardEnabled and "QUEST COMPLETE!  PRESS J TO CLAIM" or "QUEST COMPLETE!  OPEN QUESTS TO CLAIM", MINT, true, 1.5) -- a beat later: on arrival it landed with the step card and a tip
			if btn.Visible then pop(btn, 1.3, 0.4) end
		end
	end)
	R.Fx.OnClientEvent:Connect(function(kind) if kind == "openQuests" then open() end end)
	task.spawn(function() -- the first request can arrive before the profile has loaded: ask until answered
		for _ = 1, 20 do
			if got then return end
			QuestR:FireServer("get")
			task.wait(1.5)
		end
	end)

	-- the guide marker: a small sign over the place the open story quest leads to. It is drawn on the HUD from the place's
	-- screen position (like the ore glints), so it shows through walls and slides to the screen edge when the place is out of view
	local marker = new("Frame", gui, { Name = "QuestMarker", Size = S(82, 48), AnchorPoint = Vector2.new(0.5, 1), BackgroundTransparency = 1, Visible = false, ZIndex = 1 })
	local tip = new("Frame", marker, { Size = UDim2.fromScale(0.2, 0.35), Position = UDim2.fromScale(0.5, 0.72), AnchorPoint = Vector2.new(0.5, 0.5), Rotation = 45, BackgroundColor3 = GOLD, BorderSizePixel = 0 })
	new("UIAspectRatioConstraint", tip, { AspectRatio = 1 })
	new("UIStroke", tip, { Color = INK, Thickness = 2 })
	-- a small wooden plank with cream capitals (Field Notebook pass 2026-11-12; was a white pill)
	local tag = new("Frame", marker, { Size = UDim2.fromScale(1, 0.6), BackgroundColor3 = E.GLASS and Color3.fromRGB(60, 42, 120) or Color3.fromRGB(138, 90, 51), BackgroundTransparency = E.GLASS and 0.12 or 0, BorderSizePixel = 0, ZIndex = 2 }) -- cut-glass kit: a smoked glass tag with a light edge
	new("UICorner", tag, { CornerRadius = UDim.new(0.14, 0) })
	new("UIStroke", tag, { Color = E.GLASS and Color3.fromRGB(236, 226, 255) or Color3.fromRGB(59, 36, 22), Thickness = E.GLASS and 1.5 or 3 })
	new("UIGradient", tag, { Rotation = 90, Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(196, 176, 160)) })
	local tagText = text(tag, "", UDim2.fromScale(0.84, 0.72), UDim2.fromScale(0.5, 0.5), Vector2.new(0.5, 0.5), Color3.fromRGB(255, 247, 226), 700)
	tagText.Font, tagText.TextStrokeColor3 = E.HEAD or Enum.Font.Bangers, E.GLASS and Color3.fromRGB(30, 20, 66) or Color3.fromRGB(59, 36, 22)
	tagText.ZIndex = 3
	local PLACE = { cart = { "HubCart", "RIDE" }, sell = { "SellStall", "SELL" }, forge = { "Forge", "FORGE" }, egg = { "Incubator", "EGG" }, chest = { "DailyChest", "OPEN" } }
	local function target() -- the world position and the word, or nil
		local st, sp = Quests.guide(q)
		if not st or sp >= st.n or not st.point then return nil end -- chapter 2 quests have no place to point at
		local inCave = plr:GetAttribute("InCave")
		local hub, caves = workspace:FindFirstChild("Hub"), workspace:FindFirstChild("Caves")
		local function over(m, word)
			if not m then return nil end
			local cf, size = m:GetBoundingBox()
			return cf.Position + Vector3.new(0, size.Y / 2 + 2.5, 0), word
		end
		if st.point == "deposit" then
			if not inCave then return over(hub and hub:FindFirstChild("HubCart", true), "RIDE") end
			local h, deps = E.hrp(), caves and caves:FindFirstChild("Deposits")
			local best, bd
			for _, d in deps and h and deps:GetChildren() or {} do
				local c = d.PrimaryPart
				if c and c.Transparency < 1 then -- an extracted deposit hides until it grows back
					local m = (c.Position - h.Position).Magnitude
					if not bd or m < bd then best, bd = c, m end
				end
			end
			if best then return best.Position + Vector3.new(0, 3.5, 0), "MINE" end
			return nil
		end
		if inCave then -- the place is up in town: lead back to the camp's cart
			local body = caves and caves:FindFirstChild("CartBody", true)
			if body then return body.Position + Vector3.new(0, 4.5, 0), "RIDE UP" end
			return nil
		end
		local p = PLACE[st.point]
		return over(p and hub and hub:FindFirstChild(p[1], true), p and p[2])
	end
	local nextScan, pos = 0, nil
	RunService.RenderStepped:Connect(function()
		local now = os.clock()
		if now >= nextScan then
			nextScan = now + 0.5
			local word
			pos, word = target()
			if word then tagText.Text = word end
			if dot and dot.Visible and btn.Visible then pop(dot, 1.35, 0.4) end -- the claim dot keeps beating
		end
		local busy = E.isBusy and E.isBusy() or plr:GetAttribute("Seated") == true or hook.wheelOpen == true or hook.arOpen == true -- not in a minigame, a cart ride, or under the wheel or the settings
		for _, m in hook.modals or {} do if m.Visible then busy = true end end
		local h = E.hrp()
		local far = pos and h and (pos - h.Position).Magnitude or 0
		-- a sign near its place, not a pill hanging in the air all through the caves (the user, 2026-11-10)
		marker.Visible = pos ~= nil and not busy and far <= (tagText.Text == "RIDE UP" and 14 or 60)
		if not marker.Visible then return end
		local cam = workspace.CurrentCamera
		local v = cam:WorldToViewportPoint(pos)
		local vp = cam.ViewportSize
		local x, y = v.X, v.Y
		if v.Z < 0 then x, y = vp.X - x, vp.Y * 0.9 end -- behind you: point along the bottom edge
		x = math.clamp(x, vp.X * 0.27, vp.X * 0.8) -- stay between the side columns
		y = math.clamp(y - math.abs(math.sin(now * 3)) * vp.Y * 0.02, vp.Y * 0.28, vp.Y * 0.66) -- under the step card and the currency pills (0.24 touched the gem pill by a pixel), over the talisman
		marker.Position = UDim2.fromOffset(x, y - (gui.IgnoreGuiInset and 0 or game:GetService("GuiService"):GetGuiInset().Y))
		local mp, ms = marker.AbsolutePosition, marker.AbsoluteSize
		local hud = gui:FindFirstChild("CaveHud")
		local over = { gui:FindFirstChild("StepCard"), hud and hud.Visible and hud:FindFirstChild("TipBanner") or nil }
		for _, c in gui:GetChildren() do if c.Name == "PromptUI" or c.Name == "Toast" then table.insert(over, c) end end
		for _, c in over do -- a prompt bubble says what to do, and the step card, tip ribbon and toast lane are taken: the marker yields where it would sit on one
			if c.Visible then
				local cp, cs = c.AbsolutePosition, c.AbsoluteSize
				local pad = 12
				if mp.X < cp.X + cs.X + pad and cp.X < mp.X + ms.X + pad and mp.Y < cp.Y + cs.Y + pad and cp.Y < mp.Y + ms.Y + pad then marker.Visible = false end
			end
		end
	end)
end

return M
