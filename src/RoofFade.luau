-- RoofFade (ReplicatedStorage.Shared.RoofFade), started by PixelClient. Directive v13 (Gemini full1121a, first-minute town 5.2:
-- "a striped awning hid the player for 80 s, no fade"): in town, whatever stands between the high camera and your miner above
-- head height (roofs, awnings, beams, tree tops) fades to see-through around the line of sight, and comes back when you step
-- out from under it. Only this player's view changes (LocalTransparencyModifier). Display only.
local RunService = game:GetService("RunService")
local M = {}
local FADE = 0.72 -- how see-through a faded piece gets
local RADIUS = 6.5 -- studs round each blocking hit that fade with it (a roof is many voxel blocks)

function M.start(E)
	local plr = E.plr
	local faded = {} -- [part] = true while faded this pass
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Include
	local last = 0
	RunService.Heartbeat:Connect(function()
		local now = os.clock()
		if now - last < 0.1 then return end
		last = now
		local hub = workspace:FindFirstChild("Hub")
		local ch = plr.Character
		local h = ch and ch:FindFirstChild("HumanoidRootPart")
		local want = {}
		if hub and h and not plr:GetAttribute("InCave") then
			rp.FilterDescendantsInstances = { hub }
			local cam = workspace.CurrentCamera.CFrame.Position
			for _, target in { h.Position + Vector3.new(0, 1.5, 0), h.Position - Vector3.new(0, 1.5, 0) } do
				local from = cam
				for _ = 1, 4 do -- step through up to four blockers along the line
					local dir = target - from
					if dir.Magnitude < 1 then break end
					local hit = workspace:Raycast(from, dir, rp)
					if not hit then break end
					if hit.Position.Y > h.Position.Y - 2 then -- anything in the line above the knees (directive v14: trophy-room pillars still blocked the view); a roof, an awning, a beam, a crown of leaves, or a tall post or wall (directive v14 tour: a trophy-house post hid 60% of the view)
						for _, p in workspace:GetPartBoundsInRadius(hit.Position, RADIUS) do
							if p:IsDescendantOf(hub) and p.Position.Y + p.Size.Y / 2 > h.Position.Y + 2.5 and p.Position.Y - p.Size.Y / 2 > h.Position.Y - 6 and p.Transparency < 1
								and (faded[p] or p.LocalTransparencyModifier < 0.01) then want[p] = true end -- a piece another script hides (NearFade, the Crew Hearth) is left alone
						end
					end
					from = hit.Position + dir.Unit * 0.3
				end
			end
			-- directive v14 (tour grade full1122c, town 5.4: "dark pitched roofs slice through the lower viewport"): roof pieces close in front
			-- of the high camera fade too, even when they do not cover the miner
			local camCF = workspace.CurrentCamera.CFrame
			local reach = (h.Position - cam).Magnitude * 0.85 -- directive v14 (tour full1122d: the refinery roof still covered the lower left): rays through the lower
			for _, sy in { 0.62, 0.78, 0.93 } do -- screen; whatever they hit in front of the miner fades with its neighbours
				for _, sx in { 0.1, 0.3, 0.5, 0.7, 0.9 } do
					local vp = workspace.CurrentCamera.ViewportSize
					local ray = workspace.CurrentCamera:ViewportPointToRay(vp.X * sx, vp.Y * sy)
					local hit = workspace:Raycast(ray.Origin, ray.Direction * reach, rp)
					if hit and hit.Position.Y > h.Position.Y - 1 then -- from the waist: tree trunks and tall posts in front of the miner (full1122f 37-57 s) are hit low
						for _, p in workspace:GetPartBoundsInRadius(hit.Position, RADIUS) do
							if p:IsDescendantOf(hub) and p.Transparency < 1 and p.Position.Y - p.Size.Y / 2 > h.Position.Y - 6 and p.Position.Y + p.Size.Y / 2 > h.Position.Y + 2.5
								and (faded[p] or p.LocalTransparencyModifier < 0.01) then want[p] = true end
						end
					end
				end
			end
			for _, p in workspace:GetPartBoundsInRadius(cam, 26) do
				if p:IsDescendantOf(hub) and p.Transparency < 1 and p.Position.Y - p.Size.Y / 2 > h.Position.Y + 3
					and camCF.LookVector:Dot(p.Position - cam) > 0 and (faded[p] or p.LocalTransparencyModifier < 0.01) then want[p] = true end
			end
		elseif h and plr:GetAttribute("InCave") then -- tour views full1122e (Camp 1 crew station, 3/10): a rope or beam passing within
			-- 3 studs of the first-person eye sliced the screen edge to edge; thin long pieces that close fade out of the way
			local cam = workspace.CurrentCamera.CFrame.Position
			local camera = workspace.CurrentCamera
			for _, p in workspace:GetPartBoundsInRadius(cam, 3) do
				local s = p.Size
				if p.Transparency < 1 and math.min(s.X, s.Y, s.Z) <= 1.5 and math.max(s.X, s.Y, s.Z) >= 3 and not p:IsDescendantOf(ch) and not p:IsDescendantOf(camera)
					and (faded[p] or p.LocalTransparencyModifier < 0.01) then
					local lp = p.CFrame:PointToObjectSpace(cam)
					local c = Vector3.new(math.clamp(lp.X, -s.X / 2, s.X / 2), math.clamp(lp.Y, -s.Y / 2, s.Y / 2), math.clamp(lp.Z, -s.Z / 2, s.Z / 2))
					if (lp - c).Magnitude < 2.6 then want[p] = true end -- its own nearest point, not its bounding box (a long diagonal rope's box is huge)
				end
			end
		end
		for p in faded do
			if not want[p] then
				if p.Parent then p.LocalTransparencyModifier = 0 end
				faded[p] = nil
			end
		end
		for p in want do
			if not faded[p] then
				p.LocalTransparencyModifier = FADE
				faded[p] = true
			end
		end
	end)
end

return M
