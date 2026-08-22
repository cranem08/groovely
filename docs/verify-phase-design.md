# Verify Phase — Design Plan

**Status:** Foundations agreed with Product Engineer; ready to build
**Date:** 2026-07-11 (revised — supersedes the 2026-07-07 draft)
**Scope:** The verify-workflow: the final gate that demonstrates the Dark Factory
built the application *as specified by the product-workflow*. Touches all three
planes — product-workflow (authors the spec), Dark Factory (builds), verify
(certifies).

> This revision replaces the earlier "vendor a read-only fitness suite / audit the
> builder's tests" model. A sequence of foundational decisions (logged in §11) moved
> the design to: verify establishes conformance *independently*, trusts *only* the
> spec, and runs *clean-room*. Where this document and the earlier draft disagree,
> this document wins.

---

## 1. Purpose

Verify exists to demonstrate one thing: **the running application conforms to the
specification the product-workflow produced** — the whole specification, and nothing
beyond it. It is the final gate before deployment. A human trusts the Dark Factory's
autonomous build not by reading its work, but because an independent gate confirms the
result matches what was asked for.

Verify certifies *conformance to the spec*, never the *quality of the spec*. If the
specification is wrong, a faithful build of the wrong thing will — correctly — pass.
"Is this the right thing to build?" is answered upstream, by the person, on the
product-workflow plane. (See §8.)

## 2. Foundational principles

Five principles cut across every decision below.

**Shared, human-readable context is load-bearing — everywhere.** The workflow's value
is intent becoming legible artefacts that people and agents reason over together. No
rule, check, or verdict is ever reduced to an opaque token: an ID plus a machine
predicate is *lossy* — it says what to check but discards the why. Every rule reads in
full plain language wherever it appears. Verify is not a black box; its checks and its
reports carry their full human statements.

**Verify trusts only the spec.** The product-workflow spec (and facts stamped by the
neutral harness) are the only trusted inputs. Everything the Dark Factory produced or
reported — code, its own tests, coverage numbers, logs, provenance claims — is the
untrusted subject under examination, re-established by verify itself.

**Verify establishes conformance independently.** It does not rely on the builder's
tests to prove anything. It drives the app and reads the built artefact and reaches its
own verdict.

**The demonstration is only as trustworthy as verify's own checks** — so verify must
prove *its own* checks are sound before its verdict counts (§5).

**Conformance, not endorsement.** A PASS attests fidelity to the specification, not the
wisdom of the specification.

