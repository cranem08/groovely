---
name: verify
description: >
  Codifies how the verify agent turns a project's specification into an independent,
  clean-room conformance gate. Defines clause-to-check translation for behaviour
  (black-box) and architecture/structure (white-box), the bidirectional "everything
  specified present / nothing unspecified" claim, the traceability and teeth harnesses
  that prove verify's own checks are sound before its verdict counts, the
  accessibility-first element grip, the clean-room verification-project scaffold, and the
  self-scoping report. Generic and project-agnostic: all concrete stack/app bindings come
  from the project instance and commands-map.yaml. Applied exclusively by the verify agent.
---

# Skill: verify

## Purpose

Codifies everything the `verify` agent needs to build and run the terminal conformance
gate for any project: how to translate a specification into independent checks, how to
prove those checks are themselves sound, and how to run and report them clean-room. This
skill is the *method*; the per-project spec and `commands-map.yaml` supply all concrete
content. Nothing here names an app, language, or framework.

## Operating principles (from CLAUDE.md Rule 7)

- **Terminal gate.** Verify is the last check before deployment; only a PASS promotes.
- **Trust only the spec.** The spec (feature files, `fitness.md` manifest, data model,
  NFRs, `ui-field-map.md`, `deployment.yaml`) and neutral-harness facts are the only
  trusted inputs. Everything the Dark Factory produced — code, its own tests, coverage,
  logs, provenance — is the untrusted subject, re-established by verify.
- **Two techniques.** Black-box for behaviour (drive the running app, never read source),
  white-box for structure and extras (read the built artefact).
- **Independent.** Verify establishes conformance itself; it never relies on the builder's
  tests to prove anything.
- **Clean-room.** Own environment and toolchain; ingest only the pristine spec and the
  built artefact as inert input.
- **Certify one artefact.** Certify the exact content-addressed bytes that will be
  promoted; never a rebuild.
- **Conformance, not endorsement.** A PASS attests fidelity to a spec version, not the
  quality of the spec.

## Inputs

1. **Pristine spec** (from product-workflow, never from the build): `.feature` files;
   the architecture-rules manifest `docs/architecture/fitness.md`; data-model and NFR
   clause sets; `ui-field-map.md`; `deployment.yaml`.
2. **Built artefact as inert input**: the content-addressed bundle (files to inspect) and
   the deployed URL (to drive). Treated as the thing on the examination table.
3. **`commands-map.yaml`**: the stack seam — supplies concrete commands (mutation runner,
   import scanner, build, app-run) and the role→literal bindings (which globs are the
   "domain layer", which packages are "frameworks", etc.). Referenced abstractly.

## Procedure (what the verify agent performs)

1. **Assemble the clause set + traceability index.** Gather every clause across surfaces:
   behavioural scenarios from `.feature` files (by Feature/Scenario name), architecture
   clauses from `fitness.md`, data-model and NFR clauses. Record each clause ID. This
   index drives both directions of traceability (§ teeth-and-traceability).
2. **Translate each clause to a check** — see `references/check-patterns.md`. Build both
   directions: `presence` checks (everything specified is there) and `absence-of-extra`
   checks (nothing unspecified exists). Behaviour → black-box specs with accessibility-
   first grip; structure → white-box fitness functions.
3. **Prove the checks are sound before trusting any result** — see
   `references/teeth-and-traceability.md`. Enforce two-way traceability and demonstrate
   each check has teeth (mechanized mutation for structure; expected-outcome inversion +
   a known-broken reference for behaviour; never LLM-driven). A toothless or orphan check
   is a blocking verify finding, fixed before the verdict counts.
4. **Run clean-room** against the certified artefact and the deployed URL — see
   `references/verification-project.md`. Record the artefact hash.
5. **Emit the self-scoping report and verdict**, append the `product-log.md` sentinel.
6. **Audit the build's own guardrails, non-gating** — report where the build's tests
   missed something verify caught, so the factory can be strengthened. This never affects
   the deployment verdict, which comes solely from verify's own checks.

## Verdict

A PASS reads **"conforms to specification vX"** and the report names what it does *not*
attest: design quality, the soundness of the spec, anything unspecified. See
`references/verification-project.md` for the report template.

## References

- `references/manifest-format.md` — the clause schema verify consumes.
- `references/check-patterns.md` — turning each clause/check-type into a check; behaviour
  grip; the absence-of-extra (nothing-extra) checks.
- `references/teeth-and-traceability.md` — proving verify's own checks are sound.
- `references/verification-project.md` — clean-room scaffold, ingest, artefact hashing,
  report format.
- `references/cheat-sheets.md` — thin, non-binding per-stack reference notes.

EOF — Skill: verify
