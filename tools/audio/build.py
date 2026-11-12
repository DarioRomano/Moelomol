#!/usr/bin/env python3
"""Renders every sound into assets/audio/ and writes assets/audio_manifest.json
with what was measured (length, loudness, peak, loop seam).

Usage: tools/audio/build.py [sfx] [ambience] [music]
Needs numpy, scipy and ffmpeg with libvorbis (build-time only).
"""
import json
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(__file__))
import ambience  # noqa: E402
import music  # noqa: E402
import sfx  # noqa: E402
from synth import SR, SR_LONG, lufs, to_loudness, true_peak_db, write_ogg  # noqa: E402

ROOT = os.path.normpath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = os.path.join(ROOT, "assets", "audio")


def seam(x):
    """How big the jump is where a loop closes, against the largest step
    between neighbouring samples anywhere in the file (1.0 or less: no click)."""
    step = np.max(np.abs(np.diff(x, axis=1)))
    return float(np.max(np.abs(x[:, 0] - x[:, -1])) / (step + 1e-12))


def quiet_share(x, sr, target):
    """The share of the cue more than 20 dB below its loudness (the rests)."""
    block = int(0.4 * sr)
    rms = np.array([np.sqrt(np.mean(x[:, i:i + block] ** 2)) for i in range(0, x.shape[1] - block, block)])
    return float(np.mean(20 * np.log10(rms + 1e-9) < target - 20 + 3))


def render(name, stems, target, loop, extra, folder, manifest):
    full = sum(stems.values())
    gain_ref = to_loudness(full, target, SR_LONG)
    gain = float(np.sqrt(np.mean(gain_ref ** 2)) / (np.sqrt(np.mean(full ** 2)) + 1e-12))
    write_ogg(os.path.join(OUT, folder, name + ".ogg"), gain_ref)
    manifest["assets/audio/%s/%s.ogg" % (folder, name)] = {
        "seconds": round(full.shape[1] / SR_LONG, 2), "lufs": round(lufs(gain_ref, SR_LONG), 1), "true_peak_db": round(true_peak_db(gain_ref, SR_LONG), 1),
        "loop": loop, "seam": round(seam(gain_ref), 2) if loop else None, "quiet_share": round(quiet_share(gain_ref, SR_LONG, target), 2)}
    for stem in extra:  # stems keep the mix's gain, so they sum back to it
        write_ogg(os.path.join(OUT, folder, "%s_stem_%s.ogg" % (name, stem)), np.clip(stems[stem] * gain, -1, 1))
        manifest["assets/audio/%s/%s_stem_%s.ogg" % (folder, name, stem)] = {"seconds": round(full.shape[1] / SR_LONG, 2), "loop": loop, "stem_of": name}
    print("%-28s %6.1fs %6.1f LUFS  peak %5.1f dB" % (name, full.shape[1] / SR_LONG, lufs(gain_ref, SR_LONG), true_peak_db(gain_ref, SR_LONG)))


def main(argv):
    wanted = argv or ["sfx", "ambience", "music"]
    path = os.path.join(ROOT, "assets", "audio_manifest.json")
    manifest = json.load(open(path)) if os.path.exists(path) else {}
    if "sfx" in wanted:
        for name, info in sfx.build(os.path.join(OUT, "sfx")).items():
            manifest["assets/audio/sfx/%s.wav" % name] = info
        print("sfx: %d files" % len(sfx.build_table()))
    if "ambience" in wanted:
        for name, (fn, target) in ambience.CUES.items():
            render(name, {"all": fn()}, target, True, (), "ambience", manifest)
    if "music" in wanted:
        for name, (fn, target, loop, extra) in music.CUES.items():
            if len(argv) > 1 and argv[0] == "music" and name not in argv[1:]:
                continue
            render(name, fn(), target, loop, extra, "music", manifest)
    with open(path, "w", newline="\n") as f:
        json.dump(manifest, f, indent=1, sort_keys=True)
        f.write("\n")


if __name__ == "__main__":
    main(sys.argv[1:])
