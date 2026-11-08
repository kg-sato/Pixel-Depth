-- Spike: build cost of a 7-layer diggable side-view world, Parts grid vs Terrain (Edit mode).
local W, ROWS, B = 24, 420, 4 -- 24 columns, 7 layers x 60 rows, 4-stud blocks
local Stats = game:GetService("Stats")
local out = {}
local function mem() return Stats:GetTotalMemoryUsageMb() end

-- A) Parts grid
for _, c in workspace:GetChildren() do if c.Name:match("^Spike_") then c:Destroy() end end
local m0, t0 = mem(), os.clock()
local f = Instance.new("Folder"); f.Name = "Spike_Parts"
local proto = Instance.new("Part")
proto.Anchored = true; proto.Size = Vector3.new(B, B, B); proto.Material = Enum.Material.SmoothPlastic
proto.TopSurface = Enum.SurfaceType.Smooth; proto.BottomSurface = Enum.SurfaceType.Smooth
for r = 1, ROWS do
	for c = 1, W do
		local p = proto:Clone()
		p.Color = Color3.fromHSV(0.08, 0.5, 0.35 + ((r * 7 + c * 13) % 3) * 0.06)
		p.CFrame = CFrame.new(c * B, -r * B, 0)
		p.Parent = f
	end
end
f.Parent = workspace
out.parts_build_ms = math.floor((os.clock() - t0) * 1000)
out.parts_count = #f:GetChildren()
out.parts_mem_mb = math.floor(mem() - m0)
local kids = f:GetChildren()
t0 = os.clock()
for i = 1, 200 do kids[i * 37]:Destroy() end
out.parts_dig200_ms = math.floor((os.clock() - t0) * 1000 * 100) / 100
f:Destroy()

-- B) Terrain (same grid)
m0, t0 = mem(), os.clock()
local T = workspace.Terrain
T:Clear()
T:FillBlock(CFrame.new((W + 1) * B / 2, -(ROWS + 1) * B / 2, 0), Vector3.new(W * B, ROWS * B, B), Enum.Material.Ground)
out.terrain_build_ms = math.floor((os.clock() - t0) * 1000)
out.terrain_mem_mb = math.floor(mem() - m0)
t0 = os.clock()
for i = 1, 200 do
	T:FillBlock(CFrame.new((i % W + 1) * B, -(i % ROWS + 1) * B, 0), Vector3.new(B, B, B), Enum.Material.Air)
end
out.terrain_dig200_ms = math.floor((os.clock() - t0) * 1000 * 100) / 100
T:Clear()
return game:GetService("HttpService"):JSONEncode(out)
