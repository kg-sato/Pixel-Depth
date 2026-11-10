-- GloomClient (ReplicatedStorage.Shared.GloomClient), started by PixelClient. The Gloom (roadmap phase 6; server: ServerScriptService.Gloom): the flare key (HP and the flare slot are drawn by Shared.SurvivalHUD), a soot sprite
-- drawn on every server gloomling (bob, blinking eyes, squash when flared), BONK and the catch, the flare burst, the golden shield,
-- and Wick's and Smudge's speech bubbles at Camp 1. The torch follows the server: RelitAt and TorchFrozen attributes.
local M = {}
function M.start(E)
	local R, C, plr, cave, caveHud = E.R, E.C, E.plr, E.cave, E.caveHud
	local panel, fit, S, new, text, button, setKind, tween = E.panel, E.fit, E.S, E.new, E.text, E.button, E.setKind, E.tween
	local burst, sfx, shake, toast, commas, hrp = E.burst, E.sfx, E.shake, E.toast, E.commas, E.hrp
	local INK, PINK, GOLD, CREAM, FONT = E.INK, E.PINK, E.GOLD, E.CREAM, E.FONT
	local UIS, RunService = game:GetService("UserInputService"), game:GetService("RunService")
	local FlareR = R:WaitForChild("Flare", 30)
	local MINT_C = Color3.fromRGB(127, 220, 180)
	local SOOT, EYE = Color3.fromRGB(44, 42, 62), Color3.fromRGB(214, 196, 140) -- charcoal; eyes a soft gold (pale neon bloomed to white)
	-- the HP hearts and the flare slot are drawn by Shared.SurvivalHUD (the talisman); the flare itself fires from here
	local function fire()
		if FlareR and plr:GetAttribute("InCave") and (plr:GetAttribute("Flares") or 0) > 0 and not cave.mgBusy then FlareR:FireServer() end
	end
	cave.flare = fire
	UIS.InputBegan:Connect(function(io, gp)
		if not gp and (io.KeyCode == Enum.KeyCode.R or io.KeyCode == Enum.KeyCode.ButtonY) then fire() end
	end)
	-- screen layer: the hit flash and the golden shield
	local layer = new("ScreenGui", plr:WaitForChild("PlayerGui"), { Name = "GloomFx", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 6 })
	local hitFlash = new("Frame", layer, { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(255, 80, 120), BackgroundTransparency = 1, BorderSizePixel = 0 })
	local shield = new("Frame", layer, { Size = UDim2.new(1, -20, 1, -20), Position = UDim2.fromOffset(10, 10), BackgroundTransparency = 1, BorderSizePixel = 0 }) -- inset: the stroke draws outside the frame
	local WARN = Color3.fromRGB(255, 84, 104)
	local warnBar = new("Frame", layer, { Name = "GloomWarn", Size = UDim2.fromOffset(120, 16), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = WARN, BorderSizePixel = 0, Visible = false })
	new("UICorner", warnBar, { CornerRadius = UDim.new(1, 0) })
	new("UIStroke", warnBar, { Color = Color3.fromRGB(255, 255, 255), Thickness = 2 })
	local shieldStroke = new("UIStroke", shield, { Color = Color3.fromRGB(255, 210, 90), Thickness = 18, Transparency = 1 })
	-- the torch follows the server: frozen until the first bank, else counted from when you left the ring
	plr:GetAttributeChangedSignal("RelitAt"):Connect(function()
		local at = plr:GetAttribute("RelitAt")
		if at then cave.relitAt = os.clock() - (workspace:GetServerTimeNow() - at) end
	end)

	-- the soot sprites: a squashable ball (a sphere mesh), a fringe of fluff, two glowing eyes that blink
	local visFolder = new("Folder", workspace, { Name = "GloomVis" })
	local vis = {}
	local function soot()
		local m = new("Model", visFolder, { Name = "Soot" })
		local function p(size, cf, color, props)
			local q = new("Part", m, { Size = size, CFrame = cf, Color = color, Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false, Material = Enum.Material.SmoothPlastic, TopSurface = Enum.SurfaceType.Smooth, BottomSurface = Enum.SurfaceType.Smooth })
			for k, v in props or {} do q[k] = v end
			return q
		end
		local body = p(Vector3.new(2.2, 2.2, 2.2), CFrame.new(), SOOT)
		local mesh = new("SpecialMesh", body, { MeshType = Enum.MeshType.Sphere })
		m.PrimaryPart = body
		local fluff = {}
		for k = 1, 7 do
			local a = k / 7 * math.pi * 2
			local f = p(Vector3.new(0.7, 0.7, 0.7), CFrame.new(math.cos(a) * 1.05, math.sin(a * 2) * 0.5, math.sin(a) * 1.05) * CFrame.Angles(a, a * 2, 0), SOOT:Lerp(Color3.new(0, 0, 0), 0.3))
			table.insert(fluff, { part = f, off = f.CFrame })
		end
		local eyes = {}
		for _, x in { -0.4, 0.4 } do -- two round eyes, each with a dark pupil
			local e = p(Vector3.new(0.12, 0.5, 0.5), CFrame.new(x, 0.15, -1.06) * CFrame.Angles(0, math.pi / 2, 0), EYE, { Material = Enum.Material.Neon, Shape = Enum.PartType.Cylinder })
			table.insert(eyes, { part = e, off = e.CFrame })
			local pu = p(Vector3.new(0.1, 0.24, 0.24), CFrame.new(x + 0.03, 0.12, -1.12) * CFrame.Angles(0, math.pi / 2, 0), Color3.fromRGB(26, 18, 40), { Shape = Enum.PartType.Cylinder })
			table.insert(eyes, { part = pu, off = pu.CFrame })
		end
		local puff = new("ParticleEmitter", body, { Rate = 6, Lifetime = NumberRange.new(0.8, 1.4), Speed = NumberRange.new(0.5, 1.2), SpreadAngle = Vector2.new(180, 180),
			Size = NumberSequence.new(0.5, 1.1), Transparency = NumberSequence.new(0.45, 1), Color = ColorSequence.new(Color3.fromRGB(96, 80, 130)), LightInfluence = 0.3 }) -- soot puffs
		return { m = m, body = body, mesh = mesh, fluff = fluff, eyes = eyes }
	end
	local function burstAt(pos, color, n) burst(pos, Vector3.yAxis, color, n) end
	RunService.RenderStepped:Connect(function(dt)
		local folder = workspace:FindFirstChild("Gloom")
		if folder then
			for _, p in folder:GetChildren() do
				if not vis[p] then
					local v = soot()
					v.cf, v.seed, v.blink, v.state = p.CFrame, math.random() * 6, os.clock() + math.random() * 3, "creep"
					vis[p] = v
				end
			end
		end
		local now = os.clock()
		for p, v in vis do
			if not p.Parent then
				burstAt(v.cf.Position, Color3.fromRGB(80, 60, 110), 10) -- a puff of soot as it slips into a crack
				v.m:Destroy()
				vis[p] = nil
			else
				local state = p:GetAttribute("State") or "creep"
				if state ~= v.state then
					if state == "pancake" then sfx("hit", 0.6) end
					if state == "windup" then sfx("error", 1.4) end -- about to hit: hear it even with your back turned
					v.state, v.since = state, now
				end
				v.cf = v.cf:Lerp(p.CFrame, 1 - math.exp(-dt * 10))
				local bob = math.sin(now * 3 + v.seed) * 0.25
				local sy, sxz, tilt = 1, 1, 0
				if state == "pancake" then
					local k = math.min((now - (v.since or now)) / 0.12, 1)
					sy, sxz = 1 - 0.7 * k, 1 + 0.6 * k
				elseif state == "stun" then
					tilt = math.sin(now * 25) * 0.3
				elseif state == "windup" then -- rears up and shivers, eyes red
					sy, sxz, tilt = 1.3, 1.15, math.sin(now * 40) * 0.12
				elseif state == "flee" then
					sy, sxz = 0.8, 0.9
				end
				local base = v.cf * CFrame.new(0, bob - (1 - sy) * 1.1, 0) * CFrame.Angles(0, 0, tilt)
				v.body.CFrame = base
				v.mesh.Scale = Vector3.new(sxz, sy, sxz)
				for _, f in v.fluff do f.part.CFrame = base * CFrame.new(f.off.Position * Vector3.new(sxz, sy, sxz)) * f.off.Rotation * CFrame.Angles(0, now * 0.8, 0) end
				local shut = now > v.blink and now < v.blink + 0.12
				if now > v.blink + 0.12 then v.blink = now + 2 + math.random() * 2 end
				for _, e in v.eyes do
					e.part.CFrame = base * CFrame.new(e.off.Position * Vector3.new(sxz, sy, 1)) * e.off.Rotation
					e.part.Transparency = ((shut and state ~= "windup") or state == "flee") and 1 or 0
					e.col = e.col or e.part.Color
					e.part.Color = (state == "windup" and e.col == EYE) and WARN or e.col
				end
			end
		end
		-- the warning mark: a red bar at the side of the screen the nearest rearing gloomling is on (first person has no eyes in its back)
		local near, nd
		local cam = workspace.CurrentCamera
		for _, v in vis do
			if v.state == "windup" then
				local d = (v.cf.Position - cam.CFrame.Position).Magnitude
				if not nd or d < nd then near, nd = v, d end
			end
		end
		warnBar.Visible = near ~= nil
		if near then
			local rel = cam.CFrame:PointToObjectSpace(near.cf.Position)
			local a = math.atan2(rel.X, -rel.Z)
			local vp = cam.ViewportSize
			local r = math.min(vp.X, vp.Y) * 0.32
			warnBar.Position = UDim2.fromOffset(vp.X / 2 + math.sin(a) * r, vp.Y / 2 - math.cos(a) * r)
			warnBar.Rotation = math.deg(a)
			warnBar.BackgroundTransparency = 0.15 + 0.25 * math.abs(math.sin(now * 14))
		end
		-- held by a gloomling: slow feet and a pink pulse
		local held = (plr:GetAttribute("GrabbedUntil") or 0) - workspace:GetServerTimeNow()
		local hum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
		if held > 0 then
			hitFlash.BackgroundTransparency = math.min(hitFlash.BackgroundTransparency, 0.72 + 0.12 * math.sin(now * 12))
			if hum and hum.WalkSpeed > 4 then hum:SetAttribute("FreeSpeed", hum.WalkSpeed) hum.WalkSpeed = 4 end
		elseif hum and hum:GetAttribute("FreeSpeed") then
			hum.WalkSpeed = hum:GetAttribute("FreeSpeed")
			hum:SetAttribute("FreeSpeed", nil)
		end
		-- the golden shield after a catch
		local left = (plr:GetAttribute("ShieldUntil") or 0) - workspace:GetServerTimeNow()
		shieldStroke.Transparency = left > 0 and (0.35 + 0.25 * math.sin(now * 10)) or 1
		hitFlash.BackgroundTransparency = math.min(1, hitFlash.BackgroundTransparency + dt * 2.5)
	end)

	-- server moments: BONK, the catch, a flare
	R.Fx.OnClientEvent:Connect(function(kind, a, b)
		if kind == "gloomBonk" then
			shake(0.5)
			sfx("hit", 0.7)
			sfx("breakRock", 1.4)
			hitFlash.BackgroundTransparency = 0.55
			toast("BONK!", PINK, true)
		elseif kind == "caught" then
			shake(0.8)
			sfx("breakRock", 0.8)
			hitFlash.BackgroundTransparency = 0.35
			toast(a < 0 and "FAFNIR BLOCKED THE CATCH!" or (a > 0 and ("BONK! A GLOOMLING GRABBED " .. commas(a) .. " ORE") or "BONK! A GLOOMLING GOT YOU"), a < 0 and GOLD or PINK, true)
			toast("Golden shield for 5 s: run!", GOLD, false, 0.9)
		elseif kind == "grabbed" then -- held for a few seconds: a flare now saves the ore
			shake(0.6)
			sfx("breakRock", 0.6)
			hitFlash.BackgroundTransparency = 0.3
			toast("GRABBED!  FLARE NOW (R) OR A FRIEND CAN FLARE YOU FREE", PINK, true)
		elseif kind == "rescued" then
			toast(b and "FLARED FREE! NOTHING LOST" or ("RESCUED BY " .. string.upper(a) .. "!"), MINT_C, true)
			sfx("sparkle", 1.2)
		elseif kind == "rescuedFriend" then
			toast("YOU RESCUED " .. string.upper(a) .. "!", MINT_C, true)
			sfx("sparkle", 1.3)
		elseif kind == "flareFx" then -- a pocket sunrise: a white-gold ball swells and fades, sparks fly, the cave lights up
			local pos = a
			local ball = new("Part", workspace, { Shape = Enum.PartType.Ball, Size = Vector3.one, CFrame = CFrame.new(pos), Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false, Material = Enum.Material.Neon, Color = Color3.fromRGB(255, 240, 200) })
			local l = new("PointLight", ball, { Color = Color3.fromRGB(255, 226, 170), Range = 0, Brightness = 4 })
			burstAt(pos, Color3.fromRGB(255, 220, 140), 50)
			if b == plr.UserId then sfx("sparkle", 0.7) sfx("swing", 1.5) shake(0.25) end
			tween(ball, 0.35, { Size = Vector3.one * 9, Transparency = 0.6 }, Enum.EasingStyle.Quad).Completed:Connect(function()
				tween(ball, 0.6, { Size = Vector3.one * 12, Transparency = 1 }):Play()
			end)
			tween(l, 0.15, { Range = 40 }).Completed:Connect(function() tween(l, 1.4, { Range = 0, Brightness = 0 }) end)
			task.delay(2, function() ball:Destroy() end)
		end
	end)

	-- Wick and Smudge at Camp 1: a bubble with a line when you are close (Lore and Gameplay Plan, cast table)
	local LINES = {
		Wick = { "Torch relit! Your ore's safe with me.", "Ore's out there. Look for sparkles!", "Low torch? Come back to camp.", "Gloomlings hate flares. Press R!", "Banked ore is safe ore." },
		Smudge = { "...is it bright in there? Can I come?", "I'm not scary. Promise.", "The dark is SO dark." },
	}
	local bubbles = {}
	task.spawn(function()
		while true do
			task.wait(0.4)
			local caves = workspace:FindFirstChild("Caves")
			local h = hrp()
			for name, lines in LINES do
				local head = caves and caves:FindFirstChild(name .. "Head", true)
				if head and not bubbles[name] then
					local bb = new("BillboardGui", head, { Name = "Bubble", Size = UDim2.fromScale(5.6, 1.25), StudsOffset = Vector3.new(0, 3.6, 0), AlwaysOnTop = false, MaxDistance = 40, LightInfluence = 0, Enabled = false })
					local bg = new("Frame", bb, { Size = UDim2.fromScale(1, 1), BackgroundColor3 = CREAM, BorderSizePixel = 0 })
					new("UICorner", bg, { CornerRadius = UDim.new(0.4, 0) })
					new("UIStroke", bg, { Color = INK, Thickness = 2 })
					local tail = new("Frame", bb, { Size = UDim2.fromScale(0.07, 0.3), Position = UDim2.fromScale(0.5, 0.97), AnchorPoint = Vector2.new(0.5, 0.5), Rotation = 45, BackgroundColor3 = CREAM, BorderSizePixel = 0, ZIndex = 0 }) -- a tail pointing down at the speaker
					new("UIAspectRatioConstraint", tail, { AspectRatio = 1 })
					new("UIStroke", tail, { Color = INK, Thickness = 2 })
					local t = new("TextLabel", bg, { Size = UDim2.fromScale(0.9, 0.7), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, Font = FONT, TextScaled = true, TextColor3 = INK, Text = lines[1] })
					bubbles[name] = { bb = bb, t = t, i = 1, next = 0, head = head }
				end
				local bu = bubbles[name]
				if bu and bu.head.Parent and h then
					local near = (bu.head.Position - h.Position).Magnitude < (name == "Wick" and 18 or 12) and plr:GetAttribute("InCave")
					if near and not bu.bb.Enabled then bu.bb.Enabled = true end
					if not near then bu.bb.Enabled = false end
					if near and os.clock() > bu.next then
						bu.t.Text = lines[bu.i]
						bu.i = bu.i % #lines + 1
						bu.next = os.clock() + 4.5
					end
				elseif bu and not bu.head.Parent then
					bubbles[name] = nil
				end
			end
		end
	end)
end

return M
