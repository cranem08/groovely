# Reference: Architecture-Rules Manifest — Format

The canonical, project-agnostic format for the architecture-rules manifest
(`projects/{name}/docs/architecture/fitness.md`) and for any other surface that expresses
machine-checkable clauses (data model, performance, accessibility, security). Authored by
the `design` agent, validated by `sufficiency-check`, consumed by the `verify` agent and
the Dark Factory. This file defines the *format only* — it contains no project, language,
or framework content. Concrete bindings (which files are the domain layer, which package
is a framework, which command runs mutation) live in the project instance and in
`commands-map.yaml`.

## What a manifest is

A flat, ordered set of **clauses**. Each clause is the single canonical home of one
testable rule. A clause carries three things that must always travel together:

- a **statement** — the rule in full human language (the *why* and *what*), never omitted
  or reduced to a token;
- a **predicate** — the same rule stated precisely enough to check mechanically; and
- at least one **counter-example** — a concrete recipe for a known violation the check
  must reject, which is what lets `verify` prove the check has teeth.

The statement is load-bearing: shared, readable context is a workflow principle. The
predicate is *added to* the statement, never a replacement for it.

## Clause template

Each clause is a level-3 section keyed by its ID, followed by labelled fields. This is
readable as prose and parseable by convention.

```
### <ID> — <one-line title>

**Statement:** <the rule in full plain language — the normative sentence a human reads>

**Surface:** architecture | data-model | performance | accessibility | security | ...
**Source:** <ADR / standard / decision this derives from — upstream traceability>
**Check type:** <one value from the check-type vocabulary below>
**Technique:** static | runtime | black-box
**Predicate:** <precise, tool-agnostic condition, referring to project roles
  (e.g. "the domain layer", "a framework package") rather than concrete paths/names —
  those roles are resolved per project via commands-map.yaml / project config>
**Counter-examples:**
- <a concrete known-violation recipe the check MUST fail on>
- <a near-miss variant — encouraged; one example alone is necessary but not sufficient>
**Disposition:** blocking            # architecture/data/security clauses default blocking
```

## Field rules

- **ID** — stable, unique, never reused. Prefix by surface so IDs are self-describing:
  `ARCH-NNN`, `DATA-NNN`, `PERF-NNN`, `A11Y-NNN`, `SEC-NNN`. Behavioural clauses live in
  the `.feature` files and are referenced by `Feature:`/`Scenario:` name, not duplicated
  here. An ID, once published, is the anchor every restatement and every check traces to;
  changing a rule's meaning requires a new ID, not silent reuse.
- **Statement** — full sentence(s), plain language, no jargon-only tokens. This is what
  prose restatements elsewhere (ADRs, `system.md`) must match under the consistency gate.
- **Predicate** — expressed in terms of *roles* the project defines, not literals. Good:
  "no file in the domain layer imports a framework package." Not: "no file in `src/domain`
  imports `<a named framework>`." The literal mapping (domain layer -> path globs,
  framework package -> a named list) is project-instance data, keeping this clause
  portable across projects and stacks.
- **Counter-examples** — at least one; each is a deterministic, scripted mutation recipe
  (a patch), never something an agent must reason out at run time. Prefer several,
  including near-miss variants, since a single example gives false confidence.
- **Technique** — `static` (read the built source/config), `runtime` (observe the running
  app), or `black-box` (drive the running app through user-facing affordances). Most
  architecture clauses are `static`.
- **Disposition** — `blocking` or `advisory`. Conformance clauses are `blocking` by
  default; a failing blocking clause fails the gate.

## Check-type vocabulary (generic)

Every clause names one check type. These are the abstract categories the
`verify` skill knows how to turn into checks; they are stack-independent
(their bindings come from the project). Extend deliberately, not casually.

- `dependency-direction` — module A must / must not depend on module B.
- `layer-isolation` — a layer imports nothing from designated other layers.
- `tech-stack-pin` — a declared tool/version/component is present (and no forbidden
  substitute is).
- `config-audit` — a configuration asserts a required setting.
- `forbidden-api` — a designated API/construct does not appear outside its allowed home.
- `presence` — something the spec requires exists (a field, an index, a route).
- `absence-of-extra` — nothing beyond the spec exists on a surface (the bidirectional /
  "nothing extra" check; the reverse of `presence`).
- `value-constraint` — a field/setting satisfies a stated domain constraint.
- `runtime-behaviour` — a property observable only on the running app (e.g. no network
  egress from the given origin).

## Coverage obligations (checked by verify)

- **Downward traceability:** every clause maps to at least one check in the verification
  project.
- **Upward traceability:** every check maps to exactly one clause ID.
- **No orphan prose:** every plain-language restatement of a rule elsewhere (an ADR line,
  `system.md`) carries its clause ID and matches the clause's statement — enforced by the
  consistency gate in `sufficiency-check`.

## Non-content

This format file, and every workflow artefact that references it, stays generic. Worked
examples used to teach the format elsewhere are illustrations of the *shape*, not content
the workflow assumes; project rules live only under `projects/{name}/`.
