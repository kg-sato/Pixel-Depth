-- DepthGauge (ReplicatedStorage.Shared.DepthGauge), started by PixelClient with the cut-glass kit. Directive v8: a rolling
-- depth readout for the caves (reference: Instagram DctcTLNJxSk, a gauge whose digits roll, "-120m"). A small smoked glass
-- pill above the radar shows how far below Camp 1's fire you stand, in metres (one stud = 0.28 m), in cyan jelly digits
-- that roll toward the true value instead of jumping. Above the camp it reads 0 M. Display only.
local RunService = game:GetService("RunService")
local M = {}

function M.start(E)
	if not E.GLASS then return end
	local JellyText = require(script.Parent:WaitForChild("JellyText"))
	local new = E.new
	local pill = new("Frame", E.caveHud, { Name = "DepthGauge", Size = E.S(104, 26), Position = E.S(1182, 118), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Color3.fromRGB(30, 21, 58), BackgroundTransparency = 0.2, BorderSizePixel = 0, ZIndex = 3 })
	E.fit(pill, 104, 26)
	new("UICorner", pill, { CornerRadius = UDim.new(0.5, 0) })
	new("UIStroke", pill, { Color = Color3.fromRGB(150, 232, 255), Thickness = 1.5, Transparency = 0.25 })
	local holder = new("Frame", pill, { Size = UDim2.fromScale(0.84, 0.74), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, ZIndex = 4 })
	local jt = JellyText.new(holder, "0 M", { color = Color3.fromRGB(110, 215, 255), sway = false, z = 4 })
	local shown, last = 0, -1
	RunService.RenderStepped:Connect(function(dt)
		local boss = E.gui:FindFirstChild("BossBar", true)
		pill.Visible = not (E.cave.mgBusy or (boss and boss.Visible))
		if not E.caveHud.Visible or not pill.Visible then return end
		local h = E.hrp()
		if not h then return end
		local depth = math.max(0, (E.C.CAVE_ORIGIN.Y - h.Position.Y) * 0.28)
		shown += (depth - shown) * math.min(1, dt * 4) -- the digits roll after the true value
		local n = math.floor(shown + 0.5)
		if n ~= last then
			last = n
			jt.set((n > 0 and "-" or "") .. n .. " M")
		end
	end)
end

return M
