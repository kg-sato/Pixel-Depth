-- ToastManager (ReplicatedStorage.Shared.ToastManager), started by PixelClient (the user's overnight directive, 2026-11-10:
-- quests, prompts, lore lines and reward toasts wrote over each other). Every toast and lore line goes through this one
-- queue: one line on screen at a time, in one lane, and none while a minigame, a ride or a full-screen panel is up
-- (E.hold() is true): those lines wait and show afterwards. A line that is already showing or waiting is not added twice.
local GLASS = require(script.Parent:WaitForChild("Config")).UI_KIT == "glass"
local JellyText = GLASS and require(script.Parent:WaitForChild("JellyText"))
local M = {}
local LANE, MAX = 0.72, 6 -- the lane sits under the loot card (ends at 0.62) and above the hotbar (audit 2026-11-26 UI 9: was 0.69)
local Players = game:GetService("Players")
local found = {} -- name -> the GuiObject, found once (lane() runs every frame while a line is up)
local function shown(name)
	local g = found[name]
	if not (g and g.Parent) then
		local pg = Players.LocalPlayer and Players.LocalPlayer:FindFirstChild("PlayerGui")
		g = pg and pg:FindFirstChild(name, true)
		found[name] = g
	end
	return g ~= nil and g:IsA("GuiObject") and g.Visible
end
local function lane() -- in a boss fight the notices sit under the boss bar, off the fighting floor (Gemini v10n_r9: "floating across the combat space")
	-- 0.6, between the Warden's head and the dial in the lower third (tour full1125b: at 0.34 KNOT CRACKED covered the head) -- under the boss bar and its pips (at 0.25 it sat on the pips, full1119o)
	-- the RETURN TO CAMP ribbon spans 0.67-0.74, right on the lane: the same upper lane while it is up (wheel_test 2026-11-27)
	return (shown("BossBar") or shown("RootsRibbon")) and 0.6 or LANE
end
local queue, live, E, gap = {}, nil, nil, 0
local function wheelOpen() -- audit 2026-11-26 UI 1: a tip toast cut across the tool wheel's QUESTS and BAG slots
	local pg = Players.LocalPlayer and Players.LocalPlayer:FindFirstChild("PlayerGui")
	local w = pg and pg:FindFirstChild("UtilityWheel", true)
	return w ~= nil and w:IsA("GuiObject") and w.Visible and w.AbsoluteSize.X > 4
end
local function bossOn() return Players.LocalPlayer ~= nil and Players.LocalPlayer:GetAttribute("BossFight") == true end

function M.show(msg, color, big, delay)
	if delay and delay > 0 then task.delay(delay, M.show, msg, color, big) return end
	if live and live.msg == msg then return end
	for _, t in queue do if t.msg == msg then return end end
	if #queue >= MAX then table.remove(queue, 1) end -- a flood drops its oldest line
	table.insert(queue, { msg = msg, color = color, big = big })
end

function M.count() return #queue + (live and 1 or 0) end
-- one banner at a time across the screen top (Master Directive v16 4.1): the arrival banner and the hatch marquee claim the
-- banner lane for their hold; toasts wait while it is claimed, and a claimer waits while a toast is up
local claimUntil = 0
function M.claim(sec) claimUntil = math.max(claimUntil, os.clock() + sec) end
function M.free() return os.clock() >= claimUntil and live == nil and os.clock() >= gap end
function M.claimed() return os.clock() < claimUntil end -- a banner holds the centre: prompt bubbles step back (v16.1, audit 9:58)
function M.busy() return live ~= nil or #queue > 0 or os.clock() < claimUntil end -- anything on or waiting for the banner lane

