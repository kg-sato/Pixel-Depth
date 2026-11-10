-- CartFX (ReplicatedStorage.Shared.CartFX): the feel shared by the minecart ride down (MinecartRide) and the escape up
-- (MinecartEscape). Demo audits 09, 12 and 14 and the overnight brief's phase 3:
--   lantern(part)        dress a plain lamp block as a miner's lantern: amber glass, a small wick, brass cap, base and struts.
--                        The dressing is box adornments on the part, so it follows a lamp that swings or is recycled.
--   hands(cart, z)       two chunky gloved hands gripping the cart's front rim (the rider's own body is hidden in first person)
--   spring()             a damped spring (the chassis bounce over rail ties and against the buffers)
--   air(parent)          spore motes and wind streaks drifting past the camera; step(camCF, speed) every frame
--   speedLines(gui)      thin streaks at the screen edges; step(now, strength 0..1) every frame
local M = {}

local BRASS, BRASS_D = Color3.fromRGB(150, 108, 60), Color3.fromRGB(64, 46, 42)

local function box(parent, size, cf, color, transparency)
	local a = Instance.new("BoxHandleAdornment")
	a.Adornee, a.Size, a.CFrame, a.Color3, a.Transparency = parent, size, cf, color, transparency or 0
	a.AlwaysOnTop, a.ZIndex = false, 1
	a.Parent = parent
	return a
end

function M.lantern(lamp)
	local s = lamp.Size
	lamp.Size = s * Vector3.new(0.24, 0.36, 0.24) -- the block itself becomes the flame (still neon, a tenth of the glowing area)
	lamp.Material, lamp.Color = Enum.Material.Neon, Color3.fromRGB(255, 200, 124)
	box(lamp, s, CFrame.new(), Color3.fromRGB(255, 180, 96), 0.8) -- clear amber glass panes
	box(lamp, Vector3.new(s.X * 0.34, s.Y * 0.2, s.Z * 0.34), CFrame.new(0, -s.Y * 0.38, 0), BRASS_D) -- the oil cup
	box(lamp, Vector3.new(s.X * 1.16, s.Y * 0.16, s.Z * 1.16), CFrame.new(0, s.Y * 0.56, 0), BRASS)
	box(lamp, Vector3.new(s.X * 0.6, s.Y * 0.14, s.Z * 0.6), CFrame.new(0, s.Y * 0.7, 0), BRASS_D)
	box(lamp, Vector3.new(s.X * 1.16, s.Y * 0.16, s.Z * 1.16), CFrame.new(0, -s.Y * 0.56, 0), BRASS)
	for _, o in { { -1, -1 }, { -1, 1 }, { 1, -1 }, { 1, 1 } } do
		box(lamp, Vector3.new(s.X * 0.13, s.Y * 0.98, s.Z * 0.13), CFrame.new(o[1] * s.X * 0.5, 0, o[2] * s.Z * 0.5), BRASS_D)
	end
	return lamp
end

-- cart: the ride's own copy of the cart (a Model moved with PivotTo; its pivot is the rail base, -Z is forward)
function M.hands(cart, rimY, rimZ)
	local base = cart:GetPivot()
	local GLOVE, CUFF, SLEEVE = Color3.fromRGB(98, 62, 44), Color3.fromRGB(58, 38, 34), Color3.fromRGB(52, 40, 74) -- the same worn leather as the first-person hands
	local made = {}
	local function p(size, cf, color)
		local q = Instance.new("Part")
		q.Name, q.Size, q.CFrame, q.Color = "RiderHand", size, base * cf, color
		q.Material, q.Anchored, q.CanCollide, q.CanQuery, q.CanTouch, q.CastShadow = Enum.Material.SmoothPlastic, true, false, false, false, false
		q.TopSurface, q.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		q.Parent = cart
		table.insert(made, q)
		return q
	end
	for _, sd in { -1, 1 } do
		local grip = CFrame.new(sd * 0.85, rimY + 0.16, rimZ + 0.06) * CFrame.Angles(0, sd * -0.12, 0)
		local K = 0.85 -- Gemini r7: the hands filled a quarter of the frame
		local function hp(size, off, color) return p(size * K, grip * (off.Rotation + off.Position * K), color) end
		hp(Vector3.new(0.56, 0.3, 0.5), CFrame.new(0, 0.02, 0.1), GLOVE) -- the back of the hand, lying on the rim
		hp(Vector3.new(0.2, 0.26, 0.3), CFrame.new(-sd * 0.36, -0.08, 0.04) * CFrame.Angles(0, 0, sd * 0.3), GLOVE) -- the thumb, hooked under
		for k = 0, 3 do -- four fingers bent over the front edge: a knuckle on top, a fingertip hanging down the outside
			local x = (k - 1.5) * 0.14
			hp(Vector3.new(0.11, 0.2, 0.26), CFrame.new(x, 0.05, -0.24) * CFrame.Angles(-0.5, 0, 0), GLOVE:Lerp(Color3.new(1, 1, 1), 0.2 * (k % 2)))
			hp(Vector3.new(0.12, 0.24, 0.13), CFrame.new(x, -0.12, -0.37), GLOVE:Lerp(Color3.new(0, 0, 0), 0.16))
		end
		hp(Vector3.new(0.62, 0.42, 0.3), CFrame.new(0, 0.02, 0.46), CUFF) -- the leather cuff
		hp(Vector3.new(0.66, 0.1, 0.34), CFrame.new(0, 0.2, 0.46), Color3.fromRGB(120, 84, 60)) -- its stitched band
		hp(Vector3.new(0.12, 0.12, 0.06), CFrame.new(sd * 0.2, 0.06, 0.62), Color3.fromRGB(214, 168, 84)) -- a brass stud
		hp(Vector3.new(0.4, 0.38, 0.6), CFrame.new(sd * 0.05, -0.14, 0.9) * CFrame.Angles(-0.3, 0, 0), SLEEVE) -- a short forearm dipping into the tub (a long one filled the view)
	end
	-- a lantern on an iron pole at the cart's front corner (reference clip DfWPdG3FQIw: the cart carries its own light)
	local function q(size, cf, color, mat)
		local o = p(size, cf, color)
		o.Name, o.Material = "CartLamp", mat or Enum.Material.Metal
		table.remove(made) -- not a hand: it stays visible in third person too
		return o
	end
	q(Vector3.new(0.14, 1.3, 0.14), CFrame.new(1.62, rimY + 0.6, rimZ + 0.1), Color3.fromRGB(58, 52, 72))
	q(Vector3.new(0.5, 0.12, 0.12), CFrame.new(1.82, rimY + 1.2, rimZ + 0.1), Color3.fromRGB(58, 52, 72))
	local lamp = M.lantern(q(Vector3.new(0.34, 0.45, 0.34), CFrame.new(1.98, rimY + 0.86, rimZ + 0.1), Color3.fromRGB(255, 200, 124), Enum.Material.Neon)) -- out beside the cart: it must not hide the track
	local glow = Instance.new("PointLight")
	glow.Color, glow.Range, glow.Brightness, glow.Shadows = Color3.fromRGB(255, 196, 120), 9, 1.1, false -- it lights the gloves and the front planks
	glow.Parent = lamp
	return made
