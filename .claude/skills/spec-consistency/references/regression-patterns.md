# Regression Patterns: the three shapes, as worked cases

Read when triaging a consistency finding, or when deciding whether an edit is
complete. Every example below is measured, not hypothetical — each was found by an
independent adversarial scan of a real specification after a remediation pass that
believed itself finished.

## Contents

- [R-1 One-sided edit](#r-1--one-sided-edit)
- [R-2 New prose against unreconciled schema](#r-2--new-prose-against-unreconciled-schema)
- [R-3 A value contradicting a stated constant](#r-3--a-value-contradicting-a-stated-constant)
- [The class no script can catch](#the-class-no-script-can-catch)

---

## R-1 — One-sided edit

**Shape:** a fact is *restated* in two artefacts. One is corrected; the other is not.

**The tell:** both texts still exist and only one was touched. Nothing is missing, so
nothing points at anything, so no reference check can detect it. Only a comparison
of the two statements finds it.

### Case: the searched-attribute list, corrected in both directions

Scan 2 found the list of searched attributes correct in the field map and stale in
the data model. The remediation corrected the data model.

Scan 3 found the identical defect **with the two documents swapped** — the data model
now correct, the field map now stale. The remediation had introduced the mirror image
of the finding it was resolving.

*Lesson:* fixing one side of a restatement is not fixing the defect. It relocates it.
When a finding names two documents, both are in scope for the edit.

### Case: the erasure cascade that lost an entity

A new entity was added to the erasure cascade in two documents in the same pass. In
one of them, an existing entity was dropped from the sentence in the process — the
edit rewrote a list rather than appending to it. No scenario asserted that entity's
erasure, so nothing failed.

*Lesson:* an edit that rewrites a list must be diffed against the list it replaces.

**Prevention:** register the fact in `constants.md` and let restatements be checked,
or stop restating it and reference the owner.

---

## R-2 — New prose against unreconciled schema

**Shape:** behaviour is written without revisiting the field table it must run
against. The prose is coherent; the schema is coherent; together they are impossible.

### Case: the two Bill Evanses

A person-matching rule was written stating that where an incoming artist identity
contradicts a stored one for the same name, a **second person is created** — because
two musicians sharing a name is common in jazz. A scenario asserted it.

The `Person` entity retained `name` **unique per owner**. The scenario was
unsatisfiable against the schema. A build agent must either violate the constraint
silently or fail the scenario.

*Lesson:* a rule about how rows are created is a claim about the constraints on those
rows. Write the rule, then read the field table.

### Case: the column three entities do not have

The ownership rule read "every collection entity carries `owner_id`". Three owned
entities — tracks, credits, photographs — carry only a foreign key to their parent
record. The load-bearing security invariant named a column that does not exist on the
entities it was protecting.

*Lesson:* a rule quantified over "every entity" must be checked against every entity.

**Prevention:** not mechanical. Clause traceability bounds the review — the rule names
the entities it governs, so the comparison is finite.

---

## R-3 — A value contradicting a stated constant

**Shape:** a scenario or paragraph hard-codes a number owned elsewhere.

### Case: fifty records at a page size of twenty

A scenario was added asserting that after one "load more", the collector is shown
**fifty** distinct records. The list page size was twenty. A conforming build shows
forty and **fails**; a build with no pagination at all shows fifty and **passes**.

The scenario was written *in direct response to* a finding that pagination had no
coverage. The remediation produced a test that rewards the defect.

*Lesson:* a scenario's arithmetic is a restatement of a constant. Derive it from the
registry, never from memory.

### Case: the rationale that outlived its numbers

Page sizes changed from 20/24 to 10/12. Every scenario was updated. The paragraph
*explaining why the numbers were what they were* still derived 20 and 24, two
paragraphs below the rule stating 10 and 12 — and quoted a scenario line that no
longer existed anywhere.

*Lesson:* prose that justifies a value is a restatement of it.

**Prevention:** the CONSTANT check, with word forms and derived forms registered.

---

## The class no script can catch

**A scenario asserting the opposite of its own rule.**

The collation rule strips a leading article, so *The Beatles* sorts under B and
precedes *Chet Baker*. The scenario written to exercise that rule asserted **Chet
Baker before The Beatles** — the answer that surname inversion would give, which the
rule explicitly rejects.

A conforming build fails it. A build with no article-stripping passes it. It was the
only scenario covering the rule, so the suite actively enforced the defect.

This is strictly worse than a toothless assertion: a toothless test fails to catch a
defect; an inverted test demands one.

**No script can evaluate whether a Then follows from a clause.** What traceability
provides is a bounded review — the scenario names its clause, so checking it is one
comparison rather than a hunt. Anything more would be false confidence of exactly the
kind this skill exists to remove.
