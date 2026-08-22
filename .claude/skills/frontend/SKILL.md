---
name: frontend
description: Generate professional-grade UI designs with best-practice heuristics. Produces wireframes, high-fidelity designs, design tokens, and component designs in the project's actual tech stack. Outputs to ./docs/designs/ui-designs/.
allowed-tools: Task, Write, Edit, Read, Bash, Glob
---

# Frontend Design Skill

Generate professional, heuristic-grounded UI designs that directly inform
implementation. Every design output is grounded in the project's actual tech
stack, satisfies the relevant slice's acceptance criteria, and is persisted
in a structured output tree under `./docs/designs/ui-designs/`.

---

## 1. Output Structure

All design artefacts are written under `./docs/designs/ui-designs/`. Create subdirectories
as needed before writing any file.

```
./docs/designs/ui-designs/
  wireframes/          # Low-fidelity Balsamiq-style layout sketches
  hifi/                # High-fidelity designs (pixel-precise, production-ready)
  components/          # Isolated component designs
  tokens/
    design-system.json # Structured design tokens (see Section 4)
  decisions/           # Per-design rationale notes (design-decisions.md)
```

**Versioning convention:** `{design_name}_v{n}.{ext}`

Examples: `login_v1.html`, `dashboard_v2.jsx`, `card_v1.html`

Increment `n` on each iteration. Never overwrite an existing version — always
write a new file. This creates a legible revision history.

---

## 2. Tech Stack Detection

Before writing any design output, determine the project's tech stack. The
design output format must match.

### Detection order

1. Read `commands-map.yaml` at the project root — check `context.*` fields
   for declared framework, component library, and CSS approach.
2. If not present, read `CLAUDE.md` Section 3 (Tech Stack) for declared
   frontend framework and component library.
3. If neither is available, apply Glob patterns to detect:
   - `package.json` → check dependencies for React, Vue, Svelte, etc.
   - `*.config.{js,ts}` → detect Vite, Next.js, Nuxt, SvelteKit, etc.
   - Existing source files in `src/` for framework conventions.

### Output format by stack

| Detected stack | Design output format |
|---|---|
| React (no component lib) | `.jsx` — functional components with inline `style` objects or CSS Modules |
| React + shadcn/ui | `.jsx` — using shadcn primitives (`Button`, `Card`, `Input`, etc.) |
| React + MUI | `.jsx` — using MUI components and `sx` prop or `styled()` |
| React + Tailwind CSS (project-installed, not CDN) | `.jsx` with Tailwind utility classes |
| Vue 3 | `.vue` — single-file components |
| Svelte | `.svelte` — single-file components |
| Plain HTML/CSS (no framework detected) | `.html` with `<style>` block using CSS custom properties |
| Unknown / ambiguous | Semantic HTML + CSS custom properties (see Section 3.1) |

**Never** load Tailwind CSS via CDN. If Tailwind is used, it must be the
project-installed version, and class names must reflect the project's actual
config. If the Tailwind config is unavailable, default to CSS custom
properties.

### CSS approach by stack

- If the project uses CSS Modules: import `./ComponentName.module.css`
- If the project uses styled-components or Emotion: use `styled.*` wrappers
- If CSS custom properties are available: reference `var(--token-name)` from
  `design-system.json` tokens
- Default: `<style>` block with CSS custom properties referencing token values

---

## 3. Design Heuristics (Non-Negotiable)

Every design output must demonstrate application of these principles. They are
not aspirational — they are required. The `design-decisions.md` note must
reference which heuristics governed each significant decision.

### 3.1 Nielsen's 10 Usability Heuristics

Apply all 10 at every design stage. The most common failure points are noted.

1. **Visibility of system status** — Users must always know what is happening.
   Every action that takes time must show a loading state. Every state change
   must be communicated (progress indicators, status labels, toasts, badges).

2. **Match between system and real world** — Use vocabulary, icons, and
   metaphors from the user's domain. Avoid technical jargon in UI copy. Labels
   should name the thing, not describe the implementation.

3. **User control and freedom** — Every destructive or irreversible action
   needs an undo, cancel, or confirmation step. Never trap users in a flow
   without an exit.

4. **Consistency and standards** — Use the same label, icon, colour, and
   interaction pattern for the same concept everywhere. Follow platform
   conventions unless there is a compelling reason to deviate — and document
   the deviation.

