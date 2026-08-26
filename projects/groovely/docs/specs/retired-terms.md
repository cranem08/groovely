# Retired Terms — Groovely

**Status:** DRAFT — awaiting Product Engineer review
**Machine-read by:** `.claude/hooks/validate-artefact.sh` (blocking)

## What this document is, and how it differs from out-of-scope

A **retired term** names a concept this product has **abandoned**. The idea was
considered, specified in some cases, and then rejected on principle. Its vocabulary
no longer means anything here, and its appearance in any artefact is a **defect** —
residue of an incomplete removal, or a build agent reintroducing something the
product decided against.

That is not the same as **out of scope**. An out-of-scope item is *postponed*: the
concept remains valid, the vocabulary still means something, and it may return in a
later release. Collection statistics are out of scope. The wantlist is retired.

| | Out of scope | Retired |
|---|---|---|
| Status of the idea | Valid, postponed | Abandoned |
| Vocabulary | Still meaningful | Meaningless here |
| Appearing in an artefact | Expected, in `out-of-scope.md` | **A defect** |
| Recorded in | `out-of-scope.md` | This document |

## The rule

A retired term MUST NOT appear in any artefact, with two exceptions: this document,
and a line explicitly marked as a record of the retirement (a `— cut` heading, or a
row in `out-of-scope.md` explaining the decision). The hook enforces this on every
write and **blocks**.

**Ordering when retiring a term:** purge the term from every artefact *first*, then
add it here. Registering it first blocks your own cleanup.

**Registering a term:** write it in backticks, and make it specific enough to be
unambiguous. Only backticked terms are read by the check. A bare common word —
`gallery`, `everything`, `photograph` — collides with ordinary prose and makes the
check fire on innocent lines, which trains everyone to ignore it. Register the phrase
that carries the concept (`photograph gallery`), not the word that happens to name it.

---

## Retired

| Term and its variants | Retired | Why | Decision recorded in |
|---|---|---|---|
| `wantlist`, `wantlist entry`, `promote to their collection` | 2026-08-25 | Failed **P5**. It records what the collector does not own, while Groovely is about the collection they have — and Discogs' wantlist works only because it is wired to a marketplace Groovely cannot and should not replicate. | `product-log.md`, `out-of-scope.md` |
| `media condition`, `sleeve condition`, `condition notes`, `Goldmine` | 2026-08-24 | Subjective between graders, decays with play, and — decisively — lost its only consumer when the condition filter was cut. A captured field nothing reads is pure surface. | `data-model.md` §5c |
| `purchase price`, `purchase currency`, `purchase source`, `purchase details` | 2026-08-22 | A self-entered price is not evidence of value for any claim, and the information belongs wherever financial records are already kept. | `out-of-scope.md` |
| `max_price`, `maximum price`, `price ceiling` | 2026-08-25 | Marketplace equipment under **P5** — it exists to decide whether a transaction is worth doing, which is Discogs' job. | `product-principles.md` |
| `preferred_currency`, `supported-currency list`, `ISO 4217 exponent` | 2026-08-25 | Supporting machinery for prices that no longer exist. No entity carries an amount. | `data-model.md` Conventions |
| `rating of a record`, `star rating` | 2026-08-22 | A rating judges the music, not the copy, and is incoherent under a copy-centric model — two copies of one album would carry two independent ratings. | `data-model.md` §5e |
| `scope set to everything`, `Everything (default)` | 2026-08-25 | Replaced by the rule that the collector always states what they are searching for. A blended scope made the conjunction domain ambiguous. | `non-functional.md` Search semantics |
| `photograph gallery`, `primary image`, `photograph position` | 2026-08-25 | Replaced by two named slots. Naming the slots dissolves the ordering problem by construction. | `data-model.md` §8 |
| `cover image`, `cover_image_url` | 2026-08-26 | Superseded by `catalogue image` / `catalogue_image_url`. The old name tangled two independent axes — *which face* of the sleeve (front, back) and *whose picture* it is (the collector's, or one a lookup supplied). "Cover" reads as the face, so the collector's photograph and a "cover image" appeared to be the same kind of thing when they are not. | `glossary.md`, `data-model.md` §5, `product-log.md` |
| `display_name` | 2026-08-24 | Collections are private; nothing displays it. | `out-of-scope.md` |
| `play count`, `last played`, `play tracking` | 2026-08-22 | Manual counters get abandoned; an always-zero column is an unspecified extra. | `out-of-scope.md` |
| `free-text tags`, `user-defined tags` | 2026-08-22 | Fragments silently at scale. Structured personnel credits cover the motivating use case properly. | `out-of-scope.md` |
| `filter by condition`, `filter by person`, `filter by credited person` | 2026-08-24 | Condition filtering lost the field it filtered on; filtering by person duplicated `browse-by-person`, giving two implementations of one result set. | `out-of-scope.md` |

## Awaiting a ruling

These were cut but it is not yet settled whether they are **retired** or merely
**out of scope**. They are excluded from the blocking check until decided.

| Term | Question |
|---|---|
| filter by `decade` | Cut because it could not be justified beyond "the field existed" — but the concept is coherent and could return. Postponement or abandonment? |
| `collection statistics` | Recorded as deferred to a later release. Confirm it is a postponement, not a retirement. |
