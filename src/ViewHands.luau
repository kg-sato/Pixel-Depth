-- ViewHands (ReplicatedStorage.Shared.ViewHands), started by PixelClient. Demo audit 15: in first person the pickaxe floated
-- rigidly in mid-air, no hand on it and no weight. Two things:
--   hands(vm, root)  a chunky gloved chibi hand, a leather cuff and a sleeve gripping the handle, welded to the pickaxe copy
--   pose(dt, t, moving, now, camCF) -> the pickaxe's place in front of the camera, driven by springs: the swing is a target
--       curve (anticipation pull-back, snap strike, hold) that an under-damped spring chases, so the strike overshoots and
--       bounces back (recoil); the whole tool lags a little behind a turning camera and breathes while idle.
local M = {}

function M.start(E)
	local hook = E.vmHook
	local GLOVE, CUFF, SLEEVE = Color3.fromRGB(98, 62, 44), Color3.fromRGB(58, 38, 34), Color3.fromRGB(52, 40, 74) -- worn leather: a pale glove blew out to yellow beside the torch

	hook.vmHands = function(vm, root, at, k) -- at: where the fist sits (default: the model's pivot, the pickaxe's grip point); k: size
		local grip = at or vm:GetPivot()
		k = k or 1
		local function p(size, cf, color)
			local q = Instance.new("Part")
			q.Name, q.Size, q.CFrame, q.Color = "ViewHand", size * k, grip * (cf.Rotation + cf.Position * k), color
			q.Material, q.Anchored, q.CanCollide, q.CanQuery, q.CanTouch, q.CastShadow, q.Massless = Enum.Material.SmoothPlastic, false, false, false, false, false, true
			pcall(function() q.Material = Enum.Material.Leather end) -- stitched leather, not bare blocks
			q.TopSurface, q.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
			q.Parent = vm
			local w = Instance.new("WeldConstraint")
			w.Part0, w.Part1 = root, q
			w.Parent = q
			return q
		end
		p(Vector3.new(0.3, 0.46, 0.34), CFrame.new(0, 0, 0.2), GLOVE) -- the palm, behind the handle
		for k = 0, 3 do -- four fingers wrapped round the front of the handle, each a little further round than the last
			local y = 0.18 - k * 0.12
			p(Vector3.new(0.5, 0.085, 0.16), CFrame.new(0, y, -0.14 - 0.02 * (k % 2)) * CFrame.Angles(0, 0.08 * (k - 1.5), 0), GLOVE:Lerp(Color3.new(1, 1, 1), 0.22 * (k % 2))) -- a dark gap and a shade step between fingers
			p(Vector3.new(0.14, 0.1, 0.3), CFrame.new(-0.24, y, 0.02), GLOVE:Lerp(Color3.new(0, 0, 0), 0.12)) -- the fingertip coming back round
		end
		p(Vector3.new(0.18, 0.34, 0.22), CFrame.new(0.24, 0.22, -0.1) * CFrame.Angles(0, 0, -0.5), GLOVE:Lerp(Color3.new(1, 1, 1), 0.25)) -- the thumb, wrapped up along the handle
		p(Vector3.new(0.46, 0.4, 0.26), CFrame.new(0, -0.02, 0.46), CUFF) -- the cuff, toward the body
		p(Vector3.new(0.5, 0.09, 0.3), CFrame.new(0, 0.16, 0.46), Color3.fromRGB(120, 84, 60)) -- its stitched band
		p(Vector3.new(0.14, 0.14, 0.06), CFrame.new(0.12, 0.02, 0.6), Color3.fromRGB(214, 168, 84)).Material = Enum.Material.Metal -- a brass buckle
		p(Vector3.new(0.36, 0.34, 0.8), CFrame.new(0.02, -0.16, 0.94) * CFrame.Angles(-0.35, 0, 0), SLEEVE) -- the sleeve, down and back out of view
	end

	local ang, angV = 0, 0 -- the swing spring (radians)
	local sway, swayV = Vector2.zero, Vector2.zero -- lag behind the camera's turn
	local lastLook
	hook.vmPose = function(dt, t, moving, now, camCF)
		dt = math.min(dt, 1 / 30)
		local target = 0 -- the swing curve the spring chases
		if t < 0.09 then target = -0.75 * (t / 0.09) -- anticipation: a pull back
		elseif t < 0.2 then target = 1.75 -- snap strike
		elseif t < 0.3 then target = 1.2 -- a short hold on the rock
		end
		local k, c = (t >= 0.09 and t < 0.2) and 1400 or 520, (t >= 0.09 and t < 0.2) and 40 or 17 -- fast into the hit, loose after it: the recoil bounce
		angV += (k * (target - ang) - c * angV) * dt
		ang += angV * dt
		local look = camCF.LookVector
		if lastLook then -- the tool trails a turning camera, then settles
			local d = camCF:VectorToObjectSpace(look - lastLook)
			swayV += Vector2.new(-d.X, d.Y) * 14
		end
		lastLook = look
		swayV += (-sway * 160 - swayV * 16) * dt
		sway += swayV * dt
		sway = Vector2.new(math.clamp(sway.X, -0.4, 0.4), math.clamp(sway.Y, -0.3, 0.3))
		local bob = moving and math.sin(now * 10) * 0.08 or math.sin(now * 1.7) * 0.035 -- walking bob, or slow breathing
		local roll = moving and math.sin(now * 5) * 0.03 or math.sin(now * 0.85) * 0.02
		local dip = math.max(ang, 0) * 0.12 -- the head carries the hand forward and down on the strike
		return CFrame.new(1.12 + sway.X, -1.24 + bob + sway.Y - dip, -2.1 - dip) * CFrame.Angles(0.15 + sway.Y * 0.5, -0.35 - sway.X * 0.6, 0.35 + roll) * CFrame.Angles(-ang, 0, 0)
	end
end

return M
