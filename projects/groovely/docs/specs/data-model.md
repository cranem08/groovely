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
| `enrolled_at` | timestamptz? | `null` | Set when the first valid code is confirmed. **Nullable, because the row must exist before enrolment completes** — it holds the offered `secret` and the `failed_attempts` counter. "Enrolment complete" is the predicate `enrolled_at IS NOT NULL`, which is what the mandatory-2FA route guard tests. |
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
| `deleted_at` | timestamptz? | `null` | tombstone, purged exactly 90 days after deletion (C-050) |

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
| `catalogue_image_url` | text? | `null` | absolute HTTPS URL, ≤ 2048 chars | lookup |

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

Photographs the collector takes of their own copy. Distinct from `catalogue_image_url`,
which is a reference to a Discogs-hosted image and stores no bytes.

**One photograph, not a gallery and not a set of slots.** A record holds at most one
sleeve photograph (C-036). One image dissolves the ordering problem outright: no
primary-image rule, no position to store, no slot vocabulary and no reorder control,
because there is nothing to order.

An earlier draft held **two** named slots, front and back, the back justified by the
liner notes and personnel a jazz sleeve carries. The Product Engineer cut it: Groovely
is a **catalogue, not a digital replacement for the record itself**. The personnel are
already captured properly as structured credits (§11), and the sleeve essay is not
something a catalogue undertakes to reproduce — `notes` lets the collector append
whatever they want about their copy, which is a different and smaller promise. See
`out-of-scope.md`: additional images are postponed, not rejected.

| Field | Type | Default | Constraint |
|---|---|---|---|
| `id` | UUID v7 | generated | — |
| `record_id` | UUID | — | FK Record, cascade on erasure |
| `storage_key` | text | — | opaque object-store key |
| `content_type` | enum | `image/jpeg` | always `image/jpeg` (C-078) — every upload is re-encoded, so the stored type is fixed. The three accepted **upload** types are C-077. |
| `byte_size` | integer | — | bytes of the STORED rendition, not of the upload. Bounded in practice by C-040 and C-041 — see C-042; no separate cap is stated because none is enforceable independently of the resize. |
| `width` / `height` | integer | — | longest edge bounded by C-040, shorter edge following the aspect ratio |
| — | — | — | **At most one row per record among rows where `deleted_at` is null** — a partial constraint, so replacing a photograph tombstones the old row without colliding with the new one. With one image there is no `slot` column to carry it; the constraint is on the record reference alone. |
| `created_at` / `updated_at` / `version` / `deleted_at` | — | — | as §5a |

**Replacing a photograph** tombstones the prior row; its stored object is destroyed
when the tombstone is purged at ninety days (C-050), not at the moment of
replacement, so a mistaken replacement is recoverable for that window.

**Sleeve photographs are IN the MVP, and are core rather than a nice-to-have.**
The Product Engineer's reasoning overruled an earlier recommendation to cut them:
the external database holds no image for a great many older pressings, and where it
does, the image is of *a* copy rather than *this* copy. Under a copy-centric model
the collector's own photograph is authoritative — see principle P4.

### Every upload is resized on import; the original is not kept

Groovely stores **its own rendition**, never the file the collector supplied. On
import the image is bounded to **C-040 on its longest edge**, preserving the aspect
ratio, and re-encoded to JPEG at **C-041**. The upload limits C-037 and C-038 remain,
but they now bound only what the browser will *accept* — nothing near that size is
ever stored.

**Never upscaled.** An image already within C-040 is re-encoded but not enlarged.
Enlarging invents detail that was not photographed and costs bytes to store it.

**Why a bound rather than the original.** At C-037 an unbounded upload would breach
the export cap (C-056) at around a hundred records — one percent of the stated
benchmark (C-003). Bounding at C-040 puts a photograph at C-042, which pushes the cap
beyond the benchmark entirely, so the export's data-only fallback returns to being a
genuine tail case rather than a route most collectors would hit.

**C-040 is PROVISIONAL, and what it now has to satisfy is weaker than it was.** While
a back photograph existed, the bound was fixed by the smallest size at which a liner
note stays readable. That requirement went with the back slot. What remains is that
the sleeve looks right at full width on a phone, and that a page of grid tiles is not
ruinous to fetch — two requirements that pull in opposite directions and neither of
which can be settled on paper. It wants real sleeves photographed on a real phone and
looked at. Until then the value is specified precisely enough to build and verify, and
is expected to change.

EXIF stripping is mandatory without exception: phone photographs carry GPS
coordinates, and a location-tagged gallery of a valuable collection is a
physical-safety risk, not merely a privacy one. Re-encoding on import destroys the
metadata **by construction** — but the obligation is stated independently of the
mechanism, because an implementation that copied the original through would satisfy
neither.

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

**Unique on (`record_id`, `side`, `position`)** among rows where `deleted_at` is
null. Without it the claim below is false — two tracks at A1 would order arbitrarily.

**`side` is not constrained by `disc_count`.** A single-disc record may carry a track
on any side A to Z. Records legitimately have more sides than their disc count would
suggest — an etched side, a bonus seven inch tucked in a sleeve — and rejecting those
would refuse ordinary data. The only stated limit is side Z (C-032).

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
| `filing_name` | text | — | Required **on the row**, 1–200 chars — e.g. `Davis, Miles`. The row itself is optional: an artist with no row sorts by the article-stripped artist text. Clearing the filing name in the interface deletes the row rather than storing an empty one. |
| `created_at` / `updated_at` / `version` / `deleted_at` | — | — | as §5a |

**Sort key for a record's artist** is, in order: the `filing_name` matching its
`artist` if one exists; otherwise the `artist` with a leading `The `, `A ` or `An `
removed. Comparison uses an ICU `en_GB` collation.

**If a record's `artist` text is edited**, that record simply falls under whichever
filing name matches its new artist, or under none. The filing row is keyed to the
artist string, not to the record, so editing a record never orphans or rewrites it.

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

