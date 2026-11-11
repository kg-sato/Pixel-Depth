-- ToastManager (ReplicatedStorage.Shared.ToastManager), started by PixelClient (the user's overnight directive, 2026-11-10:
-- quests, prompts, lore lines and reward toasts wrote over each other). Every toast and lore line goes through this one
-- queue: one line on screen at a time, in one lane, and none while a minigame, a ride or a full-screen panel is up
-- (E.hold() is true): those lines wait and show afterwards. A line that is already showing or waiting is not added twice.
local M = {}
local LANE, MAX = 0.74, 6 -- the lane sits under the loot card (ends at 0.62) and over the bottom buttons
local queue, live, E, gap = {}, nil, nil, 0

function M.show(msg, color, big, delay)
	if delay and delay > 0 then task.delay(delay, M.show, msg, color, big) return end
	if live and live.msg == msg then return end
	for _, t in queue do if t.msg == msg then return end end
	if #queue >= MAX then table.remove(queue, 1) end -- a flood drops its oldest line
	table.insert(queue, { msg = msg, color = color, big = big })
end

function M.count() return #queue + (live and 1 or 0) end

function M.start(e)
	E = e
	game:GetService("RunService").Heartbeat:Connect(function(dt)
		local ok, hold = pcall(E.hold) -- a hold check that throws must not freeze a line on screen
		if not ok then hold = false end
		if live then
			live.label.Visible = not hold
			if not hold then live.seen += dt end
			if hold then live.t += dt return end -- a held line keeps its remaining time
			if os.clock() < live.t - (#queue > 0 and 1.2 or 0) and live.seen < 4 then return end -- a waiting line shortens the one on screen
			local l = live.label
			live = nil
			E.tween(l, 0.3, { BackgroundTransparency = 1, Position = UDim2.fromScale(0.5, LANE - 0.05) })
			for _, w in l:GetChildren() do if w:IsA("TextLabel") then E.tween(w, 0.3, { TextTransparency = 1, TextStrokeTransparency = 1 }) end end
			task.delay(0.32, function() l:Destroy() end)
			gap = os.clock() + 0.34 -- the next line waits until this one is gone
			return
		end
		local t = not hold and os.clock() >= gap and table.remove(queue, 1)
		if not t then return end
		E.sfx("pop", t.big and 0.9 or 1.1)
		-- a dark pill behind the words: bare text lay across the first-person hands (Gemini, 2026-11-10)
		local l = Instance.new("Frame")
		l.Name, l.ZIndex, l.AnchorPoint, l.BorderSizePixel = "Toast", 20, Vector2.new(0.5, 0.5), 0
		l.Size, l.Position = UDim2.fromScale(math.clamp(0.07 + #t.msg * (t.big and 0.0066 or 0.0054), 0.16, 0.5), t.big and 0.07 or 0.058), UDim2.fromScale(0.5, LANE + 0.06) -- as wide as its words need, never a bar across the screen
		l.BackgroundColor3, l.BackgroundTransparency = Color3.fromRGB(38, 28, 54), 0.22
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0.5, 0)
		corner.Parent = l
		local words = E.text(l, t.msg, UDim2.fromScale(0.92, 0.62), UDim2.fromScale(0.5, 0.5), Vector2.new(0.5, 0.5), t.color, 700)
		words.ZIndex = 21
		l.Parent = E.gui
		E.tween(l, 0.35, { Position = UDim2.fromScale(0.5, LANE) }, Enum.EasingStyle.Back)
		E.pop(l, 0.6, 0.35)
		live = { msg = t.msg, label = l, t = os.clock() + 2.5, seen = 0 }
	end)
end

return M
