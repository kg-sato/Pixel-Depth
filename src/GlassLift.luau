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
		for k = 0, 3 do -- four rock walls, a guide rail on each, a timber rib every 20 studs (they give the speed)
			local face = CFrame.Angles(0, k * math.pi / 2, 0)
			sp(Vector3.new(19, DEPTH, 1), face * CFrame.new(0, -DEPTH / 2, -9), ROCK:Lerp(Color3.fromRGB(58, 44, 88), (k % 2) * 0.35))
			sp(Vector3.new(0.4, DEPTH, 0.4), face * CFrame.new(k % 2 == 0 and 3.9 or -3.9, -DEPTH / 2, -8.3), Color3.fromRGB(138, 128, 168), { Material = Enum.Material.Metal })
			for r = 0, DEPTH // 20 - 1 do
				sp(Vector3.new(18, 0.9, 0.7), face * CFrame.new(0, -r * 20 - (k % 2) * 10, -8.2), BARK, { Material = Enum.Material.Wood })
			end
		end
		for k = 0, 3 do -- strata: a lighter band of rock every 16 studs, so the walls are not one flat colour
			local face = CFrame.Angles(0, k * math.pi / 2, 0)
			for r = 0, DEPTH // 16 - 1 do
				sp(Vector3.new(18.6, 5 + (r * 7 + k) % 4, 0.3), face * CFrame.new(0, -r * 16 - k * 4, -8.45), Color3.fromRGB(58, 44, 88):Lerp(Color3.fromRGB(96, 70, 120), ((r + k) % 3) / 3))
			end
		end
		local PINK, CYAN = Color3.fromRGB(255, 130, 200), Color3.fromRGB(120, 220, 255)
		local LIT = { Material = Enum.Material.SmoothPlastic } -- Neon turns white in a viewport: glowing things are plain saturated colour
		local UP = CFrame.Angles(0, 0, math.pi / 2) -- a cylinder's long axis is X
		for r = 0, DEPTH // 6 - 1 do -- round roots winding down the walls with a glowing vein each; rock blocks, crystals and lanterns between them
			local face = CFrame.Angles(0, (r * 3 % 4) * math.pi / 2, 0)
			local x, y = ((r * 37) % 15) - 7, -r * 6 - 4
			local lean = CFrame.Angles(0, 0, ((r * 53) % 11 - 5) * 0.12)
			local w = 1.8 + (r % 3) * 0.8
			local at = face * CFrame.new(x, y, -8.1) * lean
			sp(Vector3.new(26, w, w), at * UP, BARK:Lerp(Color3.fromRGB(132, 92, 66), (r % 4) / 4), { Material = Enum.Material.Wood, Shape = Enum.PartType.Cylinder })
			sp(Vector3.new(15, w * 0.5, w * 0.5), at * CFrame.new(w * 0.7, 3, 0.3) * CFrame.Angles(0, 0, 0.35) * UP, BARK:Lerp(Color3.fromRGB(104, 70, 54), 0.5), { Material = Enum.Material.Wood, Shape = Enum.PartType.Cylinder }) -- a side shoot
			local glow = r % 3 == 0 and VIOLET or MINT
			sp(Vector3.new(21, 0.42, 0.42), at * CFrame.new(0, 0, w / 2 + 0.02) * UP, glow, { Material = LIT.Material, Shape = Enum.PartType.Cylinder })
			sp(Vector3.new(w + 5, 24, 0.1), face * CFrame.new(x, y, -8.38) * lean, glow, { Material = LIT.Material, Transparency = 0.78 }) -- the vein's glow on the rock (a viewport has no point lights)
			sp(Vector3.new(3 + (r * 5) % 4, 2 + (r * 3) % 3, 1 + (r % 3) * 0.5), face * CFrame.new(-x * 0.8 + 2, y - 3, -8.3), ROCK:Lerp(Color3.fromRGB(86, 64, 118), ((r * 7) % 5) / 5)) -- a block of rock standing out of the wall
			if r % 3 == 1 then
				for q = 0, 2 do
					sp(Vector3.new(1.5 - q * 0.3, 5.5 - q * 1.3, 1.5 - q * 0.3), face * CFrame.new(-x + q * 1.3 - 1.3, y + 5, -7.8) * CFrame.Angles(0.5 + q * 0.2, r + q, 0.45 - q * 0.4), q == 1 and PINK or (r % 2 == 0 and VIOLET or CYAN), { Material = Enum.Material.Glass, Transparency = 0.2 })
				end
			elseif r % 3 == 2 then
				sp(Vector3.new(0.12, 3, 0.12), face * CFrame.new(-x, y + 3.5, -6.6), BARK)
				sp(Vector3.new(0.9, 1.1, 0.9), face * CFrame.new(-x, y + 1.6, -6.6), WARM, LIT)
				sp(Vector3.new(3.6, 3.6, 0.1), face * CFrame.new(-x, y + 1.6, -8.36), WARM, { Material = LIT.Material, Transparency = 0.7 })
			end
		end
		sp(Vector3.new(19, 1, 19), CFrame.new(0, -DEPTH + 2, 0), Color3.fromRGB(255, 170, 90), { Material = Enum.Material.SmoothPlastic }) -- the kiln glow of the Clay Caves far below
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
				local floor = top * CFrame.new(0, -14 - e * dist, 0)
				cage:PivotTo(floor)
				local speed = 6 * t * (1 - t) -- 0 at both ends, 1.5 in the middle
				vcam.CFrame = floor * CFrame.new(0, 4.6 + math.sin(os.clock() * 17) * 0.02 * speed, 0) * CFrame.Angles(0, 0.5 + t * 2.4, 0) * CFrame.Angles(-0.1 - math.sin(t * math.pi) ^ 2 * 0.75, 0, 0) -- a slow look round, and down the shaft in the middle
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
