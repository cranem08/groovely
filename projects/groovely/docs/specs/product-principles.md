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

<!-- consistency:retired-ok — this section explains a retirement and must name it -->

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
- *Is this cataloguing the record, or reproducing it?*
  **Groovely is a catalogue, not a digital replacement for the record itself.**
  (Rejected the back-sleeve photograph, and with it a readable-liner-note size
  constant, a display-precedence rule with three rungs, and an argument about
  thumbnail derivatives that had run for some time before the razor was applied.)

<!-- consistency:retired-ok — the worked examples must name what was rejected -->

**Decisions this test has produced.** It rejected a per-record rating (judges the
music, not the copy), play tracking, collection statistics, and free-text tags. It
admitted personnel credits (serves P1 and P2 — a view of your own collection that
no external database can produce) and track listings (printed on the sleeve, and
the practical means of telling one pressing from another).

A test that has never rejected anything is not a test. This one has.
