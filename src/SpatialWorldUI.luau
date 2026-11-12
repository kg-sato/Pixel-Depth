-- SpatialWorldUI (ReplicatedStorage.Shared.SpatialWorldUI), started by PixelClient with the cut-glass kit.
-- Directive v8, anchor B (2026-11-12). References: Instagram Dd8V7dTJzF_ (@axavert, cards floating above chests and anvils,
-- lit by the world) and DeW6v1LKeC5 (floating world menus with pips); notes in the vault.
-- Walk up to a town station (a part with the attribute Station: forge, sell, hatch, map, chest) and a frosted glass card
-- unfurls in the world above it: a SurfaceGui on an unseen part, not always-on-top, so walls hide it, it keeps its
-- perspective, and lamps tint it (LightInfluence). It shows live numbers from the server's State message: what the next
-- pickaxe still needs, what is in the bag, what an egg costs. Display only: [F] still opens the station's full panel.
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local M = {}

local MID = Vector2.new(0.5, 0.5)
local NEAR, FAR = 17, 21 -- studs: opens inside NEAR, closes past FAR (no flicker on the edge)
local PPS = 40 -- pixels per stud
local W, H = 11, 5 -- card size in studs (the town camera is high and far: smaller cards were unreadable)
local SMOKE, EDGE, WHITE = Color3.fromRGB(30, 21, 58), Color3.fromRGB(236, 226, 255), Color3.new(1, 1, 1)
local GOLD, MINT, CORAL, CYAN = Color3.fromRGB(255, 206, 84), Color3.fromRGB(127, 232, 190), Color3.fromRGB(255, 140, 150), Color3.fromRGB(150, 232, 255)

