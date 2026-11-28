-- CharRigLoader (ServerScriptService.CharRigLoader), started by PixelServer (2026-11-28): loads every v17 NPC character's uploaded
-- model (ids in Shared.CharRigData) into ReplicatedStorage.CharMeshes once; InsertService only runs on the server. Shared.PetVoxels
-- builds the client rigs from there (Shared.CharRigs mounts them over the placeholders).
local M = {}
function M.start()
	local RS = game:GetService("ReplicatedStorage")
	local IS = game:GetService("InsertService")
	local ok, DATA = pcall(function() return require(RS:WaitForChild("Shared"):WaitForChild("CharRigData", 10)) end)
	if not ok or type(DATA) ~= "table" then warn("CharRigLoader: no CharRigData", DATA) return end
	local folder = RS:FindFirstChild("CharMeshes") or Instance.new("Folder")
	folder.Name, folder.Parent = "CharMeshes", RS
	for name, d in DATA do
		if not folder:FindFirstChild(name) then
			local okL, got = pcall(function() return IS:LoadAsset(d.id) end)
			if okL and got then
				local m = got:FindFirstChildWhichIsA("Model") or got
				m.Name = name
				for _, p in m:GetDescendants() do
					if p:IsA("BasePart") then p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false end
				end
				m.Parent = folder
				if got ~= m then got:Destroy() end
			else
				warn("CharRigLoader: could not load", name, got)
			end
		end
	end
end
return M
