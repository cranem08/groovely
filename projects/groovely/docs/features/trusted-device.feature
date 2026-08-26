Feature: Trust a device

  A collector who has proven control of a device may skip the authenticator
  challenge there for thirty days.

  Scenario: A collector marks a device as trusted
    Given the collector has submitted a valid authenticator code
    When the collector chooses to trust the device
    Then the collector is shown their collection

  Scenario: A collector signs in again on a trusted device
    Given the collector has a trusted device
    When the collector submits their correct email address and password on that device
    Then the collector is shown their collection

  Scenario: A collector signs in on a device they have not trusted
    Given the collector has a trusted device
    When the collector submits their correct email address and password on a different device
    Then the collector is asked for an authenticator code

  Scenario: The trust choice is not preselected
    Given the collector has been asked for an authenticator code
    When the collector submits a valid authenticator code without altering the trust choice
    Then the collector is asked for an authenticator code at the next sign in on that device
