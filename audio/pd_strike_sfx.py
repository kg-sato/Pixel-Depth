"""Synthesised sounds for the Perfect Strike minigame (our own, made with numpy; no samples).
    python audio/pd_strike_sfx.py audio/sfx/strike
tick (approach notch), ping (perfect bell), thud (OK hit), crack (rock splits), roll (tension drum loop on the last swing),
flawless (rising sparkle run), aww (soft falling groan on a near miss)."""
import os, sys, wave
import numpy as np
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pd_audit import report  # directive v13: every sound is measured (peak, RMS, rough LUFS, crest, three bands)
SR = 44100
out = sys.argv[1]; os.makedirs(out, exist_ok=True)
rng = np.random.default_rng(11)

def lp(x, hz):
    a = np.exp(-2 * np.pi * hz / SR); y = np.empty_like(x); acc = 0.0
    for i, v in enumerate(x): acc = a * acc + (1 - a) * v; y[i] = acc
    return y
def hp(x, hz): return x - lp(x, hz)
def env(n, attack, decay):
    t = np.arange(n) / SR
    return np.minimum(t / max(attack, 1e-4), 1) * np.exp(-np.maximum(t - attack, 0) / decay)
def save(name, x, peak=0.8, loop=False):
    x = np.asarray(x, dtype=np.float64)
    if loop:
        n = SR // 8; x[:n] = x[:n] * np.linspace(0, 1, n) + x[-n:] * np.linspace(1, 0, n); x = x[:-n]
    else:
        n = min(len(x) // 4, 1764); x[-n:] *= np.linspace(1, 0, n)
    x = x * peak / max(np.abs(x).max(), 1e-9)
    with wave.open(os.path.join(out, name + ".wav"), "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR); w.writeframes((x * 32767).astype(np.int16).tobytes())
    report(name, x, SR)
def bell(f, n, decay, partials=((1, 1), (2.76, 0.4), (5.4, 0.18), (8.9, 0.08))):
    t = np.arange(n) / SR
    return sum(a * np.sin(2 * np.pi * f * k * t) * np.exp(-t / (decay / (1 + k * 0.6))) for k, a in partials)

# tick: a tiny dry wood block, for each notch as the needle nears the gold
n = int(0.06 * SR); t = np.arange(n) / SR
save("tick", (np.sin(2 * np.pi * 1900 * t) * np.exp(-t / 0.008) + hp(rng.standard_normal(n), 3000) * np.exp(-t / 0.004) * 0.5), 0.6)

# ping: a bright glassy bell with a sparkle on top: the PERFECT sound, a different timbre from the OK thud
n = int(0.7 * SR); t = np.arange(n) / SR
ping = bell(1568, n, 0.5) + 0.5 * bell(2349, n, 0.3) + hp(rng.standard_normal(n), 6000) * np.exp(-t / 0.01) * 0.6
save("ping", ping, 0.8)

# thud: a dull, muffled knock (OK hit)
n = int(0.25 * SR); t = np.arange(n) / SR
thud = np.sin(2 * np.pi * (180 * t - 120 * t * t)) * np.exp(-t / 0.05) + lp(rng.standard_normal(n), 600) * np.exp(-t / 0.03) * 2
save("thud", thud, 0.75)

# crack: stone splitting: a sharp bright snap over a low thump, a few grit ticks after it
n = int(0.45 * SR); t = np.arange(n) / SR; noise = rng.standard_normal(n)
crack = hp(noise, 2200) * env(n, 0.001, 0.025) * 1.2 + np.sin(2 * np.pi * (95 * t)) * np.exp(-t / 0.07) * 0.9
for k in rng.integers(int(0.03 * SR), int(0.3 * SR), 9):
    m = 300; crack[k:k + m] += hp(rng.standard_normal(m), 3500) * np.exp(-np.arange(m) / 40) * rng.uniform(0.2, 0.5)
save("crack", crack, 0.85)

# roll: a soft snare roll that swells (loop), under the last swing of a flawless run
n = int(1.25 * SR); roll = np.zeros(n)
step = int(SR / 22)
for i, k in enumerate(range(0, n - 1500, step)):
    m = 1500; roll[k:k + m] += hp(rng.standard_normal(m), 1800) * np.exp(-np.arange(m) / 220) * (0.6 + 0.4 * (i % 2))
roll += lp(rng.standard_normal(n), 140) * 0.6
save("roll", roll, 0.55, loop=True)

# flawless: a quick rising run of bells (C E G C E) and a shimmer tail
notes = [1047, 1319, 1568, 2093, 2637]
n = int(1.3 * SR); fl = np.zeros(n)
for i, f in enumerate(notes):
    k = int(i * 0.07 * SR); m = n - k; fl[k:] += bell(f, m, 0.6) * (0.7 + i * 0.08)
fl += hp(rng.standard_normal(n), 7000) * env(n, 0.2, 0.5) * 0.25
save("flawless", fl, 0.8)

# aww: two soft falling notes (a sad slide), for a near miss on the flawless run
n = int(0.8 * SR); t = np.arange(n) / SR
f = np.where(t < 0.3, 520 - 60 * t / 0.3, 440 - 120 * (t - 0.3) / 0.5)
ph = 2 * np.pi * np.cumsum(f) / SR
aww = (np.sin(ph) + 0.3 * np.sin(2 * ph)) * np.minimum(t / 0.03, 1) * np.exp(-t / 0.5) * (1 + 0.08 * np.sin(2 * np.pi * 6 * t))
save("aww", lp(aww, 2500), 0.6)
