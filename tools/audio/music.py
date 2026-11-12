"""The music (audio-prompts.md MUS-01, 02, 10, 11, 12, 13): a small score in
D, sparse, with long rests.

The cat's motif is D - G - A - Eb: up a fourth, up a step, then down a
tritone to a note outside the key, left unresolved. It appears once, quietly,
in the base theme's piano; closes the title; and returns enormous in MUS-13.
"""
import numpy as np
from scipy import signal
from synth import SR_LONG as SR, band, decay, env, note, place, reverb, rng, stereo_reverb
from ambience import loop_noise, slow

MOTIF = ("D4", "G4", "A4", "Eb4")


# --- instruments ------------------------------------------------------------------

def pluck(name, d, vel=1.0, seed="g"):
    """A nylon string: a soft burst of noise ringing in a tuned delay."""
    f = note(name)
    n = int(SR / f)
    real = SR / (n + 0.5)
    x = np.zeros(int(d * SR * f / real) + n + 8)
    x[:n] = band(rng(seed + name).standard_normal(n + 64), hi=min(2400.0 + f * 3, 9000), sr=SR)[64:]
    a = np.zeros(n + 2)
    a[0], a[n], a[n + 1] = 1.0, -0.4975, -0.4975
    y = signal.lfilter([1.0], a, x)
    y = np.interp(np.arange(int(d * SR)) * (f / real), np.arange(len(y)), y)  # retune exactly
    return env(band(y, 70, 4200, SR), 0.004, 0.12, SR) * vel


def piano(name, d, vel=1.0):
    """A felt piano: soft hammer, few upper partials, a long gentle decay."""
    f = note(name)
    t = np.arange(int(d * SR)) / SR
    y = np.zeros(len(t))
    for k in range(1, 9):
        fk = f * k * np.sqrt(1 + 0.0005 * k * k)
        if fk > 5000:
            break
        y += np.sin(2 * np.pi * fk * t + k) * k ** -1.7 * np.exp(-0.35 * (k - 1)) * 0.5 ** (t / (1.1 / k ** 0.6 * (220 / f) ** 0.35))
    thump = decay(band(rng("felt" + name).standard_normal(int(0.03 * SR)), hi=350, sr=SR), 0.006, SR) * 0.25
    y[:len(thump)] += thump[:len(y)]
    return env(y, 0.012, min(0.5, d * 0.3), SR) * vel


def music_box(name, d, vel=1.0):
    f = note(name)
    t = np.arange(int(d * SR)) / SR
    y = sum(np.sin(2 * np.pi * f * m * t) * g * 0.5 ** (t / h) for m, g, h in ((1, 1.0, 0.45), (2.76, 0.35, 0.14), (5.4, 0.12, 0.05)))
    return env(y, 0.002, 0.2, SR) * vel


def cello(name, d, vel=1.0):
    """Muted and low: a short bowed note, a little vibrato."""
    f = note(name)
    t = np.arange(int(d * SR)) / SR
    ph = 2 * np.pi * f * t + 0.012 * np.sin(2 * np.pi * 5.2 * t) * 2 * np.pi * f / 5.2 * 0.15
    y = sum(np.sin(ph * k) / k for k in range(1, 14))
    return env(band(y, 60, 1100, SR), 0.035, min(0.14, d * 0.4), SR) * vel


def frame_drum(vel=1.0, seed="d"):
    d = 0.7
    t = np.linspace(0, 1, int(d * SR), endpoint=False)
    y = np.sin(2 * np.pi * np.cumsum(58 + 45 * (1 - t) ** 6) / SR) * 0.5 ** (t * d / 0.1)
    y += decay(band(rng(seed).standard_normal(len(t)), 200, 1400, SR), 0.02, SR) * 0.35
    return env(y, 0.002, 0.2, SR) * vel


def harmonic(name, d, vel=1.0):
    f = note(name)
    t = np.arange(int(d * SR)) / SR
    y = np.sin(2 * np.pi * f * t) + 0.25 * np.sin(2 * np.pi * f * 2.003 * t)
    return env(y * (0.85 + 0.15 * np.sin(2 * np.pi * 4.3 * t)), min(0.9, d * 0.4), min(1.2, d * 0.45), SR) * vel