5. **Error prevention** — Design to make errors impossible before they happen.
   Disable invalid actions. Validate inline. Confirm before destructive
   operations. Prefer constraints over warnings.

6. **Recognition over recall** — Surface relevant options, actions, and data
   in context. Minimise the information users must hold in memory. Use
   progressive disclosure to show complexity only when needed.

7. **Flexibility and efficiency of use** — Provide shortcuts for expert users
   (keyboard shortcuts, bulk actions, recently used items) without cluttering
   the interface for novices. Personalisation and history are forms of this.

8. **Aesthetic and minimalist design** — Every element on screen competes for
   attention. Remove elements that do not serve the user's goal. White space
   is intentional, not empty. Decorative elements must earn their place.

9. **Help users recognise, diagnose, and recover from errors** — Error messages
   must: name the problem in plain language, explain why it happened (if
   helpful), and offer a concrete next step. "Something went wrong" is not an
   error message.

10. **Help and documentation** — Where complexity is unavoidable, provide
    contextual help (tooltips, inline hints, progressive disclosure) rather
    than relying on separate documentation.

### 3.2 Gestalt Principles (Applied to Layout)

Use Gestalt principles as the primary framework for spatial decisions.

- **Proximity** — Elements that belong together must be visually grouped.
  Related labels and inputs share a parent container. Unrelated sections have
  clear separation. Never let proximity be accidental.

- **Similarity** — Elements that behave the same must look the same. All
  primary buttons share one visual treatment. All destructive actions share
  another. Breaking similarity must be intentional and consistent.

- **Continuity** — Align elements along implied lines. Use a grid. The eye
  follows alignment; misaligned elements feel broken, not creative.

- **Closure** — Users will complete incomplete shapes. Use this to reduce
  visual noise (e.g., cards without borders can still feel bounded if
  background contrast and spacing are correct).

- **Figure/Ground** — Every interactive element needs sufficient contrast
  from its background to be perceived as a distinct affordance. Flat design
  that loses figure/ground clarity is inaccessible design.

### 3.3 WCAG 2.2 AA (Minimum Baseline)

Every design output must meet these requirements. They are not optional.

**Colour contrast:**
- Normal text (< 18pt / < 14pt bold): minimum 4.5:1 contrast ratio
- Large text (≥ 18pt / ≥ 14pt bold): minimum 3:1 contrast ratio
- UI components and graphical objects: minimum 3:1 against adjacent colours
- Do not rely on colour alone to convey meaning — always pair with text, icon,
  or pattern

**Touch and click targets:**
- Minimum target size: 44×44px (WCAG 2.5.5 AAA is 44px; AA is 24px minimum
  with sufficient spacing — design to 44px as a practical baseline)
- Sufficient spacing between adjacent targets to prevent mis-taps

**Focus states:**
- Every interactive element must have a visible focus indicator
- Focus indicator must have at least 3:1 contrast against adjacent colours
- Never remove focus outlines without providing an explicit replacement
- Focus order must follow logical reading order (left-to-right, top-to-bottom
  for LTR layouts)

**Motion:**
- Respect `prefers-reduced-motion` — provide reduced-motion variants for
  any animation or transition in the design

**Text:**
- Body text minimum 16px equivalent (1rem)
- Text must remain readable at 200% browser zoom
- Line height: minimum 1.5 for body text

**Forms:**
- Every form control has an associated visible label
- Error states must be communicated with text, not colour alone
- Required fields are clearly indicated

---

## 4. Design Tokens (`design-system.json`)

Every project must have a `./docs/designs/ui-designs/tokens/design-system.json`. Generate it
during the first design pass and update it as the system evolves.

### 4.1 Token structure

