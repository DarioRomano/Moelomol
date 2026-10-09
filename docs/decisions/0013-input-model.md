# ADR-0013: Input model

- **Status:** Accepted
- **Date:** 2026-10-09
- **Decided by:** Project lead (open question Q6; all recommendations accepted
  2026-10-09)

## Context

The lead's direction: a standard keyboard and controllers; haptic feedback on
controllers; on DualSense, its adaptive triggers and haptics. Godot 4.7.2 has
rumble, light-bar and motion-sensor APIs, but none for DualSense adaptive
triggers or HD haptics (verified, architecture appendix). The full guidance
is in `docs/design/open-questions.md`, Q6.

## Decision

1. **Actions, never keys.** All input goes through named InputMap actions;
   keyboard keys and controller buttons are bound to the same actions.
   Every action can be rebound, for keyboard and controller separately.
2. **Devices (Q6a):** the keyboard plays the game; the mouse also works in
   menus and inventories. No mouse aiming.
3. **Button prompts (Q6b):** separate prompt sets for keyboard, Xbox,
   PlayStation (DualShock 4 and DualSense) and Nintendo. Steam Deck and
   unknown controllers use Xbox prompts. Prompts follow the device last used.
4. **Haptics (Q6c):** one haptics service that gameplay calls with named
   effects. Rumble and the light bar on every controller that has them, now.
   DualSense adaptive triggers and HD haptics: a timeboxed prototype on
   Windows over USB once tools and combat exist; it decides between adopting
   an extension and writing our own (which would need an ADR superseding
   ADR-0003). Bluetooth DualSense players get rumble.
5. **Fullscreen (Q6d):** Alt+Enter (Windows, Linux) and Ctrl+Cmd+F (macOS)
   toggle fullscreen; an options-menu setting comes with the first menu.
6. **Accessibility basics:** hold-or-toggle for held actions, adjustable stick
   dead zones, vibration intensity including off.

## Consequences

- Every menu must work with keyboard, mouse and controller.
- Four sets of prompt art (placeholders until art is provisioned).
- Controller feel and haptics can only be judged by a human: every input
  feature comes with playtest checklist items.
- The DualSense prototype needs a DualSense and the lead to test it.

## Verification

Implemented so far: the fullscreen shortcuts (`src/core/window_controls.gd`,
tests in `tests/unit/test_window_controls.gd`). The rest arrives with the
first moving character and the first menu.
