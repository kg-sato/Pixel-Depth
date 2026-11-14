-- TownFill (ReplicatedStorage.Shared.TownFill), started by PixelClient. Fixes "the town is dark for about ten seconds after
-- loading and after every return from the caves" (seen in the tour video of 2026-11-14), and the same in the caves after
-- every arrival (measured 2026-11-14: picture brightness 19 for the first 8 s at Camp 1, then 67).
-- Nothing in our scripts changes in those seconds. The night town and the caves are lit almost only by their lamps, and the
-- engine builds lamp light up over several seconds after the camera arrives somewhere far away (a join, a ride, the lift,
-- the hearthstone). Until it has, this module lifts Lighting.Ambient to a fill of the colour the lamps give there (an
-- ambient of 240, 180, 125 alone matches the lit town, 195, 204, 170 the lit Camp 1; the fills are a little under those)
-- and fades it away as the lamps come in.
-- Config.TOWN_FILL = { color, cave, joinHold, hold, fade }: the town's and the caves' fill colour; seconds at full fill
-- after a join / after an arrival; seconds of fade.
-- A fill is asked for by a join, by the player attribute InCave changing and by the camera jumping more than 120 studs in one
-- frame. Other code saves and restores Lighting.Ambient (the forge scene, the two rides, the cave look), so this module
-- never writes while one of them runs (the fill then starts when it ends), and with no fill running it keeps the ambient at
-- the place's own value.
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local M = {}

function M.start(E)
	local plr, F = E.plr, E.C.TOWN_FILL
	if not F then return end
	local town = Lighting.Ambient -- the town's own ambient: this starts in town, before any cave
	local caveBase = E.C.CAVE_LIGHT.Lighting.Ambient
	E.vmHook.townAmbient = town
	local function scene() -- something else owns the lighting right now
		local escape = workspace:FindFirstChild("MinecartEscape") ~= nil -- its last act plays in town (the cart bursts out of the shaft): the fill runs under it
		return workspace:FindFirstChild("ForgeStage") ~= nil or workspace:FindFirstChild("MinecartRide") ~= nil or (plr:GetAttribute("Seated") == true and not escape)
			or (escape and plr:GetAttribute("InCave") == true)
	end
	local pend = F.joinHold -- a fill is wanted: its seconds at full strength
	local t0, hold, mode, last, shown
	plr:GetAttributeChangedSignal("InCave"):Connect(function() pend = math.max(pend or 0, F.hold) end)
	local function show(v)
		if shown ~= v then
			shown = v
			plr:SetAttribute("TownFill", v) -- read by a test
		end
	end
	RunService.RenderStepped:Connect(function()
		local cam = workspace.CurrentCamera
		local pos = cam.CFrame.Position
		if last and (pos - last).Magnitude > 120 then pend = math.max(pend or 0, F.hold) end
		last = pos
		if plr:GetAttribute("InMine") == true then -- the old block mines have their own look
			pend, t0 = nil, nil
			return show(0)
		end
		if scene() then return end
		local inCave = plr:GetAttribute("InCave") == true
		local base, color = inCave and caveBase or town, inCave and F.cave or F.color
		local now = os.clock()
		if pend or (t0 and mode ~= inCave) then
			hold = math.max(pend or F.hold, t0 and mode == inCave and (t0 + hold - now) or 0)
			t0, mode, pend = now, inCave, nil
		end
		if not t0 then
			if Lighting.Ambient ~= base then Lighting.Ambient = base end -- a ride or a scene may have put a filled value back
			return show(0)
		end
		local u = now - t0
		if u > hold + F.fade then
			t0 = nil
			Lighting.Ambient = base
			return show(0)
		end
		local k = u < hold and 1 or 1 - (u - hold) / F.fade
		Lighting.Ambient = base:Lerp(color, k * k * (3 - 2 * k))
		show(math.floor(k * 100))
	end)
end

return M
