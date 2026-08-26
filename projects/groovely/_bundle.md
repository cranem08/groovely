# GROOVELY SPECIFICATION BUNDLE (revision 3)
## AUTHORITATIVE BDD STANDARD
```
# BDD Scenario Format (Authoritative Standard)

This standard defines the **strict BDD format** used across the workflow.
All agents and skills that write, validate, or group BDD scenarios MUST
follow these rules.

## Format Rules

- **Exactly one** Given, **one** When, **one** Then per scenario
- **AND is prohibited** — if you want AND, split into multiple scenarios.
  *Clarification: this bans the `And` step keyword. A scenario has exactly three
  steps. A conjunction **within** a single step is permitted only where the joined
  items are parameters of one action or facets of one observable outcome — e.g.
  "submits the registration form with an email address and a password". If the
  conjunction joins two actions or two outcomes, split the scenario.*
- Given = pre-existing state (declarative, no actions)
- When = one user-initiated action at the system boundary
- Then = one observable outcome visible to the user or external consumer
- Scenarios describe **what happens**, never **how it is implemented**
- Use "the user" or named actors, not system-centric language
- Use only defined domain terms; flag undefined vocabulary

## Splitting a Scenario

When a scenario feels too large, apply one of these patterns:

1. **Multiple outcomes** → one scenario per outcome
2. **Multiple preconditions** → separate the state setup into distinct scenarios
   or use Background (one Given per scenario still)
3. **Multiple actions** → each action becomes its own scenario with its own
   outcome

## Given Rules

- Given contains state (declarative, not actions)
- Given uses domain language, not technical/database language
- Example: `Given the user has an active subscription` (not "database contains
  subscription record")

## When Rules

- When describes a user action at the boundary, not a system action
- When describes the triggering action, not an internal process
- Example: `When the user requests a password reset` (not "When system
  validates token")

## Then Rules

- Then describes an observable, user-visible outcome
- Then uses user-visible language, not technical endpoints
- Example: `Then the user is shown a confirmation message` (not "database
  record updated")

## Vocabulary Rules

- Use only defined domain terms (from glossary or spec)
- If a new term is needed, define it in the domain glossary first
- Use consistent naming: if one scenario says "order" don't use "purchase"
  elsewhere for the same concept
- Refer to "the user" or named actors, never "the system" or "the service"
```

===== FILE: docs/specs/data-model.md =====

# Data Model — Groovely MVP

**Status:** DRAFT — awaiting Product Engineer review
**Phase:** discover
**Tier 1 rule applied:** every field declares type, default, and a domain-plausible
constraint. Every user-editable field additionally declares its UI input component
and allowed values in `docs/designs/ui-field-map.md`.

Every open question raised during drafting has been resolved; no decision markers
remain.

---

## Conventions

| Concern | Rule |
|---|---|
| Primary keys | UUID v7, server-assigned, immutable, never reused |
| Timestamps | `timestamptz`, UTC, microsecond precision |
| Soft delete | `deleted_at` nullable tombstone on every entity **owned by** an account (records, tracks, credits, people, filing names, photographs). Tombstones exist so a future mobile client can learn during a sync what was deleted; a row that simply vanished would be invisible to it. |
| Hard delete | The **account-erasure path alone** hard-deletes. It removes the `Account` row itself and every row it owns, tombstoned rows included. `Account` therefore carries no `deleted_at` — a deleted account has no client left to sync, so a tombstone would serve nobody, and retaining one would keep the unique email address occupied and prevent the collector ever registering again. |
| Sync | Every user-owned entity carries `updated_at` and a monotonic `version` (bigint, incremented on every write) so a future mobile client can perform a delta pull |
| Text fields | UTF-8, NFC-normalised on write, trimmed of leading/trailing whitespace, control characters rejected |
| Money | **Groovely stores no monetary values.** Purchase price was cut on review, and the wantlist ceiling with it, so the entire currency apparatus that existed to support them — a supported-currency list, an account currency, per-entry currency and an ISO 4217 exponent rule — has been removed. No entity carries an amount. |
| Ownership | `Record`, `Person` and `ArtistFilingName` carry `owner_id` directly. `Track`, `Credit` and `RecordImage` are owned **transitively** through their `Record`, and carry no `owner_id` of their own. Every query is scoped by the owning `Record`'s or `Account`'s `owner_id` at the data-access layer — never by filtering in the UI. Stated explicitly because the earlier wording asserted a column three of these entities do not have. |

---

## 1. Account

The collector. One account owns exactly one collection.

| Field | Type | Default | Constraint | Editable |
|---|---|---|---|---|
| `id` | UUID v7 | generated | immutable | No |
| `email` | citext | — | required, unique, RFC 5322, 3–254 chars, lowercased | **No** — not changeable in the MVP. Changing an email address is a genuine account-takeover surface needing re-verification of both addresses and enumeration-safe errors; it is not worth opening for a private catalogue. |
| `email_verified_at` | timestamptz? | `null` | set once on verification | No |
| `password_hash` | text | — | Argon2id, m=19456 KiB, t=2, p=1 | No |
| `password_updated_at` | timestamptz | now | — | No |
| `preferred_view` | enum | `list` | One of: `grid`, `list` | Yes |
| `failed_password_attempts` | smallint | `0` | 0–5, reset on success | No |
| `locked_until` | timestamptz? | `null` | ≤ now + 15 min | No |
| `created_at` / `updated_at` | timestamptz | now | — | No |

**`display_name` was cut.** Collections are private, so nothing displays it, and an
unused field is an unspecified extra that would fail the verify gate. Recorded in
`out-of-scope.md`.

---

## 2. TotpEnrolment

One per account. Mandatory — an account without a completed enrolment cannot
reach any collection route.

| Field | Type | Default | Constraint |
|---|---|---|---|
| `account_id` | UUID | — | PK, FK Account, unique |
| `secret` | bytea | — | 160-bit, encrypted at rest with a key held outside the database |
| `algorithm` | enum | `SHA1` | fixed `SHA1` (universal authenticator support) |
| `digits` | smallint | `6` | fixed `6` |
| `period_seconds` | smallint | `30` | fixed `30` |
| `drift_periods` | smallint | `1` | fixed `1` (±30s) |
| `last_accepted_counter` | bigint? | `null` | strictly increasing — rejects replay within the window |
| `enrolled_at` | timestamptz | — | set when the first valid code is confirmed |
| `failed_attempts` | smallint | `0` | 0–5 |

---

## 2b. VerificationToken and ResetToken

Two entities of identical shape, one per purpose. Both were implied by scenarios
asserting single use and expiry, and neither existed in the model.

| Field | Type | Default | Constraint |
|---|---|---|---|
| `id` | UUID v7 | generated | — |
| `account_id` | UUID | — | FK Account |
| `token_hash` | text | — | Argon2id of a 256-bit random token. The raw token appears only in the emailed link and is never stored. |
| `issued_at` | timestamptz | now | — |
| `expires_at` | timestamptz | — | **Verification: issued_at + 24 hours. Reset: issued_at + 60 minutes.** |
| `consumed_at` | timestamptz? | `null` | Single use — a consumed token is never accepted again |

Issuing a new token of either kind invalidates any outstanding token of that kind
for the account. An expired and a consumed token are indistinguishable to the
visitor: both say the link is no longer valid, so neither becomes an oracle.

## 3. RecoveryCode

Ten rows created at enrolment. Regenerating replaces the whole set.

| Field | Type | Default | Constraint |
|---|---|---|---|
| `id` | UUID v7 | generated | — |
| `account_id` | UUID | — | FK Account |
| `code_hash` | text | — | Argon2id of a 10-char Crockford base32 code |
| `used_at` | timestamptz? | `null` | single use — a consumed code is never accepted again |
| `generation` | smallint | `1` | incremented on regeneration; prior generations invalidated |

---

## 4. Session

| Field | Type | Default | Constraint |
|---|---|---|---|
| `id` | UUID v7 | generated | opaque; the cookie carries a separate high-entropy token, hashed at rest |
| `account_id` | UUID | — | FK Account |
| `created_at` | timestamptz | now | — |
| `last_seen_at` | timestamptz | now | drives the 30-day rolling expiry |
| `absolute_expires_at` | timestamptz | now + 90d | hard cap, never extended |
| `revoked_at` | timestamptz? | `null` | set on sign-out, password change, or erasure |

**No `user_agent` or `ip_address` is stored against a session.** Both are personal
data under UK GDPR and neither is required by any agreed clause. Groovely does not
collect what no requirement needs. Recorded in `out-of-scope.md`.

---

## 5. Record

**One row = one physical copy the collector owns.** Two copies of the same album
are two rows, each with its own storage location, notes, acquisition date and
sleeve photographs.

### 5a. Identity and sync

| Field | Type | Default | Constraint |
|---|---|---|---|
| `id` | UUID v7 | generated | immutable |
| `owner_id` | UUID | — | FK Account |
| `created_at` / `updated_at` | timestamptz | now | — |
| `version` | bigint | `1` | monotonic, incremented per write |
| `deleted_at` | timestamptz? | `null` | tombstone, retained ≥ 90 days for client sync |

### 5b. Release metadata — copied onto the record at the moment the collector confirms it

Once confirmed these are the collector's own data, not a cache of Discogs content.
Groovely never refreshes them from Discogs.

| Field | Type | Default | Constraint | Source |
|---|---|---|---|---|
| `artist` | text | — | **required**, 1–200 chars | lookup or typed |
| `title` | text | — | **required**, 1–200 chars | lookup or typed |
| `label` | text? | `null` | 1–100 chars | lookup or typed |
| `catalogue_number` | text? | `null` | 1–50 chars | lookup or typed |
| `release_year` | smallint? | `null` | 1889 ≤ y ≤ current year + 1 | lookup or typed |
| `country` | char(2)? | `null` | ISO 3166-1 alpha-2 | lookup or typed |
| `format` | enum | `LP` | one of: `LP`, `EP`, `7"`, `10"`, `12" single`, `Box set`, `Picture disc`, `Flexi disc` | lookup or typed |
| `disc_count` | smallint | `1` | 1–20. See the stated limit in §9: a box set of more than 13 discs can be **catalogued**, but its track listing can only be recorded as far as side Z. |
| `speed_rpm` | enum | `33⅓` | one of: `33⅓`, `45`, `78` | lookup or typed |
| `colour` | text? | `null` | 1–50 chars (e.g. "translucent blue") | typed |
| `genres` | enum[] | `{}` | 0–5 values from the enumerated list below | lookup or typed |
| `barcode` | text? | `null` | Exactly 8, 12 or 13 digits — EAN-8, UPC-A or EAN-13 respectively — with a valid modulo-10 check digit computed for that symbology. The earlier range of 8–14 admitted lengths (9, 10, 11, 14) matching none of the named symbologies, for which "checksum-valid" had no defined meaning. | scanned or typed |
| `discogs_release_id` | integer? | `null` | > 0 — provenance reference only, never re-fetched | lookup |
| `cover_image_url` | text? | `null` | absolute HTTPS URL, ≤ 2048 chars | lookup |

> **The 15 permitted genre values** (verified against the Discogs database
> guidelines, not recalled): `Blues`, `Brass & Military`, `Children's`,
> `Classical`, `Electronic`, `Folk, World, & Country`, `Funk / Soul`, `Hip-Hop`,
> `Jazz`, `Latin`, `Non-Music`, `Pop`, `Reggae`, `Rock`, `Stage & Screen`.
> Stored as a database enum, so the values must be literal — a reference to a third
> party's list is not something a schema can be built from.

> **Note on `release_year` minimum.** 1889 is the earliest commercially issued disc
> record. A lower bound of 1889 rejects typos like `189` while admitting anything a
> collector could plausibly own.

### 5c. Condition — **cut**

Goldmine grading (`media_condition`, `sleeve_condition`, `condition_notes`) was
specified and then removed on review. Three reasons, the last decisive:

1. **Subjective.** Goldmine grades are notoriously inconsistent between graders —
   one collector's VG+ is another's VG.
2. **Transitory.** Condition decays with every play and every shelf move.
3. **No consumer.** Its only use in the system was the media-condition filter,
   which was itself cut. A captured field that nothing reads is schema,
   validation, form UI, export columns and verification surface for no function —
   and under Rule 7 an unrequested field must fail the gate.

What is lost: distinguishing the player copy from the clean copy when two are
owned. `notes` covers this better — "player copy, slight surface noise side 2"
says more than "VG+" does.

### 5d. Acquisition

Financial fields were considered and **cut**: a self-entered price is not evidence
of value for any insurance or loss claim, and the information is better kept
wherever the collector already keeps financial records. Only the date survives,
because "when did this join the collection" is a different question from "when did
I catalogue it" — and the two diverge sharply when entering a collection owned for
decades.

| Field | Type | Default | Constraint |
|---|---|---|---|
| `acquired_on` | date? | `null` | 1889-01-01 <= d <= today |

**Cut:** `purchase_price_minor`, `purchase_currency`, `purchase_source`.

### 5e. Collector's own annotations

**Inclusion test applied:** does the field describe *the physical copy on the shelf*,
or *the music pressed into it*? Copy-centric model, so only the former belongs here.

| Field | Type | Default | Constraint | Status |
|---|---|---|---|---|
| `storage_location` | text? | `null` | 1-100 chars | **In MVP.** Free text, imposing no organisational scheme - "Shelf B, 47", "crate under the window", "Mum's loft". Optional and nullable; a collector with no system leaves it empty. |
| `notes` | text? | `null` | <= 2000 chars | **In MVP.** Facts about this copy - "slight warp side 2", "bought in Tokyo, 2019". Sanitised on render. |
| `rating` | - | - | - | **Rejected.** A rating judges the music, not the copy. Under a copy-centric model two copies of one album would carry two independent ratings with no defined meaning and no correct answer for a filter. Rejected on modelling grounds, not cost. |
| `play_count` | - | - | - | **Out of MVP.** Manual counters get abandoned; an always-zero column is an unspecified extra that would fail the verify gate. |
| `last_played_at` | - | - | - | **Out of MVP.** As above. |
| `tags` | - | - | - | **Out of MVP.** A second entity, a management UI, and orphan-cleanup rules - the largest scope item on this page for the least certain payoff. |

## 6. Wantlist — **cut**

A wantlist was specified and then removed under **P5**. It records records the
collector does **not** own, while Groovely is about the collection they have. And
Discogs' wantlist works because it is wired to a marketplace that tells you when a
copy is for sale; Groovely cannot do that and should not try, so its wantlist would
be a notes list presented as a tool.

Removed with it: the promotion flow, the priority vocabulary, four feature files,
the export section, an unspecified UI surface and a 2,000-row scale target.

## 7. Tag — **deferred, documented for completeness**

Not in the MVP. Recorded here so the decision is explicit rather than forgotten.

---

## 8. RecordImage

Photographs the collector takes of their own copy. Distinct from `cover_image_url`,
which is a reference to a Discogs-hosted image and stores no bytes.

**Two named slots, not a gallery.** A record holds at most one front and one back
photograph. Naming the slots dissolves the ordering problem by construction: there
is no primary-image rule to state, no position to store and no reorder control to
build, because front is front. The back slot is kept deliberately — on a jazz record
the back sleeve carries the liner notes and the personnel, which is the part of
these objects the collector values most (P5).

| Field | Type | Default | Constraint |
|---|---|---|---|
| `id` | UUID v7 | generated | — |
| `record_id` | UUID | — | FK Record, cascade on erasure |
| `storage_key` | text | — | opaque object-store key |
| `content_type` | enum | — | `image/jpeg`, `image/png`, `image/webp` |
| `byte_size` | integer | — | ≤ 10 MiB |
| `width` / `height` | integer | — | 1–8192 px |
| `slot` | enum | — | `front` or `back`. **Unique per record** — a record holds at most one of each. |
| `created_at` | timestamptz | now | — |

