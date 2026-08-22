# Skill Anatomy: Component Details

Detailed guidance on each component of a skill.

## Contents

- [SKILL.md](#skillmd)
- [Scripts](#scripts)
- [References](#references)
- [Assets](#assets)

## SKILL.md

The required entry point for every skill.

### Frontmatter (YAML)

Contains exactly two fields:

- **name**: The skill name (matches directory name)
- **description**: What the skill does AND when to use it

The description is the primary trigger mechanism. Claude reads only the
frontmatter to decide whether to load the skill, so include all trigger
conditions here.

**Good description:**
```yaml
description: >
  Comprehensive document creation, editing, and analysis with support for
  tracked changes, comments, and formatting preservation. Use when: (1)
  creating new .docx documents, (2) modifying or editing content, (3) working
  with tracked changes, (4) adding comments, or (5) extracting text.
```

**Bad description:**
```yaml
description: Handles Word documents.
```

Do not include other frontmatter fields (license, version, author, etc.).

### Body (Markdown)

Instructions and guidance loaded only after the skill triggers.

Guidelines:
- Use imperative/infinitive form ("Create the file", not "The file is created")
- Keep under 500 lines
- Reference bundled resources with clear "when to read" guidance
- No "When to Use" sections (that belongs in description)

## Scripts

Executable code in `scripts/` for tasks requiring deterministic reliability.

**When to include:**
- Same code is rewritten repeatedly
- Deterministic output is critical
- Operation is complex enough to warrant pre-written code

**Examples:**
- `scripts/rotate_pdf.py` — PDF rotation
- `scripts/resize_image.sh` — Image resizing
- `scripts/validate_schema.py` — Schema validation

**Benefits:**
- Token efficient (execute without loading into context)
- Deterministic behaviour
- Tested and reliable

**Note:** Scripts may still need to be read for patching or environment
adjustments.

## References

Documentation in `references/` loaded as needed into context.

**When to include:**
- Documentation Claude should reference while working
- Detailed schemas, API docs, domain knowledge
- Content too detailed for SKILL.md but needed during execution

**Examples:**
- `references/schema.md` — Database table schemas
- `references/api.md` — API endpoint documentation
- `references/policies.md` — Company policies
- `references/patterns.md` — Design patterns and examples

**Best practices:**
- Keep SKILL.md lean by moving details here
- For files >100 lines, include a table of contents
- For files >10k words, include grep search patterns in SKILL.md
- Avoid duplication between SKILL.md and references

**Loading:** Claude decides when to read based on SKILL.md guidance.

## Assets

Files in `assets/` used in output, not loaded into context.

**When to include:**
- Templates that get copied or modified
- Images, icons, fonts
- Boilerplate code
- Sample documents

**Examples:**
- `assets/logo.png` — Brand logo
- `assets/template.pptx` — Presentation template
- `assets/frontend-template/` — Starter project files
- `assets/font.ttf` — Typography

**Benefits:**
- Separates output resources from documentation
- Claude uses files without loading into context
- Templates can be copied and customised
