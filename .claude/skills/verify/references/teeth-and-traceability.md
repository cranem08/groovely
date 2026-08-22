# Reference: Teeth and Traceability — Proving Verify's Own Checks

Verify is the last gate; nothing audits it. So before its verdict counts, verify must
prove its *own* checks are sound. Two obligations per check. All mechanisms are
deterministic tooling — **the LLM is never in the mutation loop** (an agent inventing and
applying mutants each run would cost unbounded tokens and is the wrong tool). The agent's
only cost is one-time authoring of harnesses and counter-examples, amortised across runs.

## 1. Traceability (both ways)

- **Downward:** every spec clause maps to at least one check. A clause with no check is a
  gap — blocking. (Completeness of coverage.)
- **Upward:** every check maps to exactly one clause ID. A check with no clause is
  ungrounded — it may be testing something the spec never said — blocking. (No rogue
  checks.)

The traceability index built in the verify procedure is the artefact that proves this; it
is part of the report.

## 2. Teeth (proven, not assumed)

A check that stays green when the guarded thing is broken proves nothing. Verify
demonstrates each check *fails* when its rule is violated, using a mechanism matched to
the cost of the surface.

### Structure — mechanized mutation (cheap)

For each structural clause, apply its manifest **counter-example(s)** as scripted patches
to an ephemeral copy of the artefact (add the forbidden import, drop the index, downgrade
the pin), and/or run standard mutation operators via the project's mutation command
(named in `commands-map.yaml`). Assert the check **fails on each mutant** and **passes on
the clean copy**. Require multiple mutants per rule, including near-miss variants — a
single counter-example is necessary but not sufficient (a string-match check can catch its
one example and miss neighbours). A surviving mutant = a toothless check = blocking finding.

### Behaviour — cheaper but real

Full app mutation plus re-running browser tests is compute-heavy, so instead:

- **Expected-outcome inversion:** flip the test's own expected value; if the test still
  passes, its assertion is inert — blocking.
- **Known-broken reference:** run the behavioural suite against a small deliberately
  non-conforming reference build; every test that should catch the break must fail. A test
  green against the broken reference is toothless — blocking.

## Order

Teeth and traceability are established **before** verify trusts any green from the real
run. A check that fails either obligation is fixed (or its clause repaired) before a
verdict is issued. This is "red-before-green" applied to the gate itself.
