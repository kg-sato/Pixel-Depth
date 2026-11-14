"""Phase C bosses: can every attack be dodged from its marked safe place, and does it hit in its marked danger?
Starts Play, wakes the Root Warden with the Studio hook DevBoss, then runs each attack alone with DevBossAtk (no knot rounds),
with the player put in the danger and then in the safe place by the server. Then the same for the Kiln Golem's sweep and rings.
    python spike/boss_atk_test.py [shots]      "shots" also saves captures/night/boss_<attack>.png of each telegraph
Shortcuts: the player is put in the caves and moved by the server; HP is read from the player attribute the server sets."""
import sys, time
import night as N
C1 = lambda code: (N.lua(code, "Client").splitlines() or ["?"])[-1]
S1 = lambda code: (N.lua(code, "Server").splitlines() or ["?"])[-1]
SHOTS = "shots" in sys.argv
P = "local p=game.Players:GetPlayers()[1] local h=p.Character.HumanoidRootPart local cv=workspace.Caves "
LOG = ("local p=game.Players.LocalPlayer p:SetAttribute('DevBossLog','') game.ReplicatedStorage.Remotes.Fx.OnClientEvent:Connect(function(k,a,b,c) "
       "if string.sub(k,1,4)=='boss' then p:SetAttribute('DevBossLog',(p:GetAttribute('DevBossLog') or '')..' '..k..(k=='bossHit' and (':'..tostring(c)) or '')) end end) return 1")
def log(): return C1("return tostring(game.Players.LocalPlayer:GetAttribute('DevBossLog'))")
def clear(): C1("game.Players.LocalPlayer:SetAttribute('DevBossLog','') return 1")
def at(boss, r, ang, face=True):  # put the player r studs from the boss, on the floor, in direction ang (degrees)
    return S1(P + "local w=cv:FindFirstChild('%s',true) local o=w.PrimaryPart.Position local d=Vector3.new(math.cos(math.rad(%s)),0,math.sin(math.rad(%s))) "
              "local rp=RaycastParams.new() rp.FilterDescendantsInstances={w,p.Character} rp.FilterType=Enum.RaycastFilterType.Exclude "
              "local hit=workspace:Raycast(o+d*%s+Vector3.new(0,6,0),Vector3.new(0,-14,0),rp) if not hit then return 'no floor' end "
              "h.AssemblyLinearVelocity=Vector3.zero h.CFrame=CFrame.lookAt(hit.Position+Vector3.new(0,3,0),Vector3.new(o.X,hit.Position.Y+3,o.Z)) return 'ok'" % (boss, ang, ang, r))
def side(boss, studs):  # step sideways (across the line to the boss) by this many studs
    return S1(P + "local w=cv:FindFirstChild('%s',true) local o=w.PrimaryPart.Position local d=((h.Position-o)*Vector3.new(1,0,1)).Unit h.CFrame=h.CFrame+d:Cross(Vector3.yAxis)*%s return 1" % (boss, studs))
def attack(kind, wait, name=None):
    clear()
    S1(P + "p:SetAttribute('HP',100) p:SetAttribute('DevBossAtk','%s') return 1" % kind)
    if SHOTS and name:
        time.sleep(0.9); N.shot(name)
    time.sleep(wait)
    return log()
def run(boss, num, ang, tests):
    sfx = "" if num == 1 else str(num)
    S1(P + "p:SetAttribute('InCave',true) return 1")
    print(boss, "start place:", at(boss, 10, ang)); time.sleep(1.5)
    for label, kind, r, step, name in tests:
        at(boss, r, ang); time.sleep(0.6)
        if kind == "sweep" and step:  # the lane aims at where you stand when it starts: start it, then step aside
            clear()  # start it, wait 0.4 s and step aside in ONE call: with a slow Studio two calls took longer than the 1.5 s warning
            S1(P + "local w=cv:FindFirstChild('%s',true) local o=w.PrimaryPart.Position p:SetAttribute('DevBossAtk','sweep%s') task.wait(0.4) local d=((h.Position-o)*Vector3.new(1,0,1)).Unit h.CFrame=h.CFrame+d:Cross(Vector3.yAxis)*%s return 1" % (boss, sfx, step)); time.sleep(3.6)
            out = log()
        else:
            out = attack(kind + sfx, 4.4 if kind == "rings" else 3.6, name)
        print(boss, label + ":", out.strip())

N.play(True); time.sleep(8)
C1(LOG)
# the Warden's open floor runs toward 315 degrees (probed 2026-11-13): 24 studs of it
run("Warden", 1, 315, [
    ("slam, standing 10 studs away", "slam", 10, 0, "boss_slam"),
    ("slam, 24 studs away", "slam", 24, 0, None),
    ("sweep, standing in the lane", "sweep", 10, 0, "boss_sweep"),
    ("sweep, stepped 7 studs aside", "sweep", 10, 7, None),
    ("rings, standing on the first band (7)", "rings", 7, 0, "boss_rings"),
    ("rings, standing in the first gap (10.5)", "rings", 10.5, 0, None),
    ("rings, standing on the second band (14)", "rings", 14, 0, None),
])
print("client errors:", C1("local t={} for _,m in game:GetService('LogService'):GetLogHistory() do if m.messageType==Enum.MessageType.MessageError and not string.find(m.message,'Requester') then t[#t+1]=string.sub(m.message,1,140) end end return #t..' '..table.concat(t,' | ')"))
N.play(False); time.sleep(3)
N.play(True); time.sleep(8)
C1(LOG)
run("KilnGolem", 2, 180, [
    ("sweep, standing in the lane", "sweep", 10, 0, "boss2_sweep"),
    ("sweep, stepped 7 studs aside", "sweep", 10, 7, None),
    ("rings, standing on the second band (14)", "rings", 14, 0, "boss2_rings"),
    ("rings, standing in the second gap (17.5)", "rings", 17.5, 0, None),
])
print("client errors 2:", C1("local t={} for _,m in game:GetService('LogService'):GetLogHistory() do if m.messageType==Enum.MessageType.MessageError and not string.find(m.message,'Requester') then t[#t+1]=string.sub(m.message,1,140) end end return #t..' '..table.concat(t,' | ')"))
N.play(False)
