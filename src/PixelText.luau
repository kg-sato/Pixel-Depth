-- ReplicatedStorage.Shared.PixelText: draws a TextLabel's or TextButton's text with the Pixelify Sans bitmap font
-- (OFL font rendered to 64 px atlases in art/font/, uploaded 2026-11-08; Roblox has no Pixelify Sans).
-- PixelText.attach(label, weight) hides the native glyphs (MaxVisibleGraphemes = 0) and mirrors Text, TextColor3,
-- TextTransparency, TextStrokeColor3/Transparency and TextXAlignment, so existing code and tweens keep working.
local PixelText = {}

local ATLAS = {
	[500] = { fill = "rbxassetid://98026650331400", stroke = "rbxassetid://127047589283705", thin = "rbxassetid://109532858380791" },
	[700] = { fill = "rbxassetid://113687285109205", stroke = "rbxassetid://133759107716720", thin = "rbxassetid://108795817649064" },
}
local CW, CH, COLS, X0 = 64, 80, 16, 8 -- atlas cell, columns, left pad inside a cell (baseline at y 60)
local BODY = 64 -- cell rows that hold ink from cap top to descender, used to fit the label height
local TRACK = { [500] = 3, [700] = 3 } -- extra letter spacing in atlas pixels (Gemini font review: outlines touched)
local THICK_AT = 0.9 -- glyph scale from which the thick outline is used; smaller text gets the thin one
-- advance widths in atlas pixels for codepoints 32..126
local ADV = {
	[500] = { 12.8, 14.8, 30.2, 43.6, 37.9, 55.7, 43.6, 17.7, 24.4, 24.4, 17.7, 38.4, 17.7, 22, 14.8, 34.2, 37.9, 26.3, 37.9, 37.9, 37.9, 37.9, 37.9, 37.9, 37.9, 37.9, 14.8, 17.7, 38.4, 38.4, 38.4, 37.9, 39.4, 37.9, 37.9, 37.9, 37.9, 37.9, 37.9, 37.9, 37.9, 26.3, 37.9, 37.9, 37.9, 49.3, 37.9, 37.9, 37.9, 37.9, 37.9, 37.9, 37.9, 37.9, 37.9, 49.3, 37.9, 37.9, 37.9, 24.4, 34.2, 24.4, 17.7, 28.7, 17.5, 43.6, 37.9, 37.9, 37.9, 37.9, 37.9, 37.9, 37.9, 14.8, 32.1, 37.9, 14.8, 49.3, 37.9, 37.9, 37.9, 37.9, 37.9, 37.9, 43.6, 37.9, 37.2, 49.3, 37.9, 37.9, 37.9, 30.1, 14.8, 30.1, 38.4 },
	[700] = { 12.8, 15.9, 31.1, 44.3, 38.6, 56.1, 44.3, 18.8, 25.3, 25.3, 18.8, 38.4, 18.8, 23.5, 15.9, 35.1, 38.6, 27.3, 38.6, 38.6, 38.6, 38.6, 38.6, 38.6, 38.6, 38.6, 15.9, 18.8, 38.4, 38.4, 38.4, 38.6, 43.1, 38.6, 38.6, 38.6, 38.6, 38.6, 38.6, 38.6, 38.6, 27.3, 38.6, 38.6, 38.6, 49.9, 38.6, 38.6, 38.6, 38.6, 38.6, 38.6, 38.6, 38.6, 38.6, 49.9, 38.6, 38.6, 38.6, 25.3, 35.1, 25.3, 18.8, 29.6, 18.6, 44.3, 38.6, 38.6, 38.6, 38.6, 38.6, 38.6, 38.6, 15.9, 33, 38.6, 15.9, 49.9, 38.6, 38.6, 38.6, 38.6, 38.6, 38.6, 44.3, 38.6, 38, 49.9, 38.6, 38.6, 38.6, 31, 15.9, 31, 38.4 },
}

local function advance(weight, cp)
	return (ADV[weight][cp - 31] or ADV[weight][64]) + TRACK[weight] -- unknown characters use "?"
end

local function paint(label, holder)
	local tt, st = label.TextTransparency, label.TextStrokeTransparency
	for _, g in holder:GetChildren() do
		if g.Name == "F" then
			g.ImageColor3, g.ImageTransparency = label.TextColor3, tt
		else
			g.ImageColor3, g.ImageTransparency = label.TextStrokeColor3, math.max(tt, st)
		end
	end
end

local function layout(label, holder, weight)
	holder:ClearAllChildren()
	local text, abs = label.Text, label.AbsoluteSize
	if text == "" or abs.X < 1 or abs.Y < 1 then return end
	local total = 0
	for _, cp in utf8.codes(text) do total += advance(weight, cp) end
	-- scale in atlas pixels -> label pixels; TextScaled fits both height and width
	local s = math.min(abs.Y / BODY, abs.X / math.max(total, 1))
	if not label.TextScaled then s = math.min(s, label.TextSize / 52) end
	local w = (total - TRACK[weight]) * s
	local align = label.TextXAlignment
	local pen = align == Enum.TextXAlignment.Left and 0 or (align == Enum.TextXAlignment.Right and abs.X - w or (abs.X - w) / 2)
	local y = (abs.Y - CH * s) / 2 + 4 * s -- ink centre sits 4 px below the cell centre
	local stroke = label.TextStrokeTransparency < 1
	local outline = s >= THICK_AT and "stroke" or "thin"
	for _, cp in utf8.codes(text) do
		local i = (cp >= 32 and cp <= 126) and cp - 32 or 31
		local off = Vector2.new((i % COLS) * CW, (i // COLS) * CH)
		if cp ~= 32 then
			for _, layer in stroke and { "S", "F" } or { "F" } do
				local g = Instance.new("ImageLabel")
				g.Name, g.BackgroundTransparency, g.BorderSizePixel = layer, 1, 0
				g.Image = ATLAS[weight][layer == "F" and "fill" or outline]
				g.ImageRectOffset, g.ImageRectSize = off, Vector2.new(CW, CH)
				-- scale units so a UIScale pop or a tween of the label size needs no relayout
				g.Size = UDim2.fromScale(CW * s / abs.X, CH * s / abs.Y)
				g.Position = UDim2.fromScale((pen - X0 * s) / abs.X, y / abs.Y)
				g.ZIndex = label.ZIndex + (layer == "F" and 1 or 0)
				g.Parent = holder
			end
		end
		pen += advance(weight, cp) * s
	end
	paint(label, holder)
end

function PixelText.attach(label: TextLabel | TextButton, weight: number?)
	local wt = (weight == 500) and 500 or 700
	label.MaxVisibleGraphemes = 0
	local holder = Instance.new("Frame")
	holder.Name, holder.BackgroundTransparency, holder.Size = "PixelGlyphs", 1, UDim2.fromScale(1, 1)
	holder.Parent = label
	local aspect = 0
	local function relayout()
		local a = label.AbsoluteSize
		aspect = a.X / math.max(a.Y, 1)
		layout(label, holder, wt)
	end
	label:GetPropertyChangedSignal("Text"):Connect(relayout)
	label:GetPropertyChangedSignal("TextXAlignment"):Connect(relayout)
	label:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		local a = label.AbsoluteSize
		if #holder:GetChildren() == 0 or math.abs(a.X / math.max(a.Y, 1) - aspect) > 0.02 * aspect then relayout() end
	end)
	for _, p in { "TextColor3", "TextTransparency", "TextStrokeTransparency", "TextStrokeColor3" } do
		label:GetPropertyChangedSignal(p):Connect(function() paint(label, holder) end)
	end
	relayout()
	return label
end

return PixelText
