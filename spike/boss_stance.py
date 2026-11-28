"""Stand the player on open floor facing a boss (the tour's stance code) and take a still from the player's own view.
python spike/boss_stance.py <Warden|KilnGolem> <shot name>   (Play running, the player in that boss's cave, NIGHT_SERIAL=1)"""
import sys, time, pathlib
here = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(here))
import night as N
boss, nm = sys.argv[1], sys.argv[2]
P = "local p=game.Players:GetPlayers()[1] local h=p.Character.HumanoidRootPart local cv=workspace.Caves "
print(N.lua(P + "local w=cv:FindFirstChild('" + boss + "',true) local o=w.PrimaryPart.Position local away=(w:GetPivot().LookVector*Vector3.new(1,0,1)).Unit "
      "local rp=RaycastParams.new() rp.FilterDescendantsInstances={w,p.Character} rp.FilterType=Enum.RaycastFilterType.Exclude local best "
      "for _,deg in {0,15,-15,30,-30,45,-45,60,-60,90,-90,180} do local d=CFrame.Angles(0,math.rad(deg),0):VectorToWorldSpace(away) local hit=workspace:Raycast(o+d*15+Vector3.new(0,6,0),Vector3.new(0,-14,0),rp) "
      "if hit and math.abs(hit.Position.Y-(o.Y-4))<4 then local eye=hit.Position+Vector3.new(0,4.5,0) local see=workspace:Raycast(eye,(o-eye),rp) local roof=workspace:Raycast(eye,Vector3.new(0,5,0),rp) "
      "local back=workspace:Raycast(eye,d*5,rp) local box=#workspace:GetPartBoundsInBox(CFrame.new(hit.Position+Vector3.new(0,3.2,0)),Vector3.new(3,5,3)) "
      "if not see and not roof and not back and box==0 then best=hit.Position break end end end "
      "if not best then local d=away local hit=workspace:Raycast(o+d*15+Vector3.new(0,6,0),Vector3.new(0,-14,0),rp) best=hit and hit.Position or o+d*15 end "
      "h.AssemblyLinearVelocity=Vector3.zero h.CFrame=CFrame.lookAt(best+Vector3.new(0,3,0),Vector3.new(o.X,best.Y+3,o.Z)) return 'ok'", "Server").splitlines()[-1])
time.sleep(1.2)
N.lua("local w=workspace.Caves:FindFirstChild('" + boss + "',true) local cam=workspace.CurrentCamera cam.CFrame=CFrame.lookAt(cam.CFrame.Position,w.PrimaryPart.Position+Vector3.new(0,1.5,0)) return 1", "Client")
time.sleep(1.5)
print(N.shot(nm))
