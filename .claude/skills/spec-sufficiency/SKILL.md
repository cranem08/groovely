---
name: spec-sufficiency
description: >
  Codifies the ambiguity pattern catalogue, report format, and triage workflow
  for the sufficiency-check agent. Defines what constitutes an insufficiently
  specified artefact, how to classify findings by severity, how to present them
  to the Product Engineer, and what constitutes a resolved finding. Applied
  exclusively by the sufficiency-check agent.
---

# Skill: spec-sufficiency

## Purpose

A spec that passes structural quality gates (valid BDD format, complete ADR
templates, valid OpenAPI) can still contain scenarios that produce a build
reflecting the agent's interpretation rather than the Product Engineer's intent.
This skill codifies the patterns that distinguish a build-ready spec from one
that merely looks complete.

The core principle: **ambiguity in a spec becomes invention in a build.**
Every item in the pattern catalogue below is a place where an autonomous build
agent must choose an interpretation. This skill makes those choices visible
before the build starts.

---

## Ambiguity Pattern Catalogue

### Tier 1 — Blocking

These patterns must be resolved before a PASS verdict is possible. Each
represents a decision the Dark Factory cannot make without the Product
Engineer's input.

---

#### Pattern T1-1: Qualitative Acceptance Criteria

**Definition:** A Then step contains a qualitative adjective with no
measurable criterion. The step describes a property rather than an observable
outcome.

**Triggers:** fast, quickly, slow, performant, responsive, reliable, stable,
robust, seamless, smooth, easy, simple, intuitive, user-friendly, clean,
efficient, powerful.

**Bad examples:**
```gherkin
Then the page loads quickly
Then the search responds fast
Then the user experience feels smooth
Then errors are handled gracefully
```

**Good resolutions:**
```gherkin
Then the page loads within 1.5 seconds on a standard broadband connection
Then search results appear within 300ms of the user finishing typing
Then the interface transitions complete within 100ms
Then the error message is displayed within 500ms and the form remains editable
```

**Resolution guidance:** Ask for the numeric threshold. If the Product Engineer
does not know the exact number, help them derive it from user expectations or
comparable systems. A rough target is always better than no target — it can be
tuned post-MVP.

---

#### Pattern T1-2: Performance Without Targets

**Definition:** A spec document states a performance requirement without a
numeric SLA, throughput budget, or availability target.

**Triggers:** "the system should handle load", "scales to many users",
"high availability", "near real-time", "minimal latency", "low overhead".

**Bad examples:**
```markdown
The system must handle concurrent users without degradation.
The API should respond in near real-time.
The application must be highly available.
```

**Good resolutions:**
```markdown
The system must support 50 concurrent users with p95 response time under 500ms.
The API must respond within 200ms for 95% of requests under normal load.
The application must achieve 99.5% uptime, measured monthly.
```

**Resolution guidance:** Distinguish between load testing targets (concurrent
users, throughput) and latency targets (p50/p95/p99 response times). Availability
targets should specify the measurement window (monthly, weekly).

---

#### Pattern T1-3: Security Without Role Enumeration

**Definition:** A scenario or spec states an access control requirement without
naming the specific roles that are permitted or restricted.

**Triggers:** "only authorised users", "authenticated users can",
"admin access required", "secure endpoint", "protected resource",
"requires permission", "role-based access".

**Bad examples:**
```gherkin
Given an authorised user is logged in
When they access the admin panel
Then they can see all user accounts
```
```markdown
The API must require authentication for write operations.
```

**Good resolutions:**
```gherkin
Given a user with the "account-manager" role is authenticated
When they navigate to /admin/accounts
Then they see a paginated list of all user accounts
And users with the "viewer" role are redirected to /dashboard
```
```markdown
The API must require a valid JWT token for POST, PUT, and DELETE operations.
Tokens must include the "scope" claim with value "write". Read operations
(GET) are publicly accessible.
```

**Resolution guidance:** Pull the actor enumeration from the discover artefacts.
Every access control statement must reference a named actor or role defined there.
If roles haven't been enumerated, that's a discover gap — surface it and pause.

---

#### Pattern T1-4: Error Handling Without Policy

