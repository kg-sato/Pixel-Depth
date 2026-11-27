-- TextFloor (ReplicatedStorage.Shared.TextFloor), started by PixelClient. Whole Game Polish audit 2026-11-26 (Global Typography,
-- rule 1): labels drawn with TextScaled in narrow boxes shrank to 5-7 px (Codex grid names, forge tiles, the tracker pill, the
-- Soul Tree's SHARDS). Every TextScaled label or button on this player's screens gets a floor: 12 px, or 11 px for a compact tag
-- (a box under 16 px tall). A label that already has a UITextSizeConstraint keeps its own maximum and gets the floor under it.
-- Screen guis only: world signs (SurfaceGui, BillboardGui) are sized by their own PixelsPerStud.
local M = {}
local BODY, TAG = 12, 11

local function onScreen(o)
	local g = o:FindFirstAncestorWhichIsA("LayerCollector")
	return g ~= nil and g:IsA("ScreenGui")
end

local function floor(o)
	if not (o:IsA("TextLabel") or o:IsA("TextButton") or o:IsA("TextBox")) or not o.TextScaled or not onScreen(o) then return end
	local want = (o.AbsoluteSize.Y > 0 and o.AbsoluteSize.Y < 16) and TAG or BODY
	local c = o:FindFirstChildOfClass("UITextSizeConstraint")
	if c then
		if c.MinTextSize < TAG then c.MinTextSize = math.min(want, c.MaxTextSize) end
		return
	end
	c = Instance.new("UITextSizeConstraint")
	c.Name = "TextFloor"
	c.MinTextSize = want
	c.Parent = o
end
M.floor = floor

function M.start(E)
	local pg = E.plr:WaitForChild("PlayerGui")
	task.delay(2, function() -- after the HUD has laid itself out, so a compact tag reads as one
		for _, d in pg:GetDescendants() do floor(d) end
	end)
	pg.DescendantAdded:Connect(function(d)
		if d:IsA("TextLabel") or d:IsA("TextButton") then task.delay(0.1, function() if d.Parent then floor(d) end end) end
	end)
end

return M
