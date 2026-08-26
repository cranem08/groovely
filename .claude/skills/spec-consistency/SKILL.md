---
name: spec-consistency
description: >
  Codifies the cross-artefact consistency gate: the regression shapes that
  remediation measurably reintroduces, the registry formats that make them
  mechanically detectable, and the order of operations for changing a constant
  or retiring a term. Provides deterministic checkers and a verified-edit tool.
  Applied by the sufficiency-check agent and by the PostToolUse write hook.
---

# Skill: spec-consistency

## Purpose

`spec-sufficiency` asks whether a single artefact says enough. This skill asks
whether the artefacts **still agree with each other** after they have been changed.

The distinction matters because the two failures have different causes. Ambiguity is
present from the moment an artefact is written. Inconsistency is *introduced* — by
the very act of resolving a finding.

The core principle: **a fact restated in five places has five chances to drift and
no mechanism to notice.** Prose has no compiler, so the drift is invisible until
someone reads all five.

### The measurement that motivates this skill

Three independent adversarial scans of one specification, with a full remediation
between each:

| Round | Findings | Introduced by the previous remediation |
|---|---|---|
| 1 | 46 | — |
| 2 | 44 | ~8 (17%) |
| 3 | 50 | ~12 (27%) |

The rate rose. One finding recurred with the two documents swapped — corrected where
it was cited, broken where it was restated. Another was recorded as fixed in
`product-log.md` and had never been fixed at all.

---

## The three regression shapes

### R-1 — One-sided edit

A rule is corrected in the document that cites it and left stale in the document
that restates it. **The tell:** both texts still exist and only one was touched.

*Measured instances:* a searched-attribute list fixed in the field map and left stale
in the data model, then — after remediation — fixed in the data model and broken in
the field map. A page-size rationale still deriving numbers that had been superseded.
An erasure cascade that silently lost an entity when an adjacent one was added.

**Mechanically detectable** by the CONSTANT check when the fact is a registered value.

### R-2 — New prose against unreconciled schema

Behaviour is added without revisiting the field table it must run against.

*Measured instances:* a person-matching rule requiring two people of the same name,
written while a uniqueness constraint on that name remained — making the scenario
unsatisfiable. An ownership rule stated in terms of a column three of the protected
entities do not have.

**Not fully mechanical.** Clause traceability makes it *reviewable* by bounding the
comparison; it cannot be decided by a script.

### R-3 — A value contradicting a stated constant

A scenario or a paragraph hard-codes a number that lives authoritatively elsewhere.

*Measured instances:* a pagination scenario asserting fifty records after one page
load at a page size of twenty — unpassable by a conforming build, passable by one
with no pagination at all.

**Mechanically detectable** by the CONSTANT check.

---

## What this skill cannot do, stated plainly

**An inverted scenario — one asserting the opposite of its own rule — is not
mechanically detectable.** No script can evaluate whether a Then follows from a
clause. Traceability makes it reviewable by bounding the comparison to one clause
and one scenario, instead of an unbounded hunt across every artefact. Claiming more
than that would be the same false confidence this skill exists to remove.

Nor does it find ambiguity, missing error policy, or anything requiring judgement.
Those remain the work of `spec-sufficiency` and of adversarial review. The two are
complementary: this catches regressions cheaply and repeatably; that catches novel
defects expensively and occasionally.

---

## Registries

Two spec artefacts, both machine-read and both blocking.

### `docs/specs/constants.md`

The single authoritative source for every number and enumeration. Other artefacts
may restate a value; a restatement that disagrees is a defect.

Two column conventions carry more weight than they appear to:

- **Word form** records how the value is written in prose and scenarios, *including
  forms derived by ±1 to probe a boundary* — a scenario says "twenty nine days" to
  assert a thirty-day limit still holds. These are invisible to a numeric scan.
- **Depends** names the scenarios whose arithmetic rests on the value, so changing
  it names what must move with it.

