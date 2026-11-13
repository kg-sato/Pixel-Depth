-- TapJuiceFX (ReplicatedStorage.Shared.TapJuiceFX), started by PixelClient. Directive v8: a streak combo for mining.
-- Every pickaxe hit on a block, every block broken and every PERFECT strike within 1.8 s of the last one adds to a streak.
-- From 3 up, a jelly counter ("X5 COMBO") lands at the right of the view, bigger and hotter as it grows (white, butter,
-- orange, pink), with a shrinking timer bar under it; each step rings a note a little higher (up to 1.4 times); from 10 up
-- a rainbow edge runs round the counter. A streak that runs out drops away. References: Instagram DfXxg4pMJSj (scaling
-- combo text) and DfJ9oAXghyN (prismatic trails), notes in the vault.
-- Display and sound only: the streak pays nothing. A paid multiplier would be the server's to grant (economy: the owner decides).
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local M = {}

local MID = Vector2.new(0.5, 0.5)
local WINDOW = 1.8
local RAMP = { Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 226, 130), Color3.fromRGB(255, 160, 70), Color3.fromRGB(255, 110, 180) }

function M.start(E)
	local JellyText = require(script.Parent:WaitForChild("JellyText"))
	local new = E.new
	local calm = false
	pcall(function() calm = game:GetService("GuiService").ReducedMotionEnabled end)
	local root = new("Frame", E.gui, { Name = "Combo", Size = E.S(230, 78), Position = E.S(1130, 452), AnchorPoint = MID, BackgroundTransparency = 1, Visible = false, ZIndex = 8 })
	local scale = new("UIScale", root, {})
	local word = new("Frame", root, { Size = UDim2.fromScale(1, 0.72), BackgroundTransparency = 1, ZIndex = 8 })
	local jt = JellyText.new(word, "X3 COMBO", { color = RAMP[1], glow = true, z = 8 })
	local bar = new("Frame", root, { Size = UDim2.fromScale(0.7, 0.07), Position = UDim2.fromScale(0.5, 0.86), AnchorPoint = MID, BackgroundColor3 = Color3.fromRGB(30, 21, 58), BackgroundTransparency = 0.3, BorderSizePixel = 0, ZIndex = 8 })
	new("UICorner", bar, { CornerRadius = UDim.new(0.5, 0) })
	local fill = new("Frame", bar, { Size = UDim2.fromScale(1, 1), BackgroundColor3 = RAMP[2], BorderSizePixel = 0, ZIndex = 9 })
	new("UICorner", fill, { CornerRadius = UDim.new(0.5, 0) })
	local rim = new("UIStroke", bar, { Color = Color3.new(1, 1, 1), Thickness = 2, Enabled = false })
	local rainbow = new("UIGradient", rim, { Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 90, 120)), ColorSequenceKeypoint.new(0.25, Color3.fromRGB(255, 220, 90)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(110, 240, 170)), ColorSequenceKeypoint.new(0.75, Color3.fromRGB(110, 190, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(220, 130, 255)) }) })

	local count, last, tier = 0, 0, 0
	local function bump()
		local now = os.clock()
		count = (now - last <= WINDOW) and count + 1 or 1
		last = now
		if count < 3 then return end
		local t = math.clamp(math.floor((count - 3) / 4) + 1, 1, #RAMP) -- 3, 7, 11, 15: a hotter colour
		if t ~= tier then tier = t jt.tint(RAMP[t]) fill.BackgroundColor3 = RAMP[math.max(t, 2)] end
		jt.set("X" .. count .. " COMBO")
		root.Visible = true
		rim.Enabled = count >= 10
		if not calm then
			jt.pop(0.012)
			scale.Scale = 1.25 + math.min(count, 20) * 0.012
			TweenService:Create(scale, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 + math.min(count, 20) * 0.012 }):Play()
			root.Rotation = (count % 2 == 0) and 3 or -3
			TweenService:Create(root, TweenInfo.new(0.3, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), { Rotation = 0 }):Play()
		end
		pcall(E.sfx, "pluck", 1 + math.min(count - 3, 10) * 0.04) -- the note climbs to 1.4 times
	end

	E.R.Fx.OnClientEvent:Connect(function(kind, a, b)
		if kind == "hit" or kind == "break" then bump()
		elseif kind == "mgStrike" and b == true then bump() end -- a PERFECT strike
	end)
	E.plr:GetAttributeChangedSignal("DevCombo"):Connect(function() -- Studio test hook: DevCombo = n adds n hits
		for _ = 1, E.plr:GetAttribute("DevCombo") or 0 do bump() end
	end)

	RunService.RenderStepped:Connect(function()
		if not root.Visible then return end
		local left = 1 - (os.clock() - last) / WINDOW
		fill.Size = UDim2.fromScale(math.clamp(left, 0, 1), 1)
		rainbow.Rotation = (os.clock() * 220) % 360
		if left <= 0 then -- the streak ran out: the counter drops away
			count, tier = 0, 0
			root.Visible = false
		end
	end)
end

return M
