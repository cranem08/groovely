# CLAUDE.md — product-workflow

## Startup Behaviour

Immediately upon session start, without waiting for any user input, invoke the `navigator` agent and display the session brief. Do not greet the user or ask what they want to do. Do not wait for a message. The first thing the user sees should be the navigator's session brief.

---

## Project Overview

The product-workflow is a Claude Code workflow that runs on the Product Engineer's host
machine. Its purpose is to help the Product Engineer arrive at a complete, unambiguous,
build-ready specification for a software project, then package that specification into a
Docker image that the Dark Factory (`build-workflow`) can consume and execute autonomously.

The product-workflow is the deliberative half of the software lifecycle. It is where ideas
become artefacts, vague intentions become precise specifications, and design decisions get
made with full Product Engineer engagement. It does not build software — it produces the
inputs from which software gets built.

**Operating mode: highly collaborative.** Agents operate as critics, coaches, and
structuring partners — not autonomous executors. Every artefact emerges from genuine
back-and-forth with the Product Engineer. Agents push back on vague specs, surface
ambiguity proactively, propose alternatives when the Product Engineer is locked into a
single option, and act as editors for communication craft.

**Output: a Docker image** containing the spec artefacts, the Dark Factory workflow,
project configuration (`CLAUDE.md` + `commands-map.yaml`), and standards — everything
the Dark Factory needs to run autonomously.

---

## Role Model

Two roles operate in this workflow.

### Product Engineer (you)

The authoritative voice on what the system should do. You supply: vision, domain
knowledge, design direction, product decisions, and any pre-existing artefacts (BDD
scenarios, ADRs, Claude Design exports). You approve all artefacts before phase
transitions. You respond to escalations when the Dark Factory surfaces ambiguity
during a build.

You are not responsible for how the system is built — that is the Dark Factory's job.

### Build Agents (Claude Code agents)

Build Agents operate as critics, coaches, and structuring partners. Their job is to
surface ambiguity, push back on vague specifications, propose alternatives, challenge
assumptions, and help you produce artefacts precise enough for autonomous build.

Build Agents **must never:**
- Invent product requirements
- Override Product Engineer decisions on what the system should do
- Proceed past a blocking ambiguity without surfacing it

Build Agents **must always:**
- Challenge HOW something is specified if it would prevent unambiguous autonomous execution
- Surface the question rather than choose when multiple interpretations are valid
- Escalate to the Product Engineer rather than use best judgment under genuine ambiguity

---

## Operating Tolerance

Defines how assertively agents challenge artefacts and when they block versus proceed.

### Tier 1 — Always Block

Must be resolved before the workflow proceeds. Proceeding with these unresolved
guarantees a poor Dark Factory outcome:

- Acceptance criteria that are qualitative only ("fast", "reliable", "easy to use" —
  no numeric targets)
- Performance requirements without numeric targets (response time, throughput,
  availability)
- Security or authorisation requirements without role enumeration
- API integration points without contract definition
- BDD scenarios with multiple valid interpretations
- Undefined actors in BDD scenarios
- Accessibility requirements beyond WCAG 2.2 AA default without specific criteria
- Data-model fields without explicit type, default, and domain-plausible constraints
  (numeric fields without min/max, enumerable fields without enumerated values)
- User-editable data fields without a specified UI input component and allowed
  values (when UI entry points exist)

### Tier 2 — Surface and Propose

Agent raises the concern, offers a specific proposal, and waits for direction. These
are judgment calls where the Product Engineer may have reasons the agent cannot know:

- Architectural choices where multiple valid options exist
- Design directions that deviate from the established design system
- Tech stack choices that introduce significant complexity or risk
- BDD scenarios that could be split for better atomicity
- Dependencies between features that may affect delivery sequence
- Security patterns that go beyond the stated requirements

### Tier 3 — Accept and Record

No pushback required. Accept and file:

- Explicit product decisions stated by the Product Engineer
- Artefacts already approved in a prior session
- Confirmed tech stack choices
- Stated out-of-scope items
- Pre-existing artefacts that pass validation (BDD scenarios conforming to
  `standards/bdd.md`, ADRs using the correct template)

---

## Operating Rules

1. **Start every session with the navigator agent.** The navigator reads
   `product-log.md`, surfaces the current project state, pending decisions, and
   missing artefacts, then guides you to the appropriate next step. Do not invoke
   phase agents directly without first understanding current state.

