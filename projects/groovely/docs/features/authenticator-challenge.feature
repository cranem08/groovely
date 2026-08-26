Feature: Authenticator challenge

  The second factor is required on every sign in, except on a device the collector
  has explicitly chosen to trust. See trusted-device.feature.

  Scenario: A collector submits a valid authenticator code
    Given the collector has submitted their correct email address and password
    When the collector submits the current authenticator code
    Then the collector is shown their collection

  Scenario: A collector submits an expired authenticator code
    Given the collector has submitted their correct email address and password
    When the collector submits an authenticator code from more than one period ago
    Then the collector is shown a message stating the code was not accepted

  Scenario: A collector reuses an authenticator code that was already accepted
    Given the collector has signed in using an authenticator code still within its thirty second period
    When the collector submits that same authenticator code again within that period
    Then the collector is shown a message stating the code was not accepted
