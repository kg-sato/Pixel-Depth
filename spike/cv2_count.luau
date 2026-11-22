-- Directive v14: build Cave v2 layers 1-4 (L1 camp mode, L2 hall mode) far away, count parts per folder and list unreached spots. Play, Server:
--   python spike/night.py lua Server @spike/cv2_count.luau
local out = {}
local mod = game.ServerScriptService.CaveV2
for _, cfg in { { 1, true, false }, { 2, false, true }, { 3, false, false }, { 4, false, false } } do
	local o = Vector3.new(6000 + cfg[1] * 900, 0, 6000)
	local ok, m = pcall(function() return (require(mod).build(workspace, o, 7, { layer = cfg[1], camp = cfg[2], hall = cfg[3] })) end)
	if ok then
		local n, byF = 0, {}
		for _, d in m:GetDescendants() do if d:IsA("BasePart") then n += 1 local f = d.Parent and d.Parent.Name or "?" byF[f] = (byF[f] or 0) + 1 end end
		local fs = {} for k, v in byF do table.insert(fs, k .. ":" .. v) end
		table.insert(out, "L" .. cfg[1] .. " parts=" .. n .. " reach=" .. tostring(m:GetAttribute("Reached")) .. " [" .. table.concat(fs, " ") .. "]")
		local miss = {} for k, v in m:GetAttributes() do if string.sub(k, 1, 6) == "Reach_" and v == false then table.insert(miss, k) end end
		if #miss > 0 then table.insert(out, "   MISSING " .. table.concat(miss, " ")) end
		m:Destroy()
	else
		table.insert(out, "L" .. cfg[1] .. " ERR " .. tostring(m))
	end
	for _, a in workspace.Terrain:GetChildren() do if a:GetAttribute("CaveV2") and a.WorldPosition.X > 5000 then a:Destroy() end end
end
return table.concat(out, " || ")
