"""Touch layout test (Studio open, Edit mode): DevTouch on, town then caves; the thumb buttons show, FLARE spends a flare,
SONAR lights deposits, key caps are hidden, no HUD overlap.    python spike/touch_test.py"""
import sys, time, pathlib
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import night
HUD = "game.Players.LocalPlayer.PlayerGui.PixelHUD"
def c(code): return night.lua(code, "Client").splitlines()[-1]
night.play(True); time.sleep(8)
c("game.Players.LocalPlayer:SetAttribute('DevTouch', true) return 1"); time.sleep(1)
print("town: notes", c(f"return tostring({HUD}.TouchNotes.Visible)"), "flare", c(f"return tostring({HUD}.TouchFlare.Visible)"))
night.shot("touch_town")
print("town overlap:", c(open(pathlib.Path(__file__).parent / "hud_overlap.luau").read()))
night.key("Q"); time.sleep(34)
print("cave: flare", c(f"return tostring({HUD}.TouchFlare.Visible)"), "sonar", c(f"return tostring({HUD}.TouchSonar.Visible)"), "ping", c(f"return tostring({HUD}.TouchPing.Visible)"), "notes", c(f"return tostring({HUD}.TouchNotes.Visible)"))
print("key caps visible:", c(f"local n=0 for _,d in {HUD}:GetDescendants() do if d.Name=='KeyHint' and d.Visible then n+=1 end end return n"))
night.shot("touch_cave")
print("cave overlap:", c(open(pathlib.Path(__file__).parent / "hud_overlap.luau").read()))
from prompt_test import SAFE
night.lua(SAFE + "local C=require(game.ReplicatedStorage.Shared.Config) local best for _,d in workspace.Caves.Deposits:GetChildren() do if d:IsA('Model') and d.PrimaryPart then local m=(d.PrimaryPart.Position-C.CAVE_ORIGIN).Magnitude if m>45 and m<95 then best=d break end end end "
          "game.Players:GetPlayers()[1].Character.HumanoidRootPart.CFrame=CFrame.new(safe(best.PrimaryPart.Position)) return 1", "Server"); time.sleep(3)
NAME = c("return game.Players.LocalPlayer.Name")
def click(path): return night.run("user_mouse_input", {"actions": [{"action": "mouseButtonClick", "mouse_button": "left", "instance_path": path}], "datamodel_type": "Client"})[-60:]
# first person locks the mouse to the centre; a Modal button frees it so the scripted click can reach the thumb buttons (a finger needs no such help)
c(f"local b=Instance.new('TextButton') b.Name='TestModal' b.Modal=true b.Text='' b.BackgroundTransparency=1 b.Size=UDim2.fromOffset(1,1) b.Parent={HUD} return 1"); time.sleep(0.6)
before = c("return game.Players.LocalPlayer:GetAttribute('Flares')")
r = click(f"Players.{NAME}.PlayerGui.PixelHUD.TouchFlare"); time.sleep(1.5)
print("flare tap:", r, "|", before, "->", c("return game.Players.LocalPlayer:GetAttribute('Flares')"))
r = click(f"Players.{NAME}.PlayerGui.PixelHUD.TouchSonar"); time.sleep(0.8)
print("sonar tap:", r, "| glows", c("local n=0 for _,d in workspace.Caves.Deposits:GetDescendants() do if d.Name=='SonarGlow' then n+=1 end end return n"), "label", c(f"return {HUD}.TouchSonar.Text"))
print("errors:", c("local n,t=0,{} for _,m in game:GetService('LogService'):GetLogHistory() do if m.messageType==Enum.MessageType.MessageError and not string.find(m.message,'Requester') then n+=1 t[#t+1]=string.sub(m.message,1,300) end end return n..' '..table.concat(t,' || ')"))  # the messages too, not only the count
night.play(False)
