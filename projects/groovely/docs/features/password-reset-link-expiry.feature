Feature: Password reset link expiry

  A reset link is single use and expires after sixty minutes.

  Scenario: A visitor follows a reset link more than sixty minutes after it was issued
    Given the visitor has a password reset link issued more than sixty minutes ago
    When the visitor follows that link
    Then the visitor is shown a message stating the link is no longer valid

  Scenario: A visitor follows a reset link that has already been used
    Given the visitor has already reset their password using a reset link
    When the visitor follows that same link again
    Then the visitor is shown a message stating the link is no longer valid
