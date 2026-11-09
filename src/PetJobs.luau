-- PetJobs (ReplicatedStorage.Shared.PetJobs): what your crew pets do in the caves (roadmap phase 7; Lore and Gameplay Plan A9).
-- Server and client both call perks(names) with the crew's pet names, so the server's rules and the HUD always agree.
-- Every crew pet carries a little light of its own; each one helps with one cave job. With several pets the best of each wins
-- (or they add up, for ore). v1 notes: Goldbristle's "glints from farther" and Kirin's "fear drains while you stand still"
-- are simplified to +1 ore on rare deposits and fear rising 30% slower; tune in playtests.
local M = {}

local JOBS = {
	Tosk = { loss = 0.20 }, -- gloomlings grab less when you are caught
	Pixiu = { loss = 0.15 },
	Kobold = { ore = 1 }, -- +1 ore on every finished deposit
	["Kepri Scarab"] = { strike = 1.1 }, -- the Perfect Strike needle turns 10% slower
	Shinemane = { light = 4 }, -- torch radius +4 studs
	Goldbristle = { rareOre = 1 }, -- lucky: rare deposits give +1 ore
	Glimwisp = { torch = 1.25 }, -- the torch dims 20% slower (lasts 1.25x as long)
	Selkie = { air = 1.5 }, -- air +50% in the grotto lake
	Zharbird = { fear = 0.85 }, -- fear rises 15% slower
	Fafnir = { block = true }, -- blocks the first gloomling catch of each dive
	Kirin = { fear = 0.7 }, -- calms you: fear rises 30% slower
	Ouro = { loss = 0.22, torch = 1.1, fear = 0.95, air = 1.2 }, -- a little of every job
	Ninering = { ninth = true }, -- every 9th deposit pays double
}
M.JOBS = JOBS

-- one line per pet for the HUD and the pet cards
M.TEXT = {
	Tosk = "Gloomlings grab 20% instead of 25%", Pixiu = "Gloomlings grab 15% instead of 25%", Kobold = "+1 ore from every deposit",
	["Kepri Scarab"] = "Perfect Strike needle 10% slower", Shinemane = "Torch light +4 studs", Goldbristle = "+1 ore from rare deposits",
	Glimwisp = "Torch lasts 25% longer", Selkie = "50% more air under water", Zharbird = "Fear rises 15% slower",
	Fafnir = "Blocks the first catch each dive", Kirin = "Fear rises 30% slower", Ouro = "A little of every job", Ninering = "Every 9th deposit pays double",
}

function M.perks(names)
	local p = { loss = nil, ore = 0, rareOre = 0, strike = 1, light = 0, torch = 1, air = 1, fear = 1, block = false, ninth = false }
	for _, n in names or {} do
		local j = JOBS[n]
		if j then
			if j.loss then p.loss = math.min(p.loss or 1, j.loss) end
			p.ore += j.ore or 0
			p.rareOre += j.rareOre or 0
			p.strike = math.max(p.strike, j.strike or 1)
			p.light = math.max(p.light, j.light or 0)
			p.torch = math.max(p.torch, j.torch or 1)
			p.air = math.max(p.air, j.air or 1)
			p.fear = math.min(p.fear, j.fear or 1)
			p.block = p.block or j.block == true
			p.ninth = p.ninth or j.ninth == true
		end
	end
	return p
end

return M
