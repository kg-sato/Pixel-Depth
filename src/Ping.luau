-- Ping (ReplicatedStorage.Shared.Ping), started by PixelClient. Co-op callouts in the caves (vault Research/Game Design
-- and Market/Fastest-Growing New Roblox Games (2026-11-11).md, "co-op built on unequal knowledge"): press Z (or the
-- middle mouse button) while looking at something and every miner nearby gets a marker there for 8 seconds: ORE on a
-- deposit, GLOOM on a gloomling, HERE anywhere else. The marker is a pill on screen that follows the spot and slides to
-- the screen edge when the spot is out of view, plus a thin beam of light in the world.
-- The server (ServerScriptService.PingRelay) checks the cave, the distance and the rate, and relays; no free text.
-- shortcut: keyboard and mouse only; add a HUD button for touch when co-op is tested on phones.
local M = {}

local LIFE, REACH = 8, 140

function M.start(E)
	local UIS, RunService = game:GetService("UserInputService"), game:GetService("RunService")
	local R, plr, new = E.R, E.plr, E.new
	local PingR = R:WaitForChild("Ping", 20)
	if not PingR then return end
	local cam = workspace.CurrentCamera
	local MID = Vector2.new(0.5, 0.5)
	local LOOK = { ore = { "ORE", E.MINT }, gloom = { "GLOOM", E.PINK }, here = { "HERE", E.BUTTER } }
	local live = {}
	local inset = game:GetService("GuiService"):GetGuiInset().Y

	local function under(inst, name) -- is inst inside a folder or model called name?
		local a = inst
		while a and a ~= workspace do
			if a.Name == name then return true end
			a = a.Parent
		end
		return false
	end
	local function send()
		if not plr:GetAttribute("InCave") or E.isBusy() then return end
		local prm = RaycastParams.new()
		prm.FilterDescendantsInstances = { plr.Character, cam }
		prm.FilterType = Enum.RaycastFilterType.Exclude
		local hit = workspace:Raycast(cam.CFrame.Position, cam.CFrame.LookVector * REACH, prm)
		if not hit then return end
		local kind = under(hit.Instance, "Deposits") and "ore" or ((hit.Instance:GetAttribute("State") ~= nil or under(hit.Instance, "Gloom")) and "gloom" or "here")
		PingR:FireServer(hit.Position, kind)
	end
	UIS.InputBegan:Connect(function(io, gp)
		if gp then return end
		if io.KeyCode == Enum.KeyCode.Z or io.UserInputType == Enum.UserInputType.MouseButton3 then send() end
	end)

	local function show(pos, kind, who)
		local look = LOOK[kind] or LOOK.here
		local pill = new("Frame", E.gui, { Name = "PingMark", Size = E.S(104, 32), AnchorPoint = Vector2.new(0.5, 1), BackgroundColor3 = look[2]:Lerp(E.WHITE, 0.35), BorderSizePixel = 0, ZIndex = 30 })
		E.fit(pill, 104, 32)
		new("UICorner", pill, { CornerRadius = UDim.new(0.5, 0) })
		new("UIStroke", pill, { Color = E.INK, Thickness = 3 })
		-- a pointer under the pill: it aims at the spot, and turns sideways when the spot is off screen
		local tip = new("Frame", pill, { Size = UDim2.fromScale(0.42, 0.42), SizeConstraint = Enum.SizeConstraint.RelativeYY, Position = UDim2.fromScale(0.5, 1.02), AnchorPoint = MID, Rotation = 45, BackgroundColor3 = E.INK, BorderSizePixel = 0, ZIndex = 29 })
		local dot = new("Frame", pill, { Size = UDim2.fromScale(0.6, 0.6), SizeConstraint = Enum.SizeConstraint.RelativeYY, Position = UDim2.fromScale(0.16, 0.5), AnchorPoint = MID, BackgroundColor3 = look[2], BorderSizePixel = 0, ZIndex = 31 })
		new("UICorner", dot, { CornerRadius = UDim.new(0.5, 0) })
		new("UIStroke", dot, { Color = E.INK, Thickness = 2 })
		local label = E.text(pill, look[1], UDim2.fromScale(0.62, 0.62), UDim2.fromScale(0.64, 0.5), MID, E.INK, 700, false)
		label.ZIndex = 31
		local name = E.text(pill, who, UDim2.fromScale(1.6, 0.5), UDim2.fromScale(0.5, -0.36), MID, E.WHITE)
		name.ZIndex = 31
		name.Visible = who ~= plr.Name -- your own ping needs no name
		local beam = Instance.new("Part") -- a thin pillar of light at the spot
		beam.Name, beam.Anchored, beam.CanCollide, beam.CanQuery, beam.CanTouch, beam.CastShadow = "PingBeam", true, false, false, false, false
		beam.Material, beam.Color, beam.Transparency = Enum.Material.Neon, look[2], 0.2
		beam.Size, beam.Position = Vector3.new(0.5, 14, 0.5), pos + Vector3.new(0, 7, 0)
		local glow = Instance.new("PointLight")
		glow.Color, glow.Range, glow.Brightness, glow.Shadows = look[2], 12, 1.2, false
		glow.Parent = beam
		local ring = Instance.new("Part") -- a ring on the ground: where exactly the spot is (Gemini r1: no ground anchor, find speed 3)
		ring.Name, ring.Shape, ring.Anchored, ring.CanCollide, ring.CanQuery, ring.CanTouch, ring.CastShadow = "PingRing", Enum.PartType.Cylinder, true, false, false, false, false
		ring.Material, ring.Color, ring.Transparency = Enum.Material.Neon, look[2], 0.5
		ring.Size, ring.CFrame = Vector3.new(0.12, 5, 5), CFrame.new(pos + Vector3.new(0, 0.1, 0)) * CFrame.Angles(0, 0, math.rad(90))
		ring.Parent = beam
		beam.Parent = workspace
		pcall(E.sfx, "pop", 1.3)
		pcall(E.pop, pill)
		table.insert(live, { pill = pill, beam = beam, ring = ring, tip = tip, pos = pos, label = label, word = look[1], t0 = os.clock() })
	end
	R.Fx.OnClientEvent:Connect(function(kind, pos, what, who)
		if kind == "ping" and typeof(pos) == "Vector3" then show(pos, what, tostring(who)) end
	end)

	RunService.RenderStepped:Connect(function()
		for i = #live, 1, -1 do
			local m = live[i]
			local age = os.clock() - m.t0
			if age > LIFE or not m.pill.Parent then
				m.pill:Destroy()
				m.beam:Destroy()
				table.remove(live, i)
			else
				local v = cam:WorldToViewportPoint(m.pos + Vector3.new(0, 3.2, 0))
				local vs = cam.ViewportSize
				local x, y = v.X, v.Y
				if v.Z < 0 then x, y = vs.X - x, vs.Y * 0.9 end -- behind you: it waits low on the side to turn toward
				x, y = math.clamp(x, vs.X * 0.25, vs.X * 0.83), math.clamp(y, vs.Y * 0.24, vs.Y * 0.8) -- inside the HUD's columns, so a marker never lies on a button
				local off = v.Z < 0 or math.abs(x - v.X) > 2 or math.abs(y - v.Y) > 2 -- pushed in from where the spot really is
				m.tip.Position = (not off) and UDim2.fromScale(0.5, 1.02) or UDim2.fromScale((v.Z < 0 and vs.X - v.X or v.X) < vs.X / 2 and -0.02 or 1.02, 0.5)
				m.pill.Position = UDim2.fromOffset(x, y - inset) -- PixelHUD starts below the top bar inset
				local pulse = 5 + 1.2 * math.sin(age * 6)
				m.ring.Size = Vector3.new(0.12, pulse, pulse)
				local h = E.hrp()
				if h then m.label.Text = m.word .. " " .. math.floor((m.pos - h.Position).Magnitude / 4 + 0.5) .. "m" end
				local fade = math.clamp((age - (LIFE - 1)) / 1, 0, 1)
				m.pill.BackgroundTransparency, m.beam.Transparency, m.ring.Transparency = fade, 0.2 + 0.8 * fade, 0.5 + 0.5 * fade
			end
		end
	end)
end

return M
