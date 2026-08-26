Feature: Delete the account

  Deletion is initiated and completed inside the application.

  Scenario: A collector deletes their account
    Given the collector is signed in
    When the collector confirms deletion of their account with their current password
    Then the collector is shown the registration screen

  Scenario: A collector confirms deletion with an incorrect password
    Given the collector is signed in
    When the collector confirms deletion of their account with an incorrect password
    Then the collector is shown a message stating the current password was not recognised

  Scenario: The collection after a refused deletion
    Given the collector has tried to delete their account with an incorrect password
    When the collector opens their collection
    Then the collector is shown the records they owned before

  Scenario: A deleted account is used to sign in
    Given the collector has deleted their account
    When the collector submits the email address and password of the deleted account
    Then the collector is shown a message stating the email address or password was not recognised

  Scenario: A collector deletes an account holding records then registers again
    Given the collector has deleted an account that owned records and registered again with the same email address
    When the collector opens their collection
    Then the collector is shown a message inviting them to add their first record

  Scenario: A sleeve photograph after the account holding it is deleted
    Given the collector has deleted an account that held a sleeve photograph
    When the collector requests the address that photograph was served from
    Then that address returns the same not-found response as an address that never existed

  Scenario: A second signed-in device after the account is deleted
    Given the collector has deleted their account while signed in on a second device
    When that second device requests the collection
    Then the collector is asked for an email address and a password
