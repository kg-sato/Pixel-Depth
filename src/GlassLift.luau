-- GlassLift (ReplicatedStorage.Shared.GlassLift), started by PixelClient. The glass elevator from Camp 1's Deep Gate down
-- to the Clay Caves (Next Systems Plan, phase B, 2026-11-13): a ride in a glass cage down a shaft of glowing roots, seen only
-- by this player. The set lives in a full-screen ViewportFrame with its own camera and its own light, not in the world:
-- a set in the world stayed black for most of the ride (2026-11-13: after the camera jumps to a far place the local lights
-- take 10 s and more to show, while the Lighting values stay the same; cause not found). The server (ClayCaves.travel)
-- moves the character behind the picture and holds it for the length of the ride (12 s the first time, 6 s
-- after); Shared.ClayClient asks for the ride through hook.glassLift(secs) and does the fades. Display only.
local RunService = game:GetService("RunService")
local M = {}

function M.start(E)
	local new, hook = E.new, E.vmHook
	local MINT, VIOLET, WARM = Color3.fromRGB(120, 255, 200), Color3.fromRGB(196, 120, 255), Color3.fromRGB(255, 214, 150)
	local BARK, ROCK, BRASS = Color3.fromRGB(74, 52, 44), Color3.fromRGB(34, 24, 52), Color3.fromRGB(176, 136, 84)
	local DEPTH = 340
	local top = CFrame.new()
	local set, cage
	local vp = new("ViewportFrame", E.top, { Name = "GlassLift", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(10, 6, 18), BorderSizePixel = 0, Visible = false, ZIndex = 53,
		Ambient = Color3.fromRGB(150, 140, 190), LightColor = Color3.fromRGB(255, 236, 214), LightDirection = Vector3.new(-0.3, -1, -0.25) }) -- under ClayClient's fade (54)
	local vcam = new("Camera", vp, { FieldOfView = 82 })
	vp.CurrentCamera = vcam

	local function build()
		set = new("Model", vp, { Name = "Shaft" })
		local function sp(size, cf, color, props)
			local p = new("Part", set, { Size = size, CFrame = top * cf, Color = color, Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false, Material = Enum.Material.Slate })
			for k, v in props or {} do p[k] = v end
			return p
		end
		-- directive v14 phase 3 (audit: "four flat walls with thin strips"): each wall is a column of 4-stud rock blocks set at
		-- different depths: a shelf juts out every 20 studs (a timber brace lies on it), niches sink back between, the strata seams
		-- dip across the blocks, and the rock changes on the way down: violet slate, iron-stained limestone with crystal vugs, then
		-- terracotta warmed by the kiln below. Every block runs back to z -16, so no gap shows the void behind.
		local function zone(y)
			if y > -100 then return { Color3.fromRGB(46, 34, 72), Color3.fromRGB(66, 50, 98), Color3.fromRGB(92, 70, 128), Color3.fromRGB(58, 44, 88) }
			elseif y > -220 then return { Color3.fromRGB(92, 70, 84), Color3.fromRGB(168, 124, 78), Color3.fromRGB(150, 84, 52), Color3.fromRGB(70, 58, 88) } -- ochre sediment with dark plum seams: the grey-tan read as bare boxes (Orchestrator 2026-11-23)
			else return { Color3.fromRGB(128, 66, 54), Color3.fromRGB(176, 104, 64), Color3.fromRGB(204, 138, 86), Color3.fromRGB(78, 42, 62) } end -- a dark plum seam in the kiln zone too: the bottom still read as plain tan boxes (Orchestrator round 2, views 09)
		end
		local ROWS = DEPTH // 4
		local vugs = {}
		for k = 0, 3 do
			local face = CFrame.Angles(0, k * math.pi / 2, 0)
			sp(Vector3.new(0.4, DEPTH, 0.4), face * CFrame.new(k % 2 == 0 and 3.9 or -3.9, -DEPTH / 2, -5.4), Color3.fromRGB(138, 128, 168), { Material = Enum.Material.Metal }) -- the guide rail, clear of the shelves
			for c = 0, 4 do
				local x = -8 + c * 4
				local r0, runD, runCol = 0, nil, nil
				local function flush(r1)
					if not runD then return end
					local n = r1 - r0
					sp(Vector3.new(4, n * 4, runD + 16), face * CFrame.new(x, -r0 * 4 - n * 2, (runD - 16) / 2), runCol)
				end
				for r = 0, ROWS - 1 do
					local y = -r * 4 - 2
					local ledge = (r + k * 2) % 5 == 0
					local nz = math.noise(x / 9 + k * 3.1, y / 14, 0.7)
					local d = ledge and (-5.8 - (c % 2) * 0.6) or (nz > 0.22 and -13 or (nz < -0.22 and -7.6 or -9.6))
					if ledge and (c + r) % 4 == 2 then d = -12 end -- a gap in the shelf
					local pal = zone(y + math.noise(x / 7 + k, y / 30, 2.2) * 26) -- a ragged boundary between the rock zones, not a straight cut
					local col = pal[math.floor((-y + x * 0.18 + k * 3) / 8) % 4 + 1] -- the seams dip about 10 degrees across the wall
					if d <= -12 then col = col:Lerp(Color3.new(0, 0, 0), 0.35) end -- a niche sits in shadow
					if d == -13 and y < -100 and (r * 7 + c + k) % 3 == 0 then table.insert(vugs, { face = face, x = x, y = y, warm = y < -220 }) end
					if d ~= runD or col ~= runCol then
						flush(r)
						r0, runD, runCol = r, d, col
					end
				end
				flush(ROWS)
			end
			for r = 0, ROWS - 1 do -- a timber brace lies on each shelf, bolted, spanning its gap
				if (r + k * 2) % 5 == 0 and r > 0 then
					local rib = face * CFrame.new(0, -r * 4 + 0.45, -6.3)
					sp(Vector3.new(18, 0.9, 0.9), rib, BARK, { Material = Enum.Material.Wood })
					for _, bx in { -6, 0, 6 } do sp(Vector3.new(0.35, 0.35, 0.2), rib * CFrame.new(bx, 0, 0.52), Color3.fromRGB(120, 110, 140), { Material = Enum.Material.Metal }) end
				end
			end
		end
		for _, cx in { -1, 1 } do for _, cz in { -1, 1 } do sp(Vector3.new(7, DEPTH, 7), CFrame.new(cx * 12.5, -DEPTH / 2, cz * 12.5), Color3.fromRGB(30, 22, 44)) end end -- the corners
		for i, v in vugs do -- crystals deep in the niches (cyan and violet), and in the kiln zone a warm glow on the niche walls
			local base = v.face * CFrame.new(v.x, v.y - 1, -12.6)
			if v.warm then
				sp(Vector3.new(3.6, 3.6, 0.1), v.face * CFrame.new(v.x, v.y, -12.85), Color3.fromRGB(255, 160, 90), { Material = Enum.Material.SmoothPlastic, Transparency = 0.55 })
			else
				for q = 0, 2 do
					sp(Vector3.new(0.7, 1.8 - q * 0.4, 0.7), base * CFrame.new(q * 0.8 - 0.8, 0.6, 0.4) * CFrame.Angles(0.5, i + q, (q - 1) * 0.4), q == 1 and Color3.fromRGB(196, 120, 255) or Color3.fromRGB(120, 220, 255), { Material = Enum.Material.Glass, Transparency = 0.15 })
				end
				sp(Vector3.new(3.4, 3.4, 0.1), v.face * CFrame.new(v.x, v.y, -12.85), Color3.fromRGB(120, 220, 255), { Material = Enum.Material.SmoothPlastic, Transparency = 0.72 })
			end
		end
		local PINK, CYAN = Color3.fromRGB(255, 130, 200), Color3.fromRGB(120, 220, 255)
		local LIT = { Material = Enum.Material.SmoothPlastic } -- Neon turns white in a viewport: glowing things are plain saturated colour
		local UP = CFrame.Angles(0, 0, math.pi / 2) -- a cylinder's long axis is X
		for r = 0, DEPTH // 12 - 1 do -- directive v14: a warm lantern on an iron bracket every 18 studs, turning round the shaft (the old roots
			-- and neon veins clipped through the new ledges); a viewport has no point lights, so a soft glow plate sits on the rock behind it
			local face = CFrame.Angles(0, (r % 4) * math.pi / 2, 0)
			local x, y = ((r * 37) % 13) - 6, -r * 12 - 6
			sp(Vector3.new(0.2, 0.2, 2.4), face * CFrame.new(x, y + 2.3, -8.4), Color3.fromRGB(60, 54, 70), { Material = Enum.Material.Metal })
			sp(Vector3.new(0.9, 1.1, 0.9), face * CFrame.new(x, y + 1.6, -7.3), WARM, LIT)
			sp(Vector3.new(5, 5, 0.1), face * CFrame.new(x, y + 1.6, -9.45), WARM, { Material = LIT.Material, Transparency = 0.74 })
		end
		for r = 0, DEPTH // 10 - 1 do -- glowing root vines hanging down the walls, teal above and violet lower (Orchestrator round 2: "plain tan panels"); every 10 studs and in front of the ledges (round 3: at z -8.6 most hung inside the rock)
			for side = 0, 1 do -- two walls a row (Orchestrator final grade: at -65 m the left and upper-right walls were still bare)
			local face = CFrame.Angles(0, ((r + 2 + side * 2) % 4) * math.pi / 2, 0)
			local x, y = ((r * 53 + side * 29) % 15) - 7, -r * 10 - 4 - side * 5
			local col = y > -160 and Color3.fromRGB(70, 230, 210) or Color3.fromRGB(190, 120, 255)
			local len = 5 + (r % 3) * 2
			for s = 0, 2 do -- a few links that swing a little sideways, so it reads as a vine, not a pipe
				sp(Vector3.new(0.35, len / 3 + 0.2, 0.35), face * CFrame.new(x + math.sin(s * 1.7 + r) * 0.35, y - len / 6 - s * len / 3, -5.4) * CFrame.Angles(0, 0, math.sin(s + r) * 0.18), col, LIT)
			end
			sp(Vector3.new(0.8, 0.8, 0.8), face * CFrame.new(x, y - len - 0.2, -5.4) * CFrame.Angles(0.6, 0.6, 0), col:Lerp(Color3.new(1, 1, 1), 0.3), LIT) -- a glowing bud at the tip
			end
		end
		sp(Vector3.new(19, 1, 19), CFrame.new(0, -DEPTH + 2, 0), Color3.fromRGB(255, 170, 90), { Material = Enum.Material.SmoothPlastic }) -- the kiln glow of the Clay Caves far below
		for r = 0, 5 do -- molten seams glowing in the kiln zone's walls, warmer the deeper (Orchestrator round 3: "warm kiln rim light down to -85 m")
			local face = CFrame.Angles(0, (r % 4) * math.pi / 2, 0)
			local y = -230 - r * 18
			sp(Vector3.new(7 + (r % 3) * 2, 0.9, 0.1), face * CFrame.new(((r * 37) % 9) - 4, y, -5.6) * CFrame.Angles(0, 0, (r % 2 == 0 and 1 or -1) * 0.12), Color3.fromRGB(255, 150 - r * 8, 70), { Material = Enum.Material.SmoothPlastic, Transparency = 0.25 })
			sp(Vector3.new(10, 4, 0.1), face * CFrame.new(((r * 37) % 9) - 4, y, -5.7), Color3.fromRGB(255, 140, 70), { Material = Enum.Material.SmoothPlastic, Transparency = 0.8 }) -- its glow on the rock
		end
		cage = new("Model", set, { Name = "Cage" })
		local function cp(size, cf, color, props)
			local p = new("Part", cage, { Size = size, CFrame = cf, Color = color, Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false, Material = Enum.Material.Metal })
			for k, v in props or {} do p[k] = v end
			return p
		end
		cage.PrimaryPart = cp(Vector3.new(7.2, 0.2, 7.2), CFrame.new(), Color3.fromRGB(170, 235, 255), { Material = Enum.Material.Glass, Transparency = 0.8 }) -- a glass floor: the view down the shaft
		cp(Vector3.new(7.2, 0.12, 0.12), CFrame.new(), BRASS) -- one thin cross under the feet: the floor reads as glass, the view down stays open
		cp(Vector3.new(0.12, 0.12, 7.2), CFrame.new(), BRASS)
		for k = 0, 3 do
			local face = CFrame.Angles(0, k * math.pi / 2, 0)
			cp(Vector3.new(6.8, 7.4, 0.12), face * CFrame.new(0, 3.85, -3.5), Color3.fromRGB(170, 235, 255), { Material = Enum.Material.Glass, Transparency = 0.82, Reflectance = 0.12 })
			cp(Vector3.new(0.18, 7.7, 0.18), face * CFrame.new(3.5, 3.85, -3.5), BRASS)
			cp(Vector3.new(7.2, 0.18, 0.18), face * CFrame.new(0, 7.6, -3.5), BRASS)
			cp(Vector3.new(7.2, 0.14, 0.14), face * CFrame.new(0, 1.1, -3.5), BRASS) -- a waist rail
		end
		local lamp = cp(Vector3.new(0.8, 0.5, 0.8), CFrame.new(0, 7.3, 0), WARM, { Material = Enum.Material.SmoothPlastic })
		cp(Vector3.new(3, 0.1, 3), CFrame.new(0, 7.5, 0), WARM, { Material = Enum.Material.SmoothPlastic, Transparency = 0.6 })
		local _ = lamp
	end

	local riding = false
	local gauge -- (ZIndex 53 like the picture: the HUD layer sorts globally, so a lower one drew under it) tour views full1122f 09 ("no depth meter, no destination"): a brass depth rail on the right of the picture
	local function makeGauge() -- a smoked violet glass plate like the HUD's pills; the rail, the names and the depth sit on it (views full1122g 09: "a bare wireframe line")
		local plate = new("Frame", vp, { Name = "DepthPlate", Size = UDim2.fromScale(0.105, 0.62), Position = UDim2.fromScale(0.93, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Color3.fromRGB(30, 18, 50), BackgroundTransparency = 0.18, BorderSizePixel = 0, ZIndex = 53 })
		new("UICorner", plate, { CornerRadius = UDim.new(0.12, 0) })
		new("UIStroke", plate, { Color = Color3.fromRGB(176, 130, 255), Thickness = 2, Transparency = 0.25 })
		new("UIGradient", plate, { Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(150, 140, 200), Color3.fromRGB(255, 200, 150)) })
		local function word(t, y, col, h)
			local l = new("TextLabel", plate, { Text = t, Size = UDim2.fromScale(0.9, h), Position = UDim2.fromScale(0.5, y), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, Font = Enum.Font.FredokaOne, TextScaled = true, TextColor3 = col, ZIndex = 53 })
			new("UIStroke", l, { Color = Color3.fromRGB(20, 10, 30), Thickness = 2 })
			return l
		end
		word("CAMP 1", 0.055, Color3.fromRGB(214, 196, 255), 0.055)
		word("KILN CAMP", 0.945, WARM, 0.06)
		local rail = new("Frame", plate, { Name = "DepthRail", Size = UDim2.fromScale(0.07, 0.74), Position = UDim2.fromScale(0.74, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Color3.fromRGB(16, 8, 28), BorderSizePixel = 0, ZIndex = 53 })
		new("UICorner", rail, { CornerRadius = UDim.new(0.5, 0) })
		new("UIStroke", rail, { Color = BRASS, Thickness = 1.5 })
		local dot = new("Frame", rail, { Size = UDim2.fromScale(3, 0.045), Position = UDim2.fromScale(0.5, 0), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = WARM, BorderSizePixel = 0, ZIndex = 53 })
		new("UICorner", dot, { CornerRadius = UDim.new(0.5, 0) })
		new("UIStroke", dot, { Color = Color3.fromRGB(255, 244, 220), Thickness = 1.5 })
		local depth = new("TextLabel", plate, { Text = "0 m", Size = UDim2.fromScale(0.55, 0.05), Position = UDim2.fromScale(0.6, 0.13), AnchorPoint = Vector2.new(1, 0.5), BackgroundTransparency = 1, Font = Enum.Font.FredokaOne, TextScaled = true, TextColor3 = Color3.new(1, 1, 1), ZIndex = 53 })
		new("UIStroke", depth, { Color = Color3.fromRGB(20, 10, 30), Thickness = 2 })
		return { dot = dot, depth = depth }
	end
	-- secs: how long the server holds the character. Returns false when the view is not free (then the fade alone covers the move).
	hook.glassLift = function(secs, fade) -- fade(transparency, seconds): the caller's black cover
		if riding or workspace.CurrentCamera.CameraType == Enum.CameraType.Scriptable then return false end
		if not set then build() end
		riding = true
		local t0, dist = os.clock() + 0.35, math.min(DEPTH - 40, secs * 24)
		task.delay(0.35, function()
			if workspace.CurrentCamera.CameraType == Enum.CameraType.Scriptable or (E.isBusy and E.isBusy()) or (hook.deathPlaying and hook.deathPlaying()) or not E.gui.Enabled then
				riding = false
				return
			end
			vp.Visible = true
			E.gui.Enabled = false
			E.sfx("open", 0.5)
			fade(1, 0.4)
			local conn, nextTick, dark = nil, 0, false
			conn = RunService.RenderStepped:Connect(function()
				local t = (os.clock() - t0) / secs
				if t >= 1 then
					conn:Disconnect()
					vp.Visible = false
					E.gui.Enabled = true
					riding = false
					E.sfx("land", 0.7)
					return
				end
				if not dark and t > 1 - 0.45 / secs then
					dark = true
					fade(0, 0.35)
				end
				local e = t * t * (3 - 2 * t) -- eases off the top and onto the floor
				vp.Ambient = Color3.fromRGB(178, 172, 228):Lerp(Color3.fromRGB(236, 182, 146), e) -- brighter since directive v14 (tour grade: the shaft read near black) -- cool slate up top, the kiln's warm glow as you near the Clay Caves
				vp.LightColor = Color3.fromRGB(220, 230, 255):Lerp(Color3.fromRGB(255, 200, 150), e)
				local floor = top * CFrame.new(0, -14 - e * dist, 0)
				cage:PivotTo(floor)
				gauge = gauge or makeGauge()
				gauge.dot.Position = UDim2.fromScale(0.5, e)
				gauge.depth.Position, gauge.depth.Text = UDim2.fromScale(0.6, 0.13 + 0.74 * e), "-" .. math.floor(e * dist / 4 + 0.5) .. " m"
				local speed = 6 * t * (1 - t) -- 0 at both ends, 1.5 in the middle
				vcam.CFrame = floor * CFrame.new(0, 4.6 + math.sin(os.clock() * 17) * 0.02 * speed, 0) * CFrame.Angles(0, 0.5 + t * 2.4, 0) * CFrame.Angles(-0.7 - math.sin(t * math.pi) ^ 2 * 0.3, 0, 0) -- a slow look round, always partly down the shaft (level, the first frames faced the rock 8 studs away: Gemini full1122e 313 s)
				if os.clock() >= nextTick then
					nextTick = os.clock() + 0.5 - speed * 0.2
					E.sfx("step", 0.4 + speed * 0.12)
				end
			end)
		end)
		return true
	end
end

return M