**Sleeve photographs are IN the MVP, and are core rather than a nice-to-have.**
The Product Engineer's reasoning overruled an earlier recommendation to cut them:
the external database holds no image for a great many older pressings, and where it
does, the image is of *a* copy rather than *this* copy. Under a copy-centric model
the collector's own photograph is authoritative — see principle P4.

EXIF stripping is mandatory without exception: phone photographs carry GPS
coordinates, and a location-tagged gallery of a valuable collection is a
physical-safety risk, not merely a privacy one.

---

## 9. Track

What is printed on the sleeve as being on the record. Groovely holds no audio and
plays nothing — a track listing is part of how the object identifies itself, and
in practice the means by which one pressing is told from another (a reissue with a
bonus track, a different running order, an edited single version).

| Field | Type | Default | Constraint |
|---|---|---|---|
| `id` | UUID v7 | generated | — |
| `record_id` | UUID | — | FK Record |
| `side` | char(1) | `A` | required, a single letter `A`–`Z` |
| `position` | smallint | — | required, 1–99, the track's number on that side |
| `title` | text | — | required, 1–300 chars |
| `duration_seconds` | integer? | `null` | 1–7200 |
| `created_at` / `updated_at` / `version` / `deleted_at` | — | — | as §5a |

**Ordering is `ORDER BY side, position`** and needs no separate sort key: letters
sort correctly as text, numbers as numbers, so A2 precedes A10 without special
handling. The displayed position (`A1`, `B2`) is *derived* by concatenation and is
never stored — storing it alongside its parts would be two representations of one
fact, free to drift apart.

**Stated limit.** Single-letter sides give A–Z: 26 sides, or 13 discs. Discogs uses
`AA`, `BB` beyond that, and those sort wrongly as text (`AA` < `Z` alphabetically
but follows it in a running order). Rather than allow two characters and ship a
silent ordering defect at the fourteenth disc, sides are constrained to A–Z and the
limit is declared.

**What this does and does not prevent.** A box set of any size up to 20 discs can be
catalogued in full — its artist, title, label, catalogue number, format, disc count,
credits, storage location, notes and photographs are all unaffected. The only
restriction is that a **track listing** cannot be recorded past side Z. This is
declared to the collector at the point it applies rather than left to be discovered,
and it is a limitation on one optional field, not on cataloguing the object.

Maximum 200 tracks per record. Tracks are pre-filled
from the `tracklist` block of a lookup and typed from the sleeve otherwise. Always
optional: a record with no tracks is valid and saves without prompting.

**Searchable.** Track titles are matched by collection search alongside artist,
title, label and catalogue number. A result matched on a track title MUST show
which track caused the match — a record appearing in results for no visible reason
is a defect, not a feature.

## 9b. ArtistFilingName

Lets the collector file an artist where a record shelf would put them, without the
software ever guessing whether a name belongs to a person or a group.

| Field | Type | Default | Constraint |
|---|---|---|---|
| `id` | UUID v7 | generated | — |
| `owner_id` | UUID | — | FK Account |
| `artist_name` | text | — | required, 1–200 chars, unique per owner (case- and accent-folded). The artist string it applies to. |
| `filing_name` | text | — | required, 1–200 chars — e.g. `Davis, Miles` |
| `created_at` / `updated_at` / `version` / `deleted_at` | — | — | as §5a |

**Sort key for a record's artist** is, in order: the `filing_name` matching its
`artist` if one exists; otherwise the `artist` with a leading `The `, `A ` or `An `
removed. Comparison uses an ICU `en_GB` collation.

Setting a filing name applies to **every record carrying that artist string**,
present and future — the collector sets it once, not once per record. Automatic
surname inversion is deliberately not attempted: no reliable signal distinguishes
Miles Davis from Weather Report, and the failure is silent.

## 10. Person

A musician or member of recording personnel. Scoped to one collector: two
collectors never share a person row, so nobody's catalogue can be affected by
anyone else's data.

| Field | Type | Default | Constraint |
|---|---|---|---|
| `id` | UUID v7 | generated | — |
| `owner_id` | UUID | — | FK Account |
| `name` | text | — | required, 1–200 chars. **Not unique on its own.** Uniqueness is on (`owner_id`, folded `name`, `discogs_artist_id`) treating nulls as equal — so one collector may hold two people named Bill Evans provided they carry different external identities. An earlier uniqueness on name alone made the two-musicians-sharing-a-name rule unsatisfiable. |
| `discogs_artist_id` | integer? | `null` | > 0 — set when the person arrived from a lookup; the reliable identity anchor |
| `created_at` / `updated_at` / `version` / `deleted_at` | — | — | as §5a |

**Duplicate prevention** is by selection, not by matching: the credit input offers
people already in the collection as the collector types, so a person is chosen
rather than retyped. Where duplicates arise anyway, a **merge** action reassigns
every credit from one person to another and tombstones the surrendered row.

## 11. Credit

Links a person to a record in a stated role. This is the entity that answers
"every record I own featuring Miles Davis, leader or sideman" — a question no
external database can answer, because none of them knows which copies are yours.

| Field | Type | Default | Constraint |
|---|---|---|---|
| `id` | UUID v7 | generated | — |
| `record_id` | UUID | — | FK Record |
| `person_id` | UUID | — | FK Person |
| `track_id` | UUID? | `null` | FK Track. **Null means the credit applies to the whole record** — the ordinary case. Set it where personnel change between tracks, which for jazz is common: albums are frequently assembled from sessions recorded months apart with different lineups. One nullable column rather than a second credit system. |
| `role` | text | — | required, 1–60 chars, from the suggested role list or free text |
| `is_primary_artist` | boolean | `false` | true where the person is the credited artist of the release rather than a contributor — this is the leader/sideman distinction |
| `position` | smallint | `0` | 0–199, display order |
| `created_at` / `updated_at` / `version` / `deleted_at` | — | — | as §5a |

Unique on (`record_id`, `person_id`, `role`, `track_id`) — the same person may hold
two roles on one record (e.g. trumpet and arranger), and may hold the same role on
several tracks, but not the same role twice at the same level.

**Source.** Credits are pre-filled from the `extraartists` block of the external
lookup when the collector confirms a candidate release — including the per-track
`extraartists` carried inside the tracklist, which populate `track_id` — and typed from the sleeve
notes otherwise. Credits are always optional: a record with none is valid, and no
save is ever blocked by their absence.

**Suggested roles** (free text permitted beyond these): Leader, Vocals, Trumpet,
Saxophone, Tenor Saxophone, Alto Saxophone, Piano, Bass, Double Bass, Drums,
Guitar, Trombone, Flute, Organ, Percussion, Arranger, Composer, Conductor,
Producer, Engineer, Recording Engineer, Liner Notes, Photography, Design.

## 12. TrustedDevice

Lets a collector skip the authenticator challenge on a device they have already
proven control of. Reduces recurring friction without lowering the security floor.

| Field | Type | Default | Constraint |
|---|---|---|---|
| `id` | UUID v7 | generated | — |
| `account_id` | UUID | — | FK Account |
| `token_hash` | text | — | hash of a high-entropy cookie value; the raw token is never stored |
| `label` | text? | `null` | 1–60 chars, collector-supplied |
| `trusted_at` | timestamptz | now | — |
| `expires_at` | timestamptz | now + 30d | hard cap, never extended without a fresh challenge |
| `revoked_at` | timestamptz? | `null` | set on revocation, password change, or erasure |

Trust is revoked for **all** devices on a password change and on erasure. The
collector can revoke any device individually from account settings.

## Erasure cascade

Account deletion **hard-deletes**, in one transaction: the `Account` row itself,
`TotpEnrolment`, all `RecoveryCode`, all `Session`, all `TrustedDevice`, all
`Record` (including tombstoned rows), all `Track`, all `Credit`, all `Person`, all
`ArtistFilingName`, and all `RecordImage` rows **together with their stored
objects**.

Because the `Account` row is removed rather than tombstoned, the email address is
released and the collector may register again with it. Exercising an erasure right
must not carry a permanent penalty. Nothing
survives except anonymous, non-attributable aggregate counters — of which we
currently specify none.


===== FILE: docs/specs/errors.md =====

# Error Taxonomy — Groovely MVP

**Status:** DRAFT — awaiting Product Engineer review

Every error assertion in the feature files takes the form "shown a message stating
…". This document supplies what those assertions point at: the trigger, the copy,
what happens to the collector's work, and whether anything is retried. Without it,
each message is an implementer's invention.

## Universal rules

1. **Input is never lost.** Any rejected submission returns with every field as the
   collector left it. Losing a half-completed record to a validation error or a
   dropped connection is the failure most likely to make someone abandon the app.
2. **Errors are stated in plain language**, name what happened, and say what to do
   next. No codes, no jargon, no blame.
3. **Validation runs on the server** and is mirrored in the browser for speed. The
   server is authoritative; the browser is a convenience.
4. **Authentication errors stay uniform** — see `security.md`. They never reveal
   whether an account exists or which factor failed, with the single stated
   exception for a locked account given the correct password.

## Connection loss

The browser MVP is **online-only** (P3). Losing connection is therefore a specified
operating condition, not an unforeseen failure.

| Aspect | Behaviour |
|---|---|
| Detection | The collector is shown a persistent banner stating Groovely needs a connection. |
| Reading | Whatever is already on screen stays usable. Nothing is cleared. |
| Writing | Blocked, with a message stating the change was not saved because there is no connection. |
| Input | Preserved in full. When the connection returns, the collector resubmits with one action. |
| Recovery | The banner clears itself when connectivity returns. No reload is required. |

## Error classes

| Class | Trigger | Copy | Retry | State |
|---|---|---|---|---|
| Validation | A field fails a data-model constraint | Names the field and the rule ("A release year must be between 1889 and next year") | None — the collector corrects it | Form preserved |
| Authentication | Wrong credentials, wrong code | Uniform text per `security.md` | None | Form preserved except the password field |
| Lockout | Five consecutive failures | Uniform, unless the password was correct | None | Form preserved |
| External lookup unavailable | Discogs unreachable, rate-limited, or slower than 10s | States lookups are temporarily unavailable, offers manual entry | 1 retry with backoff, then give up | Manual entry offered |
| Breach screening unavailable | HIBP unreachable | Silent — **fail open**, password accepted, event logged | None | Proceeds |
| Email delivery failure | Transactional mail rejected | Silent to the visitor; the message shown is unchanged | 3 retries with exponential backoff | A resend affordance exists |
| Photograph upload failure | Object store unreachable or rejects | States the photograph could not be saved; the record itself saves | 1 retry | Record saved, photograph absent |
| Photograph read failure | Object store unreachable on read | A placeholder is shown in place of the image | None | Record otherwise intact |
| Export too large | Archive would exceed 2 GiB | States the export is too large and offers a data-only export | None | Offer presented |
| Server fault | Any unhandled 5xx from Groovely's own backend | States something went wrong at Groovely's end and the change was not saved | None | Form preserved |
| Not found or not yours | A record belonging to another account, or no record | States the record was not found — **identical in both cases**, so ownership cannot be probed | None | — |

===== FILE: docs/specs/export.md =====

# Export Contract — Groovely MVP

**Status:** DRAFT — awaiting Product Engineer review

Export is how principle **P2 — the data is the collector's** is discharged. A
catalogue you cannot take away from its host is not yours. The contract below exists
because "a file containing the records they own" constrains a row *set* and never a
row's *contents*: without it, a file of bare identifiers satisfies the requirement.

## What is produced

A single **zip archive**, named `groovely-export-{YYYY-MM-DD}.zip`, containing:

| Path in archive | Contents |
|---|---|
| `collection.json` | Every entity, nested. The lossless, round-trippable form. |
| `records.csv` | One row per record, flat |
| `tracks.csv` | One row per track, keyed to its record |
| `credits.csv` | One row per credit: person, role, record, track (blank where whole-record) |
| `people.csv` | One row per person, with a count of **records** they appear on — the same number the People view shows, so the file and the screen never disagree |
| `photographs/` | The image files themselves, named `{record_id}-front.{ext}` and `{record_id}-back.{ext}` |
| `README.txt` | Plain-English description of each file and column |

**Photographs are included as files, not as links.** The hosted URLs stop resolving
when an account is deleted — which is precisely the situation an export exists for.
An export that references images the collector can no longer fetch would discharge
P2 in name only, and under P4 the collector's own photograph is the authoritative
image of their copy.

## What `collection.json` contains

Every field of every entity the collector owns, using the field names in
`data-model.md`:

- **records** — all release metadata, `acquired_on`, `storage_location`, `notes`,
  with nested `tracks[]`, `credits[]` and `photographs[]`
- **people** — id, name, external artist id
- **account** — email and `created_at` only. No password hash, no TOTP secret, no
  recovery codes, no session or trusted-device data ever appears in an export.

Tombstoned (soft-deleted) rows are **excluded**. The export is what the collector
has, not what they once had.

## Constraints

| Concern | Rule |
|---|---|
| Scope | Exactly the requesting collector's own data. No other account's row may appear in any file. |
| Size cap | 2 GiB. Beyond that the export fails with a message offering a data-only export without photographs. |
| Encoding | UTF-8 throughout. CSV per RFC 4180, comma-separated, CRLF, header row present. |
| Dates | ISO 8601. |
| Delivery | Synchronous download. No emailed link, so no dependency on mail delivery for a data right. |
| Empty collection | Still produces a valid archive, with headers and no data rows. Never a zero-byte file. |

===== FILE: docs/specs/glossary.md =====

# Domain Glossary — Groovely

**Status:** DRAFT — awaiting Product Engineer review

`standards/bdd.md` requires that scenarios use only defined domain terms. Every
term used in a `.feature` file must appear here. A term not defined here may not
be used in a scenario.

## Actors

| Term | Definition |
|---|---|
| **visitor** | A person with no Groovely account, or whose identity is not established in this scenario. May register, sign in, or request a password reset. Nothing else. |
| **collector** | A person who owns a Groovely collection. Identity is established by signing in and answering the authenticator challenge — but a collector who has signed out, or who is part-way through signing in, is still the collector, because the account is theirs. Owns exactly one collection. |

> The earlier definition tied *collector* to being currently authenticated, which made
> it impossible to name the actor in the scenarios that matter most — signing out and
> then attempting access, deleting an account and then attempting access. Ownership,
> not session state, is what distinguishes the two actors.

There is no administrator. No other actor exists in the MVP.

## Core objects

| Term | Definition |
|---|---|
| **record** | One physical copy of a release that the collector owns. Two copies of the same album are two records. |
| **collection** | The complete set of a collector's records. |
| **release** | A published edition of a recording, as identified in an external music database. Not a thing Groovely stores — a record is *derived* from a release at the moment the collector confirms one. |
| **candidate release** | One of the releases Groovely offers the collector after a lookup. Nothing is stored until the collector confirms one. |
| **sleeve photograph** | An image the collector has taken of their own copy, held in one of two named slots — **front** or **back**. Authoritative over any external image. |
| **person** | A musician or member of recording personnel, as named on a sleeve or returned by a lookup. Scoped to one collector. |
| **track** | An item printed on the sleeve as being on the record, identified by its side-and-position (A1, B2). Groovely holds no audio. |
| **credit** | A person's stated role on one record, or on one track of it — "Miles Davis, trumpet". Always optional. |
| **credited artist** | A credit marking the person as the artist of the release rather than someone who played on it. This is the leader half of the leader-versus-sideman distinction. |
| **contributor** | A credited person who is not the credited artist — the sideman half. Every credit is a contributor unless marked otherwise. |
| **cover image** | An externally hosted image referenced by URL. Used only when no sleeve photograph exists. |

## Record attributes

| Term | Definition |
|---|---|
| **acquisition date** | When the record joined the collection. Distinct from when it was catalogued. |
| **storage location** | Free text describing where the collector keeps the record. Imposes no organisational scheme. |
| **notes** | Free text about this copy. |

## Actions and mechanisms

