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
			JellyText.mirror(d, { color = kind == "ribbonPink" and Color3.fromRGB(255, 120, 185) or Color3.fromRGB(176, 140, 255), popOnChange = true }) -- deeper than the pale ribbon glass so the word stands out
		end
	end
	for _, root in { gui, pg:FindFirstChild("DailyChest") } do
		for _, d in root:GetDescendants() do adopt(d) end
		root.DescendantAdded:Connect(function(d) task.defer(adopt, d) end)
	end
	local shout = E.caveHud:FindFirstChild("PerfectStrike")
	for _, d in shout and shout:GetChildren() or {} do
		if d:IsA("TextLabel") then JellyText.mirror(d, { color = Color3.fromRGB(255, 226, 130), glow = true, popOnChange = true }) end
	end
end

return M
