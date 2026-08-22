# Feature File Examples

## Table of Contents

1. [Feature File Structure](#feature-file-structure)
2. [Good Examples](#good-examples)
3. [Bad Examples](#bad-examples)
4. [Naming Conventions](#naming-conventions)

---

## Feature File Structure

A `.feature` file follows this structure:

```gherkin
Feature: [Short descriptive name]
  [One-sentence description of the feature's user value]

  Background:
    Given [shared precondition across all scenarios in this file]

  Scenario: [Descriptive name — actor + action + outcome]
    Given [one precondition — declarative state]
    When [one user action at the boundary]
    Then [one observable outcome]
```

Rules:
- Feature name: noun phrase describing the capability
- Feature description: one sentence of user value
- Background: optional, only if ALL scenarios share the same precondition
- Each scenario: exactly one Given, one When, one Then (no AND)

---

## Good Examples

### Web Application — User Authentication

```gherkin
Feature: User authentication
  Users can sign in to access their account

  Scenario: User signs in with valid credentials
    Given the user has a registered account
    When the user submits valid login credentials
    Then the user sees their dashboard

  Scenario: User signs in with invalid credentials
    Given the user has a registered account
    When the user submits incorrect login credentials
    Then the user sees an authentication error message

  Scenario: Unauthenticated user is redirected to sign-in
    Given the user is not signed in
    When the user navigates to a protected page
    Then the user is redirected to the sign-in page
```

### API — Invoice Management

```gherkin
Feature: Invoice creation
  Merchants can create invoices for completed work

  Scenario: Merchant creates an invoice for a completed job
    Given the merchant has a completed job without an invoice
    When the merchant creates an invoice for the job
    Then the invoice is available in the merchant's invoice list

  Scenario: Invoice creation fails for an incomplete job
    Given the merchant has a job that is still in progress
    When the merchant attempts to create an invoice for the job
    Then the merchant sees an error indicating the job must be completed first
```

### CLI Tool — File Processing

```gherkin
Feature: CSV file import
  Users can import CSV files to populate the database

  Scenario: User imports a valid CSV file
    Given the user has a correctly formatted CSV file
    When the user runs the import command with the file path
    Then the records from the CSV appear in the database

  Scenario: Import rejects malformed CSV
    Given the user has a CSV file with missing required columns
    When the user runs the import command with the file path
    Then the user sees a validation error listing the missing columns
```

### MCP Server — Tool Registration

```gherkin
Feature: Tool discovery
  Clients can discover available tools on the MCP server

  Scenario: Client lists available tools
    Given the MCP server is running with registered tools
    When the client sends a tools/list request
    Then the client receives a list of tool names and descriptions

  Scenario: Client calls a registered tool
    Given the MCP server has a "search" tool registered
    When the client sends a tools/call request for "search" with valid parameters
    Then the client receives the search results
```

---

## Bad Examples

### Bad: AND in scenarios

```gherkin
# BAD — multiple preconditions with AND
Scenario: User completes checkout
  Given the user is logged in
  And the user has items in their cart
  When the user confirms checkout
  Then the order is placed
  And a confirmation email is sent
```

Fix: Split into separate scenarios per the `slice-design` skill BDD rules.

### Bad: Technical language

```gherkin
# BAD — describes implementation, not behaviour
Scenario: POST /api/orders returns 201
  Given the orders table has no records for user 42
  When a POST request is sent to /api/orders with valid JSON
  Then the response status is 201 and the body contains order_id
```

Fix: Use domain language and user-visible outcomes.

### Bad: System as actor

```gherkin
# BAD — no user action, describes internal process
Scenario: System processes payment
  Given a pending payment exists
  When the payment processor webhook fires
  Then the system updates the payment status to confirmed
```

Fix: Describe the trigger as a user or external action, and the outcome as
something observable.

### Bad: Vague outcome

```gherkin
# BAD — "works correctly" is not observable
Scenario: User registration works correctly
  Given the user is on the registration page
  When the user submits the form
  Then the registration works correctly
```

Fix: State the specific observable outcome (e.g., "the user sees a
confirmation message").

---

## Naming Conventions

### Feature files

- Use snake_case: `user_authentication.feature`, `invoice_creation.feature`
- Name after the capability, not the implementation
- One feature per file

### Scenario names

- Format: `[Actor] [action] [qualifier]`
- Good: "Merchant creates an invoice for a completed job"
- Good: "User signs in with invalid credentials"
- Bad: "Test happy path"
- Bad: "GET /api/users returns 200"

### Domain vocabulary

- Define terms in the spec, then use them consistently
- If a scenario uses "order", don't use "purchase" elsewhere for the same concept
- Use "the user" or named actors, never "the system"
