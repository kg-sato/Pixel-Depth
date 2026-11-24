"""Master Directive v15: stills of a rare hatch's two-beat showcase (gather, then rear up and roar) in the real hatch scene.
    python spike/v15_hatch.py <pet> <tag>    -> captures/night/v15hatch_<tag>_<n>.png at several moments after the hatch starts"""
import pathlib, sys, threading, time
here = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(here))
import night as N
pet = sys.argv[1] if len(sys.argv) > 1 else "Fafnir"
tag = sys.argv[2] if len(sys.argv) > 2 else "a"
N.play(False); N.play(True); time.sleep(9)
# when does the pet land? the client notes the hero act's start (PetVoxels.hero sets rig.act = "hero")
N.lua("workspace:SetAttribute('DevHeroAt',nil) return 1", "Client")  # PetVoxels.hero sets it in Studio
N.lua("workspace:SetAttribute('DevHeroSlow',4) return 1", "Server")
N.lua(f"game.ReplicatedStorage.Remotes.Fx:FireClient(game.Players:GetPlayers()[1], 'hatch', '{pet}') return 1", "Server")
t0 = time.time()
for _ in range(200):
    if N.lua("return tostring(workspace:GetAttribute('DevHeroAt')~=nil)", "Client").splitlines()[-1] == "true": break
    time.sleep(0.1)
print("hero act began %.1f s after the hatch" % (time.time() - t0), flush=True)
t1 = time.time()
for i, d in enumerate((0.0, 3.4, 6.0)):  # with DevHeroSlow 4: the gather (0 to 3 s), the rear-up roar (3 to 6.6 s), the settle
    while time.time() - t1 < d: time.sleep(0.05)
    print(i, N.shot(f"v15hatch_{tag}_{i}").name, "at %.1f" % (time.time() - t1), flush=True)
time.sleep(8)
N.lua("workspace:SetAttribute('DevHeroSlow',nil) return 1", "Server")
