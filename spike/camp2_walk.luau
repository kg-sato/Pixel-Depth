-- Camp 2 walk test (server, Play): are the openings clear, and can a character walk from the landing to each room's set points?
local C = require(game.ReplicatedStorage.Shared.Config)
local PFS = game:GetService("PathfindingService")
local O = CFrame.new(C.CAVE2_ORIGIN)
local clay = workspace.Caves.Clay
local out = {}
local op = OverlapParams.new()
op.FilterDescendantsInstances = { clay }
op.FilterType = Enum.RaycastFilterType.Include
for name, b in { door = { CFrame.new(11, 7.5, -57), Vector3.new(9, 12, 5.6) }, breach = { CFrame.new(52.5, 17.5, -57), Vector3.new(14, 32, 5.6) } } do
	local hit = {}
	for _, p in workspace:GetPartBoundsInBox(O * b[1], b[2], op) do if p.CanCollide then hit[p.Name] = true end end
	local names = {}
	for n in hit do names[#names + 1] = n end
	out[#out + 1] = name .. " blocked by " .. #names .. " " .. table.concat(names, ",")
end
local from = clay.ClayLanding.Position
local bad = 0
for name, l in { gallery = Vector3.new(11, 3, -80), galleryBack = Vector3.new(11, 3, -100), dig = Vector3.new(54, 3, -68), terrace1 = Vector3.new(50, 4.4, -84), terrace2 = Vector3.new(40, 5.8, -104), kiln = Vector3.new(-10, 3, 6), golem = Vector3.new(56, 3, 0) } do
	local path = PFS:CreatePath({ AgentRadius = 2, AgentHeight = 5, AgentCanJump = true })
	path:ComputeAsync(from, O:PointToWorldSpace(l))
	local ok = path.Status == Enum.PathStatus.Success
	if not ok then bad += 1 end
	out[#out + 1] = name .. " " .. (ok and "reached" or "NO PATH")
end
out[#out + 1] = "walk test: " .. bad .. " unreachable"
return table.concat(out, " | ")
