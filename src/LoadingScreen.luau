-- LoadingScreen (ReplicatedStorage.Shared.LoadingScreen), started by PixelClient as soon as its top ScreenGui exists.
-- Directive v8, anchor A (2026-11-12). Reference: Instagram reel De8zUC1twcI (@kxjouanim), a logo drawn letter by letter by
-- strokes of liquid light; notes in the vault, Research/Process and Tools/Instagram Saved Posts Review (2026-11-12).
--   * a dark plum cavern backdrop with slow fog, crystal shards and two energy ribbons turning behind the title
--   * PIXEL DEPTH in blocky capitals: white-to-lavender faces, a magenta-to-violet extrusion, a soft neon halo. A streak of
--     light crosses each letter in turn and the letter snaps in behind it (0.8 -> 1.05 -> 1.0)
--   * a thin glowing progress line with a rolling percentage
--   * no black cut: the whole screen dissolves and pushes forward into Camp 1 once the game has loaded
-- Display only. Config.LOADING = { on, min } (min = shortest time on screen, seconds). The player attribute DevNoIntro skips it.
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local M = {}

local MID = Vector2.new(0.5, 0.5)
local MAGENTA, VIOLET, CYAN, LAV = Color3.fromRGB(255, 0, 127), Color3.fromRGB(155, 31, 232), Color3.fromRGB(96, 232, 255), Color3.fromRGB(214, 196, 255)
local PLUM, OBSIDIAN = Color3.fromRGB(22, 8, 30), Color3.fromRGB(8, 3, 14)

local function new(cls, parent, props)
	local o = Instance.new(cls)
	for k, v in props do o[k] = v end
	o.Parent = parent
	return o
end

