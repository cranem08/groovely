Feature: Authenticator enrolment

  Authenticator enrolment is mandatory. No collection may be reached without it.

  Scenario: A visitor completes enrolment with a valid authenticator code
    Given the visitor has verified their email address and not yet completed authenticator enrolment
    When the visitor submits a valid authenticator code for the offered secret
    Then the visitor is shown ten recovery codes

  Scenario: A visitor submits an incorrect authenticator code during enrolment
    Given the visitor has verified their email address and not yet completed authenticator enrolment
    When the visitor submits an incorrect authenticator code
    Then the visitor is shown a message stating the code was not accepted

  Scenario: A visitor attempts to reach the collection before completing enrolment
    Given the visitor has verified their email address and not yet completed authenticator enrolment
    When the visitor navigates directly to the collection
    Then the visitor is shown the authenticator enrolment screen

  Scenario: Recovery codes are shown once
    Given the collector has been shown their ten recovery codes at enrolment
    When the collector returns to their account settings
    Then the collector is not shown those recovery codes again
