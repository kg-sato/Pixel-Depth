-- SlimeBody (ReplicatedStorage.Shared.SlimeBody): one picture drawn as a soft slime body (night of 2026-11-16, the owner:
-- the jelly text "looks too much like a font instead of living slime ... the animation doesn't really simulate the text
-- moving physics, only the bounce"). The picture is cut into horizontal strips; the strips are moved and widened one by
-- one, so the shape itself bends:
--   * shear: the top lags behind the foot and swings back (jelly on a plate); the higher the strip, the further it moves
--   * squash: the body gets shorter and fatter in the middle (volume kept), or taller and thinner, around its foot
--   * wiggle (2026-11-17, the owner's references: After Effects jelly text, CC Bender from the foot plus a Twirl at the top,
--     and puppet pins on an inertial-bounce expression): a faster second mode bends the letter into an S, so the top
--     whips back while the middle still leans; each strip also tilts along the bend, so the letter reads bent, not sliced
-- All three are damped springs. A word couples its letters (JellyText), so a kick on one letter runs through the word as a wave.
--   local b = SlimeBody.new(parent, { image = id, rect = Vector2 (atlas cell offset) | nil, cell = Vector2 (picture or cell size in px), strips = 4, z = 3 })
--   b.kick(shearSpeed, squashSpeed)   b.step(dt, pullShear)   b.tint(c)   b.alpha(a)   b.setRect(image, rect)   b.frame (fills parent)
-- Under Reduced Motion the caller skips step (the strips sit still and whole).
local M = {}

local KS, CS = 150, 7.5 -- shear spring: about 2 wobbles a second, dying away in about a second
local KQ, CQ = 230, 10 -- squash spring
local KW, CW = 520, 11 -- wiggle spring: the S-bend, about 3.6 wobbles a second, gone sooner than the lean

function M.new(parent, o)
	local n = o.strips or 4
	local self = { s = 0, sv = 0, q = 0, qv = 0, w = 0, wv = 0, strips = {}, n = n, still = false }
	local frame = Instance.new("Frame")
	frame.Name, frame.BackgroundTransparency, frame.Size, frame.ZIndex = "Slime", 1, UDim2.fromScale(1, 1), o.z or 3
	frame.Parent = parent
	self.frame = frame
	for k = 1, n do
		local img = Instance.new("ImageLabel")
		img.Name, img.BackgroundTransparency, img.ZIndex = "Strip", 1, o.z or 3
		img.AnchorPoint = Vector2.new(0.5, 0.5)
		img.Parent = frame
		self.strips[k] = img
	end
	local cell = o.cell
	local PAD = math.max(1, math.floor(cell.Y / 128)) -- texture rows shared with the neighbour strip
	local hs = {} -- each strip's top and bottom as shares of the picture's height
	for k = 1, n do
		hs[k] = { ((k - 1) * cell.Y / n - (k > 1 and PAD or 0)) / cell.Y, (k * cell.Y / n + (k < n and PAD or 0)) / cell.Y }
	end
	function self.setRect(image, rect)
		for k, img in self.strips do
			img.Image = image
			local pad = (k > 1 and PAD or 0) + (k < n and PAD or 0) -- each strip also samples a few rows of its neighbours, drawn where they overlap: no seam lines
			img.ImageRectOffset = (rect or Vector2.zero) + Vector2.new(0, cell.Y * (k - 1) / n - (k > 1 and PAD or 0))
			img.ImageRectSize = Vector2.new(cell.X, cell.Y / n + pad)
		end
	end
	function self.tint(c) for _, img in self.strips do img.ImageColor3 = c or Color3.new(1, 1, 1) end end
	function self.alpha(a) for _, img in self.strips do img.ImageTransparency = a end end
	function self.kick(sv, qv)
		self.sv += sv or 0
		self.qv += qv or 0
		self.wv -= (sv or 0) * 0.7 -- the top whips the other way first: overlap, like offset keyframes
		self.still = false
	end
	-- draw the strips from the springs: k = 1 is the top strip; the foot stays put
	function self.apply()
		local s, q, w = math.clamp(self.s, -0.3, 0.3), math.clamp(self.q, -0.32, o.qmax or 0.36), math.clamp(self.w, -0.2, 0.2) -- qmax: how far it may stretch (the loading logo lands 1.9 tall)
		local sy = 1 + q
		local sx = 1 / math.sqrt(sy)
		local function off(up) return s * up ^ 1.6 + w * math.sin(math.pi * up) * up end -- sideways shift at height up (0 foot .. 1 top)
		local asp = frame.AbsoluteSize.X / math.max(frame.AbsoluteSize.Y, 1)
		for k, img in self.strips do
			local a, b = hs[k][1], hs[k][2]
			local mid = (a + b) / 2 -- 0 top .. 1 foot
			local up = 1 - mid
			local belly = math.sin(math.pi * mid) -- the middle bulges most when squashed
			local w = sx * (1 - 0.45 * q * belly)
			img.Size = UDim2.fromScale(w, sy * (b - a))
			img.Position = UDim2.fromScale(0.5 + off(up), 1 - sy * (1 - mid))
			local slope = (off(math.min(up + 0.05, 1)) - off(math.max(up - 0.05, 0))) / 0.1 * asp / sy -- sideways per upward, in screen units
			img.Rotation = math.clamp(math.deg(math.atan(slope)), -14, 14)
		end
	end
	-- one physics step; pull = the shear the neighbours want this letter to have (0 when alone). Returns the energy left.
	function self.step(dt, pull)
		if self.still then -- at rest: nothing to do until a neighbour's wave arrives
			if math.abs(pull or 0) < 0.002 then return 0 end
			self.still = false
		end
		dt = math.min(dt, 1 / 30)
		self.sv += (-KS * self.s - CS * self.sv + (pull or 0) * 60) * dt
		self.qv += (-KQ * self.q - CQ * self.qv) * dt
		self.wv += (-KW * self.w - CW * self.wv) * dt
		self.s += self.sv * dt
		self.q += self.qv * dt
		self.w += self.wv * dt
		local e = math.abs(self.s) + math.abs(self.q) + math.abs(self.w) + (math.abs(self.sv) + math.abs(self.qv) + math.abs(self.wv)) * 0.05
		if e < 0.0015 and not self.still then
			self.s, self.sv, self.q, self.qv, self.w, self.wv = 0, 0, 0, 0, 0, 0
			self.still = true
			self.apply()
		elseif not self.still then
			self.apply()
		end
		return e
	end
	if o.image then self.setRect(o.image, o.rect) end
	self.apply()
	return self
end

do -- self-check: a kick dies away and the body comes to rest whole
	local t = M.new(Instance.new("Frame"), { cell = Vector2.new(128, 128), strips = 3 })
	t.kick(3, -4)
	for _ = 1, 240 do t.step(1 / 60) end
	assert(t.still and t.s == 0 and t.q == 0 and t.w == 0, "SlimeBody: settles") -- self-check
end
return M
