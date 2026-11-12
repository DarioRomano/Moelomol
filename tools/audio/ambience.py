"""Ambience loops (audio-prompts.md AMB-01 to AMB-03, and one pair per area).

Silence is material (audio-direction.md): these beds carry the world. Each
is a seamless stereo loop built from layers whose events fall at seeded
random times, so no single sound is recognisable when the loop repeats.
Further from the farm there are fewer living sounds and stranger ones.
"""
import numpy as np
from synth import SR_LONG as SR, band, decay, env, place, reverb, rng, stereo_reverb


def loop_noise(seconds, seed, lo=None, hi=None, colour="white"):
    """Filtered noise whose end crossfades into its start."""
    pad = SR * 2
    n = int(seconds * SR)
    x = rng(seed).standard_normal(n + pad)
    if colour == "brown":
        from scipy import signal
        x = signal.lfilter([0.02], [1, -0.995], x) * 3
    if lo or hi:
        x = band(x, lo, hi, SR, order=4)  # steep: wind, not hiss
    ramp = np.sin(np.linspace(0, np.pi / 2, pad))
    x[:pad] = x[:pad] * ramp + x[n:] * np.cos(np.linspace(0, np.pi / 2, pad))
    return x[:n]


def slow(seconds, seed, every=4.0, low=0.3, high=1.0):
    """A smooth random curve that returns to where it began."""
    n = int(seconds * SR)
    k = max(3, int(seconds / every))
    pts = rng(seed).uniform(low, high, k)
    xs = np.arange(n) / n * k
    i = np.floor(xs).astype(int)
    f = xs - i
    f = f * f * (3 - 2 * f)
    return pts[i % k] * (1 - f) + pts[(i + 1) % k] * f


def stereo(seconds):
    return np.zeros((2, int(seconds * SR)))


def wind(buf, seconds, seed, lo, hi, gain, every=5.0, low=0.25):
    for ch, s in enumerate(("L", "R")):
        shared = loop_noise(seconds, seed, lo, hi)
        own = loop_noise(seconds, seed + s, lo, hi)
        buf[ch] += (shared * 0.6 + own * 0.6) * slow(seconds, seed + "gust", every, low, 1.0) * gain


def tone(f0, f1, d, shape="sine"):
    t = np.linspace(0, 1, int(d * SR), endpoint=False)
    ph = 2 * np.pi * np.cumsum(f0 + (f1 - f0) * t) / SR
    return np.sin(ph) if shape == "sine" else 2 * ((ph / (2 * np.pi)) % 1.0) - 1


def bird_call(r, kind):
    """A songbird phrase: a few short gliding notes, different every time."""
    parts = []
    base = r.uniform(2600, 4200) if kind == "song" else r.uniform(1500, 2100)
    for _ in range(int(r.integers(3, 7)) if kind == "song" else 2):
        f0 = base * r.uniform(0.85, 1.25)
        d = r.uniform(0.05, 0.14) if kind == "song" else r.uniform(0.18, 0.3)
        note = env(tone(f0, f0 * r.uniform(0.8, 1.3), d), 0.008, d * 0.5, SR)
        parts += [note, np.zeros(int(r.uniform(0.03, 0.12) * SR))]
    return np.concatenate(parts)


def scatter(buf, seconds, seed, every, make, gain, wet=0.25, pan_range=(0.1, 0.9)):
    """Places events at random times about `every` seconds apart."""
    r = rng(seed)
    at = r.uniform(0, every)
    while at < seconds - 0.5:
        x = make(r)
        if wet:
            x = reverb(x, 1.4, wet, SR, seed="amb")
        place(buf, x, at, gain * r.uniform(0.6, 1.0), SR, pan=r.uniform(*pan_range))
        at += every * r.uniform(0.6, 1.5)


def insects(buf, seconds, seed, gain, lo=4200, hi=7500, rate=43):
    t = np.arange(int(seconds * SR)) / SR
    for ch, s in enumerate(("L", "R")):
        buf[ch] += loop_noise(seconds, seed + s, lo, hi) * (0.55 + 0.45 * np.sin(2 * np.pi * rate * t + ch)) * slow(seconds, seed + s + "m", 7, 0.4, 1.0) * gain


def crickets(buf, seconds, seed, count, gain):
    r = rng(seed)
    for _ in range(count):
        f, period, pan = r.uniform(4000, 5200), r.uniform(0.55, 0.9), r.uniform(0.05, 0.95)
        chirp = np.concatenate([np.concatenate([env(tone(f, f, 0.014), 0.003, 0.004, SR), np.zeros(int(0.012 * SR))]) for _ in range(3)])
        n = int(round(seconds / period))  # a whole number of chirps, so the loop closes
        rest = r.integers(0, n, 2)
        for i in range(n):
            if (i - rest[0]) % n < n // 5:  # each cricket falls silent for a while
                continue
            place(buf, chirp, i * seconds / n, gain * r.uniform(0.7, 1.0), SR, pan=pan)


