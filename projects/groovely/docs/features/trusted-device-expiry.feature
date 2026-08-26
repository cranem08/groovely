Feature: Trust expires

  Trust lasts thirty days and is never silently extended.

  Scenario: A collector signs in on a device trusted within the last thirty days
    Given the collector has a device trusted twenty nine days ago
    When the collector submits their correct email address and password on that device
    Then the collector is shown their collection

  Scenario: A collector signs in on a device trusted more than thirty days ago
    Given the collector has a device trusted more than thirty days ago
    When the collector submits their correct email address and password on that device
    Then the collector is asked for an authenticator code
