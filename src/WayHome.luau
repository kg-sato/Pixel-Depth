-- WayHome (ReplicatedStorage.Shared.WayHome), started by PixelClient. When the objective card turns urgent in the caves
-- (the torch is dying, the bag is heavy: forgeUI.caveUrgent), a line of small embers on the floor shows the walking path
-- back to the nearer camp fire. Where the navmesh has no route (measured 2026-11-11: it has one from 16 of 29 deposit
-- spots within 200 studs) the embers follow the way this player walked in, and failing that a short straight line. Five loop grades gave "cave readability" 3: with a low torch the tunnels turn to one dark
-- wash and the way home is a guess. Seen only by this player; nothing here is trusted by the server.
local M = {}
function M.start(E)
	local RunService, Pathfinding = game:GetService("RunService"), game:GetService("PathfindingService")
	local plr, C, new, hook = E.plr, E.C, E.new, E.vmHook
	local AMBER = Color3.fromRGB(226, 128, 40) -- deep: pale amber neon bloomed to a yellow blob at the feet
	local folder = new("Folder", workspace, { Name = "WayHome" })
	local dots, pts = {}, {}
	for k = 1, 16 do
		dots[k] = new("Part", folder, { Name = "Ember", Shape = Enum.PartType.Ball, Size = Vector3.new(0.36, 0.36, 0.36), Color = AMBER, Material = Enum.Material.Neon,
			Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false, Transparency = 1 })
	end
	local path = Pathfinding:CreatePath({ AgentRadius = 2, AgentHeight = 5, AgentCanJump = true, WaypointSpacing = 5 })
	local busy, nextAt = false, 0
	local crumbs = {} -- where this player walked since leaving a camp ring: floor points 5 studs apart
	local function plan()
		local h = E.hrp()
		if busy or not h then return end
		busy = true
		local camp = C.CAVE_ORIGIN
		if (C.CAVE2_ORIGIN - h.Position).Magnitude < (camp - h.Position).Magnitude then camp = C.CAVE2_ORIGIN end
		local ok = pcall(function() path:ComputeAsync(h.Position, camp + Vector3.new(0, 3, 0)) end)
		local out = {}
		if ok and path.Status == Enum.PathStatus.Success and not plr:GetAttribute("DevNoPath") then -- DevNoPath: a Studio test hook for the fallbacks
			for _, w in path:GetWaypoints() do
				local last = out[#out]
				if (w.Position - h.Position).Magnitude > 8 and (not last or (w.Position - last).Magnitude >= 4.5) then table.insert(out, w.Position + Vector3.new(0, 0.45, 0)) end
				if #out >= #dots then break end
			end
		end
		if #out == 0 then -- no walkable route found (a drop, a jump, a bridge): the way you came, newest step first
			for i = #crumbs, 1, -1 do
				local last = out[#out]
				if (crumbs[i] - h.Position).Magnitude > 8 and (not last or (crumbs[i] - last).Magnitude >= 4.5) then table.insert(out, crumbs[i] + Vector3.new(0, 0.45, 0)) end
				if #out >= #dots then break end
			end
		end
		if #out == 0 then -- no trail either (a fall, a ride): embers straight toward camp along the floor, up to the first wall
			local dir = (camp - h.Position) * Vector3.new(1, 0, 1)
			if dir.Magnitude > 12 then
				dir = dir.Unit
				local prm = RaycastParams.new() -- not the player's own body
				prm.FilterType, prm.FilterDescendantsInstances = Enum.RaycastFilterType.Exclude, { h.Parent }
				local prev = h.Position
				for i = 1, 7 do
					local at = h.Position + dir * (4.5 + i * 4.5)
					if workspace:Raycast(prev, at - prev, prm) then break end
					local floor = workspace:Raycast(at + Vector3.new(0, 3, 0), Vector3.new(0, -14, 0), prm)
					if not floor then break end
					prev = floor.Position + Vector3.new(0, 2.5, 0)
					table.insert(out, floor.Position + Vector3.new(0, 0.45, 0))
				end
			end
		end
		pts, busy = out, false
	end
	RunService.Heartbeat:Connect(function()
		local now = os.clock()
		local hh = E.hrp()
		local hum = hh and hh.Parent:FindFirstChildOfClass("Humanoid")
		if hh and hum and plr:GetAttribute("InCave") then
			if C.campAt(hh.Position) then
				if #crumbs > 0 then crumbs = {} end
			elseif hum.FloorMaterial ~= Enum.Material.Air then
				local foot = hh.Position - Vector3.new(0, hum.HipHeight + hh.Size.Y / 2, 0)
				for i = 1, #crumbs - 2 do -- back on an old step: the loop since then is not part of the way home
					if (crumbs[i] - foot).Magnitude < 5 then
						for j = #crumbs, i + 1, -1 do crumbs[j] = nil end
						break
					end
				end
				if #crumbs == 0 or (crumbs[#crumbs] - foot).Magnitude >= 5 then
					table.insert(crumbs, foot)
					if #crumbs > 160 then table.remove(crumbs, 1) end
				end
			end
		elseif #crumbs > 0 and not plr:GetAttribute("InCave") then
			crumbs = {}
		end
		local roots = workspace:GetAttribute("RootsStirAt") -- the hourly Roots Stirring warning also says: go to camp
		local want = plr:GetAttribute("InCave") == true and hh ~= nil and not C.campAt(hh.Position)
			and ((hook.caveUrgent ~= nil and hook.caveUrgent() ~= nil) or (type(roots) == "number" and roots > workspace:GetServerTimeNow()))
		if want and now >= nextAt then
			nextAt = now + 2.5
			task.spawn(plan)
		elseif not want and #pts > 0 then
			pts = {}
		end
		for k, d in dots do
			local p = want and pts[k]
			if p then
				d.Position = p
				d.Transparency = 0.25 + 0.5 * (0.5 + 0.5 * math.sin(now * 4 - k * 0.9)) -- a pulse that runs along the line toward the camp
			elseif d.Transparency < 1 then
				d.Transparency = 1
			end
		end
	end)
end
return M
