-- ReplicatedStorage.Shared.ForgeStory (src/ForgeStory.luau): the player for the forge biographies.
-- The user (2026-11-15): every pickaxe gets its own forge scene that tells where and how it was made, like a biography, with its
-- own models, backdrop, effects, animation and characters. Brief: vault Projects/Pixel-_/Briefs/Forge Biographies (2026-11-15).md.
-- This module is the only shared part: the clock, skip, chapter cards, camera, lighting save and restore, and the rigs (models
-- from ReplicatedStorage.ForgeModels, built in design3d/*.mjs; each limb is its own MeshPart on a joint, data in ForgeRigs).
-- A scene is its own module (ForgeWood, ...): { length, named, open, setup = function(ctx) return function(t, dt) end end }.
-- open = true: the scene builds a whole place of its own under its own sky (ctx.sky, ctx.atmo, ctx.prop), so no shell is put round it.
-- Client only and cosmetic: the server has already charged and given the pickaxe.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local RS = game:GetService("ReplicatedStorage")

local M = {}
M.SCENES = { WoodPickaxe = "ForgeWood", __turn = "ForgeTurn" } -- pickaxe model name -> scene module in Shared (__turn: the test stage for grading one model alone)

local WHITE, INK, NIGHT = Color3.new(1, 1, 1), Color3.fromRGB(62, 42, 86), Color3.fromRGB(22, 8, 30)
local GLOW = "rbxassetid://77591933607769"
M.GLOW, M.SPARK, M.FIRE, M.SMOKE = GLOW, "rbxasset://textures/particles/sparkles_main.dds", "rbxasset://textures/particles/fire_main.dds", "rbxasset://textures/particles/smoke_main.dds"

function M.smooth(a, b, t)
	local x = math.clamp((t - a) / (b - a), 0, 1)
	return x * x * (3 - 2 * x)
end
function M.lin(a, b, t) return math.clamp((t - a) / (b - a), 0, 1) end
function M.backOut(x)
	local c = 1.70158
	x -= 1
	return 1 + (c + 1) * x * x * x + c * x * x
end
function M.step(t, fps) return math.floor(t * (fps or 12)) / (fps or 12) end -- stop-motion: characters pose 12 times a second
local EASE = {
	lin = function(x) return x end,
	out = function(x) return 1 - (1 - x) * (1 - x) end,
	["in"] = function(x) return x * x end,
	inout = function(x) return x * x * (3 - 2 * x) end,
	back = M.backOut,
	hold = function(x) return x >= 1 and 1 or 0 end,
}
local function rot(x, y, z) return CFrame.Angles(math.rad(x or 0), math.rad(y or 0), math.rad(z or 0)) end
M.rot = rot

-- a pose track: keys = { { t, { Bone = CFrame, ... }, ease }, ... } in time order; a bone missing from a key keeps its last value
-- returns sample(t) -> { Bone = CFrame }
function M.track(keys)
	local bones = {}
	for _, k in keys do for b in k[2] do bones[b] = true end end
	local per = {} -- per bone: the list of { t, cf, ease }
	for b in bones do
		local list = {}
		for _, k in keys do if k[2][b] then table.insert(list, { k[1], k[2][b], EASE[k[3] or "inout"] }) end end
		per[b] = list
	end
	return function(t)
		local out = {}
		for b, list in per do
			local cf = list[1][2]
			for i = 2, #list do
				local a, k = list[i - 1], list[i]
				if t >= k[1] then cf = k[2] elseif t > a[1] then cf = a[2]:Lerp(k[2], k[3]((t - a[1]) / (k[1] - a[1]))) break else break end
			end
			out[b] = cf
		end
		return out
	end
end

-- a rig: a clone of ForgeModels[name]; every bone turns about its joint
local Rig = {}
Rig.__index = Rig
local function newRig(name, parent)
	local src = RS:FindFirstChild("ForgeModels") and RS.ForgeModels:FindFirstChild(name)
	local data = require(script.Parent:WaitForChild("ForgeRigs"))[name]
	if not src or not data then error("ForgeStory: no model " .. name) end
	local model = src:Clone()
	local self = setmetatable({ model = model, bones = {}, order = {}, root = CFrame.new(), scale = 1 }, Rig)
	for _, b in data do
		local p = b.center and model:FindFirstChild(b.name)
		local bone = { name = b.name, parent = b.parent, joint = b.joint, part = p, local_ = CFrame.new(), s = Vector3.one, world = CFrame.new(), shown = true }
		if p then bone.off, bone.size, bone.rot0 = b.center - b.joint, p.Size, p.CFrame.Rotation end
		self.bones[b.name] = bone
		table.insert(self.order, bone)
	end
	model.Parent = parent
	return self
end
function Rig:set(bone, cf) self.bones[bone].local_ = cf end
function Rig:pose(p) for b, cf in p do local bn = self.bones[b] if bn then bn.local_ = cf end end end
function Rig:size(bone, s) self.bones[bone].s = typeof(s) == "number" and Vector3.new(s, s, s) or s end
function Rig:show(bone, on)
	local b = self.bones[bone]
	if b.shown ~= on then b.shown = on if b.part then b.part.Transparency = on and (b.alpha or 0) or 1 end end
end
function Rig:alpha(bone, a) -- 0 solid .. 1 invisible
	local b = self.bones[bone]
	b.alpha = a
	if b.part and b.shown then b.part.Transparency = a end
end
function Rig:all(fn) for _, b in self.order do if b.part then fn(b.part, b) end end end
function Rig:joint(bone) return self.bones[bone].world end -- the world frame of a joint (after update)
function Rig:update()
	local s = self.scale
	for _, b in self.order do
		local par = b.parent and self.bones[b.parent]
		b.world = (par and par.world * CFrame.new((b.joint - par.joint) * s) or self.root * CFrame.new(b.joint * s)) * b.local_
		if b.part then
			b.part.CFrame = b.world * CFrame.new(b.off * s * b.s) * b.rot0
			b.part.Size = b.size * s * b.s
		end
	end
end
function Rig:destroy() self.model:Destroy() end

function M.has(model)
	local n = M.SCENES[model]
	return n ~= nil and script.Parent:FindFirstChild(n) ~= nil and RS:FindFirstChild("ForgeModels") ~= nil
end

-- opt: { name, model, rarity = { label, odds, colour }, sfx = fn(name, pitch), fast = bool (NAMED only), freeze = t (test hook) }
-- yields until the scene has ended; returns true when it played
function M.play(opt)
	local sceneName = M.SCENES[opt.model]
	local scene = sceneName and require(script.Parent:WaitForChild(sceneName))
	if not scene or M.playing then return false end -- one scene at a time
	M.playing = true
	local plr = Players.LocalPlayer
	local cam = workspace.CurrentCamera
	local sfx = opt.sfx or function() end
	local world = Instance.new("Folder")
	world.Name = "ForgeStage"
	world.Parent = workspace
	local O = CFrame.new(4000, 400, 600) -- far from the town, the mines, the caves and the old forge stage

	-- a plum shell round the stage, so no game sky or world shows behind the paper backdrop
	local function wall(size, cf)
		local p = Instance.new("Part")
		p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
		p.Size, p.CFrame, p.Color, p.Material = size, O * cf, NIGHT, Enum.Material.SmoothPlastic
		p.Parent = world
		return p
	end
	if not scene.open then
		wall(Vector3.new(400, 260, 2), CFrame.new(0, 60, 60)) wall(Vector3.new(400, 260, 2), CFrame.new(0, 60, -120))
		wall(Vector3.new(2, 260, 400), CFrame.new(-110, 60, 0)) wall(Vector3.new(2, 260, 400), CFrame.new(110, 60, 0))
		wall(Vector3.new(400, 2, 400), CFrame.new(0, 150, 0)) wall(Vector3.new(400, 2, 400), CFrame.new(0, -40, 0))
	end

	-- lighting: save, then let the scene drive it
	local LKEYS = { "ClockTime", "Brightness", "Ambient", "OutdoorAmbient", "ColorShift_Top", "ColorShift_Bottom", "FogEnd", "FogStart", "FogColor", "ExposureCompensation", "GeographicLatitude", "EnvironmentDiffuseScale", "EnvironmentSpecularScale", "GlobalShadows" }
	local saved, off = {}, {}
	for _, k in LKEYS do saved[k] = Lighting[k] end
	for _, e in Lighting:GetChildren() do
		if (e:IsA("PostEffect") or e:IsA("Atmosphere")) then
			if e:IsA("Atmosphere") then table.insert(off, { e, "Density", e.Density }) e.Density = 0
			elseif e.Enabled then table.insert(off, { e, "Enabled", true }) e.Enabled = false end
		end
	end
	local cc = Instance.new("ColorCorrectionEffect")
	cc.Name, cc.Parent = "ForgeStoryCC", Lighting
	local bloom = Instance.new("BloomEffect")
	bloom.Name, bloom.Intensity, bloom.Size, bloom.Threshold, bloom.Parent = "ForgeStoryBloom", 0.35, 20, 1.6, Lighting
	local dof = Instance.new("DepthOfFieldEffect")
	dof.Name, dof.FarIntensity, dof.NearIntensity, dof.InFocusRadius, dof.FocusDistance, dof.Parent = "ForgeStoryDoF", 0.25, 0, 30, 20, Lighting
	Lighting.FogEnd, Lighting.FogStart, Lighting.GlobalShadows = 100000, 100000, true
	local parked, made = {}, {} -- the game's own sky objects wait outside Lighting while a scene shows its own; made = what the scene added to Lighting

	-- the viewmodel and every other screen layer hide
	local hiddenVm = {}
	for _, d in cam:GetDescendants() do
		if d:IsA("BasePart") and d.LocalTransparencyModifier < 1 then d.LocalTransparencyModifier = 1 table.insert(hiddenVm, d) end
	end
	local pg = plr:WaitForChild("PlayerGui")
	local hidden = {}
	for _, g in pg:GetChildren() do
		if g:IsA("ScreenGui") and g.Enabled then g.Enabled = false table.insert(hidden, g) end
	end
	local gui = Instance.new("ScreenGui")
	gui.Name, gui.IgnoreGuiInset, gui.ResetOnSpawn, gui.DisplayOrder, gui.ZIndexBehavior = "ForgeStoryGui", true, false, 30, Enum.ZIndexBehavior.Sibling
	gui.Parent = pg
	local function frame(props)
		local f = Instance.new("Frame")
		f.BorderSizePixel = 0
		for k, v in props do f[k] = v end
		f.Parent = props.Parent or gui
		return f
	end
	local function label(props)
		local l = Instance.new("TextLabel")
		l.BackgroundTransparency, l.Font, l.TextScaled, l.TextColor3 = 1, Enum.Font.FredokaOne, true, WHITE
		for k, v in props do l[k] = v end
		l.Parent = props.Parent or gui
		return l
	end
	local fade = frame({ Size = UDim2.fromScale(1, 1), BackgroundColor3 = NIGHT, BackgroundTransparency = 0, ZIndex = 9 }) -- starts closed: the cut out of the UI
	local flash = frame({ Size = UDim2.fromScale(1, 1), BackgroundColor3 = WHITE, BackgroundTransparency = 1, ZIndex = 8 })
	local barT = frame({ Size = UDim2.fromScale(1, 0.1), Position = UDim2.fromScale(0, 0), BackgroundColor3 = Color3.fromRGB(14, 8, 22), ZIndex = 5 })
	local barB = frame({ Size = UDim2.fromScale(1, 0.14), Position = UDim2.fromScale(0, 0.86), BackgroundColor3 = Color3.fromRGB(14, 8, 22), ZIndex = 5 })
	-- chapter card: a small tag ("1  BORN") over the bottom bar and the biography line inside it
	local tag = frame({ Size = UDim2.fromScale(0.13, 0.05), Position = UDim2.fromScale(0.5, 0.86), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = opt.rarity[3], ZIndex = 6 })
	local tagC = Instance.new("UICorner")
	tagC.CornerRadius, tagC.Parent = UDim.new(0.5, 0), tag
	local tagS = Instance.new("UIStroke")
	tagS.Color, tagS.Thickness, tagS.Parent = Color3.fromRGB(14, 8, 22), 3, tag
	local tagText = label({ Parent = tag, Size = UDim2.fromScale(0.8, 0.66), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), TextColor3 = INK, Text = "", ZIndex = 7 })
	local line = label({ Size = UDim2.fromScale(0.74, 0.052), Position = UDim2.fromScale(0.5, 0.935), AnchorPoint = Vector2.new(0.5, 0.5), Text = "", ZIndex = 6 })
	-- name card for NAMED: the pickaxe name and the closing line
	local card = frame({ Size = UDim2.fromScale(0.34, 0.11), Position = UDim2.fromScale(0.5, 0.76), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Color3.fromRGB(255, 250, 243), BackgroundTransparency = 1, ZIndex = 6 })
	local cardC = Instance.new("UICorner")
	cardC.CornerRadius, cardC.Parent = UDim.new(0.5, 0), card
	local cardS = Instance.new("UIStroke")
	cardS.Color, cardS.Thickness, cardS.Transparency, cardS.Parent = opt.rarity[3], 4, 1, card
	local cardName = label({ Parent = card, Size = UDim2.fromScale(0.86, 0.48), Position = UDim2.fromScale(0.5, 0.34), AnchorPoint = Vector2.new(0.5, 0.5), TextColor3 = INK, Text = string.upper(opt.name), TextTransparency = 1, ZIndex = 7 })
	local cardSub = label({ Parent = card, Size = UDim2.fromScale(0.8, 0.28), Position = UDim2.fromScale(0.5, 0.74), AnchorPoint = Vector2.new(0.5, 0.5), TextColor3 = opt.rarity[3]:Lerp(INK, 0.35), Text = "", TextTransparency = 1, ZIndex = 7 })
	local skip = Instance.new("TextButton")
	skip.Text, skip.Font, skip.TextScaled, skip.TextColor3, skip.AutoButtonColor = "SKIP", Enum.Font.FredokaOne, true, INK, true
	skip.BackgroundColor3, skip.BackgroundTransparency, skip.ZIndex, skip.Visible = Color3.fromRGB(255, 250, 243), 0.1, 10, false
	skip.Size, skip.Position, skip.AnchorPoint = UDim2.fromScale(0.09, 0.055), UDim2.fromScale(0.905, 0.05), Vector2.new(0.5, 0.5)
	local skipC = Instance.new("UICorner")
	skipC.CornerRadius, skipC.Parent = UDim.new(0.5, 0), skip
	local skipPad = Instance.new("UIPadding")
	skipPad.PaddingTop, skipPad.PaddingBottom, skipPad.Parent = UDim.new(0.18, 0), UDim.new(0.18, 0), skip
	skip.Parent = gui

	local camSaved = { CameraType = cam.CameraType, FieldOfView = cam.FieldOfView, CFrame = cam.CFrame }
	cam.CameraType = Enum.CameraType.Scriptable

	-- the context a scene builds and plays with
	local rigs, fired = {}, {}
	local holdUntil, shake, kick = 0, 0, 0
	local chapter, chapterAt = 0, 0
	local ctx = {
		O = O, world = world, opt = opt, sfx = sfx, S = M, cc = cc, bloom = bloom, dof = dof,
		cam = O * CFrame.new(0, 6, 24), fov = 50, cardAlpha = 0, flashAlpha = 0,
	}
	function ctx.rig(name, cf, scale)
		local r = newRig(name, world)
		r.root, r.scale = O * (cf or CFrame.new()), scale or 1
		r:update()
		table.insert(rigs, r)
		return r
	end
	function ctx.pick() -- the real pickaxe model, for the reveal
		local art = RS:FindFirstChild("PickaxeArt")
		local src = art and art:FindFirstChild(opt.model)
		if not src then return nil end
		local p = src:Clone()
		for _, d in p:GetDescendants() do
			if d:IsA("BasePart") then d.Anchored, d.CanCollide, d.CanQuery, d.CastShadow = true, false, false, false end
		end
		p.Parent = world
		return p
	end
	function ctx.part(size, cf, color, props)
		local p = Instance.new("Part")
		p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
		p.Size, p.CFrame, p.Color, p.Material = size, O * cf, color, Enum.Material.SmoothPlastic
		for k, v in props or {} do p[k] = v end
		p.Parent = world
		return p
	end
	function ctx.emitter(parent, props)
		local e = Instance.new("ParticleEmitter")
		e.Rate, e.LightEmission, e.LightInfluence = 0, 1, 0
		for k, v in props do e[k] = v end
		e.Parent = parent
		return e
	end
	-- a scene's own sound: ctx.sound(assetId, volume, pitch, looped) -> Sound (a loop is returned playing; set its Volume each frame)
	local sounds = {}
	function ctx.sound(id, volume, pitch, looped)
		local s = Instance.new("Sound")
		s.SoundId, s.Volume, s.PlaybackSpeed, s.Looped = "rbxassetid://" .. id, volume or 0.5, pitch or 1, looped == true
		s.Parent = game:GetService("SoundService")
		s:Play()
		table.insert(sounds, s)
		return s
	end
	function ctx.light(props) for k, v in props do Lighting[k] = v end end
	-- a thing of the setting that never moves (a tree, a rock, the cabin): placed once, not stepped every frame.
	-- mirrorY = the water level: the model's Mirror bones are set so the lake shows it upside down; without it they are removed.
	function ctx.prop(name, cf, scale, mirrorY)
		local r = newRig(name, world)
		r.root, r.scale = O * (cf or CFrame.new()), scale or 1
		for _, b in r.order do
			if b.name == "Mirror" or b.name == "MirrorGlow" then
				if mirrorY and b.part then
					if b.name == "Mirror" then b.local_ = CFrame.new(0, 2 * ((O.Position.Y + mirrorY) - r.root.Position.Y), 0) end
					b.part.CastShadow = false
				elseif b.part then
					b.part:Destroy()
					b.part = nil
				end
			end
		end
		r:update()
		return r
	end
	-- the scene's own sky: ctx.sky({ side = id, up = id, dn = id, sun = degrees or 0, stars = n }); a second call swaps the pictures
	local skyObj
	function ctx.sky(s)
		if not skyObj then
			for _, e in Lighting:GetChildren() do if e:IsA("Sky") then table.insert(parked, e) e.Parent = nil end end
			skyObj = Instance.new("Sky")
			skyObj.Name, skyObj.MoonAngularSize = "ForgeStorySky", 0
			skyObj.Parent = Lighting
			table.insert(made, skyObj)
		end
		local side = "rbxassetid://" .. s.side
		skyObj.SkyboxBk, skyObj.SkyboxFt, skyObj.SkyboxLf, skyObj.SkyboxRt = side, side, side, side
		skyObj.SkyboxUp, skyObj.SkyboxDn = "rbxassetid://" .. s.up, "rbxassetid://" .. s.dn
		skyObj.SunAngularSize, skyObj.StarCount, skyObj.CelestialBodiesShown = s.sun or 0, s.stars or 0, (s.sun or 0) > 0
	end
	-- haze between the layers of a deep setting: ctx.atmo({ Density = , Haze = , Color = , Decay = , Glare = , Offset = })
	local atmoObj
	function ctx.atmo(props)
		if not atmoObj then
			atmoObj = Lighting:FindFirstChildOfClass("Atmosphere")
			if atmoObj then
				for _, k in { "Haze", "Color", "Decay", "Glare", "Offset" } do table.insert(off, { atmoObj, k, atmoObj[k] }) end -- Density is already kept above
			else
				atmoObj = Instance.new("Atmosphere")
				atmoObj.Parent = Lighting
				table.insert(made, atmoObj)
			end
		end
		for k, v in props do atmoObj[k] = v end
	end
	function ctx.effect(class, props) -- a post effect of the scene's own (SunRaysEffect ...), removed at the end
		local e = Instance.new(class)
		for k, v in props or {} do e[k] = v end
		e.Parent = Lighting
		table.insert(made, e)
		return e
	end
	-- the key light: turn the sun so it shines from a stage-space direction (the game sky is hidden, so the hour is free).
	-- Models need this for their roundness to read; ambient light alone renders them flat.
	function ctx.key(dir)
		local want = O:VectorToWorldSpace(dir.Unit)
		local best, bl, bc = -2, 0, 12
		for lat = 0, 88, 8 do
			Lighting.GeographicLatitude = lat
			for ct = 6.5, 17.5, 0.25 do
				Lighting.ClockTime = ct
				local d = Lighting:GetSunDirection():Dot(want)
				if d > best then best, bl, bc = d, lat, ct end
			end
		end
		Lighting.GeographicLatitude, Lighting.ClockTime = bl, bc
	end
	function ctx.once(key, at, t, fn) if t >= at and not fired[key] then fired[key] = true fn() end end
	function ctx.hold(sec) holdUntil = os.clock() + sec end -- hit-stop: the clock waits
	function ctx.shake(n) shake = math.max(shake, n) end
	function ctx.kick(n) kick = math.max(kick, n) end
	function ctx.chapter(i, word, text)
		if chapter == i then return end
		chapter, chapterAt = i, os.clock()
		tagText.Text, line.Text = i .. "  " .. word, text
		sfx("tab", 0.8 + i * 0.1)
	end
	function ctx.name(sub) cardSub.Text = sub end

	local t = opt.fast and scene.named or 0
	local T_END = scene.length
	local done, skipped = false, false
	local okSetup, update = pcall(scene.setup, ctx) -- a scene that fails to build still goes through the clean-up below
	if not okSetup then warn("[ForgeStory] " .. tostring(update)) done = true update = function() end end
	local function doSkip()
		if skipped or t >= scene.named then return end
		skipped = true
		fade.BackgroundTransparency = 0
		t = scene.named
		for k in fired do fired[k] = nil end
		ctx.skipped = true
	end
	skip.Activated:Connect(doSkip)
	local UIS = game:GetService("UserInputService")
	local skipConn = UIS.InputBegan:Connect(function(i) if i.KeyCode == Enum.KeyCode.Space or i.KeyCode == Enum.KeyCode.ButtonB then if t >= 0.5 then doSkip() end end end)

	local last = os.clock()
	RunService:BindToRenderStep("ForgeStory", Enum.RenderPriority.Camera.Value + 2, function()
		local now = os.clock()
		local dt = math.min(now - last, 0.1)
		last = now
		if now >= holdUntil then t += dt end
		if opt.freeze then t = math.min(t, opt.freeze) end
		skip.Visible = t >= 0.5 and t < scene.named
		local ok, err = pcall(update, t, dt)
		if not ok then warn("[ForgeStory] " .. tostring(err)) done = true return end
		for _, r in rigs do r:update() end
		-- screen layer
		local open = M.smooth(0, 0.35, t) * (1 - M.smooth(T_END - 0.35, T_END, t))
		if skipped then open = math.min(open, M.smooth(scene.named, scene.named + 0.3, t)) end
		fade.BackgroundTransparency = open
		flash.BackgroundTransparency = 1 - math.clamp(ctx.flashAlpha, 0, 1)
		local ca = math.clamp((now - chapterAt) / 0.3, 0, 1)
		local show = chapter > 0 and 1 or 0
		tag.Size = UDim2.fromScale(0.13 * (0.7 + 0.3 * M.backOut(ca)) * show, 0.05 * (0.7 + 0.3 * M.backOut(ca)) * show)
		line.TextTransparency = 1 - ca * show
		line.Position = UDim2.fromScale(0.5, 0.945 - 0.01 * ca)
		local a = math.clamp(ctx.cardAlpha, 0, 1)
		card.BackgroundTransparency, cardS.Transparency = 1 - a * 0.96, 1 - a
		cardName.TextTransparency, cardSub.TextTransparency = 1 - a, 1 - a
		card.Position = UDim2.fromScale(0.24, 0.3 - 0.02 * a) -- upper left: clear of the pickaxe, the maker and the camp
		-- camera
		kick *= math.exp(-dt * 9)
		shake *= math.exp(-dt * 7)
		local sx, sy = math.noise(now * 25, 1) * shake, math.noise(now * 25, 2) * shake
		cam.CFrame = ctx.cam * CFrame.Angles(sy * 0.05, sx * 0.05, sx * 0.02)
		cam.FieldOfView = ctx.fov - kick
		if t >= T_END then done = true end
	end)
	local started = os.clock()
	while not done and os.clock() - started < (opt.freeze and (opt.freezeFor or 30) or T_END + 8) do task.wait() end -- never hang the player in the scene
	RunService:UnbindFromRenderStep("ForgeStory")
	skipConn:Disconnect()
	-- put everything back: lighting, effects, viewmodel, HUD, camera
	for k, v in saved do Lighting[k] = v end
	for _, o in off do if o[1].Parent then o[1][o[2]] = o[3] end end
	cc:Destroy() bloom:Destroy() dof:Destroy()
	for _, e in made do e:Destroy() end
	for _, e in parked do e.Parent = Lighting end
	for _, d in hiddenVm do if d.Parent then d.LocalTransparencyModifier = 0 end end
	for _, g in hidden do if g.Parent then g.Enabled = true end end
	for k, v in camSaved do pcall(function() cam[k] = v end) end
	world:Destroy()
	for _, s in sounds do s:Destroy() end
	fade.BackgroundTransparency = 0
	for _, o in { barT, barB, tag, line, card, skip } do o.Visible = false end
	local tw = TweenService:Create(fade, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 1 })
	tw:Play()
	task.delay(0.32, function() gui:Destroy() end)
	M.playing = false
	return true
end

return M
