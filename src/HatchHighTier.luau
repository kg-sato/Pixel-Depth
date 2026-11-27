-- HatchHighTier (ReplicatedStorage.Shared.HatchHighTier): the Legendary, Mythic and Secret set pieces grown into acts (vault
-- Briefs/Pet Hatch Cutscenes (2026-11-26): Legendary +4.8 s in three cuts, Mythic +6.2 s in four, Secret +8.0 s in five). It
-- wraps Shared.HatchSignature's own hoard, storm, coil and void (their props and timing stay theirs) with longer omens and new
-- camera cuts, and adds the beats the brief names: Ouro's dead-silent black frame with only its magenta eye-slits, Ninering's
-- humble fake-out (it trembles like a Rare, glitches, "WAIT..." then "???") before the cave unmakes itself, and its 0.35 s
-- singularity dot. Fast cutscenes keep 1.6 s of each. Everything dies with ctx.world. Display only.
local M = {}

local function overlay(ctx, name)
	local pg = game:GetService("Players").LocalPlayer:FindFirstChildOfClass("PlayerGui")
	if not pg then return nil end
	local g = Instance.new("ScreenGui")
	g.Name, g.IgnoreGuiInset, g.DisplayOrder, g.ResetOnSpawn, g.Enabled = name, true, 60, false, false
	local f = Instance.new("Frame")
	f.Size, f.BackgroundColor3, f.BorderSizePixel = UDim2.fromScale(1, 1), Color3.new(0, 0, 0), 0
	f.Parent = g
	g.Parent = pg
	ctx.world.Destroying:Connect(function() g:Destroy() end)
	return g, f
end
local function cut(u, a, b) return u >= a and u < b, (u - a) / math.max(b - a, 1e-3) end

