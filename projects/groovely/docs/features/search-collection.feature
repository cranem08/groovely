Feature: Search the collection

  Scenario: A collector searches for an artist they own
    Given the collector owns a record by John Coltrane and a record by Bill Evans
    When the collector searches the artist scope for Coltrane
    Then the collector is shown only the record by John Coltrane

  Scenario: A collector searches for something they do not own
    Given the collector owns records by artists other than Miles Davis
    When the collector searches the artist scope for Miles Davis
    Then the collector is shown a message stating no records matched

  Scenario: A collector searches using different letter casing
    Given the collector owns a record by John Coltrane and a record by Bill Evans
    When the collector searches the artist scope for coltrane
    Then the collector is shown only the record by John Coltrane
