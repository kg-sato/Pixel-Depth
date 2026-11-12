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
end

return M
