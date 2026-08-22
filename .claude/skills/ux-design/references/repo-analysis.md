# UI Codebase Analysis

## Purpose

Analyse an existing UI codebase to understand current patterns, components,
and styling before designing iterations or improvements.

## When to Run

Run when the project has an existing UI and you need to design changes:

- Before iterating on existing screens
- Before establishing a design system from existing code
- When significant UI restructuring is planned

Skip if:
- Project has no UI (pure API, CLI, or MCP server)
- Project is brand new with no existing code

## Output

Write analysis to `docs/designs/ui-analysis.md`.

---

## Analysis Steps

### 1. Detect Framework and Styling Approach

Scan `package.json`, config files, and import patterns to determine:

- **Framework:** React, Vue, Svelte, Angular, etc.
- **Meta-framework:** Next.js, Nuxt, Remix, Astro, etc.
- **Component library:** shadcn/ui, Ant Design, MUI, Chakra, Radix, custom
- **CSS approach:** Tailwind, CSS Modules, styled-components, vanilla CSS

### 2. Identify Shared Components

Find the shared/reusable UI component directory (e.g., `src/components/ui/`).

For each shared primitive (Button, Input, Dialog, Card, Select, etc.):
- File path
- Component name
- Key props and variants
- Visual characteristics (colours, sizes, states)

### 3. Map Layouts

Identify shared layout components:
- App shell / root layout
- Navigation bar
- Sidebar
- Header / footer
- Layout wrappers

For each: file path and layout structure description.

### 4. Map Routes and Pages

Document the page/route structure:
- URL path → component file mapping
- Which layout each page uses
- Key pages for the user journey

### 5. Extract Theme Tokens

Document current design tokens:
- Colour palette (from CSS variables, Tailwind config, or theme files)
- Typography (font families, sizes, weights)
- Spacing scale
- Border radius and shadow values
- Breakpoints

---

## Output Format

```markdown
# UI Analysis — [Project Name]

## Framework
- Framework: [e.g., React 18]
- Meta-framework: [e.g., Next.js 14]
- CSS approach: [e.g., Tailwind CSS]
- Component library: [e.g., custom]

## Shared Components
| Component | Path | Variants |
|-----------|------|----------|
| Button | src/components/ui/button.tsx | primary, secondary, ghost |
| ...

## Layouts
| Layout | Path | Used By |
|--------|------|---------|
| App Shell | src/app/layout.tsx | All authenticated pages |
| ...

## Routes
| URL | Page Component | Layout |
|-----|---------------|--------|
| / | src/app/page.tsx | App Shell |
| ...

## Current Theme Tokens
[Extracted colour, typography, spacing values]
```

---

## Key Principles

- Document **patterns**, not full source code
- Focus on what's needed for design decisions
- Keep the analysis concise — this is input for the design system, not
  a codebase audit
