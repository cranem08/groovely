Feature: Remove a record

  Scenario: A collector removes a record from their collection
    Given the collector owns a record by John Coltrane and a record by Bill Evans
    When the collector removes the record by John Coltrane
    Then the collector's collection shows exactly the record by Bill Evans

  Scenario: A collector removes one of two copies of the same release
    Given the collector owns two records of the same release
    When the collector removes one of those records
    Then the collector's collection shows one record of that release
