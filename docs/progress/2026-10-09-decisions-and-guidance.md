# 2026-10-09: Second round of decisions; guidance for Q4 and Q6

## What was done

Recorded the lead's answers of 2026-10-09 in `docs/design/open-questions.md`:
- **Q7** resolved: the web build is validation only, never shipped (ADR-0004
  status line).
- **Q11** resolved: Git LFS (implemented in its own PR, ADR-0011).
- **Q12** resolved: start fullscreen (implemented in its own PR, ADR-0008
  amendment).
- **Q1 addition**: 21:9 and 32:9 at 1080p and 1440p (same PR as Q12).
- **Q13** resolved, B + C: people taken town by town; monsters are wildlife
  and land changed by the god's presence (`story.md`, art and audio direction).
- **Q14** resolved: the cat treats recipe is the tutorial for skills and
  crafting; feeding the pet gives story moments only (`story.md`).

The lead asked for more guidance on two questions; both sections were
rewritten:
- **Q4**: what 120 fps on a GTX 1050 Ti means for this game (8.3 ms per
  frame; the GPU is not the risk at 640×360, the CPU is; 120 Hz monitors;
  physics interpolation), a full proposed budget, what CI can and cannot
  measure, and three answers needed (CPU, Mac/Steam Deck targets, a
  minimum-spec test machine).
- **Q6**: how input will be built (actions, rebinding, last-device prompts,
  one haptics service), what Godot 4.7.2 provides, and four decisions
  (mouse, prompt families, the DualSense route, leaving fullscreen).

New **Q15**: how much world 32:9 screens should show (found while adding
super-ultrawide support).

Engine facts behind the guidance are in the architecture appendix.

## What broke, and how it was found

Nothing broke. One finding that shapes Q6: **Godot 4.7.2 has no API for
DualSense adaptive triggers or HD haptics.** Found by searching every engine
class's methods; rumble, the light bar and motion sensors do exist.

## Sources outside the engine (not verified by the engineer)

- GitHub's LFS allowance: GitHub billing documentation, checked 2026-10-09.
- DualSense on PC (adaptive triggers wired-only, OS-specific native code
  needed, an engine change covering only macOS/iOS): Godot forum thread
  "How to implement PS5 L2 and R2?".
- The "Audio Haptics" Godot extension (MIT, Godot 4.2, Linux tested, Windows
  untested): its Godot Asset Library page.
- Steam Deck refresh rates (60 Hz LCD, 90 Hz OLED) and the minimum-spec CPU
  pairing are the engineer's general knowledge, offered as proposals.