| Term | Definition |
|---|---|
| **lookup** | Asking an external music database for candidate releases, by barcode or by text. |
| **scan** | Using the device camera to read a barcode. |
| **match** | A term matches an attribute when it is a prefix of one of that attribute's words, compared with case and accents folded. All terms in a query must match. |
| **search scope** | Which attribute a search examines: artist (the default), album, track, label or catalogue number. **The collector always says what they are looking for** — there is no blended search across attributes. Every term in the query must match within a single value of the chosen attribute. A result is always a record. |
| **filing name** | The name under which an artist is sorted, where the collector has set one — "Davis, Miles". Applies to every record carrying that artist. |
| **sort direction** | Whether an ordering runs ascending or descending. Text keys default to ascending, date keys to descending. |
| **collection view** | How the collection is laid out: a grid of sleeves or a list of rows. The collector chooses; the choice is remembered. |
| **manual entry** | Creating or completing a record by typing its details, without a lookup. Always available. |
| **confirm** | The collector selecting one candidate release, at which point its values are copied onto their record as their own data. |

## Authentication

| Term | Definition |
|---|---|
| **acceptable password** | At least 12 and at most 128 characters, and not present in the known-breach corpus. |
| **breached password** | A password found in the known-breach corpus. |
| **authenticator code** | A six-digit time-based code from the collector's authenticator app. |
| **authenticator enrolment** | The one-time process of registering an authenticator app. Mandatory. |
| **recovery code** | One of ten single-use codes issued at enrolment, usable in place of an authenticator code. |
| **locked** | The state of an account after five consecutive failed password attempts, or five consecutive failed authenticator code attempts. Lasts fifteen minutes, always ends, and is not extended by attempts made during it. |
| **trusted device** | A device on which the collector has completed an authenticator challenge and chosen to skip it for thirty days. |

## Release attributes

Terms naming things printed on a record or its sleeve.

| Term | Definition |
|---|---|
| **format** | The physical form of the object. One of: `LP`, `EP`, `7"`, `10"`, `12" single`, `Box set`, `Picture disc`, `Flexi disc`. Scenarios use these exact labels, because they are also what the interface displays and therefore what a verification run locates them by. |
| **label** | The record label that issued the release — Blue Note, Impulse, Prestige. |
| **catalogue number** | The label's own identifier for a release, printed on the sleeve and the disc — BLP 1577. Distinguishes pressings that share an artist and title. |
| **release year** | The year the release was issued. |
| **side** | Which face of which disc a track is on, as a letter A to Z. |
| **position** | A track's number on its side. Displayed as side and position together — A1, B2. |
| **barcode** | The machine-readable number on a sleeve, of 8, 12 or 13 digits. Absent from most pressings made before the 1980s. |

## Flows and things the collector is shown

| Term | Definition |
|---|---|
| **registration form** | Where a visitor supplies an email address and a password to create an account. |
| **verification link** | The single-use link emailed to a new account's address, valid for 24 hours. |
| **password reset link** | The single-use link emailed on request, valid for 60 minutes. |
| **current password** | The password in force, which a collector must supply to set a new one. |
| **external music database** | The third-party service a lookup queries. Named as a thing only where a scenario concerns its availability or its data; otherwise scenarios say *lookup*. |
| **breach screening service** | The third-party service consulted to establish whether a password appears in a known breach. |
| **archive** | The single zip file an export produces. |
| **match attribution** | The line beneath a search result stating what matched and its value, where the match was on something other than the record's own artist or title. |

## Deliberately undefined

**"user"** is not a defined term in Groovely. Scenarios must say *visitor* or
*collector*, because the two have materially different permissions and using a
single word for both hides that difference.

===== FILE: docs/specs/integrations.md =====

# External Integrations — Groovely MVP

**Status:** DRAFT — awaiting Product Engineer review

**Four** external dependencies. All are reached from Groovely's own backend; no
third-party credential is ever present in the browser.

---

## 1. Discogs API

**Role:** lookup convenience only. Discogs is never the system of record (P1).

| Aspect | Value |
|---|---|
| Base | `https://api.discogs.com` |
| Auth | Personal access token or OAuth 1.0a, server-side only |
| Rate limit | 60 requests/minute authenticated (25 unauthenticated), moving average over 60 s |
| Rate-limit headers | `X-Discogs-Ratelimit`, `-Used`, `-Remaining` — MUST be read and respected |
| Cost | Free at time of writing; Discogs reserves the right to charge |

### Endpoints used

| Purpose | Endpoint |
|---|---|
| Barcode lookup | `GET /database/search?barcode={barcode}&type=release` |
| Text lookup | `GET /database/search?artist=&release_title=&type=release` |
| Release detail, including credits | `GET /releases/{id}` |

The release detail response carries a `tracklist` block (position, title,
duration) and an `extraartists` block listing credited personnel and their roles.
Individual tracklist entries carry their own `extraartists`, which populate
track-level credits. These are offered to the collector as credits when
they confirm a candidate release, and — like every other field — become the
collector's own data on confirmation. Groovely never re-fetches them.

### Terms-of-use constraints — binding on the design

Discogs' API Terms of Use state that content may not be displayed if it is more
than **six hours** older than what is on their site, and may not be cached longer
than necessary to provide the service.

**How Groovely complies.** Discogs data is *never* held as a cache. It is
presented to the collector as a set of candidate releases; when the collector
confirms one, the values are **copied onto their record as their own data** —
data they could equally have typed by hand. Groovely never subsequently
re-fetches or refreshes a saved record from Discogs. `discogs_release_id` is
retained as a provenance reference only.

Cover art is stored as a **URL reference**, not as bytes, and rendered from
Discogs' own CDN — so no image content is cached. Where the collector supplies
their own photograph, that image is authoritative (P4) and the Discogs URL is
not used.

### Parsing a track listing — binding on the design

The external `tracklist` gives `position` as **free text**: `A1`, `1`, `1-1`, a bare
`A` for a side-long piece, or empty for a heading row. Groovely's model requires a
`side` letter and an integer `position`, so several real values map to nothing.

| Incoming | Behaviour |
|---|---|
| `A1`, `B12` — a letter followed by digits | Parsed to side and position |
| `A-1`, `A.1` — letter, separator, digits | Parsed to side and position |
| `1`, `1-1`, `A`, empty, or anything else | Offered to the collector in the confirm step with **side and position blank**, for them to complete |

Nothing is saved until every offered track has a valid side and position. **No
track is silently dropped, and no side or position is ever invented** — a fabricated
fact about the object is worse than a blank the collector fills in. `duration`
arriving as `"5:37"` is parsed to seconds; anything unparseable is left empty.

### Matching a credited person — binding on the design

Confirming a release creates credits in bulk with no selection step, so the
duplicate-prevention-by-selection rule does not apply on this path.

1. If the incoming person carries an external artist id that matches a person
   already in the collection, **reuse that person**.
2. Otherwise, if the incoming name matches an existing person's name exactly after
   case and accent folding, **reuse that person**.
3. Otherwise, **create a new person**.
4. Where an incoming external artist id contradicts the id stored against a person
   of the same name, **create a second person**. Two musicians sharing a name is not
   hypothetical in jazz; surfacing a real distinction is better than silently
   collapsing two people into one. The collector can merge them if they disagree.

### Failure modes — each requires a specified, observable behaviour

| Condition | Required behaviour |
|---|---|
| No candidates for the barcode | Collector is told the barcode was not found and offered manual entry |
| Multiple candidates (reissues share barcodes) | Collector is shown the candidates and must choose one; nothing is saved until they do |
| Rate limit reached (HTTP 429) | Collector is told lookups are temporarily unavailable and offered manual entry |
| Timeout (>10 s) | As above |
| Discogs unreachable or 5xx | As above |
| Malformed or partial release payload | Fields that are present are offered; absent fields are left empty for the collector to complete |

**No failure of Discogs may prevent a record being added.** Manual entry is
always available (P1).

---

## 2. Have I Been Pwned — Pwned Passwords

**Role:** breach screening on password set and change.

| Aspect | Value |
|---|---|
| Endpoint | `GET https://api.pwnedpasswords.com/range/{first-5-hex-of-sha1}` |
| Auth | None required for the range API |
| Data transmitted | The first 5 hexadecimal characters of the SHA-1 hash **only** |
| Data never transmitted | The password, or its complete hash |

### Failure mode

| Condition | Required behaviour |
|---|---|
| Unreachable, timeout, or 5xx | **Fail open** — the password is accepted and the event is logged. An outage must never prevent registration or a password change. |

---

---

## 3. Transactional email delivery

**Role:** delivering email-verification and password-reset links. Nothing else.

Specified provider-agnostically; the concrete service is a design-phase decision.

| Aspect | Value |
|---|---|
| Messages sent | Email verification link; password reset link. No marketing, no notifications, no digests. |
| Credential | Server-side only |

### Failure mode

| Condition | Required behaviour |
|---|---|
| Delivery rejected, timeout, or provider unreachable | **Registration and reset still succeed.** The message shown to the visitor is unchanged — it must not become an oracle for delivery success. Delivery is retried three times with exponential backoff. A "resend" affordance exists. |

A mail outage must never prevent a visitor registering.

---

## 4. Object storage

**Role:** holding sleeve photographs. Specified provider-agnostically.

| Aspect | Value |
|---|---|
| Stored | Collector-supplied sleeve photographs only |
| Keys | Opaque and non-enumerable |
| Access | Served only to the owning collector |
| Deletion | Objects are destroyed with their rows on account erasure |

### Failure modes

| Condition | Required behaviour |
|---|---|
| Upload fails | The collector is told the photograph could not be saved. **The record itself still saves.** One retry. |
| Read fails | A placeholder is shown in place of the image; the record is otherwise intact |

---

## Explicitly NOT integrated

MusicBrainz, the Cover Art Archive, any email beyond verification and password
reset, any analytics or telemetry service, any payment provider, any social
platform. Each would be an
unspecified external dependency and must fail the verify gate if present.

===== FILE: docs/specs/non-functional.md =====

# Non-Functional Requirements — Groovely MVP

**Status:** DRAFT — awaiting Product Engineer review

## Scale

| Dimension | Target |
|---|---|
| Records per collection | **At least** 10,000 |
| Tracks per record | 200 (accommodates box sets) |
| Tracks per collection | ~150,000 at a typical 15 per record |
| Credits per record | 200 |
| Photographs per record | 2 — one front, one back |
| Photograph size | <= 10 MiB before processing |
| Collection page size | **PROVISIONAL** — 10 in list view, 12 in grid view |

All performance targets below are stated **at a collection of 10,000 records**.
A target met only on a small collection is not met.

**10,000 is a benchmark, not a ceiling.** Nothing rejects the 10,001st record.
The figure exists so the performance targets have a stated volume; promoting it to a
capacity cap would invent a product rule nobody asked for, and a cataloguing
application that refuses to catalogue is close to self-contradictory. Beyond 10,000
records, performance is **untested, not forbidden**.

## Performance

| Interaction | Target | Measured as |
|---|---|---|
| Collection list interactive, cold | <= 2.5 s | Largest Contentful Paint, simulated 4G, mid-tier mobile |
| Collection list interactive, warm | <= 1.5 s | as above |
| Search / filter response | p95 <= 300 ms | server response time, excluding network. The index spans records **and** their tracks, so this target holds against roughly 150,000 track rows, not 10,000 record rows. |
| Pagination increment | p95 <= 200 ms | server response time |
| Create or update a record | p95 <= 500 ms | server response time |
| Discogs lookup returns candidates | p95 <= 3 s | end to end, user-perceived |
| Discogs lookup hard timeout | 10 s | after which manual entry is offered |
| Barcode decode from camera frame | <= 2 s | from first stable frame to candidate list request |

## Supported platforms

Mobile-first. Usable, not merely functional, on a phone held in one hand.

| Platform | Requirement |
|---|---|
| Chrome, Edge | Latest 2 stable versions, desktop and Android |
| Safari | Latest 2 stable versions, macOS; iOS Safari 16+ |
| Firefox | Latest 2 stable versions, desktop |
| Viewport range | 320 px to 2560 px wide |

**Verification consequence.** The verification project MUST drive the behavioural
suite across Chromium, WebKit and Gecko. A single-engine run does not satisfy this
clause — see workflow finding #5.

## Search semantics

**The collector always states what they are searching for** — an artist, an album, a
track, a label or a catalogue number. There is no blended search across attributes.

Every term in the query must prefix-match a word within **a single value** of the
chosen attribute: "blue train" under Album matches a record titled *Blue Train*, and
does not match a record whose title holds one word and whose track list holds the
other. Comparison is over Unicode-normalised, case-folded, accent-folded text.

This is simpler to state, simpler to build and simpler to verify than a blended
search, and it removes an ambiguity that a combined search document could not resolve:
with no cross-attribute matching there is no question of which attributes a term may
span. Each scope is served by one ordinary index.

Minimum query length is two characters.

**Null placement.** `release_year` and `acquired_on` are nullable, so a total order
over the non-null rows is not a total order over the collection. Nulls sort **last
in both directions** — a record whose year you never recorded should not head the
list in either direction. Stated explicitly because the database default differs by
direction and would otherwise be inherited by accident.

**Artist collation.** The sort key for a record's artist is, in order: the
collector's `filing_name` for that artist if they have set one; otherwise the artist
text with a leading `The `, `A ` or `An ` removed. Comparison uses an ICU `en_GB`
collation. So The Beatles files under B, Miles Davis files under M by default, and
under D once the collector has filed him as "Davis, Miles". Automatic surname
inversion is deliberately **not** attempted: software cannot reliably distinguish a
person from a band, and the same rule that yields "Davis, Miles" yields "Report,
Weather" — silently, so the record is simply not where the collector looks.

Every ordering is total: the chosen sort, then record id. A non-total order makes
sort assertions unverifiable and permits rows to repeat or disappear across page
boundaries.

## Accessibility

WCAG 2.2 Level AA, per `standards/accessibility.md`. No requirements beyond AA
are asserted, so no additional criteria are specified.

Specific consequences worth stating because they constrain the build:
- Every interactive element is reachable and operable by keyboard alone.
- Every control has an accessible name; `verify` locates elements by role and
  accessible name, so an unnamed control is both an accessibility defect and an
  unverifiable one.
- Camera-based scanning MUST have an equivalent non-camera path (manual barcode
  entry and manual record entry), which is already specified.
- Format and match attribution are never conveyed by colour alone.

## Availability

**No numeric availability target is asserted for the MVP.**

This is deliberate and is recorded as workflow finding #3: the Operating Tolerance
Tier 1 rule demands numeric targets for availability, but `verify` is a one-shot
clean-room conformance gate and cannot establish a time-averaged figure such as
99.9% monthly. Asserting a number the terminal gate cannot check would be spec
theatre. Availability belongs to an operational monitoring obligation outside
verify's remit.

## Data retention

| Data | Retention |
|---|---|
| Soft-deleted rows of any kind — records, tracks, credits, people, filing names, photographs | Retained exactly 90 days from deletion, then purged |
| Sessions | purged 30 days after expiry |
| Consumed recovery codes | retained until the set is regenerated |
| Everything, on account erasure | removed immediately and unconditionally |

===== FILE: docs/specs/out-of-scope.md =====

# Out of Scope — Groovely MVP

**Status:** DRAFT — awaiting Product Engineer review

Every item here was considered and **deliberately excluded**. Recording the reason
prevents re-litigation and prevents silent scope creep during build. Under Rule 7,
anything on this list appearing in the built application **fails the verify gate**.

## Deferred to a later release

| Item | Reason |
|---|---|
| Collection statistics and insights | Purely derived from data already captured, so it can be added later at zero migration cost and will light up retroactively. Captured data was prioritised over computed data. |
| Music recommendations | Stated by the Product Engineer as explicitly post-MVP. |
| User-defined free-text tags / crates | Free-text labels fragment silently at scale — four spellings of one musician with no error to warn you. Structured personnel credits (in the MVP) cover the motivating use case properly; arbitrary tagging remains deferred. |
| Play tracking (count, last played) | Manual counters are reliably abandoned; an always-zero column would be an unspecified extra. |
| Bulk import (CSV, Discogs export) | Valuable, but a large slice with its own error-reporting and partial-failure semantics. |

