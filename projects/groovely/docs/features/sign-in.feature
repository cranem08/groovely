Feature: Sign in

  A visitor signs in with an email address and password, then is challenged for
  a second factor.

  Scenario: A visitor signs in with correct credentials
    Given the visitor has a Groovely account with completed authenticator enrolment
    When the visitor submits their correct email address and password
    Then the visitor is asked for an authenticator code

  Scenario: A visitor signs in with an incorrect password
    Given the visitor has a Groovely account with completed authenticator enrolment
    When the visitor submits their correct email address and an incorrect password
    Then the visitor is shown a message stating the email address or password was not recognised

  Scenario: A visitor signs in with an email address that has no account
    Given the visitor has no Groovely account
    When the visitor submits an unregistered email address and any password
    Then the visitor is shown the same message stating the email address or password was not recognised

  Scenario: The collection is reached before the authenticator challenge is answered
    Given the collector has submitted their correct email address and password without submitting an authenticator code
    When the collector navigates directly to their collection
    Then the collector is asked for an authenticator code

  Scenario: The collection is reached with no sign in at all
    Given the collector has a Groovely account with completed authenticator enrolment
    When the collector navigates directly to their collection without signing in
    Then the collector is asked for an email address and a password
