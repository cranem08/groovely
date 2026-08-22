# Accessibility Standard (WCAG 2.2 AA)

Checklist for WCAG 2.2 Level AA compliance. Apply during implementation and
code review of UI code.

## Perceivable

### Text Alternatives (1.1)
- [ ] All non-text content has a text alternative
- [ ] Decorative images use empty `alt=""`

### Adaptable (1.3)
- [ ] Information and structure conveyed through presentation are available programmatically
- [ ] Correct reading order in markup matches visual order
- [ ] Instructions don't rely solely on shape, size, or visual location

### Distinguishable (1.4)
- [ ] Colour is not the sole means of conveying information
- [ ] Text contrast is at least 4.5:1 (3:1 for large text)
- [ ] Text can be resized to 200% without loss of content
- [ ] Content reflows at 320px width without horizontal scrolling
- [ ] Non-text contrast is at least 3:1 for UI components

## Operable

### Keyboard Accessible (2.1)
- [ ] All functionality available via keyboard
- [ ] No keyboard traps
- [ ] Focus order is logical and predictable

### Enough Time (2.2)
- [ ] Time limits can be turned off, adjusted, or extended
- [ ] Auto-updating content can be paused, stopped, or hidden

### Navigable (2.4)
- [ ] Skip navigation link provided
- [ ] Page titles describe topic or purpose
- [ ] Focus order preserves meaning and operability
- [ ] Link purpose is clear from link text (or context)
- [ ] Multiple ways to find pages (navigation, search, sitemap)
- [ ] Headings and labels describe topic or purpose
- [ ] Focus visible on all interactive elements

### Input Modalities (2.5)
- [ ] Touch targets are at least 24x24 CSS pixels (44x44 recommended)
- [ ] Functionality is not dependent on specific input modality

## Understandable

### Readable (3.1)
- [ ] Page language is set (`lang` attribute on `<html>`)
- [ ] Language changes within content are marked

### Predictable (3.2)
- [ ] Focus changes don't trigger unexpected context changes
- [ ] Input changes don't trigger unexpected context changes
- [ ] Navigation is consistent across pages

### Input Assistance (3.3)
- [ ] Errors are identified and described in text
- [ ] Labels or instructions provided for user input
- [ ] Error suggestions provided when known
- [ ] Submissions are reversible, checked, or confirmed

## Robust

### Compatible (4.1)
- [ ] Valid HTML (no duplicate IDs, proper nesting)
- [ ] Name, role, and value available for all UI components
- [ ] Status messages available to assistive technology without focus