```json
{
  "meta": {
    "version": "1.0.0",
    "generated": "YYYY-MM-DD",
    "stack": "react | html | vue | svelte",
    "theme": "light | dark | both"
  },
  "colour": {
    "brand": {
      "primary": "#------",
      "primary-hover": "#------",
      "primary-active": "#------",
      "secondary": "#------",
      "accent": "#------"
    },
    "semantic": {
      "success": "#------",
      "success-subtle": "#------",
      "warning": "#------",
      "warning-subtle": "#------",
      "error": "#------",
      "error-subtle": "#------",
      "info": "#------",
      "info-subtle": "#------"
    },
    "neutral": {
      "0":   "#ffffff",
      "50":  "#------",
      "100": "#------",
      "200": "#------",
      "300": "#------",
      "400": "#------",
      "500": "#------",
      "600": "#------",
      "700": "#------",
      "800": "#------",
      "900": "#------",
      "950": "#------",
      "1000": "#000000"
    },
    "surface": {
      "background": "var(--colour-neutral-0)",
      "surface-1": "var(--colour-neutral-50)",
      "surface-2": "var(--colour-neutral-100)",
      "border": "var(--colour-neutral-200)",
      "border-strong": "var(--colour-neutral-400)"
    },
    "text": {
      "primary": "var(--colour-neutral-900)",
      "secondary": "var(--colour-neutral-600)",
      "disabled": "var(--colour-neutral-400)",
      "inverse": "var(--colour-neutral-0)",
      "on-brand": "var(--colour-neutral-0)"
    }
  },
  "spacing": {
    "comment": "4pt base grid. All values are multiples of 4px.",
    "1": "4px",
    "2": "8px",
    "3": "12px",
    "4": "16px",
    "5": "20px",
    "6": "24px",
    "8": "32px",
    "10": "40px",
    "12": "48px",
    "16": "64px",
    "20": "80px",
    "24": "96px",
    "32": "128px"
  },
  "typography": {
    "comment": "Minimum 3 levels, at least 6–8px difference between adjacent levels.",
    "font-family": {
      "sans": "'Inter', 'Helvetica Neue', Arial, sans-serif",
      "mono": "'JetBrains Mono', 'Fira Code', monospace"
    },
    "scale": {
      "display":    { "size": "48px", "line-height": "1.2", "weight": "700", "tracking": "-0.02em" },
      "heading-1":  { "size": "36px", "line-height": "1.25", "weight": "700", "tracking": "-0.01em" },
      "heading-2":  { "size": "28px", "line-height": "1.3",  "weight": "600", "tracking": "-0.01em" },
      "heading-3":  { "size": "22px", "line-height": "1.35", "weight": "600", "tracking": "0" },
      "heading-4":  { "size": "18px", "line-height": "1.4",  "weight": "600", "tracking": "0" },
      "body-lg":    { "size": "18px", "line-height": "1.6",  "weight": "400", "tracking": "0" },
      "body":       { "size": "16px", "line-height": "1.6",  "weight": "400", "tracking": "0" },
      "body-sm":    { "size": "14px", "line-height": "1.5",  "weight": "400", "tracking": "0.01em" },
      "label":      { "size": "14px", "line-height": "1.4",  "weight": "500", "tracking": "0.02em" },
      "caption":    { "size": "12px", "line-height": "1.4",  "weight": "400", "tracking": "0.03em" },
      "code":       { "size": "14px", "line-height": "1.6",  "weight": "400", "tracking": "0" }
    }
  },
  "shadow": {
    "sm":  "0 1px 2px 0 rgba(0,0,0,0.05)",
    "md":  "0 4px 6px -1px rgba(0,0,0,0.1), 0 2px 4px -1px rgba(0,0,0,0.06)",
    "lg":  "0 10px 15px -3px rgba(0,0,0,0.1), 0 4px 6px -2px rgba(0,0,0,0.05)",
    "xl":  "0 20px 25px -5px rgba(0,0,0,0.1), 0 10px 10px -5px rgba(0,0,0,0.04)",
    "inner": "inset 0 2px 4px 0 rgba(0,0,0,0.06)"
  },
  "border-radius": {
    "none": "0",
    "sm":   "4px",
    "md":   "8px",
    "lg":   "12px",
    "xl":   "16px",
    "full": "9999px"
  },
  "breakpoints": {
    "comment": "Mobile-first. Design at sm, enhance at md and lg.",
    "sm":  "640px",
    "md":  "768px",
    "lg":  "1024px",
    "xl":  "1280px",
    "2xl": "1536px"
  },
  "motion": {
    "duration-fast":   "100ms",
    "duration-base":   "200ms",
    "duration-slow":   "300ms",
    "easing-default":  "cubic-bezier(0.4, 0, 0.2, 1)",
    "easing-in":       "cubic-bezier(0.4, 0, 1, 1)",
    "easing-out":      "cubic-bezier(0, 0, 0.2, 1)"
  }
}
```

### 4.2 Token usage in designs

- In plain HTML designs: declare all tokens as CSS custom properties in `:root`
  at the top of the `<style>` block: `--colour-brand-primary: #3b82f6;`
- In React with CSS Modules: import the design-system.json and reference
  token values by key
