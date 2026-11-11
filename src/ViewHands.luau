-- ViewHands (ReplicatedStorage.Shared.ViewHands), started by PixelClient. Demo audit 15: in first person the pickaxe floated
-- rigidly in mid-air, no hand on it and no weight. Two things:
--   hands(vm, root)  a chunky gloved chibi hand, a leather cuff and a sleeve gripping the handle, welded to the pickaxe copy
--   pose(dt, t, moving, now, camCF) -> the pickaxe's place in front of the camera, driven by springs: the swing is a target
--       curve (anticipation pull-back, snap strike, hold) that an under-damped spring chases, so the strike overshoots and
--       bounces back (recoil); the whole tool lags a little behind a turning camera and breathes while idle.
local M = {}

function M.start(E)
	local hook = E.vmHook
	local GLOVE, CUFF, SLEEVE = Color3.fromRGB(146, 102, 70), Color3.fromRGB(62, 46, 86), Color3.fromRGB(80, 64, 118) -- a tan mitt, a plum cuff, a lilac sleeve: the dark leather read as wooden blocks (the user, 2026-11-10)

	hook.vmHands = function(vm, root, at, k) -- at: where the fist sits (default: the model's pivot, the pickaxe's grip point); k: size
		local grip = at or vm:GetPivot()
		k = k or 1
		local function p(size, cf, color)
			local q = Instance.new("Part")
			q.Name, q.Size, q.CFrame, q.Color = "ViewHand", size * k, grip * (cf.Rotation + cf.Position * k), color
			q.Material, q.Anchored, q.CanCollide, q.CanQuery, q.CanTouch, q.CastShadow, q.Massless = Enum.Material.Rubber, false, false, false, false, false, true
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
		p(Vector3.new(0.5, 0.09, 0.3), CFrame.new(0, 0.16, 0.46), Color3.fromRGB(236, 196, 116)) -- its butter band
		p(Vector3.new(0.14, 0.14, 0.06), CFrame.new(0.12, 0.02, 0.6), Color3.fromRGB(214, 168, 84)).Material = Enum.Material.Metal -- a brass buckle
		p(Vector3.new(0.4, 0.38, 2.2), CFrame.new(0.02, -0.4, 1.62) * CFrame.Angles(-0.35, 0, 0), SLEEVE) -- the whole forearm, running off the bottom of the screen (the user, 2026-11-10: arms in view like the cart ride)
		p(Vector3.new(0.44, 0.1, 0.3), CFrame.new(0.02, -0.12, 0.86) * CFrame.Angles(-0.35, 0, 0), SLEEVE:Lerp(Color3.new(1, 1, 1), 0.14)) -- a rolled sleeve hem
	end

	-- the rider's own body in first person (the user, 2026-11-10): Roblox hides the whole character in LockFirstPerson; the legs
	-- come back so you see yourself when you look down (the torso filled the lower half of the view, so it stays hidden). The
	-- arms stay hidden too: the gloved view arms replace them.
	local plr = game:GetService("Players").LocalPlayer
	game:GetService("RunService"):BindToRenderStep("PD_FPBody", Enum.RenderPriority.Camera.Value + 1, function()
		local char = plr.Character
		if not char or plr.CameraMode ~= Enum.CameraMode.LockFirstPerson or workspace.CurrentCamera.CameraType == Enum.CameraType.Scriptable then return end
		for _, q in char:GetChildren() do
			if q:IsA("BasePart") and (q.Name:find("Leg") or q.Name:find("Foot")) then q.LocalTransparencyModifier = 0 end
		end
	end)

	local YAW = -1.2 -- Minecraft's held-tool pose (the user, 2026-11-10): the head runs away from the camera, its flat face turned to screen centre
	hook.vmYaw = YAW
	local ang, angV = 0, 0 -- the swing spring (radians)
	local sway, swayV = Vector2.zero, Vector2.zero -- lag behind the camera's turn
	-- three swings in turn (the user, 2026-11-10: more swing animations): an overhead chop, a slash across from the right, a heavy
	-- blow with a deeper wind-up. side: how far the tool rolls across the view as it comes down
	local SWINGS = { { pull = -0.75, hit = 1.75, side = 0 }, { pull = -0.6, hit = 1.6, side = 0.6 }, { pull = -1.1, hit = 2.05, side = -0.3 } }
	local variant, lastT = 1, math.huge
	local landY, landV, wasAir = 0, 0, false -- a dip of both hands when you land from a jump or a drop
	local flareAt, relitSeen, liftAt = -10, nil, -10
	task.spawn(function() -- the flare (GloomClient sets cave.flare): the torch hand thrusts it forward
		for _ = 1, 100 do
			if E.cave and E.cave.flare then
				local fire = E.cave.flare
				E.cave.flare = function(...)
					flareAt = os.clock()
					return fire(...)
				end
				return
			end
			task.wait(0.2)
		end
	end)
	local flames, flameOf = {}, nil -- flame part -> its base colour, for the torch model flameOf
	hook.vmTorchPose = function(dt, moving, now, cave)
		local t = os.clock()
		if cave.relitAt ~= relitSeen then -- relit at camp: the torch lifts in a small salute
			if relitSeen and cave.relitAt - relitSeen > 1 then liftAt = t end
			relitSeen = cave.relitAt
		end
		local bob = moving and math.sin(now * 10 + 1.5) * 0.07 or math.sin(now * 2 + 1) * 0.02
		local fx = math.clamp((t - flareAt) / 0.45, 0, 1)
		local thrust = math.sin(fx * math.pi) * (1 - fx * 0.3) -- out fast, back slower
		local lift = math.sin(math.clamp((t - liftAt) / 0.7, 0, 1) * math.pi) * 0.35
		local low = (cave.fuel or 1) < 0.25 and 1 or 0 -- nearly out: the hand shivers
		local shiver = low * math.noise(now * 9, 3.1) * 0.05
		if flameOf ~= cave.tvm then -- a new torch model: find its flame blocks once, not every frame
			flameOf, flames = cave.tvm, {}
			for _, d in cave.tvm:GetDescendants() do
				if d:IsA("BasePart") and d.Name:sub(1, 5) == "Flame" then flames[d] = d.Color end
			end
		end
		for d in flames do -- the flame gutters: each flame block flickers on its own, harder when low
			do
				local n = math.noise(now * 7, d.Size.X * 13.7, d.Size.Y * 5.1)
				d.Color = flames[d]:Lerp(n > 0 and Color3.new(1, 1, 0.8) or Color3.new(0.4, 0.1, 0), math.abs(n) * (0.35 + low * 0.3))
			end
		end
		return CFrame.new(-1.3 - sway.X * 0.7 + shiver + thrust * 0.5, -1.1 + bob - sway.Y * 0.7 + landY + lift + thrust * 0.45, -2.4 - thrust * 1.1)
			* CFrame.Angles(0.3 - thrust * 0.9 - lift * 0.5, 0.25, -0.32 + (moving and math.sin(now * 5) * 0.04 or 0))
	end
	local lastLook
	hook.vmPose = function(dt, t, moving, now, camCF)
		dt = math.min(dt, 1 / 30)
		if t < lastT then variant = variant % #SWINGS + 1 end -- a new swing began
		lastT = t
		local sw = SWINGS[variant]
		local hum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
		local air = hum ~= nil and hum.FloorMaterial == Enum.Material.Air
		if wasAir and not air then landV -= 2.4 end
		wasAir = air
		landV += (-landY * 180 - landV * 14) * dt
		landY += landV * dt
		local target = 0 -- the swing curve the spring chases
		if t < 0.09 then target = sw.pull * (t / 0.09) -- anticipation: a pull back
		elseif t < 0.2 then target = sw.hit -- snap strike
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
		local step = moving and math.sin(now * 5) * 0.05 or 0 -- the hand swings side to side with each stride
		return CFrame.new(1.5 + sway.X - dip + step, -2 + bob + sway.Y - dip + landY, -2.4 - dip) * CFrame.Angles(-ang + sway.Y * 0.5, -sway.X * 0.6 + math.max(ang, 0) * 0.25, sw.side * math.max(ang, 0) * 0.5) -- the swing chops forward and in toward the crosshair
			* CFrame.Angles(-0.5, 0, 0.22 + roll) * CFrame.Angles(0, YAW, 0) -- at rest: leaning forward and a little inward, handle to the bottom right corner
	end
end

return M
