# 2026-10-09: Story premise, the pet, and AI audio prompts

## What was done

Recorded the lead's answers of 2026-10-09:
- **Q2:** placeholders in code now; final art provisioned later.
- **Q3:** music and ambience from separate specialised AI tools, run by the
  lead. Wrote `docs/design/audio-prompts.md`: delivery spec, licence and
  register rules, a shared style anchor and avoid list, the pet's four-note
  motif, prompts for every designed area (only the base so far: MUS-01,
  MUS-02, AMB-01, AMB-02, AMB-03) and the non-area cues (title MUS-10,
  discovery MUS-11, combat MUS-12, late-game motif MUS-13), and a template
  for future areas.
- **Q9:** the pet cat is secretly an eldritch god; the farm survived because
  it enjoys it; the player survived for their cat treats, the first recipe.
  This amends ADR-0005 point 4 (no companions), so it is ADR-0010, with
  ADR-0005's status line pointing to it. `docs/design/story.md` holds the
  premise, tone, writing rules and a proposed reveal structure.
- Art and audio direction updated for the pet; CLAUDE.md summary updated.
- New open questions: Q13 (what the calamity looked like, where monsters come
  from) and Q14 (does feeding the pet do anything).

No code or assets changed.

## What broke, and how it was found

Nothing broke. One judgement to flag: the brief excluded companions, and the
lead's Q9 answer adds one. I recorded it as an amendment (ADR-0010) because
the lead's answer is the decision; if the lead meant it differently, ADR-0010
is where to correct it.

## Interpretations made (lead to confirm)

- The pet is a cat (the answer centres on cat treats).
- It stays at the base and does not join adventures ("hangs out with you and
  around your farm").
- It never speaks.
- Only the base is a designed area, so only the base has area prompts; no
  day/night or seasonal variants were written, because neither system is
  decided.

## Not verified

Whether any prompt produces good results in the lead's chosen tools: only the
lead can generate and listen. The tools' licence terms are unknown to the
engineer.
