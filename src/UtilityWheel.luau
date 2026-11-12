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
		{ name = "SONAR", key = "T", x = 0.5, y = 0.17, tint = MINT,
			why = function()
				if not inCave() then return "Caves only" end
				local left = hook.sonarLeft and hook.sonarLeft() or 0
				if left > 0 then return "Ready in " .. math.ceil(left) .. " s" end
				return nil
			end,
			run = function() if hook.sonar then hook.sonar() end end },
		{ name = "FLARE", key = "R", x = 0.83, y = 0.5, icon = C.HUD_ICON.flare, tint = PINK,
			why = function()
				if not inCave() then return "Caves only" end
				if (plr:GetAttribute("Flares") or C.GLOOM.flares) <= 0 then return "No flares left" end
				return nil
			end,
			run = function() if E.cave.flare then E.cave.flare() end end },
		{ name = "CHEER", x = 0.5, y = 0.83, icon = C.HUD_ICON.calm, tint = BUTTER,
			why = function() return plr:GetAttribute("Seated") and "Not while riding" or nil end,
			run = function() if hook.emote then hook.emote("cheer") end end },
		{ name = "WARDROBE", key = "V", x = 0.17, y = 0.5, icon = E.ICON.crew, tint = E.LILAC,
			why = function() return (inCave() or plr:GetAttribute("InMine")) and "Town only" or nil end,
			run = function() if hook.wardrobe then hook.wardrobe() end end },
	}

	-- a Modal button frees the mouse in first person while the wheel is up
	local root = new("TextButton", E.gui, { Name = "UtilityWheel", Text = "", AutoButtonColor = false, Modal = true, BackgroundColor3 = INK, BackgroundTransparency = 0.36, BorderSizePixel = 0, Size = UDim2.new(1, 0, 1, 80), Position = UDim2.fromOffset(0, -80), ZIndex = 40, Visible = false }) -- 80 px up: over the top bar inset too -- the scrim keeps torches and signs from shining through (Gemini r1: readability 3 to 5)
	local holder = new("Frame", root, { Size = E.S(330, 330), Position = UDim2.new(0.5, 0, 0.5, 40), AnchorPoint = MID, BackgroundTransparency = 1, ZIndex = 40 })
	E.fit(holder, 1, 1)
	holder.Name = "Holder"
	local pop = new("UIScale", holder, { Scale = 1 })
	local function disc(parent, k, x, y, color, tr, z)
		local d = new("Frame", parent, { Size = UDim2.fromScale(k, k), Position = UDim2.fromScale(x, y), AnchorPoint = MID, BackgroundColor3 = color, BackgroundTransparency = tr, BorderSizePixel = 0, ZIndex = z })
		new("UICorner", d, { CornerRadius = UDim.new(0.5, 0) })
		return d
	end
	local plate = disc(holder, 1.1, 0.5, 0.5, WHITE, 0.06, 40) -- a soft lilac-cream plate with a lilac rim, like the kit's cards
	new("UIGradient", plate, { Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(252, 247, 255), Color3.fromRGB(226, 214, 242)) })
	new("UIStroke", plate, { Color = Color3.fromRGB(150, 128, 204), Thickness = 5 })
	for _, rot in { 45, -45 } do -- faint sector lines: where one slot's pull ends and the next begins
		new("Frame", holder, { Size = UDim2.new(1.02, 0, 0, 2), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = MID, Rotation = rot, BackgroundColor3 = INK, BackgroundTransparency = 0.86, BorderSizePixel = 0, ZIndex = 40 })
	end
	local OFF, OFF_INK = Color3.fromRGB(226, 220, 234), Color3.fromRGB(112, 96, 138) -- a soft dark plate so the wheel reads over town and cave alike
	for _, s in SLOTS do
		local d = disc(holder, 0.27, s.x, s.y, CREAM, 0, 41)
		s.fill = s.tint:Lerp(WHITE, 0.45)
		d.Name = s.name
		new("UIGradient", d, { Rotation = 90, Color = ColorSequence.new(WHITE, Color3.fromRGB(226, 220, 236)) }) -- pillowy: lighter on top
		s.lock = new("ImageLabel", d, { Image = E.ICON.lock, BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit, Size = UDim2.fromScale(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = MID, ZIndex = 44, Visible = false })
		s.disc, s.rim, s.scale = d, new("UIStroke", d, { Color = INK, Thickness = 3 }), new("UIScale", d, { Scale = 1 })
		if s.icon then
			s.img = new("ImageLabel", d, { Image = s.icon, BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit, Size = UDim2.fromScale(0.7, 0.7), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = MID, ZIndex = 42 })
		else -- the sonar has no icon in the kit: three mint rings
			s.rings = {}
			for i, k in { 0.2, 0.4, 0.6 } do
				local r = disc(d, k, 0.5, 0.5, MINT, i == 1 and 0 or 1, 42)
				table.insert(s.rings, new("UIStroke", r, { Color = i == 1 and INK or Color3.fromRGB(60, 170, 130), Thickness = 2.5 }))
			end
		end
		s.label = E.text(d, s.name, UDim2.fromScale(1.5, 0.22), UDim2.fromScale(0.5, 1.13), MID, INK, nil, false) -- outside the disc: the name never covers the icon
		s.label.ZIndex = 43
		s.sub = E.text(d, "", UDim2.fromScale(1.7, 0.15), UDim2.fromScale(0.5, 1.31), MID, Color3.fromRGB(112, 96, 138), nil, false) -- why a locked slot is locked
		s.sub.ZIndex = 43
		if s.key then
			s.cap = E.keyCap(d, s.key, UDim2.fromScale(0.3, 0.3), UDim2.fromScale(0.9, 0.12))
			s.cap.ZIndex = 44
		end
	end
	local hub = disc(holder, 0.2, 0.5, 0.52, BUTTER, 0, 41)
	new("UIGradient", hub, { Rotation = 90, Color = ColorSequence.new(WHITE, Color3.fromRGB(240, 228, 200)) })
	new("UIStroke", hub, { Color = INK, Thickness = 3 })
	local hubScale = new("UIScale", hub, { Scale = 1 })
	local hubName = E.text(hub, "TAB", UDim2.fromScale(0.86, 0.3), UDim2.fromScale(0.5, 0.4), MID, INK, nil, false)
	hubName.ZIndex = 43
	local hubWhy = E.text(hub, "", UDim2.fromScale(0.84, 0.2), UDim2.fromScale(0.5, 0.68), MID, OFF_INK, nil, false)
	hubWhy.ZIndex = 43
	local dot = disc(holder, 0.05, 0.5, 0.5, BUTTER, 0, 45) -- where the mouse has been pushed
	new("UIStroke", dot, { Color = INK, Thickness = 2 })

	local origin, sel, openedAt = Vector2.zero, nil, 0
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
			TweenService:Create(root, TweenInfo.new(0.15), { BackgroundTransparency = 0.36 }):Play() -- the scrim fades in with the pop
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
			sel = math.abs(v.X) > math.abs(v.Y) and (v.X > 0 and 2 or 4) or (v.Y < 0 and 1 or 3)
		end
		for i, s in SLOTS do
			local why = s.why()
			local off, on = why ~= nil, i == sel
			s.sub.Text = off and why or "" -- a locked slot keeps its name and says why underneath; its key cap goes (the key would not work either)
			if s.cap then s.cap.Visible = not off end
			-- unusable: a flat grey disc with a lock, never see-through (Gemini r1: transparency turned to sludge over the world)
			s.disc.BackgroundColor3 = off and OFF or (on and s.tint or s.fill)
			s.rim.Color, s.rim.Thickness = off and OFF_INK or INK, (on and not off) and 5 or 3
			s.label.TextColor3 = off and OFF_INK or INK
			s.lock.Visible = off
			if s.img then s.img.ImageTransparency, s.img.ImageColor3 = off and 0.72 or 0, off and Color3.fromRGB(170, 160, 190) or WHITE end
			if s.rings then for _, r in s.rings do r.Transparency = off and 0.6 or 0 end end
			s.scale.Scale += ((on and 1.14 or 1) - s.scale.Scale) * 0.35
		end
		local s = sel and SLOTS[sel]
		hubName.Text = s and s.name or ((tools and tools.Visible) and "TOOLS" or "TAB")
		hubWhy.Text = s and s.why() or (sel and "" or ((tools and tools.Visible) and "tap one" or "push and let go"))
	end)

	root.Activated:Connect(commit)
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
