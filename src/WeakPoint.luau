-- WeakPoint (ReplicatedStorage.Shared.WeakPoint), started by PixelClient. Directive v13 phase 3 (vault Research/UI/Non-Distracting
-- HUD and Feature Inspirations (2026-11-20), Bucket C #3, The Forge's weak points): on a rare vein (ore 3) a hot crystal facet
-- glints and slowly circles the ore during the Perfect Strike. It shines in a window of every 2.4 s of server time (0.9 s on);
-- a strike made while you aim within 9 degrees of the shining facet is a critical: the server checks the window on its own
-- clock (C.WEAK) and pays an extra ore chunk for it. E.vmHook.weakAim() hands PixelClient's strike the camera's aim ray when
-- it points at the facet; the server checks that ray from the miner's head against M.at on its own clock.
local RunService = game:GetService("RunService")
local M = {}

function M.window(t, W) return (t % W.period) < W.on end -- is the facet shining at server time t?
function M.at(core, t) -- where the facet is at server time t, round a core at position core; shared with the server's check (PixelServer)
	local a = t * 1.6
	return core + Vector3.new(math.cos(a) * 1.15, 0.5 + math.sin(t * 2.3) * 0.35, math.sin(a) * 1.15)
end

function M.start(E)
	local C, cave, hook = E.C, E.cave, E.vmHook
	local W = C.WEAK
	for _ = 1, 150 do -- PixelClient sets cave.mg once the cave HUD is built
		if cave and cave.mg then break end
		task.wait(0.2)
	end
	if not W or not cave or not cave.mg then return end
	local glint, light, dep
	local function clear()
		if glint then glint:Destroy() glint, light = nil, nil end
		dep = nil
	end
	local inner = cave.mg
	cave.mg = function(what, ...)
		inner(what, ...)
		if what == "mgStart" then
			local d, which = ...
			clear()
			if which == "strike" and d and d.PrimaryPart and (d:GetAttribute("Ore") or 0) >= W.minOre then
				dep = d
				glint = Instance.new("Part")
				glint.Name, glint.Anchored, glint.CanCollide, glint.CanQuery, glint.CanTouch, glint.CastShadow = "WeakGlint", true, false, false, false, false
				glint.Size, glint.Material, glint.Color = Vector3.new(0.45, 0.7, 0.45), Enum.Material.Neon, Color3.fromRGB(255, 244, 200)
				light = Instance.new("PointLight")
				light.Color, light.Range, light.Brightness, light.Shadows = Color3.fromRGB(255, 226, 150), 7, 2.2, false
				light.Parent = glint
				glint.Parent = workspace:FindFirstChild("ClientFX") or workspace
			end
		elseif what == "mgEnd" then
			clear()
		end
	end
	local function glintPos(t)
		local core = dep and dep.PrimaryPart
		return core and M.at(core.Position, t) or nil
	end
	hook.weakAim = function() -- the camera's aim ray when it points at the shining facet (the server checks it against its own geometry)
		if not glint or not dep then return nil end
		local t = workspace:GetServerTimeNow()
		if not M.window(t, W) then return nil end
		local p = glintPos(t)
		local cam = workspace.CurrentCamera
		local to = p and p - cam.CFrame.Position
		return to and to.Magnitude > 0 and cam.CFrame.LookVector:Dot(to.Unit) > math.cos(math.rad(W.aim)) and cam.CFrame.LookVector or nil
	end
	RunService.RenderStepped:Connect(function()
		if not glint then return end
		local t = workspace:GetServerTimeNow()
		local p = glintPos(t)
		if not p then return clear() end
		local on = M.window(t, W)
		glint.CFrame = CFrame.new(p) * CFrame.Angles(0, t * 4, math.rad(45))
		glint.Transparency = on and 0 or 0.85
		light.Enabled = on
	end)
end

return M
