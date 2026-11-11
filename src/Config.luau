-- ReplicatedStorage.Shared.Config: all tunable numbers for the Pixel Depths prototype (Game Spec v1.2).
local C = {}

-- World (2026-11-08 v2, the user: "the lobby where you upgrade is a 3rd person birdseye, slightly behind the player,
-- once they enter the mine it switches to first person"). Each player owns a plot: the camp on the surface and a 3D
-- voxel mine under it. Only the rock surfaces you can see from the open cave around you exist as Parts (flood fill).
C.B = 4 -- block size in studs
C.MINE_W = 20 -- mine footprint in blocks (x and z)
C.LAYER_ROWS = 60 -- rows per layer
C.CRUST = 2 -- unbreakable ground rows under the camp; the mine starts below them
C.PLOT_GAP = 240 -- studs between two players' mines
C.MINE_X0 = 3000 -- the mines sit far from the shared hub (hub at the origin); the lift moves you between them
C.ENTRY = { 10, 10 } -- column and depth of the 2x2 entrance hole (cells c..c+1, d..d+1)
C.ENTRY_DROP = 3 -- open rows under the hole before the first (tutorial) block
C.VIEW_R, C.VIEW_UP, C.VIEW_DOWN = 9, 7, 9 -- flood-fill render box around the player, in blocks
C.VIEW_MAX = 3200 -- open cells visited at most per render pass
C.CAVE_START = 11 -- first mine row where natural caves can open near the entrance

-- Layers: name, subtitle, wall colour, ores {name, colour, hp multiplier, value}; ore 1 is the base block
C.LAYERS = {
	{ "Rootholm", "Root Hollow", Color3.fromRGB(46, 30, 22), {
		{ "Rootflint", Color3.fromRGB(128, 86, 54), 1, 1 }, { "Ashcoal", Color3.fromRGB(58, 54, 62), 2, 2 }, { "Kobold-copper", Color3.fromRGB(226, 128, 62), 2, 4 } } },
	{ "Titan's Rest", "Clay Caves", Color3.fromRGB(70, 32, 24), {
		{ "Titan clay", Color3.fromRGB(188, 94, 62), 1, 1 }, { "Bog-iron", Color3.fromRGB(122, 98, 86), 2, 2 }, { "Rune-tin", Color3.fromRGB(214, 214, 200), 2, 4 } } },
	{ "Glitterhall", "The Glittering Hall", Color3.fromRGB(16, 20, 46), {
		{ "Frostquartz", Color3.fromRGB(62, 82, 142), 1, 1 }, { "Bard's amethyst", Color3.fromRGB(156, 92, 206), 2, 2 }, { "Valkyrie sapphire", Color3.fromRGB(70, 146, 255), 2, 4 } } },
	{ "Muspell", "Realm of Fire", Color3.fromRGB(40, 8, 8), {
		{ "Surt shard", Color3.fromRGB(124, 32, 26), 1, 1 }, { "Fireglass", Color3.fromRGB(42, 22, 32), 2, 2 }, { "Muspell ruby", Color3.fromRGB(236, 44, 64), 2, 4 } } },
	{ "Mimir's Well", "Well of Wisdom", Color3.fromRGB(8, 36, 42), {
		{ "Mimir's pearl", Color3.fromRGB(42, 124, 134), 1, 1 }, { "Norn coral", Color3.fromRGB(242, 124, 144), 2, 2 }, { "Fatestone", Color3.fromRGB(224, 232, 242), 2, 4 } } },
	{ "Alfglow", "Home of the Dark Elves", Color3.fromRGB(28, 14, 40), {
		{ "Glowcap", Color3.fromRGB(84, 52, 114), 1, 1 }, { "Elf-jade", Color3.fromRGB(124, 224, 92), 2, 2 }, { "Spore-opal", Color3.fromRGB(244, 144, 224), 2, 4 } } },
	{ "The Great Gap", "The Yawning Void", Color3.fromRGB(6, 2, 12), {
		{ "Gap-dust", Color3.fromRGB(34, 22, 44), 1, 1 }, { "Voidcrystal", Color3.fromRGB(184, 42, 206), 2, 2 }, { "Worldheart", Color3.fromRGB(255, 222, 124), 2, 4 } } },
}
C.ORE2_CHANCE, C.ORE3_CHANCE = 0.18, 0.10
C.GILDED_CHANCE = 0.012 -- mutation chance per ore block below the start area
C.GILD_MULT = 5
C.GILD_COLOR = Color3.fromRGB(255, 208, 64)
C.EGG_CHANCE = 0.004
C.EGG_COLOR = Color3.fromRGB(240, 226, 190)

-- Scripted first-30-seconds blocks under the entrance hole: [step row] = kind for all four cells of the 2x2 column
-- (step row 1 = the first block row under the open drop). kinds: base, ore2, ore3, gild (Gilded ore3), egg
C.START_ROWS = 6
C.START = { "base", "base", "ore3", "gild", "base", "egg" }
C.PREFILL = 4 -- endowed progress: the backpack starts 4/10

-- Digging
C.DIG_COOLDOWN = 0.18 -- seconds between player hits (server enforced)
C.REACH = 13 -- studs from the character's head to a block centre
-- Pixel textures (art/pd_roblox.py, 32 px art upscaled to 256 px, uploaded 2026-11-08)
C.TEX = {
	alfglow_base0 = "rbxassetid://115448677967942",
	alfglow_base1 = "rbxassetid://116137791322669",
	alfglow_cave = "rbxassetid://119731660691538",
	alfglow_ore2 = "rbxassetid://78671331929628",
	alfglow_ore3 = "rbxassetid://122569762912059",
	alfglow_wall = "rbxassetid://124606952204558",
	amber_egg = "rbxassetid://137275619825022",
	egg = "rbxassetid://133159489355843",
	gap_base0 = "rbxassetid://86263487399020",
	gap_base1 = "rbxassetid://115434686248068",
	gap_cave = "rbxassetid://84549082803895",
	gap_ore2 = "rbxassetid://91042989913114",
	gap_ore3 = "rbxassetid://104676267101288",
	gap_wall = "rbxassetid://113995212761456",
	geode = "rbxassetid://78363054348832",
	gilded = "rbxassetid://104834810775012",
	glitter_base0 = "rbxassetid://108229779387007",
	glitter_base1 = "rbxassetid://102371739818038",
	glitter_cave = "rbxassetid://78267242360414",
	glitter_ore2 = "rbxassetid://137203044287926",
	glitter_ore3 = "rbxassetid://136573985203323",
	glitter_wall = "rbxassetid://73545759491045",
	grass = "rbxassetid://92381973212663",
	mimir_base0 = "rbxassetid://88310716788544",
	mimir_base1 = "rbxassetid://109364233169915",
	mimir_cave = "rbxassetid://103318361919949",
	mimir_ore2 = "rbxassetid://104529713147357",
	mimir_ore3 = "rbxassetid://82077890386388",
	mimir_wall = "rbxassetid://110152055952088",
	muspell_base0 = "rbxassetid://131239051548805",
	muspell_base1 = "rbxassetid://82241285691013",
	muspell_cave = "rbxassetid://106022458176030",
	muspell_ore2 = "rbxassetid://86207315038924",
	muspell_ore3 = "rbxassetid://126610860277549",
	muspell_wall = "rbxassetid://110526095462296",
	rootholm_base0 = "rbxassetid://100643173961275",
	rootholm_base1 = "rbxassetid://107682120131175",
	rootholm_cave = "rbxassetid://101267996849412",
	rootholm_ore2 = "rbxassetid://92245197400696",
	rootholm_ore3 = "rbxassetid://77865950981893",
	rootholm_wall = "rbxassetid://125225384058070",
	titan_base0 = "rbxassetid://134513044302817",
	titan_base1 = "rbxassetid://94581744877286",
	titan_cave = "rbxassetid://112349192772371",
	titan_ore2 = "rbxassetid://129226927260437",
	titan_ore3 = "rbxassetid://81273911948508",
	titan_wall = "rbxassetid://134779103740583",
	-- 3D world (art/pd_world3d.py, uploaded 2026-11-08)
	grass_top = "rbxassetid://133229924509191",
	moss_top = "rbxassetid://105099584389807",
	water_top = "rbxassetid://102263231288805",
	crack1 = "rbxassetid://132940257759186",
	crack2 = "rbxassetid://109599158075303",
	crack3 = "rbxassetid://88354204027901",
}
C.LAYER_TEX = { "rootholm", "titan", "glitter", "muspell", "mimir", "alfglow", "gap" }
C.LANTERN = { count = 3, gems = 5 } -- the lost Lamplighter lanterns at the cave shrines (one each, found once ever)
C.SHRINE_ROWS = { 22, 84, 146, 208, 270, 332, 394 } -- one hidden shrine room per layer (rows of the mine, 5x3x5 cells)

-- Caves (3D noise): caverns where the cave field is high, winding tunnels where two fields both cross zero
C.CAVE_SCALE = { 9, 6 } -- horizontal and vertical noise scale in blocks
C.CAVE_LEVEL = 0.32 -- cavern threshold (higher = fewer caverns)
C.WORM_WIDTH = 0.085 -- tunnel thickness in noise units
C.WATER_CHANCE = 0.5 -- share of cave floors in a wet zone that hold a pool
C.DECO = { mushroom = 0.16, crystal = 0.05, drip = 0.22, moss = 0.6 } -- per eligible cave cell
C.PASTEL = {
	Color3.fromRGB(255, 157, 176), Color3.fromRGB(140, 227, 192), Color3.fromRGB(201, 184, 242), Color3.fromRGB(255, 224, 138),
}

-- Pickaxe ladder v3 (the user, 2026-11-08 night): World 1 has four basecamps of six pickaxes each (Root Hollow, Clay Caves,
-- Glitterhall, Muspell), the sixth of each camp is its key pickaxe; then the five sky pickaxes are the ultra endgame.
-- Brainstorm and art lines: vault Briefs/Pickaxe Progression (2026-11-08).md, section "World 1 ladder v3". Models live in
-- ServerStorage.Pickaxes by model name; a tier without its model yet falls back to the part-built pick.
C.PICKS = {
	{ name = "Wood Pickaxe", power = 1, cost = 0, model = "WoodPickaxe" }, -- Common; Camp 1 Root Hollow
	{ name = "Stone Pickaxe", power = 2, cost = 20, model = "StonePickaxe" }, -- Common; Camp 1 Root Hollow
	{ name = "Ashcoal Pickaxe", power = 3, cost = 60, model = "AshcoalPickaxe" }, -- Common; Camp 1 Root Hollow
	{ name = "Kobold-Copper Pickaxe", power = 4, cost = 150, model = "CopperPickaxe" }, -- Common; Camp 1 Root Hollow
	{ name = "Bog-Iron Pickaxe", power = 6, cost = 350, model = "BogIronPickaxe" }, -- Common; Camp 1 Root Hollow
	{ name = "Rootheart Pickaxe", power = 8, cost = 800, model = "RootheartPickaxe" }, -- Rare; Camp 1 Root Hollow
	{ name = "Mossback Pickaxe", power = 11, cost = 2000, model = "MossbackPickaxe" }, -- Common; Camp 2 Clay Caves
	{ name = "Kiln Pickaxe", power = 14, cost = 4000, model = "KilnPickaxe" }, -- Common; Camp 2 Clay Caves
	{ name = "Rune-Tin Pickaxe", power = 18, cost = 8000, model = "RuneTinPickaxe" }, -- Rare; Camp 2 Clay Caves
	{ name = "Geode Pickaxe", power = 23, cost = 15000, model = "GeodePickaxe" }, -- Rare; Camp 2 Clay Caves
	{ name = "Fossil Pickaxe", power = 29, cost = 28000, model = "FossilPickaxe" }, -- Rare; Camp 2 Clay Caves
	{ name = "Titan Hammer Pickaxe", power = 36, cost = 50000, model = "TitanHammerPickaxe" }, -- Epic; Camp 2 Clay Caves
	{ name = "Frostquartz Pickaxe", power = 45, cost = 100000, model = "FrostquartzPickaxe" }, -- Rare; Camp 3 Glitterhall
	{ name = "Amethyst Pickaxe", power = 56, cost = 180000, model = "AmethystPickaxe" }, -- Rare; Camp 3 Glitterhall
	{ name = "Songcrystal Pickaxe", power = 70, cost = 320000, model = "SongcrystalPickaxe" }, -- Rare; Camp 3 Glitterhall
	{ name = "Sapphire Pickaxe", power = 88, cost = 560000, model = "SapphirePickaxe" }, -- Epic; Camp 3 Glitterhall
	{ name = "Prism Pickaxe", power = 110, cost = 1000000, model = "PrismPickaxe" }, -- Epic; Camp 3 Glitterhall
	{ name = "Aurora Pickaxe", power = 140, cost = 1800000, model = "AuroraPickaxe" }, -- Epic; Camp 3 Glitterhall
	{ name = "Surtshard Pickaxe", power = 175, cost = 3500000, model = "SurtshardPickaxe" }, -- Epic; Camp 4 Muspell
	{ name = "Fireglass Pickaxe", power = 220, cost = 6000000, model = "FireglassPickaxe" }, -- Epic; Camp 4 Muspell
	{ name = "Ember Pickaxe", power = 275, cost = 10000000, model = "EmberPickaxe" }, -- Epic; Camp 4 Muspell
	{ name = "Ruby Pickaxe", power = 345, cost = 17000000, model = "RubyPickaxe" }, -- Legendary; Camp 4 Muspell
	{ name = "Phoenix Pickaxe", power = 430, cost = 28000000, model = "PhoenixPickaxe" }, -- Legendary; Camp 4 Muspell
	{ name = "Sunforge Pickaxe", power = 540, cost = 45000000, model = "SunforgePickaxe" }, -- Legendary; Camp 4 Muspell
	{ name = "Starlight Pickaxe", power = 700, cost = 80000000, model = "StarlightPickaxe" }, -- Legendary; Sky (ultra endgame)
	{ name = "Moonlit Pickaxe", power = 900, cost = 130000000, model = "MoonlitPickaxe" }, -- Legendary; Sky (ultra endgame)
	{ name = "Galaxy Pickaxe", power = 1150, cost = 210000000, model = "GalaxyPickaxe" }, -- Mythic; Sky (ultra endgame)
	{ name = "Royal Heart Pickaxe", power = 1500, cost = 340000000, model = "RoyalHeartPickaxe" }, -- Mythic; Sky (ultra endgame)
	{ name = "Silver Wing Pickaxe", power = 2000, cost = 550000000, model = "SilverWingPickaxe" }, -- Secret; Sky (ultra endgame)
}
C.PICK_SCALE = 0.75 -- the 3.6-stud forge models shrunk to fit the miner's hand
-- Forge v2 (2026-11-08): coins buy the next pickaxe, gems level an owned one (LV 1 to 10). In the caves the equipped pickaxe
-- multiplies the gold value of every ore it extracts (square root of its dig power); each level adds 10% value and widens the
-- Perfect Strike gold zone by 2 degrees. Rarity per pickaxe indexes C.RARITIES (card rims, gem cost scale).
C.FORGE = { maxLv = 10, gems = { 3, 4, 6, 8, 11, 15, 20, 26, 34 }, lvValue = 0.1, lvArc = 2 }
C.PICK_RARITY = { 1, 1, 1, 1, 1, 2, 1, 1, 2, 2, 2, 3, 2, 2, 2, 3, 3, 3, 3, 3, 3, 4, 4, 4, 4, 4, 5, 5, 6 }
function C.pickValue(tier, lv) -- ore value multiplier in the caves
	return math.sqrt(C.PICKS[tier].power) * (1 + C.FORGE.lvValue * ((lv or 1) - 1))
end
function C.upgradeCost(tier, lv) -- gems to go from lv to lv + 1, nil at the max level
	local g = C.FORGE.gems[lv or 1]
	return g and math.floor(g * (1 + (C.PICK_RARITY[tier] - 1) * 0.5) + 0.5)
end
function C.strikeArc(lv) -- the Perfect Strike gold zone in degrees
	return C.DEPOSIT.arc + C.FORGE.lvArc * ((lv or 1) - 1)
end

-- Hit-timing crit (spec 5.1): a ring closes on the block every CRIT_PERIOD seconds; a deliberate tap while it is closed crits.
-- The server checks the phase on its own clock; hits less than CRIT_GAP apart (spam or hold) never crit.
C.CRIT_PERIOD = 0.9
C.CRIT_FROM = 0.75 -- phase 0.75..1 counts, plus CRIT_LATE seconds after closing (network delay)
C.CRIT_LATE = 0.1
C.CRIT_GAP = 0.3
C.CRIT_MULT = 2

C.PACKS = {
	{ name = "Pouch", cap = 10, cost = 0 },
	{ name = "Satchel", cap = 25, cost = 40 },
	{ name = "Rucksack", cap = 60, cost = 300 },
	{ name = "Ore Cart", cap = 150, cost = 2000 },
	{ name = "Dwarf Vault", cap = 400, cost = 15000 },
}

-- Mutation frenzy
C.FRENZY_TIME = 10
C.COMBO_STEP = 0.25 -- value multiplier gained per block in a frenzy

-- Eggs and crew (odds in percent, shown on the odds panel; free eggs only in the prototype)
C.RARITIES = {
	{ "Common", 60, Color3.fromRGB(190, 190, 200) },
	{ "Rare", 25, Color3.fromRGB(70, 150, 255) },
	{ "Epic", 10, Color3.fromRGB(170, 90, 240) },
	{ "Legendary", 4, Color3.fromRGB(255, 196, 40) },
	{ "Mythic", 0.9, Color3.fromRGB(255, 70, 110) },
	{ "Secret", 0.1, Color3.fromRGB(255, 255, 255) },
}
-- rarity, role, power (damage per dig), every (seconds), body colour, accent colour
C.PETS = {
	Tosk = { "Common", "Hauler", 1, 1.6, Color3.fromRGB(176, 96, 44), Color3.fromRGB(120, 255, 200) },
	Kobold = { "Common", "Digger", 1, 1.2, Color3.fromRGB(110, 128, 70), Color3.fromRGB(236, 140, 60) },
	["Kepri Scarab"] = { "Common", "Fast digger", 1, 0.9, Color3.fromRGB(70, 60, 30), Color3.fromRGB(255, 210, 80) },
	Shinemane = { "Rare", "Light", 2, 1.2, Color3.fromRGB(240, 240, 250), Color3.fromRGB(255, 240, 150) },
	Goldbristle = { "Rare", "Lucky", 2, 1.2, Color3.fromRGB(214, 160, 50), Color3.fromRGB(255, 230, 110) },
	Pixiu = { "Rare", "Hauler", 2, 1.2, Color3.fromRGB(60, 150, 110), Color3.fromRGB(255, 210, 90) },
	Glimwisp = { "Epic", "Light", 3, 1.0, Color3.fromRGB(60, 200, 170), Color3.fromRGB(180, 255, 240) },
	Selkie = { "Epic", "Oxygen", 3, 1.0, Color3.fromRGB(70, 80, 120), Color3.fromRGB(200, 220, 255) },
	Zharbird = { "Epic", "Heat-proof", 3, 1.0, Color3.fromRGB(230, 90, 30), Color3.fromRGB(255, 220, 80) },
	Fafnir = { "Legendary", "Cave-in armour", 5, 0.9, Color3.fromRGB(70, 120, 70), Color3.fromRGB(255, 200, 60) },
	Kirin = { "Legendary", "Cleanser", 5, 0.9, Color3.fromRGB(90, 160, 200), Color3.fromRGB(255, 150, 60) },
	Ouro = { "Mythic", "All-rounder", 8, 0.8, Color3.fromRGB(40, 30, 60), Color3.fromRGB(255, 90, 140) },
	Ninering = { "Secret", "Ore copier", 12, 0.7, Color3.fromRGB(240, 220, 140), Color3.fromRGB(255, 255, 255) },
}
C.PITY = 40 -- eggs without Legendary or better before the next one is guaranteed (shown on the odds panel)
C.FIRST_PET = "Kobold" -- the free tutorial egg always hatches this (strong, visible digger)
C.MAX_PETS = 3
C.HATCH_TIME = 5 -- seconds of the hatch show before the pet starts digging

-- Saving (ProfileStore; Studio without API access uses its mock store)
C.SAVE_STORE = "PixelDepths_v2" -- v2 (the user, 2026-11-08): test saves wiped for the new pickaxe ladder, gems and forge levels
-- Forging costs ore as well as coins (the user's yes, 2026-11-08; Briefs/Pickaxe Progression "Materials and the ore bank").
-- Banking at camp (or selling in town) still pays coins AND keeps each chunk in a per-ore bank; keys are "layer.ore" into
-- C.LAYERS (1.1 Rootflint, 1.2 Ashcoal, 1.3 Kobold-copper, 2.1 Titan clay, 2.2 Bog-iron, 2.3 Rune-tin, 3.x Glitterhall ...).
-- About half the ore you mine while saving the coins, so coins stay the usual last gate.
C.PICK_ORE = {
	[2] = { ["1.1"] = 8 }, -- Stone (playtest 2: the first upgrade teaches that pickaxes need ore)
	[3] = { ["1.1"] = 6, ["1.2"] = 4 }, -- Ashcoal
	[4] = { ["1.2"] = 8, ["1.3"] = 3 }, -- Kobold-Copper
	[5] = { ["2.1"] = 8, ["2.2"] = 5 }, -- Bog-Iron (chasm and grotto ore)
	[6] = { ["1.3"] = 8, ["2.2"] = 8, ["2.3"] = 3 }, -- Rootheart, Camp 1's key
	[7] = { ["2.1"] = 20, ["2.2"] = 10 }, [8] = { ["2.1"] = 30, ["2.3"] = 6 }, [9] = { ["2.2"] = 20, ["2.3"] = 12 },
	[10] = { ["2.3"] = 15, ["3.1"] = 20 }, [11] = { ["2.1"] = 60, ["3.2"] = 12 }, [12] = { ["2.3"] = 30, ["3.2"] = 20, ["3.3"] = 6 },
	[13] = { ["3.1"] = 60, ["3.2"] = 20 }, [14] = { ["3.1"] = 60, ["3.2"] = 40 }, [15] = { ["3.2"] = 60, ["3.3"] = 15 },
	[16] = { ["3.1"] = 120, ["3.3"] = 30 }, [17] = { ["3.3"] = 40, ["4.1"] = 30 }, [18] = { ["3.3"] = 60, ["4.2"] = 30, ["4.3"] = 8 },
	[19] = { ["4.1"] = 120, ["4.2"] = 40 }, [20] = { ["4.1"] = 150, ["4.2"] = 80 }, [21] = { ["4.2"] = 120, ["4.3"] = 25 },
	[22] = { ["4.2"] = 150, ["4.3"] = 50 }, [23] = { ["4.3"] = 80, ["5.1"] = 60 }, [24] = { ["4.3"] = 120, ["5.2"] = 60, ["5.3"] = 15 },
	[25] = { ["5.3"] = 60, ["3.2"] = 100 }, [26] = { ["5.3"] = 90, ["5.1"] = 300 }, [27] = { ["5.3"] = 120, ["6.3"] = 30 },
	[28] = { ["5.3"] = 160, ["4.3"] = 200 }, [29] = { ["5.3"] = 220, ["3.3"] = 200 },
}
-- ore icons for the forge's have/need chips (art/icons_soft, ChatGPT via Codex imagegen, 2026-11-09)
C.ORE_ICON = { ["1.1"] = "rbxassetid://75783670652886", ["1.2"] = "rbxassetid://78471713808749", ["1.3"] = "rbxassetid://87100596939076", ["2.1"] = "rbxassetid://100049353460587", ["2.2"] = "rbxassetid://138271387658933", ["2.3"] = "rbxassetid://84304854874096", ["3.1"] = "rbxassetid://105789721830747", ["3.2"] = "rbxassetid://105263817138186", ["3.3"] = "rbxassetid://139140232453040" }
function C.oreName(key) -- "1.2" -> "Ashcoal"
	local L, i = string.match(key, "^(%d+)%.(%d+)$")
	local layer = C.LAYERS[tonumber(L)]
	local o = layer and layer[4][tonumber(i)]
	return o and o[1] or key
end
C.SAVE_TEMPLATE = { gold = 0, gems = 0, lv = {}, equip = 0, tips = {}, ores = {}, pick = 1, pack = 1, pets = {}, best = 0, hatched = 0, pity = 0, step = 1, eggs = 0, lastSeen = 0, deepest = 0, chestDay = 0, streak = 0 }

-- Layer hazards. Layer 2, Titan's Stir: after you dig, the block above may shake loose and drop one row.
-- Standing under it stuns you briefly and spills part of the bag (no damage, kid friendly).
C.STIR_LAYER = 2
C.STIR_CHANCE = 0.18
C.STIR_WARN = 1.0 -- seconds of shaking before it drops
C.STIR_STUN = 0.8
C.STIR_LOSS = 0.2 -- share of the bag spilled

-- Daily relic chest (Miro board: non-punitive, pick 1 of 3, 24 h; a missed day only pauses the streak)
C.CHEST_GOLD = 40 -- gold per chest, times the streak (capped at 7)
-- Gems (feedback batch phase 3, 2026-11-08): the second currency. Earned in play, the server decides every grant:
-- a rare deposit, a perfect grade (Perfect Strike 3/3, FLAWLESS Vein Rush) and the daily chest (gems x streak day).
-- Spent on forge levels (C.FORGE) and on egg rolls when you have no egg.
C.GEMS = { rare = 2, perfect = 1, chest = 2 }
C.EGG_GEMS = 10 -- one egg roll with gems
-- HUD pill icons (playtest 2: "remake the icons in the bottom left to be higher quality and of the same theme"; art/icons_soft/hud_*,
-- Codex imagegen in the soft kit style, ids in art/icons_soft/asset_ids.json)
C.HUD_ICON = {
	heart = "rbxassetid://112840156135846", torch = "rbxassetid://132878882630763", flare = "rbxassetid://136155303523972",
	calm = "rbxassetid://85218255319100", uneasy = "rbxassetid://108597473207994", scared = "rbxassetid://82253085768781",
}
C.EGG_COINS = 75
-- the Egg Altar in the caves (playtest 2: "rarer ones should be found in caves ... players will need to roll for them"; board PT2_Eggs).
-- Coins only, odds shown on the altar; each egg hatches on the spot from its rarity up. Guaranteed Obsidian within `pity` rolls.
C.ALTAR = { cost = 150, pity = 10, eggs = {
	{ "Crystal", 60, 2, Color3.fromRGB(150, 210, 245) }, -- name, odds %, lowest rarity index it can hatch (C.RARITIES), colour
	{ "Gold", 30, 3, Color3.fromRGB(255, 205, 80) },
	{ "Obsidian", 10, 4, Color3.fromRGB(80, 62, 110) },
} } -- a starter egg from Maribel's stall (playtest 2: cheap eggs in town, rarer ones in the caves)
-- gem packs for Robux (ServerScriptService.Shop): id = the Developer Product id from the Creator Dashboard; 0 = not created yet
-- (the pack shows SOON). Prices are a proposal for the owner to set.
C.GEM_PACKS = { { gems = 40, robux = 49, id = 0 }, { gems = 120, robux = 129, id = 0 }, { gems = 320, robux = 299, id = 0 } }

-- Night Shaft (spec 5.7): your crew keeps digging while you are away; a report waits when you come back
C.NIGHT_CAP = 8 * 3600 -- seconds counted at most
C.NIGHT_MIN = 120 -- no report for shorter breaks
C.NIGHT_RATE = 0.5 -- gold per minute for each point of crew dig power per second

-- Cameras: bird's-eye follow camera in the camp, first person in the mine
C.CAM_FOV = 50
C.CAM_DIST = 46 -- studs from the player
C.CAM_PITCH = math.rad(52) -- looking down
C.CAM_YAW = 0 -- fixed: the camera sits south of the player looking north (toward the stations)
C.FP_FOV = 80



-- Caves (cave exploration rework; vault Projects/Pixel-_/Briefs/Cave Exploration Rework.md and Cave Rework Reference Board)
C.CAVES_ON = true -- the lift goes to the shared caves; false brings back the private block mines
C.TORCH = { time = 300, range = 26, minRange = 8 } -- full light to the dimmest glow in 5 minutes (the user, 2026-11-08); wooden torch radius 18 studs (LGT-02)
-- the minecart escape on the ride up (MinecartEscape): track length (studs), base speed (studs/s), coin bonus range;
-- the server pays only when the run took at least dist / (speed * 1.6) seconds (every boost stacked the whole way)
C.ESCAPE = { dist = 1050, speed = 30, top = 1.45, bonus = { 10, 40 } } -- top: the speed wave's peak multiplier (playtest 2 runner redesign); the server's time check uses it
-- swimming in the grotto lake (CaveSwim): seconds of air, seconds to refill, swim / rise / sink speeds (studs/s), and the share of
-- the unbanked ore lost when you pass out (the same rule as a gloomling catch)
C.SWIM = { air = 14, refill = 2.5, speed = 12, rise = 9, sink = 1.2, loss = 0.25 }
-- the Gloom (ServerScriptService.Gloom): HP, damage per BONK, share of unbanked ore lost when caught, golden shield seconds, flares
-- per dive and their reach, creep speed at UNEASY and SCARED (studs/s; you walk 16), BONK reach, daze after a BONK, seconds
-- between spawns
-- the Root Warden at Camp 1's Deep Gate (ServerScriptService.Boss): the pickaxe tier you must hold (6 = Rootheart), knots to
-- crack, the knots' Perfect Strike (zone degrees, needle period, PERFECTs out of 3 to crack one), the slam (wind-up seconds,
-- reach in studs, HP it costs), how far you may walk off, and the reward
C.BOSS = { needTier = 6, knots = 3, zone = 13, period = 0.85, perfects = 2, windup = 1.1, slamReach = 22, slamHit = 45, leash = 34, gold = 500, gems = 15 } -- slam and reward as the user's directive of 2026-11-10 set them (were 34 HP, 25 gems)
-- the Kiln Golem in the Clay Caves hall (boss 2, same fight; needs tier 12, the Titan Hammer)
C.BOSS2 = { needTier = 12, knots = 3, zone = 11, period = 0.75, perfects = 2, windup = 1.0, slamReach = 24, slamHit = 45, leash = 40, gold = 1500, gems = 30 }
C.GLOOM = { hp = 100, hit = 34, loss = 0.25, shield = 5, flares = 2, flareRange = 30, speed = { 5.5, 8 }, reach = 2.8, stun = 1.5, spawnGap = 6, grab = 3, warn = 0.8 }
-- cave events (ServerScriptService.CaveEvents): the roots' warning time, the first spore storm after server start, the gap
-- between storms, a storm's length (all seconds) and what a flawless extraction pays during one
C.EVENTS = { rootsWarn = 120, sporeFirst = 240, sporeEvery = 600, sporeLen = 180, sporeMult = 1.5 }
-- the Clay Caves hall (ServerScriptService.ClayCaves, Shared.ClayClient): the two mesa heights in studs, a jar's cooldown per
-- player (s), its coins, the odds of a relic shard, the least seconds a fossil takes to brush and its gems (once ever), the
-- steam launch speed (studs/s; 150 rises about 57 studs) and the glide's fall speed
C.CLAY = { mesa = { 40, 50 }, jarEvery = 600, jarGold = { 15, 40 }, shardOdds = 0.3, brushMin = 4, fossilGems = 3, launch = 150, glideFall = 14, eggCost = 120, echoTaps = 4, echoGold = { 20, 12 }, echoEvery = 600 } -- eggCost: the Kiln Keeper's egg (the altar in the caves rolls for 150)
C.SECRET_GEMS = 10 -- the chest on the secret ledge under the chasm bridge (once per player, ever)
C.CAMP_RING = 8.6 * 4 -- Camp 1's safe ring radius in studs (CaveBuilder ringR): inside it the torch relights and fear clears
C.CAVE_ORIGIN = Vector3.new(-3000, 0, 0) -- far from the hub and the old mines, above FallenPartsDestroyHeight (-500)
C.CAVE2_ORIGIN = Vector3.new(-3000, 0, 1200) -- Camp 2 (Clay Caves), clear of Camp 1's caves (z -56..252); the camp is not built yet
C.CAMPS = { { origin = C.CAVE_ORIGIN, ring = C.CAMP_RING }, { origin = C.CAVE2_ORIGIN, ring = C.CAMP_RING } }
function C.campAt(pos) -- which camp's safe ring holds this position (1 or 2), or nil
	for i, c in C.CAMPS do
		if Vector2.new(pos.X - c.origin.X, pos.Z - c.origin.Z).Magnitude < c.ring and math.abs(pos.Y - c.origin.Y) < 30 then return i end
	end
	return nil
end
C.MAP_VIEW = 160 -- studs across the cave minimap (HUD-01); floors show once your torchlight reaches them (fog of war)
-- Ore deposits (stage 4, refs ORE-01/02, EXT-01/02, board artboard CaveUI): crystal clusters hidden against cave walls,
-- a starburst glint every `glint` seconds. The cave piece sets the layer (deeper pieces hold later layers), depth raises
-- the rare odds. Common and uncommon ore play Perfect Strike, rare ore plays Vein Rush. The server decides all loot.
C.DEPOSIT = {
	layer = { tunnel = 1, squeeze = 1, chasm = 2, grotto = 2, mush = 3 }, -- C.LAYERS index per cave theme
	rare = 0.16, rareDeep = 0.2, uncommon = 0.34, -- ore3 chance (+rareDeep at 40 studs down), then ore2 chance
	spacing = 18, max = 40, reach = 10, glint = 3, -- studs apart, per cave, prompt distance, seconds between glints
	strikes = 3, chunks = 1, bonus = 1, strikePeriod = 1.0, arc = 15, -- Perfect Strike: swings, ore per swing, extra ore per PERFECT, needle turn (s), gold arc (deg)
	rush = { 8, 12 }, rushChunks = 4, rushBeat = 1.0, -- Vein Rush: beats, base ore, seconds per beat
	regrow = 420, -- seconds until a deposit you mined grows back for you (roadmap i75: inside the hour)
	shrines = { count = 3, minDist = 90, regrow = 3600, gold = 60, gems = 2 }, -- hidden shrines: how many, studs from camp at least, per-player regrow, coins (x3 per layer), gems
	coop = { window = 20, mult = 1.5 }, -- two players on the same deposit within 20 s: both get x1.5 ore
	nests = { count = 3, minDist = 60, regrow = 3600 }, -- egg nests in quiet nooks (playtest 2): free, once an hour per player
	gilded = { count = 2, every = 300, mult = 2, gems = 1 }, -- gilded veins: how many at a time, seconds between picks, ore x, extra gems
	frenzy = { deposits = 3, window = 60, time = 20, mult = 1.5 }, -- three deposits inside a minute: x1.5 ore for 20 s
	grades = { { "FLAWLESS", 0, 2, 3 }, { "PRISTINE", 1, 1.5, 2 }, { "STANDARD", 3, 1, 1 }, { "CHIPPED", math.huge, 0.5, 0 } }, -- name, most slips, ore multiplier, stars
}
-- Cave lighting preset, applied by the client on entering the caves and undone at camp. From the lighting video the user sent
-- (https://www.youtube.com/watch?v=adgCWET34rU): realistic style, tinted ambient so shadows keep colour, low diffuse, punchy
-- contrast with a subtle tint, a small low-threshold bloom so glows read as colour, a light depth of field for big halls.
C.CAVE_LIGHT = {
	Lighting = { LightingStyle = Enum.LightingStyle.Realistic, Ambient = Color3.fromRGB(40, 32, 60), OutdoorAmbient = Color3.fromRGB(34, 27, 54), Brightness = 0, EnvironmentDiffuseScale = 0.13, EnvironmentSpecularScale = 1, ExposureCompensation = 0.2, ShadowSoftness = 0.15 }, -- specular 0.85: the wet rock and glass ores reflect (glass pass) -- playtest 2: was 40,30,64 / 36,28,60 / 0.15 / 0.25, too bright for a cave; 2026-11-10: 28,22,40 / 24,18,36 / 0.08 / 0.05 left the tunnels and gloomlings black outside the torch (loop review), lifted part of the way back; 50,39,74 / 0.32 / fog 0.37 graded as a flat lavender room (Gemini), do not go there
	Atmosphere = { Density = 0.42, Offset = 0, Color = Color3.fromRGB(52, 36, 86), Decay = Color3.fromRGB(26, 16, 46), Glare = 0, Haze = 0.8 },
	Bloom = { Intensity = 0.55, Size = 22, Threshold = 0.95 }, -- was 0.7 / 30: neon and lit floors smeared into glare (VFX note 2026-11-08)
	ColorCorrection = { Brightness = 0.03, Contrast = 0.2, Saturation = 0.12, TintColor = Color3.fromRGB(240, 230, 255) },
	DepthOfField = { FarIntensity = 0.22, FocusDistance = 36, InFocusRadius = 40, NearIntensity = 0 },
}

return C
