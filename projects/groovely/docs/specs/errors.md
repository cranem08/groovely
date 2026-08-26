# Error Taxonomy — Groovely MVP

**Status:** DRAFT — awaiting Product Engineer review

Every error assertion in the feature files takes the form "shown a message stating
…". This document supplies what those assertions point at: the trigger, the copy,
what happens to the collector's work, and whether anything is retried. Without it,
each message is an implementer's invention.

## Universal rules

1. **Input is never lost.** Any rejected submission returns with every field as the
   collector left it. Losing a half-completed record to a validation error or a
   dropped connection is the failure most likely to make someone abandon the app.
2. **Errors are stated in plain language**, name what happened, and say what to do
   next. No codes, no jargon, no blame.
3. **Validation runs on the server** and is mirrored in the browser for speed. The
   server is authoritative; the browser is a convenience.
4. **Authentication errors stay uniform** — see `security.md`. They never reveal
   whether an account exists or which factor failed, with the single stated
   exception for a locked account given the correct password.

## Connection loss

The browser MVP is **online-only** (P3). Losing connection is therefore a specified
operating condition, not an unforeseen failure.

| Aspect | Behaviour |
|---|---|
| Detection | **A request to Groovely's own backend fails or times out.** Not the browser's online status, which reports online behind a captive portal and on a dead wireless association — precisely the situations where the collector most needs to be told. Detection by evidence rather than by opinion. |
| Indication | The collector is shown a persistent banner stating Groovely needs a connection. |
| Reading | Whatever is already on screen stays usable. Nothing is cleared. |
| Writing | Blocked, with a message stating the change was not saved because there is no connection. |
| Input | Preserved in full. When the connection returns, the collector resubmits with one action. |
| Recovery | The banner clears on the next successful request that the collector's own action causes. No reload, and no polling — Groovely does not test the connection on a timer, so the banner persists until the collector next tries something. |

## Error classes

| Class | Trigger | Copy | Retry | State |
|---|---|---|---|---|
| Validation | A field fails a data-model constraint | Names the field and the rule ("A release year must be between 1889 and next year") | None — the collector corrects it | Form preserved |
| Authentication | Wrong credentials, wrong code | Uniform text per `security.md` | None | Form preserved except the password field |
| Lockout | Five consecutive failures | Uniform, unless the password was correct | None | Form preserved |
| External lookup unavailable | Discogs unreachable, rate-limited, or slower than 10s | States lookups are temporarily unavailable, offers manual entry | 1 retry with backoff, then give up | Manual entry offered |
| Breach screening unavailable | HIBP unreachable | Silent — **fail open**, password accepted, event logged | None | Proceeds |
| Email delivery failure | Transactional mail rejected | Silent to the visitor; the message shown is unchanged | 3 retries with exponential backoff | A resend affordance exists |
| Photograph upload failure | Object store unreachable or rejects | States the photograph could not be saved; the record itself saves | 1 retry | Record saved, photograph absent |
| Photograph read failure | Object store unreachable on read | A placeholder is shown in place of the image | None | Record otherwise intact |
| Export too large | Archive would exceed 2 GiB | States the export is too large and offers a data-only export | None | Offer presented |
| Server fault | Any unhandled 5xx from Groovely's own backend | States something went wrong at Groovely's end and the change was not saved | None | Form preserved |
| Link no longer valid | A verification or reset link that has expired or been used | States the link is no longer valid and offers to send a new one. **Expired and consumed are indistinguishable** — separating them would tell an attacker that a link had once existed | None | A fresh link may be requested |
| Camera permission declined | The collector refuses the camera prompt | States the camera is unavailable and that manual entry is available. A declined browser permission cannot be re-requested in-page, so the message says to enable it in browser settings | None | Manual entry offered |
| No camera present | The device reports no camera | States no camera was found | None | Manual entry offered |
| Insecure context | The page is not served over HTTPS, so the camera cannot start | States that scanning requires a secure connection | None | Manual entry offered |
| Not found or not yours | A record belonging to another account, or no record | States the record was not found — **identical in both cases**, so ownership cannot be probed | None | — |
