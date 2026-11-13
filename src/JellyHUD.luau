-- JellyHUD (ReplicatedStorage.Shared.JellyHUD), started by PixelClient with the cut-glass kit. The user, 2026-11-12: "implement
-- as much of this quality of text in UI, HUD, ingame". It turns the HUD's headline words into jelly glass letters
-- (Shared.JellyText.mirror keeps each one in step with its TextLabel, so no game logic changes):
--   * the coin and gem counts
--   * every ribbon title (panel headers, NEXT UP, the daily chest's day)
--   * the minigame shout (PERFECT!)
-- Small labels and sentences stay plain text: jelly letters need size to read.
local M = {}

function M.start(E)
	if not E.GLASS then return end
	local JellyText = require(script.Parent:WaitForChild("JellyText"))
	local gui, pg = E.gui, E.plr:WaitForChild("PlayerGui")
	local function firstLabel(o) return o and o:FindFirstChildWhichIsA("TextLabel") end
	local gold = firstLabel(E.goldPill)
	if gold then JellyText.mirror(gold, { color = Color3.fromRGB(255, 226, 130), sway = false }) end
	local gem = firstLabel(gui:FindFirstChild("GemPill", true))
	if gem then JellyText.mirror(gem, { sway = false }) end
	local function adopt(d)
		if not d:IsA("TextLabel") then return end
		local kind = d.Parent and d.Parent:GetAttribute("Kind")
		if (kind == "ribbonPink" or kind == "ribbonLilac") and d.AbsoluteSize.Y >= 0 then
			JellyText.mirror(d, { popOnChange = true }) -- the pink jelly: on the pale lilac ribbon the violet one had too little contrast -- deeper than the pale ribbon glass so the word stands out
		end
	end
	for _, root in { gui, pg:FindFirstChild("DailyChest") } do
		for _, d in root:GetDescendants() do adopt(d) end
		root.DescendantAdded:Connect(function(d) task.defer(adopt, d) end)
	end
	-- Jelly everywhere (the user, 2026-11-12): every headline label in any of the player's guis becomes jelly by itself. A
	-- headline is a TextLabel in one of the headline fonts (the kit's HEAD font; Bangers and Fredoka One in the older ride
	-- and cutscene screens), at least 18 pixels tall, saying at most 26 characters. Dark ink text becomes violet jelly,
	-- which reads on the milky glass; any other colour is kept. Sentences, tiny captions and key caps stay plain.
	local HEADS = { [E.HEAD] = true, [Enum.Font.Bangers] = true, [Enum.Font.FredokaOne] = true }
	local VIOLET = Color3.fromRGB(156, 118, 255)
	local function auto(d)
		if not d:IsA("TextLabel") or not HEADS[d.Font] or d:FindFirstChild("Jelly") or d.MaxVisibleGraphemes == 0 then return end
		if d:FindFirstAncestor("PixelLoading") or d:FindFirstAncestor("KeyHint") then return end
		if d.AbsoluteSize.Y < 18 or d.AbsoluteSize.X < 18 then return end
		local c = d.TextColor3
		local dark = c.R * 0.3 + c.G * 0.59 + c.B * 0.11 < 0.42
		local kind = d.Name == "Label" and d.Parent and d.Parent:GetAttribute("Kind") -- a kit button's own label
		if kind == "butter" or kind == "off" or kind == "lilac" then dark = true end -- white jelly washed out on the pale buttons (STRIKE! on butter): violet there
		JellyText.mirror(d, { color = dark and VIOLET or c, followColor = not dark, sway = false, maxLen = 26 })
	end
	local function later(d) -- fonts and sizes are often set a moment after a label is made
		if d:IsA("TextLabel") then task.delay(0.25, function() if d.Parent then auto(d) end end) end
	end
	for _, d in pg:GetDescendants() do later(d) end
	pg.DescendantAdded:Connect(later)
	-- in the world too: the wooden sign boards of the town and the camps (parts named Sign, built by HubBuilder and CaveBuilder)
	-- carry their words in gold jelly
	local function sign(d)
		if d:IsA("TextLabel") and d.Name == "Label" and d.Parent and d.Parent:IsA("SurfaceGui") and d.Parent.Parent and d.Parent.Parent.Name == "Sign" then
			local t = JellyText.mirror(d, { color = Color3.fromRGB(255, 205, 80), sway = false, maxLen = 20 })
			if t then -- the board's old pixel letters are pictures inside the label: they go while the jelly shows
				local function hide(c) if c:IsA("GuiObject") and c ~= t.frame then c.Visible = not t.frame.Visible end end
				for _, c in d:GetChildren() do hide(c) end
				d.ChildAdded:Connect(hide)
				t.frame:GetPropertyChangedSignal("Visible"):Connect(function() for _, c in d:GetChildren() do hide(c) end end)
			end
		end
	end
	for _, d in workspace:GetDescendants() do sign(d) end
	workspace.DescendantAdded:Connect(function(d) if d:IsA("TextLabel") then task.defer(sign, d) end end) -- class first: the caves and the rides add thousands of parts
	local shout = E.caveHud:FindFirstChild("PerfectStrike")
	for _, d in shout and shout:GetChildren() or {} do
		if d:IsA("TextLabel") then JellyText.mirror(d, { color = Color3.fromRGB(255, 226, 130), glow = true, popOnChange = true }) end
	end
end

return M
