-- SpatialPanels (ReplicatedStorage.Shared.SpatialPanels), started by PixelClient with the cut-glass kit.
-- The user, 2026-11-12: "For the GUI ... the minecraft ones are the main reference". Reference: the Minecraft mod Spatial GUI
-- (by tastytrash, shown in Instagram post Dd8V7dTJzF_; frames in the vault, Research/Reference Videos/Instagram 2026-11-12):
-- the game's ordinary menus are not flat on the glass of the screen. Each one is drawn on a panel that stands in the world
-- beside the player, turned a little away, with real perspective, while the world stays sharp and visible behind it.
-- How: while one of the game's menu frames (bag, wardrobe, quests, Soul Tree ...: the list the client keeps in hook.modals)
-- is open, the frame is moved from the HUD into a SurfaceGui on an unseen part that rides in front of the camera, yawed and
-- pitched; when it closes it goes back to the HUD. The canvas is exactly as large as the HUD, so every layout keeps its place
-- and every button still works. The panel swings in on a spring, lags a little behind the view and leans with the mouse.
-- The client drops its dark scrim when hook.noScrim() says so, and this module switches the blur off while a panel is up. Player attribute DevFlatUI turns this off.
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local M = {}

local DIST = 1.1 -- studs from the eye to the panel's middle: close, so no post, wall or rock can stand in front of a menu (it was 4 and a lantern post covered the bag)
local YAW, PITCH, FILL = 7, 2, 0.88 -- degrees turned away, degrees leaned back, share of the view it fills (the user, 2026-11-12: 15 and 4 leaned too far; face the player 5 to 10 degrees more)
local SKIP = { ARSettings = true } -- menus that are already in the world

