"""Synthesised sounds for the forge biographies (our own, made with numpy; no samples).
    python audio/pd_forge_sfx.py audio/sfx/forge
Wood scene: thunder, rain (loop), fire (loop), whittle, bonk, dawn."""
import os, sys, wave
import numpy as np
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pd_audit import report  # directive v13: every sound is measured (peak, RMS, rough LUFS, crest, three bands)
SR = 44100
out = sys.argv[1]; os.makedirs(out, exist_ok=True)
rng = np.random.default_rng(7)

def lp(x, hz):  # one-pole low-pass
    a = np.exp(-2 * np.pi * hz / SR); y = np.empty_like(x); acc = 0.0
    for i, v in enumerate(x): acc = a * acc + (1 - a) * v; y[i] = acc
    return y
def hp(x, hz): return x - lp(x, hz)
def env(n, attack, decay):  # seconds
    t = np.arange(n) / SR
    return np.minimum(t / max(attack, 1e-4), 1) * np.exp(-np.maximum(t - attack, 0) / decay)
def save(name, x, peak=0.8, loop=False):
    x = np.asarray(x, dtype=np.float64)
    if loop:  # crossfade the tail into the head so the loop has no click
        n = SR // 4; x[:n] = x[:n] * np.linspace(0, 1, n) + x[-n:] * np.linspace(1, 0, n); x = x[:-n]
    else:
        n = min(len(x) // 4, 1764); x[-n:] *= np.linspace(1, 0, n)
    x = x * peak / max(np.abs(x).max(), 1e-9)
    with wave.open(os.path.join(out, name + ".wav"), "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR); w.writeframes((x * 32767).astype(np.int16).tobytes())
    report(name, x, SR)

# thunder: a sharp crack, then a rolling low rumble
n = int(2.8 * SR); noise = rng.standard_normal(n)
crack = hp(noise, 1200) * env(n, 0.002, 0.06) * 0.9
roll = lp(noise, 120) * env(n, 0.05, 0.9) * (1 + 0.5 * np.sin(2 * np.pi * 3.1 * np.arange(n) / SR)) * 6
save("thunder", crack + roll + lp(noise, 400) * env(n, 0.01, 0.25) * 1.5, 0.85)

# rain: soft bright hiss with slow swells (loop)
n = int(3.25 * SR); noise = rng.standard_normal(n)
rain = hp(lp(noise, 7000), 1500) * (0.8 + 0.2 * np.sin(2 * np.pi * 0.6 * np.arange(n) / SR))
drops = np.zeros(n)
for k in rng.integers(0, n - 400, 140): drops[k:k + 300] += np.sin(2 * np.pi * rng.uniform(1800, 4200) * np.arange(300) / SR) * np.exp(-np.arange(300) / 40) * rng.uniform(0.2, 0.7)
save("rain", rain + drops * 0.6, 0.5, loop=True)

# fire: a low breath with dry crackles (loop)
n = int(3.25 * SR); noise = rng.standard_normal(n)
fire = lp(noise, 300) * 3 * (0.7 + 0.3 * np.sin(2 * np.pi * 1.3 * np.arange(n) / SR))
for k in rng.integers(0, n - 900, 46):
    m = int(rng.integers(120, 700)); fire[k:k + m] += hp(rng.standard_normal(m), 2500) * np.exp(-np.arange(m) / (m / 5)) * rng.uniform(0.6, 1.8)
save("fire", fire, 0.6, loop=True)

# whittle: a short dry scrape that rises in pitch
n = int(0.22 * SR); t = np.arange(n) / SR; noise = rng.standard_normal(n)
sweep = np.sin(2 * np.pi * (700 * t + 1800 * t * t)) * 0.25
save("whittle", (hp(lp(noise, 5200), 1400) + sweep * noise) * env(n, 0.012, 0.07), 0.75)

# bonk: a round wooden knock with a little spring after it
n = int(0.42 * SR); t = np.arange(n) / SR
knock = np.sin(2 * np.pi * (520 * t - 380 * t * t)) * np.exp(-t / 0.05) + 0.5 * np.sin(2 * np.pi * 1180 * t) * np.exp(-t / 0.02)
spring = np.sin(2 * np.pi * (300 + 160 * np.sin(2 * np.pi * 9 * t)) * t) * np.exp(-t / 0.14) * 0.35 * (t > 0.05)
save("bonk", knock + spring, 0.8)

# dawn: four soft bell notes rising (C, E, G, C)
n = int(2.2 * SR); x = np.zeros(n)
for i, f in enumerate([523.25, 659.25, 783.99, 1046.5]):
    k = int(i * 0.16 * SR); m = n - k; t = np.arange(m) / SR
    x[k:] += (np.sin(2 * np.pi * f * t) + 0.4 * np.sin(2 * np.pi * 2.01 * f * t) * np.exp(-t / 0.25) + 0.2 * np.sin(2 * np.pi * 3.02 * f * t) * np.exp(-t / 0.1)) * np.exp(-t / 0.7) * np.minimum(t / 0.004, 1)
save("dawn", x, 0.7)

# ---- Stone scene: river (loop), stonetap ----
# river: a shallow stream over pebbles: a soft mid hiss that swells, with many small watery plinks (loop)
n = int(3.25 * SR); noise = rng.standard_normal(n); t = np.arange(n) / SR
river = hp(lp(noise, 2600), 350) * (0.75 + 0.25 * np.sin(2 * np.pi * 0.31 * t + 1)) + lp(noise, 180) * 1.6
for k in rng.integers(0, n - 2000, 90):
    m = int(rng.integers(500, 1800)); u = np.arange(m) / SR; f0 = rng.uniform(500, 1500)
    river[k:k + m] += np.sin(2 * np.pi * (f0 * u + f0 * 1.6 * u * u)) * np.exp(-u / (m / SR / 4)) * rng.uniform(0.25, 0.7)
save("river", river, 0.5, loop=True)

# stonetap: two hard pebbles struck together: a very short bright click with a glassy ring
n = int(0.3 * SR); t = np.arange(n) / SR; noise = rng.standard_normal(n)
click = hp(noise, 3000) * np.exp(-t / 0.004) * 1.2
ring = (np.sin(2 * np.pi * 2350 * t) + 0.6 * np.sin(2 * np.pi * 3730 * t) + 0.35 * np.sin(2 * np.pi * 5210 * t)) * np.exp(-t / 0.035)
save("stonetap", click + ring * 0.8 + np.sin(2 * np.pi * 640 * t) * np.exp(-t / 0.02) * 0.5, 0.8)
