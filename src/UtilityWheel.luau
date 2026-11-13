-- UtilityWheel (ReplicatedStorage.Shared.UtilityWheel), started by PixelClient. Hold Tab: a wheel of the small actions
-- the game already has opens in the middle of the screen. Push the mouse toward one and let go (or click) to use it:
-- up SONAR (caves), right FLARE (caves), down CHEER, left WARDROBE (town). A quick tap leaves the wheel open until the
-- next Tab or a click. An action that cannot be used here is dimmed and the hub says why. Client only: every action
-- goes through the same function its own key calls, so the server checks stay where they were (flares are counted by
-- the server, the wardrobe saves through its own remote).
-- Every slot is also a tap target, and on a touch device (no keyboard) a TOOLS button in the left column opens the
-- wheel, since there is no Tab to hold (Studio hook: client attribute DevTouch shows the button on a PC).
-- shortcut: no gamepad entry yet; add a stick direction when the game is tested on a console.
local M = {}

function M.start(E)
	local UIS, RunService, TweenService = game:GetService("UserInputService"), game:GetService("RunService"), game:GetService("TweenService")
	local C, new, plr, hook = E.C, E.new, E.plr, E.vmHook
	local INK, CREAM, BUTTER, PINK, MINT, WHITE = E.INK, E.CREAM, E.BUTTER, E.PINK, E.MINT, E.WHITE
	local MID = Vector2.new(0.5, 0.5)
	local calm = false
	pcall(function() calm = game:GetService("GuiService").ReducedMotionEnabled end)
	pcall(function() game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false) end) -- Tab is ours: the game has no leaderboard values

	local function inCave() return plr:GetAttribute("InCave") == true end
	local SLOTS = {
		{ name = "SONAR", key = "T", x = 0.5, y = 0.14, tint = MINT,
			why = function()
				if not inCave() then return "Caves only" end
				local left = hook.sonarLeft and hook.sonarLeft() or 0
				if left > 0 then return "Ready in " .. math.ceil(left) .. " s" end
				return nil
			end,
			run = function() if hook.sonar then hook.sonar() end end },
		{ name = "FLARE", key = "R", x = 0.86, y = 0.5, icon = C.HUD_ICON.flare, tint = PINK,
			why = function()
				if not inCave() then return "Caves only" end
				if (plr:GetAttribute("Flares") or C.GLOOM.flares) <= 0 then return "No flares left" end
				return nil
			end,
			run = function() if E.cave.flare then E.cave.flare() end end },
		{ name = "CHEER", x = 0.5, y = 0.86, icon = C.HUD_ICON.calm, tint = BUTTER,
			-- in the caves this slot is the pet whistle (Shared.PetCompanion, key X); in town it stays the cheer
			dyn = function() return (inCave() and hook.whistle) and "WHISTLE" or "CHEER" end,
			why = function()
				if plr:GetAttribute("Seated") then return "Not while riding" end
				if inCave() and hook.whistleWhy then return hook.whistleWhy() end
				return nil
			end,
			run = function()
				if inCave() and hook.whistle then hook.whistle() elseif hook.emote then hook.emote("cheer") end
			end },
		{ name = "WARDROBE", key = "V", x = 0.14, y = 0.5, icon = E.ICON.crew, tint = E.LILAC,
			why = function() return (inCave() or plr:GetAttribute("InMine")) and "Town only" or nil end,
			run = function() if hook.wardrobe then hook.wardrobe() end end },
		-- the diagonals (2026-11-12, the owner: "add more items in there such as the settings menu")
		{ name = "NOTES", key = "N", x = 0.755, y = 0.245, icon = E.ICON.hammer, tint = BUTTER,
			why = function() return nil end,
			run = function() if hook.notebook then hook.notebook() end end },
		{ name = "BAG", key = "B", x = 0.755, y = 0.755, icon = E.ICON.bag, tint = MINT,
			why = function() return nil end,
			run = function() if hook.bag then hook.bag() end end },
		{ name = "QUESTS", key = "J", x = 0.245, y = 0.755, icon = E.ICON.star, tint = PINK,
			why = function() return nil end,
			run = function() if hook.quests then hook.quests() end end },
		{ name = "PING", key = "Z", x = 0.245, y = 0.245, icon = E.ICON.map, tint = E.LILAC,
			why = function() return (not inCave()) and "Caves only" or nil end,
			run = function() if hook.ping then hook.ping() end end },
	}

	-- Cut-glass kit (the user, 2026-11-12: "Rework the Tab wheel with the new 3D view as well as the new jelly text and icons"):
	-- the wheel stands in the world as a tilted panel (Shared.SpatialPanels takes its holder), its names are jelly letters,
	-- its icons the jelly set, its body smoked glass. No dark scrim: the world stays visible round it.
	local G = E.GLASS
	local JellyText = G and require(script.Parent:WaitForChild("JellyText"))
	if G then
		local jelly = { SONAR = "sonar", CHEER = "smile", WARDROBE = "shirt", NOTES = "gear", PING = "pin", BAG = "bag", QUESTS = "star" }
		for _, s in SLOTS do
			if jelly[s.name] then s.icon = E.ICON[jelly[s.name]] end
		end
	end
	local SCRIM = G and 1 or 0.36
	local LABEL = G and WHITE or INK
	-- a Modal button frees the mouse in first person while the wheel is up
	local root = new("TextButton", E.gui, { Name = "UtilityWheel", Text = "", AutoButtonColor = false, Modal = true, BackgroundColor3 = INK, BackgroundTransparency = SCRIM, BorderSizePixel = 0, Size = UDim2.new(1, 0, 1, 80), Position = UDim2.fromOffset(0, -80), ZIndex = 40, Visible = false }) -- 80 px up: over the top bar inset too -- the scrim keeps torches and signs from shining through (Gemini r1: readability 3 to 5)
	local holder = new("Frame", root, { Size = E.S(400, 400), Position = UDim2.new(0.5, 0, 0.5, 40), AnchorPoint = MID, BackgroundTransparency = 1, ZIndex = 40 })
	E.fit(holder, 1, 1)
	holder.Name = "Holder"
	local pop = new("UIScale", holder, { Scale = 1 })
	local function disc(parent, k, x, y, color, tr, z)
		local d = new("Frame", parent, { Size = UDim2.fromScale(k, k), Position = UDim2.fromScale(x, y), AnchorPoint = MID, BackgroundColor3 = color, BackgroundTransparency = tr, BorderSizePixel = 0, ZIndex = z })
		new("UICorner", d, { CornerRadius = UDim.new(0.5, 0) })
		return d
	end
	new("ImageLabel", holder, { Image = G and G.ring or "rbxassetid://117032895507459", BackgroundTransparency = 1, Size = UDim2.fromScale(G and 1.2 or 1.32, G and 1.2 or 1.32), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = MID, ZIndex = 40 }) -- the painted brass compass (art/ui_notebook/dial.png)
	local plate = disc(holder, 1.1, 0.5, 0.5, WHITE, 1, 40) -- a brass pocket compass with a dark leather face (Gemini on the first in-game pass: the cream disc was a 'flat pizza' over the dark cave) -- a soft lilac-cream plate with a lilac rim, like the kit's cards
	plate.Visible = not G -- the glass ring picture is the whole body
	new("UIGradient", plate, { Rotation = 90, Color = G and ColorSequence.new(Color3.fromRGB(52, 38, 100), Color3.fromRGB(24, 16, 50)) or ColorSequence.new(Color3.fromRGB(74, 50, 40), Color3.fromRGB(44, 28, 24)) })
	new("UIGradient", new("UIStroke", plate, { Color = WHITE, Thickness = 12, Transparency = 1, Enabled = not G }), { Rotation = 55, Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(244, 206, 116)), ColorSequenceKeypoint.new(0.45, Color3.fromRGB(146, 102, 32)), ColorSequenceKeypoint.new(1, Color3.fromRGB(230, 184, 88)) }) })
	local inner = disc(holder, 1.0, 0.5, 0.5, WHITE, 1, 40) -- a stitched ring inside the rim
	new("UIStroke", inner, { Color = G and Color3.fromRGB(214, 200, 255) or Color3.fromRGB(230, 184, 88), Thickness = 1.5, Transparency = 0.45 })
	for _, rot in { 22.5, 67.5, -22.5, -67.5 } do -- faint sector lines: where one slot's pull ends and the next begins
		new("Frame", holder, { Size = UDim2.new(1.02, 0, 0, 2), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = MID, Rotation = rot, BackgroundColor3 = G and Color3.fromRGB(214, 200, 255) or Color3.fromRGB(230, 184, 88), BackgroundTransparency = G and 1 or 0.7, BorderSizePixel = 0, ZIndex = 40 }) -- no sector lines on glass: they made flat pie slices
	end
	local OFF, OFF_INK = G and Color3.fromRGB(58, 50, 80) or Color3.fromRGB(150, 132, 108), G and Color3.fromRGB(206, 198, 228) or Color3.fromRGB(78, 58, 44) -- a soft dark plate so the wheel reads over town and cave alike
	for _, s in SLOTS do
		local d = disc(holder, 0.225, s.x, s.y, CREAM, 0, 41)
		s.fill = G and Color3.fromRGB(96, 74, 170) or Color3.fromRGB(236, 220, 180) -- glass tokens with the kit on; parchment tokens; the slot's own colour shows only when it is picked (Gemini: pastel candy circles undid the compass)
		d.Name = s.name
		new("UIGradient", d, { Rotation = 90, Color = ColorSequence.new(WHITE, G and Color3.fromRGB(150, 130, 200) or Color3.fromRGB(206, 188, 150)) }) -- lighter on top
		s.lock = new("ImageLabel", d, { Image = E.ICON.lock, BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit, Size = UDim2.fromScale(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = MID, ZIndex = 44, Visible = false })
		s.disc, s.rim, s.scale = d, new("UIStroke", d, { Color = INK, Thickness = 3 }), new("UIScale", d, { Scale = 1 })
		if s.icon then
			s.img = new("ImageLabel", d, { Image = s.icon, BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit, Size = UDim2.fromScale(G and 0.7 or 0.56, G and 0.7 or 0.56), Position = UDim2.fromScale(0.5, G and 0.38 or 0.4), AnchorPoint = MID, ZIndex = 42 })
		else -- the sonar has no icon in the kit: three mint rings
			s.rings = {}
			for i, k in { 0.16, 0.32, 0.48 } do
				local r = disc(d, k, 0.5, 0.4, MINT, i == 1 and 0 or 1, 42)
				table.insert(s.rings, new("UIStroke", r, { Color = i == 1 and INK or Color3.fromRGB(60, 170, 130), Thickness = 2.5 }))
			end
		end
		s.label = E.text(d, s.name, UDim2.fromScale(0.8, 0.2), UDim2.fromScale(0.5, 0.8), MID, INK, nil, false)
		s.label.Font = Enum.Font.Bangers -- inside the disc now: eight slots leave no room underneath; -- outside the disc: the name never covers the icon
		s.label.ZIndex = 43
		if G then
			s.label.Size, s.label.Position, s.label.TextColor3 = UDim2.fromScale(0.98, 0.27), UDim2.fromScale(0.5, 0.84), LABEL -- inside the token: longer names ran over the wheel's rim
			s.jt = JellyText.mirror(s.label, { color = LABEL, followColor = true, sway = false })
		end
		s.sub = E.text(d, "", UDim2.fromScale(1.7, 0.15), UDim2.fromScale(0.5, 1.31), MID, Color3.fromRGB(112, 96, 138), nil, false) -- why a locked slot is locked
		s.sub.ZIndex = 43
		s.sub.Visible = false -- with eight slots the hub alone says why a slot is locked
		if s.key then
			s.cap = E.keyCap(d, s.key, UDim2.fromScale(0.3, 0.3), UDim2.fromScale(0.9, 0.12))
			s.cap.ZIndex = 44
		end
	end
	local hub = disc(holder, G and 0.26 or 0.2, 0.5, 0.52, G and Color3.fromRGB(70, 52, 130) or BUTTER, 0, 41)
	new("UIGradient", hub, { Rotation = 90, Color = ColorSequence.new(WHITE, G and Color3.fromRGB(150, 130, 200) or Color3.fromRGB(240, 228, 200)) })
	new("UIStroke", hub, { Color = G and Color3.fromRGB(236, 226, 255) or INK, Thickness = G and 2 or 3 })
	local hubScale = new("UIScale", hub, { Scale = 1 })
	local hubName = E.text(hub, "TAB", UDim2.fromScale(0.86, G and 0.36 or 0.3), UDim2.fromScale(0.5, 0.4), MID, LABEL, nil, false)
	hubName.ZIndex = 43
	if G then JellyText.mirror(hubName, { color = Color3.fromRGB(255, 226, 130), popOnChange = true, sway = false }) end
	local hubWhy = E.text(hub, "", UDim2.fromScale(0.84, 0.2), UDim2.fromScale(0.5, 0.7), MID, G and Color3.fromRGB(236, 226, 255) or OFF_INK, nil, false)
	hubWhy.ZIndex = 43
	local dot = disc(holder, 0.05, 0.5, 0.5, BUTTER, 0, 45) -- where the mouse has been pushed
	new("UIStroke", dot, { Color = INK, Thickness = 2 })

	local origin, sel, openedAt = Vector2.zero, nil, 0
	local lastSel = nil
	local tools -- the touch-only TOOLS button (made below)
	local isOpen = false -- root stays visible a moment longer while it shrinks away
	local function close()
		if not isOpen then return end
		isOpen, sel = false, nil
		hook.cardUp, hook.wheelOpen = false, false
		if calm then root.Visible = false return end
		-- it shrinks and the scrim clears in a tenth of a second (the recording showed an instant cut)
		TweenService:Create(pop, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = 0.85 }):Play()
		TweenService:Create(root, TweenInfo.new(0.1), { BackgroundTransparency = 1 }):Play()
		task.delay(0.11, function() if not isOpen then root.Visible = false end end)
	end
	local function commit()
		local s = sel and SLOTS[sel]
		if not s then return close() end
		if s.why() then
			pcall(E.sfx, "error", 1)
			return
		end
		close()
		pcall(E.sfx, "click", 1.1)
		s.run()
	end
	local function blocked()
		if E.isBusy() or plr:GetAttribute("Seated") or (hook.deathPlaying and hook.deathPlaying()) then return true end
		for _, m in hook.modals or {} do if m.Visible then return true end end
		return false
	end
	local function open()
		if isOpen or blocked() then return end
		isOpen = true
		origin, sel, openedAt = UIS:GetMouseLocation(), nil, os.clock()
		root.Visible = true
		hook.cardUp = true -- world prompts and the location pill step back, as under a loot card
		hook.wheelOpen = true -- PixelClient frees the mouse in first person, as it does for a panel
		pcall(E.sfx, "open", 1.2)
		if not calm then
			pop.Scale = 0.8
			root.BackgroundTransparency = 1
			TweenService:Create(root, TweenInfo.new(0.15), { BackgroundTransparency = SCRIM }):Play() -- the scrim fades in with the pop
			TweenService:Create(pop, TweenInfo.new(0.16, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
		end
	end

	RunService.RenderStepped:Connect(function()
		if not isOpen then return end
		if blocked() then return close() end
		hubScale.Scale = 1 + (calm and 0 or 0.035 * math.sin(os.clock() * 3.2)) -- the hub breathes: the open wheel is never a still picture
		local v = UIS:GetMouseLocation() - origin
		local reach = holder.AbsoluteSize.X * 0.33
		if v.Magnitude > reach then v = v.Unit * reach end
		dot.Position = UDim2.fromScale(0.5 + v.X / holder.AbsoluteSize.X, 0.5 + v.Y / holder.AbsoluteSize.Y)
		dot.Visible = v.Magnitude > reach * 0.3 -- at rest it would sit on the hub's words
		sel = nil
		if v.Magnitude > reach * 0.3 then
			local best = -2 -- the slot whose direction is nearest the push
			for i, s in SLOTS do
				local d = Vector2.new(s.x - 0.5, s.y - 0.5).Unit:Dot(v.Unit)
				if d > best then best, sel = d, i end
			end
		end
		for i, s in SLOTS do
			if s.dyn then -- a slot whose job depends on where you are
				local nm = s.dyn()
				if s.name ~= nm then s.name = nm s.label.Text = nm end
			end
			local why = s.why()
			local off, on = why ~= nil, i == sel
			s.sub.Text = off and why or "" -- a locked slot keeps its name and says why underneath; its key cap goes (the key would not work either)
			if s.cap then s.cap.Visible = on and not off end -- the key shows on the picked slot only: eight white caps crowded the dial
			-- unusable: a flat grey disc with a lock, never see-through (Gemini r1: transparency turned to sludge over the world)
			s.disc.BackgroundColor3 = off and OFF or (on and s.tint or s.fill)
			s.rim.Color, s.rim.Thickness = off and OFF_INK or (G and Color3.fromRGB(236, 226, 255) or Color3.fromRGB(59, 36, 22)), (on and not off) and 5 or (G and 2 or 3)
			s.label.TextColor3 = off and OFF_INK or LABEL
			s.lock.Visible = off
			if s.img then s.img.ImageTransparency, s.img.ImageColor3 = off and 0.72 or 0, off and Color3.fromRGB(170, 160, 190) or WHITE end
			if s.rings then for _, r in s.rings do r.Transparency = off and 0.6 or 0 end end
			s.scale.Scale += ((on and 1.14 or 1) - s.scale.Scale) * 0.35
		end
		local s = sel and SLOTS[sel]
		if sel ~= lastSel then -- the newly picked slot's name wobbles like jelly
			lastSel = sel
			if s and s.jt and not calm then s.jt.pop(0.012) pcall(E.sfx, "tab", 1.3) end
		end
		hubName.Text = s and s.name or ((tools and tools.Visible) and "TOOLS" or "TAB")
		hubWhy.Text = s and s.why() or (sel and "" or ((tools and tools.Visible) and "tap one" or "move and let go"))
	end)

	root.Activated:Connect(function(io)
		-- with the kit on the wheel stands in the world behind this full-screen catcher, so a tap that lands on a slot is
		-- read here: the slot that is drawn nearest the tap (Shared.SpatialPanels says where each slot is on the screen)
		if G and io and hook.spatialPoint and holder.Parent ~= root then
			local tap = Vector2.new(io.Position.X, io.Position.Y) + game:GetService("GuiService"):GetGuiInset()
			local best = holder.AbsoluteSize.X * 0.16 -- a tap must land within about a slot's radius
			for i, s in SLOTS do
				local d = (hook.spatialPoint(s.disc.AbsolutePosition + s.disc.AbsoluteSize / 2) - tap).Magnitude
				if d < best then best, sel = d, i end
			end
		end
		commit()
	end)
	if G then -- Shared.SpatialPanels carries the holder into the world while the wheel is up, and back
		hook.spatialExtra = hook.spatialExtra or {}
		table.insert(hook.spatialExtra, { frame = holder, home = root, on = function() return root.Visible end, quick = true })
	end
	for i, s in SLOTS do -- a tap or a click straight on a slot picks it
		local tap = new("TextButton", s.disc, { Name = "Tap", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", ZIndex = 46 })
		tap.Activated:Connect(function()
			sel = i
			commit()
		end)
	end
	tools = E.button(E.gui, "TOOLS", E.S(76, 76), E.S(20, 400), nil, "lilac", "star", true)
	E.fit(tools, 1, 1)
	tools.Name = "ToolsButton"
	tools.Activated:Connect(function() if isOpen then close() else open() end end)
	local function touchOnly() tools.Visible = (UIS.TouchEnabled and not UIS.KeyboardEnabled) or plr:GetAttribute("DevTouch") ~= nil end
	plr:GetAttributeChangedSignal("DevTouch"):Connect(touchOnly)
	touchOnly()
	task.spawn(function()
		for _ = 1, 50 do
			if E.addRow then E.addRow(tools, 76) return end
			task.wait(0.1)
		end
	end)
	UIS.InputBegan:Connect(function(io, gp)
		if gp or io.KeyCode ~= Enum.KeyCode.Tab then return end
		if isOpen then close() else open() end
	end)
	UIS.InputEnded:Connect(function(io)
		if io.KeyCode ~= Enum.KeyCode.Tab or not isOpen then return end
		if sel or os.clock() - openedAt > 0.3 then commit() end -- a quick tap with no choice leaves the wheel open
	end)
	plr:GetAttributeChangedSignal("DevWheel"):Connect(function() -- Studio test hook: DevWheel = 1..4 opens the wheel and picks that slot
		local i = plr:GetAttribute("DevWheel")
		if not SLOTS[i] then return end
		open()
		sel = i
		commit()
	end)
end

return M
