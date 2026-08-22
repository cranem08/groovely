# OWASP Top 10: Code Patterns and Fixes

Concrete patterns for recognising and fixing the OWASP Top 10 during
implementation. Focus on what you'll see in code, not abstract descriptions.

## Table of Contents

1. [A01: Broken Access Control](#a01-broken-access-control)
2. [A02: Cryptographic Failures](#a02-cryptographic-failures)
3. [A03: Injection](#a03-injection)
4. [A04: Insecure Design](#a04-insecure-design)
5. [A05: Security Misconfiguration](#a05-security-misconfiguration)
6. [A06: Vulnerable Components](#a06-vulnerable-components)
7. [A07: Authentication Failures](#a07-authentication-failures)
8. [A08: Data Integrity Failures](#a08-data-integrity-failures)
9. [A09: Logging Failures](#a09-logging-failures)
10. [A10: SSRF](#a10-ssrf)

---

## A01: Broken Access Control

**If you see:** Endpoint that serves data without checking who's requesting it.

**Fix:** Add authorisation check on every request. Verify the authenticated
user has permission to access the specific resource (not just "is logged in").

```
Bad:  GET /api/users/123 → returns user 123 data (no auth check)
Good: GET /api/users/123 → verify requesting user IS user 123 or has admin role
```

**If you see:** Client-side only access control (hiding UI elements).

**Fix:** Enforce access control on the server. Client-side is cosmetic only.

---

## A02: Cryptographic Failures

**If you see:** Sensitive data stored in plaintext, weak hashing, hardcoded
keys.

**Fix:**
- Hash passwords with bcrypt/scrypt/argon2 (never MD5/SHA1)
- Encrypt sensitive data at rest and in transit
- Never hardcode encryption keys or secrets
- Use TLS for all external communications

---

## A03: Injection

**If you see:** String concatenation to build queries or commands.

**Fix:** Use parameterised queries / prepared statements.

```
Bad:  db.query(`SELECT * FROM users WHERE id = '${userId}'`)
Good: db.query('SELECT * FROM users WHERE id = $1', [userId])
```

**If you see:** `innerHTML` with user-provided content.

**Fix:** Use `textContent` or an approved sanitiser.

```
Bad:  element.innerHTML = userInput
Good: element.textContent = userInput
```

---

## A04: Insecure Design

**If you see:** No rate limiting on sensitive operations (login, password reset,
API endpoints).

**Fix:** Add rate limiting at the boundary. Design for abuse scenarios.

**If you see:** No validation of business logic invariants.

**Fix:** Express constraints as validation rules, test them.

---

## A05: Security Misconfiguration

**If you see:** Verbose error messages exposing stack traces or internal paths.

**Fix:** Return generic error messages to clients. Log details server-side.

**If you see:** Default credentials or unnecessary features enabled.

**Fix:** Remove defaults, disable unused features, follow least privilege.

---

## A06: Vulnerable Components

**If you see:** Dependencies with known CVEs in `dependency_scan` output.

**Fix:** Update to patched version. If no patch exists, evaluate alternatives
or apply compensating controls.

**If you see:** Dependencies added for trivial functionality.

**Fix:** Consider implementing the functionality directly if it's simple.

---

## A07: Authentication Failures

**If you see:** Custom authentication implementation.

**Fix:** Use established libraries. Don't roll your own auth.

**If you see:** Session tokens that are predictable or don't expire.

**Fix:** Use cryptographically random tokens with expiration.

**If you see:** Credentials in URL parameters.

**Fix:** Use request headers or body for credentials. Never in URLs.

---

## A08: Data Integrity Failures

**If you see:** Deserialization of untrusted data without validation.

**Fix:** Validate and sanitise all deserialised input. Use safe serialisation
formats.

**If you see:** Unsigned or unverified updates/downloads.

**Fix:** Verify integrity of external data (checksums, signatures).

---

## A09: Logging Failures

**If you see:** Sensitive data in log output (passwords, tokens, PII).

**Fix:** Never log secrets. Redact sensitive fields before logging.

**If you see:** No logging of security-relevant events (login failures,
access denials, privilege changes).

**Fix:** Log security events with sufficient context for investigation.

---

## A10: SSRF

**If you see:** Server-side HTTP requests using user-provided URLs.

**Fix:** Validate and allowlist permitted destinations. Block internal
network ranges (127.0.0.1, 10.x, 169.254.x, etc.).

```
Bad:  fetch(userProvidedUrl)
Good: validate URL against allowlist, then fetch
```
