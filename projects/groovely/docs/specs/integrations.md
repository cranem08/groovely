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
