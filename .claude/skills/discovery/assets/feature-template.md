Feature: [Capability name — noun phrase]
  [One sentence describing the user value this feature delivers]

  Background:
    Given [shared precondition — only if ALL scenarios share it, otherwise omit Background]

  Scenario: [Actor] [action] [qualifier — happy path]
    Given [one declarative precondition]
    When [one user action at the system boundary]
    Then [one observable outcome]

  Scenario: [Actor] [action] [qualifier — error/edge case]
    Given [one declarative precondition]
    When [one user action at the system boundary]
    Then [one observable outcome]
