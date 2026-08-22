# BDD Scenario Format (Authoritative Standard)

This standard defines the **strict BDD format** used across the workflow.
All agents and skills that write, validate, or group BDD scenarios MUST
follow these rules.

## Format Rules

- **Exactly one** Given, **one** When, **one** Then per scenario
- **AND is prohibited** — if you want AND, split into multiple scenarios
- Given = pre-existing state (declarative, no actions)
- When = one user-initiated action at the system boundary
- Then = one observable outcome visible to the user or external consumer
- Scenarios describe **what happens**, never **how it is implemented**
- Use "the user" or named actors, not system-centric language
- Use only defined domain terms; flag undefined vocabulary

## Splitting a Scenario

When a scenario feels too large, apply one of these patterns:

1. **Multiple outcomes** → one scenario per outcome
2. **Multiple preconditions** → separate the state setup into distinct scenarios
   or use Background (one Given per scenario still)
3. **Multiple actions** → each action becomes its own scenario with its own
   outcome

## Given Rules

- Given contains state (declarative, not actions)
- Given uses domain language, not technical/database language
- Example: `Given the user has an active subscription` (not "database contains
  subscription record")

## When Rules

- When describes a user action at the boundary, not a system action
- When describes the triggering action, not an internal process
- Example: `When the user requests a password reset` (not "When system
  validates token")

## Then Rules

- Then describes an observable, user-visible outcome
- Then uses user-visible language, not technical endpoints
- Example: `Then the user is shown a confirmation message` (not "database
  record updated")

## Vocabulary Rules

- Use only defined domain terms (from glossary or spec)
- If a new term is needed, define it in the domain glossary first
- Use consistent naming: if one scenario says "order" don't use "purchase"
  elsewhere for the same concept
- Refer to "the user" or named actors, never "the system" or "the service"
