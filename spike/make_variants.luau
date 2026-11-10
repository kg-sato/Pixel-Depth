-- Glass pass (2026-11-09): create the glossy MaterialVariants in Edit mode (game scripts may not write MaterialVariant maps:
-- "lacking capability Plugin"). Run from the MCP plugin (Edit):
--   python tools/studio_live.py execute_luau --file "Games/Pixel Depth/spike/make_variants.luau" code '{"datamodel_type":"Edit"}'
-- ServerScriptService.Glossify assigns them at runtime. Re-run after a rebuild from the repo (spike/rebuild_place.sh), then save.
local MS = game:GetService("MaterialService")
local ID = { -- art/glass/tex/asset_ids.json
	white = "rbxassetid://129653169462240", black = "rbxassetid://87848805123183", flat = "rbxassetid://99622743501122",
	glass = "rbxassetid://123712911660861", low = "rbxassetid://71146495128257", mid = "rbxassetid://139294868335982",
	soft = "rbxassetid://74913937734915", wetrock = "rbxassetid://138624115205209",
}
local TEX = { -- HubBuilder TEX
	planks = 136733596332196, planks_light = 72771835460014, logs = 95402050034854, stonebrick = 98964967285250,
	cobble = 115790715717963, shingle_teal = 123617774947178, shingle_plum = 97900496468174, moss_roof = 105534931797006,
	awning = 114815078373584, plaster = 90929537651821, beam = 113295401166112, bark = 95671523543687,
	rockface = 76858268703683, leaves = 87594727710313, path = 114352826559819, iron = 134383025955872,
	grass = 133229924509191, wood_frame = 98417694570042, flagstone = 113808643905036, cobble_soft = 124222168049970, cobble_lane = 138112363793278,
}
local CLASS = {
	cobble = "low", cobble_soft = "low", cobble_lane = "low", flagstone = "low", path = "low", iron = "low",
	stonebrick = "mid", rockface = "mid", shingle_teal = "mid", shingle_plum = "mid", moss_roof = "mid", plaster = "mid",
	planks = "mid", planks_light = "mid", logs = "mid", beam = "mid", bark = "mid", wood_frame = "mid",
	awning = "soft", leaves = "soft", grass = "soft",
}
local STUDS = { 1, 2, 3, 4, 4.8, 5, 6, 8 } -- every tile size HubBuilder uses (scan 2026-11-09)
local made = 0
local function variant(name, colorMap, rough, studs)
	local v = MS:FindFirstChild(name) or Instance.new("MaterialVariant")
	v.Name, v.BaseMaterial = name, Enum.Material.SmoothPlastic
	v.ColorMap, v.RoughnessMap, v.MetalnessMap, v.NormalMap = colorMap, rough, ID.black, ID.flat
	v.StudsPerTile = studs
	v.Parent = MS
	made += 1
end
for tex, id in TEX do
	for _, st in STUDS do variant("PD_" .. tex .. "_" .. st, "rbxassetid://" .. id, ID[CLASS[tex]], st) end
end
for _, class in { "low", "mid", "soft", "glass" } do variant("PD_Gloss_" .. class, ID.white, ID[class], 4) end
local rock = MS:FindFirstChild("PixelCaveRock")
if rock then rock.RoughnessMap = ID.wetrock end -- wet, glossy cave rock
return "variants " .. made .. ", cave rock wet: " .. tostring(rock ~= nil)
