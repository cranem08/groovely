# Threat Model Triggers: Decision Tree

## When Is Threat Modelling Mandatory?

Answer these questions for the current slice. If ANY answer is "Yes", threat
modelling is required.

```
Does this slice introduce a new external interface?
  (new API endpoint, webhook, form, file upload, SSE/WebSocket)
  → Yes → THREAT MODEL REQUIRED

Does this slice cross a new trust boundary?
  (client ↔ server, service ↔ service, internal ↔ external, user ↔ admin)
  → Yes → THREAT MODEL REQUIRED

Does this slice handle sensitive or regulated data?
  (PII, credentials, financial data, health data, anything under GDPR/HIPAA)
  → Yes → THREAT MODEL REQUIRED

Does this slice add or modify authentication or authorisation?
  (login, session management, role checks, permission gates, API keys)
  → Yes → THREAT MODEL REQUIRED

Does this slice modify deployment or infrastructure?
  (new service, changed network boundaries, new storage, config changes)
  → Yes → THREAT MODEL REQUIRED

Does this slice introduce agentic, autonomous, or AI-driven behaviour?
  (LLM calls, autonomous actions, tool use, agent-to-agent communication)
  → Yes → THREAT MODEL REQUIRED
```

If ALL answers are "No":
- Document "No threat modelling required" in slice constraints
- Continue implementation

## What to Produce

A slice-scoped threat model is lightweight. Minimum output:

1. **Assets at risk** — what data/capability could be harmed?
2. **Actors** — who interacts with the slice? (users, services, admins, agents)
3. **Trust boundaries** — where does trusted become untrusted?
4. **Threats** — use STRIDE per element:
   - Spoofing, Tampering, Repudiation, Information Disclosure, DoS, Elevation
5. **Mitigations** — what controls address each credible threat?
6. **Residual risks** — what remains unmitigated and why?

## Where to Record

Choose the most appropriate location:

- **Slice constraints** — if the threat model is simple (2-3 threats)
- **Security section in spec** — if the threat model is substantial
- **ADR** — if the threat model drives an architectural decision
- **Threat model notes** — `docs/architecture/threat-models/` for complex cases

## Examples

### Example: New API endpoint (simple)

```
Assets: User profile data
Actors: Authenticated users, unauthenticated requests
Trust boundary: Client → API server
Threats:
  - Spoofing: Unauthenticated access to profile data
  - Information Disclosure: Profile data leaked via error messages
  - Tampering: User modifies another user's profile
Mitigations:
  - Auth middleware on all profile endpoints
  - Authorisation check: user can only access own profile
  - Generic error responses (no data in error payloads)
Residual: None
```

### Example: No threat model needed

```
Slice: S003 — Display formatted date on dashboard
Triggers: No new interfaces, no boundary crossings, no sensitive data,
  no auth changes, no infra changes, no agentic behaviour.
Decision: No threat modelling required.
```
