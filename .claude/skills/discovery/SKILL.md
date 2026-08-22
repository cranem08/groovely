---
name: discovery
description: >
  Applied expertise for requirements elicitation — turning ideas into BDD
  scenarios and technical specifications. Use when: (1) a user describes a
  project idea verbally and needs it structured into features and specs,
  (2) rough notes or documents need formalising into BDD scenarios,
  (3) a reference application or screenshot needs translating into
  requirements, (4) a technical specification needs corresponding BDD
  scenarios, (5) validating completeness of discovered requirements, or
  (6) drafting CLAUDE.md Section 1 (Project Overview) from discovered context.
---

# Discovery

Turn ideas, notes, reference applications, and technical specifications into
structured BDD scenarios and technical specs ready for planning.

## Core Principle

Discovery is **conversational and iterative**. The user's idea is the seed;
the AI proposes structure, and the user refines until satisfied. Nothing is
written to files until the user explicitly approves.

## Input Formats

Discovery handles four input types. Each requires a different elicitation
approach:

| Input Type | What the AI Receives | Elicitation Focus |
|-----------|---------------------|-------------------|
| Verbal description | Conversational description of an idea | Scope boundaries, actors, core behaviours |
| Rough notes | Unstructured text, bullet points, documents | Organisation, gap identification, prioritisation |
| Reference application | URL, screenshot, or description of existing app | Differentiation, scope selection, feature extraction |
| Technical specification | Structured requirements document | BDD scenario derivation, gap identification |

See `references/elicitation-patterns.md` for question frameworks per input type.

## Elicitation Workflow

### Step 1 — Understand the idea

Ask targeted questions to establish:

1. **Problem** — What problem does this solve? Who has this problem?
2. **Actors** — Who interacts with the system? (named roles, not "the user")
3. **Entry points** — How do actors interact? (UI, API, CLI, event, job)
4. **Core behaviours** — What are the 3-5 most important things it does?
5. **Boundaries** — What is explicitly out of scope?
6. **Constraints** — Performance, security, compliance, accessibility, platform

Do not ask all questions at once. Start with problem and actors; follow up
based on answers. Aim for 2-3 rounds of clarification maximum.

### Step 2 — Draft BDD scenarios

Following the strict BDD format defined in `docs/standards/bdd.md`:

- **Exactly one** Given, **one** When, **one** Then per scenario
- **AND is prohibited** — split into separate scenarios
- Given = pre-existing state (declarative)
- When = one user-initiated action at the boundary
- Then = one observable outcome

Group scenarios by feature file. Each feature file represents one cohesive
area of functionality.

See `references/feature-file-examples.md` for worked examples.

### Step 3 — Draft technical specs

For each feature area, draft a specification covering:

- Purpose and user value
- Functional requirements (what the system must do)
- Non-functional requirements (performance, security, accessibility)
- Constraints and assumptions
- Out of scope (explicit exclusions)

Use the template in `assets/spec-template.md`.

### Step 4 — Present and iterate

Present all drafted scenarios and specs to the user. Explicitly ask:

1. Are any features missing?
2. Are any features out of scope and should be removed?
3. Are the scenarios accurate? Do they describe the right behaviours?
4. Are the constraints complete?

Iterate on feedback. Each round should converge — fewer changes, not more.
If scope expands significantly, flag it and confirm the user intends to
expand.

### Step 5 — Write approved artefacts

Only after user approval:

1. Write `.feature` files to `docs/features/`
2. Write spec files to `docs/specs/`
3. Draft `CLAUDE.md` Section 1 (Project Overview)

Use the template in `assets/feature-template.md` for `.feature` file structure.

## Quality Checks

Before presenting drafts to the user, verify:

- [ ] Every scenario follows strict BDD (one Given/When/Then, no AND)
- [ ] Every scenario has a named actor (not "the system")
- [ ] Every Then describes an observable outcome
- [ ] No scenario contains implementation detail
- [ ] Feature files are grouped by cohesive functionality
- [ ] Specs cover NFRs where applicable (security, performance, accessibility)
- [ ] No invented requirements — everything traces to user input
- [ ] Domain vocabulary is consistent across all scenarios

## Anti-Patterns

- **Inventing requirements** — only structure what the user provides
- **Gold plating** — adding "nice to have" features the user didn't ask for
- **Technical scenarios** — "the database stores X" is not a user behaviour
- **Vague outcomes** — "the system works correctly" is not observable
- **Premature architecture** — "using microservices" is implementation, not a requirement
- **Scope creep without flagging** — always highlight when scope is expanding

