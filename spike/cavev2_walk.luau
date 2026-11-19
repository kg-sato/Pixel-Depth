-- Cave v2 walk test (Play, Server): rebuilds CavesV2 and asks PathfindingService for a walk from camp to every spot. For a spot with
-- no path it also tries the spots on the way (the segment that breaks) and says whether the spot itself stands in open air.
local C = require(game.ReplicatedStorage.Shared.Config)
local old = workspace:FindFirstChild("CavesV2") if old then old:Destroy() end
for _, a in workspace.Terrain:GetChildren() do if a:GetAttribute("CaveV2") then a:Destroy() end end
local m = require(game.ServerScriptService.CaveV2).build(workspace, C.CAVE_V2_ORIGIN, _G.CV2_SEED or 7)
require(game.ServerScriptService.CaveProps).build(m)
task.wait(1)
local PS, T = game:GetService("PathfindingService"), workspace.Terrain
local function path(a, b) -- b may stand inside a boulder or prop: try it and eight points round it on the floor
	for k = 0, 8 do
		local t = k == 0 and b or b + Vector3.new(math.cos(k * 0.785) * 5, -1, math.sin(k * 0.785) * 5)
		local p = PS:CreatePath({ AgentRadius = 1.6, AgentHeight = 5, AgentCanJump = true, WaypointSpacing = 6 })
		pcall(function() p:ComputeAsync(a, t) end)
		if p.Status == Enum.PathStatus.Success then return true end
	end
	return false
end
local from = T.Spot_Camp.WorldPosition
local VIA = { B2 = "B1", B3 = "B2", SwallowHole = "Camp", B4 = "Cathedral", B5 = "Cathedral", SumpGate = "Cathedral" }
local out, ok = { "parts " .. m:GetAttribute("Parts") }, 0
for _, n in { "Canyon", "Cathedral", "OldTube", "SumpGate", "SwallowHole", "B1", "B2", "B3", "B4", "B5" } do
	local a = T:FindFirstChild("Spot_" .. n)
	local good = path(from, a.WorldPosition)
	if good then ok += 1 else
		local via = VIA[n] and T:FindFirstChild("Spot_" .. VIA[n])
		local air = #workspace:GetPartBoundsInRadius(a.WorldPosition, 1.2) == 0
		table.insert(out, n .. ": NO PATH (from " .. (VIA[n] or "?") .. ": " .. tostring(via and path(via.WorldPosition, a.WorldPosition)) .. ", spot in air: " .. tostring(air) .. ")")
	end
end
local vox = {}
for k, v in m:GetAttributes() do if string.sub(k, 1, 6) == "Reach_" and not v then table.insert(vox, string.sub(k, 7)) end end
table.insert(out, 1, ok .. "/10 reachable (pathfinding); voxel walk misses: " .. (#vox == 0 and "none" or table.concat(vox, ",")))
return table.concat(out, " | ")
