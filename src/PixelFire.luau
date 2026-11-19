-- PixelFire (ReplicatedStorage.Shared.PixelFire): chunky pixel flames from one grayscale 4x4 flipbook (art/fx/pixel_fire_4x4.png,
-- made by spike/pixel_fire.py, image 103206971700437), tinted per use: orange camp fires, cyan crystal vents, green spore vents.
-- Reference: Instagram Df2oc8rElqf (@vfx_therapy / @simonschreibt), sculpted chunky fire baked to a grayscale flipbook and
-- coloured by the emitter (directive v12 task 6, 2026-11-19). Server or client: M.attach(part, colorA, colorB, size).
local M = {}
M.TEXTURE = "rbxassetid://103206971700437"

function M.attach(host, a, b, size)
	size = size or 3
	local e = Instance.new("ParticleEmitter")
	e.Name = "PixelFire"
	e.Texture = M.TEXTURE
	e.FlipbookLayout, e.FlipbookMode, e.FlipbookFramerate = Enum.ParticleFlipbookLayout.Grid4x4, Enum.ParticleFlipbookMode.Loop, NumberRange.new(12, 16)
	e.Color = ColorSequence.new(a, b or a)
	e.LightEmission, e.LightInfluence = 0.55, 0
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, size * 0.75), NumberSequenceKeypoint.new(0.3, size), NumberSequenceKeypoint.new(1, size * 0.45) })
	e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(0.15, 0.05), NumberSequenceKeypoint.new(0.75, 0.15), NumberSequenceKeypoint.new(1, 1) })
	e.Lifetime, e.Rate = NumberRange.new(0.7, 1.0), size * 2.4
	e.Speed, e.SpreadAngle = NumberRange.new(0.6, 1.3), Vector2.new(6, 6)
	e.EmissionDirection, e.Acceleration = Enum.NormalId.Top, Vector3.new(0, 1.2, 0)
	e.Rotation, e.RotSpeed = NumberRange.new(-6, 6), NumberRange.new(0)
	e.Parent = host
	return e
end

return M
