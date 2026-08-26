Feature: Change a password

  A signed-in collector may change their password, but must supply the current one.
  A session alone is not sufficient authority to seize an account.

  Scenario: A collector changes their password
    Given the collector is signed in
    When the collector submits their current password together with an acceptable new password
    Then the collector is shown a message confirming their password was changed

  Scenario: A collector submits an incorrect current password
    Given the collector is signed in
    When the collector submits an incorrect current password together with an acceptable new password
    Then the collector is shown a message stating the current password was not recognised

  Scenario: A collector signs in with a changed password
    Given the collector has changed their password
    When the collector submits their email address and the new password
    Then the collector is asked for an authenticator code

  Scenario: A collector signs in with the password they replaced
    Given the collector has changed their password
    When the collector submits their email address and the password they replaced
    Then the collector is shown a message stating the email address or password was not recognised

  Scenario: A collector chooses a breached password
    Given the collector is signed in
    When the collector submits their current password together with a breached new password
    Then the collector is shown a message stating the password has appeared in a known data breach and must be changed

  Scenario: The session that made the change
    Given the collector has changed their password
    When the collector navigates directly to their collection in the same browser
    Then the collector is asked for an email address and a password
