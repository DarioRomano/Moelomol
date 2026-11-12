"""Synthesis core for Moelomol's sound (docs/design/audio-direction.md).

Everything is generated from code and seeded, so every file can be rebuilt
bit for bit. Needs numpy and scipy (build-time only; the game ships the
rendered files) and ffmpeg with libvorbis for the Ogg files.
"""
import os
import subprocess
import wave
import zlib

import numpy as np
from scipy import signal

SR = 44100  # effects (mono WAV)
SR_LONG = 48000  # music and ambience (stereo Ogg), as the delivery spec


def rng(name):
    return np.random.default_rng(zlib.crc32(name.encode()))


def secs(d, sr=SR):
    return np.arange(int(d * sr)) / sr


# --- sources ----------------------------------------------------------------------

def sine(f, d, sr=SR, phase=0.0):
    return np.sin(2 * np.pi * f * secs(d, sr) + phase)


def sweep(f0, f1, d, sr=SR, curve=1.0, shape="sine"):
    """A tone gliding from f0 to f1 (curve > 1 falls fast then slow)."""
    t = np.linspace(0, 1, int(d * sr), endpoint=False)
    f = f0 + (f1 - f0) * t ** (1.0 / curve)
    ph = 2 * np.pi * np.cumsum(f) / sr
    if shape == "saw":
        return 2 * ((ph / (2 * np.pi)) % 1.0) - 1
    if shape == "square":
        return np.sign(np.sin(ph))
    return np.sin(ph)


def noise(d, seed, sr=SR, colour="white"):
    x = rng(seed).standard_normal(int(d * sr))
    if colour == "pink":
        x = signal.lfilter([0.049922, -0.095993, 0.050612, -0.004408], [1, -2.494956, 2.017265, -0.522189], x) * 4
    elif colour == "brown":
        x = signal.lfilter([0.02], [1, -0.995], x) * 3
    return x


# --- shaping ----------------------------------------------------------------------

def band(x, lo=None, hi=None, sr=SR, order=2):
    if lo and hi:
        sos = signal.butter(order, [lo, hi], "bandpass", fs=sr, output="sos")
    elif lo:
        sos = signal.butter(order, lo, "highpass", fs=sr, output="sos")
    else:
        sos = signal.butter(order, hi, "lowpass", fs=sr, output="sos")
    return signal.sosfilt(sos, x)


def decay(n_or_x, half, sr=SR):
    """An exponential fall with the given half-life in seconds."""
    n = n_or_x if isinstance(n_or_x, int) else len(n_or_x)
    e = 0.5 ** (np.arange(n) / sr / half)
    return e if isinstance(n_or_x, int) else n_or_x * e


def env(x, attack=0.005, release=0.02, sr=SR):
    a, r = max(1, int(attack * sr)), max(1, int(release * sr))
    e = np.ones(len(x))
    e[:a] = np.linspace(0, 1, a) ** 0.7
    e[-r:] *= np.linspace(1, 0, r) ** 1.5
    return x * e


def swell(x, peak=0.5):
    """Rises to a peak part-way through, then falls: wind gusts, whooshes."""
    t = np.linspace(0, 1, len(x))
    return x * np.where(t < peak, (t / peak) ** 1.5, ((1 - t) / (1 - peak)) ** 1.5)


def mix(*parts):
    """Sums (signal, start_seconds, gain) parts into one buffer."""
    sr = SR
    end = max(int(s * sr) + len(x) for x, s, _g in parts)
    out = np.zeros(end)
    for x, s, g in parts:
        i = int(s * sr)
        out[i:i + len(x)] += x * g
    return out


def place(buf, x, at, gain=1.0, sr=SR_LONG, pan=None):
    """Adds x into a long buffer at `at` seconds, wrapping round the end so
    loops close seamlessly (tails fold back onto the start)."""
    n = buf.shape[-1]
    i = int(at * sr) % n
    idx = (i + np.arange(len(x))) % n
    if buf.ndim == 1:
        np.add.at(buf, idx, x * gain)
    else:
        p = 0.5 if pan is None else pan
        np.add.at(buf[0], idx, x * gain * np.cos(p * np.pi / 2) * 1.2)
        np.add.at(buf[1], idx, x * gain * np.sin(p * np.pi / 2) * 1.2)


def reverb(x, seconds=1.6, wet=0.25, sr=SR, seed="room", wrap=False, bright=4000):
    """Convolution with a decaying noise tail: 'distant and reverberant' out
    in the world, short and close at home. `wrap` folds the tail round."""
    n = int(seconds * sr)
    ir = band(rng(seed).standard_normal(n), hi=bright, sr=sr) * 0.5 ** (np.arange(n) / sr / (seconds / 6))
    ir /= np.sqrt(np.sum(ir ** 2))
    tail = signal.fftconvolve(x, ir)
    if wrap:
        out = x * (1 - wet) + tail[:len(x)] * wet
        out[:n - 1] += tail[len(x):] * wet
        return out
    out = np.concatenate([x, np.zeros(n - 1)]) * (1 - wet) + tail * wet
    return out


