# CSS Standard

Rules for accessible, maintainable CSS. Apply during implementation and code
review of stylesheets.

## Focus Indicators

- **Never remove focus outlines** (`outline: none`) without providing an alternative
- Custom focus styles must be at least as visible as browser defaults
- Focus indicators must have sufficient contrast (3:1 minimum against background)
- Use `:focus-visible` for keyboard-only focus styles where supported
- Test focus visibility in both light and dark modes

## Contrast

- Text contrast: minimum **4.5:1** for normal text, **3:1** for large text (WCAG AA)
- UI component contrast: minimum **3:1** against adjacent colours
- Do not convey information by colour alone — use shape, text, or pattern too
- Test with a contrast checker tool

## Layout

- Use CSS Grid or Flexbox for layout — no float-based layouts
- Design mobile-first, enhance for larger screens
- Content must be readable without horizontal scrolling at 320px width
- Use relative units (`rem`, `em`, `%`) over fixed pixels for text and spacing
- Ensure touch targets are at least 44x44 CSS pixels

## Motion and Animation

- Respect `prefers-reduced-motion` — disable or reduce animations
- No auto-playing animations that last more than 5 seconds
- No flashing content (more than 3 flashes per second)
- Animations should enhance, not block, user interaction

## Responsive Design

- Use media queries for layout shifts, not for hiding content
- Ensure all content is accessible at all breakpoints
- Test at standard breakpoints: 320px, 768px, 1024px, 1440px
- Images and media must scale without overflow
