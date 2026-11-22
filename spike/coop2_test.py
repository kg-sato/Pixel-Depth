"""Directive v14 phase 4: a real two-player co-op test through StudioTestService:ExecuteMultiplayerTestAsync(2) (Studio in Edit mode).
Installs spike/coop2_server.luau and coop2_client.luau, starts the test (a server and two client windows), waits for its result
and removes the test scripts again.   python spike/coop2_test.py"""
import json, sys, time, pathlib
here = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(here))
import night as N
if "Edit" not in N.run("get_studio_state").split("Available")[0]: N.play(False); time.sleep(2)
srv = (here / "coop2_server.luau").read_text(encoding="utf-8")
cli = (here / "coop2_client.luau").read_text(encoding="utf-8")
assert "]=====]" not in srv + cli
print(N.lua("local o=game.ServerScriptService:FindFirstChild('Coop2Test') if o then o:Destroy() end o=game.StarterPlayer.StarterPlayerScripts:FindFirstChild('Coop2Client') if o then o:Destroy() end "
            "local s=Instance.new('Script') s.Name='Coop2Test' s.Source=[=====[" + srv + "]=====] s.Parent=game.ServerScriptService "
            "local c=Instance.new('LocalScript') c.Name='Coop2Client' c.Source=[=====[" + cli + "]=====] c.Parent=game.StarterPlayer.StarterPlayerScripts "
            "workspace:SetAttribute('Coop2Result', nil) "
            "task.spawn(function() local ok, r = pcall(function() return game:GetService('StudioTestService'):ExecuteMultiplayerTestAsync(2, { mode = 'coop2' }) end) "
            "workspace:SetAttribute('Coop2Result', game:GetService('HttpService'):JSONEncode({ ok = ok, r = r })) end) return 'started'", "Edit").splitlines()[-1])
res = None
for _ in range(60):
    time.sleep(10)
    out = (N.lua("return tostring(workspace:GetAttribute('Coop2Result'))", "Edit").splitlines() or ["nil"])[-1]
    if out.startswith("{"):
        res = out
        break
print("RESULT", res)
N.lua("local o=game.ServerScriptService:FindFirstChild('Coop2Test') if o then o:Destroy() end o=game.StarterPlayer.StarterPlayerScripts:FindFirstChild('Coop2Client') if o then o:Destroy() end workspace:SetAttribute('Coop2Result', nil) return 1", "Edit")
if res:
    d = json.loads(res)
    r = d.get("r")
    for line in (r.get("log", []) if isinstance(r, dict) else [str(d)]): print(line)
