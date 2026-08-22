# SOLID Principles Standard

Rules for applying SOLID principles. Apply during implementation and code
review.

## Single Responsibility Principle (SRP)

- Each module/class/function has **one reason to change**
- If you can describe a class with "and" ("handles auth and logging"), split it
- Test: can you name the class/module's single responsibility in one short phrase?
- Warning signs: large files, many imports, methods that don't use the same fields

## Open/Closed Principle (OCP)

- Code is open for extension, closed for modification
- Growing `if/else` or `switch` chains on a type field violate OCP
- Prefer polymorphism, strategy pattern, or configuration over conditionals
- New behaviour should be addable without changing existing code

## Liskov Substitution Principle (LSP)

- Subtypes must be substitutable for their base types
- Overridden methods must accept the same inputs and return compatible outputs
- Subtypes must not strengthen preconditions or weaken postconditions
- If a subtype throws where the base doesn't, LSP is violated

## Interface Segregation Principle (ISP)

- No client should depend on methods it doesn't use
- Prefer small, focused interfaces over large, general ones
- Warning signs: implementing interfaces with `throw NotImplemented` or no-op methods
- Split large interfaces by client need

## Dependency Inversion Principle (DIP)

- High-level modules must not depend on low-level modules; both depend on abstractions
- Domain logic should not import framework or infrastructure code
- Warning signs: business logic importing database drivers, HTTP clients, or framework utilities
- Invert with interfaces/abstractions at the boundary