def blips(buf, seconds, seed, per_second, lo, hi, gain):
    """Water over stones: many tiny pitched drops."""
    r = rng(seed)
    for _ in range(int(seconds * per_second)):
        f = r.uniform(lo, hi)
        d = r.uniform(0.012, 0.04)
        place(buf, decay(tone(f, f * r.uniform(1.05, 1.5), d), d / 4, SR), r.uniform(0, seconds), gain * r.uniform(0.3, 1.0), SR, pan=r.uniform(0.3, 0.7))


def creak(r):
    d = r.uniform(0.4, 0.9)
    f = r.uniform(280, 520)
    x = tone(f, f * r.uniform(1.05, 1.25), d, "saw") * (0.5 + 0.5 * np.sin(2 * np.pi * r.uniform(17, 31) * np.arange(int(d * SR)) / SR))
    return env(band(x, 250, 2400, SR), 0.08, d * 0.4, SR)


def knock(r):
    d = 0.25
    x = decay(tone(r.uniform(150, 210), 70, d), 0.03, SR) + 0.4 * decay(band(r.standard_normal(int(d * SR)), 600, 3000, SR), 0.012, SR)
    return np.concatenate([x, np.zeros(int(r.uniform(0.25, 0.5) * SR)), x * 0.6])


def lap(r):
    d = r.uniform(1.2, 2.2)
    x = band(r.standard_normal(int(d * SR)), 300, 2600, SR)
    t = np.linspace(0, 1, len(x))
    return x * np.sin(np.pi * t) ** 2


def fire(buf, seconds, seed, gain):
    r = rng(seed)
    n = int(seconds * SR)
    for ch, s in enumerate(("L", "R")):
        buf[ch] += loop_noise(seconds, seed + s, 40, 260, "brown") * slow(seconds, seed + s + "f", 0.7, 0.6, 1.0) * gain * 1.6
    for _ in range(int(seconds * 14)):  # the crackle: many small ticks, a few gentle pops
        d = r.uniform(0.004, 0.02)
        tick = decay(band(r.standard_normal(int(d * SR) + 64), 1200, 7000, SR), d / 3, SR)
        place(buf, tick, r.uniform(0, seconds), gain * min(1.0, r.exponential(0.25)), SR, pan=r.uniform(0.3, 0.7))
    del n


def farm_day(seconds=120):
    b = stereo(seconds)
    wind(b, seconds, "farmwind", 180, 1400, 0.5)
    wind(b, seconds, "farmgrass", 1800, 5000, 0.06, every=3.0)  # the grass and leaves moving
    insects(b, seconds, "farmins", 0.025)
    scatter(b, seconds, "farmbird", 14, lambda r: bird_call(r, "song"), 0.22)
    scatter(b, seconds, "farmbird2", 31, lambda r: bird_call(r, "low"), 0.12)
    scatter(b, seconds, "farmcreak", 43, creak, 0.05)
    blips(b, seconds, "farmtrickle", 9, 900, 2600, 0.035)
    return stereo_reverb(b, 1.2, 0.12, seed="farm")


def farm_night(seconds=120):
    b = stereo(seconds)
    wind(b, seconds, "farmnwind", 140, 900, 0.4, every=7.0)
    crickets(b, seconds, "farmcrickets", 7, 0.05)
    scatter(b, seconds, "farmncreak", 55, creak, 0.04)
    blips(b, seconds, "farmntrickle", 7, 900, 2400, 0.03)
    return stereo_reverb(b, 1.4, 0.15, seed="farmn")


def hearth(seconds=60):
    b = stereo(seconds)
    fire(b, seconds, "hearth", 0.5)
    return stereo_reverb(b, 0.4, 0.08, seed="hearth", bright=5000)


def house(seconds=60):
    b = stereo(seconds)
    wind(b, seconds, "housewind", 60, 380, 0.5, every=6.0)  # the weather, heard through the walls
    scatter(b, seconds, "housetick", 23, lambda r: decay(band(r.standard_normal(2400), 500, 2500, SR), 0.006, SR), 0.05, wet=0.1)
    return stereo_reverb(b, 0.5, 0.1, seed="house")


def near_pet(seconds=64):
    """AMB-03: a very low drone breathing over eight seconds, a slowed purr
    in it, a faint shimmer far above. Meant to be felt more than heard."""
    b = stereo(seconds)
    t = np.arange(int(seconds * SR)) / SR
    breath = 0.55 + 0.45 * np.sin(2 * np.pi * t / 8.0 - np.pi / 2)
    purr = 0.6 + 0.4 * np.clip(np.sin(2 * np.pi * 3.0 * t) * 3, -1, 1)
    for ch, (f, fs) in enumerate(((48.0, 6272.0), (48.25, 6281.0))):
        b[ch] += (np.sin(2 * np.pi * f * t) * 0.8 + np.sin(2 * np.pi * f * 2 * t) * 0.12) * breath * purr
        b[ch] += loop_noise(seconds, "pet%d" % ch, 30, 120, "brown") * breath * 0.6
        b[ch] += np.sin(2 * np.pi * fs * t) * 0.004 * (0.5 + 0.5 * np.sin(2 * np.pi * t / 16.0))
    return b


