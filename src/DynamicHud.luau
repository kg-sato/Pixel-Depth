-- DynamicHud (ReplicatedStorage.Shared.DynamicHud): the "Dynamic HUD" setting (Shared.ARSettings, saved as opts.hudDynamic;
-- directive v13 phase 1, vault Research/UI/Non-Distracting HUD and Feature Inspirations (2026-11-20)).
-- When it is on and nothing needs the player (torch above 45%, calm, bag not full, no prompt in reach, no recent menu key,
-- tap or change of coins, ore or HP), the quiet chrome slides off the screen edges like Dredge and Subnautica (more than 92%
-- of the view open): the left column (coins, upgrade tracker, menu) to the left, the survival orbs and the hotbar down, the
-- event timers up. Danger (fear >= 0.25, fuel < 0.45, a full bag), a prompt, a menu key, a tap in the top-left corner, the
-- mouse at the left edge or a change slides it back softly. Off (Standard): nothing moves.
-- Only Position.Scale on one axis changes; each widget's own code still owns Visible and the other axis.
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local PPS = game:GetService("ProximityPromptService")
local M = {}

local MOVE = { -- keys that only walk, jump, mine or use: they never wake the HUD
	[Enum.KeyCode.W] = true, [Enum.KeyCode.A] = true, [Enum.KeyCode.S] = true, [Enum.KeyCode.D] = true,
	[Enum.KeyCode.Up] = true, [Enum.KeyCode.Down] = true, [Enum.KeyCode.Left] = true, [Enum.KeyCode.Right] = true,
	[Enum.KeyCode.Space] = true, [Enum.KeyCode.LeftShift] = true, [Enum.KeyCode.RightShift] = true, [Enum.KeyCode.E] = true,
	[Enum.KeyCode.F] = true, [Enum.KeyCode.LeftControl] = true,
}

function M.start(E)
	local plr, gui = E.plr, E.gui
	local T = { -- name, finder, axis, how far it slides (scale of the screen)
		{ "LeftColumn", function() return gui:FindFirstChild("LeftColumn") end, "X", -0.36 },
		{ "Timers", function() return gui:FindFirstChild("Timers") end, "Y", -0.16 },
		{ "Survival", function() return E.caveHud and E.caveHud:FindFirstChild("Survival") end, "Y", 0.36 },
		{ "Hotbar", function() return E.caveHud and E.caveHud:FindFirstChild("Hotbar") end, "Y", 0.3 },
	}
	local base, cur = {}, 0 -- cur: 0 in place .. 1 tucked away
	local wakeUntil = os.clock() + 6
	local prompts = 0
	PPS.PromptShown:Connect(function() prompts += 1 end)
	PPS.PromptHidden:Connect(function() prompts = math.max(0, prompts - 1) end)
	local function wake(t) wakeUntil = math.max(wakeUntil, os.clock() + (t or 4)) end
	M.wake = wake
	UIS.InputBegan:Connect(function(io)
		local t = io.UserInputType
		if t == Enum.UserInputType.Keyboard then
			if not MOVE[io.KeyCode] then wake(5) end
		elseif t == Enum.UserInputType.Touch then -- a tap in the top-left corner calls the column back (the thumbstick lives bottom left)
			local v = gui.AbsoluteSize
			if io.Position.X < v.X * 0.3 and io.Position.Y < v.Y * 0.55 then wake(6) end
		elseif t == Enum.UserInputType.Gamepad1 and io.KeyCode ~= Enum.KeyCode.Thumbstick1 and io.KeyCode ~= Enum.KeyCode.Thumbstick2 and io.KeyCode ~= Enum.KeyCode.ButtonA then
			wake(5)
		end
	end)
	local mouseAt = -10 -- the mouse counts at the left edge only while it is really moving there (a parked or absent cursor reads 0,0)
	UIS.InputChanged:Connect(function(io) if io.UserInputType == Enum.UserInputType.MouseMovement then mouseAt = os.clock() end end)
	for _, a in { "HP", "Flares", "InCave" } do plr:GetAttributeChangedSignal(a):Connect(function() wake(4) end) end
	plr:GetAttributeChangedSignal("HudDynamic"):Connect(function() wake(3) end)
	local lastGold, lastBag
	RunService.Heartbeat:Connect(function(dt)
		local on = plr:GetAttribute("HudDynamic") == true
		local st = E.getState and E.getState()
		if st then
			if lastGold ~= nil and (st.gold ~= lastGold or st.bag ~= lastBag) then wake(5) end
			lastGold, lastBag = st.gold, st.bag
		end
		local cave = E.cave
		local inCave = plr:GetAttribute("InCave") == true
		local danger = inCave and cave ~= nil and ((cave.fear or 0) >= 0.25 or (cave.fuel or 1) < 0.45)
		local full = st ~= nil and st.cap ~= nil and st.bag ~= nil and st.bag >= st.cap
		local edge = UIS.MouseEnabled and os.clock() - mouseAt < 1.5 and UIS.MouseBehavior == Enum.MouseBehavior.Default and UIS:GetMouseLocation().X < gui.AbsoluteSize.X * 0.14
		local promptUp = prompts > 0
		if not promptUp then -- the client draws its own prompt bubbles (PixelClient, "PromptUI"): one on screen means a thing is in reach
			for _, c in gui:GetChildren() do
				if c.Name == "PromptUI" and c:IsA("GuiObject") and c.Visible then promptUp = true break end
			end
		end
		local calm = on and not danger and not full and not promptUp and not edge and os.clock() > wakeUntil
		local goal = calm and 1 or 0
		if goal == 0 and cur == 0 then -- in place: follow the widgets' own positions, write nothing
			for _, t in T do
				local o = t[2]()
				if o then base[t[1]] = { o = o, p = o.Position } end
			end
			return
		end
		local rate = goal > cur and 1 / 0.7 or 1 / 0.28 -- away slowly, back quickly
		cur = math.clamp(cur + math.clamp(goal - cur, -rate * dt, rate * dt), 0, 1)
		local e = cur * cur * (3 - 2 * cur)
		for _, t in T do
			local o = t[2]()
			local b = o and base[t[1]]
			if o and (not b or b.o ~= o) then
				b = { o = o, p = o.Position }
				base[t[1]] = b
			end
			if o then
				local p = o.Position
				local want = t[3] == "X" and UDim2.new(b.p.X.Scale + t[4] * e, p.X.Offset, p.Y.Scale, p.Y.Offset)
					or UDim2.new(p.X.Scale, p.X.Offset, b.p.Y.Scale + t[4] * e, p.Y.Offset)
				if want ~= p then o.Position = want end
			end
		end
	end)
end

return M
