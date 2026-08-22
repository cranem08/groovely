# ADR Lifecycle: Status Transitions and Review Criteria

How ADRs move through their lifecycle and when to revisit them.

## Status Definitions

| Status | Meaning | Authority |
|---|---|---|
| Proposed | Under consideration, not yet authoritative | May be followed provisionally |
| Accepted | Approved and authoritative | Must be followed |
| Superseded | Replaced by a newer ADR | Must not be followed going forward |
| Deprecated | Historically true but no longer guides future work | Should not influence new decisions |

## Transitions

### Proposed → Accepted

A Proposed ADR becomes Accepted when:
- The decision has been reviewed
- Stakeholders have had opportunity to challenge it
- No blocking objections remain

Action: Update the Status field to "Accepted" and set the Date.

### Accepted → Superseded

An Accepted ADR becomes Superseded when:
- The original decision is no longer valid
- Assumptions have proven incorrect
- System direction has changed materially

**Rules:**
- Never edit the original ADR to change its decision
- Mark the old ADR as Superseded
- Add a link to the replacement ADR
- In the new ADR, explain why the previous decision changed

### Accepted → Deprecated

An Accepted ADR becomes Deprecated when:
- The decision remains historically true
- But it should no longer influence future design
- No direct replacement ADR is needed

Appropriate when:
- Technology has moved on
- Constraints no longer apply
- System context has fundamentally changed

### What Must NOT Happen

- Never silently change an Accepted ADR's decision
- Never delete ADRs (they are historical records)
- Never allow contradictory Accepted ADRs to coexist without resolution
- Never overload system.md with decision rationale that belongs in an ADR

## Review / Revisit Criteria

Every ADR should define triggers for revisiting. Common triggers:

- **Scale thresholds reached** — the chosen approach may not scale
- **Operational burden** — the decision creates unacceptable maintenance cost
- **New requirements** — business needs have changed
- **Dependency changes** — an external system changed its contract
- **Regulatory changes** — compliance requirements evolved
- **Evidence** — assumptions in the Rationale proved wrong
- **Time-based** — some decisions warrant periodic review (e.g., annually)

When a revisit trigger fires:
1. Re-read the original ADR's Context and Rationale
2. Assess whether the forces have changed
3. If the decision still holds → no action needed
4. If the decision needs changing → create a new ADR and Supersede the original

## Relationship to Other Artefacts

ADRs must align with:
- **BDD scenarios** (`docs/features/`) — decisions should not contradict specified behaviour
- **Technical specs** (`docs/specs/`) — specs implement what ADRs decide
- **system.md** — current intent should be consistent with Accepted ADRs

If an ADR conflicts with any of these:
1. Flag the inconsistency explicitly
2. Propose a resolution
3. Update the affected artefact(s)

## Numbering and Filing

- Location: `docs/architecture/adrs/`
- Format: `ADR-XXX-<kebab-case-title>.md`
- Numbers are sequential and never reused
- Examples:
  - `ADR-001-modular-monolith.md`
  - `ADR-007-use-postgresql-for-core-persistence.md`
