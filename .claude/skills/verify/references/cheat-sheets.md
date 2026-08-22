# Reference: Per-Stack Cheat Sheets (thin, non-binding)

Optional starter notes, one per common technology stack, that help the `design` agent
draft a new project's manifest clauses and `commands-map.yaml` faster. They exist purely
to save starting from a blank page.

## Rules of use

- **Reference only, never authoritative.** A cheat sheet is a suggestion. The project's
  own manifest and `commands-map.yaml` are the sole source of truth. Where they differ,
  the project wins.
- **Never read at verify time.** Verify consumes the project instance, not cheat sheets.
- **Thin.** A cheat sheet is short: common role→binding mappings and the usual tool names
  for that stack, as examples — not a framework the project inherits.

## What a cheat sheet may contain

- Typical **role bindings** for the stack (e.g. how the "domain layer", "framework
  package", "persistence adapter" roles usually map to paths/packages) — as examples to
  adapt.
- The **usual commands** for that stack to slot into `commands-map.yaml` (import scanner,
  mutation runner, build, app-run) — as defaults to confirm, not assume.
- Common **counter-example recipes** for that stack's typical architecture clauses.

## Template

```
# Cheat sheet: <stack name>  (reference only — project files are authoritative)

## Common role bindings (adapt per project)
- domain layer            -> <typical path globs>
- framework packages      -> <typical package names>
- persistence adapter     -> <typical path globs>

## Suggested commands-map entries (confirm per project)
- import_scan  : <typical command>
- mutation     : <typical mutation tool command>
- build        : <typical build command>
- app_run      : <typical dev/preview server command>

## Common counter-example recipes (adapt)
- <check type> : <a typical scripted violation recipe for this stack>
```

Add a new cheat sheet only when a stack recurs; do not speculatively cover stacks no
project uses. This mirrors the per-stack sections already carried by the
`build-workflow-packaging` skill.
