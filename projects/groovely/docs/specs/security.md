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
- A failed **recovery code** increments the same counter as a failed authenticator
  code. The glossary defines a recovery code as usable "in place of an authenticator
  code", so it is the same challenge answered a different way — five failures across
  either form lock the account. Counting them separately would double an attacker's
  budget at the second factor.
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

## Re-authentication for destructive actions

Three operations require **the current password** in addition to an active session:
changing a password, deleting the account, and regenerating recovery codes. An active
session alone is not sufficient authority for any of them.

The rule exists for one case: someone reaching an unlocked, signed-in browser. Without
it they can erase a collection irreversibly, or print ten fresh second-factor bypass
codes on the screen — and those are the two most destructive actions in the product,
so they cannot be the two least protected.

An incorrect current password counts toward the password lockout counter, and the
message names the current password specifically rather than using the uniform sign-in
copy: the collector is already authenticated, so nothing is disclosed by being clear.

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

Every collection query is scoped at the data-access layer by the owning `Record`'s
or `Account`'s `owner_id` — never by filtering in the UI. `Track`, `Credit` and
`RecordImage` carry no `owner_id` of their own and are scoped through their
`Record`. See the Ownership convention in `data-model.md`. A request for a record the collector does not own returns
the same response as a request for a record that does not exist.

## Photograph handling

- EXIF metadata is stripped on upload **without exception**. Phone photographs
  carry GPS coordinates; a location-tagged gallery of a valuable record
  collection is a physical-safety risk, not merely a privacy one.
- Content type validated by inspecting file contents, never by the declared
  `Content-Type` or the filename extension.
- Stored under opaque, non-enumerable keys. Served only to the owning collector.
- A photograph address belonging to another collector, and one whose account has been
  erased, return **byte-identical not-found responses**. This is the record rule
  applied to images: nothing distinguishes "not yours" from "never existed", so
  ownership cannot be probed by asking. A redirect or a distinct forbidden status
  would be an ownership oracle.

## Secrets

- TOTP secrets encrypted at rest with a key held outside the database.
- The Discogs API token is a server-side secret and is never exposed to the
  browser. All Discogs calls are proxied through Groovely's own backend.

## Erasure

Account deletion removes the account, TOTP enrolment, all recovery codes, all
sessions, all trusted devices, all records including tombstoned rows, all tracks, all credits, all
people, all filing names, and all photograph rows together with their stored
objects, in one transaction. The `Account` row itself is hard-deleted, releasing the
email address so the collector may register again. Nothing
attributable survives.