## Deferred to the mobile workflow run

| Item | Reason |
|---|---|
| Offline operation of the browser app | P3 scoped to the mobile apps. Deliberate trade-off to prove the workflow first — see `product-principles.md`. |
| Local-first client store and sync | As above. Acknowledged as the product's hardest requirement and its differentiator. |
| Native iOS and Android applications | A separate workflow run. Blocked at present by workflow finding #1: `verify` has no native mobile harness. |

## Not planned

| Item | Reason |
|---|---|
| Public profiles, sharing, following, any social surface | Collections are private. Stated by the Product Engineer at the first elicitation. |
| Marketplace, trading, for-sale flags, messaging | Would make Groovely a Discogs competitor rather than a personal catalogue, and Discogs' terms forbid using their API to circumvent their marketplace. |
| Administrator role or any operator access to collections | No requirement exists for it. An admin surface would be an unrequested capability. |
| Automatic valuation or price-guide data | Discogs marketplace data is Restricted Data under their terms and may not be used commercially. |
| Multiple collections per account | One account owns one collection and one wantlist. |
| Multi-user or shared collections | Out of the ownership model entirely. |
| Analytics, telemetry, crash reporting, third-party tracking | No requirement exists for it; each would be an unspecified external dependency and personal-data processing nobody asked for. |
| Rating a record | Rejected on modelling grounds: a rating judges the music, not the copy, and is incoherent under a copy-centric model. |
| Condition grading (media, sleeve, condition notes) | Cut on review. Goldmine grades are subjective and inconsistent between graders, decay with play, and — decisively — lost their only consumer when the media-condition filter was cut. A captured field nothing reads is pure surface. `notes` covers the one real use ("player copy, surface noise side 2") more expressively. |
| Filter by condition, decade or credited person | Condition filtering had no field left to filter on; decade could not be justified beyond "the field existed"; filtering by person duplicated browse-by-person, giving two implementations of one result set. |
| All monetary values, and the currency apparatus supporting them | Cut under **P5**. A price ceiling is marketplace equipment — it exists to decide whether a transaction is worth doing, which is Discogs' job and which Discogs already does. Groovely is about the pleasure of owning and cataloguing the object. Removing it also removes the supported-currency list, the account currency, per-entry currency, the ISO 4217 exponent rule and a currency control: no entity carries an amount. |
| Purchase price, currency and seller | Cut by the Product Engineer on review: a self-entered price is not evidence of value for any insurance or loss claim, and the information belongs wherever financial records are already kept. Acquisition date is retained. |
| `display_name` on an account | Nothing displays it. Collections are private. |
| IP address or user-agent recorded against a session | Personal data no requirement needs. |

===== FILE: docs/specs/product-principles.md =====

# Product Principles — Groovely

**Status:** DRAFT — stated by the Product Engineer, awaiting confirmation
**Purpose:** the governing intent every other artefact must be consistent with.
Where a downstream decision conflicts with a principle, the conflict is surfaced,
not reconciled silently.

## P1 — Groovely is not a thin client of Discogs

Discogs is a lookup convenience, never the system of record. The Product Engineer
already has a Discogs account and is deliberately building something different.
Any feature whose value depends on Discogs being reachable is suspect.

## P2 — The data is the collector's

Every field on a record is the collector's own data from the moment they confirm
it. Groovely never treats a record as a cache of someone else's content, never
refreshes it from an external source, and always allows full export.

## P3 — The app works offline — **scoped to the mobile apps**

Offline is a first-class operating mode for the native mobile apps, which hold
their own local data store and let a collector browse and search their catalogue
with no connection.

**The browser MVP is explicitly ONLINE-ONLY.** This is a deliberate, recorded
trade-off, not an oversight: the first objective is to prove the product-workflow
can carry a product of this complexity end to end, and attempting the full roadmap
in the first run risks never finishing. Fail fast.

**Known limitation of that choice:** the browser MVP therefore does not exercise
the capability that most differentiates Groovely from Discogs. The hardest
requirement in the product — local-first storage and sync conflict resolution —
is deferred to the mobile workflow run, where it will be met without the benefit
of having been rehearsed. This is accepted knowingly.

## P4 — The collector's own photograph is the authoritative image

Discogs may hold no image for a pressing, and where it does, the image is of *a*
copy, not *this* copy. A photograph the collector takes of their own sleeve
outranks any external image. EXIF is stripped on upload without exception:
phone photographs carry GPS coordinates, and a location-tagged gallery of a
valuable collection is a safety problem, not merely a privacy one.

## P5 — Groovely is about the joy of collecting, not the business of trading

Stated by the Product Engineer while cutting the wantlist price ceiling:

> "The app is not supposed to be a replacement for Discogs, where this value can be
> set. It is instead about the joy of collecting vinyl records and cataloguing that
> collection."

This is the positive statement P1 was missing. P1 says what Groovely is *not*; P5
says what it is *for*. Anything that exists to evaluate a transaction — prices,
ceilings, valuations, condition-as-value, what a record is worth or might fetch —
belongs to the marketplace, and the marketplace already exists elsewhere. What
belongs here is the record on the shelf, who played on it, what is pressed into it,
where you keep it, and what you remember about it.

---

## The admission test

Discovery is iterative, and good ideas keep arriving. The stopping rule is **not**
"is this outside the defined scope?" — that test is circular, because scope is
defined by the requirements already accepted, so it rejects every new idea and
approves every amended one. Applied literally it would have rejected personnel
credits, the strongest requirement in the project.

The test is anchored to the principles instead, because a new requirement does not
get to rewrite them:

> **A requirement is admitted to the MVP only if it positively SERVES a stated
> principle.** Not merely "does not contradict" one — almost nothing contradicts a
> principle. Anything that fails is recorded as a later-release candidate, however
> good the idea is.

Two sharpenings, each of which has rejected something on sight:

- *Does it describe the object on the shelf, or the music pressed into it?*
  Groovely catalogues objects. (Rejected a per-record rating.)
- *Does it serve the joy of collecting, or is it machinery for trading?*
  (Rejected the wantlist price ceiling, and would have rejected it immediately —
  without any argument about currency exponents.)

**Decisions this test has produced.** It rejected a per-record rating (judges the
music, not the copy), play tracking, collection statistics, and free-text tags. It
admitted personnel credits (serves P1 and P2 — a view of your own collection that
no external database can produce) and track listings (printed on the sleeve, and
the practical means of telling one pressing from another).

A test that has never rejected anything is not a test. This one has.

===== FILE: docs/specs/scope.md =====

# Scope — Groovely MVP

**Status:** DRAFT — awaiting Product Engineer review

## In one sentence

Groovely is a private, browser-based catalogue of the vinyl records a collector
physically owns, where each entry is one copy on their shelf and the data belongs
to the collector rather than to any music database.

## Who uses it

Two actors, no others. A **visitor** may register, sign in, or reset a password.
A **collector** — authenticated and enrolled in two-factor authentication — has
full control of their own collection and no access whatever to anyone else's.
There is no administrator, and no operator can read a collection through the
application.

## What a collector can do

**Get in**
1. Register with an email address and a password of at least twelve characters,
   screened against known breaches.
2. Verify the email address.
3. Enrol an authenticator app — mandatory — and receive ten single-use recovery codes.
4. Sign in with password plus a six-digit code — and optionally mark that device
   trusted, skipping the code there for thirty days.
5. Reset a forgotten password; end sessions everywhere by changing it.

**Add records**
6. Scan the barcode on a sleeve with the device camera and choose from the
   candidate releases found.
7. Type a record in by hand — always available, never a fallback, because older
   pressings carry no barcode.
8. Own two copies of the same album as two independent records.

**Describe records**
9. Record when the record joined the collection.
10. Note where the record is kept, in the collector's own words.
11. Write free-text notes about that particular copy.
12. Photograph the front and back of their own sleeve; those photographs outrank
    any external image.
13. Credit the musicians and recording personnel on a record, each with a role,
    pre-filled from the lookup where available and typed from the sleeve notes
    otherwise. Always optional. A credit may name a single track where the
    personnel change between them.
14. Record the track listing as printed on the sleeve — side and position, title,
    duration. Pre-filled from the lookup, always optional.

**Find records**
15. Browse the collection as a grid of sleeves or a list of rows, paginated. The
    collection is expected to hold at least ten thousand records; nothing rejects
    the record after that.
16. Search by saying what they are looking for — an artist, an album, a track, a
    label or a catalogue number. There is no blended search: the collector states
    the attribute, and every term must match within a single value of it. A result
    is always a record, because the object is what the app is about and artist,
    album and track are attributes it has.
17. Filter by format.
18. Sort by artist, title, release year, date added or acquisition date — filing
    an artist where a record shelf would put them, where they have said so.
19. Browse by person — every record featuring a musician, with their role on each,
    whether they led the session or played on it. This is the question no external
    database can answer, because none of them knows which copies are yours.

**Leave**
20. Export the entire collection as a file.
21. Delete the account from inside the app, erasing everything.

## Where it runs

Mobile-first in the browser. Latest two versions of Chrome, Edge, Firefox and
Safari on desktop; iOS Safari 16+ and Chrome on Android; 320px to 2560px wide.
HTTPS only — the camera will not function otherwise.

## Quality bars

Ten thousand records without feeling slow: search and filter within 300ms at the
95th percentile, collection interactive within 2.5 seconds cold on 4G.
WCAG 2.2 Level AA throughout. No failure of any external service may prevent a
record being added.

## What it deliberately is not

Not a social network, not a marketplace, not a price guide, not a music library, not
a wantlist, and not a thin client of Discogs. The wantlist was specified and then cut
under P5 — see `out-of-scope.md`.

**"Not a music library"** means Groovely catalogues *objects the collector owns*,
not *music they can play*. A music library — iTunes, Plex, Roon, a streaming
service — is organised around recordings and playback: it holds or streams audio,
tracks listening, and treats two copies of an album as one entry because the music
is identical. Groovely inverts each of those: it holds no audio, plays nothing, and
treats two copies as two entries *because the objects differ*. Groovely does record
what is **printed on** the object — its track listing and its personnel — because
that is part of how the object identifies itself, and in practice how one pressing
is told from another. What it never does is hold, play, stream or track the
listening of any audio. No sharing, no public profiles, no trading, no
valuations, no recommendations, no play tracking, no free-text tags, no
statistics, no analytics or telemetry of any kind. Structured personnel credits
ARE included — they are not general-purpose tagging. Full reasoning for each exclusion is in
`out-of-scope.md`.

## What is deferred, not rejected

Offline operation and a local-first store — the product's real differentiator —
belong to the native mobile apps and a later run of the workflow. The browser MVP
is online-only. This is a deliberate trade-off to prove the workflow can carry a
product of this complexity before attempting its hardest requirement.

===== FILE: docs/specs/security.md =====

# Security Constraints — Groovely MVP

**Status:** DRAFT — awaiting Product Engineer review
**Applies:** `standards/security.md`

## Actors and roles

| Role | Description | Permissions |
|---|---|---|
| Anonymous visitor | Not authenticated | Register, sign in, request password reset. Nothing else. |
| Collector | Authenticated, TOTP-verified | Full read and write over **their own** collection, photographs and account. No access to any other account's data by any route. |

There is **no administrator role** in the MVP. No human operator can read a
collector's collection through the application. This is asserted deliberately:
an unspecified admin surface would be an unrequested capability and must fail
the verify gate if present.

## Authentication

- Email and password, self-managed. Passwords hashed with Argon2id
  (m=19456 KiB, t=2, p=1), never logged, never returned by any endpoint.
- Password policy per NIST SP 800-63B: minimum 12 characters, maximum 128,
  all Unicode accepted including spaces, paste permitted, **no composition
  rules**, **no scheduled expiry**.
- Every new or changed password is screened against Have I Been Pwned using
  k-anonymity: SHA-1 the candidate, transmit only the first 5 hex characters
  of the hash, compare suffixes locally. The password and its full hash never
  leave the server. **Fail-open**: if HIBP is unreachable the password is
  accepted and the event is logged.
- TOTP second factor (RFC 6238) is **mandatory**. An account without a completed
  enrolment cannot reach any collection route.
- Ten single-use recovery codes issued at enrolment, stored Argon2id-hashed,
  displayed exactly once, regenerable (which invalidates the previous set).

## Anti-automation

- 5 consecutive failed password attempts locks the account for 15 minutes.
- 5 consecutive failed TOTP attempts locks the account for 15 minutes. The two
  counters are independent; either one reaching 5 sets the lock.
- **The lock always ends.** After 15 minutes it expires and the counter resets to
  zero. Attempts made during a lock do **not** extend it. There is no administrator
  in this product, so a lock that could persist would be an unrecoverable
  self-inflicted denial of service triggered by five typos.
- Counters also reset on a successful sign-in.
- Error messages are **uniform**: they never reveal whether an account exists,
  which factor failed, or whether an email is registered.
- **One exception, and it discloses nothing.** A locked account is told it is locked
  *only when the submitted password is correct*. An attacker enumerating addresses
  does not have the password and therefore only ever sees the uniform message; a
  collector who mistyped four times and then typed it correctly gets a real
  explanation. Disclosure is gated on knowledge the attacker lacks, so both rules
  hold simultaneously.

## Changing a password

A signed-in collector may change their password. Doing so requires **the current
password** — an active session alone is not sufficient. This defends the case that
matters: someone reaching an unlocked, signed-in browser must not be able to seize
the account and lock the owner out of it permanently.

- The new password is subject to the full policy, including breach screening.
- All sessions are revoked, including the one making the change.
- All trusted devices are revoked.
- An incorrect current password counts toward the password lockout counter. Registration and
  password-reset responses are identical for known and unknown addresses.

## Sessions

- Session cookie: `HttpOnly`, `Secure`, `SameSite=Lax`, host-only.
- 30-day rolling idle expiry; 90-day absolute cap that is never extended.
- All sessions revoked on password change, on erasure, and on explicit sign-out.
- A collector may mark a device **trusted** after a successful authenticator
  challenge, skipping the second factor on that device for **30 days**. Trust is
  bound to a hashed, high-entropy cookie value; the raw token is never stored.
  Trust expires absolutely at 30 days and is never silently extended.
- All trusted devices are revoked on password change and on erasure. A collector
  may revoke any device individually from account settings.
- Marking a device trusted is an explicit, unticked-by-default choice. It is never
  the default and never implicit.

## Transport and headers

- HTTPS only. HTTP requests redirect permanently; HSTS asserted.
- A secure context is **architecturally required**, not merely preferred:
  `getUserMedia` will not function without it, so camera scanning depends on it.
- Content Security Policy with no `unsafe-inline` and no `unsafe-eval`, with
  the WASM decoder's requirements accommodated explicitly rather than by
  weakening the policy.

## Authorisation

Every collection query is scoped by `owner_id` at the data-access layer, not by
filtering in the UI. A request for a record the collector does not own returns
the same response as a request for a record that does not exist.

## Photograph handling

- EXIF metadata is stripped on upload **without exception**. Phone photographs
  carry GPS coordinates; a location-tagged gallery of a valuable record
  collection is a physical-safety risk, not merely a privacy one.
- Content type validated by inspecting file contents, never by the declared
  `Content-Type` or the filename extension.
- Stored under opaque, non-enumerable keys. Served only to the owning collector.

## Secrets

- TOTP secrets encrypted at rest with a key held outside the database.
- The Discogs API token is a server-side secret and is never exposed to the
  browser. All Discogs calls are proxied through Groovely's own backend.

## Erasure

Account deletion removes the account, TOTP enrolment, all recovery codes, all
sessions, all trusted devices, all records including tombstoned rows, all credits, all
people, all filing names, and all photograph rows together with their stored
objects, in one transaction. The `Account` row itself is hard-deleted, releasing the
email address so the collector may register again. Nothing
attributable survives.

