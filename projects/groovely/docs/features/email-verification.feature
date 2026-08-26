Feature: Email verification

  A newly registered account must verify its email address before enrolment.

  Scenario: A visitor follows an unused verification link
    Given the visitor has registered and not yet verified their email address
    When the visitor follows the verification link sent to that address
    Then the visitor is shown the authenticator enrolment screen

  Scenario: A visitor follows a verification link that has already been used
    Given the visitor has already verified their email address
    When the visitor follows the same verification link a second time
    Then the visitor is shown a message stating the link is no longer valid

  Scenario: A collector follows a verification link more than twenty four hours after it was issued
    Given the collector has a verification link issued more than twenty four hours ago
    When the collector follows that link
    Then the collector is shown a message stating the link is no longer valid
