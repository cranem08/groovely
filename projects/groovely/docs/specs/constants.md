# Constants — Groovely

**Status:** DRAFT — awaiting Product Engineer review
**Machine-read by:** `.claude/hooks/validate-artefact.sh` (blocking)

## What this document is

**The single authoritative source for every number and enumeration in the
specification.** Every constant below is owned here. Other artefacts may restate a
value in prose or in a scenario, but a restatement that disagrees with this table is
a defect, and the hook blocks the write that introduces it.

This exists because the measured failure mode of remediation is the **one-sided
edit**: a value corrected where it is cited and left stale where it is restated.
Across three adversarial scans that shape produced findings every time — a page-size
rationale citing superseded numbers, a searched-attribute list fixed in one document
and broken in another, an erasure cascade that lost an entity. A fact restated in
five places has five chances to drift and no mechanism to notice.

## The rule

**Changing a constant: this table first, dependents after.** Update the value here,
then update every artefact that restates it. Each write passes as it is corrected.
Edit a dependent first and the hook blocks you with your own half-finished change.

Where a scenario's arithmetic depends on a constant — "shown ten records rather than
two hundred" — the dependency is recorded in the *Depends* column so a change here
names the scenarios that must move with it.

**PROVISIONAL** marks a value that is specified precisely enough to build and verify
but is **not yet earned** — it awaits validation by exploratory use and is expected
to change. It is a first-class state, not a hedge.

---

## Collection and presentation

| ID | Constant | Value | Word form | Depends |
|---|---|---|---|---|
| C-001 | Page size, list view | 10 | ten | `browse-collection`, `result-order`, `returning-to-the-collection` — **PROVISIONAL** |
| C-002 | Page size, grid view | 12 | twelve | `browse-collection`, `returning-to-the-collection` — **PROVISIONAL** |
| C-003 | Records per collection (benchmark, not a cap) | 10000 | ten thousand | `non-functional.md` |
| C-004 | Search minimum query length | 2 | two | `search-matching` |
| C-005 | Search maximum query length | 100 | — | `ui-field-map.md` |

## Authentication

| ID | Constant | Value | Word form | Depends |
|---|---|---|---|---|
| C-010 | Lockout threshold, consecutive failures | 5 | five, fifth, four (n−1) | `account-lockout` |
| C-011 | Lockout duration, minutes | 15 | fifteen | `account-lockout` |
| C-012 | Password minimum length | 12 | twelve | `password-length` |
| C-013 | Password maximum length | 128 | one hundred and twenty eight | `password-length` |
| C-014 | TOTP digits | 6 | six | `security.md` |
| C-015 | TOTP period, seconds | 30 | thirty | `authenticator-challenge` |
| C-016 | TOTP accepted drift, periods | 1 | one | `security.md` |
| C-017 | Recovery codes issued | 10 | ten | `authenticator-enrolment`, `recovery-codes` |
| C-018 | Session idle expiry, days | 30 | thirty, twenty nine (n−1) | `session-termination` |
| C-019 | Session absolute expiry, days | 90 | ninety | `session-termination` |
| C-020 | Trusted device duration, days | 30 | thirty, twenty nine (n−1) | `trusted-device-expiry` |
| C-021 | Verification link lifetime, hours | 24 | twenty four | `email-verification` |
| C-022 | Reset link lifetime, minutes | 60 | sixty | `password-reset-link-expiry` |

## Records and their contents

| ID | Constant | Value | Word form | Depends |
|---|---|---|---|---|
| C-030 | Earliest permitted release year | 1889 | — | `add-record-manually` |
| C-031 | Maximum discs per record | 20 | twenty | `box-set-track-limit` |
| C-032 | Highest track side | Z | — | `box-set-track-limit` |
| C-033 | Discs fully track-listable (C-032 ÷ 2) | 13 | thirteen, fourteen (n+1) | `box-set-track-limit` |
| C-034 | Maximum tracks per record | 200 | two hundred | `data-model.md` §9 |
| C-035 | Maximum credits per record | 200 | two hundred | `data-model.md` §11 |
| C-036 | Photographs per record | 1 | one | `sleeve-photographs` |
| C-037 | Maximum photograph **upload** size, MiB | 10 | ten, twelve (over) | `sleeve-photographs` |
| C-038 | Maximum photograph **upload** dimension, px | 8192 | — | `ui-field-map.md` |
| C-040 | **Stored** photograph dimension, longest edge, px | 1000 | one thousand, one thousand and one (over) | `sleeve-photographs`, `data-model.md` §8, `export.md` — **PROVISIONAL** |
| C-041 | Stored photograph encoding quality (JPEG) | 80 | eighty | `data-model.md` §8 — **PROVISIONAL** |
| C-042 | Expected stored bytes per photograph, MB (derived from C-040, C-041) | 0.19 | — | `data-model.md` §8, `export.md`, `non-functional.md` — **PROVISIONAL** |
| C-039 | Permitted barcode lengths, digits | 8, 12, 13 | eight, twelve, thirteen | `barcode-validation` |

## Retention, performance and limits

| ID | Constant | Value | Word form | Depends |
|---|---|---|---|---|
| C-050 | Tombstone retention, days (exact) | 90 | ninety | `non-functional.md`, `data-model.md` §5a |
| C-051 | Search / filter response, p95 ms | 300 | — | `non-functional.md` |
| C-052 | Collection interactive, cold, seconds | 2.5 | — | `non-functional.md` |
| C-053 | Collection interactive, warm, seconds | 1.5 | — | `non-functional.md` |
| C-054 | External lookup hard timeout, seconds | 10 | ten | `lookup-unavailable` |
| C-055 | Barcode decode from camera frame, seconds | 2 | two | `non-functional.md` |
| C-056 | Export archive size cap, GiB | 2 | two | `export.md` |

## Enumerations

| ID | Enumeration | Values |
|---|---|---|
| C-070 | Format | `LP`, `EP`, `7"`, `10"`, `12" single`, `Box set`, `Picture disc`, `Flexi disc` |
| C-071 | Speed (rpm) | `33⅓`, `45`, `78` |
| C-072 | Genre | `Blues`, `Brass & Military`, `Children's`, `Classical`, `Electronic`, `Folk, World, & Country`, `Funk / Soul`, `Hip-Hop`, `Jazz`, `Latin`, `Non-Music`, `Pop`, `Reggae`, `Rock`, `Stage & Screen` |
| C-074 | Search scope | `artist` (default), `album`, `track`, `label`, `catalogue number` |
| C-075 | Sort key | `artist`, `title`, `release year`, `date added` (default), `acquisition date` |
| C-076 | Collection view | `grid`, `list` (default) |
| C-077 | Photograph **upload** content types | `image/jpeg`, `image/png`, `image/webp` |
| C-078 | Photograph **stored** content type | `image/jpeg` (every upload is re-encoded; see `data-model.md` §8) |