===== FILE: docs/designs/ui-field-map.md =====

# UI Field Map — Groovely MVP

**Status:** DRAFT — awaiting Product Engineer review

Operating Tolerance Tier 1 blocks any user-editable data field that lacks a
specified UI input component and allowed values. This document supplies both for
every editable field in `docs/specs/data-model.md`.

Accessibility applies throughout: every control has a visible label and an
accessible name; no state is conveyed by colour alone; touch targets are at
least 24x24 CSS px (44x44 preferred). See `standards/accessibility.md`.

---

## Account

| Field | Component | Allowed values | Notes |
|---|---|---|---|
| `email` | Single-line text input, `type="email"` | RFC 5322, 3–254 chars | `autocomplete="username"` |
| password | Password input with a reveal toggle | 12–128 chars, any Unicode | Paste MUST be permitted. `autocomplete="new-password"` on set, `current-password` on sign in. A strength indicator is advisory only and never blocks submission. |
| current password | Password input, `autocomplete="current-password"` | Required when changing a password |
| `preferred_view` | Set by the collection view toggle, not a separate control | grid, list | Default list |
| authenticator code | Single-line text input, `inputmode="numeric"`, `autocomplete="one-time-code"` | Exactly 6 digits | Not six separate boxes — split inputs are a persistent accessibility and paste problem |
| trust this device | Checkbox beneath the authenticator code field, labelled "Trust this device for 30 days" | true / false | **Unticked by default.** Never pre-selected, never implicit. |
| trusted device label | Single-line text input in account settings | 1–60 chars | Optional; helps the collector recognise which device to revoke |
| recovery code | Single-line text input | 10 Crockford base32 chars, case-insensitive, hyphens ignored | |

## Record — release metadata

| Field | Component | Allowed values |
|---|---|---|
| `artist` | Single-line text input | Required, 1–200 chars |
| filing name | Single-line text input, offered beside the artist on the record screen | 1–200 chars, optional. Sets how this artist sorts — "Davis, Miles" — and applies to every record carrying that artist. |
| `title` | Single-line text input | Required, 1–200 chars |
| `label` | Single-line text input | 1–100 chars |
| `catalogue_number` | Single-line text input | 1–50 chars |
| `release_year` | Number input, `inputmode="numeric"` | Integer 1889 – (current year + 1) |
| `country` | Select | ISO 3166-1 alpha-2, country names displayed |
| `format` | Select | `LP`, `EP`, `7"`, `10"`, `12" single`, `Box set`, `Picture disc`, `Flexi disc`. **These strings are also the displayed labels.** Verification locates controls by accessible name, so the display label is load-bearing and is fixed here rather than left to the build. |
| `disc_count` | Number input | Integer 1–20, default 1. Where the count exceeds 13, the track editor states that a track listing can be recorded only as far as side Z. |
| `speed_rpm` | Radio group | `33⅓`, `45`, `78` — default `33⅓` |
| `colour` | Single-line text input | 1–50 chars |
| `genres` | Multi-select, max 5 | The 15 Discogs genre values |
| `barcode` | Single-line text input, `inputmode="numeric"` | Exactly 8, 12 or 13 digits, check digit valid for that length |

## Record — acquisition

| Field | Component | Allowed values |
|---|---|---|
| `acquired_on` | Date input | 1889-01-01 to today; future dates rejected with a message |

Purchase price, currency and seller were cut on review and have no UI.

## Record — collector's annotations

| Field | Component | Allowed values |
|---|---|---|
| `storage_location` | Single-line text input | 1–100 chars. Placeholder must not imply a scheme — e.g. "Where do you keep it?" not "Shelf number" |
| `notes` | Multi-line text area | ≤ 2000 chars, remaining count shown |

## Tracks

| Field | Component | Allowed values |
|---|---|---|
| `side` | Select | A–Z, default A |
| `position` | Number input, `inputmode="numeric"` | Integer 1–99 |
| `title` | Single-line text input | 1–300 chars |
| `duration_seconds` | Single-line text input accepting `m:ss` or `h:mm:ss`, stored as seconds | 1–7200 seconds |

Display position (`A1`, `B2`) is derived from side and position for display and is
never entered or stored directly. Ordering follows side then position; there is no
manual reorder control, because the order is a fact about the record rather than a
preference.

Tracks are pre-filled from a lookup and never required. A record with no tracks
saves without warning or prompt. Maximum 200 per record.

## Credits

| Field | Component | Allowed values |
|---|---|---|
| person name | Single-line text input with a suggestion list drawn from people already in the collection | 1–200 chars. Selecting a suggestion reuses the existing person; typing a new name creates one. The suggestion list is what prevents duplicate people, so it must appear from the first character and be operable by keyboard alone. |
| `role` | Combo box — select from the suggested role list, with free text permitted | 1–60 chars |
| `is_primary_artist` | Checkbox, labelled "Credited artist (not a contributor)" | true / false, default false |
| `track_id` | Select, listing the record's tracks, with a first option of "Whole record" | Any track on this record, or none. Defaults to "Whole record". Hidden entirely when the record has no tracks, since the choice would be meaningless. |
| credit order | Drag handle with keyboard-operable move-up / move-down alternatives | 0–199 |

Credits are never required. A record with no credits saves without warning or
prompt. Adding credits is always available later.

**People view.** A list of every person in the collection with a count of records
they appear on, searchable, sortable by name and by count. Opening a person shows
every record they appear on with their role on each.

**Merge people.** Where duplicates arise, the collector selects two people and
confirms a merge. The confirmation states plainly how many credits will move and
which name survives. The action is not reversible, so it is confirmed explicitly.

## Sleeve photographs

| Field | Component | Allowed values |
|---|---|---|
| front photograph | File input accepting `image/jpeg`, `image/png`, `image/webp`, with `capture` offered on mobile | ≤ 10 MiB, 1–8192 px per side |
| back photograph | As above, a separate labelled control | ≤ 10 MiB, 1–8192 px per side |

Two named slots, not a gallery. There is no ordering control and no primary-image
setting, because the slots are named. The back slot exists deliberately: on a jazz
record the back sleeve carries the liner notes and personnel.

Type is validated by inspecting file contents, never the extension. EXIF is
stripped without exception.

## Collection controls

| Control | Component | Allowed values |
|---|---|---|
| Search | Single-line search input, `type="search"` | 1–100 chars |
| Search scope | Select, adjacent to the search input | Artist (default), Album, Track, Label, Catalogue number |
| Sort direction | Toggle button, accessible name reflecting the current state | Ascending, Descending |
| Filter — format | Multi-select | The eight format values |
| Sort | Select | Artist, Title, Release year, Date added (default), Acquisition date |
| Collection view | Toggle button group, two options, accessible name reflecting the current view | Grid, List. Remembered between visits. |

**Page size follows the view: PROVISIONAL — 10 in list, 12 in grid.**

Marked provisional because it is not knowable on paper: it depends on tile size,
thumbnail weight and how the scroll feels in the hand. It is specified precisely
enough to build and to verify, and it is expected to change once it has been tried
on a real device with a real collection. A stated number is required
because "shown the first page" is satisfied by an implementation with no pagination
at all, whereas "shown twenty records rather than two hundred" is not.

The two numbers differ because the views differ: a two-column grid of sleeves shows
24 in about three phone screens, while a list row carries a thumbnail and three
lines of text, so 20 is roughly two screens. Images below the fold are lazy-loaded,
so page size does not affect the 2.5s cold-paint target and is purely a question of
how often the collector is interrupted by a Load more.

**Only one filter facet exists: format.** Condition, decade and person were each
specified and then cut on review — person duplicated browse-by-person, condition had
no consumer once grading was removed, and decade could not be justified beyond "the
field existed".

**There is no blended search.** The collector states what they are looking for and
the search examines only that attribute. Every term must prefix-match a word within
**a single value** of it — "blue train" under Album matches a record titled *Blue
Train*, and does not match a record whose title holds one word and whose track list
holds the other.

`notes` and `storage_location` are not searchable by any scope: free text was judged
too broad to search.

**Default sort direction, per key.** Text ascending, dates descending — the
conventional pattern, and the one that puts the most recently acquired records
first. Artist A→Z. Title A→Z. Release year newest first. Date added newest first.
Acquisition date newest first. Direction is carried in the URL alongside the sort
key, so a shared or bookmarked view reproduces exactly.

**Matching rule.** Word-prefix, accent-insensitive, all terms required.

- `Colt` matches Coltrane; `rane` does not. Matching is on word beginnings.
- `miles kind` requires both terms present in the searched attribute, in any order.
- Comparison is on Unicode-normalised, accent-folded, case-folded text, so `Bjork`
  matches `Björk` and the reverse. This is not cosmetic for a jazz collection —
  Dvořák, Jobim, Umiliani and Müller all fail a naive comparison.
- A search runs from **two characters**. One character over ten thousand records
  returns noise.
- An empty or whitespace-only search clears the search term and leaves the filter,
  sort and view untouched.

**Combination rule.** Selecting several formats returns records of any of them (OR
within the facet). A search term narrows the filtered set (AND between search and
filter). Both are asserted by scenarios rather than left to inference.

**Default order.** Date added, newest first. Every ordering is made total by a final
tie-break on record id — without it "ordered by artist" is unverifiable the moment
two records share an artist, and rows can silently duplicate or vanish across a page
boundary.

**Paging is a Load more button**, not infinite scroll: keyboard-operable,
announceable to assistive technology, deterministic for verify to drive, and it
leaves a stable stopping point.

**View, scope, search term, filter, sort, sort direction and page live in the URL.** Opening a
record and pressing back returns the collector exactly where they were, and a
filtered view can be bookmarked or sent to oneself. Switching between grid and list
returns to the first page, because the page sizes differ.

**Search results are always records.** A record is the object the application is
about; artist, title, track and credited person are attributes it has. The scope
selector narrows *which attribute is searched* — it never changes what a result is.
One result shape for every scope, which is also one shape to verify.

Where the scope is Track and a record has several matching tracks, the row lists
each of them.

**Search result attribution.** Where a result matched on something other than the
record's own artist or title — a track title, a label, a catalogue number, a
credited person — the result row MUST state what matched and its value, beneath the
record's artist and title. For example, searching "So What" returns:

> **Kind of Blue** — Miles Davis
> *matched track A1 · So What*

Without it, a collector cannot distinguish a correct track match from a broken
search returning everything. This is also what gives the behavioural scenarios
teeth: "the collector is shown that record" passes even when search is entirely
broken, whereas "the result states it matched the track So What" can only pass if
the match was genuinely on that track.
| Sort direction | Toggle button with accessible name reflecting current state | Ascending, Descending |

===== FILE: docs/features/account-lockout.feature =====

```gherkin
Feature: Account lockout

  Five consecutive failed attempts lock an account for fifteen minutes. The lock
  always ends.

  Scenario: A collector exceeds the permitted password attempts
    Given the collector has failed four consecutive password attempts
    When the collector submits a fifth incorrect password
    Then the collector is shown a message stating the email address or password was not recognised

  Scenario: A collector exceeds the permitted authenticator attempts
    Given the collector has failed four consecutive authenticator code attempts
    When the collector submits a fifth incorrect authenticator code
    Then the collector is shown a message stating the code was not accepted

  Scenario: Four failures do not lock the account
    Given the collector has failed four consecutive password attempts
    When the collector submits their correct email address and password
    Then the collector is asked for an authenticator code

  Scenario: A locked account is given the correct password before the lock has elapsed
    Given the collector has a locked account
    When the collector submits their correct email address and password
    Then the collector is shown a message stating the account is temporarily locked

  Scenario: A locked account is given an incorrect password before the lock has elapsed
    Given the collector has a locked account
    When the collector submits their email address and an incorrect password
    Then the collector is shown a message stating the email address or password was not recognised

  Scenario: An unregistered address is submitted five times
    Given the visitor has submitted an unregistered address with a password four times
    When the visitor submits that unregistered address a fifth time
    Then the visitor is shown a message stating the email address or password was not recognised

  Scenario: A locked account after the lock has elapsed
    Given the collector has an account locked more than fifteen minutes ago
    When the collector submits their correct email address and password
    Then the collector is asked for an authenticator code

  Scenario: The counter resets when a lock elapses
    Given the collector has an account locked more than fifteen minutes ago and has since failed one password attempt
    When the collector submits their correct email address and password
    Then the collector is asked for an authenticator code

  Scenario: The counter resets on a successful sign in
    Given the collector has failed four consecutive password attempts, signed in successfully, and since failed one further attempt
    When the collector submits their correct email address and password
    Then the collector is asked for an authenticator code
```

===== FILE: docs/features/add-record-by-scan.feature =====

```gherkin
Feature: Add a record by scanning a barcode

  The collector scans the barcode on a sleeve and Groovely offers candidate
  releases from a lookup.

  Scenario: A scan matches exactly one candidate release
    Given the collector has granted camera access
    When the collector scans a barcode matching one release
    Then the collector is shown that candidate release for confirmation

  Scenario: A collector confirms a candidate release
    Given the collector is shown a candidate release carrying a label, a catalogue number and a release year
    When the collector confirms that candidate release
    Then the collector is shown the new record carrying that release's artist, title, label, catalogue number and release year

  Scenario: A saved record after the entry it came from is changed externally
    Given the collector owns a record confirmed from a candidate release that has since been retitled in the external music database
    When the collector opens that record
    Then the collector is shown the title the record was confirmed with
```

===== FILE: docs/features/add-record-manually.feature =====

```gherkin
Feature: Add a record by manual entry

  Manual entry is a first-class path, not a fallback. Many older pressings carry
  no barcode at all.

  Scenario: A collector creates a record by typing its details
    Given the collector is on the manual entry screen
    When the collector submits an artist and a title
    Then the collector is shown the new record in their collection

  Scenario: A collector submits manual entry without an artist
    Given the collector is on the manual entry screen
    When the collector submits a title with no artist
    Then the collector is shown a message stating an artist is required

  Scenario: A collector submits a release year outside the permitted range
    Given the collector is on the manual entry screen
    When the collector submits a release year of 1650
    Then the collector is shown a message stating the release year must be between 1889 and next year
```

===== FILE: docs/features/artist-filing-name.feature =====

```gherkin
Feature: Filing an artist where a record shelf would put them

  Groovely never guesses whether a name belongs to a person or a group. The
  collector says so, once, and every record by that artist follows.

  Scenario: An artist with no filing name
    Given the collector owns a record by Miles Davis and a record by Duke Ellington
    When the collector sorts their collection by artist
    Then the collector is shown the record by Duke Ellington before the record by Miles Davis

  Scenario: A collector files an artist under a surname
    Given the collector owns a record by Miles Davis and a record by Duke Ellington
    When the collector files Miles Davis as Davis, Miles
    Then the collector is shown the record by Miles Davis before the record by Duke Ellington

  Scenario: A filing name applies to every record by that artist
    Given the collector owns three records by Miles Davis and has filed him as Davis, Miles
    When the collector adds a fourth record by Miles Davis
    Then the collector is shown that fourth record filed under Davis, Miles
```

===== FILE: docs/features/authenticator-challenge.feature =====

```gherkin
Feature: Authenticator challenge

  The second factor is required on every sign in, except on a device the collector
  has explicitly chosen to trust. See trusted-device.feature.

  Scenario: A collector submits a valid authenticator code
    Given the collector has submitted their correct email address and password
    When the collector submits the current authenticator code
    Then the collector is shown their collection

  Scenario: A collector submits an expired authenticator code
    Given the collector has submitted their correct email address and password
    When the collector submits an authenticator code from more than one period ago
    Then the collector is shown a message stating the code was not accepted

  Scenario: A collector reuses an authenticator code that was already accepted
    Given the collector has signed in using an authenticator code still within its thirty second period
    When the collector submits that same authenticator code again within that period
    Then the collector is shown a message stating the code was not accepted
```

===== FILE: docs/features/authenticator-enrolment.feature =====