function M.start(E)
	if not E.GLASS then return end
	local C, R, plr, commas = E.C, E.R, E.plr, E.commas
	local state = {}
	local function new(cls, parent, props)
		local o = Instance.new(cls)
		for k, v in props do o[k] = v end
		o.Parent = parent
		return o
	end
	local function label(parent, s, size, pos, color, font)
		return new("TextLabel", parent, { Text = s, Font = font or E.FONT, TextScaled = true, TextColor3 = color or WHITE, BackgroundTransparency = 1, Size = size, Position = pos, AnchorPoint = MID, ZIndex = 3 })
	end

	local TITLE = { forge = "BOLT'S FORGE", sell = "SELL ORE", hatch = "EGG STALL", map = "MINE MAP", chest = "DAILY CHEST" }
	-- each station's lines: returns { { text, colour }, ... } (two or three short lines) and whether the card should glow gold
	local LINES = {
		forge = function()
			local i = (state.pick or 1) + 1
			local nxt = C.PICKS[i]
			if not nxt then return { { "Every pickaxe is forged.", MINT } }, false end
			local got, want = 0, 0
			for k, n in C.PICK_ORE[i] or {} do
				got += math.min((state.ores and state.ores[k]) or 0, n)
				want += n
			end
			local coins = state.gold or 0
			local ready = got >= want and coins >= nxt.cost
			return {
				{ "NEXT: " .. string.upper(nxt.name), ready and GOLD or WHITE },
				{ (want > 0 and ("ORE " .. got .. "/" .. want .. "    ") or "") .. "COINS " .. commas(math.min(coins, nxt.cost)) .. "/" .. commas(nxt.cost), ready and MINT or CYAN },
				{ ready and "READY TO FORGE" or "Bank ore at camp, then come back.", ready and GOLD or EDGE },
			}, ready
		end,
		sell = function()
			local n = 0
			for _, v in state.bagOres or {} do n += v end
			return { { "BAG " .. (state.bag or n) .. "/" .. (state.cap or 10), WHITE }, { n > 0 and "Bolt buys your spare ore." or "Nothing to sell yet.", n > 0 and MINT or EDGE } }, false
		end,
		hatch = function()
			local eggs = state.eggs or 0
			return { { eggs > 0 and (eggs .. (eggs == 1 and " EGG TO HATCH" or " EGGS TO HATCH")) or "ROLL AN EGG", eggs > 0 and GOLD or WHITE }, { C.EGG_COINS .. " coins or " .. C.EGG_GEMS .. " gems a roll", CYAN } }, eggs > 0
		end,
		map = function() return { { "DEEPEST: " .. (state.deepest or 0) .. " m", WHITE }, { "See where each ore lives.", EDGE } }, false end,
		chest = function() return { { "One free chest a day.", WHITE }, { "Come back each day for a bigger one.", EDGE } }, false end,
	}

	local cards = {} -- station part -> card
	local function build(part, kind)
		local top = part.Position + Vector3.new(0, part.Size.Y / 2 + H / 2 + 1.5, 0)
		local board = new("Part", workspace.CurrentCamera, { Name = "SpatialCard", Size = Vector3.new(W, H, 0.05), CFrame = CFrame.new(top), Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false, Transparency = 1 })
		local sg = new("SurfaceGui", board, { Face = Enum.NormalId.Front, SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud, PixelsPerStud = PPS, AlwaysOnTop = false, LightInfluence = 0.15, Brightness = 2, ResetOnSpawn = false })
		local card = new("CanvasGroup", sg, { Size = UDim2.fromScale(1, 1), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = MID, BackgroundColor3 = SMOKE, BackgroundTransparency = 0.16, BorderSizePixel = 0, GroupTransparency = 1 })
		new("UICorner", card, { CornerRadius = UDim.new(0.1, 0) })
		local edge = new("UIStroke", card, { Color = EDGE, Thickness = 2, Transparency = 0.1 })
		new("UIGradient", card, { Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(170, 150, 220)) })
		local sheen = new("Frame", card, { Size = UDim2.fromScale(0.16, 1.6), Position = UDim2.fromScale(0.22, 0.5), AnchorPoint = MID, Rotation = 22, BackgroundColor3 = WHITE, BackgroundTransparency = 0.9, BorderSizePixel = 0, ZIndex = 1 })
		local bar = new("Frame", card, { Size = UDim2.fromScale(1, 0.27), BackgroundColor3 = Color3.fromRGB(86, 62, 160), BackgroundTransparency = 0.25, BorderSizePixel = 0, ZIndex = 2 })
		local holder = new("Frame", bar, { Size = UDim2.fromScale(0.9, 0.9), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = MID, BackgroundTransparency = 1, ZIndex = 3 })
		local title = require(script.Parent:WaitForChild("JellyText")).new(holder, TITLE[kind] or string.upper(kind), { color = Color3.new(1, 1, 1), z = 3 }) -- jelly glass letters
		new("Frame", card, { Size = UDim2.new(1, 0, 0, 2), Position = UDim2.fromScale(0, 0.27), BackgroundColor3 = EDGE, BackgroundTransparency = 0.3, BorderSizePixel = 0, ZIndex = 3 })
		local rows = {}
		for i = 1, 3 do rows[i] = label(card, "", UDim2.fromScale(0.9, 0.17), UDim2.fromScale(0.5, 0.27 + i * 0.2), WHITE, i == 1 and E.HEAD or E.FONT) end
		local sc = new("UIScale", card, { Scale = 0.6 })
		local c = { title = title, part = part, kind = kind, board = board, card = card, edge = edge, rows = rows, sc = sc, sheen = sheen, top = top, open = false }
		function c.fill()
			local lines, glow = LINES[kind]()
			local n = #lines
			for i, r in rows do
				local l = lines[i]
				r.Visible = l ~= nil
				if l then
					r.Text, r.TextColor3 = l[1], l[2]
					r.Position = UDim2.fromScale(0.5, 0.27 + (i - 0.5) * (0.73 / n)) -- two lines spread out, three sit closer
					r.Size = UDim2.fromScale(0.9, math.min(0.2, 0.5 / n))
				end
			end
			edge.Color = glow and GOLD or EDGE
		end
		return c
	end
	local function show(c, on)
		if c.open == on then return end
		c.open = on
		if on then
			c.fill()
			c.title.pop()
			c.sc.Scale = 0.6
			TweenService:Create(c.sc, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play() -- the unfurl, with a small overshoot
			TweenService:Create(c.card, TweenInfo.new(0.18), { GroupTransparency = 0 }):Play()
		else
			TweenService:Create(c.sc, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = 0.7 }):Play()
			TweenService:Create(c.card, TweenInfo.new(0.16), { GroupTransparency = 1 }):Play()
		end
	end

	local stations = {}
	local function adopt(p)
		local kind = p:IsA("BasePart") and p:GetAttribute("Station")
		if kind and LINES[kind] and not stations[p] then
			stations[p] = kind
			p.Destroying:Connect(function()
				stations[p] = nil
				if cards[p] then cards[p].board:Destroy(); cards[p] = nil end
			end)
		end
	end
	for _, d in workspace:GetDescendants() do adopt(d) end
	workspace.DescendantAdded:Connect(function(d) task.defer(adopt, d) end)

	R.State.OnClientEvent:Connect(function(s)
		state = s
		for _, c in cards do if c.open then c.fill() end end
	end)

	local acc = 0
	RunService.RenderStepped:Connect(function(dt)
		local h = E.hrp()
		local cam = workspace.CurrentCamera
		acc += dt
		local scan = acc > 0.2 -- who is near: five times a second is plenty
		if scan then acc = 0 end
		if scan and h then
			local chest = plr.PlayerGui:FindFirstChild("DailyChest")
			local hook = E.vmHook
			local busy = plr:GetAttribute("InCave") == true or E.isBusy() or (chest ~= nil and chest.Enabled) or hook.arOpen == true or (hook.noScrim ~= nil and hook.noScrim()) -- no station card behind a menu or the daily chest
			for p, kind in stations do
				local d = (p.Position - h.Position).Magnitude
				local c = cards[p]
				if not busy and d < NEAR then
					if not c then c = build(p, kind); cards[p] = c end
					show(c, true)
				elseif c and (busy or d > FAR) then
					show(c, false)
				end
			end
		end
		local now = os.clock()
		for _, c in cards do
			if c.open or c.card.GroupTransparency < 0.99 then
				local side = cam.CFrame.RightVector * Vector3.new(1, 0, 1)
				local pos = c.top + side.Unit * (W / 2 + 3.5) + Vector3.new(0, math.sin(now * 1.6 + c.top.X) * 0.12, 0) -- beside the station (its own prompt bubble sits over it), with a slow hover
				-- face against the camera's view direction (not toward its position: off-centre cards then look twisted), turning about the
				-- vertical axis and leaning back up to 55 degrees for the town's high camera; the card keeps its perspective
				local look = cam.CFrame.LookVector
				local flat = Vector3.new(-look.X, 0, -look.Z)
				if flat.Magnitude > 0.05 then
					local pitch = math.clamp(math.asin(math.clamp(-look.Y, -1, 1)), 0, math.rad(55))
					c.board.CFrame = CFrame.new(pos) * c.board.CFrame.Rotation:Lerp(CFrame.lookAt(Vector3.zero, flat.Unit * math.cos(pitch) + Vector3.yAxis * math.sin(pitch)), math.min(1, dt * 6))
				end
				c.sheen.Position = UDim2.fromScale(0.22 + 0.5 * (0.5 + 0.5 * math.sin(now * 0.7 + c.top.Z)), 0.5) -- the light slides across the glass
			end
		end
	end)
end

return M