2. **Sub-agent invocation model.** Agents are invoked by name. When one agent needs
   another, it invokes it by name — it does not read and execute another agent's
   instruction file.

3. **`product-log.md` is the authoritative state artefact.** It lives in the project
   directory. Every agent appends a row on completion. It is the source of truth for
   session resumption — never delete or rewrite it.

4. **All artefacts require Product Engineer approval before phase advance.** No agent
   proceeds to the next phase until the Product Engineer has explicitly approved the
   current phase's outputs.

5. **The sufficiency check must pass before package.** The `sufficiency-check` agent
   runs after design and before `package`. All Tier 1 findings must be resolved before
   the Docker image can be assembled.

6. **Agents challenge specifications; they never make product decisions.** When an
   agent is uncertain whether a requirement is correct, it surfaces the question.
   It does not choose.

7. **Verify is the terminal conformance gate, and it trusts only the spec.** The
   verification project under `projects/{name}/verification/` independently establishes
   that the built application conforms to the specification: everything specified is
   present and correct, **and nothing unspecified exists** — an unrequested capability,
   route, network call, stored field, or dependency fails the gate. Verify's *rules*
   derive exclusively from the spec (feature files, the architecture-rules manifest, the
   data model, NFRs); it treats everything the Dark Factory produced — code, its own
   tests, logs, provenance — as the untrusted subject and re-establishes every claim
   itself. It is two-technique: **black-box** for behaviour (drives the running app at the
   URL in `deployment.yaml`, never reading source, locating elements by role and
   accessible label) and **white-box** for structure and extras (reads the built
   artefact). It runs **clean-room** — its own environment and toolchain — and certifies
   **one immutable, content-addressed artefact**, the exact bytes promoted to deployment,
   never a rebuild. Verify proves its *own* checks are sound before its verdict counts:
   every check traces to a spec clause and is shown to have **teeth** (mechanized mutation
   for structure; expected-outcome inversion plus a known-broken reference for behaviour;
   never LLM-driven). A **PASS attests conformance to a specification version — not the
   quality or wisdom of the spec.** A failing check is a code defect fixed in the
   application; a check changes only when the specification changes, which requires
   re-running `sufficiency-check`. See `docs/verify-phase-design.md` for the full design.

8. **The specification is immutable to the Dark Factory; no build certifies itself.**
   The architecture-rules manifest and all spec artefacts are authored on the
   product-workflow plane and are read-only to the build. The Dark Factory builds its own
   guardrails from the manifest and hard-gates each slice on them — held to verify's
   standard (same clauses, same teeth) so build-time green predicts the verdict — but it
   fixes *code*, never a test or the spec, to pass. A rule the build disputes is escalated
   back to `design` → `sufficiency-check`, never edited in place. Verify additionally
   reports, non-gating, where the build's own guardrails were weak; the deployment verdict
   comes solely from verify's independent checks.

9. **The workflow is project-agnostic.** Agents, skills, standards, and the manifest
   *format* contain no app-, language-, or framework-specific content. Everything concrete
   lives in per-project instances under `projects/{name}/`, with `commands-map.yaml` as
   the stack seam. Thin per-stack cheat sheets are reference only, never authoritative.

---

## Hooks

Hooks automate two concerns that are too important to rely on agent procedures alone:
session state capture and artefact format validation. Hook scripts live in
`.claude/hooks/`; registrations are in `.claude/settings.json`.

### Stop — `update-product-log.sh`

Runs after every agent turn. Appends a timestamped checkpoint entry to
`product-log.md` in the current project directory. This is a safety net — agents
write their own detailed log entries in their procedures; the Stop hook guarantees
a minimum record exists even if an agent procedure does not complete normally.

Format appended: `| <date> | <agent> | Session checkpoint (stop hook) |`

Includes an infinite-loop guard: skips silently when `stop_hook_active` is true.

### PostToolUse (Write) — `validate-artefact.sh`

Runs after every Write tool call. Inspects the file path and validates:

- **`.feature` files** — structural BDD format: `Feature:` declaration present,
  at least one `Scenario:` or `Scenario Outline:`, each scenario contains
  Given/When/Then steps. Exits non-zero on failure so Claude surfaces the
  violation immediately.