**Domain- and stack-agnostic.** The product is the *workflows*, not any app they build.
All workflow machinery — the `verify` agent, the `verify` skill, the
manifest *format*, the `design`/`sufficiency-check` changes, Rule 7, the standards — is
generic and knows nothing about any particular app, language, or framework. It deals in
*categories* and *patterns* ("dependency-direction rule," "tech-stack pin," "the
mutation command," "the deployed URL"). Anything concrete — vinyl records, React, Dexie,
`dist/`, a specific mutation tool — lives only in per-project instances under
`projects/{name}/` (that project's manifest clauses, feature files, `verification/`
project, `commands-map.yaml`, `deployment.yaml`), produced by *running* the generic
machinery on one app. `commands-map.yaml` is the seam: stack-specific commands are named
there per project and referenced abstractly by the workflow. The workflow additionally
carries **thin, non-binding per-stack cheat sheets** (reference notes that help the
`design` agent draft a new project's manifest and commands faster) — suggestions only,
never authoritative, never read at verify time; the project's own files always win. This
mirrors the existing `build-workflow-packaging` skill's per-stack sections.

Throughout this document, **groovely is the test fixture** used to validate the generic
machinery, never a target it is tailored to. Every groovely-specific detail below
(React, Dexie, `dist/`, "no performance requirements") is an *illustration of the
format*, not content baked into the workflow.

## 3. What verify demonstrates — the claim

**Bidirectional.** Two directions, both required:

1. *Everything specified is present and correct* — every behaviour, rule, field, and
   quality target the spec asserts is satisfied by the app.
2. *Nothing unspecified is present* — the app exposes no capability the spec did not
   ask for. An unrequested addition **fails** the gate (not merely flagged). The
   human-engineer standard: you would bounce a pull request that quietly added a
   feature nobody asked for; an autonomous builder is held to the same bar — more so,
   because it adds things with no intent and no memory, and you cannot ask it why.

**What counts as an "extra."** An extra is an *observable or structural* addition: a
new user-facing capability, a route or network call, a stored data field, or an
external dependency. It is **not** the ordinary implementation detail — helper
functions, local state, styling — that is simply *how* the spec gets built. This is the
same judgement you apply to a human engineer: you review what the system *does and
exposes*, not whether every private function was named in the ticket. Conveniently,
each kind of extra is the reverse of a spec surface already held: an unrequested
capability shows against the feature files, a network call against the NFRs, a field
against the data model, a dependency against the architecture pins. "Nothing extra" is
the same set of checks as "everything present," run in the other direction.

**Remit: the entire spec.** Verify covers every surface the spec defines — behaviour,
architecture, data model, performance, accessibility, security — checking exactly what
the spec asserts on each and staying silent where it asserts nothing. Groovely declares
no performance or security requirements for its MVP, so there is simply nothing to
check there; the mechanism exists for a project that does. Leaving quality attributes to
the builder's own gates was rejected: it would let the untrusted party self-certify the
hardest, most dangerous requirements.

## 4. How verify works

**Two techniques, one authority.** Verify is black-box for behaviour and white-box for
structure. This is a *testing technique*, not opacity to humans (§2).

- *Behaviour — black-box.* Verify drives the running application and does not read its
  source. It finds elements the way a user does: by visible **role and accessible
  label**, drawn from the spec's user-facing vocabulary (feature files + UI field map).
  This doubles as an accessibility check — if verify can locate every element by role
  and name, the app is navigable by assistive technology; if it cannot find the
  "Artist" field by its label, that is at once a broken grip *and* a real WCAG failure.
  A spec'd test handle is permitted only for the residue that role-and-label cannot
  uniquely identify (one row in a long identical list, a drag, a canvas).
- *Structure & extras — white-box.* Verify reads the built artefact — imports,
  dependency graph, data fields, config, routes — to confirm architecture conformance
  and the absence of extras. (This overturns the original Rule 7 "never reads source";
  the rule is rewritten to state the two-technique model. See §7.)

**Trust boundary.** Verify ingests exactly two things: the pristine spec (from the
product-workflow, never from the build) and the built artefact as *inert input* — files
to inspect plus a deployed URL to drive. Because the spec comes from the human plane and
the build output is treated as the thing on the examination table, there is nothing in
the build a tampering builder could corrupt to fool verify.

**Clean room.** Verify runs in its own fresh environment with its own trusted toolchain.
It never executes inside the builder's workspace or trusts the builder's configs, so a
planted lint config, a fake mutation engine, or a polluted `node_modules` cannot reach
verify's judgement.

**Artifact identity.** The build produces a single immutable, content-addressed artefact
(a hash of the bundle). Verify certifies *that exact hash*; deployment promotes the
identical bytes — no rebuild between passing and shipping. The hash is the thread tying
"what shipped" to "what passed." For groovely: the Dark Factory builds `dist/`, verify
certifies *that* `dist/`, and *that* same `dist/` is committed and pulled — never a
fresh rebuild along the way.

## 5. Verifying the verifier

Verify is the last gate; nothing audits it. So the entire demonstration rests on
verify's own checks being sound, and verify must *prove* that before its verdict counts.
Two requirements per check.

**Traceability, both ways.** Every check maps to a specific spec clause, and every spec
clause maps to at least one check. Nothing in the spec goes unchecked; no check tests
something the spec never said.

**Teeth — proven, not assumed.** A check that stays green when the app is broken proves
nothing. Verify demonstrates each check *fails* when the thing it guards is violated —
using deterministic tooling, **never the LLM** (an agent inventing and applying mutants
each run would burn tokens without bound and is the wrong tool anyway). The mechanism is
matched to the cost of each surface:

- *Structure — mechanized mutation (nearly free).* Apply the clause's counter-example
  (a scripted patch: "add `import React` here," "drop this index") and/or standard
  mutation operators (Stryker, mutmut); confirm the check fails. Multiple mutants per
  rule, including near-miss variants — one counter-example is necessary but not
  sufficient (a string-match check can catch the one example and miss ten neighbours).
- *Behaviour — cheaper but real.* Full app mutation plus re-running browser tests is
  compute-heavy. Instead: invert the test's own expected outcome (if it still passes
  when you flip what it expects, it is toothless) and run the suite against a small
  known-broken reference. Catches a dead test without mutating the whole application.

The agent's only cost here is *one-time authoring* of harnesses and counter-examples,
amortised across every future run; per-run cost is ordinary compute, no model calls.

## 6. Relationship to the Dark Factory

The Dark Factory builds its *own* guardrails from the same spec — its own architectural
fitness functions and behaviour tests, exactly as it already writes its own unit tests —
and **hard-stops each slice** on them: a failing check forces it to fix the *design of
the code*, never the test. It may never edit two things to force a green: the **spec**
(a rule it dislikes is escalated to the product-workflow, not edited) and any input the
**neutral harness** controls.

Three points keep this honest and useful:

- *Independence, not trust.* Verify does not rely on the builder's guardrails to
  establish conformance — it re-derives every check itself (§2, §4). The builder's tests
  are the untrusted subject, not evidence.
- *Aligned guardrails (late-gate mitigation).* The builder's guardrails are held to
  **verify's own standard** — traced to the same spec clauses, required to have teeth —
  so build-time green strongly predicts verify green and the final gate is confirmatory
  rather than a surprise. Verify still runs once, terminally, as the sole authority.
- *Guardrail audit — non-gating.* Separately from the deployment verdict (which comes
  solely from verify's own checks), verify reports where the builder's safety net was
  weak — anything verify caught that the builder's tests should have caught but did not —
  so the factory can be strengthened. This informs; it never blocks.

Escalation: a failing check is a code defect the Dark Factory fixes. If the *rule* is
wrong, that is a spec change, escalated back to product-workflow `design` →
`sufficiency-check`, never edited in place — a test changes only when the specification
changes.

## 7. Changes on the product-workflow (spec) plane

**Single source of truth with a consistency gate.** Each testable rule lives canonically
once — as a clause carrying its full human **statement**, its machine **predicate**, and
a stable **ID**. The predicate is *added to* the statement, never a replacement for it,
so nothing is ever lossy. Where prose (an ADR, `system.md`) refers to the rule, it
**restates it in full plain language and tags the ID** — *"do not import frameworks in
the domain (ARCH-012)."* The clause is the authority; the prose is a human-readable
mirror; **sufficiency-check compares them and fails on divergence**, reusing machinery
already in place. Verify and the Dark Factory always resolve the ID to the clause; a
person reading any artefact still gets the full context.

**New/changed artefacts and agents:**

1. **Architecture-rules manifest** — the canonical clauses for architecture (statement +
   predicate + counter-example(s) + ID), owned by the `design` agent. The behavioural
   analogue already exists as `.feature` files (owned by `discover`); the data model and
   NFRs become the canonical clause sets for their surfaces.
2. **`design` agent** — emits and maintains the manifest as a first-class output,
   distilled from the ADRs/`system.md` it already produces.
3. **`sufficiency-check` agent** — gains two duties: validate that every clause is
   unambiguous and machine-checkable (a vague rule is a Tier 1 finding), and enforce the
   consistency gate between clauses and their prose restatements.
4. **`verify` agent** and **`verify` skill** — author the verification
   project and run it clean-room (§4, §5).
5. **`deployment.yaml`** — the app URL per environment; the shared contract between the
   Dark Factory and verify.
6. **`CLAUDE.md` Operating Rule 7** — rewritten for the two-technique model (black-box
   behaviour, white-box structure), trust-only-the-spec, clean-room, and the terminal
   gate; and the `verify.md` inconsistency in the directory-structure block fixed.

## 8. What a PASS attests — and what it does not

A PASS reads **"conforms to specification vX,"** and the report explicitly names what it
does *not* attest: design quality, the soundness of the spec itself, and anything the
spec never asserted. This mirrors human QA: the final phase confirms the app meets the
requirements, not that the requirements were wise. The self-scoping verdict keeps a
green from being misread as an endorsement, and keeps "is this the right thing to build?"
visibly upstream with the person.

## 9. Lifecycle position

Verify is the final gate before deployment. Its behavioural half is black-box, so the app
must already be built and deployed to a test environment (the URL in `deployment.yaml`)
when verify runs; verify certifies *that* instance by hash, and only a PASS promotes the
identical bytes onward.

```
… → package → [Dark Factory builds; own guardrails held to verify's standard,
                hard-gating each slice]
             → deploy-to-test → verify (clean-room, final gate) → promote exact artifact
```

## 10. Build sequence

Two phases, kept strictly separate: implement the generic (project-agnostic) changes
across all three workflows first; only then validate them on a simple test project. **No
project-specific artefact is authored during implementation.**

**Phase A — implement the generic workflow changes (all three workflows)**

1. Rewrite `CLAUDE.md` Rule 7 (two-technique model, trust-only-spec, clean-room, terminal
   gate) and fix the `verify.md` directory-structure inconsistency.
2. Define the generic architecture-rules manifest **format** — the clause schema
   (statement + predicate + counter-example + ID) — with no project content.
3. Write the `verify` skill: generic clause→check patterns, the
   traceability and teeth harnesses (§5), the accessibility-first grip, the clean-room
   scaffold, the self-scoping report format, and the thin per-stack cheat sheets.
4. Write the `verify` agent.
5. Extend `design` (emits a project's manifest) and `sufficiency-check` (validates
   clauses; enforces the consistency gate).
6. Wire the Dark Factory (build-workflow): build its own guardrails from a project's
   manifest, held to verify's standard; hard-gate each slice; keep the spec immutable to
   the build; record the manifest version (neutral-harness-stamped) for verify.

**Phase B — validate on a simple test project**

7. Take a simple project through the workflows to produce *its* manifest,
   `deployment.yaml`, and `verification/` project, then exercise verify end-to-end — the
   white-box path from a source tree, the black-box path once the app is built and
   deployed. This is a *test of the machinery*, not part of it.

## 11. Decision log (locked this session)

| # | Decision |
|---|----------|
| D1 | Verify establishes conformance **independently** on every surface; the split is black-box *testing* for behaviour, white-box for structure — a technique, not opacity. |
| D2 | The claim is **bidirectional** — everything specified present, nothing unspecified; extras **fail** the gate. |
| D3 | An "extra" is an **observable or structural** addition (capability, route, network call, stored field, dependency), not incidental implementation detail. |
| D4 | Verify's remit is the **entire spec** — behaviour, architecture, data model, performance, accessibility, security. |
| D5 | Verify **trusts only the spec** and neutral-harness facts; all builder output is untrusted and re-established. |
| D6 | Verify **audits the builder's guardrails as non-gating feedback**; the deployment verdict is verify's own checks alone. |
| D7 | Verify proves its **own** checks sound: **traceability both ways** + **teeth** (mechanized mutation for structure; expected-outcome inversion + known-broken reference for behaviour); **LLM never in the mutation loop**. |
| D8 | Verify runs **clean-room** — own environment and toolchain, ingesting only the pristine spec and the built artefact as inert input. |
| D9 | Verify **certifies one immutable, content-addressed artefact and promotes those exact bytes** — no rebuild between passing and shipping. |
| D10 | A testable rule lives canonically **once** (statement + predicate + ID), is **restated in full human language wherever referenced**, and is kept in sync by the **consistency gate** (sufficiency-check). Shared, readable context is foundational; nothing is reduced to an opaque token. |
| D11 | A **PASS = conformance to specification vX**, self-scoping; it does not attest design quality or the soundness of the spec. |
| D12 | Behaviour tests grip the app **accessibility-first** (role + label from the spec), with a spec'd handle fallback for the residue; this doubles as a WCAG check. |
| D13 | The builder's guardrails are **held to verify's standard** (same clauses, same teeth) so build-time green predicts the verdict; verify stays the single **terminal** gate. |
| D14 | The workflows are **domain- and stack-agnostic**. All machinery is generic; concrete app/stack detail lives only in per-project instances under `projects/{name}/`, with `commands-map.yaml` as the seam. The workflow carries **thin, non-binding per-stack cheat sheets** (reference only, project files always win). Groovely is the **test fixture**, never a design target. |

## 12. Residual notes

- **Sufficiency-check is not convergent.** A PASS means "no catalogued ambiguity pattern
  matched," not "provably unambiguous" — groovely's own re-scan surfaced new Tier 1s
  after the first pass. Traceability-both-ways (D7) helps completeness, but PASS should
  be read as a strong floor, not a proof.
- **Enforcement must be real, not policy.** "Immutable to the Dark Factory,"
  "clean-room," and "harness-stamped provenance" (D5, D8, D13) are only as strong as the
  sandbox that enforces them (filesystem permissions, separate environments/credentials).
  The design assumes this; the implementation must provide it.
- **Proportionality.** This apparatus has so far only been pointed at a single-user,
  no-auth, no-network concept-proof. Which parts earn their keep is untested until a
  project whose stakes justify the rigor runs through it. Build for groovely first; let
  real use, not speculation, drive hardening.
