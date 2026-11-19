-- Physical walk (Play, Server): the player's character walks from one cave v2 point to the next with Humanoid:MoveTo, jumping when it
-- stalls, and reports how close it got. _G.WALK = { {x,z}, ... } in local studs (origin = Config.CAVE_V2_ORIGIN).
local C = require(game.ReplicatedStorage.Shared.Config)
local o = C.CAVE_V2_ORIGIN
local function dip(x) return -x * math.tan(math.rad(6)) end
local function floorAt(x, z, y)
	local r = workspace:Raycast(o + Vector3.new(x, (y or 0) + dip(x) + 8, z), Vector3.new(0, -24, 0))
	return r and r.Position
end
local ch = game.Players:GetPlayers()[1].Character
local hum, hrp = ch:FindFirstChildOfClass("Humanoid"), ch.HumanoidRootPart
hrp.Anchored = false
local pts = _G.WALK
local out = {}
local start = floorAt(pts[1][1], pts[1][2], pts[1][3])
ch:PivotTo(CFrame.new(start + Vector3.new(0, 3, 0)))
task.wait(1)
for i = 2, #pts do
	local goal = floorAt(pts[i][1], pts[i][2], pts[i][3])
	if not goal then table.insert(out, i .. ":nofloor") break end
	local t0 = os.clock()
	local last, stuck = hrp.Position, 0
	while os.clock() - t0 < 10 do
		hum:MoveTo(goal)
		task.wait(0.25)
		local flat = Vector3.new(hrp.Position.X - goal.X, 0, hrp.Position.Z - goal.Z).Magnitude
		if flat < 3 then break end
		if (hrp.Position - last).Magnitude < 0.3 then stuck += 1 if stuck % 2 == 0 then hum.Jump = true end else stuck = 0 end
		last = hrp.Position
	end
	local miss = Vector3.new(hrp.Position.X - goal.X, 0, hrp.Position.Z - goal.Z).Magnitude
	table.insert(out, ("%d:%s(%.0f)"):format(i, miss < 3 and "ok" or "STUCK", miss))
	if miss >= 3 then table.insert(out, "at " .. tostring(hrp.Position - o)) break end
end
return table.concat(out, " ")
