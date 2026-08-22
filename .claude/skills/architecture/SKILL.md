---
name: architecture
description: >
  Applied expertise for architectural decision-making and cloud-native design.
  Use when: (1) deciding whether to create an ADR or update system.md,
  (2) writing or reviewing an Architectural Decision Record, (3) evaluating
  trade-offs between architectural alternatives, (4) checking 12-factor app
  compliance, (5) a change affects system boundaries, introduces dependencies,
  or constrains future options, or (6) documenting deviations from cloud-native
  principles.
---

# Architecture

Make and record architectural decisions using ADRs, maintain system intent in
system.md, and apply cloud-native principles where they serve the project.

## When to Create an ADR

Create an ADR when a decision:

- Changes system boundaries, architecture style, or major data flow
- Introduces an external dependency or integration contract
- Affects security, privacy, compliance, or auditability materially
- Affects operability (deployment, observability, resilience)
- Constrains future change (hard-to-reverse decisions)
- Introduces emerging paradigms (agentic AI, decentralisation, etc.)
- Creates non-trivial trade-offs that need to be remembered

**Do NOT create ADRs for:**
- Trivial, local, or easily reversible choices
- Implementation details that don't affect boundaries
- Naming conventions or code style decisions

**When unsure:** Default to creating an ADR. Keep it concise, mark it Proposed.

## system.md vs. ADR

The decision shortcut:

| Question | Action |
|---|---|
| "What do we currently believe?" | Update `system.md` |
| "Why did we choose this?" | Create an ADR |
| "Both?" | Do both |

**system.md** — use for living intent:
- Update it to reflect current truth, not historical decisions
- Change it frequently as understanding evolves
- Do not use it to preserve rationale or trade-off analysis

**ADRs** — use for decision history:
- Keep them additive and persistent (never edit to change decisions)
- Use them to preserve rationale and alternatives considered
- Expect them to outlive current intent

### Conflict Resolution

If `system.md` contradicts an Accepted ADR:
1. Flag the conflict explicitly
2. Propose a resolution
3. Create a new ADR if the decision has genuinely changed

See `references/adr-lifecycle.md` for status transitions and review criteria.

## ADR Structure

Every ADR follows the mandatory template in `assets/adr-template.md`.

**Key principles:**
- Decision-focused: what and why, not how
- Explicit about trade-offs and risks
- Concise and readable
- Consistent with BDD scenarios and system intent
- Free of implementation detail

**Numbering:** `ADR-XXX-<kebab-case-title>.md` in `docs/architecture/adrs/`

**Status lifecycle:** Proposed → Accepted → Superseded or Deprecated

### Trade-Off Analysis

When evaluating alternatives in an ADR:

1. List each realistic alternative (2-4 options)
2. For each alternative, state:
   - What it gives you (benefits)
   - What it costs (complexity, coupling, risk)
   - Why it was chosen or rejected
3. Keep each alternative to 1-3 bullets
4. Reference project constraints and standards where relevant

## 12-Factor App Compliance

The 12-factor principles apply to web applications, APIs, background workers,
serverless workloads, and containerised systems.

### The 12 Factors (Quick Reference)

1. **Codebase** — One repo, many deploys
2. **Dependencies** — Declare and isolate explicitly
3. **Config** — Store in environment, not code
4. **Backing Services** — Treat as attached resources (swappable)
5. **Build, Release, Run** — Strictly separate stages
6. **Processes** — Stateless, share-nothing
7. **Port Binding** — Self-contained, export via port
8. **Concurrency** — Scale via process model
9. **Disposability** — Fast startup, graceful shutdown
10. **Dev/Prod Parity** — Minimise environment differences
11. **Logs** — Event streams to stdout
12. **Admin Processes** — One-off tasks in same environment

### Modern Extensions

13. **Declarative Infrastructure** — Infrastructure as code, versioned
14. **Observable by Default** — Structured logs, metrics, health checks
15. **Secure by Default** — Secrets management, least privilege, no hardcoded
    credentials

### Applying 12-Factor During Implementation

**Check when:**
- Setting up a new project → verify all 12 factors are addressed
- Adding configuration → factor 3 (Config)
- Adding a backing service → factor 4 (Backing Services)
- Adding state to a process → factor 6 (Processes) — externalise it
- Adding logging → factor 11 (Logs) — stdout only
- Adding health checks → factor 14 (Observable)
- Introducing secrets → factor 15 (Secure by Default)

**When 12-factor doesn't apply:**
- Static sites with no server component
- Single-use scripts or tooling
- Embedded systems

Document deviations explicitly. State which factor is deviated from, why, and
what the trade-off is.

## Architectural Review During Slices

When implementing a slice that touches architecture:

1. Check if the change warrants an ADR (use the trigger list above)
2. If yes, write the ADR before or during implementation
3. Verify the change aligns with existing Accepted ADRs
4. Check relevant 12-factor compliance
5. Update system.md if current intent has changed
