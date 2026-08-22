# JavaScript / TypeScript Standard

Language-specific rules. Apply during implementation and code review of
JavaScript or TypeScript code.

## Variables and Constants

- Use `const` by default; `let` only when reassignment is needed
- Never use `var`
- Declare variables close to their first use
- Destructure objects and arrays when accessing multiple properties

## Async / Await

- Prefer `async/await` over `.then()` chains
- Always handle errors in async code (`try/catch` or `.catch()`)
- Use `Promise.all()` for independent concurrent operations
- Never use `await` inside a loop when operations are independent
- Avoid mixing callbacks and promises in the same flow

## Modules

- Use ES modules (`import/export`) over CommonJS (`require/module.exports`)
- One export per concept — avoid barrel files with dozens of re-exports
- Import order: external packages, then internal modules, then relative paths
- No circular imports

## Error Handling

- Throw `Error` objects (not strings or plain objects)
- Error messages describe what happened and why
- Catch at the appropriate level — don't catch just to re-throw
- Use custom error classes for domain-specific errors
- Log errors with context (what was being attempted, relevant IDs)

## DOM Safety (Browser)

- Never use `innerHTML` with untrusted content
- Use `textContent` for text, `createElement` for structure
- Sanitise user input before inserting into the DOM
- Use `addEventListener` over inline event handlers
- Clean up event listeners and timers to prevent memory leaks

## TypeScript Specifics

- Prefer `interface` for object shapes, `type` for unions/intersections
- Avoid `any` — use `unknown` and narrow with type guards
- Use strict mode (`strict: true` in tsconfig)
- Define return types explicitly for public functions
- Use discriminated unions over type assertions