**Definition:** A scenario or spec acknowledges that errors can occur but does
not define the error taxonomy, user-facing copy, retry behaviour, or fallback.

**Triggers:** "errors are handled", "if an error occurs", "gracefully",
"appropriate error message", "handle failure", "on exception", "in case of error".

**Bad examples:**
```gherkin
When the form submission fails
Then an appropriate error message is shown
```
```markdown
The system must handle database connection errors gracefully.
```

**Good resolutions:**
```gherkin
When the form is submitted with a title that exceeds 200 characters
Then the title field is highlighted in red
And the message "Title must be 200 characters or fewer" is displayed below the field
And the form data is preserved so the user can correct it without re-entering

When the database is unavailable during a read operation
Then the user sees the message "We're having trouble loading your decisions.
Please try again in a moment."
And the application retries the connection twice before showing the message
```

**Resolution guidance:** For each error case, elicit four things: (1) what
triggers the error, (2) what the user sees (exact copy or copy guidelines),
(3) what state the application is in after the error, (4) whether and how
it retries. "Gracefully" is never sufficient.

---

#### Pattern T1-5: Integration Without Contract

**Definition:** A scenario involves calling an external API, service, or
system without a corresponding contract defining the request/response schema.

**Triggers:** Any When or Then step that implies interaction with an external
system (payment provider, email service, third-party API, external database)
without a corresponding file in `docs/specs/api/`.

**Bad examples:**
```gherkin
When the user submits their payment details
Then the payment is processed by the payment provider
And a confirmation email is sent
```
*(No PaymentProvider OpenAPI contract, no email service contract)*

**Good resolution:** Create the contract files:
- `docs/specs/api/payment-provider.yaml` — OpenAPI spec for the payment
  integration, even if just the relevant endpoints
- `docs/specs/api/email-service.yaml` — the send-email endpoint schema

Or, if the integration is out of scope for this build, move it to
`docs/specs/out-of-scope.md` and remove the scenario.

**Resolution guidance:** For each external integration, there are only two
valid states: contract defined, or explicitly out of scope. There is no
valid "we'll figure it out during build" state.

---

#### Pattern T1-6: Ambiguous Actor Reference

**Definition:** A scenario uses a generic actor reference when multiple actor
types are defined in the system, making it unclear which actor the scenario
applies to.

**Triggers:** "the user" (when multiple user types exist), "a user",
"an admin" (when admin roles are not enumerated), passive voice in When steps.

**Bad examples:**
```gherkin
Given a user is on the decisions list
When the user deletes a decision
Then the decision is removed from the list
```
*(Multiple actor types defined: "decision-owner", "viewer", "account-manager")*

**Good resolutions:**
```gherkin
Given a "decision-owner" is viewing their decisions list
When they delete the decision titled "Choose database"
Then the decision is removed from their list
And users with "viewer" access to that decision no longer see it
```

**Resolution guidance:** Every scenario's actors must be drawn from the actor
enumeration established in discover. Run a cross-check: for each scenario,
does the actor in the Given/When step match a named actor from `docs/features/`
or `docs/specs/`? If not, it's a T1-6 finding.

---

#### Pattern T1-7: Accessibility Beyond Default Without Criteria

**Definition:** A spec states an accessibility requirement that goes beyond
the WCAG 2.2 AA default without specifying the exact criteria.

**Triggers:** "fully accessible", "AAA compliant", "accessible to all users",
"meets accessibility standards", "screen reader friendly", "keyboard navigable"
(without specifying scope).

**Bad examples:**
```markdown
The application must be fully accessible to users with disabilities.
The dashboard must be screen reader friendly.
```

**Good resolutions:**
```markdown
The application must conform to WCAG 2.2 AA for all user-facing pages.
In addition, all data tables must include proper ARIA roles and column headers
for screen reader navigation (WCAG 2.2 AAA criterion 1.3.6).
All interactive elements must be operable via keyboard alone, with visible
focus indicators meeting a 3:1 contrast ratio against adjacent colours.
```

---

#### Pattern T1-8: Missing Canonical Artefact

