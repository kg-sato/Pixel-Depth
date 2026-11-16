-- Experiment only (Client, in Play): a dim glowing rim on floor edges that drop away, within 90 studs of the player.
-- For an A/B of cave readability (Gemini's suggestion after the burnt-out-torch A/B, 2026-11-11). Nothing here is in the game.
-- Run again to rebuild; set workspace attribute RimOff = true first to only clear.
local old = workspace:FindFirstChild("RimTest")
if old then old:Destroy() end
if workspace:GetAttribute("RimOff") then return "cleared" end
local folder = Instance.new("Folder")
folder.Name = "RimTest"
folder.Parent = workspace
local h = game.Players.LocalPlayer.Character.HumanoidRootPart
local prm = RaycastParams.new()
prm.FilterType, prm.FilterDescendantsInstances = Enum.RaycastFilterType.Exclude, { folder, h.Parent, workspace:FindFirstChild("GloomVis"), workspace:FindFirstChild("WayHome") }
local n = 0
for _, f in workspace.Caves.Floor:GetChildren() do
	if f:IsA("BasePart") and (f.Position - h.Position).Magnitude < 90 and f.CFrame.UpVector.Y > 0.99 then
		local top = f.Position.Y + f.Size.Y / 2
		for _, e in { { Vector3.xAxis, f.Size.X, f.Size.Z }, { -Vector3.xAxis, f.Size.X, f.Size.Z }, { Vector3.zAxis, f.Size.Z, f.Size.X }, { -Vector3.zAxis, f.Size.Z, f.Size.X } } do
			local out, half, len = e[1], e[2] / 2, e[3]
			local along = Vector3.new(math.abs(out.Z), 0, math.abs(out.X))
			local runStart
			local steps = math.max(1, math.floor(len / 2))
			for i = 0, steps do
				local t = i < steps and (-len / 2 + (i + 0.5) * (len / steps)) or nil
				local drop = false
				if t then
					local edge = Vector3.new(f.Position.X, top, f.Position.Z) + out * half + along * t
					local below = workspace:Raycast(edge + out * 0.7 + Vector3.new(0, 1, 0), Vector3.new(0, -3.2, 0), prm) -- floor just outside the edge?
					local wall = workspace:Raycast(edge - out * 0.5 + Vector3.new(0, 2, 0), out * 1.4, prm) -- a wall standing on the edge?
					drop = below == nil and wall == nil
				end
				if drop and not runStart then runStart = t - len / steps / 2 end
				if (not drop) and runStart then
					local runEnd = (t and t - len / steps / 2) or len / 2
					local mid = (runStart + runEnd) / 2
					local p = Instance.new("Part")
					p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
					p.Material, p.Color = Enum.Material.Neon, Color3.fromRGB(124, 94, 66) -- round 3: a wide soft peach band that fades with distance (round 1 violet line: art fit 2; round 2 thin amber line: 4)
					p.Transparency = math.clamp(0.45 + ((Vector3.new(f.Position.X, top, f.Position.Z) + out * half + along * mid) - h.Position).Magnitude / 60, 0.45, 0.95)
					p.Size = Vector3.new(along.X > 0 and (runEnd - runStart) or 0.6, 0.06, along.Z > 0 and (runEnd - runStart) or 0.6)
					p.Position = Vector3.new(f.Position.X, top + 0.04, f.Position.Z) + out * (half - 0.31) + along * mid
					p.Parent = folder
					n += 1
					runStart = nil
				end
			end
		end
	end
end
return n .. " rim strips"
