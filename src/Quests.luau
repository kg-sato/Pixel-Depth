-- Quests (ReplicatedStorage.Shared.Quests): the quest data and its rules, shared by the server (which counts, pays and saves)
-- and the client (Shared.QuestUI, which only draws). The user, 2026-11-10: "start working on the quest menu as well as the
-- tutorial". v1: the tutorial IS the story chain (one quest at a time, in order, each pointing at a place) plus three daily
-- quests picked from a pool by the day number, the same for everyone.
--   a player's quests: { story = index of the open story quest, sp = its progress, day = day number, d = { id = progress },
--                        c = { id = true once claimed }, np = progress already made on the NEXT story quest while the
--                        open one waits to be claimed }   (string keys and numbers only: DataStore-safe)
local M = {}

-- ev: the server event that counts (PixelServer calls quest(s, ev, n)); point: where the guide arrow leads (QuestUI)
M.STORY = {
	{ id = "ride", title = "Ride the minecart", hint = "Ride the minecart down!", ev = "ride", n = 1, coins = 20, point = "cart" },
	{ id = "first", cave = true, title = "Extract your first ore", hint = "Find a glinting vein and mine it!", ev = "extract", n = 1, coins = 30, point = "deposit" },
	{ id = "three", cave = true, title = "Extract 3 more deposits", hint = "Mine 3 more glinting veins!", ev = "extract", n = 3, coins = 40, point = "deposit" },
	{ id = "sell", title = "Sell ore at the market", hint = "Ride up and sell ore to Pip!", ev = "sell", n = 1, coins = 50, point = "sell" },
	{ id = "forge", title = "Forge a new pickaxe", hint = "Forge a new pickaxe at Bolt's!", ev = "buy", n = 1, gems = 5, point = "forge" },
	{ id = "hatch", title = "Hatch an egg", hint = "Hatch an egg at the hatchery!", ev = "hatch", n = 1, gems = 5, point = "egg" },
	{ id = "chest", title = "Open the daily relic chest", hint = "Open the relic chest at spawn!", ev = "chest", n = 1, coins = 60, point = "chest" },
	-- chapter 2, the Clay Caves (2026-11-10 night). Since 2026-11-27 each points at its place too (Shared.QuestUI finds the nearest
	-- prompt with that attribute in the caves; up in town it leads to the cart): the Warden's gate, the way down, a jar, an echo
	-- wall, the geode anvil, a fossil slab
	{ id = "warden", title = "Calm the Root Warden", hint = "Forge Rootheart, calm the Warden!", ev = "warden", n = 1, gems = 10, point = "warden" },
	{ id = "clay", cave = true, title = "Go down to the Clay Caves", hint = "Go down past the Deep Gate!", ev = "clay", n = 1, coins = 100, point = "clay" },
	{ id = "jars", cave = true, title = "Smash 3 clay jars", hint = "Smash 3 jars in the Clay Caves!", ev = "jar", n = 3, coins = 120, point = "jars" },
	{ id = "echo", cave = true, title = "Win Echo Tap", hint = "Tap an echo wall, find the drum!", ev = "echo", n = 1, coins = 120, point = "echo" },
	{ id = "geode", cave = true, title = "Crack a geode", hint = "Crack a geode at the kiln anvil!", ev = "geode", n = 1, gems = 6, point = "geode" },
	{ id = "fossil", cave = true, title = "Brush a fossil clean", hint = "Gently brush a pale wall slab!", ev = "fossil", n = 1, gems = 6, point = "fossil" },
}
M.DAILY = {
	{ id = "d_extract", title = "Extract 6 deposits", ev = "extract", n = 6, coins = 120 },
	{ id = "d_perfect", title = "Get 2 perfect grades", ev = "perfect", n = 2, gems = 4 },
	{ id = "d_coins", title = "Earn 300 coins selling ore", ev = "coins", n = 300, gems = 3 },
	{ id = "d_ride", title = "Ride down 2 times", ev = "ride", n = 2, coins = 80 },
	{ id = "d_escape", title = "Escape by minecart", ev = "escape", n = 1, coins = 100 },
	{ id = "d_hatch", title = "Hatch an egg", ev = "hatch", n = 1, gems = 3 },
}