**Definition:** A canonical artefact prescribed by the product-workflow
Directory Structure is absent from the project, and no deliberate waiver
is recorded. Unlike T1-1 through T1-7, this is detected by a **structural
existence check, not a content scan** — an artefact that is silently
missing causes the same class of autonomous-build failure as an ambiguous
one, because the Dark Factory has no input where it expects one.

**Authoritative list:** the product-workflow root `CLAUDE.md` →
"Directory Structure" section is the single source of truth. Do not
duplicate it; read it and apply it. The load-bearing required set:

- `docs/architecture/system.md` — the integrated whole-system view
  (distinct from the ADRs and from the project `CLAUDE.md`)
- At least one ADR in `docs/architecture/adrs/`
- At least one `.feature` file in `docs/features/`
- The three core specs: `docs/specs/data-model.md`,
  `docs/specs/non-functional.md`, `docs/specs/out-of-scope.md`
- Project `CLAUDE.md` populated (not a stub)
- When UI entry points exist: `docs/designs/design-brief.md` and
  `docs/designs/design-system.md`
- API/MCP contracts in `docs/specs/api/` or `docs/specs/mcp/` when the
  corresponding entry points exist

**Triggers:** any prescribed artefact above does not exist on disk, OR
exists but is an empty/placeholder stub.

**Why this is Tier 1:** a missing `system.md` (or any prescribed artefact)
will not surface as a content ambiguity — the scan of a non-existent file
yields nothing, so without this pattern the gap passes silently through
the one mandatory gate before `package`. The conflation that produces this
in practice is "the guidance was folded into another artefact (e.g. the
project `CLAUDE.md`), so the prescribed file is unnecessary" — folding
content elsewhere does NOT waive the prescribed artefact.

**Resolution:** produce the missing artefact (synthesis from already-approved
inputs where applicable — no new product decisions), OR record an explicit
**dated waiver with rationale** in `product-log.md` of the form:
`| {date} | {agent} | WAIVER: {artefact} intentionally omitted. Rationale: {why}. Approved by Product Engineer. |`
Silence is never a waiver. A waiver requires Product Engineer approval.

---

### Tier 2 — Advisory

These patterns are surfaced for the Product Engineer's awareness. They are not
blocking but represent areas where the spec could be more precise.

---

#### Pattern T2-1: Implicit Preconditions

**Definition:** A scenario assumes system state that is not established by
the Given steps or a Background block.

**Bad example:**
```gherkin
Scenario: Update a decision
  Given the user is on the edit decision page
  When they change the title to "New title"
  Then the decision is updated
```
*(Assumes a decision already exists — where did it come from?)*

**Recommendation:** Add a Background block or Given step that creates the
precondition, or reference a separate scenario that establishes it.

---

#### Pattern T2-2: Missing Error Paths

**Definition:** A feature file covers only the happy path for a create,
update, or delete operation with no error scenario.

**Recommendation:** Add at least one error-path scenario per core operation.
Common candidates: invalid input, not found, permission denied.

---

#### Pattern T2-3: Data Without Validation Rules

**Definition:** A scenario mentions "valid" input without defining what
valid means.

**Bad example:**
```gherkin
Given the user enters a valid title
```

**Recommendation:** Add a spec entry defining validation rules for the field
(max length, allowed characters, required/optional status).

---

#### Pattern T2-4: Single-Scenario Features

**Definition:** A feature file contains only one scenario, suggesting
error paths and edge cases may be missing.

**Recommendation:** Consider whether the feature needs error path coverage,
boundary condition scenarios, or actor-variation scenarios.

---

## Report Format

```
── Sufficiency Check Report ──────────────────────────────────────
Project:   {project-name}
Date:      {YYYY-MM-DD HH:MM}
Scan:      {N} feature files, {M} spec documents, {P} ADRs
Verdict:   FAIL | PASS

Tier 1 — Blocking  ({N} findings)
──────────────────────────────────
[1] {file-path} — {Scenario name or section heading}
    Text:     "{exact quoted text}"
    Pattern:  T1-{N}: {Pattern name}
    Needed:   {Specific information required to resolve}
    Status:   OPEN | RESOLVED | PENDING

[2] ...

Tier 2 — Advisory  ({M} findings)
──────────────────────────────────
[1] {file-path} — {location}
    Text:     "{exact quoted text}"
    Pattern:  T2-{N}: {Pattern name}
    Recommendation: {Suggested improvement}
    Status:   NOTED | RESOLVED

──────────────────────────────────────────────────────────────────
Tier 1 resolved: {N}/{total}
Verdict:         FAIL (unresolved Tier 1 findings remain)
                 PASS (all Tier 1 findings resolved)
──────────────────────────────────────────────────────────────────
```

