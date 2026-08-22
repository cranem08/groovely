---
name: security
description: >
  Applied expertise for secure development throughout the SDLC, focused on
  build-time responsibilities. Use when: (1) code crosses trust boundaries or
  handles user input, (2) implementing authentication or authorisation logic,
  (3) introducing new dependencies or external integrations, (4) threat
  modelling is needed for a slice, (5) interpreting results from security_scan,
  dependency_scan, or secrets_scan, or (6) deciding whether a security
  concern is Critical/High vs. acceptable risk.
---

# Security

Apply secure development practices during implementation, with focus on
build-time responsibilities (Claude Code's domain).

## Core Principles

These are non-negotiable:

1. **Secure by Design** — address security during implementation, not after
2. **Least Privilege** — components get minimum access required
3. **Explicit Trust Boundaries** — all boundary crossings require validation
4. **Defence in Depth** — no single control is sufficient
5. **Fail Closed** — when in doubt, deny access or halt execution
6. **Secure Defaults** — safe configurations by default

## Threat Modelling

Threat modelling is mandatory when a slice involves any of these triggers.
See `references/threat-model-triggers.md` for the full decision tree.

**Quick check — does this slice:**
- Introduce a new external interface? → threat model
- Cross a new trust boundary? → threat model
- Handle sensitive or regulated data? → threat model
- Add authentication or authorisation logic? → threat model
- Modify deployment or infrastructure? → threat model
- Introduce agentic or AI-driven behaviour? → threat model

If none apply, document "No threat modelling required for this slice" in the
slice constraints section and move on.

### Lightweight Threat Model Process

For a slice-scoped threat model:

1. **Identify assets** — what data or capability is being protected?
2. **Identify actors** — who interacts with this slice? (users, services, agents)
3. **Identify trust boundaries** — where does trusted become untrusted?
4. **Enumerate threats** using STRIDE:
   - **S**poofing — can an actor impersonate another?
   - **T**ampering — can data be modified in transit or at rest?
   - **R**epudiation — can actions be denied without evidence?
   - **I**nformation Disclosure — can data leak to unauthorised parties?
   - **D**enial of Service — can the service be overwhelmed?
   - **E**levation of Privilege — can an actor gain unauthorised access?
5. **Propose mitigations** for credible threats
6. **Record** in slice constraints or as a security section in the spec

## Build-Time Security Checklist

Apply these patterns during implementation:

### Input Validation

- Validate ALL external inputs at the boundary (user input, API responses,
  DOM events, file uploads, query parameters)
- Use allowlists over denylists where possible
- Validate type, length, format, and range
- Keep validation separate from business logic

### Output Encoding

- Encode output appropriate to context (HTML, URL, JavaScript, CSS)
- Never use `innerHTML` with untrusted input — use `textContent` or sanitisers
- Use parameterised queries for database operations (no string concatenation)

### Authentication & Authorisation

- Never store passwords in plaintext
- Use established libraries for auth (don't roll your own)
- Check authorisation on every request, not just at the entry point
- Session tokens must be unpredictable and expire

### Secrets Management

- No hardcoded secrets in source code
- No secrets in logs
- Use environment variables or secret management services
- Rotate credentials regularly

### Dependency Hygiene

- Avoid dependencies for trivial utilities
- New dependencies must be justified and scanned
- Keep dependencies up to date
- Review `dependency_scan` output for known vulnerabilities

See `references/owasp-patterns.md` for the OWASP Top 10 mapped to code
patterns.

## Interpreting Scan Results

### security_scan findings

- **Critical/High** → must fix before proceeding
  - Injection vulnerabilities, auth bypass, secrets exposure
- **Medium** → fix if within Paths In Scope, otherwise record as TODO
- **Low/Informational** → record, don't block

### dependency_scan findings

- **Known CVE with exploit** → Critical — update or replace dependency
- **Known CVE without exploit** → High — update in current slice if possible
- **Outdated but no CVE** → Low — record for future maintenance

### secrets_scan findings

- **Any finding** → Critical — secrets in code must be removed immediately
- Do NOT commit the fix with the secret still visible in git history
- Notify the team to rotate the exposed credential

## Agent Responsibilities

- **discover / design agents** (design-time) — identify trust boundaries, surface
  OWASP risks during discovery and architecture, express security constraints in
  BDD scenarios and specifications
- **Claude Code** (build-time) — implements secure coding patterns, adds security
  tests, enforces dependency hygiene, runs and interprets security scans
- **Only humans** may accept security risk — all exceptions must be documented,
  justified, time-bound, and reviewed
