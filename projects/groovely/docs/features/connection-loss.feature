Feature: Losing the connection

  The browser app is online-only, so losing connection is a specified operating
  condition rather than an unforeseen failure.

  Scenario: A collector acts while the device has no connection
    Given the collector is shown their collection and the device has lost its connection
    When the collector opens a record that is not already loaded
    Then the collector is shown a message stating Groovely needs a connection

  Scenario: A collector reads what is already on screen while offline
    Given the collector has lost their connection while shown their collection
    When the collector opens a record already on screen
    Then the collector is shown that record

  Scenario: A collector tries to save while offline
    Given the collector has lost their connection while editing a record
    When the collector saves that record
    Then the collector is shown a message stating the change was not saved because there is no connection

  Scenario: A collector's typing survives losing the connection
    Given the collector has lost their connection while entering a record by hand
    When the collector saves that record
    Then the collector is shown the details they had already typed

  Scenario: A collector resubmits once the connection returns
    Given the collector has been told a record was not saved because there is no connection and the connection has since returned
    When the collector saves that record
    Then the collector is shown the new record in their collection

  Scenario: A collector acts once the connection has returned
    Given the collector has been shown the message stating Groovely needs a connection and the device has regained its connection
    When the collector opens a record that is not already loaded
    Then the collector is no longer shown the message stating Groovely needs a connection
