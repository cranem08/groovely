# HTML Standard

Rules for semantic, accessible HTML. Apply during implementation and code
review of HTML templates and markup.

## Semantic Elements

- Use `<header>`, `<nav>`, `<main>`, `<section>`, `<article>`, `<aside>`, `<footer>`
  for page structure — not generic `<div>` elements
- Use `<button>` for actions, `<a>` for navigation — never the reverse
- Use `<ul>`/`<ol>` for lists, not styled `<div>` sequences
- Use `<table>` for tabular data only, never for layout
- Use `<h1>` through `<h6>` in order — no skipping heading levels

## Labels and Forms

- Every form input MUST have an associated `<label>` with matching `for`/`id`
- Group related inputs with `<fieldset>` and `<legend>`
- Use `type` attributes on inputs (`email`, `tel`, `number`, `url`)
- Provide `autocomplete` attributes for common fields (name, email, address)
- Mark required fields with `required` attribute and visible indicator

## ARIA

- Use native HTML elements before reaching for ARIA roles
- If ARIA is needed: `role`, `aria-label`, `aria-describedby`, `aria-live`
- Every interactive custom element needs: role, keyboard support, focus management
- `aria-hidden="true"` on decorative elements
- Never use ARIA to override native semantics of an element

## Images and Media

- Every `<img>` must have an `alt` attribute
- Decorative images: `alt=""` (empty, not missing)
- Informative images: `alt` describes the content or function
- Provide captions for video and transcripts for audio

## Document Structure

- One `<main>` per page
- Page title (`<title>`) describes the current page content
- Language attribute on `<html>` element (`lang="en"`)
- Viewport meta tag for responsive design