def huge(name, d, vel=1.0):
    """The motif's echo: bowed metal, or something far larger, a long way off."""
    f = note(name)
    t = np.arange(int(d * SR)) / SR
    glide = 1 - 0.025 * (t / d) ** 2
    y = np.zeros(len(t))
    for m, g in ((1, 1.0), (1.48, 0.5), (2.09, 0.35), (2.92, 0.2), (3.71, 0.12)):
        y += np.sin(2 * np.pi * np.cumsum(f * m * glide) / SR + m) * g * (0.75 + 0.25 * np.sin(2 * np.pi * (0.13 + m * 0.05) * t))
    y += band(rng("huge" + name).standard_normal(len(t)), f * 0.8, f * 3, SR) * 0.25
    return y * np.sin(np.pi * np.clip(t / d, 0, 1)) ** 1.5 * vel


def room(seconds, gain=0.004):
    return np.stack([loop_noise(seconds, "room" + s, 40, 900, "brown") * gain for s in "LR"])


# --- the base theme ---------------------------------------------------------------

CHORDS = {"D": ("D3", "A3", "D4", "F#4"), "Bm": ("B2", "F#3", "B3", "D4"), "G": ("G2", "G3", "B3", "D4"), "A": ("A2", "E3", "A3", "C#4"),
          "Em": ("E2", "G3", "B3", "E4"), "Gm": ("G2", "G3", "Bb3", "D4"), "D/F#": ("F#2", "A3", "D4", "F#4")}
PHRASES = {
    "P1": (("D", "D", "G", "A"), [(0, "F#4", 2), (2, "A4", 1), (3, "B4", 1), (4, "A4", 3), (8, "D5", 2), (10, "B4", 2), (12, "A4", 4)]),
    "P2": (("Bm", "A", "G", "D"), [(0, "B4", 2), (2, "A4", 1), (3, "F#4", 1), (4, "E4", 3), (8, "G4", 2), (10, "F#4", 1), (11, "E4", 1), (12, "D4", 4)]),
    # the borrowed minor chord (G minor in D major): the touch of longing
    "P3": (("G", "Gm", "D", "D"), [(0, "B4", 2), (2, "D5", 2), (4, "Bb4", 3), (8, "A4", 2), (10, "F#4", 2), (12, "D4", 4)]),
    "P4": (("G", "D/F#", "Em", "A"), [(0, "D5", 3), (3, "B4", 1), (4, "A4", 2), (6, "F#4", 2), (8, "G4", 2), (10, "B4", 1), (11, "A4", 1), (12, "E4", 4)]),
}
FORM = ["P1", "P2", "rest3", "P1", "P3", "rest3", "P4", "P2", "rest3", "P4", "P3", "rest4"]  # 45 bars: 2:44 at 66 BPM