- In React with Tailwind: respect the project's `tailwind.config.js` — do
  not invent utility classes that don't exist in the config
- In React with shadcn/ui: map tokens to shadcn's CSS variable convention
  (`--primary`, `--secondary`, etc.) in the design's style block

---

## 5. Spacing System

Use a strict **4pt base grid**. Every margin, padding, gap, and size value
must be a multiple of 4px. Use 8px multiples as the primary rhythm.

```
4px   — micro spacing (icon gap, badge padding)
8px   — tight spacing (input padding, small gaps)
12px  — small spacing (label-to-input, icon-to-label)
16px  — base spacing (card padding, list item padding)
24px  — comfortable spacing (section internal padding)
32px  — section gap (between distinct UI groups)
48px  — page section gap
64px+ — layout-level separation
```

**Never** use arbitrary values like 7px, 13px, or 22px. If a design feels
cramped or loose with on-grid values, adjust the design — not the grid.

---

## 6. Colour System

Every design must use a complete colour system. "Only black and white" is
not a colour system — it is an incomplete design.

A complete system has four layers:

1. **Brand palette** — primary, secondary, accent (minimum). These define the
   product's visual identity. Choose values with sufficient contrast headroom
   to support accessible text on both light and dark backgrounds.

2. **Semantic colours** — success, warning, error, info. Each has a strong
   value (for icons, borders, text) and a subtle value (for backgrounds,
   fill areas). These must never be arbitrary — every semantic colour maps
   to a user-facing meaning.

3. **Neutrals** — a full greyscale ramp (0–1000 as in the token schema).
   Used for text, borders, surfaces, and backgrounds. Neutral-900 on
   neutral-0 is always the base text/background pair.

4. **Surface tokens** — semantic aliases over neutrals: `background`,
   `surface-1`, `surface-2`, `border`, `border-strong`. These decouple
   the design from specific neutral values and make dark mode trivial.

**Colour do's:**
- Use brand colour for primary actions, active states, and key affordances
- Use semantic colours to communicate status and outcomes
- Use neutral ramp for all structural UI (borders, backgrounds, secondary text)
- Ensure every text/background combination meets WCAG AA contrast

**Colour don'ts:**
- Do not use brand colour for destructive actions — use error semantic
- Do not use colour as the only differentiator between states
- Do not invent arbitrary colours outside the token system
- Do not use saturated colours for large background areas

---

## 7. Typographic Hierarchy

Every design must have a minimum of three typographic levels, with at least
6–8px of size difference between adjacent levels.

**Minimum required levels:**
- **Level 1 (heading)** — page title, section title, card heading
- **Level 2 (subheading / label)** — subsection, form label, list item title
- **Level 3 (body)** — body text, descriptions, supporting copy

**Hierarchy rules:**
- Weight (bold/medium/regular) reinforces but does not replace size hierarchy
- Line height must increase as font size decreases (smaller text needs more
  breathing room relative to its size)
- Tracking (letter-spacing) can be used on labels and captions to improve
  legibility at small sizes
- Do not use more than two font families in a single design

**Common hierarchy failure modes to avoid:**
- All text at the same weight, differentiated only by size
- Heading sizes too close together (< 4px apart)
- Body text below 14px
- Insufficient contrast between body text and secondary text levels

---

## 8. Component-Based Thinking

Every design is a composition of reusable primitives. Before designing a new
pattern, ask: "Can this be built from existing components?"

**Primitive layer** (smallest, most reusable):
- Button (primary, secondary, tertiary, destructive, icon)
- Input (text, password, email, number, select, checkbox, radio, toggle)
- Badge / Tag / Chip
- Avatar
- Icon (used consistently — pick one icon library and stick to it)
- Tooltip

**Composite layer** (assembled from primitives):
- Form (fieldset of inputs with validation states)
- Card (surface + padding + optional header/footer)
- Modal / Dialog (overlay + card + focus trap)
- Dropdown / Menu
- Navigation (top nav, sidebar, breadcrumb)
- Table (header, rows, pagination)
- Alert / Toast (semantic colour + icon + message)

**Layout layer** (positioning and structure):
- Page shell (header, main, sidebar, footer regions)
- Grid (responsive column grid)
- Stack (vertical rhythm)
- Cluster (horizontal grouping with wrap)

When designing a new feature, identify which components are needed and ensure
they are consistent with any existing components in `./docs/designs/ui-designs/components/`.
If a net-new component pattern is needed, add it to `./docs/designs/ui-designs/components/`
as an isolated design before embedding it in the feature design.

