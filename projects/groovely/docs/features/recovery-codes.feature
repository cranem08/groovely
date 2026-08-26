Feature: Recovery codes

  Ten single-use recovery codes are issued at enrolment as the lost-device path.

  Scenario: A collector signs in using an unused recovery code
    Given the collector has an unused recovery code
    When the collector submits that recovery code in place of an authenticator code
    Then the collector is shown their collection

  Scenario: A collector reuses a recovery code that has already been consumed
    Given the collector has a recovery code that has already been used
    When the collector submits that recovery code in place of an authenticator code
    Then the collector is shown a message stating the code was not accepted

  Scenario: A collector regenerates their recovery codes
    Given the collector has ten recovery codes
    When the collector requests a new set of recovery codes with their current password
    Then the collector is shown ten different recovery codes

  Scenario: A collector requests new recovery codes with an incorrect password
    Given the collector has ten recovery codes
    When the collector requests a new set of recovery codes with an incorrect password
    Then the collector is shown a message stating the current password was not recognised

  Scenario: Five failed recovery codes lock the account
    Given the collector has failed five consecutive recovery code attempts
    When the collector submits their correct email address and password
    Then the collector is shown a message stating the account is temporarily locked

  Scenario: A code from a superseded set
    Given the collector has regenerated their recovery codes
    When the collector submits a code from the previous set
    Then the collector is shown a message stating the code was not accepted
