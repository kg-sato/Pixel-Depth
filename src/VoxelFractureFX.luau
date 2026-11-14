-- VoxelFractureFX (ReplicatedStorage.Shared.VoxelFractureFX), started by PixelClient. Directive v9 (2026-11-13), cutscene 6:
-- a PERFECT strike breaks glass off the ore. On every PERFECT (Fx "mgStrike" with perfect = true):
--   * one frame of a white impact flash over the view (references Instagram Dez6v2UJmoa and Dfck1ptgbc9); left out with
--     the screen shake setting off (attribute NoShake)
--   * five glass shards in the ore's colour burst from the deposit on arcs, bounce once on the floor and fade
-- The hit-stop, the camera punch and the sounds are PixelClient's (they were there). Display only.
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local M = {}

function M.start(E)
	local plr = E.plr
	local dep
	local flash = Instance.new("Frame")
	flash.Name, flash.Size, flash.BackgroundColor3, flash.BackgroundTransparency, flash.BorderSizePixel, flash.Visible, flash.ZIndex = "ImpactFlash", UDim2.fromScale(1, 1.2), Color3.new(1, 1, 1), 0.25, 0, false, 60
	flash.Position = UDim2.fromScale(0, -0.1)
	flash.Parent = E.top or E.gui
	local folder = Instance.new("Folder")
	folder.Name = "FractureFX"
	folder.Parent = workspace
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Exclude

	local function shard(from, color, floorY, i)
		local p = Instance.new("Part")
		local s = 0.35 + (i % 3) * 0.16
		p.Size, p.Color, p.Material, p.Transparency, p.Anchored = Vector3.new(s, s * 1.5, s), color, Enum.Material.Glass, 0.15, true
		p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = false, false, false, false
		p.CFrame = CFrame.new(from)
		p.Parent = folder
		local a = i * 1.26 + math.random() * 0.6
		local vel = Vector3.new(math.cos(a) * (5 + i % 3 * 2), 9 + (i % 2) * 4, math.sin(a) * (5 + i % 3 * 2))
		local pos, bounced, t0 = from, false, os.clock()
		local conn
		conn = RunService.RenderStepped:Connect(function(dt)
			dt = math.min(dt, 1 / 30)
			vel -= Vector3.new(0, 60 * dt, 0)
			pos += vel * dt
			if pos.Y <= floorY + s / 2 then
				if bounced then
					conn:Disconnect()
					TweenService:Create(p, TweenInfo.new(0.3), { Transparency = 1 }):Play()
					task.delay(0.32, function() p:Destroy() end)
					return
				end
				bounced = true
				pos = Vector3.new(pos.X, floorY + s / 2, pos.Z)
				vel = Vector3.new(vel.X * 0.5, -vel.Y * 0.42, vel.Z * 0.5) -- one damped bounce
			end
			local spin = (os.clock() - t0) * 9
			p.CFrame = CFrame.new(pos) * CFrame.Angles(spin, spin * 0.7, i)
			if os.clock() - t0 > 2 then conn:Disconnect() p:Destroy() end
		end)
	end

	E.R.Fx.OnClientEvent:Connect(function(kind, a, b)
		if kind == "mgStart" then
			dep = a
		elseif kind == "mgEnd" then
			dep = nil
		elseif kind == "mgStrike" and b == true then
			if not plr:GetAttribute("NoShake") then
				flash.Visible = true
				task.spawn(function()
					RunService.RenderStepped:Wait()
					RunService.RenderStepped:Wait()
					flash.Visible = false
				end)
			end
			local core = dep and typeof(dep) == "Instance" and dep:IsA("Model") and dep.PrimaryPart
			if not core then return end
			local ore = E.C.LAYERS[dep:GetAttribute("Layer") or 1]
			ore = ore and ore[4][dep:GetAttribute("Ore") or 1]
			local color = (ore and ore[2] or Color3.fromRGB(120, 232, 255)):Lerp(Color3.new(1, 1, 1), 0.25)
			rp.FilterDescendantsInstances = { dep, plr.Character, folder }
			local hit = workspace:Raycast(core.Position, Vector3.new(0, -12, 0), rp)
			local floorY = hit and hit.Position.Y or core.Position.Y - 3
			for i = 1, 5 do shard(core.Position, color, floorY, i) end
		end
	end)
end

return M
