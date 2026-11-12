"""Sound effects: every action, creature and interface sound, as short mono
WAVs (audio-direction.md). Home sounds are close and dry; sounds out in the
world carry a little distance. No voices: creature calls are pitched noise
and tone, never speech-like.
"""
import numpy as np
from synth import SR, band, decay, env, mix, noise, reverb, sine, swell, sweep, secs


def thump(f0, f1, d, half=0.06):
    return decay(sweep(f0, f1, d, curve=2.5), half)


def nb(d, seed, lo=None, hi=None, half=None, attack=0.002):
    x = band(noise(d, seed), lo, hi) if (lo or hi) else noise(d, seed)
    return env(decay(x, half) if half else x, attack, min(0.03, d / 3))


def whoosh(d, seed, lo, hi, peak=0.45):
    return swell(band(noise(d, seed), lo, hi), peak)


def ring(freqs, d, half=0.15, detune=0.0):
    x = np.zeros(int(d * SR))
    for i, f in enumerate(freqs):
        x += decay(sine(f * (1 + detune * i), d), half / (1 + i * 0.35)) / (1 + i * 0.6)
    return env(x, 0.001, 0.02)


def chirp(f0, f1, d, shape="sine", curve=1.0):
    return env(sweep(f0, f1, d, curve=curve, shape=shape), 0.004, d * 0.4)


def trem(x, rate, depth=1.0):
    return x * (1 - depth / 2 + depth / 2 * np.sin(2 * np.pi * rate * secs(len(x) / SR)))


def far(x, wet=0.3, seconds=1.2):
    return reverb(x, seconds, wet, seed="far")


def step(surface, k):
    s = "%s%d" % (surface, k)
    if surface == "grass":
        return mix((nb(0.09, s, 900, 5000, 0.02), 0, 0.6), (thump(110, 70, 0.07, 0.03), 0, 0.35), (nb(0.05, s + "b", 3000, 9000, 0.012), 0.02, 0.25))
    if surface == "path":
        return mix((nb(0.08, s, 400, 2600, 0.018), 0, 0.7), (thump(130, 80, 0.06, 0.025), 0, 0.5), (nb(0.03, s + "g", 2500, 7000, 0.008), 0.035, 0.3))
    if surface == "wood":
        return mix((thump(190 + k * 12, 120, 0.09, 0.03), 0, 0.9), (ring([410 + k * 30, 733], 0.08, 0.02), 0, 0.25), (nb(0.02, s, 1500, 5000, 0.006), 0, 0.3))
    return mix((nb(0.05, s, 1200, 6000, 0.012), 0, 0.6), (thump(240, 150, 0.05, 0.018), 0, 0.5), (ring([1900 + k * 140], 0.04, 0.012), 0.004, 0.12))  # cobbles


def swing(k, heavy=False):
    d = 0.34 if heavy else 0.22
    lo, hi = (250, 1800) if heavy else (500, 3600)
    return mix((whoosh(d, "swing%d%s" % (k, heavy), lo + k * 60, hi + k * 300), 0, 1.0), (whoosh(d * 0.7, "swingb%d" % k, hi, hi * 2.2), d * 0.2, 0.25))


