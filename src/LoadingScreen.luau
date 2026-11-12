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
			local halo = glyph(box, ch, UDim2.new(), MAGENTA, 3, 0.55) -- the neon bloom: a wide soft outline behind everything
			new("UIStroke", halo, { Color = MAGENTA, Thickness = 9, Transparency = 0.78 })
			for d = 6, 1, -1 do -- the extrusion: magenta near the face, deep violet at the back
				glyph(box, ch, UDim2.fromScale(d * 0.014, d * 0.02), MAGENTA:Lerp(Color3.fromRGB(70, 10, 120), (d - 1) / 5), 4)
			end
			local face = glyph(box, ch, UDim2.new(), Color3.new(1, 1, 1), 6)
			new("UIGradient", face, { Rotation = 90, Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)), ColorSequenceKeypoint.new(0.55, Color3.new(1, 1, 1)), ColorSequenceKeypoint.new(1, LAV) }) })
			new("UIStroke", face, { Color = Color3.fromRGB(60, 8, 110), Thickness = 1.5 })
			local streak = new("Frame", cell, { Size = UDim2.fromScale(1.5, 0.07), Position = UDim2.fromScale(-1, 0.5), AnchorPoint = MID, Rotation = -14, BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Visible = false, ZIndex = 8 })
			new("UICorner", streak, { CornerRadius = UDim.new(0.5, 0) })
			new("UIGradient", streak, { Color = ColorSequence.new(CYAN, MAGENTA), Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.8, 0.1), NumberSequenceKeypoint.new(1, 0) }) })
			table.insert(letters, { box = box, sc = sc, streak = streak, halo = halo })
		end
	end

	-- the progress line
	local bar = new("Frame", all, { Size = UDim2.fromScale(0.34, 0.006), Position = UDim2.fromScale(0.5, 0.86), AnchorPoint = MID, BackgroundColor3 = Color3.fromRGB(60, 30, 90), BackgroundTransparency = 0.3, BorderSizePixel = 0, ZIndex = 5 })
	new("UICorner", bar, { CornerRadius = UDim.new(0.5, 0) })
	local fill = new("Frame", bar, { Size = UDim2.fromScale(0, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 6 })
	new("UICorner", fill, { CornerRadius = UDim.new(0.5, 0) })
	new("UIGradient", fill, { Color = ColorSequence.new(CYAN, MAGENTA) })
	local glow = new("Frame", fill, { Size = UDim2.new(1, 0, 5, 0), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = MID, BackgroundColor3 = MAGENTA, BackgroundTransparency = 0.8, BorderSizePixel = 0, ZIndex = 5 })
	new("UICorner", glow, { CornerRadius = UDim.new(0.5, 0) })
	local pct = new("TextLabel", all, { Text = "0%", Font = Enum.Font.Arcade, TextScaled = true, TextColor3 = LAV, BackgroundTransparency = 1, Size = UDim2.fromScale(0.16, 0.04), Position = UDim2.fromScale(0.5, 0.905), AnchorPoint = MID, ZIndex = 5 })

	-- letter by letter: the streak crosses, the letter snaps in behind it
	task.spawn(function()
		task.wait(0.25)
		for _, l in letters do
			l.streak.Visible = true
			TweenService:Create(l.streak, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = UDim2.fromScale(1.6, 0.36) }):Play()
			task.delay(0.07, function()
				l.box.Visible = true
				local up = TweenService:Create(l.sc, TweenInfo.new(0.11, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 1.05 })
				up.Completed:Connect(function() TweenService:Create(l.sc, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), { Scale = 1 }):Play() end)
				up:Play()
			end)
			task.delay(0.24, function() l.streak.Visible = false end)
			task.wait(0.085)
		end
	end)

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
		for i, l in letters do -- the halo breathes along the word
			l.halo.TextTransparency = 0.5 + 0.2 * math.sin(now * 3 - i * 0.5)
		end
		local loaded = game:IsLoaded() and E.plr.Character ~= nil
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
