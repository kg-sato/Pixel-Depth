-- LightGovernor (ReplicatedStorage.Shared.LightGovernor), started by PixelClient. Keeps the night dark on weak devices.
-- Measured 2026-11-12 (vault Briefs/Night That Holds At Every Graphics Level): below graphics level 7 or 8 the engine
-- draws local lights about twice as strong, and the 435 lanterns turn the night town into day (mean picture brightness
-- 129 against 84) and flatten the caves. No light values look the same at both ends, so this module scales every
-- light's brightness on the client when the device is on a low level:
--   * the saved graphics slider is 1 to 6 (readable: UserGameSettings.SavedQualityLevel), or
--   * the slider is on Automatic and the device is touch-only (a phone or tablet: the true level cannot be read, and
--     Automatic on a phone usually means a low one).
-- A PC or console on Automatic, and any device at 7 or more, is left exactly as built.
-- Lights that PixelClient drives every frame (hub lantern flicker, the torch, ore glints) multiply by E.vmHook.lightK there.
-- shortcut: lights other modules animate (flares, effects) keep their own values; they are short-lived. Studio hooks: client attribute DevLowLight forces
-- the low factor, DevTouch counts as a touch device.
local M = {}

local LOW = 0.4 -- measured in town: level 10 as built 82; level 2 as built 129, at 0.45 it is 94, at 0.4 about 90

function M.start(E)
	local UIS = game:GetService("UserInputService")
	local plr = E.plr
	local okS, ugs = pcall(function() return UserSettings():GetService("UserGameSettings") end)
	if not okS then ugs = nil end
	local factor = 1

	local function wanted()
		if plr:GetAttribute("DevLowLight") ~= nil then return LOW end
		local ok, f = pcall(function() -- anything unexpected in the settings: leave the lights as built
			local saved = ugs.SavedQualityLevel
			if saved == Enum.SavedQualitySetting.Automatic then
				local touch = (UIS.TouchEnabled and not UIS.KeyboardEnabled) or plr:GetAttribute("DevTouch") ~= nil
				return touch and LOW or 1
			end
			return saved.Value <= 6 and LOW or 1
		end)
		return (ok and type(f) == "number") and f or 1
	end
	local function apply(light)
		light.Brightness = (light:GetAttribute("B0") or light.Brightness) * factor
	end
	local function note(light) -- remember the built brightness on the light itself (attribute B0), once
		if light:GetAttribute("B0") == nil then light:SetAttribute("B0", light.Brightness) end
	end
	local function refresh()
		local f = wanted()
		if f == factor then return end
		factor = f
		E.vmHook.lightK = f -- PixelClient multiplies the lights it drives every frame (hub lanterns, the torch, ore glints)
		plr:SetAttribute("LightFactor", f) -- for tests
		for _, d in workspace:GetDescendants() do -- a change of level is rare: walk the world then (a weak table of Instances loses its keys to the collector)
			if d:IsA("Light") then
				note(d)
				apply(d)
			end
		end
	end

	for _, d in workspace:GetDescendants() do
		if d:IsA("Light") then note(d) end
	end
	workspace.DescendantAdded:Connect(function(d)
		if d:IsA("Light") then
			task.defer(function() -- after the builder has set its values
				note(d)
				if factor ~= 1 then apply(d) end
			end)
		end
	end)
	pcall(function() ugs:GetPropertyChangedSignal("SavedQualityLevel"):Connect(refresh) end)
	task.spawn(function() -- the changed signal did not fire in a Studio test: look again every two seconds (one enum read)
		while true do
			task.wait(2)
			refresh()
		end
	end)
	plr:GetAttributeChangedSignal("DevLowLight"):Connect(refresh)
	plr:GetAttributeChangedSignal("DevTouch"):Connect(refresh)
	refresh()

	-- directive v13 phase 5 (vault Research/Roblox Engine/First-Person Feel, Mobile Touch and Cross-Tier Lighting, section 4):
	-- on a low level the engine drops far light bounce and shadows in the caves, so big lamps leave black voids between them.
	-- In the caves, while the factor is low: every cave light reaches at most 18 studs with no shadow (short overlapping pools
	-- instead of a few giant bulbs), the ambient never sinks under a chromatic slate (40, 32, 60), and a light grade lifts the
	-- mid-tones a touch, so silhouettes and ledges stay readable. All of it is undone when the level or the place changes.
	local Lighting = game:GetService("Lighting")
	local grade = Instance.new("ColorCorrectionEffect")
	grade.Name, grade.Enabled, grade.Contrast, grade.Brightness, grade.Saturation = "LowTierGrade", false, 0.1, 0.04, 0.06
	grade.Parent = Lighting
	local FLOOR = Color3.fromRGB(40, 32, 60)
	local clamped = false
	local function clampCave(on)
		if on == clamped then return end
		clamped = on
		local caves = workspace:FindFirstChild("Caves")
		for _, d in caves and caves:GetDescendants() or {} do
			if d:IsA("PointLight") or d:IsA("SpotLight") then
				if d:GetAttribute("R0") == nil then d:SetAttribute("R0", d.Range) d:SetAttribute("S0", d.Shadows) end
				if on then d.Range, d.Shadows = math.min(d:GetAttribute("R0"), 18), false
				else d.Range, d.Shadows = d:GetAttribute("R0"), d:GetAttribute("S0") end
			end
		end
	end
	task.spawn(function()
		while true do
			task.wait(0.5)
			local low = factor < 1 and plr:GetAttribute("InCave") == true
			clampCave(low)
			grade.Enabled = low
			if low then
				local a = Lighting.Ambient
				local lifted = Color3.new(math.max(a.R, FLOOR.R), math.max(a.G, FLOOR.G), math.max(a.B, FLOOR.B))
				if lifted ~= a then Lighting.Ambient = lifted end
			end
		end
	end)
end

return M
