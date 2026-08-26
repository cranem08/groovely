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
| More than one image per record (back sleeve, labels, inserts, gatefold) | **Postponed, not rejected.** A record holds one photograph in the MVP. Stated by the Product Engineer: Groovely is a catalogue, not a digital replacement for the record itself — the personnel a back sleeve carries are already captured as structured credits, and `notes` lets the collector append anything else about their copy. If additional images later prove to enhance the product they can be added then, and would be designed afresh rather than resurrected as the two named slots this replaced. |

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
| Multiple collections per account | One account owns exactly one collection. |
| Multi-user or shared collections | Out of the ownership model entirely. |
| Analytics, telemetry, crash reporting, third-party tracking | No requirement exists for it; each would be an unspecified external dependency and personal-data processing nobody asked for. |
| Rating a record | Rejected on modelling grounds: a rating judges the music, not the copy, and is incoherent under a copy-centric model. |
| Condition grading (media, sleeve, condition notes) | Cut on review. Goldmine grades are subjective and inconsistent between graders, decay with play, and — decisively — lost their only consumer when the media-condition filter was cut. A captured field nothing reads is pure surface. `notes` covers the one real use ("player copy, surface noise side 2") more expressively. |
| Filter by condition, decade or credited person | Condition filtering had no field left to filter on; decade could not be justified beyond "the field existed"; filtering by person duplicated browse-by-person, giving two implementations of one result set. |
| All monetary values, and the currency apparatus supporting them | Cut under **P5**. A price ceiling is marketplace equipment — it exists to decide whether a transaction is worth doing, which is Discogs' job and which Discogs already does. Groovely is about the pleasure of owning and cataloguing the object. Removing it also removes the supported-currency list, the account currency, per-entry currency, the ISO 4217 exponent rule and a currency control: no entity carries an amount. |
| Purchase price, currency and seller | Cut by the Product Engineer on review: a self-entered price is not evidence of value for any insurance or loss claim, and the information belongs wherever financial records are already kept. Acquisition date is retained. |
| `display_name` on an account | Nothing displays it. Collections are private. |
| IP address or user-agent recorded against a session | Personal data no requirement needs. |