def build_table():
    t = {}
    for surface in ("grass", "path", "wood", "cobble"):
        for k in range(4):
            t["step_%s_%d" % (surface, k + 1)] = lambda surface=surface, k=k: step(surface, k)
    # --- the player --------------------------------------------------------------
    for k in range(3):
        t["swing_light_%d" % (k + 1)] = lambda k=k: swing(k)
    t["swing_heavy"] = lambda: swing(0, True)
    t["swing_spin"] = lambda: mix((whoosh(0.5, "spin", 300, 2400, 0.3), 0, 1.0), (whoosh(0.4, "spin2", 300, 2400, 0.6), 0.15, 0.7))
    t["hit_flesh"] = lambda: mix((thump(180, 60, 0.12, 0.035), 0, 1.0), (nb(0.06, "hitf", 300, 2500, 0.015), 0, 0.6))
    t["hit_heavy"] = lambda: mix((thump(140, 40, 0.22, 0.06), 0, 1.0), (nb(0.1, "hith", 200, 1800, 0.03), 0, 0.7), (nb(0.03, "hitc", 2000, 7000, 0.008), 0, 0.3))
    t["hit_stone"] = lambda: mix((ring([820, 1370, 2210, 3140], 0.25, 0.05), 0, 0.7), (nb(0.04, "hits", 1500, 8000, 0.01), 0, 0.7), (thump(200, 90, 0.08, 0.025), 0, 0.5))
    t["shell_break"] = lambda: mix((nb(0.3, "shell", 600, 6000, 0.07), 0, 1.0), (ring([640, 1010, 1730], 0.3, 0.06), 0, 0.5),
                                   (nb(0.05, "sh2", 2000, 9000, 0.012), 0.09, 0.5), (nb(0.05, "sh3", 2500, 9000, 0.012), 0.19, 0.35), (thump(120, 50, 0.2, 0.06), 0, 0.7))
    t["guard_block"] = lambda: mix((ring([520, 1310, 2480], 0.22, 0.04), 0, 0.8), (thump(160, 70, 0.1, 0.03), 0, 0.7), (nb(0.03, "gb", 1800, 7000, 0.008), 0, 0.4))
    t["guard_perfect"] = lambda: far(mix((ring([1174.7, 1760, 2349.3, 3520], 0.7, 0.16, 0.002), 0, 0.9), (nb(0.02, "gp", 3000, 10000, 0.006), 0, 0.5), (thump(220, 110, 0.08, 0.02), 0, 0.4)), 0.25)
    t["roll"] = lambda: mix((whoosh(0.3, "roll", 200, 1500, 0.35), 0, 0.8), (step("grass", 1), 0.04, 0.5), (step("grass", 2), 0.24, 0.6))
    t["hurt"] = lambda: mix((thump(260, 90, 0.16, 0.04), 0, 1.0), (nb(0.1, "hurt", 400, 3000, 0.03), 0, 0.5), (chirp(330, 220, 0.12), 0.01, 0.2))
    t["fall"] = lambda: far(mix((thump(150, 45, 0.5, 0.12), 0.05, 1.0), (nb(0.25, "fall", 200, 1600, 0.06), 0.05, 0.6), (whoosh(0.3, "fallw", 300, 1200, 0.8), 0, 0.3), (chirp(294, 147, 0.9, curve=2), 0.1, 0.15)), 0.3, 1.8)
    t["no_stamina"] = lambda: mix((thump(110, 90, 0.09, 0.03), 0, 1.0), (thump(100, 80, 0.09, 0.03), 0.1, 0.7))
    t["weapon_swap"] = lambda: mix((nb(0.07, "swap", 800, 5000, 0.02), 0, 0.6), (ring([900, 1650], 0.1, 0.03), 0.05, 0.4), (thump(180, 120, 0.05, 0.02), 0.07, 0.5))
    t["lock_on"] = lambda: mix((ring([1320], 0.07, 0.02), 0, 0.6), (ring([1760], 0.09, 0.03), 0.05, 0.6))
    # hammer
    t["hammer_charge"] = lambda: env(trem(band(noise(1.2, "hcharge"), 120, 700) * np.linspace(0.2, 1.0, int(1.2 * SR)), 9, 0.4), 0.05, 0.05) + 0.5 * env(sweep(70, 140, 1.2), 0.05, 0.05)
    t["hammer_sweet_spot"] = lambda: ring([1568, 2349.3, 3136], 0.25, 0.06)
    t["hammer_slam"] = lambda: far(mix((thump(120, 32, 0.6, 0.11), 0, 1.0), (nb(0.35, "slam", 150, 2200, 0.07), 0, 0.8), (nb(0.5, "slamr", 600, 5000, 0.12), 0.05, 0.35), (ring([310, 517], 0.3, 0.07), 0, 0.3)), 0.2)
    t["hammer_slam_perfect"] = lambda: far(mix((thump(140, 28, 0.9, 0.16), 0, 1.0), (nb(0.5, "slamp", 120, 2600, 0.1), 0, 0.9), (nb(0.8, "slampr", 500, 6000, 0.18), 0.06, 0.45),
                                               (ring([262, 440, 698], 0.6, 0.14), 0, 0.35), (ring([1568, 2349.3], 0.4, 0.1), 0.0, 0.2)), 0.3, 1.8)
    t["hammer_weak"] = lambda: mix((thump(150, 80, 0.12, 0.035), 0, 0.9), (nb(0.08, "weak", 300, 1800, 0.02), 0, 0.4))
    t["hammer_jab"] = lambda: mix((whoosh(0.12, "jab", 600, 3000), 0, 0.6), (thump(170, 90, 0.08, 0.025), 0.07, 0.8))
    t["stomp"] = lambda: mix((thump(100, 40, 0.3, 0.07), 0, 1.0), (nb(0.2, "stomp", 150, 1500, 0.05), 0, 0.6))
    # bow
    t["bow_draw"] = lambda: env(band(noise(0.7, "draw"), 900, 2600) * np.linspace(0.1, 0.5, int(0.7 * SR)) * (0.6 + 0.4 * np.sign(sine(38, 0.7))), 0.02, 0.05) + 0.2 * env(sweep(180, 300, 0.7), 0.05, 0.05)
    t["bow_draw_stage"] = lambda: ring([880, 1320], 0.06, 0.018)
    t["bow_release"] = lambda: mix((ring([196, 392, 588], 0.18, 0.03), 0, 0.9), (whoosh(0.16, "rel", 1200, 7000, 0.15), 0, 0.7))
    t["arrow_hit"] = lambda: mix((thump(300, 140, 0.06, 0.015), 0, 0.9), (nb(0.04, "ahit", 800, 5000, 0.01), 0, 0.7), (ring([240], 0.15, 0.04), 0.01, 0.3))
    t["arrow_pierce"] = lambda: mix((whoosh(0.2, "pierce", 1500, 8000, 0.3), 0, 0.8), (thump(260, 100, 0.1, 0.03), 0.08, 0.9), (nb(0.06, "pc", 500, 4000, 0.015), 0.08, 0.6))
    t["volley_up"] = lambda: mix((ring([196, 392], 0.15, 0.03), 0, 0.8), (whoosh(0.6, "vup", 900, 5000, 0.2) * np.linspace(1, 0.2, int(0.6 * SR)), 0, 0.6))
    t["volley_rain"] = lambda: far(mix(*[(mix((whoosh(0.12, "vr%d" % i, 1500, 7000, 0.7), 0, 0.5), (thump(280, 130, 0.05, 0.015), 0.1, 0.8)), i * 0.055 + (i % 3) * 0.02, 0.5 + (i % 4) * 0.12) for i in range(12)]), 0.15)
    # magic
    t["ember_bolt"] = lambda: mix((whoosh(0.25, "ember", 400, 3000, 0.2), 0, 0.8), (nb(0.25, "embc", 2500, 9000, 0.05) * (noise(0.25, "embm") > 0.6), 0, 0.5), (chirp(520, 260, 0.2), 0, 0.25))
    t["frost_shard"] = lambda: mix((ring([2093, 3136, 4186, 5274], 0.3, 0.06, 0.003), 0, 0.7), (whoosh(0.18, "frost", 3000, 10000, 0.2), 0, 0.5))
    t["rot_seed"] = lambda: mix((thump(160, 70, 0.2, 0.06), 0, 0.8), (trem(nb(0.3, "rot", 150, 900, 0.09), 22, 0.8), 0, 0.7))
    t["seed_bloom"] = lambda: mix((trem(nb(0.6, "bloom", 200, 1400, 0.2), 14, 0.7), 0, 0.8), (chirp(110, 185, 0.5, curve=0.6), 0, 0.3), (nb(0.1, "bloomp", 1200, 5000, 0.03), 0.42, 0.4))
    t["seed_leap"] = lambda: mix((whoosh(0.28, "leap", 500, 2600, 0.5), 0, 0.8), (chirp(155, 311, 0.26), 0, 0.3))
    t["siphon_tether"] = lambda: env(trem(band(noise(1.5, "tether"), 300, 1400), 7, 0.5) * 0.6 + 0.35 * sine(146.83, 1.5) * (1 + 0.3 * sine(0.9, 1.5)) + 0.2 * sine(207.65, 1.5), 0.1, 0.1)
    t["siphon_beam"] = lambda: far(mix((chirp(146.83, 587.3, 0.12, "saw"), 0, 0.5), (whoosh(0.5, "beam", 500, 6000, 0.12), 0, 1.0), (ring([587.3, 830.6, 1174.7], 0.6, 0.14), 0.08, 0.5), (thump(120, 50, 0.3, 0.08), 0.08, 0.7)), 0.3)
    t["burst_shatter"] = lambda: far(mix((ring([2093, 2794, 3520, 4699], 0.5, 0.1, 0.004), 0, 0.8), (nb(0.25, "shat", 2500, 10000, 0.05), 0, 0.8), (thump(180, 60, 0.2, 0.05), 0, 0.6)), 0.25)
    t["burst_blight"] = lambda: far(mix((trem(nb(0.8, "blight", 150, 1100, 0.22), 11, 0.8), 0, 1.0), (chirp(207.65, 103.8, 0.7, curve=2), 0, 0.35), (thump(110, 45, 0.3, 0.08), 0, 0.6)), 0.3)
    t["burst_brittle"] = lambda: mix((nb(0.2, "brit", 1500, 9000, 0.04), 0, 0.9), (ring([1480, 2217, 3322], 0.3, 0.06), 0, 0.6), (nb(0.04, "brit2", 3000, 10000, 0.01), 0.12, 0.5))
    t["blink"] = lambda: mix((whoosh(0.18, "blink", 800, 6000, 0.8), 0, 0.8), (chirp(415.3, 207.65, 0.15), 0.05, 0.3), (whoosh(0.2, "blink2", 800, 6000, 0.2), 0.2, 0.6))
    t["smoulder_tick"] = lambda: nb(0.12, "smo", 2000, 8000, 0.03) * (noise(0.12, "smom") > 0.3)
    t["freeze"] = lambda: mix((ring([1661, 2489, 3729, 4978], 0.6, 0.12, 0.004), 0, 0.7), (nb(0.3, "frz", 3000, 11000, 0.08) * (noise(0.3, "frzm") > 0.7), 0, 0.7), (chirp(880, 1760, 0.25), 0, 0.15))
    t["thaw"] = lambda: mix((nb(0.25, "thaw", 2000, 9000, 0.06), 0, 0.8), (ring([1245, 1865], 0.2, 0.05), 0, 0.4))
    # --- the farm (close and dry: home) ----------------------------------------------
    t["farm_till"] = lambda: mix((nb(0.22, "till", 200, 2200, 0.06), 0, 1.0), (thump(120, 60, 0.12, 0.04), 0, 0.6), (nb(0.1, "till2", 1500, 5000, 0.03), 0.1, 0.3), (ring([587.3, 880], 0.3, 0.08), 0, 0.12))
    t["farm_water"] = lambda: mix(*[(ring([900 + (i * 373) % 1400], 0.06, 0.015), i * 0.045 + (i % 3) * 0.012, 0.4) for i in range(9)], (nb(0.45, "water", 1500, 7000, 0.15), 0, 0.5))
    t["farm_rain_cast"] = lambda: mix((whoosh(1.4, "raincast", 1500, 8000, 0.5), 0, 0.8), (ring([293.7, 440, 587.3], 1.2, 0.35), 0, 0.3), *[(ring([1100 + (i * 517) % 1600], 0.05, 0.012), 0.3 + i * 0.07, 0.3) for i in range(12)])
    t["farm_plant"] = lambda: mix((nb(0.08, "plant", 500, 3000, 0.02), 0, 0.7), (thump(200, 130, 0.06, 0.02), 0, 0.6), (ring([880], 0.12, 0.04), 0.04, 0.15))
    t["farm_harvest"] = lambda: mix((nb(0.12, "harv", 1200, 6000, 0.03), 0, 0.8), (chirp(587.3, 880, 0.1), 0.03, 0.3), (ring([1174.7, 1760], 0.3, 0.09), 0.1, 0.35))
    t["farm_clear"] = lambda: mix((nb(0.5, "clear", 600, 5000, 0.12), 0, 0.9), (whoosh(0.5, "clearw", 300, 2000, 0.3), 0, 0.6), (ring([293.7, 440, 587.3, 880], 0.8, 0.22), 0.1, 0.3))
    t["farm_open_fields"] = lambda: mix((env(band(noise(2.8, "open", colour="brown"), 30, 300), 0.4, 1.2), 0, 1.0), (nb(1.5, "open2", 400, 3000, 0.4), 0.3, 0.3), (ring([146.83, 220, 293.7], 2.5, 0.7), 0.4, 0.3))
    t["mana_empty"] = lambda: mix((chirp(392, 293.7, 0.14), 0, 0.6), (chirp(293.7, 220, 0.18), 0.12, 0.5))
    t["sleep"] = lambda: mix((nb(0.5, "sleep", 300, 1800, 0.15), 0, 0.6), (thump(120, 80, 0.15, 0.05), 0.1, 0.5), (ring([293.7, 440], 1.2, 0.35), 0.3, 0.3), (ring([369.99], 1.2, 0.4), 0.7, 0.25))
    t["door_open"] = lambda: mix((ring([240], 0.05, 0.012), 0, 0.5), (env(sweep(330, 420, 0.35, shape="saw") * (0.5 + 0.5 * sine(31, 0.35)), 0.03, 0.1) * 0.3, 0.03, 1.0), (thump(160, 100, 0.08, 0.03), 0.4, 0.6))
    t["door_close"] = lambda: mix((thump(170, 70, 0.14, 0.04), 0, 1.0), (ring([230, 610], 0.1, 0.025), 0, 0.4), (nb(0.03, "dc", 800, 4000, 0.008), 0, 0.4))
    t["gate"] = lambda: mix((env(sweep(520, 610, 0.5, shape="saw") * (0.5 + 0.5 * sine(23, 0.5)), 0.05, 0.15) * 0.25, 0, 1.0), (ring([700, 1130], 0.12, 0.03), 0.5, 0.5), (thump(190, 120, 0.06, 0.02), 0.5, 0.5))
    t["chest_open"] = lambda: mix((thump(200, 140, 0.06, 0.02), 0, 0.7), (env(sweep(260, 340, 0.25, shape="saw") * (0.5 + 0.5 * sine(27, 0.25)), 0.02, 0.08) * 0.3, 0.04, 1.0), (ring([980], 0.1, 0.03), 0.02, 0.2))
    t["stove_lit"] = lambda: mix((whoosh(0.4, "stove", 200, 1600, 0.25), 0, 0.8), (nb(0.4, "stovec", 2000, 8000, 0.1) * (noise(0.4, "stovem") > 0.75), 0.1, 0.6))
    # the cat
    t["cat_meow_1"] = lambda: band(np.concatenate([env(sweep(540, 780, 0.14, curve=0.6, shape="saw"), 0.02, 0.01), env(sweep(780, 600, 0.3, curve=1.6, shape="saw"), 0.01, 0.15)]), 500, 3200)
    t["cat_meow_2"] = lambda: band(np.concatenate([env(sweep(660, 900, 0.09, shape="saw"), 0.015, 0.01), env(sweep(900, 820, 0.12, shape="saw"), 0.005, 0.08)]), 600, 3600)
    t["cat_purr"] = lambda: env(band(noise(2.0, "purr", colour="brown"), 40, 420) * (0.25 + 0.75 * (sine(25, 2.0) > 0.2)) * (0.7 + 0.3 * sine(0.55, 2.0)), 0.25, 0.3)
    t["cat_eat"] = lambda: mix(*[(nb(0.05, "eat%d" % i, 900, 5000, 0.012), i * 0.14 + (i % 2) * 0.03, 0.6 + (i % 3) * 0.15) for i in range(5)])
    # --- creatures -------------------------------------------------------------------
    t["mouse_squeak"] = lambda: mix((chirp(3200, 4300, 0.05), 0, 0.7), (chirp(4000, 3300, 0.06), 0.07, 0.6))
    t["mouse_scatter"] = lambda: mix(*[(nb(0.025, "sc%d" % i, 1500, 7000, 0.007), i * 0.04, 0.5) for i in range(7)], (chirp(3600, 4600, 0.04), 0.02, 0.3))
    t["rook_caw"] = lambda: far(band(np.concatenate([env(sweep(700, 560, 0.22, shape="saw") * (0.5 + 0.5 * sine(75, 0.22)), 0.01, 0.05), np.zeros(int(0.08 * SR)),
                                                    env(sweep(680, 520, 0.26, shape="saw") * (0.5 + 0.5 * sine(70, 0.26)), 0.01, 0.08)]), 500, 3200), 0.3)
    t["jackdaw_chack"] = lambda: far(band(np.concatenate([env(sweep(1500, 1100, 0.06, shape="saw"), 0.004, 0.02), np.zeros(int(0.05 * SR)), env(sweep(1600, 1150, 0.07, shape="saw"), 0.004, 0.03)]), 800, 5000), 0.3)
    t["wing_flap"] = lambda: mix(*[(whoosh(0.09, "flap%d" % i, 300, 2200, 0.3), i * 0.13, 0.8 - i * 0.12) for i in range(3)])
    t["bird_dive"] = lambda: whoosh(0.4, "dive", 700, 5000, 0.75)
    t["hedgehog_curl"] = lambda: mix((nb(0.12, "curl", 1500, 7000, 0.03), 0, 0.8), (ring([2600, 3900, 5100], 0.08, 0.02), 0, 0.3), (thump(160, 100, 0.06, 0.02), 0.03, 0.4))
    t["hedgehog_roll"] = lambda: env(trem(band(noise(0.5, "hroll"), 300, 2600), 26, 0.9), 0.03, 0.1)
    t["toad_croak"] = lambda: far(env(band(sweep(150, 110, 0.32, shape="saw") * (0.3 + 0.7 * (sine(34, 0.32) > 0)), 90, 1500), 0.02, 0.08), 0.2)
    t["toad_lob"] = lambda: mix((chirp(180, 420, 0.12), 0, 0.5), (nb(0.1, "lob", 300, 2000, 0.03), 0, 0.6), (whoosh(0.3, "lobw", 500, 2500, 0.3), 0.08, 0.4))
    t["glob_splat"] = lambda: mix((nb(0.16, "splat", 300, 3200, 0.04), 0, 1.0), (thump(190, 70, 0.1, 0.03), 0, 0.6), (ring([620 + i * 210 for i in range(3)], 0.05, 0.012), 0.05, 0.25))
    t["stook_rise"] = lambda: mix((nb(0.5, "stook", 1500, 8000, 0.14), 0, 0.9), (nb(0.3, "stook2", 600, 3000, 0.08), 0.1, 0.6), (chirp(98, 147, 0.4), 0.05, 0.3))
    t["stook_lash"] = lambda: mix((whoosh(0.2, "lash", 1200, 7000, 0.6), 0, 0.9), (nb(0.05, "lashc", 2500, 9000, 0.012), 0.14, 0.8))
    t["moth_flutter"] = lambda: env(trem(band(noise(0.6, "moth"), 2500, 9000), 31, 1.0), 0.05, 0.15) * 0.8
    t["grist_grunt"] = lambda: far(env(band(sweep(120, 80, 0.45, shape="saw") * (0.4 + 0.6 * (sine(41, 0.45) > -0.2)), 60, 900), 0.03, 0.15), 0.25)
    t["grist_charge"] = lambda: far(mix((env(band(sweep(90, 150, 0.6, shape="saw") * (0.4 + 0.6 * (sine(47, 0.6) > -0.2)), 60, 1100), 0.05, 0.1), 0, 0.8),
                                        *[(thump(110, 50, 0.12, 0.035), 0.05 + i * 0.13, 0.6) for i in range(4)]), 0.2)
    t["grist_wall"] = lambda: far(mix((thump(130, 35, 0.5, 0.1), 0, 1.0), (nb(0.3, "gw", 300, 3000, 0.07), 0, 0.8), (ring([330, 540, 910], 0.4, 0.08), 0, 0.3)), 0.3)
    t["grist_wallow"] = lambda: mix((nb(0.7, "wallow", 150, 1400, 0.2), 0, 0.9), (thump(100, 50, 0.3, 0.09), 0.1, 0.6), *[(ring([300 + i * 90], 0.06, 0.015), 0.2 + i * 0.11, 0.25) for i in range(4)])
    t["grist_stunned"] = lambda: far(env(band(sweep(170, 70, 0.9, curve=2, shape="saw") * (0.4 + 0.6 * (sine(29, 0.9) > 0)), 60, 800), 0.05, 0.3), 0.25)
    t["boss_defeated"] = lambda: far(mix((thump(100, 30, 1.2, 0.25), 0, 1.0), (nb(0.8, "bossd", 150, 1600, 0.2), 0, 0.6), (ring([146.83, 220, 293.7], 2.5, 0.7), 0.5, 0.35), (ring([369.99, 440], 2.5, 0.8), 1.1, 0.25)), 0.35, 2.4)
    t["rat_squeal"] = lambda: mix((chirp(2100, 2900, 0.08, "saw"), 0, 0.5), (chirp(2800, 1900, 0.14, "saw"), 0.08, 0.5), (nb(0.2, "rat", 1500, 6000, 0.05), 0, 0.3))
    t["rat_split"] = lambda: mix((nb(0.14, "split", 700, 5000, 0.035), 0, 1.0), (chirp(2400, 3400, 0.06, "saw"), 0.04, 0.35), (chirp(2900, 3900, 0.06, "saw"), 0.1, 0.35), (thump(210, 110, 0.08, 0.025), 0, 0.6))
    t["runt_drop"] = lambda: mix((whoosh(0.18, "drop", 600, 3000, 0.8), 0, 0.6), (thump(220, 120, 0.06, 0.02), 0.17, 0.8), (chirp(3000, 3800, 0.05, "saw"), 0.2, 0.3))
    t["pike_surface"] = lambda: far(mix((nb(0.35, "psurf", 500, 5000, 0.09), 0, 1.0), (thump(180, 80, 0.15, 0.05), 0, 0.5), *[(ring([700 + i * 260], 0.05, 0.012), 0.1 + i * 0.06, 0.25) for i in range(4)]), 0.25)
    t["pike_spit"] = lambda: mix((whoosh(0.22, "pspit", 1500, 8000, 0.2), 0, 0.9), (chirp(300, 700, 0.1), 0, 0.3))
    t["pike_submerge"] = lambda: far(mix((nb(0.3, "psub", 300, 3000, 0.08), 0, 0.8), (chirp(400, 150, 0.25, curve=2), 0, 0.35), (ring([520, 390], 0.08, 0.02), 0.15, 0.3)), 0.25)
    t["jet_splash"] = lambda: mix((nb(0.3, "jet", 800, 8000, 0.07), 0, 1.0), (thump(200, 90, 0.1, 0.03), 0, 0.5))
    t["lichen_rise"] = lambda: far(mix((env(band(noise(0.8, "grind"), 150, 1400) * (0.4 + 0.6 * (sine(17, 0.8) > -0.3)), 0.05, 0.2), 0, 1.0), (thump(90, 55, 0.4, 0.12), 0.1, 0.6), (nb(0.2, "soil", 600, 4000, 0.06), 0.45, 0.5)), 0.3)
    t["lichen_slam"] = lambda: far(mix((thump(120, 40, 0.4, 0.09), 0, 1.0), (ring([410, 690, 1120], 0.3, 0.06), 0, 0.5), (nb(0.2, "lslam", 300, 3500, 0.05), 0, 0.7)), 0.3)
    t["bull_snort"] = lambda: far(mix((nb(0.3, "snort", 300, 2600, 0.07), 0, 1.0), (env(band(sweep(100, 75, 0.3, shape="saw"), 50, 600), 0.02, 0.1), 0, 0.5)), 0.25)
    t["bull_bellow"] = lambda: far(env(band(np.concatenate([sweep(98, 150, 0.5, shape="saw"), sweep(150, 85, 0.8, curve=1.6, shape="saw")]) * (0.55 + 0.45 * sine(31, 1.3)), 60, 1300), 0.08, 0.4), 0.35, 2.0)
    t["herd_stampede"] = lambda: far(mix(*[(thump(100 + (i * 17) % 40, 45, 0.12, 0.035), i * 0.075 + (i % 3) * 0.02, 0.5 + (i % 4) * 0.12) for i in range(28)], (env(band(noise(2.3, "herd", colour="brown"), 30, 250), 0.5, 0.6), 0, 0.8)), 0.25)
    t["creature_defeated"] = lambda: far(mix((nb(0.4, "cdef", 800, 6000, 0.1), 0, 0.7), (chirp(440, 220, 0.4, curve=2), 0, 0.2), (ring([587.3], 0.5, 0.15), 0.1, 0.12)), 0.3)
    # --- the world -------------------------------------------------------------------
    t["note_pickup"] = lambda: mix((nb(0.12, "paper", 2000, 9000, 0.03), 0, 0.8), (nb(0.08, "paper2", 3000, 10000, 0.02), 0.09, 0.5))
    t["note_open"] = lambda: mix((nb(0.2, "unfold", 1500, 8000, 0.06) * (0.5 + 0.5 * (noise(0.2, "unf") > 0)), 0, 0.9), (nb(0.06, "unfold2", 2500, 9000, 0.015), 0.16, 0.6))
    t["note_close"] = lambda: mix((nb(0.1, "fold", 1800, 8000, 0.025), 0, 0.8), (thump(260, 180, 0.04, 0.015), 0.07, 0.3))
    t["satchel_open"] = lambda: mix((nb(0.12, "satchel", 500, 3500, 0.035), 0, 0.8), (ring([1500, 2300], 0.05, 0.015), 0.08, 0.35), (thump(170, 110, 0.06, 0.02), 0.02, 0.4))
    t["item_taken"] = lambda: mix((nb(0.05, "take", 1200, 6000, 0.012), 0, 0.6), (ring([880, 1320], 0.25, 0.07), 0.02, 0.45), (ring([1174.7], 0.3, 0.09), 0.1, 0.35))
    t["key_taken"] = lambda: mix((ring([2637, 3951, 5274], 0.25, 0.05, 0.004), 0, 0.6), (ring([2349, 3520], 0.2, 0.05), 0.08, 0.5), (nb(0.03, "key", 3000, 9000, 0.008), 0, 0.4))
    t["locked"] = lambda: mix((ring([540, 870, 1420], 0.09, 0.02), 0, 0.8), (thump(170, 110, 0.06, 0.02), 0, 0.6), (ring([510, 830], 0.08, 0.02), 0.12, 0.6), (thump(160, 105, 0.06, 0.02), 0.12, 0.5))
    t["sluice_turn"] = lambda: far(mix(*[(mix((ring([430 + (i % 3) * 25, 760], 0.08, 0.02), 0, 0.7), (nb(0.04, "ratchet%d" % i, 1000, 5000, 0.01), 0, 0.5)), i * 0.2, 1.0) for i in range(8)],
                                       (env(sweep(210, 260, 1.7, shape="saw") * (0.5 + 0.5 * sine(13, 1.7)), 0.1, 0.2) * 0.15, 0, 1.0)), 0.3)
    t["water_drain"] = lambda: far(env(band(noise(4.0, "drain"), 200, 3500) * np.linspace(1.0, 0.25, 4 * SR) * (0.75 + 0.25 * sine(0.7, 4.0)), 0.3, 1.5) + 0.4 * env(band(noise(4.0, "drain2", colour="brown"), 40, 300), 0.5, 2.0), 0.3, 2.0)
    t["winch_turn"] = lambda: far(mix(*[(mix((ring([310 + (i % 2) * 30, 520, 1180], 0.1, 0.025), 0, 0.7), (thump(150, 100, 0.05, 0.02), 0, 0.5)), i * 0.26, 1.0) for i in range(7)],
                                      (env(band(noise(1.9, "chain"), 1500, 6000) * (0.3 + 0.7 * (sine(21, 1.9) > 0.3)), 0.1, 0.2) * 0.35, 0, 1.0)), 0.3)
    t["bridge_lowering"] = lambda: far(mix((env(band(noise(5.0, "bridge", colour="brown"), 35, 320) * (0.7 + 0.3 * sine(1.3, 5.0)), 0.6, 0.3), 0, 1.0),
                                           (env(sweep(140, 95, 5.0, shape="saw") * (0.5 + 0.5 * sine(9, 5.0)), 0.5, 0.3) * 0.12, 0, 1.0),
                                           *[(ring([260 + (i * 37) % 90, 610], 0.1, 0.03), 0.4 + i * 0.52, 0.25) for i in range(9)]), 0.35, 2.2)
    t["bridge_down"] = lambda: far(mix((thump(95, 30, 0.9, 0.18), 0, 1.0), (nb(0.5, "bdown", 150, 2500, 0.12), 0, 0.8), (ring([196, 327, 540], 0.8, 0.18), 0, 0.35), (nb(0.6, "bdown2", 1500, 6000, 0.15), 0.15, 0.2)), 0.4, 2.6)
    t["mill_wheel"] = lambda: env(band(noise(2.0, "wheel"), 250, 3000) * (0.6 + 0.4 * sine(1.0, 2.0)) * 0.7 + 0.25 * sweep(120, 135, 2.0, shape="saw") * (0.5 + 0.5 * sine(6, 2.0)) * 0.3, 0.3, 0.3)
    t["splash_small"] = lambda: mix((nb(0.18, "spl", 700, 7000, 0.045), 0, 1.0), (ring([640, 910], 0.06, 0.015), 0.06, 0.3))
    t["save"] = lambda: mix((ring([587.3, 880], 0.5, 0.14), 0, 0.5), (ring([739.99], 0.6, 0.18), 0.16, 0.4))
    t["area_enter"] = lambda: far(mix((whoosh(1.0, "enter", 200, 1800, 0.5), 0, 0.6), (ring([293.7, 440], 1.5, 0.45), 0.2, 0.25)), 0.35, 2.0)
    # --- the interface: marks on paper, quiet ----------------------------------------
    t["ui_move"] = lambda: mix((nb(0.025, "uim", 2000, 8000, 0.006), 0, 0.6), (ring([1174.7], 0.05, 0.015), 0, 0.3))
    t["ui_select"] = lambda: mix((nb(0.03, "uis", 1500, 7000, 0.008), 0, 0.6), (ring([880, 1320], 0.14, 0.04), 0.005, 0.45))
    t["ui_back"] = lambda: mix((nb(0.03, "uib", 1200, 6000, 0.008), 0, 0.6), (ring([880, 660], 0.1, 0.03), 0.005, 0.35))
    t["ui_pause"] = lambda: mix((nb(0.1, "uip", 1500, 8000, 0.03), 0, 0.7), (ring([587.3], 0.2, 0.06), 0.03, 0.3))
    t["ui_unpause"] = lambda: mix((nb(0.08, "uiu", 1800, 8000, 0.02), 0, 0.7), (ring([880], 0.15, 0.05), 0.02, 0.25))
    t["ui_denied"] = lambda: mix((thump(160, 130, 0.07, 0.025), 0, 0.8), (thump(150, 120, 0.07, 0.025), 0.09, 0.6))
    return t


LOOPS = ("cat_purr", "siphon_tether", "mill_wheel", "hedgehog_roll", "moth_flutter")


def build(out_dir, only=None):
    from synth import write_wav
    table = build_table()
    made = {}
    for name, fn in sorted(table.items()):
        if only and name not in only:
            continue
        x = band(np.asarray(fn(), dtype=float), lo=25)  # no DC offset
        loop = name in LOOPS
        if loop:  # drop the faded ends, then crossfade the tail into the head
            cut, n = int(0.3 * SR) if len(x) > SR else int(0.1 * SR), int(0.08 * SR)
            x = x[cut:len(x) - cut]
            ramp = np.linspace(0, 1, n)
            x[:n] = x[:n] * ramp + x[-n:] * (1 - ramp)
            x = x[:-n]
        else:
            x = env(x, 0.001, 0.008)  # no clicks at either end
        quiet = name.startswith(("ui_", "step_", "note_", "cat_", "farm_", "satchel"))
        write_wav("%s/%s.wav" % (out_dir, name), x, peak=0.5 if quiet else 0.8)
        made[name] = {"seconds": round(len(x) / SR, 3), "loop": loop}
    return made
