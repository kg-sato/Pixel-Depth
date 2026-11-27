-- Cave mesh audit (Server, Play; read only). Town and Mine Map Overhaul 2026-11-27 gate 3 / Whole Game Polish audit gate 2:
--   floating  deposits whose foot has no cave rock within 0.15 studs below it
--   zip       props or decor within 6 studs of a zip line's ride path (the rope, the rider 3 studs under it)
--   water     terrain water voxels in the caves (the cave pools are real water since 2026-11-27) and Glass "StreamWater" slabs left
--   parts     BaseParts under workspace.Caves (budget 12,000)
--   pebble    cave parts still in Enum.Material.Pebble
--   lift      loose small cubes in the glass lift shaft (under 2 studs, not part of a model or FX)
local caves = workspace:FindFirstChild("Caves")
if not caves then return "no caves" end
local GS = require(game:GetService("ServerScriptService"):WaitForChild("GroundSnap"))
local rp = RaycastParams.new()
rp.FilterType = Enum.RaycastFilterType.Include
rp.FilterDescendantsInstances = GS.solids(caves)
local floating, eg = 0, {}
local dep = caves:FindFirstChild("Deposits")
for _, d in dep and dep:GetChildren() or {} do
	if d:IsA("Model") and #d:GetChildren() > 0 then
		local cf, size = d:GetBoundingBox()
		local bottom = cf.Position.Y - size.Y / 2
		local core = d.PrimaryPart and d.PrimaryPart.Position or cf.Position
		local hit = workspace:Raycast(Vector3.new(core.X, bottom + 0.5, core.Z), Vector3.new(0, -0.65, 0), rp)
		if not hit then
			floating += 1
			if #eg < 5 then table.insert(eg, string.format("%s(%.0f,%.0f,%.0f)", tostring(d:GetAttribute("OreName")), core.X, bottom, core.Z)) end
		end
	end
end
local zip = 0
for _, seg in GS.ropes(caves) do
	for _, fname in { "Props", "Decor" } do
		local f = caves:FindFirstChild(fname)
		for _, p in f and f:GetDescendants() or {} do
			if p:IsA("BasePart") and p.Transparency < 1 and GS.distToSeg(p.Position, seg[1], seg[2]) < 6 then zip += 1 end
		end
	end
end
local parts, pebble, slabs, geo = 0, 0, 0, 0
local GEO = { Walls = true, Floor = true, Ramps = true, Decor = true, Deposits = true, Clay = true, Landmark = true, Lights = true, Moss = true, RimGuides = true, V2Water = true } -- the cave budget's own count (spike/cv2_count.luau: L1 + L2 + the Clay hall)
for _, p in caves:GetDescendants() do
	if p:IsA("BasePart") then
		parts += 1
		local top = p
		while top.Parent ~= caves do top = top.Parent end
		if GEO[(top.Name:gsub("^L2_", ""))] then geo += 1 end
		if p.Material == Enum.Material.Pebble then pebble += 1 end
		if p.Name == "StreamWater" then slabs += 1 end
	end
end
local water = 0
do -- count terrain water voxels over the cave regions (Camp 1's caves and the Clay layer)
	local C = require(game:GetService("ReplicatedStorage").Shared.Config)
	for _, o in { C.CAVE_ORIGIN, C.CAVE2_ORIGIN } do
		local r = Region3.new(o - Vector3.new(256, 96, 256), o + Vector3.new(256, 64, 256)):ExpandToGrid(4)
		local ok, mats = pcall(function() return (workspace.Terrain:ReadVoxels(r, 4)) end)
		if ok then
			local sz = mats.Size
			for x = 1, sz.X do for y = 1, sz.Y do for z = 1, sz.Z do if mats[x][y][z] == Enum.Material.Water then water += 1 end end end end
		end
	end
end
local lift = 0
for _, p in workspace:GetDescendants() do
	if p:IsA("BasePart") and p.Parent and p.Parent.Name == "GlassLift" and p.Size.Magnitude < 2 * math.sqrt(3) and not p:GetAttribute("FX") then lift += 1 end
end
return string.format("floating %d  zip %d  water %d voxels  slabs %d  caveParts %d (budget 12000; all incl. props %d)  pebble %d  liftCubes %d  snapMoved %s pruned %s zipCleared %s | %s",
	floating, zip, water, slabs, geo, parts, pebble, lift, tostring(dep and dep:GetAttribute("SnapMoved")), tostring(dep and dep:GetAttribute("SnapPruned")), tostring(caves:GetAttribute("ZipCleared")), table.concat(eg, " "))
