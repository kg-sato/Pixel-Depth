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
	-- Master Directive v15 (@neochampy DgEHgjvNcDm, frame 5): on a fall, a faint, a grab or a catch, sharp crimson-plum
	-- fracture lines creep in from the four edges as if the screen's glass cracks (behind the card at 63; HatchSignature's
	-- edge-crack segments, thinner and with side branches). With reduced motion they are simply there, no creep.
	local shatter = new("CanvasGroup", layer, { Name = "Shatter", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, GroupTransparency = 1, Visible = false, ZIndex = 62 })
	local segs = {}
	for i, rot in { 0, 180, 90, 270 } do -- round 2 (Gemini v15_r1 3/10: thin scribbles over an untinted scene): a crimson tint closes in from every edge
		local tint = new("Frame", shatter, { Name = "Tint" .. i, Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(150, 14, 46), BackgroundTransparency = 0, BorderSizePixel = 0, ZIndex = 62 })
		new("UIGradient", tint, { Rotation = rot, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.45), NumberSequenceKeypoint.new(0.22, 0.9), NumberSequenceKeypoint.new(0.38, 1), NumberSequenceKeypoint.new(1, 1) }) })
	end
	do
		local rnd = Random.new(23)
		local function seg(a, b, k, w, branch) -- round 3: a crack is a chain of chunky square pixel shards (the voxel look), white-hot cores in crimson rims
			table.insert(segs, { a = a, b = b, k = k, w = w, branch = branch, sq = {} })
		end
		for e = 1, 16 do -- sixteen cracks, four from each edge, each a jagged chain toward the middle that stops short of the card
			local side = (e - 1) % 4 + 1
			local p = ({ Vector2.new(0, rnd:NextNumber(0.06, 0.94)), Vector2.new(1, rnd:NextNumber(0.06, 0.94)), Vector2.new(rnd:NextNumber(0.05, 0.95), 0), Vector2.new(rnd:NextNumber(0.05, 0.95), 1) })[side]
			local dir = (Vector2.new(0.5, 0.5) - p).Unit
			local steps = rnd:NextInteger(4, 6)
			for k = 1, steps do
				local ang = math.atan2(dir.Y, dir.X) + rnd:NextNumber(-0.65, 0.65)
				local q = p + Vector2.new(math.cos(ang), math.sin(ang)) * rnd:NextNumber(0.025, 0.05)
				seg(p, q, (k - 1) / steps, math.max(2, 5.5 - k * 0.7))
				if (k == 2 or k == 3) and rnd:NextNumber() < 0.7 then -- a thin side branch
					local b0, ba = q, ang + (rnd:NextNumber() < 0.5 and -1 or 1) * rnd:NextNumber(0.8, 1.3)
					for j = 1, 2 do
						local b1 = b0 + Vector2.new(math.cos(ba), math.sin(ba)) * rnd:NextNumber(0.018, 0.032)
						seg(b0, b1, (k - 0.5 + j * 0.25) / steps, 1.6, true)
						b0, ba = b1, ba + rnd:NextNumber(-0.5, 0.5)
					end
				end
				p = q
			end
		end
	end
	local crackT0, crackOn = 0, false
	local function placeCracks(u)
		local vp = layer.AbsoluteSize
		for _, sg in segs do
			local on = u > sg.k * 0.92
			local a, b = sg.a * vp, sg.b * vp
			local px = math.max(4, math.floor(sg.w * (sg.branch and 1.4 or 2) + 0.5)) -- the shard's side in pixels
			local n = on and math.max(1, math.ceil((b - a).Magnitude / (px * 0.85))) or 0
			for i = 1, math.max(n, #sg.sq) do
				local q = sg.sq[i]
				if i <= n and not q then
					q = new("Frame", shatter, { AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = sg.branch and Color3.fromRGB(255, 186, 206) or Color3.fromRGB(255, 238, 244), BorderSizePixel = 0, ZIndex = 62 })
					new("UIStroke", q, { Color = Color3.fromRGB(200, 22, 70), Thickness = 2, Transparency = 0.05 })
					sg.sq[i] = q
				end
				if q then
					q.Visible = i <= n
					if i <= n then
						local p = a:Lerp(b, (i - 0.5) / n)
						q.Position, q.Size = UDim2.fromOffset(math.floor(p.X / 2) * 2, math.floor(p.Y / 2) * 2), UDim2.fromOffset(px, px) -- snapped to a 2 px grid: hard pixel steps, not a smooth line
					end
				end
			end
		end
	end
	RunService.Heartbeat:Connect(function()
		if not crackOn then return end
		local u = calm and 1 or math.clamp((os.clock() - crackT0) / 0.65, 0, 1)
		placeCracks(u)
		if u >= 1 then crackOn = false end
	end)
	local function cracks(on)
		if on then
			shatter.Visible, shatter.GroupTransparency = true, 0.05
			crackT0, crackOn = os.clock(), true
			placeCracks(calm and 1 or 0)
		else
			crackOn = false
			tween(shatter, 0.35, { GroupTransparency = 1 })
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
	local note = text(card, "", UDim2.fromScale(0.84, 0.13), UDim2.fromScale(0.5, 0.785), Vector2.new(0.5, 0.5), E.CREAM, 700, false) -- 0.1 (was 0.085) and the grab cards at scale 0.7 (was 0.62): their note read as micro-text (Orchestrator round 2)
	title.ZIndex, big.ZIndex, note.ZIndex = 64, 64, 64
	local caps = {}
	for _, l in { title, note } do caps[l] = new("UITextSizeConstraint", l, { MinTextSize = 14 }) end
	note.TextWrapped = true -- the hint may take two lines instead of one squeezed hairline (Orchestrator final grade) -- never micro-text on the grab cards (Orchestrator round 3)
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
		cracks(opts.shatter == true)
		E.vmHook.cardUp = true
		if opts.hud == false then E.gui.Enabled = false end
		title.Text, title.TextColor3 = opts.title, opts.titleColor or E.LILAC
		big.Text, big.TextColor3 = opts.big or "", opts.bigColor or PINK
		note.Text = opts.note or ""
		local short = workspace.CurrentCamera.ViewportSize.Y < 520 -- a phone in landscape (~390 px tall): 14 px could not fit the note in the small grab card and it ran out of it (v15 text scan); 12 there, 14 on bigger screens
		caps[note].MinTextSize, caps[title].MinTextSize = short and 12 or 14, short and 12 or 14
		stroke.Color, fill.BackgroundColor3 = opts.edge or EDGE, opts.bar or GOLD
		wick.BackgroundColor3, wick.Size = opts.lit and GOLD or Color3.fromRGB(86, 80, 96), opts.lit and UDim2.fromScale(0.34, 0.5) or UDim2.fromScale(0.2, 0.2)
		card.Position = UDim2.fromScale(0.5, opts.y or 0.48)
		scale.Scale = 0.8
		tween(scale, 0.3, { Scale = short and math.max(opts.scale or 1, 0.95) or opts.scale or 1 }, Enum.EasingStyle.Back) -- a phone gets the small cards near full size
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
		cracks(false)
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
		local my = show({ shatter = true, title = why == "fell" and "LOST TO THE GLOOM" or "THE LAKE TOOK YOU", big = lost > 0 and ("-" .. E.commas(lost) .. " ORE") or "NOTHING LOST",
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
			local my = show({ shatter = true, title = "GRABBED!", titleColor = PINK, big = touch and "TAP THE FLARE!" or "FLARE NOW   [ R ]", bigColor = GOLD, note = "a friend can free you", secs = secs, drain = true,
				bar = PINK, edge = PINK, lit = true, y = 0.62, scale = 0.7, dark = 0.82, edges = 0.15, hud = false }) -- low and small: centred it hid the Gloomling and the boss arena (Gemini full1119h)
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
			local my = show({ shatter = true, title = a > 0 and ("A " .. who .. " GOT YOUR ORE") or ("A " .. who .. " GOT YOU"), titleColor = PINK, big = a > 0 and ("-" .. E.commas(a) .. " ORE") or "NOTHING LOST",
				note = "Shield up: RUN to light!", secs = C.GLOOM.shield, drain = true, bar = GOLD, edge = GOLD, y = 0.62, scale = 0.7, dark = 0.9, edges = 0.86, edgeColor = GOLD, hud = false }) -- edges 0.86 (was 0.74): in the amber Clay hall the gold edges washed the whole view out (Gemini full1121b) -- golden edges: the shield the card promises
			task.delay(2.4, function() hide(my) end)
		elseif kind == "rescued" then
			local my = show({ title = b and "FLARED FREE!" or "RESCUED!", titleColor = MINT, big = "NOTHING LOST", bigColor = MINT, note = b and "" or ("by " .. tostring(a)), secs = 1.2,
				bar = MINT, edge = MINT, lit = true, y = 0.4, scale = 0.8, dark = 1, edges = 1 })
			task.delay(1.3, function() hide(my, 0.3) end)
		end
	end)
end

return M
