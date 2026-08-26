# Non-Functional Requirements — Groovely MVP

**Status:** DRAFT — awaiting Product Engineer review

## Scale

| Dimension | Target |
|---|---|
| Records per collection | **At least** 10,000 |
| Tracks per record | 200 (accommodates box sets) |
| Tracks per collection | ~150,000 at a typical 15 per record |
| Credits per record | 200 |
| Photographs per record | C-036 |
| Photograph upload size | <= C-037 before processing |
| Photograph stored size | C-042, bounded by C-040 |
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

**A grid page fetches C-002 images at C-042 each, and that has to be measured rather
than assumed.** It is no longer the blocking problem it was when a record carried two
photographs at several times the size — lazy loading below the fold is the MVP answer,
and the cold-start target above is the thing it must not break.

What is deliberately NOT fixed here is whether a **second, smaller rendition** is
needed. It would be the obvious fix if measurement shows the target missed, and it is
not free: a second stored object per record adds schema surface Rule 7 then requires
to be specified, plus its own constants, its own scenarios, and a second thing erasure
must be shown to destroy. Recorded so that the live review answers it with a
measurement instead of the argument being had again from first principles.

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

**No numeric availability target is asserted for the MVP.** Recorded as a waiver in
`product-log.md` on 2026-08-25, approved by the Product Engineer — a self-declared
exemption inside the artefact it exempts is not a waiver.

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
