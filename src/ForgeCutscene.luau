-- ReplicatedStorage.Shared.ForgeCutscene (src/ForgeCutscene.luau): the forging cutscene after a pickaxe purchase.
-- The user (2026-11-08): leave the UI for a scene where the pickaxe is forged from its theme (star pickaxe: a meteor shower,
-- the smith floats up and compacts it), then "make the actual forging part have a lot more VFX". Storyboard (approved):
-- https://claude.ai/artifact/PoMVEcK7s85wYx5VMocQor ; plan: vault Projects/Pixel-_/Briefs/Forging Cutscenes (2026-11-08).md.
-- Client only and cosmetic: the server has already charged and given the pickaxe. A private stage far above the world;
-- one clock drives every part, camera and effect (so Skip jumps the clock and hit-stop holds it). Five acts:
-- 1 star wipe out of the UI, 2 the theme event, 3 the smith gathers the theme material into a core and squeezes it three
-- times, 4 drop, hammer slam, hold, flash and the pickaxe reveal, 5 star wipe back into the NEW PICKAXE! overlay.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local RS = game:GetService("ReplicatedStorage")

local M = {}
local GLOW, RAYS = "rbxassetid://77591933607769", "rbxassetid://98789616938156" -- soft glow and feathered rays (art/forge/fx)
local STAR = "rbxassetid://100737048426546" -- the soft-kit star sprite, the wipe shape
local SPARK = "rbxasset://textures/particles/sparkles_main.dds"
local FIRE = "rbxasset://textures/particles/fire_main.dds"
local WHITE, INK = Color3.new(1, 1, 1), Color3.fromRGB(62, 42, 86)
local function hex(h) return Color3.fromHex(h) end

-- themes: colours, the caption, whether night falls, and how the material arrives (meteors fall, motes rise, embers float)
local THEMES = {
	leaf = { c1 = hex("#9fe3c4"), c2 = hex("#ffe39a"), caption = "A HUMBLE START", fall = "rise" },
	pebble = { c1 = hex("#c9b9f2"), c2 = hex("#e0dbe9"), caption = "ROCK SOLID", fall = "rise" },
	root = { c1 = hex("#a8e6c8"), c2 = hex("#e9c48a"), caption = "ROOTS AND FLINT", fall = "rise" },
	ember = { c1 = hex("#ffae96"), c2 = hex("#ffd6a0"), caption = "THE EMBERS STIR", fall = "rise", dusk = true },
	lantern = { c1 = hex("#f5b48a"), c2 = hex("#ffe39a"), caption = "THE KOBOLD LANTERN GLOWS", fall = "rise", dusk = true },
	firefly = { c1 = hex("#ffd36e"), c2 = hex("#9fe3c4"), caption = "THE ROOTS AWAKEN", fall = "rise", dusk = true },
	clay = { c1 = hex("#eba58e"), c2 = hex("#fff1d6"), caption = "SHAPED BY HAND", fall = "rise" },
	moss = { c1 = hex("#b9e3a0"), c2 = hex("#b9aaa4"), caption = "IRON FROM THE BOG", fall = "rise", dusk = true },
	starfall = { c1 = hex("#ff7fd0"), c2 = hex("#c9a8ff"), caption = "A STAR SHOWER FALLS", fall = "meteor", night = true },
	moon = { c1 = hex("#bcd2ff"), c2 = hex("#ffffff"), caption = "THE MOON RISES", fall = "meteor", night = true },
	galaxy = { c1 = hex("#8a7cff"), c2 = hex("#ff9de6"), caption = "THE SKY OPENS", fall = "meteor", night = true },
	heart = { c1 = hex("#ff4f9a"), c2 = hex("#ffd6ea"), caption = "ALL HAIL", fall = "rise", dusk = true },
	wing = { c1 = hex("#7fb2ff"), c2 = hex("#ffffff"), caption = "ON SILVER WINGS", fall = "meteor", night = true },
}
local BY_MODEL = {
	WoodPickaxe = "leaf", StonePickaxe = "pebble", RootflintPickaxe = "root", AshcoalPickaxe = "ember", CopperPickaxe = "lantern",
	RootheartPickaxe = "firefly", TitanClayPickaxe = "clay", BogIronPickaxe = "moss", StarlightPickaxe = "starfall",
	MoonlitPickaxe = "moon", GalaxyPickaxe = "galaxy", RoyalHeartPickaxe = "heart", SilverWingPickaxe = "wing",
}

local function smooth(a, b, t) -- 0..1 smoothstep of t between a and b
	local x = math.clamp((t - a) / (b - a), 0, 1)
	return x * x * (3 - 2 * x)
end
local function backOut(x)
	local c = 1.70158
	x -= 1
	return 1 + (c + 1) * x * x * x + c * x * x
end
local function part(parent, size, cf, color, props)
	local p = Instance.new("Part")
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
	p.Size, p.CFrame, p.Color, p.Material = size, cf, color, Enum.Material.SmoothPlastic
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	for k, v in props or {} do p[k] = v end
	p.Parent = parent
	return p
end
local function emitter(parent, props)
	local e = Instance.new("ParticleEmitter")
	e.Rate, e.LightEmission, e.LightInfluence = 0, 1, 0
	for k, v in props do e[k] = v end
	e.Parent = parent
	return e
