---
name: skill-creator
description: >
  Guide for creating effective skills that extend Claude's capabilities. Use
  when: (1) creating a new skill from scratch, (2) updating or improving an
  existing skill, (3) validating a skill against best practices, (4) deciding
  what to include in scripts/, references/, or assets/, (5) writing SKILL.md
  frontmatter and body content, or (6) packaging a skill for distribution.
---

# Skill Creator

Create effective skills that extend Claude's capabilities with specialized
knowledge, workflows, and tool integrations.

## Core Principles

### Concise is Key

The context window is a shared resource. Only add what Claude doesn't already
know. Challenge each piece: "Does this justify its token cost?"

Prefer concise examples over verbose explanations.

### Degrees of Freedom

Match specificity to the task's fragility:

- **High freedom** (text instructions): Multiple valid approaches, context-dependent
- **Medium freedom** (pseudocode/parameterised scripts): Preferred pattern with variation
- **Low freedom** (specific scripts): Fragile operations, consistency critical

### Skill Anatomy

```
skill-name/
├── SKILL.md (required)
│   ├── YAML frontmatter (name, description)
│   └── Markdown body (instructions)
└── Bundled Resources (optional)
    ├── scripts/     - Executable code
    ├── references/  - Documentation loaded as needed
    └── assets/      - Output files (templates, images)
```

See `references/skill-anatomy.md` for detailed guidance on each component.

### Progressive Disclosure

Three-level loading system:

1. **Metadata** (name + description) — always in context
2. **SKILL.md body** — when skill triggers
3. **Bundled resources** — as needed

Keep SKILL.md under 500 lines. Split to references when approaching this limit.

See `references/progressive-patterns.md` for organisation patterns.

## Skill Creation Process

### Step 1: Understand with Concrete Examples

Gather concrete usage examples before building:

- "What should this skill support?"
- "How would users invoke it?"
- "What would trigger this skill?"

Conclude when functionality scope is clear.

### Step 2: Plan Reusable Contents

For each example, identify:

1. Code that would be rewritten repeatedly → `scripts/`
2. Documentation Claude needs while working → `references/`
3. Files used in output (templates, assets) → `assets/`

### Step 3: Initialize the Skill

Create the skill directory structure manually:

```
skill-name/
├── SKILL.md
├── references/
└── assets/
```

Add `scripts/` only if the skill requires executable code.

Skip if updating an existing skill.

### Step 4: Edit the Skill

1. Implement the reusable resources identified in Step 2
2. Test any scripts by running them
3. Delete unused example files from initialization
4. Write SKILL.md (see Frontmatter and Body sections below)

#### Frontmatter

Write YAML frontmatter with exactly two fields:

```yaml
---
name: skill-name
description: >
  What the skill does. Use when: (1) trigger one, (2) trigger two, ...
---
```

- `description` is the primary trigger mechanism — be comprehensive
- Include all "when to use" info here, not in the body
- No other frontmatter fields

#### Body

Write instructions using imperative/infinitive form.

- Reference bundled resources with clear guidance on when to read them
- Keep under 500 lines
- Link to references for detailed patterns

### Step 5: Validate the Skill

Check the skill against these criteria:

- [ ] SKILL.md has exactly 2 frontmatter fields (name, description)
- [ ] Description includes "Use when:" with numbered triggers
- [ ] SKILL.md is under 500 lines
- [ ] No unused example files remain
- [ ] References are linked from SKILL.md body
- [ ] No cross-skill references (skills must be self-contained)

### Step 6: Iterate

1. Use the skill on real tasks
2. Notice struggles or inefficiencies
3. Update SKILL.md or resources
4. Test again

## What NOT to Include

Do not create extraneous files:

- README.md
- INSTALLATION_GUIDE.md
- CHANGELOG.md
- User-facing documentation

Skills contain only what Claude needs to do the job.
