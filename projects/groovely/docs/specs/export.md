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
| `filing-names.csv` | One row per artist the collector has filed, with the filing name they chose |
| `people.csv` | One row per person, with a count of **records** they appear on — the same number the People view shows, so the file and the screen never disagree |
| `photographs/` | The image files themselves, named `{record_id}.jpg` |
| `README.txt` | Plain-English description of each file and column |

**Photographs are included as files, not as links.** The hosted URLs stop resolving
when an account is deleted — which is precisely the situation an export exists for.
An export that references images the collector can no longer fetch would discharge
P2 in name only, and under P4 the collector's own photograph is the authoritative
image of their copy.

**What is exported is what is stored — the bounded rendition, not an original.**
Groovely never holds the file the collector uploaded (`data-model.md` §8), so there
is no larger version an export could offer. Every file in `photographs/` is a JPEG
(C-078) bounded by C-040 on its longest edge. This is stated here because a portability
right the collector cannot evaluate is worth little: the export contains Groovely's
copy of their photograph, at the size Groovely kept it, and the collector should not
have to discover that by inspecting the archive.

## What `collection.json` contains

Every field of every entity the collector owns, using the field names in
`data-model.md`:

- **records** — all release metadata, `acquired_on`, `storage_location`, `notes`,
  with nested `tracks[]`, `credits[]` and `photographs[]`
- **people** — id, name, external artist id
- **filing names** — the artist string and the filing name chosen for it. Editorial
  work the collector did; an export that dropped it would lose data silently on the
  very path that exists to prevent that.
- **account** — email and `created_at` only. No password hash, no TOTP secret, no
  recovery codes, no session or trusted-device data ever appears in an export.

Tombstoned (soft-deleted) rows are **excluded**. The export is what the collector
has, not what they once had.

## Constraints

| Concern | Rule |
|---|---|
| Scope | Exactly the requesting collector's own data. No other account's row may appear in any file. |
| Size cap | C-056. Beyond that the export fails with a message offering a data-only export without photographs. At C-036 photograph per record and C-042 each, the cap is not reached inside the benchmark C-003, so the data-only path is a genuine tail case. It is specified rather than dropped because C-040 is PROVISIONAL and a larger stored bound would bring the cap back into range. |
| Encoding | UTF-8 throughout. CSV per RFC 4180, comma-separated, CRLF, header row present. |
| Dates | ISO 8601. |
| Delivery | Synchronous download. No emailed link, so no dependency on mail delivery for a data right. |
| Empty collection | Still produces a valid archive, with headers and no data rows. Never a zero-byte file. |
