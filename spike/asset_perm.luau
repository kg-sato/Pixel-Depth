-- Which asset ids fail to load? (the log line "Requester does not have permission for Asset." carries no id)
-- Run in Play: python spike/night.py lua Client @spike/asset_perm.luau
local CP = game:GetService("ContentProvider")
local props = { Sound = {"SoundId"}, Decal = {"Texture"}, Texture = {"Texture"}, MeshPart = {"MeshId", "TextureID"}, SpecialMesh = {"MeshId", "TextureId"},
	ImageLabel = {"Image"}, ImageButton = {"Image"}, Animation = {"AnimationId"}, SurfaceAppearance = {"ColorMap", "NormalMap", "RoughnessMap", "MetalnessMap"},
	ParticleEmitter = {"Texture"}, Beam = {"Texture"}, Trail = {"Texture"}, Sky = {"SkyboxBk"}, MaterialVariant = {"ColorMap", "NormalMap", "RoughnessMap"} }
local where, ids, seen = {}, {}, {} -- PreloadAsync wants Instances: with plain id strings nearly every id reports Failure
for _, root in {workspace, game.ReplicatedStorage, game.Lighting, game.Players.LocalPlayer.PlayerGui, game.SoundService, game.MaterialService, game.StarterGui} do
	for _, d in root:GetDescendants() do
		local ps = props[d.ClassName]
		if ps then for _, p in ps do
			local ok, v = pcall(function() return d[p] end)
			if ok and v ~= "" and not where[v] then where[v] = d:GetFullName() .. "." .. p if not seen[d] then seen[d] = true table.insert(ids, d) end end
		end end
	end
end
local bad = {}
CP:PreloadAsync(ids, function(id, status)
	if status ~= Enum.AssetFetchStatus.Success then table.insert(bad, id .. " [" .. status.Name .. "] " .. tostring(where[id])) end
end)
return #ids .. " instances, failed " .. #bad .. ": " .. string.sub(table.concat(bad, " ## "), 1, 3000)
