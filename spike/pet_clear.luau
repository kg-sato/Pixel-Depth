-- v15: stand so the lead pet's view slot falls inside each Clay column in turn and report whether the pet ends up in rock.
local plr = game.Players.LocalPlayer
local h = plr.Character.HumanoidRootPart
local clay = workspace.Caves.Clay
local pet
for _, m in workspace:GetDescendants() do if m:IsA('Model') and m:GetAttribute('Pet') then pet = m break end end
if not pet then return 'no pet' end
local cols = {}
for _, d in clay:GetDescendants() do if d:IsA('BasePart') and d.Name == 'Column' then table.insert(cols, d) end end
local rp = RaycastParams.new() rp.FilterType = Enum.RaycastFilterType.Exclude rp.FilterDescendantsInstances = { plr.Character, pet }
local op = OverlapParams.new() op.FilterType = Enum.RaycastFilterType.Exclude op.FilterDescendantsInstances = { plr.Character, pet, workspace.CurrentCamera }
local out, bad, tried = {}, 0, 0
for ci = 1, math.min(#cols, 12) do
	local col = cols[ci]
	local fl = workspace:Raycast(col.Position + Vector3.new(12, 0, 0), Vector3.new(0, -80, 0), rp)
	local floorY = fl and fl.Position.Y or (col.Position.Y - 34.9)
	local target = Vector3.new(col.Position.X, floorY + 3.6, col.Position.Z)
	for a = 0, 7 do
		local L = Vector3.new(math.cos(a * math.pi / 4), 0, math.sin(a * math.pi / 4))
		local R = L:Cross(Vector3.yAxis)
		local cp = target + 9 * R + Vector3.new(0, 1, 0) - 13.8 * L
		local ground = workspace:Raycast(cp, Vector3.new(0, -12, 0), rp)
		local clearPath = not workspace:Raycast(target + (cp - target).Unit * 3.5, cp - target - (cp - target).Unit * 3.5, rp)
		local roomy = #workspace:GetPartBoundsInBox(CFrame.new(cp - Vector3.new(0, 1.5, 0)), Vector3.new(3, 4, 3), op) == 0
		if ground and clearPath and roomy then
			tried += 1
			h.CFrame = CFrame.lookAt(ground.Position + Vector3.new(0, 3, 0), ground.Position + Vector3.new(0, 3, 0) + L)
			h.AssemblyLinearVelocity = Vector3.zero
			task.wait(0.15)
			local cam0 = workspace.CurrentCamera
			cam0.CFrame = CFrame.lookAt(cam0.CFrame.Position, cam0.CFrame.Position + L) -- first person keeps the camera's own yaw: turn it to face L
			task.wait(1.6)
			local want = cam0.CFrame:PointToWorldSpace(Vector3.new(-9, -1, -13.8))
			local cf = pet.PrimaryPart.CFrame -- 2026-11-27: the model's box held stray effect cubes, so each visible body part is checked instead
			local inRock = {}
			for _, bp in pet:GetDescendants() do
				if bp:IsA('BasePart') and bp.Transparency < 0.98 and string.sub(bp.Name, 1, 3) ~= 'Fx_' then
					for _, q in workspace:GetPartBoundsInBox(bp.CFrame, bp.Size * 0.7, op) do if q.CanCollide and q.Transparency < 1 then inRock[q.Name] = true end end
				end
			end
			local names = {} for n in inRock do table.insert(names, n) end
			if #names > 0 then bad += 1 end
			local cam = workspace.CurrentCamera
			local rel = cam.CFrame:PointToObjectSpace(cf.Position)
			table.insert(out, ('col %d dir %d: %s (slot %.1f / pet %.1f studs from column axis; in camera space %.1f %.1f %.1f; cam-head %.1f; mode %s)'):format(ci, a, #names > 0 and ('IN ' .. table.concat(names, ',')) or 'clear', (Vector3.new(want.X, 0, want.Z) - Vector3.new(col.Position.X, 0, col.Position.Z)).Magnitude, (Vector3.new(cf.Position.X, 0, cf.Position.Z) - Vector3.new(col.Position.X, 0, col.Position.Z)).Magnitude, rel.X, rel.Y, rel.Z, (cam.CFrame.Position - h.Position).Magnitude, tostring(plr.CameraMode)))
			break
		end
	end
end
return ('tried %d, in rock %d\n'):format(tried, bad) .. table.concat(out, '\n')
