-- Spike: client-side cost of the world in Play (run in the Client datamodel).
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local n, total, worst = 0, 0, 0
local conn = RunService.RenderStepped:Connect(function(dt)
	n += 1
	total += dt
	worst = math.max(worst, dt)
end)
task.wait(4)
conn:Disconnect()
local parts = 0
for _, d in workspace:WaitForChild("Shafts"):GetDescendants() do
	if d:IsA("BasePart") then parts += 1 end
end
local root = workspace.Shafts:GetChildren()[1]
local function tag(t) return math.floor(Stats:GetMemoryUsageMbForTag(t)) end
local T = Enum.DeveloperMemoryTag
return string.format("fps=%.1f worst_ms=%.1f parts=%d mem_total=%d instances=%d physParts=%d gfxParts=%d server_build_ms=%s",
	n / total, worst * 1000, parts, Stats:GetTotalMemoryUsageMb(), tag(T.Instances), tag(T.PhysicsParts), tag(T.GraphicsParts),
	tostring(root and root:GetAttribute("BuildMs")))