def millbrook_day(seconds=120):
    b = stereo(seconds)
    wind(b, seconds, "millwind", 150, 1100, 0.5, every=6.0)
    wind(b, seconds, "millreeds", 2200, 5500, 0.04, every=3.5)
    scatter(b, seconds, "millbird", 27, lambda r: bird_call(r, "song"), 0.14, wet=0.35)  # fewer birds than home
    scatter(b, seconds, "milllap", 5, lap, 0.09, wet=0.3)  # the floodwater at the meadow's edge
    scatter(b, seconds, "millcreak", 37, creak, 0.05, wet=0.4)  # the mill's timbers
    insects(b, seconds, "millins", 0.015)
    return stereo_reverb(b, 1.8, 0.2, seed="mill")


def millbrook_night(seconds=120):
    b = stereo(seconds)
    wind(b, seconds, "millnwind", 120, 800, 0.45, every=8.0)
    crickets(b, seconds, "millcrickets", 3, 0.04)
    scatter(b, seconds, "millnlap", 4, lap, 0.1, wet=0.3)
    scatter(b, seconds, "millncreak", 41, creak, 0.05, wet=0.4)
    scatter(b, seconds, "milltoad", 19, lambda r: env(band(tone(150, 115, 0.3, "saw") * (np.sin(2 * np.pi * 34 * np.arange(int(0.3 * SR)) / SR) > 0), 90, 1400, SR), 0.02, 0.1, SR), 0.07, wet=0.4)
    return stereo_reverb(b, 2.0, 0.22, seed="milln")


def hollow(buf, seconds, seed, gain):
    """Wind through empty streets: narrow, pitched, never quite a note."""
    for i, f in enumerate((233.0, 311.0, 466.0)):
        for ch, s in enumerate(("L", "R")):
            buf[ch] += loop_noise(seconds, "%s%d%s" % (seed, i, s), f * 0.97, f * 1.03) * slow(seconds, "%s%d" % (seed, i), 9.0, 0.0, 1.0) ** 2 * gain * 6


def kettlebridge_day(seconds=120):
    b = stereo(seconds)
    for ch, s in enumerate(("L", "R")):  # the river, always
        b[ch] += loop_noise(seconds, "kettriver" + s, 180, 2200) * slow(seconds, "kettriverm" + s, 5, 0.8, 1.0) * 0.3
    wind(b, seconds, "kettwind", 140, 900, 0.4, every=7.0)
    hollow(b, seconds, "ketthollow", 0.05)
    scatter(b, seconds, "kettknock", 47, knock, 0.09, wet=0.5)  # a shutter, loose
    scatter(b, seconds, "kettrope", 29, creak, 0.05, wet=0.4)  # the barge on her ropes
    scatter(b, seconds, "kettawning", 17, lambda r: lap(r) * 0.6, 0.05, wet=0.3)  # awnings lifting
    scatter(b, seconds, "kettbird", 61, lambda r: bird_call(r, "low"), 0.07, wet=0.5)  # almost no birds
    return stereo_reverb(b, 2.4, 0.26, seed="kett")


def kettlebridge_night(seconds=120):
    b = stereo(seconds)
    for ch, s in enumerate(("L", "R")):
        b[ch] += loop_noise(seconds, "kettnriver" + s, 160, 1800) * slow(seconds, "kettnriverm" + s, 5, 0.8, 1.0) * 0.3
    wind(b, seconds, "kettnwind", 110, 700, 0.4, every=9.0)
    hollow(b, seconds, "kettnhollow", 0.08)
    scatter(b, seconds, "kettnknock", 53, knock, 0.08, wet=0.5)
    scatter(b, seconds, "kettnrope", 31, creak, 0.05, wet=0.45)
    return stereo_reverb(b, 2.8, 0.3, seed="kettn")


CUES = {
    # name: (builder, LUFS target)
    "amb_farm_day": (farm_day, -24), "amb_farm_night": (farm_night, -26), "amb_hearth": (hearth, -26),
    "amb_house": (house, -30), "amb_near_pet": (near_pet, -36),
    "amb_millbrook_day": (millbrook_day, -24), "amb_millbrook_night": (millbrook_night, -26),
    "amb_kettlebridge_day": (kettlebridge_day, -24), "amb_kettlebridge_night": (kettlebridge_night, -26),
}
