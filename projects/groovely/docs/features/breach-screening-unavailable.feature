Feature: Breach screening unavailable

  Breach screening fails open. An outage of the external screening service must
  never prevent a visitor from registering.

  Scenario: The breach screening service is unreachable during registration
    Given the breach screening service is unreachable
    When the visitor submits the registration form with an unused email address and a twelve-character password
    Then the visitor is shown a message asking them to check their email for a verification link
