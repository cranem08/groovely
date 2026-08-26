Feature: Edit a record

  Scenario: A collector changes a record's storage location
    Given the collector owns a record with no storage location
    When the collector sets that record's storage location
    Then the collector is shown that record with its new storage location

  Scenario: A collector clears a record's notes
    Given the collector owns a record with notes
    When the collector clears that record's notes
    Then the collector is shown that record with no notes
