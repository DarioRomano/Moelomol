# ADR-0003: Language: statically typed GDScript

- **Status:** Accepted (approved by the project lead 2026-10-09, Q8)
- **Date:** 2026-10-09
- **Decided by:** Engineer's proposal, approved by the project lead

## Context

The brief does not name a language. Godot 4.7.2 supports GDScript in the
standard build and C# in the separate .NET build. The language is expensive to
reverse once gameplay code exists. One of the four required CI checks is a Web
build. The brief's test and render tooling must run headless in CI.

## Decision

All game code is written in **GDScript with static typing everywhere**
(variables, parameters, return values). The standard (non-.NET) Godot build is
used. No C#, no GDExtension native code, unless a later ADR supersedes this.

## Consequences

- No .NET SDK in CI or on the lead's machines; one engine binary does
  everything.
- The Web build check works with the standard export templates. Whether the C#
  build can export to the web in 4.7.2 was **not verified**; choosing GDScript
  removes the need to find out.
- Static typing gives editor and parser errors for type mistakes and faster
  execution than untyped GDScript. `debug/gdscript/warnings/untyped_declaration`
  is set to Error (verified against the engine; it makes untyped code a parse
  error, which `tests/unit/test_all_code_loads.gd` catches).
- Weaker refactoring tools than C# IDEs. Acceptable for a project of this size.
- Heavy simulation (for example large crop grids) may need care for
  performance; measured against ADR-0007 when it exists.

## Verification

`tests/unit/test_project_rules.gd` checks the setting; `test_all_code_loads.gd`
fails on any script that does not parse, including untyped declarations.