```gherkin
Feature: Authenticator enrolment

  Authenticator enrolment is mandatory. No collection may be reached without it.

  Scenario: A visitor completes enrolment with a valid authenticator code
    Given the visitor has verified their email address and not yet completed authenticator enrolment
    When the visitor submits a valid authenticator code for the offered secret
    Then the visitor is shown ten recovery codes

  Scenario: A visitor submits an incorrect authenticator code during enrolment
    Given the visitor has verified their email address and not yet completed authenticator enrolment
    When the visitor submits an incorrect authenticator code
    Then the visitor is shown a message stating the code was not accepted

  Scenario: A visitor attempts to reach the collection before completing enrolment
    Given the visitor has verified their email address and not yet completed authenticator enrolment
    When the visitor navigates directly to the collection
    Then the visitor is shown the authenticator enrolment screen

  Scenario: Recovery codes are shown once
    Given the collector has been shown their ten recovery codes at enrolment
    When the collector returns to their account settings
    Then the collector is not shown those recovery codes again
```

===== FILE: docs/features/barcode-validation.feature =====

```gherkin
Feature: Barcode validation

  Only the three symbologies that appear on records are accepted.

  Scenario: A collector types a valid thirteen digit barcode
    Given the collector is on the manual entry screen
    When the collector submits a thirteen digit barcode with a valid check digit
    Then the collector is shown the new record carrying that barcode

  Scenario: A collector types a barcode of a length matching no symbology
    Given the collector is on the manual entry screen
    When the collector submits an eleven digit barcode
    Then the collector is shown a message stating a barcode must be eight, twelve or thirteen digits

  Scenario: A collector types a barcode whose check digit is wrong
    Given the collector is on the manual entry screen
    When the collector submits a thirteen digit barcode with an incorrect check digit
    Then the collector is shown a message stating the barcode is not valid
```

===== FILE: docs/features/box-set-track-limit.feature =====

```gherkin
Feature: Track listings on a very large box set

  Sides run A to Z. A box set of more than thirteen discs is catalogued in full,
  but its track listing stops at side Z.

  Scenario: A collector catalogues a box set of more than thirteen discs
    Given the collector is on the manual entry screen
    When the collector submits an artist and a title with a disc count of eighteen
    Then the collector is shown the new record with a disc count of eighteen

  Scenario: A collector opens the track editor for an ordinary record
    Given the collector owns a record with a disc count of two
    When the collector opens that record's track listing
    Then the collector is shown no message about side Z

  Scenario: A collector opens the track editor for such a box set
    Given the collector owns a record with a disc count of eighteen
    When the collector opens that record's track listing
    Then the collector is shown a message stating tracks can be recorded only as far as side Z
```

===== FILE: docs/features/breach-screening-unavailable.feature =====

```gherkin
Feature: Breach screening unavailable

  Breach screening fails open. An outage of the external screening service must
  never prevent a visitor from registering.

  Scenario: The breach screening service is unreachable during registration
    Given the breach screening service is unreachable
    When the visitor submits the registration form with an unused email address and a twelve-character password
    Then the visitor is shown a message asking them to check their email for a verification link
```

===== FILE: docs/features/browse-by-person.feature =====

```gherkin
Feature: Browse the collection by person

  The question no external database can answer, because none of them knows which
  copies the collector owns.

  Scenario: A collector opens the list of people in their collection
    Given the collector owns a person credited on three records and a person credited on one
    When the collector opens the list of people
    Then the collector is shown a list crediting the first person on three records and the second on one

  Scenario: A collector opens a person
    Given the collector owns records crediting a person as both credited artist and contributor alongside records not crediting them
    When the collector opens that person
    Then the collector is shown only the records crediting that person with their role on each
```

===== FILE: docs/features/browse-collection.feature =====

```gherkin
Feature: Browse the collection

  Scenario: A collector with no records opens their collection
    Given the collector owns no records
    When the collector opens their collection
    Then the collector is shown a message inviting them to add their first record

  Scenario: A collector opens a collection larger than one page in list view
    Given the collector owns two hundred records and has chosen list view
    When the collector opens their collection
    Then the collector is shown ten records rather than two hundred

  Scenario: A collector opens a collection larger than one page in grid view
    Given the collector owns two hundred records and has chosen grid view
    When the collector opens their collection
    Then the collector is shown twelve records rather than two hundred
```

===== FILE: docs/features/camera-unavailable.feature =====

```gherkin
Feature: Camera unavailable

  Scanning is never the only way to add a record, and a camera that cannot be used
  says so rather than failing silently.

  Scenario: A collector declines camera access
    Given the collector has declined camera access
    When the collector opens the add record screen
    Then the collector is shown a message stating the camera is unavailable

  Scenario: A collector uses a device with no camera
    Given the collector is using a device with no camera
    When the collector opens the add record screen
    Then the collector is shown a message stating no camera was found

  Scenario: Manual entry when the camera cannot be used
    Given the collector has been told the camera is unavailable
    When the collector submits an artist and a title by manual entry
    Then the collector is shown the new record in their collection
```

===== FILE: docs/features/change-password.feature =====

```gherkin
Feature: Change a password

  A signed-in collector may change their password, but must supply the current one.
  A session alone is not sufficient authority to seize an account.

  Scenario: A collector changes their password
    Given the collector is signed in
    When the collector submits their current password together with an acceptable new password
    Then the collector is shown a message confirming their password was changed

  Scenario: A collector submits an incorrect current password
    Given the collector is signed in
    When the collector submits an incorrect current password together with an acceptable new password
    Then the collector is shown a message stating the current password was not recognised

  Scenario: A collector signs in with a changed password
    Given the collector has changed their password
    When the collector submits their email address and the new password
    Then the collector is asked for an authenticator code

  Scenario: A collector signs in with the password they replaced
    Given the collector has changed their password
    When the collector submits their email address and the password they replaced
    Then the collector is shown a message stating the email address or password was not recognised

  Scenario: A collector chooses a breached password
    Given the collector is signed in
    When the collector submits their current password together with a breached new password
    Then the collector is shown a message stating the password has appeared in a known data breach and must be changed

  Scenario: The session that made the change
    Given the collector has changed their password
    When the collector navigates directly to their collection in the same browser
    Then the collector is asked for an email address and a password
```

===== FILE: docs/features/changes-persist.feature =====

```gherkin
Feature: Changes are actually saved

  Every scenario elsewhere asserts what the collector sees in the response to their
  own action. An optimistic update whose write silently failed looks identical.
  These reopen the record to establish that the change reached the collection.

  Scenario: A storage location after the collector returns
    Given the collector has set a record's storage location
    When the collector opens that record from their collection on a later visit
    Then the collector is shown that record with that storage location

  Scenario: A credit after the collector returns
    Given the collector has credited a person on a record
    When the collector opens that record from their collection on a later visit
    Then the collector is shown that record listing that person

  Scenario: A track after the collector returns
    Given the collector has added a track to a record
    When the collector opens that record from their collection on a later visit
    Then the collector is shown that record listing that track

  Scenario: A removed record after the collector returns
    Given the collector has removed one record from a collection of three
    When the collector opens their collection on a later visit
    Then the collector is shown the two records they still own

  Scenario: A removed record is no longer found by a search that matched it
    Given the collector has removed a record that a search for Coltrane used to match
    When the collector searches the artist scope for Coltrane
    Then the collector is shown a message stating no records matched
```

===== FILE: docs/features/collection-isolation.feature =====

```gherkin
Feature: One collector never reaches another's collection

  Ownership is enforced at every query, not only on the record page. Each route
  below runs its own query and so needs its own assertion.

  Scenario: Another collector's record is requested directly
    Given another collector owns a record
    When the collector navigates directly to that record
    Then the collector is shown a message stating the record was not found

  Scenario: A search never reaches another collector's records
    Given another collector owns a record by John Coltrane while the collector owns a different record by John Coltrane
    When the collector searches the artist scope for Coltrane
    Then the collector is shown exactly their own record by John Coltrane

  Scenario: The list of people never includes another collector's people
    Given another collector has credited Paul Chambers while the collector has credited only Bill Evans
    When the collector opens their list of people
    Then the collector is shown exactly one person, named Bill Evans

  Scenario: An export never contains another collector's records
    Given another collector owns a record by Thelonious Monk while the collector owns records by John Coltrane and Bill Evans
    When the collector requests an export of their collection
    Then the collector is given an archive containing exactly the records by John Coltrane and Bill Evans
```

===== FILE: docs/features/collection-view.feature =====

```gherkin
Feature: Choose how the collection is laid out

  Some collectors browse by cover, others scan detail. The choice is remembered.

  Scenario: A collector switches to grid view
    Given the collector is shown their collection as a list of rows
    When the collector switches to grid view
    Then the collector is shown their collection as a grid of sleeves

  Scenario: A collector returns after choosing a view
    Given the collector has chosen grid view
    When the collector opens their collection on a later visit
    Then the collector is shown their collection as a grid of sleeves
```

===== FILE: docs/features/connection-loss.feature =====

```gherkin
Feature: Losing the connection

  The browser app is online-only, so losing connection is a specified operating
  condition rather than an unforeseen failure.

  Scenario: A collector loses their connection while browsing
    Given the collector is shown their collection
    When the collector's connection is lost
    Then the collector is shown a message stating Groovely needs a connection

  Scenario: A collector reads what is already on screen while offline
    Given the collector has lost their connection while shown their collection
    When the collector opens a record already on screen
    Then the collector is shown that record

  Scenario: A collector tries to save while offline
    Given the collector has lost their connection while editing a record
    When the collector saves that record
    Then the collector is shown a message stating the change was not saved because there is no connection

  Scenario: A collector's typing survives losing the connection
    Given the collector has lost their connection while entering a record by hand
    When the collector saves that record
    Then the collector is shown the details they had already typed

  Scenario: A collector resubmits once the connection returns
    Given the collector has been told a record was not saved because there is no connection and the connection has since returned
    When the collector saves that record
    Then the collector is shown the new record in their collection

  Scenario: A collector's connection returns
    Given the collector has lost their connection
    When the collector's connection returns
    Then the collector is no longer shown the message stating Groovely needs a connection
```

===== FILE: docs/features/credits-from-lookup.feature =====

```gherkin
Feature: Credits arriving from a lookup

  Where the external music database holds credited personnel, they are offered to
  the collector without any typing.

  Scenario: A collector confirms a release that has credited personnel
    Given the collector is shown a candidate release with credited personnel
    When the collector confirms that candidate release
    Then the collector is shown the new record carrying those people and their roles

  Scenario: A collector confirms a release that has no credited personnel
    Given the collector is shown a candidate release with no credited personnel
    When the collector confirms that candidate release
    Then the collector is shown the new record with no credits
```

===== FILE: docs/features/credits-manual.feature =====

```gherkin
Feature: Crediting a person by hand

  Credits are always optional. No record is ever prevented from being saved by
  their absence.

  Scenario: A collector credits a person read from the sleeve notes
    Given the collector owns a record with no credits
    When the collector credits a person with the role of tenor saxophone
    Then the collector is shown that record listing that person on tenor saxophone

  Scenario: A collector marks a person as the credited artist
    Given the collector owns a record crediting Miles Davis and Bill Evans as contributors
    When the collector marks Miles Davis as the credited artist
    Then the collector is shown that record listing Miles Davis as the credited artist and Bill Evans as a contributor

  Scenario: A credit is a contributor unless marked otherwise
    Given the collector owns a record with no credits
    When the collector credits a person with the role of piano
    Then the collector is shown that record listing that person as a contributor

  Scenario: A collector credits the same person in a second role
    Given the collector owns a record crediting a person on trumpet
    When the collector credits that same person with the role of arranger
    Then the collector is shown that record listing that person in both roles
```

===== FILE: docs/features/credits-per-track-from-lookup.feature =====

```gherkin
Feature: Per-track credits arriving from a lookup

  A jazz album is frequently assembled from sessions with different lineups, and
  the external database records that per track.

  Scenario: A candidate release crediting a person on one track only
    Given the collector is shown a candidate release crediting a person on its second track only
    When the collector confirms that candidate release
    Then the collector is shown that person credited against that track only

  Scenario: A candidate release crediting a person across the whole record
    Given the collector is shown a candidate release crediting a person with no track named
    When the collector confirms that candidate release
    Then the collector is shown that person credited against the whole record
```

===== FILE: docs/features/credits-per-track.feature =====

```gherkin
Feature: Crediting a person on one track

  Jazz albums are frequently assembled from sessions recorded months apart with
  different lineups, so a credit may apply to one track rather than the record.

  Scenario: A collector credits a person on a single track
    Given the collector owns a record with several tracks
    When the collector credits a person on one of those tracks
    Then the collector is shown that person credited against that track only

  Scenario: A collector credits a person on the whole record
    Given the collector owns a record with several tracks
    When the collector credits a person against the whole record
    Then the collector is shown that person credited against the whole record

  Scenario: A record with no tracks offers no track choice
    Given the collector owns a record with no tracks
    When the collector adds a credit to that record
    Then the collector is not offered a track to attribute the credit to
```

===== FILE: docs/features/credits-person-matching.feature =====

```gherkin
Feature: Matching a credited person arriving from a lookup

  Confirming a release creates credits in bulk with no selection step, so people
  are matched rather than chosen.

  Scenario: A person already in the collection under the same external identity
    Given the collector has a person credited on one record carrying an external artist identity
    When the collector confirms a candidate release crediting that same external artist identity
    Then the collector's list of people shows that person once against a count of two

  Scenario: A person already in the collection under the same name only
    Given the collector has Bill Evans credited on one record with no external artist identity
    When the collector confirms a candidate release crediting Bill Evans with no external artist identity
    Then the collector's list of people shows Bill Evans once against a count of two

  Scenario: Two musicians sharing a name
    Given the collector has a person named Bill Evans carrying one external artist identity
    When the collector confirms a candidate release crediting a different Bill Evans carrying another external artist identity
    Then the collector's list of people shows two people named Bill Evans

  Scenario: A person not previously in the collection
    Given the collector has no person named Paul Chambers
    When the collector confirms a candidate release crediting Paul Chambers
    Then the collector's list of people shows Paul Chambers once
```

===== FILE: docs/features/credits-person-reuse.feature =====

```gherkin
Feature: Reusing a person already in the collection

  Selecting an existing person rather than retyping their name is what prevents a
  collection accumulating several spellings of one musician. Whether it worked is
  observable in the list of people, not on the record.

  Scenario: A collector begins typing the name of a person already credited elsewhere
    Given the collector has credited Miles Davis on one record and Bill Evans on another
    When the collector types Mil into the person name on a third record
    Then the collector is offered Miles Davis and not Bill Evans

  Scenario: A collector selects an offered person
    Given the collector has credited a person on one record and is offered that person on a second
    When the collector selects that person
    Then the collector's list of people shows that person once against a count of two

  Scenario: A collector types a name nobody in the collection carries
    Given the collector has credited Miles Davis on one record
    When the collector credits Paul Chambers on a second record
    Then the collector's list of people shows two people
```

===== FILE: docs/features/delete-account.feature =====

```gherkin
Feature: Delete the account

  Deletion is initiated and completed inside the application.

  Scenario: A collector deletes their account
    Given the collector is signed in
    When the collector confirms deletion of their account
    Then the collector is shown the registration screen

  Scenario: A deleted account is used to sign in
    Given the collector has deleted their account
    When the collector submits the email address and password of the deleted account
    Then the collector is shown a message stating the email address or password was not recognised

  Scenario: A collector deletes an account holding records then registers again
    Given the collector has deleted an account that owned records and registered again with the same email address
    When the collector opens their collection
    Then the collector is shown a message inviting them to add their first record

  Scenario: A sleeve photograph after the account holding it is deleted
    Given the collector has deleted an account that held a sleeve photograph
    When the address that photograph was served from is requested
    Then no image is returned

  Scenario: A second signed-in device after the account is deleted
    Given the collector has deleted their account while signed in on a second device
    When that second device requests the collection
    Then the collector is asked for an email address and a password
```

