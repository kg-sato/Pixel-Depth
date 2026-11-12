"""Night helper for Pixel Depth (Studio open on the place). Run from anywhere.
    python night.py push            push every src file whose Studio Source differs (creates missing ModuleScripts), prints sizes
    python night.py play | stop     start / stop Play (play waits until the character exists)
    python night.py lua <Server|Client|Edit> "<code>"      or  lua <where> @file.luau
    python night.py shot <name>     capture to captures/night/<name>.png
    python night.py key <K> [K...]  key presses on the Client
    python night.py sizes           character counts of every src file (limit 200,000)"""
import ctypes, json, os, pathlib, subprocess, sys, tempfile, time
game = pathlib.Path(__file__).resolve().parent.parent
root = game.parent.parent  # the Roblox workspace (tools/)
out = game / "captures" / "night"; out.mkdir(parents=True, exist_ok=True)
SSS = {"Shop", "Analytics", "Boss", "HubBuilder", "CaveBuilder", "ZFix", "Gloom", "Glossify", "CaveEvents", "ClayCaves", "SoulTree"}
SKIP = {"install_pickaxes"}


def path_of(f):
    n = f.name.split(".")[0]
    if n == "PixelServer": return "ServerScriptService.PixelServer", "Script"
    if n == "PixelClient": return "StarterPlayer.StarterPlayerScripts.PixelClient", "LocalScript"
    if n in SSS: return "ServerScriptService." + n, "ModuleScript"
    return "ReplicatedStorage.Shared." + n, "ModuleScript"


def run(tool, args=None, shot=None, file=None):
    env = dict(os.environ)
    if shot: env["STUDIO_SHOT"] = str(shot)
    cmd = [sys.executable, str(root / "tools" / "studio_live.py"), tool]
    cmd += ["--file", file, "code", json.dumps(args or {})] if file else [json.dumps(args or {})]
    r = subprocess.run(cmd, capture_output=True, text=True, cwd=root, env=env, encoding="utf-8", errors="replace")
    return ((r.stdout or "") + (r.stderr or "")).strip()


def lua(code, where="Server"):
    with tempfile.NamedTemporaryFile("w", suffix=".luau", delete=False, encoding="utf-8") as t: t.write(code)
    try: return run("execute_luau", {"datamodel_type": where}, file=t.name)
    finally: os.unlink(t.name)


def restore():  # a minimised Studio captures grey: restore it
    u = ctypes.windll.user32
    def cb(h, _):
        n = u.GetWindowTextLengthW(h); b = ctypes.create_unicode_buffer(n + 1); u.GetWindowTextW(h, b, n + 1)
        if b.value.endswith("Roblox Studio") and u.IsIconic(h): u.ShowWindow(h, 9)
        return True
    u.EnumWindows(ctypes.WINFUNCTYPE(ctypes.c_bool, ctypes.c_void_p, ctypes.c_void_p)(cb), 0)


def shot(name):
    restore(); time.sleep(0.25)
    p = out / f"{name}.png"
    run("screen_capture", {"capture_id": name}, shot=p)
    return p


def key(*ks):
    for k in ks: run("user_keyboard_input", {"actions": [{"action": "keyPress", "key_code": k}], "datamodel_type": "Client"})


def push():
    if "Edit" not in run("get_studio_state").split("Available")[0]: play(False); time.sleep(1.5)  # scripts are pushed in Edit: a push during Play did nothing
    pushed = 0
    for f in sorted((game / "src").glob("*.luau")):
        if f.name.split(".")[0] in SKIP: continue
        path, cls = path_of(f)
        src = f.read_text(encoding="utf-8").replace("\r\n", "\n")
        assert len(src) < 199000, f"{f.name} is {len(src)} characters: over the Roblox limit"
        eq = "=" * next(n for n in range(1, 20) if f"]{'=' * n}]" not in src)
        parent, name = path.rsplit(".", 1)
        code = (f'local par = game\nfor s in string.gmatch("{parent}", "[^.]+") do par = par:FindFirstChild(s) end\n'
                f'local o = par:FindFirstChild("{name}")\nlocal new = [{eq}[\n{src}]{eq}]\n'
                f'if o and o.Source == new then return "same" end\n'
                f'if not o then o = Instance.new("{cls}") o.Name = "{name}" o.Parent = par end\n'
                f'o.Source = new\nreturn "PUSHED {path} " .. #o.Source')
        r = lua(code, "Edit").splitlines()[-1:]
        assert r and ("same" in r[0] or "PUSHED" in r[0]), f"push failed for {f.name}: {r}"
        if "same" not in r[0]: print(r[0]); pushed += 1
    print("push done,", pushed, "changed")


def play(on=True):
    print(run("start_stop_play", {"is_start": on})[-80:])
    if on:
        for _ in range(40):
            time.sleep(1.5)
            if "ready" in lua('local p=game.Players:GetPlayers()[1] return (p and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and workspace:FindFirstChild("Hub")) and "ready" or "wait"'): break
        restore(); time.sleep(2)


if __name__ == "__main__":
    a = sys.argv[1:]
    if a[0] == "push": push()
    elif a[0] == "play": play(True)
    elif a[0] == "stop": play(False)
    elif a[0] == "lua": print(lua(open(a[2][1:], encoding="utf-8").read() if a[2].startswith("@") else a[2], a[1]))
    elif a[0] == "shot": print(shot(a[1]))
    elif a[0] == "key": key(*a[1:])
    elif a[0] == "sizes":
        for f in sorted((game / "src").glob("*.luau")): print(f"{len(f.read_text(encoding='utf-8').replace(chr(13), '')):7d} {f.name}")
