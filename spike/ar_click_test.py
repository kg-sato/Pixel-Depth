"""Do the look-around settings take clicks? Starts Play, opens the settings (N), clicks the Screen shake toggle where it is
drawn and reads the player's NoShake attribute (nil -> true).   python spike/ar_click_test.py"""
import time
import night as N
C1 = lambda code: N.lua(code, "Client").splitlines()[-1]
N.play(True); time.sleep(8)
N.key("N"); time.sleep(2.4)
r = C1("local pg=game.Players.LocalPlayer.PlayerGui local sg=pg.AR_SETTINGS local o for _,d in sg:GetDescendants() do if d:IsA('TextButton') then o=d break end end "
       "local part=sg.Adornee local c=o.AbsolutePosition+o.AbsoluteSize/2 local cs=sg.AbsoluteSize "
       "local w=part.CFrame*Vector3.new(-(c.X/cs.X-0.5)*part.Size.X,(0.5-c.Y/cs.Y)*part.Size.Y,-part.Size.Z/2) local v=workspace.CurrentCamera:WorldToViewportPoint(w) "
       "local i=game:GetService('GuiService'):GetGuiInset() return math.floor(v.X)..','..math.floor(v.Y-i.Y)")
x, y = [int(v) for v in r.split(",")]
# the first simulated clicks after the panels appear are sometimes not delivered (seen 2026-11-12: clicks 1 and 2 lost, 3 and 4
# landed; cause unknown, a person moving a real mouse was not tested), so the test tries up to four times
for k in range(4):
    N.run("user_mouse_input", {"actions": [{"action": "moveTo", "x": x + k, "y": y}], "datamodel_type": "Client"}); time.sleep(0.5)
    N.run("user_mouse_input", {"actions": [{"action": "mouseButtonClick", "mouse_button": "left", "x": x + k, "y": y}], "datamodel_type": "Client"}); time.sleep(0.6)
    v = C1("return tostring(game.Players.LocalPlayer:GetAttribute('NoShake'))")
    if v == "true": break
print("toggle drawn at", x, y, "| clicks needed:", k + 1, "| NoShake after click:", v)
