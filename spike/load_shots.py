"""Loading screen stills through Studio's screen capture (the window recorder freezes when the display sleeps at night).
Starts the loading screen with the game's own Config.LOADING (min = 9 s) and takes stills at a few moments.
    python spike/load_shots.py <prefix>     -> captures/night/<prefix>_<n>.png"""
import sys, time, threading
import night as N
pre = sys.argv[1]
N.lua('local C=require(game.ReplicatedStorage.Shared.Config) task.spawn(function() local t=table.clone(C.LOADING) t.on,t.min=true,9 require(game.ReplicatedStorage.Shared.LoadingScreen).start({ C = { LOADING = t, UI_GLASS = C.UI_GLASS }, plr = game.Players.LocalPlayer }) end) return 1', "Client")
t0 = time.time()
for k, at in enumerate((1.2, 2.2, 5.0)):
    while time.time() - t0 < at: time.sleep(0.05)
    N.shot(f"{pre}_{k}")
print("done")
