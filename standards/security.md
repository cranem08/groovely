# Security Standard

Rules for secure development. Apply during implementation and code review.

## Input Validation

- Validate all input at trust boundaries (user input, API requests, external data)
- Use allowlists over denylists where possible
- Validate type, length, format, and range
- Never trust client-side validation alone — always validate server-side

## Secrets Management

- **No secrets in code** — no API keys, passwords, tokens, or connection strings
- Use environment variables or a secrets manager
- No secrets in logs, error messages, or stack traces
- No secrets in version control (check `.gitignore` before committing)

## Injection Prevention

- Use parameterised queries for all database access (never string concatenation)
- Use templating engines with auto-escaping for HTML output
- No `innerHTML` with untrusted input — use `textContent` or sanitise first
- No `eval()`, `Function()`, or dynamic code execution with untrusted input
- Sanitise file paths to prevent path traversal

## Authentication and Authorisation

- Hash passwords with bcrypt, scrypt, or argon2 (never MD5 or SHA alone)
- Use constant-time comparison for secrets and tokens
- Implement rate limiting on authentication endpoints
- Check authorisation on every request, not just at the UI level
- Use short-lived tokens; implement refresh token rotation

## Dependency Hygiene

- Review new dependencies before adding (popularity, maintenance, licence)
- Keep dependencies up to date — known vulnerabilities are the #1 attack vector
- Pin dependency versions for reproducible builds
- Run dependency scans as part of the quality pipeline

## Data Protection

- Encrypt sensitive data at rest and in transit (TLS for all external communication)
- Minimise data collection — only collect what you need
- No PII in logs or error messages
- Implement data retention policies where applicable