function M.start(e)
	E = e
	game:GetService("RunService").Heartbeat:Connect(function(dt)
		local ok, hold = pcall(E.hold) -- a hold check that throws must not freeze a line on screen
		if not ok then hold = false end
		hold = hold or wheelOpen()
		if bossOn() then -- audit 2026-11-26 UI 9: ORE BANK lay across the Root Warden's chest and SAFE AT CAMP floated in the boss room
			for i = #queue, 1, -1 do
				local m = string.upper(queue[i].msg)
				if m:find("ORE BANK") or m:find("SAFE AT CAMP") or m:find("CAMP IS SAFE") then table.remove(queue, i) end
			end
		end
		if live then
			live.label.Visible = not hold
			local ln = lane()
			if live.lane ~= ln then live.lane = ln E.tween(live.label, 0.25, { Position = UDim2.fromScale(0.5, ln) }) end -- the roots ribbon or the boss bar came up under a line already on screen
			if not hold then live.seen += dt end
			if hold then live.t += dt return end -- a held line keeps its remaining time
			if os.clock() < live.t - (#queue > 0 and 1.2 or 0) and live.seen < 4 then return end -- a waiting line shortens the one on screen
			local l = live.label
			live = nil
			E.tween(l, 0.3, { GroupTransparency = 1, Position = UDim2.fromScale(0.5, lane() - 0.05) })
			local edge = l:FindFirstChildOfClass("UIStroke") -- a CanvasGroup's own stroke is drawn outside the group: it stayed as an empty ring (Gemini full1122e 28-32 s)
			if edge then E.tween(edge, 0.3, { Transparency = 1 }) end
			for _, w in l:GetChildren() do if w:IsA("TextLabel") then E.tween(w, 0.3, { TextTransparency = 1, TextStrokeTransparency = 1 }) end end
			task.delay(0.32, function() l:Destroy() end)
			gap = os.clock() + 0.34 -- the next line waits until this one is gone
			return
		end
		if hold or os.clock() < gap or os.clock() < claimUntil or #queue == 0 then return end
		local fight = shown("BossBar") or bossOn() -- a boss fight: only its own lines show now; the rest (quests, torch, gifts) wait for the end (Gemini full1119h)
		local pick = 1
		if fight then
			pick = nil
			for i, q in queue do
				local m = string.upper(q.msg)
				if m:find("WARDEN") or m:find("GOLEM") or m:find("KNOT") or m:find("VENT") or m:find("JUMP") or m:find("DODGE") or m:find("FLARE") or m:find("GRAB") or m:find("CHEST") then pick = i break end
			end
			if not pick then return end
		end
		local t = table.remove(queue, pick)
		if lane() ~= LANE then t.big = false end -- in a boss fight every notice is the small pill: a big one covered the boss (Gemini views_full1122e 06)
		E.sfx("pop", t.big and 0.9 or 1.1)
		-- a dark pill behind the words: bare text lay across the first-person hands (Gemini, 2026-11-10)
		local l = Instance.new("CanvasGroup") -- directive v14: one group fades as a whole (jelly glyphs are images and did not fade)
		l.Name, l.ZIndex, l.AnchorPoint, l.BorderSizePixel = "Toast", 20, Vector2.new(0.5, 0.5), 0
		l.Size, l.Position = UDim2.fromScale(math.clamp(0.07 + #t.msg * (t.big and 0.0066 or 0.0054), 0.16, 0.5), t.big and 0.07 or 0.058), UDim2.fromScale(0.5, lane() + 0.06) -- as wide as its words need, never a bar across the screen
		l.BackgroundColor3, l.BackgroundTransparency = Color3.fromRGB(38, 28, 54), 0.22
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0.5, 0)
		corner.Parent = l
		local words = E.text(l, t.msg, UDim2.fromScale(0.92, 0.62), UDim2.fromScale(0.5, 0.5), Vector2.new(0.5, 0.5), t.color, 700)
		words.ZIndex = 21
		if #t.msg > 26 then -- v15: a long line gets a taller, wider pill and a floor on its letter size (Orchestrator: KILN CAMP · ORE IS SAFE HERE squeezed onto one hairline)
			l.Size = UDim2.fromScale(math.clamp(0.08 + #t.msg * (t.big and 0.0088 or 0.0072), 0.2, 0.56), t.big and 0.088 or 0.072)
			words.Size = UDim2.fromScale(0.9, 0.66)
			local cap = Instance.new("UITextSizeConstraint")
			cap.MinTextSize, cap.MaxTextSize = 15, 40
			cap.Parent = words
		end
		if GLASS then -- cut-glass kit: a smoked glass pill with a light edge; a short line is spelled in jelly letters and lands with a wobble
			local edge = Instance.new("UIStroke")
			edge.Color, edge.Thickness, edge.Transparency = Color3.fromRGB(236, 226, 255), 1.5, 0.2
			edge.Parent = l
			l.BackgroundColor3, l.BackgroundTransparency = Color3.fromRGB(30, 21, 58), 0.14
			if #t.msg <= 26 then
				l.Size = UDim2.fromScale(math.clamp(0.1 + #t.msg * 0.0125, 0.18, 0.5), t.big and 0.1 or 0.082)
				words.Size = UDim2.fromScale(0.9, 0.7)
				local jt = JellyText.mirror(words, { color = (t.color or Color3.new(1, 1, 1)):Lerp(Color3.new(1, 1, 1), 0.25), glow = t.big, maxLen = 26 }) -- a toast may come without a colour (that crashed here and the line never showed: found by the touch test, 2026-11-13)
				local _ = jt -- no per-letter pop (directive v14): mid-stagger the line read "D" or "THE"
			end
		end
		l.Parent = E.gui
		E.tween(l, 0.35, { Position = UDim2.fromScale(0.5, lane()) }, Enum.EasingStyle.Back)
		E.pop(l, 0.86, 0.3) -- from 0.86, not 0.6: a deep shrink dropped the words under JellyText's 26 px fit and they swapped mid-pop
		live = { msg = t.msg, label = l, t = os.clock() + 2.5, seen = 0, lane = lane() }
	end)
end

return M
