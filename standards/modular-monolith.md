# Modular Monolith Standard

Rules for structuring applications as modular monoliths. Apply during design,
implementation, and code review.

## When to Use a Modular Monolith

A modular monolith is a single deployable unit organised into well-defined,
loosely coupled modules with explicit boundaries.

- **Unstructured monolith** — when the application is small enough that
  modules add no value (fewer than 3 bounded contexts, single developer,
  prototype). Start here, but graduate to modular monolith when boundaries
  emerge.
- **Modular monolith** — when the application has multiple bounded contexts,
  needs independent development within modules, and does not yet require
  independent deployment. **Default architectural style for most projects.**
- **Microservices** — when independent deployment and scaling per module is
  a hard requirement backed by evidence, not a preference. Extract from a
  modular monolith when evidence demands it.

When in doubt, choose modular monolith. You can always extract modules into
services; you cannot easily merge services back into a monolith.

## Module Identification

Modules map to **bounded contexts** from the domain, not technical layers.

Identification heuristics:
- Each module owns a distinct set of domain concepts (nouns/entities that
  belong together)
- Changes within one business capability should not require changes in
  another module
- If two concepts always change together, they belong in the same module
- If two concepts change for different reasons or at different rates, they
  belong in separate modules

Warning signs of wrong boundaries:
- A feature change touches many modules → boundaries are too granular
- A module has unrelated responsibilities that never interact → too coarse
- Module names are technical ("database", "api", "utils") rather than
  domain-based ("billing", "inventory", "identity")

Rules:
- Name modules after business capabilities, not technical concerns
- Prefer fewer, coarser modules initially — split when evidence shows
  distinct rates of change

## Module Structure

Each module is a directory under `src/modules/` (or language equivalent).

Recommended internal structure:

```
src/modules/<module-name>/
  public/            # Public API surface (interfaces, DTOs, events)
  domain/            # Domain logic (entities, value objects, domain services)
  application/       # Use cases / application services
  infrastructure/    # Adapters (database, HTTP, messaging)
  tests/             # Module-scoped tests
```

Rules:
- `public/` is the **only** directory other modules may import from
- `domain/` must have zero dependencies on framework or infrastructure code
  (per DIP in `docs/standards/solid-principles.md`)
- `application/` orchestrates domain objects and infrastructure via
  ports/interfaces defined in `domain/`
- `infrastructure/` implements ports defined in `domain/` or `application/`
- Every module MUST have an explicit public API surface — if there is no
  `public/` directory (or equivalent), the module boundary is not enforced

Internal sub-directory names may vary by language convention, but the
layering rules apply regardless. Document deviations via ADR.

## Module Boundaries

A module's **public API** is the only contract between modules.

What constitutes the public API:
- Interfaces and types in the `public/` directory
- Published domain events
- Nothing else

Encapsulation rules:
- Other modules MUST NOT import from `domain/`, `application/`, or
  `infrastructure/` of another module
- Other modules MUST NOT access another module's database tables, queues,
  or files
- Other modules MUST NOT instantiate another module's internal classes
  directly

Enforcement:
- Use language-level visibility (packages, internal modifiers) where
  available
- Use linting rules or architectural fitness functions to detect violations
- Code review MUST flag cross-module boundary violations as Critical severity

If you need something from another module, use its public API. If the public
API does not expose it, negotiate an API change — do not bypass the boundary.

## Inter-Module Communication

Two permitted communication patterns:

**1. Synchronous — direct call via interface**

Module A calls module B's public interface. Use when A needs an immediate
response and the operation is fast.

Rules:
- Always call through the public interface, never reach into internals
- The caller depends on an abstraction (interface), not the concrete
  implementation
- Inject the dependency — do not use service locators or static references

**2. Asynchronous — domain events**

Module A publishes an event; module B subscribes. Use when A does not need
a response, or the operation can be eventually consistent.

Rules:
- Events are immutable facts about something that happened (past tense:
  `OrderPlaced`, `UserRegistered`)
- Events belong to the publishing module's public API
- The publisher must not know or care who subscribes
- Events carry only the data the subscriber needs — no leaking internal state
- Start with an in-process event bus (simple pub/sub within the monolith);
  replace with a message broker only when extracting to services

Prefer events for cross-module side effects. Use direct calls only when the
caller requires an immediate, synchronous result.

## Data Ownership

Each module owns its data exclusively.

Rules:
- No shared database tables between modules
- No direct SQL joins across module boundaries
- No shared ORM models or repositories
- Each module manages its own schema and migrations

Data access patterns:
- If module A needs data from module B, it calls B's public API — not B's
  database
- If modules need the same reference data, define it in the shared kernel
  (see below) or duplicate it
