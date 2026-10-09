# 2026-10-09: Fourth round of decisions (Q8, Q16, dropped targets)

## What was done

Recorded the lead's answers:
- **Q8:** typed GDScript approved; ADR-0003 Accepted.
- **Q16:** measure on the Ryzen 7 5800X and on the Steam Frame, through FEX
  (x86 build) and natively (Linux ARM64 test build). ADR-0007 records the
  method; ADR-0004 records the ARM64 test build as not shipping. The builds
  and overlay are in their own PRs.
- **macOS and Steam Deck performance targets dropped** from ADR-0007.
  Interpreted as the performance targets only: macOS stays a shipping
  platform (ADR-0004) with no performance target. Asked the lead to confirm.
- ADR-0007 now notes that full-resolution rendering (ADR-0008 Amendment 3)
  makes GPU work scale with screen size (9× the 640×360 work at 1080p, 32× at
  5120×1440).

New **Q17**: whole-number or fractional scaling now that rendering is full
resolution.

## What broke, and how it was found

Nothing broke.

## Not verified

Option D (a real minimum-spec PC) was not chosen, so the 120 fps target can
only be estimated (5800X scaled rule, Steam Frame stress test), never
confirmed on its own hardware.
