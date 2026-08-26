Feature: Revoke device trust

  Scenario: A collector reviews the devices they have trusted
    Given the collector has trusted a device labelled Kitchen laptop and signed in without trusting a device labelled Work laptop
    When the collector opens their trusted devices
    Then the collector is shown exactly one trusted device, labelled Kitchen laptop

  Scenario: A collector revokes a trusted device
    Given the collector has a trusted device
    When the collector revokes that device from their account settings
    Then that device is no longer shown in the collector's list of trusted devices

  Scenario: A collector signs in on a device whose trust they revoked
    Given the collector has revoked the trust on a device
    When the collector submits their correct email address and password on that device
    Then the collector is asked for an authenticator code

  Scenario: A collector signs in on a trusted device after changing their password
    Given the collector has changed their password since trusting a device
    When the collector submits their correct email address and password on that device
    Then the collector is asked for an authenticator code
