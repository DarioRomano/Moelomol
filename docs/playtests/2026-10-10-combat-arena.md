# Playtest: combat test arena (greatsword)

**For:** the project lead. **Why:** the rules are tested automatically (46
tests), but whether combat *feels* right (responsiveness, weight, timing,
readability, rumble) can only be judged by playing.

## 1. Build

The release or PR build for your 5800X (Windows or Linux). From the title
press **F2** until the arena appears (title → test card → renderer features →
arena), or launch with `-- --start-scene combat_arena`. Play once with a
keyboard and once with a controller (any; a DualSense works for rumble).

## 2. Controls

| | Keyboard | Controller |
|---|---|---|
| Move | W A S D | left stick |
| Light | J | X / Square |
| Heavy | K | RT / R2 |
| Skill (Follow-through / Brace) | L | Y / Triangle |
| Dodge | Space | A / Cross |
| Lock on (hold) | Left Shift | LT / L2 |
| Switch target | Q / E | right stick left / right |

Developer keys: **F6** creatures passive (practise combos on standing
targets), **F5** render interpolation on/off (Q20), **F3** performance
overlay. The top-left line shows the current move and chain.

## 3. Checks

Write a short note for each: fine / problem (what).

1. **Movement** feels responsive in all eight directions and on the stick;
   no slide or delay. Result:
2. **Dodge:** roll distance (2 tiles) and duration feel right; you can dodge
   *through* a creature's lunge when timed well (the character turns
   see-through while invulnerable). Result:
3. **Telegraph:** the creature's red flash and red wedge give enough warning
   to react (0.7 s). Too long, too short? Result:
4. **Light chain (F6 on):** three sweeps connect on a standing creature; each
   feels faster than the last. Result:
5. **Finishers:** heavy alone, after 1, 2 and 3 lights gives cleave, shove,
   spin, rising slash. Each feels clearly different. Result:
6. **Push and impacts:** shoving a creature into a pillar, a wall or the
   other creature feels powerful (impact ring, extra damage, often a
   stagger). Result:
7. **Stagger and Follow-through:** staggered creatures (grey, circling
   stars) are obvious; Skill next to one gives Follow-through. Result:
8. **Brace:** Skill with nothing staggered nearby; take the lunge while
   bracing ("BRACE READY" appears), then Heavy comes out instantly. Is the
   0.5 s window usable? Result:
9. **Hit-stop:** hits feel weighty, not sticky. Heavier hits pause longer.
   Result:
10. **Lock-on:** holding lock keeps facing the target while moving; switching
    targets works; aiming without it (soft aim) feels fair. Result:
11. **Stamina:** you run out when spamming, and it never feels unfair.
    Result:
12. **Rumble (controller):** hits, heavy hits, impacts, staggers and being
    hit each feel different and not too strong. Result:
13. **Q20 at 120 Hz:** on a 120 Hz (or faster) screen, compare F5 on and off
    while moving and dodging. On: smoother but up to 16.7 ms behind. Off:
    immediate but possibly juddery. Which do you prefer, and can you feel the
    delay? Result:
14. **Overlay (F3)** in the arena while fighting both creatures: note FPS,
    frame times and "logic" ms. Result:
15. **Anything else** that feels wrong, slow, floaty or confusing. Result:

## 4. Report back

Notes per check; tuning changes come back as a PR with the new values for
your approval.
