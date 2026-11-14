-- ARSettings (ReplicatedStorage.Shared.ARSettings), started by PixelClient with the cut-glass kit. It replaces the paper
-- notebook (key N, the NOTES slot of the wheel, the NOTES thumb button).
-- The user, 2026-11-12: "the AR Jelly UI would be sick where you look to your left and right for the settings ... and you see
-- this poppy text". References: Instagram Dd8V7dTJzF_ and DfbjiL-TBuK (glass panels standing in the world), reel DfUpUhcuASY (jelly text).
-- Three glass panels stand in the world on an arc round the player: SOUND on the left, SETTINGS ahead, CONTROLS on the right,
-- each under a jelly title. You look from one to the next: move the mouse toward a screen edge, press A / D or the arrow
-- keys, or tap the jelly arrows on a phone. The view is a scripted camera at the player's head; it eases in from the game
-- camera and back out, and it runs after the game's own camera step (PixelCam) so the two never fight.
-- Settings are the same as the notebook's and call the same things: master volume (SoundService.PixelMaster), screen shake
-- (attribute NoShake), key hints (frames named KeyHint), darker nights (attribute DevLowLight).
-- The settings are saved with the player's profile (field opts, remote Opts; the owner said yes on 2026-11-13).
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")
local M = {}

local MID = Vector2.new(0.5, 0.5)
local RADIUS, SPREAD = 2.3, 48 -- the starting values; fit() below sets both from the screen each time the panels open. studs from the eye to a panel (close, so little of the world can stand in front: always-on-top world panels do not draw in this game); degrees between panels
local PW, PH, PPS = 1.7, 1.31, 272 -- 16% smaller in the world with the same pixels (directive v9 and Gemini 2026-11-13: the side panels and their titles were cut by the screen edge)
local _ = nil -- panel size in studs, pixels per stud
local SMOKE, EDGE, WHITE = Color3.fromRGB(30, 21, 58), Color3.fromRGB(236, 226, 255), Color3.new(1, 1, 1)
local PINK, MINT, BUTTER, CYAN, LILAC = Color3.fromRGB(255, 150, 205), Color3.fromRGB(150, 255, 210), Color3.fromRGB(255, 226, 130), Color3.fromRGB(160, 240, 255), Color3.fromRGB(205, 188, 255) -- bright: a tint multiplies the pale jelly

