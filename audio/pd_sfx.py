import subprocess, sys, glob, os, wave, numpy as np
out = sys.argv[1]; os.makedirs(out, exist_ok=True)
# name: (pack file, max seconds or None)
PICK = { "click": ("drop_001", None), "tab": ("select_005", 0.25), "open": ("maximize_007", None), "close": ("minimize_007", None),
 "pop": ("drop_003", None), "error": ("error_004", None), "coin": ("glass_005", None), "sparkle": ("glass_004", None),
 "hit": ("impactMining_002", 0.35), "clink": ("impactGlass_light_001", None), "breakRock": ("impactMining_004", None), "swing": ("cloth1", 0.45),
 "upgrade": ("confirmation_002", None), "claim": ("jingles_PIZZI00", None), "hatch": ("jingles_STEEL00", None), "step": ("footstep_concrete_000", None),
 "pluck": ("pluck_002", None), "land": ("impactSoft_medium_000", None) }
for name, (src, cut) in PICK.items():
    f = glob.glob(f"kenney/**/{src}.ogg", recursive=True)[0]
    raw = subprocess.run(["ffmpeg","-v","quiet","-i",f,"-ac","1","-ar","44100","-f","f32le","-"],capture_output=True).stdout
    x = np.frombuffer(raw, dtype=np.float32).copy()
    if cut: x = x[:int(cut*44100)]
    n = min(len(x)//4, 882); x[-n:] *= np.linspace(1, 0, n)  # fade the tail: no click at the cut
    x *= 0.85 / np.abs(x).max()  # the pack files peak over 1.0 (clipping): bring every sound to the same peak
    x = np.concatenate([x, np.zeros(2205, np.float32)])
    with wave.open(os.path.join(out, name + ".wav"), "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(44100); w.writeframes((x*32767).astype(np.int16).tobytes())
    print(name, src, round(len(x)/44100, 2))
