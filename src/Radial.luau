-- Radial (ReplicatedStorage.Shared.Radial): circular progress for the HUD (the survival talisman's torch ring, the upgrade
-- tracker's ring, the flare cooldown wipe). A ring is two half-circles, each inside a clipping half; a UIGradient with a hard
-- transparency step turns in each half, so the visible arc grows clockwise from 12 o'clock. Nothing is rotated (a rotated
-- frame is not clipped), so it only draws arcs that start at the top.
local M = {}

local STEP = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.4999, 0), NumberSequenceKeypoint.new(0.5, 1), NumberSequenceKeypoint.new(1, 1) })

local function make(cls, parent, props)
	local o = Instance.new(cls)
	for k, v in props do o[k] = v end
	o.Parent = parent
	return o
end

-- parent: a square GuiObject. opt: thick (share of the diameter; nil = a filled pie), color, track (a faint full ring behind, or nil),
-- trackTransparency, z. Returns { root, set(fraction 0..1), color(Color3) }.
function M.arc(parent, opt)
	local root = make("Frame", parent, { Name = opt.name or "Arc", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = opt.z or 2 })
	local strokes, grads, fills = {}, {}, {}
	local function ring(holder, pos, color, transparency)
		local f = make("Frame", holder, { Size = UDim2.fromScale(1, 1), Position = pos, BackgroundColor3 = color, BackgroundTransparency = opt.thick and 1 or transparency, BorderSizePixel = 0, ZIndex = opt.z or 2 })
		make("UICorner", f, { CornerRadius = UDim.new(0.5, 0) })
		local target = f
		if opt.thick then
			target = make("UIStroke", f, { Color = color, Transparency = transparency, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
			table.insert(strokes, { stroke = target, frame = f, holder = holder })
		elseif holder ~= root then
			table.insert(fills, f)
		end
		return f, target
	end
	if opt.track then ring(root, UDim2.new(), opt.track, opt.trackTransparency or 0.6) end
	for side = 0, 1 do
		local clip = make("Frame", root, { Size = UDim2.fromScale(0.5, 1), Position = UDim2.fromScale(side * 0.5, 0), BackgroundTransparency = 1, ClipsDescendants = true, ZIndex = opt.z or 2 })
		local f, target = ring(clip, UDim2.fromScale(-side, 0), opt.color or Color3.new(1, 1, 1), opt.thick and 0 or (opt.fillTransparency or 0))
		f.Size = UDim2.fromScale(2, 1)
		grads[side] = make("UIGradient", target, { Transparency = STEP })
	end
	local function resize() -- the stroke is drawn outside its frame: inset each ring by the stroke so the arc stays inside the square
		local d = root.AbsoluteSize.Y
		local t = math.max(1, d * (opt.thick or 0))
		for _, s in strokes do
			s.stroke.Thickness = t
			local full = s.holder == root
			s.frame.Size = UDim2.new(full and 1 or 2, -2 * t, 1, -2 * t)
			s.frame.Position = UDim2.new(s.frame.Position.X.Scale, t, 0, t)
		end
	end
	if opt.thick then
		root:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize)
		resize()
	end
	local api = { root = root }
	function api.set(frac)
		local a = math.clamp(frac, 0, 1) * 360
		grads[1].Rotation = math.clamp(a, 0, 180) -- right half: 12 o'clock round to 6
		grads[0].Rotation = math.clamp(a, 180, 360) -- left half: 6 o'clock round to 12
	end
	function api.color(c)
		for _, s in strokes do if s.holder ~= root then s.stroke.Color = c end end
		for _, f in fills do f.BackgroundColor3 = c end
	end
	api.set(opt.value or 1)
	return api
end

return M
