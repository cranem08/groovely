# Wireframe Format Standard

## Purpose

Define the standard format for structured markdown wireframes used as UI
design artefacts. All wireframes in `docs/designs/` must follow this format.

---

## File Naming

- Design system: `docs/designs/design-system.md`
- Page wireframes: `docs/designs/NN-page-name.md` (e.g., `01-sign-in.md`)
- Slice design records: `docs/designs/S###-design.md`

---

## Wireframe Structure

Each wireframe file must contain these sections:

### 1. Title and Layout

```markdown
# Wireframe: [Page Name]

## Layout
- [Overall page structure: nav bar, sidebar, main content area]
- [Max width, centering, padding]
```

### 2. ASCII Art Diagram

Use box-drawing characters to show the page layout:

```
┌─────────────────────────────────────────────────────────┐
│  App Name                                    Sign out   │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│                                                         │
│  Page heading                          [Primary CTA]    │
│                                                         │
│  ┌───────────────────────────────────────────────────┐  │
│  │  Content area                                     │  │
│  └───────────────────────────────────────────────────┘  │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

Use annotations with arrows to reference the design system:

```
│  App Name                                    Sign out   │
     ↑ text xl, bold, #111827                   ↑ ghost link, text-muted
```

### 3. Component Specifications

For each significant element in the wireframe:

```markdown
### Components

- **Page heading:** text 3xl, bold, Text primary (#111827)
- **Primary CTA:** bg Primary 600 (#2563EB), text white, rounded-md, semibold
- **Content card:** bg white, border Border (#E5E7EB), rounded-lg, padding spacing-6
```

All colour, typography, and spacing values must reference the design system.

### 4. States

Document interactive states:

```markdown
### States

- **Default:** [description]
- **Hover:** [description]
- **Focus:** [description] (must include visible focus indicator)
- **Error:** [description] (must use role="alert" for screen readers)
- **Loading:** [description]
- **Empty:** [description]
- **Disabled:** [description]
```

### 5. Accessibility

Every wireframe must include:

```markdown
### Accessibility

- [Semantic HTML requirements: <table>, <fieldset>, <nav>, etc.]
- [Label associations: all inputs have <label> elements]
- [Focus management: where focus goes on page transitions]
- [Keyboard navigation: tab order, keyboard shortcuts]
- [Screen reader considerations: aria-labels, roles, live regions]
- [Colour independence: no information conveyed by colour alone]
```

### 6. Related Features

```markdown
### Related Features
- `docs/features/[feature-name].feature`
- `docs/specs/[spec-name].md`
```

---

## Rules

1. **Reference the design system** — every colour, font, spacing, and
   component style must trace back to `docs/designs/design-system.md`
2. **No implementation details** — wireframes describe *what* and *how it
   looks*, not *how it's built*. No framework-specific code.
3. **Accessibility is mandatory** — every wireframe must include the
   accessibility section. Not optional, not "add later."
4. **States matter** — interactive elements must document all relevant
   states (hover, focus, error, empty, loading, disabled)
5. **One page per file** — complex pages can be split into sections within
   the file, but each file covers one logical page or screen
6. **Cross-reference features** — link wireframes to the BDD scenarios and
   specs they implement

---

## Design System References in Wireframes

Use inline design system values for quick reference:

```
Good: bg Primary 600 (#2563EB), text white, rounded-md
Bad:  blue button with white text
```

Always include the hex value or token name so implementation can be verified
against the design system without opening a second file.
