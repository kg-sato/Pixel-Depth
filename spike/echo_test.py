"""Echo Tap (2026-11-20): a tap on a cave wall puts a number on the rock (Shared.MiningLoops, screen-space EchoMarks).
    python spike/echo_test.py      (Studio hook DevEcho: a tap at the screen centre)"""
import time, threading
import night as N
C1 = lambda code: (N.lua(code, "Client").splitlines() or ["?"])[-1]
N.play(True); time.sleep(6)
N.key("Q"); time.sleep(30)
code = """local p=game.Players.LocalPlayer local h=p.Character.HumanoidRootPart local cam=workspace.CurrentCamera local rp=RaycastParams.new() rp.FilterDescendantsInstances={p.Character}
local best,bd for i=0,23 do local a=i*math.pi/12 local d=Vector3.new(math.cos(a),0,math.sin(a)) local r=workspace:Raycast(h.Position+Vector3.new(0,1.5,0),d*40,rp) if r and (not bd or r.Distance<bd) and r.Distance>3 then best,bd=d,r.Distance end end
local eye=h.Position+Vector3.new(0,1.5,0)+best*(bd-7) local t=os.clock() local fired=false local seen='none'
while os.clock()-t<3 do cam.CameraType=Enum.CameraType.Scriptable cam.CFrame=CFrame.lookAt(eye,eye+best) if not fired and os.clock()-t>0.5 then fired=true p:SetAttribute('DevEcho',os.clock()) end
 local m=p.PlayerGui:FindFirstChild('EchoMarks') local l=m and m:FindFirstChildOfClass('TextLabel') if l and os.clock()-t>1.2 then seen='number '..l.Text..' visible '..tostring(l.Visible) end
 game:GetService('RunService').RenderStepped:Wait() end return seen"""
print("echo:", C1(code))
print("client errors:", C1("local t={} for _,m in game:GetService('LogService'):GetLogHistory() do if m.messageType==Enum.MessageType.MessageError and not string.find(m.message,'Requester') and not string.find(m.message,'not authorized') then t[#t+1]=string.sub(m.message,1,140) end end return #t..' '..table.concat(t,' | ')"))
N.play(False)
