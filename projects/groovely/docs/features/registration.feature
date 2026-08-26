Feature: Registration

  A visitor creates a Groovely account with an email address and an acceptable
  password.

  Scenario: A visitor registers with an unused email address and an acceptable password
    Given the visitor has no Groovely account
    When the visitor submits the registration form with an unused email address and an acceptable password
    Then the visitor is shown a message asking them to check their email for a verification link

  Scenario: A visitor registers with an email address that already has an account
    Given the visitor has a Groovely account
    When the visitor submits the registration form with that same email address and an acceptable password
    Then the visitor is shown the same message asking them to check their email for a verification link

  Scenario: Registering again over an existing address leaves that account untouched
    Given the collector has an account and a visitor has since submitted the registration form with that same email address and a different password
    When the collector submits their email address and their original password
    Then the collector is asked for an authenticator code

  Scenario: A visitor chooses a breached password
    Given the visitor has no Groovely account
    When the visitor submits the registration form with an unused email address and a breached password
    Then the visitor is shown a message stating the password has appeared in a known data breach and must be changed
