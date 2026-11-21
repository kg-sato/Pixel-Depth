-- MuckPeeks (ReplicatedStorage.Shared.MuckPeeks), started by PixelClient. Directive v13 phase 4 (vault Research/UI/Non-Distracting
-- HUD and Feature Inspirations (2026-11-20), Bucket C #6, Lethal Company / Dandy's World): a light-shy Muck-Pup peeks over a
-- boulder at the branch mouths (the PeekSpot attachments from ServerScriptService.CaveProps) when you are 30 to 50 studs away,
-- blinking two amber eyes; the moment your torch sweeps over it (you look within about 14 degrees of it) it squeaks and ducks
-- behind the rock, and peeks again 8 to 15 s later. It teaches "light scares them" before any Gloomling can hurt you.
-- Client-only and cosmetic: no collisions, no rewards, no damage.
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local M = {}

function M.start(E)
	local plr = E.plr
	local pups = {}
	local function make(a)
		local m = Instance.new("Model")
		m.Name = "MuckPup"
		local function piece(name, size, color, mat, shape)
			local p = Instance.new("Part")
			p.Name, p.Size, p.Color, p.Material, p.Anchored = name, size, color, mat or Enum.Material.SmoothPlastic, true
			p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = false, false, false, false
			if shape then p.Shape = shape end
			p.Parent = m
			return p
		end
		local body = piece("Body", Vector3.new(1.5, 1.2, 1.3), Color3.fromRGB(34, 24, 30), Enum.Material.SmoothPlastic, Enum.PartType.Ball)
		local eyes = {}
		for s = -1, 1, 2 do
			local e = piece("Eye", Vector3.new(0.3, 0.3, 0.12), Color3.fromRGB(255, 186, 70), Enum.Material.Neon)
			e:SetAttribute("Side", s)
			table.insert(eyes, e)
		end
		m.PrimaryPart = body
		m.Parent = workspace:FindFirstChild("ClientFX") or workspace
		local face = a:GetAttribute("Face") or Vector3.zAxis
		return { a = a, m = m, body = body, eyes = eyes, face = Vector3.new(face.X, 0, face.Z).Unit, top = a:GetAttribute("Top") or a.WorldPosition.Y + 1.1, h = 0, goal = 0, nextPeek = os.clock() + math.random() * 6, blink = 0 }
	end
	local function scan()
		for _, a in workspace.Terrain:GetChildren() do
			if a.Name == "PeekSpot" and a:IsA("Attachment") and not pups[a] then pups[a] = make(a) end
		end
	end
	task.delay(6, scan)
	workspace.Terrain.ChildAdded:Connect(function(c) if c.Name == "PeekSpot" then task.defer(scan) end end)

	local function place(p)
		local base = p.a.WorldPosition
		local y = p.top - 1.15 + p.h * 1.05 -- hidden: wholly under the rock's top; peeking: eyes just over it
		local cf = CFrame.lookAt(Vector3.new(base.X, y, base.Z), Vector3.new(base.X, y, base.Z) + p.face)
		p.body.CFrame = cf
		local open = os.clock() < p.blink and 0.15 or 1
		for _, e in p.eyes do
			e.CFrame = cf * CFrame.new(e:GetAttribute("Side") * 0.32, 0.18, -0.6)
			e.Size = Vector3.new(0.3, 0.3 * open, 0.12)
			e.Transparency = p.h > 0.3 and 0 or 1
		end
	end
	RunService.Heartbeat:Connect(function(dt)
		local h = E.hrp and E.hrp()
		local inCave = plr:GetAttribute("InCave") == true
		local cam = workspace.CurrentCamera
		local now = os.clock()
		for _, p in pups do
			local d = h and (p.a.WorldPosition - h.Position).Magnitude or 999
			if not inCave or d > 70 then
				p.h, p.goal = 0, 0
				p.m.Parent = nil -- nothing to draw far away
				continue
			end
			if p.m.Parent == nil then p.m.Parent = workspace:FindFirstChild("ClientFX") or workspace end
			local toPup = (p.body.Position - cam.CFrame.Position)
			local seen = toPup.Magnitude > 0 and cam.CFrame.LookVector:Dot(toPup.Unit) > math.cos(math.rad(14))
			if p.goal > 0 and seen and p.h > 0.5 then -- the torch found it: a squeak and a duck
				p.goal, p.nextPeek = 0, now + 8 + math.random() * 7
				if E.sfx then E.sfx("pop", 2.3) end
			elseif p.goal == 0 and now > p.nextPeek and d > 30 and d < 50 and not seen then
				p.goal = 1
				p.blink = 0
			end
			if p.goal > 0 and now > p.blink + 2.5 and math.random() < dt * 0.5 then p.blink = now + 0.12 end -- a slow blink now and then
			local rate = p.goal > p.h and 2.5 or 9 -- up slowly, down fast
			p.h = math.clamp(p.h + math.clamp(p.goal - p.h, -rate * dt, rate * dt), 0, 1)
			place(p)
		end
	end)
end

return M
