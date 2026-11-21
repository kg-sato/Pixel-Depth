"""Measured checks for our synthesised sounds (directive v13 phase 2): Claude cannot hear, so every WAV is judged by numbers.
    report(name, x, sr)  prints peak dBFS, RMS dBFS, a rough LUFS (K-weighting approximation), crest factor and the energy
    share in three bands (sub < 180 Hz, body 180 Hz - 1.5 kHz, crisp > 1.5 kHz). Returns a dict for tables.
    python audio/pd_audit.py <wav or folder> ...   audits files already on disk."""
import sys, os, wave
import numpy as np


def _kweight(x, sr):
    # a rough ITU-R BS.1770 K-weighting: a high shelf (+4 dB over ~1.5 kHz) and a high pass at ~38 Hz, one-pole each
    from scipy.signal import lfilter, butter
    b, a = butter(2, 38 / (sr / 2), "highpass")
    y = lfilter(b, a, x)
    b2, a2 = butter(1, 1500 / (sr / 2), "highpass")
    return y + lfilter(b2, a2, y) * (10 ** (4 / 20) - 1)


def report(name, x, sr=44100, quiet=False):
    x = np.asarray(x, dtype=np.float64)
    peak = float(np.abs(x).max()) or 1e-12
    rms = float(np.sqrt(np.mean(x * x))) or 1e-12
    k = _kweight(x, sr)
    lufs = -0.691 + 10 * np.log10(np.mean(k * k) + 1e-12)
    spec = np.abs(np.fft.rfft(x)) ** 2
    f = np.fft.rfftfreq(len(x), 1 / sr)
    tot = spec.sum() or 1e-12
    bands = (spec[f < 180].sum() / tot, spec[(f >= 180) & (f < 1500)].sum() / tot, spec[f >= 1500].sum() / tot)
    r = {"name": name, "sec": round(len(x) / sr, 2), "peak": round(20 * np.log10(peak), 2), "rms": round(20 * np.log10(rms), 2),
         "lufs": round(float(lufs), 2), "crest": round(20 * np.log10(peak / rms), 2), "sub": round(bands[0] * 100, 1),
         "body": round(bands[1] * 100, 1), "crisp": round(bands[2] * 100, 1)}
    if not quiet:
        print(f"{name:<18} {r['sec']:>6}s  peak {r['peak']:>6} dBFS  rms {r['rms']:>6}  ~LUFS {r['lufs']:>6}  crest {r['crest']:>5} dB  "
              f"bands {r['sub']:>4}/{r['body']:>4}/{r['crisp']:>4} %")
    return r


def read(path):
    with wave.open(path, "rb") as w:
        sr, n, ch = w.getframerate(), w.getnframes(), w.getnchannels()
        x = np.frombuffer(w.readframes(n), dtype=np.int16).astype(np.float64) / 32767
    if ch > 1: x = x.reshape(-1, ch).mean(axis=1)
    return x, sr


if __name__ == "__main__":
    for p in sys.argv[1:]:
        files = [os.path.join(p, f) for f in sorted(os.listdir(p)) if f.endswith(".wav")] if os.path.isdir(p) else [p]
        for f in files:
            x, sr = read(f)
            report(os.path.basename(f)[:-4], x, sr)