function M.start(E)
	if not E.GLASS then return end
	local plr, hook, C = E.plr, E.vmHook, E.C
	local JellyText = require(script.Parent:WaitForChild("JellyText"))
	local pg = plr:WaitForChild("PlayerGui")
	local function new(cls, parent, props)
		local o = Instance.new(cls)
		for k, v in props do o[k] = v end
		o.Parent = parent
		return o
	end
	local function label(parent, s, size, pos, color, font, alignLeft)
		local l = new("TextLabel", parent, { Text = s, Font = font or E.FONT, TextScaled = true, TextColor3 = color or WHITE, BackgroundTransparency = 1, Size = size, Position = pos, AnchorPoint = MID, ZIndex = 4 })
		if alignLeft then l.TextXAlignment = Enum.TextXAlignment.Left end
		return l
	end

	-- a 1 px flag frame in the HUD marks the settings as an open menu: the client then frees the mouse in first person and
	-- hides widgets and prompts. It must not be a Modal button: a Modal button anywhere swallowed every click meant for the
	-- world panels (found with spike/ar_probe.py, 2026-11-12)
	local flag = new("Frame", E.gui, { Name = "ARSettings", BackgroundTransparency = 1, Size = UDim2.fromOffset(1, 1), Visible = false })
	if E.addModal then E.addModal(flag) end
	local folder = new("Folder", workspace.CurrentCamera, { Name = "ARSettings" })
	local state = { vol = 8, shake = true, hints = true, dark = false, fast = false }
	-- The settings are saved with the player's profile (the owner said yes, 2026-11-13): every change goes to the server
	-- (remote Opts, which keeps only these four fields), and at the start the panel asks the server for them.
	local setters = {} -- key -> function(value): put a loaded value on its control and apply it
	local OptsR = E.R:FindFirstChild("Opts")
	local function send()
		if OptsR then OptsR:FireServer({ vol = state.vol, shake = state.shake, hints = state.hints, dark = state.dark, fast = state.fast }) end
	end
	local panels, isOpen, focus = {}, false, 0 -- focus: -1 left, 0 middle, 1 right
	local shut

	local function glassButton(parent, word, color, size, pos, act)
		local b = new("TextButton", parent, { Text = "", AutoButtonColor = false, Size = size, Position = pos, AnchorPoint = MID, BackgroundColor3 = color, BackgroundTransparency = 0.15, BorderSizePixel = 0, ZIndex = 4 })
		new("UICorner", b, { CornerRadius = UDim.new(0.3, 0) })
		new("UIStroke", b, { Color = WHITE, Thickness = 2, Transparency = 0.25 })
		new("UIGradient", b, { Rotation = 90, Color = ColorSequence.new(WHITE, Color3.fromRGB(190, 180, 215)) })
		local holder = new("Frame", b, { Size = UDim2.fromScale(0.84, 0.7), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = MID, BackgroundTransparency = 1, ZIndex = 5 })
		local jt = JellyText.new(holder, word, { color = WHITE, z = 5 })
		local sc = new("UIScale", b, {})
		b.MouseEnter:Connect(function() TweenService:Create(sc, TweenInfo.new(0.12), { Scale = 1.07 }):Play() end)
		b.MouseLeave:Connect(function() TweenService:Create(sc, TweenInfo.new(0.12), { Scale = 1 }):Play() end)
		b.Activated:Connect(function()
			sc.Scale = 0.86 -- a jelly press: it dips and springs back
			TweenService:Create(sc, TweenInfo.new(0.4, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), { Scale = 1 }):Play()
			jt.pop(0.02)
			E.sfx("click", 1)
			act()
		end)
		return b, jt
	end

	local function panel(slot, title, tint)
		local part = new("Part", folder, { Name = title, Size = Vector3.new(PW, PH, 0.05), Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false, Transparency = 1 })
		local sg = new("SurfaceGui", pg, { Name = "AR_" .. title, Adornee = part, Face = Enum.NormalId.Front, SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud, PixelsPerStud = PPS, AlwaysOnTop = false, LightInfluence = 0, Brightness = 1.4, MaxDistance = 1000, ResetOnSpawn = false, Enabled = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling })
		local root = new("Frame", sg, { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 })
		local sc = new("UIScale", root, {})
		local card = new("Frame", root, { Size = UDim2.fromScale(0.94, 0.74), Position = UDim2.fromScale(0.5, 0.61), AnchorPoint = MID, BackgroundColor3 = SMOKE, BackgroundTransparency = 0.07, BorderSizePixel = 0, ZIndex = 2 }) -- nearly solid: the world behind made the labels hard to read
		new("UICorner", card, { CornerRadius = UDim.new(0.07, 0) })
		new("UIStroke", card, { Color = tint:Lerp(WHITE, 0.6), Thickness = 3, Transparency = 0.1 })
		new("UIGradient", card, { Rotation = 90, Color = ColorSequence.new(WHITE, Color3.fromRGB(160, 140, 215)) })
		local sheen = new("Frame", card, { Size = UDim2.fromScale(0.14, 1.7), Position = UDim2.fromScale(0.2, 0.5), AnchorPoint = MID, Rotation = 22, BackgroundColor3 = WHITE, BackgroundTransparency = 0.91, BorderSizePixel = 0, ZIndex = 2 })
		card.ClipsDescendants = true
		local head = new("Frame", root, { Size = UDim2.fromScale(0.9, 0.24), Position = UDim2.fromScale(0.5, 0.13), AnchorPoint = MID, BackgroundTransparency = 1, ZIndex = 6 })
		local jt = JellyText.new(head, title, { color = slot ~= 0 and tint or nil, glow = true, z = 6 })
		local p = { slot = slot, part = part, sg = sg, root = root, sc = sc, card = card, title = jt, sheen = sheen }
		panels[slot] = p
		return p, card
	end

	-- SOUND (left)
	do
		local _, card = panel(-1, "SOUND", CYAN)
		local numHolder = new("Frame", card, { Size = UDim2.fromScale(0.5, 0.3), Position = UDim2.fromScale(0.5, 0.22), AnchorPoint = MID, BackgroundTransparency = 1, ZIndex = 4 })
		local num = JellyText.new(numHolder, "80%", { color = CYAN, z = 4 })
		local pips = {}
		for i = 1, 10 do
			pips[i] = new("ImageLabel", card, { Image = E.GLASS.hex, BackgroundTransparency = 1, Size = UDim2.fromScale(0.085, 0.16), Position = UDim2.fromScale(0.095 + (i - 1) * 0.09, 0.5), AnchorPoint = MID, ScaleType = Enum.ScaleType.Fit, ZIndex = 4 })
		end
		local function apply(pop)
			local g = SoundService:FindFirstChild("PixelMaster")
			if g then g.Volume = state.vol / 10 end
			for i, pip in pips do pip.Image = i <= state.vol and E.GLASS.hexOn or E.GLASS.hex end
			num.set(state.vol == 0 and "OFF" or (state.vol * 10 .. "%"))
			if pop then num.pop(0.02) end
		end
		local _, minus = glassButton(card, "-", LILAC, UDim2.fromScale(0.26, 0.24), UDim2.fromScale(0.3, 0.8), function() state.vol = math.max(0, state.vol - 1) apply(true) send() end)
		new("UIScale", minus.frame, { Scale = 1.9 }) -- the dash glyph is small in its cell: as heavy as the plus beside it
		glassButton(card, "+", CYAN, UDim2.fromScale(0.26, 0.24), UDim2.fromScale(0.7, 0.8), function() state.vol = math.min(10, state.vol + 1) apply(true) send() end)
		local g = SoundService:FindFirstChild("PixelMaster")
		if g then state.vol = math.clamp(math.floor(g.Volume * 10 + 0.5), 0, 10) end
		apply(false)
		setters.vol = function(v) state.vol = v apply(false) end
	end

	-- SETTINGS (ahead)
	do
		local _, card = panel(0, "SETTINGS", PINK)
		local function toggle(i, name, key, act)
			local y = 0.13 + (i - 1) * 0.165 -- four rows since directive v9 (were three, 0.2 apart)
			label(card, name, UDim2.fromScale(0.52, 0.12), UDim2.fromScale(0.33, y), WHITE, E.FONT, true) -- the open sentence font: condensed capitals filled in on a phone
			local b, jt
			b, jt = glassButton(card, state[key] and "ON" or "OFF", state[key] and MINT or LILAC, UDim2.fromScale(0.26, 0.135), UDim2.fromScale(0.8, y), function()
				state[key] = not state[key]
				jt.set(state[key] and "ON" or "OFF")
				b.BackgroundColor3 = state[key] and MINT or LILAC
				act(state[key])
				send()
			end)
			setters[key] = function(v)
				state[key] = v
				jt.set(v and "ON" or "OFF")
				b.BackgroundColor3 = v and MINT or LILAC
				act(v)
			end
		end
		toggle(1, "Screen shake", "shake", function(on) plr:SetAttribute("NoShake", (not on) or nil) end)
		toggle(2, "Key hints", "hints", function(on)
			for _, d in E.gui:GetDescendants() do
				if d.Name == "KeyHint" and d:IsA("GuiObject") then d.Visible = on end
			end
		end)
		toggle(3, "Darker nights", "dark", function(on) plr:SetAttribute("DevLowLight", on or nil) end)
		-- directive v9: "Fast-Open / Skip Cutscene": the forge scene, the Secret hatch scene and the glass lift are left out and
		-- are replaced by a plain fade (attribute FastCine, read where each scene starts)
		toggle(4, "Fast cutscenes", "fast", function(on) plr:SetAttribute("FastCine", on or nil) end)
		local x = 0.2
		for _, s in { { "BAG", MINT, "bag" }, { "QUESTS", BUTTER, "quests" }, { "DONE", PINK, nil } } do
			glassButton(card, s[1], s[2], UDim2.fromScale(0.27, 0.15), UDim2.fromScale(x, 0.84), function()
				shut()
				if s[3] and hook[s[3]] then task.delay(0.3, hook[s[3]]) end
			end)
			x += 0.3
		end
	end

	-- CONTROLS (right)
	do
		local _, card = panel(1, "CONTROLS", BUTTER)
		local KEYS = { { "F", "Use or talk" }, { "E", "Mine ore" }, { "R", "Flare" }, { "T", "Sonar" }, { "Z", "Ping crew" }, { "TAB", "Tool wheel" }, { "B", "Bag" }, { "J", "Quests" }, { "H", "Inspect" }, { "N", "Settings" } }
		for i, k in KEYS do
			local col, row = (i - 1) % 2, math.floor((i - 1) / 2)
			local y = 0.12 + row * 0.185
			local cap = new("Frame", card, { Size = UDim2.fromScale(0.11, 0.13), Position = UDim2.fromScale(0.085 + col * 0.5, y), AnchorPoint = MID, BackgroundColor3 = Color3.fromRGB(58, 42, 112), BackgroundTransparency = 0, BorderSizePixel = 0, ZIndex = 4 }) -- a dark cap: pale jelly on a white cap had no contrast
			new("UICorner", cap, { CornerRadius = UDim.new(0.25, 0) })
			new("UIStroke", cap, { Color = BUTTER, Thickness = 2 })
			label(cap, k[1], UDim2.fromScale(0.84, 0.7), UDim2.fromScale(0.5, 0.5), BUTTER, E.HEAD)
			label(card, k[2], UDim2.fromScale(0.33, 0.1), UDim2.fromScale(0.325 + col * 0.5, y), WHITE, E.FONT, true)
		end
	end

	if OptsR then -- ask the server for the saved settings (it answers once the profile has loaded)
		local loaded = false
		OptsR.OnClientEvent:Connect(function(o)
			if loaded or type(o) ~= "table" then return end
			loaded = true
			for k, v in o do
				if setters[k] and v ~= state[k] then setters[k](v) end
			end
		end)
		task.spawn(function()
			for _ = 1, 15 do
				if loaded then break end
				OptsR:FireServer("get")
				task.wait(1)
			end
		end)
	end

	-- jelly arrows for phones (and a hint for everyone)
	local nav = new("ScreenGui", pg, { Name = "ARNav", ResetOnSpawn = false, DisplayOrder = 40, Enabled = false })
	local function arrow(sym, x, d)
		local b = new("TextButton", nav, { Text = "", BackgroundColor3 = SMOKE, BackgroundTransparency = 0.25, Size = UDim2.fromScale(0.07, 0.14), SizeConstraint = Enum.SizeConstraint.RelativeYY, Position = UDim2.fromScale(x, 0.5), AnchorPoint = MID, BorderSizePixel = 0 })
		b.Size = UDim2.fromScale(0.14, 0.14)
		new("UICorner", b, { CornerRadius = UDim.new(0.5, 0) })
		new("UIStroke", b, { Color = EDGE, Thickness = 2, Transparency = 0.2 })
		label(b, sym, UDim2.fromScale(0.6, 0.6), UDim2.fromScale(0.5, 0.48), WHITE, E.HEAD)
		b.Activated:Connect(function() focus = math.clamp(focus + d, -1, 1) end)
		return b
	end
	local arrows = { arrow("<", 0.05, -1), arrow(">", 0.95, 1) } -- shown only where there is a finger: with a mouse they sat on top of the side panels
	local hintBar = new("Frame", nav, { Size = UDim2.fromScale(0.44, 0.07), Position = UDim2.fromScale(0.5, 0.94), AnchorPoint = MID, BackgroundColor3 = SMOKE, BackgroundTransparency = 0.3, BorderSizePixel = 0 })
	new("UICorner", hintBar, { CornerRadius = UDim.new(0.5, 0) })
	local hintText = label(hintBar, "", UDim2.fromScale(0.9, 0.6), UDim2.fromScale(0.5, 0.5), EDGE, E.HEAD)
	local function touchNow() return (UIS.TouchEnabled and not UIS.KeyboardEnabled) or plr:GetAttribute("DevTouch") ~= nil end

	-- the camera
	local base, yaw, pitch, blend, closing = nil, 0, 0, 0, false
	local lastMouse, mouseAt = nil, 0
	local function place()
		for slot, p in panels do
			local cf = base * CFrame.Angles(0, -math.rad(slot * SPREAD), 0) * CFrame.new(0, 0.06, -RADIUS)
			p.part.CFrame = CFrame.lookAt(cf.Position, base.Position + Vector3.new(0, 0.06, 0)) -- every panel faces the eye
		end
	end
	-- 2026-11-14 (the owner: "fix controls"): at 48 degrees apart the side panels stood half outside a 16:9 view (its half angle is
	-- 48 degrees), so CONTROLS was cut at the right edge. All three now fit the screen that is there: the panels stand further
	-- away (smaller on screen, same pixels) and closer together.
	local function fit()
		local vp = workspace.CurrentCamera.ViewportSize
		local half = math.deg(math.atan(math.tan(math.rad(32)) * vp.X / math.max(vp.Y, 1))) -- half the view across, at the 64 degree field of view used here
		local a = math.clamp((half - 2) / 3.1, 9, 20.3) -- half a panel's width in degrees
		RADIUS = PW / 2 / math.tan(math.rad(a))
		SPREAD = math.min(48, a * 2.1)
	end
	local function open()
		if isOpen or E.isBusy() or plr:GetAttribute("Seated") then return end
		fit()
		local h = E.hrp()
		if not h then return end
		isOpen, closing, focus, yaw, pitch, blend = true, false, 0, 0, 0, 0
		local look = h.CFrame.LookVector * Vector3.new(1, 0, 1)
		local cam = workspace.CurrentCamera
		if plr:GetAttribute("InCave") then look = cam.CFrame.LookVector * Vector3.new(1, 0, 1) end
		if look.Magnitude < 0.1 then look = Vector3.new(0, 0, -1) end
		local eye = h.Position + Vector3.new(0, 2.6, 0)
		-- face the clearest way: the three panels need open air, so look round in 30 degree steps and take the turn nearest
		-- to where the player already looks that has room for all three (or the roomiest one)
		local rp = RaycastParams.new()
		rp.FilterDescendantsInstances = { plr.Character, folder }
		local function free(dir)
			local best = RADIUS + 1.5
			for _, dy in { 0.5, 0, -0.9 } do -- the top, the middle and the bottom edge of a panel: a low crate must count too
				local hit = workspace:Raycast(eye + Vector3.new(0, dy, 0), dir * (RADIUS + 1.5), rp)
				if hit then best = math.min(best, hit.Distance) end
			end
			return best
		end
		local best, bestScore
		for step = 0, 11 do
			local turn = (step % 2 == 0 and 1 or -1) * math.ceil(step / 2) * 30 -- 0, -30, 30, -60, 60 ...
			local d = CFrame.Angles(0, math.rad(turn), 0):VectorToWorldSpace(look.Unit)
			local room = math.min(free(d), free(CFrame.Angles(0, math.rad(SPREAD), 0):VectorToWorldSpace(d)), free(CFrame.Angles(0, -math.rad(SPREAD), 0):VectorToWorldSpace(d)))
			if room >= RADIUS + 0.5 then best = d break end
			if not bestScore or room > bestScore then best, bestScore = d, room end
		end
		base = CFrame.lookAt(eye, eye + best)
		hook.arOpen = true
		place()
		flag.Visible, nav.Enabled = true, true
		local touch = touchNow()
		for _, a in arrows do a.Visible = touch end
		hintText.Text = touch and "DRAG OR TAP THE ARROWS TO LOOK ROUND" or "LOOK LEFT AND RIGHT: MOUSE OR A / D      CLOSE: N"
		for slot, p in panels do
			p.sg.Enabled = true
			p.part.CanQuery = true -- a SurfaceGui gets no clicks through a part that cannot be queried
			p.sc.Scale = 0.4
			task.delay(0.12 + math.abs(slot) * 0.1, function() -- the middle panel first, then the sides
				if not isOpen then return end
				TweenService:Create(p.sc, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
				p.title.pop()
			end)
		end
		E.sfx("sparkle", 1.1)
	end
	shut = function()
		if not isOpen or closing then return end
		closing = true
		for _, p in panels do TweenService:Create(p.sc, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = 0.4 }):Play() end
		nav.Enabled = false
	end
	hook.notebook = function() if isOpen then shut() else open() end end
	UIS.InputBegan:Connect(function(io, gp)
		if gp then return end
		local k = io.KeyCode
		if k == Enum.KeyCode.N then hook.notebook()
		elseif isOpen and (k == Enum.KeyCode.A or k == Enum.KeyCode.Left) then focus = math.max(-1, focus - 1) mouseAt = 0
		elseif isOpen and (k == Enum.KeyCode.D or k == Enum.KeyCode.Right) then focus = math.min(1, focus + 1) mouseAt = 0
		elseif isOpen and k == Enum.KeyCode.Escape then shut() end
	end)

	-- phones: drag a finger sideways to look round (the arrows still step panel by panel)
	local dragYaw = nil
	UIS.TouchMoved:Connect(function(touch, gp)
		if not isOpen or closing then return end
		local vp = workspace.CurrentCamera.ViewportSize
		dragYaw = math.clamp((dragYaw or yaw) - touch.Delta.X / vp.X * 150, -SPREAD - 6, SPREAD + 6)
	end)
	UIS.TouchEnded:Connect(function()
		if dragYaw then
			focus = math.clamp(math.floor(dragYaw / SPREAD + 0.5), -1, 1) -- let go: settle on the nearest panel
			dragYaw = nil
		end
	end)

	RunService:BindToRenderStep("PixelARSettings", Enum.RenderPriority.Camera.Value + 2, function(dt)
		if not isOpen then return end
		local cam = workspace.CurrentCamera
		local now = os.clock()
		local h = E.hrp()
		if not closing and (not h or (h.Position - base.Position).Magnitude > 7 or E.isBusy()) then shut() end -- walked away, or a minigame began
		blend = math.clamp(blend + (closing and -dt or dt) / 0.4, 0, 1)
		if hook.blur then hook.blur.Enabled = false end -- the client blurs the world behind a menu; these panels stand IN the world and must stay sharp
		local ch = plr.Character
		for _, d in ch and ch:GetDescendants() or {} do -- the view sits in the player's head: hide the body from its owner
			if d:IsA("BasePart") or d:IsA("Decal") then d.LocalTransparencyModifier = 1 end
		end
		if closing and blend <= 0 then
			isOpen, closing = false, false
			flag.Visible = false
			hook.arOpen = false
			if hook.blur then hook.blur.Enabled = true end
			if not plr:GetAttribute("InCave") then
				for _, d in ch and ch:GetDescendants() or {} do
					if d:IsA("BasePart") or d:IsA("Decal") then d.LocalTransparencyModifier = 0 end
				end
			end
			for _, p in panels do p.sg.Enabled = false p.part.CanQuery = false end
			return
		end
		-- where to look: the mouse near a screen edge turns the head; keys and arrows step from panel to panel
		local m = UIS:GetMouseLocation()
		if UIS.MouseEnabled and lastMouse and (m - lastMouse).Magnitude > 2 then mouseAt = now end
		lastMouse = m
		local vp = cam.ViewportSize
		local goalYaw, goalPitch = focus * SPREAD, 0
		if UIS.MouseEnabled and now - mouseAt < 4 then
			local nx, ny = (m.X / vp.X - 0.5) * 2, (m.Y / vp.Y - 0.5) * 2
			local edge = math.sign(nx) * math.clamp((math.abs(nx) - 0.3) / 0.6, 0, 1) -- a calm middle, then it turns faster toward the edge
			goalYaw = math.clamp(yaw + edge * 90 * dt * 2.2, -SPREAD - 6, SPREAD + 6)
			goalPitch = 0 -- no nod with the mouse: it moved the buttons away from the cursor as it came near (a click test missed its button)
			focus = math.clamp(math.floor(goalYaw / SPREAD + 0.5), -1, 1)
			yaw = goalYaw
		elseif dragYaw then
			yaw = dragYaw
		else
			yaw += (goalYaw - yaw) * (1 - math.exp(-dt * 7))
		end
		pitch += (goalPitch - pitch) * (1 - math.exp(-dt * 6))
		cam.FieldOfView += (64 - cam.FieldOfView) * (blend * blend * (3 - 2 * blend)) -- one field of view in town and in first person, so the panels are the same size everywhere (the game's own camera step sets it back each frame)
		for _, m in cam:GetChildren() do -- the first-person torch and pickaxe stood in front of the buttons
			if m ~= folder and m.Name ~= "SpatialPanel" and m.Name ~= "SpatialCard" then
				for _, d in m:GetDescendants() do if d:IsA("BasePart") then d.LocalTransparencyModifier = closing and 0 or 1 end end
				if m:IsA("BasePart") then m.LocalTransparencyModifier = closing and 0 or 1 end
			end
		end
		local want = base * CFrame.Angles(0, -math.rad(yaw), 0) * CFrame.Angles(math.rad(pitch), 0, 0)
		local k = blend * blend * (3 - 2 * blend)
		cam.CFrame = cam.CFrame:Lerp(want, k) -- cam.CFrame here is what the game's own camera step just wrote
		for slot, p in panels do
			local bob = math.sin(now * 1.3 + slot * 1.9) * 0.03
			local cf = base * CFrame.Angles(0, -math.rad(slot * SPREAD), 0) * CFrame.new(0, 0.06 + bob, -RADIUS)
			p.part.CFrame = CFrame.lookAt(cf.Position, base.Position + Vector3.new(0, 0.06 + bob, 0))
			p.sheen.Position = UDim2.fromScale(0.2 + 0.6 * (0.5 + 0.5 * math.sin(now * 0.6 + slot)), 0.5)
		end
	end)
end

return M