function M.apply(SIG)
	local hoard, storm, coil, void = SIG.hoard, SIG.storm, SIG.coil, SIG.void
	if hoard then -- FAFNIR: the hoard piles (wide, low), the wyrm wakes (tight on the skull's eyes), roar and fracture (low hero)
		local step = hoard.step
		hoard.omen, hoard.fastOmen = 4.8, 1.6
		hoard.step = function(ctx, u, dt)
			local p, l, f = step(ctx, u, dt)
			if u < 0.31 then return ctx.NEST + Vector3.new(-5, 1.0, -10), ctx.NEST + Vector3.new(0, 2.5, 2), 60 end
			local on, v = cut(u, 0.31, 0.69)
			if on then return ctx.NEST + Vector3.new(0.6, 5.6 + v * 0.6, -3.5), ctx.NEST + Vector3.new(0, 7.2, 7.5), 42 end
			return p, l, f
		end
		local start = hoard.start
		hoard.start = function(ctx) start(ctx) if ctx.caption then ctx.caption.Text = "THE VAULT BREATHES BENEATH ITS GOLD." end end
	end
	if storm then -- KIRIN: thunderheads gather (low, tilting skyward), twin bolts strike (side cut), the cleansing ripple
		local step = storm.step
		storm.omen, storm.fastOmen = 4.8, 1.6
		storm.step = function(ctx, u, dt)
			local p, l, f = step(ctx, u, dt)
			if u < 0.33 then local v = u / 0.33 return ctx.NEST + Vector3.new(1, 0.6, -8), ctx.NEST + Vector3.new(0, 3 + v * 9, 2), 62 end
			local on = cut(u, 0.33, 0.71)
			if on then return ctx.NEST + Vector3.new(-8, 2.4, 0.5), ctx.NEST + Vector3.new(0, 2.2, 0), 48 end
			return p, l, f
		end
		local start = storm.start
		storm.start = function(ctx) start(ctx) if ctx.caption then ctx.caption.Text = "LIGHTNING KNEELS WHERE CLEAR WATER FLOWS." end end
	end
	if coil then -- OURO: time halts (still and wide), the serpent coils (a 150-degree orbit), glass fracture (tight push), black beat
		local step, burst = coil.step, coil.burst
		coil.omen, coil.fastOmen = 6.2, 1.6
		coil.step = function(ctx, u, dt)
			local p, l, f = step(ctx, u, dt)
			local st = ctx.state
			if u < 0.24 then return ctx.NEST + Vector3.new(0, 3, -12), ctx.NEST + Vector3.new(0, 2, 0), 56 end
			local on, v = cut(u, 0.24, 0.55)
			if on then local a = math.rad(-75 + v * 150) return ctx.NEST + Vector3.new(math.sin(a) * 8, 3.2, -math.cos(a) * 8), ctx.NEST + Vector3.new(0, 2, 0), 50 end
			on, v = cut(u, 0.55, 0.96)
			if on then return ctx.NEST + Vector3.new(0, 2.2, -7 + v * 2.6), ctx.NEST + Vector3.new(0, 2.1, 0), 44 - v * 6 end
			if not st.blackGui then -- the last 0.25 s: dead-silent black, only the eye-slits burn in the middle
				local g, f2 = overlay(ctx, "HatchEyes")
				if g then
					for sgn = -1, 1, 2 do
						local e = Instance.new("Frame")
						e.Size, e.Position, e.AnchorPoint, e.BackgroundColor3, e.BorderSizePixel, e.Rotation = UDim2.fromScale(0.07, 0.012), UDim2.fromScale(0.5 + sgn * 0.06, 0.48), Vector2.new(0.5, 0.5), Color3.fromRGB(255, 60, 200), 0, sgn * -8
						e.Parent = f2
					end
					g.Enabled = true
				end
				st.blackGui = g or true
				local sg = game:GetService("SoundService")
				st.vol = sg:FindFirstChild("PixelMaster") and sg.PixelMaster.Volume
				if st.vol then sg.PixelMaster.Volume = 0 end
			end
			return p, l, f
		end
		coil.burst = function(ctx)
			local st = ctx.state
			if typeof(st.blackGui) == "Instance" then st.blackGui:Destroy() end
			local sg = game:GetService("SoundService")
			if st.vol and sg:FindFirstChild("PixelMaster") then sg.PixelMaster.Volume = st.vol end
			burst(ctx)
		end
		local start = coil.start
		coil.start = function(ctx) start(ctx) if ctx.caption then ctx.caption.Text = "NO END. ONLY THE COIL CLOSING." end end
	end
	if void then -- NINERING: the humble fake-out, then the grotto unmakes itself, nine rings, the singularity, the cathedral
		local start, step, burst = void.start, void.step, void.burst
		void.omen, void.fastOmen = 8.0, 1.6
		local FAKE = 0.2
		void.start = function(ctx)
			ctx.state.fake = true
			if ctx.caption then ctx.caption.Text = "A FAINT GLOW..." end
		end
		void.step = function(ctx, u, dt)
			local st = ctx.state
			if u < FAKE and not ctx.fast then -- an ordinary Rare tremble, white going sapphire... then a glitch
				local v = u / FAKE
				if v > 0.6 and not st.glitched then
					st.glitched = true
					if ctx.caption then ctx.caption.Text = "WAIT..." end
					ctx.sfx("breakRock", 2.6)
					local g = overlay(ctx, "HatchGlitch")
					if g then
						g:FindFirstChildOfClass("Frame").BackgroundColor3 = Color3.fromRGB(255, 200, 80)
						g:FindFirstChildOfClass("Frame").BackgroundTransparency = 0.7
						g.Enabled = true
						task.delay(0.12, function() g:Destroy() end)
					end
				end
				if v > 0.85 and ctx.caption then ctx.caption.Text = "???" end
				local j = st.glitched and (math.random() - 0.5) * 0.3 or 0
				return ctx.NEST + Vector3.new(j, 2, -6.5), ctx.NEST + Vector3.new(0, 1.6, 0), 48
			end
			if not st.voidStarted then
				st.voidStarted = true
				start(ctx)
				if ctx.caption then ctx.caption.Text = "NINE ORBITS BENT BEFORE THE CORE." end
			end
			local w = (u - FAKE) / (1 - FAKE)
			local p, l, f = step(ctx, w, dt)
			if u > 0.925 and u < 0.97 then -- the singularity: 0.35 s of black with one pulsing white star
				if not st.dot then
					local g, f2 = overlay(ctx, "HatchDot")
					if g then
						local d = Instance.new("Frame")
						d.Size, d.Position, d.AnchorPoint, d.BackgroundColor3, d.BorderSizePixel = UDim2.fromOffset(10, 10), UDim2.fromScale(0.5, 0.5), Vector2.new(0.5, 0.5), Color3.new(1, 1, 1), 0
						local c = Instance.new("UICorner")
						c.CornerRadius = UDim.new(0.5, 0)
						c.Parent = d
						d.Parent = f2
						g.Enabled = true
					end
					st.dot = g or true
				end
			elseif u >= 0.97 and typeof(st.dot) == "Instance" then
				st.dot:Destroy()
				st.dot = false
			end
			return p, l, f
		end
		void.burst = function(ctx)
			local st = ctx.state
			if not st.voidStarted then st.voidStarted = true start(ctx) end
			if typeof(st.dot) == "Instance" then st.dot:Destroy() end
			burst(ctx)
		end
	end
end

return M
