-- v15: require every changed Shared module in Play; report the ones that fail to compile or run their body
local out = {}
for _, n in { "PetCompanion", "CrystalChimes", "GlassLift", "ToastManager", "ARSettings", "MinecartEscape", "SoulTreeUI", "DeathScreen", "RefineryFX", "RetentionTimers", "TownChronicle", "Config" } do
	local m = game.ReplicatedStorage.Shared:FindFirstChild(n)
	local ok, err = pcall(require, m)
	if not ok then table.insert(out, n .. ": " .. tostring(err)) end
end
return #out == 0 and "all ok" or table.concat(out, "\n")
