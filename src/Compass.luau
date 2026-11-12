-- Compass (ReplicatedStorage.Shared.Compass), started by PixelClient. A top compass ribbon for the caves: the letters
-- slide as you turn, the campfire icon sits at the bearing of the nearer camp and sticks to the end of the ribbon when
-- camp is behind you. Client only, display only.
-- A/B candidate (2026-11-11): the round radar already carries N and the camp icon, and the user took an earlier top
-- ribbon out on 2026-11-08. It shows only when M.ON is true or the client attribute DevCompass is set; while it shows,
-- the radar's own N and camp icon are hidden (one compass at a time).
local M = {}
M.ON = false

local SPAN = 150 -- degrees across the ribbon

function M.start(E)
	local C, new, S, plr = E.C, E.new, E.S, E.plr
	local cam = workspace.CurrentCamera
	local bar = new("CanvasGroup", E.caveHud, { Name = "Compass", Size = S(300, 26), Position = S(640, 12), AnchorPoint = Vector2.new(0.5, 0),
		BackgroundColor3 = E.CREAM, BackgroundTransparency = 0.08, BorderSizePixel = 0, ZIndex = 5, Visible = false })
	E.fit(bar, 300, 26)
	new("UICorner", bar, { CornerRadius = UDim.new(0.5, 0) })
	new("UIStroke", bar, { Color = E.INK, Thickness = 2.5 }) -- a cream pill with an ink rim, like the objective card (a dark brass strip graded fit 3)
	local DEEP_PINK = Color3.fromRGB(226, 88, 138)
	local marks = {}
	local NAMES = { [0] = "N", [45] = "NE", [90] = "E", [135] = "SE", [180] = "S", [225] = "SW", [270] = "W", [315] = "NW" }
	for d = 0, 345, 15 do
		local o
		if NAMES[d] then
			local big = d % 90 == 0
			o = E.text(bar, NAMES[d], UDim2.fromScale(0.12, big and 0.78 or 0.5), UDim2.fromScale(0.5, 0.5), Vector2.new(0.5, 0.5), d == 0 and DEEP_PINK or E.INK, nil, false)
			o.TextTransparency = big and 0 or 0.45
		else
			o = new("Frame", bar, { Size = UDim2.new(0, 2, 0.34, 0), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = E.INK, BackgroundTransparency = 0.7, BorderSizePixel = 0 })
		end
		o.ZIndex = 6
		table.insert(marks, { d, o })
	end
	local camp = E.icon(bar, "camp", UDim2.fromScale(0.9, 0.9), UDim2.fromScale(0.5, 0.5), Vector2.new(0.5, 0.5))
	camp.SizeConstraint, camp.ZIndex = Enum.SizeConstraint.RelativeYY, 8
	local notch = new("Frame", bar, { Size = UDim2.new(0, 3, 0.3, 0), Position = UDim2.fromScale(0.5, 0), AnchorPoint = Vector2.new(0.5, 0), BackgroundColor3 = DEEP_PINK, BorderSizePixel = 0, ZIndex = 9 })
	new("UICorner", notch, { CornerRadius = UDim.new(0.5, 0) })

	local function rel(deg, yaw) return (deg - yaw + 180) % 360 - 180 end
	game:GetService("RunService").RenderStepped:Connect(function()
		local h = E.hrp()
		local on = h ~= nil and plr:GetAttribute("InCave") == true and (M.ON or plr:GetAttribute("DevCompass") ~= nil) and not E.isBusy()
		bar.Visible = on
		local radar = E.caveHud:FindFirstChild("Minimap")
		if radar then
			for _, n in { "North", "CampIcon" } do
				local o = radar:FindFirstChild(n)
				if o then o.Visible = not on end
			end
		end
		if not on then return end
		local lv = cam.CFrame.LookVector
		local yaw = math.deg(math.atan2(lv.X, -lv.Z)) -- 0 = north (-Z), as on the radar
		for _, m in marks do
			local r = rel(m[1], yaw)
			m[2].Visible = math.abs(r) < SPAN / 2
			m[2].Position = UDim2.fromScale(0.5 + r / SPAN, 0.5)
		end
		local p = h.Position
		local to = C.CAVE_ORIGIN - p
		if (C.CAVE2_ORIGIN - p).Magnitude < to.Magnitude then to = C.CAVE2_ORIGIN - p end
		local r = math.clamp(rel(math.deg(math.atan2(to.X, -to.Z)), yaw), -SPAN / 2 * 0.9, SPAN / 2 * 0.9) -- behind you: it waits at the end to turn toward
		camp.Position = UDim2.fromScale(0.5 + r / SPAN, 0.5)
	end)
end

return M
