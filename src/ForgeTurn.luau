-- ReplicatedStorage.Shared.ForgeTurn (src/ForgeTurn.luau): a test scene for ForgeStory, never shown to players.
-- It stands ONE forge model on a grey stage in three views (front, side, three-quarter back) under plain daylight, so the
-- model can be graded alone against its own reference sheet: ForgeStory.play({ model = "__turn", turn = "<model>", freeze = 1 }).
-- Used by spike/asset_shots.py.
local M = { length = 30, named = 29 }

function M.setup(ctx)
	local name = ctx.opt.turn
	local rgb, v3 = Color3.fromRGB, Vector3.new
	local probe = ctx.prop(name, CFrame.new())
	local lo, hi = v3(1e9, 1e9, 1e9), v3(-1e9, -1e9, -1e9)
	probe:all(function(p)
		local c, s = ctx.O:PointToObjectSpace(p.Position), p.Size / 2
		lo, hi = lo:Min(c - s), hi:Max(c + s)
	end)
	local size, mid = hi - lo, (lo + hi) / 2
	local W = math.max(size.X, size.Z) * 1.2
	local rigs = { probe }
	probe.root = ctx.O * CFrame.new(-mid.X, -lo.Y, -mid.Z)
	probe:update()
	for i, yaw in { 90, 150 } do
		local turn = CFrame.Angles(0, math.rad(yaw), 0)
		table.insert(rigs, ctx.prop(name, CFrame.new((i == 1 and W or -W), -lo.Y, 0) * turn * CFrame.new(-mid.X, 0, -mid.Z)))
	end
	for _, r in rigs do r:all(function(p) if p.Material ~= Enum.Material.Neon then p.Material = Enum.Material.Rubber end end) end
	ctx.part(v3(W * 12, 1, W * 12), CFrame.new(0, -0.5, 0), rgb(150, 150, 158))
	ctx.part(v3(W * 12, size.Y * 6, 1), CFrame.new(0, size.Y, W * 2.6), rgb(160, 160, 170))
	ctx.light({ Ambient = rgb(120, 120, 128), OutdoorAmbient = rgb(120, 120, 128), Brightness = 2.4, ExposureCompensation = 0, ColorShift_Top = rgb(255, 250, 240) })
	ctx.key(v3(0.5, 0.8, -0.6))
	local span = math.max(W * 3.3 / 2.5, size.Y * 1.35)
	local dist = span / (2 * math.tan(math.rad(15)))
	return function()
		ctx.cam = ctx.O * CFrame.lookAt(v3(0, size.Y * 0.62, -dist), v3(0, size.Y * 0.47, 0))
		ctx.fov = 30
		ctx.dof.FarIntensity, ctx.dof.InFocusRadius = 0, 500
	end
end

return M