**PROVISIONAL** marks a value specified precisely enough to build and verify but not
yet earned — pending validation by use, and expected to change. A first-class state,
not a hedge.

#### Choosing a probe — the part that decides whether a constant is protected at all

The constant check does not scan for numbers everywhere; it fires only on lines
carrying a **probe phrase**, and the probe table is hand-maintained. A constant with
no probe is in the registry, cited by artefacts, and **completely unchecked** — a
contradiction of it passes silently while the run reports clean. Adding a row to
`constants.md` is therefore only half the work.

**The probe must be the phrase that MEANS the constant, never the unit it is measured
in.** C-040 bounds a stored photograph to 2000 px. Probing on `pixels` looks obvious
and is wrong: feature scenarios legitimately state an oversized upload, a shape to
preserve, a boundary one pixel over — every one of them in pixels, none of them
restating the constant, all of them flagged. Probing on `longest edge` fires on the
lines that assert the bound and on nothing else.

The test to apply before adding a probe: *can this phrase appear in an artefact for a
reason other than stating this constant?* If yes, it is a unit or a common word, not
a probe.

**A check that parses values out of prose must first strip its own registry's
vocabulary.** `C-043` carries the digits 043. Cited beside a unit it was read as the
value 43 and reported as contradicting a different constant — so the gate taxed the
one behaviour that most reduces drift (citing an ID rather than restating a number)
and rewarded restating it. Strip constant references before reading any number.

### `docs/specs/retired-terms.md`

A **retired** term names a concept the product has abandoned. Its vocabulary means
nothing here and its appearance is a defect.

This is **not** the same as out of scope. An out-of-scope item is postponed: still
valid, still meaningful, possibly returning. Collection statistics are out of scope.
A wantlist is retired. Two lists, two lifecycles, and only one is a defect when it
appears.

**Register a term in backticks, and make it specific enough to be unambiguous.**
Only backticked terms are read. A bare common word — `gallery`, `everything`,
`photograph` — collides with ordinary prose, fires on innocent lines, and trains
everyone to ignore the check. Register the phrase that carries the concept.

---

## Order of operations

Blocking checks make ordering load-bearing. Both are the reverse of the intuitive
order, which is why they are written down.

| Change | Order |
|---|---|
| Changing a constant | `constants.md` **first**, then every artefact that restates it |
| Retiring a term | Purge it from every artefact **first**, then register it |

The reverse order blocks you with your own half-finished change.

## Declaring a legitimate mention

Prose sometimes must name a retired concept — explaining why it went, or listing what
the product is not. Declare it:

```markdown
<!-- consistency:retired-ok — this section explains a retirement and must name it -->
```

The marker exempts the rest of the section. Declaring an exception is honest;
widening a heuristic until it guesses correctly is an arms race with English.

---

## Scripts

### `scripts/check_consistency.py`

```
check_consistency.py --project DIR [--file PATH]
```

Full sweep, or one file for the write hook. Exit 0 clean, 1 findings, 2 config error.

**Prove it has teeth before trusting a clean result.** Copy the artefacts, inject one
defect of each class, confirm each is caught, and discard the copy. A check that has
never failed is not known to work — the same standard `verify` applies to itself.

### `scripts/apply_resolution.py`

```
apply_resolution.py --file PATH --old TEXT --new TEXT
```

Performs a replacement, asserting **exactly one** match. Exits non-zero on zero
matches or several. Use it for every resolution.

This exists because a script that reports success without asserting its match put two
**false completion entries** into `product-log.md` — the artefact the navigator and
package agents read to decide project state. A false entry there can advance a phase
on work that never happened.

**Never record a resolution as applied without verifying the artefact changed.**

---

## Reading

`references/regression-patterns.md` — the three shapes as worked cases, with the
measured examples in full. Read when triaging a consistency finding or deciding
whether an edit is complete.
