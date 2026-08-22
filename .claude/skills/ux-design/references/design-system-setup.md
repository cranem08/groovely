# Design System Setup

## Purpose

Establish `docs/designs/design-system.md` as the single source of truth for
all visual design specifications. All wireframes and UI implementations must
reference this file for colours, typography, spacing, and component styles.

---

## Two Paths

### A. Extract from Existing Codebase

When the project already has a UI:

1. Read theme files: `globals.css`, `tailwind.config.*`, CSS variable
   definitions, theme provider files
2. Read component library: identify shared UI primitives and their styling
3. Extract and document:
   - Colour palette (primary, secondary, accent, semantic, neutrals)
   - Typography (font families, sizes, weights, line heights)
   - Spacing scale (margins, padding, gaps)
   - Border radius values
   - Shadow definitions
   - Breakpoints
   - Component patterns (button styles, card styles, input styles)
   - Motion/animation patterns
4. Write to `docs/designs/design-system.md`

### B. Create for New Project

When starting from scratch:

1. Ask the user about visual direction:
   - Applications or websites to draw inspiration from
   - Colour preferences or existing brand identity
   - General feel: minimal, corporate, playful, technical
2. If the user provides a reference URL or screenshot, analyse it for
   colour palette, typography, and layout patterns
3. Propose a design system based on the user's direction
4. Iterate until the user approves
5. Write to `docs/designs/design-system.md`

---

## Design System File Structure

`docs/designs/design-system.md` should cover:

```markdown
# Design System — [Project Name]

## Product Context
- Product name and description
- Target users and key pages
- Key features and user jobs

## Visual Direction
[1-2 sentences describing the overall feel and constraints]

## Colour Palette
- Primary: [hex values and usage]
- Secondary: [hex values and usage] (if needed)
- Semantic: success, warning, error, info [hex values]
- Neutrals: background, surface, text, border [hex values]

## Typography
- Font families (heading, body, mono)
- Size scale (xs through 4xl with rem and px values)
- Weight scale (regular, medium, semibold, bold)
- Line height scale (tight, normal, relaxed)

## Spacing
- Base unit (e.g., 4px grid)
- Scale (1 through 16 with rem values)

## Layout
- Max content width
- Breakpoints (sm, md, lg, xl)
- Grid system

## Components
- Button styles (primary, secondary, ghost, destructive)
- Card styles
- Input styles (default, focus, error)
- Navigation patterns
- Table styles
- Badge/status styles

## Motion
- Transition durations (fast, normal, slow)
- Easing curves
- Reduced motion: respect `prefers-reduced-motion`

## Constraints
- WCAG AA contrast ratios (4.5:1 normal text, 3:1 large text)
- Visible focus indicators on all interactive elements
- No information conveyed by colour alone
- Minimum touch target: 44x44px
- Readable at 200% zoom without horizontal scrolling
```

---

## Fidelity Rules

The design system is a **hard constraint**:

1. All wireframes must reference only colours, fonts, spacing, and styles
   from the design system
2. If a wireframe deviates, it is a finding (severity: High)
3. Deviation requires explicit user approval and update to the design system

---

## When to Update

Update the design system when:
- User approves a new visual direction
- New component patterns are established
- Brand guidelines change
- Accessibility audit reveals contrast or sizing issues

The design system evolves — but always intentionally, never accidentally.
