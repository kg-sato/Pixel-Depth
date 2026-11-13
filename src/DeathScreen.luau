-- DeathScreen (ReplicatedStorage.Shared.DeathScreen), started by PixelClient: the defeat screens (the user, 2026-11-10: the
-- death screen was a bare line of text; then "improve the death screen / caught screen").
--   death   E.vmHook.death(lost, why), when the server has woken us at Camp 1 after a fall ("fell") or a faint in the lake:
--           the view tumbles, the dark closes in from the edges with drifting soot, the HUD steps away, and a card shows a
--           snuffed lantern, the lost ore counting down and a bar that fills while you wake. Then embers at the campfire.
--   grabbed Fx "grabbed" (a Gloomling holds you for a few seconds): soot presses in from the edges, a card counts the hold
--           down and tells you to flare (R). It ends on a rescue or on the catch.
--   caught  Fx "caught" (it took ore): the card shows what it took and the golden shield running out.
-- cave.caughtUI tells Shared.GloomClient these cards replace its toasts.
local M = {}

function M.start(E)
	local RunService = game:GetService("RunService")
	local new, text, tween, top, C = E.new, E.text, E.tween, E.top, E.C
	local DARK, SOOT, PLUM, EDGE = Color3.fromRGB(22, 14, 36), Color3.fromRGB(60, 38, 92), Color3.fromRGB(44, 30, 64), Color3.fromRGB(128, 100, 176)
	local GOLD, PINK, MINT = E.GOLD, E.PINK, E.MINT
	local calm = false
	pcall(function() calm = game:GetService("GuiService").ReducedMotionEnabled end)
	local UIS = game:GetService("UserInputService")
	local touch = UIS.TouchEnabled and not UIS.KeyboardEnabled -- a phone has no R key: name the flare button instead

	local layer = new("Frame", top, { Name = "DeathScreen", Size = UDim2.fromScale(1, 1), BackgroundColor3 = DARK, BackgroundTransparency = 1, Visible = false, ZIndex = 60 })
	local edges = {}
	for i, rot in { 0, 180, 90, 270 } do -- four soft bands of dark that close in from the edges
		local f = new("Frame", layer, { Size = UDim2.fromScale(1, 1), BackgroundColor3 = SOOT, BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 61 })
		new("UIGradient", f, { Rotation = rot, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.3, 1), NumberSequenceKeypoint.new(1, 1) }) })
		edges[i] = f
	end
	local function soot(n, color)
		if calm then return end
		for _ = 1, n do -- small dark flakes drift from the edges to the middle
			local a = math.random() * math.pi * 2
			local s = math.random(6, 16)
			local p = new("Frame", layer, { Size = UDim2.fromOffset(s, s), Position = UDim2.fromScale(0.5 + math.cos(a) * 0.62, 0.5 + math.sin(a) * 0.62), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = (color or SOOT):Lerp(Color3.new(0, 0, 0), math.random() * 0.5), BorderSizePixel = 0, Rotation = math.random(0, 90), ZIndex = 62 })
			tween(p, 1.1 + math.random() * 0.8, { Position = UDim2.fromScale(0.5 + math.cos(a) * 0.2, 0.5 + math.sin(a) * 0.2), BackgroundTransparency = 1, Rotation = p.Rotation + 180 }, Enum.EasingStyle.Sine, Enum.EasingDirection.In)
			task.delay(2, function() p:Destroy() end)
		end
	end
	-- one card for all three screens: a dark glass plate with a soft edge, an icon, a title, a big line, a note and a bar
	local card = new("Frame", layer, { Size = UDim2.fromScale(0.36, 0.4), Position = UDim2.fromScale(0.5, 0.48), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = PLUM, BackgroundTransparency = 0.06, BorderSizePixel = 0, Visible = false, ZIndex = 63 })
	new("UIAspectRatioConstraint", card, { AspectRatio = 1.75 })
	new("UICorner", card, { CornerRadius = UDim.new(0.09, 0) })
	local stroke = new("UIStroke", card, { Color = EDGE, Thickness = 3 })
	local scale = new("UIScale", card, { Scale = 1 })
	local function block(parent, size, pos, color, z)
		local f = new("Frame", parent, { Size = size, Position = pos, AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = color, BorderSizePixel = 0, ZIndex = z or 64 })
		new("UICorner", f, { CornerRadius = UDim.new(0.18, 0) })
		return f
	end
	-- the icon: a small voxel lantern (cap, glass, base) whose wick is lit or snuffed
	local icon = new("Frame", card, { Size = UDim2.fromScale(0.16, 0.3), Position = UDim2.fromScale(0.5, 0.19), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, ZIndex = 64 })
	new("UIAspectRatioConstraint", icon, { AspectRatio = 0.8 })
	local CREAM = Color3.fromRGB(255, 235, 175) -- a pale lantern: the lilac one sank into the card
	block(icon, UDim2.fromScale(0.5, 0.12), UDim2.fromScale(0.5, 0.06), CREAM)
	block(icon, UDim2.fromScale(0.86, 0.14), UDim2.fromScale(0.5, 0.2), CREAM)
	local glass = block(icon, UDim2.fromScale(0.7, 0.52), UDim2.fromScale(0.5, 0.53), Color3.fromRGB(104, 88, 140))
	block(icon, UDim2.fromScale(0.86, 0.14), UDim2.fromScale(0.5, 0.88), CREAM)
	local wick = block(glass, UDim2.fromScale(0.34, 0.5), UDim2.fromScale(0.5, 0.58), GOLD, 65)
	local title = text(card, "", UDim2.fromScale(0.88, 0.17), UDim2.fromScale(0.5, 0.45), Vector2.new(0.5, 0.5), E.LILAC, 700)
	local big = text(card, "", UDim2.fromScale(0.8, 0.17), UDim2.fromScale(0.5, 0.63), Vector2.new(0.5, 0.5), PINK, 700, false)
	local note = text(card, "", UDim2.fromScale(0.84, 0.085), UDim2.fromScale(0.5, 0.78), Vector2.new(0.5, 0.5), E.CREAM, 700, false)
	title.ZIndex, big.ZIndex, note.ZIndex = 64, 64, 64
	if E.GLASS then -- cut-glass kit: the big line is jelly, taking each screen's own colour and landing with a pop
		big.Size = UDim2.fromScale(0.86, 0.22)
		require(script.Parent:WaitForChild("JellyText")).mirror(big, { color = PINK, followColor = true, popOnChange = true, glow = true, maxLen = 26 })
	end
	local track = block(card, UDim2.fromScale(0.7, 0.05), UDim2.fromScale(0.5, 0.9), Color3.fromRGB(84, 64, 112))
	local fill = new("Frame", track, { Size = UDim2.fromScale(0, 1), BackgroundColor3 = GOLD, BorderSizePixel = 0, ZIndex = 65 })
	new("UICorner", fill, { CornerRadius = UDim.new(0.5, 0) })

	local playing = false -- the death screen is up (declared here: show and hide below read it)
	local token = 0 -- every show takes a new number: a later screen cancels an earlier one's timers
	local function show(opts)
		token += 1
		local my = token
		layer.Visible, card.Visible = true, true
		E.vmHook.cardUp = true
		if opts.hud == false then E.gui.Enabled = false end
		title.Text, title.TextColor3 = opts.title, opts.titleColor or E.LILAC
		big.Text, big.TextColor3 = opts.big or "", opts.bigColor or PINK
		note.Text = opts.note or ""
		stroke.Color, fill.BackgroundColor3 = opts.edge or EDGE, opts.bar or GOLD
		wick.BackgroundColor3, wick.Size = opts.lit and GOLD or Color3.fromRGB(86, 80, 96), opts.lit and UDim2.fromScale(0.34, 0.5) or UDim2.fromScale(0.2, 0.2)
		card.Position = UDim2.fromScale(0.5, opts.y or 0.48)
		scale.Scale = 0.8
		tween(scale, 0.3, { Scale = opts.scale or 1 }, Enum.EasingStyle.Back)
		fill.Size = UDim2.fromScale(opts.drain and 1 or 0, 1)
		tween(fill, opts.secs, { Size = UDim2.fromScale(opts.drain and 0 or 1, 1) }, Enum.EasingStyle.Linear)
		tween(layer, 0.4, { BackgroundTransparency = opts.dark or 1 })
		for _, f in edges do
			f.BackgroundColor3 = opts.edgeColor or SOOT
			tween(f, 0.3, { BackgroundTransparency = opts.edges or 0 })
		end
		return my
	end
	local function hide(my, after)
		if my ~= token then return end
		tween(scale, 0.2, { Scale = 0.85 })
		tween(layer, after or 0.5, { BackgroundTransparency = 1 })
		for _, f in edges do tween(f, after or 0.5, { BackgroundTransparency = 1 }) end
		task.delay(0.2, function() if my == token then card.Visible = false end end)
		task.delay((after or 0.5) + 0.05, function()
			if my == token then
				layer.Visible = false
				E.vmHook.cardUp = false
				if not playing then E.gui.Enabled = true end
			end
		end)
	end

	local tumbleAt = -10
	RunService:BindToRenderStep("PD_DeathTumble", Enum.RenderPriority.Camera.Value + 3, function()
		local t = (os.clock() - tumbleAt) / 0.9
		if t >= 1 or calm then return end
		local k = (1 - t) ^ 2 -- the view rolls over and looks up at the way we fell, then settles
		local cam = workspace.CurrentCamera
		cam.CFrame = cam.CFrame * CFrame.Angles(0.9 * k, 0, 1.4 * k * math.sin(t * 5))
	end)

	E.vmHook.death = function(lost, why)
		if playing then return end
		playing = true
		lost = lost or 0
		tumbleAt = os.clock()
		E.sfx("land", 0.6)
		soot(28)
		local my = show({ title = why == "fell" and "LOST TO THE GLOOM" or "THE LAKE TOOK YOU", big = lost > 0 and ("-" .. E.commas(lost) .. " ORE") or "NOTHING LOST",
			note = "Waking by the campfire...", secs = 2.6, dark = 0, edges = 0 })
		task.delay(0.4, function() if playing then E.gui.Enabled = false end end) -- the HUD showed through the dark
		task.delay(0.35, function()
			E.sfx("error", 0.7)
			if lost > 0 then -- the lost ore counts down to nothing
				local t0 = os.clock()
				while os.clock() - t0 < 0.9 and my == token do
					big.Text = "-" .. E.commas(math.ceil(lost * (1 - (os.clock() - t0) / 0.9))) .. " ORE"
					task.wait(0.04)
				end
				if my == token then big.Text = "-" .. E.commas(lost) .. " ORE" end
			end
		end)
		task.delay(2.7, function()
			E.gui.Enabled = true
			playing = false
			hide(my, 0.7)
			local h = E.hrp()
			if h and E.burst then E.burst(h.Position + h.CFrame.LookVector * 4 - Vector3.new(0, 2, 0), Vector3.yAxis, Color3.fromRGB(255, 170, 84), 26) end -- embers
		end)
	end
	E.vmHook.deathPlaying = function() return playing end

	-- the Gloomling screens
	if E.cave then E.cave.caughtUI = true end
	E.R.Fx.OnClientEvent:Connect(function(kind, a, b)
		if playing then return end
		if kind == "grabbed" then
			local secs = a or C.GLOOM.grab
			soot(16)
			local my = show({ title = "GRABBED!", titleColor = PINK, big = touch and "TAP THE FLARE!" or "FLARE NOW   [ R ]", bigColor = GOLD, note = "or a friend can flare you free", secs = secs, drain = true,
				bar = PINK, edge = PINK, lit = true, y = 0.3, scale = 0.8, dark = 0.7, edges = 0.15, hud = false })
			task.spawn(function() -- the plate shivers while it holds you
				while my == token and layer.Visible do
					card.Rotation = calm and 0 or math.noise(os.clock() * 16, 4) * 5
					task.wait()
				end
				card.Rotation = 0
			end)
			task.delay(secs + 0.4, function() hide(my) end)
		elseif kind == "caught" and (a or 0) >= 0 then
			soot(20)
			local hr = E.hrp()
			local who = (hr and (hr.Position - E.C.CAVE2_ORIGIN).Magnitude < 130) and "CLAYLING" or "GLOOMLING" -- the Clay Caves hall has claylings (server: Gloom kind 2)
			local my = show({ title = a > 0 and ("A " .. who .. " GOT YOUR ORE") or ("A " .. who .. " GOT YOU"), titleColor = PINK, big = a > 0 and ("-" .. E.commas(a) .. " ORE") or "NOTHING LOST",
				note = "Golden shield: RUN to the light!", secs = C.GLOOM.shield, drain = true, bar = GOLD, edge = GOLD, y = 0.3, scale = 0.8, dark = 0.85, edges = 0.74, edgeColor = GOLD, hud = false }) -- golden edges: the shield the card promises
			task.delay(2.4, function() hide(my) end)
		elseif kind == "rescued" then
			local my = show({ title = b and "FLARED FREE!" or "RESCUED!", titleColor = MINT, big = "NOTHING LOST", bigColor = MINT, note = b and "" or ("by " .. tostring(a)), secs = 1.2,
				bar = MINT, edge = MINT, lit = true, y = 0.4, scale = 0.8, dark = 1, edges = 1 })
			task.delay(1.3, function() hide(my, 0.3) end)
		end
	end)
end

return M
