# ADR-0004: Target platforms

- **Status:** Accepted
- **Date:** 2026-10-09
- **Decided by:** Project lead (brief of 2026-10-09)

## Context

The brief names Windows, macOS and Linux. The brief's merge gate also includes a
"Web build" CI check and a "Desktop export" CI check.

## Decision

- **Shipping platforms:** Windows, macOS and Linux desktop.
- **Desktop export** is a required CI check for all three.
- **Web build** is a required CI check. Whether the web build is also a shipping
  platform is undecided (open question Q7). Until the lead decides, it is
  treated as a build-health check only: it must export successfully, but no
  web-specific features are built.

## Consequences

- Godot's web export uses the Compatibility renderer
  (`rendering/renderer/rendering_method.web` defaults to `gl_compatibility`,
  verified 2026-10-09) while desktop defaults to Forward+. Which renderer the
  desktop build uses is open question Q5.
- Platform-specific code paths (save locations, window handling) must work on
  all three desktop systems. Save paths should go through `user://`.
- macOS distribution outside the editor normally needs code signing and
  notarisation, which needs an Apple developer account (a secret the engineer
  does not have). CI can produce an unsigned macOS export; signing is deferred
  until there is something to distribute and will be raised then.
- Real-hardware behaviour on each platform cannot be verified headlessly and
  goes on playtest checklists.
