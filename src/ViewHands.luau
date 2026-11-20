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
		-- rounded chibi glove (directive v12 task 6, 2026-11-19: the box hand read as loose blocks by the handle): a ball palm,
		-- tube fingers and knuckle balls, a round cuff and a tube sleeve, all welded to the pickaxe copy
		local Y90 = CFrame.Angles(0, math.pi / 2, 0) -- a cylinder runs along X: turned, it runs along the arm (Z)
		local function round(q, shape) q.Shape = shape return q end
		round(p(Vector3.new(0.5, 0.5, 0.5), CFrame.new(0, 0.02, 0.2), GLOVE), Enum.PartType.Ball) -- the palm, behind the handle
		for k = 0, 3 do -- four fingers wrapped round the front of the handle
			local y = 0.18 - k * 0.12
			local shade = GLOVE:Lerp(Color3.new(1, 1, 1), 0.16 * (k % 2))
			round(p(Vector3.new(0.46, 0.13, 0.13), CFrame.new(0, y, -0.14 - 0.02 * (k % 2)) * CFrame.Angles(0, 0.08 * (k - 1.5), 0), shade), Enum.PartType.Cylinder)
			round(p(Vector3.new(0.15, 0.15, 0.15), CFrame.new(-0.24, y, 0.0), GLOVE:Lerp(Color3.new(0, 0, 0), 0.1)), Enum.PartType.Ball) -- the fingertip coming back round
		end
		round(p(Vector3.new(0.34, 0.17, 0.17), CFrame.new(0.24, 0.22, -0.1) * CFrame.Angles(0, 0, 1.07), GLOVE:Lerp(Color3.new(1, 1, 1), 0.22)), Enum.PartType.Cylinder) -- the thumb, up along the handle
		round(p(Vector3.new(0.3, 0.52, 0.52), CFrame.new(0, -0.02, 0.46) * Y90, CUFF), Enum.PartType.Cylinder) -- the cuff, toward the body
		round(p(Vector3.new(0.09, 0.56, 0.56), CFrame.new(0, -0.02, 0.36) * Y90, Color3.fromRGB(236, 196, 116)), Enum.PartType.Cylinder) -- its butter band
		p(Vector3.new(0.14, 0.14, 0.06), CFrame.new(0.2, 0.08, 0.6), Color3.fromRGB(214, 168, 84)).Material = Enum.Material.Metal -- a brass buckle
		round(p(Vector3.new(2.2, 0.44, 0.44), CFrame.new(0.02, -0.4, 1.62) * CFrame.Angles(-0.35, 0, 0) * Y90, SLEEVE), Enum.PartType.Cylinder) -- the whole forearm, running off the bottom of the screen
		round(p(Vector3.new(0.12, 0.5, 0.5), CFrame.new(0.02, -0.12, 0.86) * CFrame.Angles(-0.35, 0, 0) * Y90, SLEEVE:Lerp(Color3.new(1, 1, 1), 0.14)), Enum.PartType.Cylinder) -- a rolled sleeve hem
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
	-- the owner, 2026-11-17: "bulkier, slower, bigger movements": every swing pulls further back, comes down further and
	-- carries the whole arm with it (pull and hit were -0.75/1.75, -0.6/1.6, -1.1/2.05)
	local SWINGS = { { pull = -1.0, hit = 1.15, side = 0 }, { pull = -0.85, hit = 1.05, side = 0.6 }, { pull = -1.35, hit = 1.25, side = -0.3 } } -- the hit lands the head on the crosshair now that the fist holds the handle's end
	-- Perfect Strike (heavy = true): the pick is held up over the right shoulder between swings, drawn further back as the
	-- needle nears the gold, then brought down in one big chop that bites into the rock a moment and climbs back slowly
	-- (it used to vanish for the whole minigame). READY is the raised rest, NEAR the extra draw at the gold.
	local READY, NEAR = -0.95, -0.45
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
				if d:IsA("BasePart") and d.Name:sub(1, 5) == "Flame" then flames[d] = d.Color:Lerp(Color3.fromRGB(200, 90, 20), 0.52) end -- a deeper orange base: near the eye the pale flame was a white blob
			end
		end
		for d in flames do -- the flame gutters: each flame block flickers on its own, harder when low
			do
				local n = math.noise(now * 7, d.Size.X * 13.7, d.Size.Y * 5.1)
				d.Color = flames[d]:Lerp(n > 0 and Color3.new(1, 0.7, 0.3) or Color3.new(0.4, 0.1, 0), math.abs(n) * (0.35 + low * 0.3))
			end
		end
		return CFrame.new(-1.3 - sway.X * 0.7 + shiver + thrust * 0.5, -1.1 + bob - sway.Y * 0.7 + landY + lift + thrust * 0.45, -2.4 - thrust * 1.1)
			* CFrame.Angles(0.3 - thrust * 0.9 - lift * 0.5, 0.25, -0.32 + (moving and math.sin(now * 5) * 0.04 or 0))
	end
	local lastLook
	-- H: look your pickaxe over (directive v8). For 1.8 s it lifts to the middle of the view, turns once about its handle and
	-- tips toward you, then settles back. Display only; a swing ends it at once.
	local inspectAt = -10
	game:GetService("UserInputService").InputBegan:Connect(function(io, gp)
		if gp or io.KeyCode ~= Enum.KeyCode.H or E.isBusy() then return end
		if os.clock() - inspectAt > 1.8 then
			inspectAt = os.clock()
			pcall(E.sfx, "swing", 0.7)
		end
	end)
	local heavyW = 0 -- 0 normal digging .. 1 the raised Perfect Strike stance, eased so the pick climbs up and settles down
	hook.vmPose = function(dt, t, moving, now, camCF, heavy, near)
		dt = math.min(dt, 1 / 30)
		heavyW += ((heavy and 1 or 0) - heavyW) * math.min(1, dt * 5)
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
		local k, c
		if heavy then -- the big chop: a deep draw, a heavy fall, a long bite in the rock, a slow climb back to the shoulder
			local ready = READY + NEAR * math.clamp(near or 0, 0, 1) ^ 2
			if t < 0.14 then target = ready + (-1.55 - ready) * (t / 0.14)
			elseif t < 0.34 then target = 1.15
			elseif t < 0.62 then target = 0.95
			else target = ready end
			local fall = t >= 0.14 and t < 0.34
			k, c = fall and 900 or (t < 0.62 and 300 or 70), fall and 34 or (t < 0.62 and 22 or 13) -- the climb back is a soft spring: the weight of the head
		else -- digging: the same three beats, longer and bigger (they were 0.09 / 0.2 / 0.3 s)
			if t < 0.11 then target = sw.pull * (t / 0.11) -- anticipation: a pull back
			elseif t < 0.22 then target = sw.hit -- the strike
			elseif t < 0.34 then target = 0.85 -- a hold on the rock
			end
			local fall = t >= 0.11 and t < 0.22
			k, c = fall and 1100 or 300, fall and 36 or 15 -- fast into the hit, slow and loose after it: a heavier recoil
		end
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
		local dip = math.max(ang, 0) * (0.2 + 0.12 * heavyW) -- the head carries the arm forward and down on the strike (was 0.12)
		local lift = -math.min(ang, 0) * 0.35 -- the wind-up lifts the whole arm, not only the wrist
		local hx, hy = 0.4 * heavyW, 0.2 * heavyW -- the raised stance: out to the right and up, clear of the dial and the STRIKE button
		local step = moving and math.sin(now * 5) * 0.05 or 0 -- the hand swings side to side with each stride
		local i = os.clock() - inspectAt
		if t < 0.3 then inspectAt = -10 end -- a swing ends the look
		local w, turn = 0, 0
		if i < 1.8 then
			local up, down = math.clamp(i / 0.3, 0, 1), math.clamp((1.8 - i) / 0.3, 0, 1)
			w = math.min(up * up * (3 - 2 * up), down * down * (3 - 2 * down))
			local q = math.clamp((i - 0.2) / 1.3, 0, 1)
			turn = q * q * (3 - 2 * q) * math.pi * 2
		end
		return CFrame.new(1.75 + hx + sway.X - dip * (1 + heavyW) + step - 1.15 * w, -1.55 + hy + lift + bob + sway.Y - dip * (1 + heavyW) + landY + 0.95 * w, -2.4 - dip - 0.5 * w) * CFrame.Angles(-ang + sway.Y * 0.5 + 0.35 * w, -sway.X * 0.6 + math.max(ang, 0) * 0.25, sw.side * math.max(ang, 0) * 0.5) -- the swing chops forward and in toward the crosshair
			* CFrame.Angles(-0.35, 0, 0.44 + roll) * CFrame.Angles(0, YAW + turn, 0) -- at rest: the fist in the bottom right, the handle leaning 25 degrees in toward the middle (Minecraft's handheld first-person roll) and a little forward (was -0.5 / 0.22)
	end
end

return M
