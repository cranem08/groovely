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

<!-- consistency:retired-ok — a list of what the product is not must name those things -->

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