def base_theme(bpm=66, sparse=False):
    """MUS-01 (guitar, piano answering) or, sparse, MUS-02 (piano alone,
    fragments, as if remembered). Returns {stem: buffer}."""
    beat = 60.0 / bpm
    bars = sum(4 if p in PHRASES else int(p[-1]) for p in FORM)
    seconds = bars * 4 * beat
    guitar, keys = np.zeros((2, int(seconds * SR))), np.zeros((2, int(seconds * SR)))
    r = rng("theme%s" % sparse)
    bar, rests_seen = 0, 0
    for n, part in enumerate(FORM):
        if part.startswith("rest"):
            rests_seen += 1
            t0 = bar * 4 * beat
            if not sparse:
                if rests_seen in (2, 3):  # the piano answers, a few phrases later
                    for at, name, _d in PHRASES["P1"][1][:4]:
                        place(keys, piano(name.replace("4", "5"), 3.0, 0.22), t0 + (at + 1) * beat, pan=0.6)
                if rests_seen == 4:  # the cat's motif, once, quiet, ending on the note that is not in the key
                    for i, name in enumerate(MOTIF):
                        place(keys, piano(name.replace("4", "5"), 4.5 if i == 3 else 2.0, 0.2), t0 + (2 + i * 1.5) * beat, pan=0.62)
            bar += int(part[-1])
            continue
        chords, melody = PHRASES[part]
        if sparse:
            if n % 3 == 1:  # MUS-02 leaves whole phrases out
                bar += 4
                continue
            for at, name, d in melody[: 4 if n % 2 else 7]:
                place(keys, piano(name, max(3.0, d * beat * 2.5), 0.4), (bar * 4 + at) * beat + r.uniform(0, 0.03), pan=0.5)
            for i in (0, 2):
                place(keys, piano(CHORDS[chords[i]][0].replace("2", "3"), 5.0, 0.25), (bar + i) * 4 * beat, pan=0.45)
            bar += 4
            continue
        for i, chord in enumerate(chords):
            bass, t1, t2, t3 = CHORDS[chord]
            t0 = (bar + i) * 4 * beat
            pattern = [bass, t1, t2, t3, t1, t2, t3, t2] if i < 3 else [bass, t1, t2, None, None, None, None, None]  # each phrase thins out
            for k, name in enumerate(pattern):
                if name:
                    place(guitar, pluck(name, 2.4, 0.5 if k == 0 else 0.3, "g%d" % k), t0 + k * beat / 2 + r.uniform(0, 0.012), pan=0.4)
        for at, name, d in melody:
            place(guitar, pluck(name, min(3.5, max(2.5, d * beat * 1.8)), 0.62, "m"), (bar * 4 + at) * beat + r.uniform(0, 0.015), pan=0.46)
        if part == "P3":  # the piano shadows the long notes of the phrase with the minor chord
            for at, name, d in melody[2:]:
                place(keys, piano(name, d * beat * 2.2, 0.16), (bar * 4 + at) * beat + 0.02, pan=0.6)
        bar += 4
    guitar = stereo_reverb(guitar, 1.3, 0.16, seed="gtr")
    keys = stereo_reverb(keys, 2.2, 0.3, seed="pno")
    stems = {"piano": keys, "room": room(seconds)}
    if not sparse:
        stems["guitar"] = guitar
    return stems


# --- the other cues ---------------------------------------------------------------

def title(bpm=60):
    """MUS-10: felt piano over soft wind; the last phrase is the motif."""
    beat = 60.0 / bpm
    seconds = 24 * 4 * beat
    keys = np.zeros((2, int(seconds * SR)))
    tune = PHRASES["P4"][1] + [(at + 16, n, d) for at, n, d in PHRASES["P2"][1]] + [(at + 40, n, d) for at, n, d in PHRASES["P1"][1][:5]]
    for at, name, d in tune:
        place(keys, piano(name, max(3.5, d * beat * 2.5), 0.45), at * beat, pan=0.5)
    for bar, name in ((0, "G2"), (2, "E3"), (4, "B2"), (6, "G2"), (10, "D3"), (12, "G2")):
        place(keys, piano(name, 6.0, 0.3), bar * 4 * beat, pan=0.42)
    for i, name in enumerate(MOTIF):  # bars 16-18, then two bars of wind before the loop
        place(keys, piano(name, 9.0 if i == 3 else 3.0, 0.4), (64 + i * 2.5) * beat, pan=0.5)
    keys = stereo_reverb(keys, 2.6, 0.32, seed="title")
    wind = np.stack([loop_noise(seconds, "titlewind" + s, 160, 1100) * slow(seconds, "titlegust", 6, 0.25, 1.0) * 0.012 for s in "LR"])
    return {"piano": keys, "wind": wind}


STINGS = [("D5", "F#5", "A5", "E5"), ("A4", "D5", "E5", "C#5"), ("F#5", "D5", "E5", "B4"), ("D5", "A5", "G5"), ("B4", "D5", "F#5", "E5"), ("A5", "F#5", "G5")]


