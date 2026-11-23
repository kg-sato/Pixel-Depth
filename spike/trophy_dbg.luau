local g for _,d in workspace.Hub.TrophyHouse:GetChildren() do if d.Name=='TrophyGlass' and d:GetAttribute('Trophy')=='gate1' then g=d end end
local cam=workspace.CurrentCamera
local RS=game:GetService('RunService')
local cf=CFrame.lookAt((g.CFrame*CFrame.new(6.9,5,20)).Position,(g.CFrame*CFrame.new(6.9,-0.6,0)).Position)
RS:BindToRenderStep('dbgcam',2000,function() cam.CFrame=cf end)
task.wait(1)
local out, seen = {}, {}
for i=-3,3 do for j=-2,2 do
	local r=cam:ViewportPointToRay(cam.ViewportSize.X*(0.5+i*0.12),cam.ViewportSize.Y*(0.5+j*0.15))
	local hit=workspace:Raycast(r.Origin,r.Direction*80)
	if hit and not seen[hit.Instance] then seen[hit.Instance]=true
		table.insert(out,hit.Instance:GetFullName()..' d='..math.floor(hit.Distance)..' ltm='..string.format('%.2f',hit.Instance.LocalTransparencyModifier)) end
end end
local pets = {}
for _, m in workspace:GetDescendants() do if m:IsA('Model') and m:GetAttribute('Pet') then local bp=m:FindFirstChildWhichIsA('BasePart',true) table.insert(pets, m:GetFullName()..' at '..tostring(math.floor((m:GetPivot().Position-cam.CFrame.Position).Magnitude))..' ltm '..(bp and string.format('%.2f',bp.LocalTransparencyModifier) or '?')) end end
return table.concat(out,'\n')..'\nPETS\n'..table.concat(pets,'\n')