---

## 9. Slice Context Integration

When a slice context is available, the design must be grounded in it.

### 9.1 Pre-design reading

Before producing any design output:

1. Read the relevant slice plan at `docs/build/slices/S###.md`
2. Extract:
   - **Entry Point** — what triggers this UI? (user action, route, event)
   - **Observable Outcome** — what does the user see when it succeeds?
   - **BDD Scenarios** — the acceptance criteria the design must satisfy
   - **Constraints** — security, performance, accessibility, business rules
3. Read referenced feature files in `docs/features/`
4. Read any existing designs in `./docs/designs/ui-designs/` for continuity

The design must make every BDD scenario achievable. If a scenario describes
a state the design does not accommodate, that is a design gap — resolve it
before writing the output.

### 9.2 Mapping scenarios to design states

For each scenario, identify the corresponding UI state:

| BDD pattern | Design state to include |
|---|---|
| `Given [user is on X page]` | Entry state / initial render |
| `When [user submits form]` | Loading / in-progress state |
| `Then [user sees success message]` | Success state with semantic colour + message |
| `Then [user sees error]` | Error state with inline validation or toast |
| `Given [user has no items]` | Empty state |
| `When [user has many items]` | Populated state (with realistic data) |

Every identified state must appear as a distinct section or variant in the
design output.

---

## 10. Design Workflow

### 10.1 Wireframe first

Before producing high-fidelity designs, produce a low-fidelity wireframe that
establishes layout and information hierarchy without visual embellishment.

Wireframe requirements:
- Greyscale only — no brand colours
- Placeholder content with realistic labels (not "Lorem ipsum" unless
  content strategy is undefined — use representative copy)
- Show all key states: default, loading, error, empty, success
- Annotate layout decisions that reference Gestalt principles
- Use ASCII-art box notation or simple HTML with grey boxes if writing to
  a file

Wireframe output format: `.html` with minimal styling (grey boxes, black
text, no decoration), saved to `./docs/designs/ui-designs/wireframes/`.

Example wireframe HTML structure:

```html
<!-- ./docs/designs/ui-designs/wireframes/login_v1.html -->
<!--
  WIREFRAME: Login Form
  Slice: S001 — User Authentication
  Heuristics applied:
  - Recognition over recall: email pre-filled from URL param if available
  - Error prevention: submit disabled until both fields populated
  - User control: "Forgot password" link present
-->
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>Wireframe: Login — v1</title>
  <style>
    /* Wireframe styles only — not production CSS */
    ...
  </style>
</head>
<body>
  ...
</body>
</html>
```

### 10.2 Three-variant iteration

Unless the user asks for a single version, generate **three parallel design
variants** using sub-agents. Each variant explores a different design
direction while satisfying the same acceptance criteria.

Spawn three Task sub-agents concurrently:

```
Task A: Conservative — closest to platform conventions, lowest learning curve
Task B: Balanced — moderate visual identity, clear hierarchy
Task C: Expressive — stronger brand presence, more distinctive layout
```

Each sub-agent receives the same slice context, token system, and acceptance
criteria. Each writes its output to a separate versioned file:

```
./docs/designs/ui-designs/hifi/login_v1a.html   (or .jsx / .vue / .svelte)
./docs/designs/ui-designs/hifi/login_v1b.html
./docs/designs/ui-designs/hifi/login_v1c.html
```

After all three are written, summarise the differences and ask the user to
select a direction or describe a blend. On the next iteration, write
`login_v2.{ext}` incorporating the selected direction.

### 10.3 High-fidelity design requirements

Every high-fidelity design output must include:

- All design tokens referenced from `design-system.json` (via CSS custom
  properties or framework-appropriate mechanism)
- All states identified in the slice context (Section 9.2)
- Correct typographic hierarchy (minimum 3 levels)
- Professional colour system (brand + semantic + neutrals)
- 4pt/8pt spacing grid applied to all spacing values
- Accessible contrast ratios for all text/background pairs
- Focus states for all interactive elements
- Touch targets ≥ 44×44px for all interactive elements
- Responsive behaviour described (or demonstrated) for at least sm and lg
  breakpoints

### 10.4 Component isolation

If a design introduces a new reusable component pattern, also write it as an
isolated component design to `./docs/designs/ui-designs/components/`:

- Single component in isolation (no page chrome)
- Show all variant states: default, hover, focus, active, disabled, error
- Include annotations for spacing, typography, and colour tokens used

