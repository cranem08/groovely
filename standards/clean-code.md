# Clean Code Standard

Rules for writing readable, maintainable code. Apply during implementation
and code review.

## Function Size

- Functions should do **one thing**
- If a function needs a comment to explain a section, extract that section
- Aim for functions under 20 lines; investigate anything over 40
- Extract conditions into well-named boolean functions

## Naming

- Names reveal intent: `calculateTotal` not `calc`, `isExpired` not `check`
- Avoid abbreviations unless universally understood (`id`, `url`, `html`)
- Name length proportional to scope: short in small loops, descriptive in public APIs
- Boolean variables/functions: `isActive`, `hasPermission`, `canDelete`
- Avoid negated booleans: `isEnabled` not `isNotDisabled`

## Cognitive Load

- Maximum one level of nesting preferred; two acceptable; three requires refactoring
- Use early returns to reduce nesting (guard clauses)
- Avoid clever code — prefer obvious over concise
- One concept per function, one purpose per file
- Keep related code close together (spatial locality)

## Duplication

- Exact duplication (copy-paste): extract immediately
- Structural duplication (same shape, different values): extract with parameters
- **Do not** extract coincidental similarity — two things that look alike but
  change for different reasons should remain separate

## Error Handling

- Handle errors at the appropriate level (not too early, not too late)
- Fail fast: validate inputs at boundaries, not deep in call stacks
- Error messages must be actionable: what failed, why, and what to do
- Never swallow errors silently (`catch {}` with no handling)

## Explicit Dependencies

- All dependencies visible in function signature (no hidden global state)
- Prefer dependency injection over service locators or singletons
- Import only what you use
- No side effects in functions that appear to be pure
