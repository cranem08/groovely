# Semantic HTML: Element Decision Tree

Use this reference when choosing which HTML element to use. Start with the
purpose, not the appearance.

## Contents

- [Decision Tree](#decision-tree)
- [Common Mistakes and Fixes](#common-mistakes-and-fixes)

## Decision Tree

### "I need to group content on the page"

- Is it the primary content? → `<main>` (one per page)
- Is it introductory or navigational? → `<header>`
- Is it a set of navigation links? → `<nav>`
- Is it a thematic group with its own heading? → `<section>`
- Is it self-contained / independently distributable? → `<article>`
- Is it tangentially related (sidebar, callout)? → `<aside>`
- Is it closing content? → `<footer>`
- None of the above? → `<div>` (last resort)

### "I need the user to do something"

- Triggers an action (submit, toggle, delete)? → `<button>`
- Navigates to a URL? → `<a href="...">`
- Submits a group of data? → `<form>`
- Selects from options? → `<select>` or radio/checkbox group
- Enters text data? → `<input>` or `<textarea>`

**Never:**
- Attach click handlers to `<div>` or `<span>`
- Use `<a>` without `href` for actions
- Use `<a href="#">` as a button substitute

### "I need to display text content"

- Is it a document heading? → `<h1>`–`<h6>` (maintain hierarchy)
- Is it a paragraph? → `<p>`
- Is it a list of items? → `<ul>` (unordered) or `<ol>` (ordered)
- Is it a term and definition? → `<dl>`, `<dt>`, `<dd>`
- Is it a block quotation? → `<blockquote>`
- Is it code? → `<code>` (inline) or `<pre><code>` (block)
- Is it emphasis? → `<em>` (stress) or `<strong>` (importance)
- Is it a time or date? → `<time datetime="...">`

### "I need to display data"

- Is it tabular data with rows and columns? → `<table>`
  - Use `<thead>`, `<tbody>`, `<th scope="...">` for structure
  - Never use tables for layout
- Is it an image or illustration? → `<img>` with `alt`
  - Decorative? → `alt=""`
  - Complex? → provide extended description
- Is it media with controls? → `<video>` or `<audio>` with controls

### "I need to build a form"

1. Wrap in `<form>`
2. Every input gets a `<label>` (explicit `for`/`id` or wrapping)
3. Group related inputs in `<fieldset>` + `<legend>`
4. Use correct input types:
   - `type="email"` for email
   - `type="password"` for passwords
   - `type="number"` for numeric input
   - `type="tel"` for phone numbers
   - `type="url"` for URLs
   - `type="search"` for search fields
5. Submit with `<button type="submit">`
6. Never rely on placeholder as a label substitute

## Common Mistakes and Fixes

### Clickable div instead of button

**Wrong:**
```html
<div class="btn" onclick="save()">Save</div>
```

**Right:**
```html
<button type="button" class="btn" onclick="save()">Save</button>
```

**Why:** `<div>` is not focusable, has no keyboard activation, and is not
announced as interactive by screen readers.

### Link used as button

**Wrong:**
```html
<a href="#" onclick="deleteItem()">Delete</a>
```

**Right:**
```html
<button type="button" onclick="deleteItem()">Delete</button>
```

**Why:** `<a>` communicates navigation. `<button>` communicates action.

### Missing label

**Wrong:**
```html
<input type="email" placeholder="Email address">
```

**Right:**
```html
<label for="email">Email address</label>
<input type="email" id="email" placeholder="you@example.com">
```

**Why:** Placeholders disappear on input and are not reliably announced.

### Heading used for styling

**Wrong:**
```html
<h3 class="large-text">Welcome back</h3>  <!-- inside an h1 section -->
```

**Right:**
```html
<p class="large-text">Welcome back</p>
```

Or restructure the heading hierarchy to be correct.

**Why:** Headings define document outline. Skipping levels or using them for
visual effect breaks navigation for assistive technology.

### Generic link text

**Wrong:**
```html
<a href="/report">Click here</a>
```

**Right:**
```html
<a href="/report">View monthly report</a>
```

**Why:** Link text must be meaningful out of context. Screen reader users
often navigate by links alone.

### Image without alt

**Wrong:**
```html
<img src="chart.png">
```

**Right (informative):**
```html
<img src="chart.png" alt="Sales increased 23% in Q3 compared to Q2">
```

**Right (decorative):**
```html
<img src="divider.png" alt="">
```

**Why:** Without `alt`, screen readers announce the filename, which is useless.
