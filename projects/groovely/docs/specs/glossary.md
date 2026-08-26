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
| **sleeve photograph** | The one image the collector has taken of their own copy. At most one per record. Authoritative over any external image. |
| **person** | A musician or member of recording personnel, as named on a sleeve or returned by a lookup. Scoped to one collector. |
| **track** | An item printed on the sleeve as being on the record, identified by its side-and-position (A1, B2). Groovely holds no audio. |
| **credit** | A person's stated role on one record, or on one track of it — "Miles Davis, trumpet". Always optional. |
| **credited artist** | A credit marking the person as the artist of the release rather than someone who played on it. This is the leader half of the leader-versus-sideman distinction. |
| **contributor** | A credited person who is not the credited artist — the sideman half. Every credit is a contributor unless marked otherwise. |
| **catalogue image** | An externally hosted image referenced by URL, obtained from a lookup. Not a photograph of this collector's copy. |
| **display image** | The image shown for a record. Chosen by a fixed precedence: the collector's sleeve photograph, else the catalogue image. A record with neither shows no image. |

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
| **artist** | The act credited on the front of the record, held as `Record.artist`. The Artist search scope examines this and any filing name set for it. |
| **album** | What the Album search scope examines: the record's own title. Named "album" in the interface because that is what a collector calls it, and `title` in the data model. |
| **title** | The name of the release, held as `Record.title`. |
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