===== FILE: docs/features/delete-record.feature =====

```gherkin
Feature: Remove a record

  Scenario: A collector removes a record from their collection
    Given the collector owns a record by John Coltrane and a record by Bill Evans
    When the collector removes the record by John Coltrane
    Then the collector's collection shows exactly the record by Bill Evans

  Scenario: A collector removes one of two copies of the same release
    Given the collector owns two records of the same release
    When the collector removes one of those records
    Then the collector's collection shows one record of that release
```

===== FILE: docs/features/duplicate-records.feature =====

```gherkin
Feature: Owning more than one copy of a release

  Two copies of the same album are two records, each with its own storage location,
  notes, acquisition date and sleeve photographs.

  Scenario: A collector adds a release they already own
    Given the collector already owns a record of a release
    When the collector confirms a candidate release for that same release
    Then the collector's collection contains two records of that release
```

===== FILE: docs/features/edit-record.feature =====

```gherkin
Feature: Edit a record

  Scenario: A collector changes a record's storage location
    Given the collector owns a record with no storage location
    When the collector sets that record's storage location
    Then the collector is shown that record with its new storage location

  Scenario: A collector clears a record's notes
    Given the collector owns a record with notes
    When the collector clears that record's notes
    Then the collector is shown that record with no notes
```

===== FILE: docs/features/email-verification.feature =====

```gherkin
Feature: Email verification

  A newly registered account must verify its email address before enrolment.

  Scenario: A visitor follows an unused verification link
    Given the visitor has registered and not yet verified their email address
    When the visitor follows the verification link sent to that address
    Then the visitor is shown the authenticator enrolment screen

  Scenario: A visitor follows a verification link that has already been used
    Given the visitor has already verified their email address
    When the visitor follows the same verification link a second time
    Then the visitor is shown a message stating the link is no longer valid

  Scenario: A collector follows a verification link more than twenty four hours after it was issued
    Given the collector has a verification link issued more than twenty four hours ago
    When the collector follows that link
    Then the collector is shown a message stating the link is no longer valid
```

===== FILE: docs/features/export-collection.feature =====

```gherkin
Feature: Export the collection

  The collector can take their data with them. An export that omits what the
  collector actually owns discharges the principle in name only.

  Scenario: A collector exports a collection carrying tracks and credits
    Given the collector owns one record with two tracks and one credit while another collector owns a record
    When the collector requests an export of their collection
    Then the collector is given an archive containing that one record with its two tracks and its one credit and no other record

  Scenario: A collector exports a collection carrying a sleeve photograph
    Given the collector owns a record with one sleeve photograph
    When the collector requests an export of their collection
    Then the collector is given an archive containing an image file named for that record whose contents are that photograph

  Scenario: A collector with an empty collection exports it
    Given the collector owns no records
    When the collector requests an export of their collection
    Then the collector is given an archive containing column headings and no data rows

  Scenario: An export omits credentials
    Given the collector owns one record by John Coltrane, has enrolled with a known authenticator secret, and holds ten known recovery codes
    When the collector requests an export of their collection
    Then the collector is given an archive in which that record appears and neither that secret nor any of those recovery codes appears

  Scenario: A collector exports a collection containing a removed record
    Given the collector has removed a record from a collection of three
    When the collector requests an export of their collection
    Then the collector is given an archive containing the two records they still own
```

===== FILE: docs/features/filter-collection.feature =====

```gherkin
Feature: Filter the collection

  Format is the only filter facet. It matches how a collection physically exists:
  singles live in a different box from albums.

  Scenario: A collector filters by one format
    Given the collector owns two records of format 7", one of format 12" single and one of format LP
    When the collector filters by the format 7"
    Then the collector is shown exactly those two records of format 7"

  Scenario: A collector filters by two formats
    Given the collector owns two records of format 7", one of format 12" single and one of format LP
    When the collector filters by the formats 7" and 12" single
    Then the collector is shown exactly those three records

  Scenario: A collector clears an applied filter
    Given the collector has filtered a collection of four records down to two
    When the collector clears the filter
    Then the collector is shown all four of their records
```

===== FILE: docs/features/lookup-unavailable.feature =====

```gherkin
Feature: Lookup unavailable

  No failure of the external music database may prevent a record being added.

  Scenario: The external music database is unreachable
    Given the external music database is unreachable
    When the collector scans a barcode
    Then the collector is shown a message offering manual entry because lookups are temporarily unavailable

  Scenario: The external music database rate limit has been reached
    Given the external music database has refused further requests for the current minute
    When the collector scans a barcode
    Then the collector is shown a message offering manual entry because lookups are temporarily unavailable

  Scenario: The external music database does not respond within ten seconds
    Given the external music database responds no sooner than ten seconds
    When the collector scans a barcode
    Then the collector is shown a message offering manual entry because lookups are temporarily unavailable

  Scenario: A collector adds a record while the external music database is unreachable
    Given the external music database is unreachable
    When the collector submits an artist and a title by manual entry
    Then the collector is shown the new record in their collection

  Scenario: A candidate release missing some fields
    Given the external music database returns a release carrying no country and no release year
    When the collector confirms that candidate release
    Then the collector is shown the new record carrying that release's artist and title with its country and release year empty
```

===== FILE: docs/features/merge-people.feature =====

```gherkin
Feature: Merge duplicate people

  Where two entries for one musician arise despite the suggestion list, the
  collector can combine them.

  Scenario: A collector merges two people
    Given the collector has a person credited on two records and a duplicate of that musician credited on one other record
    When the collector merges the duplicate into the first
    Then the collector is shown one person credited on three records

  Scenario: A collector is told what a merge will do before confirming
    Given the collector has a person credited on two records and a duplicate of that musician credited on one other record
    When the collector submits those two people for merging
    Then the collector is shown that one credit will move and which name will remain
```

===== FILE: docs/features/password-length.feature =====

```gherkin
Feature: Password length

  Groovely enforces a minimum and maximum password length and no other
  composition requirement.

  Scenario: A visitor chooses a password shorter than twelve characters
    Given the visitor has no Groovely account
    When the visitor submits the registration form with a password of eleven characters
    Then the visitor is shown a message stating the password must be at least twelve characters

  Scenario: A visitor chooses a long passphrase containing spaces
    Given the visitor has no Groovely account
    When the visitor submits the registration form with a ninety-character passphrase containing spaces
    Then the visitor is shown a message asking them to check their email for a verification link

  Scenario: A collector chooses a password of exactly the maximum length
    Given the collector has no Groovely account
    When the collector submits the registration form with a password of one hundred and twenty eight characters
    Then the collector is shown a message asking them to check their email for a verification link

  Scenario: A collector chooses a password longer than the maximum
    Given the collector has no Groovely account
    When the collector submits the registration form with a password of one hundred and twenty nine characters
    Then the collector is shown a message stating a password may be at most one hundred and twenty eight characters
```

===== FILE: docs/features/password-reset-link-expiry.feature =====

```gherkin
Feature: Password reset link expiry

  A reset link is single use and expires after sixty minutes.

  Scenario: A visitor follows a reset link more than sixty minutes after it was issued
    Given the visitor has a password reset link issued more than sixty minutes ago
    When the visitor follows that link
    Then the visitor is shown a message stating the link has expired

  Scenario: A visitor follows a reset link that has already been used
    Given the visitor has already reset their password using a reset link
    When the visitor follows that same link again
    Then the visitor is shown a message stating the link has expired
```

===== FILE: docs/features/password-reset.feature =====

```gherkin
Feature: Password reset

  A collector who has forgotten their password sets a new one. Resetting does not
  bypass the second factor.

  Scenario: A collector requests a reset for a registered email address
    Given the collector has a Groovely account
    When the collector requests a password reset for that email address
    Then the collector is shown a message stating that a reset link has been sent if an account exists

  Scenario: A visitor requests a reset for an unregistered email address
    Given the visitor has no Groovely account
    When the visitor requests a password reset for an unregistered email address
    Then the visitor is shown the same message stating that a reset link has been sent if an account exists

  Scenario: A collector follows a valid reset link
    Given the collector has an unused password reset link
    When the collector follows that link
    Then the collector is asked to choose a new password

  Scenario: A collector sets a new password
    Given the collector has followed an unused password reset link
    When the collector submits an acceptable password
    Then the collector is asked for an authenticator code

  Scenario: A collector signs in with a password set through a reset link
    Given the collector has set a new password using a reset link
    When the collector submits their email address and that new password
    Then the collector is asked for an authenticator code

  Scenario: A collector signs in with the password a reset replaced
    Given the collector has set a new password using a reset link
    When the collector submits their email address and the password the reset replaced
    Then the collector is shown a message stating the email address or password was not recognised

  Scenario: A collector chooses a breached password when resetting
    Given the collector has followed an unused password reset link
    When the collector submits a breached password
    Then the collector is shown a message stating the password has appeared in a known data breach and must be changed
```

===== FILE: docs/features/recovery-codes.feature =====

```gherkin
Feature: Recovery codes

  Ten single-use recovery codes are issued at enrolment as the lost-device path.

  Scenario: A collector signs in using an unused recovery code
    Given the collector has an unused recovery code
    When the collector submits that recovery code in place of an authenticator code
    Then the collector is shown their collection

  Scenario: A collector reuses a recovery code that has already been consumed
    Given the collector has a recovery code that has already been used
    When the collector submits that recovery code in place of an authenticator code
    Then the collector is shown a message stating the code was not accepted

  Scenario: A collector regenerates their recovery codes
    Given the collector has ten recovery codes
    When the collector requests a new set of recovery codes
    Then the collector is shown ten different recovery codes

  Scenario: A code from a superseded set
    Given the collector has regenerated their recovery codes
    When the collector submits a code from the previous set
    Then the collector is shown a message stating the code was not accepted
```

===== FILE: docs/features/registration.feature =====

```gherkin
Feature: Registration

  A visitor creates a Groovely account with an email address and an acceptable
  password.

  Scenario: A visitor registers with an unused email address and an acceptable password
    Given the visitor has no Groovely account
    When the visitor submits the registration form with an unused email address and an acceptable password
    Then the visitor is shown a message asking them to check their email for a verification link

  Scenario: A visitor registers with an email address that already has an account
    Given the visitor has a Groovely account
    When the visitor submits the registration form with that same email address and an acceptable password
    Then the visitor is shown the same message asking them to check their email for a verification link

  Scenario: Registering again over an existing address leaves that account untouched
    Given the collector has an account and a visitor has since submitted the registration form with that same email address and a different password
    When the collector submits their email address and their original password
    Then the collector is asked for an authenticator code

  Scenario: A visitor chooses a breached password
    Given the visitor has no Groovely account
    When the visitor submits the registration form with an unused email address and a breached password
    Then the visitor is shown a message stating the password has appeared in a known data breach and must be changed
```

===== FILE: docs/features/result-order.feature =====

```gherkin
Feature: The order records are shown in

  Every ordering is total, so the same query always returns the same order and no
  record is repeated or skipped across a page boundary.

  Scenario: A collector opens their collection for the first time
    Given the collector owns records added on several dates
    When the collector opens their collection
    Then the collector is shown their most recently added record first

  Scenario: A collector loads a second page
    Given the collector owns fifty records and has chosen list view
    When the collector loads more records
    Then the collector is shown twenty distinct records with none repeated

  Scenario: Records sharing the sorted value across a page boundary
    Given the collector owns thirty records by the same artist, sorted by artist, in list view
    When the collector loads more records
    Then the collector is shown twenty distinct records with none repeated

  Scenario: The same query on a later visit
    Given the collector owns three records by the same artist
    When the collector sorts their collection by artist on a later visit
    Then the collector is shown those three records in the order they were shown before
```

===== FILE: docs/features/returning-to-the-collection.feature =====

```gherkin
Feature: Returning to where you were

  Opening a record must not cost the collector their place.

  Scenario: A collector opens a record and goes back
    Given the collector has opened a record from the second page of a filtered collection
    When the collector goes back
    Then the collector is shown that same filtered collection at that same point

  Scenario: A collector returns to a bookmarked view
    Given the collector has bookmarked a filtered and sorted view of their collection
    When the collector opens that bookmark
    Then the collector is shown that same filtered and sorted view

  Scenario: A collector switches view while further down the collection
    Given the collector has loaded a second page in list view
    When the collector switches to grid view
    Then the collector is shown twelve records rather than twenty
```

===== FILE: docs/features/scan-multiple-candidates.feature =====

```gherkin
Feature: A barcode matching several releases

  Reissues frequently share a barcode with the original pressing, so a scan may
  legitimately match more than one release.

  Scenario: A scan matches several candidate releases
    Given the collector has granted camera access
    When the collector scans a barcode matching four releases
    Then the collector is shown all four candidate releases to choose between

  Scenario: A collector leaves several candidate releases without choosing
    Given the collector is shown several candidate releases
    When the collector leaves the candidate list without confirming one
    Then the collector's collection contains no new record
```

===== FILE: docs/features/scan-no-match.feature =====

```gherkin
Feature: A barcode matching no release

  Scenario: A scan matches no candidate release
    Given the collector has granted camera access
    When the collector scans a barcode matching no release
    Then the collector is shown a message offering manual entry because no release was found
```

===== FILE: docs/features/search-by-track.feature =====

```gherkin
Feature: Find the records carrying a track

  Scenario: A track appearing on several records in the collection
    Given the collector owns three records carrying a track titled Blue in Green and four records that do not
    When the collector searches for Blue in Green in the track scope
    Then the collector is shown only those three records

  Scenario: A result states which track matched
    Given the collector owns a record carrying a track titled Blue in Green at position A3
    When the collector searches for Blue in Green in the track scope
    Then the collector is shown that result stating it matched the track Blue in Green at position A3

  Scenario: A record carrying the track more than once
    Given the collector owns a record carrying a track titled Blue in Green on side A and on side C
    When the collector searches for Blue in Green in the track scope
    Then the collector is shown one result stating both positions

  Scenario: A track the collector does not own
    Given the collector owns no record carrying a track titled Giant Steps
    When the collector searches for Giant Steps in the track scope
    Then the collector is shown a message stating no records matched
```

===== FILE: docs/features/search-collection.feature =====

```gherkin
Feature: Search the collection

  Scenario: A collector searches for an artist they own
    Given the collector owns a record by John Coltrane and a record by Bill Evans
    When the collector searches the artist scope for Coltrane
    Then the collector is shown only the record by John Coltrane

  Scenario: A collector searches for something they do not own
    Given the collector owns records by artists other than Miles Davis
    When the collector searches the artist scope for Miles Davis
    Then the collector is shown a message stating no records matched

  Scenario: A collector searches using different letter casing
    Given the collector owns a record by John Coltrane and a record by Bill Evans
    When the collector searches the artist scope for coltrane
    Then the collector is shown only the record by John Coltrane
```

===== FILE: docs/features/search-matching.feature =====

```gherkin
Feature: What counts as a match

  Matching is on word beginnings, ignoring case and accents, and every term in the
  query must match.

  Scenario: A collector types the beginning of a word
    Given the collector owns a record by John Coltrane and a record by Bill Evans
    When the collector searches the artist scope for Colt
    Then the collector is shown only the record by John Coltrane

  Scenario: A collector types the minimum two characters
    Given the collector owns a record by John Coltrane and a record by Bill Evans
    When the collector searches the artist scope for Co
    Then the collector is shown only the record by John Coltrane

  Scenario: A collector types the middle of a word
    Given the collector owns a record by John Coltrane and a record by Bill Evans
    When the collector searches the artist scope for rane
    Then the collector is shown a message stating no records matched

  Scenario: A collector types two terms in either order
    Given the collector owns a record titled Kind of Blue by Miles Davis and a record titled Blue Train by John Coltrane
    When the collector searches the album scope for blue
    Then the collector is shown only the record titled Kind of Blue

  Scenario: A collector types a term matching only one record of two
    Given the collector owns a record titled Kind of Blue and a record titled Blue Train
    When the collector searches the album scope for blue train
    Then the collector is shown only the record titled Blue Train

  Scenario: A collector omits an accent the record carries
    Given the collector owns a record by Antonín Dvořák and a record by Bill Evans
    When the collector searches the artist scope for Dvorak
    Then the collector is shown only the record by Antonín Dvořák

  Scenario: A collector types an accent the record does not carry
    Given the collector owns a record by Muller spelled with no umlaut and a record by Bill Evans
    When the collector searches the artist scope for Müller
    Then the collector is shown only the record by Muller

  Scenario: A collector types a single character
    Given the collector owns a record by John Coltrane and a record by Bill Evans
    When the collector searches the artist scope for the single character c
    Then the collector is shown both of those records
```