function M.start(E)
	local cfg = E.C.LOADING or { on = true, min = 2.6 }
	if not cfg.on or E.plr:GetAttribute("DevNoIntro") then return end
	local gui = new("ScreenGui", E.plr:WaitForChild("PlayerGui"), { Name = "PixelLoading", IgnoreGuiInset = true, ResetOnSpawn = false, DisplayOrder = 100 })
	local all = new("CanvasGroup", gui, { Name = "All", Size = UDim2.fromScale(1, 1), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = MID, BackgroundColor3 = PLUM, BorderSizePixel = 0 })
	new("UIGradient", all, { Rotation = 90, Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, OBSIDIAN), ColorSequenceKeypoint.new(0.5, PLUM), ColorSequenceKeypoint.new(1, Color3.fromRGB(38, 12, 54)) }) })
	local zoom = new("UIScale", all, {})

	-- cavern depth fog: three wide soft bands drifting sideways
	local fog = {}
	for i = 1, 3 do
		local f = new("Frame", all, { Size = UDim2.fromScale(1.3, 0.34), Position = UDim2.fromScale(0.5, 0.3 + i * 0.16), AnchorPoint = MID, BackgroundColor3 = i == 2 and Color3.fromRGB(70, 30, 120) or Color3.fromRGB(110, 26, 110), BackgroundTransparency = 0.8, BorderSizePixel = 0, ZIndex = 1 })
		new("UIGradient", f, { Rotation = 90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(1, 1) }) })
		fog[i] = f
	end
	-- energy ribbons: long thin bands of light crossing behind the title
	local ribbons = {}
	for i, d in { { MAGENTA, -9, 0.4 }, { CYAN, 7, 0.47 } } do
		local r = new("Frame", all, { Size = UDim2.fromScale(1.5, 0.012), Position = UDim2.fromScale(0.5, d[3]), AnchorPoint = MID, Rotation = d[2], BackgroundColor3 = d[1], BorderSizePixel = 0, ZIndex = 2 })
		new("UIGradient", r, { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.35, 0.35), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(0.65, 0.35), NumberSequenceKeypoint.new(1, 1) }) })
		local halo = new("Frame", r, { Size = UDim2.fromScale(1, 7), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = MID, BackgroundColor3 = d[1], BackgroundTransparency = 0.88, BorderSizePixel = 0, ZIndex = 1 })
		new("UIGradient", halo, { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(1, 1) }) })
		ribbons[i] = { f = r, y = d[3], rot = d[2] }
	end
	-- crystal shards on a flat orbit behind the title
	local shards = {}
	local rng = Random.new(7)
	for i = 1, 16 do
		local s = new("Frame", all, { Size = UDim2.fromScale(0.012, 0.05), AnchorPoint = MID, BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 2 })
		new("UIGradient", s, { Rotation = 90, Color = ColorSequence.new(i % 2 == 0 and CYAN or MAGENTA, VIOLET), Transparency = NumberSequence.new(0, 0.5) })
		shards[i] = { f = s, a = i / 16 * math.pi * 2, r = rng:NextNumber(0.3, 0.46), sp = rng:NextNumber(0.25, 0.5), tilt = rng:NextNumber(-40, 40), k = rng:NextNumber(0.6, 1.5) }
	end

	-- the title: one cell per letter
	local WORD = "PIXEL DEPTH"
	local title = new("Frame", all, { Name = "Title", Size = UDim2.fromScale(0.3, 0.2), Position = UDim2.fromScale(0.5, 0.43), AnchorPoint = MID, BackgroundTransparency = 1, ZIndex = 5 })
	new("UIAspectRatioConstraint", title, { AspectRatio = #WORD * 0.62, DominantAxis = Enum.DominantAxis.Width })
	new("UIScale", title, { Scale = 2.5 }) -- scaled text is capped at 100 px: the word is laid out small and magnified
	local letters = {}
	local px = math.clamp(math.floor(workspace.CurrentCamera.ViewportSize.X * 0.3 / #WORD * 1.3), 8, 100) -- a fixed size, magnified by the UIScale: TextScaled stops at 100 px on screen
	local function glyph(parent, ch, pos, color, z, tr)
		return new("TextLabel", parent, { Text = ch, Font = Enum.Font.Arcade, TextSize = px, BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Position = pos, TextColor3 = color, TextTransparency = tr or 0, ZIndex = z })
	end
	for i = 1, #WORD do
		local ch = WORD:sub(i, i)
		if ch ~= " " then
			local cell = new("Frame", title, { Size = UDim2.fromScale(1 / #WORD, 1), Position = UDim2.fromScale((i - 0.5) / #WORD, 0.5), AnchorPoint = MID, BackgroundTransparency = 1, ZIndex = 5 })
			local box = new("Frame", cell, { Size = UDim2.fromScale(1.75, 1.75), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = MID, BackgroundTransparency = 1, Visible = false, ZIndex = 5 }) -- wider than its cell: the font has wide side bearings
			local sc = new("UIScale", box, { Scale = 0.8 })
			local jelly = cfg.letters and cfg.letters[ch]
			local halo
			if jelly then -- a 3D jelly glass letter (the user, 2026-11-12, reference reel DfUpUhcuASY): a rendered picture, with a glow behind and a glint that crosses it
				halo = new("ImageLabel", box, { Image = jelly, ImageColor3 = MAGENTA, ImageTransparency = 0.6, BackgroundTransparency = 1, Size = UDim2.fromScale(1.28, 1.28), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = MID, ZIndex = 3 })
				local img = new("ImageLabel", box, { Name = "Jelly", Image = jelly, BackgroundTransparency = 1, Size = UDim2.fromScale(1.12, 1.12), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = MID, ScaleType = Enum.ScaleType.Stretch, ZIndex = 6 }) -- Stretch: the picture itself squashes and stretches with its frame
				new("UIAspectRatioConstraint", img, { AspectRatio = 1 })
				new("UIAspectRatioConstraint", halo, { AspectRatio = 1 })
				if cfg.hot and cfg.hot[ch] then -- the same letter in white, laid over it while it is still hot from landing
					new("ImageLabel", img, { Name = "Hot", Image = cfg.hot[ch], BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ScaleType = Enum.ScaleType.Stretch, ZIndex = 7 })
				end
			else
			halo = glyph(box, ch, UDim2.new(), MAGENTA, 3, 0.55) -- the neon bloom: a wide soft outline behind everything
			new("UIStroke", halo, { Color = MAGENTA, Thickness = 9, Transparency = 0.78 })
			for d = 6, 1, -1 do -- the extrusion: magenta near the face, deep violet at the back
				glyph(box, ch, UDim2.fromScale(d * 0.014, d * 0.02), MAGENTA:Lerp(Color3.fromRGB(70, 10, 120), (d - 1) / 5), 4)
			end
			local face = glyph(box, ch, UDim2.new(), Color3.new(1, 1, 1), 6)
			new("UIGradient", face, { Rotation = 90, Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)), ColorSequenceKeypoint.new(0.55, Color3.new(1, 1, 1)), ColorSequenceKeypoint.new(1, LAV) }) })
			new("UIStroke", face, { Color = Color3.fromRGB(60, 8, 110), Thickness = 1.5 })
			end
			table.insert(letters, { box = box, sc = sc, halo = halo, cell = cell, jelly = box:FindFirstChild("Jelly") })
		end
	end

	-- the progress line
	local bar = new("Frame", all, { Size = UDim2.fromScale(0.4, 0.022), Position = UDim2.fromScale(0.5, 0.84), AnchorPoint = MID, BackgroundColor3 = Color3.fromRGB(60, 30, 90), BackgroundTransparency = 0.3, BorderSizePixel = 0, ZIndex = 5 })
	new("UICorner", bar, { CornerRadius = UDim.new(0.5, 0) })
	local fill = new("Frame", bar, { Size = UDim2.fromScale(0, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 6 })
	new("UICorner", fill, { CornerRadius = UDim.new(0.5, 0) })
	new("UIGradient", fill, { Color = ColorSequence.new(CYAN, MAGENTA) })
	local glow = new("Frame", fill, { Size = UDim2.new(1, 0, 2.4, 0), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = MID, BackgroundColor3 = MAGENTA, BackgroundTransparency = 0.8, BorderSizePixel = 0, ZIndex = 5 })
	new("UICorner", glow, { CornerRadius = UDim.new(0.5, 0) })
	local pct = new("TextLabel", all, { Text = "0%", Font = Enum.Font.Arcade, TextScaled = true, TextColor3 = LAV, BackgroundTransparency = 1, Size = UDim2.fromScale(0.2, 0.07), Position = UDim2.fromScale(0.5, 0.915), AnchorPoint = MID, ZIndex = 5 })

	do -- the percentage in cyan jelly digits (the plain arcade digits were the last non-jelly text on this screen)
		local ok, JellyText = pcall(function() return require(script.Parent:WaitForChild("JellyText")) end)
		if ok and JellyText then JellyText.mirror(pct, { color = Color3.fromRGB(110, 215, 255), sway = false }) end
	end
	-- four-point star glints that pop beside a letter as it lands, and now and then afterwards
	local function sparkle(cell, k)
		local s = new("Frame", cell, { Size = UDim2.fromScale(0.34, 0.34), Position = UDim2.fromScale(0.5 + (math.random() - 0.5) * 1.1, 0.5 + (math.random() - 0.5) * 0.9), AnchorPoint = MID, BackgroundTransparency = 1, Rotation = math.random(-20, 20), ZIndex = 9 })
		new("UIAspectRatioConstraint", s, { AspectRatio = 1 })
		local sc = new("UIScale", s, { Scale = 0 })
		for _, d in { { 1, 0.14 }, { 0.14, 1 } } do -- two thin diamonds make the star
			local arm = new("Frame", s, { Size = UDim2.fromScale(d[1], d[2]), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = MID, BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 9 })
			new("UICorner", arm, { CornerRadius = UDim.new(0.5, 0) })
			new("UIGradient", arm, { Rotation = d[1] == 1 and 0 or 90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(1, 1) }) })
		end
		task.delay((k or 0) * 0.06, function()
			local up = TweenService:Create(sc, TweenInfo.new(0.16, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 0.5 + math.random() * 0.7 })
			up.Completed:Connect(function()
				local down = TweenService:Create(sc, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = 0 })
				down.Completed:Connect(function() s:Destroy() end)
				down:Play()
			end)
			up:Play()
			TweenService:Create(s, TweenInfo.new(0.46), { Rotation = s.Rotation + 90 }):Play()
		end)
	end
	-- The motion, measured frame by frame on the reference reel (Instagram De8zUC1twcI, 30 fps, one 2.2 s loop; the numbers
	-- are in the vault brief "Glass and Jelly UI"): nothing moves in a straight line.
	--   * a spark drops in first; each letter then arrives 1.8 times too tall, thin and leaning, white-hot, and springs to shape
	--     at about 4.5 swings a second, so five or six letters are in motion at once
	--   * the word starts squeezed to the left (55% of its width), holds at 84%, then snaps out 5% too wide and comes back
	--   * the last letter lands with a drip that hangs 1.7 times too long and snaps back
	--   * then the shake: the whole word is thrown about 9% to the right and springs back, a ripple runs back through the
	--     letters, and the white heat cools to colour
	local function spring(x, freq, zeta) -- a damped spring toward .goal; .kick(v) adds speed
		local sp = { x = x, v = 0, goal = x }
		local w = 2 * math.pi * freq
		function sp.step(dt)
			dt = math.min(dt, 1 / 30)
			sp.v += (-(w * w) * (sp.x - sp.goal) - 2 * zeta * w * sp.v) * dt
			sp.x += sp.v * dt
			return sp.x
		end
		return sp
	end
	local n = #letters
	for k, l in letters do
		local beat = ({ 0, 0.08, 0.17, 0.27, 0.38 })[(k - 1) % 5 + 1] -- one letter at a time, each a little later than the last: never an even tick
		l.at = 0.3 + beat + (k > n / 2 and 0.62 or 0) -- the second word waits a beat: the hold in the middle
		l.sy = spring(1.8, 4.5, 0.3)
		l.sy.goal = 1
		l.rot = spring(-20, 4, 0.35)
		l.rot.goal = 0
		l.heat = 1
		l.slot = l.cell.Position.X.Scale
		l.hot = l.jelly and l.jelly:FindFirstChild("Hot")
		l.sc.Scale = 1
	end
	local slamAt = letters[n].at + 0.13
	local spread, kickX, kickY, tilt, punch = spring(0.55, 4.2, 0.32), spring(0, 4.5, 0.28), spring(0, 5, 0.3), spring(-6, 3.5, 0.35), spring(0, 5, 0.35)
	spread.goal, tilt.goal = 0.84, 0
	local titleScale = title:FindFirstChildOfClass("UIScale")
	local spark = new("Frame", title, { Size = UDim2.fromScale(0.012, 0.3), Position = UDim2.fromScale(0.06, -0.5), AnchorPoint = MID, Rotation = 18, BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 9 })
	new("UICorner", spark, { CornerRadius = UDim.new(0.5, 0) })
	new("UIStroke", spark, { Color = MAGENTA, Thickness = 3, Transparency = 0.4 })
	spark.Visible = false
	-- The logo runs on its own clock. It starts only when every letter picture has loaded and a few frames have drawn, and it
	-- never jumps ahead after a slow frame: on a real join the first second is full of hitches, and with the wall clock all
	-- ten letters were already "due" by the first frame that drew, so they popped in together (the user, 2026-11-12).
	local ready, frames, clock, sparked = false, 0, 0, false
	task.spawn(function()
		local list = {}
		for _, set in { cfg.letters or {}, cfg.hot or {} } do
			for _, id in set do table.insert(list, id) end
		end
		local done = false
		task.spawn(function()
			pcall(function() game:GetService("ContentProvider"):PreloadAsync(list) end)
			done = true
		end)
		local t = os.clock()
		while not done and os.clock() - t < 6 do task.wait() end -- never hold the screen for more than six seconds
		ready = true
	end)
	local slammed = false
	local shownAt = {}

	local t0, shown, done = os.clock(), 0, false
	local conn
	conn = RunService.RenderStepped:Connect(function(dt)
		local now = os.clock() - t0
		for i, f in fog do f.Position = UDim2.fromScale(0.5 + math.sin(now * 0.22 + i * 2) * 0.12, 0.3 + i * 0.16) end
		for i, r in ribbons do
			r.f.Position = UDim2.fromScale(0.5 + math.sin(now * 0.5 + i) * 0.05, r.y + math.sin(now * 0.8 + i * 1.7) * 0.025)
			r.f.Rotation = r.rot + math.sin(now * 0.6 + i) * 3
		end
		for _, s in shards do
			s.a += dt * s.sp
			local depth = math.sin(s.a) -- -1 far .. 1 near
			s.f.Position = UDim2.fromScale(0.5 + math.cos(s.a) * s.r, 0.43 + depth * 0.13)
			s.f.Size = UDim2.fromScale(0.009 * s.k * (0.7 + 0.4 * depth), 0.06 * s.k * (0.7 + 0.4 * depth))
			s.f.Rotation = s.tilt + now * 30 * s.sp
			s.f.BackgroundTransparency = 0.35 - 0.3 * depth
		end
		-- the word: its spread, the slam and the shake after it
		frames += 1
		if ready and frames > 4 then clock += math.min(dt, 1 / 30) end
		local real = now
		now = clock -- from here to the end of the letters, time is the logo's own clock
		if clock > 0 and not sparked then
			sparked = true
			spark.Visible = true
			TweenService:Create(spark, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 0.14), { Position = UDim2.fromScale(0.05, 0.5), Size = UDim2.fromScale(0.02, 0.9) }):Play()
			task.delay(0.32, function() spark:Destroy() end)
		end
		if not slammed and now >= slamAt - 0.25 then spread.goal = 1 end
		if not slammed and now >= slamAt then
			slammed = true
			E.plr:SetAttribute("DevLoadTimes", table.concat(shownAt, " ")) -- read by a test: the letters must be spread out, not together
			kickX.v, kickY.v, tilt.v, punch.v = 3.8, 7, 46, 1.6
			for k, l in letters do
				task.delay((n - k) * 0.018, function() -- the ripple runs back from the last letter to the first
					l.sy.v -= 3.2 + math.random() * 1.6
					l.rot.v += (math.random() - 0.5) * 160
					l.heat = math.max(l.heat, 0.55)
					sparkle(l.cell, 0)
				end)
			end
		end
		local sp, kx, ky = spread.step(dt), kickX.step(dt), kickY.step(dt)
		title.Rotation = tilt.step(dt)
		if titleScale then titleScale.Scale = 2.5 * (1 + punch.step(dt) * 0.03) end
		for i, l in letters do
			if now >= l.at then
				if not l.box.Visible then
					l.box.Visible = true
					shownAt[#shownAt + 1] = string.format("%.2f", real) -- wall-clock second each letter appeared, for the timing test
					for k = 1, 2 do sparkle(l.cell, k) end
					if i == n then task.delay(0.09, function() l.sy.v += 9 end) end -- the last letter's drip
				end
				local sy = math.clamp(l.sy.step(dt), 0.45, 2.2)
				local sx = math.clamp(1 / math.sqrt(sy), 0.5, 1.5) -- jelly keeps its volume: taller means thinner
				local rot = l.rot.step(dt)
				l.heat *= math.exp(-dt * 4.5)
				l.cell.Position = UDim2.fromScale(0.04 + (l.slot - 0.04) * sp + kx, 0.5 + ky + (i == n and (sy - 1) * 0.22 or 0))
				local breath = 0.5 + 0.2 * math.sin(now * 3 - i * 0.5)
				if l.jelly then
					local idle = slammed and 1 or 0
					l.jelly.Size = UDim2.fromScale(1.12 * sx, 1.12 * sy)
					l.jelly:FindFirstChildOfClass("UIAspectRatioConstraint").AspectRatio = sx / sy
					l.jelly.Rotation = rot + idle * math.sin(now * 1.7 + i) * 2
					l.jelly.Position = UDim2.fromScale(0.5, 0.5 + idle * math.sin(now * 2.1 + i * 0.7) * 0.025)
					l.halo.ImageTransparency = math.clamp(breath + 0.1 - l.heat * 0.6, 0, 1)
					l.halo.ImageColor3 = MAGENTA:Lerp(Color3.new(1, 1, 1), math.min(l.heat, 1))
					if l.hot then l.hot.ImageTransparency = 1 - math.min(l.heat * 1.1, 1) end
					if slammed and math.random() < dt * 0.3 then sparkle(l.cell) end
				else
					l.sc.Scale = sy
					l.box.Rotation = rot
					l.halo.TextTransparency = breath
				end
			end
		end
		now = real
		local loaded = game:IsLoaded() and E.plr.Character ~= nil and clock > slamAt + 0.9 -- the logo always finishes its landing and shake
		local goal = math.min(now / cfg.min, loaded and 1 or 0.9)
		shown += (goal - shown) * math.min(1, dt * 8)
		fill.Size = UDim2.fromScale(shown, 1)
		pct.Text = math.floor(shown * 100 + 0.5) .. "%"
		if not done and shown > 0.985 and now >= cfg.min then
			done = true
			conn:Disconnect()
			pct.Text, fill.Size = "100%", UDim2.fromScale(1, 1)
			-- dissolve forward into the camp: the screen fades while it pushes toward the player, never through black
			TweenService:Create(zoom, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = 1.35 }):Play()
			local out = TweenService:Create(all, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { GroupTransparency = 1 })
			out.Completed:Connect(function() gui:Destroy() end)
			out:Play()
		end
	end)
	return gui
end

return M
