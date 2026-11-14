-- CaveEvents (ServerScriptService.CaveEvents), started by PixelServer (the user's overnight directive, 2026-11-10). Two events
-- for everyone in the caves; the server decides both and tells the clients through workspace attributes (server time):
--   * Roots Stirring (EVT-01), every hour on the hour: RootsStirAt is set C.EVENTS.rootsWarn seconds ahead. At that time every
--     miner who is in the caves but outside a camp ring is carried to Camp 1 by the roots, with nothing lost.
--   * Spore storm: every C.EVENTS.sporeEvery seconds, for C.EVENTS.sporeLen seconds, SporeStorm holds the end time. While it
--     blows, a flawless extraction pays x C.EVENTS.sporeMult (PixelServer.finishMinigame asks M.sporeMult()).
-- Studio hooks: workspace attribute DevRoots = seconds until the roots strike, DevSpore = seconds a storm lasts.
local Players = game:GetService("Players")
local C = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"))
local M = {}
local EV = C.EVENTS

function M.goldZone() -- the Perfect Strike zone's width factor: wider during a Golden Vein Surge
	local ends = workspace:GetAttribute("GoldSurge")
	return (ends and workspace:GetServerTimeNow() < ends) and EV.goldZone or 1
end
function M.sporeMult(flawless)
	local ends = workspace:GetAttribute("SporeStorm")
	return (flawless and ends and workspace:GetServerTimeNow() < ends) and EV.sporeMult or 1
end

function M.init(ctx)
	local function sweep()
		local landing = ctx.landing()
		if not landing then return end
		local n = 0
		for _, plr in Players:GetPlayers() do
			local s, hrp = ctx.data[plr], ctx.hrpOf(plr)
			if s and hrp and plr:GetAttribute("InCave") and not C.campAt(hrp.Position) and not ctx.busy(plr) then
				if s.mg then ctx.finish(s) end -- an open minigame pays what it earned first
				n += 1
				hrp.AssemblyLinearVelocity = Vector3.zero
				hrp.CFrame = landing.CFrame + Vector3.new((n % 3 - 1) * 4, 3, math.floor(n / 3) * 4)
				ctx.fx:FireClient(plr, "rootsSweep")
				if ctx.analytics then ctx.analytics.event(s, "RootsSwept") end
			end
		end
	end
	task.spawn(function()
		local rootsAt, sporeAt = nil, workspace:GetServerTimeNow() + EV.sporeFirst
		local surgeAt = workspace:GetServerTimeNow() + EV.surgeFirst
		local goldAt = workspace:GetServerTimeNow() + EV.goldFirst
		workspace:SetAttribute("SporeAt", sporeAt) -- the next start of each event, for the countdown pills (Shared.RetentionTimers)
		workspace:SetAttribute("KilnSurgeAt", surgeAt)
		workspace:SetAttribute("GoldSurgeAt", goldAt)
		while true do
			task.wait(1)
			local now = workspace:GetServerTimeNow()
			local dev = workspace:GetAttribute("DevRoots")
			if dev then
				workspace:SetAttribute("DevRoots", nil)
				rootsAt = now + dev
				workspace:SetAttribute("RootsStirAt", rootsAt)
			elseif not rootsAt then
				local left = 3600 - os.time() % 3600 -- seconds to the next full hour
				if left <= EV.rootsWarn then
					rootsAt = now + left
					workspace:SetAttribute("RootsStirAt", rootsAt)
				end
			end
			if rootsAt and now >= rootsAt then
				sweep()
				rootsAt = nil
				task.delay(6, function() workspace:SetAttribute("RootsStirAt", nil) end)
				task.wait(8) -- past the hour mark, so the same hour does not start it again
			end
			local devS = workspace:GetAttribute("DevSpore")
			if devS then
				workspace:SetAttribute("DevSpore", nil)
				sporeAt = now
				workspace:SetAttribute("SporeStorm", now + devS)
			elseif now >= sporeAt then
				sporeAt = now + EV.sporeEvery
				workspace:SetAttribute("SporeStorm", now + EV.sporeLen)
				workspace:SetAttribute("SporeAt", sporeAt)
			end
			local ends = workspace:GetAttribute("SporeStorm")
			if ends and now >= ends then workspace:SetAttribute("SporeStorm", nil) end
			-- Kiln Surge (Camp 2's own event, phase D, 2026-11-13): every EV.surgeEvery seconds for EV.surgeLen seconds the kiln
			-- roars: every clay jar is whole again for everyone (the saved jar cooldowns are cleared) and the steam vents blow
			-- without a rest (Shared.ClayClient reads the end time KilnSurge; a higher throw only hit the roof). Studio hook: workspace attribute DevSurge = seconds it lasts.
			local devK = workspace:GetAttribute("DevSurge")
			if devK or now >= surgeAt then
				workspace:SetAttribute("DevSurge", nil)
				surgeAt = now + EV.surgeEvery
				workspace:SetAttribute("KilnSurgeAt", surgeAt)
				local len = devK or EV.surgeLen
				workspace:SetAttribute("KilnSurge", now + len)
				for _, s in ctx.data do
					if s.cool then
						for k in s.cool do if string.sub(k, 1, 3) == "jar" then s.cool[k] = nil end end
					end
				end
				ctx.fx:FireAllClients("kilnSurge", len)
			end
			-- Golden Vein Surge (directive v9): every EV.goldEvery seconds for EV.goldLen the Perfect Strike zone is EV.goldZone
			-- times as wide for everyone (PixelServer asks M.goldZone when a strike starts). Studio hook: DevGold = seconds.
			local devG = workspace:GetAttribute("DevGold")
			if devG or now >= goldAt then
				workspace:SetAttribute("DevGold", nil)
				goldAt = now + EV.goldEvery
				workspace:SetAttribute("GoldSurgeAt", goldAt)
				workspace:SetAttribute("GoldSurge", now + (devG or EV.goldLen))
				ctx.fx:FireAllClients("goldSurge", devG or EV.goldLen)
			end
			local goldEnds = workspace:GetAttribute("GoldSurge")
			if goldEnds and now >= goldEnds then workspace:SetAttribute("GoldSurge", nil) end
			local surgeEnds = workspace:GetAttribute("KilnSurge")
			if surgeEnds and now >= surgeEnds then workspace:SetAttribute("KilnSurge", nil) end
		end
	end)
end

return M