===== FILE: docs/features/search-result-attribution.feature =====

```gherkin
Feature: A result says why it matched

  Where a result matched on something other than its own artist or title, the row
  states what matched. Without it a collector cannot tell a correct match from a
  search returning everything.

  Scenario: A result matched on a label
    Given the collector owns a record on Blue Note and a record on Impulse
    When the collector searches the label scope for Blue Note
    Then the collector is shown that result stating it matched the label Blue Note

  Scenario: A result matched on a catalogue number
    Given the collector owns a record with catalogue number BLP 1577 and a record with another
    When the collector searches the catalogue number scope for BLP 1577
    Then the collector is shown that result stating it matched the catalogue number BLP 1577

  Scenario: A result matched on the record's own artist
    Given the collector owns a record by John Coltrane and a record by Bill Evans
    When the collector searches the artist scope for Coltrane
    Then the collector is shown that result stating no reason beyond the artist already displayed
```

===== FILE: docs/features/search-scope.feature =====

```gherkin
Feature: Saying what you are searching for

  There is no blended search. The collector states the attribute; every term must
  match within a single value of it. A result is always a record.

  Scenario: A collector searches by album
    Given the collector owns a record titled Blue Train, a record with a track titled Blue Train, and a record with neither
    When the collector searches the album scope for Blue Train
    Then the collector is shown only the record titled Blue Train

  Scenario: A collector searches by track
    Given the collector owns a record titled Blue Train, a record with a track titled Blue Train, and a record with neither
    When the collector searches the track scope for Blue Train
    Then the collector is shown only the record with the track titled Blue Train

  Scenario: A collector searches by artist
    Given the collector owns a record by John Coltrane titled Giant Steps and a record by Bill Evans titled Coltrane Sessions
    When the collector searches the artist scope for Coltrane
    Then the collector is shown only the record by John Coltrane

  Scenario: Terms must match within one value
    Given the collector owns a record titled Kind of Blue by Miles Davis
    When the collector searches the album scope for blue miles
    Then the collector is shown a message stating no records matched

  Scenario: A collector searches by label
    Given the collector owns a record on Blue Note, a record on Impulse, and a record titled Blue Note Sessions
    When the collector searches the label scope for Blue Note
    Then the collector is shown only the record on Blue Note

  Scenario: A collector searches by catalogue number
    Given the collector owns a record with catalogue number BLP 1577 and a record with a different catalogue number
    When the collector searches the catalogue number scope for BLP 1577
    Then the collector is shown only the record with catalogue number BLP 1577
```

===== FILE: docs/features/search-with-filter.feature =====

```gherkin
Feature: Searching within a filtered collection

  A filter and a search narrow together. Neither discards the other.

  Scenario: A collector searches while a filter is applied
    Given the collector owns a 7" by John Coltrane, an LP by John Coltrane and a 7" by Bill Evans, filtered to format 7"
    When the collector searches the artist scope for Coltrane
    Then the collector is shown only the 7" by John Coltrane

  Scenario: A collector clears the search but keeps the filter
    Given the collector owns a 7" by John Coltrane, a 7" by Bill Evans and an LP by John Coltrane, filtered to format 7" and searched for Coltrane
    When the collector clears the search
    Then the collector is shown exactly the two records of format 7"
```

===== FILE: docs/features/session-termination.feature =====

```gherkin
Feature: Session termination

  Signing out and changing a password both end active sessions.

  Scenario: A collector signs out
    Given the collector is signed in
    When the collector signs out
    Then the collector is shown the sign in screen

  Scenario: A collector changes their password while signed in elsewhere
    Given the collector is signed in on a second device
    When the collector changes their password
    Then the session on the second device no longer has access to the collection

  Scenario: The collection is reached after the collector has signed out
    Given the collector has signed out
    When the collector navigates directly to their collection
    Then the collector is asked for an email address and a password

  Scenario: A session within its idle limit
    Given the collector has not used Groovely for twenty nine days
    When the collector navigates directly to their collection
    Then the collector is shown their collection

  Scenario: A session that has been idle beyond its limit
    Given the collector has not used Groovely for more than thirty days
    When the collector navigates directly to their collection
    Then the collector is asked for an email address and a password

  Scenario: A session older than its absolute limit
    Given the collector has a session created more than ninety days ago
    When the collector navigates directly to their collection
    Then the collector is asked for an email address and a password
```

===== FILE: docs/features/sign-in.feature =====

```gherkin
Feature: Sign in

  A visitor signs in with an email address and password, then is challenged for
  a second factor.

  Scenario: A visitor signs in with correct credentials
    Given the visitor has a Groovely account with completed authenticator enrolment
    When the visitor submits their correct email address and password
    Then the visitor is asked for an authenticator code

  Scenario: A visitor signs in with an incorrect password
    Given the visitor has a Groovely account with completed authenticator enrolment
    When the visitor submits their correct email address and an incorrect password
    Then the visitor is shown a message stating the email address or password was not recognised

  Scenario: A visitor signs in with an email address that has no account
    Given the visitor has no Groovely account
    When the visitor submits an unregistered email address and any password
    Then the visitor is shown the same message stating the email address or password was not recognised

  Scenario: The collection is reached before the authenticator challenge is answered
    Given the collector has submitted their correct email address and password without submitting an authenticator code
    When the collector navigates directly to their collection
    Then the collector is asked for an authenticator code

  Scenario: The collection is reached with no sign in at all
    Given the collector has a Groovely account with completed authenticator enrolment
    When the collector navigates directly to their collection without signing in
    Then the collector is asked for an email address and a password
```

===== FILE: docs/features/sleeve-photographs.feature =====

```gherkin
Feature: Photograph your own copy

  Two named slots, front and back. The collector's own photograph is authoritative
  over any external cover image.

  Scenario: A collector photographs the front of their sleeve
    Given the collector owns a record showing an external cover image
    When the collector adds a front photograph to that record
    Then the collector is shown that record displaying their front photograph

  Scenario: A collector photographs the back of their sleeve
    Given the collector owns a record with a front photograph and no back photograph
    When the collector adds a back photograph to that record
    Then the collector is shown that record displaying both photographs

  Scenario: A photograph is served to the collector who owns it
    Given the collector owns a record carrying a front photograph
    When the collector requests the address that photograph is served from
    Then the collector is given that image

  Scenario: A collector replaces a photograph in a slot
    Given the collector owns a record carrying a front photograph
    When the collector adds a different front photograph to that record
    Then the collector is shown that record displaying the newer front photograph

  Scenario: A collector adds a photograph carrying location metadata
    Given the collector owns a record with no photographs
    When the collector adds a front photograph of twelve hundred pixels square carrying location metadata
    Then the collector is shown that photograph at twelve hundred pixels square carrying no location metadata

  Scenario: A collector adds a file that is not an image
    Given the collector owns a record with no photographs
    When the collector adds a file named sleeve.jpg whose contents are not an image
    Then the collector is shown a message stating only image files are accepted

  Scenario: A collector adds a photograph larger than the limit
    Given the collector owns a record with no photographs
    When the collector adds a front photograph of twelve mebibytes
    Then the collector is shown a message stating a photograph may be no larger than ten mebibytes

  Scenario: A collector removes a photograph
    Given the collector owns a record carrying a front photograph and a back photograph
    When the collector removes the front photograph
    Then the collector is shown that record carrying only the back photograph

  Scenario: Another collector's photograph is requested
    Given another collector owns a record carrying a front photograph
    When the collector requests the address that photograph is served from
    Then the collector is shown a message stating the record was not found
```

===== FILE: docs/features/sort-by-title-and-year.feature =====

```gherkin
Feature: Sorting by title and by release year

  Scenario: A collector sorts by title
    Given the collector owns records whose titles are not already in order
    When the collector sorts their collection by title
    Then the collector is shown their records ordered by title

  Scenario: A collector sorts by release year
    Given the collector owns records released in several years that are not already in year order
    When the collector sorts their collection by release year
    Then the collector is shown their most recently released record first
```

===== FILE: docs/features/sort-collection.feature =====

```gherkin
Feature: Sort the collection

  Scenario: A collector sorts by artist
    Given the collector owns records by several artists that are not already in artist order
    When the collector sorts their collection by artist
    Then the collector is shown their records ordered by artist

  Scenario: A collector sorts by the date a record was added
    Given the collector owns records added on several dates that are not already in date added order
    When the collector sorts their collection by date added
    Then the collector is shown their records ordered by date added

  Scenario: A collector sorts by acquisition date
    Given the collector owns records acquired on several dates that are not already in acquisition date order
    When the collector sorts their collection by acquisition date
    Then the collector is shown their records ordered by acquisition date
```

===== FILE: docs/features/sort-edge-cases.feature =====

```gherkin
Feature: Sorting where the value is missing or awkward

  An ordering that is only defined for tidy data is not an ordering.

  Scenario: A collector sorts by acquisition date with some dates missing
    Given the collector owns two records with acquisition dates and one without
    When the collector sorts their collection by acquisition date
    Then the collector is shown the record without an acquisition date after both records that have one

  Scenario: A collector reverses a sort where a value is missing
    Given the collector owns two records with acquisition dates and one without
    When the collector reverses the sort by acquisition date
    Then the collector is shown the record without an acquisition date after both records that have one

  Scenario: A collector sorts by artist where a name begins with an article
    Given the collector owns a record by The Beatles and a record by Duke Ellington
    When the collector sorts their collection by artist
    Then the collector is shown the record by The Beatles before the record by Duke Ellington

  Scenario: A collector sorts by artist where a name carries an accent
    Given the collector owns a record by Müller spelled with an umlaut and a record by Muzak
    When the collector sorts their collection by artist
    Then the collector is shown the record by Müller before the record by Muzak

  Scenario: A collector reverses a sort
    Given the collector is shown their collection sorted by artist ascending
    When the collector reverses the sort direction
    Then the collector is shown their records in the opposite order
```

===== FILE: docs/features/track-listing.feature =====

```gherkin
Feature: Record the track listing

  What is printed on the sleeve. Groovely holds no audio and plays nothing.

  Scenario: A collector confirms a release that has a track listing
    Given the collector is shown a candidate release with a track listing
    When the collector confirms that candidate release
    Then the collector is shown the new record listing those tracks in their printed order

  Scenario: A collector adds a track by hand
    Given the collector owns a record with no tracks
    When the collector adds a track on side A at position one with a title
    Then the collector is shown that record listing that track at position A1

  Scenario: A collector saves a record without any tracks
    Given the collector is on the manual entry screen
    When the collector submits an artist and a title without adding any tracks
    Then the collector is shown the new record in their collection
```

===== FILE: docs/features/track-ordering.feature =====

```gherkin
Feature: Track order

  Order follows side then position, so a tenth track never precedes a second one.

  Scenario: A collector views a record with more than nine tracks on a side
    Given the collector owns a record whose track at position ten on side A was added before its track at position two
    When the collector opens that record
    Then the collector is shown the track at position two before the track at position ten

  Scenario: A collector views a record with tracks on more than one side
    Given the collector owns a record whose side B tracks were added before its side A tracks
    When the collector opens that record
    Then the collector is shown every track on side A before any track on side B
```

===== FILE: docs/features/track-position-parsing.feature =====

```gherkin
Feature: Track positions that do not parse

  The external database gives positions as free text. No track is silently dropped,
  and no side or position is ever invented.

  Scenario: A track listing that parses cleanly
    Given the collector is shown a candidate release whose tracks are positioned A1 and B1
    When the collector confirms that candidate release
    Then the collector is shown the new record listing a track at position A1 and a track at position B1

  Scenario: A track whose position cannot be parsed
    Given the collector is shown a candidate release carrying a track with no side letter
    When the collector confirms that candidate release
    Then the collector is asked to supply a side and a position for that track

  Scenario: A collector completes a track that could not be parsed
    Given the collector has been asked to supply a side and a position for a track
    When the collector supplies side C and position two
    Then the collector is shown the new record listing that track at position C2

  Scenario: A duration that parses
    Given the collector is shown a candidate release carrying a track whose duration reads 5:37
    When the collector confirms that candidate release
    Then the collector is shown that track with a duration of five minutes and thirty seven seconds

  Scenario: An unparseable duration
    Given the collector is shown a candidate release carrying a track with an unreadable duration
    When the collector confirms that candidate release
    Then the collector is shown that track with no duration
```

===== FILE: docs/features/trusted-device-expiry.feature =====

```gherkin
Feature: Trust expires

  Trust lasts thirty days and is never silently extended.

  Scenario: A collector signs in on a device trusted within the last thirty days
    Given the collector has a device trusted twenty nine days ago
    When the collector submits their correct email address and password on that device
    Then the collector is shown their collection

  Scenario: A collector signs in on a device trusted more than thirty days ago
    Given the collector has a device trusted more than thirty days ago
    When the collector submits their correct email address and password on that device
    Then the collector is asked for an authenticator code
```

===== FILE: docs/features/trusted-device-revocation.feature =====

```gherkin
Feature: Revoke device trust

  Scenario: A collector reviews the devices they have trusted
    Given the collector has trusted a device labelled Kitchen laptop and signed in without trusting a device labelled Work laptop
    When the collector opens their trusted devices
    Then the collector is shown exactly one trusted device, labelled Kitchen laptop

  Scenario: A collector revokes a trusted device
    Given the collector has a trusted device
    When the collector revokes that device from their account settings
    Then that device is no longer shown in the collector's list of trusted devices

  Scenario: A collector signs in on a device whose trust they revoked
    Given the collector has revoked the trust on a device
    When the collector submits their correct email address and password on that device
    Then the collector is asked for an authenticator code

  Scenario: A collector signs in on a trusted device after changing their password
    Given the collector has changed their password since trusting a device
    When the collector submits their correct email address and password on that device
    Then the collector is asked for an authenticator code
```

===== FILE: docs/features/trusted-device.feature =====

```gherkin
Feature: Trust a device

  A collector who has proven control of a device may skip the authenticator
  challenge there for thirty days.

  Scenario: A collector marks a device as trusted
    Given the collector has submitted a valid authenticator code
    When the collector chooses to trust the device
    Then the collector is shown their collection

  Scenario: A collector signs in again on a trusted device
    Given the collector has a trusted device
    When the collector submits their correct email address and password on that device
    Then the collector is shown their collection

  Scenario: A collector signs in on a device they have not trusted
    Given the collector has a trusted device
    When the collector submits their correct email address and password on a different device
    Then the collector is asked for an authenticator code

  Scenario: The trust choice is not preselected
    Given the collector has been asked for an authenticator code
    When the collector submits a valid authenticator code without altering the trust choice
    Then the collector is asked for an authenticator code at the next sign in on that device
```

===== FILE: docs/features/view-record.feature =====

```gherkin
Feature: View a record

  Scenario: A collector opens a record from their collection
    Given the collector owns a record by John Coltrane titled Blue Train of format LP kept in Crate B with notes reading slight warp side two
    When the collector opens that record
    Then the collector is shown that record's artist, title, format, storage location and notes

  Scenario: A collector navigates directly to their own record
    Given the collector owns a record by John Coltrane
    When the collector navigates directly to that record
    Then the collector is shown that record's artist and title

  Scenario: A collector opens a record belonging to another collector
    Given another collector owns a record
    When the collector navigates directly to that record
    Then the collector is shown a message stating the record was not found
```