end

function M.spring(stiffness, damping)
	local s = { y = 0, v = 0 }
	function s.kick(v) s.v += v end
	function s.step(dt)
		dt = math.min(dt, 1 / 30)
		s.v += (-stiffness * s.y - damping * s.v) * dt
		s.y += s.v * dt
		return s.y
	end
	return s
end

function M.air(parent)
	local p = Instance.new("Part")
	p.Name, p.Size, p.Transparency = "CartAir", Vector3.new(16, 9, 2), 1
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
	p.Parent = parent
	local motes = Instance.new("ParticleEmitter") -- drifting spore motes: slow, glowing, they light as you rush through them
	motes.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	motes.Color = ColorSequence.new(Color3.fromRGB(150, 240, 200), Color3.fromRGB(200, 170, 255))
	motes.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.3, 0.22), NumberSequenceKeypoint.new(1, 0) })
	motes.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.3, 0.25), NumberSequenceKeypoint.new(1, 1) })
	motes.Lifetime, motes.Speed, motes.Rate = NumberRange.new(1.1, 1.8), NumberRange.new(0.5, 2), 0
	motes.Shape, motes.EmissionDirection = Enum.ParticleEmitterShape.Box, Enum.NormalId.Back
	motes.LightEmission, motes.LightInfluence, motes.SpreadAngle = 0.8, 0, Vector2.new(30, 30)
	motes.Parent = p
	local wind = Instance.new("ParticleEmitter") -- the draft: long faint streaks pulled toward the camera at speed
	wind.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	wind.Color = ColorSequence.new(Color3.fromRGB(230, 225, 255))
	wind.Size = NumberSequence.new(0.1, 0.05)
	wind.Squash = NumberSequence.new(4)
	wind.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.4, 0.7), NumberSequenceKeypoint.new(1, 1) })
	wind.Lifetime, wind.Speed, wind.Rate = NumberRange.new(0.35, 0.5), NumberRange.new(30, 46), 0
	wind.Shape, wind.EmissionDirection, wind.Orientation = Enum.ParticleEmitterShape.Box, Enum.NormalId.Back, Enum.ParticleOrientation.VelocityParallel
	wind.LightEmission, wind.LightInfluence = 0.5, 0
	wind.Parent = p
	local api = { part = p }
	function api.step(camCF, speed, calm)
		p.CFrame = camCF * CFrame.new(0, 0.5, -24)
		motes.Rate = math.clamp(6 + speed * 0.5, 0, 34)
		wind.Rate = (calm or speed < 30) and 0 or math.clamp((speed - 30) * 1.4, 0, 40)
	end
	return api
end

function M.speedLines(gui, n)
	local lines = {}
	for k = 1, n or 16 do
		local a = (k / (n or 16)) * math.pi * 2 + (k % 3) * 0.13
		local f = Instance.new("Frame")
		f.BorderSizePixel, f.BackgroundColor3, f.BackgroundTransparency = 0, Color3.new(1, 1, 1), 1
		f.Size, f.AnchorPoint, f.Rotation, f.ZIndex = UDim2.fromScale(0.004, 0.13), Vector2.new(0.5, 0.5), math.deg(a) + 90, 3
		f.Parent = gui
		lines[k] = { f = f, a = a, phase = (k * 0.37) % 1 }
	end
	return function(now, strength)
		for _, L in lines do
			local r = 0.3 + ((now * 1.6 + L.phase) % 1) * 0.42
			L.f.Position = UDim2.fromScale(0.5 + math.cos(L.a) * r * 0.62, 0.5 + math.sin(L.a) * r)
			L.f.BackgroundTransparency = 1 - strength * 0.5 * (1 - (r - 0.3) / 0.42)
		end
	end
end

return M
