# Upstream Handoff — changes made in this instance for integration into the product-workflow template

**Instance:** `groovely` (product-workflow v1.0.0)
**Date:** 2026-08-25
**Status:** implemented here, tested here, **not yet integrated into the template**

## Why these changes were made in the instance rather than the template

Changing the template mid-project and re-importing would introduce instability into a
project that is itself the evidence base. The changes were therefore made here,
proven here, and are handed over with their reasoning rather than as a diff — so the
template team can judge the design, not just the code.

---

## The measurement that motivates all of it

One specification. Three independent adversarial scans, each by reviewers with no
access to the authoring reasoning. A full remediation pass between each.

| Round | Findings | Introduced by the previous remediation | Rate |
|---|---|---|---|
| 1 | 46 | — | — |
| 2 | 44 | ~8 | 17% |
| 3 | 50 | ~12 | 27% |

**The rate rose.** Two results sharpen it:

- One finding recurred in scan 3 **with the two documents swapped**. The remediation
  had corrected the document that cited a rule and introduced the identical defect in
  the document that restated it.
- One finding was recorded in `product-log.md` as fixed and **had never been fixed**.
  A second false entry was found in the same log, from the same cause: an edit script
  that reported success without asserting its match.

The workflow's own rule — *"ALWAYS re-scan after resolutions — fixes can introduce
new ambiguities"* — is **vindicated** by this. It is the only reason any of it is
visible. What the rule lacks is a mechanism.

**The gap in one sentence:** the Dark Factory hard-gates every slice, while the
specification feeding it is hand-edited with no gate at all.

---

## Changes for integration

### 1. New skill: `spec-consistency`

`.claude/skills/spec-consistency/` — SKILL.md, `references/regression-patterns.md`,
`scripts/check_consistency.py`, `scripts/apply_resolution.py`.

Follows the `spec-sufficiency` pattern exactly: two-field frontmatter, catalogue in
the body, detail in references, deterministic code in scripts, applied by one agent.

**Answers workflow finding #24.** `spec-sufficiency` asks whether an artefact says
enough; this asks whether the artefacts still agree with each other after being
changed. Different failure, different cause, different moment.

**Project-agnostic?** The skill and both scripts are. The registries they read are
project data.

### 2. Two new spec artefacts (registry pattern)

- **`docs/specs/constants.md`** — the single authoritative source for every number
  and enumeration. Two column conventions matter more than they look: **Word form**
  records prose spellings *including forms derived by ±1 to probe a boundary*
  ("twenty nine days" asserting a thirty-day limit), which are invisible to a numeric
  scan; **Depends** names the scenarios whose arithmetic rests on the value.
  **PROVISIONAL** marks a value specified precisely enough to build and verify but
  not yet earned — this also **answers finding #22**, which asked for exactly this
  state and found the workflow had no way to express it.
- **`docs/specs/retired-terms.md`** — concepts the product has **abandoned**.

**Retired is not out-of-scope, and the distinction is the Product Engineer's.** Out of
scope is a *postponement*: the concept is still valid, the vocabulary still means
something, it may return. Retired means abandoned on principle. Only the second is a
defect when it reappears. Two lists, two lifecycles. The template's `out-of-scope.md`
currently conflates them under three unmarked headings.

### 3. Extended `validate-artefact.sh`, and a wider matcher

The hook already validated `.feature` structure and ADR templates on write. It now
also runs the consistency check on every `.md` and `.feature` under a project, and
**blocks**.

`settings.json` matcher widened from `Write` to `Write|Edit|MultiEdit`; timeout 10s → 15s.
The measured regressions arrived through all three.

**Blocking is deliberate.** An advisory check is one you learn to scroll past — which
is functionally identical to not having it.

**Blocking forces an order of operations**, and both are the reverse of the intuitive
order, which is why they must be documented rather than discovered:

| Change | Order |
|---|---|
| Changing a constant | `constants.md` **first**, then its dependants |
| Retiring a term | Purge everywhere **first**, then register |

### 4. `apply_resolution.py` — edits that cannot silently fail

Asserts **exactly one** match; exits non-zero on zero or many; verifies the file
changed after writing.

**Answers finding #25.** `product-log.md` is what the navigator and package agents
read to determine project state, so a false completion entry can advance a phase on
work that never happened. This makes an unverified edit impossible rather than
merely discouraged. Every edit in this handoff was applied through it.

### 5. Amendments to the `sufficiency-check` agent

- **Step 0.5 — consistency gate.** After the Step 0 artefact-completeness gate,
  before the content scan. Findings are Tier 1. Requires the check be **shown to have
  teeth** — copy the artefacts, inject one defect of each class, confirm each is
  caught, discard the copy. The same standard `verify` already applies to itself.
- **Step 4 amended.** Resolutions applied through `apply_resolution.py`; the
  consistency check re-run after **each** resolution rather than once at the end (the
  measured regressions were introduced one edit at a time and compounded); and an
  explicit instruction that where a finding names two artefacts, **both** are in
  scope — correcting one side relocates the defect rather than resolving it.
- **Three Non-Negotiable Rules added**, including never recording a resolution as
  applied without verifying the artefact changed.

---

## What was deliberately NOT built, and why