function M.start(E)
	if not E.GLASS or E.plr:GetAttribute("DevFlatUI") then return end
	local hook, gui, plr = E.vmHook, E.gui, E.plr
	local pg = plr:WaitForChild("PlayerGui")
	local part = Instance.new("Part")
	part.Name, part.Anchored, part.CanCollide, part.CanQuery, part.CanTouch, part.CastShadow, part.Transparency = "SpatialPanel", true, false, false, false, false, 1 -- CanQuery is switched on only while a panel is up: a SurfaceGui gets no clicks through a part that cannot be queried (found 2026-11-12: buttons on world panels did nothing)
	part.Size = Vector3.new(4, 2, 0.02)
	part.Parent = workspace.CurrentCamera
	local sg = Instance.new("SurfaceGui")
	sg.Name, sg.Adornee, sg.Face, sg.ResetOnSpawn, sg.Enabled = "SpatialPanels", part, Enum.NormalId.Front, false, false
	sg.SizingMode, sg.LightInfluence, sg.AlwaysOnTop, sg.MaxDistance, sg.ZIndexBehavior = Enum.SurfaceGuiSizingMode.FixedSize, 0, false, 1000, Enum.ZIndexBehavior.Sibling
	sg.Parent = pg

	local held = {} -- frame -> the parent it came from
	local count, openedAt, swing, swingV, lean = 0, 0, 0, 0, Vector2.zero
	local wasAny = false
	local last -- the panel's CFrame last frame, for the lag behind the view

	local function release(f)
		local home = held[f]
		held[f] = nil
		count -= 1
		if f.Parent == sg then f.Parent = home end
	end

	-- where a point of the canvas (pixels) is on the screen right now: for code that must match a tap to something on the panel
	hook.spatialPoint = function(p)
		local c = sg.CanvasSize
		local w = part.CFrame * Vector3.new(-(p.X / c.X - 0.5) * part.Size.X, (0.5 - p.Y / c.Y) * part.Size.Y, -part.Size.Z / 2)
		local v = workspace.CurrentCamera:WorldToViewportPoint(w)
		return Vector2.new(v.X, v.Y)
	end
	local live = true
	hook.noScrim = function() -- asked by the client in the frame a menu opens, before this module's own step has run
		if not live then return false end
		for _, f in hook.modals or {} do
			if not SKIP[f.Name] and f:IsA("GuiObject") and f.Visible then return true end
		end
		for _, e in hook.spatialExtra or {} do
			if e.menu and e.on() then return true end
		end
		return false
	end

	RunService:BindToRenderStep("PixelSpatialPanels", Enum.RenderPriority.Camera.Value + 3, function(dt)
		for _, f in hook.modals or {} do
			if not SKIP[f.Name] and f:IsA("GuiObject") then
				if f.Visible and not held[f] and f.Parent == gui then
					held[f] = gui
					count += 1
					f.Parent = sg
					if count == 1 then openedAt, swing, swingV, last = os.clock(), 1, 0, nil end
				elseif held[f] and not f.Visible then
					release(f)
				end
			end
		end
		for _, e in hook.spatialExtra or {} do -- pieces that are not whole menus (the tool wheel's holder): { frame, home, on(), quick }
			local f = e.frame
			if e.on() and not held[f] and f.Parent == e.home then
				held[f] = e.home
				count += 1
				f.Parent = sg
				if count == 1 then openedAt, swing, swingV, last = os.clock(), e.quick and 0.35 or 1, 0, nil end
			elseif held[f] and not e.on() then
				release(f)
			end
		end
		for f in held do if not f.Parent then held[f] = nil count -= 1 end end -- destroyed while open
		local any = count > 0
		hook.spatialOpen = any
		if sg.Enabled ~= any then sg.Enabled = any end
		if part.CanQuery ~= any then part.CanQuery = any end
		-- the first-person tools (the torch and pickaxe copies that live under the camera) stood in front of the panel:
		-- they are hidden from their owner while a panel is up
		local function tools(hide)
			for _, m in workspace.CurrentCamera:GetChildren() do
				if m ~= part and m.Name ~= "ARSettings" and m.Name ~= "SpatialCard" then
					for _, d in m:GetDescendants() do
						if d:IsA("BasePart") then d.LocalTransparencyModifier = hide and 1 or 0 end
					end
					if m:IsA("BasePart") then m.LocalTransparencyModifier = hide and 1 or 0 end
				end
			end
		end
		local fb = workspace.CurrentCamera:FindFirstChild("ForgeBlur") -- the forge's own blur would blur the forge itself now that it stands in the world
		if fb then fb.Enabled = not any end
		if not any then
			if wasAny then
				if hook.blur then hook.blur.Enabled = true end
				tools(false)
			end
			wasAny = false
			return
		end
		wasAny = true
		tools(true)
		if hook.blur then hook.blur.Enabled = false end -- the world stays sharp behind the panel

		local cam = workspace.CurrentCamera
		local vp, canvas = cam.ViewportSize, gui.AbsoluteSize
		if canvas.X < 10 or canvas.Y < 10 then return end
		sg.CanvasSize = canvas
		local viewH = 2 * DIST * math.tan(math.rad(cam.FieldOfView / 2)) -- the view's height in studs at the panel's distance
		local h = viewH * (canvas.Y / vp.Y) * FILL
		part.Size = Vector3.new(h * canvas.X / canvas.Y, h, 0.02)
		-- the swing in: it turns from edge-on to its resting angle on a spring (about 3.5 swings a second, lightly damped)
		local w = 2 * math.pi * 3.5
		swingV += (-(w * w) * swing - 2 * 0.42 * w * swingV) * math.min(dt, 1 / 30)
		swing += swingV * math.min(dt, 1 / 30)
		-- it leans toward the mouse a little, so moving the cursor shows its depth
		local m = UIS:GetMouseLocation()
		local goal = Vector2.new((m.X / vp.X - 0.5) * 2, (m.Y / vp.Y - 0.5) * 2)
		lean = lean:Lerp(goal, math.min(1, dt * 6))
		local inset = GuiService:GetGuiInset().Y
		local want = cam.CFrame
			* CFrame.new(viewH * 0.012, -viewH * (inset / 2) / vp.Y * FILL, -DIST)
			* CFrame.Angles(0, math.pi, 0) -- the front face looks back at the eye
			* CFrame.Angles(math.rad(PITCH - lean.Y * 0.5), math.rad(-YAW - swing * 62 - lean.X * 0.8), 0)
		-- a short lag behind the view: when the camera turns, the panel trails and catches up
		last = last and last:Lerp(want, math.min(1, dt * 14)) or want
		if (last.Position - want.Position).Magnitude > 2 then last = want end
		part.CFrame = last
	end)

	plr:GetAttributeChangedSignal("DevFlatUI"):Connect(function() -- a test can put every menu back on the flat HUD
		if plr:GetAttribute("DevFlatUI") then
			for f in held do release(f) end
			RunService:UnbindFromRenderStep("PixelSpatialPanels")
			sg.Enabled, hook.spatialOpen, live, part.CanQuery = false, false, false, false
		end
	end)
end

return M
