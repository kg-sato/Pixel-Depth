-- ReplicatedStorage.Shared.Config: all tunable numbers for the Pixel Depths prototype (Game Spec v1.2).
local C = {}

-- World grid (one shaft per player, side view, one block thick)
C.B = 4 -- block size in studs
C.GAP = 0.14 -- blocks are this much smaller than the grid: the dark backing shows through as grid lines (Delve reference)
C.GRASS = Color3.fromRGB(96, 168, 70) -- grass cap on the surface row
C.COLS = 24 -- shaft width in blocks
C.LAYER_ROWS = 60 -- rows per layer
C.SHAFT_GAP = 6 -- empty blocks between two players' shafts
C.START_COL = 12 -- column of the glowing first block
C.WINDOW = true -- spike result: only rows near the player exist as Parts (false = build all 420 rows, for the perf test)
C.WIN_UP, C.WIN_DOWN, C.SURFACE_KEEP = 24, 36, 14 -- rows kept above/below the player, plus the top rows

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

-- Scripted first-30-seconds rows: [row] = {[column offset from START_COL] = kind}
-- kinds: base, ore2, ore3, gild (Gilded ore3), egg
C.START_ROWS = 6
C.START = {
	[1] = { [0] = "base" },
	[2] = { [0] = "base" },
	[3] = { [0] = "ore3" },
	[4] = { [-1] = "gild", [0] = "gild", [1] = "gild" },
	[5] = { [0] = "base" },
	[6] = { [0] = "egg" },
}
C.PREFILL = 4 -- endowed progress: the backpack starts 4/10

-- Digging
C.DIG_COOLDOWN = 0.18 -- seconds between player hits (server enforced)
C.REACH = 10.5 -- studs from the character to a block centre
-- Pickaxe ladder: Wood and Stone are part-built; the ten magical pickaxes are the Pickaxe Forge models (ServerStorage.Pickaxes)
C.PICKS = {
	{ name = "Wood Pickaxe", power = 1, cost = 0 },
	{ name = "Stone Pickaxe", power = 2, cost = 20 },
	{ name = "Heart Gem Pickaxe", power = 4, cost = 150, model = "HeartGemPickaxe" },
	{ name = "Starlight Pickaxe", power = 7, cost = 600, model = "StarlightPickaxe" },
	{ name = "Moonlit Pickaxe", power = 12, cost = 2000, model = "MoonlitPickaxe" },
	{ name = "Rose Thorn Pickaxe", power = 20, cost = 6000, model = "RoseThornPickaxe" },
	{ name = "Pearl Tide Pickaxe", power = 32, cost = 15000, model = "PearlTidePickaxe" },
	{ name = "Galaxy Pickaxe", power = 50, cost = 40000, model = "GalaxyPickaxe" },
	{ name = "Sakura Pickaxe", power = 80, cost = 100000, model = "SakuraPickaxe" },
	{ name = "Lotus Crystal Pickaxe", power = 125, cost = 250000, model = "LotusCrystalPickaxe" },
	{ name = "Royal Heart Pickaxe", power = 200, cost = 600000, model = "RoyalHeartPickaxe" },
	{ name = "Silver Wing Pickaxe", power = 320, cost = 1500000, model = "SilverWingPickaxe" },
}
C.PICK_SCALE = 0.75 -- the 3.6-stud forge models shrunk to fit the miner's hand

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
C.SAVE_STORE = "PixelDepths_v1"
C.SAVE_TEMPLATE = { gold = 0, pick = 1, pack = 1, pets = {}, best = 0, hatched = 0, pity = 0, step = 1, eggs = 0, lastSeen = 0 }

-- Layer hazards. Layer 2, Titan's Stir: after you dig, the block above may shake loose and drop one row.
-- Standing under it stuns you briefly and spills part of the bag (no damage, kid friendly).
C.STIR_LAYER = 2
C.STIR_CHANCE = 0.18
C.STIR_WARN = 1.0 -- seconds of shaking before it drops
C.STIR_STUN = 0.8
C.STIR_LOSS = 0.2 -- share of the bag spilled

-- Camp incubator: after the tutorial egg, fossil eggs go into your bag of eggs and hatch at the camp incubator
C.INCUBATOR_COL = 20 -- surface column of the incubator (the sell stand is at column 3)

-- Night Shaft (spec 5.7): your crew keeps digging while you are away; a report waits when you come back
C.NIGHT_CAP = 8 * 3600 -- seconds counted at most
C.NIGHT_MIN = 120 -- no report for shorter breaks
C.NIGHT_RATE = 0.5 -- gold per minute for each point of crew dig power per second

-- Camera (near-orthographic, tilted so block tops and sides show; movement stays on the plane)
C.CAM_FOV = 22
C.CAM_DIST = 160
C.CAM_YAW = math.rad(16) -- turn toward the right side faces
C.CAM_PITCH = math.rad(20) -- look down onto the top faces

return C
