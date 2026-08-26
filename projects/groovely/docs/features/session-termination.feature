Feature: Session termination

  Signing out and changing a password both end active sessions.

  Scenario: A collector signs out
    Given the collector is signed in
    When the collector signs out
    Then the collector is shown the sign in screen

  Scenario: A collector changes their password while signed in elsewhere
    Given the collector is signed in on a second device
    When the collector changes their password
    Then that second device is asked for an email address and a password

  Scenario: The collection is reached after the collector has signed out
    Given the collector has signed out
    When the collector navigates directly to their collection
    Then the collector is asked for an email address and a password

  Scenario: A session within its idle limit
    Given the collector has not used Groovely for twenty nine days
    When the collector navigates directly to their collection
    Then the collector is shown their collection

  Scenario: A session that has been idle beyond its limit
    Given the collector has not used Groovely for more than thirty days
    When the collector navigates directly to their collection
    Then the collector is asked for an email address and a password

  Scenario: A session older than its absolute limit
    Given the collector has a session created more than ninety days ago
    When the collector navigates directly to their collection
    Then the collector is asked for an email address and a password
