---
name: ux-design
description: >
  Establishes design briefs, user journeys, flows, and personas that inform
  the frontend skill's artefact generation. Also covers API contract design
  (OpenAPI/AsyncAPI) and MCP server interface design. Use when: (1) gathering
  UI requirements and producing a design brief before invoking the frontend
  skill, (2) setting up or maintaining docs/designs/design-system.md (the
  human-readable design narrative), (3) designing API contracts
  (OpenAPI/AsyncAPI), (4) designing MCP server tool interfaces, or (5)
  recording design approval decisions.
---

# UX Design

Establishes the design context that drives UI artefact generation: user
personas, journeys, flows, and the design brief that the `frontend` skill
consumes to produce wireframes, high-fidelity designs, tokens, and component
designs. Also covers API contract design and MCP server interface design.

## Core Principle

Design before implementation. All design artefacts must be **approved by the
user** before implementation begins. Design decisions are documented and
traceable to slice plans.

## Design Types

| Type | Output Location | Format |
|------|----------------|--------|
| Design brief | `docs/designs/design-brief.md` | Structured markdown |
| Design system narrative | `docs/designs/design-system.md` | Human-readable markdown |
| UI artefacts (wireframes, hifi, tokens) | `docs/designs/ui-designs/` | Produced by `frontend` skill |
| API contracts | `docs/specs/api/` | OpenAPI/AsyncAPI specification |
| MCP server interfaces | `docs/specs/mcp/` | Tool/resource schema definition |

## Design System Files

Two files make up the design system. They are complementary, not competing:

**`docs/designs/design-system.md`** (this skill's output) — a human-readable
narrative capturing design intent, brand decisions, visual direction, usage
guidelines, and rationale. Produced and maintained by this skill.

**`docs/designs/ui-designs/tokens/design-system.json`** (the `frontend`
skill's output) — machine-usable structured tokens: colours, spacing,
typography, shadows, border-radius, breakpoints, and motion. The
implementation source of truth.

The markdown narrative informs the JSON tokens — the `frontend` skill reads
`design-system.md` as part of its design brief context and translates
relevant decisions into token values. **If the two files conflict, the JSON
takes precedence for implementation.** Discrepancies should be flagged and
`design-system.md` updated to match.

## UI Design Workflow

Two workflows depending on whether the project has existing UI.

### Existing UI — Iterate and Improve

1. **Analyse existing UI** — Read existing UI source code to understand
   current patterns, components, and styling approach.
   See `references/repo-analysis.md` for the analysis process.

2. **Establish design system** — Ensure `docs/designs/design-system.md`
   exists. If missing, extract from the codebase or create new.
   See `references/design-system-setup.md`.

3. **Gather requirements** — Ask the user what they want to change.
   Clarify: keep current style or create a new direction.

4. **Produce the design brief** — Write `docs/designs/design-brief.md`
   covering:
   - **User personas** — who uses this UI, their goals, and their context
   - **Key user journeys** — the end-to-end flows this change affects
   - **Flow diagrams** — text-based or simple ASCII flows for each journey
   - **Interaction requirements** — behaviours, states, transitions required
   - **Content hierarchy per screen** — what information appears, in what
     order, with what relative emphasis
   - **Constraints** — brand, accessibility, platform, existing design system
   - **Current state summary** — what the existing UI does and where it falls
     short relative to the new requirements

5. **Hand off to `frontend` skill** — The design brief is the input. The
   `frontend` skill produces all artefacts: wireframes, hifi designs, tokens,
   component designs, and design decisions documents.

6. **Write approval record** — Once the user approves the `frontend` skill
   output, write the approval decision to `docs/designs/S###-design.md`
   using the template in `assets/design-review-template.md`.

### Brand New Project — Design from Scratch

1. **Gather requirements** — Understand the product, target users, and
   visual direction from the user. Ask about:
   - Applications or sites they want to draw inspiration from
   - Colour preferences or brand identity
   - General feel (minimal, corporate, playful, technical)
   - Target platforms (desktop, mobile, both) and any accessibility
     requirements beyond WCAG AA

2. **Set up design system** — Create `docs/designs/design-system.md`
   based on the user's visual direction.
   See `references/design-system-setup.md`.

3. **Produce the design brief** — Write `docs/designs/design-brief.md`
   covering:
   - **User personas** — who uses this product, their goals, technical
     comfort level, and usage context
   - **Key user journeys** — the primary end-to-end flows across the
     product (not just the current slice — the full picture)
   - **Flow diagrams** — text-based or simple ASCII flows for each journey,
     showing decision points and alternate paths
   - **Interaction requirements** — behaviours, states, and transitions
     required for each key screen
   - **Content hierarchy per screen** — what information appears on each
     screen, in what order, with what relative emphasis
   - **Constraints** — brand identity, accessibility requirements, target
     platform conventions, performance constraints (e.g. avoid heavy
     animations on low-end devices)

4. **Hand off to `frontend` skill** — The design brief and
   `docs/designs/design-system.md` are the inputs. The `frontend` skill
   produces all artefacts: wireframes, hifi designs, design tokens
   (`design-system.json`), component designs, and design decisions documents.

5. **Write approval record** — Once the user approves the `frontend` skill
   output, write the approval decision to `docs/designs/S###-design.md`
   using the template in `assets/design-review-template.md`.

## Design System Fidelity

`docs/designs/design-system.md` is a **hard constraint** on the design brief
and on all `frontend` skill outputs:

- The design brief must not propose visual directions that contradict the
  established design system without flagging the deviation explicitly
- The `frontend` skill uses `design-system.md` as a constraint when
  generating `design-system.json` tokens — deviations require user approval
- Iteration on visual style requires updating `docs/designs/design-system.md`
  first, then regenerating affected tokens in `design-system.json`
- Layout, structure, and content hierarchy can iterate freely within the
  design brief without triggering a design system update

## API Contract Design

For slices with API entry points:

1. **Identify endpoints** — Extract from slice plan Entry Point and scenarios
2. **Define schema** — Request/response schemas with types
3. **Document constraints** — Authentication, rate limits, pagination
4. **Write contract** — OpenAPI 3.x or AsyncAPI format in `docs/specs/api/`
5. **Present for approval** — User must approve before implementation

Per `docs/standards/rest.md` for RESTful API design rules.

## MCP Server Interface Design

For slices building MCP server tools or resources:

1. **Identify tools/resources** — Extract from slice plan scenarios
2. **Define input schemas** — JSON Schema for tool parameters
3. **Define output format** — Expected response structure
4. **Document capabilities** — What each tool does, constraints, error cases
5. **Write interface spec** — In `docs/specs/mcp/`
6. **Present for approval** — User must approve before implementation

## Design Approval Gate

Designs are approved or rejected before implementation proceeds:

| Verdict | Criteria |
|---------|----------|
| **PASS** | Meets requirements, accessible, consistent with design system |
| **FAIL** | Missing requirements, accessibility issues, design system violations |

Use the template in `assets/design-review-template.md` for the approval record.

## Severity Classification

Refer to the `frontend` skill for design output severity classification.
The `frontend` skill owns the authoritative severity table covering Critical,
High, Medium, and Low issues in generated design artefacts.
