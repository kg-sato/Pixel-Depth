-- JellySkin (ReplicatedStorage.Shared.JellySkin), started by PixelClient. Directive v10.0 re-run (2026-11-16), HUD point 2: every
-- button and pill on one Obsidian-Lavender Jelly-Glass look. Gemini (round v10n_r6, 4.8/10): "flat, murky rectangular blocks
-- with hairline strokes; no jelly bevel, no top dome shine". The kit images stay; on top of each pill and button this adds
--   * a jelly bevel: a rim of light round the shape, cyan at the top fading to violet (magenta for the pink kinds)
--   * a top dome shine: a soft white crescent over the upper half, clipped inside the shape
--   * the 0.92 -> 1.08 -> 1.0 bounce on hover and press for the pills that take clicks through a "Hit" button
--     (JellyPress already bounces the real buttons that wear a skin)
-- The cave hotbar's hexes get the same dome shine. Display only; nothing here changes what a button does.
local TweenService = game:GetService("TweenService")
local M = {}
local VIOLET, MAGENTA, CYAN = Color3.fromRGB(155, 31, 232), Color3.fromRGB(255, 0, 127), Color3.fromRGB(0, 240, 255)
local PINKISH = { pink = true, pillPink = true }
local SKIP = { panel = true, card = true, slot = true, keycap = true } -- big panels keep their own glass; key caps are too small
M.KINDS = function(k) return not SKIP[k] and not string.find(k, "^ribbon") end

local function shine(o, z, w, h, y)
	if o:FindFirstChild("DomeShine") then return end
	local f = Instance.new("Frame")
	f.Name, f.BorderSizePixel, f.BackgroundColor3, f.ClipsDescendants = "DomeShine", 0, Color3.new(1, 1, 1), true
	f.Size, f.Position, f.AnchorPoint, f.ZIndex = UDim2.fromScale(w or 0.84, h or 0.4), UDim2.fromScale(0.5, y or 0.07), Vector2.new(0.5, 0), z
	local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0.5, 0) c.Parent = f
	local g = Instance.new("UIGradient") g.Rotation, g.Transparency = 90, NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(0.7, 0.88), NumberSequenceKeypoint.new(1, 1) }) g.Parent = f
	f.Parent = o
end

local function rim(o, kind)
	if o:FindFirstChild("JellyRim") then return end
	if not o:FindFirstChildOfClass("UICorner") then -- the stroke follows the frame's own corner: round it like the pill image
		local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0.32, 0) c.Parent = o
	end
	local s = Instance.new("UIStroke")
	s.Name, s.ApplyStrokeMode, s.Color, s.Thickness, s.Transparency = "JellyRim", Enum.ApplyStrokeMode.Border, Color3.new(1, 1, 1), 1.6, 0.15
	local g = Instance.new("UIGradient") g.Rotation, g.Color = 90, ColorSequence.new(CYAN, PINKISH[kind] and MAGENTA or VIOLET) g.Parent = s
	s.Parent = o
end

local function bounce(o)
	local hit = o:FindFirstChild("Hit")
	if not hit or not hit:IsA("GuiButton") or o:FindFirstChild("JellyBounce") then return end
	local sc = Instance.new("UIScale") sc.Name = "JellyBounce" sc.Parent = o
	local function go(from)
		sc.Scale = from
		local up = TweenService:Create(sc, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 1.08 })
		up.Completed:Once(function() TweenService:Create(sc, TweenInfo.new(0.16, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play() end)
		up:Play()
	end
	hit.MouseEnter:Connect(function() go(0.96) end)
	hit.MouseButton1Down:Connect(function() go(0.92) end)
end

function M.dress(o)
	local kind = o:GetAttribute("Kind")
	if typeof(kind) ~= "string" or not o:IsA("GuiObject") or not M.KINDS(kind) then return end
	local sk = o:FindFirstChild("Skin")
	shine(o, (sk and sk.ZIndex or 0) + 1)
	rim(o, kind)
	bounce(o)
end

function M.start(E)
	local gui = E.gui
	for _, d in gui:GetDescendants() do M.dress(d) end
	gui.DescendantAdded:Connect(function(d) task.defer(function() if d.Parent then M.dress(d) end end) end)
	task.delay(4, function() for _, d in gui:GetDescendants() do M.dress(d) end end) -- skins set after their frame was added
	task.spawn(function() -- the cave hotbar's hexes: a dome shine on each slot
		local bar = E.caveHud and E.caveHud:WaitForChild("Hotbar", 20)
		for _, slot in bar and bar:GetChildren() or {} do
			if slot:IsA("GuiObject") then shine(slot, slot.ZIndex + 1, 0.5, 0.26, 0.14) end -- narrower: inside the hex's slanted top
		end
	end)
end

assert(M.KINDS("pillLilac") and M.KINDS("mint") and not M.KINDS("panel") and not M.KINDS("ribbonPink"), "JellySkin: kind filter") -- self-check
return M
