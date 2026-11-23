-- v15: free spots for the Deep Chronicle monolith (a 12 x 9 footprint, 14 tall) round the plaza and the trophy terrace walkway
local hub = workspace.Hub
local O = hub:GetAttribute("Origin") or Vector3.new(0, 0, 0)
local soft = {}
for _, d in hub:GetDescendants() do
	if d:IsA("BasePart") and (d.Name == "Flower" or d.Name == "Tuft" or d.Name == "EdgeTuft" or d.Name == "Stem" or d.Name == "Bloom" or d.Name == "Grass" or d.Name == "Pebble") then table.insert(soft, d) end
end
local op = OverlapParams.new() op.FilterType = Enum.RaycastFilterType.Exclude op.FilterDescendantsInstances = soft
local rp = RaycastParams.new() rp.FilterType = Enum.RaycastFilterType.Exclude rp.FilterDescendantsInstances = soft
local out = {}
for x = -30, 44, 3 do for z = -48, 10, 3 do
	local top = Vector3.new(x, 40, z) + O
	local hit = workspace:Raycast(top, Vector3.new(0, -60, 0), rp)
	if hit then
		local g = hit.Position.Y
		local n = 0
		for _, d in workspace:GetPartBoundsInBox(CFrame.new(Vector3.new(x, g + 7.6, z) + O), Vector3.new(12, 14, 9), op) do
			if not d:FindFirstAncestorOfClass("Model") or not d:FindFirstAncestorOfClass("Model"):FindFirstChildOfClass("Humanoid") then n += 1 end
		end
		if n == 0 then table.insert(out, ("%d,%d g=%.1f %s"):format(x, z, g, hit.Instance.Name)) end
	end
end end
return #out .. " free: " .. table.concat(out, " | ")
