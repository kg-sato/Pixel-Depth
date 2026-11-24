-- GumText (ReplicatedStorage.Shared.GumText): Gumdrop, the game's own small-text font (the owner, 2026-11-18: "remake or alter
-- the font for the game so it's original, matches the jelly text idea, yet stays useable"). Roblox has no official custom-font
-- upload, so the letters are our own glyphs in an image atlas (art/pd_gum_font.py -> Shared.GumGlyphs, ids Config.GUM): round,
-- chunky strokes with a dark rim, a body lit from the top and a white bevel light, readable from 12 px up. The 3D jelly letters
-- (JellyText) stay for headlines; Gumdrop takes everything they cannot: sentences, captions, small labels and numbers.
--   GumText.attach(label)   draws the label's text in Gumdrop and keeps it in step (Text, size, colour, transparency, alignment,
--                           wrapping, TextScaled with its UITextSizeConstraint, UIPadding). Returns a control or nil.
--   ctl.on(bool)            show Gumdrop (hides the plain glyphs) or give the label back its plain text
--   GumText.covers(str)     can Gumdrop spell every character
--   GumText.start(E)        converts every plain body label in the player's guis (the kit's body fonts) by itself
-- Plain text is hidden with MaxVisibleGraphemes = 0 only once the atlas has really loaded, so text never goes blank.
local ContentProvider = game:GetService("ContentProvider")
local G = require(script.Parent:WaitForChild("GumGlyphs"))
local C = require(script.Parent:WaitForChild("Config"))
local M = {}
local CAP_TO_SIZE = 0.7 -- a font's cap height is about 0.7 of its TextSize (Fredoka, Titillium): Gumdrop matches that
local LINE = 1.18 -- line height in TextSizes
local GLOSS_MIN = 15 -- below this text size the bevel light is too small to see: one layer per letter
local MODE = C.uiText() -- "flat": the flat atlas and no gloss layer
local BODY_IMG = MODE == "flat" and C.GUM.flat or C.GUM.body

local ready = false
local waiting = {}
task.spawn(function()
	local probes = {}
	for _, id in MODE == "flat" and { BODY_IMG } or { BODY_IMG, C.GUM.gloss } do -- the flat look never shows the gloss: it does not wait for it (Codex 2026-11-24)
		local p = Instance.new("ImageLabel")
		p.Image = id
		table.insert(probes, p)
	end
	pcall(function() ContentProvider:PreloadAsync(probes) end)
	local holder = Instance.new("ScreenGui")
	holder.Name, holder.ResetOnSpawn = "GumProbe", false
	for _, p in probes do p.Size, p.BackgroundTransparency, p.ImageTransparency, p.Parent = UDim2.fromOffset(2, 2), 1, 0.99, holder end
	holder.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
	local t0 = os.clock()
	while not probes[1].IsLoaded do task.wait(0.25) end -- the body atlas: text stays plain until it is in, however long (a 30 s cut-off left later labels plain for good, Codex 2026-11-24)
	while probes[2] and not probes[2].IsLoaded and os.clock() - t0 < 30 do task.wait(0.25) end
	holder:Destroy()
	ready = true
	for _, f in waiting do task.spawn(f) end
	table.clear(waiting)
end)

function M.whenReady(f) -- run f now if the atlas has loaded, else once it has (JellyText.mirror in the flat look)
	if ready then f() else table.insert(waiting, f) end
end

local function norm(s) -- key brackets have no glyph: "[ R ]" is drawn "(R)", as the jelly letters do (2026-11-24: FLARE NOW [ R ] fell back to the plain font)
	return (s:gsub("%[ ?", "("):gsub(" ?%]", ")"))
end

function M.covers(str)
	for _, cp in utf8.codes(norm(str)) do
		local ch = utf8.char(cp)
		if ch ~= " " and ch ~= "\n" and not G.glyphs[ch] then return false end
	end
	return true
end

