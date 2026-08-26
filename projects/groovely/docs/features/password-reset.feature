Feature: Password reset

  A collector who has forgotten their password sets a new one. Resetting does not
  bypass the second factor.

  Scenario: A collector requests a reset for a registered email address
    Given the collector has a Groovely account
    When the collector requests a password reset for that email address
    Then the collector is shown a message stating that a reset link has been sent if an account exists

  Scenario: A visitor requests a reset for an unregistered email address
    Given the visitor has no Groovely account
    When the visitor requests a password reset for an unregistered email address
    Then the visitor is shown the same message stating that a reset link has been sent if an account exists

  Scenario: A collector follows a valid reset link
    Given the collector has an unused password reset link
    When the collector follows that link
    Then the collector is asked to choose a new password

  Scenario: A collector sets a new password
    Given the collector has followed an unused password reset link
    When the collector submits an acceptable password
    Then the collector is asked for an authenticator code

  Scenario: A collector signs in with a password set through a reset link
    Given the collector has set a new password using a reset link
    When the collector submits their email address and that new password
    Then the collector is asked for an authenticator code

  Scenario: A collector signs in with the password a reset replaced
    Given the collector has set a new password using a reset link
    When the collector submits their email address and the password the reset replaced
    Then the collector is shown a message stating the email address or password was not recognised

  Scenario: A collector chooses a breached password when resetting
    Given the collector has followed an unused password reset link
    When the collector submits a breached password
    Then the collector is shown a message stating the password has appeared in a known data breach and must be changed