def stereo_reverb(buf, seconds, wet, sr=SR_LONG, seed="hall", bright=3500):
    return np.stack([reverb(buf[0], seconds, wet, sr, seed + "L", True, bright), reverb(buf[1], seconds, wet, sr, seed + "R", True, bright)])


# --- loudness (ITU-R BS.1770 integrated, gated) -------------------------------------

def lufs(x, sr):
    x = np.atleast_2d(x)
    f0, g, q = 1681.974450955533, 3.999843853973347, 0.7071752369554196
    k = np.tan(np.pi * f0 / sr)
    vh, vb = 10 ** (g / 20), (10 ** (g / 20)) ** 0.4996667741545416
    a0 = 1 + k / q + k * k
    b = [(vh + vb * k / q + k * k) / a0, 2 * (k * k - vh) / a0, (vh - vb * k / q + k * k) / a0]
    a = [1, 2 * (k * k - 1) / a0, (1 - k / q + k * k) / a0]
    y = signal.lfilter(b, a, x)
    f0, q = 38.13547087602444, 0.5003270373238773
    k = np.tan(np.pi * f0 / sr)
    a2 = [1, 2 * (k * k - 1) / (1 + k / q + k * k), (1 - k / q + k * k) / (1 + k / q + k * k)]
    y = signal.lfilter([1, -2, 1], a2, y)
    block, hop = int(0.4 * sr), int(0.1 * sr)
    powers = np.array([np.sum(np.mean(y[:, i:i + block] ** 2, axis=1)) for i in range(0, y.shape[1] - block + 1, hop)])
    if len(powers) == 0:
        powers = np.array([np.sum(np.mean(y ** 2, axis=1))])
    loud = -0.691 + 10 * np.log10(powers + 1e-12)
    keep = powers[loud > -70]
    if len(keep) == 0:
        return -70.0
    rel = -0.691 + 10 * np.log10(np.mean(keep)) - 10
    keep = powers[(loud > -70) & (loud > rel)]
    return float(-0.691 + 10 * np.log10(np.mean(keep)))


def true_peak_db(x, sr):
    up = signal.resample_poly(np.atleast_2d(x), 4, 1, axis=1)
    return float(20 * np.log10(np.max(np.abs(up)) + 1e-12))


def to_loudness(x, target, sr, ceiling=-1.0):
    """Gain to the target LUFS; if peaks would pass the ceiling, soft-limit."""
    x = x * 10 ** ((target - lufs(x, sr)) / 20)
    over = true_peak_db(x, sr) - ceiling
    if over > 0:
        lim = 10 ** (ceiling / 20)
        x = np.tanh(x / lim * 0.9) * lim / 0.9 * 0.98 if over < 6 else x * 10 ** (-over / 20)
        if true_peak_db(x, sr) > ceiling:
            x = x * 10 ** ((ceiling - true_peak_db(x, sr) - 0.05) / 20)
    return x


# --- files ------------------------------------------------------------------------

def write_wav(path, x, sr=SR, peak=0.85):
    """Mono 16-bit WAV for short effects, peak-normalised."""
    os.makedirs(os.path.dirname(path), exist_ok=True)
    x = x / (np.max(np.abs(x)) + 1e-9) * peak
    r = rng(path[-24:])
    data = np.clip(np.round(x * 32767 + (r.random(len(x)) - 0.5)), -32768, 32767).astype("<i2")  # dithered
    with wave.open(path, "wb") as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(sr)
        f.writeframes(data.tobytes())


def write_ogg(path, x, sr=SR_LONG, quality=4):
    """Stereo Ogg Vorbis through ffmpeg, with no encoder date or tags so the
    file is the same on every build."""
    os.makedirs(os.path.dirname(path), exist_ok=True)
    pcm = np.clip(x.T, -1, 1).astype("<f4").tobytes()
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-f", "f32le", "-ar", str(sr), "-ac", str(x.shape[0]), "-i", "pipe:0",
                    "-c:a", "libvorbis", "-q:a", str(quality), "-map_metadata", "-1", "-fflags", "+bitexact", "-flags:a", "+bitexact",
                    "-serial_offset", "1", path], input=pcm, check=True)


def note(name):
    """'D4', 'F#3', 'Eb5' to Hz (A4 = 440)."""
    steps = {"C": -9, "D": -7, "E": -5, "F": -4, "G": -2, "A": 0, "B": 2}
    n = steps[name[0]] + (1 if "#" in name else 0) - (1 if "b" in name[1:] else 0)
    return 440.0 * 2 ** ((n + 12 * (int(name[-1]) - 4)) / 12)
