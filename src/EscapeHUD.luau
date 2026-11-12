-- EscapeHUD (ReplicatedStorage.Shared.EscapeHUD), started by MinecartEscape for each run. The escape's reading aids:
-- a stopwatch chip beside the progress bar, the gap meter at the bottom centre (your cart waits at the right end, the
-- Gloom creeps toward it from the left and the danger fill grows behind it), the lean / jump / duck warnings (a row of
-- chevrons with the key to press) and the pop of the 3-2-1. Display only: the run itself is judged in MinecartEscape
-- and paid by the server.
local TweenService = game:GetService("TweenService")
local M = {}

local WHITE, INK = Color3.new(1, 1, 1), Color3.fromRGB(62, 42, 86)
local CREAM, BUTTER, PINK, MINT = Color3.fromRGB(236, 228, 255), Color3.fromRGB(255, 217, 112), Color3.fromRGB(255, 157, 176), Color3.fromRGB(127, 220, 180)
local GLOOM = Color3.fromRGB(124, 96, 184)
local MID = Vector2.new(0.5, 0.5)

function M.start(E)
	local gui, calm, keys = E.gui, E.calm == true, E.keys == true
	local function frame(parent, props)
		local f = Instance.new("Frame")
		f.BorderSizePixel, f.AnchorPoint = 0, MID
		for k, v in props do f[k] = v end
		f.Parent = parent
		return f
	end
	local function round(o, r)
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(r or 0.5, 0)
		c.Parent = o
	end
	local function stroke(o, col, th)
		local s = Instance.new("UIStroke")
		s.Color, s.Thickness = col, th
		s.Parent = o
		return s
	end
	local function label(parent, text, size, pos, color, z)
		local t = Instance.new("TextLabel")
		t.BackgroundTransparency, t.Font, t.TextScaled, t.Text, t.TextColor3 = 1, Enum.Font.FredokaOne, true, text, color
		t.Size, t.Position, t.AnchorPoint, t.ZIndex = size, pos, MID, z or 5
		t.Parent = parent
		return t
	end
	local function square(parent, k, pos, color, z) -- a square sized from the height of its parent
		local f = frame(parent, { Size = UDim2.fromScale(k, k), SizeConstraint = Enum.SizeConstraint.RelativeYY, Position = pos, BackgroundColor3 = color, ZIndex = z })
		round(f)
		return f
	end

	-- the stopwatch chip
	local chip = frame(gui, { Size = UDim2.fromScale(0.078, 0.05), Position = UDim2.fromScale(0.742, 0.06), BackgroundColor3 = CREAM, ZIndex = 3 })
	round(chip)
	chip.BackgroundTransparency = 0.14 -- frosted glass (directive v8), a fine deep edge
	stroke(chip, INK, 1.5)
	local dial = square(chip, 0.66, UDim2.fromScale(0.2, 0.5), BUTTER, 4)
	stroke(dial, INK, 2)
	local spin = frame(dial, { Size = UDim2.fromScale(1, 1), Position = UDim2.fromScale(0.5, 0.5), BackgroundTransparency = 1, ZIndex = 5 })
	frame(spin, { Size = UDim2.fromScale(0.14, 0.42), Position = UDim2.fromScale(0.5, 0.29), BackgroundColor3 = INK, ZIndex = 5 })
	local timeText = label(chip, "0.0", UDim2.fromScale(0.56, 0.72), UDim2.fromScale(0.66, 0.5), INK, 5)

	-- the gap meter: bottom centre, just above the cart's rim, where the eye already is
	local box = frame(gui, { Size = UDim2.fromScale(0.24, 0.085), Position = UDim2.fromScale(0.5, 0.925), BackgroundTransparency = 1, ZIndex = 3 })
	local track = frame(box, { Size = UDim2.fromScale(0.9, 0.34), Position = UDim2.fromScale(0.5, 0.72), BackgroundColor3 = CREAM, ZIndex = 3 })
	round(track)
	track.BackgroundTransparency = 0.2
	stroke(track, INK, 1.5)
	local fill = frame(track, { AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.fromScale(0.1, 1), Position = UDim2.fromScale(0, 0.5), BackgroundColor3 = GLOOM, ZIndex = 4 })
	round(fill)
	local blob = square(box, 0.7, UDim2.fromScale(0.09, 0.68), GLOOM, 6) -- the Gloom: a soot ball with two eyes
	stroke(blob, INK, 3)
	for _, x in { 0.36, 0.68 } do square(blob, 0.2, UDim2.fromScale(x, 0.42), WHITE, 7) end
	local cart = frame(box, { Size = UDim2.fromScale(0.86, 0.56), SizeConstraint = Enum.SizeConstraint.RelativeYY, Position = UDim2.fromScale(0.93, 0.56), BackgroundColor3 = BUTTER, ZIndex = 6 })
	round(cart, 0.25)
	stroke(cart, INK, 3)
	frame(cart, { Size = UDim2.fromScale(1, 0.22), Position = UDim2.fromScale(0.5, 0.3), BackgroundColor3 = CREAM, ZIndex = 7 }) -- the cart's rim band
	for _, x in { 0.24, 0.76 } do square(cart, 0.46, UDim2.fromScale(x, 1.05), INK, 7) end
	local gapText = label(box, "THE GLOOM  30 m", UDim2.fromScale(0.9, 0.36), UDim2.fromScale(0.5, 0.16), WHITE, 5) -- the words never change, only the number and the colour
	stroke(gapText, INK, 3)

	-- the warnings: butter chevrons running the way to go, with the key to press
	local KEY = { right = "D", left = "A", up = "SPACE", down = "S" }
	local warns = {}
	for dir, d in { right = { 0.76, 0.5, 0, "LEAN" }, left = { 0.24, 0.5, 180, "LEAN" }, up = { 0.5, 0.27, -90, "JUMP" }, down = { 0.5, 0.68, 90, "DUCK" } } do
		-- one dark plate holds the chevrons and the key, so neither melts into the lanterns behind
		local c = frame(gui, { Size = UDim2.fromScale(0.19, 0.19), SizeConstraint = Enum.SizeConstraint.RelativeYY, Position = UDim2.fromScale(d[1], d[2]), BackgroundColor3 = Color3.fromRGB(24, 16, 46), BackgroundTransparency = 0.22, ZIndex = 5, Visible = false })
		round(c, 0.18)
		stroke(c, CREAM, 1.5)
		local arrow = frame(c, { Size = UDim2.fromScale(0.6, 0.6), Position = UDim2.fromScale(0.5, 0.33), BackgroundTransparency = 1, Rotation = d[3], ZIndex = 5 })
		local bars = {}
		for i = 1, 3 do -- three chevrons in a row along the arrow's own axis
			bars[i] = {}
			for _, s in { -1, 1 } do
				local b = frame(arrow, { Size = UDim2.fromScale(0.4, 0.13), Position = UDim2.fromScale(-0.16 + i * 0.33, 0.5 + s * 0.125), Rotation = -s * 40, BackgroundColor3 = BUTTER, ZIndex = 5 })
				round(b)
				table.insert(bars[i], { b })
			end
		end
		local cap = frame(c, { Size = UDim2.fromScale(keys and (dir == "up" and 0.84 or 0.36) or 0.84, 0.26), Position = UDim2.fromScale(0.5, 0.78), BackgroundColor3 = CREAM, BackgroundTransparency = keys and 0 or 1, ZIndex = 5 })
		round(cap, 0.3)
		local capStroke = stroke(cap, INK, 3)
		capStroke.Enabled = keys
		local word = label(cap, keys and KEY[dir] or d[4], UDim2.fromScale(0.86, 0.8), UDim2.fromScale(0.5, 0.5), keys and INK or BUTTER, 6)
		if not keys then stroke(word, INK, 3) end
		local sc = Instance.new("UIScale")
		sc.Parent = c
		warns[dir] = { c = c, bars = bars, scale = sc }
	end

	local hud = {}
	function hud.time(t)
		timeText.Text = string.format("%.1f", math.max(t, 0))
		spin.Rotation = math.max(t, 0) * 360 -- one turn of the hand each second
	end
	local gapShown, gapAt = 1, nil
	function hud.gap(g, now) -- g: 1 = the Gloom is far behind, 0 = it has you
		-- the meter chases the true gap instead of jumping when a BONK takes a third of it at once (video judge 2026-11-11)
		gapShown += (math.clamp(g, 0, 1) - gapShown) * (1 - math.exp(-math.min(now - (gapAt or now), 0.1) * 7))
		gapAt = now
		g = gapShown
		local close = g <= 0.3
		local x = 0.09 + 0.7 * (1 - g) -- the Gloom walks toward the cart
		local beat = (close and not calm) and 0.1 * math.abs(math.sin(now * 9)) or 0
		blob.Position = UDim2.fromScale(x, 0.68)
		blob.Size = UDim2.fromScale(0.7 + beat, 0.7 + beat)
		blob.BackgroundColor3 = close and PINK or GLOOM
		fill.Size = UDim2.fromScale(math.clamp((x - 0.05) / 0.9, 0.05, 1), 1) -- the danger fill grows behind it
		fill.BackgroundColor3 = close and PINK or GLOOM -- never butter: butter is the cart
		gapText.Text = "THE GLOOM  " .. math.floor(g * 30 + 0.5) .. " m"
		gapText.TextColor3 = close and PINK or WHITE
	end
	local shown, lastAsk, quietUntil = nil, 0, 0
	function hud.hit(now) -- a BONK: the plate steps aside for the word
		quietUntil = now + 0.25
	end
	function hud.warn(dir, now)
		if dir then lastAsk = now end
		-- a gap of a frame or two between one hazard and the next must not blink the plate off and on
		local want = dir or ((now - lastAsk < 0.12) and shown or nil)
		if now < quietUntil then want = nil end
		if want ~= shown then
			shown = want
			if want and not calm then -- it arrives with a small pop
				local sc = warns[want].scale
				sc.Scale = 0.7
				TweenService:Create(sc, TweenInfo.new(0.16, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
			end
		end
		dir = shown
		for name, w in warns do
			local on = name == dir
			w.c.Visible = on
			if on then
				for i, pair in w.bars do -- the light runs along the row, toward where to go
					local a = calm and 0 or 0.7 * (0.5 + 0.5 * math.sin(now * 14 - i * 1.4))
					for _, b in pair do b[1].BackgroundTransparency = a end
				end
			end
		end
	end
	function hud.pop(o) -- the 3-2-1 lands with a pop
		if calm then return end
		local s = o:FindFirstChildOfClass("UIScale") or Instance.new("UIScale")
		s.Scale, s.Parent = 1.6, o
		TweenService:Create(s, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	end
	function hud.hide()
		chip.Visible, box.Visible = false, false
		shown, lastAsk = nil, -1 -- no grace here: a plate that was up when the run ended must not stay on the result screen (Codex review)
		for _, w in warns do w.c.Visible = false end
	end
	return hud
end

return M
