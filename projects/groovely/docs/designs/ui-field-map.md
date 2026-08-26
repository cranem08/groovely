# UI Field Map — Groovely MVP

**Status:** DRAFT — awaiting Product Engineer review

Operating Tolerance Tier 1 blocks any user-editable data field that lacks a
specified UI input component and allowed values. This document supplies both for
every editable field in `docs/specs/data-model.md`.

Accessibility applies throughout: every control has a visible label and an
accessible name; no state is conveyed by colour alone; touch targets are at
least 24x24 CSS px, which is WCAG 2.2 AA (2.5.8). No AAA criterion is asserted —
an unfalsifiable "preference" cannot fail a build and so states nothing. See
`standards/accessibility.md`.

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

**People view controls.** Its search obeys the same matching rule as the collection
(word-prefix, accent-insensitive, all terms). Default sort is by count, highest
first, ties broken by name and then by person id so the order is total. Page size
follows the collection view (C-001, C-002). The record count is a count of
**distinct records**, not of credits — a person credited twice on one record counts
once, and the export column carries the same number.

**Merge people.** Where duplicates arise, the collector selects two people and
confirms a merge. The confirmation states plainly how many credits will move and
which name survives. The action is not reversible, so it is confirmed explicitly.

## Sleeve photograph

| Field | Component | Allowed values |
|---|---|---|
| sleeve photograph | Single file input accepting the C-077 upload types, with `capture` offered on mobile | upload ≤ C-037 and ≤ C-038 per side |

**The upload limits are not the stored size.** Whatever is accepted is reduced on
import to C-040 on its longest edge and re-encoded to JPEG (`data-model.md` §8), so
the control must not promise the collector that their original is kept. An image
already inside the bound is not enlarged.

One photograph, not a gallery. There is no ordering control, no primary-image setting
and no second labelled control, because there is only one image. Adding a photograph
to a record that already has one **replaces** it — the control says so before it does
it, since the collector cannot see a second slot to reason about.

Type is validated by inspecting file contents, never the extension. EXIF is
stripped without exception — the re-encode destroys it, but the obligation stands
independently of the mechanism.

**Which image stands for the record.** Wherever an image represents a record — the
collection list tile, a search result, the header of the record page — the **display
image** is the collector's **sleeve photograph**, else the **catalogue image**. A record
with neither shows no image, not a placeholder sleeve. The precedence is fixed and not
a setting: the collector's own photograph outranks anything a lookup supplied (**P4**).

## Collection controls

| Control | Component | Allowed values |
|---|---|---|
| Search | Single-line search input, `type="search"` | Empty, or two to one hundred characters (C-004, C-005). A single character is accepted into the field and **the search is not run** — the collection is shown unfiltered, with no error, because a partially typed word is not a mistake. |
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
at all, whereas "shown ten records rather than two hundred" is not.

The two numbers differ because the views differ: a grid tile is smaller than a list
row, so 12 tiles and 10 rows occupy comparable space on a phone. Images below the fold are lazy-loaded,
so page size does not affect the 2.5s cold-paint target and is purely a question of
how often the collector is interrupted by a Load more.

**Only one filter facet exists: format.** Condition, decade and person were each
specified and then cut on review — person duplicated browse-by-person, condition had
no consumer once grading was removed, and decade could not be justified beyond "the
field existed".

**What each scope searches.** Stated as a mapping, because the control labels and
the field names differ — nothing else connects the Album scope to `Record.title`.

| Scope | Searches |
|---|---|
| Artist (default) | `Record.artist`, and any `filing_name` set for it — so filing Miles Davis as "Davis, Miles" makes both spellings find him |
| Album | `Record.title` |
| Track | `Track.title` |
| Label | `Record.label` |
| Catalogue number | `Record.catalogue_number` |

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
about; artist, title and track are attributes it has. The scope
selector narrows *which attribute is searched* — it never changes what a result is.
One result shape for every scope, which is also one shape to verify.

Where the scope is Track and a record has several matching tracks, the row lists
each of them.

**Search result attribution.** Where a result matched on something other than the
record's own artist or title — a track title, a label, a catalogue number — the
result row MUST state what matched and its value, beneath the
record's artist and title. For example, searching "So What" returns:

> **Kind of Blue** — Miles Davis
> *matched track A1 · So What*

Without it, a collector cannot distinguish a correct track match from a broken
search returning everything. This is also what gives the behavioural scenarios
teeth: "the collector is shown that record" passes even when search is entirely
broken, whereas "the result states it matched the track So What" can only pass if
the match was genuinely on that track.
