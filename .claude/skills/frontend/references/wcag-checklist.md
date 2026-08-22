# WCAG 2.2 AA Checklist for Implementation

This checklist reformulates WCAG 2.2 AA requirements as concrete checks to
apply during implementation and review. Organised by what you're building,
not by WCAG success criterion number.

## Table of Contents

- [Interactive Elements](#interactive-elements)
- [Forms](#forms)
- [Images and Media](#images-and-media)
- [Text and Typography](#text-and-typography)
- [Colour and Contrast](#colour-and-contrast)
- [Keyboard Navigation](#keyboard-navigation)
- [Focus Management](#focus-management)
- [Dynamic Content](#dynamic-content)
- [Page Structure](#page-structure)
- [Motion and Animation](#motion-and-animation)

## Interactive Elements

- [ ] All buttons use `<button>` (not styled divs or spans)
- [ ] All links use `<a href="...">` with descriptive text
- [ ] No interactive element relies on hover alone (touch devices exist)
- [ ] Click/touch targets are at least 24x24 CSS pixels (WCAG 2.2)
- [ ] Interactive elements have visible labels or accessible names
- [ ] Disabled elements use native `disabled` attribute

## Forms

- [ ] Every input has an associated `<label>` (explicit or wrapping)
- [ ] Labels are visible (not just `aria-label` unless visually hidden
      labels are justified)
- [ ] Required fields are indicated (not by colour alone)
- [ ] Error messages identify the field and describe the error
- [ ] Error messages are associated with inputs (`aria-describedby` or
      adjacent to field)
- [ ] Form validation errors don't clear user input
- [ ] Autocomplete attributes are used where applicable (`autocomplete="email"`,
      `autocomplete="current-password"`, etc.)
- [ ] Related inputs are grouped with `<fieldset>` + `<legend>`

## Images and Media

- [ ] Informative images have descriptive `alt` text
- [ ] Decorative images have `alt=""`
- [ ] Complex images (charts, diagrams) have extended descriptions
- [ ] Video content has captions
- [ ] Audio content has transcripts
- [ ] Media players have accessible controls

## Text and Typography

- [ ] Text can be resized to 200% without loss of content or function
- [ ] Line spacing is at least 1.5x font size for body text
- [ ] No text is rendered as an image (unless essential)
- [ ] Language is declared (`<html lang="...">`)
- [ ] Language changes within content are marked (`<span lang="...">`)

## Colour and Contrast

- [ ] Normal text: 4.5:1 contrast ratio minimum
- [ ] Large text (18pt / 14pt bold): 3:1 contrast ratio minimum
- [ ] UI components and graphical objects: 3:1 contrast ratio minimum
- [ ] Information is not conveyed by colour alone — use text, icons, or
      patterns as well
- [ ] Focus indicators meet 3:1 contrast against adjacent colours
- [ ] Links in body text are distinguishable (underline or 3:1 contrast
      plus non-colour indicator on hover/focus)

## Keyboard Navigation

- [ ] All functionality is operable via keyboard
- [ ] Tab order follows logical reading/interaction order
- [ ] No keyboard traps (user can always Tab away)
  - Exception: modal dialogs may trap focus but must have Escape to close
- [ ] Custom keyboard shortcuts don't conflict with browser/AT shortcuts
- [ ] Keyboard shortcuts can be turned off or remapped (if single-character)
- [ ] Skip navigation link provided for repeated blocks

## Focus Management

- [ ] Focus is visible on all interactive elements
- [ ] Focus outlines are never removed without replacement
- [ ] Focus moves logically when content changes:
  - Modal opens → focus moves into modal
  - Modal closes → focus returns to trigger
  - Item deleted → focus moves to logical next element
  - Dynamic content added → focus managed or announced
- [ ] Focus is not forcibly moved without user action (except modals,
      error correction)
- [ ] `tabindex` usage is minimal:
  - `tabindex="0"` — adds to tab order (rare, justified)
  - `tabindex="-1"` — programmatic focus only
  - `tabindex` > 0 — never use

## Dynamic Content

- [ ] Loading states are communicated (`aria-busy="true"`, live region,
      or visible indicator)
- [ ] Content updates are announced when relevant (`aria-live="polite"`
      for non-urgent, `aria-live="assertive"` for urgent)
- [ ] Single-page app route changes update page title and manage focus
- [ ] Toast/notification messages are announced via live regions
- [ ] Infinite scroll provides alternative navigation (pagination link
      or "load more" button)

## Page Structure

- [ ] Exactly one `<h1>` per page/view
- [ ] Heading levels are hierarchical (no skipping from h2 to h4)
- [ ] Landmark regions are present (`<header>`, `<nav>`, `<main>`, `<footer>`)
- [ ] Landmark regions have unique labels if duplicated
      (`<nav aria-label="Primary">`, `<nav aria-label="Footer">`)
- [ ] Page has a descriptive `<title>`
- [ ] Document language is set (`<html lang="en">`)

## Motion and Animation

- [ ] `prefers-reduced-motion` is respected — reduce or remove animations
- [ ] No content flashes more than 3 times per second
- [ ] Auto-playing content can be paused, stopped, or hidden
- [ ] Animations are not required to understand content
- [ ] Parallax and motion effects have reduced-motion alternatives

## During Code Review

Use these severity levels when raising accessibility findings:

| Severity | Trigger |
|---|---|
| Critical | Users cannot access core functionality (missing labels, no keyboard access, focus trap) |
| High | Users encounter significant barriers (contrast failure, invalid ARIA, focus loss) |
| Medium | Suboptimal but usable (missing landmark labels, heading hierarchy gaps) |
| Low | Best practice improvement (missing autocomplete, verbose ARIA) |

Critical and High findings block the slice. Medium and Low are reported only.