function M.day(now) return math.floor((now or os.time()) / 86400) end

function M.dailies(day) -- today's three
	local r, pool, out = Random.new(day), table.clone(M.DAILY), {}
	for i = 1, 3 do out[i] = table.remove(pool, r:NextInteger(1, #pool)) end
	return out
end

function M.clean(q, day) -- whatever was saved, made safe; a new day clears the daily progress
	q = type(q) == "table" and q or {}
	local o = { story = math.clamp(math.floor(tonumber(q.story) or 1), 1, #M.STORY + 1), sp = math.max(math.floor(tonumber(q.sp) or 0), 0), np = math.max(math.floor(tonumber(q.np) or 0), 0), day = day, d = {}, c = {} }
	if tonumber(q.day) == day then
		for _, d in M.DAILY do
			local p = type(q.d) == "table" and tonumber(q.d[d.id])
			if p then o.d[d.id] = math.clamp(math.floor(p), 0, d.n) end
			if type(q.c) == "table" and q.c[d.id] == true then o.c[d.id] = true end
		end
	end
	return o
end

function M.bump(q, ev, n) -- count an event; true when something moved
	local changed = false
	local st = M.STORY[q.story]
	if st and st.ev == ev and q.sp < st.n then
		q.sp = math.min(q.sp + n, st.n)
		changed = true
	elseif st then -- done but not claimed yet: what you do meanwhile counts for the next quest (Gemini loop review, 2026-11-10)
		local nx = M.STORY[q.story + 1]
		if nx and nx.ev == ev and (q.np or 0) < nx.n then
			q.np = math.min((q.np or 0) + n, nx.n)
			changed = true
		end
	end
	for _, d in M.dailies(q.day) do
		local p = q.d[d.id] or 0
		if d.ev == ev and p < d.n then
			q.d[d.id] = math.min(p + n, d.n)
			changed = true
		end
	end
	return changed
end

function M.guide(q) -- the story quest to work on now and its progress: a finished, unclaimed one already leads to the next
	local st = M.STORY[q.story]
	if st and q.sp >= st.n then return M.STORY[q.story + 1], q.np or 0 end
	return st, q.sp
end

function M.claim(q, id) -- the finished, unclaimed quest with this id (its reward is the caller's to pay), or nil
	local st = M.STORY[q.story]
	if st and st.id == id and q.sp >= st.n then
		q.story += 1
		q.sp, q.np = q.np or 0, 0
		return st
	end
	for _, d in M.dailies(q.day) do
		if d.id == id and (q.d[id] or 0) >= d.n and not q.c[id] then
			q.c[id] = true
			return d
		end
	end
	return nil
end

do -- self-check: the rules above
	local q = M.clean(nil, 5)
	assert(q.story == 1 and not M.claim(q, "ride"))
	assert(M.bump(q, "ride", 1) and M.claim(q, "ride").coins == 20 and q.story == 2 and not M.claim(q, "ride"))
	M.bump(q, "extract", 1) -- quest 2 done, not claimed: two more extracts count for quest 3
	assert(M.guide(q).id == "three" and M.bump(q, "extract", 2) and q.np == 2)
	assert(M.claim(q, "first") and q.story == 3 and q.sp == 2 and q.np == 0 and M.guide(q).id == "three")
	local d = M.dailies(5)[1]
	M.bump(q, d.ev, d.n)
	assert(M.claim(q, d.id) == d and not M.claim(q, d.id))
	assert(M.clean(q, 6).c[d.id] == nil and M.clean(q, 5).c[d.id] == true and M.clean({ story = 99 }, 1).story == #M.STORY + 1)
end

return M