---

## 11. Design Decisions Document

Every design file must have a corresponding `design-decisions.md` note.

File location: `./docs/designs/ui-designs/decisions/{design_name}_v{n}-decisions.md`

Required sections:

```markdown
# Design Decisions: {Design Name} v{n}

## Slice context
- Slice: S### — {slice title}
- Scenarios addressed: {list scenario titles}

## Heuristics applied
{For each significant decision, name the heuristic and describe its application.}

Example:
- **Heuristic 8 — Aesthetic and minimalist design:** The form is presented
  without a sidebar navigation to reduce distraction during authentication.
  The single-column layout eliminates ambiguity about primary action.

## Colour rationale
{Describe the colour decisions: why these brand colours, why these semantic
colour pairings, what contrast ratios were verified.}

## Spacing decisions
{Describe the spatial rhythm: which spacing tokens were used for which
regions and why.}

## Typography decisions
{Describe the typographic hierarchy: which scale levels were used, how
hierarchy is established for the primary reading path.}

## Acceptance criteria mapping
| Scenario | Design state | Location in file |
|---|---|---|
| Given user is on login page | Default form state | Lines ~40–80 |
| When user submits with empty fields | Inline validation errors | Lines ~120–150 |
| Then user sees welcome message | Post-auth redirect notice | Lines ~180–200 |

## Open questions / deferred decisions
{Anything that could not be resolved and needs user input or a future
iteration.}
```

---

## 12. Accessibility in Design Output

The following accessibility requirements apply at the design-output level —
they must be present in the generated code, not just implied.

**Semantic structure:**
- Use semantic HTML elements for their intended purpose: `<nav>`, `<main>`,
  `<header>`, `<footer>`, `<section>`, `<article>`, `<button>`, `<a>`
- Heading levels must be hierarchical and must not skip levels
- Every form control must have an associated `<label>`

**ARIA:**
- Use ARIA only when native HTML semantics are insufficient
- Never add redundant ARIA roles to semantic elements (e.g., `role="button"`
  on a `<button>`)
- Dynamic regions that update must use `aria-live` appropriately
- Modals must trap focus and restore it on close (`aria-modal`, `role="dialog"`)

**Images and icons:**
- Decorative images: `alt=""`
- Informative images: meaningful `alt` text describing content, not appearance
- Icon buttons: `aria-label` describing the action, not the icon name

**Motion:**
- All transitions must respect `@media (prefers-reduced-motion: reduce)` —
  include the reduced-motion variant in every design that uses animation

**Keyboard:**
- Logical tab order following visual reading order
- No keyboard traps outside intentional modal patterns
- Custom interactive components (tabs, accordions, carousels) must implement
  the correct ARIA keyboard interaction pattern

---

## 13. Severity Classification

When reviewing design outputs or self-checking before presenting to the user:

| Severity | Examples |
|---|---|
| Critical | Missing labels on form controls; colour-only state differentiation; inaccessible interactive elements; contrast ratio failures on body text |
| High | Focus states absent; touch targets below 24px; off-grid spacing values; heading levels skipped; semantic HTML violations |
| Medium | Missing empty state; inconsistent component treatment; typography hierarchy unclear; spacing inconsistency within a section |
| Low | Minor token deviation; annotation incomplete; variant naming inconsistency |

Critical and High issues must be resolved before presenting a design to the
user. Medium and Low are noted in `design-decisions.md` as open questions.

---

## 14. Quick Reference Checklist

Before writing any design output, verify:

- [ ] Tech stack detected — output format matches
- [ ] `design-system.json` exists (or will be created in this pass)
- [ ] Slice context read — all scenarios identified and mapped to states
- [ ] Wireframe produced before hifi (or user explicitly skipped wireframe)
- [ ] Three variants queued (or user requested single version)
- [ ] All states covered: default, loading, error, empty, success
- [ ] 4pt/8pt grid applied to all spacing
- [ ] Typographic hierarchy: minimum 3 levels, ≥ 6px size difference between adjacent levels
- [ ] Colour system: brand + semantic + neutrals — no colour-only state differentiation
- [ ] WCAG AA contrast verified for all text/background pairs
- [ ] Touch targets ≥ 44×44px
- [ ] Focus states present for all interactive elements
- [ ] `design-decisions.md` written for each output
- [ ] Files written to `./docs/designs/ui-designs/` with correct versioned names
