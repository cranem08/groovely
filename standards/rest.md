# REST API Standard

Rules for RESTful API design and OpenAPI specification. Apply during design,
implementation, and code review of API endpoints.

## URL Structure

- Use nouns, not verbs: `/bookmarks` not `/getBookmarks`
- Use plural resource names: `/users`, `/bookmarks`, `/tags`
- Use kebab-case for multi-word segments: `/user-preferences`
- Nest to express hierarchy: `/users/{id}/bookmarks`
- Limit nesting to two levels — flatten beyond that
- No trailing slashes: `/bookmarks` not `/bookmarks/`
- No file extensions in URLs: `/bookmarks` not `/bookmarks.json`

## HTTP Methods

- `GET` — read (safe, idempotent, no side effects)
- `POST` — create (not idempotent)
- `PUT` — full replace (idempotent)
- `PATCH` — partial update (idempotent)
- `DELETE` — remove (idempotent)
- Never use `GET` for operations that modify state
- Use `POST` for actions that don't map to CRUD: `POST /bookmarks/{id}/archive`

## Status Codes

- `200` — success (GET, PUT, PATCH, DELETE with body)
- `201` — created (POST, include `Location` header)
- `204` — success with no body (DELETE)
- `400` — bad request (validation failure, malformed input)
- `401` — unauthenticated (missing or invalid credentials)
- `403` — forbidden (authenticated but not authorised)
- `404` — not found
- `409` — conflict (duplicate resource, version conflict)
- `422` — unprocessable entity (semantically invalid input)
- `429` — too many requests (rate limited)
- `500` — internal server error (never expose internals)

## Request and Response Bodies

- Use JSON (`application/json`) for all request and response bodies
- Use camelCase for JSON property names
- Return the created or updated resource on `POST`, `PUT`, `PATCH`
- Paginate list endpoints — never return unbounded collections
- Use cursor-based or offset pagination with consistent fields: `data`, `meta.total`, `meta.nextCursor` or `meta.page`
- Include only fields the client needs — support sparse fieldsets where practical

## Error Responses

- Use a consistent error shape for all error responses:
  ```json
  { "error": { "code": "VALIDATION_ERROR", "message": "Human-readable description", "details": [] } }
  ```
- `code` is a machine-readable string (not the HTTP status code)
- `message` is safe to show to end users — no stack traces, no internal paths
- `details` is an optional array for field-level validation errors
- Never leak implementation details (database names, table names, internal IDs)

## Versioning

- Version via URL prefix: `/v1/bookmarks`
- Increment the major version only for breaking changes
- Support at most two major versions concurrently
- Document deprecation timelines in API responses via `Deprecation` header

## Security

- Authenticate via `Authorization` header (Bearer token) — never in query strings
- Return `401` for missing/invalid credentials, `403` for insufficient permissions
- Apply rate limiting to all public endpoints — return `429` with `Retry-After` header
- Set CORS headers explicitly — never use `Access-Control-Allow-Origin: *` in production
- Validate and sanitise all input per `docs/standards/security.md`

## OpenAPI 3.x Specification

- Use OpenAPI 3.0 or later for all API specifications
- Design spec-first: write the OpenAPI document before implementing endpoints
- Store specifications in `docs/specs/api/` (e.g. `docs/specs/api/openapi.yaml`)
- Every endpoint must have: `operationId`, `summary`, `responses` (at minimum `200` and `4xx`)
- Define reusable schemas in `components/schemas` — no inline object definitions
- Use `$ref` to reference shared schemas, parameters, and responses
- Mark required fields explicitly in schemas — do not rely on defaults
- Include `example` or `examples` for request bodies and non-trivial responses
- Validate the spec with a linter (e.g. `spectral`, `redocly`) as part of the quality pipeline