def sting(k):
    """MUS-11: three or four music-box notes ending unresolved. Not a prize:
    something someone left behind."""
    notes = STINGS[k]
    buf = np.zeros((2, int(2.4 * SR)))
    for i, name in enumerate(notes):
        place(buf, music_box(name, 2.0 if i == len(notes) - 1 else 0.9, 0.5 + 0.1 * (i == len(notes) - 1)), 0.05 + i * (0.3 + 0.03 * (k % 3)), pan=0.4 + 0.07 * i)
    left = reverb(buf[0], 2.6, 0.35, SR, "stingL")
    right = reverb(buf[1], 2.6, 0.35, SR, "stingR")
    out = np.stack([left, right])
    fade = int(0.8 * SR)
    out[:, -fade:] *= np.linspace(1, 0, fade) ** 2
    return {"box": out}


def combat(bpm=104, bars=32):
    """MUS-12: tension without bombast. Stems so the game can layer it."""
    beat = 60.0 / bpm
    seconds = bars * 4 * beat
    cel, perc, harm = (np.zeros((2, int(seconds * SR))) for _ in range(3))
    a = ["D2", "D2", "F2", "D2", "A2", "D2", "G2", "F2"]
    b = ["D2", "D2", "F2", "D2", "Bb2", "A2", "G2", "E2"]
    r = rng("combat")
    for bar in range(bars):
        t0 = bar * 4 * beat
        line = a if bar % 4 < 2 else b
        if bar % 8 == 7:
            line = ["D2", None, None, None, "D2", None, "A1", None]  # a breath
        for k, name in enumerate(line):
            if name:
                place(cel, cello(name, beat * 0.42, 0.55 if k % 4 == 0 else 0.4), t0 + k * beat / 2, pan=0.45)
        if bar >= 4:
            hits = {0: (0.0, 2.5), 1: (0.0, 1.5, 3.0), 2: (0.0, 2.5, 3.5), 3: (0.0,)}[bar % 4]
            for h in hits:
                place(perc, frame_drum(0.6 if h == 0 else 0.4, "d%d" % int(r.integers(4))), t0 + h * beat, pan=0.55)
        if bar % 8 == 4 and bar >= 8:  # two notes a semitone apart, high and thin
            pair = ("A5", "Bb5") if bar % 16 == 12 else ("E6", "F6")
            for name, pan in zip(pair, (0.3, 0.7)):
                place(harm, harmonic(name, 8 * beat, 0.12), t0, pan=pan)
    return {"cello": stereo_reverb(cel, 0.9, 0.12, seed="cel"), "percussion": stereo_reverb(perc, 1.4, 0.2, seed="perc"),
            "harmonics": stereo_reverb(harm, 2.5, 0.35, seed="harm")}


def motif_wrong(seconds=52):
    """MUS-13: the little tune, very slow; then the same four notes from
    something huge and far away. Unsettling, not frightening."""
    keys, far = np.zeros((2, int(seconds * SR))), np.zeros((2, int(seconds * SR)))
    for i, name in enumerate(MOTIF):
        place(keys, piano(name, 8.0, 0.4), 2.0 + i * 3.0, pan=0.5)
        place(far, huge(name.replace("4", "1"), 12.0 if i == 3 else 8.0, 0.5), 15.0 + i * 6.0, pan=0.35 + 0.1 * i)
    place(far, harmonic("Eb7", 10.0, 0.01), 36.0, pan=0.5)  # the shimmer far above it
    keys = stereo_reverb(keys, 3.0, 0.35, seed="wrongp")
    far = stereo_reverb(far, 4.5, 0.5, seed="wrongf", bright=1800)
    fade = int(5 * SR)
    for buf in (keys, far):
        buf[:, -fade:] *= np.linspace(1, 0, fade) ** 2
    return {"piano": keys, "far": far}


CUES = {
    # name: (builder, LUFS, loop, stems to export besides the mix)
    "mus_01_base_theme": (base_theme, -18, True, ("guitar", "piano")),
    "mus_02_base_theme_sparse": (lambda: base_theme(62, True), -22, True, ()),
    "mus_10_title": (title, -20, True, ()),
    "mus_12_combat": (combat, -18, True, ("cello", "percussion", "harmonics")),
    "mus_13_motif_wrong": (motif_wrong, -20, False, ()),
}
for _k in range(len(STINGS)):
    CUES["mus_11_discovery_%d" % (_k + 1)] = ((lambda k=_k: sting(k)), -20, False, ())
