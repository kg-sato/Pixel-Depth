-- TownChronicle (ReplicatedStorage.Shared.TownChronicle), started by PixelClient. Master Directive v15 (@neochampy's Monument
-- of Life): the Deep Chronicle monolith in town (HubBuilder builds it with an empty face; PixelServer writes the model's
-- attribute Rows, a JSON list of { u = user id, n = name, d = deepest camp 0..2, e = escapes, b = bosses beaten }, every few
-- seconds). This module etches those rows into the face on this player's screen, marks this player's own line in mint and
-- writes this player's next mark at the foot of the stone. Display only.
local HttpService = game:GetService("HttpService")
local M = {}
local DEEP = { [0] = "TOWN", "CAMP 1", "KILN CAMP" }
local LAYER = { [0] = "", "L1  ", "L2  " }

function M.start(E)
	local plr = E.plr or game:GetService("Players").LocalPlayer
	local IVORY, GOLDE, MINE = Color3.fromRGB(236, 226, 204), Color3.fromRGB(255, 206, 110), Color3.fromRGB(150, 236, 210)
	local function face()
		local hub = workspace:FindFirstChild("Hub")
		local m = hub and hub:FindFirstChild("Chronicle")
		local slab = m and m:FindFirstChild("ChronicleSlab")
		return m, slab and slab:FindFirstChild("ChronicleGui")
	end
	local function count(n, one, many) n = tonumber(n) or 0 return n .. " " .. (n == 1 and one or (many or one .. "S")) end
	local function draw()
		local m, sg = face()
		if not sg then return end
		local ok, rows = pcall(HttpService.JSONDecode, HttpService, m:GetAttribute("Rows") or "[]")
		if not ok or type(rows) ~= "table" then rows = {} end
		local me
		for _, r in rows do if type(r) == "table" and r.u == plr.UserId then me = r end end -- the server lists everyone; the stone shows the first six
		for i = 1, 6 do
			local r = rows[i]
			local nameL, statL = sg:FindFirstChild("Name" .. i, true), sg:FindFirstChild("Stat" .. i, true) -- inside the padded Face frame (2026-11-27)
			if nameL and statL then
				if type(r) == "table" then
					local mine = r.u == plr.UserId
					nameL.Text = i .. ".  " .. tostring(r.n or "MINER")
					nameL.TextColor3 = mine and MINE or IVORY
					local d = math.clamp(tonumber(r.d) or 0, 0, 2)
					statL.Text = (LAYER[d] or "") .. (DEEP[d] or "TOWN") .. "  /  " .. count(r.e, "ESCAPE") .. "  /  " .. count(r.b, "BOSS", "BOSSES") -- "7 ESC" read as "GESC" (tour n1127b); slashes: the stone's font has no middot (it drew "?", tour pt1127), and pipes read as the digit 1: the thin pipes read as the digit 1 (audit 2026-11-26 text 5)
					statL.TextColor3 = mine and MINE or GOLDE
				else
					nameL.Text, statL.Text = "", ""
				end
			end
		end
		local mineL = sg:FindFirstChild("Mine", true)
		if mineL then -- this player's next mark on the stone
			local r = me
			if not r then
				mineL.Text = ""
			elseif (tonumber(r.d) or 0) < 1 then
				mineL.Text = "YOUR NEXT MARK:  REACH CAMP 1"
			elseif (tonumber(r.b) or 0) < 1 then
				mineL.Text = "YOUR NEXT MARK:  BEAT THE ROOT WARDEN"
			elseif (tonumber(r.d) or 0) < 2 then
				mineL.Text = "YOUR NEXT MARK:  REACH THE KILN CAMP"
			elseif (tonumber(r.e) or 0) < 1 then
				mineL.Text = "YOUR NEXT MARK:  ESCAPE BY MINECART"
			else
				mineL.Text = "YOUR MARK:  " .. (tonumber(r.e) or 0) .. " ESCAPES FROM THE DEEP"
			end
		end
	end
	task.spawn(function() -- the town may still be building when this starts
		local m
		for _ = 1, 90 do
			m = face()
			if m then break end
			task.wait(1)
		end
		if not m then return end
		m:GetAttributeChangedSignal("Rows"):Connect(draw)
		draw()
	end)
end

return M
