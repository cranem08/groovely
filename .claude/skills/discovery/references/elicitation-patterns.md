# Elicitation Patterns by Input Type

## Table of Contents

1. [Verbal Description](#verbal-description)
2. [Rough Notes](#rough-notes)
3. [Reference Application](#reference-application)
4. [Technical Specification](#technical-specification)
5. [Handling Ambiguity](#handling-ambiguity)

---

## Verbal Description

The user describes an idea conversationally. The goal is to extract structure
from unstructured speech.

### Round 1 — Scope and actors

- "Who is this for? Describe the main types of people who will use it."
- "What's the single most important thing it does for them?"
- "How do they interact with it — web browser, mobile app, API, command line?"
- "What should it explicitly NOT do?"

### Round 2 — Behaviours

- "Walk me through what [actor] does from start to finish for [core behaviour]."
- "What happens when things go wrong? (invalid input, permissions, edge cases)"
- "Are there any time-based or event-triggered behaviours? (notifications, scheduled jobs)"

### Round 3 — Constraints

- "Are there security requirements? (authentication, data protection, compliance)"
- "Performance expectations? (response time, concurrent users, data volume)"
- "Accessibility requirements? (WCAG level, assistive technology support)"
- "Any existing systems this must integrate with?"

### When to stop asking

Stop when you can confidently draft scenarios covering:
- All named actors and their primary journeys
- Happy path + main error cases for each behaviour
- Key non-functional constraints

---

## Rough Notes

The user provides unstructured text — bullet points, brainstorming notes,
meeting transcripts, or partial documents.

### Approach

1. **Categorise** — Sort items into: actors, behaviours, constraints, unknowns
2. **Identify gaps** — Which categories are underrepresented?
3. **Ask about gaps only** — Don't re-ask about well-covered areas
4. **Resolve contradictions** — Present conflicting items and ask which is correct

### Common gaps in rough notes

| Gap | Question |
|-----|----------|
| Missing actors | "These notes mention [behaviour] — who performs this?" |
| Missing outcomes | "What should happen after [action]?" |
| Missing constraints | "Are there security/performance requirements for [feature]?" |
| Missing boundaries | "Should [mentioned-but-unclear-item] be in scope?" |

---

## Reference Application

The user points to an existing application (URL, screenshot, or description)
as a reference for what they want to build.

### Approach

1. **Understand the reference** — What does the reference app do?
2. **Identify scope** — "Which parts of this do you want? All of it, or specific features?"
3. **Identify differentiation** — "What should be different from the reference?"
4. **Extract features** — List the observable behaviours in the reference
5. **Confirm scope** — Present the extracted features and ask which are in/out

### Key questions

- "Is this a clone of [reference], or inspired by it?"
- "Which specific features do you want to replicate?"
- "What would you change or improve?"
- "Who is your target user — same as [reference] or different?"

### Pitfall

Reference apps often have 10x more features than the user wants. Always
confirm scope before drafting scenarios for everything visible.

---

## Technical Specification

The user provides a structured requirements document, API contract, or
technical design.

### Approach

1. **Read thoroughly** — Identify all stated requirements
2. **Derive scenarios** — Map each requirement to one or more BDD scenarios
3. **Identify gaps** — What behaviours are implied but not stated?
4. **Validate** — Present derived scenarios and ask if they capture the intent

### Common gaps in technical specs

| Gap | Question |
|-----|----------|
| Missing error handling | "The spec describes [happy path] — what should happen on failure?" |
| Missing user context | "Who triggers [technical process]?" |
| Missing NFRs | "Are there performance/security requirements for [feature]?" |
| Implicit assumptions | "[Spec assumes X] — is this correct?" |

---

## Handling Ambiguity

When requirements are unclear or contradictory:

### Do

- Present the ambiguity explicitly: "I see two possible interpretations..."
- Offer concrete options: "Option A means X, Option B means Y"
- Ask a single focused question to resolve
- Record the resolution as an assumption in the spec

### Do not

- Silently pick one interpretation
- Ask open-ended "what do you mean?" questions
- Stack multiple ambiguities into one question
- Invent a resolution and move on

### Escalation

If the user cannot resolve an ambiguity:
- Record it as an open question in `docs/specs/`
- Mark affected scenarios as "pending clarification"
- Continue with unaffected requirements
- Flag that the plan agent will mark this as BLOCKED if unresolved