local TRACK_SMALL = 0.05 -- extra advance (share of the cell) under 18 px: small letters ran together (Gemini round 1)
local track = 0
local function adv(ch) local g = G.glyphs[ch] return (g and g[2] or G.space) + track end

-- Lines of the text at text size s (px) in a box w px wide: { {text, width} }. Wrapping breaks at spaces; a word wider than the
-- box stays whole on its own line (the fit then shrinks it).
local function lines(text, s, w, wrap)
	track = s < 18 and TRACK_SMALL or 0
	local cell = s * CAP_TO_SIZE / G.cap
	local out = {}
	for para in (text .. "\n"):gmatch("(.-)\n") do
		local cur, cw = "", 0
		for word in para:gmatch("%S+") do
			local ww = 0
			for _, cp in utf8.codes(word) do ww += adv(utf8.char(cp)) * cell end
			local sp = cur == "" and 0 or G.space * cell
			if wrap and cur ~= "" and cw + sp + ww > w then
				table.insert(out, { cur, cw })
				cur, cw = word, ww
			else
				cur, cw = cur == "" and word or (cur .. " " .. word), cw + sp + ww
			end
		end
		table.insert(out, { cur, cw })
	end
	return out, cell
end

local function fits(text, s, w, h, wrap)
	local ls = lines(text, s, w, wrap)
	if #ls * s * LINE > h + 0.5 then return false end
	for _, l in ls do if l[2] > w + 0.5 then return false end end
	return true
end

