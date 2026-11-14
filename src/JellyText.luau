-- JellyText (ReplicatedStorage.Shared.JellyText): words made of 3D jelly glass letters (the user, 2026-11-12: "this jelly
-- feeling really resonates with me ... as much of this quality of text in UI, HUD, ingame"). Reference: Instagram reel
-- DfUpUhcuASY (puffy glossy letters with a darker rim). The letters are Blender renders packed into an atlas
-- (art/pd_logo_jelly.py, art/pd_jelly_atlas.py -> Shared.JellyGlyphs, ids in Config.JELLY).
--   local JellyText = require(Shared.JellyText)
--   local t = JellyText.new(parent, "SETTINGS", { color = Color3?, glow = bool, pop = bool, sway = bool, z = number, align = "left"|"center"|"right" })
--   t.set("SOUND")   t.pop()   t.tint(color)   t.destroy()   t.frame (the row; it fills the parent and keeps the word's shape)
-- The word fits inside its parent (whichever of width or height is the tighter). With a colour it uses the pale atlas and tints
-- it; without one it uses the pink atlas. It works in a ScreenGui, a SurfaceGui and a BillboardGui. Unknown characters are spaces.
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local G = require(script.Parent:WaitForChild("JellyGlyphs"))
local C = require(script.Parent:WaitForChild("Config"))
local M = {}

local MID = Vector2.new(0.5, 0.5)
local SPACE = 0.34
local live = {} -- every word on screen, for the one shared animation loop

-- The atlas pictures must really be on screen before any plain text is hidden: a picture that is still loading, or that the
-- platform has not approved yet, draws nothing, and mirrored labels would be blank. ready[image] turns true once it has loaded.
local ready, waiting = {}, {}
local function watch(image)
	if ready[image] ~= nil then return end
	ready[image] = false
	task.spawn(function()
		local probe = Instance.new("ImageLabel")
		probe.Image, probe.Size, probe.BackgroundTransparency, probe.ImageTransparency = image, UDim2.fromOffset(2, 2), 1, 0.99
		local holder = Instance.new("ScreenGui")
		holder.Name, holder.ResetOnSpawn = "JellyProbe", false
		probe.Parent = holder
		holder.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
		pcall(function() game:GetService("ContentProvider"):PreloadAsync({ probe }) end)
		while not probe.IsLoaded do task.wait(0.5) end
		ready[image] = true
		holder:Destroy()
		for _, f in waiting do task.spawn(f) end
		local all = true
		for _, ok in ready do all = all and ok end
		if all then table.clear(waiting) end -- nothing left to wait for
	end)
end
for _, id in C.JELLY do watch(id) end

local function make(cls, parent, props)
	local o = Instance.new(cls)
	for k, v in props do o[k] = v end
	o.Parent = parent
	return o
end

-- Which atlas draws a colour: one of the true-colour jellies when the colour is near it (they keep their white shine; a tint
-- on the pale atlas multiplies the shine away and looks like dough), else the pale atlas with a tint. nil = the pink jelly.
local TONES = { gold = Color3.fromRGB(255, 205, 80), cyan = Color3.fromRGB(110, 215, 255), violet = Color3.fromRGB(160, 120, 255), mint = Color3.fromRGB(120, 235, 180), pink = Color3.fromRGB(255, 120, 190) }
function M.pick(color)
	if not color then return C.JELLY.pink, nil end
	local h, s, v = color:ToHSV()
	if s < 0.16 then return C.JELLY.white, color end -- white and greys: the pale atlas
	local best, bd
	for name, c in TONES do
		if C.JELLY[name] then
			local h2 = c:ToHSV()
			local d = math.min(math.abs(h - h2), 1 - math.abs(h - h2))
			if not bd or d < bd then best, bd = name, d end
		end
	end
	if best and bd < 0.09 then return C.JELLY[best], v < 0.6 and Color3.fromHSV(0, 0, 0.55 + v * 0.5) or nil end -- a dim colour dims its jelly
	return C.JELLY.white, color
end

function M.new(parent, str, opt)
	opt = opt or {}
	local z = opt.z or 3
	local row = make("Frame", parent, { Name = "Jelly", Size = UDim2.fromScale(1, 1), Position = UDim2.fromScale(opt.align == "left" and 0 or (opt.align == "right" and 1 or 0.5), 0.5), AnchorPoint = Vector2.new(opt.align == "left" and 0 or (opt.align == "right" and 1 or 0.5), 0.5), BackgroundTransparency = 1, ZIndex = z })
	local ratio = make("UIAspectRatioConstraint", row, { AspectRatio = 1 })
	local self = { frame = row, glyphs = {}, color = opt.color, born = os.clock(), sway = opt.sway ~= false, text = nil, glow = opt.glow == true }

	local function build(s)
		for _, g in self.glyphs do g.img:Destroy() if g.glow then g.glow:Destroy() end end
		table.clear(self.glyphs)
		self.raw = string.upper(s)
		s = self.raw:gsub("%[ ?", "("):gsub(" ?%]", ")"):gsub("  +", " ") -- square brackets have no glyph; runs of spaces close up
		local total = 0
		for i = 1, #s do
			local g = G.glyphs[s:sub(i, i)]
			total += g and g[2] or SPACE
		end
		total = math.max(total, 0.2)
		ratio.AspectRatio = total -- the row is as wide as the word, in letter heights
		local image, tint = M.pick(self.color)
		local x = 0
		for i = 1, #s do
			local g = G.glyphs[s:sub(i, i)]
			if g then
				local rect = Vector2.new((g[1] % G.cols) * G.cell, math.floor(g[1] / G.cols) * G.cell)
				local pos = UDim2.fromScale((x + g[2] / 2) / total, 0.5)
				local props = { Image = image, ImageRectOffset = rect, ImageRectSize = Vector2.new(G.cell, G.cell), BackgroundTransparency = 1, Size = UDim2.fromScale(1 / total, 1), Position = pos, AnchorPoint = MID, ZIndex = z + 1 }
				local glow
				if opt.glow then
					glow = make("ImageLabel", row, props)
					glow.ZIndex, glow.ImageTransparency, glow.Size = z, 0.62, UDim2.fromScale(1.22 / total, 1.22)
					glow.ImageColor3 = self.color or Color3.fromRGB(255, 0, 127)
				end
				local img = make("ImageLabel", row, props)
				if tint then img.ImageColor3 = tint end
				table.insert(self.glyphs, { img = img, glow = glow, sc = make("UIScale", img, {}), pos = pos, w = 1 / total, i = i })
				x += g[2]
			else
				x += SPACE
			end
		end
		self.text = s
	end

	function self.set(s)
		if string.upper(s) ~= self.raw then build(s) end
	end
	function self.tint(c)
		self.color = c
		local s = self.text
		self.text = nil
		build(s)
	end
	function self.pop(stagger) -- every letter lands with a spring, one after the other, then wobbles like jelly
		self.born = os.clock()
		for k, g in self.glyphs do
			g.sc.Scale = 0
			g.born = self.born + (k - 1) * (stagger or 0.035)
			task.delay((k - 1) * (stagger or 0.035), function()
				if g.img.Parent then TweenService:Create(g.sc, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play() end
			end)
		end
	end
	function self.destroy()
		live[self] = nil
		row:Destroy()
	end

	build(str or "")
	if opt.pop then self.pop() end
	live[self] = true
	row.Destroying:Connect(function() live[self] = nil end)
	return self
end

-- Can the font spell this string? False when it holds a character with no glyph (a letter of another script, an emoji):
-- such a string must stay plain text, or the missing letters would show as gaps.
function M.covers(str)
	local s = string.upper(str):gsub("%[ ?", "("):gsub(" ?%]", ")")
	for i = 1, #s do
		local ch = s:sub(i, i)
		if ch ~= " " and not G.glyphs[ch] then return false end
	end
	return true
end

-- Pop every jelly word under a root (a menu that has just opened): the biggest word lands letter by letter, the rest together.
function M.popUnder(root)
	local big, size
	for t in live do
		if t.frame.Parent and t.frame.Visible and t.frame:IsDescendantOf(root) then
			local h = t.frame.AbsoluteSize.Y
			if not size or h > size then big, size = t, h end
		end
	end
	if big then big.pop(0.045) end
end

-- Turn an existing TextLabel into jelly: its own text is hidden and a jelly word with the same string sits inside it, follows
-- its Text and its TextTransparency from then on. opt as in new(), plus popOnChange, followColor (tint from TextColor3) and
-- maxLen (longer strings stay plain text).
function M.mirror(label, opt)
	opt = opt or {}
	if label:FindFirstChild("Jelly") then return end
	local ax = label.TextXAlignment
	local t = M.new(label, label.Text, { color = opt.color, glow = opt.glow, sway = opt.sway, z = label.ZIndex + 1, align = ax == Enum.TextXAlignment.Left and "left" or (ax == Enum.TextXAlignment.Right and "right" or "center") })
	local function alpha(a)
		for _, g in t.glyphs do g.img.ImageTransparency = a if g.glow then g.glow.ImageTransparency = 0.62 + 0.38 * a end end
	end
	-- the plain text (and its outline) is not drawn while the jelly stands in for it; its transparency and colour stay the
	-- game's to set. A string longer than opt.maxLen is a sentence, not a headline: it goes back to plain text.
	local function fit()
		if not label.Parent then return end
		local h = label.AbsoluteSize.Y
		local long = (opt.maxLen ~= nil and #label.Text > opt.maxLen) or (h > 0 and h < 17) or not M.covers(label.Text) -- jelly letters under 17 px are mush, and a string the font cannot spell would have gaps: such a label stays plain text
		local ok = ready[(M.pick(t.color))] == true
		label.MaxVisibleGraphemes = (long or not ok) and -1 or 0
		t.frame.Visible = not long and ok
		-- a text set while the jelly was hidden (atlas still loading, label too small) was never built: build it when the jelly shows
		-- (2026-11-13: the quest marker's word RIDE was missing in town, its tag was empty)
		if t.frame.Visible and t.text ~= label.Text then
			t.set(label.Text)
			for _, g in t.glyphs do g.img.ImageTransparency = label.TextTransparency end
		end
	end
	if ready[(M.pick(t.color))] ~= true then table.insert(waiting, fit) end -- run again when its atlas finishes loading
	fit()
	alpha(label.TextTransparency)
	label:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
	label:GetPropertyChangedSignal("Text"):Connect(function()
		fit()
		if not t.frame.Visible then return end
		t.set(label.Text)
		alpha(label.TextTransparency)
		if opt.popOnChange and label.TextTransparency < 1 then t.pop(0.02) end
	end)
	label:GetPropertyChangedSignal("TextTransparency"):Connect(function() alpha(label.TextTransparency) end) -- fades and hides written by the game
	if opt.followColor then
		label:GetPropertyChangedSignal("TextColor3"):Connect(function()
			t.tint(label.TextColor3)
			alpha(label.TextTransparency)
		end)
	end
	return t
end

-- A four-point star glint that pops on a letter and fades: the shine on glass (words made with glow = true twinkle now and
-- then; never under Reduced Motion).
local calm = false
pcall(function() calm = game:GetService("GuiService").ReducedMotionEnabled end)
local function shown(o) -- is this word really on screen: every ancestor visible, its gui enabled
	while o do
		if o:IsA("GuiObject") and not o.Visible then return false end
		if o:IsA("LayerCollector") then return o.Enabled end
		o = o.Parent
	end
	return false
end
local function glint(t)
	if not shown(t.frame) then return end
	local g = t.glyphs[math.random(1, #t.glyphs)]
	if not g or g.img.ImageTransparency > 0.5 then return end
	local s = make("Frame", t.frame, { Size = UDim2.fromScale(g.w * 0.5, 0.5), Position = g.pos + UDim2.fromScale((math.random() - 0.5) * g.w * 0.6, -0.12 - math.random() * 0.2), AnchorPoint = MID, BackgroundTransparency = 1, Rotation = math.random(-15, 15), ZIndex = g.img.ZIndex + 2 })
	make("UIAspectRatioConstraint", s, { AspectRatio = 1 })
	local sc = make("UIScale", s, { Scale = 0 })
	for _, d in { { 1, 0.13 }, { 0.13, 1 } } do
		local arm = make("Frame", s, { Size = UDim2.fromScale(d[1], d[2]), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = MID, BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = s.ZIndex })
		make("UICorner", arm, { CornerRadius = UDim.new(0.5, 0) })
		make("UIGradient", arm, { Rotation = d[1] == 1 and 0 or 90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(1, 1) }) })
	end
	local up = TweenService:Create(sc, TweenInfo.new(0.16, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 0.6 + math.random() * 0.6 })
	up.Completed:Connect(function()
		local down = TweenService:Create(sc, TweenInfo.new(0.32, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = 0 })
		down.Completed:Connect(function() s:Destroy() end)
		down:Play()
	end)
	up:Play()
	TweenService:Create(s, TweenInfo.new(0.48), { Rotation = s.Rotation + 80 }):Play()
end

local lastStep = os.clock()
RunService.RenderStepped:Connect(function()
	local now = os.clock()
	local dt = math.min(now - lastStep, 0.1)
	lastStep = now
	for t in live do
		if t.glow and not calm and #t.glyphs > 0 and t.frame.Parent and t.frame.Visible and math.random() < dt * 0.9 and t.frame.AbsoluteSize.Y >= 28 then glint(t) end
		if t.frame.Parent and t.sway then
			for _, g in t.glyphs do
				local age = g.born and (now - g.born) or 9
				local wob = (age > 0 and age < 1.2) and math.exp(-age * 5) * math.sin(age * 22) * 0.2 or 0 -- squash and stretch that dies away
				g.img.Size = UDim2.fromScale(g.w * (1 + wob), 1 - wob)
				g.img.Rotation = math.sin(now * 1.7 + g.i * 0.9) * 1.1
				g.img.Position = g.pos + UDim2.fromScale(0, math.sin(now * 2.1 + g.i * 0.7) * 0.03)
			end
		end
	end
end)

return M