end
local function ns(a, b) return NumberSequence.new(a, b) end

-- options: { name = "Starlight Pickaxe", model = "StarlightPickaxe", rarity = { "Legendary", odds, colour }, sfx = fn(name, pitch) }
-- yields until the scene has ended (about 8 s, less when skipped)
function M.play(opt)
	local plr = Players.LocalPlayer
	local cam = workspace.CurrentCamera
	local th = THEMES[BY_MODEL[opt.model] or ""] or { c1 = opt.rarity[3], c2 = WHITE, caption = "FORGED IN THE DEEP", fall = "rise", dusk = true }
	local sfx = opt.sfx or function() end
	local O = Vector3.new(4000, 400, 0) -- the stage: far from the town, the mines and the caves
	local world = Instance.new("Folder")
	world.Name = "ForgeStage"
	world.Parent = workspace

	-- the stage: a round platform, a glowing rim and runes, an anvil and two braziers
	local plat = part(world, Vector3.new(2, 40, 40), CFrame.new(O) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(96, 74, 128), { Shape = Enum.PartType.Cylinder })
	part(world, Vector3.new(0.3, 41, 41), plat.CFrame * CFrame.new(0.95, 0, 0), th.c1, { Shape = Enum.PartType.Cylinder, Material = Enum.Material.Neon, Transparency = 0.55 })
	part(world, Vector3.new(0.25, 34, 34), plat.CFrame * CFrame.new(1.05, 0, 0), Color3.fromRGB(122, 98, 160), { Shape = Enum.PartType.Cylinder })
	for k = 0, 11 do
		local a = k / 12 * math.pi * 2
		part(world, Vector3.new(1.6, 0.3, 0.6), CFrame.new(O + Vector3.new(math.cos(a) * 15.5, 1.15, math.sin(a) * 15.5)) * CFrame.Angles(0, -a, 0), th.c1, { Material = Enum.Material.Neon, Transparency = 0.25 })
	end
	local A = O + Vector3.new(0, 1, 0) -- floor centre
	local anvilTop = A + Vector3.new(0, 3.1, 0)
	local metal, metalLt = Color3.fromRGB(88, 76, 112), Color3.fromRGB(150, 136, 178)
	part(world, Vector3.new(3.2, 1, 2.2), CFrame.new(A + Vector3.new(0, 0.5, 0)), metal)
	part(world, Vector3.new(1.6, 1.4, 1.2), CFrame.new(A + Vector3.new(0, 1.7, 0)), metal)
	part(world, Vector3.new(4.4, 0.9, 1.9), CFrame.new(A + Vector3.new(0, 2.65, 0)), metalLt)
	part(world, Vector3.new(1.4, 0.7, 1.2), CFrame.new(A + Vector3.new(2.7, 2.75, 0)) * CFrame.Angles(0, 0, -0.35), metalLt)
	for _, x in { -9, 9 } do
		local br = part(world, Vector3.new(2.4, 2.4, 2.4), CFrame.new(A + Vector3.new(x, 1.2, -6)), metal)
		local fl = part(world, Vector3.new(1.6, 0.3, 1.6), br.CFrame * CFrame.new(0, 1.3, 0), th.c1, { Material = Enum.Material.Neon })
		emitter(fl, { Texture = FIRE, Rate = 18, Color = ColorSequence.new(th.c2, th.c1), Size = ns(1.4, 0.2), Transparency = ns(0.2, 1), Lifetime = NumberRange.new(0.6, 1), Speed = NumberRange.new(2, 4), EmissionDirection = Enum.NormalId.Top })
		local l = Instance.new("PointLight")
		l.Color, l.Range, l.Brightness = th.c1, 14, 1.4
		l.Parent = fl
	end

	-- the smith: Bolt the raccoon (the user's pick, 2026-11-08): grey fur, a dark mask with bright eyes, a white muzzle, round ears,
	-- a ringed tail, a butter apron and a pink bandana; the right arm swings the hammer about the shoulder
	local smith = {}
	local skinC, apron = Color3.fromRGB(150, 146, 168), Color3.fromRGB(255, 217, 112) -- skinC: Bolt's fur
	local FUR_D, FUR_L, MASK = Color3.fromRGB(96, 90, 116), Color3.fromRGB(196, 192, 210), Color3.fromRGB(64, 56, 82)
	local function piece(name, size, off, color, props)
		local p = part(world, size, CFrame.new(), color, props)
		p.Name = name
		table.insert(smith, { p = p, off = off, arm = name:sub(1, 3) == "Arm" or name:sub(1, 3) == "Ham" })
		return p
	end
	piece("Body", Vector3.new(2.4, 2.2, 1.6), CFrame.new(0, 2.6, 0), skinC)
	piece("Apron", Vector3.new(2.0, 1.9, 0.2), CFrame.new(0, 2.5, -0.85), apron)
	piece("Head", Vector3.new(2.6, 2.2, 2.3), CFrame.new(0, 4.8, 0), FUR_L)
	piece("Mask", Vector3.new(2.62, 0.7, 0.12), CFrame.new(0, 4.95, -1.17), MASK)
	for _, x in { -0.55, 0.55 } do
		piece("Eye", Vector3.new(0.38, 0.44, 0.08), CFrame.new(x, 4.95, -1.25), WHITE)
		piece("Pupil", Vector3.new(0.2, 0.28, 0.06), CFrame.new(x, 4.93, -1.3), INK)
		piece("Ear", Vector3.new(0.75, 0.75, 0.5), CFrame.new(x * 1.65, 6.2, 0), FUR_D)
		piece("EarIn", Vector3.new(0.42, 0.42, 0.06), CFrame.new(x * 1.65, 6.15, -0.27), Color3.fromRGB(255, 190, 205))
	end
	piece("Muzzle", Vector3.new(1.2, 0.65, 0.45), CFrame.new(0, 4.2, -1.3), Color3.fromRGB(250, 246, 240))
	piece("Nose", Vector3.new(0.46, 0.28, 0.24), CFrame.new(0, 4.55, -1.48), INK) -- on the muzzle's top edge
	piece("Bandana", Vector3.new(2.66, 0.45, 2.36), CFrame.new(0, 5.72, 0), Color3.fromRGB(255, 157, 176))
	for k = 1, 4 do -- the ringed tail curls up behind
		piece("Tail", Vector3.new(0.85, 0.85, 0.85), CFrame.new(0, 1.4 + k * 0.5, 0.95 + k * 0.42) * CFrame.Angles(0.3 * k, 0, 0), k % 2 == 0 and MASK or FUR_L)
	end
	piece("LegL", Vector3.new(0.9, 1.4, 1.0), CFrame.new(-0.6, 0.75, 0), FUR_D)
	piece("LegR", Vector3.new(0.9, 1.4, 1.0), CFrame.new(0.6, 0.75, 0), FUR_D)
	piece("PawL", Vector3.new(0.8, 1.8, 0.8), CFrame.new(-1.6, 2.6, 0), skinC) -- the left arm hangs at the side
	piece("ArmR", Vector3.new(0.8, 1.8, 0.8), CFrame.new(0, -0.8, 0), skinC) -- relative to the right shoulder pivot
	piece("HammerHandle", Vector3.new(0.3, 2.4, 0.3), CFrame.new(0, -1.9, -0.9) * CFrame.Angles(math.pi / 2, 0, 0), Color3.fromRGB(170, 122, 92))
	piece("HammerHead", Vector3.new(1.2, 0.9, 0.9), CFrame.new(0, -1.9, -2.0), metalLt)
	local shoulder = CFrame.new(1.6, 3.4, 0)
	local smithBase = CFrame.new(A + Vector3.new(0, 0, 4.2)) -- behind the anvil, facing it (and the camera)
	local glowRing = part(world, Vector3.new(0.2, 6, 6), CFrame.new(), th.c1, { Shape = Enum.PartType.Cylinder, Material = Enum.Material.Neon, Transparency = 1 })
	local aura = emitter(glowRing, { Texture = SPARK, Color = ColorSequence.new(th.c1, th.c2), Size = ns(0.6, 0), Transparency = ns(0, 1), Lifetime = NumberRange.new(0.6, 1.2), Speed = NumberRange.new(2, 5), SpreadAngle = Vector2.new(30, 30), EmissionDirection = Enum.NormalId.Right })

	-- the core: layered neon balls, a light, a swirl of sparkles, orbiting motes, crackling tendrils
	local corePos = A + Vector3.new(0, 7.5, 0)
	local core = part(world, Vector3.one, CFrame.new(corePos), th.c1, { Shape = Enum.PartType.Ball, Material = Enum.Material.Neon, Transparency = 1 })
	local coreIn = part(world, Vector3.one, CFrame.new(corePos), WHITE, { Shape = Enum.PartType.Ball, Material = Enum.Material.Neon, Transparency = 1 })
	local coreLight = Instance.new("PointLight")
	coreLight.Color, coreLight.Range, coreLight.Brightness, coreLight.Shadows = th.c1, 0, 0, false
	coreLight.Parent = core
	local swirl = emitter(core, { Texture = SPARK, Color = ColorSequence.new(th.c2, th.c1), Size = ns(0.9, 0), Transparency = ns(0, 1), Lifetime = NumberRange.new(0.4, 0.8), Speed = NumberRange.new(-6, -3), RotSpeed = NumberRange.new(-200, 200), SpreadAngle = Vector2.new(180, 180), Shape = Enum.ParticleEmitterShape.Sphere, ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface })
	local bursts = emitter(core, { Texture = SPARK, Color = ColorSequence.new(WHITE, th.c1), Size = ns(1.2, 0), Transparency = ns(0, 1), Lifetime = NumberRange.new(0.4, 0.9), Speed = NumberRange.new(14, 30), Drag = 4, SpreadAngle = Vector2.new(180, 180) })
	local billboard = Instance.new("BillboardGui")
	billboard.Size, billboard.AlwaysOnTop, billboard.LightInfluence = UDim2.fromScale(14, 14), false, 0
	billboard.Adornee, billboard.Parent = core, world
	local bbGlow = Instance.new("ImageLabel")
	bbGlow.BackgroundTransparency, bbGlow.Image, bbGlow.ImageColor3, bbGlow.ImageTransparency = 1, GLOW, th.c1, 1
	bbGlow.Size, bbGlow.Position, bbGlow.AnchorPoint = UDim2.fromScale(1, 1), UDim2.fromScale(0.5, 0.5), Vector2.new(0.5, 0.5)
	bbGlow.Parent = billboard
	local bbRays = bbGlow:Clone()
	bbRays.Image, bbRays.ImageColor3 = RAYS, th.c2
	bbRays.Parent = billboard
	local motes = {}
	for k = 1, 14 do
		local m = part(world, Vector3.one * 0.45, CFrame.new(corePos), k % 2 == 0 and th.c1 or th.c2, { Shape = Enum.PartType.Ball, Material = Enum.Material.Neon, Transparency = 1 })
		local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
		a0.Position, a1.Position = Vector3.new(0, 0.2, 0), Vector3.new(0, -0.2, 0)
		a0.Parent, a1.Parent = m, m
		local tr = Instance.new("Trail")
		tr.Attachment0, tr.Attachment1, tr.Lifetime, tr.LightEmission = a0, a1, 0.35, 1
		tr.Color, tr.Transparency, tr.WidthScale = ColorSequence.new(m.Color), ns(0.1, 1), ns(1, 0)
		tr.FaceCamera, tr.Parent = true, m
		motes[k] = { p = m, a = k / 14 * math.pi * 2, r = 5 + (k % 3), h = (k % 4 - 1.5) * 0.9, sp = 2.2 + (k % 5) * 0.35 }
	end
	local tendrils = {}
	local coreAtt = Instance.new("Attachment")
	coreAtt.Parent = core
	for k = 1, 4 do -- crackling energy beams from the braziers and the floor to the core while it is squeezed
		local at = Instance.new("Attachment")
		local a = k / 4 * math.pi * 2 + 0.4
		at.WorldPosition = A + Vector3.new(math.cos(a) * 11, 0.6, math.sin(a) * 11)
		at.Parent = plat
		local b = Instance.new("Beam")
		b.Attachment0, b.Attachment1, b.Width0, b.Width1 = at, coreAtt, 0.5, 0.15
		b.Color, b.LightEmission, b.LightInfluence, b.FaceCamera, b.Segments = ColorSequence.new(th.c2, th.c1), 1, 0, true, 16
		b.Transparency = NumberSequence.new(1)
		b.Parent = plat
		tendrils[k] = b
	end

	-- the falling (or rising) material for act 2 and 3
	local streaks = {}
	for k = 1, 18 do
		local s = part(world, Vector3.one * 0.7, CFrame.new(O), k % 3 == 0 and th.c2 or th.c1, { Shape = Enum.PartType.Ball, Material = Enum.Material.Neon, Transparency = 1 })
		local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
		a0.Position, a1.Position = Vector3.new(0, 0.35, 0), Vector3.new(0, -0.35, 0)
		a0.Parent, a1.Parent = s, s
		local tr = Instance.new("Trail")
		tr.Attachment0, tr.Attachment1, tr.Lifetime, tr.LightEmission = a0, a1, th.fall == "meteor" and 0.5 or 0.3, 1
		tr.Color, tr.Transparency, tr.WidthScale, tr.FaceCamera = ColorSequence.new(WHITE, s.Color), ns(0, 1), ns(1, 0), true
		tr.Parent = s
		local a = math.random() * math.pi * 2
		local start = th.fall == "meteor" and (A + Vector3.new(math.cos(a) * 40 - 30, 60 + math.random() * 20, math.sin(a) * 30))
			or (A + Vector3.new(math.cos(a) * (8 + math.random() * 10), 0.5, math.sin(a) * (8 + math.random() * 10)))
		streaks[k] = { p = s, start = start, t0 = 0.9 + (k - 1) * 0.12 + math.random() * 0.15, dur = 1.1 + math.random() * 0.5, side = math.random() < 0.5 and -1 or 1 }
	end

	-- slam effects: a spark fountain, two floor shockwaves, a light pillar, embers
	local fountainP = part(world, Vector3.one * 0.2, CFrame.new(anvilTop) * CFrame.Angles(0, 0, math.pi / 2), WHITE, { Transparency = 1 })
	local fountain = emitter(fountainP, { Texture = SPARK, Color = ColorSequence.new(WHITE, th.c1), Size = ns(0.9, 0.1), Transparency = ns(0, 1), Lifetime = NumberRange.new(0.6, 1.3), Speed = NumberRange.new(20, 42), Drag = 1.5, Acceleration = Vector3.new(0, -45, 0), SpreadAngle = Vector2.new(70, 70), EmissionDirection = Enum.NormalId.Right })
	local embers = emitter(fountainP, { Texture = SPARK, Color = ColorSequence.new(th.c2, th.c1), Size = ns(0.5, 0), Transparency = ns(0.2, 1), Lifetime = NumberRange.new(1.5, 2.5), Speed = NumberRange.new(2, 6), Acceleration = Vector3.new(0, 4, 0), SpreadAngle = Vector2.new(90, 90), EmissionDirection = Enum.NormalId.Right })
	local waves = {}
	for k = 1, 3 do waves[k] = part(world, Vector3.new(0.3, 2, 2), CFrame.new(A + Vector3.new(0, 0.2 + k * 0.05, 0)) * CFrame.Angles(0, 0, math.pi / 2), k == 2 and th.c2 or th.c1, { Shape = Enum.PartType.Cylinder, Material = Enum.Material.Neon, Transparency = 1 }) end
	local pillar = part(world, Vector3.new(60, 4, 4), CFrame.new(A + Vector3.new(0, 30, 0)) * CFrame.Angles(0, 0, math.pi / 2), th.c2, { Shape = Enum.PartType.Cylinder, Material = Enum.Material.Neon, Transparency = 1 })

	-- the pickaxe: the real model (ReplicatedStorage.PickaxeArt), held over the anvil for the reveal
	local pick
	local lib = RS:FindFirstChild("PickaxeArt")
	local src = lib and lib:FindFirstChild(opt.model or "")
	if src then
		pick = src:Clone()
		for _, d in pick:GetDescendants() do
			if d:IsA("BasePart") then d.Anchored, d.CanCollide, d.CanQuery = true, false, false end
		end
		pick.Parent = world
	end
	local pickSize = pick and select(2, pick:GetBoundingBox()) or Vector3.one
	local pickScale0 = pick and pick:GetScale() or 1

	-- screen layer: the star wipe, letterbox, caption, flash, name card, skip
	local gui = Instance.new("ScreenGui")
	gui.Name, gui.IgnoreGuiInset, gui.ResetOnSpawn, gui.DisplayOrder, gui.ZIndexBehavior = "ForgeCutsceneGui", true, false, 30, Enum.ZIndexBehavior.Sibling
	local pg = plr:WaitForChild("PlayerGui")
	local hidden = {}
	for _, g in pg:GetChildren() do
		if g:IsA("ScreenGui") and g.Enabled then g.Enabled = false table.insert(hidden, g) end
	end
	gui.Parent = pg
	local function frame(props)
		local f = Instance.new("Frame")
		f.BorderSizePixel = 0
		for k, v in props do f[k] = v end
		f.Parent = props.Parent or gui
		return f
	end
	local barT = frame({ Size = UDim2.fromScale(1, 0.11), Position = UDim2.fromScale(0, -0.11), BackgroundColor3 = Color3.fromRGB(14, 8, 22), ZIndex = 5 })
	local barB = frame({ Size = UDim2.fromScale(1, 0.11), Position = UDim2.fromScale(0, 1), BackgroundColor3 = Color3.fromRGB(14, 8, 22), ZIndex = 5 })
	local caption = Instance.new("TextLabel")
	caption.BackgroundTransparency, caption.Font, caption.TextScaled, caption.Text = 1, Enum.Font.FredokaOne, true, th.caption
	caption.TextColor3, caption.TextTransparency, caption.ZIndex = WHITE, 1, 6
	caption.Size, caption.Position, caption.AnchorPoint = UDim2.fromScale(0.6, 0.05), UDim2.fromScale(0.5, 0.945), Vector2.new(0.5, 0.5)
	local capStroke = Instance.new("UIStroke")
	capStroke.Color, capStroke.Thickness, capStroke.Transparency = th.c1:Lerp(INK, 0.5), 3, 1
	capStroke.Parent = caption
	caption.Parent = gui
	local flash = frame({ Size = UDim2.fromScale(1, 1), BackgroundColor3 = WHITE, BackgroundTransparency = 1, ZIndex = 8 })
	local wipe = Instance.new("ImageLabel")
	wipe.BackgroundTransparency, wipe.Image, wipe.ImageColor3, wipe.ZIndex = 1, STAR, th.c1, 9
	wipe.Size, wipe.Position, wipe.AnchorPoint = UDim2.fromScale(0, 0), UDim2.fromScale(0.5, 0.5), Vector2.new(0.5, 0.5)
	local wipeAspect = Instance.new("UIAspectRatioConstraint")
	wipeAspect.AspectRatio, wipeAspect.DominantAxis = 1, Enum.DominantAxis.Width
	wipeAspect.Parent = wipe
	wipe.Parent = gui
	local card = frame({ Size = UDim2.fromScale(0.36, 0.11), Position = UDim2.fromScale(0.5, 0.79), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Color3.fromRGB(255, 250, 243), BackgroundTransparency = 1, ZIndex = 6 })
	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0.5, 0)
	cardCorner.Parent = card
	local cardStroke = Instance.new("UIStroke")
	cardStroke.Color, cardStroke.Thickness, cardStroke.Transparency = opt.rarity[3], 4, 1
	cardStroke.Parent = card
	local cardName = caption:Clone()
	cardName.Text, cardName.TextColor3, cardName.Size, cardName.Position = string.upper(opt.name), INK, UDim2.fromScale(0.86, 0.5), UDim2.fromScale(0.5, 0.36)
	cardName.UIStroke.Transparency = 1
	cardName.Parent = card
	local cardRar = caption:Clone()
	cardRar.Text, cardRar.TextColor3, cardRar.Size, cardRar.Position = string.upper(opt.rarity[1]), opt.rarity[3], UDim2.fromScale(0.5, 0.3), UDim2.fromScale(0.5, 0.76)
	cardRar.UIStroke.Transparency = 1
	cardRar.Parent = card
	local skip = Instance.new("TextButton")
	skip.Size, skip.Position, skip.AnchorPoint = UDim2.fromScale(0.09, 0.055), UDim2.fromScale(0.95, 0.06), Vector2.new(1, 0)
	skip.BackgroundColor3, skip.BackgroundTransparency, skip.Font, skip.TextScaled, skip.Text = Color3.fromRGB(255, 250, 243), 0.1, Enum.Font.FredokaOne, true, "SKIP"
	skip.TextColor3, skip.ZIndex, skip.AutoButtonColor, skip.Visible = INK, 7, true, false
	local skipCorner = cardCorner:Clone()
	skipCorner.Parent = skip
	skip.Parent = gui

	-- lighting: night or dusk for the theme, restored after; blur and depth of field off while the scene plays
	local camSaved = { CameraType = cam.CameraType, CameraSubject = cam.CameraSubject, FieldOfView = cam.FieldOfView }
	local saved = { ClockTime = Lighting.ClockTime, Brightness = Lighting.Brightness, Ambient = Lighting.Ambient, OutdoorAmbient = Lighting.OutdoorAmbient, ExposureCompensation = Lighting.ExposureCompensation }
	local off = {}
	for _, root in { Lighting, cam } do
		for _, e in root:GetChildren() do
			if (e:IsA("BlurEffect") or e:IsA("DepthOfFieldEffect")) and e.Enabled then e.Enabled = false table.insert(off, e) end
		end
	end
	local cc = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
	local ccSaved = cc and { Brightness = cc.Brightness, TintColor = cc.TintColor, Saturation = cc.Saturation }
	local hiddenVm = {}
	for _, m in cam:GetChildren() do -- the first-person viewmodel would float in front of the scene
		for _, d in m:GetDescendants() do
			if d:IsA("BasePart") and d.LocalTransparencyModifier < 1 then d.LocalTransparencyModifier = 1 table.insert(hiddenVm, d) end
		end
	end
	local function stageLighting()
		Lighting.ClockTime = th.night and 0 or (th.dusk and 18.3 or 14)
		Lighting.Brightness = th.night and 1 or 2
		Lighting.Ambient = th.c1:Lerp(Color3.new(0, 0, 0), 0.6)
		Lighting.OutdoorAmbient = th.c1:Lerp(Color3.new(0, 0, 0), 0.45)
		Lighting.ExposureCompensation = 0
		if cc then cc.TintColor, cc.Saturation = th.c2:Lerp(WHITE, 0.75), 0.15 end
	end

	-- the clock: t advances with real time except during the hit-stop; Skip jumps to act 5
	local T_END = 8.0
	local t, last, holdUntil, fired, done = 0, os.clock(), 0, {}, false
	local quickJumped = false -- opt.quick (an upgrade): from the swap straight to the drop, slam and reveal
	local camCF, fov, kick, shake = CFrame.new(), 70, 0, 0
	local function once(key, at, fn)
		if t >= at and not fired[key] then
			fired[key] = true
			fn()
		end
	end
	skip.Activated:Connect(function()
		if t < 7.3 then
			for _, k in { "wipe1", "act2", "rise", "sq1", "sq2", "sq3", "slam", "reveal" } do fired[k] = true end
			t = 7.3
		end
	end)
	local smithY, armA = 0, 0
	RunService:BindToRenderStep("ForgeCut", Enum.RenderPriority.Camera.Value + 20, function()
		local now = os.clock()
		local dt = math.min(now - last, 0.1)
		last = now
		if now >= holdUntil then t += dt end
		if opt.quick and not quickJumped and t >= 0.9 then
			quickJumped = true
			t = 5.0
			for _, s in streaks do s.hit = true end
			for i = 1, 3 do fired["sq" .. i] = true end
		end
		cam.CameraType = Enum.CameraType.Scriptable

		-- act 1: the star wipe grows out of the screen, the scene swaps behind it, then it shrinks away
		local w = t < 0.45 and smooth(0, 0.45, t) or (t < 0.9 and 1 - smooth(0.45, 0.9, t) or (t > 7.4 and smooth(7.4, 7.75, t) or 0))
		wipe.Size, wipe.Rotation = UDim2.fromScale(3.2 * w, 3.2 * w), t * 40
		once("wipe1", 0.45, function()
			stageLighting()
			skip.Visible = true
			sfx("swing", 0.7)
		end)
		local lb = smooth(0.5, 1.0, t) * (1 - smooth(7.3, 7.6, t))
		barT.Position, barB.Position = UDim2.fromScale(0, -0.11 + 0.11 * lb), UDim2.fromScale(0, 1 - 0.11 * lb)
		local capA = smooth(0.9, 1.3, t) * (1 - smooth(2.6, 3.0, t))
		caption.TextTransparency, capStroke.Transparency = 1 - capA, 1 - capA

		-- act 2: the material arrives (meteors fall from the sky, or motes rise from the floor), curving into the core
		for _, s in streaks do
			local u = math.clamp((t - s.t0) / s.dur, 0, 1)
			s.p.Transparency = (u > 0 and u < 1) and 0 or 1
			if u > 0 and u < 1 then
				local mid = th.fall == "meteor" and (s.start:Lerp(corePos, 0.5) + Vector3.new(s.side * 10, 6, 0)) or (s.start:Lerp(corePos, 0.5) + Vector3.new(s.side * 4, 4, 0))
				local e = u * u
				local p = (1 - e) ^ 2 * s.start + 2 * (1 - e) * e * mid + e * e * corePos
				s.p.CFrame = CFrame.new(p)
			end
			if u >= 1 and not s.hit then
				s.hit = true
				bursts:Emit(6)
				sfx("clink", 1.6 + math.random() * 0.4)
			end
		end

		-- the smith: idle, looks up, floats up on a glowing ring, squeezes, drops, swings the hammer
		local rise = smooth(2.4, 3.6, t) * (1 - smooth(5.45, 5.65, t))
		smithY = rise * 6 + math.sin(t * 3) * 0.25 * rise
		local swing = 0
		if t > 5.45 and t < 5.85 then swing = -2.2 * smooth(5.45, 5.8, t) -- raise
		elseif t >= 5.85 then swing = -2.2 + 3.0 * smooth(5.85, 5.95, t) - 0.8 * smooth(6.2, 6.8, t) end -- slam, settle
		local reach = rise * 2.4 -- the hammer arm raised up and forward while floating
		local aside = smooth(6.0, 6.5, t)
		local base = smithBase * CFrame.new(7 * aside, smithY, -2 * aside) * CFrame.Angles(0, -0.5 * aside, 0)
		for _, sp in smith do
			if sp.arm then
				sp.p.CFrame = base * shoulder * CFrame.Angles(swing + reach, 0, 0) * sp.off
			else
				sp.p.CFrame = base * sp.off
			end
		end
		glowRing.CFrame = base * CFrame.new(0, 0.2, 0) * CFrame.Angles(0, 0, math.pi / 2)
		glowRing.Transparency = 1 - 0.6 * rise
		aura.Rate = rise * 40

		-- act 3: the core gathers, the motes orbit and spiral in, three squeezes, tendrils crackle
		local gather = smooth(1.6, 3.9, t)
		local sq = 0
		for i, at in { 3.9, 4.4, 4.9 } do
			once("sq" .. i, at, function()
				sfx("clink", 1.0 + (i - 1) * 0.12)
				sfx("sparkle", 1.1 + i * 0.1)
				bursts:Emit(30 + i * 10)
				kick = 4 + i
				shake = 0.25 + i * 0.1
				for k, wv in waves do
					if k == i then wv.Size = Vector3.new(0.3, 2, 2) wv.Transparency = 0.1 wv:SetAttribute("Born", t) wv:SetAttribute("At", corePos.Y) end
				end
			end)
			local d = t - at
			if d > 0 and d < 0.35 then sq = math.max(sq, math.sin(d / 0.35 * math.pi)) end
		end
		local compact = smooth(3.9, 5.2, t)
		local coreR = (0.4 + gather * 2.6) * (1 - 0.35 * compact) * (1 - 0.3 * sq)
		local landed = smooth(5.5, 5.85, t)
		local cPos = corePos:Lerp(anvilTop + Vector3.new(0, 0.6, 0), landed)
		local vis = gather > 0.01 and t < 6.05
		core.Size, coreIn.Size = Vector3.one * coreR * 2, Vector3.one * coreR * 1.2
		core.CFrame, coreIn.CFrame = CFrame.new(cPos), CFrame.new(cPos)
		core.Transparency, coreIn.Transparency = vis and 0.15 or 1, vis and 0 or 1
		coreLight.Range, coreLight.Brightness = vis and (10 + 20 * gather) or 0, vis and (1 + 3 * compact) or 0
		swirl.Rate = vis and (20 + 80 * gather) or 0
		bbGlow.ImageTransparency = vis and (1 - 0.8 * gather) or 1
		bbRays.ImageTransparency = vis and (1 - 0.7 * compact) or 1
		bbRays.Rotation = t * 60
		billboard.Size = UDim2.fromScale(6 + coreR * 6, 6 + coreR * 6)
		if t >= 6.0 and t < 7.5 then -- the reveal: the glow and rays come back behind the pickaxe
			local r = smooth(6.0, 6.3, t) * (1 - smooth(7.3, 7.5, t))
			core.CFrame = CFrame.new(anvilTop + Vector3.new(0, 4.2, 0.6))
			bbGlow.ImageTransparency, bbRays.ImageTransparency = 1 - 0.75 * r, 1 - 0.6 * r
			billboard.Size = UDim2.fromScale(10 + 4 * r, 10 + 4 * r)
		end
		for _, m in motes do
			local on = t > 2.4 and t < 5.6
			m.p.Transparency = on and 0 or 1
			if on then
				local r = m.r * (1 - 0.8 * compact)
				local a = m.a + t * m.sp * (1 + 2 * compact)
				m.p.CFrame = CFrame.new(cPos + Vector3.new(math.cos(a) * r, m.h * (1 - compact) + math.sin(a * 2) * 0.6, math.sin(a) * r))
			end
		end
		local crackle = smooth(3.7, 4.0, t) * (1 - smooth(5.4, 5.6, t))
		for k, b in tendrils do
			b.Transparency = NumberSequence.new(1 - 0.9 * crackle)
			b.CurveSize0, b.CurveSize1 = (math.random() - 0.5) * 8 * crackle, (math.random() - 0.5) * 8 * crackle
			b.Width0 = 0.3 + 0.4 * sq
		end

		-- act 4: drop, hammer slam with a hold, flash, sparks, shockwaves, the light pillar, then the reveal
		once("slam", 5.85, function()
			holdUntil = os.clock() + 0.12 -- the dead hold before the flash
			sfx("breakRock", 0.7)
			sfx("clink", 0.8)
			fountain:Emit(160)
			embers:Emit(60)
			bursts:Emit(80)
			kick, shake = 10, 1.2
			for k, wv in waves do wv.Size = Vector3.new(0.3, 2, 2) wv.Transparency = 0.05 wv:SetAttribute("Born", t + k * 0.08) wv:SetAttribute("At", A.Y + 0.2 + k * 0.05) end
			pillar:SetAttribute("Born", t)
			flash.BackgroundTransparency = 0
		end)
		flash.BackgroundTransparency = math.min(1, flash.BackgroundTransparency + dt * 5)
		for _, wv in waves do
			local born = wv:GetAttribute("Born")
			if born and t >= born then
				local u = math.clamp((t - born) / 0.7, 0, 1)
				local r = 2 + u * (wv:GetAttribute("At") > A.Y + 3 and 16 or 34)
				wv.Size = Vector3.new(0.3, r, r)
				wv.CFrame = CFrame.new(Vector3.new(A.X, wv:GetAttribute("At"), A.Z)) * CFrame.Angles(0, 0, math.pi / 2)
				wv.Transparency = 0.05 + 0.95 * u
			end
		end
		local pb = pillar:GetAttribute("Born")
		if pb then
			local u = math.clamp((t - pb) / 0.5, 0, 1)
			pillar.Size = Vector3.new(60, 1.6 * (1 - u) + 0.2, 1.6 * (1 - u) + 0.2)
			pillar.Transparency = 0.3 + 0.7 * math.sqrt(u)
		end
		once("reveal", 6.0, function()
			sfx("upgrade", 1)
			sfx("sparkle", 1.3)
		end)
		if pick then
			local u = math.clamp((t - 6.0) / 0.5, 0, 1)
			local show = t >= 6.0
			local s = show and math.max(0.05, backOut(u)) or 0.05
			pick:ScaleTo(pickScale0 * s * (5.5 / math.max(pickSize.Y, 0.1)))
			local spin = smooth(6.0, 7.2, t) * math.pi * 2
			pick:PivotTo(CFrame.new(anvilTop + Vector3.new(0, 1.5 + 2.6 * smooth(6.0, 6.6, t) + math.sin(t * 2) * 0.15, 0)) * CFrame.Angles(0, math.pi + spin, math.rad(-20)))
			for _, d in pick:GetDescendants() do
				if d:IsA("BasePart") then d.LocalTransparencyModifier = show and 0 or 1 end
			end
		end
		local cardA = smooth(6.3, 6.6, t) * (1 - smooth(7.3, 7.5, t))
		card.BackgroundTransparency, cardStroke.Transparency = 1 - cardA * 0.96, 1 - cardA
		cardName.TextTransparency, cardRar.TextTransparency = 1 - cardA, 1 - cardA
		card.Position = UDim2.fromScale(0.5, 0.82 - 0.03 * cardA)

		-- the camera: wide and low, tilt up with the smith, close on the core, whip to the anvil, slow push on the hero
		local wide = CFrame.lookAt(A + Vector3.new(-14, 6, -24), A + Vector3.new(0, 6, 0))
		local up = CFrame.lookAt(A + Vector3.new(-10, 8, -20), A + Vector3.new(0, 12, 2))
		local close = CFrame.lookAt(cPos + Vector3.new(-5, 1.5, -10), cPos)
		local anvilCam = CFrame.lookAt(A + Vector3.new(-6, 5, -11), anvilTop)
		local hero = CFrame.lookAt(anvilTop + Vector3.new(-2.5, 3.2, -8.5 + 1.5 * smooth(6.0, 7.4, t)), anvilTop + Vector3.new(0, 3.2, 0))
		local cf = wide:Lerp(up, smooth(2.2, 3.4, t))
		cf = cf:Lerp(close, smooth(3.6, 4.0, t))
		cf = cf:Lerp(anvilCam, smooth(5.4, 5.6, t))
		cf = cf:Lerp(hero, smooth(5.95, 6.3, t))
		fov = 70 - 6 * smooth(0.9, 2.4, t) - 14 * smooth(3.6, 4.0, t) * (1 - smooth(5.4, 5.6, t))
		kick *= math.exp(-dt * 9)
		shake *= math.exp(-dt * 7)
		local sx, sy = math.noise(t * 25, 1) * shake, math.noise(t * 25, 2) * shake
		cam.CFrame = cf * CFrame.Angles(sy * 0.05, sx * 0.05, sx * 0.02)
		cam.FieldOfView = fov - kick

		if t >= T_END then done = true end
	end)
	local started = os.clock()
	while not done and os.clock() - started < 20 do task.wait() end -- never hang the player in the scene
	RunService:UnbindFromRenderStep("ForgeCut")
	-- put everything back: lighting, effects, viewmodel, HUD, camera
	for k, v in saved do Lighting[k] = v end
	if cc and ccSaved then for k, v in ccSaved do cc[k] = v end end
	for _, e in off do e.Enabled = true end
	for _, d in hiddenVm do if d.Parent then d.LocalTransparencyModifier = 0 end end
	for _, g in hidden do if g.Parent then g.Enabled = true end end
	for k, v in camSaved do pcall(function() cam[k] = v end) end
	world:Destroy()
	-- the wipe shrinks away over the restored view, then the layer goes
	local tw = TweenService:Create(wipe, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = UDim2.fromScale(0, 0) })
	tw:Play()
	task.delay(0.32, function() gui:Destroy() end)
end

return M
