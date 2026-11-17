"""Directive v10.0 re-run (2026-11-16 night): the grading set, one still per HUD defect, in a fresh Play session.
    python spike/v10n_shots.py <round>      stills: <workspace>/Overnight/judge/v10n_<round>/NN_name.png, plus the HUD overlap
                                            report of each still in overlaps.txt
Shortcuts (say so to a grader): keys pressed by script, the MENU and timers pill clicked by script, teleports by the server,
Dev attributes (DevBoss, DevCodex), the camera aimed by script for the boss."""
import sys, time
import night as N

rnd = sys.argv[1] if len(sys.argv) > 1 else "r1"
out = N.root / "Overnight" / "judge" / f"v10n_{rnd}"; out.mkdir(parents=True, exist_ok=True)
N.out = out
P = "local p=game.Players:GetPlayers()[1] local h=p.Character.HumanoidRootPart local cv=workspace.Caves "
rep = []


def S(code): return (N.lua(code, "Server").splitlines() or ["?"])[-1]
def C(code): return (N.lua(code, "Client").splitlines() or ["?"])[-1]


def shot(name):
    N.shot(name)
    r = C(open(N.game / "spike" / "hud_overlap.luau", encoding="utf-8").read())
    rep.append(f"{name}: {r}")
    print(name, r, flush=True)


N.play(False); N.restore()
N.run("start_stop_play", {"is_start": True}); time.sleep(12)
NAME = C("return game.Players.LocalPlayer.Name")
def click(path): N.run("user_mouse_input", {"actions": [{"action": "mouseButtonClick", "mouse_button": "left", "instance_path": "Players." + NAME + ".PlayerGui.PixelHUD." + path}], "datamodel_type": "Client"})

shot("01_town")
click("LeftColumn.Currency.MenuButton.Hit"); time.sleep(0.6); click("Timers.Main.Open"); time.sleep(1.5)
shot("02_town_menu_timers")
click("Timers.Main.Open"); time.sleep(0.3); click("LeftColumn.Currency.MenuButton.Hit"); time.sleep(0.5)
N.run("user_mouse_input", {"actions": [{"action": "moveTo", "x": 300, "y": 500}], "datamodel_type": "Client"})
N.key("N"); time.sleep(3)
shot("03_settings")
N.key("N"); time.sleep(1.2)
S(P + "p:SetAttribute('DevCodex',12) return 1"); time.sleep(1)
N.key("K"); time.sleep(3)
shot("04_codex")
N.key("K"); time.sleep(1)
N.key("Q"); time.sleep(32)
shot("05_cave")
import subprocess
subprocess.run([sys.executable, str(N.game / "spike" / "mg_night.py"), f"v10n_{rnd}", "strike"], capture_output=True, text=True, cwd=N.game / "spike")
import re
PILOT = re.search(r"PILOT = r'''(.*?)'''", (N.game / 'spike' / 'boss_fight_test.py').read_text(encoding='utf-8'), re.S).group(1)
def look(expr): C("local cv=workspace.Caves local cam=workspace.CurrentCamera cam.CFrame=CFrame.lookAt(cam.CFrame.Position," + expr + ") return 1")
S(P + "p:SetAttribute('DevEquip',6) local w=cv:FindFirstChild('Warden',true) local o=w.PrimaryPart.Position local t=cv:FindFirstChild('TentSide',true) local away=((o-t.Position)*Vector3.new(1,0,1)).Unit "
      "local rp=RaycastParams.new() rp.FilterDescendantsInstances={w,p.Character} rp.FilterType=Enum.RaycastFilterType.Exclude local best "
      "for _,deg in {35,-35,60,-60,0,90,-90,120,-120,150,-150,180} do local d=CFrame.Angles(0,math.rad(deg),0):VectorToWorldSpace(away) local hit=workspace:Raycast(o+d*10+Vector3.new(0,6,0),Vector3.new(0,-14,0),rp) "
      "if hit and math.abs(hit.Position.Y-(o.Y-4))<4 then local eye=hit.Position+Vector3.new(0,4.5,0) local see=workspace:Raycast(eye,(o-eye),rp) local roof=workspace:Raycast(eye,Vector3.new(0,5,0),rp) "
      "local back=workspace:Raycast(eye,d*5,rp) local box=#workspace:GetPartBoundsInBox(CFrame.new(hit.Position+Vector3.new(0,3.2,0)),Vector3.new(3,5,3)) "
      "if not see and not roof and not back and box==0 then best=hit.Position break end end end "  # open floor, a clear line to the boss, head room and nothing behind: the first try stood inside the rock
      "if not best then local d=Vector3.new(math.cos(math.rad(315)),0,math.sin(math.rad(315))) best=workspace:Raycast(o+d*10+Vector3.new(0,6,0),Vector3.new(0,-14,0),rp).Position end "
      "h.AssemblyLinearVelocity=Vector3.zero h.CFrame=CFrame.lookAt(best+Vector3.new(0,3,0),Vector3.new(o.X,best.Y+3,o.Z)) return 1"); time.sleep(1.5)  # on the side away from the camp tent (it filled a third of the picture)
look("cv:FindFirstChild('Warden',true).PrimaryPart.Position")
C(PILOT)
# the camera keeps looking at the boss and the floor before it through the fight
C("local RS=game:GetService('RunService') local w=workspace.Caves:FindFirstChild('Warden',true) local cam=workspace.CurrentCamera _G.BossLook=RS.RenderStepped:Connect(function() "
  "local to=w.PrimaryPart.Position-Vector3.new(0,2.5,0) local cf=CFrame.lookAt(cam.CFrame.Position,to) cam.CFrame=cam.CFrame:Lerp(cf,0.08) end) return 1")

S(P + "p:SetAttribute('DevBoss',1) return 1"); time.sleep(10)
shot("07_warden_fight")
time.sleep(5)
shot("08_warden_fight2")
for _ in range(30):
    time.sleep(2)
    if "bossWin" in C("return tostring(game.Players.LocalPlayer:GetAttribute('DevBossLog'))"): break
C("if _G.BossLook then _G.BossLook:Disconnect() end return 1")
import shutil
for f in (N.game / "captures" / "night").glob(f"v10n_{rnd}_strike*.png"): shutil.copy(f, out / ("06_" + f.name))
(out / "overlaps.txt").write_text("\n".join(rep) + "\n", encoding="utf-8")
N.play(False)
print("done", out)
