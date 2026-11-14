-- NearFade (ReplicatedStorage.Shared.NearFade), started by PixelClient. The town's high camera hangs close to the cavern rim,
-- and a glowing wall crystal a few studs from the lens filled the edge of the screen as a flat cyan shape (Gemini read it as a
-- rendering glitch, 2026-11-14). The rim's crystals fade out for this player while the camera is within NEAR studs of them.
-- Display only.
local M = {}
local NEAR, FULL = 26, 40 -- gone inside NEAR studs, whole again beyond FULL

function M.start(E)
	local list = {}
	local function scan()
		table.clear(list)
		local hub = workspace:FindFirstChild("Hub")
		local wall = hub and hub:FindFirstChild("HollowWall")
		for _, d in wall and wall:GetChildren() or {} do
			if d:IsA("BasePart") and d.Name == "WallCrystal" then table.insert(list, d) end
		end
	end
	task.spawn(function()
		while true do
			if #list == 0 then scan() end
			local at = workspace.CurrentCamera.CFrame.Position
			for _, p in list do
				local d = (p.Position - at).Magnitude
				p.LocalTransparencyModifier = math.clamp((FULL - d) / (FULL - NEAR), 0, 1)
			end
			task.wait(0.2)
		end
	end)
end

return M
