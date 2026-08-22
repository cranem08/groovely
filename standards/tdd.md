# TDD Standard

Rules for test-driven development. Apply during implementation and code review.

## Red-Green-Refactor

1. **Red** — Write a failing test for the next behaviour
2. **Green** — Write the minimum code to make it pass
3. **Refactor** — Clean up while keeping tests green
4. Repeat

Never skip the red phase. Never write production code without a failing test.

## Test Quality

- Tests describe **behaviour**, not implementation
- Test names state what happens: "returns error when email is invalid"
- Each test verifies **one behaviour** (one logical assertion)
- Tests must be independent — no shared mutable state, no ordering dependency
- Tests must be deterministic — same result every time

## Arrange/Act/Assert

Every test follows this structure:

1. **Arrange** — Set up preconditions and inputs
2. **Act** — Execute the behaviour under test (one call)
3. **Assert** — Verify the expected outcome

Separate sections visually. Keep each section minimal.

## Test Coverage

- Coverage target: **95%** for changed code
- Coverage measures lines/branches exercised, not behaviour verified
- 100% coverage with poor assertions is worse than 90% with good ones
- Focus coverage on: business logic, boundary conditions, error paths
- Acceptable gaps: framework boilerplate, trivial getters/setters

## What NOT to Test

- Framework internals (trust the framework)
- Third-party library behaviour (test your integration, not theirs)
- Trivial code with no logic (simple data classes, configuration)
- Private methods directly (test through public interface)

## Anti-Patterns

- **Implementation-coupled tests**: Testing that a specific method was called rather
  than the observable outcome
- **Test-per-method**: One test per production method instead of per behaviour
- **Excessive mocking**: Mocking more than one layer deep
- **Brittle assertions**: Asserting exact strings, timestamps, or generated IDs