- Duplication across modules is acceptable when it preserves autonomy —
  this is a deliberate trade-off, not an accident

Eventual consistency:
- When module B updates data that module A previously queried, use domain
  events to notify A
- Do not assume strong consistency across module boundaries unless
  explicitly designed for it

If two modules share a database table, they are not two modules — they are
one module with a misleading directory structure.

## Dependency Rules

Permitted dependency directions:
- Any module may depend on the **shared kernel**
- A module may depend on another module's `public/` API only
- Within a module, dependencies flow inward:
  `infrastructure/` → `application/` → `domain/`
- `domain/` depends on nothing external (no framework, no infrastructure,
  no other modules)

Prohibited:
- No circular dependencies between modules (A → B → A)
- No transitive internal access (A uses B's public API which leaks C's
  internals)
- No upward dependencies within a module (domain must not depend on
  application; application must not depend on infrastructure)

Detection:
- Use dependency analysis tools (language-specific) to verify the
  dependency graph
- A circular dependency between modules indicates a missing module or a
  wrong boundary — resolve by extracting a new module or merging

Per `docs/standards/solid-principles.md` for dependency inversion within
modules.

## Shared Kernel

The shared kernel is a small, deliberately curated set of code shared across
all modules.

What belongs in the shared kernel:
- Cross-cutting types: common value objects (Money, EmailAddress, EntityId),
  error base classes, result types
- Framework bootstrap and wiring (module registration, event bus setup)
- Shared infrastructure interfaces (logging, configuration, time provider)

What does NOT belong:
- Domain logic specific to any module
- Business rules or validation that belongs to a bounded context
- Large utility libraries (extract to a separate package instead)

Rules:
- The shared kernel must remain small and stable — changes affect all modules
- Every addition requires justification (document in ADR if non-trivial)
- If the shared kernel grows beyond ~15-20 files, audit it for misplaced
  domain logic

Location: `src/shared/` or equivalent (not inside any module).

## Testing

Testing levels in a modular monolith:

- **Unit tests (within module):** Test domain logic and application services
  in isolation. Mock infrastructure. Located in module `tests/` or project
  `tests/unit/`. Per `docs/standards/tdd.md`.
- **Integration tests (within module):** Test module with real
  infrastructure (database, file system). Verify the module's public API
  contract. Located in `tests/integration/`.
- **Cross-module integration tests:** Test interactions between two or more
  modules through their public APIs only. Never test against another
  module's internals. Located in `tests/integration/`.
- **End-to-end tests:** Test full system behaviour through external entry
  points. Located in `tests/e2e/`.

Rules:
- Unit tests must not cross module boundaries — if a test needs another
  module, mock it at the public API interface
- Integration tests across modules must use only public APIs — if the test
  breaks when a module's internals change (but its public API is stable),
  the test is coupled to internals
- Each module's tests should be runnable independently

## Anti-Patterns

1. **Distributed monolith** — modules that have boundaries in name only but
   share data, state, and internal APIs freely. Remedy: enforce public API
   and data ownership rules.

2. **God module** — one module that every other module depends on, containing
   mixed-concern logic. Remedy: split by bounded context; move shared types
   to shared kernel.

3. **Circular dependencies** — module A depends on B, B depends on A.
   Remedy: extract the shared concern into a third module or merge the two.

4. **Shared mutable state** — modules sharing in-memory caches, global
   variables, or static state. Remedy: each module owns its own state;
   communicate via events or public APIs.

5. **Database integration** — using the database as a communication channel
   (module A reads module B's tables). Remedy: call B's public API or
   subscribe to B's events.

6. **Leaky abstraction** — public API exposes internal implementation details
   (ORM entities, infrastructure types). Remedy: define DTOs and interfaces
   in `public/` that do not leak internals.

7. **Premature extraction** — splitting modules too early based on speculation
   rather than evidence of different change rates. Remedy: start coarse,
   split when evidence demands it.

8. **Technical modules** — modules named "database", "api", "utils" that cut
   horizontally across domains. Remedy: organise by business capability, not
   technical layer.

## Migration Path

A well-structured modular monolith makes service extraction straightforward.

When to extract a module to a separate service:
- The module needs independent scaling
- The module needs independent deployment (different release cadence)
- The module needs a different technology stack
- Team boundaries require independent repositories

Extraction steps:
1. Verify the module's public API is the only contract (no boundary
   violations)
2. Replace in-process calls with network calls (HTTP, gRPC, messaging)
3. Replace the in-process event bus with a message broker for that module's
   events
4. Extract the module's data store into an independent database
5. Deploy the module as a separate service

If you cannot extract a module cleanly, the monolith has hidden coupling.
Fix the coupling before attempting extraction. Document the extraction
decision as an ADR per the architecture skill.
