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

local function make(cls, parent, props)
	local o = Instance.new(cls)
	for k, v in props do o[k] = v end
	o.Parent = parent
	return o
end

function M.new(parent, str, opt)
	opt = opt or {}
	local z = opt.z or 3
	local row = make("Frame", parent, { Name = "Jelly", Size = UDim2.fromScale(1, 1), Position = UDim2.fromScale(opt.align == "left" and 0 or (opt.align == "right" and 1 or 0.5), 0.5), AnchorPoint = Vector2.new(opt.align == "left" and 0 or (opt.align == "right" and 1 or 0.5), 0.5), BackgroundTransparency = 1, ZIndex = z })
	local ratio = make("UIAspectRatioConstraint", row, { AspectRatio = 1 })
	local self = { frame = row, glyphs = {}, color = opt.color, born = os.clock(), sway = opt.sway ~= false, text = nil }

	local function build(s)
		for _, g in self.glyphs do g.img:Destroy() if g.glow then g.glow:Destroy() end end
		table.clear(self.glyphs)
		s = string.upper(s)
		local total = 0
		for i = 1, #s do
			local g = G.glyphs[s:sub(i, i)]
			total += g and g[2] or SPACE
		end
		total = math.max(total, 0.2)
		ratio.AspectRatio = total -- the row is as wide as the word, in letter heights
		local image = self.color and C.JELLY.white or C.JELLY.pink
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
				if self.color then img.ImageColor3 = self.color end
				table.insert(self.glyphs, { img = img, glow = glow, sc = make("UIScale", img, {}), pos = pos, w = 1 / total, i = i })
				x += g[2]
			else
				x += SPACE
			end
		end
		self.text = s
	end

	function self.set(s)
		if string.upper(s) ~= self.text then build(s) end
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

-- Turn an existing TextLabel into jelly: its own text is hidden and a jelly word with the same string sits inside it, follows
-- its Text and its TextTransparency from then on. opt as in new(), plus popOnChange and followColor (tint from TextColor3).
function M.mirror(label, opt)
	opt = opt or {}
	if label:FindFirstChild("Jelly") then return end
	local ax = label.TextXAlignment
	local t = M.new(label, label.Text, { color = opt.color, glow = opt.glow, sway = opt.sway, z = label.ZIndex + 1, align = ax == Enum.TextXAlignment.Left and "left" or (ax == Enum.TextXAlignment.Right and "right" or "center") })
	local function alpha(a)
		for _, g in t.glyphs do g.img.ImageTransparency = a if g.glow then g.glow.ImageTransparency = 0.62 + 0.38 * a end end
	end
	label.MaxVisibleGraphemes = 0 -- the plain text (and its outline) is never drawn; its transparency and colour stay the game's to set
	alpha(label.TextTransparency)
	label:GetPropertyChangedSignal("Text"):Connect(function()
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

RunService.RenderStepped:Connect(function()
	local now = os.clock()
	for t in live do
		if t.frame.Parent and t.sway then
			for _, g in t.glyphs do
				local age = g.born and (now - g.born) or 9
				local wob = (age > 0 and age < 1.2) and math.exp(-age * 5) * math.sin(age * 22) * 0.2 or 0 -- squash and stretch that dies away
				g.img.Size = UDim2.fromScale(g.w * (1 + wob), 1 - wob)
				g.img.Rotation = math.sin(now * 1.7 + g.i * 0.9) * 2.2
				g.img.Position = g.pos + UDim2.fromScale(0, math.sin(now * 2.1 + g.i * 0.7) * 0.03)
			end
		end
	end
end)

return M