**Clause-to-scenario traceability.** Designed and sequenced last, not implemented.
Assigning stable IDs across ten documents and tagging 219 scenarios is itself a large
hand edit — precisely the operation measured at 17–27% regression. It should be done
*with the other checks already running*, not before them.

Note the workflow **already has this concept**: the `sufficiency-check` contract's
*Manifest Clause Validation and Consistency Gate* requires stable IDs and states that
a prose restatement must carry its clause ID and match. That rule exists for
architecture clauses. **Every regression measured here is that same rule, applied to
spec clauses, unenforced.** Extending its scope is a smaller change than it appears.

**Automatic detection of an inverted scenario** — one asserting the opposite of its
own rule (finding #21). Not mechanically decidable: no script can evaluate whether a
Then follows from a clause. Traceability makes it *reviewable* by bounding the
comparison. Claiming more would be the false confidence this work exists to remove.

---

## Integration notes and risks

| Item | Note |
|---|---|
| Registry formats | Markdown tables, same family as every other spec artefact. No new format to learn, and human-readable when the check is not running. |
| Probe precision | The CONSTANT check covers a curated high-risk probe set, not all 43 registered constants. A precise check over the important ones is worth more than a noisy one over all. **A noisy check is worse than none** — the first draft here produced 351 findings, almost all false, and had to be rebuilt. |
| Retired-term registration | Terms must be **backticked and specific**. A bare common word (`gallery`, `everything`) collides with ordinary prose and trains everyone to ignore the check. |
| Pragma | `<!-- consistency:retired-ok -->` declares a legitimate mention and exempts the rest of the section. Declaring an exception is honest; widening a heuristic until it guesses correctly is an arms race with English. |
| Deletion | The hook cannot remove files. Superseded artefacts go to `_to_delete/` for the Product Engineer — see finding #9, still open. |
| False-positive risk | Real. Mitigated by scoping the CONSTANT check to spec artefacts only (logs legitimately quote superseded values while recounting history), stripping dates, requiring a unit adjacent to a value, and matching probes on word boundaries. |

## Verification performed

- **Mutation test.** Artefacts copied; one defect of each class injected — a retired
  term, a contradicted constant, an orphaned glossary term. All three caught. The
  unmutated copy clean. Copy discarded, originals untouched.
- **Hook test.** A file containing a retired term blocked with exit 1 and an
  actionable message; a clean file passed with exit 0.
- **`apply_resolution.py` test.** Refuses a zero-match edit (the failure that caused
  both false log entries), refuses an ambiguous multi-match edit, applies and verifies
  a good one.
- **Full sweep.** The current 71-artefact specification passes clean.
- **Formatting-variance mutations (added 2026-08-26).** The four mutations above were
  all authored on a single line, and they hid a latent hole: matching was line-scoped,
  so a multi-word term wrapped across a line break passed the blocking gate entirely.
  The suite now injects each defect **wrapped as well as unwrapped**, and asserts the
  negative case too — a glossary term used only in wrapped form must NOT be reported
  as unused. See finding #29. **A mutation suite proves teeth only against the defect
  shapes it injects, and a suite written by the checker's own author injects the shapes
  the checker already handles.** Any prose-consuming check integrated into the template
  should carry a formatting-variance axis: wrapped, indented, emphasised, table-split.

## A caution for whoever integrates the two-line window

The first implementation of the wrapped-term window fired **four false positives**, all
of the same shape: a blank line preceding a legitimate cut record ("Purchase price ...
were cut on review"). The window inherited the *first* line's exemptions, and a blank
line has none, so the blank line laundered the exempt line into a finding. In a
**blocking** gate that is the worst possible failure — it stops honest work.

Two conditions make it safe, and both are load-bearing:

1. The next line must carry no cut-record marker and no `consistency:retired-ok` pragma
   of its own.
2. The term must match in the **joined** text while matching in **neither line alone**.
   A match contained in one line is that line's to report, on its own iteration, under
   its own exemptions.

Without (2) the window double-reports; without (1) it fires on every blank line above a
cut record. Do not integrate the window without both.

## Two more traps for whoever integrates the constant check

Both were found by the gate firing on honest work while a real constant was added.

**Strip your own registry's vocabulary before reading numbers.** `C-043` contains the
digits 043. Cited next to a unit it parses as the value 43 and gets reported as
contradicting a different constant. The gate then taxes the single behaviour that most
reduces drift — citing an ID instead of restating a number — and rewards restating it.
`C-056` escaped only because no unit happened to follow it, so this is luck-dependent,
not rare.

**A constant with no probe is unchecked, and nothing says so.** The probe table is
hand-maintained; adding a row to `constants.md` protects nothing by itself. A registry
that looks authoritative while covering only some of its rows is worse than an obviously
partial one, because every clean run reads as full coverage. Recommend the template
build **coverage reporting** — the checker stating which constants it can actually
detect a contradiction in. This instance did NOT build it; see finding #31.

## Findings this handoff answers

#21 (partially — bounded review, not automatic detection), #22, #24, #25, #29, #30.
Still open: #9 (no mechanism for retiring a superseded artefact), #16, #17, #18, #31.
Newly opened by this instance: #28 (sibling glossary terms varying on different axes —
no mechanical check can see it; recommend an orthogonality question in the critique
loop) and #31 (unprobed constants are silently unchecked; recommend coverage reporting).
