# Progressive Disclosure Patterns

Patterns for organising skill content to minimise context usage while
maintaining discoverability.

## Contents

- [The Three Levels](#the-three-levels)
- [Pattern 1: High-Level Guide](#pattern-1-high-level-guide)
- [Pattern 2: Domain Organisation](#pattern-2-domain-organisation)
- [Pattern 3: Conditional Details](#pattern-3-conditional-details)
- [Guidelines](#guidelines)

## The Three Levels

Skills use progressive disclosure to manage context:

| Level | Content | When loaded | Target size |
|---|---|---|---|
| 1 | Metadata (name + description) | Always | ~100 words |
| 2 | SKILL.md body | When skill triggers | <500 lines |
| 3 | Bundled resources | As needed by Claude | Unlimited |

The goal: load only what's needed, when it's needed.

## Pattern 1: High-Level Guide

Keep SKILL.md as an overview with links to detailed references.

```markdown
# PDF Processing

## Quick Start

Extract text with pdfplumber:
[brief code example]

## Advanced Features

- **Form filling**: See `references/forms.md` for complete guide
- **Annotations**: See `references/annotations.md` for all options
- **Examples**: See `references/examples.md` for common patterns
```

Claude loads `forms.md`, `annotations.md`, or `examples.md` only when the
user needs those features.

## Pattern 2: Domain Organisation

For skills spanning multiple domains, organise by domain:

```
bigquery-skill/
├── SKILL.md (overview + navigation)
└── references/
    ├── finance.md (revenue, billing metrics)
    ├── sales.md (opportunities, pipeline)
    ├── product.md (API usage, features)
    └── marketing.md (campaigns, attribution)
```

When a user asks about sales metrics, Claude only loads `sales.md`.

Similarly for multi-framework skills:

```
cloud-deploy/
├── SKILL.md (workflow + provider selection)
└── references/
    ├── aws.md (AWS deployment patterns)
    ├── gcp.md (GCP deployment patterns)
    └── azure.md (Azure deployment patterns)
```

When the user chooses AWS, Claude only loads `aws.md`.

## Pattern 3: Conditional Details

Show basic content inline, link to advanced content:

```markdown
# DOCX Processing

## Creating Documents

Use docx-js for new documents:
[basic example]

## Editing Documents

For simple edits, modify the XML directly.

**For tracked changes**: See `references/redlining.md`
**For OOXML internals**: See `references/ooxml.md`
```

Claude loads `redlining.md` or `ooxml.md` only when the user needs those
specific features.

## Guidelines

### Keep References Shallow

All reference files should link directly from SKILL.md — one level deep.

**Good:**
```
skill/
├── SKILL.md (links to all references)
└── references/
    ├── api.md
    ├── schemas.md
    └── examples.md
```

**Bad:**
```
skill/
├── SKILL.md (links to overview.md)
└── references/
    └── overview.md (links to details/)
        └── details/
            ├── api.md
            └── schemas.md
```

### Structure Long References

For files over 100 lines, include a table of contents at the top:

```markdown
# API Reference

## Contents

- [Authentication](#authentication)
- [Endpoints](#endpoints)
- [Error Codes](#error-codes)
- [Rate Limits](#rate-limits)

## Authentication
...
```

This lets Claude see the full scope when previewing.

### Avoid Duplication

Information lives in ONE place:

- Core workflow → SKILL.md
- Detailed reference material → references/
- Never both

If you find yourself copying content, move it to a reference and link to it.