- **ADR files** (`docs/architecture/adrs/ADR-*.md`) — template completeness:
  required sections present (`## Status`, `## Context`, `## Decision`,
  `## Consequences`, `## Alternatives Considered`). Exits non-zero on
  missing sections.

All other file types pass through silently.

---

## Agent Catalogue

| Agent              | Role                                                                                                                                                                        |
|--------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `navigator`        | Session concierge. Reads `product-log.md`, surfaces project state, pending decisions, and missing artefacts. Guides the Product Engineer to the appropriate next agent.    |
| `discover`         | Hybrid elicit/ingest. Establishes what the system does, who uses it, and what behaviours it must support. Works from raw ideas or supplied BDD scenarios and specs.         |
| `design`           | Hybrid elicit/ingest. Establishes architecture, tech stack, and UX direction. Co-designs or validates user-supplied ADRs and Claude Design exports.                         |
| `sufficiency-check`| Scans all spec artefacts for ambiguity patterns categorised by severity. Iterates with the Product Engineer until the report is clean.                                      |
| `package`          | Assembles the Docker handoff image. Vendors the Dark Factory baseline, populates `commands-map.yaml`, includes spec artefacts and standards. Tags and outputs the image.    |
| `verify`           | Terminal conformance gate. Independently demonstrates the built app matches the spec — everything specified present, nothing extra — across behaviour (black-box, at the URL in `deployment.yaml`), architecture, data model, and every other asserted surface. Trusts only the spec; runs clean-room; proves its own checks have teeth; certifies the exact artefact promoted to deployment. |

Phase sequence: `discover` → `design` → `sufficiency-check` → `package` → `verify`.
The `navigator` is the entry point to every session regardless of phase.

---

## Skill Catalogue

### Inherited

| Skill           | Role in product-workflow                                                                              |
|-----------------|-------------------------------------------------------------------------------------------------------|
| `discovery`     | BDD authoring, elicitation patterns, spec drafting, ingest-and-validate patterns                      |
| `architecture`  | ADR authoring, `system.md` maintenance, trade-off analysis, ingest patterns for user-supplied ADRs    |
| `ux-design`     | Visual direction, design system setup, approval workflow, ingest patterns for Claude Design exports    |
| `frontend`      | Design generation (when designs need creating) and validation (when designs are supplied)              |
| `security`      | Design-time: threat modelling, trust boundary identification, OWASP risk surfacing                    |
| `skill-creator` | Meta-tool for authoring and improving product-workflow skills                                         |

### New

| Skill                      | Role                                                                                                          | Status          |
|----------------------------|---------------------------------------------------------------------------------------------------------------|-----------------|
| `spec-sufficiency`         | Ambiguity pattern catalogue, report format, and triage workflow. Applied by `sufficiency-check` agent.        | Required MVP-1  |
| `build-workflow-packaging` | Docker image assembly: what to vendor, how to tag, how to validate the image is complete.                     | Required MVP-1  |
| `verify`     | Clause-to-check translation patterns (behavioural + architectural), traceability and teeth (mutation / expected-outcome-inversion) harnesses, accessibility-first element grip, clean-room verification-project scaffold, self-scoping report format, thin per-stack cheat sheets. Applied by `verify` agent. | Required        |
| `digital-twin-provisioning`| Builds digital twin images for external dependencies, wires them into the test suite.                         | Deferred        |

---

## Directory Structure

