-- RetentionTimers (ReplicatedStorage.Shared.RetentionTimers), started by PixelClient. Directive v9 (2026-11-13, section 5B):
-- two jelly pills at the top centre of the HUD, so there is always a timer about to finish.
--   * the gift pill: NEXT GIFT 04:12, counting the minutes played today toward the next playtime gift (C.GIFTS); when one is
--     due it turns gold and pulses: GIFT READY, press Y or click it. The server keeps the count and pays (ServerScriptService.Retention).
--   * the event pill: the event that is on, with the time it has left, or the next one to start with its countdown: the
--     Golden Vein Surge, the Kiln Surge, the spore storm, the Roots Stirring (the server's clocks, workspace attributes).
-- Both step aside while a boss bar is up. Display and one remote call; nothing is decided here.
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local M = {}

function M.start(E)
	local C, R, gui = E.C, E.R, E.gui
	local GiftR = R:WaitForChild("Gift", 10)
	if not GiftR or not C.GIFTS then return end
	local GOLD, CYAN, WHITE = Color3.fromRGB(255, 214, 107), Color3.fromRGB(0, 240, 255), Color3.new(1, 1, 1)
	-- Directive v10 (2026-11-14: "merge the top timers into one expandable pill"): ONE pill at the top centre shows the most
	-- urgent line (a gift to take, an event that is on, a refinery that is done, else whatever comes soonest). Pointing at it
	-- or clicking it drops down every line: Gift (click it to claim), Event, Refine.
	local holder = E.new("Frame", gui, { Name = "Timers", Size = E.S(210, 36), Position = E.S(606, 34), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, ZIndex = 3 }) -- 4 px lower: it sat tight under the Roblox top bar (Gemini full1119k)
	local function pill(parent, name, size, pos, kind)
		local p = E.panel(parent, size, pos, Vector2.new(0.5, 0.5), kind)
		p.Name = name
		local t = E.text(p, "", UDim2.fromScale(0.86, 0.5), UDim2.fromScale(0.5, 0.46), Vector2.new(0.5, 0.5), WHITE, 700, false)
		t.Name, t.Font = "Line", E.HEAD or t.Font -- the headline font: Shared.JellyHUD turns it into jelly letters
		return p, t
	end
	local mainP, mainT = pill(holder, "Main", UDim2.fromScale(1, 1), UDim2.fromScale(0.5, 0.5), "pillLilac")
	local mainHit = E.new("TextButton", mainP, { Name = "Open", Text = "", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 5 })
	local drop = E.new("Frame", holder, { Name = "Drop", Size = UDim2.fromScale(1, 3.3), Position = UDim2.fromScale(0.5, 1.12), AnchorPoint = Vector2.new(0.5, 0), BackgroundTransparency = 1, Visible = false, ZIndex = 8 })
	local giftP, giftT = pill(drop, "Gift", UDim2.fromScale(1, 0.3), UDim2.fromScale(0.5, 0.16), "pillButter")
	local eventP, eventT = pill(drop, "Event", UDim2.fromScale(1, 0.3), UDim2.fromScale(0.5, 0.5), "pillLilac")
	local refP, refT = pill(drop, "Refine", UDim2.fromScale(1, 0.3), UDim2.fromScale(0.5, 0.84), "pillLilac")
	E.new("UIListLayout", drop, { FillDirection = Enum.FillDirection.Vertical, HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0.04, 0), SortOrder = Enum.SortOrder.LayoutOrder })
	giftP.LayoutOrder, eventP.LayoutOrder, refP.LayoutOrder = 1, 2, 3
	local pinned = false
	mainHit.Activated:Connect(function()
		pinned = not pinned
		E.sfx("click", 1.1)
	end)
	local hit = E.new("TextButton", giftP, { Name = "Claim", Text = "", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 5 })
	local pulse = E.new("UIScale", mainP, { Name = "Pulse" })

	local got, secs0, at0 = 0, 0, os.clock() -- gifts taken, seconds played when the server last said so
	local function clock(s)
		s = math.max(0, math.floor(s + 0.5))
		return string.format("%02d:%02d", s // 60, s % 60)
	end
	local function claim()
		local g = C.GIFTS[got + 1]
		if g and secs0 + (os.clock() - at0) >= g[1] then GiftR:FireServer("claim") end
	end
	hit.Activated:Connect(claim)
	UIS.InputBegan:Connect(function(io, gp) if not gp and io.KeyCode == Enum.KeyCode.Y then claim() end end)

	local NAMES = { coins = "COINS", gems = "GEMS", egg = "EGG", flares = "FLARES" }
	R.Fx.OnClientEvent:Connect(function(kind, a, b, c)
		if kind == "gift" then
			got, secs0, at0 = a, b, os.clock()
		elseif kind == "giftPaid" then
			E.toast("PLAYTIME GIFT:  +" .. b .. " " .. (NAMES[a] or string.upper(tostring(a))), GOLD, true)
			E.sfx("upgrade", 1.1)
			if E.fly and a == "coins" and E.goldPill then
				local c = giftP.AbsolutePosition + giftP.AbsoluteSize / 2
				E.fly("coin", UDim2.fromOffset(c.X, c.Y), E.goldPill, 6, 0.05)
			end
		elseif kind == "refine" then -- the Surface Refinery's answers
			if a == "start" then E.toast("GEODE IN THE REFINERY:  DONE IN " .. clock(b), GOLD, true) E.sfx("open", 0.7)
			elseif a == "wait" then E.toast("THE REFINERY NEEDS " .. clock(b) .. " MORE", WHITE)
			elseif a == "paid" then E.toast("REFINED!  +" .. tostring(b) .. " GEMS  +" .. tostring(c) .. " COINS", GOLD, true) E.sfx("upgrade", 1.2)
			elseif a == "none" then E.toast("NO GEODE TO REFINE.  JARS IN THE CLAY CAVES HOLD THEM", WHITE) end
		elseif kind == "crystalRift" then -- a tall violet crystal of light stands over the kiln while the rift is open
			E.toast("CRYSTAL RIFT IN THE CLAY CAVES!  ORE THERE IS WORTH " .. C.EVENTS.riftValue .. "X", Color3.fromRGB(200, 140, 255), true)
			E.sfx("upgrade", 0.6)
			local old = workspace:FindFirstChild("CrystalRiftFX")
			if old then old:Destroy() end
			local f = Instance.new("Model")
			f.Name = "CrystalRiftFX"
			local at = CFrame.new(C.CAVE2_ORIGIN + Vector3.new(6, 30, -12))
			for i = 1, 3 do
				local p = Instance.new("Part")
				p.Size, p.CFrame, p.Anchored = Vector3.new(5 - i, 34 - i * 6, 5 - i), at * CFrame.Angles(0.12 * i, i * 1.1, 0.1 * i), true
				p.Color, p.Material, p.Transparency = Color3.fromRGB(190, 130, 255), i == 3 and Enum.Material.Neon or Enum.Material.Glass, i == 3 and 0.2 or 0.45
				p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = false, false, false, false
				p.Parent = f
				if i == 3 then
					local l = Instance.new("PointLight")
					l.Color, l.Range, l.Brightness, l.Shadows = Color3.fromRGB(200, 140, 255), 60, 1.4, false
					l.Parent = p
				end
			end
			f.Parent = workspace
			task.delay(a, function() if f.Parent then f:Destroy() end end)
		elseif kind == "goldSurge" then
			E.toast("GOLDEN VEIN SURGE!  THE GOLD ZONE IS TWICE AS WIDE", GOLD, true)
			E.sfx("upgrade", 0.8)
		end
	end)

	local EVENTS = { -- name, attribute with the end time while it is on, attribute with its next start
		{ "CRYSTAL RIFT", "CrystalRift", "RiftAt" }, { "GOLD SURGE", "GoldSurge", "GoldSurgeAt" }, { "KILN SURGE", "KilnSurge", "KilnSurgeAt" }, { "SPORE STORM", "SporeStorm", "SporeAt" }, { "ROOTS STIR", nil, "RootsStirAt" },
	}
	local acc = 1
	RunService.Heartbeat:Connect(function(dt)
		acc += dt
		if acc < 0.25 then return end
		acc = 0
		local boss = gui:FindFirstChild("BossBar", true)
		local chest = E.plr.PlayerGui:FindFirstChild("DailyChest")
		holder.Visible = not (boss and boss.Visible) and not (chest and chest.Enabled) and not (E.vmHook and (E.vmHook.arOpen or E.vmHook.modalOpen)) and not (E.isBusy and E.isBusy()) -- a minigame owns the top (it hid the Vein Rush quality bar, 2026-11-17); a reward chest has the top of the screen to itself
		if not holder.Visible then return end
		do -- open while the pointer is on the pill or its list, or while it is pinned by a click
			local m = game:GetService("UserInputService"):GetMouseLocation() - game:GetService("GuiService"):GetGuiInset()
			local p, s = holder.AbsolutePosition, holder.AbsoluteSize
			local over = game:GetService("UserInputService").MouseEnabled and m.X >= p.X and m.X <= p.X + s.X and m.Y >= p.Y and m.Y <= p.Y + s.Y * (drop.Visible and 4.5 or 1)
			drop.Visible = pinned or over
		end
		local g = C.GIFTS[got + 1]
		local played = secs0 + (os.clock() - at0)
		local giftIn = math.huge -- seconds to the next gift (0 = one waits)
		if not g then
			giftT.Text, giftT.TextColor3, pulse.Scale = "ALL GIFTS TAKEN TODAY", WHITE, 1
		elseif played >= g[1] then
			giftT.Text, giftT.TextColor3 = "GIFT READY!  PRESS Y", GOLD
			pulse.Scale = 1 + math.abs(math.sin(os.clock() * 4)) * 0.06
			giftIn = 0
		else
			giftT.Text, giftT.TextColor3, pulse.Scale = "NEXT GIFT  " .. clock(g[1] - played), WHITE, 1
			giftIn = g[1] - played
		end
		local now = workspace:GetServerTimeNow()
		local line, col, soon = nil, WHITE, math.huge
		for _, e in EVENTS do
			local ends = e[2] and workspace:GetAttribute(e[2])
			if ends and ends > now then
				line, col, soon = e[1] .. " ON  " .. clock(ends - now), (e[1] == "GOLD SURGE" and GOLD) or (e[1] == "CRYSTAL RIFT" and Color3.fromRGB(214, 160, 255)) or CYAN, -1
				break
			end
			local nextAt = workspace:GetAttribute(e[3])
			if nextAt and nextAt > now and nextAt - now < soon then
				soon, line = nextAt - now, e[1] .. " IN  " .. clock(nextAt - now)
			end
		end
		local refAt = E.plr:GetAttribute("RefineAt") -- the refinery: its own line when nothing else is on, and on the furnace's sign
		local sign = workspace:FindFirstChild("Hub") and workspace.Hub:FindFirstChild("RefinerySign")
		local signT = sign and sign:FindFirstChild("RefineryGui") and sign.RefineryGui:FindFirstChild("Line")
		if signT then signT.Text = refAt and (refAt <= now and "READY!" or clock(refAt - now)) or "REFINERY" end
		refP.Visible = refAt ~= nil
		if refAt then refT.Text, refT.TextColor3 = refAt <= now and "REFINERY READY!" or ("REFINERY IN  " .. clock(refAt - now)), refAt <= now and GOLD or WHITE end
		eventP.Visible = line ~= nil
		if line then eventT.Text, eventT.TextColor3 = line, col end
		-- the one pill: what wants the player now, else what comes soonest
		local below = E.plr:GetAttribute("InCave") == true -- in the caves the cave events lead the pill; a waiting gift is not shouted over the boss and the chimes (Gemini full1119e)
		if giftIn == 0 and not below then mainT.Text, mainT.TextColor3 = giftT.Text, GOLD -- below ground the gift waits in the list (Gemini full1119j): the cave pill is for cave events
		elseif line and soon == -1 then mainT.Text, mainT.TextColor3 = line, col
		elseif refAt and refAt <= now and not below then mainT.Text, mainT.TextColor3 = refT.Text, GOLD -- the refinery is in town: below, its line waits in the list
		elseif line and soon < giftIn and not (refAt and refAt - now < soon) then mainT.Text, mainT.TextColor3 = line, col
		elseif refAt and refAt - now < giftIn and not (below and refAt <= now) then mainT.Text, mainT.TextColor3 = refT.Text, WHITE
		elseif below and line then mainT.Text, mainT.TextColor3 = line, col
		else mainT.Text, mainT.TextColor3 = giftT.Text, WHITE end
		-- the list shows the OTHER lines: the one on the pill is not said twice (Gemini, 2026-11-14)
		giftP.Visible = giftT.Text ~= mainT.Text
		eventP.Visible = line ~= nil and line ~= mainT.Text
		refP.Visible = refAt ~= nil and refT.Text ~= mainT.Text
	end)
end

return M