### Verdict Rules

**PASS:** All Tier 1 findings have status RESOLVED. Tier 2 findings may
remain NOTED. The spec is build-ready.

**FAIL:** One or more Tier 1 findings have status OPEN or PENDING. Do not
issue a PASS verdict under any circumstance with open Tier 1 findings.

**PENDING status:** A Tier 1 finding is PENDING when the Product Engineer
cannot resolve it in the current session (e.g., they need to check with a
stakeholder, look up an SLA, or draft copy). Record it as PENDING, append
a FAIL sentinel to `product-log.md`, and stop. The sufficiency-check agent
re-ingests PENDING findings on next invocation.

---

## Triage Principles

**Work sequentially, not in bulk.** Present one finding at a time during
triage. Bulk presentation leads to shallow resolutions where the Product
Engineer approves a fix without fully understanding the implication.

**Quote exactly.** Always quote the exact phrase that triggered the finding.
Do not paraphrase. The Product Engineer must see the precise text to give
a precise fix.

**Propose a resolution draft.** Do not just describe the problem — offer a
concrete rewrite. The Product Engineer reacts faster to a draft than to an
abstract description of what's missing.

**Check the fix.** After applying a resolution, re-read the edited section
and confirm: (a) the Tier 1 finding is eliminated, (b) no new Tier 1
finding has been introduced by the fix.

**Accept PENDING gracefully.** If the Product Engineer cannot resolve a
finding in the session, mark it PENDING without judgement and move on.
A partial pass session is more useful than a stalled one.

---

## Clause Validation and the Consistency Gate

Alongside the ambiguity catalogue, the sufficiency check validates the machine-checkable
clause sets — the architecture-rules manifest (`docs/architecture/fitness.md`) and the
data-model and NFR clause sets — authored to `verify`'s
`references/manifest-format.md`. These clauses become the checks the `verify` agent and
the Dark Factory build, so a weak clause is as damaging as an ambiguous requirement.

For every clause, raise a **Tier 1** finding when any of these fail:

- **Missing part.** The clause lacks a full human **statement**, a **predicate**, or at
  least one **counter-example**. All three must travel together; a statement reduced to a
  bare ID or predicate is a finding in itself (shared readable context is required).
- **Unmachinable predicate.** The predicate is vague or qualitative ("cleanly layered",
  "reasonable", "fast") rather than a precise, checkable condition — the same defect as a
  qualitative acceptance criterion.
- **Hollow counter-example.** The counter-example does not actually violate the stated
  rule, so it could not prove the check has teeth downstream.
- **Unstable ID.** The ID is missing, duplicated, or reused for a changed meaning.

### Consistency gate

Wherever a rule is restated in prose (an ADR line, `system.md`, a design brief), the
restatement must carry its clause **ID** and **match** the canonical clause statement.
A divergence between a restatement and its clause is a **Tier 1** finding — this gate is
what makes the single-source-of-truth rule safe, letting rules read in full plain
language everywhere without drifting. Report clause and consistency findings in the same
report, under the same Tier discipline; all must be clean before PASS.

---

## Compounding Effect

The spec-sufficiency check has a compounding second-order benefit: each
finding surfaced is a piece of feedback about the Product Engineer's
communication craft. Patterns that recur across sessions (e.g., consistently
missing numeric criteria, consistently using passive voice in When steps)
reveal systematic gaps in how the Product Engineer writes specifications.

Over multiple projects, the frequency and type of Tier 1 findings should
decrease as the Product Engineer internalises the precision standards.
The verification workflow's results downstream will reflect this improvement.

EOF — Skill: spec-sufficiency