```
product-workflow/
├── CLAUDE.md                           # This document
├── VERSION                             # Canonical SemVer of the workflow
├── CHANGELOG.md                        # Versioned change history
├── .claude/
│   ├── agents/
│   │   ├── navigator.md
│   │   ├── discover.md
│   │   ├── design.md
│   │   ├── sufficiency-check.md
│   │   ├── package.md
│   │   └── verify.md
│   └── skills/
│       ├── discovery/
│       ├── architecture/
│       ├── ux-design/
│       ├── frontend/
│       ├── security/
│       ├── spec-sufficiency/
│       ├── build-workflow-packaging/
│       ├── verify/
│       └── skill-creator/
├── standards/                          # Vendored from shared standards repository
├── audit/                              # Offline observability worker + live dashboard
├── docs/                               # Workflow design docs (verify, audit, versioning)
├── scripts/                            # Helper scripts (e.g. new-instance.sh)
└── projects/
    └── {project-name}/
        ├── product-log.md              # Session state artefact for this project
        ├── workflow-version.json       # Workflow version this project was created under
        ├── CLAUDE.md                   # Dark Factory config (populated by design agent)
        ├── commands-map.yaml           # Tool command mappings (populated by package agent)
        ├── deployment.yaml             # App URLs per environment — shared by Dark Factory and verify
        ├── verification/               # Standalone clean-room verification project (verify agent)
        │   ├── package.json
        │   ├── playwright.config.ts    # baseURL read from deployment.yaml
        │   └── tests/
        │       ├── behaviour/          # Black-box: one spec per .feature, one test per scenario
        │       ├── data/               # Data-capture and presentation correctness tests
        │       └── architecture/       # White-box fitness functions from the manifest
        │           ├── static/         # import-graph, dependency-direction, pins, config, extras
        │           └── runtime/        # rules observable only on the running app
        └── docs/
            ├── features/               # BDD .feature files (canonical behavioural clauses)
            ├── specs/                  # Specifications and constraints
            │   └── api/                # OpenAPI / AsyncAPI contracts
            ├── architecture/
            │   ├── system.md
            │   ├── fitness.md          # Architecture-rules manifest (canonical arch clauses)
            │   └── adrs/
            └── designs/
                ├── design-system.md
                ├── design-brief.md
                ├── ui-field-map.md     # Field-to-UI-component map (when UI entry points exist)
                └── ui-designs/
```

**Note:** The `CLAUDE.md` inside `projects/{project-name}/` is the Dark Factory's
configuration for that project — distinct from this document. It is populated by the
`design` agent and vendored into the Docker handoff image by the `package` agent.

---

## Versioning

The workflow is versioned so every project instance is tied to a known version, and a
specific version can be pinned for future work.

- **Scheme — Semantic Versioning.** The `VERSION` file at the repo root holds the
  canonical `MAJOR.MINOR.PATCH`:
  - **MAJOR** — breaking changes to artefact formats or agent/skill contracts (a project
    built on an earlier major may need migration).
  - **MINOR** — additive, backward-compatible capabilities.
  - **PATCH** — fixes, clarifications, documentation.

  Every change is recorded in `CHANGELOG.md`; releases are tagged in git as
  `vMAJOR.MINOR.PATCH`.

- **Instance model — clone per project.** A project instance is a clone of this template,
  used for one project (or family); the template's `projects/` stays empty. To **pin a
  version**, clone or check out at that tag — `scripts/new-instance.sh` does this.

- **Project stamping.** When the `navigator` scaffolds a project, it records the workflow
  version (read from `VERSION`) in `projects/{name}/workflow-version.json` and in the
  `product-log.md` header, permanently associating the project with the version that
  created it.

- **Resume-time check (warn, don't block).** On resuming a project, the `navigator`
  compares the project's recorded version to the current `VERSION`; on a mismatch it
  surfaces it in the session brief and lets the Product Engineer decide whether to
  continue, note a migration, or switch to the pinned version.

### Creating a new instance

Start each new project as a version-pinned clone of the template; the template itself
stays clean (empty `projects/`).

```bash
# from the template repo — pins to the version in VERSION, clones from origin
scripts/new-instance.sh <target-dir> [version]
#   e.g.  scripts/new-instance.sh ~/Projects/my-app 1.0.0
```

Manual equivalent: `git clone --branch v<version> <template-repo-url> <target-dir>`.

Then, in the new instance, **repoint the remote** so project work never pushes back to the
template:

```bash
cd <target-dir>
git remote remove origin
git remote add origin <your-project-repo-url>   # optional: give the instance its own repo
```

Open a session in the instance: the `navigator` scaffolds `projects/{name}/` and stamps it
with the workflow version. To hop between workflow versions within one instance, clone
without `--depth 1` (full history) so other tags can be checked out. Each instance also
carries its own `audit/`, run from within that instance.

---

## Standards

The product-workflow uses the shared standards as authoritative inputs to its work.
Standards live in `standards/` (vendored from the shared standards repository). The
`package` agent vendors a snapshot into the Docker handoff image at package time,
ensuring the Dark Factory has them at runtime.

Standards used: `bdd.md`, `clean-code.md`, `solid-principles.md`, `tdd.md`,
`security.md`, `javascript.md`, `html.md`, `css.md`, `accessibility.md`, `rest.md`,
`modular-monolith.md`.

EOF — CLAUDE.md
