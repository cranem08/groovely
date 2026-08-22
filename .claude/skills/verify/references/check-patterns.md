# Reference: Clause-to-Check Patterns

How the `verify` agent turns each spec clause into an independent check. Generic and
tool-agnostic — concrete commands and role→literal bindings come from the project's
`commands-map.yaml` and manifest. Every check maps to exactly one clause ID.

## Two techniques

- **Behaviour → black-box.** Drive the running app; never read source. Locate elements
  the way a user does (see "Accessibility-first grip" below).
- **Structure & extras → white-box.** Read the built artefact — imports, dependency
  graph, config, declared fields/routes — as inert input.

## Behavioural checks (from `.feature` scenarios)

One spec per feature, one test per scenario. Each Given/When/Then step maps to: arrange
app state through user-facing affordances, act through them, assert an observable outcome.
The assertion must be on something a user or external system can observe (visible text,
state, exported data, a network effect), never on internal source.

### Accessibility-first grip

Find elements by **role and accessible name/label**, drawn from the spec's user-facing
vocabulary (`.feature` files + `ui-field-map.md`): e.g. "the control with role *button*
and name *<label from spec>*", "the field labelled *<label from spec>*". This needs no
source reading and doubles as an accessibility check — if a required element cannot be
found by role and name, that is at once a broken grip and a real accessibility failure,
reported against the relevant A11Y clause. A spec-declared test handle is permitted
**only** for the residue that role+name cannot uniquely identify (one row among identical
rows, a drag, a canvas); the handle is named in the spec, not invented from the DOM.

## Structural checks (from the manifest, by check type)

Each realises one `check type` from the manifest vocabulary. Bindings (paths, package
names, settings) are resolved from project config; the pattern is generic.

- **dependency-direction / layer-isolation** — build the import/dependency graph of the
  built artefact; assert the designated source set contains no import resolving to a
  forbidden target set. Resolve re-exports and transitive edges, not just literal strings.
- **tech-stack-pin** — parse the dependency/config manifests; assert the declared
  tool/version/component is present and no forbidden substitute appears.
- **config-audit** — parse the named configuration; assert the required setting holds.
- **forbidden-api** — scan for the designated API/construct; assert it appears only within
  its allowed home (if any) and nowhere else.
- **presence** — assert the specified field/index/route/capability exists in the built
  artefact (static) or is observable (runtime).
- **value-constraint** — assert a field/setting satisfies its stated domain constraint.
- **runtime-behaviour** — observe the running app (e.g. capture network egress from the
  given origin and assert none occurs).

## Absence-of-extra checks (the "nothing unspecified" direction)

Bidirectional conformance requires the reverse of `presence`: confirm the app exposes
**nothing** the spec did not ask for. An extra is an *observable or structural* addition,
never incidental implementation detail (helpers, local state, styling). Enumerate the
built surface and diff it against the spec:

- **capabilities / routes** — enumerate user-facing capabilities and routes; every one
  must trace to a `.feature`/spec clause. Untraceable → fail.
- **network egress** — every endpoint/origin the app contacts must trace to a spec clause;
  an unrequested call → fail.
- **stored fields** — every persisted field must trace to the data model; an extra field
  → fail.
- **dependencies** — every external dependency must trace to a tech-stack clause; an
  unrequested library → fail.

Each extra is reported against the surface it violates, with its full context (what was
found, where, and which spec surface it fails against). Extras are blocking.

## Output

Every check carries its clause ID and the clause's full human statement, so results and
failures read in the spec's own vocabulary (never a bare ID).
