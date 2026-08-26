Feature: Account lockout

  Five consecutive failed attempts lock an account for fifteen minutes. The lock
  always ends.

  Scenario: A fifth password failure locks the account
    Given the collector has failed five consecutive password attempts
    When the collector submits their correct email address and password
    Then the collector is shown a message stating the account is temporarily locked

  Scenario: A fifth authenticator failure locks the account
    Given the collector has failed five consecutive authenticator code attempts
    When the collector submits their correct email address and password
    Then the collector is shown a message stating the account is temporarily locked

  Scenario: Four authenticator failures do not lock the account
    Given the collector has failed four consecutive authenticator code attempts
    When the collector submits the current authenticator code
    Then the collector is shown their collection

  Scenario: Four failures do not lock the account
    Given the collector has failed four consecutive password attempts
    When the collector submits their correct email address and password
    Then the collector is asked for an authenticator code

  Scenario: A locked account is given the correct password before the lock has elapsed
    Given the collector has a locked account
    When the collector submits their correct email address and password
    Then the collector is shown a message stating the account is temporarily locked

  Scenario: A locked account is given an incorrect password before the lock has elapsed
    Given the collector has a locked account
    When the collector submits their email address and an incorrect password
    Then the collector is shown a message stating the email address or password was not recognised

  Scenario: An unregistered address is submitted five times
    Given the visitor has submitted an unregistered address with a password four times
    When the visitor submits that unregistered address a fifth time
    Then the visitor is shown a message stating the email address or password was not recognised

  Scenario: A locked account after the lock has elapsed
    Given the collector has an account locked more than fifteen minutes ago
    When the collector submits their correct email address and password
    Then the collector is asked for an authenticator code

  Scenario: The counter resets when a lock elapses
    Given the collector has an account locked more than fifteen minutes ago and has since failed one password attempt
    When the collector submits their correct email address and password
    Then the collector is asked for an authenticator code

  Scenario: The counter resets on a successful sign in
    Given the collector has failed four consecutive password attempts, signed in successfully, and since failed one further attempt
    When the collector submits their correct email address and password
    Then the collector is asked for an authenticator code
