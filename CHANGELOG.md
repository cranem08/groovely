# Changelog

All notable changes to the product-workflow are recorded here. The workflow follows
Semantic Versioning (see `CLAUDE.md` § Versioning): the `VERSION` file holds the current
version, and git tags `vMAJOR.MINOR.PATCH` mark releases used to pin a version for a
project instance.

- **MAJOR** — breaking changes to artefact formats or agent/skill contracts.
- **MINOR** — additive, backward-compatible capabilities.
- **PATCH** — fixes, clarifications, documentation.

## [1.0.0] — 2026-08-22

First tagged release: the product-workflow as a reusable, project-agnostic template.

### Added
- Phase sequence `discover → design → sufficiency-check → package → verify`, with the
  `navigator` as the entry point.
- **Verify phase** — a terminal, independent conformance gate: bidirectional
  (everything specified present, nothing extra), trust-only-the-spec, clean-room,
  proven teeth + traceability, certify-one-artefact. Adds the `verify` agent, the
  `verify` skill, the architecture-rules manifest format, and the `design` /
  `sufficiency-check` extensions (manifest emission, clause validation, consistency gate).
- **Dark Factory verify-alignment obligations** carried into packaging; a parameterised
  Dark Factory runner template with container authentication and audit-log persistence.
- **Audit & observability layer** (`audit/`) — an offline, no-LLM worker that parses
  Claude's native logs across all planes, plus a live localhost dashboard (running
  agents, project, model, context window, saturation) and per-run trace reports.
- **Workflow versioning** — this changelog, the `VERSION` file, per-project version
  stamping (`workflow-version.json` + `product-log.md` header), and a resume-time
  mismatch warning in the `navigator`; plus `scripts/new-instance.sh` to clone the
  template at a pinned version.

### Notes
- Project-agnostic throughout: all machinery is generic; concrete app/stack detail lives
  only in per-project instances under `projects/{name}/`.
