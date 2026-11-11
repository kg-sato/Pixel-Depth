-- CoopMining (ReplicatedStorage.Shared.CoopMining), started by PixelClient (the user's overnight directive, 2026-11-10:
-- "resonant arcs between miners on shared crystals"). The server already pays the co-op bonus when a friend works the same
-- deposit (Fx "coopBonus"); this is its look: for a second a jagged mint arc runs from the deposit to every miner within
-- 20 studs of it, with a spark at each end. Client only. Seen with one player by firing the Fx by hand; never with two.
local M = {}

function M.start(E)
	local MINT = E.MINT
	local function arc(a, b) -- a jagged line of thin neon parts from a to b, redrawn a few times, then gone
		local parts = {}
		local function draw()
			for _, p in parts do p:Destroy() end
			table.clear(parts)
			local last, n = a, 6
			for k = 1, n do
				local t = k / n
				local at = a:Lerp(b, t) + (k < n and Vector3.new(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5) * 1.6 or Vector3.zero)
				local p = Instance.new("Part")
				p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
				p.Material, p.Color, p.Size = Enum.Material.Neon, MINT, Vector3.new(0.12, 0.12, (at - last).Magnitude)
				p.CFrame = CFrame.lookAt((at + last) / 2, at)
				p.Parent = workspace:FindFirstChild("ClientFX") or workspace
				table.insert(parts, p)
				last = at
			end
		end
		task.spawn(function()
			for _ = 1, 7 do
				draw()
				task.wait(0.09)
			end
			for _, p in parts do p:Destroy() end
		end)
	end
	E.R.Fx.OnClientEvent:Connect(function(kind)
		if kind ~= "coopBonus" then return end
		local h = E.hrp()
		local deps = workspace:FindFirstChild("Caves") and workspace.Caves:FindFirstChild("Deposits")
		if not h or not deps then return end
		local best, bd
		for _, d in deps:GetChildren() do -- the deposit we just finished is the nearest one
			local c = d.PrimaryPart
			local m = c and (c.Position - h.Position).Magnitude
			if m and (not bd or m < bd) then best, bd = c, m end
		end
		if not best or bd > 20 then return end
		E.sfx("sparkle", 1.5)
		for _, pl in game:GetService("Players"):GetPlayers() do
			local r = pl.Character and pl.Character:FindFirstChild("HumanoidRootPart")
			if r and (r.Position - best.Position).Magnitude < 20 then
				arc(best.Position, r.Position + Vector3.new(0, 0.5, 0))
				if E.burst then E.burst(r.Position, Vector3.yAxis, MINT, 8) end
			end
		end
	end)
end

return M
