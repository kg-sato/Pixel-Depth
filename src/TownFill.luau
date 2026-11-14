-- TownFill (ReplicatedStorage.Shared.TownFill), started by PixelClient. Fixes "the town is dark for about ten seconds after
-- loading and after every return from the caves" (seen in the tour video of 2026-11-14).
-- Measured 2026-11-14: nothing in our scripts changes in those seconds. The night town is lit almost only by its lamps (mean
-- picture brightness 27 with the lamps out, 89 with them), and the engine builds lamp light up over several seconds after a
-- join or a teleport. Until it has, this module lifts Lighting.Ambient to a warm fill of the colour the lamps give (an ambient
-- of 240, 180, 125 alone matches the lit town; the fill is a little under it) and fades it away as the lamps come in.
-- Config.TOWN_FILL = { color, joinHold, hold, fade }: seconds at full fill after a join / after a return, then the fade.
-- Other code saves and restores Lighting.Ambient (the forge scene, the two rides, the cave look), so this module never
-- writes while one of them runs, and a watchdog puts the town's own ambient back if one of them restored a filled value.
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local M = {}

function M.start(E)
	local plr, F = E.plr, E.C.TOWN_FILL
	if not F then return end
	local base = Lighting.Ambient -- the town's own ambient: this starts in town, before any cave
	E.vmHook.townAmbient = base
	local run, active = 0, false
	local joinUntil = os.clock() + F.joinHold -- a join gets the long hold, whatever attribute settles in its first seconds
	local function inTown() return plr:GetAttribute("InCave") ~= true and plr:GetAttribute("InMine") ~= true end
	local function scene() -- something else owns the lighting right now
		local escape = workspace:FindFirstChild("MinecartEscape") ~= nil -- its last act plays in town (the cart bursts out of the shaft): the fill runs under it
		return workspace:FindFirstChild("ForgeStage") ~= nil or workspace:FindFirstChild("MinecartRide") ~= nil or (plr:GetAttribute("Seated") == true and not escape)
			or (escape and plr:GetAttribute("InCave") == true)
	end
	local function fill(hold)
		run += 1
		local me, t0 = run, os.clock()
		active = true
		local conn
		conn = RunService.RenderStepped:Connect(function()
			local u = os.clock() - t0
			if me ~= run or not inTown() or u > hold + F.fade then
				conn:Disconnect()
				if me == run then
					active = false
					if inTown() and not scene() then Lighting.Ambient = base end
				end
				return
			end
			if scene() then return end
			local k = u < hold and 1 or 1 - (u - hold) / F.fade
			Lighting.Ambient = base:Lerp(F.color, k * k * (3 - 2 * k))
			plr:SetAttribute("TownFill", math.floor(k * 100)) -- read by a test
		end)
	end
	local function stop() -- a ride or a dive starts: hand the lighting over at the town's own value
		if active then
			run += 1
			active = false
			if inTown() then Lighting.Ambient = base end
			plr:SetAttribute("TownFill", 0)
		end
	end
	local function arrived() if inTown() then fill(math.max(F.hold, joinUntil - os.clock())) else stop() end end
	plr:GetAttributeChangedSignal("InCave"):Connect(arrived)
	plr:GetAttributeChangedSignal("InMine"):Connect(arrived)
	plr:GetAttributeChangedSignal("Seated"):Connect(function() if plr:GetAttribute("Seated") == true then stop() end end)
	if inTown() then fill(F.joinHold) end
	task.spawn(function() -- the watchdog
		while true do
			task.wait(0.5)
			if not active and inTown() and not scene() and Lighting.Ambient ~= base then Lighting.Ambient = base end
			if not active and plr:GetAttribute("TownFill") ~= 0 then plr:SetAttribute("TownFill", 0) end
		end
	end)
end

return M