function M.attach(label, opt)
	opt = opt or {}
	if label:FindFirstChild("Gum") then return nil end
	local holder = Instance.new("Frame")
	holder.Name, holder.BackgroundTransparency, holder.Size, holder.ZIndex = "Gum", 1, UDim2.fromScale(1, 1), label.ZIndex + 1
	holder.Visible = false
	holder.Parent = label
	local pool, used = {}, 0
	local on, queued = false, false
	local ctl = { holder = holder }

	local function glyph(i)
		local g = pool[i]
		if g then return g end
		local b = Instance.new("ImageLabel")
		b.Name, b.BackgroundTransparency, b.Image, b.ImageRectSize = "B", 1, BODY_IMG, Vector2.new(G.cell, G.cell)
		b.Parent = holder
		local s = Instance.new("ImageLabel")
		s.Name, s.BackgroundTransparency, s.Image, s.ImageRectSize = "S", 1, C.GUM.gloss, Vector2.new(G.cell, G.cell)
		s.Parent = holder
		g = { b = b, s = s }
		pool[i] = g
		return g
	end

	local function paint()
		local t = label.TextTransparency
		for i = 1, used do
			local g = pool[i]
			g.b.ImageColor3, g.b.ImageTransparency = label.TextColor3, t
			g.s.ImageTransparency = g.s.Visible and (1 - (1 - t) * 0.92) or 1
		end
	end

	local function layout()
		queued = false
		if not on or not label.Parent then return end
		local text = norm(label.Text)
		local abs = label.AbsoluteSize
		if abs.X < 2 or abs.Y < 2 then return end -- not drawn (a billboard out of range): lay out when it has a size again
		local pad = label:FindFirstChildOfClass("UIPadding")
		local l, r, t, b = 0, 0, 0, 0
		if pad then
			l, r = pad.PaddingLeft.Scale * abs.X + pad.PaddingLeft.Offset, pad.PaddingRight.Scale * abs.X + pad.PaddingRight.Offset
			t, b = pad.PaddingTop.Scale * abs.Y + pad.PaddingTop.Offset, pad.PaddingBottom.Scale * abs.Y + pad.PaddingBottom.Offset
		end
		local w, h = math.max(abs.X - l - r, 1), math.max(abs.Y - t - b, 1)
		l, t = 0, 0 -- the holder is a child of the label, so it already sits inside the padding: glyphs are placed from its corner
		local wrap = label.TextWrapped
		local s = label.TextSize
		if label.TextScaled then
			local lim = label:FindFirstChildOfClass("UITextSizeConstraint")
			local function biggest(wr)
				local lo, hi = lim and lim.MinTextSize or 1, math.min(lim and lim.MaxTextSize or 100, h / LINE)
				if fits(text, hi, w, h, wr) then return hi end
				for _ = 1, 12 do -- binary search for the biggest size that fits
					local mid = (lo + hi) / 2
					if fits(text, mid, w, h, wr) then lo = mid else hi = mid end
				end
				return lo
			end
			s = biggest(false)
			if wrap then -- one line unless wrapping buys a much bigger size: a box laid out for one line of the old font must not grow a second line over its neighbour
				local sw = biggest(true)
				if s < sw * 0.75 then s = sw else wrap = false end
			end
		elseif not fits(text, s, w, h, wrap) then -- Gumdrop is wider than the condensed Titillium it replaces: a fixed size that spills shrinks to fit (down to 60 %)
			local lo, hi = s * 0.6, s
			for _ = 1, 8 do
				local mid = (lo + hi) / 2
				if fits(text, mid, w, h, wrap) then lo = mid else hi = mid end
			end
			s = lo
		end
		s = math.floor(s * 2) / 2 -- round down: rounding up let long lines spill a few px past their box
		local ls, cell = lines(text, s, w, wrap)
		local lineH = s * LINE * label.LineHeight
		local total = #ls * lineH
		local ya = label.TextYAlignment
		local y0 = t + (ya == Enum.TextYAlignment.Top and 0 or (ya == Enum.TextYAlignment.Bottom and h - total or (h - total) / 2))
		local xa = label.TextXAlignment
		local capPx = cell * G.cap
		local n = 0
		local gloss = s >= GLOSS_MIN and MODE == "jelly"
		for li, ln in ls do
			local x = l + (xa == Enum.TextXAlignment.Left and 0 or (xa == Enum.TextXAlignment.Right and w - ln[2] or (w - ln[2]) / 2))
			local base = y0 + (li - 1) * lineH + (lineH + capPx) / 2 -- the cap sits centred in its line
			for _, cp in utf8.codes(ln[1]) do
				local ch = utf8.char(cp)
				local gd = G.glyphs[ch]
				local a = ((gd and gd[2] or G.space) + track) * cell
				if gd then
					n += 1
					local g = glyph(n)
					local rect = Vector2.new((gd[1] % G.cols) * G.cell, math.floor(gd[1] / G.cols) * G.cell)
					local pos = UDim2.fromOffset(math.floor(x + a / 2 - cell / 2 + 0.5), math.floor(base - G.base * cell + 0.5))
					local size = UDim2.fromOffset(math.ceil(cell), math.ceil(cell))
					g.b.ImageRectOffset, g.b.Position, g.b.Size, g.b.Visible, g.b.ZIndex = rect, pos, size, true, label.ZIndex + 1
					g.s.ImageRectOffset, g.s.Position, g.s.Size, g.s.Visible, g.s.ZIndex = rect, pos, size, gloss, label.ZIndex + 2
				end
				x += a
			end
		end
		for i = n + 1, #pool do pool[i].b.Visible, pool[i].s.Visible = false, false end
		used = n
		local widest = 0
		for _, ln in ls do widest = math.max(widest, ln[2]) end
		-- the ink box relative to the holder (text checks: spike/text_overlap.luau): line starts, first cap top to last baseline
		local bx0 = math.huge
		for _, ln in ls do bx0 = math.min(bx0, l + (xa == Enum.TextXAlignment.Left and 0 or (xa == Enum.TextXAlignment.Right and w - ln[2] or (w - ln[2]) / 2))) end
		label:SetAttribute("GumBox", Rect.new(bx0, y0 + (lineH - capPx) / 2, bx0 + widest, y0 + (#ls - 1) * lineH + (lineH + capPx) / 2))
		label:SetAttribute("GumWidth", widest) -- the drawn text's width in px: the plain TextBounds is 0 while the glyphs are hidden (IconPass reads it)
		paint()
	end
	local function queue()
		if on and not queued then queued = true task.defer(layout) end
	end

	function ctl.on(v)
		v = v and ready and M.covers(label.Text) and not label.RichText
		on = v
		holder.Visible = v
		if not v then label:SetAttribute("GumWidth", nil) label:SetAttribute("GumBox", nil) end
		if v then queue() end
		return v
	end
	for _, p in { "Text", "AbsoluteSize", "TextXAlignment", "TextYAlignment", "TextWrapped", "TextScaled", "TextSize", "LineHeight" } do
		label:GetPropertyChangedSignal(p):Connect(queue)
	end
	label:GetPropertyChangedSignal("ZIndex"):Connect(function() holder.ZIndex = label.ZIndex + 1 queue() end)
	label:GetPropertyChangedSignal("TextColor3"):Connect(paint)
	label:GetPropertyChangedSignal("TextTransparency"):Connect(paint)
	return ctl
end

-- One label on its own (not jelly): Gumdrop whenever it can spell the text, plain text otherwise.
function M.auto(label)
	local ctl = M.attach(label)
	if not ctl then return end
	local function sync()
		local v = ctl.on(true)
		label.MaxVisibleGraphemes = v and 0 or -1
	end
	label:GetPropertyChangedSignal("Text"):Connect(sync)
	label:GetPropertyChangedSignal("RichText"):Connect(sync)
	if ready then sync() else table.insert(waiting, sync) end
	return ctl
end

local BODY = { [Enum.Font.TitilliumWeb] = true, [Enum.Font.FredokaOne] = true, [Enum.Font.Oswald] = true, [Enum.Font.SourceSansBold] = true, [Enum.Font.SourceSans] = true }
function M.start(E)
	if not C.GUM or not C.GUM.on then return end
	local pg = E.plr:WaitForChild("PlayerGui")
	local function take(d)
		if not (d:IsA("TextLabel") or d:IsA("TextButton")) or d:FindFirstChild("Gum") or d:FindFirstChild("PixelGlyphs") then return end
		local jel = d:FindFirstChild("Jelly") -- the 3D jelly row (a Frame); JellyPress's bounce UIScale shares the name
		if d.MaxVisibleGraphemes == 0 or (jel and jel:IsA("GuiObject")) or not BODY[d.Font] or d.AutomaticSize ~= Enum.AutomaticSize.None then return end -- an auto-sized label measures its own text: hiding it would collapse the box
		if d:FindFirstAncestor("PixelLoading") or d:GetAttribute("NoGum") then return end
		M.auto(d)
	end
	local function later(d) -- the jelly pass (JellyHUD) takes headlines a quarter second after a label appears: go after it
		if d:IsA("TextLabel") or d:IsA("TextButton") then task.delay(0.45, function() if d.Parent then take(d) end end) end
	end
	for _, d in pg:GetDescendants() do later(d) end
	pg.DescendantAdded:Connect(later)
	local cam = workspace.CurrentCamera -- the town's floating station cards are SurfaceGuis on parts under the camera
	for _, d in cam:GetDescendants() do later(d) end
	cam.DescendantAdded:Connect(later)
end

-- self-check: the atlas spells the HUD's words, and a long sentence wraps into more than one line in a narrow box
assert(M.covers("FLARE NOW  [ R ]") and norm("FLARE NOW  [ R ]") == "FLARE NOW  (R)", "GumText: brackets")
assert(M.covers("SPORE STORM IN 03:47") and M.covers("Walk to the minecart and ride down into the mine!") and not M.covers("\u{1F48E}"), "GumText: covers")
assert(#(lines("one two three four five six", 20, 120, true)) > 1, "GumText: wrap")
return M
