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
	-- the owner, 2026-11-13: "remove the striped lines in the background and only have the text". The fog, the ribbons and the
	-- shards are made only when Config.LOADING.fx is true.
	local FX = cfg.fx == true
	local fog = {}
	for i = 1, FX and 3 or 0 do
		local f = new("Frame", all, { Size = UDim2.fromScale(1.3, 0.34), Position = UDim2.fromScale(0.5, 0.3 + i * 0.16), AnchorPoint = MID, BackgroundColor3 = i == 2 and Color3.fromRGB(70, 30, 120) or Color3.fromRGB(110, 26, 110), BackgroundTransparency = 0.8, BorderSizePixel = 0, ZIndex = 1 })
		new("UIGradient", f, { Rotation = 90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(1, 1) }) })
		fog[i] = f
	end
	-- energy ribbons: long thin bands of light crossing behind the title
	local ribbons = {}
	for i, d in FX and { { MAGENTA, -9, 0.4 }, { CYAN, 7, 0.47 } } or {} do
		local r = new("Frame", all, { Size = UDim2.fromScale(1.5, 0.012), Position = UDim2.fromScale(0.5, d[3]), AnchorPoint = MID, Rotation = d[2], BackgroundColor3 = d[1], BorderSizePixel = 0, ZIndex = 2 })
		new("UIGradient", r, { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.35, 0.35), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(0.65, 0.35), NumberSequenceKeypoint.new(1, 1) }) })
		local halo = new("Frame", r, { Size = UDim2.fromScale(1, 7), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = MID, BackgroundColor3 = d[1], BackgroundTransparency = 0.88, BorderSizePixel = 0, ZIndex = 1 })
		new("UIGradient", halo, { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(1, 1) }) })
		ribbons[i] = { f = r, y = d[3], rot = d[2] }
	end
	-- crystal shards on a flat orbit behind the title
	local shards = {}
	local rng = Random.new(7)
	for i = 1, FX and 16 or 0 do
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
	local okSB, SlimeBody = pcall(function() return require(script.Parent:WaitForChild("SlimeBody")) end)
	local bodies = {} -- the letter picture's box -> its slime body (2026-11-16 night: the letters bend like slime, not only bounce)
	local px = math.clamp(math.floor(workspace.CurrentCamera.ViewportSize.X * 0.3 / #WORD * 1.3), 8, 100) -- a fixed size, magnified by the UIScale: TextScaled stops at 100 px on screen
	local function glyph(parent, ch, pos, color, z, tr)
		return new("TextLabel", parent, { Text = ch, Font = Enum.Font.Arcade, TextSize = px, BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Position = pos, TextColor3 = color, TextTransparency = tr or 0, ZIndex = z })
	end
	-- the fused wordmark (2026-11-17, Gemini n17_r2: "letters glued to drips, not one gooey body"): each word is one rendered slime
	-- body in which the letters melt into each other; it is cut into one column per letter, and each column still flies in,
	-- bounces and bends on its own (at rest the columns meet and read as one piece of slime)
	local lay = {}
	if cfg.word and okSB then
		local H = 1.3 -- world units in every word picture's height
		local units, gapU = {}, 0.42
		local total = 0
		for j, wd in cfg.word do
			units[j] = wd.w / wd.h * H
			total += units[j] + (j > 1 and gapU or 0)
		end
		local x0, k = 0, 0
		for j, wd in cfg.word do
			for c = 1, #wd.cuts - 1 do
				k += 1
				local a, b = wd.cuts[c], wd.cuts[c + 1]
				lay[k] = { x = (x0 + (a + b) / 2 / wd.h * H) / total, w = (b - a) / wd.h * H / total, image = wd.image, hot = wd.hot, rect = Vector2.new(a, 0), size = Vector2.new(b - a, wd.h) }
			end
			x0 += units[j] + gapU
		end
		title:FindFirstChildOfClass("UIAspectRatioConstraint").AspectRatio = total / H -- a column cell is then exactly as tall as the title: its picture keeps its own shape
		title.Size = UDim2.fromScale(0.3, 0.2)
	end
	local li = 0
	for i = 1, #WORD do
		local ch = WORD:sub(i, i)
		if ch ~= " " then
			li += 1
			local L = lay[li]
			local cell = new("Frame", title, { Size = L and UDim2.fromScale(L.w, 1) or UDim2.fromScale(1 / #WORD, 1), Position = UDim2.fromScale(L and L.x or (i - 0.5) / #WORD, 0.5), AnchorPoint = MID, BackgroundTransparency = 1, ZIndex = 5 })
			local box = new("Frame", cell, { Size = L and UDim2.fromScale(1, 1) or UDim2.fromScale(1.75, 1.75), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = MID, BackgroundTransparency = 1, Visible = false, ZIndex = 5 }) -- wider than its cell: the font has wide side bearings
			local sc = new("UIScale", box, { Scale = 0.8 })
			local jelly = L and L.image or (cfg.letters and cfg.letters[ch])
			local halo
			if jelly then -- a 3D jelly glass letter (the user, 2026-11-12, reference reel DfUpUhcuASY): a rendered picture, with a glow behind and a glint that crosses it
				halo = new("ImageLabel", box, { Image = jelly, ImageColor3 = MAGENTA, ImageTransparency = 0.6, BackgroundTransparency = 1, Size = UDim2.fromScale(1.28, 1.28), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = MID, ZIndex = 3 })
				local img = new("ImageLabel", box, { Name = "Jelly", Image = jelly, BackgroundTransparency = 1, Size = UDim2.fromScale(1.12, 1.12), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = MID, ScaleType = Enum.ScaleType.Stretch, ZIndex = 6 }) -- Stretch: the picture itself squashes and stretches with its frame
				if L then -- a column of the wordmark: it fills its cell exactly, so neighbouring columns meet
					img.Size, halo.Size = UDim2.fromScale(1, 1), UDim2.fromScale(1.12, 1.12)
					halo.ImageRectOffset, halo.ImageRectSize = L.rect, L.size
				else
					new("UIAspectRatioConstraint", img, { AspectRatio = 1 })
					new("UIAspectRatioConstraint", halo, { AspectRatio = 1 })
				end
				if okSB then -- the picture is drawn by slime strips that shear and squash; the box itself stays whole
					img.Image = ""
					bodies[img] = { SlimeBody.new(img, { image = jelly, rect = L and L.rect, cell = L and L.size or Vector2.new(512, 512), strips = 12, z = 6, qmax = 0.9 }) }
				end
				-- a plain letter under the picture, shown only if the picture never loads (a slow phone, an asset still in review)
				local plain = glyph(box, ch, UDim2.new(), Color3.fromRGB(255, 170, 215), 5)
				plain.Name, plain.Visible, plain.Font = "Plain", false, Enum.Font.FredokaOne
				new("UIStroke", plain, { Color = Color3.fromRGB(120, 20, 110), Thickness = 2 })
				local hotId = L and L.hot or (cfg.hot and cfg.hot[ch])
				if hotId then -- the same letter in white, laid over it while it is still hot from landing
					local hot = new("ImageLabel", img, { Name = "Hot", Image = hotId, BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ScaleType = Enum.ScaleType.Stretch, ZIndex = 7 })
					if bodies[img] then -- the white-hot copy bends with it
						hot.Image = ""
						local hb = SlimeBody.new(hot, { image = hotId, rect = L and L.rect, cell = L and L.size or Vector2.new(512, 512), strips = 12, z = 7, qmax = 0.9 })
						hot:GetPropertyChangedSignal("ImageTransparency"):Connect(function() hb.alpha(hot.ImageTransparency) end)
						table.insert(bodies[img], hb)
					end
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
		l.sy = spring(1.9, 4.2, 0.16) -- 2026-11-13 "increase the bounciness": damping 0.3 -> 0.16 here and lower on every spring below
		l.sy.goal = 1
		l.rot = spring(-24, 3.8, 0.18)
		l.rot.goal = 0
		l.heat = 1
		l.slot = l.cell.Position.X.Scale
		l.hot = l.jelly and l.jelly:FindFirstChild("Hot")
		l.sc.Scale = 1
	end
	local slamAt = letters[n].at + 0.13
	-- goo bridges (Gemini n17_r1: "connect adjacent letters with viscous ligaments"): a strand of the same slime hangs between a
	-- few neighbouring letters once both have landed; it stretches thinner as they move apart and wobbles with their bounce
	local bridges = {}
	if cfg.bridge and not cfg.word then -- the wordmark is already one piece
		for _, pr in { { 3, 4 }, { 6, 7 }, { 8, 9 } } do
			local a, b = letters[pr[1]], letters[pr[2]]
			if a and b then
				local img = new("ImageLabel", title, { Name = "Goo", Image = cfg.bridge, BackgroundTransparency = 1, ImageTransparency = 1, AnchorPoint = MID, ScaleType = Enum.ScaleType.Stretch, ZIndex = 4 }) -- behind the letters: its end blobs hide inside them and only the stretched middle shows (in front they read as bones)
				table.insert(bridges, { img = img, a = a, b = b, gap0 = nil })
			end
		end
	end
	local titleAspect = #WORD * 0.62
	local spread, kickX, kickY, tilt, punch = spring(0.55, 4, 0.2), spring(0, 4.2, 0.15), spring(0, 4.6, 0.16), spring(-6, 3.3, 0.18), spring(0, 4.6, 0.18)
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
		for _, l in letters do -- a picture that did not arrive: the plain letter stands in
			local face = l.jelly and (bodies[l.jelly] and bodies[l.jelly][1].strips[1] or l.jelly) -- a slime letter draws through its strips: ask a strip
			if face and not face.IsLoaded then
				local plain = l.box:FindFirstChild("Plain")
				if plain then plain.Visible = true end
				task.spawn(function() -- and steps back if the picture turns up later
					while face.Parent and not face.IsLoaded do task.wait(0.3) end
					if plain and plain.Parent then plain.Visible = false end
				end)
			end
		end
		ready = true
	end)
	local slammed, waveAt = false, nil
	-- sound: a soft pop for each letter, a step higher each time, and a thud with a sparkle when the word shakes (the game's
	-- own "pop", "land" and "sparkle" sounds; not heard by Claude). Config.LOADING.sound = false turns it off.
	local function play(id, vol, pitch)
		if cfg.sound == false then return end
		local snd = Instance.new("Sound")
		snd.SoundId, snd.Volume, snd.PlaybackSpeed = "rbxassetid://" .. id, vol, pitch
		snd.Parent = gui
		snd:Play()
		snd.Ended:Once(function() snd:Destroy() end)
		task.delay(4, function() if snd.Parent then snd:Destroy() end end)
	end
	local shownAt = {}

	-- Mining dressing (the owner, 2026-11-14: "add more mining themes to the loading screen ... only icons that were designed and
	-- are final"). Nothing is drawn for this screen: it uses the game's own jelly icons (Config.UI_GLASS.icon, art/icons_jelly).
	--   * six treasures pop in round the word once it has landed, each on its own spring, and float
	--   * a jelly pickaxe works at the head of the progress line: every strike throws a star glint and knocks a gem or a coin
	--     out of the line, which arcs away and fades
	-- Config.LOADING.mine = false turns it off.
	local mineStep = function(_dt, _real, _shown) end
	local G = E.C.UI_GLASS
	if cfg.mine ~= false and G and G.icon and G.hud then
		local I = G.icon
		task.spawn(function() pcall(function() game:GetService("ContentProvider"):PreloadAsync({ I.gem, I.coin, I.chest, I.egg, I.surface, I.pick, G.hud.torch }) end) end)
		local YY = Enum.SizeConstraint.RelativeYY
		local floats = {}
		for i, d in { { I.gem, 0.2, 0.2, 0.18, -10 }, { I.chest, 0.2, 0.8, 0.18, 10 }, { G.hud.torch, 0.16, 0.06, 0.6, 8 }, { I.egg, 0.16, 0.94, 0.6, -8 }, { I.coin, 0.13, 0.15, 0.74, -6 }, { I.surface, 0.13, 0.85, 0.74, 6 } } do -- three mirrored pairs on one oval round the word
			local holder = new("Frame", all, { Name = "Treasure", Size = UDim2.fromScale(d[2], d[2]), SizeConstraint = YY, Position = UDim2.fromScale(d[3], d[4]), AnchorPoint = MID, BackgroundTransparency = 1, ZIndex = 3 })
			new("ImageLabel", holder, { Image = d[1], ImageColor3 = MAGENTA, ImageTransparency = 0.8, BackgroundTransparency = 1, Size = UDim2.fromScale(1.3, 1.3), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = MID, ZIndex = 3 }) -- a soft glow of its own shape
			new("ImageLabel", holder, { Image = d[1], BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 4 })
			local f = { holder = holder, sc = new("UIScale", holder, { Scale = 0 }), x = d[3], y = d[4], rot = d[5], at = slamAt + 0.2 + i * 0.11, sp = spring(0, 3.4, 0.32) }
			floats[i] = f
		end
		local tip = new("Frame", all, { Name = "Vein", Size = UDim2.fromScale(0.07, 0.07), SizeConstraint = YY, AnchorPoint = MID, BackgroundTransparency = 1, ZIndex = 8 })
		local pick = new("ImageLabel", all, { Name = "Pick", Image = I.pick, BackgroundTransparency = 1, Size = UDim2.fromScale(0.2, 0.2), SizeConstraint = YY, AnchorPoint = MID, ZIndex = 8 })
		local chips, phase, hits, flash = {}, 0, 0, 0
		mineStep = function(dt, real, shown)
			for i, f in floats do
				if clock >= f.at then f.sp.goal = 1 end
				f.sc.Scale = math.max(f.sp.step(dt), 0)
				f.holder.Position = UDim2.fromScale(f.x, f.y + math.sin(real * 1.1 + i * 1.7) * 0.012)
				f.holder.Rotation = f.rot + math.sin(real * 0.8 + i) * 4
			end
			local h = gui.AbsoluteSize.Y
			local tx = 0.3 + 0.4 * shown -- the head of the progress line
			tip.Position = UDim2.fromScale(tx, 0.84)
			local before = phase
			phase = (phase + dt / 0.62) % 1
			local rot -- lift slowly, come down fast, rest a moment: a swing, not a wobble
			if phase < 0.55 then rot = 12 - 50 * (1 - (1 - phase / 0.55) ^ 2)
			elseif phase < 0.7 then rot = -38 + 66 * ((phase - 0.55) / 0.15) ^ 2
			else rot = 28 - 16 * ((phase - 0.7) / 0.3) end
			pick.Rotation = rot
			pick.Position = UDim2.new(tx, -h * 0.07, 0.84, -h * 0.092)
			if before < 0.7 and phase >= 0.7 then -- the strike lands
				hits += 1
				flash = 1
				sparkle(tip, 0)
				for k = 1, 3 do -- a spray of three: gems and coins by turns, fanned out
					local size = 0.06 + math.random() * 0.035
					local c = new("ImageLabel", all, { Name = "Chip", Image = (hits + k) % 2 == 0 and I.coin or I.gem, BackgroundTransparency = 1, Size = UDim2.fromScale(size, size), SizeConstraint = YY, AnchorPoint = MID, ZIndex = 7 })
					chips[#chips + 1] = { f = c, x = 0, y = -h * 0.035, vx = (k - 2 + (math.random() - 0.5) * 0.6) * h * 0.2, vy = -h * (0.4 + math.random() * 0.2), t = 0, spin = (math.random() - 0.5) * 500, tx = tx }
				end
				for k = 1, 2 do sparkle(tip, k) end
			end
			flash *= math.exp(-dt * 9)
			glow.BackgroundTransparency = 0.8 - 0.4 * flash
			for i = #chips, 1, -1 do
				local c = chips[i]
				c.t += dt
				c.vy += h * 1.1 * dt -- they rise in an arc and are gone before they fall back through the line
				c.x += c.vx * dt
				c.y += c.vy * dt
				c.f.Position = UDim2.new(c.tx, c.x, 0.84, c.y)
				c.f.Rotation += c.spin * dt
				c.f.ImageTransparency = math.clamp((c.t - 0.35) / 0.3, 0, 1)
				if c.t > 0.65 then
					c.f:Destroy()
					table.remove(chips, i)
				end
			end
		end
	end

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
			kickX.v, kickY.v, tilt.v, punch.v = 5.2, 11, 74, 2.8
			play(88699226385252, 0.5, 0.9)
			play(96727638802500, 0.3, 1.2)
			for k, l in letters do
				task.delay((n - k) * 0.018, function() -- the ripple runs back from the last letter to the first
					l.sy.v -= 5.5 + math.random() * 2.5
					l.rot.v += (math.random() - 0.5) * 160
					l.heat = math.max(l.heat, 0.55)
					sparkle(l.cell, 0)
				end)
			end
		end
		if slammed and now > (waveAt or 0) then -- now and then a shiver runs along the word from one letter, like a wobble through slime
			if waveAt then
				local from, dir = math.random(1, n), math.random() < 0.5 and -1 or 1
				for k, l in letters do
					task.delay(math.abs(k - from) * 0.06, function()
						local f = 1 / (1 + math.abs(k - from) * 0.5)
						l.rot.v += dir * 55 * f
						l.sy.v -= 2.2 * f
					end)
				end
			end
			waveAt = now + 2.4 + math.random() * 1.6
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
					play(98559989688124, 0.28, 0.9 + i * 0.05)
					if i == n then task.delay(0.09, function() l.sy.v += 12 end) end -- the last letter's drip
				end
				local sy = math.clamp(l.sy.step(dt), 0.4, 2.4)
				if sy < 1 then sy = 1 - (1 - sy) * 0.55 end -- the squash half of each bounce is softened: at full depth a letter was crushed flat and unreadable
				local sx = math.clamp(1 / math.sqrt(sy), 0.5, 1.5) -- jelly keeps its volume: taller means thinner
				local rot = l.rot.step(dt)
				l.heat *= math.exp(-dt * 4.5)
				l.cell.Position = UDim2.fromScale(0.04 + (l.slot - 0.04) * sp + kx, 0.5 + ky + (i == n and (sy - 1) * 0.22 or 0))
				local breath = 0.5 + 0.2 * math.sin(now * 3 - i * 0.5)
				if l.jelly then
					local idle = slammed and 1 or 0
					local bs = bodies[l.jelly]
					if bs then -- slime: the lean becomes a shear (the top swings, the foot stays) and the bounce a squash of the body
						for _, b in bs do
							b.s = rot / 85 + idle * math.sin(now * 1.3 + i * 0.8) * 0.025
							b.q = sy - 1 + idle * math.sin(now * 2.2 + i) * 0.02
							b.apply()
						end
						l.jelly.Rotation = rot * 0.2
					else
						l.jelly.Size = UDim2.fromScale(1.12 * sx, 1.12 * sy)
						l.jelly:FindFirstChildOfClass("UIAspectRatioConstraint").AspectRatio = sx / sy
						l.jelly.Rotation = rot + idle * math.sin(now * 1.7 + i) * 2
					end
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
		for _, br in bridges do
			local a, b = br.a, br.b
			if now >= math.max(a.at, b.at) + 0.3 then
				local xa, xb = a.cell.Position.X.Scale, b.cell.Position.X.Scale
				local gap = math.abs(xb - xa)
				br.gap0 = br.gap0 or gap
				local st = gap / br.gap0
				local w = gap * 1.1 -- the end blobs sink into the two letters
				local h = br.gap0 * 0.95 * titleAspect * 1.5 / math.sqrt(math.max(st, 0.3)) -- stretched thinner, pressed fatter
				local sag = (a.sy.x + b.sy.x - 2) * 0.12 -- the bounce of the two letters pulls the strand down and up
				br.img.Size = UDim2.fromScale(w, h)
				br.img.Position = UDim2.fromScale((xa + xb) / 2, 0.5 + 0.2 + (a.cell.Position.Y.Scale + b.cell.Position.Y.Scale - 1) / 2 + sag)
				br.img.Rotation = (b.cell.Position.Y.Scale - a.cell.Position.Y.Scale) * 40
				br.img.ImageTransparency = math.max(0, br.img.ImageTransparency - dt * 5)
			end
		end
		now = real
		local loaded = game:IsLoaded() and E.plr.Character ~= nil and clock > slamAt + 1.7 -- the logo always finishes its landing and its bounces
		local goal = math.min(now / cfg.min, loaded and 1 or 0.9)
		shown += (goal - shown) * math.min(1, dt * 8)
		fill.Size = UDim2.fromScale(shown, 1)
		pct.Text = math.floor(shown * 100 + 0.5) .. "%"
		mineStep(dt, now, shown)
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
